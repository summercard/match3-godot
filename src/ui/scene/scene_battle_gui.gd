# scene_battle_gui.gd - 可在 Godot 编辑器中调整的战局界面
class_name SceneBattleGui
extends "res://src/ui/scene/scene_battle.gd"

const MULTI_ENEMY_PATHS := [
	"Combatants/MultiEnemies/Enemy1",
	"Combatants/MultiEnemies/Enemy2",
	"Combatants/MultiEnemies/Enemy3",
]
const PLAYER_PATHS := [
	"Combatants/Players/Player1",
	"Combatants/Players/Player2",
	"Combatants/Players/Player3",
]
const ITEM_PATHS := [
	"BottomControls/Item1",
	"BottomControls/Item2",
	"BottomControls/Item3",
]

## 头像原始位置与闪白材质缓存；受击反应只改表现，不碰战斗状态。
var _portrait_base_positions: Dictionary = {}
var _portrait_flash_materials: Dictionary = {}


func _ready() -> void:
	super._ready()
	_sync_gui()

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_sync_gui()

func _process(delta: float) -> void:
	super._process(delta)
	_sync_gui()

func _uses_editable_gui() -> bool:
	return true

func _sync_gui() -> void:
	if not is_inside_tree() or _battle == null:
		return
	_sync_top_hud()
	_sync_enemy_slots()
	_sync_player_slots()
	_sync_bottom_controls()
	_sync_hit_reactions()

func _sync_top_hud() -> void:
	_label("TopHud/TurnBadge/Value").text = "%d/%d" % [_battle.turn_count, _battle.max_turns]
	_label("TopHud/SpeedLabel").text = "%dx" % _battle_speed
	var status: Dictionary = _battle.get_status()
	var phase_label := _label("TopHud/BossPhase")
	phase_label.visible = status.get("is_boss_battle", false)
	phase_label.text = "阶段 %d/%d" % [status.get("current_phase", 1), status.get("total_phases", 1)]
	var wave_label := _label("TopHud/WaveLabel")
	var show_wave: bool = not status.get("is_boss_battle", false) and int(status.get("wave_total", 1)) > 1
	wave_label.visible = show_wave
	wave_label.text = "波次 %d/%d" % [status.get("wave_index", 1), status.get("wave_total", 1)]

func _sync_enemy_slots() -> void:
	var enemy_count: int = mini(_battle.enemies.size(), 3)
	var stage_slot := _control("Combatants/SingleEnemy")
	stage_slot.visible = enemy_count == 1
	_control("Combatants/MultiEnemies").visible = enemy_count > 1
	if enemy_count == 1:
		_set_stage_enemy(stage_slot, _battle.enemies[0])
	for i in MULTI_ENEMY_PATHS.size():
		var slot := _control(MULTI_ENEMY_PATHS[i])
		slot.visible = enemy_count > 1 and i < enemy_count
		if slot.visible:
			_set_combatant(slot, _battle.enemies[i], "red")

func _sync_player_slots() -> void:
	var player_count: int = mini(_battle.player_team.size(), 3)
	for i in PLAYER_PATHS.size():
		var slot := _control(PLAYER_PATHS[i])
		slot.visible = i < player_count
		if slot.visible:
			_set_combatant(slot, _battle.player_team[i], "green")

func _set_stage_enemy(slot: Control, unit: Dictionary) -> void:
	_set_combatant(slot, unit, "red")
	var element := str(unit.get("element", "fire"))
	var orb := slot.get_node("Orb") as TextureRect
	orb.texture = _get_texture(str(GEM_IMAGE_PATHS.get(element, GEM_IMAGE_PATHS["fire"])))
	var hp := maxi(int(unit.get("hp", 0)), 0)
	var max_hp := maxi(int(unit.get("maxHP", 1)), 1)
	var active_beads := clampi(int(ceil(float(hp) / float(max_hp) * 5.0)), 0, 5)
	(slot.get_node("Beads") as Label).text = "●".repeat(active_beads) + "○".repeat(5 - active_beads)

func _set_combatant(slot: Control, unit: Dictionary, fill_color: String) -> void:
	if unit == null:
		slot.visible = false
		return
	var hp := maxi(int(unit.get("hp", 0)), 0)
	var max_hp := maxi(int(unit.get("maxHP", 1)), 1)
	var portrait := slot.get_node("Portrait") as TextureRect
	portrait.texture = _get_monster_texture(unit)
	portrait.modulate.a = 1.0 if hp > 0 else 0.35
	(slot.get_node("Name") as Label).text = str(unit.get("name", "精灵"))
	var hp_bar := slot.get_node("HpBar")
	hp_bar.set("fill_color", _hp_system_color(fill_color))
	var next_ratio := float(hp) / float(max_hp) * 100.0
	var unit_key := "%s|%s|%d" % [unit.get("id", ""), unit.get("name", ""), max_hp]
	if str(slot.get_meta("hp_unit_key", "")) != unit_key:
		slot.set_meta("hp_unit_key", unit_key)
		hp_bar.call("snap_to_value", next_ratio)
	else:
		hp_bar.call("set_target_value", next_ratio)
	(slot.get_node("HpText") as Label).text = "%d/%d" % [hp, max_hp]


## 受击反应：按 0.2s 计时驱动头像抖动与闪白；总开关关闭时恢复原位置与材质。
func _sync_hit_reactions() -> void:
	if not BattleHitReactionScript.enabled:
		_reset_slot_reaction("Combatants/SingleEnemy")
		for path in MULTI_ENEMY_PATHS:
			_reset_slot_reaction(path)
		for path in PLAYER_PATHS:
			_reset_slot_reaction(path)
		return
	_sync_slot_reaction("Combatants/SingleEnemy", true, 0)
	for i in MULTI_ENEMY_PATHS.size():
		_sync_slot_reaction(MULTI_ENEMY_PATHS[i], true, i)
	for i in PLAYER_PATHS.size():
		_sync_slot_reaction(PLAYER_PATHS[i], false, i)


func _sync_slot_reaction(path: String, is_enemy: bool, index: int) -> void:
	var slot := get_node_or_null(path) as Control
	if slot == null:
		return
	var portrait := slot.get_node_or_null("Portrait") as TextureRect
	if portrait == null:
		return
	var base := _portrait_base_position(portrait)
	var reaction := BattleHitReactionScript.find(_hit_reactions, is_enemy, index)
	portrait.position = base + BattleHitReactionScript.shake_offset(reaction)
	_apply_portrait_flash(portrait, BattleHitReactionScript.flash_alpha(reaction))


func _reset_slot_reaction(path: String) -> void:
	var slot := get_node_or_null(path) as Control
	if slot == null:
		return
	var portrait := slot.get_node_or_null("Portrait") as TextureRect
	if portrait == null:
		return
	portrait.position = _portrait_base_position(portrait)
	var material: ShaderMaterial = _portrait_flash_materials.get(portrait)
	if material != null:
		material.set_shader_parameter("flash_amount", 0.0)
	portrait.material = null


func _portrait_base_position(portrait: TextureRect) -> Vector2:
	if not _portrait_base_positions.has(portrait):
		_portrait_base_positions[portrait] = portrait.position
	return _portrait_base_positions[portrait]


func _apply_portrait_flash(portrait: TextureRect, alpha: float) -> void:
	var material: ShaderMaterial = _portrait_flash_materials.get(portrait)
	if material == null:
		material = BattleHitReactionScript.new_flash_material()
		_portrait_flash_materials[portrait] = material
	if portrait.material != material:
		portrait.material = material
	material.set_shader_parameter("flash_amount", clampf(alpha, 0.0, 1.0))

func _hp_system_color(fill_color: String) -> Color:
	match fill_color:
		"red":
			return Color(0.95, 0.12, 0.18, 1.0)
		"blue":
			return Color(0.10, 0.55, 0.95, 1.0)
		"gold":
			return Color(1.0, 0.68, 0.08, 1.0)
		_:
			return Color(0.45, 0.82, 0.08, 1.0)

func _sync_bottom_controls() -> void:
	var toggle_key := "capture_toggle_on" if _auto_capture_enabled else "capture_toggle_off"
	_texture("BottomControls/CaptureToggle/Image").texture = _get_texture(BATTLE_UI_ASSETS[toggle_key])
	_label("BottomControls/CaptureToggle/Badge").text = "开" if _auto_capture_enabled else "关"
	for i in ITEM_PATHS.size():
		var slot := _control(ITEM_PATHS[i])
		var item: Dictionary = _hotbar_items[i] if i < _hotbar_items.size() else {}
		var has_item := not item.is_empty() and int(item.get("count", 0)) > 0
		slot.visible = has_item
		if not has_item:
			continue
		var item_id := str(item.get("id", ""))
		_texture("%s/Icon" % ITEM_PATHS[i]).texture = _get_texture(_item_icon_asset_path(item_id))
		_texture("%s/Selection" % ITEM_PATHS[i]).visible = _is_hotbar_item_selected(i, item)
		var count := int(item.get("count", 0))
		var badge := _label("%s/Badge" % ITEM_PATHS[i])
		badge.visible = count > 1
		badge.text = str(count)

func _get_capture_toggle_rect(base_y: float) -> Rect2:
	if is_inside_tree() and has_node("BottomControls/CaptureToggle"):
		return _control_rect("BottomControls/CaptureToggle")
	return super._get_capture_toggle_rect(base_y)

func _get_speed_button_rect() -> Rect2:
	if is_inside_tree() and has_node("TopHud/SpeedButton"):
		return _control_rect("TopHud/SpeedButton")
	return super._get_speed_button_rect()

func _get_settings_button_rect() -> Rect2:
	if is_inside_tree() and has_node("TopHud/SettingsButton"):
		return _control_rect("TopHud/SettingsButton")
	return super._get_settings_button_rect()

func _get_hotbar_slot_rect(base_y: float, slot_idx: int) -> Rect2:
	if is_inside_tree() and slot_idx >= 0 and slot_idx < ITEM_PATHS.size():
		return _control_rect(ITEM_PATHS[slot_idx])
	return super._get_hotbar_slot_rect(base_y, slot_idx)

func _get_player_card_rect(index: int) -> Rect2:
	if is_inside_tree() and index >= 0 and index < PLAYER_PATHS.size():
		return _control_rect("%s/SkillHitArea" % PLAYER_PATHS[index])
	return super._get_player_card_rect(index)

func _control_rect(path: NodePath) -> Rect2:
	var node := _control(path)
	var root_inverse := get_global_transform_with_canvas().affine_inverse()
	var origin := root_inverse * node.get_global_transform_with_canvas().origin
	return Rect2(origin, node.size)

func _control(path: NodePath) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

func _texture(path: NodePath) -> TextureRect:
	return get_node(path) as TextureRect

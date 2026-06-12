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
	"BottomControls/Item3",
	"BottomControls/Item4",
	"BottomControls/Item5",
]
const CAPTURE_ITEM_PATHS := [
	"BottomControls/Item1",
	"BottomControls/Item2",
]
const DEFEATED_GHOST_ASSET := "res://assets/images/effects/battle_fx_defeated_ghost.png"

func _ready() -> void:
	super._ready()
	_connect_item_confirm_buttons()
	_portrait_defeat_ghost_cache.clear()
	_portrait_base_scale_cache.clear()
	_portrait_base_global_center_cache.clear()
	_portrait_hit_flash_overlay_cache.clear()
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
	_sync_item_confirm_popup()

func _connect_item_confirm_buttons() -> void:
	var cancel := get_node_or_null("ItemConfirmLayer/Panel/CancelButton") as BaseButton
	if cancel != null and not cancel.pressed.is_connected(_cancel_hotbar_item_confirm):
		cancel.pressed.connect(_cancel_hotbar_item_confirm)
	var confirm := get_node_or_null("ItemConfirmLayer/Panel/UseButton") as BaseButton
	if confirm != null and not confirm.pressed.is_connected(_confirm_hotbar_item_use):
		confirm.pressed.connect(_confirm_hotbar_item_use)

func _sync_top_hud() -> void:
	_label("TopHud/TurnBadge/Value").text = "%d/%d" % [_battle.turn_count, _battle.max_turns]
	var status: Dictionary = _battle.get_status()
	var phase_label := _label("TopHud/BossPhase")
	phase_label.visible = status.get("is_boss_battle", false)
	phase_label.text = "阶段 %d/%d" % [status.get("current_phase", 1), status.get("total_phases", 1)]

func _sync_enemy_slots() -> void:
	var enemy_count: int = mini(_battle.enemies.size(), 3)
	var stage_slot := _control("Combatants/SingleEnemy")
	stage_slot.visible = enemy_count == 1
	_control("Combatants/MultiEnemies").visible = enemy_count > 1
	if enemy_count == 1:
		_set_stage_enemy(stage_slot, _battle.enemies[0])
		# ★ 主人定 2026-06-11：单怪 Boss 受击 portrait 柔和闪白
		_apply_hit_feedback(stage_slot, true, 0)
		# ★ 主人定 2026-06-11：倒下阶段 portrait：先渐隐，再幽灵从下冲上渐显
		_apply_defeat_feedback(stage_slot, true, 0)
		# ★ 主人定 2026-06-11：攻击者弹性放大
		_apply_elastic_feedback(stage_slot, true, 0)
	for i in MULTI_ENEMY_PATHS.size():
		var slot := _control(MULTI_ENEMY_PATHS[i])
		slot.visible = enemy_count > 1 and i < enemy_count
		if slot.visible:
			_set_combatant(slot, _battle.enemies[i], "red")
			# ★ 主人定 2026-06-11：多怪受击 portrait 柔和闪白
			_apply_hit_feedback(slot, true, i)
			_apply_defeat_feedback(slot, true, i)
			_apply_elastic_feedback(slot, true, i)

func _sync_player_slots() -> void:
	var player_count: int = mini(_battle.player_team.size(), 3)
	for i in PLAYER_PATHS.size():
		var slot := _control(PLAYER_PATHS[i])
		slot.visible = i < player_count
		if slot.visible:
			_set_combatant(slot, _battle.player_team[i], "green")
			# ★ 主人定 2026-06-11：玩家受击 portrait 柔和闪白
			_apply_hit_feedback(slot, false, i)
			_apply_defeat_feedback(slot, false, i)
			_apply_elastic_feedback(slot, false, i)

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
	portrait.texture = _get_monster_texture(unit) if hp > 0 else _get_texture(DEFEATED_GHOST_ASSET)
	portrait.modulate.a = 1.0
	(slot.get_node("Name") as Label).text = str(unit.get("name", "精灵"))
	var hp_bar := slot.get_node("HpBar")
	hp_bar.set("fill_color", _hp_system_color(fill_color))
	hp_bar.set("value", float(hp) / float(max_hp) * 100.0)
	(slot.get_node("HpText") as Label).text = "%d/%d" % [hp, max_hp]

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
	_sync_capture_item_slots()
	for i in ITEM_PATHS.size():
		var slot := _control(ITEM_PATHS[i])
		var item: Dictionary = _hotbar_items[i] if i < _hotbar_items.size() else {}
		var has_item := not item.is_empty() and int(item.get("count", 0)) > 0
		slot.visible = true
		if slot.has_node("Base"):
			(slot.get_node("Base") as TextureRect).modulate.a = 1.0 if has_item else 0.72
		_texture("%s/Icon" % ITEM_PATHS[i]).texture = null
		_texture("%s/Selection" % ITEM_PATHS[i]).visible = false
		_label("%s/Badge" % ITEM_PATHS[i]).visible = false
		if not has_item:
			continue
		var item_id := str(item.get("id", ""))
		_texture("%s/Icon" % ITEM_PATHS[i]).texture = _get_texture(_item_icon_asset_path(item_id))
		_texture("%s/Selection" % ITEM_PATHS[i]).visible = _is_hotbar_item_selected(i, item)
		var count := int(item.get("count", 0))
		var badge := _label("%s/Badge" % ITEM_PATHS[i])
		badge.visible = count > 1
		badge.text = str(count)

func _sync_capture_item_slots() -> void:
	for i in CAPTURE_ITEM_PATHS.size():
		var path: String = str(CAPTURE_ITEM_PATHS[i])
		var slot := _control(path)
		var item: Dictionary = _capture_slot_items[i] if i < _capture_slot_items.size() else {}
		var has_item := not item.is_empty() and int(item.get("count", 0)) > 0
		slot.visible = true
		if slot.has_node("Base"):
			(slot.get_node("Base") as TextureRect).modulate.a = 1.0 if has_item else 0.72
		_texture("%s/Icon" % path).texture = null
		_texture("%s/Selection" % path).visible = false
		_label("%s/Badge" % path).visible = false
		if not has_item:
			continue
		var item_id := str(item.get("id", ""))
		_texture("%s/Icon" % path).texture = _get_texture(_item_icon_asset_path(item_id))
		_texture("%s/Selection" % path).visible = item_id == _equipped_capture_item_id
		var count := int(item.get("count", 0))
		var badge := _label("%s/Badge" % path)
		badge.visible = count > 1
		badge.text = str(count)

func _sync_item_confirm_popup() -> void:
	var layer := get_node_or_null("ItemConfirmLayer") as Control
	if layer == null:
		return
	var visible := _pending_hotbar_slot >= 0 and _pending_hotbar_slot < _hotbar_items.size()
	layer.visible = visible
	if not visible:
		return
	var item: Dictionary = _hotbar_items[_pending_hotbar_slot]
	var item_id := str(item.get("id", ""))
	var def: Dictionary = ItemDB.get_item(item_id)
	_texture("ItemConfirmLayer/Panel/IconFrame/Icon").texture = _get_texture(_item_icon_asset_path(item_id))
	_label("ItemConfirmLayer/Panel/Title").text = "使用道具"
	_label("ItemConfirmLayer/Panel/Name").text = str(def.get("name", "道具"))
	_label("ItemConfirmLayer/Panel/Desc").text = str(def.get("desc", ""))
	_label("ItemConfirmLayer/Panel/Count").text = "拥有: %d" % int(item.get("count", 0))
	_label("ItemConfirmLayer/Panel/CancelButton/Text").text = "取消"
	_label("ItemConfirmLayer/Panel/UseButton/Text").text = "使用"

func _get_capture_toggle_rect(base_y: float) -> Rect2:
	if is_inside_tree() and has_node("BottomControls/CaptureToggle"):
		return _control_rect("BottomControls/CaptureToggle")
	return super._get_capture_toggle_rect(base_y)

func _get_capture_item_slot_rect(base_y: float, slot_idx: int) -> Rect2:
	if is_inside_tree() and slot_idx >= 0 and slot_idx < CAPTURE_ITEM_PATHS.size():
		return _control_rect(CAPTURE_ITEM_PATHS[slot_idx])
	return super._get_capture_item_slot_rect(base_y, slot_idx)

func _get_hotbar_slot_rect(base_y: float, slot_idx: int) -> Rect2:
	if is_inside_tree() and slot_idx >= 0 and slot_idx < ITEM_PATHS.size():
		return _control_rect(ITEM_PATHS[slot_idx])
	return super._get_hotbar_slot_rect(base_y, slot_idx)

func _get_player_card_rect(index: int) -> Rect2:
	if is_inside_tree() and index >= 0 and index < PLAYER_PATHS.size():
		return _control_rect("%s/SkillHitArea" % PLAYER_PATHS[index])
	return super._get_player_card_rect(index)

# ★ 主人定 2026-06-11：把 .tscn 里的 Portrait 真实中心位置喂给 renderer
# renderer 用这些点作为攻击特效（hit spark / bullet / attack cue）的锚点
# 这样你直接在场景里拖 Enemy1/2/3 / SingleEnemy / Player1/2/3 节点就能看到特效跟着走
func _combatant_render_state() -> Dictionary:
	var state := super._combatant_render_state()
	if is_inside_tree() and _battle != null:
		state["gui_enemy_centers"] = _collect_enemy_centers()
		state["gui_player_centers"] = _collect_player_centers()
	return state

func _collect_enemy_centers() -> Array:
	var centers: Array = []
	var enemy_count: int = mini(_battle.enemies.size(), 3)
	if enemy_count <= 1:
		var path := NodePath("Combatants/SingleEnemy/Portrait")
		if has_node(path):
			centers.append(_get_portrait_effect_center(path, true, 0))
		else:
			centers.append(Vector2.ZERO)
	else:
		for i in MULTI_ENEMY_PATHS.size():
			var path := NodePath("%s/Portrait" % MULTI_ENEMY_PATHS[i])
			if has_node(path):
				centers.append(_get_portrait_effect_center(path, true, i))
			else:
				centers.append(Vector2.ZERO)
	return centers

func _collect_player_centers() -> Array:
	var centers: Array = []
	for i in PLAYER_PATHS.size():
		var path := NodePath("%s/Portrait" % PLAYER_PATHS[i])
		if has_node(path):
			centers.append(_get_portrait_effect_center(path, false, i))
		else:
			centers.append(Vector2.ZERO)
	return centers

func _portrait_center(path: NodePath) -> Vector2:
	var rect := _control_rect(path)
	return rect.position + rect.size * 0.5

# ★ 主人定 2026-06-11：受击时让"特效位置"和"角色图片位置"分离
# 角色图片在 _apply_hit_feedback 里只做柔和闪白，不再位移
# 特效（hit spark 等）仍锁在角色被命中那一刻的原位置
# 这里第一次观察时缓存 portrait 的全局中心；只要该 combatant 有 hit_flash 在播，
# 就回 base_center 而不是 current center
var _portrait_base_global_center_cache: Dictionary = {}

func _get_portrait_effect_center(path: NodePath, is_enemy: bool, index: int) -> Vector2:
	var portrait: TextureRect = get_node(path) as TextureRect
	if portrait == null:
		return Vector2.ZERO
	var portrait_id: int = portrait.get_instance_id()
	var current_center: Vector2 = _portrait_current_global_center(portrait)
	var hit_active := false
	for flash in _hit_flashes:
		if bool(flash.get("isEnemy", false)) == is_enemy and int(flash.get("monsterIndex", -1)) == index:
			hit_active = true
			break
	var defeat_active := _has_defeat_transition(is_enemy, index)
	if not _portrait_base_global_center_cache.has(portrait_id):
		if (hit_active or defeat_active) and _portrait_base_pos_cache.has(portrait_id):
			var base_pos: Vector2 = _portrait_base_pos_cache[portrait_id]
			_portrait_base_global_center_cache[portrait_id] = current_center + (base_pos - portrait.position)
		else:
			_portrait_base_global_center_cache[portrait_id] = current_center
	var base_center: Vector2 = _portrait_base_global_center_cache[portrait_id]
	# 命中和倒下过渡期间都回 base center，避免受击圈跟随幽灵上浮。
	if hit_active or defeat_active:
		return base_center
	return current_center

func _has_defeat_transition(is_enemy: bool, index: int) -> bool:
	for entry in _defeat_transitions:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			return true
	return false

func _portrait_current_global_center(portrait: TextureRect) -> Vector2:
	var root_inverse := get_global_transform_with_canvas().affine_inverse()
	var global_center: Vector2 = portrait.get_global_transform_with_canvas() * (portrait.size * 0.5)
	return root_inverse * global_center

# ★ 主人定 2026-06-11：受击反馈
# Portrait 节点在编辑器 GUI 模式下承担怪物贴图渲染，加上：
# 1) 命中瞬间叠一层柔和暖白 additive overlay，随后自然淡出
# 2) 不再移动 portrait，避免受击反馈和特效锚点互相干扰
# 3) 没命中时清回 white modulate 和 base position
var _portrait_base_pos_cache: Dictionary = {}
var _portrait_hit_flash_overlay_cache: Dictionary = {}

func _apply_hit_feedback(slot: Control, is_enemy: bool, index: int) -> void:
	var portrait := slot.get_node_or_null("Portrait") as TextureRect
	if portrait == null:
		return
	var portrait_id := portrait.get_instance_id()
	if not _portrait_base_pos_cache.has(portrait_id):
		_portrait_base_pos_cache[portrait_id] = portrait.position
	var base_pos: Vector2 = _portrait_base_pos_cache[portrait_id]
	if not _portrait_base_global_center_cache.has(portrait_id):
		_portrait_base_global_center_cache[portrait_id] = _portrait_current_global_center(portrait)
	# 查找匹配的 hit_flash
	var flash_t: float = 0.0
	for flash in _hit_flashes:
		if bool(flash.get("isEnemy", false)) == is_enemy and int(flash.get("monsterIndex", -1)) == index:
			var max_t: float = maxf(0.01, float(flash.get("maxTimer", 0.4)))
			flash_t = clampf(float(flash.get("timer", 0.0)) / max_t, 0.0, 1.0)
			break
	if flash_t <= 0.0:
		portrait.position = base_pos
		portrait.modulate = Color(1.0, 1.0, 1.0, portrait.modulate.a)
		_set_hit_flash_overlay(slot, portrait, 0.0)
		return
	portrait.modulate = Color(1.0, 1.0, 1.0, portrait.modulate.a)
	portrait.position = base_pos
	# flash_t 从 1 → 0：命中瞬间最亮，然后快速柔和衰减。
	_set_hit_flash_overlay(slot, portrait, pow(flash_t, 0.68) * 0.34)

func _set_hit_flash_overlay(slot: Control, portrait: TextureRect, alpha: float) -> void:
	var portrait_id := portrait.get_instance_id()
	var overlay := _portrait_hit_flash_overlay_cache.get(portrait_id, null) as TextureRect
	if overlay == null or not is_instance_valid(overlay):
		overlay = TextureRect.new()
		overlay.name = "HitFlashOverlay"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.expand_mode = portrait.expand_mode
		overlay.stretch_mode = portrait.stretch_mode
		overlay.z_index = portrait.z_index
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		overlay.material = mat
		slot.add_child(overlay)
		_portrait_hit_flash_overlay_cache[portrait_id] = overlay
	overlay.texture = portrait.texture
	overlay.position = portrait.position
	overlay.size = portrait.size
	overlay.scale = portrait.scale
	overlay.pivot_offset = portrait.pivot_offset
	overlay.visible = alpha > 0.01 and portrait.texture != null
	overlay.modulate = Color(0.96, 0.90, 0.68, clampf(alpha, 0.0, 0.45))

func _control_rect(path: NodePath) -> Rect2:
	var node := _control(path)
	var root_inverse := get_global_transform_with_canvas().affine_inverse()
	var origin := root_inverse * node.get_global_transform_with_canvas().origin
	return Rect2(origin, node.size)

# ★ 主人定 2026-06-11：倒下阶段 portrait 处理
# 0.00~0.20 活体图 alpha 1→0（先消失）
# 0.20~0.30 空隙
# 0.30~1.00 幽灵从下方冲上（offset_y +28→0）+ alpha 0→1（渐渐变出现）
# 阶段外：恢复 base 位置 + alpha 1 + 活体图
var _portrait_defeat_ghost_cache: Dictionary = {}

func _apply_defeat_feedback(slot: Control, is_enemy: bool, index: int) -> void:
	var portrait := slot.get_node_or_null("Portrait") as TextureRect
	if portrait == null:
		return
	var portrait_id := portrait.get_instance_id()
	if not _portrait_base_pos_cache.has(portrait_id):
		_portrait_base_pos_cache[portrait_id] = portrait.position
	var base_pos: Vector2 = _portrait_base_pos_cache[portrait_id]
	# 取出 hp
	var hp_alive: bool = true
	if _battle != null:
		var arr: Array = _battle.enemies if is_enemy else _battle.player_team
		if index >= 0 and index < arr.size():
			var unit: Dictionary = arr[index]
			if unit == null or maxi(int(unit.get("hp", 0)), 0) <= 0:
				hp_alive = false
	# 取出 defeat transition
	var dt: Dictionary = {}
	for entry in _defeat_transitions:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			dt = entry
			break
	if dt.is_empty():
		if hp_alive:
			# 活体且无倒下过渡时，不接管 position/modulate；受击反馈负责位移和染色。
			return
		else:
			# legacy：没 transition 记录时，按旧行为：直接显示 ghost
			_portrait_defeat_ghost_cache[portrait_id] = true
			portrait.texture = _get_texture(DEFEATED_GHOST_ASSET)
			portrait.position = base_pos
			portrait.modulate.a = 1.0
			return
	var max_t: float = maxf(0.01, float(dt.get("maxDuration", dt.get("duration", 0.7))))
	var t: float = clampf(1.0 - float(dt.get("timer", max_t)) / max_t, 0.0, 1.0)
	if t < 0.20:
		# 阶段 1：活体图渐隐
		# 每帧锁定为活体图，避免 _set_combatant 在 hp<=0 时先切成 ghost。
		var arr2: Array = _battle.enemies if is_enemy else _battle.player_team
		if index >= 0 and index < arr2.size():
			var unit2: Dictionary = arr2[index]
			if unit2 != null:
				var alive_tex: Texture2D = _get_monster_texture(unit2)
				if alive_tex != null:
					portrait.texture = alive_tex
		_portrait_defeat_ghost_cache[portrait_id] = false
		portrait.position = base_pos
		portrait.modulate.a = 1.0 - (t / 0.20)
	elif t < 0.30:
		# 阶段 2：空隙（隐藏）
		portrait.position = base_pos
		portrait.modulate.a = 0.0
	else:
		# 阶段 3：幽灵从下冲上 + 渐显
		# 每帧锁定为 ghost 图，确保淡入上浮阶段不被其他同步逻辑覆盖。
		portrait.texture = _get_texture(DEFEATED_GHOST_ASSET)
		_portrait_defeat_ghost_cache[portrait_id] = true
		var rise: float = clampf((t - 0.30) / 0.70, 0.0, 1.0)
		var offset_y: float = 28.0 * (1.0 - rise)
		portrait.position = base_pos + Vector2(0.0, offset_y)
		portrait.modulate.a = rise

# ★ 主人定 2026-06-11：攻击者小幅度弹性放大（应用到 portrait.scale）
# progress 0→0.10 1.0→1.08
# progress 0.10→0.25 1.08→0.97
# progress 0.25→0.40 0.97→1.02
# progress 0.40→1.0 1.02→1.0
var _portrait_base_scale_cache: Dictionary = {}

func _apply_elastic_feedback(slot: Control, is_enemy: bool, index: int) -> void:
	var portrait := slot.get_node_or_null("Portrait") as TextureRect
	if portrait == null:
		return
	var portrait_id := portrait.get_instance_id()
	if not _portrait_base_scale_cache.has(portrait_id):
		# 锁定 pivot 到中心，确保从中心缩放
		portrait.pivot_offset = portrait.size * 0.5
		_portrait_base_scale_cache[portrait_id] = portrait.scale
	var base_scale: Vector2 = _portrait_base_scale_cache[portrait_id]
	var factor: float = 1.0
	for entry in _attacker_elastic_anims:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			var max_t: float = maxf(0.01, float(entry.get("maxDuration", entry.get("duration", 0.32))))
			var t: float = clampf(1.0 - float(entry.get("timer", max_t)) / max_t, 0.0, 1.0)
			if t < 0.10:
				factor = 1.0 + 0.08 * (t / 0.10)
			elif t < 0.25:
				var p: float = (t - 0.10) / 0.15
				factor = 1.08 - 0.11 * p
			elif t < 0.40:
				var p2: float = (t - 0.25) / 0.15
				factor = 0.97 + 0.05 * p2
			elif t < 1.0:
				var p3: float = (t - 0.40) / 0.60
				factor = 1.02 - 0.02 * p3
			break
	# 倒下阶段不要和 elastic 叠加（避免 ghost 也缩放）
	for entry in _defeat_transitions:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			factor = 1.0
			break
	portrait.scale = base_scale * factor

func _control(path: NodePath) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

func _texture(path: NodePath) -> TextureRect:
	return get_node(path) as TextureRect

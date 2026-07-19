# scene_battle_gui.gd - 可在 Godot 编辑器中调整的战局界面
class_name SceneBattleGui
extends "res://src/ui/scene/scene_battle.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
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
const PLAYER_SLOT_TEAM_INDICES := [1, 0, 2]
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
const ELEMENT_ICON_PATHS := {
	"fire": "res://assets/images/ui/elements/element_fire.png",
	"water": "res://assets/images/ui/elements/element_water.png",
	"grass": "res://assets/images/ui/elements/element_grass.png",
	"thunder": "res://assets/images/ui/elements/element_thunder.png",
	"earth": "res://assets/images/ui/elements/element_earth.png",
	"wind": "res://assets/images/ui/elements/element_wind.png",
	"light": "res://assets/images/ui/elements/element_light.png",
	"dark": "res://assets/images/ui/elements/element_dark.png",
	"ice": "res://assets/images/ui/elements/element_water.png",
	"void": "res://assets/images/ui/elements/element_dark.png",
	"temporal": "res://assets/images/ui/elements/element_light.png",
	"star": "res://assets/images/ui/elements/element_light.png",
}
const BOSS_STATUS_OFFSET_Y: float = -56.0
const BATTLE_END_OVERLAY_PATH := NodePath("BattleEndOverlay")
const BATTLE_END_TITLE_PATH := NodePath("BattleEndOverlay/Banner/Title")
const BATTLE_END_STATUS_PATH := NodePath("BattleEndOverlay/StatusGroup/StatusLabel")
const BATTLE_END_CONTINUE_TEXT_PATH := NodePath("BattleEndOverlay/ContinueButton/Text")
const PAUSE_DIALOG_PATH := NodePath("PauseDialog")
const PAUSE_BUTTON_PATH := NodePath("TopHud/PauseButton")
const GEM_CONVERT_LAYER_PATH := NodePath("GemConvertLayer")
const GUI_CACHE_PATHS := [
	"Background",
	"TopHud",
	"TopHud/TurnBadge/Value",
	"TopHud/ObjectiveLabel",
	"TopHud/BossPhase",
	"TopHud/PauseButton",
	"Combatants/SingleEnemy",
	"Combatants/MultiEnemies",
	"Combatants/MultiEnemies/Enemy1",
	"Combatants/MultiEnemies/Enemy2",
	"Combatants/MultiEnemies/Enemy3",
	"Combatants/Players/Player1",
	"Combatants/Players/Player2",
	"Combatants/Players/Player3",
	"BottomControls",
	"BottomControls/CaptureToggle",
	"BottomControls/CaptureToggle/Image",
	"BottomControls/CaptureToggle/Badge",
	"ItemConfirmLayer",
	"ItemConfirmLayer/Panel/IconFrame/Icon",
	"ItemConfirmLayer/Panel/Title",
	"ItemConfirmLayer/Panel/Name",
	"ItemConfirmLayer/Panel/Desc",
	"ItemConfirmLayer/Panel/Count",
	"ItemConfirmLayer/Panel/CancelButton",
	"ItemConfirmLayer/Panel/CancelButton/Text",
	"ItemConfirmLayer/Panel/UseButton",
	"ItemConfirmLayer/Panel/UseButton/Text",
	"GemConvertLayer",
	"GemConvertLayer/Panel/SourceRow",
	"GemConvertLayer/Panel/TargetRow",
	"GemConvertLayer/Panel/TargetTitle",
	"GemConvertLayer/Panel/ConfirmButton",
	"GemConvertLayer/Panel/CancelButton",
	"BattleEndOverlay",
	"BattleEndOverlay/Shade",
	"BattleEndOverlay/Burst",
	"BattleEndOverlay/Panel",
	"BattleEndOverlay/Banner",
	"BattleEndOverlay/StatusGroup",
	"BattleEndOverlay/StatusGroup/Plaque",
	"BattleEndOverlay/StatusGroup/StatusLabel",
	"BattleEndOverlay/ContinueButton",
	"BattleEndOverlay/ContinueButton/Text",
]

# === 战斗界面入场动画时间线（对齐大厅 Header / BottomNav 节奏）===
const ENTRY_TOP_DELAY := 0.00
const ENTRY_NAV_DELAY := 0.38
const ENTRY_TOP_DURATION := 0.34
const ENTRY_NAV_DURATION := 0.34
const ENTRY_TOP_SLIDE := 30.0
const ENTRY_NAV_SLIDE := 30.0
var _entry_played: bool = false
var _battle_end_overlay_base_positions: Dictionary = {}
var _paused_by_player: bool = false
var _gui_node_cache: Dictionary = {}
var _gui_dirty: bool = true
var _last_gui_signature: String = ""
var _sync_gui_call_count: int = 0

# === 属性易形 picker 状态 ===
var _gem_convert_stage: int = 0        # 0=hidden, 1=picking source, 2=picking target
var _gem_convert_source: String = ""
var _gem_convert_target: String = ""
var _gem_convert_pending_item_id: String = ""
var _gem_convert_pending_slot: int = -1

func _ready() -> void:
	super._ready()
	_warm_gui_node_cache()
	_connect_item_confirm_buttons()
	_connect_gem_convert_buttons()
	_connect_pause_buttons()
	_attach_button_feedbacks()
	_portrait_defeat_ghost_cache.clear()
	_portrait_base_scale_cache.clear()
	_portrait_base_global_center_cache.clear()
	_portrait_hit_flash_overlay_cache.clear()
	_mark_gui_dirty()
	_sync_gui()
	_maybe_play_entry()

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_mark_gui_dirty()
	_sync_gui()

func _exit_tree() -> void:
	# 避免玩家在暂停态退出场景时残留 paused 状态
	if is_instance_valid(get_tree()) and get_tree().paused:
		get_tree().paused = false
	_paused_by_player = false

func _process(delta: float) -> void:
	super._process(delta)
	if _should_sync_gui_after_process():
		_sync_gui()

func _uses_editable_gui() -> bool:
	return true

func _uses_editable_battle_end_overlay() -> bool:
	return has_node(BATTLE_END_OVERLAY_PATH)

func _sync_gui() -> void:
	if not is_inside_tree() or _battle == null:
		return
	_sync_gui_call_count += 1
	_sync_background()
	_sync_top_hud()
	_sync_enemy_slots()
	_sync_player_slots()
	_sync_bottom_controls()
	_sync_item_confirm_popup()
	_sync_gem_convert_layer()
	_sync_battle_end_overlay()
	_gui_dirty = false
	_last_gui_signature = _build_gui_signature()

func _mark_gui_dirty() -> void:
	_gui_dirty = true

func _should_sync_gui_after_process() -> bool:
	if not is_inside_tree() or _battle == null:
		return false
	if _gui_dirty:
		return true
	if _has_active_gui_motion():
		return true
	return _build_gui_signature() != _last_gui_signature

func _has_active_gui_motion() -> bool:
	if _state == BattleState.BATTLE_END and _battle_end_overlay_timer <= BATTLE_END_TOTAL_DURATION + 0.08:
		return true
	if _capture_phase == "playing" or _capture_phase == "checking":
		return true
	return (
		not _hit_flashes.is_empty()
		or not _attacker_elastic_anims.is_empty()
		or not _defeat_transitions.is_empty()
	)

func _build_gui_signature() -> String:
	if _battle == null:
		return "no-battle"
	var status: Dictionary = _battle.get_status()
	var objective: Dictionary = _battle.get_objective_state(_board)
	var parts: Array[String] = []
	parts.append(str(_state))
	parts.append(str(_battle.turn_count))
	parts.append(str(_battle.max_turns))
	parts.append(str(_battle.battle_result))
	parts.append(str(objective.get("mode", "")))
	parts.append(str(objective.get("display", "")))
	parts.append(str(status.get("current_phase", "")))
	parts.append(str(status.get("total_phases", "")))
	parts.append(str(status.get("is_boss_battle", false)))
	parts.append(JSON.stringify(status.get("leader_charge_points", {})))
	parts.append(JSON.stringify(status.get("enemy_intents", {})))
	parts.append(_combatants_signature(_battle.enemies))
	parts.append(_combatants_signature(_battle.player_team))
	parts.append(JSON.stringify(_capture_slot_items))
	parts.append(JSON.stringify(_hotbar_items))
	parts.append(str(_auto_capture_enabled))
	parts.append(_equipped_capture_item_id)
	parts.append(str(_selected_hotbar_slot))
	parts.append(str(_pending_hotbar_slot))
	parts.append(str(_gem_convert_stage))
	parts.append(_gem_convert_source)
	parts.append(_gem_convert_target)
	parts.append(_capture_phase)
	parts.append(str(_capture_success))
	parts.append(JSON.stringify(_capture_result_text))
	parts.append(str(_paused_by_player))
	return "|".join(parts)

func _combatants_signature(combatants: Array) -> String:
	var parts: Array[String] = []
	for i in mini(combatants.size(), 3):
		var unit: Dictionary = combatants[i] if combatants[i] is Dictionary else {}
		parts.append("%s:%s:%s:%s:%s:%s:%s:%s" % [
			str(unit.get("id", unit.get("monsterId", ""))),
			str(unit.get("name", "")),
			str(unit.get("hp", "")),
			str(unit.get("maxHP", "")),
			str(unit.get("element", "")),
			str(unit.get("boardAffinity", "")),
			str(unit.get("isBoss", false)),
			str(unit.get("isElite", false)),
		])
	return ",".join(parts)

func _warm_gui_node_cache() -> void:
	_gui_node_cache.clear()
	for path in GUI_CACHE_PATHS:
		_cache_node_if_present(NodePath(path))
	for path in CAPTURE_ITEM_PATHS:
		for child in ["Base", "Icon", "Selection", "Badge"]:
			_cache_node_if_present(NodePath("%s/%s" % [path, child]))
	for path in ITEM_PATHS:
		for child in ["Base", "Icon", "Selection", "Badge"]:
			_cache_node_if_present(NodePath("%s/%s" % [path, child]))
	for e in ["Fire", "Water", "Grass", "Thunder", "Light"]:
		_cache_node_if_present(NodePath("GemConvertLayer/Panel/SourceRow/Src%s" % e))
		_cache_node_if_present(NodePath("GemConvertLayer/Panel/TargetRow/Tgt%s" % e))

func _cache_node_if_present(path: NodePath) -> void:
	var node := get_node_or_null(path)
	if node != null:
		_gui_node_cache[str(path)] = node

func _cached_node(path: NodePath) -> Node:
	var key := str(path)
	var cached := _gui_node_cache.get(key, null) as Node
	if cached != null and is_instance_valid(cached):
		return cached
	var node := get_node(path)
	_gui_node_cache[key] = node
	return node

func _sync_background() -> void:
	var background := get_node_or_null("Background") as TextureRect
	if background == null:
		return
	var texture := _get_texture(_battle_background_path)
	if background.texture != texture:
		background.texture = texture

func _connect_item_confirm_buttons() -> void:
	var cancel := get_node_or_null("ItemConfirmLayer/Panel/CancelButton") as BaseButton
	if cancel != null and not cancel.pressed.is_connected(_cancel_hotbar_item_confirm):
		cancel.pressed.connect(_cancel_hotbar_item_confirm)
	var confirm := get_node_or_null("ItemConfirmLayer/Panel/UseButton") as BaseButton
	if confirm != null and not confirm.pressed.is_connected(_confirm_hotbar_item_use):
		confirm.pressed.connect(_confirm_hotbar_item_use)

func _connect_gem_convert_buttons() -> void:
	var elements := ["Fire", "Water", "Grass", "Thunder", "Light"]
	for e in elements:
		var src := get_node_or_null("GemConvertLayer/Panel/SourceRow/Src%s" % e) as BaseButton
		if src != null and not src.pressed.is_connected(_on_gem_convert_source_picked):
			src.pressed.connect(_on_gem_convert_source_picked.bind(str(e).to_lower()))
		var tgt := get_node_or_null("GemConvertLayer/Panel/TargetRow/Tgt%s" % e) as BaseButton
		if tgt != null and not tgt.pressed.is_connected(_on_gem_convert_target_picked):
			tgt.pressed.connect(_on_gem_convert_target_picked.bind(str(e).to_lower()))
	var confirm := get_node_or_null("GemConvertLayer/Panel/ConfirmButton") as BaseButton
	if confirm != null and not confirm.pressed.is_connected(_on_gem_convert_confirm):
		confirm.pressed.connect(_on_gem_convert_confirm)
	var cancel := get_node_or_null("GemConvertLayer/Panel/CancelButton") as BaseButton
	if cancel != null and not cancel.pressed.is_connected(_on_gem_convert_cancel):
		cancel.pressed.connect(_on_gem_convert_cancel)

func _connect_pause_buttons() -> void:
	var pause_btn := get_node_or_null(PAUSE_BUTTON_PATH) as BaseButton
	if pause_btn != null and not pause_btn.pressed.is_connected(_on_pause_button_pressed):
		pause_btn.pressed.connect(_on_pause_button_pressed)
	var resume_btn := get_node_or_null("PauseDialog/Panel/ResumeButton") as BaseButton
	if resume_btn != null and not resume_btn.pressed.is_connected(_on_resume_button_pressed):
		resume_btn.pressed.connect(_on_resume_button_pressed)
	var quit_btn := get_node_or_null("PauseDialog/Panel/QuitButton") as BaseButton
	if quit_btn != null and not quit_btn.pressed.is_connected(_on_quit_button_pressed):
		quit_btn.pressed.connect(_on_quit_button_pressed)

func _attach_button_feedbacks() -> void:
	for button in _collect_base_buttons(self):
		if button.has_node("CartoonFeedback"):
			continue
		var feedback := CartoonButtonFeedbackScript.new()
		button.add_child(feedback)
		feedback.setup(button, _feedback_profile_for_button(button))

func _collect_base_buttons(node: Node) -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	if node is BaseButton:
		buttons.append(node as BaseButton)
	for child in node.get_children():
		buttons.append_array(_collect_base_buttons(child))
	return buttons

func _feedback_profile_for_button(button: BaseButton) -> int:
	var node_name := str(button.name).to_lower()
	if node_name.contains("confirm") or node_name.contains("use") or node_name.contains("continue"):
		return CartoonButtonFeedback.Profile.PRIMARY
	if node_name.contains("pause") or node_name.contains("src") or node_name.contains("tgt"):
		return CartoonButtonFeedback.Profile.ICON
	return CartoonButtonFeedback.Profile.NAV

func _on_pause_button_pressed() -> void:
	# 战斗结束后禁用暂停入口（结算层接管输入）
	if _state == BattleState.BATTLE_END:
		return
	if _paused_by_player:
		return
	var dialog := get_node_or_null(PAUSE_DIALOG_PATH) as Control
	if dialog == null:
		return
	dialog.visible = true
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_paused_by_player = true
	get_tree().paused = true
	_mark_gui_dirty()

func _on_resume_button_pressed() -> void:
	_resume_from_pause()

func _resume_from_pause() -> void:
	var dialog := get_node_or_null(PAUSE_DIALOG_PATH) as Control
	if dialog != null:
		dialog.visible = false
		dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paused_by_player = false
	if is_instance_valid(get_tree()):
		get_tree().paused = false
	_mark_gui_dirty()

func _on_quit_button_pressed() -> void:
	# 先解暂停，避免场景切换时残留 paused 状态影响下一场景
	_paused_by_player = false
	if is_instance_valid(get_tree()):
		get_tree().paused = false
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager != null and scene_manager.has_method("switch_scene"):
		scene_manager.switch_scene("main", {}, "fade")
	else:
		# 兜底：直接走 main 的切换
		var main_node := get_node_or_null("/root/Main")
		if main_node != null and main_node.has_method("switch_scene"):
			main_node.switch_scene("main", {}, "fade")

# 战斗界面入场序列：TopHud 从上方滑入 + 淡入，BottomControls 从下方滑入 + 淡入
func _maybe_play_entry() -> void:
	if _entry_played:
		return
	_entry_played = true
	_play_entry()

func _play_entry() -> void:
	# 1) TopHud：上方 30px 滑入 + 淡入
	var top := get_node_or_null("TopHud") as Control
	if top != null:
		var top_rest_y := top.position.y
		top.position.y = top_rest_y - ENTRY_TOP_SLIDE
		top.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_TOP_DELAY)
		tween.tween_property(top, "modulate:a", 1.0, ENTRY_TOP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(top, "position:y", top_rest_y, ENTRY_TOP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2) BottomControls：下方 30px 滑入 + 淡入
	var bottom := get_node_or_null("BottomControls") as Control
	if bottom != null:
		var bottom_rest_y := bottom.position.y
		bottom.position.y = bottom_rest_y + ENTRY_NAV_SLIDE
		bottom.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_NAV_DELAY)
		tween.tween_property(bottom, "modulate:a", 1.0, ENTRY_NAV_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(bottom, "position:y", bottom_rest_y, ENTRY_NAV_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _sync_top_hud() -> void:
	_label("TopHud/TurnBadge/Value").text = "%d/%d" % [_battle.turn_count, _battle.max_turns]
	var status: Dictionary = _battle.get_status()
	var objective_label := _label("TopHud/ObjectiveLabel")
	var objective: Dictionary = _battle.get_objective_state(_board)
	objective_label.visible = str(objective.get("mode", "defeat_enemies")) != "defeat_enemies"
	objective_label.text = str(objective.get("display", ""))
	var phase_label := _label("TopHud/BossPhase")
	phase_label.visible = status.get("is_boss_battle", false)
	phase_label.text = TranslationServer.translate("阶段 %d/%d") % [status.get("current_phase", 1), status.get("total_phases", 1)]

func _sync_enemy_slots() -> void:
	var enemy_count: int = mini(_battle.enemies.size(), 3)
	var stage_slot := _control("Combatants/SingleEnemy")
	_apply_tower_enemy_offset(stage_slot)
	_apply_tower_enemy_offset(_control("Combatants/MultiEnemies"))
	var featured_single := enemy_count == 1 and BattleCombatantRendererScript.uses_featured_single_layout(_battle.enemies[0])
	stage_slot.visible = featured_single
	_control("Combatants/MultiEnemies").visible = enemy_count > 1 or (enemy_count == 1 and not featured_single)
	if featured_single:
		_set_stage_enemy(stage_slot, _battle.enemies[0])
		# 单体精英 / Boss 使用特殊放大槽。
		_apply_hit_feedback(stage_slot, true, 0)
		# ★ 主人定 2026-06-11：倒下阶段 portrait：先渐隐，再幽灵从下冲上渐显
		_apply_defeat_feedback(stage_slot, true, 0)
		# ★ 主人定 2026-06-11：攻击者弹性放大
		_apply_elastic_feedback(stage_slot, true, 0)
	for i in MULTI_ENEMY_PATHS.size():
		var slot := _control(MULTI_ENEMY_PATHS[i])
		var enemy_index := i
		if enemy_count == 1 and not featured_single:
			# 普通单怪保持常规尺寸，放在三槽布局的中央。
			slot.visible = i == 1
			enemy_index = 0
		else:
			slot.visible = enemy_count > 1 and i < enemy_count
		if slot.visible:
			_set_combatant(slot, _battle.enemies[enemy_index], "red", true)
			# ★ 主人定 2026-06-11：多怪受击 portrait 柔和闪白
			_apply_hit_feedback(slot, true, enemy_index)
			_apply_defeat_feedback(slot, true, enemy_index)
			_apply_elastic_feedback(slot, true, enemy_index)


func _apply_tower_enemy_offset(control: Control) -> void:
	if control == null:
		return
	if not control.has_meta("v132_base_y"):
		control.set_meta("v132_base_y", control.position.y)
	control.position.y = float(control.get_meta("v132_base_y")) - (10.0 if _tower_mode else 0.0)

func _sync_player_slots() -> void:
	var player_count: int = mini(_battle.player_team.size(), 3)
	for i in PLAYER_PATHS.size():
		var slot := _control(PLAYER_PATHS[i])
		var team_index := _team_index_for_player_slot(i)
		slot.visible = team_index >= 0 and team_index < player_count
		if slot.visible:
			_set_combatant(slot, _battle.player_team[team_index], "green", false)
			_sync_leader_charge_point(slot, _battle.player_team[team_index])
			_sync_leader_badge(slot, team_index)
			# ★ 主人定 2026-06-11：玩家受击 portrait 柔和闪白
			_apply_hit_feedback(slot, false, team_index)
			_apply_defeat_feedback(slot, false, team_index)
			_apply_elastic_feedback(slot, false, team_index)
		else:
			_sync_leader_badge(slot, -1)

func _team_index_for_player_slot(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= PLAYER_SLOT_TEAM_INDICES.size():
		return slot_index
	return int(PLAYER_SLOT_TEAM_INDICES[slot_index])

func _player_slot_index_for_team_index(team_index: int) -> int:
	for slot_index in PLAYER_SLOT_TEAM_INDICES.size():
		if int(PLAYER_SLOT_TEAM_INDICES[slot_index]) == team_index:
			return slot_index
	return team_index

func _active_leader_index_for_gui() -> int:
	if _battle == null:
		return -1
	var status: Dictionary = _battle.get_status()
	var leader_info: Variant = status.get("leader_skill_info", null)
	if leader_info is Dictionary:
		var leader_index := int((leader_info as Dictionary).get("leader_index", -1))
		if leader_index >= 0:
			return leader_index
	for i in range(_battle.player_team.size()):
		var unit = _battle.player_team[i]
		if unit != null and int(unit.get("hp", 0)) > 0:
			return i
	return -1

func _sync_leader_badge(slot: Control, team_index: int) -> void:
	var badge := slot.get_node_or_null("LeaderBadge") as TextureRect
	if badge == null:
		return
	badge.visible = team_index >= 0 and team_index == _active_leader_index_for_gui()

func _sync_leader_charge_point(slot: Control, unit: Dictionary) -> void:
	var point := slot.get_node_or_null("LeaderChargePoint") as Control
	if point == null or _battle == null or unit == null:
		return
	var status: Dictionary = _battle.get_status()
	var charges: Dictionary = status.get("leader_charge_points", {})
	var max_charge := maxi(1, int(status.get("leader_charge_max", 1)))
	var monster_id := str(unit.get("id", ""))
	var value := int(charges.get(monster_id, 0))
	point.visible = int(unit.get("hp", 0)) > 0
	var progress := clampf(float(value) / float(max_charge), 0.0, 1.0)
	if point.has_method("animate_to"):
		point.call("animate_to", progress)
	else:
		point.set("progress", progress)
	point.set("element", str(unit.get("boardAffinity", unit.get("element", "fire"))))

func _set_stage_enemy(slot: Control, unit: Dictionary) -> void:
	_set_combatant(slot, unit, "red", true)
	var element := str(unit.get("element", "fire"))
	var orb := slot.get_node("Orb") as TextureRect
	orb.texture = _get_texture(str(GEM_IMAGE_PATHS.get(element, GEM_IMAGE_PATHS["fire"])))
	var hp := maxi(int(unit.get("hp", 0)), 0)
	var max_hp := maxi(int(unit.get("maxHP", 1)), 1)
	var active_beads := clampi(int(ceil(float(hp) / float(max_hp) * 5.0)), 0, 5)
	(slot.get_node("Beads") as Label).text = "●".repeat(active_beads) + "○".repeat(5 - active_beads)

func _set_combatant(slot: Control, unit: Dictionary, fill_color: String, allow_boss_status_offset: bool = false) -> void:
	if unit == null:
		slot.visible = false
		return
	var hp := maxi(int(unit.get("hp", 0)), 0)
	var max_hp := maxi(int(unit.get("maxHP", 1)), 1)
	_apply_combatant_status_offset(slot, allow_boss_status_offset and bool(unit.get("isBoss", false)) and hp > 0)
	var portrait := slot.get_node("Portrait") as TextureRect
	_apply_portrait_visual_scale(portrait, _combatant_portrait_scale(slot, unit, hp))
	portrait.texture = _get_monster_texture(unit) if hp > 0 else _get_texture(DEFEATED_GHOST_ASSET)
	portrait.modulate.a = 1.0
	var is_elite := bool(unit.get("isElite", false))
	var elite_prefix := "★精英 " if is_elite else ""
	var name_label := slot.get_node("Name") as Label
	name_label.text = "%s%s" % [TranslationServer.translate(elite_prefix), TranslationServer.translate(str(unit.get("name", "精灵")))]
	name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.16, 1.0) if is_elite else Color.WHITE)
	var hp_bar := slot.get_node("HpBar")
	hp_bar.set("fill_color", _hp_system_color(fill_color))
	hp_bar.set("value", float(hp) / float(max_hp) * 100.0)
	var hp_label := slot.get_node("HpText") as Label
	hp_label.text = "%d/%d" % [hp, max_hp]
	_sync_hp_label_layout(slot, hp_label)
	var element_icon := slot.get_node_or_null("ElementIcon") as TextureRect
	if element_icon != null:
		var element := str(unit.get("boardAffinity", unit.get("element", "fire")))
		element_icon.texture = _get_texture(str(ELEMENT_ICON_PATHS.get(element, ELEMENT_ICON_PATHS["fire"])))
		element_icon.visible = element_icon.texture != null

var _portrait_base_rect_cache: Dictionary = {}
var _status_base_rect_cache: Dictionary = {}

func _combatant_portrait_scale(slot: Control, unit: Dictionary, hp: int) -> float:
	if hp <= 0:
		return 1.0
	# Cocos/微信 1.3.2 的战局敌方框使用固定尺寸；只保留共鸣塔
	# 独立的 1.30 倍体型规则。这样稀有度不会再次改写最终立绘框。
	var slot_path := str(slot.get_path())
	if slot_path.contains("/Combatants/SingleEnemy") or slot_path.contains("/Combatants/MultiEnemies/"):
		return float(unit.get("_towerVisualScale", 1.0))
	return float(unit.get("_visualScale", StatCalculator.visual_scale_for_stats(unit)))

func _apply_portrait_visual_scale(portrait: TextureRect, visual_scale: float) -> void:
	var portrait_id := portrait.get_instance_id()
	if not _portrait_base_rect_cache.has(portrait_id):
		_portrait_base_rect_cache[portrait_id] = Rect2(portrait.position, portrait.size)
	var base_rect: Rect2 = _portrait_base_rect_cache[portrait_id]
	var scale := maxf(0.1, visual_scale)
	var scaled_size := base_rect.size * scale
	var scaled_pos := base_rect.position + (base_rect.size - scaled_size) * 0.5
	portrait.position = scaled_pos
	portrait.size = scaled_size
	portrait.pivot_offset = scaled_size * 0.5
	_portrait_base_pos_cache[portrait_id] = scaled_pos
	_portrait_base_global_center_cache[portrait_id] = _portrait_current_global_center(portrait)

func _apply_combatant_status_offset(slot: Control, is_boss: bool) -> void:
	var offset := Vector2(0.0, BOSS_STATUS_OFFSET_Y if is_boss else 0.0)
	for node_name in ["Name", "HpBar", "HpFrameBase", "HpFrame", "HpText", "ElementIcon", "Beads", "Orb"]:
		var node := slot.get_node_or_null(node_name) as Control
		if node == null:
			continue
		var node_id := node.get_instance_id()
		if not _status_base_rect_cache.has(node_id):
			_status_base_rect_cache[node_id] = Rect2(node.position, node.size)
		var base_rect: Rect2 = _status_base_rect_cache[node_id]
		node.position = base_rect.position + offset
		node.size = base_rect.size

func _sync_hp_label_layout(slot: Control, hp_label: Label) -> void:
	var frame := slot.get_node_or_null("HpFrame") as Control
	if frame != null:
		hp_label.position = frame.position
		hp_label.size = frame.size
	var font_size := 11
	var outline_size := 2
	if slot.name == "EnemyStageSlot":
		font_size = 14
		if frame != null:
			hp_label.position = frame.position + Vector2(-6.0, -2.0)
			hp_label.size = frame.size + Vector2(12.0, 2.0)
	hp_label.add_theme_font_size_override("font_size", font_size)
	hp_label.add_theme_constant_override("outline_size", outline_size)
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
	_label("ItemConfirmLayer/Panel/Count").text = TranslationServer.translate("拥有: %d") % int(item.get("count", 0))
	_label("ItemConfirmLayer/Panel/CancelButton/Text").text = "取消"
	_label("ItemConfirmLayer/Panel/UseButton/Text").text = "使用"

# === 属性易形 picker 实现 ===
func _open_gem_convert_picker(item_id: String, slot_idx: int) -> void:
	_gem_convert_pending_item_id = item_id
	_gem_convert_pending_slot = slot_idx
	_gem_convert_source = ""
	_gem_convert_target = ""
	_gem_convert_stage = 1
	_mark_gui_dirty()
	var layer := get_node_or_null(GEM_CONVERT_LAYER_PATH) as Control
	if layer != null:
		layer.visible = true
		layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_gem_convert_layer()

func _on_gem_convert_source_picked(element: String) -> void:
	if _gem_convert_stage != 1:
		return
	_gem_convert_source = element
	_gem_convert_target = ""
	_gem_convert_stage = 2
	_mark_gui_dirty()
	_sync_gem_convert_layer()

func _on_gem_convert_target_picked(element: String) -> void:
	if _gem_convert_stage != 2:
		return
	_gem_convert_target = element
	_mark_gui_dirty()
	_sync_gem_convert_layer()

func _on_gem_convert_confirm() -> void:
	if _gem_convert_stage != 2:
		return
	if _gem_convert_source.is_empty() or _gem_convert_target.is_empty():
		return
	if _gem_convert_source == _gem_convert_target:
		return
	_execute_gem_type_shift(_gem_convert_source, _gem_convert_target)

func _on_gem_convert_cancel() -> void:
	_close_gem_convert_picker(false)

func _close_gem_convert_picker(consume: bool) -> void:
	var layer := get_node_or_null(GEM_CONVERT_LAYER_PATH) as Control
	if layer != null:
		layer.visible = false
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if consume and _gem_convert_pending_slot >= 0 and not _gem_convert_pending_item_id.is_empty():
		_consume_hotbar_item(_gem_convert_pending_item_id, _gem_convert_pending_slot)
	_gem_convert_stage = 0
	_gem_convert_source = ""
	_gem_convert_target = ""
	_gem_convert_pending_item_id = ""
	_gem_convert_pending_slot = -1
	# 重置 ItemConfirmLayer 状态
	_pending_hotbar_slot = -1
	_mark_gui_dirty()

func _sync_gem_convert_layer() -> void:
	var layer := get_node_or_null(GEM_CONVERT_LAYER_PATH) as Control
	if layer == null:
		return
	var active := _gem_convert_stage == 1 or _gem_convert_stage == 2
	layer.visible = active
	if not active:
		return
	var source_row := get_node_or_null("GemConvertLayer/Panel/SourceRow") as Control
	var target_row := get_node_or_null("GemConvertLayer/Panel/TargetRow") as Control
	var target_title := get_node_or_null("GemConvertLayer/Panel/TargetTitle") as Control
	var confirm_btn := get_node_or_null("GemConvertLayer/Panel/ConfirmButton") as BaseButton
	if source_row != null:
		source_row.visible = true
	if target_row != null:
		target_row.visible = _gem_convert_stage == 2
	if target_title != null:
		target_title.visible = _gem_convert_stage == 2
	if confirm_btn != null:
		confirm_btn.disabled = not (_gem_convert_stage == 2 and not _gem_convert_source.is_empty() and not _gem_convert_target.is_empty() and _gem_convert_source != _gem_convert_target)
	# 禁用 source 已被选为 target 的按钮
	var elements := ["Fire", "Water", "Grass", "Thunder", "Light"]
	for e in elements:
		var el := str(e).to_lower()
		var src := get_node_or_null("GemConvertLayer/Panel/SourceRow/Src%s" % e) as BaseButton
		if src != null:
			src.disabled = _gem_convert_stage == 2 and el == _gem_convert_target
		var tgt := get_node_or_null("GemConvertLayer/Panel/TargetRow/Tgt%s" % e) as BaseButton
		if tgt != null:
			tgt.disabled = _gem_convert_stage == 2 and el == _gem_convert_source

func _execute_gem_type_shift(source: String, target: String) -> void:
	if _board == null:
		_close_gem_convert_picker(false)
		return
	if _state != BattleState.IDLE:
		_show_message("当前无法使用道具")
		_close_gem_convert_picker(false)
		return
	var affected := 0
	for r in range(_board.rows):
		for c in range(_board.cols):
			if str(_board.grid[r][c]) == source:
				_board.grid[r][c] = target
				affected += 1
	_screen_flash_timer = 0.22
	_element_glow = {"type": target, "timer": 0.5, "color": GEM_COLORS.get(target, C["gold"])}
	var source_emoji: String = GEM_EMOJI.get(source, source)
	var target_emoji: String = GEM_EMOJI.get(target, target)
	var center_x := float(_board.offset_x) + float(_board.cols) * float(_board.cell_size) * 0.5
	var center_y := float(_board.offset_y) + float(_board.rows) * float(_board.cell_size) * 0.5
	_spawn_item_use_effect("gem_shift", Vector2(center_x, center_y), GEM_COLORS.get(target, C["gold"]), 0.92, {"source": source, "target": target, "affected": affected})
	_floating_texts.append({"text": "%s→%s × %d" % [source_emoji, target_emoji, affected], "x": center_x, "y": center_y, "color": C["gold"], "size": 16.0, "timer": 0.0, "duration": 1.0})
	_show_message(TranslationServer.translate("使用 属性易形：%s → %s（%d 个宝石）") % [source_emoji, target_emoji, affected])
	_sfx("battle_heal_leaf_bubble")
	queue_redraw()
	_close_gem_convert_picker(true)

func _sync_battle_end_overlay() -> void:
	var layer := get_node_or_null(BATTLE_END_OVERLAY_PATH) as Control
	if layer == null:
		return
	var active := _state == BattleState.BATTLE_END
	layer.visible = active
	layer.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	if not active:
		return
	var is_win: bool = _battle != null and _battle.battle_result == "win"
	(layer.get_node("Shade") as ColorRect).modulate.a = _overlay_fade(BATTLE_END_BG_START, BATTLE_END_BG_DURATION)
	_sync_battle_end_texture_node("Burst", _overlay_xform(BATTLE_END_BURST_START, BATTLE_END_BURST_DURATION, BATTLE_END_BURST_SCALE_START, 1.08, BATTLE_END_BURST_OFFSET_Y), is_win)
	_sync_battle_end_texture_node("Panel", _overlay_xform(BATTLE_END_PANEL_START, BATTLE_END_PANEL_DURATION, BATTLE_END_PANEL_SCALE_START, 1.0, 0.0), true)
	_sync_battle_end_texture_node("Banner", _overlay_xform(BATTLE_END_BANNER_START, BATTLE_END_BANNER_DURATION, BATTLE_END_BANNER_SCALE_START, 1.05, BATTLE_END_BANNER_OFFSET_Y), true)
	_sync_battle_end_texture_node("StatusGroup", _overlay_xform(BATTLE_END_PLAQUE_START, BATTLE_END_PLAQUE_DURATION, BATTLE_END_PLAQUE_SCALE_START, 1.05, 0.0), true)
	_sync_battle_end_texture_node("ContinueButton", _overlay_xform(BATTLE_END_TAP_START, BATTLE_END_TAP_DURATION, BATTLE_END_TAP_SCALE_START, 1.06, BATTLE_END_TAP_OFFSET_Y), _capture_phase == "done" or _capture_phase == "")

	var title := get_node_or_null(BATTLE_END_TITLE_PATH) as Label
	if title != null:
		title.text = "胜利" if is_win else "失败"
		title.add_theme_color_override("font_color", C["gold"] if is_win else Color(0.78, 0.78, 0.86))
	var state_text := "点击查看结算"
	var state_color: Color = C["text_muted"]
	if _capture_phase != "done" and _capture_phase != "":
		state_text = "收服判定中..."
		state_color = C["gold"]
	elif not _capture_result_text.is_empty():
		state_text = _clean_battle_end_status_text(str(_capture_result_text.get("title", state_text)))
		state_color = C["success"] if _capture_success else Color(0.52, 0.67, 0.86)
	var status_label := get_node_or_null(BATTLE_END_STATUS_PATH) as Label
	if status_label != null:
		status_label.text = state_text
		status_label.add_theme_color_override("font_color", state_color)
	var plaque := get_node_or_null("BattleEndOverlay/StatusGroup/Plaque") as CanvasItem
	if plaque != null:
		plaque.visible = not _capture_result_text.is_empty()
	var continue_text := get_node_or_null(BATTLE_END_CONTINUE_TEXT_PATH) as Label
	if continue_text != null:
		continue_text.visible = _capture_phase == "done" or _capture_phase == ""

func _sync_battle_end_texture_node(path: NodePath, xform: Dictionary, visible: bool) -> void:
	var node := get_node_or_null(NodePath("BattleEndOverlay/%s" % String(path))) as Control
	if node == null:
		return
	if not _battle_end_overlay_base_positions.has(node.get_instance_id()):
		_battle_end_overlay_base_positions[node.get_instance_id()] = node.position
		node.pivot_offset = node.size * 0.5
	var base_pos: Vector2 = _battle_end_overlay_base_positions[node.get_instance_id()]
	node.visible = visible and float(xform.get("alpha", 0.0)) > 0.0
	node.modulate.a = float(xform.get("alpha", 1.0))
	node.scale = Vector2.ONE * float(xform.get("scale", 1.0))
	node.position = base_pos + Vector2(0.0, float(xform.get("offset_y", 0.0)))

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
	var slot_index := _player_slot_index_for_team_index(index)
	if is_inside_tree() and slot_index >= 0 and slot_index < PLAYER_PATHS.size():
		return _control_rect("%s/SkillHitArea" % PLAYER_PATHS[slot_index])
	return super._get_player_card_rect(index)

# ★ 主人定 2026-06-11：把 .tscn 里的 Portrait 真实中心位置喂给 renderer
# renderer 用这些点作为攻击特效（hit spark / bullet / attack cue）的锚点
# 这样你直接在场景里拖 Enemy1/2/3 / SingleEnemy / Player1/2/3 节点就能看到特效跟着走
func _combatant_render_state() -> Dictionary:
	var state := super._combatant_render_state()
	if is_inside_tree() and _battle != null:
		state["gui_enemy_centers"] = _collect_enemy_centers()
		state["gui_player_centers"] = _collect_player_centers()
		state["gui_enemy_hp_rects"] = _collect_enemy_hp_rects()
	return state

func _collect_enemy_centers() -> Array:
	var centers: Array = []
	var enemy_count: int = mini(_battle.enemies.size(), 3)
	if enemy_count <= 1:
		var featured_single := enemy_count == 1 and BattleCombatantRendererScript.uses_featured_single_layout(_battle.enemies[0])
		var path := NodePath("Combatants/SingleEnemy/Portrait" if featured_single else "Combatants/MultiEnemies/Enemy2/Portrait")
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

func _collect_enemy_hp_rects() -> Array:
	var rects: Array = []
	var enemy_count: int = mini(_battle.enemies.size(), 3)
	if enemy_count <= 1:
		var featured_single := enemy_count == 1 and BattleCombatantRendererScript.uses_featured_single_layout(_battle.enemies[0])
		var path := NodePath("Combatants/SingleEnemy/HpFrame" if featured_single else "Combatants/MultiEnemies/Enemy2/HpFrame")
		rects.append(_control_rect(path) if has_node(path) else Rect2())
	else:
		for i in MULTI_ENEMY_PATHS.size():
			var path := NodePath("%s/HpFrame" % MULTI_ENEMY_PATHS[i])
			rects.append(_control_rect(path) if has_node(path) else Rect2())
	return rects

func _collect_player_centers() -> Array:
	var centers: Array = []
	var player_count: int = mini(_battle.player_team.size(), 3) if _battle != null else PLAYER_PATHS.size()
	for team_index in range(player_count):
		var slot_index := _player_slot_index_for_team_index(team_index)
		var path := NodePath("%s/Portrait" % PLAYER_PATHS[slot_index])
		if has_node(path):
			centers.append(_get_portrait_effect_center(path, false, team_index))
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
	return _cached_node(path) as Control

func _label(path: NodePath) -> Label:
	return _cached_node(path) as Label

func _texture(path: NodePath) -> TextureRect:
	return _cached_node(path) as TextureRect

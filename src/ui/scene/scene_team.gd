# ============================================
# ui/scene/scene_team.gd - 队伍编成场景
# 翻译自: js/ui/sceneTeamSetup.js
# 重构后: 纯代码驱动，无 @onready 依赖
# ============================================
# 队伍编成界面，支持：
# - 队长+2成员槽位（最多3只怪兽）
# - 拖拽排序、选中切换
# - 怪兽详情（等级/性格/队长技能）
# - 总战力计算与显示
# ============================================

class_name SceneTeam
extends Control

# ============ 信号 ============
signal team_changed(team: Dictionary)
signal scene_exit()

# ============ 布局常量 ============
const DESIGN_W := 375.0
const DESIGN_H := 667.0
const MARGIN := 15.0

# ============ 节点引用（代码创建） ============
var back_button: Button
var title_label: Label
var power_label: Label
var leader_slot_container: HBoxContainer
var member_slots_container: HBoxContainer
var monster_list_scroll: ScrollContainer
var monster_list_grid: GridContainer
var save_button: Button
var cancel_button: Button
var confirm_dialog: PanelContainer
var guide_label: Label

# ============ 游戏引用 ============
var game_manager: Node = null

# ============ 状态数据 ============
var team: Dictionary = {
	"leader": null,
	"member1": null,
	"member2": null
}
var selected_slot: String = ""
var hovered_slot: String = ""
var hovered_monster_index: int = -1
var list_scroll_y: float = 0.0
var captured_monsters: Array = []

# ============ 动画状态 ============
var anim_state: Dictionary = {
	"show_guide": false,
	"guide_timer": 0.0,
	"assign_pop_scale": 1.0,
	"assign_pop_target": "",
	"power_highlight": 0.0,
	"power_highlight_target": 0.0,
	"slot_glow_phase": 0.0,
	"assign_pop_start_time": 0.0
}

var _confirm_dialog_visible: bool = false

# ============ 槽位配置 ============
const SLOT_KEYS: Array = ["leader", "member1", "member2"]
const SLOT_LABELS: Dictionary = {
	"leader": "队长",
	"member1": "成员1",
	"member2": "成员2"
}

# ============ 生命周期 ============

var _bg_texture: ColorRect

func _add_dark_background() -> void:
	_bg_texture = ColorRect.new()
	_bg_texture.color = Color(0.04, 0.07, 0.15, 1.0)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

func _ready() -> void:
	_add_dark_background()
	_create_ui()
	_setup_ui()
	mouse_filter = Control.MOUSE_FILTER_STOP
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	monster_list_scroll.scroll_vertical = 0
	
	# 确认弹窗按钮
	var confirm_btn: Button = confirm_dialog.get_node_or_null("VBox/ConfirmBtn")
	var continue_btn: Button = confirm_dialog.get_node_or_null("VBox/ContinueBtn")
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_cancel)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_edit)

func _create_ui() -> void:
	# ===== 主容器 VBox =====
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)
	
	# ===== Header =====
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(DESIGN_W, 55)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)
	
	# 返回按钮
	back_button = Button.new()
	back_button.custom_minimum_size = Vector2(60, 35)
	back_button.text = "<<"
	back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(back_button)
	
	var header_spacer1 := Control.new()
	header_spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer1)
	
	# 标题
	title_label = Label.new()
	title_label.text = "队伍编成"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)
	
	var header_spacer2 := Control.new()
	header_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer2)
	
	# 引导标签
	guide_label = Label.new()
	guide_label.text = "点击下方怪兽加入队伍"
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_label.modulate.a = 0.0
	header.add_child(guide_label)
	
	# ===== 战力显示区域 =====
	var power_section := PanelContainer.new()
	power_section.custom_minimum_size = Vector2(DESIGN_W, 30)
	var power_style := StyleBoxFlat.new()
	power_style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	power_style.corner_radius_top_left = 6
	power_style.corner_radius_top_right = 6
	power_style.corner_radius_bottom_left = 6
	power_style.corner_radius_bottom_right = 6
	power_section.add_theme_stylebox_override("panel", power_style)
	vbox.add_child(power_section)
	
	var power_margin := MarginContainer.new()
	power_margin.add_theme_constant_override("margin_left", 10)
	power_margin.add_theme_constant_override("margin_right", 10)
	power_section.add_child(power_margin)
	
	power_label = Label.new()
	power_label.text = "队伍总战力: 0"
	power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	power_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	power_margin.add_child(power_label)
	
	# ===== 队伍槽位区域 =====
	var team_slots := VBoxContainer.new()
	team_slots.custom_minimum_size = Vector2(DESIGN_W, 125)
	team_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(team_slots)
	
	# 队长槽位
	leader_slot_container = HBoxContainer.new()
	leader_slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
	team_slots.add_child(leader_slot_container)
	
	var leader_slot := _create_team_slot("leader", 100, 120)
	leader_slot_container.add_child(leader_slot)
	
	# 成员槽位
	member_slots_container = HBoxContainer.new()
	member_slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	team_slots.add_child(member_slots_container)
	
	var spacer_left := Control.new()
	spacer_left.custom_minimum_size = Vector2(50, 0)
	member_slots_container.add_child(spacer_left)
	
	var member1_slot := _create_team_slot("member1", 80, 100)
	member_slots_container.add_child(member1_slot)
	
	var spacer_mid := Control.new()
	spacer_mid.custom_minimum_size = Vector2(20, 0)
	member_slots_container.add_child(spacer_mid)
	
	var member2_slot := _create_team_slot("member2", 80, 100)
	member_slots_container.add_child(member2_slot)
	
	var spacer_right := Control.new()
	spacer_right.custom_minimum_size = Vector2(50, 0)
	member_slots_container.add_child(spacer_right)
	
	# ===== 怪兽列表区域 =====
	monster_list_scroll = ScrollContainer.new()
	monster_list_scroll.custom_minimum_size = Vector2(DESIGN_W, DESIGN_H - 95.0 - 200.0)
	monster_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(monster_list_scroll)
	
	monster_list_grid = GridContainer.new()
	monster_list_grid.columns = 4
	monster_list_grid.add_theme_constant_override("h_separation", 10)
	monster_list_grid.add_theme_constant_override("v_separation", 10)
	monster_list_grid.custom_minimum_size.x = DESIGN_W
	monster_list_scroll.add_child(monster_list_grid)
	
	# ===== 底部按钮区域 =====
	var buttons := HBoxContainer.new()
	buttons.custom_minimum_size = Vector2(DESIGN_W, 55)
	buttons.add_theme_constant_override("separation", 20)
	vbox.add_child(buttons)
	
	cancel_button = Button.new()
	cancel_button.custom_minimum_size = Vector2(100, 45)
	cancel_button.text = "取消"
	cancel_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(cancel_button)
	
	var btn_spacer := Control.new()
	btn_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(btn_spacer)
	
	save_button = Button.new()
	save_button.custom_minimum_size = Vector2(140, 45)
	save_button.text = "保存"
	save_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(save_button)
	
	# ===== 确认对话框 =====
	confirm_dialog = PanelContainer.new()
	confirm_dialog.visible = false
	confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	var dialog_style := StyleBoxFlat.new()
	dialog_style.bg_color = Color(0.12, 0.12, 0.2, 0.95)
	dialog_style.border_width_left = 2
	dialog_style.border_width_right = 2
	dialog_style.border_width_top = 2
	dialog_style.border_width_bottom = 2
	dialog_style.border_color = Color(0.3, 0.3, 0.5, 1.0)
	dialog_style.corner_radius_top_left = 8
	dialog_style.corner_radius_top_right = 8
	dialog_style.corner_radius_bottom_left = 8
	dialog_style.corner_radius_bottom_right = 8
	confirm_dialog.add_theme_stylebox_override("panel", dialog_style)
	add_child(confirm_dialog)
	
	var dialog_vbox := VBoxContainer.new()
	dialog_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_dialog.add_child(dialog_vbox)
	
	var dialog_msg := Label.new()
	dialog_msg.text = "确定返回主界面吗？"
	dialog_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_vbox.add_child(dialog_msg)
	
	var dialog_btns := HBoxContainer.new()
	dialog_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	dialog_btns.add_theme_constant_override("separation", 20)
	dialog_vbox.add_child(dialog_btns)
	
	var confirm_btn := Button.new()
	confirm_btn.custom_minimum_size = Vector2(100, 40)
	confirm_btn.text = "确认"
	confirm_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_btns.add_child(confirm_btn)
	
	var continue_btn := Button.new()
	continue_btn.custom_minimum_size = Vector2(100, 40)
	continue_btn.text = "继续编辑"
	continue_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_btns.add_child(continue_btn)

func _create_team_slot(slot_key: String, w: float, h: float) -> Control:
	var slot := PanelContainer.new()
	slot.name = "Slot_%s" % slot_key
	slot.custom_minimum_size = Vector2(w, h)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.6, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	slot.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	# SlotLabel (槽位标识)
	var slot_lbl := Label.new()
	slot_lbl.name = "SlotLabel"
	slot_lbl.text = SLOT_LABELS.get(slot_key, slot_key)
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(slot_lbl)
	
	# EmojiLabel
	var emoji_lbl := Label.new()
	emoji_lbl.name = "EmojiLabel"
	emoji_lbl.text = "?"
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(emoji_lbl)
	
	# NameLabel
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "空槽位"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_lbl)
	
	# LevelLabel
	var level_lbl := Label.new()
	level_lbl.name = "LevelLabel"
	level_lbl.text = ""
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(level_lbl)
	
	# NatureLabel
	var nature_lbl := Label.new()
	nature_lbl.name = "NatureLabel"
	nature_lbl.text = ""
	nature_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nature_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(nature_lbl)
	
	# ElementLabel
	var element_lbl := Label.new()
	element_lbl.name = "ElementLabel"
	element_lbl.text = ""
	element_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(element_lbl)
	
	# SkillLabel (队长技能)
	var skill_lbl := Label.new()
	skill_lbl.name = "SkillLabel"
	skill_lbl.text = ""
	skill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(skill_lbl)
	
	# EmptyLabel
	var empty_lbl := Label.new()
	empty_lbl.name = "EmptyLabel"
	empty_lbl.text = ""
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(empty_lbl)
	
	# SelectedBorder (选中边框)
	var border := PanelContainer.new()
	border.name = "SelectedBorder"
	border.visible = false
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 3
	border_style.border_width_right = 3
	border_style.border_width_top = 3
	border_style.border_width_bottom = 3
	border_style.border_color = Color(1.0, 0.85, 0.0, 1.0)
	border_style.corner_radius_top_left = 8
	border_style.corner_radius_top_right = 8
	border_style.corner_radius_bottom_left = 8
	border_style.corner_radius_bottom_right = 8
	border.add_theme_stylebox_override("panel", border_style)
	slot.add_child(border)
	
	return slot

func _setup_ui() -> void:
	confirm_dialog.visible = false

func init(data: Dictionary = {}) -> void:
	print("[SceneTeam] 队伍编成初始化")
	
	# 获取游戏管理器
	game_manager = get_node_or_null("/root/GameManager")
	
	# 加载队伍数据
	var SaveManager = load("res://src/core/save_manager.gd")
	if SaveManager and SaveManager.instance:
		team = SaveManager.instance.load_team().duplicate(true)
	else:
		team = {"leader": null, "member1": null, "member2": null}
	
	list_scroll_y = 0.0
	monster_list_scroll.scroll_vertical = 0
	selected_slot = ""
	hovered_slot = ""
	hovered_monster_index = -1
	
	# 检查是否有收服怪物
	captured_monsters = _get_captured_monsters()
	anim_state["show_guide"] = captured_monsters.size() == 0
	anim_state["guide_timer"] = 0.0
	
	_update_ui()

func _get_captured_monsters() -> Array:
	var captured: Array = []
	var SaveManager = load("res://src/core/save_manager.gd")
	if SaveManager and SaveManager.instance:
		var player = SaveManager.instance.load_player()
		captured = player.get("captured", [])
	return captured

func _process(delta: float) -> void:
	# 引导提示闪烁
	if anim_state["show_guide"]:
		anim_state["guide_timer"] += delta
	
	# 槽位发光动画
	anim_state["slot_glow_phase"] += delta * 4.0
	
	# 分配弹跳动画（easeOutBack缓动）
	if anim_state["assign_pop_scale"] != 1.0 and anim_state["assign_pop_target"] != "":
		var elapsed := _get_assign_pop_elapsed()
		var duration := 0.3
		if elapsed < duration:
			var t := elapsed / duration
			if t < 0.5:
				anim_state["assign_pop_scale"] = 1.3 - 0.3 * (t * 2.0)
			else:
				var t2 := (t - 0.5) * 2.0
				anim_state["assign_pop_scale"] = 1.0 + 0.05 * sin(t2 * PI)
		else:
			anim_state["assign_pop_scale"] = 1.0
	
	# 战力达标高亮过渡
	var should_highlight := _check_power_ready()
	anim_state["power_highlight_target"] = 1.0 if should_highlight else 0.0
	var target: float = anim_state["power_highlight_target"]
	var current: float = anim_state["power_highlight"]
	if absf(current - target) > 0.01:
		var speed := 3.0 * get_process_delta_time()
		if current < target:
			anim_state["power_highlight"] = minf(current + speed, target)
		else:
			anim_state["power_highlight"] = maxf(current - speed, target)

func _get_assign_pop_elapsed() -> float:
	if anim_state["assign_pop_start_time"] == 0.0:
		return 0.0
	return (Time.get_ticks_msec() - anim_state["assign_pop_start_time"]) / 1000.0

# ============ 事件处理 ============
func _gui_input(event: InputEvent) -> void:
	if _confirm_dialog_visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_confirm_dialog_tap(event.position)
			accept_event()
		elif event is InputEventScreenTouch and event.pressed:
			_handle_confirm_dialog_tap(event.position)
			accept_event()
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_tap(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_handle_tap(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		if event.relative.y < -10:
			_scroll_list(1)
		elif event.relative.y > 10:
			_scroll_list(-1)
		accept_event()

func _handle_tap(pos: Vector2) -> void:
	if _confirm_dialog_visible:
		_handle_confirm_dialog_tap(pos)
		return
	
	# 返回按钮区域检测
	if pos.x >= 15 and pos.x <= 75 and pos.y >= 15 and pos.y <= 50:
		game_manager.scene_manager.change_scene("main", {}, "slide")
		return
	
	# 保存按钮区域
	var save_rect := Rect2(DESIGN_W - 160, DESIGN_H - 80, 140, 45)
	if save_rect.has_point(pos):
		_on_save_pressed()
		return
	
	# 取消按钮区域
	var cancel_rect := Rect2(20, DESIGN_H - 80, 100, 45)
	if cancel_rect.has_point(pos):
		_show_confirm_dialog()
		return
	
	# 槽位点击检测
	for slot_key in SLOT_KEYS:
		var slot_rect: Rect2 = _get_slot_rect(slot_key)
		if slot_rect.has_point(pos):
			_handle_slot_tap(slot_key)
			return
	
	# 怪物列表点击检测
	var monster_index := _get_monster_index_at_pos(pos)
	if monster_index >= 0 and monster_index < captured_monsters.size():
		_assign_to_slot(captured_monsters[monster_index])

func _handle_slot_tap(slot_key: String) -> void:
	if team[slot_key] != null:
		team[slot_key] = null
		if selected_slot == slot_key:
			selected_slot = ""
	else:
		selected_slot = "" if selected_slot == slot_key else slot_key
	_update_ui()

func _scroll_list(direction: int) -> void:
	var step := 105.0
	var max_scroll := _get_max_list_scroll()
	list_scroll_y = clamp(list_scroll_y + direction * step, 0.0, max_scroll)
	monster_list_scroll.scroll_vertical = int(list_scroll_y)

func _get_max_list_scroll() -> float:
	var rows: float = ceil(captured_monsters.size() / 4.0)
	var content_h: float = rows * 105.0 - 10.0
	var view_h: float = DESIGN_H - 95.0 - 200.0
	return maxf(0.0, content_h - view_h)

func _get_monster_index_at_pos(pos: Vector2) -> int:
	# 用 ScrollContainer 和 GridContainer 的实际位置
	if not monster_list_grid or not monster_list_scroll:
		return -1
	
	# 计算网格相对场景的位置
	var node := monster_list_grid as Control
	var accum_pos := Vector2.ZERO
	while node and node != self:
		accum_pos += node.position
		node = node.get_parent() as Control
	
	var list_x := accum_pos.x
	var list_y := accum_pos.y - list_scroll_y
	var list_bottom_y := accum_pos.y + monster_list_scroll.size.y
	
	if pos.y < accum_pos.y or pos.y > list_bottom_y:
		return -1
	
	var rel_x := pos.x - list_x
	var rel_y := pos.y - list_y
	
	var col := int(floor(rel_x / 95.0))
	var row := int(floor(rel_y / 105.0))
	var index := row * 4 + col
	
	if col < 0 or col >= 4:
		return -1
	
	return index

func _assign_to_slot(monster_id: String) -> void:
	if selected_slot == "":
		for slot_key in SLOT_KEYS:
			if team[slot_key] == null:
				team[slot_key] = monster_id
				_trigger_assign_pop(slot_key)
				selected_slot = ""
				_update_ui()
				return
		team["leader"] = monster_id
		_trigger_assign_pop("leader")
		selected_slot = ""
	else:
		var existing: Variant = team[selected_slot]
		team[selected_slot] = monster_id
		for slot_key in SLOT_KEYS:
			if slot_key != selected_slot and team[slot_key] == monster_id:
				team[slot_key] = existing
				break
		_trigger_assign_pop(selected_slot)
		selected_slot = ""
	_update_ui()

func _trigger_assign_pop(slot_key: String) -> void:
	anim_state["assign_pop_target"] = slot_key
	anim_state["assign_pop_scale"] = 1.3
	anim_state["assign_pop_start_time"] = Time.get_ticks_msec()

func _show_confirm_dialog() -> void:
	_confirm_dialog_visible = true
	confirm_dialog.visible = true

func _hide_confirm_dialog() -> void:
	_confirm_dialog_visible = false
	confirm_dialog.visible = false

func _handle_confirm_dialog_tap(pos: Vector2) -> void:
	if not confirm_dialog:
		return
	# 简单检测：确认弹窗在场景中心
	var dialog_size := Vector2(250, 150)
	var dialog_pos := (Vector2(DESIGN_W, DESIGN_H) - dialog_size) / 2.0
	var confirm_btn_rect := Rect2(dialog_pos.x + 15, dialog_pos.y + 100, 100, 40)
	var continue_btn_rect := Rect2(dialog_pos.x + 135, dialog_pos.y + 100, 100, 40)
	
	if confirm_btn_rect.has_point(pos):
		_hide_confirm_dialog()
		game_manager.scene_manager.change_scene("main", {}, "slide")
	elif continue_btn_rect.has_point(pos):
		_hide_confirm_dialog()
	elif Rect2(dialog_pos, dialog_size).has_point(pos):
		pass  # 点击弹窗内部但不按钮，不做处理
	else:
		# 点击弹窗外部也关闭
		_hide_confirm_dialog()

func _on_confirm_cancel() -> void:
	_hide_confirm_dialog()
	game_manager.scene_manager.change_scene("main", {}, "slide")

func _on_continue_edit() -> void:
	_hide_confirm_dialog()

func _on_back_pressed() -> void:
	game_manager.scene_manager.change_scene("main", {}, "slide")

func _on_save_pressed() -> void:
	_save_team()
	game_manager.scene_manager.change_scene("main", {}, "slide")

func _on_cancel_pressed() -> void:
	_show_confirm_dialog()

func _save_team() -> void:
	var SaveManager = load("res://src/core/save_manager.gd")
	if SaveManager and SaveManager.instance:
		SaveManager.instance.save_team(team)
	print("[SceneTeam] 队伍已保存: ", team)

# ============ UI 更新 ============
func _update_ui() -> void:
	_update_team_slots()
	_update_monster_list()
	_update_power_display()
	_update_guide()
	_update_buttons()

func _update_team_slots() -> void:
	var MonsterDB = load("res://src/data/monster_db.gd")
	var SaveManager = load("res://src/core/save_manager.gd")
	
	for slot_key in SLOT_KEYS:
		var slot_container: HBoxContainer
		if slot_key == "leader":
			slot_container = leader_slot_container
		else:
			slot_container = member_slots_container
		
		var slot_node: Control = slot_container.get_node_or_null("Slot_%s" % slot_key)
		if not slot_node:
			continue
		
		var monster_id = team.get(slot_key)
		
		var emoji_label: Label = slot_node.get_node_or_null("EmojiLabel")
		var name_label: Label = slot_node.get_node_or_null("NameLabel")
		var level_label: Label = slot_node.get_node_or_null("LevelLabel")
		var nature_label: Label = slot_node.get_node_or_null("NatureLabel")
		var element_label: Label = slot_node.get_node_or_null("ElementLabel")
		var skill_label: Label = slot_node.get_node_or_null("SkillLabel")
		
		if monster_id and MonsterDB:
			var monster_data = MonsterDB.get_monster(monster_id)
			var player_level := 1
			var player_nature := ""
			
			if SaveManager and SaveManager.instance:
				var player = SaveManager.instance.load_player()
				if player.has("pokedex") and player["pokedex"].has(monster_id):
					player_level = player["pokedex"][monster_id].get("level", 1)
					player_nature = player["pokedex"][monster_id].get("nature", "")
			
			if emoji_label:
				emoji_label.text = monster_data.get("emoji", "❓") if monster_data else "❓"
			if name_label:
				name_label.text = monster_data.get("name", "未知") if monster_data else "未知"
			if level_label:
				level_label.text = "Lv.%d" % player_level
			if nature_label:
				nature_label.text = player_nature
			if element_label:
				element_label.text = _get_element_name(monster_data.get("element", "fire")) if monster_data else ""
			
			if slot_key == "leader" and monster_data and monster_data.has("leader_skill"):
				var LeaderSkillDB = load("res://src/data/leader_skill_db.gd")
				if LeaderSkillDB:
					var skill = LeaderSkillDB.get_skill(monster_data["leader_skill"])
					if skill_label:
						skill_label.text = "%s %s" % [skill.get("icon", "⭐"), skill.get("name", "队长技")] if skill else ""
		
		if slot_node.has_node("SelectedBorder"):
			var border: Control = slot_node.get_node("SelectedBorder")
			border.visible = (selected_slot == slot_key)

func _update_monster_list() -> void:
	for child in monster_list_grid.get_children():
		child.queue_free()
	
	var MonsterDB = load("res://src/data/monster_db.gd")
	var SaveManager = load("res://src/core/save_manager.gd")
	
	for i in range(captured_monsters.size()):
		var monster_id = captured_monsters[i]
		var monster_data = null
		if MonsterDB:
			monster_data = MonsterDB.get_monster(monster_id)
		
		var player_level := 1
		var player_nature := ""
		if SaveManager and SaveManager.instance:
			var player = SaveManager.instance.load_player()
			if player.has("pokedex") and player["pokedex"].has(monster_id):
				player_level = player["pokedex"][monster_id].get("level", 1)
				player_nature = player["pokedex"][monster_id].get("nature", "")
		
		var card := _create_monster_card(monster_id, monster_data, player_level, player_nature)
		monster_list_grid.add_child(card)

func _create_monster_card(monster_id: String, monster_data: Dictionary, level: int, nature: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(85, 95)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	card.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	var emoji := Label.new()
	emoji.text = monster_data.get("emoji", "❓") if monster_data else "❓"
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.add_theme_font_size_override("font_size", 24)
	vbox.add_child(emoji)
	
	var name := Label.new()
	name.text = monster_data.get("name", "未知") if monster_data else "未知"
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name)
	
	var level_lbl := Label.new()
	level_lbl.text = "Lv.%d" % level
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(level_lbl)
	
	var element: String = monster_data.get("element", "fire") if monster_data else "fire"
	var rarity: int = monster_data.get("rarity", 1) if monster_data else 1
	var attr_lbl := Label.new()
	attr_lbl.text = "%s %s" % [_get_element_name(element), "★".repeat(rarity)]
	attr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(attr_lbl)
	
	var in_team := _is_monster_in_team(monster_id)
	if in_team:
		card.add_theme_stylebox_override("panel", _get_in_team_style())
	
	return card

func _get_in_team_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.85, 0.0, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _is_monster_in_team(monster_id: String) -> bool:
	return team.values().has(monster_id)

func _get_slot_rect(slot_key: String) -> Rect2:
	# 用实际节点位置
	var slot_container: HBoxContainer
	if slot_key == "leader":
		slot_container = leader_slot_container
	else:
		slot_container = member_slots_container
	
	var slot_node: Control = slot_container.get_node_or_null("Slot_%s" % slot_key)
	if slot_node:
		# _gui_input 坐标是相对于当前 Control 的
		# slot_node 的 position 是相对于父容器
		# 用 get_rect() 获取在父容器中的位置，再累计到场景坐标
		var node := slot_node
		var accum_pos := Vector2.ZERO
		while node and node != self:
			accum_pos += node.position
			node = node.get_parent() as Control
		return Rect2(accum_pos, slot_node.size)
	
	# fallback
	match slot_key:
		"leader":
			return Rect2(DESIGN_W / 2.0 - 50, 85, 100, 120)
		"member1":
			return Rect2(DESIGN_W / 2.0 - 140, 210, 80, 100)
		"member2":
			return Rect2(DESIGN_W / 2.0 + 60, 210, 80, 100)
	return Rect2()

func _get_slot_key_for_monster(monster_id: String) -> String:
	for slot_key in SLOT_KEYS:
		if team.get(slot_key) == monster_id:
			return slot_key
	return ""

func _update_power_display() -> void:
	var power := _calc_team_power()
	var is_ready := _check_power_ready()
	
	if power_label:
		power_label.text = "队伍总战力: %d" % power
		if is_ready:
			var highlight: float = anim_state["power_highlight"]
			var r := int(170.0 - 170.0 * highlight)
			var g := int(170.0 + 85.0 * highlight)
			power_label.add_theme_color_override("font_color", Color(r / 255.0, g / 255.0, 50.0 / 255.0))

func _update_guide() -> void:
	if guide_label:
		guide_label.visible = anim_state["show_guide"]
		if anim_state["show_guide"]:
			var alpha := 0.6 + sin(anim_state["guide_timer"] * 3.0) * 0.4
			guide_label.modulate.a = alpha

func _update_buttons() -> void:
	pass

func _get_monster_data(monster_id: String) -> Dictionary:
	if not monster_id:
		return {}
	var MonsterDB = load("res://src/data/monster_db.gd")
	if MonsterDB:
		var result: Dictionary = MonsterDB.get_monster(monster_id)
		if result.is_empty():
			return {}
		return result
	return {}

func _calc_team_power() -> int:
	var power := 0
	var MonsterDB = load("res://src/data/monster_db.gd")
	var SaveManager = load("res://src/core/save_manager.gd")
	
	for slot_key in SLOT_KEYS:
		var monster_id = team.get(slot_key)
		if not monster_id:
			continue
		var monster_data = _get_monster_data(monster_id)
		if monster_data.is_empty():
			continue
		
		var real_level := 1
		var nature_id := ""
		
		if SaveManager and SaveManager.instance:
			var player = SaveManager.instance.load_player()
			if player.has("pokedex") and player["pokedex"].has(monster_id):
				real_level = player["pokedex"][monster_id].get("level", 1)
				nature_id = player["pokedex"][monster_id].get("nature", "")
		
		var stats = _get_monster_stats(monster_id, real_level, nature_id)
		if stats.size() >= 4:
			power += stats[0] + stats[1] + stats[2] + stats[3]
	
	return power

func _get_monster_stats(monster_id: String, level: int, nature_id: String) -> Array:
	var monster_data = _get_monster_data(monster_id)
	if monster_data.is_empty():
		return [0, 0, 0, 0]
	
	var base_hp: int = monster_data.get("baseHP", 100)
	var base_atk: int = monster_data.get("baseATK", 10)
	var base_def: int = monster_data.get("baseDEF", 10)
	var base_spd: int = monster_data.get("baseSPD", 10)
	
	return [base_hp, base_atk, base_def, base_spd]

func _check_power_ready() -> bool:
	if captured_monsters.size() == 0:
		return false
	return team.get("leader") != null

func _get_element_name(element: String) -> String:
	var names: Dictionary = {
		"fire": "火", "water": "水", "grass": "草", "thunder": "雷",
		"light": "光", "earth": "土", "wind": "风", "dark": "暗"
	}
	return names.get(element, element)

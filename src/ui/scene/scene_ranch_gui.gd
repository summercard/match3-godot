# scene_ranch_gui.gd - 可在 Godot 编辑器中调整的精灵牧场界面控制器
# 玩法与存档逻辑沿用 SceneRanch；此脚本仅将动态数据绑定到 .tscn 节点。
class_name SceneRanchGui
extends "res://src/ui/scene/scene_ranch.gd"

const RANCH_CARD_PATHS := [
	"Pages/RanchPage/RosterPanel/Card1",
	"Pages/RanchPage/RosterPanel/Card2",
	"Pages/RanchPage/RosterPanel/Card3",
	"Pages/RanchPage/RosterPanel/Card4",
	"Pages/RanchPage/RosterPanel/Card5",
	"Pages/RanchPage/RosterPanel/Card6",
]
const CLASS_CARD_PATHS := [
	"Pages/ClassroomPage/RosterPanel/Card1",
	"Pages/ClassroomPage/RosterPanel/Card2",
	"Pages/ClassroomPage/RosterPanel/Card3",
]
const SOCIAL_CARD_PATHS := [
	"Pages/SocialPage/RosterPanel/Card1",
	"Pages/SocialPage/RosterPanel/Card2",
	"Pages/SocialPage/RosterPanel/Card3",
]
const SLOT_PATHS := [
	"Pages/RanchPage/Slots/Slot1",
	"Pages/RanchPage/Slots/Slot2",
	"Pages/RanchPage/Slots/Slot3",
	"Pages/RanchPage/Slots/Slot4",
	"Pages/RanchPage/Slots/Slot5",
]
const TEXT_WHITE := Color(1.0, 1.0, 1.0)
const TEXT_MUTED := Color(0.66, 0.72, 0.82)
const TEXT_GOLD := Color(1.0, 0.84, 0.25)

var _gui_tick: float = 0.0

func _ready() -> void:
	super._ready()
	_ensure_pet_farm_layout()
	_connect_gui_actions()
	_sync_gui()

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_sync_gui()

func initialize(game: Node) -> void:
	super.initialize(game)
	_sync_gui()

func _process(delta: float) -> void:
	_time += delta
	if _status_timer > 0.0:
		_status_timer = maxf(0.0, _status_timer - delta)
	_gui_tick += delta
	if _gui_tick >= 0.25:
		_gui_tick = 0.0
		_sync_dynamic_gui()

func _draw() -> void:
	# Runtime visuals are provided by ranch_hub.tscn nodes, not Canvas drawing.
	pass

func _gui_input(_event: InputEvent) -> void:
	# TextureButtons in the editable scene own all touch input.
	pass

func _connect_gui_actions() -> void:
	_connect_button("Header/BackButton", _on_back_button_pressed)
	_connect_button("Pages/RanchPage/CollectRow/CollectButton", _on_collect_button_pressed)
	_connect_button("Pages/RanchPage/BottomButtons/FocusButton", _on_focus_button_pressed)
	_connect_button("Pages/RanchPage/BottomButtons/ClassroomButton", _switch_to_classroom)
	_connect_button("Pages/RanchPage/BottomButtons/SocialButton", _switch_to_social)
	_connect_button("Pages/RanchPage/RosterPanel/PreviousButton", _on_ranch_previous_pressed)
	_connect_button("Pages/RanchPage/RosterPanel/NextButton", _on_ranch_next_pressed)
	for i in SLOT_PATHS.size():
		_connect_button(SLOT_PATHS[i], _on_ranch_slot_pressed.bind(i))
	for i in RANCH_CARD_PATHS.size():
		_connect_button(RANCH_CARD_PATHS[i], _on_ranch_card_pressed.bind(i))

	_connect_button("Pages/ClassroomPage/DetailPanel/EvolveButton", _on_evolve_button_pressed)
	_connect_button("Pages/ClassroomPage/BottomButtons/RanchButton", _switch_to_ranch)
	_connect_button("Pages/ClassroomPage/BottomButtons/SocialButton", _switch_to_social)
	_connect_button("Pages/ClassroomPage/RosterPanel/PreviousButton", _on_class_previous_pressed)
	_connect_button("Pages/ClassroomPage/RosterPanel/NextButton", _on_class_next_pressed)
	for i in CLASS_CARD_PATHS.size():
		_connect_button(CLASS_CARD_PATHS[i], _on_class_card_pressed.bind(i))

	_connect_button("Pages/SocialPage/PlacePanel/SwitchButton", _on_place_switch_pressed)
	_connect_button("Pages/SocialPage/PlacePanel/SlotA", _on_social_slot_pressed.bind("slot_a"))
	_connect_button("Pages/SocialPage/PlacePanel/SlotB", _on_social_slot_pressed.bind("slot_b"))
	_connect_button("Pages/SocialPage/BottomButtons/ClassroomButton", _switch_to_classroom)
	_connect_button("Pages/SocialPage/BottomButtons/ActionButton", _on_social_action_pressed)
	_connect_button("Pages/SocialPage/RosterPanel/PreviousButton", _on_class_previous_pressed)
	_connect_button("Pages/SocialPage/RosterPanel/NextButton", _on_class_next_pressed)
	_connect_button("Pages/SocialPage/ResultPopup/ConfirmButton", _on_result_confirm_pressed)
	var result_shade := get_node("Pages/SocialPage/ResultPopup/Shade") as Control
	if not result_shade.gui_input.is_connected(_on_result_shade_input):
		result_shade.gui_input.connect(_on_result_shade_input)
	for i in SOCIAL_CARD_PATHS.size():
		_connect_button(SOCIAL_CARD_PATHS[i], _on_social_card_pressed.bind(i))

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _on_back_button_pressed() -> void:
	if _active_page == "ranch":
		_go_to_scene("main")
	else:
		_switch_to_ranch()

func _on_collect_button_pressed() -> void:
	_on_collect_pressed()
	_sync_gui()

func _on_focus_button_pressed() -> void:
	_toggle_care_focus_selected()
	_sync_gui()

func _on_ranch_slot_pressed(index: int) -> void:
	_select_slot(index)
	_collect_slot(index)
	_sync_gui()

func _on_ranch_card_pressed(visible_index: int) -> void:
	var idx := _list_page * RANCH_CARD_PATHS.size() + visible_index
	if idx < _captured_monsters.size():
		_on_picker_item_pressed(_get_instance_id(_captured_monsters[idx]))
		_sync_gui()

func _on_ranch_previous_pressed() -> void:
	_change_list_page(-1)
	_sync_gui()

func _on_ranch_next_pressed() -> void:
	_change_list_page(1)
	_sync_gui()

func _on_class_previous_pressed() -> void:
	_class_page = clampi(_class_page - 1, 0, _class_max_page)
	_sync_gui()

func _on_class_next_pressed() -> void:
	_class_page = clampi(_class_page + 1, 0, _class_max_page)
	_sync_gui()

func _on_class_card_pressed(visible_index: int) -> void:
	var idx := _class_page * CLASS_CARD_PATHS.size() + visible_index
	if idx < _captured_monsters.size():
		_class_selected_instance_id = _get_instance_id(_captured_monsters[idx])
		_sync_gui()

func _on_evolve_button_pressed() -> void:
	_on_evolve_pressed()
	_sync_gui()

func _on_place_switch_pressed() -> void:
	_cycle_social_place()
	_sync_gui()

func _on_social_slot_pressed(slot_key: String) -> void:
	_select_or_clear_social_slot(slot_key)
	_sync_gui()

func _on_social_card_pressed(visible_index: int) -> void:
	var idx := _class_page * SOCIAL_CARD_PATHS.size() + visible_index
	if idx < _captured_monsters.size():
		_assign_social_instance(_get_instance_id(_captured_monsters[idx]))
		_sync_gui()

func _on_social_action_pressed() -> void:
	_try_social_action()
	_sync_gui()

func _on_result_confirm_pressed() -> void:
	_social_result_popup = {}
	_sync_gui()

func _on_result_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_result_confirm_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		_on_result_confirm_pressed()

func _switch_to_ranch() -> void:
	super._switch_to_ranch()
	_sync_gui()

func _switch_to_classroom() -> void:
	super._switch_to_classroom()
	_sync_gui()

func _switch_to_social() -> void:
	super._switch_to_social()
	_sync_gui()

func _refresh_ranch_view() -> void:
	super._refresh_ranch_view()
	_sync_gui()

func _show_status(text: String) -> void:
	super._show_status(text)
	_sync_status()

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Pages"):
		return
	_node("Pages/RanchPage").visible = _active_page == "ranch"
	_node("Pages/ClassroomPage").visible = _active_page == "classroom"
	_node("Pages/SocialPage").visible = _active_page == "social"
	var title := "宠物农场"
	if _active_page == "classroom":
		title = "怪物课堂"
	elif _active_page == "social":
		title = "社交庭院"
	_label("Header/Title").text = title
	_sync_status()
	if _active_page == "ranch":
		_sync_ranch_page()
	elif _active_page == "classroom":
		_sync_classroom_page()
	else:
		_sync_social_page()
	_sync_result_popup()

func _sync_dynamic_gui() -> void:
	_sync_status()
	if _active_page == "ranch":
		_sync_ranch_slots()
		_sync_collect_row()
	elif _active_page == "social":
		_sync_social_place()
	_sync_result_popup()

func _sync_status() -> void:
	var status := get_node_or_null("Header/Status") as Label
	var feedback_visible := _status_timer > 0.0 and not _status_text.is_empty()
	if status != null:
		status.visible = feedback_visible and _active_page == "ranch"
		status.text = _status_text
		status.modulate.a = minf(1.0, _status_timer) if status.visible else 0.0
	_sync_subpage_ribbon("Pages/ClassroomPage/Ribbon/RibbonText", "培养与进化", feedback_visible and _active_page == "classroom")
	_sync_subpage_ribbon("Pages/SocialPage/Ribbon/RibbonText", "交流活动", feedback_visible and _active_page == "social")

func _sync_subpage_ribbon(path: String, default_text: String, show_feedback: bool) -> void:
	var ribbon_text := get_node_or_null(path) as Label
	if ribbon_text == null:
		return
	ribbon_text.text = _status_text if show_feedback else default_text
	ribbon_text.add_theme_color_override("font_color", TEXT_GOLD if show_feedback else TEXT_MUTED)

func _sync_ranch_page() -> void:
	_sync_ranch_slots()
	_sync_collect_row()
	var focus := get_node("Pages/RanchPage/BottomButtons/FocusButton") as TextureButton
	_button_label(focus).text = "取消专注" if not _care_focus_instance_id.is_empty() else "专注培养"
	_sync_card_strip(RANCH_CARD_PATHS, _list_page * RANCH_CARD_PATHS.size(), "ranch")
	_sync_page_buttons("Pages/RanchPage/RosterPanel", _list_page, _max_list_page)
	_sync_roster_pagination()

func _sync_ranch_slots() -> void:
	for i in SLOT_PATHS.size():
		var slot_node := get_node(SLOT_PATHS[i]) as TextureButton
		var slot: Dictionary = _slots_data[i] if i < _slots_data.size() else {}
		var instance_id := str(slot.get("instance_id", ""))
		var occupied := not instance_id.is_empty() and MonsterDb.has_monster(_get_monster_id(instance_id))
		var slot_frame := slot_node.get_node_or_null("FarmFrame") as TextureRect
		if slot_frame == null:
			slot_frame = TextureRect.new()
			slot_frame.name = "FarmFrame"
			slot_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			slot_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			slot_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slot_node.add_child(slot_frame)
			slot_node.move_child(slot_frame, 0)
		slot_frame.texture = _tex(RANCH_ASSETS["slot_occupied"])
		var portrait := slot_node.get_node("Portrait") as TextureRect
		var level := slot_node.get_node("Level") as Label
		var level_badge := slot_node.get_node("LevelBadge") as TextureRect
		var ribbon := slot_node.get_node("Ribbon") as TextureRect
		var status := slot_node.get_node("Status") as Label
		var timer_plate := slot_node.get_node("TimerPlate") as TextureRect
		var timer := slot_node.get_node("Timer") as Label
		var plus := slot_node.get_node("EmptyPlus") as Label
		var empty_text := slot_node.get_node("EmptyText") as Label
		var sparkle := slot_node.get_node("Sparkle") as TextureRect
		portrait.visible = occupied
		level.visible = occupied
		level_badge.visible = occupied
		ribbon.visible = occupied
		status.visible = occupied
		timer_plate.visible = occupied
		timer.visible = occupied
		sparkle.visible = occupied
		plus.visible = not occupied
		empty_text.visible = not occupied
		if occupied:
			portrait.texture = _portrait_texture(instance_id)
			level.text = "Lv.%d" % _get_monster_level(instance_id)
			var care: Dictionary = _care_state_map.get(instance_id, _get_care_state(instance_id))
			var placement_text := _format_elapsed_short(slot.get("placed_at", null))
			if not str(care.get("label", "")).is_empty():
				placement_text = "专注 " + placement_text.trim_prefix("放置 ")
			status.text = "EXP +%d/h" % (60 + _get_monster_level(instance_id) * 10)
			timer.text = placement_text.trim_prefix("放置 ").trim_prefix("专注 ")
		else:
			empty_text.text = "放入这里" if i == _selected_slot else "空位"
			empty_text.modulate = TEXT_GOLD if i == _selected_slot else TEXT_WHITE
			plus.modulate = TEXT_GOLD if i == _selected_slot else Color(0.98, 0.90, 0.67)

func _sync_collect_row() -> void:
	var total_exp := _total_idle_exp()
	var total_coin := total_exp * 1.25
	_label("Pages/RanchPage/CollectRow/ExpValue").text = "+" + _format_count(total_exp)
	_label("Pages/RanchPage/CollectRow/CoinValue").text = "+" + _format_count(total_coin)

func _ensure_pet_farm_layout() -> void:
	_ensure_top_resource_bar()
	_ensure_roster_heading()
	_ensure_six_roster_cards()
	_ensure_roster_pagination()
	_ensure_pet_farm_bottom_nav()
	for path in SLOT_PATHS:
		_ensure_pet_farm_slot(get_node(path) as TextureButton)
	for path in RANCH_CARD_PATHS:
		_style_pet_farm_card(get_node(path) as TextureButton)
	for path in [
		"Pages/RanchPage/BottomButtons/FocusButton",
		"Pages/RanchPage/BottomButtons/ClassroomButton",
		"Pages/RanchPage/BottomButtons/SocialButton",
	]:
		var label := (get_node(path) as TextureButton).get_node("Text") as Label
		label.add_theme_color_override("font_color", Color(0.32, 0.16, 0.03))
	(get_node("Pages/RanchPage/BottomButtons") as Control).visible = false

func _ensure_pet_farm_bottom_nav() -> void:
	if has_node("PetFarmBottomNav"):
		return
	var nav := Control.new()
	nav.name = "PetFarmBottomNav"
	nav.z_index = 12
	nav.position = Vector2(12.0, 600.0)
	nav.size = Vector2(351.0, 65.0)
	add_child(nav)
	var panel := TextureRect.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.texture = _tex(RANCH_ASSETS["pet_farm_nav_panel"])
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav.add_child(panel)
	var specs := [
		["主页", "⌂", "", Callable(self, "_on_pet_farm_home")],
		["宠物", "", RANCH_ASSETS["pet_tab"], Callable(self, "_on_pet_farm_pets")],
		["课堂", "", RANCH_ASSETS["pet_classroom"], Callable(self, "_on_pet_farm_classroom")],
		["广场", "", RANCH_ASSETS["social_plaza"], Callable(self, "_on_pet_farm_social")],
		["菜单", "", RANCH_ASSETS["menu_tab"], Callable(self, "_on_pet_farm_menu")],
	]
	for i in specs.size():
		var button := Button.new()
		button.name = "Nav%d" % (i + 1)
		button.position = Vector2(8.0 + i * 67.0, 4.0)
		button.size = Vector2(67.0, 57.0)
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(specs[i][3])
		nav.add_child(button)
		if i == 1:
			var selected := TextureRect.new()
			selected.position = Vector2(3.0, 1.0)
			selected.size = Vector2(61.0, 59.0)
			selected.texture = _tex(RANCH_ASSETS["pet_farm_nav_selected"])
			selected.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			selected.stretch_mode = TextureRect.STRETCH_SCALE
			selected.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(selected)
		if not str(specs[i][2]).is_empty():
			var icon := TextureRect.new()
			icon.position = Vector2(18.0, 4.0)
			icon.size = Vector2(31.0, 31.0)
			icon.texture = _tex(specs[i][2])
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(icon)
		else:
			var glyph := Label.new()
			glyph.position = Vector2(0.0, 2.0)
			glyph.size = Vector2(67.0, 31.0)
			glyph.text = specs[i][1]
			glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			glyph.add_theme_color_override("font_color", Color(0.52, 0.25, 0.05))
			glyph.add_theme_font_size_override("font_size", 27)
			button.add_child(glyph)
		var text := Label.new()
		text.position = Vector2(0.0, 34.0)
		text.size = Vector2(67.0, 20.0)
		text.text = specs[i][0]
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.add_theme_color_override("font_color", Color(0.36, 0.18, 0.05))
		text.add_theme_font_size_override("font_size", 11)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(text)

func _on_pet_farm_home() -> void:
	_go_to_scene("main")

func _on_pet_farm_pets() -> void:
	_show_status("当前已在宠物农场")

func _on_pet_farm_classroom() -> void:
	_switch_to_classroom()

func _on_pet_farm_social() -> void:
	_switch_to_social()

func _on_pet_farm_menu() -> void:
	_show_status("更多宠物功能正在整理中")

func _ensure_top_resource_bar() -> void:
	if has_node("PetFarmResourceBar"):
		return
	var bar := Control.new()
	bar.name = "PetFarmResourceBar"
	bar.z_index = 9
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var specs := [
		[Rect2(16.0, 14.0, 105.0, 34.0), "★  12,350"],
		[Rect2(127.0, 14.0, 105.0, 34.0), "◆  2,548"],
		[Rect2(238.0, 14.0, 121.0, 34.0), "♥  5  Full"],
	]
	for spec in specs:
		var panel := Panel.new()
		panel.position = spec[0].position
		panel.size = spec[0].size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.95, 0.82, 0.98)
		style.border_color = Color(0.96, 0.69, 0.30, 1.0)
		style.set_border_width_all(2)
		style.set_corner_radius_all(14)
		panel.add_theme_stylebox_override("panel", style)
		bar.add_child(panel)
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.text = spec[1]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.34, 0.17, 0.04))
		label.add_theme_font_size_override("font_size", 12)
		panel.add_child(label)

func _ensure_roster_heading() -> void:
	var panel := get_node("Pages/RanchPage/RosterPanel") as Control
	if panel.has_node("Heading"):
		return
	var heading := Label.new()
	heading.name = "Heading"
	heading.position = Vector2(0.0, 4.0)
	heading.size = Vector2(355.0, 18.0)
	heading.text = "🐾  我的宠物  🐾"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(0.42, 0.21, 0.05))
	heading.add_theme_font_size_override("font_size", 14)
	panel.add_child(heading)
	var hint := Label.new()
	hint.name = "Hint"
	hint.position = Vector2(0.0, 21.0)
	hint.size = Vector2(355.0, 15.0)
	hint.text = "点击宠物，再点击农场空位进行放置"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.48, 0.29, 0.11))
	hint.add_theme_font_size_override("font_size", 9)
	panel.add_child(hint)

func _ensure_six_roster_cards() -> void:
	var panel := get_node("Pages/RanchPage/RosterPanel") as Control
	for i in range(3, 6):
		var name := "Card%d" % (i + 1)
		if panel.has_node(name):
			continue
		var card := (panel.get_node("Card3") as TextureButton).duplicate() as TextureButton
		card.name = name
		panel.add_child(card)
	for i in RANCH_CARD_PATHS.size():
		var card := get_node(RANCH_CARD_PATHS[i]) as TextureButton
		card.position = Vector2(8.0 + i * 57.0, 42.0)
		card.size = Vector2(52.0, 76.0)

func _ensure_roster_pagination() -> void:
	var panel := get_node("Pages/RanchPage/RosterPanel") as Control
	if panel.has_node("Pagination"):
		return
	var pagination := Control.new()
	pagination.name = "Pagination"
	pagination.position = Vector2(126.0, 133.0)
	pagination.size = Vector2(104.0, 13.0)
	pagination.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(pagination)
	for i in 5:
		var dot := Label.new()
		dot.name = "Dot%d" % (i + 1)
		dot.position = Vector2(i * 20.0, 0.0)
		dot.size = Vector2(13.0, 13.0)
		dot.text = "●" if i == 0 else "○"
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.add_theme_color_override("font_color", Color(1.0, 0.62, 0.05) if i == 0 else Color(0.71, 0.45, 0.19))
		dot.add_theme_font_size_override("font_size", 11)
		pagination.add_child(dot)

func _sync_roster_pagination() -> void:
	var pagination := get_node("Pages/RanchPage/RosterPanel/Pagination") as Control
	for i in 5:
		var dot := pagination.get_node("Dot%d" % (i + 1)) as Label
		var active := i == mini(_list_page, 4)
		dot.text = "●" if active else "○"
		dot.add_theme_color_override("font_color", Color(1.0, 0.62, 0.05) if active else Color(0.71, 0.45, 0.19))

func _style_pet_farm_card(card: TextureButton) -> void:
	var frame := card.get_node("Frame") as TextureRect
	frame.size = Vector2(52.0, 76.0)
	var portrait := card.get_node("Portrait") as TextureRect
	portrait.position = Vector2(5.0, 5.0)
	portrait.size = Vector2(42.0, 46.0)
	var name_label := card.get_node("Name") as Label
	name_label.visible = false
	var level := card.get_node("Level") as Label
	level.position = Vector2(2.0, 56.0)
	level.size = Vector2(48.0, 17.0)
	level.add_theme_color_override("font_color", Color(0.40, 0.20, 0.04))
	level.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.84, 1.0))
	level.add_theme_constant_override("outline_size", 1)
	var check := card.get_node("Check") as TextureRect
	check.position = Vector2(37.0, 58.0)
	check.size = Vector2(15.0, 15.0)

func _ensure_pet_farm_slot(slot: TextureButton) -> void:
	if not slot.has_node("LevelBadge"):
		var level_badge := TextureRect.new()
		level_badge.name = "LevelBadge"
		level_badge.position = Vector2(17.0, -17.0)
		level_badge.size = Vector2(72.0, 24.0)
		level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_badge.texture = _tex(RANCH_ASSETS["level_badge"])
		level_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		level_badge.stretch_mode = TextureRect.STRETCH_SCALE
		slot.add_child(level_badge)
		slot.move_child(level_badge, 1)
	if not slot.has_node("TimerPlate"):
		var plate := TextureRect.new()
		plate.name = "TimerPlate"
		plate.position = Vector2(15.0, 113.0)
		plate.size = Vector2(76.0, 22.0)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.texture = _tex(RANCH_ASSETS["timer_plate"])
		plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plate.stretch_mode = TextureRect.STRETCH_SCALE
		slot.add_child(plate)
	if not slot.has_node("Timer"):
		var timer := Label.new()
		timer.name = "Timer"
		timer.position = Vector2(15.0, 113.0)
		timer.size = Vector2(76.0, 22.0)
		timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		timer.add_theme_color_override("font_color", Color(0.36, 0.19, 0.05))
		timer.add_theme_font_size_override("font_size", 9)
		slot.add_child(timer)
	var level := slot.get_node("Level") as Label
	level.position = Vector2(17.0, -16.0)
	level.size = Vector2(72.0, 23.0)
	level.add_theme_color_override("font_color", Color(0.32, 0.17, 0.04))
	level.add_theme_color_override("font_outline_color", Color(1.0, 0.95, 0.78, 1.0))
	level.add_theme_constant_override("outline_size", 1)

func _sync_classroom_page() -> void:
	var instance_id := _class_selected_instance_id
	if instance_id.is_empty() and not _captured_monsters.is_empty():
		instance_id = _get_instance_id(_captured_monsters[0])
	var panel := _node("Pages/ClassroomPage/DetailPanel")
	var portrait := panel.get_node("Portrait") as TextureRect
	var empty := panel.get_node("Empty") as Label
	var evolve := panel.get_node("EvolveButton") as TextureButton
	if instance_id.is_empty():
		portrait.visible = false
		empty.visible = true
		evolve.disabled = true
		_set_action_frame(evolve, false)
	else:
		var instance := _get_instance(instance_id)
		var monster_id := str(instance.get("monsterId", _get_monster_id(instance_id)))
		var monster := MonsterDb.get_monster(monster_id)
		var stats := _get_instance_stats(instance_id)
		var info := _get_evolution_info_for_instance(instance_id)
		var target_id := str(info.get("target_id", ""))
		var target := MonsterDb.get_monster(target_id) if not target_id.is_empty() else {}
		var target_name := str(target.get("name", "无")) if not target.is_empty() else "无"
		portrait.visible = true
		empty.visible = false
		portrait.texture = _portrait_texture(instance_id)
		(panel.get_node("Name") as Label).text = str(monster.get("name", monster_id))
		(panel.get_node("Info") as Label).text = "Lv.%d · %s · %s" % [int(instance.get("level", 1)), _get_nature_name(str(instance.get("nature", ""))), ELEMENT_LABELS.get(str(monster.get("element", "")), str(monster.get("element", "")))]
		(panel.get_node("Stats") as Label).text = "HP %d   ATK %d   DEF %d" % [int(stats.get("hp", 0)), int(stats.get("atk", 0)), int(stats.get("def", 0))]
		(panel.get_node("Evolution") as Label).text = "进化目标：%s" % target_name
		(panel.get_node("Condition") as Label).text = str(info.get("condition_text", "无法进化"))
		(panel.get_node("Upgrade") as Label).text = str(info.get("play_upgrade_text", "玩法: 无"))
		# Even an unavailable evolution stays tappable so players receive the
		# exact missing-level or missing-item feedback.
		evolve.disabled = false
		_set_action_frame(evolve, bool(info.get("can_evolve", false)))
	_sync_card_strip(CLASS_CARD_PATHS, _class_page * CLASS_CARD_PATHS.size(), "classroom")
	_sync_page_buttons("Pages/ClassroomPage/RosterPanel", _class_page, _class_max_page)

func _sync_social_page() -> void:
	_sync_social_place()
	_sync_card_strip(SOCIAL_CARD_PATHS, _class_page * SOCIAL_CARD_PATHS.size(), "social")
	_sync_page_buttons("Pages/SocialPage/RosterPanel", _class_page, _class_max_page)

func _sync_social_place() -> void:
	var place := _current_social_place()
	var config := SocialRulesScript.place_config_for(place)
	var panel := _node("Pages/SocialPage/PlacePanel")
	(panel.get_node("Title") as Label).text = str(config.get("name", "社交场所"))
	(panel.get_node("Duration") as Label).text = "用时%s" % SocialRulesScript.duration_label_for_place(place)
	var switch_button := panel.get_node("SwitchButton") as TextureButton
	switch_button.disabled = place.get("started_at", null) != null
	_set_action_frame(switch_button, not switch_button.disabled)
	_sync_social_slot(panel.get_node("SlotA") as TextureButton, "slot_a", place)
	_sync_social_slot(panel.get_node("SlotB") as TextureButton, "slot_b", place)
	(panel.get_node("Preview") as Label).text = _social_preview_text(place)
	var detail := _social_relationship_detail(place)
	var relation_text := "放入两只精灵后显示关系预览"
	if not detail.is_empty():
		relation_text = "当前 %s · %d次 · 最高%d" % [str(detail.get("currentLabel", "未相识")), int(detail.get("count", 0)), int(detail.get("bestScore", 0))]
		if not bool(detail.get("hasHistory", false)):
			relation_text = "当前 未相识 · 预计%s · %d分" % [str(detail.get("nextLabel", "初识")), int(detail.get("nextScore", 0))]
	(panel.get_node("Relationship/Text") as Label).text = relation_text
	var action := get_node("Pages/SocialPage/BottomButtons/ActionButton") as TextureButton
	action.disabled = not _social_action_enabled(place)
	_set_action_frame(action, not action.disabled)
	_button_label(action).text = _social_action_label(place)

func _sync_social_slot(node: TextureButton, slot_key: String, place: Dictionary) -> void:
	var instance_id := str(place.get(slot_key, ""))
	var selected := _social_selected_slot == slot_key
	var portrait := node.get_node("Portrait") as TextureRect
	var check := node.get_node("Check") as TextureRect
	var name_label := node.get_node("Name") as Label
	var detail_label := node.get_node("Detail") as Label
	check.visible = selected
	if instance_id.is_empty():
		portrait.visible = false
		name_label.text = "选择怪物"
		detail_label.text = slot_key.replace("slot_", "").to_upper()
		return
	var instance := _get_instance(instance_id)
	var monster := MonsterDb.get_monster(str(instance.get("monsterId", "")))
	portrait.visible = true
	portrait.texture = _portrait_texture(instance_id)
	name_label.text = str(monster.get("name", ""))
	detail_label.text = "%s %s" % [_gender_label(instance), _get_nature_name(str(instance.get("nature", "")))]

func _sync_card_strip(paths: Array, start_index: int, context: String) -> void:
	var used := _used_monsters()
	var place := _current_social_place()
	for i in paths.size():
		var card := get_node(paths[i]) as TextureButton
		var idx := start_index + i
		card.visible = idx < _captured_monsters.size()
		if not card.visible:
			continue
		var instance_id := _get_instance_id(_captured_monsters[idx])
		var selected := false
		if context == "ranch":
			selected = used.has(instance_id) or instance_id == _selected_monster_id()
		elif context == "classroom":
			selected = instance_id == _class_selected_instance_id
		else:
			selected = str(place.get("slot_a", "")) == instance_id or str(place.get("slot_b", "")) == instance_id
		_sync_card(card, instance_id, selected, context)

func _sync_card(card: TextureButton, instance_id: String, selected: bool, context: String) -> void:
	var monster := MonsterDb.get_monster(_get_monster_id(instance_id))
	var instance := _get_instance(instance_id)
	(card.get_node("Frame") as TextureRect).texture = _tex(RANCH_ASSETS["roster_card_selected" if selected else "roster_card"])
	(card.get_node("Portrait") as TextureRect).texture = _portrait_texture(instance_id)
	(card.get_node("Name") as Label).text = str(monster.get("name", ""))
	var detail := "Lv.%d" % _get_monster_level(instance_id)
	if context != "ranch":
		var element: String = ELEMENT_LABELS.get(str(monster.get("element", "")), "")
		detail += " · " + element
	(card.get_node("Level") as Label).text = detail
	var detail_label := card.get_node("Detail") as Label
	detail_label.visible = context != "ranch"
	detail_label.text = _get_nature_name(str(instance.get("nature", ""))).substr(0, 3)
	var check := card.get_node("Check") as TextureRect
	check.visible = selected if context != "classroom" else false

func _sync_page_buttons(panel_path: String, page: int, page_max: int) -> void:
	var previous := get_node(panel_path + "/PreviousButton") as TextureButton
	var next := get_node(panel_path + "/NextButton") as TextureButton
	previous.visible = page_max > 0
	next.visible = page_max > 0
	previous.disabled = page <= 0
	next.disabled = page >= page_max

func _sync_result_popup() -> void:
	var popup := _node("Pages/SocialPage/ResultPopup")
	popup.visible = not _social_result_popup.is_empty()
	if not popup.visible:
		return
	var result := _social_result_popup
	var major: Dictionary = result.get("majorOutcome", {})
	var tags: Array = result.get("tags", [])
	var accent := TEXT_GOLD
	if str(major.get("type", "none")) == "erosion":
		accent = Color(1.0, 0.34, 0.30)
	elif str(major.get("type", "none")) == "birth":
		accent = Color(0.65, 1.0, 0.68)
	elif tags.has("属性相克"):
		accent = Color(1.0, 0.68, 0.18)
	var title := popup.get_node("Panel/Title") as Label
	title.text = _social_result_title(result)
	title.modulate = accent
	(popup.get_node("Panel/Score") as Label).text = "相性 %d · %s · +%dEXP · +%d金币" % [int(result.get("score", 0)), str(result.get("relation_label", "初识")), int(result.get("exp_each", 0)), int(result.get("gold", 0))]
	var event: Dictionary = result.get("event", {})
	(popup.get_node("Panel/Event") as Label).text = str(event.get("name", "社交事件"))
	(popup.get_node("Panel/Flavor") as Label).text = str(event.get("flavor", "关系发生了变化。"))
	var lines := _social_result_major_lines(result)
	for i in 3:
		var line := popup.get_node("Panel/Line%d" % (i + 1)) as Label
		line.text = str(lines[i]) if i < lines.size() else ""

func _portrait_texture(instance_id: String) -> Texture2D:
	return _tex(MonsterArtDBScript.get_art_path(_get_monster_id(instance_id), "ranch"))

func _button_label(button: TextureButton) -> Label:
	return button.get_node("Text") as Label

func _set_action_frame(button: TextureButton, enabled: bool) -> void:
	var frame := button.get_node_or_null("Frame") as TextureRect
	if frame != null:
		frame.texture = _tex(RANCH_ASSETS["collect_button" if enabled else "secondary_button"])
	var text_node := button.get_node_or_null("Text") as Label
	if text_node != null:
		text_node.add_theme_color_override("font_color", Color(0.22, 0.12, 0.02) if enabled else TEXT_WHITE)

func _label(path: String) -> Label:
	return get_node(path) as Label

func _node(path: String) -> Control:
	return get_node(path) as Control

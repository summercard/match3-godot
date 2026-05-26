# scene_ranch_gui.gd - 可在 Godot 编辑器中调整的精灵牧场界面控制器
# 玩法与存档逻辑沿用 SceneRanch；此脚本仅将动态数据绑定到 .tscn 节点。
class_name SceneRanchGui
extends "res://src/ui/scene/scene_ranch.gd"

const RANCH_CARD_PATHS := [
	"Pages/RanchPage/RosterPanel/Card1",
	"Pages/RanchPage/RosterPanel/Card2",
	"Pages/RanchPage/RosterPanel/Card3",
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
	var title := "怪物牧场"
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

func _sync_ranch_slots() -> void:
	for i in SLOT_PATHS.size():
		var slot_node := get_node(SLOT_PATHS[i]) as TextureButton
		var slot: Dictionary = _slots_data[i] if i < _slots_data.size() else {}
		var instance_id := str(slot.get("instance_id", ""))
		var occupied := not instance_id.is_empty() and MonsterDb.has_monster(_get_monster_id(instance_id))
		var portrait := slot_node.get_node("Portrait") as TextureRect
		var level := slot_node.get_node("Level") as Label
		var ribbon := slot_node.get_node("Ribbon") as TextureRect
		var status := slot_node.get_node("Status") as Label
		var plus := slot_node.get_node("EmptyPlus") as Label
		var empty_text := slot_node.get_node("EmptyText") as Label
		var sparkle := slot_node.get_node("Sparkle") as TextureRect
		portrait.visible = occupied
		level.visible = occupied
		ribbon.visible = occupied
		status.visible = occupied
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
			status.text = placement_text
		else:
			empty_text.text = "放入这里" if i == _selected_slot else "空位"
			empty_text.modulate = TEXT_GOLD if i == _selected_slot else TEXT_WHITE
			plus.modulate = TEXT_GOLD if i == _selected_slot else Color(0.98, 0.90, 0.67)

func _sync_collect_row() -> void:
	var total_exp := _total_idle_exp()
	var total_coin := total_exp * 1.25
	_label("Pages/RanchPage/CollectRow/ExpValue").text = "+" + _format_count(total_exp)
	_label("Pages/RanchPage/CollectRow/CoinValue").text = "+" + _format_count(total_coin)

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

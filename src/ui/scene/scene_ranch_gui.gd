# scene_ranch_gui.gd - 可在 Godot 编辑器中调整的精灵牧场界面控制器
# 玩法与存档逻辑沿用 SceneRanch；此脚本仅将动态数据绑定到 .tscn 节点。
class_name SceneRanchGui
extends "res://src/ui/scene/scene_ranch.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const PAGE_BACKGROUNDS := {
	"ranch": "res://assets/images/ranch/bg_ranch_pasture.png",
	"classroom": "res://assets/images/ranch/bg_pet_academy.png",
	"social": "res://assets/images/ranch/bg_social_meadow_yard.png",
}
const SOCIAL_PLACE_BACKGROUNDS := {
	"meadow_yard": "res://assets/images/ranch/bg_social_meadow_yard.png",
	"sunny_yard": "res://assets/images/ranch/bg_social_sunny_yard.png",
	"quiet_pond": "res://assets/images/ranch/bg_social_quiet_pond.png",
}
const LOBBY_ASSETS := {
	"currency": "res://assets/images/main/lobby_refresh/ui_currency_capsule_v3.png",
	"gold": "res://assets/images/main/lobby_refresh/icon_gold_coin_v3.png",
	"gems": "res://assets/images/main/lobby_refresh/icon_diamond_gem_v3.png",
	"plus": "res://assets/images/main/lobby_refresh/icon_plus_v3.png",
}
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
	"Pages/ClassroomPage/RosterPanel/Card4",
	"Pages/ClassroomPage/RosterPanel/Card5",
	"Pages/ClassroomPage/RosterPanel/Card6",
]
const SOCIAL_CARD_PATHS := [
	"Pages/SocialPage/RosterPanel/Card1",
	"Pages/SocialPage/RosterPanel/Card2",
	"Pages/SocialPage/RosterPanel/Card3",
	"Pages/SocialPage/RosterPanel/Card4",
	"Pages/SocialPage/RosterPanel/Card5",
	"Pages/SocialPage/RosterPanel/Card6",
]
const SLOT_PATHS := [
	"Pages/RanchPage/Slots/Slot1",
	"Pages/RanchPage/Slots/Slot2",
	"Pages/RanchPage/Slots/Slot3",
	"Pages/RanchPage/Slots/Slot4",
	"Pages/RanchPage/Slots/Slot5",
]
const SOCIAL_HEART_FX_PATHS := [
	"Pages/SocialPage/PlacePanel/FxLayer/HeartFx1",
	"Pages/SocialPage/PlacePanel/FxLayer/HeartFx2",
	"Pages/SocialPage/PlacePanel/FxLayer/HeartFx3",
	"Pages/SocialPage/PlacePanel/FxLayer/HeartFx4",
]
const TEXT_WHITE := Color(1.0, 1.0, 1.0)
const TEXT_MUTED := Color(0.66, 0.72, 0.82)
const TEXT_GOLD := Color(1.0, 0.84, 0.25)

var _gui_tick: float = 0.0
var _social_page: int = 0
var _toast_tween: Tween = null
var _social_heart_fx_running: bool = false
var _social_heart_tweens: Array[Tween] = []

func _ready() -> void:
	super._ready()
	_ensure_pet_farm_layout()
	_connect_gui_actions()
	_attach_interaction_feedback()
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
	_connect_button("PetFarmBottomNav/Nav1", _on_pet_farm_home)
	_connect_button("PetFarmBottomNav/Nav2", _on_pet_farm_pets)
	_connect_button("PetFarmBottomNav/Nav3", _on_pet_farm_classroom)
	_connect_button("PetFarmBottomNav/Nav4", _on_pet_farm_social)
	_connect_button("PetFarmBottomNav/Nav5", _on_pet_farm_menu)
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
	_connect_button("Pages/SocialPage/RosterPanel/PreviousButton", _on_social_previous_pressed)
	_connect_button("Pages/SocialPage/RosterPanel/NextButton", _on_social_next_pressed)
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
	_list_page = clampi(_list_page - 1, 0, _context_max_page())
	_sync_gui()

func _on_ranch_next_pressed() -> void:
	_list_page = clampi(_list_page + 1, 0, _context_max_page())
	_sync_gui()

func _on_class_previous_pressed() -> void:
	_class_page = clampi(_class_page - 1, 0, _context_max_page())
	_sync_gui()

func _on_class_next_pressed() -> void:
	_class_page = clampi(_class_page + 1, 0, _context_max_page())
	_sync_gui()

func _on_social_previous_pressed() -> void:
	_social_page = clampi(_social_page - 1, 0, _context_max_page())
	_sync_gui()

func _on_social_next_pressed() -> void:
	_social_page = clampi(_social_page + 1, 0, _context_max_page())
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
	var idx := _social_page * SOCIAL_CARD_PATHS.size() + visible_index
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
	_play_toast_feedback()

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Pages"):
		return
	_node("Pages/RanchPage").visible = _active_page == "ranch"
	_node("Pages/ClassroomPage").visible = _active_page == "classroom"
	_node("Pages/SocialPage").visible = _active_page == "social"
	var back_button := get_node_or_null("Header/BackButton") as TextureButton
	if back_button != null:
		back_button.visible = _active_page == "ranch"
	var background := get_node_or_null("Background") as TextureRect
	if background != null:
		var background_path := str(PAGE_BACKGROUNDS.get(_active_page, PAGE_BACKGROUNDS["ranch"]))
		if _active_page == "social":
			background_path = _social_background_path()
		background.texture = _tex(background_path)
	var title := "精灵农场"
	if _active_page == "classroom":
		title = "精灵课堂"
	elif _active_page == "social":
		title = "社交广场"
	_label("Header/Title").text = title
	_sync_top_resource_bar()
	_sync_pet_farm_bottom_nav()
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
		_calc_idle_exp()
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

	var toast := get_node_or_null("SharedToast") as Label
	if toast != null:
		toast.visible = feedback_visible
		toast.text = _status_text
		toast.modulate.a = minf(1.0, _status_timer) if toast.visible else 0.0

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
	_sync_page_buttons("Pages/RanchPage/RosterPanel", _list_page, _context_max_page())

func _sync_ranch_slots() -> void:
	for i in SLOT_PATHS.size():
		var slot_node := get_node(SLOT_PATHS[i]) as TextureButton
		var slot: Dictionary = _slots_data[i] if i < _slots_data.size() else {}
		var instance_id := str(slot.get("instance_id", ""))
		var occupied := not instance_id.is_empty() and MonsterDb.has_monster(_get_monster_id(instance_id))
		var slot_frame := slot_node.get_node("FarmFrame") as TextureRect
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
			status.text = "EXP +%d/h" % (60 + _get_monster_level(instance_id) * 10)
			timer.text = _format_elapsed(slot.get("placed_at", null))
			timer.modulate = TEXT_GOLD if not str(care.get("label", "")).is_empty() else TEXT_WHITE
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
	# Visual structure lives in ranch_hub.tscn so the Godot editor is the
	# source of truth. Runtime code only validates and binds live data.
	var required_paths := [
		"PetFarmResourceBar",
		"SharedToast",
		"PetFarmBottomNav/Nav5",
		"Pages/RanchPage/RosterPanel/Card6",
		"Pages/RanchPage/RosterPanel/PageText",
		"Pages/ClassroomPage/DetailPanel/CreamFrame",
		"Pages/ClassroomPage/DetailPanel/EvolveButton/ModernFrame",
		"Pages/ClassroomPage/RosterPanel/Card6",
		"Pages/SocialPage/PlacePanel/HeartBubble",
		"Pages/SocialPage/PlacePanel/FxLayer/HeartFx4",
		"Pages/SocialPage/PlacePanel/SwitchButton/SocialFrame",
		"Pages/SocialPage/BondPanel",
		"Pages/SocialPage/BottomButtons/ActionButton/SocialFrame",
		"Pages/SocialPage/RosterPanel/Card6",
	]
	for path in required_paths:
		if not has_node(path):
			push_error("ranch_hub.tscn is missing required UI node: " + path)

func _on_pet_farm_home() -> void:
	_go_to_scene("main")

func _on_pet_farm_pets() -> void:
	if _active_page == "ranch":
		_show_status("当前已在宠物农场")
	else:
		_switch_to_ranch()

func _on_pet_farm_classroom() -> void:
	_switch_to_classroom()

func _on_pet_farm_social() -> void:
	_switch_to_social()

func _on_pet_farm_menu() -> void:
	_show_status("更多宠物功能正在整理中")

func _sync_top_resource_bar() -> void:
	var bar := get_node_or_null("PetFarmResourceBar") as Control
	if bar == null or bar.get_child_count() < 3:
		return
	var player: Dictionary = _storage.get_player() if _storage != null and _storage.has_method("get_player") else {}
	var values := [
		"金币  %s" % _format_resource_number(int(player.get("gold", 0))),
		"钻石  %s" % _format_resource_number(int(player.get("gems", 0))),
		"体力  Full",
	]
	for i in 3:
		var panel := bar.get_child(i) as Panel
		if panel != null:
			(panel.get_node("Value") as Label).text = values[i]

func _sync_pet_farm_bottom_nav() -> void:
	var nav := get_node_or_null("PetFarmBottomNav") as Control
	if nav == null:
		return
	var active_index := 1
	if _active_page == "classroom":
		active_index = 2
	elif _active_page == "social":
		active_index = 3
	for i in 5:
		var button := nav.get_node_or_null("Nav%d" % (i + 1)) as Button
		if button == null:
			continue
		var selected := button.get_node_or_null("Selected") as TextureRect
		if selected != null:
			selected.visible = i == active_index
		button.modulate = Color.WHITE if i == active_index else Color(0.92, 0.92, 0.92)

func _play_toast_feedback() -> void:
	var toast := get_node_or_null("SharedToast") as Label
	if toast == null:
		return
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast.pivot_offset = toast.size * 0.5
	toast.scale = Vector2(0.72, 0.72)
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_property(toast, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _attach_interaction_feedback() -> void:
	var paths := [
		"Header/BackButton",
		"Pages/RanchPage/CollectRow/CollectButton",
		"Pages/RanchPage/BottomButtons/FocusButton",
		"Pages/ClassroomPage/DetailPanel/EvolveButton",
		"Pages/SocialPage/PlacePanel/SwitchButton",
		"Pages/SocialPage/BottomButtons/ActionButton",
		"Pages/SocialPage/ResultPopup/ConfirmButton",
	]
	paths.append_array(SLOT_PATHS)
	paths.append_array(RANCH_CARD_PATHS)
	paths.append_array(CLASS_CARD_PATHS)
	paths.append_array(SOCIAL_CARD_PATHS)
	for path in paths:
		var button := get_node_or_null(path) as BaseButton
		_attach_button_feedback(button, CartoonButtonFeedback.Profile.NAV)
	var nav := get_node_or_null("PetFarmBottomNav") as Control
	if nav != null:
		for i in 5:
			_attach_button_feedback(nav.get_node_or_null("Nav%d" % (i + 1)) as BaseButton, CartoonButtonFeedback.Profile.NAV)

func _attach_button_feedback(button: BaseButton, profile: int) -> void:
	if button == null or button.has_node("CartoonFeedback"):
		return
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)

func _context_max_page() -> int:
	var page_size := RANCH_CARD_PATHS.size()
	return maxi(0, ceili(float(_captured_monsters.size()) / float(page_size)) - 1)

func _format_resource_number(num: int) -> String:
	var digits := str(absi(num))
	var formatted := ""
	while digits.length() > 3:
		formatted = "," + digits.substr(digits.length() - 3) + formatted
		digits = digits.substr(0, digits.length() - 3)
	formatted = digits + formatted
	return "-" + formatted if num < 0 else formatted

func _social_background_path() -> String:
	var place_id := str(_current_social_place().get("place_id", "meadow_yard"))
	return str(SOCIAL_PLACE_BACKGROUNDS.get(place_id, SOCIAL_PLACE_BACKGROUNDS["meadow_yard"]))

func _evolution_stone_icon_path(item_id: String) -> String:
	var element := item_id.trim_prefix("evolution_stone_")
	var path := "res://assets/images/items/icon_stone_%s.png" % element
	return path if ResourceLoader.exists(path) else RANCH_ASSETS["exp"]

func _sync_classroom_page() -> void:
	var instance_id := _class_selected_instance_id
	if instance_id.is_empty() and not _captured_monsters.is_empty():
		instance_id = _get_instance_id(_captured_monsters[0])
	var panel := _node("Pages/ClassroomPage/DetailPanel")
	var portrait := panel.get_node("Portrait") as TextureRect
	var target_portrait := panel.get_node("TargetPortrait") as TextureRect
	var empty := panel.get_node("Empty") as Label
	var evolve := panel.get_node("EvolveButton") as TextureButton
	var stone_icon := panel.get_node("StoneIcon") as TextureRect
	if instance_id.is_empty():
		portrait.visible = false
		target_portrait.visible = false
		stone_icon.visible = false
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
		var target_name := str(target.get("name", "最终形态")) if not target.is_empty() else "最终形态"
		var level := int(instance.get("level", 1))
		var target_stats := MonsterDb.get_monster_stats(target_id, level, str(instance.get("nature", ""))) if not target_id.is_empty() else {}
		var required_level := int(info.get("required_level", 1))
		var item_count := int(info.get("item_count", 0))
		var required_item := str(info.get("required_item", ""))
		portrait.visible = true
		target_portrait.visible = not target.is_empty()
		stone_icon.visible = not required_item.is_empty()
		empty.visible = false
		portrait.texture = _portrait_texture(instance_id)
		target_portrait.texture = _tex(MonsterArtDBScript.get_art_path(target_id, "ranch"))
		stone_icon.texture = _tex(_evolution_stone_icon_path(required_item))
		(panel.get_node("Name") as Label).text = str(monster.get("name", monster_id))
		(panel.get_node("Info") as Label).text = "Lv.%d · %s · %s" % [level, _get_nature_name(str(instance.get("nature", ""))), ELEMENT_LABELS.get(str(monster.get("element", "")), str(monster.get("element", "")))]
		(panel.get_node("TargetName") as Label).text = target_name
		(panel.get_node("TargetLevel") as Label).text = "进化后 · Lv.%d" % level if not target.is_empty() else "已是最终形态"
		(panel.get_node("Stats") as Label).text = "属性预览  HP %d→%d   ATK %d→%d   DEF %d→%d" % [int(stats.get("hp", 0)), int(target_stats.get("hp", stats.get("hp", 0))), int(stats.get("atk", 0)), int(target_stats.get("atk", stats.get("atk", 0))), int(stats.get("def", 0)), int(target_stats.get("def", stats.get("def", 0)))]
		(panel.get_node("LevelRequirement") as Label).text = "等级 %d/%d" % [level, required_level]
		(panel.get_node("StoneRequirement") as Label).text = "%s  %d/1" % [str(info.get("item_name", "进化石")), item_count]
		(panel.get_node("Condition") as Label).text = str(info.get("condition_text", "无法进化"))
		(panel.get_node("Upgrade") as Label).text = str(info.get("play_upgrade_text", "玩法: 无"))
		# Even an unavailable evolution stays tappable so players receive the
		# exact missing-level or missing-item feedback.
		evolve.disabled = false
		_set_action_frame(evolve, bool(info.get("can_evolve", false)))
	_sync_card_strip(CLASS_CARD_PATHS, _class_page * CLASS_CARD_PATHS.size(), "classroom")
	_sync_page_buttons("Pages/ClassroomPage/RosterPanel", _class_page, _context_max_page())

func _sync_social_page() -> void:
	_sync_social_place()
	_sync_card_strip(SOCIAL_CARD_PATHS, _social_page * SOCIAL_CARD_PATHS.size(), "social")
	_sync_page_buttons("Pages/SocialPage/RosterPanel", _social_page, _context_max_page())

func _sync_social_place() -> void:
	var place := _current_social_place()
	var config := SocialRulesScript.place_config_for(place)
	var panel := _node("Pages/SocialPage/PlacePanel")
	(panel.get_node("Title") as Label).text = str(config.get("name", "社交场所"))
	(panel.get_node("Duration") as Label).text = "用时%s" % SocialRulesScript.duration_label_for_place(place)
	var switch_button := panel.get_node("SwitchButton") as TextureButton
	switch_button.disabled = place.get("started_at", null) != null
	_set_action_frame(switch_button, not switch_button.disabled)
	_sync_social_heart_fx(place)
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
	var bond_panel := _node("Pages/SocialPage/BondPanel")
	var relation_level := maxi(1, int(detail.get("currentLevel", 0)))
	(bond_panel.get_node("BondTitle") as Label).text = "%s · 羁绊 Lv.%d" % [str(config.get("name", "社交场所")), relation_level]
	(bond_panel.get_node("ProgressText") as Label).text = relation_text
	(bond_panel.get_node("Summary") as Label).text = _social_preview_text(place)
	var progress_fill := bond_panel.get_node("ProgressFill") as Panel
	progress_fill.size.x = 154.0 * _social_bond_progress(place, detail)
	var action := get_node("Pages/SocialPage/BottomButtons/ActionButton") as TextureButton
	action.disabled = not _social_action_enabled(place) and place.get("started_at", null) == null
	_set_action_frame(action, not action.disabled)
	_button_label(action).text = _social_action_label(place)

func _social_bond_progress(place: Dictionary, detail: Dictionary) -> float:
	if place.get("started_at", null) != null:
		return clampf(SocialRulesScript.progress(place), 0.06, 1.0)
	if detail.is_empty():
		return 0.0
	return clampf(float(detail.get("bestScore", detail.get("nextScore", 0))) / 100.0, 0.08, 1.0)

func _sync_social_heart_fx(place: Dictionary) -> void:
	var should_run := place.get("started_at", null) != null
	if should_run == _social_heart_fx_running:
		return
	_stop_social_heart_fx()
	_social_heart_fx_running = should_run
	if not should_run:
		return
	for i in SOCIAL_HEART_FX_PATHS.size():
		var heart := get_node(SOCIAL_HEART_FX_PATHS[i]) as TextureRect
		var start_position := heart.position
		var start_scale := Vector2.ONE * (0.70 + float(i % 3) * 0.08)
		var drift := -9.0 + float(i) * 6.0
		heart.visible = true
		heart.pivot_offset = heart.size * 0.5
		var tween := create_tween().set_loops()
		tween.tween_interval(float(i) * 0.52)
		tween.tween_callback(_reset_social_heart_fx.bind(heart, start_position, start_scale))
		tween.tween_property(heart, "modulate:a", 0.84, 0.45)
		tween.parallel().tween_property(heart, "position", start_position + Vector2(drift, -23.0), 1.65)
		tween.parallel().tween_property(heart, "scale", start_scale * 1.08, 1.65)
		tween.tween_property(heart, "position", start_position + Vector2(drift * 1.35, -45.0), 1.25)
		tween.parallel().tween_property(heart, "modulate:a", 0.0, 1.25)
		tween.tween_interval(0.35)
		_social_heart_tweens.append(tween)

func _reset_social_heart_fx(heart: TextureRect, start_position: Vector2, start_scale: Vector2) -> void:
	heart.position = start_position
	heart.scale = start_scale
	heart.modulate.a = 0.0

func _stop_social_heart_fx() -> void:
	for tween in _social_heart_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_social_heart_tweens.clear()
	for path in SOCIAL_HEART_FX_PATHS:
		var heart := get_node_or_null(path) as TextureRect
		if heart != null:
			heart.visible = false

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
		var ranch_locked := context == "social" and _is_instance_in_ranch(instance_id)
		card.modulate = Color(1.0, 1.0, 1.0, 0.52) if ranch_locked else Color.WHITE
		card.tooltip_text = "农场挂机中，先从农场取下" if ranch_locked else ""

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
	detail_label.visible = false
	detail_label.text = _get_nature_name(str(instance.get("nature", ""))).substr(0, 3)
	var check := card.get_node("Check") as TextureRect
	check.visible = selected and context == "ranch"
	var selection_mark := card.get_node_or_null("SelectionMark") as Label
	if selection_mark != null:
		selection_mark.visible = selected and context != "ranch"

func _sync_page_buttons(panel_path: String, page: int, page_max: int) -> void:
	var previous := get_node(panel_path + "/PreviousButton") as TextureButton
	var next := get_node(panel_path + "/NextButton") as TextureButton
	previous.visible = page_max > 0
	next.visible = page_max > 0
	previous.disabled = page <= 0
	next.disabled = page >= page_max
	var page_text := get_node_or_null(panel_path + "/PageText") as Label
	if page_text != null:
		page_text.text = "%d / %d" % [page + 1, page_max + 1]

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
	if button.has_node("SocialFrame"):
		_set_social_action_style(button, enabled)
		return
	if button.has_node("ModernFrame"):
		_set_classroom_evolve_style(button, enabled)
		return
	var frame := button.get_node_or_null("Frame") as TextureRect
	if frame != null:
		frame.texture = _tex(RANCH_ASSETS["collect_button" if enabled else "secondary_button"])
	var text_node := button.get_node_or_null("Text") as Label
	if text_node != null:
		text_node.add_theme_color_override("font_color", Color(0.22, 0.12, 0.02) if enabled else TEXT_WHITE)

func _set_classroom_evolve_style(button: TextureButton, enabled: bool) -> void:
	var modern_frame := button.get_node("ModernFrame") as Panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.52, 0.80, 0.12, 1.0) if enabled else Color(0.39, 0.57, 0.16, 1.0)
	style.border_color = Color(0.98, 0.76, 0.20, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.19, 0.12, 0.02, 0.38)
	style.shadow_size = 4
	modern_frame.add_theme_stylebox_override("panel", style)
	var text_node := button.get_node("Text") as Label
	text_node.add_theme_color_override("font_color", Color.WHITE)
	text_node.add_theme_color_override("font_outline_color", Color(0.20, 0.34, 0.05))
	text_node.add_theme_constant_override("outline_size", 2)

func _set_social_action_style(button: TextureButton, enabled: bool) -> void:
	var social_frame := button.get_node("SocialFrame") as Panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.52, 0.10, 1.0) if enabled else Color(0.71, 0.56, 0.32, 1.0)
	style.border_color = Color(1.0, 0.76, 0.22, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.35, 0.16, 0.02, 0.35)
	style.shadow_size = 4
	social_frame.add_theme_stylebox_override("panel", style)
	var text_node := button.get_node("Text") as Label
	text_node.add_theme_color_override("font_color", Color.WHITE)
	text_node.add_theme_color_override("font_outline_color", Color(0.49, 0.20, 0.02))
	text_node.add_theme_constant_override("outline_size", 2)

func _label(path: String) -> Label:
	return get_node(path) as Label

func _node(path: String) -> Control:
	return get_node(path) as Control

# scene_ranch_gui.gd - 可在 Godot 编辑器中调整的精灵牧场界面控制器
# 玩法与存档逻辑沿用 SceneRanch；此脚本仅将动态数据绑定到 .tscn 节点。
class_name SceneRanchGui
extends "res://src/ui/controllers/ranch_logic.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const GrowthRulesScript := preload("res://src/core/growth_rules.gd")
const PAGE_BACKGROUNDS := {
	"ranch": "res://assets/images/ui/backgrounds/ranch_optimized_bg_ranch_pasture_750.png",
	"classroom": "res://assets/images/ui/backgrounds/ranch_optimized_bg_pet_academy_750.png",
	"social": "res://assets/images/ui/backgrounds/ranch_optimized_bg_social_meadow_yard_750.png",
}
const SOCIAL_PLACE_BACKGROUNDS := {
	"meadow_yard": "res://assets/images/ui/backgrounds/ranch_optimized_bg_social_meadow_yard_750.png",
	"sunny_yard": "res://assets/images/ui/backgrounds/ranch_optimized_bg_social_sunny_yard_750.png",
	"quiet_pond": "res://assets/images/ui/backgrounds/ranch_optimized_bg_social_quiet_pond_750.png",
}
const LOBBY_ASSETS := {
	"currency": "res://assets/images/ui/panels/main_ui_currency_capsule_v3.png",
	"gold": "res://assets/images/ui/icons/main_icon_gold_coin_v3.png",
	"gems": "res://assets/images/ui/gems/main_icon_diamond_gem_v3.png",
	"plus": "res://assets/images/ui/icons/main_icon_currency_plus_green.png",
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
const TIMER_PENDING_COLOR := Color(0.55, 1.0, 0.42)
const TIMER_WAITING_COLOR := Color(0.70, 0.86, 1.0)
const DYNAMIC_GUI_INTERVAL := 1.0
const STATUS_GUI_INTERVAL := 1.0 / 15.0
const RANCH_SLOT_LEVEL_FONT_SIZE := 8
const RANCH_SLOT_EXP_FONT_SIZE := 8
const RANCH_SLOT_TIMER_FONT_SIZE := 7
const RANCH_SLOT_EXP_OUTLINE_SIZE := 1
const RANCH_SLOT_EMPTY_PLUS_FONT_SIZE := 34
const RANCH_SLOT_EMPTY_PLUS_SELECTED_FONT_SIZE := 44
const RANCH_SLOT_EMPTY_TEXT_FONT_SIZE := 13
const RANCH_SLOT_EMPTY_TEXT_SELECTED_FONT_SIZE := 17
const RANCH_SLOT_EMPTY_OUTLINE_SIZE := 4
const RANCH_SLOT_EMPTY_SELECTED_OUTLINE_SIZE := 6
const RANCH_SLOT_EMPTY_SELECTED_TEXT_COLOR := Color(1.0, 0.42, 0.04)
const CLASSROOM_INFO_FONT_SIZE := 11
const CLASSROOM_STATS_FONT_SIZE := 8
const CLASSROOM_LEADER_SKILL_FONT_SIZE := 7
const CLASSROOM_REQUIREMENT_TITLE_FONT_SIZE := 11
const CLASSROOM_REQUIREMENT_FONT_SIZE := 9
const CLASSROOM_EVOLVE_BUTTON_FONT_SIZE := 13
const SOCIAL_EMPTY_SLOT_TEXTURE := "res://assets/images/ui/panels/team_new_ui_empty_pedestal_plus.png"
const SOCIAL_BOND_TITLE_FONT_SIZE := 10
const SOCIAL_BOND_TEXT_FONT_SIZE := 8
const SOCIAL_BOND_SUMMARY_FONT_SIZE := 7

# 子页面入场动画（参考胜利界面：奖励槽从下方弹入 + 淡入）
const SUBPAGE_ENTRY_DURATION := 0.20
const SUBPAGE_ENTRY_OFFSET_Y := 14.0
const SUBPAGE_CARD_START := 0.05
const SUBPAGE_CARD_STAGGER := 0.05
const SUBPAGE_CARD_DURATION := 0.22
const SUBPAGE_BTN_DELAY := 0.30
const SUBPAGE_BTN_DURATION := 0.20

# 首次进入旅馆（hub 级别）入场：Header / ResourceBar / BottomNav 整体 stagger
const HUB_HEADER_DURATION := 0.22
const HUB_RESOURCE_DURATION := 0.22
const HUB_NAV_START := 0.18
const HUB_NAV_STAGGER := 0.04
const HUB_NAV_DURATION := 0.18
const HARVEST_POP_DURATION := 0.10
const HARVEST_FLOAT_DURATION := 0.34
const HARVEST_FEEDBACK_DURATION := HARVEST_POP_DURATION + HARVEST_FLOAT_DURATION

var _dynamic_gui_tick: float = 0.0
var _status_gui_tick: float = 0.0
var _social_page: int = 0
var _toast_tween: Tween = null
var _social_heart_fx_running: bool = false
var _social_heart_tweens: Array[Tween] = []
var _subpage_entry_tweens: Array[Tween] = []
var _hub_entry_tweens: Array[Tween] = []
var _hub_entry_played: bool = false
var _portrait_path_cache: Dictionary = {}
var _upgrade_animating: bool = false
var _upgrade_feedback_tween: Tween = null
var _upgrade_value_tweens: Array[Tween] = []
var _harvest_float_tweens: Array[Tween] = []
var _sell_pending_instance_id: String = ""
var _sell_pending_quote: Dictionary = {}

func _ready() -> void:
	super._ready()
	_ensure_pet_farm_layout()
	_connect_gui_actions()
	_attach_interaction_feedback()
	_sync_gui()
	_play_subpage_entry(_active_page)

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_sync_gui()
	# 在 _sync_gui 之后才能 _play_hub_entry：因为 _sync_gui 内部的 _sync_pet_farm_bottom_nav
	# 会把 Nav button.modulate 覆盖为 WHITE。_hub_entry_played 守卫保证只播一次。
	_play_hub_entry()

func initialize(game: Node) -> void:
	super.initialize(game)
	_sync_gui()

func _process(delta: float) -> void:
	_time += delta
	if _status_timer > 0.0:
		_status_timer = maxf(0.0, _status_timer - delta)
		_status_gui_tick += delta
		if _status_gui_tick >= STATUS_GUI_INTERVAL or _status_timer <= 0.0:
			_status_gui_tick = 0.0
			_sync_status()
	_dynamic_gui_tick += delta
	if _dynamic_gui_tick >= DYNAMIC_GUI_INTERVAL:
		_dynamic_gui_tick = 0.0
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
	_connect_button("Pages/ClassroomPage/DetailPanel/UpgradeButton", _on_upgrade_button_pressed)
	_connect_button("Pages/ClassroomPage/DetailPanel/SellButton", _on_sell_button_pressed)
	_connect_button("Pages/ClassroomPage/SellConfirmPopup/CancelButton", _on_sell_dialog_cancelled)
	_connect_button("Pages/ClassroomPage/SellConfirmPopup/ConfirmButton", _on_sell_dialog_confirmed)
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
	var sell_shade := get_node("Pages/ClassroomPage/SellConfirmPopup/Shade") as Control
	if not sell_shade.gui_input.is_connected(_on_sell_shade_input):
		sell_shade.gui_input.connect(_on_sell_shade_input)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _on_back_button_pressed() -> void:
	if _active_page == "ranch":
		_go_to_scene("main")
	else:
		_switch_to_ranch()

func _on_focus_button_pressed() -> void:
	_toggle_care_focus_selected()
	_sync_gui()

func _on_ranch_slot_pressed(index: int) -> void:
	_select_slot(index)
	_collect_slot(index)
	_sync_gui()

func _collect_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slots_data.size():
		return
	var slot: Dictionary = _slots_data[slot_index]
	var instance_id = slot.get("instance_id", null)
	if instance_id == null:
		_show_status("选择空位后从列表放入精灵")
		return
	var exp := int(_idle_exp_map.get(str(instance_id), 0))
	if exp <= 0:
		_show_status("暂无可收获收益")
		return
	if not _can_add_shared_exp(exp):
		_show_status(_shared_exp_overflow_text())
		return
	var added := exp
	var overflow := 0
	if _storage != null and _storage.has_method("add_shared_monster_exp"):
		var add_result: Dictionary = _storage.add_shared_monster_exp(exp)
		added = int(add_result.get("added", exp))
		overflow = int(add_result.get("overflow", 0))
	if added < exp or overflow > 0:
		_show_status(_shared_exp_overflow_text())
		return
	slot["placed_at"] = Time.get_unix_time_from_system() * 1000.0
	_save_ranch_state()
	_refresh_ranch_view()
	_clear_status_feedback()
	exp_collected.emit(added)
	if added > 0:
		_show_slot_harvest_float(slot_index, added)
	else:
		_show_status("经验槽已满")

func _on_collect_pressed() -> void:
	var total_collected := 0
	var collectable_slots: Array[Dictionary] = []
	for i in range(_slots_data.size()):
		var slot: Dictionary = _slots_data[i]
		var monster_id = slot.get("instance_id", null)
		if monster_id == null:
			continue
		var exp := int(_idle_exp_map.get(str(monster_id), 0))
		if exp <= 0:
			continue
		total_collected += exp
		collectable_slots.append({"slot": slot, "index": i, "exp": exp})
	if total_collected <= 0:
		_show_status(_no_idle_reward_text())
		return
	if not _can_add_shared_exp(total_collected):
		_show_status(_shared_exp_overflow_text())
		return
	var added := total_collected
	var overflow := 0
	if total_collected > 0 and _storage != null and _storage.has_method("add_shared_monster_exp"):
		var add_result: Dictionary = _storage.add_shared_monster_exp(total_collected)
		added = int(add_result.get("added", total_collected))
		overflow = int(add_result.get("overflow", 0))
	if added < total_collected or overflow > 0:
		_show_status(_shared_exp_overflow_text())
		return
	var now_ms := Time.get_unix_time_from_system() * 1000.0
	for entry: Dictionary in collectable_slots:
		var slot: Dictionary = entry.get("slot", {})
		slot["placed_at"] = now_ms
	_save_ranch_state()
	_refresh_ranch_view()
	_clear_status_feedback()
	if added > 0:
		exp_collected.emit(added)
		for entry: Dictionary in collectable_slots:
			_show_slot_harvest_float(int(entry.get("index", 0)), int(entry.get("exp", 0)))
	else:
		_show_status("经验槽已满")

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
		_clear_sell_pending()
		_sync_gui()

func _on_evolve_button_pressed() -> void:
	_clear_sell_pending()
	_on_evolve_pressed()
	_sync_gui()

func _on_upgrade_button_pressed() -> void:
	_clear_sell_pending()
	var instance_id := _class_selected_instance_id
	var before := _fresh_instance(instance_id).duplicate(true)
	var pool_before := int(_storage.get_shared_monster_exp()) if _storage != null and _storage.has_method("get_shared_monster_exp") else 0
	var result: Dictionary = _on_upgrade_pressed()
	var after := _fresh_instance(instance_id).duplicate(true)
	var pool_after := int(_storage.get_shared_monster_exp()) if _storage != null and _storage.has_method("get_shared_monster_exp") else pool_before
	_sync_gui()
	if bool(result.get("ok", false)):
		_status_text = ""
		_status_timer = 0.0
		_sync_status()
		_play_upgrade_feedback(before, after, result, pool_before, pool_after)

func _on_sell_button_pressed() -> void:
	var instance_id := _class_selected_instance_id
	if instance_id.is_empty():
		_show_status("请选择要出售的精灵")
		return
	if _storage == null or not _storage.has_method("get_monster_sell_quote") or not _storage.has_method("sell_monster_instance"):
		_show_status("出售系统不可用")
		return
	var quote: Dictionary = _storage.get_monster_sell_quote(instance_id)
	if not bool(quote.get("ok", false)):
		_clear_sell_pending()
		_show_status("无法出售该精灵")
		_sync_gui()
		return
	_sell_pending_instance_id = instance_id
	_sell_pending_quote = quote.duplicate(true)
	_show_sell_confirm_dialog(quote)

func _on_sell_dialog_confirmed() -> void:
	var instance_id := _sell_pending_instance_id
	if instance_id.is_empty():
		return
	_hide_sell_confirm_popup()
	if _storage == null or not _storage.has_method("sell_monster_instance"):
		_clear_sell_pending()
		_show_status("出售系统不可用")
		return
	var result: Dictionary = _storage.sell_monster_instance(instance_id)
	_clear_sell_pending()
	if not bool(result.get("ok", false)):
		var error := str(result.get("error", "unknown"))
		var message := "出售失败"
		if error == "last_monster":
			message = "至少保留 1 只精灵"
		_show_status(message)
		_sync_gui()
		return
	_load_data()
	_select_classroom_after_removed(instance_id)
	_sync_gui()
	_show_status(TranslationServer.translate("出售成功：%s") % _sell_reward_text(result))

func _on_sell_dialog_cancelled() -> void:
	_hide_sell_confirm_popup()
	_clear_sell_pending()

func _on_sell_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_sell_dialog_cancelled()
	elif event is InputEventScreenTouch and event.pressed:
		_on_sell_dialog_cancelled()

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
	if not _can_open_feature("ranch"):
		_sync_gui()
		return
	super._switch_to_ranch()
	_sync_gui()
	_play_subpage_entry("ranch")

func _switch_to_classroom() -> void:
	if not _can_open_feature("classroom"):
		_sync_gui()
		return
	super._switch_to_classroom()
	_sync_gui()
	_play_subpage_entry("classroom")

func _switch_to_social() -> void:
	if not _can_open_feature("social"):
		_sync_gui()
		return
	super._switch_to_social()
	_sync_gui()
	_play_subpage_entry("social")

func _refresh_ranch_view() -> void:
	_calc_idle_exp()
	_update_list_scroll_limit()
	_update_class_scroll_limit()
	_sync_gui()

func _init_bubbles() -> void:
	_bubbles = []

func _add_bubble(_slot_index: int) -> void:
	pass

func _show_status(text: String) -> void:
	super._show_status(text)
	_sync_status()
	_play_toast_feedback()

func _clear_status_feedback() -> void:
	_status_text = ""
	_status_timer = 0.0
	_sync_status()

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
		_set_texture(background, _tex(background_path))
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
	_sync_feature_button("Pages/RanchPage/BottomButtons/ClassroomButton", "classroom", "课堂")
	_sync_feature_button("Pages/RanchPage/BottomButtons/SocialButton", "social", "广场")

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
		_set_visible(portrait, occupied)
		_set_visible(level, occupied)
		_set_visible(level_badge, occupied)
		_set_visible(ribbon, occupied)
		_set_visible(status, occupied)
		_set_visible(timer_plate, occupied)
		_set_visible(timer, occupied)
		_set_visible(sparkle, false)
		_set_visible(plus, not occupied)
		_set_visible(empty_text, not occupied)
		var selected := i == _selected_slot
		_apply_ranch_slot_level_text_style(level, selected and occupied)
		_apply_ranch_slot_idle_text_style(status, timer, selected and occupied)
		if occupied:
			_set_texture(portrait, _portrait_texture(instance_id))
			_set_text(level, "Lv.%d" % _get_monster_level(instance_id))
			var care: Dictionary = _care_state_map.get(instance_id, _get_care_state(instance_id))
			_set_text(status, "EXP +%d/h" % roundi(float(care.get("rate", _get_idle_exp_rate(instance_id))) * 12.0))
			_set_text(timer, _format_elapsed(slot.get("placed_at", null)))
			var pending_exp := int(_idle_exp_map.get(instance_id, 0))
			timer.modulate = TIMER_PENDING_COLOR if pending_exp > 0 else TIMER_WAITING_COLOR
			level_badge.modulate = Color(1.18, 1.06, 0.48) if selected else Color.WHITE
			ribbon.modulate = Color(1.18, 1.08, 0.52) if selected else Color.WHITE
		else:
			empty_text.text = "放入这里" if i == _selected_slot else "空位"
			empty_text.modulate = RANCH_SLOT_EMPTY_SELECTED_TEXT_COLOR if i == _selected_slot else TEXT_WHITE
			plus.modulate = TEXT_GOLD if i == _selected_slot else Color(0.98, 0.90, 0.67)
			_apply_ranch_slot_empty_text_style(plus, empty_text, i == _selected_slot)

func _apply_ranch_slot_level_text_style(level: Label, selected: bool = false) -> void:
	if level != null:
		level.add_theme_font_size_override("font_size", RANCH_SLOT_LEVEL_FONT_SIZE)
		level.add_theme_constant_override("outline_size", 4 if selected else 1)
		level.add_theme_color_override("font_outline_color", Color(1.0, 0.58, 0.05, 1.0) if selected else Color(1.0, 0.95, 0.78, 1.0))
		level.clip_text = true

func _apply_ranch_slot_idle_text_style(status: Label, timer: Label, selected: bool = false) -> void:
	if status != null:
		status.add_theme_font_size_override("font_size", RANCH_SLOT_EXP_FONT_SIZE)
		status.add_theme_constant_override("outline_size", 4 if selected else RANCH_SLOT_EXP_OUTLINE_SIZE)
		status.add_theme_color_override("font_outline_color", Color(0.95, 0.45, 0.02, 1.0) if selected else Color(0.0, 0.0, 0.0, 0.7))
		status.clip_text = true
	if timer != null:
		timer.add_theme_font_size_override("font_size", RANCH_SLOT_TIMER_FONT_SIZE)
		timer.clip_text = true

func _apply_ranch_slot_empty_text_style(plus: Label, empty_text: Label, selected: bool) -> void:
	if plus != null:
		plus.add_theme_font_size_override("font_size", RANCH_SLOT_EMPTY_PLUS_SELECTED_FONT_SIZE if selected else RANCH_SLOT_EMPTY_PLUS_FONT_SIZE)
		plus.add_theme_constant_override("outline_size", RANCH_SLOT_EMPTY_SELECTED_OUTLINE_SIZE if selected else RANCH_SLOT_EMPTY_OUTLINE_SIZE)
		plus.clip_text = false
	if empty_text != null:
		empty_text.add_theme_font_size_override("font_size", RANCH_SLOT_EMPTY_TEXT_SELECTED_FONT_SIZE if selected else RANCH_SLOT_EMPTY_TEXT_FONT_SIZE)
		empty_text.add_theme_constant_override("outline_size", RANCH_SLOT_EMPTY_SELECTED_OUTLINE_SIZE if selected else RANCH_SLOT_EMPTY_OUTLINE_SIZE)
		empty_text.clip_text = false

func _sync_collect_row() -> void:
	var total_exp := _total_idle_exp()
	var total_coin := total_exp * 1.25
	_set_text(_label("Pages/RanchPage/CollectRow/ExpValue"), "+" + _format_count(total_exp))
	_set_text(_label("Pages/RanchPage/CollectRow/CoinValue"), "+" + _format_count(total_coin))

func _show_slot_harvest_float(slot_index: int, amount: int) -> void:
	if amount <= 0 or slot_index < 0 or slot_index >= SLOT_PATHS.size():
		return
	var page := get_node_or_null("Pages/RanchPage") as Control
	var slot_node := get_node_or_null(SLOT_PATHS[slot_index]) as Control
	if page == null or slot_node == null:
		return
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 80
	label.text = "EXP +%d" % amount
	label.size = Vector2(112.0, 28.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", PROJECT_ROUND_FONT)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.74, 1.0, 0.32, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.22, 0.03, 0.92))
	label.add_theme_constant_override("outline_size", 4)
	var slot_center := slot_node.position + slot_node.size * 0.5
	var start_pos := Vector2(slot_center.x - label.size.x * 0.5, slot_node.position.y - 32.0)
	label.position = start_pos
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.92, 0.92)
	page.add_child(label)
	var tween := create_tween()
	_harvest_float_tweens.append(tween)
	tween.tween_property(label, "scale", Vector2.ONE, HARVEST_POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position", start_pos + Vector2(0.0, -12.0), HARVEST_POP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position", start_pos + Vector2(0.0, -44.0), HARVEST_FLOAT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, HARVEST_FLOAT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_cleanup_harvest_float.bind(label, tween))

func _cleanup_harvest_float(label: Label, tween: Tween) -> void:
	_harvest_float_tweens.erase(tween)
	if label != null and is_instance_valid(label):
		label.queue_free()

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
		"Pages/ClassroomPage/DetailPanel/EvolveButton/butter02",
		"Pages/ClassroomPage/RosterPanel/Card6",
		"Pages/SocialPage/PlacePanel/HeartBubble",
		"Pages/SocialPage/PlacePanel/FxLayer/HeartFx4",
		"Pages/SocialPage/PlacePanel/SwitchButton/butter01",
		"Pages/SocialPage/BondPanel",
		"Pages/SocialPage/BottomButtons/ActionButton/butter01",
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
		TranslationServer.translate("金币  %s") % _format_resource_number(int(player.get("gold", 0))),
		TranslationServer.translate("钻石  %s") % _format_resource_number(int(player.get("gems", 0))),
		TranslationServer.translate("体力  %d/5") % int(player.get("stamina", 5)),
	]
	for i in 3:
		var panel := bar.get_child(i) as Panel
		if panel != null:
			var value_label := panel.get_node("Value") as Label
			_set_text(value_label, values[i])
			CartoonTypography.fit_label(value_label, value_label.get_theme_font_size("font_size"), 6, 6.0)

func _sync_pet_farm_bottom_nav() -> void:
	var nav := get_node_or_null("PetFarmBottomNav") as Control
	if nav == null:
		return
	var nav_labels := {"ranch": "农场", "classroom": "课堂", "social": "广场"}
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
		var feature_id := ""
		if i == 1:
			feature_id = "ranch"
		elif i == 2:
			feature_id = "classroom"
		elif i == 3:
			feature_id = "social"
		var state := _feature_unlock_state(feature_id) if not feature_id.is_empty() else {"unlocked": true}
		var unlocked := bool(state.get("unlocked", true))
		var label := button.get_node_or_null("Text") as Label
		button.disabled = not unlocked
		button.tooltip_text = "" if unlocked else TranslationServer.translate("%s · Lv.%d 解锁") % [TranslationServer.translate(str(state.get("label", ""))), int(state.get("required_level", 1))]
		button.modulate = Color.WHITE if i == active_index else Color(0.92, 0.92, 0.92)
		if not unlocked:
			button.modulate = Color(0.48, 0.48, 0.52, 0.90)
			if selected != null:
				selected.visible = false
			if label != null:
				label.text = TranslationServer.translate("%s %d级") % [TranslationServer.translate(str(nav_labels.get(feature_id, ""))), int(state.get("required_level", 1))]
		elif not feature_id.is_empty():
			if label != null:
				label.text = str(nav_labels.get(feature_id, ""))
		if label != null:
			CartoonTypography.fit_label(label, 11, 6, 4.0)

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

# 首次进入旅馆 hub：Header / ResourceBar / BottomNav 5 个 nav 按钮 stagger
# 只在第一次进入时播放；后续子页面切换仅触发 _play_subpage_entry
func _play_hub_entry() -> void:
	if _hub_entry_played:
		return
	if not is_inside_tree():
		return
	_hub_entry_played = true
	_kill_hub_entry_tweens()

	# Header：从顶部滑下 + 淡入
	var header := get_node_or_null("Header") as Control
	if header != null and header.visible:
		var orig_h_y := header.position.y
		header.position.y = orig_h_y - 12.0
		header.modulate.a = 0.0
		var h_tween := create_tween()
		h_tween.tween_property(header, "modulate:a", 1.0, HUB_HEADER_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		h_tween.parallel().tween_property(header, "position:y", orig_h_y, HUB_HEADER_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_hub_entry_tweens.append(h_tween)

	# PetFarmResourceBar：从顶部滑下 + 淡入（比 Header 稍迟）
	var res_bar := get_node_or_null("PetFarmResourceBar") as Control
	if res_bar != null and res_bar.visible:
		var orig_r_y := res_bar.position.y
		res_bar.position.y = orig_r_y - 10.0
		res_bar.modulate.a = 0.0
		var r_tween := create_tween()
		r_tween.tween_interval(0.05)
		r_tween.tween_property(res_bar, "modulate:a", 1.0, HUB_RESOURCE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		r_tween.parallel().tween_property(res_bar, "position:y", orig_r_y, HUB_RESOURCE_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_hub_entry_tweens.append(r_tween)

	# PetFarmBottomNav 5 个按钮：scale bounce 0.7 → 1.08 → 1.0 + 淡入，依次错开
	var nav := get_node_or_null("PetFarmBottomNav") as Control
	if nav != null and nav.visible:
		for i in 5:
			var btn := nav.get_node_or_null("Nav%d" % (i + 1)) as Control
			if btn == null or not btn.visible:
				continue
			btn.pivot_offset = btn.size * 0.5
			btn.scale = Vector2(0.7, 0.7)
			btn.modulate.a = 0.0
			var n_tween := create_tween()
			n_tween.tween_interval(HUB_NAV_START + HUB_NAV_STAGGER * float(i))
			n_tween.tween_property(btn, "modulate:a", 1.0, HUB_NAV_DURATION) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			n_tween.parallel().tween_property(btn, "scale", Vector2(1.08, 1.08), HUB_NAV_DURATION) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			n_tween.tween_property(btn, "scale", Vector2.ONE, 0.08) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_hub_entry_tweens.append(n_tween)

func _kill_hub_entry_tweens() -> void:
	for t in _hub_entry_tweens:
		if t != null and t.is_valid():
			t.kill()
	_hub_entry_tweens.clear()

# 子页面入场动画：参考胜利界面的奖励槽节奏
# 1) 整页：上浮 + 淡入
# 2) 卡片：从下方弹入 + 淡入（依次错开）
# 3) 底部按钮组：上滑 + 淡入
# 注意：仅修改 modulate.a / scale / position，不改 .visible，保证可见性测试不被破坏
func _play_subpage_entry(page_name: String) -> void:
	if not is_inside_tree() or not has_node("Pages"):
		return
	var page := get_node_or_null("Pages/%s" % _subpage_node_suffix(page_name)) as Control
	if page == null:
		return

	# 先停掉旧的入场 tween（防止连续切换时叠态）
	_kill_subpage_entry_tweens()

	# === 1) 整页上浮 + 淡入 ===
	var orig_page_pos := page.position
	page.position = orig_page_pos + Vector2(0, SUBPAGE_ENTRY_OFFSET_Y)
	page.modulate.a = 0.0
	var page_tween := create_tween()
	page_tween.tween_property(page, "modulate:a", 1.0, SUBPAGE_ENTRY_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	page_tween.parallel().tween_property(page, "position:y", orig_page_pos.y, SUBPAGE_ENTRY_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_subpage_entry_tweens.append(page_tween)

	# === 2) 卡片：从下方弹入 + 淡入，依次错开 ===
	for i in _subpage_card_paths_for(page_name).size():
		var card_path: String = _subpage_card_paths_for(page_name)[i]
		var card := get_node_or_null(card_path) as Control
		if card == null or not card.visible:
			continue
		# 锁定/半透明的卡片不参与入场，保持原状态
		if card.modulate.a < 0.9:
			continue
		card.pivot_offset = Vector2(card.size.x * 0.5, card.size.y)
		card.scale = Vector2(0.6, 0.6)
		card.modulate.a = 0.0
		var card_tween := create_tween()
		card_tween.tween_interval(SUBPAGE_CARD_START + float(i) * SUBPAGE_CARD_STAGGER)
		card_tween.tween_property(card, "modulate:a", 1.0, SUBPAGE_CARD_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		card_tween.parallel().tween_property(card, "scale", Vector2(1.08, 1.08), SUBPAGE_CARD_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(card, "scale", Vector2.ONE, 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_subpage_entry_tweens.append(card_tween)

	# === 3) 底部按钮组：上滑 + 淡入 ===
	var btns := page.get_node_or_null("BottomButtons") as Control
	if btns != null and btns.visible:
		var orig_btn_y := btns.position.y
		btns.position.y = orig_btn_y + 12.0
		btns.modulate.a = 0.0
		var btn_tween := create_tween()
		btn_tween.tween_interval(SUBPAGE_BTN_DELAY)
		btn_tween.tween_property(btns, "modulate:a", 1.0, SUBPAGE_BTN_DURATION)
		btn_tween.parallel().tween_property(btns, "position:y", orig_btn_y, SUBPAGE_BTN_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_subpage_entry_tweens.append(btn_tween)

	# === 4) 子页面专属面板 stagger ===
	_play_subpage_extras(page, page_name)

# 各子页面专属的面板/槽位入场：
#   - ranch：5 个 Slot 依次 scale pop + CollectRow 上滑
#   - classroom：DetailPanel 从左侧滑入 + 淡入
#   - social：PlacePanel 左滑入 + BondPanel 右滑入
func _play_subpage_extras(page: Control, page_name: String) -> void:
	match page_name:
		"ranch":
			for i in SLOT_PATHS.size():
				var slot := get_node_or_null(SLOT_PATHS[i]) as Control
				if slot == null or not slot.visible:
					continue
				slot.pivot_offset = slot.size * 0.5
				slot.scale = Vector2(0.75, 0.75)
				slot.modulate.a = 0.0
				var s_tween := create_tween()
				s_tween.tween_interval(0.08 + float(i) * 0.04)
				s_tween.tween_property(slot, "modulate:a", 1.0, 0.18) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				s_tween.parallel().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.18) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				s_tween.tween_property(slot, "scale", Vector2.ONE, 0.08) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_subpage_entry_tweens.append(s_tween)
			var collect := page.get_node_or_null("CollectRow") as Control
			if collect != null and collect.visible:
				var orig_c_y := collect.position.y
				collect.position.y = orig_c_y + 10.0
				collect.modulate.a = 0.0
				var c_tween := create_tween()
				c_tween.tween_interval(0.22)
				c_tween.tween_property(collect, "modulate:a", 1.0, 0.20) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				c_tween.parallel().tween_property(collect, "position:y", orig_c_y, 0.20) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_subpage_entry_tweens.append(c_tween)
		"classroom":
			var detail := page.get_node_or_null("DetailPanel") as Control
			if detail != null and detail.visible:
				var orig_d_x := detail.position.x
				detail.position.x = orig_d_x - 16.0
				detail.modulate.a = 0.0
				var d_tween := create_tween()
				d_tween.tween_interval(0.06)
				d_tween.tween_property(detail, "modulate:a", 1.0, 0.22) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				d_tween.parallel().tween_property(detail, "position:x", orig_d_x, 0.22) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_subpage_entry_tweens.append(d_tween)
		"social":
			var place := page.get_node_or_null("PlacePanel") as Control
			if place != null and place.visible:
				var orig_p_x := place.position.x
				place.position.x = orig_p_x - 14.0
				place.modulate.a = 0.0
				var p_tween := create_tween()
				p_tween.tween_interval(0.06)
				p_tween.tween_property(place, "modulate:a", 1.0, 0.22) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				p_tween.parallel().tween_property(place, "position:x", orig_p_x, 0.22) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_subpage_entry_tweens.append(p_tween)
			var bond := page.get_node_or_null("BondPanel") as Control
			if bond != null and bond.visible:
				var orig_b_x := bond.position.x
				bond.position.x = orig_b_x + 14.0
				bond.modulate.a = 0.0
				var b_tween := create_tween()
				b_tween.tween_interval(0.12)
				b_tween.tween_property(bond, "modulate:a", 1.0, 0.22) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				b_tween.parallel().tween_property(bond, "position:x", orig_b_x, 0.22) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_subpage_entry_tweens.append(b_tween)

func _kill_subpage_entry_tweens() -> void:
	for t in _subpage_entry_tweens:
		if t != null and t.is_valid():
			t.kill()
	_subpage_entry_tweens.clear()

func _subpage_node_suffix(page_name: String) -> String:
	match page_name:
		"ranch":
			return "RanchPage"
		"classroom":
			return "ClassroomPage"
		"social":
			return "SocialPage"
	return ""

func _subpage_card_paths_for(page_name: String) -> PackedStringArray:
	match page_name:
		"ranch":
			return RANCH_CARD_PATHS
		"classroom":
			return CLASS_CARD_PATHS
		"social":
			return SOCIAL_CARD_PATHS
	return PackedStringArray()

func _attach_interaction_feedback() -> void:
	var paths := [
		"Header/BackButton",
		"Pages/RanchPage/BottomButtons/FocusButton",
		"Pages/SocialPage/PlacePanel/SwitchButton",
		"Pages/SocialPage/BottomButtons/ActionButton",
		"Pages/SocialPage/ResultPopup/ConfirmButton",
		"Pages/ClassroomPage/SellConfirmPopup/CancelButton",
		"Pages/ClassroomPage/SellConfirmPopup/ConfirmButton",
	]
	paths.append_array(SLOT_PATHS)
	paths.append_array(RANCH_CARD_PATHS)
	paths.append_array(CLASS_CARD_PATHS)
	paths.append_array(SOCIAL_CARD_PATHS)
	for path in paths:
		var button := get_node_or_null(path) as BaseButton
		_attach_button_feedback(button, CartoonButtonFeedback.Profile.NAV, false)
	_attach_button_feedback(get_node_or_null("Pages/ClassroomPage/DetailPanel/UpgradeButton") as BaseButton, CartoonButtonFeedback.Profile.PRIMARY, true)
	_attach_button_feedback(get_node_or_null("Pages/ClassroomPage/DetailPanel/EvolveButton") as BaseButton, CartoonButtonFeedback.Profile.ENTRY, true)
	_attach_button_feedback(get_node_or_null("Pages/ClassroomPage/DetailPanel/SellButton") as BaseButton, CartoonButtonFeedback.Profile.ENTRY, true)
	var nav := get_node_or_null("PetFarmBottomNav") as Control
	if nav != null:
		for i in 5:
			_attach_button_feedback(nav.get_node_or_null("Nav%d" % (i + 1)) as BaseButton, CartoonButtonFeedback.Profile.NAV, false)

func _attach_button_feedback(button: BaseButton, profile: int, burst_enabled: bool = true) -> void:
	if button == null or button.has_node("CartoonFeedback"):
		return
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)
	feedback.set_burst_enabled(burst_enabled)

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
	var path := "res://assets/images/ui/gems/items_new_icon_evolution_stone_%s.png" % element
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
	var upgrade := panel.get_node("UpgradeButton") as TextureButton
	var sell := panel.get_node("SellButton") as TextureButton
	var stone_icon := panel.get_node("StoneIcon") as TextureRect
	_apply_classroom_detail_text_style(panel)
	if instance_id.is_empty():
		_clear_sell_pending()
		portrait.visible = false
		target_portrait.visible = false
		stone_icon.visible = false
		empty.visible = true
		evolve.disabled = true
		upgrade.disabled = true
		sell.disabled = true
		(panel.get_node("Stats") as Label).text = ""
		(panel.get_node("Stats") as Label).visible = false
		(panel.get_node("AttributeLabels") as Label).text = ""
		(panel.get_node("AttributeValues") as Label).text = ""
		(panel.get_node("AttributeStats") as Label).text = ""
		(panel.get_node("LeaderSkill") as Label).text = ""
		(panel.get_node("SellButton/Text") as Label).text = "出售"
		_set_action_frame(evolve, false)
	else:
		var instance := _fresh_instance(instance_id)
		var monster_id := str(instance.get("monsterId", _get_monster_id(instance_id)))
		var monster := MonsterDb.get_monster(monster_id)
		var stats := _get_instance_stats(instance_id)
		var info := _get_evolution_info_for_instance(instance_id)
		var target_id := str(info.get("target_id", ""))
		var target := MonsterDb.get_monster(target_id) if not target_id.is_empty() else {}
		var target_name := TranslationServer.translate(str(target.get("name", "最终形态"))) if not target.is_empty() else TranslationServer.translate("最终形态")
		var level := int(instance.get("level", 1))
		var required_level := int(info.get("required_level", 1))
		var item_count := int(info.get("item_count", 0))
		var required_item := str(info.get("required_item", ""))
		portrait.visible = true
		target_portrait.visible = false
		stone_icon.visible = not required_item.is_empty()
		empty.visible = false
		portrait.texture = _portrait_texture(instance_id)
		target_portrait.texture = _monster_portrait_texture(target_id)
		stone_icon.texture = _tex(_evolution_stone_icon_path(required_item))
		var classroom_name := panel.get_node("Name") as Label
		classroom_name.text = "%s%s" % [_elite_prefix(instance), TranslationServer.translate(str(monster.get("name", monster_id)))]
		CartoonTypography.fit_label(classroom_name, 17, 7)
		(panel.get_node("Info") as Label).text = _classroom_info_text(instance, monster)
		(panel.get_node("TargetName") as Label).visible = false
		(panel.get_node("TargetLevel") as Label).visible = false
		(panel.get_node("Arrow") as Label).visible = false
		var compact_stats := panel.get_node("Stats") as Label
		compact_stats.visible = true
		compact_stats.text = _classroom_stats_text(instance, monster, stats)
		(panel.get_node("AttributeLabels") as Label).text = _classroom_attribute_labels_text()
		(panel.get_node("AttributeValues") as Label).text = _classroom_attribute_values_text(instance, monster, stats)
		(panel.get_node("AttributeStats") as Label).text = _classroom_attribute_stats_text(instance, stats)
		for legacy_path in ["AttributeLabels", "AttributeValues", "AttributeStats"]:
			(panel.get_node(legacy_path) as Label).visible = false
		(panel.get_node("LeaderSkill") as Label).text = _classroom_leader_skill_text(monster)
		var current_exp := int(instance.get("exp", 0))
		var needed_exp := GrowthRulesScript.get_exp_for_level(level)
		_sync_exp_progress(panel.get_node("MonsterExpBar") as ProgressBar, current_exp, needed_exp)
		(panel.get_node("MonsterExpText") as Label).text = TranslationServer.translate("当前经验 %d / %d") % [current_exp, needed_exp]
		var pool_exp := int(_storage.get_shared_monster_exp()) if _storage != null and _storage.has_method("get_shared_monster_exp") else 0
		var pool_capacity := int(_storage.get_shared_monster_exp_capacity()) if _storage != null and _storage.has_method("get_shared_monster_exp_capacity") else 1
		_sync_exp_progress(panel.get_node("PoolBar") as ProgressBar, pool_exp, pool_capacity)
		(panel.get_node("PoolText") as Label).text = TranslationServer.translate("总经验槽 %s / %s") % [_format_resource_number(pool_exp), _format_resource_number(pool_capacity)]
		(panel.get_node("LevelRequirement") as Label).text = TranslationServer.translate("等级 %d/%d") % [level, required_level]
		(panel.get_node("StoneRequirement") as Label).text = TranslationServer.translate(str(info.get("item_name", "进化石")))
		(panel.get_node("StoneCount") as Label).text = "%d/1" % item_count
		(panel.get_node("Condition") as Label).text = TranslationServer.translate(str(info.get("condition_text", "无法进化")))
		(panel.get_node("Upgrade") as Label).text = TranslationServer.translate(str(info.get("play_upgrade_text", "玩法: 无")))
		# Even an unavailable evolution stays tappable so players receive the
		# exact missing-level or missing-item feedback.
		evolve.disabled = false
		_set_action_frame(evolve, bool(info.get("can_evolve", false)))
		upgrade.disabled = false
		_set_action_frame(upgrade, pool_exp > 0 and level < StatCalculator.MAX_LEVEL)
		_sync_sell_button(panel, instance_id)
	for button_path in ["UpgradeButton/Text", "EvolveButton/Text", "SellButton/Text"]:
		CartoonTypography.fit_label(panel.get_node(button_path) as Label, CLASSROOM_EVOLVE_BUTTON_FONT_SIZE, 6)
	CartoonTypography.fit_label(panel.get_node("RequirementsTitle") as Label, CLASSROOM_REQUIREMENT_TITLE_FONT_SIZE, 6)
	CartoonTypography.fit_label(panel.get_node("PoolText") as Label, CLASSROOM_REQUIREMENT_FONT_SIZE, 6)
	_sync_card_strip(CLASS_CARD_PATHS, _class_page * CLASS_CARD_PATHS.size(), "classroom")
	_sync_page_buttons("Pages/ClassroomPage/RosterPanel", _class_page, _context_max_page())
	_sync_feature_button("Pages/ClassroomPage/BottomButtons/RanchButton", "ranch", "农场")
	_sync_feature_button("Pages/ClassroomPage/BottomButtons/SocialButton", "social", "广场")


func _sync_feature_button(path: String, feature_id: String, unlocked_text: String) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button == null:
		return
	var state := _feature_unlock_state(feature_id)
	var unlocked := bool(state.get("unlocked", false))
	button.disabled = not unlocked
	button.tooltip_text = "" if unlocked else TranslationServer.translate("%s · Lv.%d 解锁") % [TranslationServer.translate(str(state.get("label", ""))), int(state.get("required_level", 1))]
	button.modulate = Color.WHITE if unlocked else Color(0.50, 0.50, 0.55, 0.90)
	var label := button.get_node_or_null("Text") as Label
	if label != null:
		label.text = unlocked_text if unlocked else "%s Lv.%d" % [unlocked_text, int(state.get("required_level", 1))]
		CartoonTypography.fit_label(label, label.get_theme_font_size("font_size"), 6, 4.0)

func _apply_classroom_detail_text_style(panel: Control) -> void:
	for path in ["Info", "TargetLevel"]:
		var label := panel.get_node_or_null(path) as Label
		if label != null:
			label.add_theme_font_size_override("font_size", CLASSROOM_INFO_FONT_SIZE)
			label.add_theme_constant_override("outline_size", 0)
			label.remove_theme_color_override("font_outline_color")
			label.clip_text = true
	var stats := panel.get_node_or_null("Stats") as Label
	if stats != null:
		stats.add_theme_font_size_override("font_size", CLASSROOM_STATS_FONT_SIZE)
		stats.add_theme_constant_override("line_spacing", -1)
		stats.clip_text = true
		stats.autowrap_mode = TextServer.AUTOWRAP_OFF
	for path in ["AttributeLabels", "AttributeValues", "AttributeStats"]:
		var attribute_label := panel.get_node_or_null(path) as Label
		if attribute_label != null:
			attribute_label.add_theme_font_size_override("font_size", CLASSROOM_STATS_FONT_SIZE)
			attribute_label.add_theme_constant_override("outline_size", 0)
			attribute_label.clip_text = false
			attribute_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var leader_skill := panel.get_node_or_null("LeaderSkill") as Label
	if leader_skill != null:
		leader_skill.add_theme_font_size_override("font_size", CLASSROOM_LEADER_SKILL_FONT_SIZE)
		leader_skill.add_theme_constant_override("line_spacing", 0)
		leader_skill.add_theme_constant_override("outline_size", 0)
		leader_skill.clip_text = true
		leader_skill.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var title := panel.get_node_or_null("RequirementsTitle") as Label
	if title != null:
		title.add_theme_font_size_override("font_size", CLASSROOM_REQUIREMENT_TITLE_FONT_SIZE)
		title.clip_text = true
	for path in ["LevelRequirement", "StoneRequirement", "StoneCount"]:
		var label := panel.get_node_or_null(path) as Label
		if label != null:
			label.add_theme_font_size_override("font_size", CLASSROOM_REQUIREMENT_FONT_SIZE)
			label.add_theme_constant_override("outline_size", 0)
			label.clip_text = false
	var evolve_text := panel.get_node_or_null("EvolveButton/Text") as Label
	if evolve_text != null:
		evolve_text.add_theme_font_size_override("font_size", CLASSROOM_EVOLVE_BUTTON_FONT_SIZE)
	var upgrade_text := panel.get_node_or_null("UpgradeButton/Text") as Label
	if upgrade_text != null:
		upgrade_text.add_theme_font_size_override("font_size", CLASSROOM_EVOLVE_BUTTON_FONT_SIZE)
	var sell_text := panel.get_node_or_null("SellButton/Text") as Label
	if sell_text != null:
		sell_text.add_theme_font_size_override("font_size", CLASSROOM_EVOLVE_BUTTON_FONT_SIZE)

func _sync_exp_progress(bar: ProgressBar, value: int, maximum: int) -> void:
	bar.max_value = max(1, maximum)
	bar.value = clampi(value, 0, maximum)
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.45, 0.25, 0.08, 0.28)
	background.corner_radius_top_left = 6
	background.corner_radius_top_right = 6
	background.corner_radius_bottom_left = 6
	background.corner_radius_bottom_right = 6
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.38, 0.78, 0.24, 1.0)
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

func _fresh_instance(instance_id: String) -> Dictionary:
	if instance_id.is_empty():
		return {}
	if _storage != null and _storage.has_method("get_monster_instance"):
		var current: Dictionary = _storage.get_monster_instance(instance_id)
		if not current.is_empty():
			_instance_by_id[instance_id] = current
			_monster_id_by_instance[instance_id] = str(current.get("monsterId", ""))
			_level_by_instance[instance_id] = int(current.get("level", 1))
			_stats_by_instance.erase(instance_id)
			return current
	return _get_instance(instance_id)

func _classroom_info_text(instance: Dictionary, monster: Dictionary) -> String:
	return "Lv.%d · %d★" % [int(instance.get("level", 1)), int(monster.get("rarity", 1))]

func _classroom_stats_text(instance: Dictionary, monster: Dictionary, stats: Dictionary) -> String:
	var rarity := int(stats.get("rarity", monster.get("rarity", 1)))
	var power := _classroom_power(stats)
	return TranslationServer.translate("Lv.%d · %s\n性格 %s · 性别 %s\n%d★ · 精英 %s\nHP %d · ATK %d\nDEF %d · SPD %d\n战力 %d") % [int(instance.get("level", 1)), TranslationServer.translate(str(ELEMENT_LABELS.get(str(monster.get("element", "")), str(monster.get("element", ""))))), _get_nature_name(str(instance.get("nature", ""))), _gender_label(instance), rarity, TranslationServer.translate("是" if bool(instance.get("isElite", false)) else "否"), int(stats.get("hp", 0)), int(stats.get("atk", 0)), int(stats.get("def", 0)), int(stats.get("spd", 0)), power]

func _classroom_attribute_labels_text() -> String:
	return TranslationServer.translate("等级\n属性\n性格\n性别\n稀有度\n精英")

func _classroom_attribute_values_text(instance: Dictionary, monster: Dictionary, stats: Dictionary) -> String:
	var rarity := int(stats.get("rarity", monster.get("rarity", 1)))
	return "Lv.%d\n%s\n%s\n%s\n%s\n%s" % [
		int(instance.get("level", 1)),
		TranslationServer.translate(str(ELEMENT_LABELS.get(str(monster.get("element", "")), str(monster.get("element", ""))))),
		TranslationServer.translate(_get_nature_name(str(instance.get("nature", "")))),
		TranslationServer.translate(_gender_label(instance)),
		"★".repeat(rarity),
		TranslationServer.translate("是" if bool(instance.get("isElite", false)) else "否"),
	]

func _classroom_attribute_stats_text(instance: Dictionary, stats: Dictionary) -> String:
	return TranslationServer.translate("HP：%d\nATK：%d\nDEF：%d\nSPD：%d\n战力：%d\n满级：%s") % [
		int(stats.get("hp", 0)),
		int(stats.get("atk", 0)),
		int(stats.get("def", 0)),
		int(stats.get("spd", 0)),
		_classroom_power(stats),
		TranslationServer.translate("是" if int(instance.get("level", 1)) >= StatCalculator.MAX_LEVEL else "否"),
	]

func _classroom_leader_skill_text(monster: Dictionary) -> String:
	var skill_id := str(monster.get("leaderSkill", ""))
	if skill_id.is_empty():
		return "队长技能：无"
	var skill := LeaderSkillDb.get_leader_skill(skill_id)
	if skill.is_empty():
		return "队长技能：未知"
	var desc := TranslationServer.translate(str(skill.get("desc", "")))
	var skill_name := TranslationServer.translate(str(skill.get("name", "未知")))
	if desc.is_empty():
		return TranslationServer.translate("队长技能：%s") % skill_name
	# This panel is already the leader-skill section. A dedicated name line
	# keeps longer Latin descriptions readable without colliding with stats.
	return "%s\n%s" % [skill_name, desc]

func _classroom_power(stats: Dictionary) -> int:
	return int(stats.get("hp", 0)) + int(stats.get("atk", 0)) + int(stats.get("def", 0)) + int(stats.get("spd", 0))

func _sync_sell_button(panel: Control, instance_id: String) -> void:
	var sell := panel.get_node_or_null("SellButton") as TextureButton
	if sell == null:
		return
	sell.disabled = false
	var text := sell.get_node_or_null("Text") as Label
	if text != null:
		text.text = "出售"

func _show_sell_confirm_dialog(quote: Dictionary) -> void:
	var popup := get_node_or_null("Pages/ClassroomPage/SellConfirmPopup") as Control
	if popup == null:
		_show_status("出售确认界面不可用")
		return
	(popup.get_node("Panel/Name") as Label).text = TranslationServer.translate(str(quote.get("name", "该精灵")))
	(popup.get_node("Panel/Detail") as Label).text = TranslationServer.translate("星级 %s · Lv.%d") % ["★".repeat(int(quote.get("rarity", 1))), int(quote.get("level", 1))]
	(popup.get_node("Panel/Reward") as Label).text = TranslationServer.translate("可获得 %s") % _sell_reward_text(quote)
	popup.visible = true

func _hide_sell_confirm_popup() -> void:
	var popup := get_node_or_null("Pages/ClassroomPage/SellConfirmPopup") as Control
	if popup != null:
		popup.visible = false

func _clear_sell_pending() -> void:
	_sell_pending_instance_id = ""
	_sell_pending_quote = {}
	_hide_sell_confirm_popup()

func _sell_reward_text(quote: Dictionary) -> String:
	var amount := int(quote.get("amount", 0))
	var currency := str(quote.get("currency", "gold"))
	return "+%d%s" % [amount, "宝石" if currency == "gems" else "金币"]

func _select_classroom_after_removed(removed_instance_id: String) -> void:
	if _captured_monsters.is_empty():
		_class_selected_instance_id = ""
		_class_page = 0
		return
	_class_page = clampi(_class_page, 0, _context_max_page())
	for instance: Dictionary in _captured_monsters:
		var instance_id := _get_instance_id(instance)
		if instance_id != removed_instance_id:
			_class_selected_instance_id = instance_id
			return
	_class_selected_instance_id = _get_instance_id(_captured_monsters[0])

func _play_upgrade_feedback(before: Dictionary, after: Dictionary, result: Dictionary, pool_before: int, pool_after: int) -> void:
	_kill_upgrade_feedback_tweens()
	var panel := _node("Pages/ClassroomPage/DetailPanel")
	var feedback := panel.get_node("UpgradeFeedback") as Control
	var glow := feedback.get_node("Glow") as TextureRect
	var message := feedback.get_node("Message") as Label
	var transfer := feedback.get_node("Transfer") as Label
	var portrait := panel.get_node("Portrait") as TextureRect
	var info := panel.get_node("Info") as Label
	var stats := panel.get_node("Stats") as Label
	var monster_bar := panel.get_node("MonsterExpBar") as ProgressBar
	var monster_text := panel.get_node("MonsterExpText") as Label
	var pool_bar := panel.get_node("PoolBar") as ProgressBar
	var pool_text := panel.get_node("PoolText") as Label
	var pool_title := panel.get_node("RequirementsTitle") as Label
	var upgrade := panel.get_node("UpgradeButton") as TextureButton
	var old_level := int(before.get("level", 1))
	var new_level := int(after.get("level", old_level))
	var old_exp := int(before.get("exp", 0))
	var new_exp := int(after.get("exp", old_exp))
	var old_needed := GrowthRulesScript.get_exp_for_level(old_level)
	var new_needed := GrowthRulesScript.get_exp_for_level(new_level)
	var consumed := int(result.get("consumed", 0))
	var leveled_up := new_level > old_level
	var after_monster := MonsterDb.get_monster(str(after.get("monsterId", "")))
	var after_stats := MonsterService.get_owned_stats(str(after.get("monsterId", "")), new_level, str(after.get("nature", "")), bool(after.get("isElite", false)))

	_upgrade_animating = true
	upgrade.disabled = false
	feedback.visible = true
	feedback.modulate = Color.WHITE
	glow.pivot_offset = glow.size * 0.5
	glow.scale = Vector2(0.62, 0.62)
	glow.modulate.a = 0.0
	message.pivot_offset = message.size * 0.5
	message.scale = Vector2(0.60, 0.60)
	message.modulate.a = 0.0
	message.text = TranslationServer.translate("升级成功  Lv.%d!") % new_level if leveled_up else TranslationServer.translate("经验注入 +%d") % consumed
	transfer.position.y = 226.0
	transfer.modulate.a = 0.0
	transfer.text = TranslationServer.translate("经验槽 -%d  →  精灵 +%d") % [consumed, consumed]
	pool_title.visible = false
	portrait.pivot_offset = portrait.size * 0.5
	info.pivot_offset = info.size * 0.5
	stats.pivot_offset = stats.size * 0.5
	if leveled_up:
		var before_monster := MonsterDb.get_monster(str(before.get("monsterId", "")))
		var before_stats := MonsterService.get_owned_stats(str(before.get("monsterId", "")), old_level, str(before.get("nature", "")), bool(before.get("isElite", false)))
		info.text = _classroom_info_text(before, before_monster)
		stats.text = _classroom_stats_text(before, before_monster, before_stats)

	monster_bar.max_value = old_needed
	monster_bar.value = old_exp
	monster_text.text = TranslationServer.translate("当前经验 %d / %d") % [old_exp, old_needed]
	pool_bar.value = pool_before
	pool_text.text = TranslationServer.translate("总经验槽 %s / %s") % [_format_resource_number(pool_before), _format_resource_number(int(pool_bar.max_value))]

	var pool_tween := create_tween()
	_upgrade_value_tweens.append(pool_tween)
	pool_tween.tween_method(_set_pool_feedback_value.bind(pool_bar, pool_text), float(pool_before), float(pool_after), 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var exp_tween := create_tween()
	_upgrade_value_tweens.append(exp_tween)
	if leveled_up:
		exp_tween.tween_method(_set_monster_feedback_value.bind(monster_bar, monster_text, old_needed), float(old_exp), float(old_needed), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		exp_tween.tween_callback(_reset_level_exp_bar.bind(monster_bar, monster_text, new_exp, new_needed, info, stats, after, after_monster, after_stats))
	else:
		exp_tween.tween_method(_set_monster_feedback_value.bind(monster_bar, monster_text, old_needed), float(old_exp), float(new_exp), 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_upgrade_feedback_tween = create_tween()
	_upgrade_feedback_tween.set_parallel(true)
	_upgrade_feedback_tween.tween_property(glow, "modulate:a", 0.95 if leveled_up else 0.55, 0.18)
	_upgrade_feedback_tween.tween_property(glow, "scale", Vector2(1.08, 1.08), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_feedback_tween.tween_property(message, "modulate:a", 1.0, 0.12)
	_upgrade_feedback_tween.tween_property(message, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_feedback_tween.tween_property(transfer, "modulate:a", 1.0, 0.12)
	_upgrade_feedback_tween.tween_property(transfer, "position:y", 208.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_upgrade_feedback_tween.tween_property(portrait, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_feedback_tween.tween_property(info, "scale", Vector2(1.14, 1.14), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_feedback_tween.tween_property(stats, "modulate", Color(1.18, 0.96, 0.48, 1.0), 0.22)
	_upgrade_feedback_tween.chain().tween_interval(0.34)
	_upgrade_feedback_tween.chain().set_parallel(true)
	_upgrade_feedback_tween.tween_property(glow, "modulate:a", 0.0, 0.30)
	_upgrade_feedback_tween.tween_property(message, "modulate:a", 0.0, 0.26)
	_upgrade_feedback_tween.tween_property(transfer, "modulate:a", 0.0, 0.24)
	_upgrade_feedback_tween.tween_property(portrait, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_upgrade_feedback_tween.tween_property(info, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_upgrade_feedback_tween.tween_property(stats, "modulate", Color.WHITE, 0.24)
	_upgrade_feedback_tween.chain().tween_callback(_finish_upgrade_feedback)
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("powerup_burst_soft")

func _set_pool_feedback_value(value: float, bar: ProgressBar, label: Label) -> void:
	bar.value = value
	label.text = TranslationServer.translate("总经验槽 %s / %s") % [_format_resource_number(roundi(value)), _format_resource_number(roundi(bar.max_value))]

func _set_monster_feedback_value(value: float, bar: ProgressBar, label: Label, maximum: int) -> void:
	bar.value = value
	label.text = TranslationServer.translate("当前经验 %d / %d") % [roundi(value), maximum]

func _reset_level_exp_bar(bar: ProgressBar, label: Label, value: int, maximum: int, info: Label, stats: Label, instance: Dictionary, monster: Dictionary, current_stats: Dictionary) -> void:
	bar.max_value = maximum
	bar.value = value
	bar.self_modulate = Color(1.28, 1.10, 0.42, 1.0)
	label.text = TranslationServer.translate("当前经验 %d / %d") % [value, maximum]
	info.text = _classroom_info_text(instance, monster)
	stats.text = _classroom_stats_text(instance, monster, current_stats)
	var flash := create_tween()
	flash.tween_property(bar, "self_modulate", Color.WHITE, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _finish_upgrade_feedback() -> void:
	_upgrade_animating = false
	_upgrade_value_tweens.clear()
	var feedback := get_node_or_null("Pages/ClassroomPage/DetailPanel/UpgradeFeedback") as Control
	if feedback != null:
		feedback.visible = false
	var pool_title := get_node_or_null("Pages/ClassroomPage/DetailPanel/RequirementsTitle") as Label
	if pool_title != null:
		pool_title.visible = true
	_sync_gui()

func _kill_upgrade_feedback_tweens() -> void:
	if _upgrade_feedback_tween != null and _upgrade_feedback_tween.is_valid():
		_upgrade_feedback_tween.kill()
	for tween in _upgrade_value_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_upgrade_value_tweens.clear()

func _sync_social_page() -> void:
	_sync_social_place()
	_sync_card_strip(SOCIAL_CARD_PATHS, _social_page * SOCIAL_CARD_PATHS.size(), "social")
	_sync_page_buttons("Pages/SocialPage/RosterPanel", _social_page, _context_max_page())

func _sync_social_place() -> void:
	var place := _current_social_place()
	var config := SocialRulesScript.place_config_for(place)
	var panel := _node("Pages/SocialPage/PlacePanel")
	_apply_social_observation_text_style()
	var heart_bubble := panel.get_node_or_null("HeartBubble") as TextureRect
	if heart_bubble != null:
		heart_bubble.visible = false
	(panel.get_node("Title") as Label).text = TranslationServer.translate(str(config.get("name", "社交场所")))
	(panel.get_node("Duration") as Label).text = TranslationServer.translate("用时%s") % SocialRulesScript.duration_label_for_place(place)
	var switch_button := panel.get_node("SwitchButton") as TextureButton
	switch_button.disabled = place.get("started_at", null) != null
	_set_action_frame(switch_button, not switch_button.disabled)
	_sync_social_heart_fx(place)
	_sync_social_slot(panel.get_node("SlotA") as TextureButton, "slot_a", place)
	_sync_social_slot(panel.get_node("SlotB") as TextureButton, "slot_b", place)
	(panel.get_node("Preview") as Label).text = _social_preview_text(place)
	var detail := _social_relationship_detail(place)
	var relation_text := "放入两只精灵后显示学习概率"
	if not detail.is_empty():
		relation_text = TranslationServer.translate("性格学习概率 %d%%") % int(detail.get("successPercent", 0))
	(panel.get_node("Relationship/Text") as Label).text = relation_text
	var bond_panel := _node("Pages/SocialPage/BondPanel")
	(bond_panel.get_node("BondTitle") as Label).text = TranslationServer.translate("%s · 1小时性格交流") % TranslationServer.translate(str(config.get("name", "社交场所")))
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
	return clampf(float(detail.get("successPercent", 0)) / 100.0, 0.08, 1.0)

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
		var start_scale := Vector2.ONE * (1.30 + float(i % 3) * 0.12)
		var drift := -15.0 + float(i) * 10.0
		heart.visible = true
		heart.pivot_offset = heart.size * 0.5
		var tween := create_tween().set_loops()
		tween.tween_interval(float(i) * 0.38)
		tween.tween_callback(_reset_social_heart_fx.bind(heart, start_position, start_scale))
		tween.tween_property(heart, "modulate:a", 0.95, 0.28)
		tween.parallel().tween_property(heart, "scale", start_scale * 1.18, 0.28)
		tween.tween_property(heart, "position", start_position + Vector2(drift, -34.0), 1.30)
		tween.parallel().tween_property(heart, "scale", start_scale * 1.45, 1.30)
		tween.tween_property(heart, "position", start_position + Vector2(drift * 1.45, -66.0), 0.95)
		tween.parallel().tween_property(heart, "modulate:a", 0.0, 0.95)
		tween.tween_interval(0.22)
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
	var raw_instance_id = place.get(slot_key, "")
	var instance_id := "" if raw_instance_id == null else str(raw_instance_id)
	if instance_id == "<null>" or instance_id == "null":
		instance_id = ""
	var selected := _social_selected_slot == slot_key
	var frame := node.get_node("Frame") as TextureRect
	var portrait := node.get_node("Portrait") as TextureRect
	var check := node.get_node("Check") as TextureRect
	var name_label := node.get_node("Name") as Label
	var detail_label := node.get_node("Detail") as Label
	check.visible = false
	frame.texture = _tex(SOCIAL_EMPTY_SLOT_TEXTURE)
	frame.visible = instance_id.is_empty()
	frame.z_index = 2
	frame.modulate = Color(1, 1, 1, 1)
	frame.position = Vector2(16.0, 12.0) if selected and instance_id.is_empty() else Vector2(24.0, 21.0)
	frame.size = Vector2(88.0, 94.0) if selected and instance_id.is_empty() else Vector2(72.0, 78.0)
	if instance_id.is_empty():
		portrait.visible = false
		name_label.visible = false
		detail_label.visible = false
		return
	var instance := _get_instance(instance_id)
	var monster := MonsterDb.get_monster(str(instance.get("monsterId", "")))
	if instance.is_empty() or monster.is_empty():
		frame.visible = true
		portrait.visible = false
		name_label.visible = false
		detail_label.visible = false
		return
	portrait.visible = true
	portrait.z_index = 3
	name_label.visible = true
	detail_label.visible = true
	portrait.texture = _portrait_texture(instance_id)
	name_label.text = "%s%s" % [_elite_prefix(instance), TranslationServer.translate(str(monster.get("name", "")))]
	CartoonTypography.fit_label(name_label, 17, 7)
	detail_label.text = "%s %s" % [_gender_label(instance), _get_nature_name(str(instance.get("nature", "")))]

func _apply_social_observation_text_style() -> void:
	var bond_panel := get_node_or_null("Pages/SocialPage/BondPanel") as Control
	if bond_panel == null:
		return
	var title := bond_panel.get_node_or_null("BondTitle") as Label
	if title != null:
		title.add_theme_font_size_override("font_size", SOCIAL_BOND_TITLE_FONT_SIZE)
		title.clip_text = true
	var progress := bond_panel.get_node_or_null("ProgressText") as Label
	if progress != null:
		progress.add_theme_font_size_override("font_size", SOCIAL_BOND_TEXT_FONT_SIZE)
		progress.clip_text = true
	var summary := bond_panel.get_node_or_null("Summary") as Label
	if summary != null:
		summary.add_theme_font_size_override("font_size", SOCIAL_BOND_SUMMARY_FONT_SIZE)
		summary.clip_text = true

func _sync_card_strip(paths: Array, start_index: int, context: String) -> void:
	var used := _used_monsters()
	var place := _current_social_place()
	var team_ids := _team_instance_ids()
	for i in paths.size():
		var card := get_node(paths[i]) as TextureButton
		var idx := start_index + i
		_set_visible(card, idx < _captured_monsters.size())
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
		var in_team := team_ids.has(instance_id) or (team_ids.is_empty() and _is_instance_in_team(instance_id))
		_sync_card(card, instance_id, selected, context, in_team)
		var ranch_locked := context == "social" and _is_instance_in_ranch(instance_id)
		card.modulate = Color(1.0, 1.0, 1.0, 0.52) if ranch_locked else Color.WHITE
		card.tooltip_text = "农场挂机中，先从农场取下" if ranch_locked else ""

func _sync_card(card: TextureButton, instance_id: String, selected: bool, context: String, in_team: bool = false) -> void:
	var monster := MonsterDb.get_monster(_get_monster_id(instance_id))
	var instance := _get_instance(instance_id)
	_set_texture(card.get_node("Portrait") as TextureRect, _portrait_texture(instance_id))
	var card_name := card.get_node("Name") as Label
	_set_text(card_name, "%s%s" % [_elite_prefix(instance), TranslationServer.translate(str(monster.get("name", "")))])
	CartoonTypography.fit_label(card_name, 12, 6)
	_set_text(card.get_node("Level") as Label, "Lv.%d" % _get_monster_level(instance_id))
	_sync_owned_no_label(card, instance_id)
	var detail_label := card.get_node("Detail") as Label
	_set_visible(detail_label, false)
	_set_text(detail_label, _get_nature_name(str(instance.get("nature", ""))).substr(0, 3))
	var check := card.get_node("Check") as TextureRect
	_set_visible(check, selected)
	var selection_mark := card.get_node_or_null("SelectionMark") as Label
	if selection_mark != null:
		selection_mark.position = Vector2(7.0, 55.0)
		selection_mark.size = Vector2(49.0, 18.0)
		selection_mark.text = _team_badge_text()
		selection_mark.add_theme_font_size_override("font_size", 8)
		selection_mark.add_theme_color_override("font_color", Color(1.0, 0.97, 0.76, 1.0))
		selection_mark.add_theme_color_override("font_outline_color", Color(0.06, 0.28, 0.10, 1.0))
		selection_mark.add_theme_constant_override("outline_size", 3)
		_set_visible(selection_mark, in_team)

func _sync_owned_no_label(card: TextureButton, instance_id: String) -> void:
	var label := card.get_node_or_null("OwnedNo") as Label
	if label == null:
		label = Label.new()
		label.name = "OwnedNo"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)
	label.position = Vector2(24.0, 3.0)
	label.size = Vector2(28.0, 15.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.43, 0.24, 0.07, 1.0))
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.84, 1.0))
	label.add_theme_constant_override("outline_size", 1)
	var owned_no := _owned_no_label(instance_id)
	label.text = owned_no
	label.visible = not owned_no.is_empty()

func _sync_page_buttons(panel_path: String, page: int, page_max: int) -> void:
	var previous := get_node(panel_path + "/PreviousButton") as TextureButton
	var next := get_node(panel_path + "/NextButton") as TextureButton
	previous.visible = page_max > 0
	next.visible = page_max > 0
	previous.disabled = page <= 0
	next.disabled = page >= page_max
	var page_text := get_node_or_null(panel_path + "/PageText") as Label
	if page_text != null:
		_set_text(page_text, "%d / %d" % [page + 1, page_max + 1])

func _sync_result_popup() -> void:
	var popup := _node("Pages/SocialPage/ResultPopup")
	popup.visible = not _social_result_popup.is_empty()
	if not popup.visible:
		return
	var result := _social_result_popup
	var accent := TEXT_GOLD
	var title := popup.get_node("Panel/Title") as Label
	title.text = _social_result_title(result)
	title.modulate = accent
	(popup.get_node("Panel/Score") as Label).text = TranslationServer.translate("本次性格学习概率 %d%%") % int(result.get("success_percent", 0))
	(popup.get_node("Panel/Event") as Label).text = str(result.get("place_name", "社交场所"))
	(popup.get_node("Panel/Flavor") as Label).text = str(result.get("rule_text", ""))
	var lines := _social_result_major_lines(result)
	for i in 3:
		var line := popup.get_node("Panel/Line%d" % (i + 1)) as Label
		line.text = str(lines[i]) if i < lines.size() else ""

func _portrait_texture(instance_id: String) -> Texture2D:
	return _monster_portrait_texture(_get_monster_id(instance_id))

func _monster_portrait_texture(monster_id: String) -> Texture2D:
	var path := _portrait_path(monster_id)
	return _tex(path) if not path.is_empty() else null

func _portrait_path(monster_id: String) -> String:
	if _portrait_path_cache.has(monster_id):
		return str(_portrait_path_cache[monster_id])
	var path := MonsterArtDBScript.get_art_path(monster_id, "ranch")
	_portrait_path_cache[monster_id] = path
	return path

func _button_label(button: TextureButton) -> Label:
	return button.get_node("Text") as Label

func _set_text(label: Label, value: String) -> void:
	if label.text != value:
		label.text = value

func _set_texture(node: TextureRect, value: Texture2D) -> void:
	if node.texture != value:
		node.texture = value

func _set_visible(node: CanvasItem, value: bool) -> void:
	if node.visible != value:
		node.visible = value

func _set_action_frame(button: TextureButton, enabled: bool) -> void:
	# The visual is authored in ranch_hub.tscn (butter01/butter02). Runtime
	# only communicates disabled state by tinting that art; it never overlays
	# a generated Panel or replacement texture.
	var art := button.get_node_or_null("butter02") as CanvasItem
	if art == null:
		art = button.get_node_or_null("butter01") as CanvasItem
	if art != null:
		art.modulate = Color.WHITE if enabled else Color(0.68, 0.68, 0.68, 0.88)

func _label(path: String) -> Label:
	return get_node(path) as Label

func _node(path: String) -> Control:
	return get_node(path) as Control

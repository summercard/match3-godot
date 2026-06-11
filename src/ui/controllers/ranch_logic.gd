# ranch_logic.gd - 精灵牧场界面的旧脚本逻辑父类
# 美术包装：按概念图重排，image-2 牧场资产 + Canvas 绘制
class_name SceneRanch
extends Control

signal exp_collected(total_exp: int)

const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const ItemDBScript = preload("res://src/data/item_db.gd")
const SocialRulesScript = preload("res://src/core/social_rules.gd")
const EvolutionRulesScript = preload("res://src/core/evolution_rules.gd")
const ELEMENT_LABELS := {
	"fire": "火", "water": "水", "grass": "草",
	"thunder": "雷", "light": "光", "dark": "暗"
}

const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0
const SLOT_COUNT: int = 5
const IDLE_INTERVAL_MS: float = 5.0 * 60.0 * 1000.0
const IDLE_MAX_MS: float = 8.0 * 60.0 * 60.0 * 1000.0

const RANCH_ASSETS := {
	"bg": "res://assets/images/ui/backgrounds/ranch_bg_ranch_pasture.png",
	"header": "res://assets/images/ui/bars/ranch_ui_header_plaque.png",
	"back": "res://assets/images/ui/buttons/ranch_ui_back_button.png",
	"slot_occupied": "res://assets/images/ui/slots/ranch_ui_slot_occupied.png",
	"slot_empty": "res://assets/images/ui/slots/ranch_ui_slot_empty.png",
	"slot_locked": "res://assets/images/ui/slots/ranch_ui_slot_locked.png",
	"level_badge": "res://assets/images/ui/icons/ranch_ui_level_badge.png",
	"timer_plate": "res://assets/images/ui/panels/ranch_ui_timer_plate.png",
	"collect_button": "res://assets/images/ui/buttons/ranch_ui_btn_collect_gold.png",
	"status_ribbon": "res://assets/images/ui/panels/ranch_ui_status_ribbon_green.png",
	"reward_strip": "res://assets/images/ui/panels/ranch_ui_reward_strip_dark.png",
	"exp": "res://assets/images/ui/icons/ranch_icon_exp_badge.png",
	"coin": "res://assets/images/ui/icons/ranch_icon_gold_coin.png",
	"check": "res://assets/images/ui/icons/ranch_icon_check_badge.png",
	"banner": "res://assets/images/ui/panels/ranch_ui_banner_small.png",
	"banner_fringe": "res://assets/images/ui/panels/ranch_ui_banner_fringe.png",
	"sparkle": "res://assets/images/effects/ranch_fx_leaf_sparkle_cluster.png",
	"nav_button": "res://assets/images/ui/buttons/team_ui_btn_cancel.png",
	"secondary_button": "res://assets/images/ui/buttons/album_ui_btn_secondary_blue.png",
	"roster_card": "res://assets/images/ui/cards/ranch_ui_roster_card_ranch.png",
	"roster_card_selected": "res://assets/images/ui/cards/ranch_ui_roster_card_ranch_selected.png",
	"previous_round": "res://assets/images/ui/buttons/ranch_ui_btn_previous_round.png",
	"next_round": "res://assets/images/ui/buttons/ranch_ui_btn_next_round.png",
	"pet_farm_nav_panel": "res://assets/images/ui/icons/ranch_ui_pet_farm_nav_panel.png",
	"pet_farm_nav_selected": "res://assets/images/ui/icons/ranch_ui_pet_farm_nav_selected.png",
	"pet_classroom": "res://assets/images/ui/icons/common_nav_icon_nav_classroom.png",
	"social_plaza": "res://assets/images/ui/icons/common_nav_icon_nav_social.png",
	"pet_tab": "res://assets/images/ui/icons/common_nav_icon_nav_pets.png",
	"menu_tab": "res://assets/images/ui/icons/common_nav_icon_nav_menu.png",
	"classroom_detail": "res://assets/images/ui/panels/ranch_ui_classroom_detail_panel.png",
	"care_roster_panel": "res://assets/images/ui/panels/ranch_ui_care_roster_panel.png",
	"social_place": "res://assets/images/ui/panels/ranch_ui_social_place_panel.png",
	"social_slot": "res://assets/images/ui/slots/ranch_ui_social_slot_frame.png",
	"social_result": "res://assets/images/ui/panels/ranch_ui_social_result_panel.png",
	"relationship": "res://assets/images/ui/panels/ranch_ui_relationship_ribbon.png",
	"prev_arrow": "res://assets/images/ui/buttons/stage_icon_prev_arrow.png",
	"next_arrow": "res://assets/images/ui/buttons/stage_icon_next_arrow.png",
	"scrollbar": "res://assets/images/ui/bars/inventory_ui_scrollbar.png",
}

const C := {
	"text": Color(1.0, 1.0, 1.0),
	"text_muted": Color(0.66, 0.72, 0.82),
	"gold": Color(1.0, 0.84, 0.25),
	"green": Color(0.47, 0.95, 0.31),
	"dark": Color(0.03, 0.06, 0.13, 0.86),
}

const SLOT_RECTS := [
	Rect2(20.0, 208.0, 106.0, 112.0),
	Rect2(134.0, 198.0, 106.0, 112.0),
	Rect2(248.0, 208.0, 106.0, 112.0),
	Rect2(78.0, 320.0, 108.0, 112.0),
	Rect2(204.0, 323.0, 108.0, 112.0),
]

const BACK_RECT := Rect2(12.0, 13.0, 60.0, 48.0)
const LIST_RECT := Rect2(10.0, 486.0, 355.0, 130.0)
const LIST_CLIP_RECT := Rect2(49.0, 502.0, 277.0, 88.0)
const LIST_CARD_W: float = 70.0
const LIST_CARD_H: float = 82.0
const LIST_CARD_GAP: float = 14.0
const LIST_CARD_START_X: float = 65.0
const LIST_CARD_Y: float = 504.0
const LIST_LEFT_ARROW_RECT := Rect2(10.0, 500.0, 39.0, 92.0)
const LIST_RIGHT_ARROW_RECT := Rect2(326.0, 500.0, 39.0, 92.0)
const COLLECT_RECT := Rect2(263.0, 439.0, 91.0, 44.0)
const RANCH_FOCUS_RECT := Rect2(10.0, 621.0, 112.0, 45.0)
const RANCH_CLASSROOM_RECT := Rect2(131.0, 621.0, 112.0, 45.0)
const RANCH_SOCIAL_RECT := Rect2(252.0, 621.0, 112.0, 45.0)
const BOTTOM_LEFT_RECT := Rect2(14.0, 610.0, 105.0, 48.0)
const BOTTOM_RIGHT_RECT := Rect2(256.0, 610.0, 105.0, 48.0)
const CLASS_DETAIL_RECT := Rect2(12.0, 84.0, 351.0, 194.0)
const CLASS_LIST_RECT := Rect2(10.0, 288.0, 355.0, 254.0)
const CLASS_LIST_CLIP_RECT := Rect2(20.0, 304.0, 335.0, 222.0)
const CLASS_COLS: int = 3
const CLASS_CARD_W: float = 96.0
const CLASS_CARD_H: float = 112.0
const CLASS_CARD_GAP: float = 8.0
const CLASS_GRID_X: float = 31.0
const CLASS_GRID_Y: float = 307.0
const CLASS_EVOLVE_RECT := Rect2(238.0, 226.0, 108.0, 46.0)
const CLASS_LEFT_ARROW_RECT := Rect2(11.0, 536.0, 44.0, 54.0)
const CLASS_RIGHT_ARROW_RECT := Rect2(320.0, 536.0, 44.0, 54.0)
const SOCIAL_PLACE_RECT := Rect2(12.0, 84.0, 351.0, 194.0)
const SOCIAL_SLOT_A_RECT := Rect2(27.0, 146.0, 101.0, 90.0)
const SOCIAL_SLOT_B_RECT := Rect2(247.0, 146.0, 101.0, 90.0)
const SOCIAL_ACTION_RECT := Rect2(135.0, 229.0, 105.0, 46.0)
const SOCIAL_PLACE_SWITCH_RECT := Rect2(250.0, 91.0, 98.0, 44.0)
const SOCIAL_RELATION_RECT := Rect2(22.0, 246.0, 331.0, 25.0)
const SOCIAL_RESULT_POPUP_RECT := Rect2(25.0, 111.0, 325.0, 392.0)
const SOCIAL_RESULT_CLOSE_RECT := Rect2(125.0, 443.0, 125.0, 46.0)
const SUBPAGE_RIBBON_RECT := Rect2(18.0, 555.0, 339.0, 42.0)

var _game: Node = null
var _storage: Node = null
var _active_page: String = "ranch"
var _selected_slot: int = 0
var _slots_data: Array = []
var _social_places: Array = []
var _social_selected_slot: String = "slot_a"
var _care_focus_instance_id: String = ""
var _care_state_map: Dictionary = {}
var _captured_monsters: Array = []
var _idle_exp_map: Dictionary = {}
var _bubbles: Array = []
var _bubble_timer: float = 0.0
var _texture_cache: Dictionary = {}
var _time: float = 0.0
var _list_page: int = 0
var _max_list_page: int = 0
var _dragging_list: bool = false
var _class_scroll_y: float = 0.0
var _class_max_scroll_y: float = 0.0
var _class_page: int = 0
var _class_max_page: int = 0
var _dragging_class_list: bool = false
var _class_selected_instance_id: String = ""
var _last_drag_x: float = 0.0
var _last_drag_y: float = 0.0
var _status_text: String = ""
var _status_timer: float = 0.0
var _social_result_popup: Dictionary = {}

class BubbleData:
	var slot_index: int = 0
	var age: float = 0.0
	var life: float = 2.8
	var drift: float = 0.0
	var rise: float = 0.0

func _ready() -> void:
	name = "SceneRanch"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

func init(_data: Dictionary = {}) -> void:
	_game = _root_node("GameManager")
	_storage = _resolve_storage()
	_active_page = "ranch"
	_load_data()
	_calc_idle_exp()
	_init_bubbles()
	queue_redraw()

func initialize(game: Node) -> void:
	_game = game
	_storage = _resolve_storage()
	_active_page = "ranch"
	_load_data()
	_calc_idle_exp()
	_init_bubbles()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if _status_timer > 0.0:
		_status_timer = maxf(0.0, _status_timer - delta)
	_update_bubbles(delta)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_last_drag_x = event.position.x
				_last_drag_y = event.position.y
				var design_pos := _to_design(event.position)
				_dragging_list = _active_page == "ranch" and LIST_RECT.has_point(design_pos)
				_dragging_class_list = false  # no drag for classroom/social lists
			else:
				if abs(event.position.x - _last_drag_x) < 8.0 and abs(event.position.y - _last_drag_y) < 8.0:
					_handle_tap(_to_design(event.position))
				_dragging_list = false
				_dragging_class_list = false
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if _active_page != "classroom" and _active_page != "social":
				_change_list_page(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if _active_page != "classroom" and _active_page != "social":
				_change_list_page(1)
	elif event is InputEventMouseMotion and _dragging_list:
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_last_drag_x = event.position.x
			_last_drag_y = event.position.y
			var design_pos := _to_design(event.position)
			_dragging_list = _active_page == "ranch" and LIST_RECT.has_point(design_pos)
			_dragging_class_list = false  # no drag for classroom/social lists
		else:
			if abs(event.position.x - _last_drag_x) < 8.0 and abs(event.position.y - _last_drag_y) < 8.0:
				_handle_tap(_to_design(event.position))
			_dragging_list = false
			_dragging_class_list = false
		accept_event()
	elif event is InputEventScreenDrag and _dragging_list:
		accept_event()
	elif event is InputEventScreenDrag and _dragging_class_list:
		accept_event()

func _handle_tap(pos: Vector2) -> void:
	if not _social_result_popup.is_empty():
		if SOCIAL_RESULT_CLOSE_RECT.has_point(pos) or not SOCIAL_RESULT_POPUP_RECT.has_point(pos):
			_social_result_popup = {}
			queue_redraw()
		return
	if BACK_RECT.has_point(pos):
		if _active_page == "classroom" or _active_page == "social":
			_switch_to_ranch()
		else:
			_go_to_scene("main")
		return
	if _active_page == "classroom":
		_handle_classroom_tap(pos)
		return
	if _active_page == "social":
		_handle_social_tap(pos)
		return
	_handle_ranch_tap(pos)

func _handle_ranch_tap(pos: Vector2) -> void:
	if COLLECT_RECT.has_point(pos):
		_on_collect_pressed()
		return
	if RANCH_FOCUS_RECT.has_point(pos):
		_toggle_care_focus_selected()
		return
	if RANCH_CLASSROOM_RECT.has_point(pos):
		_switch_to_classroom()
		return
	if RANCH_SOCIAL_RECT.has_point(pos):
		_switch_to_social()
		return
	if LIST_LEFT_ARROW_RECT.has_point(pos):
		_scroll_monster_list(-1)
		return
	if LIST_RIGHT_ARROW_RECT.has_point(pos):
		_scroll_monster_list(1)
		return
	for i in range(SLOT_RECTS.size()):
		if SLOT_RECTS[i].has_point(pos):
			_select_slot(i)
			_collect_slot(i)
			return
	var picker_idx := _picker_index_at(pos)
	if picker_idx >= 0 and picker_idx < _captured_monsters.size():
		_on_picker_item_pressed(_get_instance_id(_captured_monsters[picker_idx]))

func _handle_classroom_tap(pos: Vector2) -> void:
	if BOTTOM_LEFT_RECT.has_point(pos):
		_switch_to_ranch()
		return
	if BOTTOM_RIGHT_RECT.has_point(pos):
		_switch_to_social()
		return
	if CLASS_LEFT_ARROW_RECT.has_point(pos):
		_class_page = clampi(_class_page - 1, 0, _class_max_page)
		queue_redraw()
		return
	if CLASS_RIGHT_ARROW_RECT.has_point(pos):
		_class_page = clampi(_class_page + 1, 0, _class_max_page)
		queue_redraw()
		return
	if CLASS_EVOLVE_RECT.has_point(pos):
		_on_evolve_pressed()
		return
	var idx := _classroom_index_at(pos)
	if idx >= 0 and idx < _captured_monsters.size():
		_class_selected_instance_id = _get_instance_id(_captured_monsters[idx])
		queue_redraw()

func _handle_social_tap(pos: Vector2) -> void:
	if BOTTOM_LEFT_RECT.has_point(pos):
		_switch_to_classroom()
		return
	if BOTTOM_RIGHT_RECT.has_point(pos):
		_try_social_action()
		return
	if SOCIAL_PLACE_SWITCH_RECT.has_point(pos):
		_cycle_social_place()
		return
	if CLASS_LEFT_ARROW_RECT.has_point(pos):
		_class_page = clampi(_class_page - 1, 0, _class_max_page)
		queue_redraw()
		return
	if CLASS_RIGHT_ARROW_RECT.has_point(pos):
		_class_page = clampi(_class_page + 1, 0, _class_max_page)
		queue_redraw()
		return
	if SOCIAL_SLOT_A_RECT.has_point(pos):
		_select_or_clear_social_slot("slot_a")
		return
	if SOCIAL_SLOT_B_RECT.has_point(pos):
		_select_or_clear_social_slot("slot_b")
		return
	var idx := _classroom_index_at(pos)
	if idx >= 0 and idx < _captured_monsters.size():
		_assign_social_instance(_get_instance_id(_captured_monsters[idx]))

func _switch_to_social() -> void:
	_active_page = "social"
	_dragging_class_list = false
	_update_class_scroll_limit()
	queue_redraw()

func _switch_to_classroom() -> void:
	_active_page = "classroom"
	if _class_selected_instance_id.is_empty() and not _captured_monsters.is_empty():
		_class_selected_instance_id = _get_instance_id(_captured_monsters[0])
	_update_class_scroll_limit()
	queue_redraw()

func _switch_to_ranch() -> void:
	_active_page = "ranch"
	_dragging_class_list = false
	queue_redraw()

func _toggle_care_focus_selected() -> void:
	var instance_id := _selected_monster_id()
	if instance_id.is_empty():
		_show_status("先选择牧场中的精灵")
		return
	if _care_focus_instance_id == instance_id:
		if _storage != null and _storage.has_method("clear_ranch_care_focus"):
			_storage.clear_ranch_care_focus()
		_care_focus_instance_id = ""
		_show_status("已取消专注培养")
	else:
		if _storage != null and _storage.has_method("set_ranch_care_focus"):
			if not _storage.set_ranch_care_focus(instance_id):
				_show_status("专注培养设置失败")
				return
		_care_focus_instance_id = instance_id
		var care := _get_care_state(instance_id)
		var label := str(care.get("label", ""))
		_show_status("专注培养已设定%s" % ("：" + label if not label.is_empty() else ""))
	_load_data()
	_refresh_ranch_view()

func _select_or_clear_social_slot(slot_key: String) -> void:
	var place := _current_social_place()
	if place.get("started_at", null) != null:
		_show_status("社交进行中")
		return
	if _social_selected_slot == slot_key and place.get(slot_key, null) != null:
		if _storage != null and _storage.has_method("clear_social_slot"):
			_storage.clear_social_slot(0, slot_key)
			_load_data()
		else:
			place[slot_key] = null
			_social_places[0] = place
		queue_redraw()
		return
	_social_selected_slot = slot_key
	queue_redraw()

func _assign_social_instance(instance_id: String) -> void:
	var place := _current_social_place()
	if place.get("started_at", null) != null:
		_show_status("社交进行中")
		return
	if _is_instance_in_ranch(instance_id):
		_show_status("该精灵正在农场挂机，请先从农场取下")
		return
	if _storage != null and _storage.has_method("assign_social_slot"):
		if not _storage.assign_social_slot(0, _social_selected_slot, instance_id):
			_show_status("该精灵当前无法参加社交")
			return
		_load_data()
	else:
		if place.get("slot_a") == instance_id:
			place["slot_a"] = null
		if place.get("slot_b") == instance_id:
			place["slot_b"] = null
		place[_social_selected_slot] = instance_id
		_social_places[0] = place
	queue_redraw()

func _try_social_action() -> void:
	var place := _current_social_place()
	if SocialRulesScript.is_ready(place):
		if _storage != null and _storage.has_method("collect_social"):
			var collect_result: Dictionary = _storage.collect_social(0)
			if bool(collect_result.get("ok", false)):
				var result: Dictionary = collect_result.get("result", {})
				_show_status("%s +%dEXP +%d金币" % [result.get("label", "社交完成"), int(result.get("exp_each", 0)), int(result.get("gold", 0))])
				_social_result_popup = result.duplicate(true)
				_load_data()
				queue_redraw()
				return
		_show_status("社交领取失败")
		return
	if place.get("started_at", null) != null:
		_show_status("社交进行中 %d%%" % int(SocialRulesScript.progress(place) * 100.0))
		return
	if not SocialRulesScript.can_start(place):
		_show_status("需要放入两只精灵")
		return
	if _storage != null and _storage.has_method("start_social"):
		var result: Dictionary = _storage.start_social(0)
		if bool(result.get("ok", false)):
			_show_status("社交开始")
			_load_data()
			return
		_show_status("社交开始失败")

func _cycle_social_place() -> void:
	var place := _current_social_place()
	if place.get("started_at", null) != null:
		_show_status("社交进行中，不能更换场所")
		return
	if _storage != null and _storage.has_method("cycle_social_place"):
		if not _storage.cycle_social_place(0):
			_show_status("场所切换失败")
			return
		_load_data()
	else:
		place["place_id"] = SocialRulesScript.next_place_id(str(place.get("place_id", "meadow_yard")))
		place["last_result"] = {}
		_social_places[0] = place
	var place_config := SocialRulesScript.place_config_for(_current_social_place())
	_show_status("切换到%s" % str(place_config.get("name", "社交场所")))
	queue_redraw()

func _get_instance_id(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("instanceId", ""))
	return str(value)

func _get_monster_id(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("monsterId", (value as Dictionary).get("id", "")))
	var ref_id := str(value)
	if _storage != null and _storage.has_method("get_monster_instance"):
		var instance: Dictionary = _storage.get_monster_instance(ref_id)
		if not instance.is_empty():
			return str(instance.get("monsterId", ""))
	return ref_id

func _load_data() -> void:
	_slots_data = []
	for _i in range(SLOT_COUNT):
		_slots_data.append({"instance_id": null, "placed_at": null})

	if _storage != null and _storage.has_method("get_ranch_state"):
		var ranch_state: Dictionary = _storage.get_ranch_state()
		var saved_slots: Array = ranch_state.get("slots", [])
		for i in range(mini(saved_slots.size(), SLOT_COUNT)):
			_slots_data[i] = _normalize_slot(saved_slots[i])
		_social_places = SocialRulesScript.normalize_places(ranch_state.get("social_places", []), 1)
		_care_focus_instance_id = str(ranch_state.get("care_focus_instance_id", ""))

		if _storage.has_method("get_captured_monsters"):
			_captured_monsters = _storage.get_owned_monsters() if _storage.has_method("get_owned_monsters") else _storage.get_captured_monsters()
		else:
			var player: Dictionary = _storage.load_player() if _storage.has_method("load_player") else {}
			_captured_monsters = player.get("captured", [])
	else:
		_social_places = SocialRulesScript.normalize_places([], 1)
		_care_focus_instance_id = ""
		_captured_monsters = [
			{"instanceId": "monster_001", "monsterId": "monster_001"},
			{"instanceId": "monster_002", "monsterId": "monster_002"},
			{"instanceId": "monster_003", "monsterId": "monster_003"}
		]

	_captured_monsters = _captured_monsters.filter(func(item): return MonsterDb.has_monster(_get_monster_id(item)))
	if _captured_monsters.is_empty():
		_captured_monsters = [
			{"instanceId": "monster_001", "monsterId": "monster_001"},
			{"instanceId": "monster_002", "monsterId": "monster_002"},
			{"instanceId": "monster_003", "monsterId": "monster_003"}
		]
	if _class_selected_instance_id.is_empty() and not _captured_monsters.is_empty():
		_class_selected_instance_id = _get_instance_id(_captured_monsters[0])
	if _social_places.is_empty():
		_social_places = SocialRulesScript.normalize_places([], 1)
	_select_slot(clampi(_selected_slot, 0, SLOT_COUNT - 1))
	_update_list_scroll_limit()
	_update_class_scroll_limit()

func _normalize_slot(slot_data: Variant) -> Dictionary:
	if not slot_data is Dictionary:
		return {"instance_id": null, "placed_at": null}
	var slot: Dictionary = slot_data
	return {
		"instance_id": slot.get("instance_id", slot.get("monster_id", slot.get("monsterId", null))),
		"placed_at": slot.get("placed_at", slot.get("placedAt", null)),
	}

func _save_ranch_state() -> void:
	if _storage != null and _storage.has_method("set_ranch_state"):
		_storage.set_ranch_state({
			"slots": _slots_data,
			"unlocked_slots": SLOT_COUNT,
			"social_places": _social_places,
			"care_focus_instance_id": _care_focus_instance_id,
		})

func _calc_idle_exp() -> void:
	_idle_exp_map = {}
	_care_state_map = {}
	var now := Time.get_unix_time_from_system() * 1000.0
	for slot: Dictionary in _slots_data:
		var monster_id = slot.get("instance_id", null)
		var placed_at = slot.get("placed_at", null)
		if monster_id == null or placed_at == null:
			continue
		var elapsed := minf(maxf(0.0, now - float(placed_at)), IDLE_MAX_MS)
		var intervals := int(elapsed / IDLE_INTERVAL_MS)
		if intervals <= 0:
			continue
		var rate := _get_idle_exp_rate(str(monster_id))
		_care_state_map[str(monster_id)] = _get_care_state(str(monster_id))
		_idle_exp_map[str(monster_id)] = intervals * rate

func _init_bubbles() -> void:
	_bubbles = []
	for i in range(_slots_data.size()):
		if _slots_data[i].get("instance_id", null) != null:
			_add_bubble(i)

func _add_bubble(slot_index: int) -> void:
	var bubble := BubbleData.new()
	bubble.slot_index = slot_index
	bubble.life = 2.0 + randf() * 1.6
	bubble.drift = (randf() - 0.5) * 22.0
	bubble.rise = 30.0 + randf() * 16.0
	_bubbles.append(bubble)

func _update_bubbles(delta: float) -> void:
	_bubble_timer += delta
	if _bubble_timer > 3.0:
		_bubble_timer = 0.0
		for i in range(_slots_data.size()):
			if _slots_data[i].get("instance_id", null) != null and randf() > 0.45:
				_add_bubble(i)
	for i in range(_bubbles.size() - 1, -1, -1):
		var b: BubbleData = _bubbles[i]
		b.age += delta
		if b.age >= b.life:
			_bubbles.remove_at(i)

func _select_slot(index: int) -> void:
	_selected_slot = clampi(index, 0, SLOT_COUNT - 1)
	queue_redraw()

func _on_picker_item_pressed(instance_id: String) -> void:
	for i in range(_slots_data.size()):
		if _slots_data[i].get("instance_id", null) == instance_id:
			_slots_data[i] = {"instance_id": null, "placed_at": null}
			if _care_focus_instance_id == instance_id:
				_care_focus_instance_id = ""
			_save_ranch_state()
			_refresh_ranch_view()
			return
	if _is_instance_in_social(instance_id):
		_show_status("该精灵正在社交，请先结束社交")
		return
	if _selected_slot < 0 or _selected_slot >= SLOT_COUNT:
		return
	var old_id = _slots_data[_selected_slot].get("instance_id", null)
	if old_id != null:
		var old_exp := int(_idle_exp_map.get(str(old_id), 0))
		if old_exp > 0 and _storage != null and _storage.has_method("add_instance_exp"):
			_storage.add_instance_exp(str(old_id), old_exp)
		if _care_focus_instance_id == str(old_id):
			_care_focus_instance_id = ""
	_slots_data[_selected_slot] = {
		"instance_id": instance_id,
		"placed_at": Time.get_unix_time_from_system() * 1000.0,
	}
	_save_ranch_state()
	_refresh_ranch_view()

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
	if _storage != null and _storage.has_method("add_instance_exp"):
		_storage.add_instance_exp(str(instance_id), exp)
	slot["placed_at"] = Time.get_unix_time_from_system() * 1000.0
	_save_ranch_state()
	_refresh_ranch_view()
	exp_collected.emit(exp)
	_show_status("收获 +%d EXP" % exp)

func _on_collect_pressed() -> void:
	var total_collected := 0
	for slot: Dictionary in _slots_data:
		var monster_id = slot.get("instance_id", null)
		if monster_id == null:
			continue
		var exp := int(_idle_exp_map.get(str(monster_id), 0))
		if exp <= 0:
			continue
		if _storage != null and _storage.has_method("add_instance_exp"):
			_storage.add_instance_exp(str(monster_id), exp)
		total_collected += exp
		slot["placed_at"] = Time.get_unix_time_from_system() * 1000.0
	_save_ranch_state()
	_refresh_ranch_view()
	if total_collected > 0:
		exp_collected.emit(total_collected)
		_show_status("收获 +%d EXP" % total_collected)
	else:
		_show_status("暂无可收获收益")

func _on_evolve_pressed() -> void:
	var info := _get_selected_evolution_info()
	if info.is_empty():
		_show_status("请选择已放置的精灵")
		return
	if not bool(info.get("has_evolution", false)):
		_show_status("当前形态无法进化")
		return
	if not bool(info.get("level_ok", false)):
		_show_status("需要 Lv.%d" % int(info.get("required_level", 1)))
		return
	if not bool(info.get("item_ok", false)):
		_show_status("%s 不足" % str(info.get("item_name", "进化道具")))
		return
	var instance_id := str(info.get("instance_id", ""))
	var required_item := str(info.get("required_item", ""))
	if _storage == null or not _storage.has_method("evolve_instance"):
		_show_status("进化系统不可用")
		return
	var item_consumed := false
	if _storage != null and _storage.has_method("use_item") and not _storage.use_item(required_item, 1):
		_show_status("%s 不足" % str(info.get("item_name", "进化道具")))
		return
	item_consumed = _storage.has_method("use_item")
	var result: Dictionary = _storage.evolve_instance(instance_id)
	if not bool(result.get("ok", false)):
		if item_consumed and _storage.has_method("add_item"):
			_storage.add_item(required_item, 1)
		_show_status("进化失败：%s" % str(result.get("reason", "unknown")))
		return
	if _storage.has_method("add_achievement_progress"):
		_storage.add_achievement_progress("evolveCount", 1)
	var new_id := str(result.get("newMonsterId", ""))
	var new_data := MonsterDb.get_monster(new_id)
	var report: Dictionary = result.get("evolutionReport", {})
	var play_text := str(report.get("play_upgrade", ""))
	_show_status("进化成功：%s %s" % [str(new_data.get("name", new_id)), play_text])
	_load_data()
	_refresh_ranch_view()

func _refresh_ranch_view() -> void:
	_calc_idle_exp()
	_init_bubbles()
	_update_list_scroll_limit()
	_update_class_scroll_limit()
	queue_redraw()

func _show_status(text: String) -> void:
	_status_text = text
	_status_timer = 2.2

func _draw() -> void:
	_draw_background()
	_draw_header()
	if _active_page == "classroom":
		_draw_classroom()
	elif _active_page == "social":
		_draw_social()
	else:
		_draw_ranch_slots()
		_draw_bubbles()
		_draw_monster_list()
		_draw_collect_row()
		_draw_status_text()
	if not _social_result_popup.is_empty():
		_draw_social_result_popup()

func _draw_background() -> void:
	var bg := _tex(RANCH_ASSETS["bg"])
	if bg:
		_draw_texture_cover(bg, Rect2(0, 0, DESIGN_W, DESIGN_H))
	else:
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.06, 0.12, 0.08))
	draw_rect(Rect2(0, 0, DESIGN_W, 86), Color(0.02, 0.05, 0.12, 0.50))

func _draw_header() -> void:
	_draw_texture_contain(_tex(RANCH_ASSETS["back"]), BACK_RECT)
	_draw_texture_contain(_tex(RANCH_ASSETS["header"]), Rect2(88.0, 13.0, 219.0, 53.0))
	var title := "精灵牧场"
	if _active_page == "classroom":
		title = "精灵课堂"
	elif _active_page == "social":
		title = "社交庭院"
	_draw_text(title, DESIGN_W / 2.0, 50.0, C["text"], 23.0, 190.0)

func _draw_status_text() -> void:
	if _status_timer <= 0.0 or _status_text.is_empty():
		return
	var alpha := minf(1.0, _status_timer)
	var y := 268.0 if _active_page == "classroom" else 92.0
	_draw_text(_status_text, DESIGN_W / 2.0, y, Color(1.0, 0.88, 0.36, alpha), 18.0, 260.0)

func _draw_code_button(rect: Rect2, text: String, enabled: bool) -> void:
	if enabled:
		_draw_texture_three_slice(_tex(RANCH_ASSETS["collect_button"]), rect, 42.0, 40.0)
		_draw_text(text, rect.get_center().x, rect.position.y + rect.size.y * 0.63, Color(0.18, 0.10, 0.02), 13.0, rect.size.x - 10.0)
		return
	_draw_texture_three_slice(_tex(RANCH_ASSETS["secondary_button"]), rect, 44.0, 44.0, 0.52)
	_draw_text(text, rect.get_center().x, rect.position.y + rect.size.y * 0.63, C["text_muted"], 13.0, rect.size.x - 10.0)

func _draw_ranch_slots() -> void:
	for i in range(SLOT_RECTS.size()):
		_draw_slot(i, SLOT_RECTS[i])

func _draw_slot(index: int, rect: Rect2) -> void:
	var slot: Dictionary = _slots_data[index] if index < _slots_data.size() else {}
	var monster_id = slot.get("instance_id", null)
	var occupied := monster_id != null and MonsterDb.has_monster(_get_monster_id(str(monster_id)))

	if occupied:
		var id := str(monster_id)
		var level := _get_monster_level(id)
		_draw_monster_portrait(id, Rect2(rect.position.x + 22.0, rect.position.y + 17.0, rect.size.x - 44.0, 58.0))
		var care: Dictionary = _care_state_map.get(id, _get_care_state(id))
		var care_label := str(care.get("label", ""))
		_draw_text("Lv.%d" % level, rect.get_center().x, rect.position.y + 89.0, C["text"], 12.0, 72.0)
		_draw_texture_fit(_tex(RANCH_ASSETS["status_ribbon"]), Rect2(rect.position.x + 11.0, rect.position.y + 93.0, rect.size.x - 22.0, 18.0))
		var placement_text := _format_elapsed_short(slot.get("placed_at", null))
		if not care_label.is_empty():
			placement_text = "专注 " + placement_text.trim_prefix("放置 ")
		_draw_text(placement_text, rect.get_center().x, rect.position.y + 106.0, C["text"], 9.5, rect.size.x - 24.0)
	else:
		var empty_color := C["gold"] if index == _selected_slot else Color(0.98, 0.90, 0.67)
		_draw_text("+", rect.get_center().x, rect.position.y + 69.0, empty_color, 26.0, 42.0)
		_draw_text("放入这里" if index == _selected_slot else "空位", rect.get_center().x, rect.position.y + 102.0, C["gold"] if index == _selected_slot else C["text"], 11.0, rect.size.x - 28.0)

func _draw_bubbles() -> void:
	for b: BubbleData in _bubbles:
		if b.slot_index < 0 or b.slot_index >= SLOT_RECTS.size():
			continue
		var rect: Rect2 = SLOT_RECTS[b.slot_index]
		var t := clampf(b.age / b.life, 0.0, 1.0)
		var alpha := 1.0 - maxf(0.0, (t - 0.72) / 0.28)
		var x := rect.get_center().x + sin(t * TAU) * 9.0 + b.drift * t
		var y := rect.position.y - 3.0 - b.rise * t
		_draw_texture_contain(_tex(RANCH_ASSETS["sparkle"]), Rect2(x - 14.0, y - 8.0, 28.0, 14.0), alpha)

func _draw_collect_row() -> void:
	var total_exp := _total_idle_exp()
	var total_coin := total_exp * 1.25
	_draw_texture_contain(_tex(RANCH_ASSETS["exp"]), Rect2(19.0, 445.0, 29.0, 30.0))
	_draw_text("+" + _format_count(total_exp), 76.0, 468.0, Color(0.98, 0.92, 0.65), 16.0, 54.0)
	_draw_texture_contain(_tex(RANCH_ASSETS["coin"]), Rect2(108.0, 446.0, 29.0, 28.0))
	_draw_text("+" + _format_count(total_coin), 166.0, 468.0, Color(0.98, 0.92, 0.65), 16.0, 56.0)
	_draw_texture_contain(_tex(RANCH_ASSETS["collect_button"]), COLLECT_RECT)
	_draw_text("收获", COLLECT_RECT.get_center().x, COLLECT_RECT.position.y + 29.0, Color(0.22, 0.12, 0.02), 16.0, COLLECT_RECT.size.x - 12.0)
	_draw_asset_button(RANCH_FOCUS_RECT, "取消专注" if not _care_focus_instance_id.is_empty() else "专注培养")
	_draw_asset_button(RANCH_CLASSROOM_RECT, "精灵课堂")
	_draw_asset_button(RANCH_SOCIAL_RECT, "社交庭院")

func _draw_monster_list() -> void:
	_draw_texture_nine_slice(_tex(RANCH_ASSETS["care_roster_panel"]), LIST_RECT, Vector2(64.0, 56.0), Vector2(32.0, 28.0))
	var used := _used_monsters()
	for i in range(_captured_monsters.size()):
		var card := _picker_card_rect(i)
		if not LIST_CLIP_RECT.encloses(card):
			continue
		var monster_id := _get_instance_id(_captured_monsters[i])
		var in_use := used.has(monster_id)
		_draw_picker_card(monster_id, card, in_use)
	_draw_list_controls()

func _draw_classroom() -> void:
	_draw_classroom_detail()
	_draw_classroom_list()
	_draw_classroom_bottom()
	_draw_status_text()

func _draw_classroom_detail() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["classroom_detail"]), CLASS_DETAIL_RECT)
	var instance_id := _class_selected_instance_id
	if instance_id.is_empty() and not _captured_monsters.is_empty():
		instance_id = _get_instance_id(_captured_monsters[0])
	if instance_id.is_empty():
		_draw_text("暂无精灵", CLASS_DETAIL_RECT.get_center().x, CLASS_DETAIL_RECT.position.y + 90.0, C["text_muted"], 14.0, 180.0)
		_draw_code_button(CLASS_EVOLVE_RECT, "进化", false)
		return
	var instance := _get_instance(instance_id)
	var monster_id := str(instance.get("monsterId", _get_monster_id(instance_id)))
	var monster := MonsterDb.get_monster(monster_id)
	var stats := _get_instance_stats(instance_id)
	var info := _get_evolution_info_for_instance(instance_id)
	var target_id := str(info.get("target_id", ""))
	var target := MonsterDb.get_monster(target_id) if not target_id.is_empty() else {}
	var target_name := str(target.get("name", "无")) if not target.is_empty() else "无"
	_draw_monster_portrait(instance_id, Rect2(28.0, 112.0, 91.0, 85.0))
	_draw_text(str(monster.get("name", monster_id)), 222.0, 130.0, C["text"], 16.0, 130.0)
	_draw_text("Lv.%d · %s · %s" % [int(instance.get("level", 1)), _get_nature_name(str(instance.get("nature", ""))), ELEMENT_LABELS.get(str(monster.get("element", "")), str(monster.get("element", "")))], 222.0, 151.0, C["text_muted"], 10.5, 132.0)
	_draw_text("HP %d   ATK %d   DEF %d" % [int(stats.get("hp", 0)), int(stats.get("atk", 0)), int(stats.get("def", 0))], 222.0, 171.0, Color(0.82, 0.92, 1.0), 10.0, 132.0)
	_draw_text("进化目标：%s" % target_name, 222.0, 193.0, C["gold"] if bool(info.get("has_evolution", false)) else C["text_muted"], 11.5, 132.0)
	_draw_text(str(info.get("condition_text", "无法进化")), 222.0, 211.0, C["text_muted"], 9.5, 132.0)
	_draw_text(str(info.get("play_upgrade_text", "玩法升级: 无")), 126.0, 250.0, Color(0.76, 0.95, 1.0), 9.0, 178.0)
	_draw_code_button(CLASS_EVOLVE_RECT, "进化", bool(info.get("can_evolve", false)))

func _draw_classroom_list() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["care_roster_panel"]), CLASS_LIST_RECT)
	for i in range(_captured_monsters.size()):
		var card := _classroom_card_rect(i)
		if card.position.y + card.size.y < CLASS_LIST_CLIP_RECT.position.y or card.position.y > CLASS_LIST_CLIP_RECT.end.y:
			continue
		if card.position.x < CLASS_LIST_CLIP_RECT.position.x or card.end.x > CLASS_LIST_CLIP_RECT.end.x:
			continue
		_draw_classroom_card(_get_instance_id(_captured_monsters[i]), card)
	if _class_max_scroll_y > 0.0:
		_draw_texture_fit(_tex(RANCH_ASSETS["scrollbar"]), Rect2(348.0, CLASS_LIST_CLIP_RECT.position.y, 7.0, CLASS_LIST_CLIP_RECT.size.y))

func _draw_classroom_card(instance_id: String, rect: Rect2) -> void:
	var selected := instance_id == _class_selected_instance_id
	_draw_texture_contain(_tex(RANCH_ASSETS["roster_card_selected" if selected else "roster_card"]), rect)
	_draw_monster_portrait(instance_id, Rect2(rect.position.x + 19.0, rect.position.y + 11.0, rect.size.x - 38.0, 54.0))
	var monster := MonsterDb.get_monster(_get_monster_id(instance_id))
	var instance: Dictionary = _get_instance(instance_id)
	var nature_short := _get_nature_name(str(instance.get("nature", "")))
	if nature_short.length() > 3:
		nature_short = nature_short.substr(0, 3)
	var elem: String = ELEMENT_LABELS.get(str(monster.get("element", "")), "")
	_draw_text(str(monster.get("name", "")), rect.get_center().x, rect.position.y + 77.0, C["text"], 10.5, rect.size.x - 20.0)
	_draw_text("Lv.%d · %s" % [int(instance.get("level", 1)), elem], rect.get_center().x, rect.position.y + 92.0, C["gold"], 9.0, rect.size.x - 20.0)
	_draw_text(nature_short, rect.get_center().x, rect.position.y + 105.0, C["text_muted"], 8.0, rect.size.x - 20.0)

func _draw_classroom_bottom() -> void:
	_draw_texture_three_slice(_tex(RANCH_ASSETS["relationship"]), SUBPAGE_RIBBON_RECT, 110.0, 110.0)
	_draw_text("培养与进化", DESIGN_W / 2.0, SUBPAGE_RIBBON_RECT.position.y + 27.0, C["text_muted"], 12.0, 140.0)
	_draw_code_button(BOTTOM_LEFT_RECT, "牧场", true)
	_draw_code_button(BOTTOM_RIGHT_RECT, "社交", true)
	if _class_max_page > 0:
		var left_a := 0.35 if _class_page <= 0 else 0.9
		var right_a := 0.35 if _class_page >= _class_max_page else 0.9
		_draw_texture_contain(_tex(RANCH_ASSETS["prev_arrow"]), CLASS_LEFT_ARROW_RECT, left_a)
		_draw_texture_contain(_tex(RANCH_ASSETS["next_arrow"]), CLASS_RIGHT_ARROW_RECT, right_a)
		_draw_text("%d/%d" % [_class_page + 1, _class_max_page + 1], DESIGN_W / 2.0, 570.0, Color(0.76, 0.82, 1.0, 0.75), 9.0, 60.0)

func _draw_social() -> void:
	_draw_social_place()
	_draw_social_list()
	_draw_social_bottom()
	_draw_status_text()

func _draw_social_place() -> void:
	var place := _current_social_place()
	var place_config := SocialRulesScript.place_config_for(place)
	_draw_texture_fit(_tex(RANCH_ASSETS["social_place"]), SOCIAL_PLACE_RECT)
	_draw_text(str(place_config.get("name", "社交场所")), 106.0, SOCIAL_PLACE_RECT.position.y + 32.0, C["gold"], 14.0, 116.0)
	_draw_text("用时%s" % SocialRulesScript.duration_label_for_place(place), 106.0, SOCIAL_PLACE_RECT.position.y + 47.0, C["text_muted"], 9.0, 110.0)
	_draw_code_button(SOCIAL_PLACE_SWITCH_RECT, "换场", place.get("started_at", null) == null)
	_draw_social_slot("slot_a", SOCIAL_SLOT_A_RECT, place)
	_draw_social_slot("slot_b", SOCIAL_SLOT_B_RECT, place)
	_draw_text("＋", DESIGN_W / 2.0, 192.0, C["text_muted"], 24.0, 40.0)
	var preview_text := _social_preview_text(place)
	_draw_text(preview_text, DESIGN_W / 2.0, 242.0, C["text_muted"], 9.5, 288.0)
	_draw_social_relationship_detail(place)

func _draw_social_slot(slot_key: String, rect: Rect2, place: Dictionary) -> void:
	var selected := _social_selected_slot == slot_key
	var instance_id := str(place.get(slot_key, ""))
	_draw_texture_contain(_tex(RANCH_ASSETS["social_slot"]), rect)
	if selected:
		_draw_texture_contain(_tex(RANCH_ASSETS["check"]), Rect2(rect.end.x - 23.0, rect.position.y + 3.0, 20.0, 20.0))
	if instance_id.is_empty():
		_draw_text("选择精灵", rect.get_center().x, rect.position.y + 58.0, C["text_muted"], 12.0, rect.size.x - 10.0)
		_draw_text(slot_key.replace("slot_", "").to_upper(), rect.get_center().x, rect.position.y + 84.0, C["text_muted"], 9.0, rect.size.x)
		return
	var instance := _get_instance(instance_id)
	var monster := MonsterDb.get_monster(str(instance.get("monsterId", "")))
	_draw_monster_portrait(instance_id, Rect2(rect.position.x + 20.0, rect.position.y + 6.0, rect.size.x - 40.0, 50.0))
	_draw_text(str(monster.get("name", "")), rect.get_center().x, rect.position.y + 67.0, C["text"], 9.5, rect.size.x - 12.0)
	_draw_text("%s %s" % [_gender_label(instance), _get_nature_name(str(instance.get("nature", "")))], rect.get_center().x, rect.position.y + 82.0, C["text_muted"], 8.0, rect.size.x - 12.0)

func _draw_social_list() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["care_roster_panel"]), CLASS_LIST_RECT)
	for i in range(_captured_monsters.size()):
		var card := _classroom_card_rect(i)
		if card.position.y + card.size.y < CLASS_LIST_CLIP_RECT.position.y or card.position.y > CLASS_LIST_CLIP_RECT.end.y:
			continue
		if card.position.x < CLASS_LIST_CLIP_RECT.position.x or card.end.x > CLASS_LIST_CLIP_RECT.end.x:
			continue
		_draw_classroom_card(_get_instance_id(_captured_monsters[i]), card)

func _draw_social_bottom() -> void:
	_draw_texture_three_slice(_tex(RANCH_ASSETS["relationship"]), SUBPAGE_RIBBON_RECT, 110.0, 110.0)
	_draw_text("交流活动", DESIGN_W / 2.0, SUBPAGE_RIBBON_RECT.position.y + 27.0, C["text_muted"], 12.0, 140.0)
	_draw_code_button(BOTTOM_LEFT_RECT, "课堂", true)
	var place := _current_social_place()
	_draw_code_button(BOTTOM_RIGHT_RECT, _social_action_label(place), _social_action_enabled(place))
	if _class_max_page > 0:
		var left_a := 0.35 if _class_page <= 0 else 0.9
		var right_a := 0.35 if _class_page >= _class_max_page else 0.9
		_draw_texture_contain(_tex(RANCH_ASSETS["prev_arrow"]), CLASS_LEFT_ARROW_RECT, left_a)
		_draw_texture_contain(_tex(RANCH_ASSETS["next_arrow"]), CLASS_RIGHT_ARROW_RECT, right_a)
		_draw_text("%d/%d" % [_class_page + 1, _class_max_page + 1], DESIGN_W / 2.0, 570.0, Color(0.76, 0.82, 1.0, 0.75), 9.0, 60.0)

func _draw_social_relationship_detail(place: Dictionary) -> void:
	var detail := _social_relationship_detail(place)
	_draw_texture_three_slice(_tex(RANCH_ASSETS["relationship"]), SOCIAL_RELATION_RECT, 110.0, 110.0)
	if detail.is_empty():
		_draw_text("放入两只精灵后显示关系预览", SOCIAL_RELATION_RECT.get_center().x, SOCIAL_RELATION_RECT.position.y + 17.0, C["text_muted"], 10.0, SOCIAL_RELATION_RECT.size.x - 12.0)
		return
	var title := "当前 %s · %d次 · 最高%d" % [
		str(detail.get("currentLabel", "未相识")),
		int(detail.get("count", 0)),
		int(detail.get("bestScore", 0))
	]
	if not bool(detail.get("hasHistory", false)):
		title = "当前 未相识 · 预计%s · %d分" % [str(detail.get("nextLabel", "初识")), int(detail.get("nextScore", 0))]
	_draw_text(title, SOCIAL_RELATION_RECT.get_center().x, SOCIAL_RELATION_RECT.position.y + 17.0, C["gold"], 10.0, SOCIAL_RELATION_RECT.size.x - 14.0)

func _draw_social_result_popup() -> void:
	var result := _social_result_popup
	var major: Dictionary = result.get("majorOutcome", {})
	var major_type := str(major.get("type", "none"))
	var tags: Array = result.get("tags", [])
	draw_rect(_scale_rect(Rect2(0, 0, DESIGN_W, DESIGN_H)), Color(0.0, 0.0, 0.0, 0.58))
	var accent := C["gold"]
	if major_type == "erosion":
		accent = Color(1.0, 0.34, 0.30)
	elif major_type == "birth":
		accent = Color(0.65, 1.0, 0.68)
	elif tags.has("属性相克"):
		accent = Color(1.0, 0.68, 0.18)
	_draw_texture_contain(_tex(RANCH_ASSETS["social_result"]), SOCIAL_RESULT_POPUP_RECT)
	_draw_text(_social_result_title(result), DESIGN_W / 2.0, 180.0, accent, 21.0, 260.0)
	_draw_text("相性 %d · %s · +%dEXP · +%d金币" % [
		int(result.get("score", 0)),
		str(result.get("relation_label", "初识")),
		int(result.get("exp_each", 0)),
		int(result.get("gold", 0))
	], DESIGN_W / 2.0, 206.0, C["text"], 11.0, 268.0)
	var event: Dictionary = result.get("event", {})
	_draw_text(str(event.get("name", "社交事件")), DESIGN_W / 2.0, 241.0, Color(0.76, 0.95, 1.0), 15.0, 260.0)
	_draw_text(str(event.get("flavor", "关系发生了变化。")), DESIGN_W / 2.0, 266.0, C["text_muted"], 10.2, 276.0)
	var lines := _social_result_major_lines(result)
	var y := 318.0
	for line in lines:
		_draw_text(str(line), DESIGN_W / 2.0, y, C["text"], 11.2, 278.0)
		y += 24.0
	_draw_code_button(SOCIAL_RESULT_CLOSE_RECT, "确认", true)

func _social_result_title(result: Dictionary) -> String:
	var major: Dictionary = result.get("majorOutcome", {})
	match str(major.get("type", "none")):
		"birth":
			return "复合新生"
		"erosion":
			return "侵蚀警报"
		_:
			return str(result.get("label", "社交完成"))

func _social_result_major_lines(result: Dictionary) -> Array:
	var major: Dictionary = result.get("majorOutcome", {})
	match str(major.get("type", "none")):
		"birth":
			var created: Array = major.get("createdInstances", [])
			var names: Array = []
			for child in created:
				if child is Dictionary:
					var child_data: Dictionary = child
					names.append(str(child_data.get("name", "复合幼体")))
			if names.is_empty():
				return ["产生了复合幼体计划，等待写入精灵池。"]
			return [
				"诞生 %d 只 Lv.1 复合幼体" % names.size(),
				"新成员：%s" % "、".join(names.slice(0, 2)),
				"已记录父母血缘与复合特质"
			]
		"erosion":
			if bool(major.get("protected", false)):
				return [
					"%s 出现侵蚀冲动" % str(major.get("aggressorName", "侵蚀者")),
					"%s 已受保护，未从精灵池删除" % str(major.get("victimName", "伙伴")),
					"高风险确认流程尚未开启"
				]
			var effect: Dictionary = major.get("negativeEffect", {})
			return [
				"%s 吞噬了 %s" % [str(major.get("aggressorName", "侵蚀者")), str(major.get("victimName", "伙伴"))],
				"获得额外 +%dEXP" % int(major.get("expGain", 0)),
				"负面状态：%s" % str(effect.get("name", "侵蚀负担"))
			]
		_:
			var tags: Array = result.get("tags", [])
			var lines: Array = [
				str(result.get("summary", "这次社交被记录到关系记忆。"))
			]
			if tags.has("属性相克"):
				lines.append("⚠ 属性相克 · 侵蚀风险提高")
			lines.append("标签：%s" % "、".join(tags))
			return lines

func _draw_picker_card(monster_id: String, rect: Rect2, in_use: bool) -> void:
	var highlighted := in_use or monster_id == _selected_monster_id()
	var monster := MonsterDb.get_monster(monster_id)
	_draw_texture_contain(_tex(RANCH_ASSETS["roster_card_selected" if highlighted else "roster_card"]), rect)
	_draw_monster_portrait(monster_id, Rect2(rect.position.x + 11.0, rect.position.y + 7.0, rect.size.x - 22.0, 43.0))
	_draw_text(str(monster.get("name", "")), rect.get_center().x, rect.position.y + 61.0, C["text"], 9.5, rect.size.x - 12.0)
	_draw_text("Lv.%d" % _get_monster_level(monster_id), rect.get_center().x, rect.position.y + 75.0, C["gold"], 9.5, rect.size.x - 12.0)
	if in_use:
		_draw_texture_contain(_tex(RANCH_ASSETS["check"]), Rect2(rect.position.x + rect.size.x - 21.0, rect.position.y + rect.size.y - 21.0, 20.0, 20.0))

func _draw_list_controls() -> void:
	if _max_list_page <= 0:
		return
	var left_alpha := 0.35 if _list_page <= 0 else 0.9
	var right_alpha := 0.35 if _list_page >= _max_list_page else 0.9
	_draw_texture_contain(_tex(RANCH_ASSETS["prev_arrow"]), Rect2(LIST_LEFT_ARROW_RECT.position + Vector2(7.0, 22.0), Vector2(30.0, 30.0)), left_alpha)
	_draw_texture_contain(_tex(RANCH_ASSETS["next_arrow"]), Rect2(LIST_RIGHT_ARROW_RECT.position + Vector2(7.0, 22.0), Vector2(30.0, 30.0)), right_alpha)

func _change_list_page(direction: int) -> void:
	var new_page := clampi(_list_page + direction, 0, _max_list_page)
	if new_page != _list_page:
		_list_page = new_page
		queue_redraw()

func _scroll_monster_list(direction: int) -> void:
	_change_list_page(direction)

func _draw_monster_portrait(monster_id: String, rect: Rect2) -> void:
	var tex := _tex(MonsterArtDBScript.get_art_path(_get_monster_id(monster_id), "ranch"))
	if tex:
		_draw_texture_contain(tex, rect)
	else:
		var placeholder := rect.grow(-minf(rect.size.x, rect.size.y) * 0.12)
		_draw_texture_contain(_tex(RANCH_ASSETS["social_slot"]), placeholder)
		_draw_text("?", placeholder.get_center().x, placeholder.position.y + placeholder.size.y * 0.68, C["text_muted"], minf(24.0, placeholder.size.x * 0.45), placeholder.size.x)

func _picker_card_rect(index: int) -> Rect2:
	var cards_per_page := int(LIST_CLIP_RECT.size.x / (LIST_CARD_W + LIST_CARD_GAP))
	cards_per_page = maxi(1, cards_per_page)
	var page_offset := _list_page * cards_per_page
	var card_x := LIST_CARD_START_X + float(index - page_offset) * (LIST_CARD_W + LIST_CARD_GAP)
	return Rect2(card_x, LIST_CARD_Y, LIST_CARD_W, LIST_CARD_H)

func _picker_index_at(pos: Vector2) -> int:
	if not LIST_CLIP_RECT.has_point(pos):
		return -1
	if LIST_LEFT_ARROW_RECT.has_point(pos) or LIST_RIGHT_ARROW_RECT.has_point(pos):
		return -1
	var cards_per_page := int(LIST_CLIP_RECT.size.x / (LIST_CARD_W + LIST_CARD_GAP))
	cards_per_page = maxi(1, cards_per_page)
	var page_offset := _list_page * cards_per_page
	var rel := pos.x - LIST_CARD_START_X
	if rel < 0.0:
		return -1
	var idx := page_offset + int(rel / (LIST_CARD_W + LIST_CARD_GAP))
	var card := _picker_card_rect(idx)
	if not LIST_CLIP_RECT.encloses(card) or not card.has_point(pos):
		return -1
	return idx

func _classroom_card_rect(index: int) -> Rect2:
	var rows_visible := int(CLASS_LIST_CLIP_RECT.size.y / (CLASS_CARD_H + CLASS_CARD_GAP))
	rows_visible = maxi(1, rows_visible)
	var page_offset := _class_page * rows_visible * CLASS_COLS
	var local := index - page_offset
	if local < 0:
		return Rect2(-9999, -9999, CLASS_CARD_W, CLASS_CARD_H)
	var col := local % CLASS_COLS
	var row := local / CLASS_COLS
	return Rect2(
		CLASS_GRID_X + float(col) * (CLASS_CARD_W + CLASS_CARD_GAP),
		CLASS_GRID_Y + float(row) * (CLASS_CARD_H + CLASS_CARD_GAP),
		CLASS_CARD_W,
		CLASS_CARD_H
	)

func _classroom_index_at(pos: Vector2) -> int:
	if not CLASS_LIST_CLIP_RECT.has_point(pos):
		return -1
	for i in range(_captured_monsters.size()):
		var card := _classroom_card_rect(i)
		if card.has_point(pos):
			return i
	return -1

func _selected_monster_id() -> String:
	if _selected_slot >= 0 and _selected_slot < _slots_data.size():
		var id = _slots_data[_selected_slot].get("instance_id", null)
		return str(id) if id != null else ""
	return ""

func _get_instance(instance_id: String) -> Dictionary:
	if instance_id.is_empty():
		return {}
	if _storage != null and _storage.has_method("get_monster_instance"):
		return _storage.get_monster_instance(instance_id)
	for candidate: Variant in _captured_monsters:
		if candidate is Dictionary and _get_instance_id(candidate) == instance_id:
			return (candidate as Dictionary).duplicate(true)
	return {"instanceId": instance_id, "monsterId": _get_monster_id(instance_id), "level": 1, "nature": ""}

func _get_instance_stats(instance_id: String) -> Dictionary:
	if _storage != null and _storage.has_method("get_instance_stats"):
		return _storage.get_instance_stats(instance_id)
	# 统一公式：牧场预览也走 StatCalculator（保持 nature 兼容）
	var instance := _get_instance(instance_id)
	var monster_id := _get_monster_id(instance_id)
	var level := _get_monster_level(instance_id)
	var nature := str(instance.get("nature", ""))
	# ★ 主人定 2026-06-11：精英宠物走 ELITE tier
	var is_elite: bool = bool(instance.get("isElite", MonsterDb.MONSTER_DB.get(monster_id, {}).get("isElite", false)))
	var tier: int = StatCalculator.EnemyTier.ELITE if is_elite else StatCalculator.EnemyTier.NORMAL
	return StatCalculator.calc_with_tier(monster_id, level, nature, tier)

func _get_selected_evolution_info() -> Dictionary:
	var instance_id := _class_selected_instance_id if _active_page == "classroom" else _selected_monster_id()
	return _get_evolution_info_for_instance(instance_id)

func _get_evolution_info_for_instance(instance_id: String) -> Dictionary:
	var instance := _get_instance(instance_id)
	if instance.is_empty():
		return {}
	var monster_id := str(instance.get("monsterId", ""))
	var monster := MonsterDb.get_monster(monster_id)
	var evolution: Dictionary = monster.get("evolution", {})
	var target_id := str(evolution.get("target", ""))
	var required_level := int(evolution.get("level", 1))
	var required_item := str(evolution.get("item", _get_default_evolution_item(monster_id)))
	var item_count: int = _storage.get_item_count(required_item) if _storage != null and _storage.has_method("get_item_count") else 0
	var item_data: Dictionary = ItemDBScript.get_item(required_item)
	var item_name := str(item_data.get("name", "进化道具"))
	var level := int(instance.get("level", 1))
	var has_evolution := not target_id.is_empty() and MonsterDb.has_monster(target_id)
	var preview := EvolutionRulesScript.build_preview(instance)
	var level_ok := level >= required_level
	var item_ok: bool = item_count > 0
	var condition := "无法进化"
	if has_evolution:
		condition = "Lv.%d / %s x1" % [required_level, item_name]
		if level_ok and not item_ok:
			condition = "%s不足(%d)" % [item_name, item_count]
		elif not level_ok and item_ok:
			condition = "等级不足(%d/%d)" % [level, required_level]
		elif level_ok and item_ok:
			condition = "条件满足"
	return {
		"instance_id": instance_id,
		"monster_id": monster_id,
		"target_id": target_id,
		"required_level": required_level,
		"required_item": required_item,
		"item_name": item_name,
		"item_count": item_count,
		"has_evolution": has_evolution,
		"level_ok": level_ok,
		"item_ok": item_ok,
		"can_evolve": has_evolution and level_ok and item_ok,
		"condition_text": condition,
		"stat_summary": str(preview.get("stat_summary", "")),
		"play_upgrade_text": "玩法: %s" % str(preview.get("play_upgrade", "稳定成长")) if has_evolution else "玩法: 已稳定",
		"social_text": str(preview.get("social_text", "社交启发: 无"))
	}

func _get_default_evolution_item(monster_id: String) -> String:
	var monster := MonsterDb.get_monster(monster_id)
	var element := str(monster.get("element", "fire"))
	var map := {
		"fire": "evolution_stone_fire",
		"water": "evolution_stone_water",
		"grass": "evolution_stone_grass",
		"thunder": "evolution_stone_thunder",
		"light": "evolution_stone_light",
		"earth": "evolution_stone_earth",
		"wind": "evolution_stone_wind",
		"dark": "evolution_stone_dark"
	}
	return str(map.get(element, "evolution_stone_fire"))

func _get_nature_name(nature_id: String) -> String:
	if nature_id.is_empty():
		return "无性格"
	var nature := NatureDB.get_nature(nature_id)
	return str(nature.get("name", nature_id)) if not nature.is_empty() else nature_id

func _gender_label(instance: Dictionary) -> String:
	var gender := SocialRulesScript.gender_for_instance(instance)
	return str(SocialRulesScript.GENDER_LABELS.get(gender, gender))

# ★ 主人定 2026-06-11：精英宠物名字前缀
#   instance.isElite=true 时返回 "★精英 "，否则空字符串
#   兼容老存档：fallback 到 MONSTER_DB.isElite
func _elite_prefix(instance: Dictionary) -> String:
	if instance.is_empty():
		return ""
	if bool(instance.get("isElite", false)):
		return "★精英 "
	var monster_id := str(instance.get("monsterId", ""))
	if monster_id.is_empty():
		return ""
	if bool(MonsterDb.MONSTER_DB.get(monster_id, {}).get("isElite", false)):
		return "★精英 "
	return ""

func _current_social_place() -> Dictionary:
	if _social_places.is_empty():
		_social_places = SocialRulesScript.normalize_places([], 1)
	return _social_places[0]

func _social_action_label(place: Dictionary) -> String:
	if SocialRulesScript.is_ready(place):
		return "领取"
	if place.get("started_at", null) != null:
		return "%d%%" % int(SocialRulesScript.progress(place) * 100.0)
	return "开始"

func _social_action_enabled(place: Dictionary) -> bool:
	return SocialRulesScript.is_ready(place) or SocialRulesScript.can_start(place)

func _social_preview_text(place: Dictionary) -> String:
	var a_id := str(place.get("slot_a", ""))
	var b_id := str(place.get("slot_b", ""))
	if a_id.is_empty() or b_id.is_empty():
		var last: Dictionary = place.get("last_result", {})
		if not last.is_empty():
			var last_major: Dictionary = last.get("majorOutcome", {})
			if str(last_major.get("type", "none")) != "none":
				return "%s：%s" % [str(last_major.get("name", "上次结果")), str(last_major.get("summary", ""))]
			return str(last.get("summary", "上次社交完成"))
		return "放入两只精灵后开始社交"
	var a := _get_instance(a_id)
	var b := _get_instance(b_id)
	if a.is_empty() or b.is_empty():
		return "社交对象异常"
	var preview := SocialRulesScript.preview(a, b, place)
	var major: Dictionary = preview.get("majorOutcome", {})
	var major_text := ""
	if str(major.get("type", "none")) != "none":
		major_text = " · " + str(major.get("name", "特殊结果"))
	return "%s %d分  关系:%s%s" % [preview.get("label", "社交"), int(preview.get("score", 0)), preview.get("relation_label", "初识"), major_text]

func _social_event_text(place: Dictionary) -> String:
	var a_id := str(place.get("slot_a", ""))
	var b_id := str(place.get("slot_b", ""))
	if a_id.is_empty() or b_id.is_empty():
		var last: Dictionary = place.get("last_result", {})
		if not last.is_empty():
			var last_major: Dictionary = last.get("majorOutcome", {})
			if str(last_major.get("type", "none")) != "none":
				return "%s：%s" % [str(last_major.get("name", "特殊结果")), str(last_major.get("rarity", "rare"))]
			var event: Dictionary = last.get("event", {})
			return "%s：%s" % [str(event.get("name", "上次事件")), str(last.get("relation_label", "关系"))]
		return "选择两只精灵后预览事件"
	var a := _get_instance(a_id)
	var b := _get_instance(b_id)
	if a.is_empty() or b.is_empty():
		return ""
	var preview := SocialRulesScript.preview(a, b, place)
	var major: Dictionary = preview.get("majorOutcome", {})
	if str(major.get("type", "none")) != "none":
		return "%s：%s" % [str(major.get("name", "特殊结果")), str(major.get("summary", ""))]
	var event: Dictionary = preview.get("event", {})
	return "%s：%s / %s" % [str(event.get("name", "社交事件")), str(event.get("theme", "陪伴")), str(event.get("hook", "memory"))]

func _social_event_flavor_text(place: Dictionary) -> String:
	var a_id := str(place.get("slot_a", ""))
	var b_id := str(place.get("slot_b", ""))
	var event: Dictionary = {}
	if a_id.is_empty() or b_id.is_empty():
		var last: Dictionary = place.get("last_result", {})
		event = last.get("event", {})
	else:
		var a := _get_instance(a_id)
		var b := _get_instance(b_id)
		if not a.is_empty() and not b.is_empty():
			event = SocialRulesScript.preview(a, b, place).get("event", {})
	var flavor := str(event.get("flavor", ""))
	if flavor.is_empty():
		return "事件内容会记录到关系记忆里。"
	return flavor

func _social_relationship_detail(place: Dictionary) -> Dictionary:
	var a_id := str(place.get("slot_a", ""))
	var b_id := str(place.get("slot_b", ""))
	if a_id.is_empty() or b_id.is_empty():
		return {}
	var a := _get_instance(a_id)
	var b := _get_instance(b_id)
	if a.is_empty() or b.is_empty():
		return {}
	return SocialRulesScript.build_relationship_detail(a, b, place)

func _used_monsters() -> Dictionary:
	var used := {}
	for slot: Dictionary in _slots_data:
		var id = slot.get("instance_id", null)
		if id != null:
			used[str(id)] = true
	return used

func _is_instance_in_ranch(instance_id: String) -> bool:
	if instance_id.is_empty():
		return false
	for slot: Dictionary in _slots_data:
		if str(slot.get("instance_id", "")) == instance_id:
			return true
	return false

func _is_instance_in_social(instance_id: String) -> bool:
	if instance_id.is_empty():
		return false
	for place: Dictionary in _social_places:
		if str(place.get("slot_a", "")) == instance_id or str(place.get("slot_b", "")) == instance_id:
			return true
	return false

func _update_list_scroll_limit() -> void:
	var cards_per_page := int(LIST_CLIP_RECT.size.x / (LIST_CARD_W + LIST_CARD_GAP))
	cards_per_page = maxi(1, cards_per_page)
	_max_list_page = maxi(0, ceili(float(_captured_monsters.size()) / float(cards_per_page)) - 1)
	_list_page = clampi(_list_page, 0, _max_list_page)

func _update_class_scroll_limit() -> void:
	_class_max_scroll_y = maxf(0.0, _classroom_content_height() - CLASS_LIST_CLIP_RECT.size.y)
	_class_scroll_y = clampf(_class_scroll_y, 0.0, _class_max_scroll_y)
	var class_cards_per_row := CLASS_COLS
	var class_rows_visible := int(CLASS_LIST_CLIP_RECT.size.y / (CLASS_CARD_H + CLASS_CARD_GAP))
	class_rows_visible = maxi(1, class_rows_visible)
	var rows_total := ceili(float(_captured_monsters.size()) / float(class_cards_per_row))
	_class_max_page = maxi(0, rows_total - class_rows_visible)
	_class_page = clampi(_class_page, 0, _class_max_page)

func _monster_list_content_width() -> float:
	if _captured_monsters.is_empty():
		return LIST_CLIP_RECT.size.x
	return maxf(LIST_CLIP_RECT.size.x, LIST_CARD_START_X - LIST_CLIP_RECT.position.x + float(_captured_monsters.size()) * LIST_CARD_W + float(maxi(0, _captured_monsters.size() - 1)) * LIST_CARD_GAP)

func _classroom_content_height() -> float:
	if _captured_monsters.is_empty():
		return CLASS_LIST_CLIP_RECT.size.y
	var rows := ceili(float(_captured_monsters.size()) / float(CLASS_COLS))
	return float(rows) * CLASS_CARD_H + float(maxi(0, rows - 1)) * CLASS_CARD_GAP

func _total_idle_exp() -> float:
	var total := 0.0
	for value in _idle_exp_map.values():
		total += float(value)
	return total

func _get_monster_level(monster_id: String) -> int:
	if _storage != null and _storage.has_method("get_instance_level"):
		return _storage.get_instance_level(monster_id)
	if _storage != null and _storage.has_method("get_monster_level"):
		return _storage.get_monster_level(_get_monster_id(monster_id))
	for candidate: Variant in _captured_monsters:
		if candidate is Dictionary and _get_instance_id(candidate) == monster_id:
			return int((candidate as Dictionary).get("level", 1))
	return 1

func _get_idle_exp_rate(monster_id: String) -> float:
	if _storage != null and _storage.has_method("get_idle_exp_rate_for_instance"):
		return _storage.get_idle_exp_rate_for_instance(monster_id)
	if _storage != null and _storage.has_method("get_idle_exp_rate"):
		return _storage.get_idle_exp_rate(_get_monster_id(monster_id))
	return 5.0 + float(_get_monster_level(monster_id))

func _get_care_state(instance_id: String) -> Dictionary:
	if _storage != null and _storage.has_method("get_ranch_care_state"):
		return _storage.get_ranch_care_state(instance_id)
	return {
		"rate": 5.0 + float(_get_monster_level(instance_id)),
		"label": "专注" if _care_focus_instance_id == instance_id else ""
	}

func _format_elapsed(placed_at: Variant) -> String:
	if placed_at == null:
		return "00:00:00"
	var elapsed := minf(maxf(0.0, Time.get_unix_time_from_system() * 1000.0 - float(placed_at)), IDLE_MAX_MS)
	var total_sec := int(elapsed / 1000.0)
	var h := total_sec / 3600
	var m := (total_sec % 3600) / 60
	var s := total_sec % 60
	return "%02d:%02d:%02d" % [h, m, s]

func _format_elapsed_short(placed_at: Variant) -> String:
	var time := _format_elapsed(placed_at)
	return "放置 " + time.substr(0, 5)

func _format_count(value: Variant) -> String:
	var num := float(value)
	if num >= 1000.0:
		return "%.1fK" % (num / 1000.0)
	return str(int(num))

func _to_design(pos: Vector2) -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return pos
	return Vector2(pos.x * DESIGN_W / size.x, pos.y * DESIGN_H / size.y)

func _resolve_storage() -> Node:
	if _game != null and "storage" in _game and _game.storage != null:
		return _game.storage
	return _root_node("SaveManager")

func _root_node(node_name: String) -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)

func _go_to_scene(scene_name: String) -> void:
	var manager := _root_node("SceneManager")
	if manager and manager.has_method("switch_scene"):
		manager.switch_scene(scene_name)

func _tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex:
		draw_texture_rect(tex, _scale_rect(rect), false, Color(1.0, 1.0, 1.0, opacity))

func _draw_texture_contain(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_rect := Rect2(rect.position + (rect.size - draw_size) * 0.5, draw_size)
	draw_texture_rect(tex, _scale_rect(draw_rect), false, Color(1.0, 1.0, 1.0, opacity))

func _draw_texture_three_slice(tex: Texture2D, rect: Rect2, left_src_w: float, right_src_w: float, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= left_src_w + right_src_w or tex_size.y <= 0.0:
		_draw_texture_fit(tex, rect, opacity)
		return
	var scale := rect.size.y / tex_size.y
	var left_w := minf(rect.size.x * 0.42, left_src_w * scale)
	var right_w := minf(rect.size.x * 0.42, right_src_w * scale)
	var middle_w := maxf(0.0, rect.size.x - left_w - right_w)
	var source_middle_w := tex_size.x - left_src_w - right_src_w
	var modulate := Color(1.0, 1.0, 1.0, opacity)
	draw_texture_rect_region(tex, _scale_rect(Rect2(rect.position, Vector2(left_w, rect.size.y))), Rect2(0.0, 0.0, left_src_w, tex_size.y), modulate)
	draw_texture_rect_region(tex, _scale_rect(Rect2(rect.position.x + left_w, rect.position.y, middle_w, rect.size.y)), Rect2(left_src_w, 0.0, source_middle_w, tex_size.y), modulate)
	draw_texture_rect_region(tex, _scale_rect(Rect2(rect.end.x - right_w, rect.position.y, right_w, rect.size.y)), Rect2(tex_size.x - right_src_w, 0.0, right_src_w, tex_size.y), modulate)

func _draw_texture_nine_slice(tex: Texture2D, rect: Rect2, source_corner: Vector2, dest_corner: Vector2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= source_corner.x * 2.0 or tex_size.y <= source_corner.y * 2.0:
		_draw_texture_fit(tex, rect, opacity)
		return
	var edge := Vector2(
		minf(dest_corner.x, rect.size.x * 0.46),
		minf(dest_corner.y, rect.size.y * 0.46)
	)
	var src_x := [0.0, source_corner.x, tex_size.x - source_corner.x, tex_size.x]
	var src_y := [0.0, source_corner.y, tex_size.y - source_corner.y, tex_size.y]
	var dst_x := [rect.position.x, rect.position.x + edge.x, rect.end.x - edge.x, rect.end.x]
	var dst_y := [rect.position.y, rect.position.y + edge.y, rect.end.y - edge.y, rect.end.y]
	var modulate := Color(1.0, 1.0, 1.0, opacity)
	for row in range(3):
		for col in range(3):
			var dest := Rect2(dst_x[col], dst_y[row], dst_x[col + 1] - dst_x[col], dst_y[row + 1] - dst_y[row])
			var source := Rect2(src_x[col], src_y[row], src_x[col + 1] - src_x[col], src_y[row + 1] - src_y[row])
			draw_texture_rect_region(tex, _scale_rect(dest), source, modulate)

func _draw_asset_button(rect: Rect2, text: String) -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["nav_button"]), rect)
	_draw_text(text, rect.get_center().x, rect.position.y + 30.0, C["text"], 13.0, rect.size.x - 12.0)

func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var source_size := rect.size / scale
	var source_pos := (tex_size - source_size) / 2.0
	draw_texture_rect_region(tex, _scale_rect(rect), Rect2(source_pos, source_size), Color(1.0, 1.0, 1.0, opacity))

func _draw_text(text: String, x: float, y: float, color: Color, font_size: float, max_w: float = 200.0) -> void:
	var font := ThemeDB.fallback_font
	var sx := _sx()
	var sy := _sy()
	var sc = minf(sx, sy)
	var left := (x - max_w / 2.0) * sx
	var pos := Vector2(left, y * sy)
	var width := max_w * sx
	draw_string(font, pos + Vector2(1.0, 1.5) * sc, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size * sc, Color(0, 0, 0, color.a * 0.62))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size * sc, color)

func _scale_rect(rect: Rect2) -> Rect2:
	return Rect2(
		rect.position.x * _sx(),
		rect.position.y * _sy(),
		rect.size.x * _sx(),
		rect.size.y * _sy()
	)

func _sx() -> float:
	return size.x / DESIGN_W if size.x > 0.0 else 1.0

func _sy() -> float:
	return size.y / DESIGN_H if size.y > 0.0 else 1.0

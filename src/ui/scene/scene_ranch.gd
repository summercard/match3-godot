# scene_ranch.gd - 怪物牧场
# 美术包装：按概念图重排，image-2 牧场资产 + Canvas 绘制
class_name SceneRanch
extends Control

signal exp_collected(total_exp: int)

const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const ItemDBScript = preload("res://src/data/item_db.gd")

const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0
const SLOT_COUNT: int = 5
const IDLE_INTERVAL_MS: float = 5.0 * 60.0 * 1000.0
const BUBBLE_TYPES := ["Z", "EXP", "+", "♪"]

const RANCH_ASSETS := {
	"bg": "res://assets/images/ranch/bg_ranch_pasture.png",
	"header": "res://assets/images/ranch/ui_header_plaque.png",
	"back": "res://assets/images/ranch/ui_back_button.png",
	"slot_occupied": "res://assets/images/ranch/ui_slot_occupied.png",
	"slot_empty": "res://assets/images/ranch/ui_slot_empty.png",
	"income_panel": "res://assets/images/ranch/ui_income_panel.png",
	"list_panel": "res://assets/images/ranch/ui_monster_list_panel.png",
	"collect_button": "res://assets/images/ranch/ui_btn_collect_gold.png",
	"status_ribbon": "res://assets/images/ranch/ui_status_ribbon_green.png",
	"reward_strip": "res://assets/images/ranch/ui_reward_strip_dark.png",
	"exp": "res://assets/images/ranch/icon_exp_badge.png",
	"coin": "res://assets/images/ranch/icon_gold_coin.png",
	"check": "res://assets/images/ranch/icon_check_badge.png",
	"banner": "res://assets/images/ranch/ui_banner_small.png",
	"banner_fringe": "res://assets/images/ranch/ui_banner_fringe.png",
	"sparkle": "res://assets/images/ranch/fx_leaf_sparkle_cluster.png",
}

const C := {
	"text": Color(1.0, 1.0, 1.0),
	"text_muted": Color(0.66, 0.72, 0.82),
	"gold": Color(1.0, 0.84, 0.25),
	"green": Color(0.47, 0.95, 0.31),
	"dark": Color(0.03, 0.06, 0.13, 0.86),
}

const SLOT_RECTS := [
	Rect2(20.0, 198.0, 106.0, 126.0),
	Rect2(134.0, 188.0, 106.0, 126.0),
	Rect2(248.0, 198.0, 106.0, 126.0),
	Rect2(78.0, 310.0, 108.0, 126.0),
	Rect2(204.0, 313.0, 108.0, 126.0),
]

const BACK_RECT := Rect2(12.0, 13.0, 54.0, 54.0)
const INCOME_RECT := Rect2(18.0, 604.0, 339.0, 54.0)
const LIST_RECT := Rect2(9.0, 466.0, 357.0, 128.0)
const LIST_CLIP_RECT := Rect2(28.0, 480.0, 319.0, 88.0)
const LIST_CARD_W: float = 55.0
const LIST_CARD_H: float = 74.0
const LIST_CARD_GAP: float = 8.0
const LIST_CARD_START_X: float = 34.0
const LIST_CARD_Y: float = 484.0
const LIST_LEFT_ARROW_RECT := Rect2(12.0, 500.0, 16.0, 54.0)
const LIST_RIGHT_ARROW_RECT := Rect2(347.0, 500.0, 16.0, 54.0)
const BOTTOM_LEFT_RECT := Rect2(25.0, 614.0, 76.0, 34.0)
const BOTTOM_RIGHT_RECT := Rect2(274.0, 614.0, 76.0, 34.0)
const CLASS_DETAIL_RECT := Rect2(15.0, 86.0, 345.0, 176.0)
const CLASS_LIST_RECT := Rect2(13.0, 274.0, 349.0, 319.0)
const CLASS_LIST_CLIP_RECT := Rect2(24.0, 286.0, 327.0, 292.0)
const CLASS_COLS: int = 3
const CLASS_CARD_W: float = 94.0
const CLASS_CARD_H: float = 102.0
const CLASS_CARD_GAP: float = 10.0
const CLASS_GRID_X: float = 31.0
const CLASS_GRID_Y: float = 292.0
const CLASS_EVOLVE_RECT := Rect2(242.0, 214.0, 92.0, 34.0)

var _game: Node = null
var _storage: Node = null
var _active_page: String = "ranch"
var _selected_slot: int = 0
var _slots_data: Array = []
var _captured_monsters: Array = []
var _idle_exp_map: Dictionary = {}
var _bubbles: Array = []
var _bubble_timer: float = 0.0
var _texture_cache: Dictionary = {}
var _time: float = 0.0
var _list_scroll_x: float = 0.0
var _max_list_scroll_x: float = 0.0
var _dragging_list: bool = false
var _class_scroll_y: float = 0.0
var _class_max_scroll_y: float = 0.0
var _dragging_class_list: bool = false
var _class_selected_instance_id: String = ""
var _last_drag_x: float = 0.0
var _last_drag_y: float = 0.0
var _status_text: String = ""
var _status_timer: float = 0.0

class BubbleData:
	var slot_index: int = 0
	var text: String = ""
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
				_dragging_class_list = _active_page == "classroom" and CLASS_LIST_RECT.has_point(design_pos)
			else:
				if abs(event.position.x - _last_drag_x) < 8.0 and abs(event.position.y - _last_drag_y) < 8.0:
					_handle_tap(_to_design(event.position))
				_dragging_list = false
				_dragging_class_list = false
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if _active_page == "classroom":
				_class_scroll_y = clampf(_class_scroll_y - 36.0, 0.0, _class_max_scroll_y)
			else:
				_list_scroll_x = clampf(_list_scroll_x - 24.0, 0.0, _max_list_scroll_x)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if _active_page == "classroom":
				_class_scroll_y = clampf(_class_scroll_y + 36.0, 0.0, _class_max_scroll_y)
			else:
				_list_scroll_x = clampf(_list_scroll_x + 24.0, 0.0, _max_list_scroll_x)
	elif event is InputEventMouseMotion and _dragging_list:
		var delta_x: float = _last_drag_x - event.position.x
		_list_scroll_x = clampf(_list_scroll_x + delta_x, 0.0, _max_list_scroll_x)
		_last_drag_x = event.position.x
		accept_event()
	elif event is InputEventMouseMotion and _dragging_class_list:
		var delta_y: float = _last_drag_y - event.position.y
		_class_scroll_y = clampf(_class_scroll_y + delta_y, 0.0, _class_max_scroll_y)
		_last_drag_y = event.position.y
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_last_drag_x = event.position.x
			_last_drag_y = event.position.y
			var design_pos := _to_design(event.position)
			_dragging_list = _active_page == "ranch" and LIST_RECT.has_point(design_pos)
			_dragging_class_list = _active_page == "classroom" and CLASS_LIST_RECT.has_point(design_pos)
		else:
			if abs(event.position.x - _last_drag_x) < 8.0 and abs(event.position.y - _last_drag_y) < 8.0:
				_handle_tap(_to_design(event.position))
			_dragging_list = false
			_dragging_class_list = false
		accept_event()
	elif event is InputEventScreenDrag and _dragging_list:
		_list_scroll_x = clampf(_list_scroll_x - event.relative.x, 0.0, _max_list_scroll_x)
		accept_event()
	elif event is InputEventScreenDrag and _dragging_class_list:
		_class_scroll_y = clampf(_class_scroll_y - event.relative.y, 0.0, _class_max_scroll_y)
		accept_event()

func _handle_tap(pos: Vector2) -> void:
	if BACK_RECT.has_point(pos):
		if _active_page == "classroom":
			_switch_to_ranch()
		else:
			_go_to_scene("main")
		return
	if _active_page == "classroom":
		_handle_classroom_tap(pos)
		return
	_handle_ranch_tap(pos)

func _handle_ranch_tap(pos: Vector2) -> void:
	if BOTTOM_LEFT_RECT.has_point(pos):
		_show_status("点击场上怪物收获")
		return
	if BOTTOM_RIGHT_RECT.has_point(pos):
		_switch_to_classroom()
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
		_show_status("功能预留")
		return
	if CLASS_EVOLVE_RECT.has_point(pos):
		_on_evolve_pressed()
		return
	var idx := _classroom_index_at(pos)
	if idx >= 0 and idx < _captured_monsters.size():
		_class_selected_instance_id = _get_instance_id(_captured_monsters[idx])
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

		if _storage.has_method("get_captured_monsters"):
			_captured_monsters = _storage.get_owned_monsters() if _storage.has_method("get_owned_monsters") else _storage.get_captured_monsters()
		else:
			var player: Dictionary = _storage.load_player() if _storage.has_method("load_player") else {}
			_captured_monsters = player.get("captured", [])
	else:
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
		})

func _calc_idle_exp() -> void:
	_idle_exp_map = {}
	var now := Time.get_unix_time_from_system() * 1000.0
	for slot: Dictionary in _slots_data:
		var monster_id = slot.get("instance_id", null)
		var placed_at = slot.get("placed_at", null)
		if monster_id == null or placed_at == null:
			continue
		var elapsed := maxf(0.0, now - float(placed_at))
		var intervals := int(elapsed / IDLE_INTERVAL_MS)
		if intervals <= 0:
			continue
		var rate := _get_idle_exp_rate(str(monster_id))
		_idle_exp_map[str(monster_id)] = intervals * rate

func _init_bubbles() -> void:
	_bubbles = []
	for i in range(_slots_data.size()):
		if _slots_data[i].get("instance_id", null) != null:
			_add_bubble(i)

func _add_bubble(slot_index: int) -> void:
	var bubble := BubbleData.new()
	bubble.slot_index = slot_index
	bubble.text = BUBBLE_TYPES[randi() % BUBBLE_TYPES.size()]
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
			_save_ranch_state()
			_refresh_ranch_view()
			return
	if _selected_slot < 0 or _selected_slot >= SLOT_COUNT:
		return
	var old_id = _slots_data[_selected_slot].get("instance_id", null)
	if old_id != null:
		var old_exp := int(_idle_exp_map.get(str(old_id), 0))
		if old_exp > 0 and _storage != null and _storage.has_method("add_instance_exp"):
			_storage.add_instance_exp(str(old_id), old_exp)
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
		_show_status("选择空位后从列表放入怪物")
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
		_show_status("请选择已放置的怪物")
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
	if _storage != null and _storage.has_method("use_item") and not _storage.use_item(required_item, 1):
		_show_status("%s 不足" % str(info.get("item_name", "进化道具")))
		return
	if _storage == null or not _storage.has_method("evolve_instance"):
		_show_status("进化系统不可用")
		return
	var result: Dictionary = _storage.evolve_instance(instance_id)
	if not bool(result.get("ok", false)):
		_show_status("进化失败：%s" % str(result.get("reason", "unknown")))
		return
	if _storage.has_method("add_achievement_progress"):
		_storage.add_achievement_progress("evolveCount", 1)
	var new_id := str(result.get("newMonsterId", ""))
	var new_data := MonsterDb.get_monster(new_id)
	_show_status("进化成功：%s" % str(new_data.get("name", new_id)))
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
	else:
		_draw_ranch_slots()
		_draw_bubbles()
		_draw_monster_list()
		_draw_income_panel()
		_draw_status_text()

func _draw_background() -> void:
	var bg := _tex(RANCH_ASSETS["bg"])
	if bg:
		_draw_texture_cover(bg, Rect2(0, 0, DESIGN_W, DESIGN_H))
	else:
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.06, 0.12, 0.08))
	draw_rect(Rect2(0, 0, DESIGN_W, 86), Color(0.02, 0.05, 0.12, 0.50))

func _draw_header() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["back"]), BACK_RECT)
	_draw_texture_fit(_tex(RANCH_ASSETS["header"]), Rect2(97, 18, 205, 46))
	_draw_text("怪物课堂" if _active_page == "classroom" else "怪物牧场", DESIGN_W / 2.0, 50.0, C["text"], 22.0, 190.0)

func _draw_status_text() -> void:
	if _status_timer <= 0.0 or _status_text.is_empty():
		return
	var alpha := minf(1.0, _status_timer)
	var y := 268.0 if _active_page == "classroom" else 92.0
	_draw_text(_status_text, DESIGN_W / 2.0, y, Color(1.0, 0.88, 0.36, alpha), 18.0, 260.0)

func _draw_code_button(rect: Rect2, text: String, enabled: bool) -> void:
	var bg := Color(0.93, 0.70, 0.22, 0.94) if enabled else Color(0.24, 0.27, 0.32, 0.78)
	var stroke := Color(1.0, 0.90, 0.42, 0.95) if enabled else Color(0.44, 0.48, 0.56, 0.65)
	var color := Color(0.18, 0.10, 0.02) if enabled else C["text_muted"]
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 7.0, bg)
	_draw_stroke_rect(rect, 1.5, stroke)
	_draw_text(text, rect.get_center().x, rect.position.y + 23.0, color, 13.0, rect.size.x)

func _draw_ranch_slots() -> void:
	for i in range(SLOT_RECTS.size()):
		_draw_slot(i, SLOT_RECTS[i])

func _draw_slot(index: int, rect: Rect2) -> void:
	var slot: Dictionary = _slots_data[index] if index < _slots_data.size() else {}
	var monster_id = slot.get("instance_id", null)
	var occupied := monster_id != null and MonsterDb.has_monster(_get_monster_id(str(monster_id)))
	var platform_rect := Rect2(rect.position.x, rect.position.y + 42.0, rect.size.x, 58.0)
	_draw_texture_fit(_tex(RANCH_ASSETS["slot_occupied" if occupied else "slot_empty"]), platform_rect, 0.96)
	if index == _selected_slot:
		_draw_stroke_rect(platform_rect.grow(-3.0), 2.0, C["gold"])

	if occupied:
		var id := str(monster_id)
		var level := _get_monster_level(id)
		_draw_monster_portrait(id, Rect2(rect.position.x + 20.0, rect.position.y + 2.0, rect.size.x - 40.0, 70.0))
		_draw_texture_fit(_tex(RANCH_ASSETS["banner"]), Rect2(rect.position.x + 20.0, rect.position.y + 88.0, rect.size.x - 40.0, 22.0))
		_draw_text("Lv.%d" % level, rect.get_center().x, rect.position.y + 104.0, C["text"], 13.0, 76.0)
		_draw_texture_fit(_tex(RANCH_ASSETS["status_ribbon"]), Rect2(rect.position.x + 8.0, rect.position.y + 109.0, rect.size.x - 16.0, 22.0))
		_draw_text("放置中 " + _format_elapsed(slot.get("placed_at", null)), rect.get_center().x, rect.position.y + 125.0, C["text"], 9.0, rect.size.x - 20.0)
		_draw_texture_fit(_tex(RANCH_ASSETS["reward_strip"]), Rect2(rect.position.x + 8.0, rect.position.y + 131.0, rect.size.x - 16.0, 25.0), 0.94)
		_draw_texture_fit(_tex(RANCH_ASSETS["exp"]), Rect2(rect.position.x + 14.0, rect.position.y + 134.0, 18.0, 18.0))
		_draw_text("+" + _format_count(_idle_exp_map.get(id, 0)), rect.position.x + 51.0, rect.position.y + 149.0, C["gold"], 9.0, 44.0)
		_draw_texture_fit(_tex(RANCH_ASSETS["coin"]), Rect2(rect.position.x + 61.0, rect.position.y + 134.0, 18.0, 18.0))
		_draw_text("+" + _format_count(_idle_exp_map.get(id, 0) * 1.25), rect.position.x + 92.0, rect.position.y + 149.0, C["gold"], 9.0, 40.0)
	else:
		_draw_text("+", rect.get_center().x, rect.position.y + 83.0, Color(0.98, 0.90, 0.67), 28.0, 60.0)
		_draw_texture_fit(_tex(RANCH_ASSETS["banner"]), Rect2(rect.position.x + 20.0, rect.position.y + 100.0, rect.size.x - 40.0, 24.0))
		_draw_text("空位", rect.get_center().x, rect.position.y + 118.0, C["text"], 13.0, 78.0)

func _draw_bubbles() -> void:
	for b: BubbleData in _bubbles:
		if b.slot_index < 0 or b.slot_index >= SLOT_RECTS.size():
			continue
		var rect: Rect2 = SLOT_RECTS[b.slot_index]
		var t := clampf(b.age / b.life, 0.0, 1.0)
		var alpha := 1.0 - maxf(0.0, (t - 0.72) / 0.28)
		var x := rect.get_center().x + sin(t * TAU) * 9.0 + b.drift * t
		var y := rect.position.y + 18.0 - b.rise * t
		_draw_text(b.text, x, y, Color(1.0, 0.95, 0.55, alpha), 10.0, 42.0)

func _draw_income_panel() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["income_panel"]), INCOME_RECT)
	var total_exp := _total_idle_exp()
	var total_coin := total_exp * 1.25
	_draw_code_button(BOTTOM_LEFT_RECT, "提示", true)
	_draw_texture_fit(_tex(RANCH_ASSETS["exp"]), Rect2(116.0, 617.0, 25.0, 25.0))
	_draw_text("+" + _format_count(total_exp), 164.0, 638.0, Color(0.98, 0.92, 0.65), 17.0, 54.0)
	_draw_texture_fit(_tex(RANCH_ASSETS["coin"]), Rect2(198.0, 617.0, 25.0, 25.0))
	_draw_text("+" + _format_count(total_coin), 244.0, 638.0, Color(0.98, 0.92, 0.65), 17.0, 54.0)
	_draw_code_button(BOTTOM_RIGHT_RECT, "课堂", true)

func _draw_monster_list() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["list_panel"]), LIST_RECT)
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
	_draw_rounded_rect(CLASS_DETAIL_RECT.position.x, CLASS_DETAIL_RECT.position.y, CLASS_DETAIL_RECT.size.x, CLASS_DETAIL_RECT.size.y, 8.0, Color(0.03, 0.06, 0.13, 0.82))
	_draw_stroke_rect(CLASS_DETAIL_RECT, 1.5, Color(0.35, 0.55, 0.80, 0.70))
	var instance_id := _class_selected_instance_id
	if instance_id.is_empty() and not _captured_monsters.is_empty():
		instance_id = _get_instance_id(_captured_monsters[0])
	if instance_id.is_empty():
		_draw_text("暂无怪物", CLASS_DETAIL_RECT.get_center().x, CLASS_DETAIL_RECT.position.y + 90.0, C["text_muted"], 14.0, 180.0)
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
	_draw_monster_portrait(instance_id, Rect2(34.0, 110.0, 92.0, 92.0))
	_draw_text(str(monster.get("name", monster_id)), 188.0, 113.0, C["text"], 18.0, 130.0)
	_draw_text("Lv.%d  %s" % [int(instance.get("level", 1)), _get_nature_name(str(instance.get("nature", "")))], 188.0, 137.0, C["text_muted"], 11.0, 145.0)
	_draw_text("HP %d   ATK %d" % [int(stats.get("hp", 0)), int(stats.get("atk", 0))], 188.0, 160.0, Color(0.82, 0.92, 1.0), 11.0, 150.0)
	_draw_text("进化: %s" % target_name, 188.0, 188.0, C["gold"] if bool(info.get("has_evolution", false)) else C["text_muted"], 12.0, 154.0)
	_draw_text(str(info.get("condition_text", "无法进化")), 188.0, 209.0, C["text_muted"], 10.0, 154.0)
	_draw_code_button(CLASS_EVOLVE_RECT, "进化", bool(info.get("can_evolve", false)))

func _draw_classroom_list() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["list_panel"]), CLASS_LIST_RECT)
	for i in range(_captured_monsters.size()):
		var card := _classroom_card_rect(i)
		if card.position.y + card.size.y < CLASS_LIST_CLIP_RECT.position.y or card.position.y > CLASS_LIST_CLIP_RECT.end.y:
			continue
		if card.position.x < CLASS_LIST_CLIP_RECT.position.x or card.end.x > CLASS_LIST_CLIP_RECT.end.x:
			continue
		_draw_classroom_card(_get_instance_id(_captured_monsters[i]), card)
	if _class_max_scroll_y > 0.0:
		var track := Rect2(353.0, CLASS_LIST_CLIP_RECT.position.y, 3.0, CLASS_LIST_CLIP_RECT.size.y)
		_draw_rounded_rect(track.position.x, track.position.y, track.size.x, track.size.y, 1.5, Color(0.12, 0.20, 0.32, 0.82))
		var thumb_h := maxf(36.0, track.size.y * minf(1.0, CLASS_LIST_CLIP_RECT.size.y / _classroom_content_height()))
		var thumb_y := track.position.y + (track.size.y - thumb_h) * (_class_scroll_y / _class_max_scroll_y)
		_draw_rounded_rect(track.position.x, thumb_y, track.size.x, thumb_h, 1.5, C["gold"])

func _draw_classroom_card(instance_id: String, rect: Rect2) -> void:
	var selected := instance_id == _class_selected_instance_id
	var bg := Color(0.08, 0.16, 0.23, 0.92)
	var stroke := C["gold"] if selected else Color(0.34, 0.48, 0.68, 0.95)
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 6.0, bg)
	_draw_stroke_rect(rect, 2.0, stroke)
	_draw_monster_portrait(instance_id, Rect2(rect.position.x + 14.0, rect.position.y + 8.0, rect.size.x - 28.0, 62.0))
	var monster := MonsterDb.get_monster(_get_monster_id(instance_id))
	_draw_text(str(monster.get("name", "")), rect.get_center().x, rect.position.y + 82.0, C["text"], 9.0, rect.size.x - 8.0)
	_draw_text("Lv.%d" % _get_monster_level(instance_id), rect.get_center().x, rect.position.y + 96.0, C["text_muted"], 8.0, rect.size.x)

func _draw_classroom_bottom() -> void:
	_draw_texture_fit(_tex(RANCH_ASSETS["income_panel"]), INCOME_RECT)
	_draw_code_button(BOTTOM_LEFT_RECT, "牧场", true)
	_draw_text("怪物课堂", DESIGN_W / 2.0, 637.0, C["text_muted"], 12.0, 120.0)
	_draw_code_button(BOTTOM_RIGHT_RECT, "预留", false)

func _draw_picker_card(monster_id: String, rect: Rect2, in_use: bool) -> void:
	var bg := Color(0.09, 0.16, 0.24, 0.90)
	var stroke := Color(0.38, 0.50, 0.70)
	if in_use:
		bg = Color(0.12, 0.30, 0.13, 0.92)
		stroke = Color(0.52, 0.86, 0.25)
	elif monster_id == _selected_monster_id():
		stroke = C["gold"]
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 5.0, bg)
	_draw_stroke_rect(rect, 2.0, stroke)
	_draw_monster_portrait(monster_id, Rect2(rect.position.x + 6.0, rect.position.y + 5.0, rect.size.x - 12.0, 47.0))
	_draw_text("Lv.%d" % _get_monster_level(monster_id), rect.get_center().x, rect.position.y + 67.0, C["text"], 9.0, rect.size.x)
	if in_use:
		_draw_texture_fit(_tex(RANCH_ASSETS["check"]), Rect2(rect.position.x + rect.size.x - 20.0, rect.position.y + rect.size.y - 20.0, 19.0, 19.0))

func _draw_list_controls() -> void:
	if _max_list_scroll_x <= 0.0:
		return
	var left_alpha := 0.35 if _list_scroll_x <= 0.5 else 0.9
	var right_alpha := 0.35 if _list_scroll_x >= _max_list_scroll_x - 0.5 else 0.9
	_draw_text("<", LIST_LEFT_ARROW_RECT.get_center().x, LIST_LEFT_ARROW_RECT.position.y + 35.0, Color(1.0, 0.92, 0.55, left_alpha), 16.0, 22.0)
	_draw_text(">", LIST_RIGHT_ARROW_RECT.get_center().x, LIST_RIGHT_ARROW_RECT.position.y + 35.0, Color(1.0, 0.92, 0.55, right_alpha), 16.0, 22.0)
	var track := Rect2(42.0, 580.0, 291.0, 4.0)
	_draw_rounded_rect(track.position.x, track.position.y, track.size.x, track.size.y, 2.0, Color(0.15, 0.25, 0.38, 0.82))
	var thumb_w := maxf(38.0, track.size.x * minf(1.0, LIST_CLIP_RECT.size.x / _monster_list_content_width()))
	var thumb_x := track.position.x
	if _max_list_scroll_x > 0.0:
		thumb_x += (track.size.x - thumb_w) * (_list_scroll_x / _max_list_scroll_x)
	_draw_rounded_rect(thumb_x, track.position.y, thumb_w, track.size.y, 2.0, Color(0.85, 0.72, 0.34, 0.95))

func _scroll_monster_list(direction: int) -> void:
	_list_scroll_x = clampf(_list_scroll_x + float(direction) * (LIST_CARD_W + LIST_CARD_GAP) * 3.0, 0.0, _max_list_scroll_x)
	queue_redraw()

func _draw_monster_portrait(monster_id: String, rect: Rect2) -> void:
	var tex := _tex(MonsterArtDBScript.get_art_path(_get_monster_id(monster_id), "ranch"))
	if tex:
		_draw_texture_fit(tex, rect)
	else:
		var db := MonsterDb.get_monster(_get_monster_id(monster_id))
		_draw_text(db.get("emoji", "?"), rect.get_center().x, rect.position.y + rect.size.y * 0.72, C["text"], minf(26.0, rect.size.x * 0.52), rect.size.x)

func _picker_card_rect(index: int) -> Rect2:
	return Rect2(LIST_CARD_START_X + float(index) * (LIST_CARD_W + LIST_CARD_GAP) - _list_scroll_x, LIST_CARD_Y, LIST_CARD_W, LIST_CARD_H)

func _picker_index_at(pos: Vector2) -> int:
	if not LIST_CLIP_RECT.has_point(pos):
		return -1
	if LIST_LEFT_ARROW_RECT.has_point(pos) or LIST_RIGHT_ARROW_RECT.has_point(pos):
		return -1
	var rel := pos.x + _list_scroll_x - LIST_CARD_START_X
	if rel < 0.0:
		return -1
	var idx := int(rel / (LIST_CARD_W + LIST_CARD_GAP))
	var card := _picker_card_rect(idx)
	if not LIST_CLIP_RECT.encloses(card) or not card.has_point(pos):
		return -1
	return idx

func _classroom_card_rect(index: int) -> Rect2:
	var col := index % CLASS_COLS
	var row := index / CLASS_COLS
	return Rect2(
		CLASS_GRID_X + float(col) * (CLASS_CARD_W + CLASS_CARD_GAP),
		CLASS_GRID_Y + float(row) * (CLASS_CARD_H + CLASS_CARD_GAP) - _class_scroll_y,
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
	return {"instanceId": instance_id, "monsterId": _get_monster_id(instance_id), "level": 1, "nature": ""}

func _get_instance_stats(instance_id: String) -> Dictionary:
	if _storage != null and _storage.has_method("get_instance_stats"):
		return _storage.get_instance_stats(instance_id)
	return MonsterDb.get_monster_stats(_get_monster_id(instance_id), _get_monster_level(instance_id))

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
		"condition_text": condition
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

func _used_monsters() -> Dictionary:
	var used := {}
	for slot: Dictionary in _slots_data:
		var id = slot.get("instance_id", null)
		if id != null:
			used[str(id)] = true
	return used

func _update_list_scroll_limit() -> void:
	var last_card_end := LIST_CARD_START_X + maxf(0.0, float(_captured_monsters.size()) - 1.0) * (LIST_CARD_W + LIST_CARD_GAP) + LIST_CARD_W
	_max_list_scroll_x = maxf(0.0, last_card_end - LIST_CLIP_RECT.end.x)
	_list_scroll_x = clampf(_list_scroll_x, 0.0, _max_list_scroll_x)

func _update_class_scroll_limit() -> void:
	_class_max_scroll_y = maxf(0.0, _classroom_content_height() - CLASS_LIST_CLIP_RECT.size.y)
	_class_scroll_y = clampf(_class_scroll_y, 0.0, _class_max_scroll_y)

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
	return 1

func _get_idle_exp_rate(monster_id: String) -> float:
	if _storage != null and _storage.has_method("get_idle_exp_rate_for_instance"):
		return _storage.get_idle_exp_rate_for_instance(monster_id)
	if _storage != null and _storage.has_method("get_idle_exp_rate"):
		return _storage.get_idle_exp_rate(_get_monster_id(monster_id))
	return 5.0 + float(_get_monster_level(monster_id))

func _format_elapsed(placed_at: Variant) -> String:
	if placed_at == null:
		return "00:00:00"
	var elapsed := maxf(0.0, Time.get_unix_time_from_system() * 1000.0 - float(placed_at))
	var total_sec := int(elapsed / 1000.0)
	var h := total_sec / 3600
	var m := (total_sec % 3600) / 60
	var s := total_sec % 60
	return "%02d:%02d:%02d" % [h, m, s]

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

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	var rect := _scale_rect(Rect2(x, y, w, h))
	draw_rect(rect, color)

func _draw_stroke_rect(rect: Rect2, line_width: float, color: Color) -> void:
	var r := _scale_rect(rect)
	var lw := line_width * minf(size.x / DESIGN_W, size.y / DESIGN_H)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, lw), color)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - lw, r.size.x, lw), color)
	draw_rect(Rect2(r.position.x, r.position.y, lw, r.size.y), color)
	draw_rect(Rect2(r.position.x + r.size.x - lw, r.position.y, lw, r.size.y), color)

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

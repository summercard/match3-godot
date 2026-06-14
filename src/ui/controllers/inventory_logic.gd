# ============================================
# inventory_logic.gd - 背包界面的旧脚本逻辑父类
# 翻译来源: js/ui/sceneInventory.js
# ============================================

class_name SceneInventory
extends Control

const ItemDB = preload("res://src/data/item_db.gd")

signal back_pressed()

const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0
const COLS := 5
const CELL_SIZE := 60.0
const CELL_GAP := 10.0
const BACK_RECT := Rect2(10.0, 8.0, 58.0, 58.0)
const TAB_Y := 64.0
const GRID_PANEL := Rect2(9.0, 104.0, 357.0, 405.0)
const GRID_TOP := 122.0
const GRID_BOTTOM := 502.0
const GRID_LEFT := 18.0
const DETAIL_RECT := Rect2(9.0, 515.0, 357.0, 136.0)
const USE_BTN_RECT := Rect2(275.0, 603.0, 78.0, 38.0)

const INVENTORY_ASSETS := {
	"bg": "res://assets/images/ui/backgrounds/main_lobby_bg_day_v3.png",
	"back": "res://assets/images/ui/buttons/album_ui_back_button.png",
	"backpack": "res://assets/images/ui/icons/common_nav_icon_nav_inventory.png",
	"currency_chip": "res://assets/images/ui/panels/main_ui_currency_capsule_v3.png",
	"tab_active": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_active.png",
	"tab_inactive": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_normal.png",
	"grid_panel": "res://assets/images/ui/panels/inventory_new_ui_inventory_panel.png",
	"slot": "res://assets/images/ui/slots/inventory_new_ui_inventory_slot.png",
	"slot_selected": "res://assets/images/ui/slots/inventory_new_ui_inventory_slot_selected.png",
	"slot_locked": "res://assets/images/ui/slots/inventory_new_ui_inventory_slot_empty.png",
	"scrollbar": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_normal.png",
	"detail_panel": "res://assets/images/ui/panels/inventory_new_ui_inventory_detail_panel.png",
	"detail_icon_frame": "res://assets/images/ui/icons/inventory_new_ui_inventory_icon_badge.png",
	"rarity_ribbon": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_normal.png",
	"use_button": "res://assets/images/ui/buttons/inventory_new_ui_inventory_use_button.png",
	"toast": "res://assets/images/ui/panels/inventory_new_ui_inventory_toast.png",
	"gold": "res://assets/images/ui/icons/main_icon_gold_coin_v3.png",
	"diamond": "res://assets/images/ui/gems/main_icon_diamond_gem_v3.png",
}

const ITEM_ICON_ASSETS := {
	"capture_ball": "res://assets/images/ui/icons/items_new_icon_capture_ball.png",
	"capture_ball_plus": "res://assets/images/ui/icons/items_new_icon_capture_ball_plus.png",
	"capture_ball_elite": "res://assets/images/ui/icons/items_new_icon_capture_ball_plus.png",
	"exp_potion": "res://assets/images/ui/icons/items_new_icon_exp_potion.png",
	"exp_crystal": "res://assets/images/ui/icons/items_new_icon_exp_crystal.png",
	"hp_potion": "res://assets/images/ui/icons/items_new_icon_hp_potion.png",
	"hp_potion_large": "res://assets/images/ui/icons/items_new_icon_hp_potion.png",
	"guard_charm": "res://assets/images/ui/icons/battle_icon_guard_charm.png",
	"rock_hammer": "res://assets/images/ui/icons/battle_icon_rock_hammer.png",
	"rock_hammer_plus": "res://assets/images/ui/icons/battle_icon_rock_hammer.png",
	"unlock_key": "res://assets/images/ui/gems/items_new_icon_evolution_stone_thunder.png",
	"mist_cleanser": "res://assets/images/ui/gems/items_new_icon_evolution_stone_water.png",
	"focus_crystal": "res://assets/images/ui/icons/battle_icon_focus_crystal.png",
	"board_reset": "res://assets/images/ui/icons/battle_icon_board_reset.png",
	"absorb_shield": "res://assets/images/ui/icons/battle_icon_absorb_shield.png",
	"gem_type_shift": "res://assets/images/ui/icons/battle_icon_gem_type_shift.png",
	"gold_bag": "res://assets/images/ui/icons/items_new_icon_gold_bag.png",
	"gold_chest": "res://assets/images/ui/icons/items_new_icon_gold_chest.png",
	"evolution_stone_fire": "res://assets/images/ui/gems/items_new_icon_evolution_stone_fire.png",
	"evolution_stone_water": "res://assets/images/ui/gems/items_new_icon_evolution_stone_water.png",
	"evolution_stone_grass": "res://assets/images/ui/gems/items_new_icon_evolution_stone_grass.png",
	"evolution_stone_thunder": "res://assets/images/ui/gems/items_new_icon_evolution_stone_thunder.png",
	"evolution_stone_light": "res://assets/images/ui/gems/items_new_icon_evolution_stone_light.png",
	"evolution_stone_earth": "res://assets/images/ui/gems/items_new_icon_evolution_stone_earth.png",
	"evolution_stone_wind": "res://assets/images/ui/gems/items_new_icon_evolution_stone_wind.png",
	"evolution_stone_dark": "res://assets/images/ui/gems/items_new_icon_evolution_stone_dark.png",
}

const TABS := [
	{"id": "all", "label": "全部"},
	{"id": "items", "label": "道具"},
	{"id": "materials", "label": "材料"},
	{"id": "gems", "label": "宝石"},
]
const C := {
	"white": Color(1.0, 1.0, 1.0),
	"muted": Color(0.66, 0.72, 0.83),
	"dim": Color(0.36, 0.44, 0.57),
	"gold": Color(1.0, 0.78, 0.18),
	"blue": Color(0.42, 0.78, 1.0),
	"shadow": Color(0, 0, 0, 0.55),
}

var _inventory: Dictionary = {}
var _player: Dictionary = {}
var _item_list: Array = []
var _selected_item: Dictionary = {}
var _capture_settings: Dictionary = {}
var _equipped_battle_items: Array = []
var _toast_text: String = ""
var _toast_timer: float = 0.0
var _scroll_offset: float = 0.0
var _storage: Node = null
var _active_tab := "all"
var _texture_cache: Dictionary = {}


func _ready() -> void:
	_storage = get_node_or_null("/root/SaveManager")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)


func init(data: Dictionary = {}) -> void:
	# print("[SceneInventory] 背包初始化")
	_storage = get_node_or_null("/root/SaveManager")
	_inventory = _storage.load_inventory() if _storage else {}
	_player = _storage.load_player() if _storage else {}
	_capture_settings = _storage.load_capture_settings() if _storage and _storage.has_method("load_capture_settings") else {"autoCapture": false, "equippedItem": "", "equippedBattleItems": []}
	_equipped_battle_items = _load_equipped_battle_items()
	_active_tab = data.get("tab", "all")
	_selected_item = {}
	_toast_text = ""
	_toast_timer = 0.0
	_scroll_offset = 0.0
	_build_item_list()
	set_process(false)
	queue_redraw()


func _build_item_list() -> void:
	_item_list.clear()
	for item_id in _inventory:
		var count: int = _inventory[item_id]
		if count > 0 and ItemDB.has_item(item_id):
			var item_data: Dictionary = ItemDB.get_item(item_id)
			if _matches_tab(item_data):
				_item_list.append({"id": item_id, "count": count, "data": item_data})
	_item_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	if _selected_item.is_empty() and not _item_list.is_empty():
		_selected_item = _item_list[0]
	elif not _selected_item.is_empty():
		var selected_id := str(_selected_item.get("id", ""))
		_selected_item = {}
		for item in _item_list:
			if item.get("id", "") == selected_id:
				_selected_item = item
				break
		if _selected_item.is_empty() and not _item_list.is_empty():
			_selected_item = _item_list[0]


func _matches_tab(item_data: Dictionary) -> bool:
	var item_type := str(item_data.get("type", ""))
	if _active_tab == "all":
		return true
	if _active_tab == "gems":
		return item_type == "evolution"
	if _active_tab == "materials":
		return item_type == "gold"
	return item_type != "evolution" and item_type != "gold"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenDrag:
		if abs(event.relative.y) > 10.0 and event.position.y >= GRID_TOP and event.position.y <= GRID_BOTTOM:
			var step := CELL_SIZE + CELL_GAP
			var max_offset := _get_max_scroll_offset()
			if event.relative.y < 0:
				_scroll_offset = minf(max_offset, _scroll_offset + step)
			else:
				_scroll_offset = maxf(0.0, _scroll_offset - step)
			queue_redraw()
		accept_event()


func _on_tap(x: float, y: float) -> void:
	var point := Vector2(x, y)
	if BACK_RECT.has_point(point):
		back_pressed.emit()
		return
	for tab in TABS:
		var rect := _get_tab_rect(str(tab["id"]))
		if rect.has_point(point):
			_active_tab = str(tab["id"])
			_scroll_offset = 0.0
			_selected_item = {}
			_build_item_list()
			queue_redraw()
			return
	if USE_BTN_RECT.has_point(point) and not _selected_item.is_empty():
		_use_item(str(_selected_item.get("id", "")))
		return
	var idx := _get_item_index_at(x, y)
	if idx >= 0 and idx < _item_list.size():
		_selected_item = _item_list[idx]
		queue_redraw()


func _get_item_index_at(x: float, y: float) -> int:
	if y < GRID_TOP or y > GRID_BOTTOM:
		return -1
	var rel_x := x - GRID_LEFT
	var rel_y := y - GRID_TOP + _scroll_offset
	if rel_x < 0.0 or rel_y < 0.0:
		return -1
	var col := int(rel_x / (CELL_SIZE + CELL_GAP))
	var row := int(rel_y / (CELL_SIZE + CELL_GAP))
	var local_x := fmod(rel_x, CELL_SIZE + CELL_GAP)
	var local_y := fmod(rel_y, CELL_SIZE + CELL_GAP)
	if col >= COLS or local_x > CELL_SIZE or local_y > CELL_SIZE:
		return -1
	return row * COLS + col


func _get_max_scroll_offset() -> float:
	var rows := ceili(float(_item_list.size()) / float(COLS))
	var content_h := rows * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var view_h := GRID_BOTTOM - GRID_TOP
	return maxf(0.0, content_h - view_h)


func _use_item(item_id: String) -> void:
	if item_id.is_empty() or not _storage:
		return
	var item_data: Dictionary = ItemDB.get_item(item_id)
	if item_data.is_empty():
		return
	var item_type := str(item_data.get("type", ""))
	var effect: Dictionary = item_data.get("effect", {})
	match item_type:
		"exp":
			var exp_gain: int = effect.get("expGain", 0)
			if exp_gain > 0 and _storage.use_item(item_id, 1):
				_storage.add_player_exp(exp_gain)
				_show_toast("获得 %d 经验" % exp_gain)
		"gold":
			var gold_gain: int = effect.get("goldGain", 0)
			if gold_gain > 0 and _storage.use_item(item_id, 1):
				_storage.add_gold(gold_gain)
				_show_toast("获得 %d 金币" % gold_gain)
		"capture":
			if _storage and _storage.has_method("save_capture_settings"):
				_capture_settings["equippedItem"] = item_id
				_storage.save_capture_settings(_capture_settings)
				_show_toast("已装备为捕捉球")
			else:
				_show_toast("捕捉球可在战斗中选择")
		"battle":
			_toggle_battle_item_equip(item_id)
			_inventory = _storage.load_inventory() if _storage else {}
			_player = _storage.load_player() if _storage else {}
			_capture_settings = _storage.load_capture_settings() if _storage and _storage.has_method("load_capture_settings") else _capture_settings
			_equipped_battle_items = _load_equipped_battle_items()
			_build_item_list()
			_scroll_offset = minf(_scroll_offset, _get_max_scroll_offset())
			queue_redraw()
			return
			_show_toast("战斗道具请在战斗中使用")
		"evolution":
			_show_toast("进化石请在精灵进化中使用")
		_:
			_show_toast("该道具暂时无法使用")
	_inventory = _storage.load_inventory() if _storage else {}
	_player = _storage.load_player() if _storage else {}
	_capture_settings = _storage.load_capture_settings() if _storage and _storage.has_method("load_capture_settings") else _capture_settings
	_equipped_battle_items = _load_equipped_battle_items()
	_build_item_list()
	_scroll_offset = minf(_scroll_offset, _get_max_scroll_offset())
	queue_redraw()


func _load_equipped_battle_items() -> Array:
	var result: Array = []
	var source: Array = _capture_settings.get("equippedBattleItems", [])
	var inventory: Dictionary = _inventory
	for value in source:
		var item_id := str(value)
		if result.size() >= 3:
			break
		if item_id.is_empty() or item_id in result:
			continue
		if int(inventory.get(item_id, 0)) <= 0:
			continue
		var item_data: Dictionary = ItemDB.get_item(item_id)
		if str(item_data.get("type", "")) != "battle":
			continue
		result.append(item_id)
	return result


func _toggle_battle_item_equip(item_id: String) -> void:
	if item_id.is_empty() or not _storage or not _storage.has_method("save_capture_settings"):
		return
	var item_data: Dictionary = ItemDB.get_item(item_id)
	if str(item_data.get("type", "")) != "battle":
		return
	if item_id in _equipped_battle_items:
		_equipped_battle_items.erase(item_id)
		_show_toast("已卸下 %s" % str(item_data.get("name", "道具")))
	else:
		if _equipped_battle_items.size() >= 3:
			_equipped_battle_items.remove_at(0)
		_equipped_battle_items.append(item_id)
		_show_toast("已装备 %s" % str(item_data.get("name", "道具")))
	_capture_settings["equippedBattleItems"] = _equipped_battle_items.duplicate()
	_storage.save_capture_settings(_capture_settings)


func _equip_battle_item_to_slot(item_id: String, slot_idx: int) -> void:
	if item_id.is_empty() or slot_idx < 0 or slot_idx >= 3 or not _storage or not _storage.has_method("save_capture_settings"):
		return
	var item_data: Dictionary = ItemDB.get_item(item_id)
	if str(item_data.get("type", "")) != "battle":
		return
	if item_id in _equipped_battle_items:
		_equipped_battle_items.erase(item_id)
	while _equipped_battle_items.size() <= slot_idx:
		_equipped_battle_items.append("")
	_equipped_battle_items[slot_idx] = item_id
	var compact: Array = []
	for value in _equipped_battle_items:
		var equipped_id := str(value)
		if not equipped_id.is_empty() and not compact.has(equipped_id):
			compact.append(equipped_id)
	_equipped_battle_items = compact
	_capture_settings["equippedBattleItems"] = _equipped_battle_items.duplicate()
	_storage.save_capture_settings(_capture_settings)
	_show_toast("已装备 %s" % str(item_data.get("name", "道具")))


func _show_toast(text: String) -> void:
	_toast_text = text
	_toast_timer = 1.8
	set_process(true)
	queue_redraw()


func _process(dt: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= dt
		if _toast_timer <= 0.0:
			_toast_text = ""
		queue_redraw()
		if _toast_timer <= 0.0:
			set_process(false)


func _draw() -> void:
	_draw_texture_cover(_tex("bg"), Rect2(0, 0, DESIGN_WIDTH, DESIGN_HEIGHT))
	_draw_header()
	_draw_tabs()
	_draw_grid()
	_draw_detail_panel()
	_draw_toast()


func _draw_header() -> void:
	_draw_texture_fit(_tex("back"), BACK_RECT)
	_draw_texture_fit(_tex("backpack"), Rect2(78.0, 16.0, 50.0, 46.0))
	_draw_text_shadow("背包", Vector2(170.0, 45.0), C["white"], 28.0, true, 110.0)
	_draw_currency_chip(Rect2(184.0, 16.0, 88.0, 32.0), "gold", int(_player.get("gold", 0)))
	_draw_currency_chip(Rect2(285.0, 16.0, 86.0, 32.0), "diamond", int(_player.get("gems", 0)))


func _draw_currency_chip(rect: Rect2, icon_key: String, amount: int) -> void:
	_draw_texture_fit(_tex("currency_chip"), rect)
	_draw_texture_fit(_tex(icon_key), Rect2(rect.position.x + 4.0, rect.position.y + 4.0, 24.0, 24.0))
	_draw_text_shadow(_format_number(amount), Vector2(rect.position.x + 57.0, rect.position.y + 22.0), C["white"], 14.0, true, 58.0)


func _draw_tabs() -> void:
	for tab in TABS:
		var rect := _get_tab_rect(str(tab["id"]))
		var active: bool = str(tab["id"]) == _active_tab
		_draw_texture_fit(_tex("tab_active" if active else "tab_inactive"), rect)
		_draw_text_shadow(tab["label"], rect.get_center() + Vector2(0, 8.0), C["white"] if active else C["muted"], 17.0, true, rect.size.x)


func _get_tab_rect(tab_id: String) -> Rect2:
	var idx := 0
	for i in range(TABS.size()):
		if str(TABS[i]["id"]) == tab_id:
			idx = i
			break
	return Rect2(8.0 + idx * 91.0, TAB_Y, 91.0, 42.0)


func _draw_grid() -> void:
	_draw_texture_fit(_tex("grid_panel"), GRID_PANEL)
	if _item_list.is_empty():
		_draw_text_shadow("还没有道具", GRID_PANEL.get_center() + Vector2(0, -18.0), C["muted"], 17.0, true, 160.0)
		_draw_text_shadow("去战斗或商店获取吧", GRID_PANEL.get_center() + Vector2(0, 12.0), C["dim"], 13.0, false, 180.0)
	else:
		for idx in range(_item_list.size()):
			var row := idx / COLS
			var col := idx % COLS
			var gx := GRID_LEFT + col * (CELL_SIZE + CELL_GAP)
			var gy := GRID_TOP + row * (CELL_SIZE + CELL_GAP) - _scroll_offset
			if gy + CELL_SIZE < GRID_TOP or gy > GRID_BOTTOM:
				continue
			_draw_item_slot(_item_list[idx], Rect2(gx, gy, CELL_SIZE, CELL_SIZE))
	_draw_locked_slots()
	_draw_scrollbar()


func _draw_item_slot(item: Dictionary, rect: Rect2) -> void:
	var selected: bool = not _selected_item.is_empty() and item.get("id", "") == _selected_item.get("id", "")
	_draw_texture_fit(_tex("slot_selected" if selected else "slot"), rect)
	_draw_texture_fit(_get_item_texture(str(item.get("id", ""))), Rect2(rect.position.x + 8.0, rect.position.y + 7.0, 44.0, 42.0))
	_draw_text_shadow(str(item.get("count", 0)), rect.position + Vector2(46.0, 52.0), C["white"], 14.0, true, 34.0)


func _draw_locked_slots() -> void:
	var visible_slots := 25
	var start := _item_list.size()
	for idx in range(start, mini(visible_slots, start + 5)):
		var row := idx / COLS
		var col := idx % COLS
		var gx := GRID_LEFT + col * (CELL_SIZE + CELL_GAP)
		var gy := GRID_TOP + row * (CELL_SIZE + CELL_GAP) - _scroll_offset
		if gy + CELL_SIZE >= GRID_TOP and gy <= GRID_BOTTOM:
			_draw_texture_fit(_tex("slot_locked"), Rect2(gx, gy, CELL_SIZE, CELL_SIZE))


func _draw_scrollbar() -> void:
	var max_off := _get_max_scroll_offset()
	if max_off <= 0.0:
		return
	var track := Rect2(350.0, GRID_TOP + 8.0, 9.0, GRID_BOTTOM - GRID_TOP - 16.0)
	_draw_texture_fit(_tex("scrollbar"), track)
	var thumb_h := maxf(38.0, track.size.y * (track.size.y / (track.size.y + max_off)))
	var thumb_y := track.position.y + (track.size.y - thumb_h) * (_scroll_offset / max_off)
	draw_rect(Rect2(track.position.x + 2.0, thumb_y, 5.0, thumb_h), Color(0.85, 0.78, 0.66, 0.9), true)


func _draw_detail_panel() -> void:
	_draw_texture_fit(_tex("detail_panel"), DETAIL_RECT)
	if _selected_item.is_empty():
		_draw_text_shadow("选择一个道具查看详情", DETAIL_RECT.get_center(), C["muted"], 15.0, true, 220.0)
		return
	var item_data: Dictionary = _selected_item.get("data", {})
	var item_id := str(_selected_item.get("id", ""))
	_draw_texture_fit(_tex("detail_icon_frame"), Rect2(20.0, 532.0, 112.0, 96.0))
	_draw_texture_fit(_get_item_texture(item_id), Rect2(46.0, 550.0, 60.0, 58.0))
	_draw_texture_fit(_tex("rarity_ribbon"), Rect2(26.0, 617.0, 100.0, 28.0))
	_draw_text_shadow(_rarity_label(int(item_data.get("rarity", 1))), Vector2(76.0, 636.0), C["muted"], 12.0, true, 80.0)
	_draw_text_left(item_data.get("name", ""), Vector2(143.0, 549.0), C["blue"], 18.0, true, 160.0)
	_draw_text_left(_wrap_text(item_data.get("desc", ""), 15), Vector2(143.0, 579.0), C["muted"], 13.0, false, 178.0)
	_draw_text_left("拥有: %d" % int(_selected_item.get("count", 0)), Vector2(143.0, 630.0), C["gold"], 12.0, true, 100.0)
	var item_type := str(item_data.get("type", ""))
	var equipped := item_type == "capture" and str(_capture_settings.get("equippedItem", "")) == item_id
	if item_type == "capture":
		_draw_text_left("战斗捕捉球: %s" % ("已装备" if equipped else "未装备"), Vector2(223.0, 630.0), C["gold"] if equipped else C["muted"], 12.0, true, 122.0)
	_draw_texture_fit(_tex("use_button"), USE_BTN_RECT)
	var button_text := "装备" if item_type == "capture" and not equipped else ("已装备" if item_type == "capture" else "使用")
	_draw_text_shadow(button_text, USE_BTN_RECT.get_center() + Vector2(0, 8.0), C["white"], 18.0, true, USE_BTN_RECT.size.x)


func _draw_toast() -> void:
	if _toast_text == "" or _toast_timer <= 0.0:
		return
	var alpha := minf(_toast_timer / 0.5, 1.0)
	_draw_texture_fit(_tex("toast"), Rect2(62.0, 580.0, 250.0, 42.0), alpha)
	_draw_text_shadow(_toast_text, Vector2(DESIGN_WIDTH / 2.0, 607.0), Color(1, 1, 1, alpha), 14.0, true, 220.0)


func _rarity_label(rarity: int) -> String:
	match rarity:
		1:
			return "普通"
		2:
			return "稀有"
		3:
			return "史诗"
		_:
			return "传说"


func _wrap_text(text: String, max_chars: int) -> String:
	var result := ""
	var line_len := 0
	for i in range(text.length()):
		result += text[i]
		line_len += 1
		if line_len >= max_chars and i < text.length() - 1:
			result += "\n"
			line_len = 0
	return result


func _format_number(value: int) -> String:
	var text := str(value)
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = text[i] + out
		count += 1
	return out


func _tex(key: String) -> Texture2D:
	return _get_texture(INVENTORY_ASSETS.get(key, ""))


func _get_item_texture(item_id: String) -> Texture2D:
	return _get_texture(ITEM_ICON_ASSETS.get(item_id, ""))


func _get_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path] as Texture2D


func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1, 1, 1, opacity))


func _draw_texture_cover(tex: Texture2D, rect: Rect2) -> void:
	if tex == null:
		draw_rect(rect, Color(0.04, 0.07, 0.15), true)
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var source_size := rect.size / scale
	var source_pos := (tex_size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size))


func _draw_text_shadow(text: String, center: Vector2, color: Color, font_size: float, bold: bool = false, width: float = 160.0) -> void:
	var size_i := int(font_size)
	var left := center.x - width / 2.0
	draw_string(ThemeDB.fallback_font, Vector2(left + 1.0, center.y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, C["shadow"])
	draw_string(ThemeDB.fallback_font, Vector2(left, center.y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, color)


func _draw_text_left(text: String, pos: Vector2, color: Color, font_size: float, bold: bool = false, width: float = 160.0) -> void:
	var size_i := int(font_size)
	var lines := text.split("\n")
	for i in range(lines.size()):
		var y := pos.y + i * (font_size + 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(pos.x + 1.0, y + 2.0), lines[i], HORIZONTAL_ALIGNMENT_LEFT, width, size_i, C["shadow"])
		draw_string(ThemeDB.fallback_font, Vector2(pos.x, y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, width, size_i, color)

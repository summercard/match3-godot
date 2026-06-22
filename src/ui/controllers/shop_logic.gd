# shop_logic.gd - 商店界面的旧脚本逻辑父类
# 翻译来源: js/ui/sceneShop.js
class_name SceneShop
extends Control

const PROJECT_ROUND_FONT: Font = preload("res://assets/fonts/jf-openhuninn-2.1.ttf")
const ItemDB = preload("res://src/data/item_db.gd")

signal purchase_completed(item_id: String, quantity: int)

const DESIGN_W := 375.0
const DESIGN_H := 667.0

const BACK_BTN := Rect2(10.0, 8.0, 58.0, 58.0)
const TAB_Y := 68.0
const FEATURE_RECT := Rect2(12.0, 112.0, 351.0, 126.0)
const GRID_Y := 252.0
const GRID_BOTTOM := 590.0
const GRID_COLS := 4
const CARD_W := 82.0
const CARD_H := 142.0
const CARD_GAP_X := 8.0
const CARD_GAP_Y := 12.0
const CARD_LEFT := 11.0
const BTN_H := 27.0
const BOTTOM_NAV_RECT := Rect2(0.0, 596.0, 375.0, 71.0)

const SHOP_ASSETS := {
	"bg": "res://assets/images/ui/backgrounds/ranch_optimized_bg_pet_academy_750.png",
	"top_bar": "res://assets/images/ui/panels/shop_ui_shop_title_plaque_image2.png",
	"back_button": "res://assets/images/ui/buttons/ranch_ui_btn_previous_round.png",
	"currency_chip": "res://assets/images/ui/panels/main_ui_currency_capsule_v3.png",
	"tab_active": "res://assets/images/ui/buttons/shop_ui_shop_tab_active_image2_clean.png",
	"tab_inactive": "res://assets/images/ui/buttons/shop_ui_shop_tab_normal_image2_clean.png",
	"feature_banner": "res://assets/images/ui/panels/inventory_new_ui_inventory_panel.png",
	"product_card": "res://assets/images/ui/cards/shop_ui_shop_card_panel_image2_clean.png",
	"price_plate": "res://assets/images/ui/buttons/shop_ui_shop_price_button_image2_clean.png",
	"buy_button": "res://assets/images/ui/buttons/inventory_new_ui_inventory_use_button.png",
	"buy_button_disabled": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_normal.png",
	"popup_panel": "res://assets/images/ui/panels/inventory_new_ui_inventory_detail_panel.png",
	"qty_button": "res://assets/images/ui/buttons/album_ui_dex_filter_compact_normal.png",
	"bottom_nav": "res://assets/images/ui/icons/main_ui_bottom_nav_panel_v3.png",
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
	{"id": "all", "label": "所有", "icon": "▣"},
	{"id": "capture", "label": "捕获道具", "icon": "●"},
	{"id": "battle", "label": "战场道具", "icon": "★"},
	{"id": "other", "label": "其他道具", "icon": "◆"},
]

const C := {
	"white": Color(1.0, 1.0, 1.0),
	"muted": Color(0.64, 0.70, 0.82),
	"dim": Color(0.38, 0.45, 0.58),
	"gold": Color(1.0, 0.78, 0.18),
	"danger": Color(1.0, 0.28, 0.26),
	"success": Color(0.30, 0.88, 0.42),
	"blue": Color(0.34, 0.78, 1.0),
	"shadow": Color(0.0, 0.0, 0.0, 0.55),
}

var game: Node
var player_data: Dictionary = {}
var shop_list: Array = []
var selected_item: Dictionary = {}
var popup: Dictionary = {}
var scroll_offset: float = 0.0
var tap_handler: Callable
var swipe_handler: Callable
var _storage: Node = null
var _bg_texture: ColorRect
var _texture_cache: Dictionary = {}
var _active_tab := "all"
var _popup_quantity := 1


func _init(game_ref: Node = null) -> void:
	game = game_ref
	_add_dark_background()
	set_process(false)


func _add_dark_background() -> void:
	_bg_texture = ColorRect.new()
	_bg_texture.color = Color(0.04, 0.07, 0.15, 1.0)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)


func init(data: Dictionary = {}) -> void:
	# print("[SceneShop] 商店初始化")
	if game == null:
		game = get_node_or_null("/root/GameManager")
	_storage = _get_storage()
	_load_player()
	selected_item = {}
	popup = {}
	scroll_offset = 0.0
	_popup_quantity = 1
	_active_tab = data.get("tab", "all")
	_build_shop_list()
	_set_input_handlers()
	set_process(false)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenDrag:
		var direction := "up" if event.relative.y < 0.0 else "down"
		_on_swipe(event.position.x, event.position.y, direction)
		accept_event()


func _load_player() -> void:
	var storage := _get_storage()
	player_data = storage.load_player() if storage and storage.has_method("load_player") else {}


func _get_storage() -> Node:
	if _storage and is_instance_valid(_storage):
		return _storage
	_storage = get_node_or_null("/root/SaveManager")
	if _storage == null and game and game.get("storage"):
		_storage = game.storage
	return _storage


func _build_shop_list() -> void:
	shop_list = []
	var shop_items: Array = ItemDB.get_shop_items()
	for entry in shop_items:
		var item_id: String = entry.get("id", "")
		var item_data: Dictionary = ItemDB.get_item(item_id)
		if item_data.is_empty():
			continue
		shop_list.append({
			"id": item_id,
			"price": entry.get("price", 0),
			"currency": entry.get("currency", "gold"),
			"daily_limit": entry.get("daily_limit", _default_daily_limit(item_data)),
			"label": entry.get("label", ""),
			"data": item_data
		})


func _set_input_handlers() -> void:
	tap_handler = Callable(self, "_on_tap")
	swipe_handler = Callable(self, "_on_swipe")


func _on_tap(x: float, y: float) -> void:
	if popup.size() > 0:
		_handle_popup_tap(x, y)
		return

	if BACK_BTN.has_point(Vector2(x, y)):
		_go_main()
		return

	for tab in TABS:
		var rect := _get_tab_rect(tab["id"])
		if rect.has_point(Vector2(x, y)):
			_active_tab = tab["id"]
			scroll_offset = 0.0
			return

	_handle_product_tap(x, y)


func _handle_popup_tap(x: float, y: float) -> void:
	var rect := _popup_rect()
	if not rect.has_point(Vector2(x, y)):
		popup = {}
		return

	if Rect2(rect.position.x + rect.size.x - 34.0, rect.position.y + 10.0, 24.0, 24.0).has_point(Vector2(x, y)):
		popup = {}
		return

	if _popup_minus_rect().has_point(Vector2(x, y)):
		_popup_quantity = maxi(1, _popup_quantity - 1)
		return
	if _popup_plus_rect().has_point(Vector2(x, y)):
		_popup_quantity = mini(99, _popup_quantity + 1)
		return
	if _popup_plus_ten_rect().has_point(Vector2(x, y)):
		_popup_quantity = mini(99, _popup_quantity + 10)
		return
	if _popup_cancel_rect().has_point(Vector2(x, y)):
		popup = {}
		return
	if _popup_confirm_rect().has_point(Vector2(x, y)):
		_confirm_purchase(str(popup.get("id", "")), _popup_quantity)
		popup = {}
		return


func _handle_product_tap(x: float, y: float) -> void:
	var items := _get_visible_shop_items()
	if y < GRID_Y or y > GRID_BOTTOM:
		return
	for i in range(items.size()):
		var card := _get_card_rect(i)
		if card.position.y + card.size.y < GRID_Y or card.position.y > GRID_BOTTOM:
			continue
		var buy_rect := Rect2(card.position.x + 7.0, card.position.y + 111.0, CARD_W - 14.0, BTN_H)
		if buy_rect.has_point(Vector2(x, y)):
			var shop_item: Dictionary = items[i]
			selected_item = shop_item
			_show_purchase_popup(shop_item)
			return


func _on_swipe(x: float, y: float, direction: String) -> void:
	if popup.size() > 0 or y < GRID_Y or y > GRID_BOTTOM:
		return
	var max_offset := _get_max_scroll_offset()
	if direction == "up":
		scroll_offset = minf(max_offset, scroll_offset + 86.0)
	elif direction == "down":
		scroll_offset = maxf(0.0, scroll_offset - 86.0)


func _get_visible_shop_items() -> Array:
	var result: Array = []
	for entry in shop_list:
		var item: Dictionary = entry.get("data", {})
		var item_type: String = item.get("type", "")
		if _active_tab == "items" and item_type == "evolution":
			continue
		if _active_tab == "gems" and item_type != "evolution":
			continue
		result.append(entry)
	if _active_tab == "recommend" and result.size() > 8:
		return result.slice(0, 8)
	return result


func _get_max_scroll_offset() -> float:
	var items := _get_visible_shop_items()
	var rows := ceili(float(items.size()) / float(GRID_COLS))
	var content_h := rows * (CARD_H + CARD_GAP_Y) - CARD_GAP_Y
	return maxf(0.0, content_h - (GRID_BOTTOM - GRID_Y))


func _get_card_rect(index: int) -> Rect2:
	var col := index % GRID_COLS
	var row := index / GRID_COLS
	var x := CARD_LEFT + col * (CARD_W + CARD_GAP_X)
	var y := GRID_Y + row * (CARD_H + CARD_GAP_Y) - scroll_offset
	return Rect2(x, y, CARD_W, CARD_H)


func _go_main() -> void:
	if game and game.get("scene_manager") and game.scene_manager.has_method("switch_scene"):
		game.scene_manager.switch_scene("main", {}, "slide")
	elif has_node("/root/SceneManager"):
		get_node("/root/SceneManager").switch_scene("main", {}, "slide")


func _show_purchase_popup(item: Dictionary) -> void:
	_popup_quantity = 1
	popup = {
		"id": item.id,
		"data": item.data,
		"price": item.price,
		"currency": item.currency
	}


func _confirm_purchase(item_id: String, quantity: int = 1) -> void:
	var item_data: Dictionary = ItemDB.get_item(item_id)
	if item_data.is_empty():
		return

	quantity = maxi(1, quantity)
	var storage := _get_storage()
	if storage == null:
		_show_toast("存档暂不可用，请稍后重试", "warning")
		return
	var remaining := _get_daily_remaining(item_id)
	if remaining <= 0:
		_show_toast("今日购买次数已用完", "warning")
		return
	if quantity > remaining:
		_show_toast("今日最多还能购买 %d 个" % remaining, "warning")
		return
	var player: Dictionary = _load_player_data()
	var total_price: float = _get_item_price(item_id) * quantity
	var currency: String = _get_item_currency(item_id)

	if currency == "gold":
		if (player.get("gold", 0) as float) < total_price:
			_show_toast("金币不足", "warning")
			return
	elif currency == "gems":
		if (player.get("gems", 0) as float) < total_price:
			_show_toast("宝石不足", "warning")
			return
	else:
		_show_toast("商品货币配置错误", "warning")
		return

	var updated_player: Dictionary = {}
	var tx: Dictionary = {"ok": false, "error": "storage_unavailable"}
	if storage.has_method("run_transaction"):
		tx = storage.run_transaction(func():
			var tx_remaining := _get_daily_remaining(item_id)
			if tx_remaining <= 0:
				return {"ok": false, "error": "daily_limit_empty"}
			if quantity > tx_remaining:
				return {"ok": false, "error": "daily_limit_changed", "remaining": tx_remaining}

			var tx_player: Dictionary = _load_player_data()
			if currency == "gold":
				if (tx_player.get("gold", 0) as float) < total_price:
					return {"ok": false, "error": "not_enough_gold"}
				tx_player["gold"] = (tx_player.get("gold", 0) as float) - total_price
			elif currency == "gems":
				if (tx_player.get("gems", 0) as float) < total_price:
					return {"ok": false, "error": "not_enough_gems"}
				tx_player["gems"] = (tx_player.get("gems", 0) as float) - total_price
			else:
				return {"ok": false, "error": "bad_currency"}
			_save_player_data(tx_player)
			_add_item(item_id, quantity)
			_record_daily_purchase(item_id, quantity)
			updated_player = tx_player.duplicate(true)
			return {"ok": true}
		)
	else:
		if currency == "gold":
			player["gold"] = (player.get("gold", 0) as float) - total_price
		elif currency == "gems":
			player["gems"] = (player.get("gems", 0) as float) - total_price
		_save_player_data(player)
		_add_item(item_id, quantity)
		_record_daily_purchase(item_id, quantity)
		updated_player = player.duplicate(true)
		tx = {"ok": true}

	if not bool(tx.get("ok", false)):
		var error := str(tx.get("error", "save_failed"))
		if error == "daily_limit_changed":
			_show_toast("今日最多还能购买 %d 个" % int(tx.get("remaining", 0)), "warning")
		elif error == "daily_limit_empty":
			_show_toast("今日购买次数已用完", "warning")
		elif error == "not_enough_gold":
			_show_toast("金币不足", "warning")
		elif error == "not_enough_gems":
			_show_toast("宝石不足", "warning")
		else:
			_show_toast("购买保存失败，请重试", "warning")
		return

	player_data["gold"] = updated_player.get("gold", player.get("gold", 0))
	player_data["gems"] = updated_player.get("gems", player.get("gems", 0))

	emit_signal("purchase_completed", item_id, quantity)
	_show_toast("获得 %s x%d" % [str(item_data.get("name", "")), quantity], "success")
	# print("[Shop] 购买成功: %s x%d" % [str(item_data.get("name", "")), quantity])


func _load_player_data() -> Dictionary:
	var storage := _get_storage()
	return storage.load_player() if storage and storage.has_method("load_player") else {}


func _save_player_data(player: Dictionary) -> void:
	var storage := _get_storage()
	if storage and storage.has_method("save_player"):
		storage.save_player(player)


func _add_item(item_id: String, count: int) -> void:
	var storage := _get_storage()
	if storage and storage.has_method("add_item"):
		storage.add_item(item_id, count)


func _get_item_price(item_id: String) -> float:
	for entry in shop_list:
		if entry.id == item_id:
			return entry.price
	return 0.0


func _get_item_currency(item_id: String) -> String:
	for entry in shop_list:
		if entry.id == item_id:
			return entry.currency
	return "gold"


func _can_afford(item_id: String, quantity: int = 1) -> bool:
	if quantity > _get_daily_remaining(item_id):
		return false
	var price := _get_item_price(item_id) * quantity
	var currency := _get_item_currency(item_id)
	if currency == "gold":
		return (player_data.get("gold", 0) as float) >= price
	return (player_data.get("gems", 0) as float) >= price


func _show_toast(msg: String, kind: String = "info") -> void:
	if has_node("../ToastManager") or has_node("%ToastManager"):
		var tm = get_node("%ToastManager") if has_node("%ToastManager") else get_node("../ToastManager")
		if tm.has_method("show_toast"):
			tm.show_toast(msg, kind)


func _draw() -> void:
	_draw_texture_cover(_tex("bg"), Rect2(0, 0, DESIGN_W, DESIGN_H))
	_draw_header()
	_draw_tabs()
	_draw_feature_banner()
	_draw_product_grid()
	_draw_bottom_nav()
	if popup.size() > 0:
		_draw_popup()


func _draw_header() -> void:
	_draw_texture_fit(_tex("top_bar"), Rect2(0, 0, DESIGN_W, 60.0))
	_draw_texture_fit(_tex("back_button"), BACK_BTN)
	_draw_text_shadow("商店", Vector2(118.0, 39.0), C["white"], 28.0, true, 120.0)
	_draw_currency_chip(Rect2(178.0, 14.0, 92.0, 32.0), "gold", int(player_data.get("gold", 0)))
	_draw_currency_chip(Rect2(278.0, 14.0, 92.0, 32.0), "diamond", int(player_data.get("gems", 0)))


func _draw_currency_chip(rect: Rect2, icon_key: String, amount: int) -> void:
	_draw_texture_fit(_tex("currency_chip"), rect)
	_draw_texture_fit(_tex(icon_key), Rect2(rect.position.x + 5.0, rect.position.y + 4.0, 24.0, 24.0))
	_draw_text_shadow(_format_number(amount), Vector2(rect.position.x + 58.0, rect.position.y + 22.0), C["white"], 15.0, true, 65.0)


func _draw_tabs() -> void:
	for tab in TABS:
		var rect: Rect2 = _get_tab_rect(str(tab["id"]))
		var active: bool = str(tab["id"]) == _active_tab
		_draw_texture_fit(_tex("tab_active" if active else "tab_inactive"), rect)
		var color: Color = C["gold"] if active else C["muted"]
		_draw_text_shadow("%s  %s" % [tab["icon"], tab["label"]], rect.get_center() + Vector2(0, 8), color, 17.0, true, rect.size.x)


func _get_tab_rect(tab_id: String) -> Rect2:
	var idx := 0
	for i in range(TABS.size()):
		if TABS[i]["id"] == tab_id:
			idx = i
			break
	return Rect2(38.0 + idx * 102.0, TAB_Y, 98.0, 42.0)


func _draw_feature_banner() -> void:
	_draw_texture_fit(_tex("feature_banner"), FEATURE_RECT)
	_draw_texture_fit(_get_texture("res://assets/images/ui/icons/items_new_icon_gold_chest.png"), Rect2(36.0, 130.0, 80.0, 80.0))
	_draw_text_shadow("新手超值礼包", Vector2(250.0, 143.0), C["gold"], 21.0, true, 190.0)
	_draw_text_shadow("限时特惠，助力冒险！", Vector2(252.0, 166.0), C["white"], 12.0, true, 170.0)
	_draw_feature_reward("gold", "x10,000", Vector2(202.0, 195.0))
	_draw_feature_reward("diamond", "x1,000", Vector2(256.0, 195.0))
	_draw_texture_fit(_get_texture("res://assets/images/ui/gems/items_new_icon_evolution_stone_fire.png"), Rect2(302.0, 174.0, 32.0, 32.0))
	_draw_text_shadow("x10", Vector2(319.0, 217.0), C["white"], 9.0, true, 42.0)
	_draw_texture_fit(_tex("buy_button"), Rect2(224.0, 208.0, 106.0, 29.0))
	_draw_text_shadow("¥ 30", Vector2(277.0, 229.0), C["white"], 17.0, true, 90.0)


func _draw_feature_reward(icon_key: String, label: String, pos: Vector2) -> void:
	_draw_texture_fit(_tex("price_plate"), Rect2(pos.x - 19.0, pos.y - 22.0, 38.0, 42.0))
	_draw_texture_fit(_tex(icon_key), Rect2(pos.x - 12.0, pos.y - 16.0, 24.0, 24.0))
	_draw_text_shadow(label, pos + Vector2(0, 20.0), C["white"], 8.0, true, 48.0)


func _draw_product_grid() -> void:
	var items := _get_visible_shop_items()
	draw_rect(Rect2(0, GRID_Y - 6.0, DESIGN_W, GRID_BOTTOM - GRID_Y + 8.0), Color(0.02, 0.08, 0.15, 0.18), true)
	for i in range(items.size()):
		var card := _get_card_rect(i)
		if card.position.y + card.size.y < GRID_Y or card.position.y > GRID_BOTTOM:
			continue
		_draw_product_card(items[i], card)
	_draw_scrollbar(items.size())


func _draw_product_card(shop_item: Dictionary, rect: Rect2) -> void:
	var item: Dictionary = shop_item.get("data", {})
	_draw_texture_fit(_tex("product_card"), rect)
	_draw_text_shadow(item.get("name", ""), Vector2(rect.get_center().x, rect.position.y + 24.0), C["white"], 11.0, true, rect.size.x - 8.0)
	_draw_texture_fit(_get_item_texture(shop_item.get("id", "")), Rect2(rect.position.x + 18.0, rect.position.y + 40.0, 46.0, 46.0))
	_draw_text_shadow(_get_limit_text(shop_item), Vector2(rect.get_center().x, rect.position.y + 89.0), C["muted"], 8.0, true, 68.0)
	var price_rect := Rect2(rect.position.x + 7.0, rect.position.y + 92.0, 68.0, 24.0)
	_draw_texture_fit(_tex("price_plate"), price_rect)
	var currency_key := "diamond" if shop_item.get("currency", "gold") == "gems" else "gold"
	_draw_texture_fit(_tex(currency_key), Rect2(price_rect.position.x + 8.0, price_rect.position.y + 4.0, 16.0, 16.0))
	_draw_text_shadow(str(shop_item.get("price", 0)), Vector2(price_rect.position.x + 45.0, price_rect.position.y + 17.0), C["gold"] if currency_key == "gold" else C["blue"], 12.0, true, 42.0)
	var buy_rect := Rect2(rect.position.x + 7.0, rect.position.y + 111.0, CARD_W - 14.0, BTN_H)
	var can_afford := _can_afford(shop_item.get("id", ""))
	_draw_texture_fit(_tex("buy_button" if can_afford else "buy_button_disabled"), buy_rect)
	_draw_text_shadow("购买" if can_afford else "不足", buy_rect.get_center() + Vector2(0, 6.0), C["white"] if can_afford else C["muted"], 13.0 if can_afford else 10.0, true, buy_rect.size.x)


func _draw_scrollbar(item_count: int) -> void:
	var max_offset := _get_max_scroll_offset()
	if max_offset <= 0.0:
		return
	var track := Rect2(366.0, GRID_Y, 4.0, GRID_BOTTOM - GRID_Y)
	draw_rect(track, Color(1, 1, 1, 0.12), true)
	var rows := ceili(float(item_count) / float(GRID_COLS))
	var content_h := rows * (CARD_H + CARD_GAP_Y) - CARD_GAP_Y
	var thumb_h := maxf(38.0, track.size.y * (track.size.y / content_h))
	var thumb_y := track.position.y + (track.size.y - thumb_h) * (scroll_offset / max_offset)
	draw_rect(Rect2(365.0, thumb_y, 6.0, thumb_h), Color(0.62, 0.82, 1.0, 0.7), true)


func _draw_bottom_nav() -> void:
	_draw_texture_fit(_tex("bottom_nav"), BOTTOM_NAV_RECT)
	var labels := [
		{"icon": "▣", "text": "每日特惠"},
		{"icon": "◆", "text": "限时礼包"},
		{"icon": "★", "text": "月卡"},
	]
	for i in range(labels.size()):
		var x := 62.0 + i * 125.0
		_draw_text_shadow(labels[i]["icon"], Vector2(x, 626.0), C["dim"], 25.0, true, 80.0)
		_draw_text_shadow(labels[i]["text"], Vector2(x, 657.0), C["muted"], 12.0, true, 90.0)
		if i < labels.size() - 1:
			draw_rect(Rect2(124.0 + i * 125.0, 618.0, 1.0, 32.0), Color(0.5, 0.62, 0.8, 0.24), true)


func _draw_popup() -> void:
	var rect := _popup_rect()
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0, 0, 0, 0.52), true)
	_draw_texture_fit(_tex("popup_panel"), rect)
	_draw_text_shadow("购买确认", Vector2(rect.get_center().x, rect.position.y + 35.0), C["white"], 18.0, true, 160.0)
	_draw_text_shadow("×", Vector2(rect.position.x + rect.size.x - 22.0, rect.position.y + 29.0), C["white"], 24.0, true, 32.0)
	var data: Dictionary = popup.get("data", {})
	var item_id := str(popup.get("id", ""))
	_draw_texture_fit(_get_item_texture(item_id), Rect2(rect.position.x + 31.0, rect.position.y + 59.0, 72.0, 72.0))
	_draw_text_left(data.get("name", ""), Vector2(rect.position.x + 122.0, rect.position.y + 82.0), C["white"], 18.0, true, 150.0)
	_draw_text_left("拥有：%d" % _get_item_count(item_id), Vector2(rect.position.x + 122.0, rect.position.y + 107.0), C["muted"], 13.0, false, 150.0)
	_draw_quantity_controls(rect)
	_draw_total_price(rect)
	_draw_texture_fit(_tex("buy_button_disabled"), _popup_cancel_rect())
	_draw_text_shadow("取消", _popup_cancel_rect().get_center() + Vector2(0, 7), C["white"], 16.0, true, _popup_cancel_rect().size.x)
	var can_afford := _can_afford(item_id, _popup_quantity)
	_draw_texture_fit(_tex("buy_button" if can_afford else "buy_button_disabled"), _popup_confirm_rect())
	_draw_text_shadow("确认购买", _popup_confirm_rect().get_center() + Vector2(0, 7), C["white"] if can_afford else C["muted"], 16.0, true, _popup_confirm_rect().size.x)


func _draw_quantity_controls(rect: Rect2) -> void:
	_draw_texture_fit(_tex("qty_button"), _popup_minus_rect())
	_draw_text_shadow("−", _popup_minus_rect().get_center() + Vector2(0, 7), C["white"], 20.0, true, 40.0)
	draw_rect(Rect2(rect.position.x + 92.0, rect.position.y + 116.0, 116.0, 34.0), Color(0.04, 0.11, 0.20, 0.85), true)
	draw_rect(Rect2(rect.position.x + 92.0, rect.position.y + 116.0, 116.0, 34.0), Color(0.32, 0.45, 0.65, 0.8), false, 2.0)
	_draw_text_shadow(str(_popup_quantity), Vector2(rect.position.x + 150.0, rect.position.y + 140.0), C["white"], 18.0, true, 90.0)
	_draw_texture_fit(_tex("qty_button"), _popup_plus_rect())
	_draw_text_shadow("+", _popup_plus_rect().get_center() + Vector2(0, 7), C["white"], 18.0, true, 40.0)
	_draw_texture_fit(_tex("qty_button"), _popup_plus_ten_rect())
	_draw_text_shadow("+10", _popup_plus_ten_rect().get_center() + Vector2(0, 7), C["white"], 14.0, true, 42.0)


func _draw_total_price(rect: Rect2) -> void:
	var total := int(popup.get("price", 0)) * _popup_quantity
	var currency_key := "diamond" if popup.get("currency", "gold") == "gems" else "gold"
	var price_rect := Rect2(rect.position.x + 88.0, rect.position.y + 151.0, 124.0, 29.0)
	_draw_texture_fit(_tex("price_plate"), price_rect)
	_draw_text_left("总价:", Vector2(price_rect.position.x + 9.0, price_rect.position.y + 20.0), C["muted"], 12.0, false, 45.0)
	_draw_texture_fit(_tex(currency_key), Rect2(price_rect.position.x + 56.0, price_rect.position.y + 4.0, 21.0, 21.0))
	_draw_text_shadow(str(total), Vector2(price_rect.position.x + 96.0, price_rect.position.y + 21.0), C["gold"] if currency_key == "gold" else C["blue"], 15.0, true, 55.0)


func _popup_rect() -> Rect2:
	return Rect2(38.0, 462.0, 300.0, 190.0)


func _popup_minus_rect() -> Rect2:
	var r := _popup_rect()
	return Rect2(r.position.x + 38.0, r.position.y + 116.0, 42.0, 34.0)


func _popup_plus_rect() -> Rect2:
	var r := _popup_rect()
	return Rect2(r.position.x + 220.0, r.position.y + 116.0, 42.0, 34.0)


func _popup_plus_ten_rect() -> Rect2:
	var r := _popup_rect()
	return Rect2(r.position.x + 263.0, r.position.y + 116.0, 42.0, 34.0)


func _popup_cancel_rect() -> Rect2:
	var r := _popup_rect()
	return Rect2(r.position.x + 18.0, r.position.y + 148.0, 124.0, 36.0)


func _popup_confirm_rect() -> Rect2:
	var r := _popup_rect()
	return Rect2(r.position.x + 158.0, r.position.y + 148.0, 126.0, 36.0)


func _get_limit_text(shop_item: Dictionary) -> String:
	var item_id := str(shop_item.get("id", ""))
	var limit := _get_daily_limit(item_id)
	return "每日限购 %d/%d" % [_get_daily_remaining(item_id), limit]


func _default_daily_limit(item: Dictionary) -> int:
	match str(item.get("type", "")):
		"capture":
			return 10
		"evolution":
			return 3
		_:
			return 5


func _get_daily_limit(item_id: String) -> int:
	for entry in shop_list:
		if str(entry.get("id", "")) == item_id:
			return maxi(1, int(entry.get("daily_limit", 1)))
	return 1


func _get_daily_purchased(item_id: String) -> int:
	var storage := _get_storage()
	if storage and storage.has_method("get_shop_daily_purchase_count"):
		return int(storage.get_shop_daily_purchase_count(item_id))
	return 0


func _get_daily_remaining(item_id: String) -> int:
	return maxi(0, _get_daily_limit(item_id) - _get_daily_purchased(item_id))


func _record_daily_purchase(item_id: String, quantity: int) -> void:
	var storage := _get_storage()
	if storage and storage.has_method("record_shop_daily_purchase"):
		storage.record_shop_daily_purchase(item_id, quantity)


func _get_item_count(item_id: String) -> int:
	var storage := _get_storage()
	if storage and storage.has_method("load_inventory"):
		var inv: Dictionary = storage.load_inventory()
		return int(inv.get(item_id, 0))
	return 0


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
	return _get_texture(SHOP_ASSETS.get(key, ""))


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
	draw_string(PROJECT_ROUND_FONT, Vector2(left + 1.0, center.y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, C["shadow"])
	draw_string(PROJECT_ROUND_FONT, Vector2(left, center.y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, color)


func _draw_text_left(text: String, pos: Vector2, color: Color, font_size: float, bold: bool = false, width: float = 160.0) -> void:
	var size_i := int(font_size)
	draw_string(PROJECT_ROUND_FONT, Vector2(pos.x + 1.0, pos.y + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, C["shadow"])
	draw_string(PROJECT_ROUND_FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, color)


func _process(_delta: float) -> void:
	pass

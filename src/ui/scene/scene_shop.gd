# scene_shop.gd - 商店场景
# 翻译来源: js/ui/sceneShop.js
class_name SceneShop extends Control

## 信号
signal purchase_completed(item_id: String, quantity: int)

## 布局常量
const BACK_BTN := Rect2(10, 10, 60, 36)
const CURRENCY_Y := 100
const LIST_Y := 160
const ITEM_H := 70
const ITEM_GAP := 8
const BTN_X := 280
const BTN_W := 80
const BTN_H := 40
const DESIGN_W := 375.0
const DESIGN_H := 667.0

var game: Node
var player_data: Dictionary = {}
var shop_list: Array = []
var selected_item: Dictionary = {}
var popup: Dictionary = {}
var scroll_offset: float = 0.0
var tap_handler: Callable
var swipe_handler: Callable

var _bg_texture: ColorRect

func _add_dark_background() -> void:
	_bg_texture = ColorRect.new()
	_bg_texture.color = Color(0.04, 0.07, 0.15, 1.0)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

func _init(game_ref: Node = null) -> void:
	game = game_ref
	_add_dark_background()
	_add_currency_icons()

func _add_currency_icons() -> void:
	if ResourceLoader.exists("res://assets/images/main/icon_gold.png"):
		var gold_icon := TextureRect.new()
		gold_icon.texture = load("res://assets/images/main/icon_gold.png")
		gold_icon.position = Vector2(58, CURRENCY_Y - 4)
		gold_icon.size = Vector2(20, 20)
		gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gold_icon.z_index = -5
		add_child(gold_icon)
	if ResourceLoader.exists("res://assets/images/main/icon_diamond.png"):
		var gem_icon := TextureRect.new()
		gem_icon.texture = load("res://assets/images/main/icon_diamond.png")
		gem_icon.position = Vector2(273, CURRENCY_Y - 4)
		gem_icon.size = Vector2(20, 20)
		gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gem_icon.z_index = -5
		add_child(gem_icon)


func init(data: Dictionary = {}) -> void:
	print("[SceneShop] 商店初始化")
	if game == null:
		game = get_node_or_null("/root/GameManager")
	_load_player()
	selected_item = {}
	popup = {}
	scroll_offset = 0.0
	_build_shop_list()
	_set_input_handlers()


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
	var storage = preload("res://src/core/save_manager.gd").new()
	player_data = storage.load_player()
	storage.free()


func _build_shop_list() -> void:
	shop_list = []
	# SHOP_ITEMS 和 ITEMS_DB 需在对应数据模块中定义
	var shop_items: Array = []
	var items_db: Dictionary = {}
	if ResourceLoader.exists("res://src/data/item_db.gd"):
		var item_db_res = load("res://src/data/item_db.gd")
		if item_db_res:
			var instance = item_db_res.new()
			if instance.has("SHOP_ITEMS"):
				shop_items = instance.SHOP_ITEMS
			if instance.has("ITEMS_DB"):
				items_db = instance.ITEMS_DB
			instance.free()

	for entry in shop_items:
		var item_data: Dictionary = {}
		if items_db.has(entry.id):
			item_data = items_db[entry.id]
		shop_list.append({
			"id": entry.id,
			"price": entry.price,
			"currency": entry.currency,
			"label": entry.label if entry.has("label") else "",
			"data": item_data
		})


func _set_input_handlers() -> void:
	tap_handler = Callable(self, "_on_tap")
	swipe_handler = Callable(self, "_on_swipe")
	# 连接 game 的输入信号（根据实际输入系统实现）


func _on_tap(x: float, y: float) -> void:
	# 购买确认弹窗
	if popup.size() > 0:
		var p: Dictionary = popup
		var pw: float = p.w
		var ph: float = p.h
		var px: float = p.x
		var py: float = p.y
		# 遮罩点击关闭
		if not (x >= px and x <= px + pw and y >= py and y <= py + ph):
			popup = {}
			return
		# 确认按钮
		var confirm_x: float = px + 20
		var confirm_y: float = py + ph - 55
		if x >= confirm_x and x <= confirm_x + 110 and y >= confirm_y and y <= confirm_y + 40:
			_confirm_purchase(p.id)
			popup = {}
			return
		# 取消按钮
		var cancel_x: float = px + 150
		if x >= cancel_x and x <= cancel_x + 110 and y >= confirm_y and y <= confirm_y + 40:
			popup = {}
			return
		return

	# 返回按钮
	if _in_rect(x, y, BACK_BTN):
		_go_main()
		return

	# 商品购买按钮
	var list_bottom_y: float = DESIGN_H - 20
	if y < LIST_Y or y > list_bottom_y:
		return
	for i in range(shop_list.size()):
		var shop_item: Dictionary = shop_list[i]
		var item_y: float = LIST_Y + i * (ITEM_H + ITEM_GAP) - scroll_offset
		if item_y < LIST_Y or item_y + ITEM_H > list_bottom_y:
			continue
		var btn_y: float = item_y + (ITEM_H - BTN_H) / 2
		if x >= BTN_X and x <= BTN_X + BTN_W and y >= btn_y and y <= btn_y + BTN_H:
			selected_item = shop_item
			_show_purchase_popup(shop_item)
			return


func _on_swipe(x: float, y: float, direction: String) -> void:
	if popup.size() > 0 or y < LIST_Y:
		return
	var max_offset: float = _get_max_scroll_offset()
	if direction == "up":
		scroll_offset = min(max_offset, scroll_offset + ITEM_H + ITEM_GAP)
	elif direction == "down":
		scroll_offset = max(0.0, scroll_offset - ITEM_H - ITEM_GAP)


func _get_max_scroll_offset() -> float:
	var list_bottom_y: float = DESIGN_H - 20
	var content_h: float = shop_list.size() * (ITEM_H + ITEM_GAP) - ITEM_GAP
	return maxf(0.0, content_h - (list_bottom_y - LIST_Y))


func _in_rect(x: float, y: float, rect: Rect2) -> bool:
	return x >= rect.position.x and x <= rect.position.x + rect.size.x and y >= rect.position.y and y <= rect.position.y + rect.size.y


func _go_main() -> void:
	if game and game.get("scene_manager") and game.scene_manager.has_method("switch_scene"):
		game.scene_manager.switch_scene("main", {}, "slide")
	elif has_node("/root/SceneManager"):
		get_node("/root/SceneManager").switch_scene("main", {}, "slide")


func _show_purchase_popup(item: Dictionary) -> void:
	var pw: float = 300
	var ph: float = 200
	var px: float = (DESIGN_W - pw) / 2
	var py: float = (DESIGN_H - ph) / 2
	popup = {
		"x": px, "y": py, "w": pw, "h": ph,
		"id": item.id,
		"data": item.data,
		"price": item.price,
		"currency": item.currency
	}


func _confirm_purchase(item_id: String) -> void:
	var items_db: Dictionary = {}
	if ResourceLoader.exists("res://src/data/item_db.gd"):
		var item_db_res = load("res://src/data/item_db.gd")
		if item_db_res:
			var instance = item_db_res.new()
			if instance.has("ITEMS_DB"):
				items_db = instance.ITEMS_DB
			instance.free()

	if not items_db.has(item_id):
		return

	var item_data: Dictionary = items_db[item_id]
	var player: Dictionary = _load_player_data()
	var price: float = _get_item_price(item_id)
	var currency: String = _get_item_currency(item_id)

	if currency == "gold":
		if (player.get("gold", 0) as float) < price:
			_show_toast("💰 金币不足", "warning")
			return
		player["gold"] = (player.get("gold", 0) as float) - price
	elif currency == "gems":
		if (player.get("gems", 0) as float) < price:
			_show_toast("💎 钻石不足", "warning")
			return
		player["gems"] = (player.get("gems", 0) as float) - price

	_save_player_data(player)
	player_data["gold"] = player.get("gold", 0)
	player_data["gems"] = player.get("gems", 0)

	_add_item(item_id, 1)
	_show_toast("✅ 获得 " + str(item_data.get("name", "")) + "！", "success")
	print("[Shop] 购买成功: " + str(item_data.get("name", "")))


func _load_player_data() -> Dictionary:
	var storage = preload("res://src/core/save_manager.gd").new()
	var data: Dictionary = storage.load_player()
	storage.free()
	return data


func _save_player_data(player: Dictionary) -> void:
	var storage = preload("res://src/core/save_manager.gd").new()
	storage.save_player(player)
	storage.free()


func _add_item(item_id: String, count: int) -> void:
	# 通过 storage 系统添加道具
	var storage = preload("res://src/core/save_manager.gd").new()
	storage.add_item(item_id, count)
	storage.free()


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


func _can_afford(item_id: String) -> bool:
	var price: float = _get_item_price(item_id)
	var currency: String = _get_item_currency(item_id)
	if currency == "gold":
		return (player_data.get("gold", 0) as float) >= price
	else:
		return (player_data.get("gems", 0) as float) >= price


func _show_toast(msg: String, kind: String = "info") -> void:
	if has_node("../ToastManager") or has_node("%ToastManager"):
		var tm = get_node("%ToastManager") if has_node("%ToastManager") else get_node("../ToastManager")
		if tm.has_method("show_toast"):
			tm.show_toast(msg, kind)


func _draw() -> void:
	# 背景
	_draw_rect(Rect2(0, 0, size.x, size.y), Color("#1a1a2e"))

	# 顶部标题栏
	var theme = _get_theme()
	_draw_rect(Rect2(0, 0, size.x, 60), theme.bg_card)

	# 返回按钮
	_draw_rect(BACK_BTN, theme.buttons.secondary.bg_color)
	_draw_text("← 返回", Vector2(BACK_BTN.position.x + 10, BACK_BTN.position.y + 23), theme.text_primary, theme.font.body.size)

	# 标题
	_draw_text("商店", Vector2(size.x / 2, 35), theme.text_primary, theme.font.subtitle.size, theme.font.subtitle.weight)

	# 货币显示
	var gold: float = player_data.get("gold", 0)
	var gems: float = player_data.get("gems", 0)
	_draw_text("💰 " + str(gold), Vector2(80, CURRENCY_Y), theme.gold, theme.font.subtitle.size, theme.font.subtitle.weight)
	_draw_text("💎 " + str(gems), Vector2(295, CURRENCY_Y), theme.primary, theme.font.subtitle.size, theme.font.subtitle.weight)

	# 分隔线
	_draw_rect(Rect2(10, CURRENCY_Y + 25, 355, 1), theme.text_muted)

	# 商品列表标题
	_draw_text("商品列表", Vector2(20, LIST_Y - 10), theme.text_muted, theme.font.small.size)

	# 绘制商品
	var list_bottom_y: float = DESIGN_H - 20
	for i in range(shop_list.size()):
		var shop_item: Dictionary = shop_list[i]
		var item_y: float = LIST_Y + i * (ITEM_H + ITEM_GAP) - scroll_offset
		if item_y < LIST_Y or item_y + ITEM_H > list_bottom_y:
			continue
		var item: Dictionary = shop_item.data

		# 商品卡片背景
		_draw_rect(Rect2(10, item_y, 355, ITEM_H), theme.bg_card)

		# 道具图标
		_draw_text(item.get("emoji", "📦"), Vector2(30, item_y + ITEM_H / 2 + 8), theme.text_primary, 32)

		# 道具名称
		_draw_text(item.get("name", ""), Vector2(75, item_y + 22), theme.text_primary, theme.font.body.size, theme.font.body.weight)

		# 道具描述
		_draw_text(item.get("desc", ""), Vector2(75, item_y + 42), theme.text_muted, theme.font.small.size)

		# 价格标签
		var price_color: Color = theme.gold if shop_item.currency == "gold" else theme.primary
		var price_symbol: String = "💰" if shop_item.currency == "gold" else "💎"
		_draw_text(price_symbol + " " + str(shop_item.price), Vector2(75, item_y + 60), price_color, theme.font.small.size, theme.font.small.weight)

		# 购买按钮
		var btn_y: float = item_y + (ITEM_H - BTN_H) / 2
		var can_afford: bool = _can_afford(shop_item.id)
		if can_afford:
			_draw_rect(Rect2(BTN_X, btn_y, BTN_W, BTN_H), theme.buttons.primary.bg_color)
			_draw_text("购买", Vector2(BTN_X + 40, btn_y + 25), theme.buttons.primary.text_color, theme.buttons.primary.font_size, theme.buttons.primary.font_weight)
		else:
			_draw_rect(Rect2(BTN_X, btn_y, BTN_W, BTN_H), theme.text_dark)
			var btn_label = "金币不足" if shop_item.currency == "gold" else "钻石不足"
			_draw_text(btn_label, Vector2(BTN_X + 40, btn_y + 25), theme.text_muted, theme.font.small.size)

	# 滚动条
	var max_offset: float = _get_max_scroll_offset()
	if max_offset > 0:
		var track_y: float = LIST_Y
		var track_h: float = DESIGN_H - LIST_Y - 20
		var thumb_h: float = maxf(36, track_h * (track_h / (track_h + max_offset)))
		var thumb_y: float = track_y + (track_h - thumb_h) * (scroll_offset / max_offset)
		_draw_rect(Rect2(368, track_y, 3, track_h), Color(1, 1, 1, 0.12))
		_draw_rect(Rect2(367, thumb_y, 5, thumb_h), Color(1, 1, 1, 0.45))

	# 购买确认弹窗
	if popup.size() > 0:
		var p: Dictionary = popup
		# 遮罩
		_draw_rect(Rect2(0, 0, size.x, size.y), Color(0, 0, 0, 0.7))
		# 弹窗背景
		_draw_rect(Rect2(p.x, p.y, p.w, p.h), theme.bg_card)
		# 顶部装饰条
		_draw_rect(Rect2(p.x + 20, p.y + 10, p.w - 40, 3), theme.buttons.primary.bg_color)
		# 标题
		_draw_text("确认购买", Vector2(p.x + p.w / 2, p.y + 40), theme.text_primary, theme.font.subtitle.size, theme.font.subtitle.weight)
		# 道具图标
		_draw_text(p.data.get("emoji", "📦"), Vector2(p.x + p.w / 2, p.y + 80), theme.text_primary, 36)
		_draw_text(p.data.get("name", ""), Vector2(p.x + p.w / 2, p.y + 115), theme.text_primary, theme.font.body.size, theme.font.body.weight)
		# 价格
		var price_color: Color = theme.primary if p.currency == "gems" else theme.gold
		var price_symbol: String = "💎" if p.currency == "gems" else "💰"
		_draw_text(price_symbol + " " + str(p.price), Vector2(p.x + p.w / 2, p.y + 140), price_color, theme.font.body.size, theme.font.body.weight)
		# 确认按钮
		_draw_rect(Rect2(p.x + 20, p.y + p.h - 55, 110, 40), theme.buttons.primary.bg_color)
		_draw_text("确认购买", Vector2(p.x + 75, p.y + p.h - 28), theme.buttons.primary.text_color, theme.buttons.primary.font_size, theme.buttons.primary.font_weight)
		# 取消按钮
		_draw_rect(Rect2(p.x + 150, p.y + p.h - 55, 110, 40), theme.text_dark)
		_draw_text("取消", Vector2(p.x + 205, p.y + p.h - 28), theme.text_secondary, theme.font.body.size)


func _draw_rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, true)


func _draw_text(text: String, pos: Vector2, color: Color, size: float = 16, weight: int = 0) -> void:
	var font_normal = ThemeDB.fallback_font
	var fnt_size = int(size * 2)  # 缩放因子补偿
	var f = ThemeDB.fallback_font
	if weight >= 700:
		f = ThemeDB.fallback_font  # fallback 暂不支持粗体
	var sp = LabelSettings.new()
	sp.font = f
	sp.font_size = fnt_size
	# 直接用 draw_string 抗锯齿
	var lines = text.split("\n", false)
	for idx in range(lines.size()):
		var line_text = lines[idx]
		var offset_y = pos.y + idx * (fnt_size + 4)
		draw_string(ThemeDB.fallback_font, Vector2(pos.x - 100, offset_y), line_text, HORIZONTAL_ALIGNMENT_CENTER, 200, fnt_size, color)


func _get_theme():
	# 加载 theme.gd 作为颜色/字体配置
	if ResourceLoader.exists("res://src/core/theme.gd"):
		var theme_res = load("res://src/core/theme.gd")
		if theme_res:
			var inst = theme_res.new()
			var result = inst.get_theme_data()
			inst.free()
			return result
	return _get_default_theme()


func _get_default_theme():
	return {
		"bg_medium": Color("#16213e"),
		"bg_card": Color("#1a1a2e"),
		"text_primary": Color("#e8e8e8"),
		"text_secondary": Color("#a0a0a0"),
		"text_muted": Color("#6b6b6b"),
		"text_dark": Color("#2d2d2d"),
		"primary": Color("#4a90d9"),
		"gold": Color("#f5c518"),
		"success": Color("#4caf50"),
		"danger": Color("#e53935"),
		"white": Color("#ffffff"),
		"font": {
			"title": {"size": 22, "weight": 700},
			"subtitle": {"size": 18, "weight": 600},
			"body": {"size": 14, "weight": 400},
			"small": {"size": 12, "weight": 400},
			"tiny": {"size": 10, "weight": 400}
		},
		"buttons": {
			"primary": {"bg_color": Color("#4a90d9"), "text_color": Color("#ffffff"), "font_size": 14, "font_weight": 600},
			"secondary": {"bg_color": Color("#2d2d44"), "text_color": Color("#e8e8e8"), "font_size": 14, "font_weight": 400},
			"danger": {"bg_color": Color("#e53935"), "text_color": Color("#ffffff"), "font_size": 14, "font_weight": 600}
		},
		"radius": {"sm": 4, "md": 8, "lg": 16}
	}


func _process(_delta: float) -> void:
	queue_redraw()

# scene_shop_gui.gd - 可在 Godot 编辑器中调整的商店界面
# 商品列表改为分页 GUI 卡片，购买弹窗也节点化。
class_name SceneShopGui
extends "res://src/ui/scene/scene_shop.gd"

const PAGE_SIZE := 9
const CARD_PATHS := [
	"ProductGrid/Cards/Card1",
	"ProductGrid/Cards/Card2",
	"ProductGrid/Cards/Card3",
	"ProductGrid/Cards/Card4",
	"ProductGrid/Cards/Card5",
	"ProductGrid/Cards/Card6",
	"ProductGrid/Cards/Card7",
	"ProductGrid/Cards/Card8",
	"ProductGrid/Cards/Card9",
]
const TAB_PATHS := ["Tabs/Recommend", "Tabs/Items", "Tabs/Gems"]

var _shop_page := 0
var _toast_timer := 0.0

func _ready() -> void:
	if _bg_texture:
		_bg_texture.visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_setup_toast_bubble()
	_connect_gui_actions()
	_sync_gui()

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_shop_page = int(data.get("page", 0))
	_clamp_shop_page()
	_sync_gui()

func _draw() -> void:
	pass

func _gui_input(_event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
	if _toast_timer <= 0.0:
		set_process(false)
		return
	_toast_timer -= delta
	if _toast_timer <= 0.0 and has_node("Toast"):
		_node("Toast").visible = false
		set_process(false)

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
	return result

func _connect_gui_actions() -> void:
	_connect_button("Header/BackButton", _go_main)
	for i in TAB_PATHS.size():
		_connect_button(TAB_PATHS[i], _on_tab_pressed.bind(str(TABS[i].get("id", "recommend"))))
	for i in CARD_PATHS.size():
		_connect_button(CARD_PATHS[i], _on_card_pressed.bind(i))
	_connect_button("ProductGrid/PageControls/PreviousButton", _on_previous_page_pressed)
	_connect_button("ProductGrid/PageControls/NextButton", _on_next_page_pressed)
	_connect_button("PopupOverlay/Panel/CloseButton", _on_popup_cancel_pressed)
	_connect_button("PopupOverlay/Panel/MinusButton", _on_popup_minus_pressed)
	_connect_button("PopupOverlay/Panel/PlusButton", _on_popup_plus_pressed)
	_connect_button("PopupOverlay/Panel/PlusTenButton", _on_popup_plus_ten_pressed)
	_connect_button("PopupOverlay/Panel/CancelButton", _on_popup_cancel_pressed)
	_connect_button("PopupOverlay/Panel/ConfirmButton", _on_popup_confirm_pressed)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _on_tab_pressed(tab_id: String) -> void:
	_active_tab = tab_id
	scroll_offset = 0.0
	_shop_page = 0
	selected_item = {}
	popup = {}
	_sync_gui()

func _on_card_pressed(visible_index: int) -> void:
	var index := _shop_page * PAGE_SIZE + visible_index
	var items := _get_visible_shop_items()
	if index < 0 or index >= items.size():
		return
	var shop_item: Dictionary = items[index]
	selected_item = shop_item
	_show_purchase_popup(shop_item)

func _on_previous_page_pressed() -> void:
	_shop_page = maxi(0, _shop_page - 1)
	_sync_gui()

func _on_next_page_pressed() -> void:
	_shop_page = mini(_max_shop_page(), _shop_page + 1)
	_sync_gui()

func _on_popup_minus_pressed() -> void:
	_popup_quantity = maxi(1, _popup_quantity - 1)
	_sync_popup()

func _on_popup_plus_pressed() -> void:
	_popup_quantity = mini(99, _popup_quantity + 1)
	_sync_popup()

func _on_popup_plus_ten_pressed() -> void:
	_popup_quantity = mini(99, _popup_quantity + 10)
	_sync_popup()

func _on_popup_cancel_pressed() -> void:
	popup = {}
	_sync_popup()

func _on_popup_confirm_pressed() -> void:
	if popup.is_empty():
		return
	_confirm_purchase(str(popup.get("id", "")), _popup_quantity)
	popup = {}
	_sync_gui()

func _show_purchase_popup(item: Dictionary) -> void:
	_popup_quantity = 1
	popup = {
		"id": item.get("id", ""),
		"data": item.get("data", {}),
		"price": item.get("price", 0),
		"currency": item.get("currency", "gold")
	}
	_sync_popup()

func _show_toast(msg: String, kind: String = "info") -> void:
	_setup_toast_bubble()
	_label("Toast/Text").text = msg
	var toast := _node("Toast")
	toast.visible = true
	toast.z_index = 80
	_apply_toast_style(kind)
	_toast_timer = 1.8
	set_process(true)

func _setup_toast_bubble() -> void:
	if not has_node("Toast"):
		return
	var toast := _node("Toast")
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := get_node_or_null("Toast/Frame")
	if frame is Panel:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.945, 0.745, 0.96)
		style.border_color = Color(0.17, 0.095, 0.025, 0.96)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
		style.shadow_size = 5
		style.shadow_offset = Vector2(2, 3)
		(frame as Panel).add_theme_stylebox_override("panel", style)
	if has_node("Toast/Text"):
		var text := _label("Toast/Text")
		text.add_theme_color_override("font_color", Color(0.16, 0.095, 0.025, 1.0))
		text.add_theme_color_override("font_shadow_color", Color(1.0, 0.96, 0.78, 0.62))
	if has_node("Toast/Tail"):
		(_node("Toast/Tail") as ColorRect).color = Color(1.0, 0.945, 0.745, 0.96)
	if has_node("Toast/TailShadow"):
		(_node("Toast/TailShadow") as ColorRect).color = Color(0.0, 0.0, 0.0, 0.32)

func _apply_toast_style(kind: String) -> void:
	var bubble_color := Color(1.0, 0.945, 0.745, 0.96)
	var text_color := Color(0.16, 0.095, 0.025, 1.0)
	if kind == "warning":
		bubble_color = Color(1.0, 0.82, 0.66, 0.97)
		text_color = Color(0.33, 0.09, 0.035, 1.0)
	var frame := get_node_or_null("Toast/Frame")
	if frame is Panel:
		var style := (frame as Panel).get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.bg_color = bubble_color
		(frame as Panel).add_theme_stylebox_override("panel", style)
	if has_node("Toast/Tail"):
		(_node("Toast/Tail") as ColorRect).color = bubble_color
	if has_node("Toast/Text"):
		_label("Toast/Text").add_theme_color_override("font_color", text_color)

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Header"):
		return
	_sync_header()
	_sync_tabs()
	if has_node("FeatureBanner"):
		_node("FeatureBanner").visible = false
	_sync_cards()
	_sync_page_controls()
	_sync_popup()

func _sync_header() -> void:
	_label("Header/Title").text = "商店"
	_label("Header/GoldChip/Amount").text = _format_number(int(player_data.get("gold", 0)))
	_label("Header/DiamondChip/Amount").text = _format_number(int(player_data.get("gems", 0)))

func _sync_tabs() -> void:
	for i in TAB_PATHS.size():
		var tab := get_node(TAB_PATHS[i]) as TextureButton
		var active: bool = str(TABS[i].get("id", "")) == _active_tab
		(tab.get_node("Frame") as TextureRect).texture = _tex("tab_active" if active else "tab_inactive")
		(tab.get_node("Text") as Label).text = str(TABS[i].get("label", ""))
		tab.modulate.a = 1.0 if active else 0.78

func _sync_feature() -> void:
	_label("FeatureBanner/Title").text = "新手超值礼包"
	_label("FeatureBanner/Desc").text = "限时特惠，助力冒险"

func _sync_cards() -> void:
	var items := _get_visible_shop_items()
	var start := _shop_page * PAGE_SIZE
	for i in CARD_PATHS.size():
		var card := get_node(CARD_PATHS[i]) as TextureButton
		var index := start + i
		card.visible = index < items.size()
		if not card.visible:
			continue
		_sync_card(card, items[index])

func _sync_card(card: TextureButton, shop_item: Dictionary) -> void:
	var item: Dictionary = shop_item.get("data", {})
	var item_id := str(shop_item.get("id", ""))
	var currency_key := "diamond" if str(shop_item.get("currency", "gold")) == "gems" else "gold"
	var can_afford := _can_afford(item_id)
	(card.get_node("Icon") as TextureRect).texture = _get_item_texture(item_id)
	(card.get_node("Name") as Label).text = str(item.get("name", ""))
	(card.get_node("Limit") as Label).text = _get_limit_text(shop_item)
	(card.get_node("Price/Icon") as TextureRect).texture = _tex(currency_key)
	(card.get_node("Price/Text") as Label).text = str(shop_item.get("price", 0))
	card.disabled = false
	card.modulate.a = 1.0 if can_afford else 0.74
	if card.has_node("BuyButton"):
		(card.get_node("BuyButton") as Control).visible = false

func _sync_page_controls() -> void:
	_clamp_shop_page()
	var max_page := _max_shop_page()
	_label("ProductGrid/PageControls/PageLabel").text = "%d/%d" % [_shop_page + 1, max_page + 1]
	var prev := get_node("ProductGrid/PageControls/PreviousButton") as TextureButton
	var next := get_node("ProductGrid/PageControls/NextButton") as TextureButton
	prev.disabled = _shop_page <= 0
	next.disabled = _shop_page >= max_page
	prev.modulate.a = 0.45 if prev.disabled else 1.0
	next.modulate.a = 0.45 if next.disabled else 1.0

func _sync_popup() -> void:
	var overlay := _node("PopupOverlay")
	overlay.visible = not popup.is_empty()
	if not overlay.visible:
		return
	var data: Dictionary = popup.get("data", {})
	var item_id := str(popup.get("id", ""))
	var currency_key := "diamond" if str(popup.get("currency", "gold")) == "gems" else "gold"
	var total := int(popup.get("price", 0)) * _popup_quantity
	var can_afford := _can_afford(item_id, _popup_quantity)
	(get_node("PopupOverlay/Panel/Icon") as TextureRect).texture = _get_item_texture(item_id)
	_label("PopupOverlay/Panel/Name").text = str(data.get("name", ""))
	_label("PopupOverlay/Panel/Owned").text = "拥有: %d" % _get_item_count(item_id)
	_label("PopupOverlay/Panel/Quantity").text = str(_popup_quantity)
	(get_node("PopupOverlay/Panel/TotalPrice/Icon") as TextureRect).texture = _tex(currency_key)
	_label("PopupOverlay/Panel/TotalPrice/Text").text = str(total)
	var confirm := get_node("PopupOverlay/Panel/ConfirmButton") as TextureButton
	confirm.disabled = not can_afford
	confirm.modulate.a = 1.0 if can_afford else 0.62

func _max_shop_page() -> int:
	return maxi(0, ceili(float(_get_visible_shop_items().size()) / float(PAGE_SIZE)) - 1)

func _clamp_shop_page() -> void:
	_shop_page = clampi(_shop_page, 0, _max_shop_page())

func _node(path: NodePath) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

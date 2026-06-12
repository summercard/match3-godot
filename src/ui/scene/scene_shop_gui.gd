# scene_shop_gui.gd - 可在 Godot 编辑器中调整的商店界面
# 商品列表改为分页 GUI 卡片，购买弹窗也节点化。
class_name SceneShopGui
extends "res://src/ui/controllers/shop_logic.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const TAB_ACTIVE_TEXTURE := preload("res://assets/images/ui/buttons/shop_ui_shop_tab_active_image2_clean.png")
const TAB_NORMAL_TEXTURE := preload("res://assets/images/ui/buttons/shop_ui_shop_tab_normal_image2_clean.png")
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
const TAB_PATHS := ["Tabs/Gems", "Tabs/Coins", "Tabs/Hearts", "Tabs/Boosters", "Tabs/Chest"]

var _shop_page := 0
var _toast_timer := 0.0
var _toast_tween: Tween = null

func _ready() -> void:
	if _bg_texture:
		_bg_texture.visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_setup_toast_bubble()
	_connect_gui_actions()
	_attach_shop_feedback()
	_sync_gui()
	call_deferred("_play_enter_animation")

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
		var item_id := str(entry.get("id", ""))
		if _active_tab == "gems":
			result.append(entry)
			continue
		if _active_tab == "coins" and item_type != "gold":
			continue
		if _active_tab == "hearts" and not item.get("effect", {}).has("healRatio"):
			continue
		if _active_tab == "boosters" and not (item_type in ["capture", "exp", "battle"]):
			continue
		if _active_tab == "chest" and item_type != "evolution":
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
	_connect_button("BottomNav/HomeButton", _go_main)

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
	_play_tab_switch_motion()

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
	_play_popup_motion()

func _show_toast(msg: String, kind: String = "info") -> void:
	_setup_toast_bubble()
	_label("Toast/Text").text = msg
	var toast := _node("Toast")
	toast.visible = true
	toast.z_index = 80
	toast.scale = Vector2(0.92, 0.92)
	_apply_toast_style(kind)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast, "scale", Vector2(1.08, 1.08), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_property(toast, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
	_sync_static_labels()
	_sync_header()
	_sync_tabs()
	if has_node("FeatureBanner"):
		_node("FeatureBanner").visible = false
	_sync_cards()
	_sync_page_controls()
	_sync_popup()

func _sync_static_labels() -> void:
	var labels := {
		"BottomNav/HomeButton/Text": "主页",
		"PopupOverlay/Panel/Title": "购买确认",
		"PopupOverlay/Panel/CloseButton/Text": "×",
		"PopupOverlay/Panel/CancelButton/Text": "取消",
		"PopupOverlay/Panel/ConfirmButton/Text": "确认购买",
	}
	for path in labels.keys():
		if has_node(path):
			_label(path).text = str(labels[path])

func _sync_header() -> void:
	if has_node("Header/Title"):
		_label("Header/Title").text = "商店"
	if has_node("TitlePlaque/Title"):
		_label("TitlePlaque/Title").text = "商店"
	_label("Header/GoldChip/Amount").text = _format_number(int(player_data.get("gold", 0)))
	_label("Header/DiamondChip/Amount").text = _format_number(int(player_data.get("gems", 0)))
	if has_node("Header/EnergyChip/Amount"):
		_label("Header/EnergyChip/Amount").text = "5 Full"

func _sync_tabs() -> void:
	for i in TAB_PATHS.size():
		var tab := get_node(TAB_PATHS[i]) as TextureButton
		var active: bool = str(TABS[i].get("id", "")) == _active_tab
		var frame := tab.get_node("Frame") as TextureRect
		frame.texture = TAB_ACTIVE_TEXTURE if active else TAB_NORMAL_TEXTURE
		(tab.get_node("Text") as Label).text = str(TABS[i].get("label", ""))
		tab.modulate.a = 1.0
		var text := tab.get_node("Text") as Label
		text.add_theme_color_override("font_color", Color.WHITE if active else Color(0.43, 0.24, 0.07))
		text.add_theme_color_override("font_shadow_color", Color(0.42, 0.10, 0.13, 0.72) if active else Color(1.0, 0.95, 0.78, 0.72))

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
	if card.has_node("BestRibbon"):
		(card.get_node("BestRibbon") as Control).visible = item_id in ["gold_chest", "capture_ball_elite", "focus_crystal", "evolution_stone_light", "evolution_stone_dark"]
		if card.has_node("BestRibbon/Text"):
			(card.get_node("BestRibbon/Text") as Label).text = "超值"
	card.disabled = false
	card.modulate.a = 1.0
	if card.has_node("Price"):
		(card.get_node("Price") as Control).modulate.a = 1.0
	if card.has_node("BuyButton"):
		(card.get_node("BuyButton") as Control).visible = true

func _sync_page_controls() -> void:
	_clamp_shop_page()
	var max_page := _max_shop_page()
	_label("ProductGrid/PageControls/PageLabel").text = "%d / %d" % [_shop_page + 1, max_page + 1]
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

func _attach_shop_feedback() -> void:
	var primary_paths := {
		"PopupOverlay/Panel/ConfirmButton": true,
	}
	var entry_paths := {}
	for path in CARD_PATHS:
		entry_paths[path] = true
	var feedback_paths := [
		"Tabs/Gems",
		"Tabs/Coins",
		"Tabs/Hearts",
		"Tabs/Boosters",
		"Tabs/Chest",
		"ProductGrid/PageControls/PreviousButton",
		"ProductGrid/PageControls/NextButton",
		"PopupOverlay/Panel/CloseButton",
		"PopupOverlay/Panel/MinusButton",
		"PopupOverlay/Panel/PlusButton",
		"PopupOverlay/Panel/PlusTenButton",
		"PopupOverlay/Panel/CancelButton",
		"PopupOverlay/Panel/ConfirmButton",
		"BottomNav/HomeButton",
	]
	for path in CARD_PATHS:
		feedback_paths.append(path)
	for path in feedback_paths:
		var button := get_node_or_null(path) as BaseButton
		if button == null or button.has_node("CartoonFeedback"):
			continue
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		var profile := CartoonButtonFeedback.Profile.NAV
		if primary_paths.has(path):
			profile = CartoonButtonFeedback.Profile.PRIMARY
		elif entry_paths.has(path):
			profile = CartoonButtonFeedback.Profile.ENTRY
		feedback.setup(button, profile)

func _play_enter_animation() -> void:
	if not is_inside_tree():
		return
	# 1) TitlePlaque：原有的弹跳 pop
	if has_node("TitlePlaque"):
		var title := _node("TitlePlaque")
		title.pivot_offset = title.size * 0.5
		title.scale = Vector2(0.94, 0.94)
		var title_tween := create_tween()
		title_tween.tween_property(title, "scale", Vector2(1.04, 1.04), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		title_tween.tween_property(title, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 2) Header 三个货币 chip：依次淡入 + 下滑
	var chip_paths := ["Header/GoldChip", "Header/DiamondChip", "Header/EnergyChip"]
	for i in chip_paths.size():
		var chip := get_node_or_null(chip_paths[i]) as Control
		if chip == null or not chip.visible:
			continue
		var orig_y := chip.position.y
		chip.position.y = orig_y - 10.0
		chip.modulate.a = 0.0
		chip.pivot_offset = chip.size * 0.5
		var chip_tween := create_tween()
		chip_tween.tween_interval(0.04 + 0.05 * float(i))
		chip_tween.tween_property(chip, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		chip_tween.parallel().tween_property(chip, "position:y", orig_y, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 3) Tabs 5 个标签：依次 scale pop（保持原 modulate.a 不动，避免破坏 _sync_tabs 的视觉）
	for i in TAB_PATHS.size():
		var tab := get_node_or_null(TAB_PATHS[i]) as Control
		if tab == null or not tab.visible:
			continue
		tab.pivot_offset = tab.size * 0.5
		tab.scale = Vector2(0.82, 0.82)
		var tab_tween := create_tween()
		tab_tween.tween_interval(0.10 + 0.04 * float(i))
		tab_tween.tween_property(tab, "scale", Vector2(1.08, 1.08), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tab_tween.tween_property(tab, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 4) ProductGrid 卡片：保留原始 stagger
	for i in CARD_PATHS.size():
		var card := get_node_or_null(CARD_PATHS[i]) as Control
		if card == null or not card.visible:
			continue
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.96, 0.96)
		var tween := create_tween()
		tween.tween_interval(0.015 * float(i))
		tween.tween_property(card, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 5) PageControls：左右翻页按钮一起 scale pop
	var page_ctrl := get_node_or_null("ProductGrid/PageControls") as Control
	if page_ctrl != null and page_ctrl.visible:
		page_ctrl.pivot_offset = page_ctrl.size * 0.5
		page_ctrl.scale = Vector2(0.88, 0.88)
		page_ctrl.modulate.a = 0.0
		var pc_tween := create_tween()
		pc_tween.tween_interval(0.26)
		pc_tween.tween_property(page_ctrl, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pc_tween.parallel().tween_property(page_ctrl, "scale", Vector2(1.05, 1.05), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pc_tween.tween_property(page_ctrl, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 6) BottomNav HomeButton：上滑 + 淡入
	var home_btn := get_node_or_null("BottomNav/HomeButton") as Control
	if home_btn != null and home_btn.visible:
		var orig_home_y := home_btn.position.y
		home_btn.position.y = orig_home_y + 10.0
		home_btn.modulate.a = 0.0
		home_btn.pivot_offset = home_btn.size * 0.5
		var home_tween := create_tween()
		home_tween.tween_interval(0.30)
		home_tween.tween_property(home_btn, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		home_tween.parallel().tween_property(home_btn, "position:y", orig_home_y, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_tab_switch_motion() -> void:
	for i in CARD_PATHS.size():
		var card := get_node_or_null(CARD_PATHS[i]) as Control
		if card == null or not card.visible:
			continue
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.98, 0.98)
		var tween := create_tween()
		tween.tween_interval(0.01 * float(i))
		tween.tween_property(card, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_popup_motion() -> void:
	var panel := get_node_or_null("PopupOverlay/Panel") as Control
	if panel == null or popup.is_empty():
		return
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2(1.03, 1.03), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _max_shop_page() -> int:
	return maxi(0, ceili(float(_get_visible_shop_items().size()) / float(PAGE_SIZE)) - 1)

func _clamp_shop_page() -> void:
	_shop_page = clampi(_shop_page, 0, _max_shop_page())

func _node(path: NodePath) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

func _go_to_scene(scene_name: String) -> void:
	if game and game.get("scene_manager") and game.scene_manager.has_method("switch_scene"):
		game.scene_manager.switch_scene(scene_name, {}, "slide")
	elif has_node("/root/SceneManager"):
		get_node("/root/SceneManager").switch_scene(scene_name, {}, "slide")

func _make_tab_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.32, 0.52, 1.0) if active else Color(1.0, 0.94, 0.78, 0.98)
	style.border_color = Color(1.0, 0.72, 0.28, 1.0) if active else Color(0.91, 0.58, 0.20, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.shadow_color = Color(0.36, 0.16, 0.03, 0.22)
	style.shadow_size = 3
	return style

# scene_inventory_gui.gd - 可在 Godot 编辑器中调整的背包界面
# 物品区改为固定分页，不再依赖拖拽滚动。
class_name SceneInventoryGui
extends "res://src/ui/scene/scene_inventory.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const PAGE_SIZE := 15
const SLOT_PATHS := [
	"GridPanel/Slots/Slot1",
	"GridPanel/Slots/Slot2",
	"GridPanel/Slots/Slot3",
	"GridPanel/Slots/Slot4",
	"GridPanel/Slots/Slot5",
	"GridPanel/Slots/Slot6",
	"GridPanel/Slots/Slot7",
	"GridPanel/Slots/Slot8",
	"GridPanel/Slots/Slot9",
	"GridPanel/Slots/Slot10",
	"GridPanel/Slots/Slot11",
	"GridPanel/Slots/Slot12",
	"GridPanel/Slots/Slot13",
	"GridPanel/Slots/Slot14",
	"GridPanel/Slots/Slot15",
]
const TAB_PATHS := [
	"Tabs/All",
	"Tabs/Items",
	"Tabs/Materials",
	"Tabs/Gems",
]

var _inventory_page := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_connect_gui_actions()
	_attach_inventory_feedback()
	_sync_gui()
	call_deferred("_play_enter_animation")

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_inventory_page = int(data.get("page", 0))
	_clamp_inventory_page()
	_sync_gui()

func _draw() -> void:
	pass

func _gui_input(_event: InputEvent) -> void:
	pass

func _process(dt: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= dt
		if _toast_timer <= 0.0:
			_toast_text = ""
			set_process(false)
		_sync_toast()

func _connect_gui_actions() -> void:
	_connect_button("Header/BackButton", _on_back_pressed)
	for i in TAB_PATHS.size():
		_connect_button(TAB_PATHS[i], _on_tab_pressed.bind(str(TABS[i].get("id", "all"))))
	for i in SLOT_PATHS.size():
		_connect_button(SLOT_PATHS[i], _on_slot_pressed.bind(i))
	_connect_button("GridPanel/PageControls/PreviousButton", _on_previous_page_pressed)
	_connect_button("GridPanel/PageControls/NextButton", _on_next_page_pressed)
	_connect_button("DetailPanel/UseButton", _on_use_pressed)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _on_back_pressed() -> void:
	back_pressed.emit()

func _on_tab_pressed(tab_id: String) -> void:
	_active_tab = tab_id
	_scroll_offset = 0.0
	_inventory_page = 0
	_selected_item = {}
	_build_item_list()
	_sync_gui()

func _on_slot_pressed(visible_index: int) -> void:
	var index := _inventory_page * PAGE_SIZE + visible_index
	if index < 0 or index >= _item_list.size():
		return
	_selected_item = _item_list[index]
	_sync_gui()

func _on_previous_page_pressed() -> void:
	_inventory_page = maxi(0, _inventory_page - 1)
	_sync_gui()

func _on_next_page_pressed() -> void:
	_inventory_page = mini(_max_inventory_page(), _inventory_page + 1)
	_sync_gui()

func _on_use_pressed() -> void:
	if _selected_item.is_empty():
		return
	_use_item(str(_selected_item.get("id", "")))
	_clamp_inventory_page()
	_sync_gui()

func _use_item(item_id: String) -> void:
	super._use_item(item_id)
	_clamp_inventory_page()
	_sync_gui()

func _show_toast(text: String) -> void:
	_toast_text = text
	_toast_timer = 1.8
	set_process(true)
	_sync_toast()

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Header"):
		return
	_sync_static_labels()
	_sync_header()
	_sync_tabs()
	_sync_grid()
	_sync_page_controls()
	_sync_detail()
	_sync_toast()

func _sync_static_labels() -> void:
	for i in TAB_PATHS.size():
		if has_node("%s/Text" % TAB_PATHS[i]):
			_label("%s/Text" % TAB_PATHS[i]).text = str(TABS[i].get("label", ""))
	var labels := {
		"GridPanel/EmptyTitle": "还没有道具",
		"GridPanel/EmptyHint": "去战斗或商店获取吧",
		"DetailPanel/EmptyText": "选择一个道具查看详情",
		"DetailPanel/UseButton/Text": "使用",
	}
	for path in labels.keys():
		if has_node(path):
			_label(path).text = str(labels[path])

func _sync_header() -> void:
	_label("Header/Title").text = "背包"
	_label("Header/GoldChip/Amount").text = _format_number(int(_player.get("gold", 0)))
	_label("Header/DiamondChip/Amount").text = _format_number(int(_player.get("gems", 0)))

func _sync_tabs() -> void:
	for i in TAB_PATHS.size():
		var tab := get_node(TAB_PATHS[i]) as TextureButton
		var active: bool = str(TABS[i].get("id", "")) == _active_tab
		(tab.get_node("Frame") as TextureRect).texture = _tex("tab_active" if active else "tab_inactive")
		(tab.get_node("Text") as Label).text = str(TABS[i].get("label", ""))
		tab.modulate.a = 1.0
		var text := tab.get_node("Text") as Label
		text.add_theme_color_override("font_color", Color.WHITE if active else Color(0.43, 0.24, 0.07))
		text.add_theme_color_override("font_shadow_color", Color(0.44, 0.12, 0.14, 0.65) if active else Color(1.0, 0.95, 0.78, 0.72))

func _sync_grid() -> void:
	_label("GridPanel/EmptyTitle").visible = _item_list.is_empty()
	_label("GridPanel/EmptyHint").visible = _item_list.is_empty()
	var start := _inventory_page * PAGE_SIZE
	for i in SLOT_PATHS.size():
		var slot := get_node(SLOT_PATHS[i]) as TextureButton
		var index := start + i
		if index < _item_list.size():
			_sync_item_slot(slot, _item_list[index])
		else:
			_sync_empty_slot(slot)

func _sync_item_slot(slot: TextureButton, item: Dictionary) -> void:
	slot.disabled = false
	slot.modulate.a = 1.0
	var selected: bool = not _selected_item.is_empty() and str(item.get("id", "")) == str(_selected_item.get("id", ""))
	(slot.get_node("Frame") as TextureRect).texture = _tex("slot_selected" if selected else "slot")
	(slot.get_node("Icon") as TextureRect).texture = _get_item_texture(str(item.get("id", "")))
	(slot.get_node("Count") as Label).text = str(item.get("count", 0))
	(slot.get_node("Name") as Label).text = ""
	(slot.get_node("Lock") as TextureRect).visible = false
	(slot.get_node("Count") as Label).visible = true
	(slot.get_node("Name") as Label).visible = false

func _sync_empty_slot(slot: TextureButton) -> void:
	slot.disabled = true
	slot.modulate.a = 0.72
	(slot.get_node("Frame") as TextureRect).texture = _tex("slot_locked")
	(slot.get_node("Icon") as TextureRect).texture = null
	(slot.get_node("Count") as Label).text = ""
	(slot.get_node("Name") as Label).text = ""
	(slot.get_node("Lock") as TextureRect).visible = false
	(slot.get_node("Count") as Label).visible = false
	(slot.get_node("Name") as Label).visible = false

func _sync_page_controls() -> void:
	_clamp_inventory_page()
	var max_page := _max_inventory_page()
	_label("GridPanel/PageControls/PageLabel").text = "%d/%d" % [_inventory_page + 1, max_page + 1]
	var prev := get_node("GridPanel/PageControls/PreviousButton") as TextureButton
	var next := get_node("GridPanel/PageControls/NextButton") as TextureButton
	prev.disabled = _inventory_page <= 0
	next.disabled = _inventory_page >= max_page
	prev.modulate.a = 0.45 if prev.disabled else 1.0
	next.modulate.a = 0.45 if next.disabled else 1.0

func _sync_detail() -> void:
	var empty := _selected_item.is_empty()
	_label("DetailPanel/EmptyText").visible = empty
	_node("DetailPanel/Content").visible = not empty
	if empty:
		(get_node("DetailPanel/UseButton") as TextureButton).disabled = true
		(get_node("DetailPanel/UseButton") as TextureButton).modulate.a = 0.55
		return
	var item_data: Dictionary = _selected_item.get("data", {})
	var item_id := str(_selected_item.get("id", ""))
	var item_type := str(item_data.get("type", ""))
	var equipped := item_type == "capture" and str(_capture_settings.get("equippedItem", "")) == item_id
	(get_node("DetailPanel/Content/IconFrame/Icon") as TextureRect).texture = _get_item_texture(item_id)
	_label("DetailPanel/Content/IconFrame/Rarity").text = _rarity_label(int(item_data.get("rarity", 1)))
	_label("DetailPanel/Content/Name").text = str(item_data.get("name", ""))
	_label("DetailPanel/Content/Desc").text = _wrap_text(str(item_data.get("desc", "")), 15)
	_label("DetailPanel/Content/Count").text = "拥有: %d" % int(_selected_item.get("count", 0))
	_label("DetailPanel/Content/Type").text = _type_label(item_type)
	_label("DetailPanel/Content/EquipState").text = "捕捉球: %s" % ("已装备" if equipped else "未装备") if item_type == "capture" else ""
	var use_button := get_node("DetailPanel/UseButton") as TextureButton
	use_button.disabled = false
	use_button.modulate.a = 1.0
	_label("DetailPanel/UseButton/Text").text = "装备" if item_type == "capture" and not equipped else ("已装备" if item_type == "capture" else "使用")

func _sync_toast() -> void:
	var toast := _node("Toast")
	toast.visible = _toast_text != "" and _toast_timer > 0.0
	if not toast.visible:
		return
	toast.modulate.a = minf(_toast_timer / 0.5, 1.0)
	_label("Toast/Text").text = _toast_text

func _type_label(item_type: String) -> String:
	match item_type:
		"capture":
			return "捕捉道具"
		"exp":
			return "经验道具"
		"gold":
			return "金币材料"
		"battle":
			return "战斗道具"
		"evolution":
			return "进化材料"
		_:
			return "道具"

func _short_item_name(text: String) -> String:
	if text.length() <= 5:
		return text
	return text.substr(0, 5)

func _attach_inventory_feedback() -> void:
	var paths := [
		"Header/BackButton",
		"Tabs/All",
		"Tabs/Items",
		"Tabs/Materials",
		"Tabs/Gems",
		"GridPanel/PageControls/PreviousButton",
		"GridPanel/PageControls/NextButton",
		"DetailPanel/UseButton",
	]
	for path in SLOT_PATHS:
		paths.append(path)
	for path in paths:
		var button := get_node_or_null(path) as BaseButton
		if button == null or button.has_node("CartoonFeedback"):
			continue
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		var profile := CartoonButtonFeedback.Profile.NAV
		if path == "DetailPanel/UseButton":
			profile = CartoonButtonFeedback.Profile.PRIMARY
		elif path in SLOT_PATHS:
			profile = CartoonButtonFeedback.Profile.ENTRY
		elif path == "Header/BackButton":
			profile = CartoonButtonFeedback.Profile.ICON
		feedback.setup(button, profile)

func _play_enter_animation() -> void:
	for path in ["Header", "Tabs", "GridPanel", "DetailPanel"]:
		var node := get_node_or_null(path) as Control
		if node == null:
			continue
		node.pivot_offset = node.size * 0.5
		node.scale = Vector2(0.97, 0.97)
		var tween := create_tween()
		tween.tween_property(node, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _max_inventory_page() -> int:
	return maxi(0, ceili(float(_item_list.size()) / float(PAGE_SIZE)) - 1)

func _clamp_inventory_page() -> void:
	_inventory_page = clampi(_inventory_page, 0, _max_inventory_page())

func _node(path: NodePath) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

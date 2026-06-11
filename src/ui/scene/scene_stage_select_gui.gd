# scene_stage_select_gui.gd - 可在 Godot 编辑器中逐章调整的章节大地图界面
# 数据、解锁与扫荡规则沿用 SceneStageSelect；每个大章使用独立的 .tscn 地图文件。
class_name SceneStageSelectGui
extends "res://src/ui/controllers/stage_select_logic.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const AnimationHelperScript := preload("res://src/engine/animation_player.gd")

const CHAPTER_MAP_NODES := {
	"chapter_1": "MapScroll/ChapterMaps/Chapter01Grassland",
	"chapter_2": "MapScroll/ChapterMaps/Chapter02FireValley",
	"chapter_3": "MapScroll/ChapterMaps/Chapter03MysticForest",
	"chapter_4": "MapScroll/ChapterMaps/Chapter04EclipseCanopy",
	"chapter_5": "MapScroll/ChapterMaps/Chapter05ThunderTemple",
	"chapter_6": "MapScroll/ChapterMaps/Chapter06FrostThrone",
	"chapter_7": "MapScroll/ChapterMaps/Chapter07VoidDomain",
	"chapter_8": "MapScroll/ChapterMaps/Chapter08TemporalRift",
	"chapter_9": "MapScroll/ChapterMaps/Chapter09StarlitTemple",
	"chapter_10": "MapScroll/ChapterMaps/Chapter10ChaosDomain",
	"chapter_11": "MapScroll/ChapterMaps/Chapter11RadiantTemple",
}
const DOT_PATHS := [
	"Header/Dots/Dot1", "Header/Dots/Dot2", "Header/Dots/Dot3",
	"Header/Dots/Dot4", "Header/Dots/Dot5", "Header/Dots/Dot6",
	"Header/Dots/Dot7", "Header/Dots/Dot8", "Header/Dots/Dot9",
	"Header/Dots/Dot10", "Header/Dots/Dot11",
]
const TEXT_WHITE := Color(1.0, 1.0, 1.0)
const TEXT_MUTED := Color(0.66, 0.75, 0.88)
const MAP_SCROLL_DRAG_THRESHOLD: float = 8.0
const DEFAULT_STAR_LIT_PATH := "res://assets/images/ui/icons/stage_icon_star_lit.png"
const DEFAULT_STAR_DIM_PATH := "res://assets/images/ui/icons/stage_icon_star_lit.png"
const CHAPTER_01_STAR_PATH := "res://assets/images/ui/icons/stage_star_gold_new.png"

var _chapter_map: Control = null
var _chapter_map_id: String = ""
var _chapter_maps_content: Control = null
var _map_scroll: ScrollContainer = null
var _cloud_layer_far: Control = null
var _cloud_layer_near: Control = null
var _bottom_prev_map_btn: TextureButton = null
var _bottom_return_btn: TextureButton = null
var _bottom_next_map_btn: TextureButton = null
var _scroll_pointer_active: bool = false
var _scroll_dragging: bool = false
var _scroll_start_pos: Vector2 = Vector2.ZERO
var _scroll_last_pos: Vector2 = Vector2.ZERO
var _scroll_ignore_tap_once: bool = false
var _shade_visible_state := false
var _sweep_dialog_anim_state := false
var _sweep_result_anim_state := false
var _anim: AnimationHelper = null

func _get_anim() -> AnimationHelper:
	if _anim == null:
		_anim = get_node_or_null("/root/AnimationHelper") as AnimationHelper
	return _anim

func _ready() -> void:
	super._ready()
	_connect_shell_actions()
	_sync_gui()

func initialize(game: Node, data: Dictionary = {}) -> void:
	super.initialize(game, data)
	_sync_gui()
	_scroll_map_to_start()

func _create_ui() -> void:
	_back_btn = get_node("Header/BackButton") as TextureButton
	_prev_chapter_btn = get_node("Header/PreviousButton") as TextureButton
	_next_chapter_btn = get_node("Header/NextButton") as TextureButton
	_chapter_title = get_node("Header/ChapterTitle") as Label
	_chapter_name_label = get_node("Header/ChapterName") as Label
	_star_label = get_node("Header/StarValue") as Label
	_header_panel = get_node("Bindings/HeaderPanel") as PanelContainer
	_stage_container = get_node("MapScroll/ChapterMaps") as Control
	_chapter_maps_content = _stage_container
	_map_scroll = get_node("MapScroll") as ScrollContainer
	_cloud_layer_far = get_node_or_null("CloudLayerFar") as Control
	_cloud_layer_near = get_node_or_null("CloudLayerNear") as Control
	_reward_panel = get_node("Bindings/RewardPanel") as PanelContainer
	_bottom_prev_map_btn = get_node("BottomNav/PrevMapButton") as TextureButton
	_bottom_return_btn = get_node("BottomNav/ReturnButton") as TextureButton
	_bottom_next_map_btn = get_node("BottomNav/NextMapButton") as TextureButton
	_dots_container = get_node("Bindings/DotsContainer") as HBoxContainer
	_sweep_dialog = get_node("PopupLayer/SweepDialog") as Control
	_sweep_title_label = get_node("PopupLayer/SweepDialog/TitleLabel") as Label
	_sweep_gold_label = get_node("PopupLayer/SweepDialog/GoldLabel") as Label
	_sweep_exp_label = get_node("PopupLayer/SweepDialog/ExpLabel") as Label
	_sweep_rule_label = get_node("PopupLayer/SweepDialog/RuleLabel") as Label
	_sweep_confirm_btn = get_node("PopupLayer/SweepDialog/ConfirmBtn") as Button
	_sweep_cancel_btn = get_node("PopupLayer/SweepDialog/CancelBtn") as Button
	_sweep_anim_overlay = get_node("PopupLayer/SweepResult") as Control
	_sweep_anim_title_label = get_node("PopupLayer/SweepResult/TitleLabel") as Label
	_sweep_anim_gold_label = get_node("PopupLayer/SweepResult/GoldLabel") as Label
	_sweep_anim_exp_label = get_node("PopupLayer/SweepResult/ExpLabel") as Label
	var vertical_bar := _map_scroll.get_v_scroll_bar()
	if vertical_bar != null and not vertical_bar.value_changed.is_connected(_on_map_scroll_changed):
		vertical_bar.value_changed.connect(_on_map_scroll_changed)

func _connect_shell_actions() -> void:
	_connect_button(_back_btn, _on_back_btn_pressed)
	_connect_button(_prev_chapter_btn, _on_prev_chapter_btn_pressed)
	_connect_button(_next_chapter_btn, _on_next_chapter_btn_pressed)
	_connect_button(_bottom_prev_map_btn, _on_prev_chapter_btn_pressed)
	_connect_button(_bottom_return_btn, _on_back_btn_pressed)
	_connect_button(_bottom_next_map_btn, _on_next_chapter_btn_pressed)
	_connect_button(_sweep_confirm_btn, _do_sweep_confirm)
	_connect_button(_sweep_cancel_btn, _on_sweep_cancel_pressed)
	var shade := get_node("PopupLayer/Shade") as ColorRect
	if not shade.gui_input.is_connected(_on_popup_shade_input):
		shade.gui_input.connect(_on_popup_shade_input)
	_attach_button_feedback(_back_btn, CartoonButtonFeedback.Profile.ICON)
	_attach_button_feedback(_bottom_prev_map_btn, CartoonButtonFeedback.Profile.NAV, false)
	_attach_button_feedback(_bottom_return_btn, CartoonButtonFeedback.Profile.ENTRY)
	_attach_button_feedback(_bottom_next_map_btn, CartoonButtonFeedback.Profile.NAV, false)
	_attach_button_feedback(_sweep_confirm_btn, CartoonButtonFeedback.Profile.PRIMARY)
	_attach_button_feedback(_sweep_cancel_btn, CartoonButtonFeedback.Profile.NAV, false)

func _connect_button(button: BaseButton, action: Callable) -> void:
	if not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _attach_button_feedback(button: BaseButton, profile: int, burst_enabled: bool = true) -> void:
	if button == null or button.has_node("CartoonFeedback"):
		return
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)
	feedback.set_burst_enabled(burst_enabled)

func _gui_input(_event: InputEvent) -> void:
	# The editable chapter map buttons own all touch input.
	pass

func _input(event: InputEvent) -> void:
	if _map_scroll == null or _sweep_dialog_active or _sweep_anim_active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_map_scroll_drag(event.position)
		else:
			_finish_map_scroll_drag()
	elif event is InputEventScreenDrag:
		_update_map_scroll_drag(event.position, event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_map_scroll_drag(event.position)
		else:
			_finish_map_scroll_drag()
	elif event is InputEventMouseMotion and _scroll_pointer_active and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_update_map_scroll_drag(event.position, event.relative)

func _begin_map_scroll_drag(position: Vector2) -> void:
	if not _map_scroll.get_global_rect().has_point(position):
		return
	_scroll_pointer_active = true
	_scroll_dragging = false
	_scroll_start_pos = position
	_scroll_last_pos = position

func _update_map_scroll_drag(position: Vector2, relative: Vector2) -> void:
	if not _scroll_pointer_active:
		return
	if not _scroll_dragging and position.distance_to(_scroll_start_pos) >= MAP_SCROLL_DRAG_THRESHOLD:
		_scroll_dragging = true
		_scroll_ignore_tap_once = true
	if _scroll_dragging:
		_map_scroll.scroll_vertical -= int(round(relative.y))
		_scroll_last_pos = position
		_update_cloud_parallax(float(_map_scroll.scroll_vertical))
		get_viewport().set_input_as_handled()

func _finish_map_scroll_drag() -> void:
	if not _scroll_pointer_active:
		return
	var was_dragging := _scroll_dragging
	_scroll_pointer_active = false
	_scroll_dragging = false
	if was_dragging:
		_scroll_ignore_tap_once = true
		get_viewport().set_input_as_handled()
		call_deferred("_clear_scroll_tap_suppression")

func _clear_scroll_tap_suppression() -> void:
	_scroll_ignore_tap_once = false

func _should_ignore_pressed_after_scroll() -> bool:
	if not _scroll_ignore_tap_once:
		return false
	_scroll_ignore_tap_once = false
	return true

func _draw() -> void:
	# Formal map display is provided by chapter .tscn files, not Canvas drawing.
	pass

func _refresh_stage_nodes() -> void:
	_sync_map_nodes()

func _update_header() -> void:
	if _chapters.is_empty() or _current_chapter_index >= _chapters.size():
		return
	_ensure_chapter_map()
	var chapter: Dictionary = _chapters[_current_chapter_index]
	var chapter_stars := _get_chapter_stars(chapter)
	var total_stars: int = maxi((chapter.get("stages", []).size() as int) * 3, 1)
	var theme_color: Color = CHAPTER_THEME_TINTS.get(_current_chapter_element(), Color(0.30, 0.95, 0.34))
	_chapter_title.text = "第%d章" % (_current_chapter_index + 1)
	_chapter_title.add_theme_color_override("font_color", theme_color)
	_chapter_name_label.text = str(chapter.get("name", ""))
	_star_label.text = "%d/%d" % [chapter_stars, total_stars]
	(get_node("Header/Badge/Number") as Label).text = str(_current_chapter_index + 1)
	_sync_map_nodes()

func _update_chapter_buttons() -> void:
	_prev_chapter_btn.visible = false
	_prev_chapter_btn.disabled = _current_chapter_index <= 0
	_next_chapter_btn.visible = false
	_next_chapter_btn.disabled = _current_chapter_index >= _chapters.size() - 1
	if _bottom_prev_map_btn != null:
		_bottom_prev_map_btn.disabled = _current_chapter_index <= 0
		_bottom_prev_map_btn.modulate.a = 0.48 if _bottom_prev_map_btn.disabled else 1.0
	if _bottom_next_map_btn != null:
		_bottom_next_map_btn.disabled = _current_chapter_index >= _chapters.size() - 1
		_bottom_next_map_btn.modulate.a = 0.48 if _bottom_next_map_btn.disabled else 1.0

func _update_page_dots() -> void:
	var anim := _get_anim()
	for i in DOT_PATHS.size():
		var dot := get_node(DOT_PATHS[i]) as ColorRect
		dot.visible = i < _chapters.size()
		var target_color: Color = Color(1.0, 0.82, 0.18, 1.0) if i == _current_chapter_index else Color(1.0, 1.0, 1.0, 0.34)
		var target_size: Vector2 = Vector2(10.0, 6.0) if i == _current_chapter_index else Vector2(5.0, 5.0)
		if dot.color != target_color:
			if anim != null:
				anim.tween_property(dot, "color", dot.color, target_color, 0.25, "ease_out")
			else:
				dot.color = target_color
		if dot.size != target_size:
			if anim != null:
				anim.tween_property(dot, "size", dot.size, target_size, 0.25, "ease_out")
			else:
				dot.size = target_size

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("MapScroll/ChapterMaps"):
		return
	_ensure_chapter_map()
	_sync_map_nodes()
	_sync_popup_visibility()

func _ensure_chapter_map() -> void:
	var chapter_id := str(_current_chapter().get("id", ""))
	if chapter_id.is_empty() or chapter_id == _chapter_map_id:
		return
	var map_path := str(CHAPTER_MAP_NODES.get(chapter_id, ""))
	if map_path.is_empty() or not has_node(map_path):
		push_error("Cannot find chapter map node: " + map_path)
		return
	for path: String in CHAPTER_MAP_NODES.values():
		(get_node(path) as Control).visible = path == map_path
	_chapter_map = get_node(map_path) as Control
	_chapter_map_id = chapter_id
	_prepare_chapter_map_scroll_extent()
	_scroll_map_to_start()
	_connect_chapter_map_actions()

func _prepare_chapter_map_scroll_extent() -> void:
	if _chapter_map == null:
		return
	var map_height := _chapter_map_scroll_height()
	if _chapter_maps_content != null:
		_chapter_maps_content.custom_minimum_size = Vector2(DESIGN_W, map_height)
		_chapter_maps_content.size = Vector2(DESIGN_W, map_height)
	_chapter_map.custom_minimum_size = Vector2(DESIGN_W, map_height)
	_chapter_map.size = Vector2(DESIGN_W, map_height)
	for child_path in ["Background", "PathDecorations", "StageNodes"]:
		if _chapter_map.has_node(child_path):
			var child := _chapter_map.get_node(child_path) as Control
			if child.size.y < map_height:
				child.size = Vector2(DESIGN_W, map_height)

func _chapter_map_scroll_height() -> float:
	if _chapter_map != null:
		return maxf(maxf(_chapter_map.custom_minimum_size.y, _chapter_map.size.y), _map_scroll.size.y if _map_scroll != null else 0.0)
	if _chapter_maps_content != null:
		return maxf(_chapter_maps_content.custom_minimum_size.y, _chapter_maps_content.size.y)
	return DESIGN_H

func _scroll_map_to_start() -> void:
	if _map_scroll == null:
		return
	_map_scroll.scroll_horizontal = 0
	_map_scroll.scroll_vertical = 0
	_update_cloud_parallax(0.0)
	call_deferred("_scroll_map_to_bottom")

func _scroll_map_to_bottom() -> void:
	if _map_scroll == null:
		return
	_map_scroll.scroll_horizontal = 0
	_map_scroll.scroll_vertical = int(_chapter_map_scroll_height())
	_update_cloud_parallax(float(_map_scroll.scroll_vertical))

func _on_map_scroll_changed(value: float) -> void:
	_update_cloud_parallax(value)

func _update_cloud_parallax(scroll_value: float) -> void:
	if _cloud_layer_far != null:
		_cloud_layer_far.position = Vector2(-scroll_value * 0.035, -scroll_value * 0.055)
	if _cloud_layer_near != null:
		_cloud_layer_near.position = Vector2(scroll_value * 0.055, -scroll_value * 0.105)

func _connect_chapter_map_actions() -> void:
	for index in _stage_buttons().size():
		var stage_button := _stage_buttons()[index]
		_connect_button(stage_button, _on_stage_pressed.bind(index))
		_connect_button(stage_button.get_node("SweepButton") as BaseButton, _on_sweep_pressed.bind(index))
	var boss_button := _boss_button()
	if boss_button != null:
		_connect_button(boss_button, _on_boss_pressed)
	for stage_button in _stage_buttons():
		_attach_button_feedback(stage_button, CartoonButtonFeedback.Profile.NAV, false)
		_attach_button_feedback(stage_button.get_node_or_null("SweepButton") as BaseButton, CartoonButtonFeedback.Profile.ICON, false)
	var boss := _boss_button()
	if boss != null:
		_attach_button_feedback(boss, CartoonButtonFeedback.Profile.ENTRY, false)

func _stage_buttons() -> Array[TextureButton]:
	var result: Array[TextureButton] = []
	if _chapter_map == null:
		return result
	if not _chapter_map.has_node("StageNodes"):
		return result
	var stage_nodes := _chapter_map.get_node("StageNodes") as Control
	for child: Node in stage_nodes.get_children():
		if child is TextureButton and str(child.name).begins_with("Stage"):
			result.append(child as TextureButton)
	result.sort_custom(func(a: TextureButton, b: TextureButton): return str(a.name) < str(b.name))
	return result

func _boss_button() -> TextureButton:
	if _chapter_map != null and _chapter_map.has_node("BossStage"):
		return _chapter_map.get_node("BossStage") as TextureButton
	return null

func _sync_map_nodes() -> void:
	if _chapter_map == null or _cards.is_empty():
		return
	var stage_cards: Array = _cards.filter(func(card): return not bool(card.get("is_boss", false)))
	var buttons := _stage_buttons()
	for i in buttons.size():
		var button := buttons[i]
		button.visible = i < stage_cards.size()
		if button.visible:
			_sync_stage_button(button, stage_cards[i])
	var boss_card := _boss_card()
	var boss_button := _boss_button()
	if boss_button != null and not boss_card.is_empty():
		_sync_boss_button(boss_button, boss_card)

func _sync_stage_button(button: TextureButton, card: Dictionary) -> void:
	var enabled := bool(card.get("enabled", true))
	button.disabled = not enabled
	button.modulate.a = 1.0 if enabled else 0.80
	(button.get_node("StageNumber") as Label).text = str(card.get("stage_no", ""))
	(button.get_node("StageNumber") as Label).modulate = TEXT_WHITE if enabled else TEXT_MUTED
	var lock_state := button.get_node("LockState") as Label
	lock_state.visible = not enabled
	_sync_selection_ring(button, enabled)
	_sync_stars(button.get_node("Stars") as Control, int(card.get("stars", 0)), enabled)
	(button.get_node("SweepButton") as Button).visible = enabled and bool(card.get("can_sweep", false))

func _sync_boss_button(button: TextureButton, card: Dictionary) -> void:
	var enabled := bool(card.get("enabled", true))
	button.disabled = not enabled
	button.modulate.a = 1.0 if enabled else 0.82
	_sync_selection_ring(button, enabled)
	_sync_stars(button.get_node("Stars") as Control, int(card.get("stars", 0)), enabled)
	(button.get_node("LockState") as Label).visible = not enabled

func _sync_selection_ring(button: TextureButton, enabled: bool) -> void:
	if not button.has_node("SelectionRing"):
		return
	var ring := button.get_node("SelectionRing") as TextureRect
	ring.visible = enabled
	ring.modulate.a = 0.72 if enabled else 0.0

func _sync_stars(container: Control, count: int, enabled: bool) -> void:
	for i in 3:
		var star := container.get_node("Star%02d" % (i + 1)) as TextureRect
		var lit := i < count
		var path := DEFAULT_STAR_LIT_PATH if lit else DEFAULT_STAR_DIM_PATH
		if _chapter_map_id == "chapter_1":
			path = CHAPTER_01_STAR_PATH
		star.texture = _get_texture(path)
		star.modulate.a = 1.0 if enabled and lit else 0.32

func _boss_card() -> Dictionary:
	for card: Dictionary in _cards:
		if bool(card.get("is_boss", false)):
			return card
	return {}

func _active_stage_cards() -> Array:
	return _cards.filter(func(card): return not bool(card.get("is_boss", false)))

func _on_stage_pressed(index: int) -> void:
	if _should_ignore_pressed_after_scroll():
		return
	var cards := _active_stage_cards()
	if index < cards.size() and bool(cards[index].get("enabled", false)):
		stage_selected.emit(str(cards[index].get("id", "")), cards[index].get("stage_data", {}), _current_chapter_index)

func _on_sweep_pressed(index: int) -> void:
	if _should_ignore_pressed_after_scroll():
		return
	var cards := _active_stage_cards()
	if index < cards.size() and bool(cards[index].get("enabled", false)) and bool(cards[index].get("can_sweep", false)):
		_show_sweep_dialog(str(cards[index].get("id", "")), str(cards[index].get("text", "")))

func _on_boss_pressed() -> void:
	if _should_ignore_pressed_after_scroll():
		return
	var card := _boss_card()
	if not card.is_empty() and bool(card.get("enabled", false)):
		stage_selected.emit(str(card.get("id", "")), card.get("stage_data", {}), _current_chapter_index)

func _on_popup_shade_input(event: InputEvent) -> void:
	if not _sweep_dialog_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_sweep_cancel_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		_on_sweep_cancel_pressed()

func _switch_chapter(direction: int) -> void:
	super._switch_chapter(direction)
	_sync_gui()

func _show_sweep_dialog(stage_id: String, stage_name: String) -> void:
	super._show_sweep_dialog(stage_id, stage_name)
	_sync_popup_visibility()

func _on_sweep_cancel_pressed() -> void:
	super._on_sweep_cancel_pressed()
	_sync_popup_visibility()

func _do_sweep_confirm() -> void:
	super._do_sweep_confirm()
	_sync_popup_visibility()

func _update_sweep_animation(delta: float) -> void:
	super._update_sweep_animation(delta)
	_sync_popup_visibility()

func _sync_popup_visibility() -> void:
	var shade := get_node("PopupLayer/Shade") as ColorRect
	var want_shade := _sweep_dialog_active or _sweep_anim_active
	var want_dialog := _sweep_dialog_active
	var want_result := _sweep_anim_active
	var anim := _get_anim()

	if want_shade and not _shade_visible_state:
		_shade_visible_state = true
		shade.visible = true
		if anim != null:
			shade.modulate.a = 0.0
			anim.tween_property(shade, "modulate:a", 0.0, 0.48, 0.25, "ease_out")
		else:
			shade.modulate.a = 0.48
	elif not want_shade and _shade_visible_state:
		_shade_visible_state = false
		shade.visible = false
		shade.modulate.a = 0.0

	if want_dialog and not _sweep_dialog_anim_state:
		_sweep_dialog_anim_state = true
		if anim != null:
			anim.pop_in(_sweep_dialog, 0.28)
		else:
			_sweep_dialog.visible = true
	elif not want_dialog and _sweep_dialog_anim_state:
		_sweep_dialog_anim_state = false
		if anim != null and _sweep_dialog.visible:
			anim.pop_out(_sweep_dialog, 0.18)
		else:
			_sweep_dialog.visible = false

	if want_result and not _sweep_result_anim_state:
		_sweep_result_anim_state = true
		if anim != null:
			anim.pop_in(_sweep_anim_overlay, 0.30)
		else:
			_sweep_anim_overlay.visible = true
	elif not want_result and _sweep_result_anim_state:
		_sweep_result_anim_state = false
		if anim != null and _sweep_anim_overlay.visible:
			anim.pop_out(_sweep_anim_overlay, 0.20)
		else:
			_sweep_anim_overlay.visible = false

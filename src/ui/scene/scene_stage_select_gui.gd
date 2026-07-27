# scene_stage_select_gui.gd - 可在 Godot 编辑器中逐章调整的章节大地图界面
# 数据、解锁与扫荡规则沿用 SceneStageSelect；每个大章使用独立的 .tscn 地图文件。
class_name SceneStageSelectGui
extends "res://src/ui/controllers/stage_select_logic.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const AnimationHelperScript := preload("res://src/engine/animation_player.gd")
const StageSelectChapterRegistryScript := preload("res://src/ui/scene/stage_select_chapter_registry.gd")
const MonsterIdleAnimatorScript := preload("res://src/ui/components/monster_idle_animator.gd")

const CHAPTER_MAP_NODES := StageSelectChapterRegistryScript.CHAPTER_MAP_NODES
const CHAPTER_MAP_SCENES := StageSelectChapterRegistryScript.CHAPTER_MAP_SCENES
const DOT_PATHS := [
	"Header/Dots/Dot1", "Header/Dots/Dot2", "Header/Dots/Dot3",
	"Header/Dots/Dot4", "Header/Dots/Dot5", "Header/Dots/Dot6",
	"Header/Dots/Dot7", "Header/Dots/Dot8", "Header/Dots/Dot9",
	"Header/Dots/Dot10", "Header/Dots/Dot11",
]
const TEXT_WHITE := Color(1.0, 1.0, 1.0)
const TEXT_MUTED := Color(0.66, 0.75, 0.88)
const MAP_SCROLL_DRAG_THRESHOLD: float = 8.0
const DEFAULT_STAR_LIT_PATH := "res://assets/images/ui/icons/stage_star_gold_new.png"
const DEFAULT_STAR_DIM_PATH := "res://assets/images/ui/icons/result_refresh_icon_star_silver.png"
const CHAPTER_01_STAR_PATH := "res://assets/images/ui/icons/stage_star_gold_new.png"
const STAGE_LOCK_ICON_PATH := "res://assets/images/ui/icons/stage_lock_icon.png"
const STAGE_LOCK_ICON_SIZE := Vector2(28.0, 28.0)
const STAGE_NUMBER_SIZE := Vector2(64.0, 22.0)
const STAGE_LOCK_REFERENCE_Y: float = 36.0
const BOSS_COMPACT_PLATFORM_SCALE: float = 1.0
const BOSS_COMPACT_BUTTON_MAX_SIZE := Vector2(130.0, 150.0)
const CLOUD_TRANSITION_CLOSE_DURATION: float = 0.50
const CLOUD_TRANSITION_HOLD_DURATION: float = 0.22
const CLOUD_TRANSITION_OPEN_DURATION: float = 0.66
const CLOUD_TRANSITION_MAP_OUT_SCALE: Vector2 = Vector2(1.105, 1.105)
const CLOUD_TRANSITION_MAP_IN_SCALE: Vector2 = Vector2(1.12, 1.12)
const CLOUD_TRANSITION_LAYER_Z_INDEX: int = 4096
const MAP_SHELL_UI_Z_INDEX: int = 2048
const MAP_POPUP_LAYER_Z_INDEX: int = 3072
const CLOUD_TRANSITION_MIST_CLOSED_ALPHA: float = 1.0
const TRANSITION_LEFT_CLOSED_X := [-285.0, -365.0, -310.0, -255.0, -315.0, -260.0, -155.0, -245.0, -170.0, -145.0]
const TRANSITION_RIGHT_CLOSED_X := [-110.0, -145.0, -95.0, -20.0, -75.0, -55.0, -10.0, 45.0, 65.0, 30.0]
const TRANSITION_LEFT_DELAY := [0.0, 0.04, 0.02, 0.07, 0.11, 0.03, 0.015, 0.055, 0.085, 0.11]
const TRANSITION_RIGHT_DELAY := [0.03, 0.0, 0.05, 0.09, 0.12, 0.02, 0.025, 0.065, 0.095, 0.115]

# === 大地图入场动画时间线（对齐大厅 Header / BottomNav 节奏）===
const ENTRY_HEADER_DELAY := 0.00
const ENTRY_NAV_DELAY := 0.38
const ENTRY_HEADER_DURATION := 0.34
const ENTRY_NAV_DURATION := 0.34
const ENTRY_HEADER_SLIDE := 30.0
const ENTRY_NAV_SLIDE := 30.0
var _entry_played: bool = false

var _chapter_map: Control = null
var _chapter_map_id: String = ""
var _chapter_maps_content: Control = null
var _map_scroll: ScrollContainer = null
var _cloud_layer_far: Control = null
var _cloud_layer_near: Control = null
var _transition_cloud_layer: Control = null
var _transition_mist: ColorRect = null
var _transition_left_clouds: Array[Control] = []
var _transition_right_clouds: Array[Control] = []
var _map_transition_active: bool = false
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
var _sweep_choice_card: Dictionary = {}
var _anim: AnimationHelper = null
var _focus_stage_id: String = ""
var _focus_scroll_applied: bool = false
var _chapter_lock_hint: Label = null
var _chapter_lock_hint_tween: Tween = null
var _chapter_scene_cache: Dictionary = {}

func _get_anim() -> AnimationHelper:
	if _anim == null:
		_anim = get_node_or_null("/root/AnimationHelper") as AnimationHelper
	return _anim

func _ready() -> void:
	super._ready()
	_connect_shell_actions()
	_sync_gui()
	_maybe_play_entry()

func initialize(game: Node, data: Dictionary = {}) -> void:
	_focus_stage_id = str(data.get("focusStageId", ""))
	_focus_scroll_applied = false
	super.initialize(game, data)
	_sync_gui()
	_scroll_map_to_start()
	# _scroll_map_to_start 内部 call_deferred 了 _scroll_map_to_bottom。
	# 我们也用 call_deferred 排到它之后执行，确保 focus 滚动不会被打回底部。
	if not _focus_stage_id.is_empty():
		call_deferred("_scroll_map_to_focus", _focus_stage_id)

func _create_ui() -> void:
	_back_btn = get_node("Header/BackButton") as TextureButton
	_prev_chapter_btn = get_node_or_null("Header/PreviousButton") as TextureButton
	_next_chapter_btn = get_node_or_null("Header/NextButton") as TextureButton
	_chapter_title = get_node("Header/ChapterTitle") as Label
	_chapter_name_label = get_node("Header/ChapterName") as Label
	_star_label = get_node("Header/StarValue") as Label
	_header_panel = get_node("Bindings/HeaderPanel") as PanelContainer
	_stage_container = get_node("MapScroll/ChapterMaps") as Control
	_chapter_maps_content = _stage_container
	_map_scroll = get_node("MapScroll") as ScrollContainer
	_cloud_layer_far = get_node_or_null("CloudLayerFar") as Control
	_cloud_layer_near = get_node_or_null("CloudLayerNear") as Control
	_transition_cloud_layer = get_node_or_null("TransitionCloudLayer") as Control
	_transition_mist = get_node_or_null("TransitionCloudLayer/Mist") as ColorRect
	_cache_transition_clouds()
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
	_enforce_shell_z_order()
	_setup_chapter_lock_hint()
	var vertical_bar := _map_scroll.get_v_scroll_bar()
	if vertical_bar != null and not vertical_bar.value_changed.is_connected(_on_map_scroll_changed):
		vertical_bar.value_changed.connect(_on_map_scroll_changed)


func _enforce_shell_z_order() -> void:
	for path in ["Header", "BottomNav"]:
		var shell := get_node_or_null(path) as Control
		if shell != null:
			shell.z_index = MAP_SHELL_UI_Z_INDEX
	var popup_layer := get_node_or_null("PopupLayer") as Control
	if popup_layer != null:
		popup_layer.z_index = MAP_POPUP_LAYER_Z_INDEX
	if _transition_cloud_layer != null:
		_transition_cloud_layer.z_index = CLOUD_TRANSITION_LAYER_Z_INDEX

func _connect_shell_actions() -> void:
	_connect_button(_back_btn, _on_back_btn_pressed)
	_connect_button(_prev_chapter_btn, _on_prev_chapter_btn_pressed)
	_connect_button(_next_chapter_btn, _on_next_chapter_btn_pressed)
	_connect_button(_bottom_prev_map_btn, _on_prev_chapter_btn_pressed)
	_connect_button(_bottom_return_btn, _on_back_btn_pressed)
	_connect_button(_bottom_next_map_btn, _on_next_chapter_btn_pressed)
	_connect_button(_sweep_confirm_btn, _do_sweep_confirm)
	_connect_button(_sweep_cancel_btn, _on_sweep_enter_pressed)
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
	if button == null:
		return
	if not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _attach_button_feedback(button: BaseButton, profile: int, burst_enabled: bool = true) -> void:
	if button == null or button.has_node("CartoonFeedback"):
		return
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)
	feedback.set_burst_enabled(burst_enabled)

func _cache_transition_clouds() -> void:
	_transition_left_clouds.clear()
	_transition_right_clouds.clear()
	if _transition_cloud_layer == null:
		return
	for child: Node in _transition_cloud_layer.get_children():
		if child is Control:
			var control := child as Control
			if str(control.name).begins_with("LeftCloud"):
				_transition_left_clouds.append(control)
			elif str(control.name).begins_with("RightCloud"):
				_transition_right_clouds.append(control)
	_transition_left_clouds.sort_custom(func(a: Control, b: Control): return str(a.name) < str(b.name))
	_transition_right_clouds.sort_custom(func(a: Control, b: Control): return str(a.name) < str(b.name))
	_reset_transition_clouds()

func _reset_transition_clouds() -> void:
	if _transition_cloud_layer == null:
		return
	for cloud in _transition_left_clouds:
		if not cloud.has_meta("open_position"):
			cloud.set_meta("open_position", cloud.position)
		cloud.position = cloud.get_meta("open_position")
	for cloud in _transition_right_clouds:
		if not cloud.has_meta("open_position"):
			cloud.set_meta("open_position", cloud.position)
		cloud.position = cloud.get_meta("open_position")
	if _transition_mist != null:
		_transition_mist.color = Color(1, 1, 1, 0.0)
	_transition_cloud_layer.visible = false

# 大地图入场序列：Header 从上方滑入 + 淡入，BottomNav 从下方滑入 + 淡入
func _maybe_play_entry() -> void:
	if _entry_played:
		return
	_entry_played = true
	_play_entry()

func _play_entry() -> void:
	# 1) Header：上方 30px 滑入 + 淡入
	var header := get_node_or_null("Header") as Control
	if header != null:
		var header_rest_y := header.position.y
		header.position.y = header_rest_y - ENTRY_HEADER_SLIDE
		header.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_HEADER_DELAY)
		tween.tween_property(header, "modulate:a", 1.0, ENTRY_HEADER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(header, "position:y", header_rest_y, ENTRY_HEADER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2) BottomNav：下方 30px 滑入 + 淡入
	var nav := get_node_or_null("BottomNav") as Control
	if nav != null:
		var nav_rest_y := nav.position.y
		nav.position.y = nav_rest_y + ENTRY_NAV_SLIDE
		nav.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_NAV_DELAY)
		tween.tween_property(nav, "modulate:a", 1.0, ENTRY_NAV_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(nav, "position:y", nav_rest_y, ENTRY_NAV_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _gui_input(_event: InputEvent) -> void:
	# The editable chapter map buttons own all touch input.
	pass

func _input(event: InputEvent) -> void:
	if _map_scroll == null or _sweep_dialog_active or _sweep_anim_active or _map_transition_active:
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
	_chapter_title.text = TranslationServer.translate("第%d章") % (_current_chapter_index + 1)
	_chapter_title.add_theme_color_override("font_color", theme_color)
	_chapter_name_label.text = TranslationServer.translate(str(chapter.get("name", "")))
	CartoonTypography.fit_label(_chapter_name_label, 14, 7)
	_star_label.text = "%d/%d" % [chapter_stars, total_stars]
	var badge_number := get_node_or_null("Header/Badge/Number") as Label
	if badge_number != null:
		badge_number.text = str(_current_chapter_index + 1)
	_sync_map_nodes()

func _update_chapter_buttons() -> void:
	if _prev_chapter_btn != null:
		_prev_chapter_btn.visible = false
		_prev_chapter_btn.disabled = _current_chapter_index <= 0
	if _next_chapter_btn != null:
		_next_chapter_btn.visible = false
		_next_chapter_btn.disabled = _current_chapter_index >= _chapters.size() - 1
	if _bottom_prev_map_btn != null:
		_bottom_prev_map_btn.disabled = _current_chapter_index <= 0
		_bottom_prev_map_btn.modulate.a = 0.48 if _bottom_prev_map_btn.disabled else 1.0
	if _bottom_next_map_btn != null:
		var has_next := _current_chapter_index < _chapters.size() - 1
		var next_chapter_index := _current_chapter_index + 1
		var next_unlocked := has_next and _is_chapter_unlocked(next_chapter_index)
		_bottom_next_map_btn.disabled = not has_next
		_bottom_next_map_btn.modulate = Color.WHITE if next_unlocked else Color(0.62, 0.66, 0.72, 0.82)
		_bottom_next_map_btn.tooltip_text = TranslationServer.translate("前往第%d章") % (next_chapter_index + 1) if next_unlocked else (
			TranslationServer.translate("第%d章尚未解锁，请先击败第%d章 Boss") % [next_chapter_index + 1, next_chapter_index] if has_next else "已到达最终章"
		)
		var next_text := _bottom_next_map_btn.get_node_or_null("Text") as Label
		if next_text != null:
			next_text.text = TranslationServer.translate("第%d章") % (next_chapter_index + 1) if has_next else "最终章"
			next_text.add_theme_color_override("font_color", Color.WHITE if next_unlocked else Color(0.78, 0.82, 0.88))
		var next_arrow := _bottom_next_map_btn.get_node_or_null("Arrow") as TextureRect
		if next_arrow != null:
			next_arrow.visible = next_unlocked
		var lock_icon := _ensure_next_chapter_lock_icon()
		lock_icon.visible = has_next and not next_unlocked

func _ensure_next_chapter_lock_icon() -> TextureRect:
	var lock_icon := _bottom_next_map_btn.get_node_or_null("LockIcon") as TextureRect
	if lock_icon != null:
		return lock_icon
	lock_icon = TextureRect.new()
	lock_icon.name = "LockIcon"
	lock_icon.position = Vector2(68.0, 9.0)
	lock_icon.size = Vector2(20.0, 20.0)
	lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_icon.texture = _get_texture(STAGE_LOCK_ICON_PATH)
	_bottom_next_map_btn.add_child(lock_icon)
	return lock_icon

func _setup_chapter_lock_hint() -> void:
	if _chapter_lock_hint != null:
		return
	_chapter_lock_hint = Label.new()
	_chapter_lock_hint.name = "ChapterLockHint"
	_chapter_lock_hint.position = Vector2(37.5, 515.0)
	_chapter_lock_hint.size = Vector2(300.0, 44.0)
	_chapter_lock_hint.z_index = 3000
	_chapter_lock_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_lock_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_lock_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chapter_lock_hint.add_theme_font_size_override("font_size", 14)
	_chapter_lock_hint.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))
	_chapter_lock_hint.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.95))
	_chapter_lock_hint.add_theme_constant_override("outline_size", 4)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.075, 0.15, 0.94)
	panel.border_color = Color(1.0, 0.72, 0.18, 0.95)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(12)
	_chapter_lock_hint.add_theme_stylebox_override("normal", panel)
	_chapter_lock_hint.visible = false
	add_child(_chapter_lock_hint)

func _show_chapter_locked_hint(chapter_index: int) -> void:
	_setup_chapter_lock_hint()
	if _chapter_lock_hint_tween != null and _chapter_lock_hint_tween.is_valid():
		_chapter_lock_hint_tween.kill()
	_chapter_lock_hint.text = TranslationServer.translate("第%d章尚未解锁，请先击败第%d章 Boss") % [chapter_index + 1, chapter_index]
	_chapter_lock_hint.visible = true
	_chapter_lock_hint.modulate.a = 0.0
	_chapter_lock_hint.scale = Vector2(0.92, 0.92)
	_chapter_lock_hint.pivot_offset = _chapter_lock_hint.size * 0.5
	_chapter_lock_hint_tween = create_tween()
	_chapter_lock_hint_tween.set_parallel(true)
	_chapter_lock_hint_tween.tween_property(_chapter_lock_hint, "modulate:a", 1.0, 0.16)
	_chapter_lock_hint_tween.tween_property(_chapter_lock_hint, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_chapter_lock_hint_tween.chain().tween_interval(1.6)
	_chapter_lock_hint_tween.chain().tween_property(_chapter_lock_hint, "modulate:a", 0.0, 0.28)
	_chapter_lock_hint_tween.chain().tween_callback(func(): _chapter_lock_hint.visible = false)

func _update_page_dots() -> void:
	var anim := _get_anim()
	for i in DOT_PATHS.size():
		var dot := get_node_or_null(DOT_PATHS[i]) as ColorRect
		if dot == null:
			continue
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

## 从大厅点击"开始冒险"时，会附带 focusStageId。把 chapter map
## 滚动到该台子可见位置。仅当用户没手动滚动过、且目标在当前章节时生效。
func _maybe_apply_focus_scroll() -> void:
	if _focus_scroll_applied:
		return
	if _focus_stage_id.is_empty():
		return
	if _map_scroll == null or _chapter_map == null:
		return
	if not _scroll_pointer_active:
		_scroll_map_to_focus(_focus_stage_id)
		_focus_scroll_applied = true

func _scroll_map_to_focus(stage_id: String) -> void:
	if stage_id.is_empty():
		return
	var target_button: Control = _find_stage_button(stage_id)
	if target_button == null:
		return
	# 把 stage 节点投影到 chapter map 的局部坐标
	var stage_nodes := _chapter_map.get_node_or_null("StageNodes")
	var stage_nodes_offset := Vector2.ZERO
	if stage_nodes != null:
		stage_nodes_offset = stage_nodes.position
	var target_y := target_button.position.y + stage_nodes_offset.y + target_button.size.y * 0.5
	var view_h := _map_scroll.size.y
	# 真正可滚动的最大值是 ScrollContainer 内部 VScrollBar.max_value
	# (= content_height - viewport_height)，不是 chapter map 的整体高度。
	var max_scroll: float = 0.0
	var v_bar: VScrollBar = _map_scroll.get_v_scroll_bar()
	if v_bar != null:
		max_scroll = float(v_bar.max_value)
	else:
		max_scroll = maxf(0.0, _chapter_map_scroll_height() - view_h)
	var desired := target_y - view_h * 0.5
	_map_scroll.scroll_vertical = clampf(desired, 0.0, max_scroll)
	_update_cloud_parallax(float(_map_scroll.scroll_vertical))

## 按 stage_id 在当前章节里找对应的 TextureButton（含 BossStage）
func _find_stage_button(stage_id: String) -> Control:
	if _cards.is_empty():
		return null
	var boss_card := _boss_card()
	if not boss_card.is_empty() and str(boss_card.get("id", "")) == stage_id:
		return _boss_button()
	var stage_cards: Array = _cards.filter(func(card): return not bool(card.get("is_boss", false)))
	var buttons := _stage_buttons()
	for i in stage_cards.size():
		if i >= buttons.size():
			break
		if str(stage_cards[i].get("id", "")) == stage_id:
			return buttons[i]
	return null

func _ensure_chapter_map() -> void:
	var chapter_id := str(_current_chapter().get("id", ""))
	if chapter_id.is_empty():
		return
	if chapter_id == _chapter_map_id and is_instance_valid(_chapter_map):
		return
	var map_path := str(CHAPTER_MAP_NODES.get(chapter_id, ""))
	var scene_path := str(CHAPTER_MAP_SCENES.get(chapter_id, ""))
	if map_path.is_empty() or scene_path.is_empty():
		push_error("Cannot find chapter map scene: " + chapter_id)
		return
	var packed_scene := _load_chapter_scene(chapter_id, scene_path)
	if packed_scene == null:
		push_error("Cannot load chapter map scene: " + scene_path)
		return
	_clear_instanced_chapter_maps()
	var map := packed_scene.instantiate() as Control
	if map == null:
		push_error("Cannot instantiate chapter map scene: " + scene_path)
		return
	map.name = _chapter_map_node_name(chapter_id)
	map.visible = true
	map.layout_mode = 0
	_chapter_maps_content.add_child(map)
	_chapter_map = map
	_chapter_map_id = chapter_id
	_prepare_chapter_map_scroll_extent()
	_scroll_map_to_start()
	_connect_chapter_map_actions()
	_normalize_chapter_map_visuals()

func _load_chapter_scene(chapter_id: String, scene_path: String) -> PackedScene:
	if _chapter_scene_cache.has(chapter_id):
		return _chapter_scene_cache[chapter_id] as PackedScene
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene != null:
		_chapter_scene_cache[chapter_id] = packed_scene
	return packed_scene

func _chapter_map_node_name(chapter_id: String) -> String:
	var node_path := str(CHAPTER_MAP_NODES.get(chapter_id, ""))
	if node_path.is_empty():
		return "ChapterMap"
	var parts := node_path.split("/")
	return str(parts[parts.size() - 1])

func _clear_instanced_chapter_maps() -> void:
	if _chapter_maps_content == null:
		return
	for child in _chapter_maps_content.get_children():
		child.queue_free()
	_chapter_map = null
	_chapter_map_id = ""

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
		_configure_sweep_indicator(stage_button)
	var boss_button := _boss_button()
	if boss_button != null:
		_connect_button(boss_button, _on_boss_pressed)
	for stage_button in _stage_buttons():
		_attach_button_feedback(stage_button, CartoonButtonFeedback.Profile.NAV, false)
		_ensure_portrait_node(stage_button, _STAGE_PORTRAIT_FALLBACK_POS, _STAGE_PORTRAIT_SIZE)
		_normalize_stage_button_layout(stage_button)
	var boss := _boss_button()
	if boss != null:
		_attach_button_feedback(boss, CartoonButtonFeedback.Profile.ENTRY, false)
		_ensure_portrait_node(boss, _BOSS_PORTRAIT_FALLBACK_POS, _BOSS_PORTRAIT_SIZE)
		_normalize_boss_button_layout(boss)

func _configure_sweep_indicator(stage_button: TextureButton) -> void:
	var sweep_indicator := stage_button.get_node_or_null("SweepButton") as Button
	if sweep_indicator == null:
		return
	sweep_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweep_indicator.focus_mode = Control.FOCUS_NONE
	for child in sweep_indicator.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

# 普通关卡台子的画像尺寸（位置由 _apply_stage_portrait 动态按台子中心计算）
const _STAGE_PORTRAIT_SIZE := Vector2(74.0, 66.0)
# Boss 台子的画像尺寸
const _BOSS_PORTRAIT_SIZE := Vector2(118.0, 108.0)
# 首帧 fallback 位置（_apply_*_portrait 会在 _sync 时按台子尺寸重设为"底部对准中心"）
const _STAGE_PORTRAIT_FALLBACK_POS := Vector2(9.0, -17.0)
const _BOSS_PORTRAIT_FALLBACK_POS := Vector2(30.0, 10.0)
const _STAGE_PORTRAIT_LIFT := 4.0
const _BOSS_PORTRAIT_LIFT := -5.0
const _BOSS_PORTRAIT_PEDESTAL_ANCHOR_Y := 0.58

var _boss_stage_portrait_texture_cache: Dictionary = {}

## 动态为关卡台子添加怪物画像 TextureRect；只创建一次，避免重复堆叠。
## 位置由 _apply_stage_portrait / _apply_boss_portrait 按台子尺寸动态计算（底部对准台子中心）。
func _ensure_portrait_node(button: TextureButton, fallback_pos: Vector2, portrait_size: Vector2) -> TextureRect:
	if button == null:
		return null
	if button.has_node("MonsterPortrait"):
		return button.get_node("MonsterPortrait") as TextureRect
	var portrait := TextureRect.new()
	portrait.name = "MonsterPortrait"
	portrait.position = fallback_pos
	portrait.size = portrait_size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.visible = false
	button.add_child(portrait)
	return portrait

## 从 card 中取出该关卡的"招牌"怪物 ID：普通关卡取第一个 enemy；
## 多阶段 Boss 取第一阶段第一个 enemy；找不到返回空串。
func _feature_enemy_id(card: Dictionary) -> String:
	var stage_data: Dictionary = card.get("stage_data", {})
	if stage_data.is_empty():
		return ""
	var enemies: Array = stage_data.get("enemies", [])
	if not enemies.is_empty():
		return str(enemies[0])
	for phase: Dictionary in stage_data.get("phases", []):
		var phase_enemies: Array = phase.get("enemies", [])
		if not phase_enemies.is_empty():
			return str(phase_enemies[0])
	return ""

## 把招牌怪物的画像同步到台子上的 MonsterPortrait。
## 显示规则：已解锁但未通关（stars==0）的关卡，把招牌怪物原色画像放在台子中心，
## 让怪物看起来"坐在台子上"。已锁定（enabled==false）或已通关（stars>0）的关卡不显示。
func _apply_stage_portrait(button: TextureButton, card: Dictionary) -> void:
	var portrait := _ensure_portrait_node(button, _STAGE_PORTRAIT_FALLBACK_POS, _STAGE_PORTRAIT_SIZE)
	if portrait == null:
		return
	var enabled := bool(card.get("enabled", true))
	var stars := int(card.get("stars", 0))
	if not enabled or stars > 0:
		MonsterIdleAnimatorScript.unbind(portrait)
		portrait.visible = false
		portrait.texture = null
		return
	var monster_id := _feature_enemy_id(card)
	var path := MonsterArtDB.get_battle_portrait_path(monster_id) if not monster_id.is_empty() else ""
	if path.is_empty() or not ResourceLoader.exists(path):
		MonsterIdleAnimatorScript.unbind(portrait)
		portrait.visible = false
		portrait.texture = null
		return
	portrait.texture = load(path)
	MonsterIdleAnimatorScript.bind(portrait, monster_id)
	# 保留原色（白 modulate = 无修改）
	portrait.modulate = Color(1, 1, 1, 1)
	# 动态定位：图片底部对准台子中心并略向上抬，水平居中。
	_center_portrait_on_pedestal(button, portrait, _STAGE_PORTRAIT_LIFT)
	portrait.visible = true

func _apply_boss_portrait(button: TextureButton, card: Dictionary) -> void:
	var portrait := _ensure_portrait_node(button, _BOSS_PORTRAIT_FALLBACK_POS, _BOSS_PORTRAIT_SIZE)
	if portrait == null:
		return
	var monster_id := _feature_enemy_id(card)
	var path := MonsterArtDB.get_battle_portrait_path(monster_id) if not monster_id.is_empty() else ""
	if path.is_empty() or not ResourceLoader.exists(path):
		MonsterIdleAnimatorScript.unbind(portrait)
		portrait.visible = false
		portrait.texture = null
		return
	portrait.texture = _stage_select_boss_portrait_texture(path)
	MonsterIdleAnimatorScript.bind(portrait, monster_id)
	portrait.modulate = Color(1, 1, 1, 1)
	portrait.z_index = 1
	_center_boss_portrait_on_pedestal(button, portrait)
	portrait.visible = true

func _stage_select_boss_portrait_texture(path: String) -> Texture2D:
	if _boss_stage_portrait_texture_cache.has(path):
		return _boss_stage_portrait_texture_cache[path]
	var source := load(path) as Texture2D
	if source == null:
		return null
	_boss_stage_portrait_texture_cache[path] = source
	return _boss_stage_portrait_texture_cache[path]

## 把 portrait 放在台子中心：图片底部贴着 button 垂直中线，水平居中。
## 这样怪物画像看起来像坐在台子上（露出台子上半部分）。
func _center_portrait_on_pedestal(button: TextureButton, portrait: TextureRect, lift: float) -> void:
	var btn_size: Vector2 = button.size
	var port_size: Vector2 = portrait.size
	# Bottom-of-portrait sits slightly above the pedestal midline.
	portrait.position = Vector2(
		(btn_size.x - port_size.x) * 0.5,
		btn_size.y * 0.5 - lift - port_size.y
	)

func _center_boss_portrait_on_pedestal(button: TextureButton, portrait: TextureRect) -> void:
	var platform := button.get_node_or_null("Platform") as Control
	if platform == null:
		_center_portrait_on_pedestal(button, portrait, _BOSS_PORTRAIT_LIFT)
		return
	var port_size: Vector2 = portrait.size
	var platform_center_x := platform.position.x + platform.size.x * 0.5
	var anchor_y := platform.position.y + platform.size.y * _BOSS_PORTRAIT_PEDESTAL_ANCHOR_Y
	portrait.position = Vector2(platform_center_x - port_size.x * 0.5, anchor_y - port_size.y)

func _normalize_chapter_map_visuals() -> void:
	if _chapter_map == null:
		return
	var path_decorations := _chapter_map.get_node_or_null("PathDecorations") as CanvasItem
	if path_decorations != null:
		path_decorations.visible = false
	for stage_button in _stage_buttons():
		_normalize_stage_button_layout(stage_button)
	var boss := _boss_button()
	if boss != null:
		_normalize_boss_button_layout(boss)

func _normalize_stage_button_layout(button: TextureButton) -> void:
	if button == null:
		return
	var number := button.get_node_or_null("StageNumber") as Label
	if number == null:
		return
	var platform := button.get_node_or_null("Platform") as Control
	var center_x := button.size.x * 0.5
	var top_y := 14.0
	if platform != null:
		center_x = platform.position.x + platform.size.x * 0.5
		top_y = platform.position.y + 1.0
	number.position = Vector2(center_x - STAGE_NUMBER_SIZE.x * 0.5, top_y)
	number.size = STAGE_NUMBER_SIZE
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.add_theme_font_override("font", _stage_number_font())
	number.add_theme_font_size_override("font_size", 12)
	number.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.18, 0.92))
	number.add_theme_constant_override("outline_size", 3)

func _normalize_boss_button_layout(button: TextureButton) -> void:
	if button == null:
		return
	var platform := button.get_node_or_null("Platform") as TextureRect
	if platform == null:
		return
	var is_compact := button.size.x <= BOSS_COMPACT_BUTTON_MAX_SIZE.x and button.size.y <= BOSS_COMPACT_BUTTON_MAX_SIZE.y
	if not is_compact:
		return
	if not platform.has_meta("base_position"):
		platform.set_meta("base_position", platform.position)
		platform.set_meta("base_size", platform.size)
	var base_position: Vector2 = platform.get_meta("base_position")
	var base_size: Vector2 = platform.get_meta("base_size")
	var center := base_position + base_size * 0.5
	var target_size := base_size * BOSS_COMPACT_PLATFORM_SCALE
	platform.size = target_size
	platform.position = center - target_size * 0.5
	platform.z_index = 0
	var label := button.get_node_or_null("StageLabel") as Label
	if label != null:
		label.z_index = 3
		label.size = Vector2(84.0, 24.0)
		label.position = Vector2((button.size.x - label.size.x) * 0.5, platform.position.y + platform.size.y * 0.56)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", _stage_number_font())
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.18, 0.94))
		label.add_theme_constant_override("outline_size", 3)
	var stars := button.get_node_or_null("Stars") as Control
	if stars != null:
		stars.z_index = 3
		stars.size = Vector2(48.0, 14.0)
		stars.position = Vector2((button.size.x - stars.size.x) * 0.5, platform.position.y + platform.size.y * 0.82)

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
	_normalize_chapter_map_visuals()
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
	var number := button.get_node("StageNumber") as Label
	number.text = _stage_display_label(card)
	number.modulate = TEXT_WHITE if enabled else TEXT_MUTED
	number.visible = true
	_normalize_stage_button_layout(button)
	_sync_lock_state(button, not enabled)
	_sync_selection_ring(button, enabled)
	_sync_stars(button.get_node("Stars") as Control, int(card.get("stars", 0)), enabled)
	var sweep_indicator := button.get_node("SweepButton") as Button
	sweep_indicator.visible = enabled and bool(card.get("can_sweep", false))
	_configure_sweep_indicator(button)
	_apply_stage_portrait(button, card)

func _sync_boss_button(button: TextureButton, card: Dictionary) -> void:
	var enabled := bool(card.get("enabled", true))
	button.disabled = not enabled
	button.modulate.a = 1.0 if enabled else 0.82
	var label := button.get_node_or_null("StageLabel") as Label
	if label != null:
		label.text = _stage_display_label(card)
		label.modulate = TEXT_WHITE if enabled else TEXT_MUTED
	_normalize_boss_button_layout(button)
	_sync_selection_ring(button, enabled)
	_sync_stars(button.get_node("Stars") as Control, int(card.get("stars", 0)), enabled)
	_sync_lock_state(button, not enabled)
	_apply_boss_portrait(button, card)

func _sync_lock_state(button: TextureButton, visible: bool) -> void:
	var lock_node := button.get_node_or_null("LockState") as CanvasItem
	if lock_node == null:
		return
	if lock_node is TextureRect:
		var icon := lock_node as TextureRect
		if icon.texture == null or icon.texture.resource_path != STAGE_LOCK_ICON_PATH:
			icon.texture = _get_texture(STAGE_LOCK_ICON_PATH)
		icon.size = STAGE_LOCK_ICON_SIZE
		if button.name == "BossStage" and button.has_node("Platform"):
			var platform := button.get_node("Platform") as Control
			icon.position = platform.position + (platform.size - STAGE_LOCK_ICON_SIZE) * 0.5
			icon.z_index = 4
		else:
			icon.position = Vector2((button.size.x - STAGE_LOCK_ICON_SIZE.x) * 0.5, STAGE_LOCK_REFERENCE_Y)
	elif lock_node is Label:
		(lock_node as Label).text = ""
	lock_node.visible = visible

func _sync_selection_ring(button: TextureButton, _enabled: bool) -> void:
	if not button.has_node("SelectionRing"):
		return
	var ring := button.get_node("SelectionRing") as TextureRect
	ring.visible = false
	ring.modulate.a = 0.0

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
	if index >= cards.size():
		return
	var card: Dictionary = cards[index]
	if not bool(card.get("enabled", false)):
		return
	if bool(card.get("can_sweep", false)):
		_sweep_choice_card = card.duplicate(true)
		_show_sweep_dialog(str(card.get("id", "")), str(card.get("text", "")))
		return
	_emit_stage_selection(card)

func _on_sweep_enter_pressed() -> void:
	if _sweep_choice_card.is_empty():
		_on_sweep_cancel_pressed()
		return
	var card := _sweep_choice_card.duplicate(true)
	_on_sweep_cancel_pressed()
	_emit_stage_selection(card)

func _emit_stage_selection(card: Dictionary) -> void:
	stage_selected.emit(str(card.get("id", "")), card.get("stage_data", {}), _current_chapter_index)

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
	if _map_transition_active:
		return
	var new_index: int = _current_chapter_index + direction
	if new_index < 0 or new_index >= _chapters.size():
		return
	if direction > 0 and not _is_chapter_unlocked(new_index):
		_show_chapter_locked_hint(new_index)
		return
	_play_cloud_chapter_transition(direction)

func _play_cloud_chapter_transition(direction: int) -> void:
	_map_transition_active = true
	_set_transition_buttons_disabled(true)
	_prepare_transition_layer()
	var outgoing_map := _chapter_map
	_prepare_map_for_transition(outgoing_map)

	var close_tween := create_tween()
	close_tween.set_parallel(true)
	if outgoing_map != null:
		close_tween.tween_property(outgoing_map, "scale", CLOUD_TRANSITION_MAP_OUT_SCALE, 0.48).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		close_tween.tween_property(outgoing_map, "modulate:a", 0.84, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _transition_mist != null:
		close_tween.tween_property(_transition_mist, "color", Color(1, 1, 1, CLOUD_TRANSITION_MIST_CLOSED_ALPHA), 0.46).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween_transition_clouds(close_tween, true)
	await close_tween.finished

	super._switch_chapter(direction)
	_sync_gui()
	await get_tree().process_frame
	var incoming_map := _chapter_map
	_prepare_map_for_transition(incoming_map)
	if incoming_map != null:
		incoming_map.scale = CLOUD_TRANSITION_MAP_IN_SCALE
		incoming_map.modulate.a = 1.0
	if CLOUD_TRANSITION_HOLD_DURATION > 0.0:
		await get_tree().create_timer(CLOUD_TRANSITION_HOLD_DURATION).timeout

	var open_tween := create_tween()
	open_tween.set_parallel(true)
	if incoming_map != null:
		open_tween.tween_property(incoming_map, "scale", Vector2.ONE, 0.58).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _transition_mist != null:
		open_tween.tween_property(_transition_mist, "color", Color(1, 1, 1, 0.0), 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween_transition_clouds(open_tween, false)
	await open_tween.finished

	if is_instance_valid(outgoing_map):
		outgoing_map.scale = Vector2.ONE
		outgoing_map.modulate.a = 1.0
	if is_instance_valid(incoming_map):
		incoming_map.scale = Vector2.ONE
		incoming_map.modulate.a = 1.0
	_reset_transition_clouds()
	_map_transition_active = false
	_set_transition_buttons_disabled(false)
	_update_chapter_buttons()

func _prepare_transition_layer() -> void:
	if _transition_cloud_layer == null:
		return
	_transition_cloud_layer.z_index = CLOUD_TRANSITION_LAYER_Z_INDEX
	_transition_cloud_layer.visible = true
	_transition_cloud_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	if _transition_mist != null:
		_transition_mist.color = Color(1, 1, 1, 0.0)
	for cloud in _transition_left_clouds:
		if not cloud.has_meta("open_position"):
			cloud.set_meta("open_position", cloud.position)
		cloud.position = cloud.get_meta("open_position")
	for cloud in _transition_right_clouds:
		if not cloud.has_meta("open_position"):
			cloud.set_meta("open_position", cloud.position)
		cloud.position = cloud.get_meta("open_position")

func _prepare_map_for_transition(map: Control) -> void:
	if map == null or _map_scroll == null:
		return
	map.pivot_offset = Vector2(DESIGN_W * 0.5, float(_map_scroll.scroll_vertical) + DESIGN_H * 0.5)
	map.scale = Vector2.ONE
	map.modulate.a = 1.0

func _tween_transition_clouds(tween: Tween, closing: bool) -> void:
	for i in _transition_left_clouds.size():
		var cloud := _transition_left_clouds[i]
		var target: Vector2 = cloud.get_meta("open_position")
		if closing:
			target.x = float(TRANSITION_LEFT_CLOSED_X[mini(i, TRANSITION_LEFT_CLOSED_X.size() - 1)])
		var duration := CLOUD_TRANSITION_CLOSE_DURATION if closing else CLOUD_TRANSITION_OPEN_DURATION
		var delay := float(TRANSITION_LEFT_DELAY[mini(i, TRANSITION_LEFT_DELAY.size() - 1)])
		if not closing:
			delay = maxf(0.0, 0.14 - delay)
		tween.tween_property(cloud, "position", target, duration + float(i) * 0.012).set_delay(delay).set_trans(Tween.TRANS_BACK if closing else Tween.TRANS_QUART).set_ease(Tween.EASE_OUT if closing else Tween.EASE_IN_OUT)
	for i in _transition_right_clouds.size():
		var cloud := _transition_right_clouds[i]
		var target: Vector2 = cloud.get_meta("open_position")
		if closing:
			target.x = float(TRANSITION_RIGHT_CLOSED_X[mini(i, TRANSITION_RIGHT_CLOSED_X.size() - 1)])
		var duration := CLOUD_TRANSITION_CLOSE_DURATION if closing else CLOUD_TRANSITION_OPEN_DURATION
		var delay := float(TRANSITION_RIGHT_DELAY[mini(i, TRANSITION_RIGHT_DELAY.size() - 1)])
		if not closing:
			delay = maxf(0.0, 0.14 - delay)
		tween.tween_property(cloud, "position", target, duration + float(i) * 0.012).set_delay(delay).set_trans(Tween.TRANS_BACK if closing else Tween.TRANS_QUART).set_ease(Tween.EASE_OUT if closing else Tween.EASE_IN_OUT)

func _set_transition_buttons_disabled(disabled: bool) -> void:
	for button in [_bottom_prev_map_btn, _bottom_next_map_btn, _bottom_return_btn, _back_btn]:
		if button != null:
			button.disabled = disabled

func _show_sweep_dialog(stage_id: String, stage_name: String) -> void:
	super._show_sweep_dialog(stage_id, stage_name)
	_sweep_title_label.text = TranslationServer.translate("选择操作：%s") % stage_name
	(_sweep_confirm_btn.get_node("Text") as Label).text = "扫荡"
	(_sweep_cancel_btn.get_node("Text") as Label).text = "进入关卡"
	_sync_popup_visibility()

func _on_sweep_cancel_pressed() -> void:
	super._on_sweep_cancel_pressed()
	_sweep_choice_card.clear()
	_sync_popup_visibility()

func _do_sweep_confirm() -> void:
	super._do_sweep_confirm()
	_sync_popup_visibility()

func _update_sweep_animation(delta: float) -> void:
	super._update_sweep_animation(delta)
	_sync_popup_visibility()

func _sync_popup_visibility() -> void:
	var popup_layer := get_node("PopupLayer") as Control
	var shade := get_node("PopupLayer/Shade") as ColorRect
	var want_shade := _sweep_dialog_active or _sweep_anim_active
	var want_dialog := _sweep_dialog_active
	var want_result := _sweep_anim_active
	var anim := _get_anim()
	popup_layer.visible = want_shade or want_dialog or want_result

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

## scene_manager.gd — 场景管理器（Autoload）
## 提供全局场景切换接口
extends Node

const TransitionProgressScript = preload("res://src/core/transition_progress.gd")

var _main_node: Control = null  # main.tscn 的根节点引用

## 转场特效
var _transition_overlay: ColorRect = null
var _is_transitioning: bool = false
var _pending_scene_name: String = ""
var _pending_scene_data: Dictionary = {}
var _pending_scene_mode: String = ""
const TRANSITION_DURATION: float = 0.3  # 淡入淡出时长（秒）
const QUICK_TRANSITION_DURATION: float = 0.11
const QUICK_TRANSITION_ALPHA: float = 0.42
var _team_assets_warmed := false

func _ready() -> void:
	set_process_input(true)
	# 等待主场景加载完成
	await get_tree().process_frame
	_main_node = get_tree().root.get_node_or_null("Main") as Control
	_setup_transition_overlay()
	call_deferred("_warm_team_assets")

func _warm_team_assets() -> void:
	if _team_assets_warmed:
		return
	var script := load("res://src/ui/scene/scene_team_gui.gd") as GDScript
	if script != null and script.has_method("warm_assets"):
		script.call("warm_assets")
	_team_assets_warmed = true

func _setup_transition_overlay() -> void:
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.z_index = 1000  # 最顶层
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.gui_input.connect(_on_transition_overlay_gui_input)
	get_tree().root.add_child(_transition_overlay)

func _input(_event: InputEvent) -> void:
	if _is_transitioning:
		get_viewport().set_input_as_handled()

func _on_transition_overlay_gui_input(_event: InputEvent) -> void:
	if _is_transitioning:
		get_viewport().set_input_as_handled()

func is_transitioning() -> bool:
	return _is_transitioning

## 切换场景（带淡入淡出效果）
func switch_scene(scene_name: String, data: Dictionary = {}, mode: String = "") -> void:
	if _is_transitioning:
		_pending_scene_name = scene_name
		_pending_scene_data = data
		_pending_scene_mode = mode
		return
	_is_transitioning = true
	_set_transition_input_blocked(true)
	if scene_name == "team":
		_warm_team_assets()
	var quick := mode == "quick" or scene_name == "team"
	var duration := QUICK_TRANSITION_DURATION if quick else TRANSITION_DURATION
	var max_alpha := QUICK_TRANSITION_ALPHA if quick else 1.0
	
	await _fade_out(duration, max_alpha)
	
	# 执行场景切换
	_do_switch_scene(scene_name, data, mode)
	
	await _fade_in(duration, max_alpha)
	
	_is_transitioning = false
	if _pending_scene_name.is_empty():
		_set_transition_input_blocked(false)
	_flush_pending_scene()

func _set_transition_input_blocked(blocked: bool) -> void:
	if _transition_overlay == null:
		return
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if blocked else Control.MOUSE_FILTER_IGNORE

func _flush_pending_scene() -> void:
	if _pending_scene_name.is_empty():
		return
	var scene_name := _pending_scene_name
	var data := _pending_scene_data
	var mode := _pending_scene_mode
	_pending_scene_name = ""
	_pending_scene_data = {}
	_pending_scene_mode = ""
	call_deferred("switch_scene", scene_name, data, mode)

func _fade_out(duration: float = TRANSITION_DURATION, max_alpha: float = 1.0) -> void:
	if _transition_overlay == null:
		return
	var t: float = 0.0
	while t < duration:
		await get_tree().process_frame
		t = TransitionProgressScript.advance(t, duration, _get_transition_delta())
		_transition_overlay.color = Color(0.0, 0.0, 0.0, TransitionProgressScript.fade_alpha(t, duration, max_alpha, true))
	_transition_overlay.color = Color(0.0, 0.0, 0.0, max_alpha)

func _fade_in(duration: float = TRANSITION_DURATION, max_alpha: float = 1.0) -> void:
	if _transition_overlay == null:
		return
	var t: float = 0.0
	while t < duration:
		await get_tree().process_frame
		t = TransitionProgressScript.advance(t, duration, _get_transition_delta())
		_transition_overlay.color = Color(0.0, 0.0, 0.0, TransitionProgressScript.fade_alpha(t, duration, max_alpha, false))
	_transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

func _get_transition_delta() -> float:
	var delta := get_process_delta_time()
	if delta <= 0.0:
		return 1.0 / 60.0
	return delta

func _do_switch_scene(scene_name: String, data: Dictionary, mode: String) -> void:
	if _main_node == null:
		_main_node = get_tree().root.get_node_or_null("Main") as Control
	if _main_node and _main_node.has_method("switch_scene"):
		_main_node.switch_scene(scene_name, data, mode)
	else:
		push_warning(TranslationServer.translate("[SceneManager] 无法切换场景: ") + scene_name)

## 兼容微信版/旧移植代码里仍在使用的 change_scene 命名
func change_scene(scene_name: String, data: Dictionary = {}, mode: String = "") -> void:
	switch_scene(scene_name, data, mode)

## 获取当前场景名
func get_current_scene_name() -> String:
	if _main_node and _main_node.has_method("get_current_scene_name"):
		return _main_node.get_current_scene_name()
	return ""

## 获取当前场景节点
func get_current_scene() -> Control:
	if _main_node and _main_node.has_method("get_current_scene"):
		return _main_node.get_current_scene()
	return null

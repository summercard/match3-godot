## scene_manager.gd — 场景管理器（Autoload）
## 提供全局场景切换接口
extends Node

var _main_node: Control = null  # main.tscn 的根节点引用

## 转场特效
var _transition_overlay: ColorRect = null
var _is_transitioning: bool = false
const TRANSITION_DURATION: float = 0.3  # 淡入淡出时长（秒）

func _ready() -> void:
	# 等待主场景加载完成
	await get_tree().process_frame
	_main_node = get_tree().root.get_node_or_null("Main") as Control
	_setup_transition_overlay()

func _setup_transition_overlay() -> void:
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.z_index = 1000  # 最顶层
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截点击
	get_tree().root.add_child(_transition_overlay)

## 切换场景（带淡入淡出效果）
func switch_scene(scene_name: String, data: Dictionary = {}, mode: String = "") -> void:
	if _is_transitioning:
		push_warning("[SceneManager] 正在转场中，忽略切换请求: " + scene_name)
		return
	_is_transitioning = true
	
	# 阶段1：淡出（0 → 0.3s）
	await _fade_out()
	
	# 执行场景切换
	_do_switch_scene(scene_name, data, mode)
	
	# 阶段2：淡入（0.3 → 0.6s）
	await _fade_in()
	
	_is_transitioning = false

func _fade_out() -> void:
	if _transition_overlay == null:
		return
	var t: float = 0.0
	var step: float = 0.016  # ~60fps
	while t < TRANSITION_DURATION:
		t += step
		var alpha: float = clamp(t / TRANSITION_DURATION, 0.0, 1.0)
		_transition_overlay.color = Color(0.0, 0.0, 0.0, alpha)
		await get_tree().process_frame
	_transition_overlay.color = Color(0.0, 0.0, 0.0, 1.0)

func _fade_in() -> void:
	if _transition_overlay == null:
		return
	var t: float = 0.0
	var step: float = 0.016  # ~60fps
	while t < TRANSITION_DURATION:
		t += step
		var alpha: float = 1.0 - clamp(t / TRANSITION_DURATION, 0.0, 1.0)
		_transition_overlay.color = Color(0.0, 0.0, 0.0, alpha)
		await get_tree().process_frame
	_transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

func _do_switch_scene(scene_name: String, data: Dictionary, mode: String) -> void:
	if _main_node == null:
		_main_node = get_tree().root.get_node_or_null("Main") as Control
	if _main_node and _main_node.has_method("switch_scene"):
		_main_node.switch_scene(scene_name, data, mode)
	else:
		push_warning("[SceneManager] 无法切换场景: " + scene_name)

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

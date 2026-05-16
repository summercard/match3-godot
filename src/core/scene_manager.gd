## scene_manager.gd — 场景管理器（Autoload）
## 提供全局场景切换接口
extends Node

var _main_node: Control = null  # main.tscn 的根节点引用

func _ready() -> void:
	# 等待主场景加载完成
	await get_tree().process_frame
	_main_node = get_tree().root.get_node_or_null("Main") as Control

## 切换场景
func switch_scene(scene_name: String, data: Dictionary = {}, mode: String = "") -> void:
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

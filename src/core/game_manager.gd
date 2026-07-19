## GameManager — 游戏全局管理器（Autoload）
## 只保留：信号总线 + 场景切换
## 所有存档逻辑已迁移至 SaveManager
extends Node

# ====== 信号 ======
signal scene_changed(scene_name: String)

# ====== 子系统引用 ======
var scene_manager_node: Node = null  # main.tscn 中挂载的 main.gd
## 场景管理器（兼容 scene_team.gd 的 game_manager.scene_manager 调用）
var scene_manager: Node = null
## 存档管理器（兼容微信版 game.storage 调用）
var storage: Node = null

# ====== 单例 ======
static var instance: Node

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	instance = null

func _ready() -> void:
	# print("[GameManager] 初始化")
	# 等待场景树就绪
	await get_tree().process_frame

	# 获取主场景引用（用于场景切换分发）
	var root := get_tree().root
	scene_manager_node = root.get_node_or_null("Main")

	# 获取 SceneManager 引用（供其他场景使用）
	scene_manager = root.get_node_or_null("SceneManager")
	storage = root.get_node_or_null("SaveManager")

	# print("[GameManager] 初始化完成")

# ====== 场景切换 ======
func switch_scene(scene_name: String, data: Dictionary = {}, mode: String = "") -> void:
	if scene_manager == null:
		scene_manager = get_tree().root.get_node_or_null("SceneManager")
	if scene_manager and scene_manager.has_method("switch_scene"):
		scene_manager.switch_scene(scene_name, data, mode)
		emit_signal("scene_changed", scene_name)
		return

	if scene_manager_node == null:
		scene_manager_node = get_tree().root.get_node_or_null("Main")
	if scene_manager_node and scene_manager_node.has_method("switch_scene"):
		scene_manager_node.switch_scene(scene_name, data, mode)
		emit_signal("scene_changed", scene_name)
	else:
		push_warning(TranslationServer.translate("[GameManager] 无法切换场景: ") + scene_name)

## 兼容仍调用 game.scene_manager.change_scene / game.change_scene 的旧界面代码
func change_scene(scene_name: String, data: Dictionary = {}, mode: String = "") -> void:
	switch_scene(scene_name, data, mode)

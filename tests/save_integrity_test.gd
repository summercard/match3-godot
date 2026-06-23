extends SceneTree

const SaveManagerScript = preload("res://src/core/save_manager.gd")
const SaveFileStoreScript = preload("res://src/core/save_file_store.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist")
	if storage == null:
		_finish()
		return

	storage.clear_all_data()
	_expect(storage.get_save_schema_version() == 1, "new saves should carry schema_version=1")

	var player: Dictionary = storage.load_player()
	player["gold"] = 123
	_expect(storage.save_player(player), "save_player should report success when disk save succeeds")
	player["gold"] = 456
	_expect(storage.save_player(player), "second save_player should create a backup before replacing the main save")

	var save_path: String = str(storage.call("_get_save_path"))
	var backup_path := SaveFileStoreScript.get_backup_path(save_path)
	_expect(FileAccess.file_exists(backup_path), "atomic save should keep a .bak backup")

	var main_path := _global_path(save_path)
	DirAccess.remove_absolute(main_path)
	var recovered := SaveManagerScript.new()
	var status: Dictionary = recovered.get_load_status()
	_expect(str(status.get("status", "")) == "recovered_backup", "missing main save should restore from .bak")
	_expect(bool(status.get("recovered", false)), "load status should mark backup recovery")
	_expect(int(recovered.load_player().get("gold", 0)) == 123, "backup recovery should load the last coherent previous save")
	recovered.free()

	storage.clear_all_data()
	player = storage.load_player()
	player["gold"] = 777
	storage.set_force_save_failure(true)
	_expect(not storage.save_player(player), "save_player should propagate save failure")
	_expect(not storage.save_inventory({"capture_ball": 9}), "save_inventory should propagate save failure")
	storage.set_force_save_failure(false)

	_finish()


func _global_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SaveIntegrity] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SaveIntegrity] " + failure)
	quit(1)

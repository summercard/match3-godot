class_name SaveFileStore
extends RefCounted


static func load_config(save_path: String) -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(save_path)
	if err == OK:
		return {
			"ok": true,
			"config": config,
			"status": "loaded",
			"error": OK,
			"recovered": false,
		}
	var backup_path := get_backup_path(save_path)
	var backup := ConfigFile.new()
	var backup_err := backup.load(backup_path)
	if backup_err == OK:
		_restore_backup(save_path, backup_path)
		return {
			"ok": true,
			"config": backup,
			"status": "recovered_backup",
			"error": err,
			"backup_error": backup_err,
			"recovered": true,
		}
	if err == ERR_FILE_NOT_FOUND:
		return {
			"ok": true,
			"config": ConfigFile.new(),
			"status": "empty",
			"error": err,
			"recovered": false,
		}

	return {
		"ok": false,
		"config": ConfigFile.new(),
		"status": "corrupt",
		"error": err,
		"backup_error": backup_err,
		"recovered": false,
	}


static func save_atomic(config: ConfigFile, save_path: String) -> Dictionary:
	var global_save_path := _global_path(save_path)
	var base_dir := global_save_path.get_base_dir()
	if not base_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(base_dir)

	var temp_path := "%s.tmp" % global_save_path
	var backup_path := "%s.bak" % global_save_path
	var err := config.save(temp_path)
	if err != OK:
		return {"ok": false, "error": "temp_save_failed", "code": err}

	if FileAccess.file_exists(global_save_path):
		var backup_err := DirAccess.copy_absolute(global_save_path, backup_path)
		if backup_err != OK:
			DirAccess.remove_absolute(temp_path)
			return {"ok": false, "error": "backup_failed", "code": backup_err}
		var remove_err := DirAccess.remove_absolute(global_save_path)
		if remove_err != OK:
			DirAccess.remove_absolute(temp_path)
			return {"ok": false, "error": "replace_remove_failed", "code": remove_err}

	var rename_err := DirAccess.rename_absolute(temp_path, global_save_path)
	if rename_err != OK:
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(global_save_path):
			DirAccess.copy_absolute(backup_path, global_save_path)
		return {"ok": false, "error": "replace_rename_failed", "code": rename_err}

	return {"ok": true, "error": "", "code": OK}


static func get_backup_path(save_path: String) -> String:
	return "%s.bak" % _global_path(save_path)


static func _restore_backup(save_path: String, backup_path: String) -> void:
	var global_save_path := _global_path(save_path)
	var global_backup_path := _global_path(backup_path)
	var base_dir := global_save_path.get_base_dir()
	if not base_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(base_dir)
	DirAccess.copy_absolute(global_backup_path, global_save_path)


static func _global_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path

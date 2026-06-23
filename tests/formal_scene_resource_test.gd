extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_paths: Array[String] = ["res://main.tscn"]
	_collect_tscn_paths("res://src", scene_paths)
	for scene_path in scene_paths:
		_scan_tscn_resource_paths(scene_path)
	_finish()


func _collect_tscn_paths(dir_path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		_failures.append("formal resource scan should open %s" % dir_path)
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".tscn"):
			result.append("%s/%s" % [dir_path, file_name])
	for child_name in dir.get_directories():
		if child_name.begins_with("."):
			continue
		_collect_tscn_paths("%s/%s" % [dir_path, child_name], result)


func _scan_tscn_resource_paths(scene_path: String) -> void:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		_failures.append("formal scene should be readable: %s" % scene_path)
		return
	var line_number := 0
	while not file.eof_reached():
		line_number += 1
		var line := file.get_line()
		var res_path := _extract_resource_path(line)
		if res_path.is_empty():
			continue
		if _is_banned_resource_path(res_path):
			_failures.append("%s:%d should not reference banned resource path %s" % [scene_path, line_number, res_path])
			continue
		if not ResourceLoader.exists(res_path) and not FileAccess.file_exists(res_path):
			_failures.append("%s:%d missing resource %s" % [scene_path, line_number, res_path])


func _is_banned_resource_path(res_path: String) -> bool:
	for prefix in [
		"res://.godot/imported",
		"res://assets/MATCH3美术资产",
		"res://assets/新美术资产",
	]:
		if res_path.begins_with(prefix):
			return true
	return false


func _extract_resource_path(line: String) -> String:
	if not line.contains("[ext_resource"):
		return ""
	var marker := "path=\""
	var start := line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	if end < 0:
		return ""
	return line.substr(start, end - start)


func _finish() -> void:
	if _failures.is_empty():
		print("[FormalSceneResource] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[FormalSceneResource] " + failure)
	quit(1)

extends SceneTree

const SCENE_DIR := "res://src/ui/scenes"
const TEST_DIR := "res://tests"
const BANNED_FORMAL_SCRIPT_PREFIX := "res://src/ui/controllers/"
const DYNAMIC_SCRIPT_MARKER := "set_" + "script("
const BANNED_TEAM_CONTROLLER_LOAD := "res://src/ui/controllers/team_" + "logic.gd"
const ALLOWED_TEST_SET_SCRIPT := {
	"visual_scene_runner.gd": true,
}

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_scan_scene_scripts(SCENE_DIR)
	_scan_test_dynamic_script_replacement(TEST_DIR)

	if _failures.is_empty():
		print("[UiSceneContract] OK")
		quit(0)
	else:
		for failure in _failures:
			push_error("[UiSceneContract] " + failure)
		quit(1)

func _scan_scene_scripts(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	_expect(dir != null, "%s should be readable" % dir_path)
	if dir == null:
		return

	for file_name in dir.get_files():
		if not file_name.ends_with(".tscn"):
			continue
		var path := dir_path + "/" + file_name
		var text := FileAccess.get_file_as_string(path)
		for line in text.split("\n"):
			var script_path := _extract_resource_path(str(line))
			if script_path.begins_with(BANNED_FORMAL_SCRIPT_PREFIX):
				_expect(false, "%s should not bind a formal scene directly to %s" % [path, script_path])

	for subdir in dir.get_directories():
		_scan_scene_scripts(dir_path + "/" + subdir)

func _scan_test_dynamic_script_replacement(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	_expect(dir != null, "%s should be readable" % dir_path)
	if dir == null:
		return

	for file_name in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		var path := dir_path + "/" + file_name
		var text := FileAccess.get_file_as_string(path)
		if text.contains(DYNAMIC_SCRIPT_MARKER) and not ALLOWED_TEST_SET_SCRIPT.has(file_name):
			_expect(false, "%s should not dynamically replace scene scripts in tests" % path)
		if text.contains(BANNED_TEAM_CONTROLLER_LOAD):
			_expect(false, "%s should not load the archived team draw controller" % path)

	for subdir in dir.get_directories():
		_scan_test_dynamic_script_replacement(dir_path + "/" + subdir)

func _extract_resource_path(line: String) -> String:
	var marker := "path=\""
	var start := line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	if end < 0:
		return ""
	return line.substr(start, end - start)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

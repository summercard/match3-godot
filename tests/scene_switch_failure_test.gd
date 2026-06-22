extends SceneTree

const MainScript = preload("res://main.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = MainScript.new()
	var old_scene := Control.new()
	old_scene.name = "OldScene"
	main.add_child(old_scene)
	main.set("_current_scene", old_scene)
	main.set("_current_scene_name", "old_scene")
	var old_name: String = main.get_current_scene_name()
	var failed: bool = main.switch_scene("__missing_scene__")
	_expect(not failed, "switching to a missing scene should return false")
	_expect(main.get_current_scene() == old_scene, "failed scene switch should keep the current scene instance")
	_expect(main.get_current_scene_name() == old_name, "failed scene switch should keep the current scene name")

	main.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SceneSwitchFailure] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SceneSwitchFailure] " + failure)
	quit(1)

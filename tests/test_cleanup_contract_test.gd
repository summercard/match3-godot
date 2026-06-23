extends SceneTree

const SCENE_TESTS := [
	"active_skill_test.gd",
	"battle_gui_scene_test.gd",
	"inventory_gui_scene_test.gd",
	"main_lobby_scene_test.gd",
	"shop_gui_scene_test.gd",
	"spd_power_contract_test.gd",
	"stage_select_gui_scene_test.gd",
	"start_gui_scene_test.gd",
]

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for test_file in SCENE_TESTS:
		var path: String = "res://tests/" + str(test_file)
		var text := FileAccess.get_file_as_string(path)
		_expect(text.contains("TestSceneCleanup"), "%s should use the shared scene cleanup helper" % path)
		_expect(text.contains("queue_free_root"), "%s should queue root cleanup before quit" % path)

	if _failures.is_empty():
		print("[TestCleanupContract] OK")
		quit(0)
	else:
		for failure in _failures:
			push_error("[TestCleanupContract] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

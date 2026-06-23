extends SceneTree

const SaveManagerScript = preload("res://src/core/save_manager.gd")
const BattlePrepareScript = preload("res://src/ui/controllers/battle_prepare_logic.gd")
const TeamGuiScript = preload("res://src/ui/scene/scene_team_gui.gd")
const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stats := {"hp": 100, "atk": 30, "def": 20, "spd": 999}
	var expected := 150
	var prepare = BattlePrepareScript.new()
	var team_gui = TeamGuiScript.new()
	_expect(prepare.call("_calc_battle_power", stats) == expected, "battle prepare power should ignore SPD")
	_expect(team_gui.call("_calc_battle_power", stats) == expected, "TSCN team power should ignore SPD")

	var storage = SaveManagerScript.new()
	root.add_child(storage)
	storage.clear_all_data()
	var first := storage.add_monster_instance("monster_001", {"level": 5, "nature": "brave"})
	var first_id := str(first.get("instanceId", ""))
	storage.save_team({"leader": first_id, "member1": null, "member2": null})
	var saved_stats: Dictionary = storage.get_instance_stats(first_id)
	_expect(storage.calc_team_power() == int(saved_stats.get("hp", 0)) + int(saved_stats.get("atk", 0)) + int(saved_stats.get("def", 0)), "SaveManager team power should ignore SPD")

	prepare.free()
	team_gui.free()
	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SpdPowerContract] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SpdPowerContract] " + failure)
	quit(1)

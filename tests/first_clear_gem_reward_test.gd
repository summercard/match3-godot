extends SceneTree

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

	var normal_first := _show_result("stage_1_1", "normal", "win")
	_expect(int(storage.get_player().get("gems", 0)) == 3, "normal stage first clear should grant 3 diamonds")
	_expect(int((normal_first.get("_rewards") as Dictionary).get("gems", 0)) == 3, "normal first-clear result should expose 3 diamonds")
	normal_first.queue_free()

	var normal_repeat := _show_result("stage_1_1", "normal", "win")
	_expect(int(storage.get_player().get("gems", 0)) == 3, "replaying a cleared normal stage should not grant diamonds")
	_expect(int((normal_repeat.get("_rewards") as Dictionary).get("gems", 0)) == 0, "repeat-clear result should not show diamonds")
	normal_repeat.queue_free()

	var boss_first := _show_result("stage_1_12", "boss", "win")
	_expect(int(storage.get_player().get("gems", 0)) == 13, "boss first clear should grant 10 diamonds")
	_expect(int((boss_first.get("_rewards") as Dictionary).get("gems", 0)) == 10, "boss first-clear result should expose 10 diamonds")
	boss_first.queue_free()

	var boss_repeat := _show_result("stage_1_12", "boss", "win")
	_expect(int(storage.get_player().get("gems", 0)) == 13, "replaying a cleared boss stage should not grant diamonds")
	boss_repeat.queue_free()

	var defeat := _show_result("stage_1_2", "normal", "lose")
	_expect(int(storage.get_player().get("gems", 0)) == 13, "defeat should not grant first-clear diamonds")
	_expect(not storage.is_stage_cleared("stage_1_2"), "defeat should not consume the first-clear reward")
	defeat.queue_free()

	_finish()

func _show_result(stage_id: String, stage_type: String, result_type: String) -> Control:
	var result: Control = load("res://src/ui/controllers/result_logic.gd").new()
	root.add_child(result)
	result.init({
		"result": result_type,
		"stageId": stage_id,
		"stageData": {"id": stage_id, "type": stage_type},
		"turnCount": 5,
		"maxTurns": 20,
		"stageRewards": {"gold": 0, "exp": 0},
		"playerTeam": [{"id": "monster_001", "level": 1, "hp": 10, "maxHP": 10}],
		"capture_played_inline": true,
		"captured": false,
	})
	return result

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[FirstClearGemReward] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[FirstClearGemReward] " + failure)
	quit(1)

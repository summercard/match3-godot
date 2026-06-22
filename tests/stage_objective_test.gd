extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const BoardScript = preload("res://src/match3/board.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_formal_stage_contains_runtime_goal()
	_test_break_rocks_replaces_enemy_defeat_condition()
	_test_fog_control_can_win_with_enemies_alive()
	_test_unlock_path_can_win_with_enemies_alive()
	_test_regular_goal_still_requires_enemy_defeat()
	_finish()


func _test_formal_stage_contains_runtime_goal() -> void:
	var stage: Dictionary = StageDBScript.new().get_stage("stage_2_6")
	_expect(str(stage.get("stageGoal", {}).get("id", "")) == "break_rocks", "formal chapter 2 obstacle stage should carry a break-rocks runtime goal")


func _test_break_rocks_replaces_enemy_defeat_condition() -> void:
	var board = BoardScript.new(3, 3)
	board.set_obstacles([{"row": 1, "col": 1, "type": "rock", "hp": 1}])
	var battle = _make_battle({"id": "break_rocks", "label": "破障"}, board)
	battle.enemies[0]["hp"] = 0
	_expect(not battle.check_battle_end(), "enemy defeat alone must not complete a break-rocks stage")
	board.damage_obstacle(1, 1)
	_expect(battle.check_battle_end(board), "clearing the final rock should complete the stage")
	_expect(battle.battle_result == "win", "completed rock objective should produce a win")
	var payload: Dictionary = battle.get_battle_result()
	_expect(bool(payload.get("objectiveCompleted", false)), "result payload should record objective completion")
	battle.free()


func _test_fog_control_can_win_with_enemies_alive() -> void:
	var board = BoardScript.new(3, 3)
	board.set_poison_fog({"tiles": [{"row": 1, "col": 1}], "spreadInterval": 99})
	var battle = _make_battle({"id": "fog_control", "label": "控雾"}, board)
	board.clear_poison_fog(1, 1)
	_expect(battle.check_battle_end(board), "clearing all poison fog should complete the stage")
	_expect(int(battle.enemies[0].get("hp", 0)) > 0, "fog objective should not require defeating the enemy")
	battle.free()


func _test_unlock_path_can_win_with_enemies_alive() -> void:
	var board = BoardScript.new(3, 3)
	board.set_locked_gems([{"row": 1, "col": 1, "hp": 1}])
	var battle = _make_battle({"id": "unlock_path", "label": "解锁"}, board)
	board.unlock_gem(1, 1)
	_expect(battle.check_battle_end(board), "unlocking the final gem should complete the stage")
	_expect(str(battle.get_objective_state(board).get("display", "")).contains("1/1"), "objective state should expose realtime progress")
	battle.free()


func _test_regular_goal_still_requires_enemy_defeat() -> void:
	var board = BoardScript.new(3, 3)
	var battle = _make_battle({"id": "board_affinity", "label": "能量训练"}, board)
	_expect(not battle.check_battle_end(board), "regular lesson goal should not auto-complete")
	battle.enemies[0]["hp"] = 0
	_expect(battle.check_battle_end(board), "regular lesson goal should still complete by defeating enemies")
	battle.free()


func _make_battle(goal: Dictionary, board):
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	var stage := {
		"id": "objective_test",
		"enemies": ["enemy_001"],
		"enemyLevel": 1,
		"maxTurns": 10,
		"stageGoal": goal,
		"rewards": {"gold": 1, "exp": 1}
	}
	battle.init(["monster_001"], ["enemy_001"], 5, 1, stage, "objective_test")
	battle.configure_objective(board)
	return battle


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[StageObjective] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[StageObjective] " + failure)
	quit(1)

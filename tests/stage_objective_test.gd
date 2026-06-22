extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const BoardScript = preload("res://src/match3/board.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_formal_stage_uses_enemy_defeat_goal()
	_test_board_goals_do_not_replace_enemy_defeat()
	_test_regular_goal_still_requires_enemy_defeat()
	_finish()


func _test_formal_stage_uses_enemy_defeat_goal() -> void:
	var stage: Dictionary = StageDBScript.new().get_stage("stage_2_6")
	_expect(str(stage.get("stageGoal", {}).get("id", "")) == "defeat_enemies", "formal obstacle stages should keep the standard defeat-enemies goal")


func _test_board_goals_do_not_replace_enemy_defeat() -> void:
	var board = BoardScript.new(3, 3)
	board.set_obstacles([{"row": 1, "col": 1, "type": "rock", "hp": 1}])
	var battle = _make_battle({"id": "break_rocks", "label": "break"}, board)
	board.damage_obstacle(1, 1)
	_expect(not battle.check_battle_end(board), "clearing rocks should not complete the stage while enemies are alive")
	battle.enemies[0]["hp"] = 0
	_expect(battle.check_battle_end(board), "defeating enemies should complete the stage even if a board goal was configured")
	battle.free()


func _test_regular_goal_still_requires_enemy_defeat() -> void:
	var board = BoardScript.new(3, 3)
	var battle = _make_battle({"id": "board_affinity", "label": "lesson"}, board)
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

extends SceneTree

const RewardRulesScript = preload("res://src/battle/reward_rules.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var db := StageDBScript.new()
	_test_stage_shape(db)
	_test_turn_budget_curve(db)
	_test_battle_manager_uses_stage_turns(db)
	_test_early_rewards(db)
	_finish()


func _test_stage_shape(db: StageDB) -> void:
	var chapters := db.get_chapters()
	_expect(chapters.size() == 11, "stage database should expose 11 chapters")
	for idx in range(chapters.size()):
		var chapter: Dictionary = chapters[idx]
		var chapter_num := idx + 1
		var stages: Array = chapter.get("stages", [])
		_expect(stages.size() == 12, "chapter_%d should expose 11 normal stages plus 1 boss" % chapter_num)
		if stages.size() >= 12:
			_expect(str(stages[11].get("id", "")) == "stage_%d_12" % chapter_num, "chapter_%d boss should be stage_%d_12" % [chapter_num, chapter_num])
			_expect(str(stages[11].get("type", "")) == "boss", "chapter_%d final stage should be boss" % chapter_num)


func _test_turn_budget_curve(db: StageDB) -> void:
	var normal_1_1 := db.get_stage("stage_1_1")
	var normal_1_11 := db.get_stage("stage_1_11")
	var normal_11_11 := db.get_stage("stage_11_11")
	var boss_1 := db.get_stage("stage_1_12")
	var boss_6 := db.get_stage("stage_6_12")
	var boss_10 := db.get_stage("stage_10_12")
	var boss_11 := db.get_stage("stage_11_12")

	_expect(int(normal_1_1.get("maxTurns", 0)) >= 16, "stage_1_1 should have a normal-stage turn budget")
	_expect(int(normal_1_11.get("maxTurns", 0)) > int(normal_1_1.get("maxTurns", 0)), "late normal stages in a chapter should allow a little more room")
	_expect(int(normal_11_11.get("maxTurns", 0)) > int(normal_1_11.get("maxTurns", 0)), "late chapters should allow more normal-stage mechanism room")
	_expect(int(boss_1.get("maxTurns", 0)) == 42, "chapter 1 boss should keep a real challenge window, not the old fixed 20")
	_expect(int(boss_6.get("maxTurns", 0)) == 87, "chapter 6 boss should use the base boss curve")
	_expect(int(boss_10.get("maxTurns", 0)) >= 180, "late bosses should give engaged players enough turns without lowering boss HP")
	_expect(int(boss_11.get("maxTurns", 0)) > int(boss_10.get("maxTurns", 0)), "final chapter boss should have the largest turn budget")

	var clean_team := [{"hp": 1, "maxHP": 10}, {"hp": 1, "maxHP": 10}, {"hp": 1, "maxHP": 10}]
	var two_dead_team := [{"hp": 1, "maxHP": 10}, {"hp": 0, "maxHP": 10}, {"hp": 0, "maxHP": 10}]
	_expect(RewardRulesScript.calc_battle_stars_for_team(clean_team) == 3, "clean late-boss clears should still be eligible for 3 stars")
	_expect(RewardRulesScript.calc_battle_stars_for_team(two_dead_team) == 1, "two deaths should lower battle mastery")


func _test_battle_manager_uses_stage_turns(db: StageDB) -> void:
	var boss := db.get_stage("stage_1_12")
	var battle := BattleManager.new()
	root.add_child(battle)
	battle.init(["monster_001"], boss.get("enemies", []), 1, int(boss.get("enemyLevel", 1)), boss, str(boss.get("id", "")))
	_expect(battle.max_turns == int(boss.get("maxTurns", 0)), "BattleManager should read maxTurns from stage data")
	battle.queue_free()


func _test_early_rewards(db: StageDB) -> void:
	var stage_1_1 := db.get_stage("stage_1_1")
	var stage_1_2 := db.get_stage("stage_1_2")
	var stage_1_11 := db.get_stage("stage_1_11")
	var boss_1 := db.get_stage("stage_1_12")
	var first_ball := RewardRulesScript.get_first_guaranteed_item(stage_1_1.get("rewards", {}))
	var second_ball := RewardRulesScript.get_first_guaranteed_item(stage_1_2.get("rewards", {}))
	var boss_item := RewardRulesScript.get_first_guaranteed_item(boss_1.get("rewards", {}))

	_expect(str(first_ball.get("id", "")) == "capture_ball", "first stage should seed one capture ball for early capture practice")
	_expect(str(second_ball.get("id", "")) == "capture_ball", "second stage should still teach capture with a visible ball")
	_expect(str(boss_item.get("id", "")) == "capture_ball_plus", "chapter 1 boss should keep the plus ball payoff")
	_expect(int(boss_1.get("rewards", {}).get("gold", 0)) > int(stage_1_11.get("rewards", {}).get("gold", 0)), "boss gold should be a visible chapter payoff")
	_expect(int(boss_1.get("rewards", {}).get("exp", 0)) > int(stage_1_11.get("rewards", {}).get("exp", 0)), "boss exp should be a visible chapter payoff")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BossTurnBudget] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[BossTurnBudget] " + failure)
		quit(1)

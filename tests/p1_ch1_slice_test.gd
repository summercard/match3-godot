extends SceneTree

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const ItemDBScript = preload("res://src/data/item_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_db := StageDBScript.new()
	var expected_lessons := {
		"stage_1_1": "board_affinity",
		"stage_1_2": "capture_window",
		"stage_1_3": "ward_skill",
		"stage_1_4": "tempo_skill",
		"stage_1_5": "boss_break"
	}
	for stage_id in expected_lessons.keys():
		var stage: Dictionary = stage_db.get_stage(stage_id)
		_expect(not stage.is_empty(), "%s should exist" % stage_id)
		_expect(stage.get("targetLesson", "") == expected_lessons[stage_id], "%s should expose target lesson" % stage_id)
		_expect(not str(stage.get("prepareHint", "")).is_empty(), "%s should have prepare hint" % stage_id)
		_expect(not str(stage.get("battleHint", "")).is_empty(), "%s should have battle hint" % stage_id)
		_expect(not str(stage.get("designGoal", "")).is_empty(), "%s should have design goal" % stage_id)

	var capture_stage: Dictionary = stage_db.get_stage("stage_1_2")
	var capture_items: Array = capture_stage.get("rewards", {}).get("guaranteedItems", [])
	_expect(capture_items.size() == 1, "stage_1_2 should guarantee a capture item")
	_expect(ItemDBScript.get_item(str(capture_items[0].get("id", ""))).get("type", "") == "capture", "stage_1_2 guaranteed item should be capture type")

	var boss_stage: Dictionary = stage_db.get_stage("stage_1_5")
	_expect(boss_stage.get("type", "") == "boss", "stage_1_5 should remain boss stage")
	_expect(boss_stage.get("phases", []).size() == 2, "stage_1_5 should keep two-phase boss structure")
	_expect(str(boss_stage.get("prepareHint", "")).contains("束缚"), "boss prepare hint should teach tempo counterplay")
	_expect(str(boss_stage.get("prepareHint", "")).contains("守护"), "boss prepare hint should teach ward counterplay")
	var boss_items: Array = boss_stage.get("rewards", {}).get("guaranteedItems", [])
	_expect(boss_items.size() == 1 and str(boss_items[0].get("id", "")) == "capture_ball_plus", "stage_1_5 should reward advanced capture ball")

	var battle = BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], [], 5, 3, boss_stage, "stage_1_5")
	_expect(battle.enemies.size() == 1, "boss battle should spawn phase 1 enemy")
	battle.enemies[0]["hp"] = int(battle.enemies[0].get("maxHP", 1) * 0.45)
	var phase_result: Dictionary = battle.process_match_result({}, 1)
	_expect(phase_result.get("phase_transition", {}).get("phase", 0) == 2, "boss should expose phase transition below half hp")
	battle.free()

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[P1Ch1Slice] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[P1Ch1Slice] " + failure)
		quit(1)

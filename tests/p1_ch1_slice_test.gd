extends SceneTree

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const ItemDBScript = preload("res://src/data/item_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_db := StageDBScript.new()
	var chapter: Dictionary = stage_db.get_chapter("chapter_1")
	var stages: Array = chapter.get("stages", [])
	_expect(stages.size() == 12, "chapter 1 should expose 12 main stages")
	for i in range(11):
		_expect(str(stages[i].get("id", "")) == "stage_1_%d" % (i + 1), "chapter 1 normal stage id should be sequential")
		_expect(str(stages[i].get("type", "")) == "normal", "chapter 1 stages 1-11 should be normal")
		_expect(not str(stages[i].get("prepareHint", "")).is_empty(), "normal stage should have prepare hint")
		_expect(not str(stages[i].get("battleHint", "")).is_empty(), "normal stage should have battle hint")
		_expect(not str(stages[i].get("designGoal", "")).is_empty(), "normal stage should have design goal")

	var capture_stage: Dictionary = stage_db.get_stage("stage_1_2")
	var capture_items: Array = capture_stage.get("rewards", {}).get("guaranteedItems", [])
	_expect(capture_items.size() == 1, "stage_1_2 should guarantee a capture item")
	_expect(ItemDBScript.get_item(str(capture_items[0].get("id", ""))).get("type", "") == "capture", "stage_1_2 guaranteed item should be capture type")

	var boss_stage: Dictionary = stage_db.get_stage("stage_1_12")
	_expect(boss_stage.get("type", "") == "boss", "stage_1_12 should be the chapter boss stage")
	_expect(boss_stage.get("targetLesson", "") == "boss_break", "stage_1_12 should expose boss lesson")
	_expect(boss_stage.get("phases", []).size() == 2, "stage_1_12 should keep two-phase boss structure")
	_expect(not str(boss_stage.get("prepareHint", "")).is_empty(), "boss prepare hint should teach counterplay")
	_expect(not str(boss_stage.get("battleHint", "")).is_empty(), "boss battle hint should teach counterplay")
	var boss_items: Array = boss_stage.get("rewards", {}).get("guaranteedItems", [])
	_expect(boss_items.size() == 1 and str(boss_items[0].get("id", "")) == "capture_ball_plus", "stage_1_12 should reward advanced capture ball")

	var battle = BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], [], 5, 3, boss_stage, "stage_1_12")
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

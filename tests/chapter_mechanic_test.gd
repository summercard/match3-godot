extends SceneTree

const SceneBattlePrepareScript = preload("res://src/ui/controllers/battle_prepare_logic.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_chapter_templates()
	_test_stage_goals()
	_test_boss_layers()
	_test_prepare_ui_reads_mechanic()
	_finish()


func _test_chapter_templates() -> void:
	var stage_db := StageDBScript.new()
	var chapters: Array = stage_db.get_chapters()
	_expect(chapters.size() >= 11, "chapter list should remain complete")
	for chapter: Dictionary in chapters:
		var mechanic: Dictionary = chapter.get("chapterMechanic", {})
		var stages: Array = chapter.get("stages", [])
		_expect(not mechanic.is_empty(), "%s should expose chapterMechanic" % chapter.get("id", "chapter"))
		_expect(not str(mechanic.get("name", "")).is_empty(), "%s should have mechanic name" % chapter.get("id", "chapter"))
		_expect(not str(mechanic.get("tagline", "")).is_empty(), "%s should have mechanic tagline" % chapter.get("id", "chapter"))
		_expect(stages.size() == 12, "%s should expose 12 stages" % chapter.get("id", "chapter"))
		for i in range(11):
			_expect(str((stages[i] as Dictionary).get("type", "")) == "normal", "stages 1-11 should be normal")
		_expect(str((stages[11] as Dictionary).get("type", "")) == "boss", "stage 12 should be boss")


func _test_stage_goals() -> void:
	var stage_db := StageDBScript.new()
	var rock_stage: Dictionary = stage_db.get_stage("stage_2_5")
	_expect(rock_stage.has("obstacles"), "chapter 2 mid stages should introduce rock pressure")
	_expect(rock_stage.get("stageGoal", {}).get("id", "") == "break_rocks", "rock pressure stage should expose break rocks goal")

	var fog_stage: Dictionary = stage_db.get_stage("stage_6_5")
	_expect(fog_stage.has("poisonFog"), "chapter 6 mid stages should introduce fog pressure")
	_expect(fog_stage.get("stageGoal", {}).get("id", "") == "fog_control", "poison fog stage should expose fog control goal")

	var old_elite: Dictionary = stage_db.get_stage("stage_2_4e")
	_expect(old_elite.is_empty(), "old elite branch ids should not be part of the 12-stage map")


func _test_boss_layers() -> void:
	var stage_db := StageDBScript.new()
	var boss_stage: Dictionary = stage_db.get_stage("stage_2_12")
	var layers: Array = boss_stage.get("bossLayers", [])
	_expect(layers.size() == 3, "boss stage should expose three boss layers")
	_expect(not str(layers[0].get("label", "")).is_empty(), "boss layer 1 should have a label")
	_expect(not str(layers[1].get("text", "")).is_empty(), "boss layer 2 should describe board pressure")
	_expect(not str(layers[2].get("text", "")).is_empty(), "boss layer 3 should describe break point")


func _test_prepare_ui_reads_mechanic() -> void:
	var stage_db := StageDBScript.new()
	var scene: Control = SceneBattlePrepareScript.new()
	root.add_child(scene)
	scene.init({
		"stageId": "stage_2_12",
		"stageData": stage_db.get_stage("stage_2_12")
	})
	var summary: String = scene.call("_get_stage_mechanic_summary")
	var hint: String = scene.call("_get_element_hint")
	_expect(not summary.is_empty(), "battle prepare should summarize chapter mechanic")
	_expect(hint.contains("Boss"), "battle prepare hint should include boss layer summary")
	scene.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ChapterMechanic] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[ChapterMechanic] " + failure)
		quit(1)

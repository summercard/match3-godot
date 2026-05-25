extends SceneTree

const ChapterMechanicRulesScript = preload("res://src/data/chapter_mechanic_rules.gd")
const SceneBattlePrepareScript = preload("res://src/ui/scene/scene_battle_prepare.gd")
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
		_expect(not mechanic.is_empty(), "%s should expose chapterMechanic" % chapter.get("id", "chapter"))
		_expect(not str(mechanic.get("name", "")).is_empty(), "%s should have mechanic name" % chapter.get("id", "chapter"))
		_expect(not str(mechanic.get("tagline", "")).is_empty(), "%s should have mechanic tagline" % chapter.get("id", "chapter"))


func _test_stage_goals() -> void:
	var stage_db := StageDBScript.new()
	var rock_stage: Dictionary = stage_db.get_stage("stage_2_4e")
	var goal: Dictionary = rock_stage.get("stageGoal", {})
	_expect(goal.get("id", "") == "elite_pressure", "elite stage should use elite pressure goal")
	_expect(str(goal.get("tip", "")).contains("岩障") or str(goal.get("tip", "")).contains("压力"), "elite goal should explain pressure")

	var fog_stage: Dictionary = stage_db.get_stage("stage_6_3")
	_expect(fog_stage.get("stageGoal", {}).get("id", "") == "fog_control", "poison fog stage should expose fog control goal")


func _test_boss_layers() -> void:
	var stage_db := StageDBScript.new()
	var boss_stage: Dictionary = stage_db.get_stage("stage_2_5")
	var layers: Array = boss_stage.get("bossLayers", [])
	_expect(layers.size() == 3, "boss stage should expose three boss layers")
	_expect(str(layers[0].get("label", "")) == "主节奏", "boss layer 1 should be rhythm")
	_expect(str(layers[1].get("text", "")).contains("岩障"), "chapter 2 boss should mention rock board pressure")
	_expect(str(layers[2].get("text", "")).contains("破盾"), "chapter 2 boss should mention shield break")


func _test_prepare_ui_reads_mechanic() -> void:
	var stage_db := StageDBScript.new()
	var scene: Control = SceneBattlePrepareScript.new()
	root.add_child(scene)
	scene.init({
		"stageId": "stage_2_5",
		"stageData": stage_db.get_stage("stage_2_5")
	})
	var summary: String = scene.call("_get_stage_mechanic_summary")
	var hint: String = scene.call("_get_element_hint")
	_expect(summary.contains("岩障开路"), "battle prepare should summarize chapter mechanic")
	_expect(hint.contains("Boss："), "battle prepare hint should include boss layer summary")
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

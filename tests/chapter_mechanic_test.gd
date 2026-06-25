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
	var fountain_stage: Dictionary = stage_db.get_stage("stage_2_5")
	_expect(fountain_stage.has("fountains"), "chapter 2 mid stages should introduce fountain pressure")
	_expect(not fountain_stage.has("obstacles"), "chapter 2 should no longer use the old rock pressure")
	_expect(fountain_stage.get("stageGoal", {}).get("id", "") == "defeat_enemies", "fountain pressure stages should still use enemy defeat as the win goal")

	var vine_stage: Dictionary = stage_db.get_stage("stage_3_5")
	_expect(vine_stage.has("vines"), "chapter 3 mid stages should introduce vine pressure")
	_expect(vine_stage.get("stageGoal", {}).get("id", "") == "defeat_enemies", "vine pressure stages should still use enemy defeat as the win goal")

	var tide_stage: Dictionary = stage_db.get_stage("stage_4_5")
	_expect(tide_stage.has("tideRule"), "chapter 4 mid stages should introduce tide pressure")
	_expect(not tide_stage.has("obstacles"), "chapter 4 tide stages should not inherit the old rock pressure")
	_expect(not tide_stage.has("lockedGems"), "chapter 4 should not introduce locked-gem pressure while teaching tide")
	_expect(tide_stage.get("stageGoal", {}).get("id", "") == "defeat_enemies", "tide pressure stages should still use enemy defeat as the win goal")

	var fog_stage: Dictionary = stage_db.get_stage("stage_6_5")
	_expect(fog_stage.has("poisonFog"), "chapter 6 mid stages should introduce fog pressure")
	_expect(fog_stage.get("stageGoal", {}).get("id", "") == "defeat_enemies", "poison fog stages should still use enemy defeat as the win goal")

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
	var boss_stage: Dictionary = stage_db.get_stage("stage_2_12")
	var scene: Control = SceneBattlePrepareScript.new()
	root.add_child(scene)
	scene.init({
		"stageId": "stage_2_12",
		"stageData": boss_stage
	})
	var summary: String = scene.call("_get_stage_mechanic_summary")
	var hint: String = scene.call("_get_element_hint")
	_expect(not summary.is_empty(), "battle prepare should summarize chapter mechanic")
	_expect(hint.contains("Boss"), "battle prepare hint should include boss layer summary")
	var phase_enemies: Array = (boss_stage.get("phases", [])[0] as Dictionary).get("enemies", [])
	var preview_enemy_ids: Array = scene.call("_get_preview_enemy_ids", boss_stage)
	var enemy_team: Array = scene.get("_enemy_team")
	_expect(preview_enemy_ids == phase_enemies, "battle prepare boss preview should use phase 1 enemies")
	_expect(not enemy_team.is_empty() and str((enemy_team[0] as Dictionary).get("id", "")) == str(phase_enemies[0]), "battle prepare displayed boss should match battle phase 1 enemy")
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

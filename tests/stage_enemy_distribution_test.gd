extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var db := StageDB.new()
	var non_boss_owners: Dictionary = {}
	var boss_owners: Dictionary = {}
	for raw_chapter: Dictionary in StageDB.STAGES_DATA.get("chapters", []):
		var chapter: Dictionary = db._expanded_chapter(raw_chapter)
		var chapter_id := str(chapter.get("id", ""))
		for stage: Dictionary in chapter.get("stages", []):
			var enemy_ids := _stage_enemy_ids(stage)
			for enemy_id in enemy_ids:
				if enemy_id.begins_with("monster_boss_"):
					if not boss_owners.has(enemy_id):
						boss_owners[enemy_id] = {}
					boss_owners[enemy_id][chapter_id] = true
				elif enemy_id.begins_with("enemy_"):
					if not non_boss_owners.has(enemy_id):
						non_boss_owners[enemy_id] = {}
					non_boss_owners[enemy_id][chapter_id] = true

	for enemy_id in non_boss_owners.keys():
		var chapters: Array = non_boss_owners[enemy_id].keys()
		_expect(chapters.size() == 1, "%s should belong to one map only, got %s" % [enemy_id, ", ".join(chapters)])

	for boss_id in boss_owners.keys():
		var chapters: Array = boss_owners[boss_id].keys()
		_expect(chapters.size() == 1, "%s boss should be exclusive to one map, got %s" % [boss_id, ", ".join(chapters)])
		var expected_chapter := "chapter_%d" % int(boss_id.get_slice("_", 2))
		_expect(chapters[0] == expected_chapter, "%s should only appear in %s, got %s" % [boss_id, expected_chapter, chapters[0]])

	_finish()


func _stage_enemy_ids(stage: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if stage.has("phases"):
		for phase: Dictionary in stage.get("phases", []):
			for enemy_id in phase.get("enemies", []):
				var id := str(enemy_id)
				if not id.is_empty() and not result.has(id):
					result.append(id)
		return result
	for enemy_id in stage.get("enemies", []):
		var id := str(enemy_id)
		if not id.is_empty() and not result.has(id):
			result.append(id)
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[StageEnemyDistribution] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[StageEnemyDistribution] " + failure)
	quit(1)

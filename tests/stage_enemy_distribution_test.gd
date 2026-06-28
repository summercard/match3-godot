extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var db := StageDB.new()
	for raw_chapter: Dictionary in StageDB.STAGES_DATA.get("chapters", []):
		var chapter: Dictionary = db._expanded_chapter(raw_chapter)
		var chapter_num := _chapter_number(chapter)
		var expected_pool: Array = StageDB.CHAPTER_ENEMY_POOLS.get(chapter_num, [])
		if expected_pool.is_empty() and chapter_num > 8:
			expected_pool = StageDB.CHAPTER_ENEMY_POOLS.get(8, [])
		var expected_boss := str(StageDB.CHAPTER_BOSS_IDS.get(chapter_num, ""))
		if expected_boss.is_empty() and chapter_num > 8:
			expected_boss = str(StageDB.CHAPTER_BOSS_IDS.get(8, ""))

		for stage: Dictionary in chapter.get("stages", []):
			var enemy_ids := _stage_enemy_ids(stage)
			for enemy_id in enemy_ids:
				var data: Dictionary = MonsterDb.MONSTER_DB.get(enemy_id, {})
				_expect(not data.is_empty(), "%s should exist in MonsterDb" % enemy_id)
				if enemy_id.begins_with("monster_boss_"):
					_expect(enemy_id == expected_boss, "%s should use chapter boss %s" % [str(stage.get("id", "")), expected_boss])
				else:
					_expect(enemy_id.begins_with("monster_"), "%s should use unified monster_* ids" % enemy_id)
					_expect(expected_pool.has(enemy_id), "%s should belong to chapter %d pool" % [enemy_id, chapter_num])
					_expect(int(data.get("rarity", 0)) <= 2, "%s should not be a direct 3-star stage spawn" % enemy_id)

	_finish()


func _chapter_number(chapter: Dictionary) -> int:
	var chapter_id := str(chapter.get("id", "chapter_1"))
	return int(chapter_id.get_slice("_", 1))


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

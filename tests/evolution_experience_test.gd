extends SceneTree

const EvolutionRulesScript = preload("res://src/core/evolution_rules.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		_finish()
		return

	save_manager.clear_all_data()
	var starter_id := "monster_002"
	var starter_data: Dictionary = MonsterDb.get_monster(starter_id)
	var evolution: Dictionary = starter_data.get("evolution", {})
	var target_id := str(evolution.get("target", ""))
	var starter: Dictionary = save_manager.add_monster_instance(starter_id, {
		"level": int(evolution.get("level", 1)),
		"nature": "brave",
		"source": "test",
		"evolutionInsight": {"label": "测试启发", "score": 80, "tags": ["默契"]}
	})
	var starter_instance_id := str(starter.get("instanceId", ""))
	var before: Dictionary = save_manager.get_monster_instance(starter_instance_id)
	var insight: Dictionary = before.get("evolutionInsight", {})
	_expect(not target_id.is_empty(), "current starter should provide an evolution target")
	_expect(not insight.is_empty(), "test instance should carry evolution insight")
	var preview := EvolutionRulesScript.build_preview(before)
	_expect(str(preview.get("social_text", "")).contains("社交启发"), "preview should show social insight")
	_expect(str(preview.get("play_upgrade", "")).length() > 0, "preview should show play upgrade")

	var result: Dictionary = save_manager.evolve_instance(starter_instance_id)
	_expect(bool(result.get("ok", false)), "eligible monster should evolve")
	_expect(not result.get("evolutionReport", {}).is_empty(), "evolution should return report")
	var after: Dictionary = save_manager.get_monster_instance(starter_instance_id)
	_expect(str(after.get("monsterId", "")) == target_id, "evolution should update monster id")
	_expect(after.get("evolutionInsight", {}).is_empty(), "evolution should consume insight")
	_expect(int(after.get("evolutionCount", 0)) == 1, "evolution should increment count")
	_expect((after.get("evolutionHistory", []) as Array).size() == 1, "evolution should record history")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EvolutionExperience] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[EvolutionExperience] " + failure)
		quit(1)

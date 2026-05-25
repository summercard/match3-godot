extends SceneTree

const EvolutionRulesScript = preload("res://src/core/evolution_rules.gd")
const SocialRulesScript = preload("res://src/core/social_rules.gd")

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
	var fire: Dictionary = save_manager.add_monster_instance("monster_001", {
		"level": 16,
		"nature": "brave",
		"gender": "male",
		"source": "test"
	})
	var water: Dictionary = save_manager.add_monster_instance("monster_002", {
		"level": 16,
		"nature": "calm",
		"gender": "female",
		"source": "test"
	})
	var fire_id := str(fire.get("instanceId", ""))
	var water_id := str(water.get("instanceId", ""))

	_expect(save_manager.assign_social_slot(0, "slot_a", fire_id), "should assign first social slot")
	_expect(save_manager.assign_social_slot(0, "slot_b", water_id), "should assign second social slot")
	_expect(bool(save_manager.start_social(0).get("ok", false)), "should start social")
	var ranch: Dictionary = save_manager.get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	places[0]["started_at"] = Time.get_unix_time_from_system() * 1000.0 - SocialRulesScript.DURATION_MS - 1000.0
	ranch["social_places"] = places
	save_manager.set_ranch_state(ranch)
	var social: Dictionary = save_manager.collect_social(0)
	_expect(bool(social.get("ok", false)), "ready social should collect")

	var before: Dictionary = save_manager.get_monster_instance(fire_id)
	var insight: Dictionary = before.get("evolutionInsight", {})
	_expect(not insight.is_empty(), "social should create evolution insight")
	var preview := EvolutionRulesScript.build_preview(before)
	_expect(str(preview.get("social_text", "")).contains("社交启发"), "preview should show social insight")
	_expect(str(preview.get("play_upgrade", "")).length() > 0, "preview should show play upgrade")

	var result: Dictionary = save_manager.evolve_instance(fire_id)
	_expect(bool(result.get("ok", false)), "eligible monster should evolve")
	_expect(not result.get("evolutionReport", {}).is_empty(), "evolution should return report")
	var after: Dictionary = save_manager.get_monster_instance(fire_id)
	_expect(str(after.get("monsterId", "")) == "monster_006", "evolution should update monster id")
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

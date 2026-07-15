extends SceneTree

const FeatureUnlockRulesScript = preload("res://src/core/feature_unlock_rules.gd")
const SocialRulesScript = preload("res://src/core/social_rules.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist")
	if storage == null:
		_finish()
		return

	_expect(storage.reset_to_initial_state(), "initial-state reset should save")
	var player: Dictionary = storage.get_player()
	_expect(int(player.get("level", 0)) == 1, "fresh profile should begin at level 1")
	_expect(int(player.get("exp", -1)) == 0, "fresh profile should begin with no player experience")
	_expect(int(player.get("gold", -1)) == 0 and int(player.get("gems", -1)) == 0, "fresh profile should reset currencies")
	_expect(int(player.get("stamina", 0)) == 5, "fresh profile should reset stamina")

	var starters: Array = MonsterPool.DEFAULT_STARTERS
	var owned_species: Array = storage.get_owned_species_ids()
	_expect(owned_species.size() == starters.size(), "only the starter species should unlock the fresh album")
	var starter_natures := {}
	for starter_id: String in starters:
		_expect(owned_species.has(starter_id), "starter species should unlock the album: %s" % starter_id)
		var starter := MonsterPool.get_first_instance_by_monster_id(storage.get_monster_pool(), starter_id)
		var nature_id := str(starter.get("nature", ""))
		_expect(nature_id == MonsterPool.starter_nature(starter_id), "%s should use its deterministic starter nature" % starter_id)
		starter_natures[nature_id] = true
	_expect(starter_natures.size() == starters.size(), "starter natures must be mutually distinct")
	var expected_pattern := _starter_nature_pattern(storage, starters)
	for _reset_index in range(2):
		_expect(storage.reset_to_initial_state(), "repeat initial-state reset should save")
		_expect(_starter_nature_pattern(storage, starters) == expected_pattern, "starter nature pattern should remain stable across fresh saves")
	var starter_a: Dictionary = MonsterPool.get_first_instance_by_monster_id(storage.get_monster_pool(), str(starters[0]))
	var starter_b: Dictionary = MonsterPool.get_first_instance_by_monster_id(storage.get_monster_pool(), str(starters[1]))
	var first_social: Dictionary = SocialRulesScript.preview(starter_a, starter_b, {"place_id": "meadow_yard"})
	_expect(not (first_social.get("event", {}) as Dictionary).is_empty(), "two starters should produce a visible first social event")
	_expect(not str(first_social.get("relation_label", "")).is_empty(), "first starter social should expose a relationship result")
	var acquired: Dictionary = storage.add_monster_instance("monster_001", {"source": "test_capture"})
	_expect(not acquired.is_empty() and storage.get_owned_species_ids().has("monster_001"), "a captured species should unlock in the album")

	var settings: Dictionary = storage.load_settings()
	_expect(bool(settings.get("soundOn", false)) and bool(settings.get("musicOn", false)) and bool(settings.get("vibrationOn", false)), "fresh settings should enable audio and vibration")
	_expect(str(settings.get("qualityLevel", "")) == "high" and str(settings.get("performanceMode", "")) == "balanced", "fresh settings should use the configured defaults")

	_expect(not bool(storage.get_feature_unlock_state("ranch").get("unlocked", true)), "farm should be locked below level 10")
	_expect(bool(storage.get_feature_unlock_state("classroom").get("unlocked", false)), "classroom should be available from the start")
	_expect(not bool(storage.get_feature_unlock_state("social").get("unlocked", true)), "social plaza should be locked below level 25")
	_expect(bool(FeatureUnlockRulesScript.get_unlock_state("ranch", 10).get("unlocked", false)), "farm should unlock at level 10")
	_expect(not bool(FeatureUnlockRulesScript.get_unlock_state("social", 24).get("unlocked", true)), "social plaza should remain locked at level 24")
	_expect(bool(FeatureUnlockRulesScript.get_unlock_state("social", 25).get("unlocked", false)), "social plaza should unlock at level 25")

	await _expect_ranch_page_guard(storage)
	_finish()


func _expect_ranch_page_guard(storage: Node) -> void:
	var ranch_scene := load("res://src/ui/scenes/ranch_hub.tscn").instantiate() as Control
	root.add_child(ranch_scene)
	await process_frame

	ranch_scene.call("init", {"page": "ranch"})
	_expect(str(ranch_scene.get("_active_page")) == "classroom", "locked farm route should fall back to classroom")
	ranch_scene.call("init", {"page": "social"})
	_expect(str(ranch_scene.get("_active_page")) == "classroom", "locked social route should fall back to classroom")
	var player: Dictionary = storage.get_player()
	player["level"] = 10
	storage.save_player(player)
	ranch_scene.call("init", {"page": "ranch"})
	_expect(str(ranch_scene.get("_active_page")) == "ranch", "farm route should open at level 10")
	player["level"] = 25
	storage.save_player(player)
	ranch_scene.call("init", {"page": "social"})
	_expect(str(ranch_scene.get("_active_page")) == "social", "social route should open at level 25")
	ranch_scene.queue_free()
	await process_frame


func _starter_nature_pattern(storage: Node, starters: Array) -> Array[String]:
	var pattern: Array[String] = []
	for starter_id: String in starters:
		var instance: Dictionary = MonsterPool.get_first_instance_by_monster_id(storage.get_monster_pool(), starter_id)
		pattern.append(str(instance.get("nature", "")))
	return pattern


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[InitialStateAndFeatureUnlock] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[InitialStateAndFeatureUnlock] " + failure)
	quit(1)

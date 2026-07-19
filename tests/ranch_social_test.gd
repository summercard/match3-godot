extends SceneTree

const SocialRulesScript = preload("res://src/core/social_rules.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_social_rules_132()
	_test_ranch_social_exclusivity()
	_test_social_state_normalizes_after_load()
	_test_social_ui_reload_switch_and_start()
	_test_save_manager_trait_learning_flow()
	_finish()


func _test_social_rules_132() -> void:
	var a := {"instanceId": "test_a", "monsterId": "monster_001", "nature": "brave"}
	var b := {"instanceId": "test_b", "monsterId": "monster_002", "nature": "cautious"}
	var chances: Array[int] = []
	for place_id in SocialRulesScript.PLACE_ORDER:
		var place := SocialRulesScript.normalize_place({"place_id": place_id})
		var config := SocialRulesScript.place_config_for(place)
		var preview: Dictionary = SocialRulesScript.preview(a, b, place)
		chances.append(int(preview.get("success_percent", -1)))
		_expect(SocialRulesScript.duration_ms_for_place(place) == 60.0 * 60.0 * 1000.0, "%s should use the shared one-hour duration" % place_id)
		_expect(str(SocialRulesScript.duration_label_for_place(place)) == "1小时", "%s should show the one-hour duration" % place_id)
		_expect(not str(config.get("summary", "")).is_empty(), "%s should explain its trait preference" % place_id)
		_expect(float(preview.get("success_chance", 0.0)) >= 0.05 and float(preview.get("success_chance", 0.0)) <= float(config.get("chanceCap", 0.0)), "%s probability should stay in its cap" % place_id)
		for removed_key in ["relation_level", "relation_label", "event", "majorOutcome", "gold", "items", "exp"]:
			_expect(not preview.has(removed_key), "1.3.2 social result should not expose legacy %s" % removed_key)
	_expect(SocialRulesScript.get_event_catalog().size() == 3, "social should expose exactly the three 1.3.2 venues")
	var unique_chances := {}
	for chance in chances:
		unique_chances[chance] = true
	_expect(unique_chances.size() >= 2, "venue preferences should materially change trait-learning probability")
	var normalized := SocialRulesScript.normalize_place({"placeId": "quiet_pond", "slotA": "a", "slotB": "b", "startedAt": 1000})
	_expect(str(normalized.get("place_id", "")) == "quiet_pond", "legacy camel-case place data should remain loadable")
	_expect(SocialRulesScript.personality_traits({"nature": "brave", "learnedNatures": ["gentle", "wise", "calm"]}).size() == 3, "personality storage should cap at three traits")


func _test_ranch_social_exclusivity() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist for ranch social exclusivity")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var player: Dictionary = save_manager.get_player()
	player["level"] = 25
	save_manager.save_player(player)
	var owned: Array = save_manager.get_owned_monsters()
	if owned.size() < 2:
		_expect(false, "default save should have two monsters for ranch social exclusivity")
		return
	var ranch_id := str(owned[0].get("instanceId", ""))
	var social_id := str(owned[1].get("instanceId", ""))
	_expect(save_manager.place_instance_in_ranch(ranch_id, 0), "test monster should enter ranch")
	_expect(not save_manager.assign_social_slot(0, "slot_a", ranch_id), "ranch monster should not enter social")
	_expect(save_manager.assign_social_slot(0, "slot_a", social_id), "non-ranch monster should enter social")
	_expect(not save_manager.place_instance_in_ranch(social_id, 1), "social monster should not enter ranch")


func _test_social_state_normalizes_after_load() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var owned: Array = save_manager.get_owned_monsters()
	if owned.size() < 2:
		_expect(false, "default save should have two monsters for social normalization")
		return
	var first_id := str(owned[0].get("instanceId", ""))
	var first_monster_id := str(owned[0].get("monsterId", ""))
	var now_ms := Time.get_unix_time_from_system() * 1000.0
	save_manager.set_ranch_state({
		"slots": [], "unlockedSlots": 5,
		"socialPlaces": [{"placeId": "quiet_pond", "slotA": first_monster_id, "slotB": first_monster_id, "startedAt": now_ms}]
	})
	var normalized: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(str(normalized.get("place_id", "")) == "quiet_pond", "legacy venue id should normalize after load")
	_expect(str(normalized.get("slot_a", "")) == first_id, "legacy monster id should resolve to instance id")
	_expect(normalized.get("slot_b", null) == null, "one monster must not occupy both social slots")
	_expect(normalized.get("started_at", null) == null, "invalid legacy pairing should cancel its timer")


func _test_social_ui_reload_switch_and_start() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var player: Dictionary = save_manager.get_player()
	player["level"] = 25
	save_manager.save_player(player)
	var owned: Array = save_manager.get_owned_monsters()
	if owned.size() < 2:
		_expect(false, "default save should have two monsters for social UI")
		return
	var a_id := str(owned[0].get("instanceId", ""))
	var b_id := str(owned[1].get("instanceId", ""))
	_expect(save_manager.assign_social_slot(0, "slot_a", a_id), "UI flow should assign slot A")
	_expect(save_manager.assign_social_slot(0, "slot_b", b_id), "UI flow should assign slot B")
	_expect(save_manager.cycle_social_place(0), "UI flow should switch venue")
	var ranch: Control = load("res://src/ui/controllers/ranch_logic.gd").new()
	root.add_child(ranch)
	ranch.call("init", {})
	ranch.call("_switch_to_social")
	_expect(str(ranch.call("_current_social_place").get("place_id", "")) == "sunny_yard", "social page should load the saved venue")
	ranch.call("_try_social_action")
	_expect(ranch.call("_current_social_place").get("started_at", null) != null, "start button should begin the one-hour timer")
	ranch.call("_select_or_clear_social_slot", "slot_a")
	_expect(str(ranch.call("_current_social_place").get("slot_a", "")) == a_id, "running social should lock its selected pair")
	ranch.queue_free()


func _test_save_manager_trait_learning_flow() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var owned: Array = save_manager.get_owned_monsters()
	if owned.size() < 2:
		_expect(false, "default save should have two monsters for trait learning")
		return
	var a_id := str(owned[0].get("instanceId", ""))
	var b_id := str(owned[1].get("instanceId", ""))
	# A stable interaction index guarantees this test exercises a successful learn.
	var successful_interaction := -1
	for interaction in range(100):
		var trial_place := SocialRulesScript.normalize_place({"place_id": "meadow_yard", "slot_a": a_id, "slot_b": b_id, "interaction_count": interaction})
		if not (SocialRulesScript.resolve(owned[0], owned[1], trial_place).get("learned_natures", []) as Array).is_empty():
			successful_interaction = interaction
			break
	_expect(successful_interaction >= 0, "stable social rolls should include a learnable interaction")
	if successful_interaction < 0:
		return
	var ranch_state: Dictionary = save_manager.get_ranch_state()
	var places: Array = ranch_state.get("social_places", [])
	places[0]["interaction_count"] = successful_interaction
	ranch_state["social_places"] = places
	save_manager.set_ranch_state(ranch_state)
	save_manager.update_monster_instance(a_id, {"socialProfile": {"socialExp": 7}, "bondMemory": {"partners": {"legacy_partner": {"count": 2}}}})
	_expect(save_manager.assign_social_slot(0, "slot_a", a_id), "trait flow should assign first learner")
	_expect(save_manager.assign_social_slot(0, "slot_b", b_id), "trait flow should assign second learner")
	_expect(bool(save_manager.start_social(0).get("ok", false)), "trait flow should start")
	_force_social_ready(save_manager)
	var before_gold := int(save_manager.get_player().get("gold", 0))
	var before_count: int = save_manager.get_owned_monsters().size()
	var collect: Dictionary = save_manager.collect_social(0)
	_expect(bool(collect.get("ok", false)), "ready one-hour social should collect")
	var result: Dictionary = collect.get("result", {})
	_expect(not (result.get("learned_natures", []) as Array).is_empty(), "successful result should learn exactly a missing trait")
	_expect(not result.has("majorOutcome") and not result.has("relation_level") and not result.has("gold"), "collected result should contain no removed social systems")
	_expect(int(save_manager.get_player().get("gold", 0)) == before_gold, "social should not grant currency")
	_expect(save_manager.get_owned_monsters().size() == before_count, "social should not create or consume monsters")
	var a_after: Dictionary = save_manager.get_monster_instance(a_id)
	var b_after: Dictionary = save_manager.get_monster_instance(b_id)
	_expect(SocialRulesScript.personality_traits(a_after).size() <= 3 and SocialRulesScript.personality_traits(b_after).size() <= 3, "learned trait storage should respect capacity")
	_expect(int(a_after.get("socialProfile", {}).get("socialExp", 0)) == 7, "old social profile data should remain load-compatible but unchanged")
	_expect((a_after.get("bondMemory", {}).get("partners", {}) as Dictionary).has("legacy_partner"), "old bond memory should remain load-compatible but unchanged")
	var finished_place: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(finished_place.get("started_at", null) == null, "collecting should reset the timer")
	_expect(not (finished_place.get("last_result", {}) as Dictionary).is_empty(), "collecting should retain the learning result")


func _force_social_ready(save_manager: Node) -> void:
	var ranch: Dictionary = save_manager.get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	places[0]["started_at"] = Time.get_unix_time_from_system() * 1000.0 - SocialRulesScript.DURATION_MS - 1000.0
	ranch["social_places"] = places
	save_manager.set_ranch_state(ranch)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RanchSocial] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[RanchSocial] " + failure)
	quit(1)

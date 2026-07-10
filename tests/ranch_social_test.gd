extends SceneTree

const SocialRulesScript = preload("res://src/core/social_rules.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_social_rules()
	_test_ranch_social_exclusivity()
	_test_social_state_normalizes_after_load()
	_test_social_ui_reload_switch_and_start()
	_test_save_manager_social_flow()
	_test_social_birth_major_outcome()
	_test_social_erosion_is_protected()
	_finish()

func _test_ranch_social_exclusivity() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist for ranch social exclusivity")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var owned: Array = save_manager.get_owned_monsters()
	_expect(owned.size() >= 2, "default save should have two monsters for ranch social exclusivity")
	if owned.size() < 2:
		return
	var ranch_id := str(owned[0].get("instanceId", ""))
	var social_id := str(owned[1].get("instanceId", ""))
	_expect(save_manager.place_instance_in_ranch(ranch_id, 0), "test monster should enter ranch")
	_expect(save_manager.is_instance_in_ranch(ranch_id), "ranch occupancy helper should report placed monster")
	_expect(not save_manager.assign_social_slot(0, "slot_a", ranch_id), "ranch monster should not enter social")
	_expect(save_manager.assign_social_slot(0, "slot_a", social_id), "non-ranch monster should enter social")
	_expect(not save_manager.place_instance_in_ranch(social_id, 1), "social monster should not enter ranch")

	var ranch: Dictionary = save_manager.get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	places[0]["slot_b"] = ranch_id
	places[0]["started_at"] = Time.get_unix_time_from_system() * 1000.0
	ranch["social_places"] = places
	save_manager.set_ranch_state(ranch)
	var normalized_place: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(normalized_place.get("slot_b", null) == null, "legacy overlap should remove ranch monster from social slot")
	_expect(normalized_place.get("started_at", null) == null, "legacy overlap cleanup should cancel invalid social timer")


func _test_social_state_normalizes_after_load() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist for social load normalization")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var owned: Array = save_manager.get_owned_monsters()
	_expect(owned.size() >= 3, "default save should have three monsters for social load normalization")
	if owned.size() < 3:
		return
	var first_instance_id := str(owned[0].get("instanceId", ""))
	var first_monster_id := str(owned[0].get("monsterId", ""))
	var second_instance_id := str(owned[1].get("instanceId", ""))
	var third_instance_id := str(owned[2].get("instanceId", ""))
	var now_ms := Time.get_unix_time_from_system() * 1000.0

	save_manager.set_ranch_state({
		"slots": [],
		"unlockedSlots": 5,
		"socialPlaces": [{
			"placeId": "quiet_pond",
			"slotA": first_monster_id,
			"slotB": first_monster_id,
			"startedAt": now_ms
		}]
	})
	var duplicate_place: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(str(duplicate_place.get("place_id", "")) == "quiet_pond", "legacy social place id should normalize after load")
	_expect(str(duplicate_place.get("slot_a", "")) == first_instance_id, "legacy monster id should resolve to instance id in social slot")
	_expect(duplicate_place.get("slot_b", null) == null, "same monster should not occupy both social slots after load")
	_expect(duplicate_place.get("started_at", null) == null, "duplicate social slot cleanup should cancel timer")

	save_manager.set_ranch_state({
		"slots": [],
		"unlocked_slots": 5,
		"social_places": [{
			"place_id": "sunny_yard",
			"slot_a": second_instance_id,
			"slot_b": "missing_instance",
			"started_at": now_ms
		}]
	})
	var missing_place: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(str(missing_place.get("slot_a", "")) == second_instance_id, "valid social slot should survive missing partner cleanup")
	_expect(missing_place.get("slot_b", null) == null, "missing social partner should be removed after load")
	_expect(missing_place.get("started_at", null) == null, "missing social partner cleanup should cancel timer")

	save_manager.set_ranch_state({
		"slots": [],
		"unlocked_slots": 5,
		"social_places": [{
			"place_id": "meadow_yard",
			"slot_a": second_instance_id,
			"slot_b": third_instance_id,
			"started_at": now_ms
		}]
	})
	_expect(save_manager.remove_monster_instance(third_instance_id), "removing a monster should succeed for social cleanup")
	var after_remove: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(str(after_remove.get("slot_a", "")) == second_instance_id, "removing social partner should keep the remaining partner")
	_expect(after_remove.get("slot_b", null) == null, "removed monster should be cleared from social slot")
	_expect(after_remove.get("started_at", null) == null, "removing social partner should cancel social timer")


func _test_social_ui_reload_switch_and_start() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist for social UI reload")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var owned: Array = save_manager.get_owned_monsters()
	_expect(owned.size() >= 2, "default save should have two monsters for social UI reload")
	if owned.size() < 2:
		return
	var a_id := str(owned[0].get("instanceId", ""))
	var b_id := str(owned[1].get("instanceId", ""))
	_expect(save_manager.assign_social_slot(0, "slot_a", a_id), "UI reload test should assign slot A")
	_expect(save_manager.assign_social_slot(0, "slot_b", b_id), "UI reload test should assign slot B")
	_expect(save_manager.cycle_social_place(0), "UI reload test should switch to sunny yard")

	var ranch: Control = load("res://src/ui/controllers/ranch_logic.gd").new()
	root.add_child(ranch)
	ranch.call("init", {})
	ranch.call("_switch_to_social")
	var loaded_place: Dictionary = ranch.call("_current_social_place")
	_expect(str(loaded_place.get("place_id", "")) == "sunny_yard", "social page should load saved place when opened")

	_expect(save_manager.cycle_social_place(0), "external save change should switch to quiet pond")
	ranch.call("_switch_to_classroom")
	ranch.call("_switch_to_social")
	var reloaded_place: Dictionary = ranch.call("_current_social_place")
	_expect(str(reloaded_place.get("place_id", "")) == "quiet_pond", "reopening social page should reload saved place")

	ranch.call("_cycle_social_place")
	var switched_place: Dictionary = ranch.call("_current_social_place")
	_expect(str(switched_place.get("place_id", "")) == "meadow_yard", "place switch button should update local state after reload")
	_expect(str(save_manager.get_ranch_state().get("social_places", [])[0].get("place_id", "")) == "meadow_yard", "place switch button should persist after reload")

	ranch.call("_try_social_action")
	var started_place: Dictionary = ranch.call("_current_social_place")
	_expect(started_place.get("started_at", null) != null, "start button should update local started_at after reload")
	ranch.call("_select_or_clear_social_slot", "slot_a")
	var locked_place: Dictionary = ranch.call("_current_social_place")
	_expect(str(locked_place.get("slot_a", "")) == a_id, "running social should not clear slot after reload")

	var unlocked_state: Dictionary = save_manager.get_ranch_state()
	var places: Array = unlocked_state.get("social_places", [])
	places[0]["started_at"] = null
	unlocked_state["social_places"] = places
	save_manager.set_ranch_state(unlocked_state)
	ranch.call("_switch_to_social")
	ranch.call("_select_or_clear_social_slot", "slot_a")
	var cleared_place: Dictionary = ranch.call("_current_social_place")
	_expect(cleared_place.get("slot_a", null) == null, "clear slot toggle should work after reloading an idle social place")
	ranch.queue_free()


func _test_social_rules() -> void:
	var a := {
		"instanceId": "test_a",
		"monsterId": "monster_001",
		"nature": "brave",
		"gender": "male"
	}
	var b := {
		"instanceId": "test_b",
		"monsterId": "monster_002",
		"nature": "cautious",
		"gender": "female"
	}
	var place := SocialRulesScript.normalize_place({"place_id": "sunny_yard"})
	var result: Dictionary = SocialRulesScript.preview(a, b, place)
	var sunny_events: Array = SocialRulesScript.get_event_catalog("sunny_yard")
	_expect(sunny_events.size() >= 4, "sunny yard should have a meaningful event content pool")
	_expect(int(result.get("score", 0)) >= 80, "same element and complementary nature should score high")
	_expect(str(result.get("gender_pair", "")).contains("雄性"), "result should expose gender pair")
	_expect(result.get("tags", []).has("异性互补"), "different genders should affect social tags")
	_expect(result.get("tags", []).has("同属性共鸣"), "same element should affect social tags")
	_expect(str(result.get("place_id", "")) == "sunny_yard", "result should expose social place")
	_expect(str(result.get("relation_label", "")).length() > 0, "result should expose relation label")
	var event: Dictionary = result.get("event", {})
	_expect(not event.is_empty(), "result should expose social event")
	_expect(not str(event.get("flavor", "")).is_empty(), "social event should expose designed flavor text")
	_expect(not str(event.get("outcome", "")).is_empty(), "social event should expose designed outcome text")
	_expect(not str(event.get("hook", "")).is_empty(), "social event should expose future system hook")
	_expect(SocialRulesScript.duration_ms_for_place(place) == 2.0 * 60.0 * 60.0 * 1000.0, "sunny yard should use a 2 hour social duration")
	_expect(str(SocialRulesScript.duration_label_for_place({"place_id": "quiet_pond"})) == "6小时", "quiet pond should expose a 6 hour social duration")
	var detail: Dictionary = SocialRulesScript.build_relationship_detail(a, b, place)
	_expect(not bool(detail.get("hasHistory", true)), "relationship detail should expose no-history state")
	_expect(int(detail.get("nextScore", 0)) == int(result.get("score", 0)), "relationship detail should expose next score")
	_expect(not str(detail.get("nextEventFlavor", "")).is_empty(), "relationship detail should expose next event flavor")


func _test_save_manager_social_flow() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var owned: Array = save_manager.get_owned_monsters()
	_expect(owned.size() >= 2, "default save should have two monsters for social")
	if owned.size() < 2:
		return
	var a_id := str(owned[0].get("instanceId", ""))
	var b_id := str(owned[1].get("instanceId", ""))
	_expect(not str(owned[0].get("gender", "")).is_empty(), "monster instances should have gender")
	_expect(save_manager.cycle_social_place(0), "should cycle social place before starting")
	var selected_place: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(str(selected_place.get("place_id", "")) != "meadow_yard", "cycled social place should be persisted")
	_expect(save_manager.assign_social_slot(0, "slot_a", a_id), "should assign first social slot")
	_expect(save_manager.assign_social_slot(0, "slot_b", b_id), "should assign second social slot")
	var start: Dictionary = save_manager.start_social(0)
	_expect(bool(start.get("ok", false)), "should start social with two monsters")
	_force_social_ready(save_manager)
	var before_gold := int(save_manager.get_player().get("gold", 0))
	var collect: Dictionary = save_manager.collect_social(0)
	_expect(bool(collect.get("ok", false)), "ready social should collect")
	var result: Dictionary = collect.get("result", {})
	_expect(int(result.get("shared_exp_added", 0)) > 0, "social should add its training exp to the shared pool")
	_expect(not result.get("event", {}).is_empty(), "social should resolve an event")
	_expect(str(result.get("place_id", "")) == str(selected_place.get("place_id", "")), "social result should use selected place")
	var a_after: Dictionary = save_manager.get_monster_instance(a_id)
	var profile: Dictionary = a_after.get("socialProfile", {})
	var memory: Dictionary = a_after.get("bondMemory", {})
	_expect(int(profile.get("socialExp", 0)) > 0, "social should increase social profile exp")
	_expect(str(profile.get("lastPartnerId", "")) == b_id, "social profile should remember last partner")
	_expect((profile.get("lastSocialTags", []) as Array).size() > 0, "social profile should remember result tags")
	_expect((memory.get("partners", {}) as Dictionary).has(b_id), "bond memory should remember social partner")
	var partner_memory: Dictionary = (memory.get("partners", {}) as Dictionary).get(b_id, {})
	_expect(int(partner_memory.get("relationLevel", 0)) >= 1, "bond memory should remember relation level")
	_expect(not str(partner_memory.get("lastEventName", "")).is_empty(), "bond memory should remember last event")
	_expect(not str(partner_memory.get("lastEventFlavor", "")).is_empty(), "bond memory should remember event flavor")
	_expect(not str(partner_memory.get("lastEventHook", "")).is_empty(), "bond memory should remember event hook")
	var b_after: Dictionary = save_manager.get_monster_instance(b_id)
	var detail_after: Dictionary = SocialRulesScript.build_relationship_detail(a_after, b_after, selected_place)
	_expect(bool(detail_after.get("hasHistory", false)), "relationship detail should expose history after collect")
	_expect(int(detail_after.get("count", 0)) >= 1, "relationship detail should expose social count")
	_expect(not str(detail_after.get("lastEventOutcome", "")).is_empty(), "relationship detail should expose last event outcome")
	_expect(int(save_manager.get_player().get("gold", 0)) > before_gold, "social should grant gold")
	var after: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(after.get("started_at", null) == null, "collected social should reset timer")
	_expect(not after.get("last_result", {}).is_empty(), "collected social should keep last result")

func _test_social_birth_major_outcome() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist for birth test")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var parent_a: Dictionary = save_manager.add_monster_instance("monster_001", {"level": 10, "nature": "brave", "gender": "male", "source": "test"})
	var parent_b: Dictionary = save_manager.add_monster_instance("monster_002", {"level": 10, "nature": "cautious", "gender": "female", "source": "test"})
	var a_id := str(parent_a.get("instanceId", ""))
	var b_id := str(parent_b.get("instanceId", ""))
	save_manager.update_monster_instance(a_id, {
		"bondMemory": {"partners": {b_id: {"count": 3, "bestScore": 92}}}
	})
	save_manager.update_monster_instance(b_id, {
		"bondMemory": {"partners": {a_id: {"count": 3, "bestScore": 92}}}
	})
	_expect(save_manager.cycle_social_place(0), "birth test should switch to sunny yard")
	_expect(save_manager.assign_social_slot(0, "slot_a", a_id), "birth test should assign first parent")
	_expect(save_manager.assign_social_slot(0, "slot_b", b_id), "birth test should assign second parent")
	_expect(bool(save_manager.start_social(0).get("ok", false)), "birth test should start social")
	_force_social_ready(save_manager)
	var before_count: int = save_manager.get_owned_monsters().size()
	var collect: Dictionary = save_manager.collect_social(0)
	_expect(bool(collect.get("ok", false)), "birth social should collect")
	var result: Dictionary = collect.get("result", {})
	var major: Dictionary = result.get("majorOutcome", {})
	_expect(str(major.get("type", "")) == "birth", "high bond opposite gender social should create birth major outcome")
	var created: Array = major.get("createdInstances", [])
	_expect(created.size() >= 1, "birth major outcome should create at least one child")
	_expect(save_manager.get_owned_monsters().size() == before_count + created.size(), "birth children should be added to monster pool")
	for child in created:
		var child_data: Dictionary = child
		var lineage: Dictionary = child_data.get("lineage", {})
		_expect(str(child_data.get("source", "")) == "social_birth", "birth child should keep source")
		_expect(int(child_data.get("level", 0)) == 1, "birth child should start at level 1")
		_expect(str(lineage.get("type", "")) == "hybrid_birth", "birth child should keep hybrid lineage")
		_expect((child_data.get("mutationTraits", []) as Array).has("hybrid_birth"), "birth child should keep hybrid trait")


func _test_social_erosion_is_protected() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist for erosion test")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	var aggressor: Dictionary = save_manager.add_monster_instance("monster_boss_007", {"level": 8, "nature": "chaos", "gender": "male", "source": "test"})
	var victim: Dictionary = save_manager.add_monster_instance("monster_061", {"level": 8, "nature": "gentle", "gender": "male", "source": "test"})
	var aggressor_id := str(aggressor.get("instanceId", ""))
	var victim_id := str(victim.get("instanceId", ""))
	_expect(save_manager.cycle_social_place(0), "erosion test should use a neutral social place")
	_expect(save_manager.assign_social_slot(0, "slot_a", aggressor_id), "erosion test should assign aggressor")
	_expect(save_manager.assign_social_slot(0, "slot_b", victim_id), "erosion test should assign victim")
	_expect(bool(save_manager.start_social(0).get("ok", false)), "erosion test should start social")
	_force_social_ready(save_manager)
	var collect: Dictionary = save_manager.collect_social(0)
	_expect(bool(collect.get("ok", false)), "erosion social should collect")
	var result: Dictionary = collect.get("result", {})
	var major: Dictionary = result.get("majorOutcome", {})
	_expect(str(major.get("type", "")) == "erosion", "dangerous mismatch social should create erosion major outcome")
	_expect(bool(major.get("protected", false)), "erosion should be protected by default")
	_expect(bool(major.get("requiresConfirmation", false)), "erosion should require a future explicit confirmation flow")
	_expect(not bool(major.get("victimRemoved", true)), "protected erosion should not remove victim")
	_expect(not save_manager.get_monster_instance(victim_id).is_empty(), "protected erosion victim should remain in monster pool")
	var aggressor_after: Dictionary = save_manager.get_monster_instance(aggressor_id)
	_expect(not aggressor_after.is_empty(), "erosion aggressor should remain")
	_expect(not (aggressor_after.get("mutationTraits", []) as Array).has("erosion_hunger"), "protected erosion should not mutate aggressor")
	var effects: Array = aggressor_after.get("conditionEffects", [])
	_expect(effects.is_empty(), "protected erosion should not apply negative condition effect")
	var social_place: Dictionary = save_manager.get_ranch_state().get("social_places", [])[0]
	_expect(str(social_place.get("slot_b", "")) == victim_id, "protected erosion should keep victim social slot")


func _force_social_ready(save_manager: Node) -> void:
	var ranch: Dictionary = save_manager.get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	var duration_ms := SocialRulesScript.duration_ms_for_place(places[0])
	places[0]["started_at"] = Time.get_unix_time_from_system() * 1000.0 - duration_ms - 1000.0
	ranch["social_places"] = places
	save_manager.set_ranch_state(ranch)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RanchSocial] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[RanchSocial] " + failure)
		quit(1)

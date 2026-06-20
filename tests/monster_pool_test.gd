extends SceneTree

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
	var pool: Array = save_manager.get_monster_pool()
	_expect(pool.size() >= 3, "new save should migrate/create starter monster instances")
	var starter_instance: Dictionary = pool[0]
	var starter_id := str(starter_instance.get("instanceId", ""))
	_expect(not starter_id.is_empty(), "starter should have instanceId")
	for starter: Dictionary in pool.slice(0, 3):
		var starter_view := MonsterService.build_instance_view(starter)
		var expected_stats := StatCalculator.calc(str(starter.get("monsterId", "")), int(starter.get("level", 1)), str(starter.get("nature", "")))
		_expect(starter_view.get("stats", {}) == expected_stats, "starter %s should use normal player stats without enemy HP scaling" % str(starter.get("monsterId", "")))

	var first: Dictionary = save_manager.add_monster_instance("monster_001", {"nature": "brave", "source": "test"})
	var second: Dictionary = save_manager.add_monster_instance("monster_001", {"nature": "cautious", "source": "test"})
	_expect(str(first.get("instanceId", "")) != str(second.get("instanceId", "")), "same monster species should create distinct instances")
	_expect(first.get("socialProfile", {}).has("style"), "monster instance should expose social profile")
	_expect((first.get("bondTraits", []) as Array).size() >= 3, "monster instance should expose bond traits")
	_expect(first.get("bondMemory", {}).has("partners"), "monster instance should expose bond memory")
	_expect(save_manager.get_instances_by_monster_id("monster_001").size() >= 3, "monster_001 should allow multiple owned instances")

	save_manager.save_team({"leader": first["instanceId"], "member1": second["instanceId"], "member2": null})
	var team: Dictionary = save_manager.load_team()
	_expect(team.get("leader") == first["instanceId"], "team should store leader instanceId")
	_expect(team.get("member1") == second["instanceId"], "team should store member instanceId")
	_expect(save_manager.get_team_battle_stats().size() == 2, "team battle stats should be built from instances")

	save_manager.place_instance_in_ranch(first["instanceId"], 0)
	var ranch: Dictionary = save_manager.get_ranch_state()
	_expect(ranch.get("slots", [])[0].get("instance_id") == first["instanceId"], "ranch should store instance_id")

	var view := MonsterService.get_instance_view(first["instanceId"], save_manager)
	_expect(view.get("monsterId", "") == "monster_001", "MonsterService should resolve instance monsterId")
	_expect(view.get("stats", {}).has("atk"), "MonsterService should include calculated stats")
	_expect(view.get("art", {}).has("battle"), "MonsterService should include art bundle")
	_expect(view.get("socialProfile", {}).has("style"), "MonsterService should include social profile")
	_expect((view.get("bondTraits", []) as Array).size() >= 3, "MonsterService should include bond traits")
	_expect(view.get("identity", {}).has("ecology"), "MonsterService should include ecology identity")

	var ranch_scene = load("res://src/ui/controllers/ranch_logic.gd").new()
	root.add_child(ranch_scene)
	ranch_scene.init()
	ranch_scene._slots_data[0]["placed_at"] = (Time.get_unix_time_from_system() - 3600.0) * 1000.0
	ranch_scene._calc_idle_exp()
	var level_before_collect: int = save_manager.get_instance_level(first["instanceId"])
	ranch_scene._collect_slot(0)
	_expect(save_manager.get_instance_level(first["instanceId"]) >= level_before_collect, "ranch slot tap should collect only that instance")

	save_manager.update_monster_instance(first["instanceId"], {"level": 16})
	save_manager.add_item("evolution_stone_fire", 1)
	ranch_scene._active_page = "classroom"
	ranch_scene._class_selected_instance_id = first["instanceId"]
	ranch_scene._selected_slot = 0
	ranch_scene._on_evolve_pressed()
	var evolved: Dictionary = save_manager.get_monster_instance(first["instanceId"])
	_expect(evolved.get("monsterId", "") == "monster_006", "classroom evolve should update monsterId and keep instanceId")
	_expect(save_manager.get_item_count("evolution_stone_fire") == 0, "classroom evolve should consume evolution item")
	ranch_scene.queue_free()

	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[MonsterPool] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[MonsterPool] " + failure)
		quit(1)

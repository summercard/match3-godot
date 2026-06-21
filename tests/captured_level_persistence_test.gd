extends SceneTree

const SceneResultScript = preload("res://src/ui/controllers/result_logic.gd")
const BattleFlowControllerScript = preload("res://src/ui/components/battle_flow_controller.gd")

class FakeBattle:
	extends RefCounted
	var result: Dictionary

	func _init(value: Dictionary) -> void:
		result = value

	func get_battle_result() -> Dictionary:
		return result.duplicate(true)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var water_level_ten := StatCalculator.calc("enemy_002", 10, "wise")
	assert(int(water_level_ten.get("hp", 0)) == 235, "Lv10 owned water pet must grow from restored owned HP base")
	assert(int(water_level_ten.get("atk", 0)) == 29, "Lv10 owned water pet must grow from restored owned ATK base")
	assert(int(water_level_ten.get("def", 0)) == 7 and int(water_level_ten.get("spd", 0)) == 12, "owned pet DEF and SPD must use level and nature formula")
	for level in [7, 15]:
		var target := {
			"id": "enemy_001",
			"level": level,
			"nature": "brave",
			"isElite": false,
		}
		var options: Dictionary = SceneResultScript.build_captured_instance_options(
			target,
			{"enemyLevel": 1}
		)
		assert(int(options.get("level", 0)) == level, "captured monster must keep its runtime battle level")

		var instance := MonsterPool.create_instance("enemy_001", options)
		var stats := MonsterPool.get_instance_stats(instance)
		assert(int(instance.get("level", 0)) == level, "captured instance level must persist")
		assert(int(stats.get("level", 0)) == level, "captured stats must be calculated at the saved level")
		assert(stats == StatCalculator.calc("enemy_001", level, "brave"), "captured stats must match base stats, level, and nature")

	var save_manager := root.get_node_or_null("/root/SaveManager")
	assert(save_manager != null, "SaveManager must be available")
	save_manager.clear_all_data()
	var expected_level := 23
	var battle_stats := StatCalculator.calc("enemy_001", expected_level, "brave")
	battle_stats["maxHP"] = int(battle_stats.get("hp", 0)) * 4
	battle_stats["hp"] = battle_stats["maxHP"]
	battle_stats["atk"] = int(battle_stats.get("atk", 0)) * 2
	var payload := BattleFlowControllerScript.build_result_payload(FakeBattle.new({
		"result": "win",
		"enemyLevel": 1,
		"enemies": [{
			"id": "enemy_001",
			"level": expected_level,
			"nature": "brave",
			"isElite": false,
			"maxHP": battle_stats.get("maxHP", 0),
			"atk": battle_stats.get("atk", 0),
			"def": battle_stats.get("def", 0),
			"spd": battle_stats.get("spd", 0),
		}],
	}), {
		"success": true,
		"target": {"id": "enemy_001"},
	})
	var payload_target: Dictionary = payload.get("capture_target", {})
	assert(int(payload_target.get("level", 0)) == expected_level, "battle payload must preserve any runtime enemy level")
	assert(str(payload_target.get("nature", "")) == "brave", "battle payload must preserve runtime nature")

	var result := SceneResultScript.new()
	root.add_child(result)
	result.set("_storage", save_manager)
	result.set("_captured", true)
	result.set("_capture_target", payload_target)
	result.set("_battle_result", {"enemyLevel": 1, "playerTeam": []})
	result.call("_save_rewards")

	var captured: Array = save_manager.get_instances_by_monster_id("enemy_001")
	assert(captured.size() == 1, "capture settlement must add one owned instance")
	var saved: Dictionary = captured[0]
	var instance_id := str(saved.get("instanceId", ""))
	assert(int(saved.get("level", 0)) == expected_level, "capture settlement must save any runtime level")

	var ranch: Control = load("res://src/ui/scenes/ranch_hub.tscn").instantiate()
	root.add_child(ranch)
	ranch.init()
	ranch.call("_switch_to_classroom")
	ranch.set("_class_selected_instance_id", instance_id)
	ranch.call("_sync_gui")
	var classroom_instance: Dictionary = ranch.call("_fresh_instance", instance_id)
	var classroom_stats: Dictionary = ranch.call("_get_instance_stats", instance_id)
	var info := ranch.get_node("Pages/ClassroomPage/DetailPanel/Info") as Label
	var values := ranch.get_node("Pages/ClassroomPage/DetailPanel/AttributeValues") as Label
	var expected_owned_stats := StatCalculator.calc("enemy_001", expected_level, "brave")
	assert(int(classroom_instance.get("level", 0)) == expected_level, "classroom must resolve the saved instance")
	assert(classroom_stats == expected_owned_stats, "classroom attributes must use base stats, saved level, and saved nature")
	assert(info.text.begins_with("Lv.%d" % expected_level), "classroom info must display the saved level")
	assert(values.text.begins_with("Lv.%d\n" % expected_level), "classroom attributes must display the saved level")

	var elite := MonsterPool.create_instance("enemy_001", {
		"level": 15,
		"nature": "brave",
		"isElite": true,
	})
	assert(
		MonsterPool.get_instance_stats(elite) == StatCalculator.calc("enemy_001", 15, "brave"),
		"all warehouse monsters must use the same base, level, and nature formula"
	)
	assert(MonsterService.build_instance_view(elite).get("stats", {}) == MonsterPool.get_instance_stats(elite), "all owned-stat entry points must agree")

	var second: Dictionary = save_manager.add_monster_instance("enemy_001", {"level": 7, "nature": "calm", "source": "capture"})
	assert(str(second.get("instanceId", "")) != instance_id, "each captured pet must be a unique instance")
	assert(MonsterPool.get_instance_stats(second) == StatCalculator.calc("enemy_001", 7, "calm"), "each unique instance must use its own level and nature")
	var album_view := MonsterService.get_species_album_view("enemy_001", save_manager)
	assert((album_view.get("representative", {}) as Dictionary).is_empty(), "album must not expose a warehouse representative")
	assert(album_view.get("stats", {}) == StatCalculator.calc("enemy_001", 1, ""), "album must show neutral species reference stats")

	ranch.queue_free()
	result.queue_free()
	await process_frame
	print("[CapturedLevelPersistence] OK")
	quit(0)

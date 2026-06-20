extends SceneTree

const GrowthRulesScript = preload("res://src/core/growth_rules.gd")
const SceneResultScript = preload("res://src/ui/controllers/result_logic.gd")
const SceneTeamScript = preload("res://src/ui/controllers/team_logic.gd")

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
	_expect(pool.size() >= 3, "default monster pool should contain starters")
	if pool.size() < 3:
		_finish()
		return

	var high_id := str(pool[0].get("instanceId", ""))
	var low_id := str(pool[1].get("instanceId", ""))
	var third_id := str(pool[2].get("instanceId", ""))
	save_manager.update_monster_instance(high_id, {"level": 5, "exp": 0})
	save_manager.update_monster_instance(low_id, {"level": 2, "exp": 0})
	save_manager.update_monster_instance(third_id, {"level": 5, "exp": 0})
	save_manager.save_team({"leader": high_id, "member1": low_id, "member2": third_id})

	_test_growth_rules()
	_test_storage_catchup(save_manager, low_id)
	_test_team_ui_state(save_manager, low_id)
	_test_result_awards(save_manager, high_id, low_id, third_id)
	_finish()


func _test_growth_rules() -> void:
	_expect(is_equal_approx(GrowthRulesScript.calc_catchup_multiplier(2, 5), 1.5), "level gap 3 should give 1.5x catchup")
	_expect(is_equal_approx(GrowthRulesScript.calc_catchup_multiplier(4, 5), 1.0), "level gap 1 should not trigger catchup")
	_expect(GrowthRulesScript.calc_catchup_exp(100, 1, 10) == 200, "catchup multiplier should cap at 2x")


func _test_storage_catchup(save_manager: Node, low_id: String) -> void:
	var state: Dictionary = save_manager.get_instance_catchup_state(low_id)
	_expect(bool(state.get("enabled", false)), "low-level team member should expose catchup state")
	_expect(save_manager.calc_instance_battle_exp(low_id, 100) == 150, "storage battle exp should apply catchup multiplier")


func _test_team_ui_state(save_manager: Node, low_id: String) -> void:
	var scene: Control = SceneTeamScript.new()
	root.add_child(scene)
	scene.init({})
	var state: Dictionary = scene.call("_get_catchup_state", low_id)
	_expect(bool(state.get("enabled", false)), "team scene should expose catchup badge state")
	_expect(str(state.get("label", "")).contains("追赶"), "team scene catchup label should be player-facing")
	scene.queue_free()


func _test_result_awards(save_manager: Node, high_id: String, low_id: String, third_id: String) -> void:
	var scene: Control = SceneResultScript.new()
	root.add_child(scene)
	scene.initialize(null, {
		"result": "win",
		"stageId": "stage_1_1",
		"capture_played_inline": true,
		"captured": false,
		"turnCount": 2,
		"maxTurns": 10,
		"stageRewards": {"gold": 100, "exp": 100},
		"playerTeam": [
			{"id": high_id, "monsterId": "monster_001", "hp": 100, "maxHP": 100, "level": 5},
			{"id": low_id, "monsterId": "monster_002", "hp": 100, "maxHP": 100, "level": 2},
			{"id": third_id, "monsterId": "monster_003", "hp": 100, "maxHP": 100, "level": 5}
		]
	})
	var awards: Dictionary = scene.get("_monster_exp_awards")
	_expect(int(awards.get("shared", {}).get("added", 0)) == 100, "battle monster exp should enter the shared pool once")
	_expect(save_manager.get_instance_exp(high_id) == 0, "battle should not directly add exp to the active monster")
	_expect(save_manager.get_instance_exp(low_id) == 0, "battle should not directly add catchup exp to a team member")
	scene.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GrowthCatchup] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[GrowthCatchup] " + failure)
		quit(1)

extends SceneTree

const TowerDBScript = preload("res://src/data/tower_db.gd")
const TowerRulesScript = preload("res://src/core/tower_rules.gd")
const TowerRunControllerScript = preload("res://src/core/tower_run_controller.gd")
const TowerRankProviderScript = preload("res://src/core/tower_rank_provider.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_floor_structure()
	_test_card_and_checkpoint_flow()
	_test_failure_reward_rules()
	_test_rank_sorting()
	_test_save_manager_integration()
	_finish()


func _test_floor_structure() -> void:
	var first := TowerDBScript.get_floor(1)
	_expect(not bool(first.get("isBoss", true)), "floor 1 should be a normal wave")
	_expect((first.get("enemies", []) as Array).size() == 3, "normal tower wave should have three enemies")
	_expect(int(first.get("enemyLevel", 0)) >= 50, "tower should start at post-chapter-10 strength")
	var fifth := TowerDBScript.get_floor(5)
	_expect(bool(fifth.get("isBoss", false)), "floor 5 should be a boss wave")
	_expect((fifth.get("enemies", []) as Array).size() == 3, "boss wave should have boss plus two adds")
	_expect(int(fifth.get("towerWave", 0)) == 5, "floor 5 should be the fifth wave")
	var final_floor := TowerDBScript.get_floor(99)
	_expect(bool(final_floor.get("isBoss", false)), "floor 99 should be the final boss")
	_expect(int(final_floor.get("towerStage", 0)) == 20, "floor 99 should belong to final stage 20")
	_expect(int(final_floor.get("towerWave", 0)) == 4, "final stage should use its four-wave exception")
	var cards := TowerDBScript.get_card_candidates(5, 12017)
	_expect(cards.size() == 3, "boss should offer three distinct cards")
	_expect(str(cards[0].get("id", "")) != str(cards[1].get("id", "")), "card candidates should not duplicate")


func _test_card_and_checkpoint_flow() -> void:
	var team := [{"id": "a", "hp": 100, "maxHP": 100}, {"id": "b", "hp": 80, "maxHP": 100}]
	var state := TowerRulesScript.begin_run(TowerRulesScript.default_state(), ["a", "b"], team)
	for floor in range(1, 5):
		var wave := TowerRulesScript.complete_wave(state, {"party_snapshot": team, "skill_charges": {}, "leader_charge_points": {}}, 3, 200 + floor)
		_expect(bool(wave.get("ok", false)), "normal wave %d should complete" % floor)
		state = wave.get("state", {})
		_expect(int(state.get("current_floor", 0)) == floor + 1, "normal wave should advance to next floor")
	var boss := TowerRulesScript.complete_wave(state, {"party_snapshot": team, "skill_charges": {}, "leader_charge_points": {}}, 4, 680)
	_expect(str(boss.get("event", "")) == "boss_cleared", "fifth floor should wait for card choice")
	state = boss.get("state", {})
	_expect(int(state.get("current_floor", 0)) == 5, "tower should not advance before choosing a card")
	var cards: Array = boss.get("cards", [])
	var card_result := TowerRulesScript.choose_card(state, str(cards[0].get("id", "")))
	_expect(bool(card_result.get("ok", false)), "offered card should be selectable")
	state = card_result.get("state", {})
	_expect(int(state.get("current_floor", 0)) == 6, "card selection should open next stage")
	_expect(int(state.get("checkpoint_floor", 0)) == 6, "boss choice should create checkpoint")
	_expect(int(state.get("highest_floor", 0)) == 5, "tower should record highest cleared floor")
	_expect(int(state.get("highest_turn_damage", 0)) == 680, "tower should record highest turn damage")


func _test_failure_reward_rules() -> void:
	var state := TowerRulesScript.default_state()
	var reward := TowerRulesScript.failure_reward(6)
	_expect(int(reward.get("gold", 0)) > 0 and int(reward.get("shared_exp", 0)) > 0, "a tower checkpoint failure should offer a light consolation reward")
	state = TowerRulesScript.mark_failure_reward_claimed(state, 6)
	_expect((state.get("claimed_failure_rewards", []) as Array).has(6), "a delivered failure reward should be tracked by checkpoint")
	var restored := TowerRulesScript.restore_checkpoint(state)
	_expect((restored.get("claimed_failure_rewards", []) as Array).has(6), "checkpoint recovery should preserve delivered failure rewards")


func _test_rank_sorting() -> void:
	var state := TowerRulesScript.default_state()
	state["highest_floor"] = 42
	state["total_player_turns"] = 360
	state["highest_turn_damage"] = 990
	var climb := TowerRankProviderScript.get_climb_entries("测试者", state)
	var burst := TowerRankProviderScript.get_burst_entries("测试者", state)
	_expect(not climb.is_empty() and int(climb[0].get("floor", 0)) >= int(climb[1].get("floor", 0)), "climb leaderboard should sort floor descending")
	_expect(not burst.is_empty() and int(burst[0].get("damage", 0)) >= int(burst[1].get("damage", 0)), "burst leaderboard should sort damage descending")


func _test_save_manager_integration() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist for tower integration")
	if storage == null:
		return
	storage.clear_all_data()
	_expect(not storage.is_tower_unlocked(), "tower should be locked before the chapter-five final boss")
	_expect(storage.save_stage_stars("stage_5_12", 1), "chapter-five final boss progress should save")
	_expect(storage.is_tower_unlocked(), "tower should unlock after stage_5_12")
	var controller := TowerRunControllerScript.new(storage)
	var started := controller.start_new_run()
	_expect(bool(started.get("ok", false)), "tower should start with default team after unlock")
	var state: Dictionary = storage.get_tower_state()
	_expect(bool(state.get("active", false)), "tower start should persist active run")
	_expect((state.get("party_snapshot", []) as Array).size() > 0, "tower run should persist party snapshot")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TowerRules] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TowerRules] " + failure)
	quit(1)

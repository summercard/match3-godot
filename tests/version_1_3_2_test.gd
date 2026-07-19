extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const BattlePrepareScript = preload("res://src/ui/controllers/battle_prepare_logic.gd")
const BoardScript = preload("res://src/match3/board.gd")
const CaptureSystemScript = preload("res://src/battle/capture_system.gd")
const HazardRulesScript = preload("res://src/ui/components/battle_hazard_rules.gd")
const ItemDBScript = preload("res://src/data/item_db.gd")
const LeaderV132Script = preload("res://src/data/leader_skill_v132_db.gd")
const SignInRewardDBScript = preload("res://src/data/sign_in_reward_db.gd")
const EcologyDBScript = preload("res://src/data/monster_ecology_db.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const StatusEffectScript = preload("res://src/battle/status_effect.gd")
const TowerDBScript = preload("res://src/data/tower_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_capture_and_item_economy()
	_test_stage_and_tower_progression()
	_test_sign_in_single_source()
	_test_ecology_catalog()
	_test_leader_skill_override_catalog()
	_test_leader_runtime_states()
	_test_hazard_damage_and_result_snapshot()
	_finish()


func _test_capture_and_item_economy() -> void:
	var expected_rates := {1: 0.72, 2: 0.38, 3: 0.20, 4: 0.11, 5: 0.055}
	for rarity in expected_rates:
		_expect(is_equal_approx(float(CaptureSystemScript.BASE_CAPTURE_RATE[rarity]), float(expected_rates[rarity])), "rarity %d capture base should match 1.3.2" % rarity)
	var base := CaptureSystemScript.calc_capture_probability(0, 100, 10, 10, 3)
	var high_enemy := CaptureSystemScript.calc_capture_probability(0, 100, 10, 20, 3)
	var elite := CaptureSystemScript.calc_capture_probability(0, 100, 10, 10, 3, {"is_elite": true})
	_expect(is_equal_approx(base, 0.20), "equal-level rarity-three target should use its base rate at zero HP")
	_expect(is_equal_approx(high_enemy, 0.08), "ten-level lead should reduce the level factor by 60%")
	_expect(is_equal_approx(elite, base * 0.9), "elite capture should multiply the final result by 0.9")
	_expect(is_equal_approx(CaptureSystemScript.calc_capture_probability(100, 100, 1, 99, 5), 0.02), "capture probability should retain the 2% floor")
	var expected_balls := {"capture_ball": 0.20, "capture_ball_plus": 0.30, "capture_ball_elite": 0.70}
	for item_id in expected_balls:
		var item: Dictionary = ItemDBScript.get_item(item_id)
		_expect(is_equal_approx(float(item.get("effect", {}).get("captureBonus", 0.0)), float(expected_balls[item_id])), "%s should use the migrated capture bonus" % item_id)
	_expect(int(ItemDBScript.get_item("gold_bag").get("effect", {}).get("goldGain", 0)) == 500, "gold bag should grant 500")
	_expect(int(ItemDBScript.get_item("gold_chest").get("effect", {}).get("goldGain", 0)) == 2000, "gold chest should grant 2000")
	_expect(not ItemDBScript.get_shop_items().any(func(entry): return str(entry.get("id", "")) == "unlock_key"), "unlock key should stay out of the shop catalog")
	var prices := {}
	for entry: Dictionary in ItemDBScript.get_shop_items():
		prices[str(entry.get("id", ""))] = {"price": int(entry.get("price", 0)), "currency": str(entry.get("currency", ""))}
	for expected in [
		{"id": "hp_potion_large", "price": 1500, "currency": "gold"},
		{"id": "capture_ball", "price": 300, "currency": "gold"},
		{"id": "capture_ball_plus", "price": 1000, "currency": "gold"},
		{"id": "capture_ball_elite", "price": 100, "currency": "gems"},
		{"id": "absorb_shield", "price": 800, "currency": "gold"},
		{"id": "rock_hammer", "price": 660, "currency": "gold"},
	]:
		_expect(prices.get(expected["id"], {}) == {"price": expected["price"], "currency": expected["currency"]}, "%s shop price should match 1.3.2" % expected["id"])


func _test_stage_and_tower_progression() -> void:
	var db := StageDBScript.new()
	_expect(int(db.get_stage("stage_1_1").get("enemyLevel", 0)) == 5, "stage_1_1 should keep its baseline enemy level")
	_expect(int(db.get_stage("stage_1_2").get("enemyLevel", 0)) == 11, "stage_1_2 should receive the six-level increase")
	_expect(int(db.get_stage("stage_5_12").get("enemyLevel", 0)) == 36, "chapter-five boss should receive the six-level increase")
	_expect(str(db.get_stage("stage_1_6").get("battleHint", "")).is_empty(), "ordinary non-fountain stages should not show generic battle hints")
	_expect(str(db.get_stage("stage_2_5").get("battleHint", "")).contains("喷泉"), "fountain stages should retain the Chinese mechanic hint")
	_expect(TowerDBScript.UNLOCK_STAGE_ID == "stage_5_12", "tower should unlock from the chapter-five final boss")
	_expect(TowerDBScript.unlock_hint() == TowerDBScript.UNLOCK_HINT and TowerDBScript.UNLOCK_HINT.contains("第 5 章最终 Boss"), "tower unlock copy should come from one rule source")
	_expect(int(TowerDBScript.get_floor(1).get("maxTurns", 0)) == 34, "tower floor turn budget should include the six-turn increase")
	var default_prepare := BattlePrepareScript.new()
	_expect(is_equal_approx(float(default_prepare.call("_preview_random_elite_chance", {})), 0.10), "ordinary prepare flow should inherit the battle core's ten-percent elite rate")
	default_prepare.free()
	_test_elite_encounter_snapshot()


func _test_elite_encounter_snapshot() -> void:
	var stage := {
		"id": "elite_snapshot_test", "type": "normal", "enemies": ["monster_014", "monster_015"],
		"enemyLevel": 10, "randomEliteChance": 1.0,
	}
	var prepare := BattlePrepareScript.new()
	root.add_child(prepare)
	prepare.init({"stageId": "elite_snapshot_test", "stageData": stage})
	var encounter_stage: Dictionary = prepare.get("_stage_data")
	var preview_index := int(encounter_stage.get("_encounterEliteIndex", -1))
	_expect(preview_index >= 0 and preview_index < 2, "prepare should roll exactly one eligible elite into the encounter snapshot")
	var preview_team: Array = prepare.get("_enemy_team")
	var preview_elites := 0
	for enemy: Dictionary in preview_team:
		preview_elites += 1 if bool(enemy.get("isElite", false)) else 0
	_expect(preview_elites == 1, "prepare should display the one promoted elite")
	var battle := BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_002"], stage["enemies"], 10, 10, encounter_stage, "elite_snapshot_test")
	var battle_elites := 0
	var battle_elite_index := -1
	for index in range(battle.enemies.size()):
		if bool((battle.enemies[index] as Dictionary).get("isElite", false)):
			battle_elites += 1
			battle_elite_index = index
	_expect(battle_elites == 1 and battle_elite_index == preview_index, "battle should reuse the prepare snapshot instead of rerolling its elite")
	prepare.free()
	battle.free()


func _test_sign_in_single_source() -> void:
	var schedule := SignInRewardDBScript.get_schedule()
	_expect(schedule.size() == 7, "sign-in should use one seven-day schedule")
	_expect(int(schedule[0].get("gold", 0)) == 500, "day one should grant 500 gold")
	_expect(int(schedule[1].get("items", [])[0].get("count", 0)) == 200 and str(schedule[1].get("items", [])[0].get("id", "")) == "exp_potion", "day two should grant 200 EXP potions")
	_expect(int(schedule[2].get("items", [])[0].get("count", 0)) == 50, "day three should grant 50 water stones")
	_expect(int(schedule[3].get("items", [])[0].get("count", 0)) == 2, "day four should grant two fire stones")
	_expect(str(schedule[4].get("items", [])[0].get("id", "")) == "hp_potion", "day five should grant one HP potion")
	_expect(int(schedule[5].get("items", [])[0].get("count", 0)) == 100, "day six should grant 100 water stones")
	var seventh: Dictionary = schedule[6].get("monsters", [])[0]
	_expect(str(seventh.get("monsterId", "")) == "monster_049" and int(seventh.get("level", 0)) == 1, "day seven should grant one level-one monster_049")
	_expect(SignInRewardDBScript.get_reward(8) == SignInRewardDBScript.get_reward(1), "day eight should cycle to day one")
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "sign-in runtime award test should have SaveManager")
	if storage == null:
		return
	storage.clear_all_data()
	var day_one_reward: Dictionary = storage.do_sign_in()
	_expect(day_one_reward == SignInRewardDBScript.get_reward(1), "actual day-one award should read the shared reward table")
	_expect(int(storage.get_player().get("gold", 0)) == 500, "actual day-one sign-in should deposit 500 gold")
	_expect(storage.do_sign_in().is_empty(), "same-day sign-in should not award twice")
	storage.save_sign_in_data({"lastSignInDate": str(storage.call("_get_date_minus_days", 1)), "consecutiveDays": 6, "totalDays": 6})
	var before_seventh: int = storage.get_instances_by_monster_id("monster_049").size()
	var day_seven_reward: Dictionary = storage.do_sign_in()
	var signed_monsters: Array = storage.get_instances_by_monster_id("monster_049")
	_expect(day_seven_reward == SignInRewardDBScript.get_reward(7), "actual day-seven award should read the shared reward table")
	_expect(signed_monsters.size() == before_seventh + 1 and int((signed_monsters.back() as Dictionary).get("level", 0)) == 1, "actual day-seven sign-in should add one level-one monster_049")
	storage.clear_all_data()


func _test_ecology_catalog() -> void:
	var monsters := MonsterDb.get_all()
	var validation := EcologyDBScript.validate_catalog(monsters)
	_expect(monsters.size() == 111, "the playable catalog should contain 111 species")
	_expect(bool(validation.get("ok", false)) and int(validation.get("count", 0)) == 111, "all 111 species should have unique ecology cores")
	for monster: Dictionary in monsters:
		var ecology := EcologyDBScript.get_ecology(monster)
		_expect(not str(ecology.get("habitat", "")).is_empty(), "%s ecology should include habitat" % monster.get("id", ""))
		_expect(not str(ecology.get("niche", "")).is_empty(), "%s ecology should include behavior/niche" % monster.get("id", ""))
		_expect(not str(ecology.get("adventurerTip", "")).is_empty(), "%s ecology should include an adventurer tip" % monster.get("id", ""))


func _test_leader_skill_override_catalog() -> void:
	_expect(LeaderV132Script.OVERRIDES.size() >= 55, "1.3.2 leader-skill override catalog should cover every finalized family")
	var first_kind := {
		"020": "randomize_enemy_element", "023": "convert_adjacent_gems_from_random_source", "029": "self_atk_boost",
		"031": "shuffle_board", "034": "convert_gems", "036": "clear_random_element_gems_damage_all",
		"039": "randomize_enemy_element", "043": "reflect_damage", "045": "confuse_enemy_attack", "049": "convert_gems",
		"051": "remove_random_element_gems", "056": "damage_per_living_element_unit", "062": "status", "070": "status",
		"073": "status", "076": "convert_gems", "081": "grant_ally_charge", "084": "heal_over_time",
		"087": "self_damage_reduction", "090": "heal_by_gem_count", "097": "self_atk_boost", "099": "random_multi_hit",
		"101": "convert_element_gems_by_ratio",
	}
	for suffix in first_kind:
		var effects: Array = LeaderSkillDb.get_leader_skill("LS_MONSTER_%s" % suffix).get("burstEffects", [])
		_expect(not effects.is_empty() and str(effects[0].get("kind", "")) == str(first_kind[suffix]), "monster_%s should use its finalized 1.3.2 burst" % suffix)
	var numeric_checks := [
		{"skill": "LS_MONSTER_030", "key": "multiplier", "value": 1.5},
		{"skill": "LS_MONSTER_035", "key": "count", "value": 8.0},
		{"skill": "LS_MONSTER_044", "key": "ratio", "value": 0.3},
		{"skill": "LS_MONSTER_046", "key": "ratio", "value": 0.5},
		{"skill": "LS_MONSTER_052", "index": 1, "key": "multiplier", "value": 3.5},
		{"skill": "LS_MONSTER_057", "key": "ratio", "value": 1.8},
		{"skill": "LS_MONSTER_063", "key": "increment_ratio", "value": 0.015},
		{"skill": "LS_MONSTER_072", "key": "turns", "value": 3.0},
		{"skill": "LS_MONSTER_075", "index": 1, "key": "ratio", "value": 0.8},
		{"skill": "LS_MONSTER_083", "key": "charge_amount", "value": 2.0},
		{"skill": "LS_MONSTER_086", "key": "turns", "value": 3.0},
		{"skill": "LS_MONSTER_089", "index": 1, "key": "multiplier", "value": 3.6},
		{"skill": "LS_MONSTER_092", "key": "target_count", "value": 3.0},
		{"skill": "LS_MONSTER_100", "key": "count", "value": 10.0},
		{"skill": "LS_MONSTER_102", "key": "ratio", "value": 0.5},
		{"skill": "LS_MONSTER_101", "key": "ratio", "value": 0.75},
		{"skill": "LS_MONSTER_103", "key": "ratio", "value": 1.0},
	]
	for check: Dictionary in numeric_checks:
		var effects: Array = LeaderSkillDb.get_leader_skill(str(check["skill"])).get("burstEffects", [])
		var index := int(check.get("index", 0))
		_expect(index < effects.size() and is_equal_approx(float(effects[index].get(str(check["key"]), -999.0)), float(check["value"])), "%s %s should match the final numeric rule" % [check["skill"], check["key"]])
	var boss_effect: Dictionary = LeaderSkillDb.get_leader_skill("LS_BOSS_008").get("burstEffects", [])[0]
	_expect(str(boss_effect.get("kind", "")) == "clear_element_gems_damage_highest_hp" and is_equal_approx(float(boss_effect.get("ratio", 0.0)), 0.2), "boss 008 should use fire-clear damage scaling")


func _test_leader_runtime_states() -> void:
	for wind_clear in [
		{"leader": "monster_051", "expected": 1, "clear_all": false},
		{"leader": "monster_052", "expected": 64, "clear_all": true},
	]:
		var wind_battle := _ready_battle(str(wind_clear["leader"]), ["monster_014"])
		for row in range(wind_battle.board.rows):
			for col in range(wind_battle.board.cols):
				wind_battle.board.grid[row][col] = "thunder"
		var wind_log: Dictionary = wind_battle.consume_ready_leader_burst().get("leader_skill_log", {})
		var wind_effect: Dictionary = (wind_log.get("effects", []) as Array)[0]
		_expect(int(wind_effect.get("count", 0)) == int(wind_clear["expected"]), "%s should clear its finalized number of wind gems" % wind_clear["leader"])
		_expect(bool(wind_effect.get("clear_all", false)) == bool(wind_clear["clear_all"]), "%s should preserve its finalized clear-all mode" % wind_clear["leader"])
		_free_battle(wind_battle)

	var regen_battle := _ready_battle("monster_084", ["monster_014"])
	var regen_leader: Dictionary = regen_battle.player_team[0]
	var max_hp := int(regen_leader.get("maxHP", 1))
	regen_leader["hp"] = int(floor(float(max_hp) * 0.25))
	var start_hp := int(regen_leader.get("hp", 0))
	var regen_log: Dictionary = regen_battle.consume_ready_leader_burst().get("leader_skill_log", {})
	_expect(int(regen_log.get("damage", 0)) == 0, "sleeping-bear regeneration should deal no damage")
	for turn in range(3):
		regen_battle.call("_finish_leader_enemy_action", 0)
	var expected_hp := mini(max_hp, start_hp + int(floor(float(max_hp) * 0.2)) * 3)
	_expect(int(regen_leader.get("hp", 0)) == expected_hp, "regeneration should tick after exactly three enemy actions")
	_expect(regen_battle.leader_regeneration.is_empty(), "regeneration should expire after the third action")
	_free_battle(regen_battle)

	var state_battle := _ready_battle("monster_043", ["monster_014", "monster_015"])
	var leader_id := str(state_battle.player_team[0].get("id", ""))
	state_battle.apply_leader_reflect(leader_id, 0.3, 2)
	var enemy_before := int(state_battle.enemies[0].get("hp", 0))
	var reflected := int(state_battle.call("_apply_leader_reflect_damage", state_battle.player_team[0], 0, 100))
	_expect(reflected == 30 and int(state_battle.enemies[0].get("hp", 0)) == enemy_before - 30, "reflect should use 30% of actual HP loss")
	for _stack in range(5):
		state_battle.add_leader_damage_reduction(leader_id, 0.2)
	_expect(is_equal_approx(float(state_battle.leader_damage_reductions.get(leader_id, 0.0)), 0.8), "permanent damage reduction should cap at 80%")
	state_battle.apply_enemy_vulnerability(0, 3.0, 3)
	var vulnerability_hit := state_battle.apply_direct_enemy_damage(0, 100, false, leader_id)
	_expect(int(vulnerability_hit.get("remaining", 0)) == 300, "enemy vulnerability should multiply direct battle damage")
	state_battle.apply_enemy_confusion(0, 1.0, 1)
	state_battle.apply_enemy_confusion(1, 1.0, 1)
	var enemy_turn := state_battle.enemy_action()
	_expect((enemy_turn.get("actions", []) as Array).any(func(action): return bool(action.get("is_friendly_fire", false))), "100% confusion seam should redirect the next enemy action to another enemy")
	_free_battle(state_battle)

	var status := StatusEffectScript.new()
	status.init_effects(1)
	var poisoned := [{"name": "毒伤木桩", "hp": 1000}]
	status.apply_status(0, "poison", 1000, "毒伤木桩", {"duration": -1, "dot_mult": 0.01, "increment_per_turn": 0.01})
	var poison_ticks: Array[int] = []
	for _turn in range(3):
		var logs := status.begin_enemy_turn(poisoned)
		poison_ticks.append(int(logs[0].get("damage", 0)))
		status.end_enemy_turn(poisoned)
	_expect(poison_ticks == [10, 20, 30], "permanent poison should increase by its base step every target action")


func _test_hazard_damage_and_result_snapshot() -> void:
	var battle := _ready_battle("monster_087", ["monster_014"])
	battle.player_team[0]["maxHP"] = 100
	battle.player_team[0]["hp"] = 100
	battle.player_team[0]["element"] = "earth"
	battle.player_team[1]["maxHP"] = 200
	battle.player_team[1]["hp"] = 200
	battle.player_team[1]["element"] = "water"
	battle.player_team[2]["maxHP"] = 300
	battle.player_team[2]["hp"] = 300
	battle.player_team[2]["element"] = "grass"
	var backlash := HazardRulesScript.process_destroyed_rock_backlash(battle, [{"destroyed": true}, {"destroyed": true}])
	_expect(int(battle.player_team[0].get("hp", 0)) == 100, "earth ally should ignore rock backlash")
	_expect(int(battle.player_team[1].get("hp", 0)) == 160 and int(battle.player_team[2].get("hp", 0)) == 240, "each destroyed rock should deal 10% max HP to every living non-earth ally")
	_expect((backlash.get("hits", []) as Array).size() == 4, "two rocks against two eligible allies should create four backlash hits")
	var snapshot_id := str(battle.battle_start_team_snapshot[0].get("id", ""))
	battle.player_team[0]["id"] = "mutated_after_battle_start"
	var result := battle.get_battle_result()
	_expect(str(result.get("player_team", [])[0].get("id", "")) == snapshot_id, "battle result should use the battle-start team snapshot")
	_free_battle(battle)


func _ready_battle(leader_id: String, enemy_ids: Array) -> BattleManager:
	var battle := BattleManagerScript.new()
	root.add_child(battle)
	battle.init([leader_id, "monster_002", "monster_011"], enemy_ids, 20, 20, {
		"id": "version_1_3_2_test", "enemies": enemy_ids, "enemyLevel": 20, "disableRandomElite": true,
	}, "version_1_3_2_test")
	for enemy: Dictionary in battle.enemies:
		enemy["maxHP"] = 10000
		enemy["hp"] = 10000
	for monster: Dictionary in battle.player_team:
		battle.leader_charge_points[str(monster.get("id", ""))] = BattleManager.LEADER_CHARGE_MAX
	var board := BoardScript.new(8, 8)
	board.init_board()
	battle.board = board
	return battle


func _free_battle(battle: BattleManager) -> void:
	battle.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[Version132] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[Version132] " + failure)
	quit(1)

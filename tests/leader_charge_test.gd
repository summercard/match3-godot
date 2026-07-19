extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_fire_leader_burst_damage()
	_test_grass_leader_burst_heal()
	_test_light_leader_burst_converts_gems()
	_test_wind_leader_burst_weakens_two_turns()
	_test_dark_leader_burst_lifesteals()
	_test_independent_charges_release_in_queue_order()
	_test_dead_member_does_not_block_ready()
	_test_dead_leader_promotes_next_leader_skill()
	_test_dead_same_name_member_does_not_attack_after_match()
	await process_frame
	_finish()


func _test_fire_leader_burst_damage() -> void:
	var battle := _make_battle("monster_095")
	var before_hp := int(battle.enemies[0].get("hp", 0))
	var burst := _charge_and_consume(battle, _all_gems())
	_expect(str(burst.get("element", "")) == "fire", "fire leader should produce fire burst")
	_expect(int(burst.get("remaining_damage", 0)) > 0, "fire burst should deal damage")
	_expect(int(battle.enemies[0].get("hp", 0)) < before_hp, "fire burst should reduce enemy hp")
	_expect(int(battle.leader_charge_points.get(battle.player_team[0].get("id", ""), -1)) == 0, "only the releasing leader charge should reset after burst")
	for index in range(1, battle.player_team.size()):
		_expect(int(battle.leader_charge_points.get(battle.player_team[index].get("id", ""), 0)) == BattleManager.LEADER_CHARGE_MAX, "other full leaders should keep their charges after an earlier burst")
	battle.free()


func _test_grass_leader_burst_heal() -> void:
	var battle := _make_battle("monster_002")
	battle.player_team[1]["hp"] = maxi(1, int(battle.player_team[1].get("maxHP", 1)) / 3)
	var before_hp := int(battle.player_team[1].get("hp", 0))
	var burst := _charge_and_consume(battle, _all_gems())
	var healed := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "heal" and int(effect.get("amount", 0)) > 0:
			healed = true
	_expect(str(burst.get("element", "")) == "grass", "grass leader should produce grass burst")
	_expect(healed, "grass burst should include a heal effect")
	_expect(int(battle.player_team[1].get("hp", 0)) > before_hp, "grass burst should heal the lowest ally")
	battle.free()


func _test_light_leader_burst_converts_gems() -> void:
	var battle := _make_battle("monster_035")
	var burst := _charge_and_consume(battle, _all_gems())
	var converts := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "convert_gems" and int(effect.get("requested_count", 0)) == 8 and str(effect.get("target_element", "")) == "light" and int(effect.get("edge_layers", 0)) == 2:
			converts = true
	_expect(str(burst.get("element", "")) == "light", "light leader should produce light burst")
	_expect(converts, "monster_035 should convert eight outer-two-ring gems into light gems")
	battle.free()


func _test_wind_leader_burst_weakens_two_turns() -> void:
	var battle := _make_battle("monster_005")
	var burst := _charge_and_consume(battle, _all_gems())
	var weakens_two_turns := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "weaken" and int(effect.get("turns", 0)) == 2:
			weakens_two_turns = true
	_expect(str(burst.get("element", "")) == "wind", "wind leader should produce wind burst")
	_expect(weakens_two_turns, "wind burst should reduce attack for 2 turns")
	_expect(int(battle.enemy_tempo_mods.get(0, {}).get("turns", 0)) == 2, "wind burst should store 2 weaken turns")
	battle.free()


func _test_dark_leader_burst_lifesteals() -> void:
	var battle := _make_battle("monster_017")
	battle.player_team[1]["hp"] = maxi(1, int(battle.player_team[1].get("maxHP", 1)) / 3)
	var before_hp := int(battle.player_team[1].get("hp", 0))
	var burst := _charge_and_consume(battle, _all_gems())
	var lifesteals := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "lifesteal" and int(effect.get("amount", 0)) > 0 and int(effect.get("source_damage", 0)) > 0:
			lifesteals = true
	_expect(str(burst.get("element", "")) == "dark", "dark leader should produce dark burst")
	_expect(lifesteals, "dark burst should heal from dealt damage")
	_expect(int(battle.player_team[1].get("hp", 0)) > before_hp, "dark lifesteal should heal the lowest ally")
	battle.free()


func _test_independent_charges_release_in_queue_order() -> void:
	var battle := _make_battle("monster_095")
	var first_id := str(battle.player_team[0].get("id", ""))
	var second_id := str(battle.player_team[1].get("id", ""))
	battle.leader_charge_points[first_id] = BattleManager.LEADER_CHARGE_MAX
	battle.leader_charge_points[second_id] = BattleManager.LEADER_CHARGE_MAX
	var first_preview := battle.get_ready_leader_burst_preview()
	_expect(str(first_preview.get("leader_id", "")) == first_id, "the first filled leader should occupy the queue head")
	var first_burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	_expect(str(first_burst.get("leader_id", "")) == first_id, "the queue should release the first filled leader first")
	_expect(int(battle.leader_charge_points.get(first_id, -1)) == 0, "the released leader should reset only its own charge")
	_expect(int(battle.leader_charge_points.get(second_id, 0)) == BattleManager.LEADER_CHARGE_MAX, "the next queued leader should retain its full charge")
	_expect(battle.is_leader_burst_ready(), "a second full leader should remain ready after the first release")
	var second_burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	_expect(str(second_burst.get("leader_id", "")) == second_id, "the queue should release the next filled leader without refilling")
	battle.free()


func _test_dead_member_does_not_block_ready() -> void:
	var battle := _make_battle("monster_093")
	battle.player_team[2]["hp"] = 0
	battle.leader_charge_points[str(battle.player_team[0].get("id", ""))] = BattleManager.LEADER_CHARGE_MAX
	battle.leader_charge_points[str(battle.player_team[1].get("id", ""))] = BattleManager.LEADER_CHARGE_MAX
	battle.leader_charge_points[str(battle.player_team[2].get("id", ""))] = 0
	_expect(battle.is_leader_burst_ready(), "dead team members should not block ready leader burst")
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	_expect(str(burst.get("leader_id", "")) == str(battle.player_team[0].get("id", "")), "living leftmost leader should release when a later member is dead")
	battle.free()


func _test_dead_leader_promotes_next_leader_skill() -> void:
	var battle := _make_battle("monster_093")
	battle.player_team[0]["hp"] = 0
	battle.leader_charge_points[str(battle.player_team[0].get("id", ""))] = 0
	battle.leader_charge_points[str(battle.player_team[1].get("id", ""))] = BattleManager.LEADER_CHARGE_MAX
	battle.leader_charge_points[str(battle.player_team[2].get("id", ""))] = BattleManager.LEADER_CHARGE_MAX
	var preview := battle.get_ready_leader_burst_preview()
	_expect(int(preview.get("leader_index", -1)) == 1, "dead leader should promote the next living member")
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	_expect(int(burst.get("leader_index", -1)) == 1, "promoted leader index should be recorded in burst log")
	_expect(str(burst.get("leader_id", "")) == str(battle.player_team[1].get("id", "")), "promoted leader should release their own leader skill")
	_expect(str(burst.get("skill_id", "")) == str(battle.player_team[1].get("leaderSkill", "")), "promoted leader burst should use the promoted member skill id")
	battle.free()


func _test_dead_same_name_member_does_not_attack_after_match() -> void:
	var battle := _make_battle("monster_093")
	var dead_monster: Dictionary = battle.player_team[0]
	var alive_monster: Dictionary = battle.player_team[1]
	var shared_name := "Same Name"
	dead_monster["name"] = shared_name
	alive_monster["name"] = shared_name
	dead_monster["hp"] = 0
	alive_monster["hp"] = int(alive_monster.get("maxHP", 1))
	for i in range(2, battle.player_team.size()):
		battle.player_team[i]["hp"] = 0
	var dead_id := str(dead_monster.get("id", ""))
	var alive_id := str(alive_monster.get("id", ""))
	battle.leader_charge_points[dead_id] = 0
	battle.leader_charge_points[alive_id] = 0
	var affinity := str(battle.call("_board_affinity", alive_monster))
	var result: Dictionary = battle.process_match_result({affinity: 3}, 1)
	var logs: Array = result.get("damage_log", [])
	_expect(logs.size() == 1, "only the living same-name member should attack after a match")
	if not logs.is_empty():
		var log: Dictionary = logs[0]
		_expect(str(log.get("attacker_id", "")) == alive_id, "match damage log should identify the living attacker id")
		_expect(int(log.get("attacker_index", -1)) == 1, "match damage log should identify the living attacker index")
	_expect(int(battle.leader_charge_points.get(dead_id, -1)) == 0, "dead same-name member should not gain leader charge")
	_expect(int(battle.leader_charge_points.get(alive_id, 0)) == 1, "living same-name member should gain leader charge")
	battle.free()


func _make_battle(leader_id: String) -> BattleManager:
	var battle := BattleManagerScript.new()
	root.add_child(battle)
	var team := [leader_id]
	for candidate in ["monster_093", "monster_002", "monster_011"]:
		if not team.has(candidate):
			team.append(candidate)
		if team.size() >= 3:
			break
	battle.init(team, ["monster_014"], 12, 4, {
		"id": "leader_charge_test",
		"enemies": ["monster_014"],
		"enemyLevel": 4,
		"disableRandomElite": true
	}, "leader_charge_test")
	battle.enemies[0]["maxHP"] = 100000
	battle.enemies[0]["hp"] = 100000
	return battle


func _all_gems() -> Dictionary:
	return {
		"fire": 8,
		"water": 8,
		"grass": 8,
		"earth": 8,
		"wind": 8,
		"thunder": 8,
		"light": 8,
		"dark": 8
	}


func _charge_and_consume(battle: BattleManager, gem_counts: Dictionary) -> Dictionary:
	for i in range(BattleManager.LEADER_CHARGE_MAX):
		var result: Dictionary = battle.process_match_result(gem_counts, 1)
		if i < BattleManager.LEADER_CHARGE_MAX - 1:
			_expect(not bool(result.get("leader_skill_pending", false)), "leader burst should not be pending before full charge")
	_expect(bool(battle.process_match_result({}, 1).get("leader_skill_pending", false)), "leader burst should be pending after full charge")
	return battle.consume_ready_leader_burst().get("leader_skill_log", {})


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LeaderCharge] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[LeaderCharge] " + failure)
	quit(1)

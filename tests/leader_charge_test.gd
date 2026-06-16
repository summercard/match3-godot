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
	_finish()


func _test_fire_leader_burst_damage() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_001", "monster_002", "monster_003"], ["enemy_001"], 10, 4)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	var before_hp := int(battle.enemies[0].get("hp", 0))
	var result: Dictionary = battle.process_match_result({"fire": 8, "water": 8, "grass": 8}, 1)
	var burst: Dictionary = result.get("leader_skill_log", {})
	_expect(not burst.is_empty(), "full leader charge should trigger a burst")
	_expect(str(burst.get("element", "")) == "fire", "fire leader should produce fire burst")
	_expect(int(burst.get("remaining_damage", 0)) > 0, "fire burst should deal damage")
	_expect(int(battle.enemies[0].get("hp", 0)) < before_hp, "fire burst should reduce enemy hp")
	for m: Dictionary in battle.player_team:
		_expect(int(battle.leader_charge_points.get(m.get("id", ""), -1)) == 0, "leader charges should reset after burst")
	battle.free()


func _test_grass_leader_burst_heal() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_003", "monster_001", "monster_002"], ["enemy_001"], 10, 4)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	battle.player_team[1]["hp"] = maxi(1, int(battle.player_team[1].get("maxHP", 1)) / 3)
	var before_hp := int(battle.player_team[1].get("hp", 0))
	var result: Dictionary = battle.process_match_result({"grass": 8, "fire": 8, "water": 8}, 1)
	var burst: Dictionary = result.get("leader_skill_log", {})
	var healed := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "heal" and int(effect.get("amount", 0)) > 0:
			healed = true
	_expect(str(burst.get("element", "")) == "grass", "grass leader should produce grass burst")
	_expect(healed, "grass burst should include a heal effect")
	_expect(int(battle.player_team[1].get("hp", 0)) > before_hp, "grass burst should heal the lowest ally")
	battle.free()


func _test_light_leader_burst_converts_gems() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_010", "monster_001", "monster_002"], ["enemy_001"], 10, 4)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	var result: Dictionary = battle.process_match_result({"light": 8, "fire": 8, "water": 8}, 1)
	var burst: Dictionary = result.get("leader_skill_log", {})
	var converts := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "convert_gems" and int(effect.get("count", 0)) == 2 and str(effect.get("target_element", "")) == "light":
			converts = true
	_expect(str(burst.get("element", "")) == "light", "light leader should produce light burst")
	_expect(converts, "light burst should request converting 2 other gems into light/star gems")
	battle.free()


func _test_wind_leader_burst_weakens_two_turns() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_016", "monster_001", "monster_002"], ["enemy_001"], 10, 4)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	var result: Dictionary = battle.process_match_result({"thunder": 8, "fire": 8, "water": 8}, 1)
	var burst: Dictionary = result.get("leader_skill_log", {})
	var weakens_two_turns := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "weaken" and int(effect.get("turns", 0)) == 2:
			weakens_two_turns = true
	_expect(str(burst.get("element", "")) == "wind", "wind leader should produce wind burst")
	_expect(weakens_two_turns, "wind burst should reduce attack for 2 turns")
	_expect(int(battle.enemy_tempo_mods.get(0, {}).get("turns", 0)) == 2, "wind burst should store 2 weaken turns")
	battle.free()


func _test_dark_leader_burst_lifesteals() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_017", "monster_001", "monster_002"], ["enemy_001"], 10, 4)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	battle.player_team[1]["hp"] = maxi(1, int(battle.player_team[1].get("maxHP", 1)) / 3)
	var before_hp := int(battle.player_team[1].get("hp", 0))
	var result: Dictionary = battle.process_match_result({"light": 8, "fire": 8, "water": 8}, 1)
	var burst: Dictionary = result.get("leader_skill_log", {})
	var lifesteals := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "lifesteal" and int(effect.get("amount", 0)) > 0 and int(effect.get("source_damage", 0)) > 0:
			lifesteals = true
	_expect(str(burst.get("element", "")) == "dark", "dark leader should produce dark burst")
	_expect(lifesteals, "dark burst should heal from dealt damage")
	_expect(int(battle.player_team[1].get("hp", 0)) > before_hp, "dark lifesteal should heal the lowest ally")
	battle.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LeaderCharge] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[LeaderCharge] " + failure)
		quit(1)

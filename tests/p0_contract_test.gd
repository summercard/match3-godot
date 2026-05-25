extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const CaptureSystemScript = preload("res://src/battle/capture_system.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_board_affinity_contract()
	_test_skill_effect_contract()
	_test_capture_window_contract()
	_finish()


func _test_board_affinity_contract() -> void:
	var ice_stats: Dictionary = MonsterDbScript.get_monster_stats("monster_033", 1)
	_expect(ice_stats.get("element", "") == "ice", "ice monster should keep fantasy element")
	_expect(ice_stats.get("boardAffinity", "") == "water", "ice monster should map to water board affinity")

	var battle = BattleManagerScript.new()
	battle.init(["monster_033"], ["enemy_001"], 5, 1)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	var monster_id := str(battle.player_team[0].get("id", ""))

	var water_result: Dictionary = battle.process_match_result({"water": 3}, 1)
	_expect(water_result.get("damage_log", []).size() == 1, "board affinity gems should trigger damage")
	_expect(int(battle.skill_charges.get(monster_id, 0)) == 3, "board affinity gems should charge skill")

	var hp_after_water := int(battle.enemies[0].get("hp", 0))
	var ice_result: Dictionary = battle.process_match_result({"ice": 3}, 1)
	_expect(ice_result.get("damage_log", []).is_empty(), "fantasy element without board gem should not trigger damage")
	_expect(int(battle.enemies[0].get("hp", 0)) == hp_after_water, "non-board fantasy gem should not change hp")
	battle.free()


func _test_skill_effect_contract() -> void:
	var battle = BattleManagerScript.new()
	battle.init(["monster_002", "monster_003", "monster_001"], ["enemy_001"], 5, 1)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000

	var warder: Dictionary = battle.player_team[0]
	var warder_id := str(warder.get("id", ""))
	warder["hp"] = maxi(1, int(warder.get("maxHP", 1)) / 2)
	var hp_before := int(warder.get("hp", 0))
	var ward_cost := int(warder.get("skill", {}).get("cost", 0))
	battle.skill_charges[warder_id] = ward_cost
	var ward_result: Dictionary = battle.use_active_skill(warder_id)
	_expect(ward_result.get("success", false), "ward skill should release")
	_expect(ward_result.get("skill_type", "") == "ward", "water starter should be a ward skill")
	_expect(_has_effect(ward_result, "heal"), "ward skill should include heal effect")
	_expect(_has_effect(ward_result, "guard"), "ward skill should include guard effect")
	_expect(int(warder.get("hp", 0)) > hp_before, "ward skill should restore hp")
	_expect(battle.player_guards.has(warder_id), "ward skill should register one guard")

	var tempo_user: Dictionary = battle.player_team[1]
	var tempo_id := str(tempo_user.get("id", ""))
	var tempo_cost := int(tempo_user.get("skill", {}).get("cost", 0))
	battle.skill_charges[tempo_id] = tempo_cost
	var tempo_result: Dictionary = battle.use_active_skill(tempo_id)
	_expect(tempo_result.get("success", false), "tempo skill should release")
	_expect(tempo_result.get("skill_type", "") == "tempo", "grass starter should be a tempo skill")
	_expect(_has_effect(tempo_result, "damage"), "tempo skill should include damage effect")
	_expect(_has_effect(tempo_result, "weaken"), "tempo skill should include weaken effect")
	_expect(battle.enemy_tempo_mods.has(0), "tempo skill should register enemy weaken")
	battle.free()


func _test_capture_window_contract() -> void:
	var locked: Dictionary = CaptureSystemScript.calc_taming_window(90, 100)
	var open: Dictionary = CaptureSystemScript.calc_taming_window(25, 100)
	var prime: Dictionary = CaptureSystemScript.calc_taming_window(10, 100)
	var overpowered: Dictionary = CaptureSystemScript.calc_taming_window(0, 100)
	var suppressed: Dictionary = CaptureSystemScript.calc_taming_window(70, 100, {"suppressed": true})

	_expect(locked.get("state", "") == "locked", "high hp target should be locked")
	_expect(open.get("state", "") == "open", "low hp target should open capture window")
	_expect(prime.get("state", "") == "prime", "very low hp target should be prime")
	_expect(overpowered.get("state", "") == "overpowered", "defeated target should be overpowered")
	_expect(suppressed.get("state", "") == "unstable", "suppressed target should start unstable window")
	_expect(float(prime.get("bonus", 0.0)) > float(open.get("bonus", 0.0)), "prime window should beat open bonus")

	var no_window_prob := CaptureSystemScript.calc_capture_probability(25, 100, 5, 5, 2)
	var window_prob := CaptureSystemScript.calc_capture_probability(25, 100, 5, 5, 2, {"taming_window": open})
	_expect(window_prob > no_window_prob, "taming window should increase capture probability")

	var battle = BattleManagerScript.new()
	battle.init(["monster_001"], ["enemy_001"], 5, 1)
	battle.enemies[0]["maxHP"] = 100
	battle.enemies[0]["hp"] = 25
	battle.call("_refresh_capture_windows")
	var candidate: Dictionary = battle.get_best_capture_candidate()
	_expect(not candidate.is_empty(), "battle should expose best capture candidate")
	_expect(candidate.get("window", {}).get("state", "") == "open", "best capture candidate should carry open window")
	battle.enemies[0]["hp"] = 10
	battle.call("_refresh_capture_windows")
	candidate = battle.get_best_capture_candidate()
	_expect(candidate.get("window", {}).get("state", "") == "prime", "best capture candidate should update to prime")
	battle.free()


func _has_effect(result: Dictionary, kind: String) -> bool:
	for effect: Dictionary in result.get("effect_logs", []):
		if effect.get("kind", "") == kind:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[P0Contract] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[P0Contract] " + failure)
		quit(1)

extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const CaptureSystemScript = preload("res://src/battle/capture_system.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")
const MonsterPoolScript = preload("res://src/core/monster_pool.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_board_affinity_contract()
	_test_skill_effect_contract()
	_test_capture_window_contract()
	_finish()


func _test_board_affinity_contract() -> void:
	var starter_ids: Array = MonsterPoolScript.DEFAULT_STARTERS
	_expect(not starter_ids.is_empty(), "current starter roster should exist")
	if starter_ids.is_empty():
		return
	var monster_id := str(starter_ids[0])
	var starter_stats: Dictionary = MonsterDbScript.get_monster_stats(monster_id, 1)
	var affinity := str(starter_stats.get("boardAffinity", ""))
	_expect(not affinity.is_empty(), "current starter should expose board affinity")

	var battle = BattleManagerScript.new()
	battle.init([monster_id], ["enemy_001"], 5, 1)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	monster_id = str(battle.player_team[0].get("id", ""))

	var affinity_result: Dictionary = battle.process_match_result({affinity: 3}, 1)
	_expect(affinity_result.get("damage_log", []).size() == 1, "board affinity gems should trigger damage")
	_expect(int(battle.skill_charges.get(monster_id, 0)) == 3, "board affinity gems should charge skill")

	var hp_after_affinity := int(battle.enemies[0].get("hp", 0))
	var other_affinity := "fire" if affinity != "fire" else "water"
	var other_result: Dictionary = battle.process_match_result({other_affinity: 3}, 1)
	_expect(other_result.get("damage_log", []).is_empty(), "non-affinity gems should not trigger the active starter")
	_expect(int(battle.enemies[0].get("hp", 0)) == hp_after_affinity, "non-affinity gems should not change hp")
	battle.free()


func _test_skill_effect_contract() -> void:
	var battle = BattleManagerScript.new()
	battle.init(MonsterPoolScript.DEFAULT_STARTERS, ["enemy_001"], 5, 1)
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	for user: Dictionary in battle.player_team:
		var user_id := str(user.get("id", ""))
		var cost := int(user.get("skill", {}).get("cost", 0))
		_expect(cost > 0, "each current starter should expose an active skill cost")
		battle.skill_charges[user_id] = cost
		var result: Dictionary = battle.use_active_skill(user_id)
		_expect(result.get("success", false), "charged current starter skill should release")
		_expect(not result.get("effect_logs", []).is_empty(), "starter skill should expose resolved effects")
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

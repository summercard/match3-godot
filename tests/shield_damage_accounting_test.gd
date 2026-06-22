extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_001"], ["monster_boss_002"], 1, 1)
	var enemy: Dictionary = battle.enemies[0]
	var enemy_hp_before := int(enemy.get("hp", 0))
	var skill_system = battle.get("_enemy_skill_system")
	var shield_state: Dictionary = skill_system.get_skill_state(0, "shield")
	shield_state["current_hp"] = 10000
	shield_state["max_hp"] = 10000

	seed(20260622)
	var result: Dictionary = battle.process_match_result({"fire": 3}, 1)
	var logs: Array = result.get("damage_log", [])
	_expect(logs.size() == 1, "one matching attacker should produce one damage log")
	if not logs.is_empty():
		var log: Dictionary = logs[0]
		var raw_damage := int(log.get("raw_damage", 0))
		_expect(raw_damage > 0, "raw damage should remain visible for shield feedback")
		_expect(int(log.get("damage", -1)) == 0, "fully absorbed damage should report zero HP damage")
		_expect(int(log.get("shield_absorbed", -1)) == raw_damage, "shield absorption should equal raw damage")
	_expect(int(enemy.get("hp", 0)) == enemy_hp_before, "fully absorbed damage must not reduce enemy HP")
	var monster_id := str(battle.player_team[0].get("id", ""))
	_expect(int(battle.total_damage_dealt.get(monster_id, 0)) == 0, "absorbed damage must not inflate total damage dealt")
	battle.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ShieldDamageAccounting] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[ShieldDamageAccounting] " + failure)
	quit(1)

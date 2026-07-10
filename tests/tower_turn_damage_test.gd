extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BattleManagerScript.new()
	root.add_child(battle)
	var stage := {
		"id": "tower_turn_test", "mode": "tower", "enemies": ["monster_001"],
		"enemyLevel": 5, "maxTurns": 30, "disableRandomElite": true,
		"towerBuffs": [{"id": "strike_resonance", "damage_bonus": 0.18}]
	}
	battle.init(["monster_001", "monster_002", "monster_003"], ["monster_001"], 20, 5, stage, "tower_turn_test")
	battle.begin_player_turn()
	var result: Dictionary = battle.process_match_result({"fire": 3, "water": 3, "grass": 3}, 1)
	var sum := 0
	for log in result.get("damage_log", []):
		if log is Dictionary:
			sum += int((log as Dictionary).get("damage", 0))
	_expect(sum > 0, "tower match should deal player damage")
	_expect(int(battle.current_player_turn_damage) == sum, "current turn damage should aggregate match damage")
	_expect(int(battle.highest_player_turn_damage) == sum, "highest turn damage should record match total")
	var continuation := battle.get_tower_continuation()
	_expect(int(continuation.get("highest_turn_damage", 0)) == sum, "tower continuation should expose explosion record")
	battle.begin_tower_wave({
		"id": "tower_turn_test_2", "mode": "tower", "enemies": ["monster_002", "monster_003", "monster_004"],
		"enemyLevel": 6, "maxTurns": 30, "disableRandomElite": true, "towerBuffs": []
	})
	_expect(not battle.battle_over and battle.enemies.size() == 3, "next tower wave should replace enemies without resetting battle object")
	_expect(int(battle.highest_player_turn_damage) == sum, "next wave should preserve highest turn record")
	battle.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TowerTurnDamage] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TowerTurnDamage] " + failure)
	quit(1)

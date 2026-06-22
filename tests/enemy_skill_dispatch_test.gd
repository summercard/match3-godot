extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	var stage := {
		"id": "enemy_skill_dispatch",
		"enemies": ["enemy_001"],
		"enemyLevel": 1,
		"maxTurns": 10,
		"rewards": {"gold": 1, "exp": 1}
	}
	battle.init(["monster_001"], ["enemy_001"], 5, 1, stage, "enemy_skill_dispatch")
	battle.enemies[0]["atk"] = 1
	battle.enemies[0]["enemySkills"] = [
		{"type": "poison", "damage_per_stack": 7, "max_stacks": 3, "interval": 2}
	]
	battle.get("_enemy_skill_system").init_skill_state(battle.enemies)
	var hp_before := int(battle.player_team[0].get("hp", 0))
	var first: Dictionary = battle.enemy_action()
	_expect(_has_skill_action(first.get("actions", []), "poison_apply"), "poison should be applied through the formal enemy turn")
	var second: Dictionary = battle.enemy_action()
	_expect(_has_skill_action(second.get("actions", []), "poison_damage"), "poison damage should be returned as a formal enemy action")
	_expect(int(battle.player_team[0].get("hp", 0)) < hp_before, "poison dispatch should change player HP, not only emit signals")

	battle.queue_free()
	await process_frame
	_finish()


func _has_skill_action(actions: Array, skill_type: String) -> bool:
	for action in actions:
		if action is Dictionary and bool(action.get("is_enemy_skill", false)) and str(action.get("skill_type", "")) == skill_type:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EnemySkillDispatch] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[EnemySkillDispatch] " + failure)
	quit(1)

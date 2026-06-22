extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StatusEffectScript = preload("res://src/battle/status_effect.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_one_turn_stun_skips_exactly_one_action()
	_test_enemy_attacks_rotate_one_at_a_time()
	_test_two_turn_freeze_remains_active_for_two_actions()
	_test_dot_ticks_for_its_full_duration()
	_finish()


func _test_one_turn_stun_skips_exactly_one_action() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_001"], ["enemy_001"], 5, 1)
	var status = battle.get("_status_effect")
	status.apply_status(0, "stun", 10, str(battle.enemies[0].get("name", "")))
	var player_hp_before := int(battle.player_team[0].get("hp", 0))
	var result: Dictionary = battle.enemy_action()
	var actions: Array = result.get("actions", [])
	_expect(actions.size() == 1, "stunned enemy should still produce one skipped-action log")
	if not actions.is_empty():
		_expect(bool(actions[0].get("is_stunned", false)), "one-turn stun should skip the current enemy action")
	_expect(int(battle.player_team[0].get("hp", 0)) == player_hp_before, "stunned enemy must not damage the player")
	_expect(status.get_effects_snapshot()[0] == null, "one-turn stun should expire after the skipped action")
	battle.free()


func _test_enemy_attacks_rotate_one_at_a_time() -> void:
	var battle = BattleManagerScript.new()
	root.add_child(battle)
	battle.init(["monster_001"], ["enemy_001", "enemy_001", "enemy_001"], 5, 1)
	for member: Dictionary in battle.player_team:
		member["hp"] = 99999
		member["maxHP"] = 99999
	for enemy: Dictionary in battle.enemies:
		enemy["atk"] = 1
	var expected := [0, 1, 2, 0]
	for turn_idx in range(expected.size()):
		var result: Dictionary = battle.enemy_action()
		var attacks: Array = []
		for action in result.get("actions", []):
			if action is Dictionary and not bool(action.get("is_enemy_skill", false)) and int(action.get("damage", 0)) >= 0 and action.has("enemy_index"):
				attacks.append(action)
		_expect(attacks.size() == 1, "enemy turn should contain exactly one enemy attack")
		if not attacks.is_empty():
			_expect(int((attacks[0] as Dictionary).get("enemy_index", -1)) == int(expected[turn_idx]), "enemy attacks should rotate left-to-right")
	battle.free()


func _test_two_turn_freeze_remains_active_for_two_actions() -> void:
	var status = StatusEffectScript.new()
	status.init_effects(1)
	var enemies: Array = [{"name": "冰冻目标", "hp": 1000, "maxHP": 1000}]
	status.apply_status(0, "freeze", 10, "冰冻目标")

	status.begin_enemy_turn(enemies)
	_expect(is_equal_approx(status.get_freeze_atk_multiplier(0), 0.7), "freeze should reduce attack on its first action")
	status.end_enemy_turn(enemies)
	var first_snapshot: Array = status.get_effects_snapshot()
	_expect(first_snapshot[0] != null and int(first_snapshot[0].get("turns_left", 0)) == 1, "two-turn freeze should keep one turn after the first action")

	status.begin_enemy_turn(enemies)
	_expect(is_equal_approx(status.get_freeze_atk_multiplier(0), 0.7), "freeze should reduce attack on its second action")
	status.end_enemy_turn(enemies)
	_expect(status.get_effects_snapshot()[0] == null, "freeze should expire after its second action")
	_expect(is_equal_approx(status.get_freeze_atk_multiplier(0), 1.0), "expired freeze should no longer reduce attack")


func _test_dot_ticks_for_its_full_duration() -> void:
	var status = StatusEffectScript.new()
	status.init_effects(1)
	var enemies: Array = [{"name": "灼烧目标", "hp": 1000, "maxHP": 1000}]
	status.apply_status(0, "burn", 100, "灼烧目标")
	for _turn in range(3):
		status.begin_enemy_turn(enemies)
		status.end_enemy_turn(enemies)
	_expect(int(enemies[0].get("hp", 0)) == 955, "three-turn burn should deal three 15-point ticks")
	_expect(status.get_effects_snapshot()[0] == null, "burn should expire after its third tick")
	status.begin_enemy_turn(enemies)
	_expect(int(enemies[0].get("hp", 0)) == 955, "expired burn must not deal a fourth tick")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[StatusEffectTurnOrder] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[StatusEffectTurnOrder] " + failure)
	quit(1)

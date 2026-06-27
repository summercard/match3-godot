extends SceneTree

const DamageCalculatorScript = preload("res://src/battle/damage_calculator.gd")
const ElementRulesScript = preload("res://src/battle/element_rules.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_all_element_entry_points_share_one_matrix()
	_test_removed_elements_are_neutral()
	_finish()


func _test_all_element_entry_points_share_one_matrix() -> void:
	_expect(ElementRulesScript.ELEMENTS.size() == 8, "battle rules should expose the 8 active fantasy elements")
	for attacker in ElementRulesScript.ELEMENTS:
		_expect(ElementRulesScript.is_known_element(attacker), "%s should be a known fantasy element" % attacker)
		for defender in ElementRulesScript.ELEMENTS:
			var expected := ElementRulesScript.get_multiplier(attacker, defender)
			var player_value := MonsterDbScript.get_element_multiplier(attacker, defender)
			var enemy_value := DamageCalculatorScript.get_element_multiplier(attacker, defender)
			_expect(is_equal_approx(player_value, expected), "player multiplier drifted for %s -> %s" % [attacker, defender])
			_expect(is_equal_approx(enemy_value, expected), "enemy multiplier drifted for %s -> %s" % [attacker, defender])

	_expect(is_equal_approx(ElementRulesScript.get_multiplier("fire", "grass"), 1.5), "strong relation should use 1.5x")
	_expect(is_equal_approx(ElementRulesScript.get_multiplier("fire", "water"), 0.75), "weak relation should use 0.75x")
	_expect(is_equal_approx(ElementRulesScript.get_multiplier("unknown", "fire"), 1.0), "unknown attacker should remain neutral")


func _test_removed_elements_are_neutral() -> void:
	for element in ["ice", "void", "temporal", "star", "chaos"]:
		_expect(not ElementRulesScript.is_known_element(element), "%s should not be a battle-rule element" % element)
		_expect(is_equal_approx(ElementRulesScript.get_multiplier(element, "fire"), 1.0), "%s attacker should be neutral" % element)
		_expect(is_equal_approx(ElementRulesScript.get_multiplier("fire", element), 1.0), "%s defender should be neutral" % element)

	seed(20260622)
	var fire_target := DamageCalculatorScript.calc_enemy_damage(100.0, "chaos", 0.0, "fire")
	seed(20260622)
	var water_target := DamageCalculatorScript.calc_enemy_damage(100.0, "chaos", 0.0, "water")
	seed(20260622)
	var grass_target := DamageCalculatorScript.calc_enemy_damage(100.0, "chaos", 0.0, "grass")
	_expect(fire_target == water_target and water_target == grass_target, "removed elements should deal neutral enemy damage")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ElementMatrix] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[ElementMatrix] " + failure)
	quit(1)

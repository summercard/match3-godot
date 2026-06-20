extends SceneTree

const DamageCalculatorScript = preload("res://src/battle/damage_calculator.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var three_star := StatCalculator.calc("monster_006", 80, "")
	var four_star := StatCalculator.calc("monster_014", 80, "")
	var legacy_three_star := MonsterDb.get_monster_stats("monster_006", 80, "")

	_expect(int(three_star.get("def", 0)) == 45, "three-star Lv80 DEF should use flat growth")
	_expect(int(legacy_three_star.get("def", 0)) == int(three_star.get("def", 0)), "legacy UI stats should match battle DEF")
	_expect(is_equal_approx(DamageCalculatorScript.get_defense_reduction(float(three_star.get("def", 0))), 45.0 / 245.0), "three-star Lv80 reduction should be near twenty percent")
	_expect(DamageCalculatorScript.get_defense_reduction(float(four_star.get("def", 0))) <= 0.25, "high-base-defense monsters should respect the reduction cap")
	_expect(is_equal_approx(DamageCalculatorScript.get_defense_reduction(1000000.0), 0.25), "DEF reduction should never exceed twenty-five percent")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[DefenseCurve] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[DefenseCurve] " + failure)
	quit(1)

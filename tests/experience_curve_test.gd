extends SceneTree

const GrowthRulesScript = preload("res://src/core/growth_rules.gd")
const GrowthSystemScript = preload("res://src/growth/growth_system.gd")
const MonsterPoolScript = preload("res://src/core/monster_pool.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(GrowthRulesScript.get_exp_for_level(1) == 90, "Lv1 requirement should remain 90")
	_expect(GrowthRulesScript.get_exp_for_level(30) == 380, "Lv30 requirement should remain on the original curve")
	_expect(GrowthRulesScript.get_exp_for_level(31) == 391, "late-growth term should begin after Lv30")
	_expect(GrowthRulesScript.get_exp_for_level(40) == 580, "Lv40 requirement should include late growth")
	_expect(GrowthRulesScript.get_exp_for_level(50) == 980, "Lv50 requirement should include late growth")
	_expect(GrowthRulesScript.get_exp_for_level(60) == 1580, "Lv60 requirement should include late growth")
	_expect(GrowthRulesScript.get_exp_for_level(79) == 3271, "Lv79 requirement should include late growth")
	_expect(GrowthRulesScript.get_total_exp_for_level(80) == 78345, "Lv80 cumulative requirement should match the new curve")
	_expect(GrowthSystemScript.get_exp_for_level(60) == GrowthRulesScript.get_exp_for_level(60), "GrowthSystem should use the shared curve")

	var instance := {"monsterId": "monster_001", "level": 60, "exp": 0}
	var before_level_result := MonsterPoolScript.add_instance_exp(instance, 1579)
	_expect(not bool(before_level_result.get("leveledUp", false)), "1579 EXP should not level a Lv60 monster")
	var level_result := MonsterPoolScript.add_instance_exp(instance, 1)
	_expect(bool(level_result.get("leveledUp", false)) and int(instance.get("level", 0)) == 61, "1580 total EXP should level a Lv60 monster")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ExperienceCurve] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[ExperienceCurve] " + failure)
	quit(1)

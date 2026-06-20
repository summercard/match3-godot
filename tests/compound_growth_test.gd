extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var expected_rates := {1: 0.05, 2: 0.07, 3: 0.08, 4: 0.12, 5: 0.15}
	for rarity: int in expected_rates:
		var rate := float(expected_rates[rarity])
		var level_10 := StatCalculator.growth_mult(10, rarity)
		var level_11 := StatCalculator.growth_mult(11, rarity)
		_assert(is_equal_approx(level_11 / level_10, 1.0 + rate), "rarity %d should compound by %.0f%% each level" % [rarity, rate * 100.0])

	var level_1 := StatCalculator.calc("monster_001", 1, "")
	var level_2 := StatCalculator.calc("monster_001", 2, "")
	var level_20 := StatCalculator.calc("monster_001", 20, "")
	for stat_key in ["hp", "atk", "spd"]:
		var expected_level_2 := int(float(level_1.get(stat_key, 0)) * 1.07)
		_assert(int(level_2.get(stat_key, 0)) == expected_level_2, "two-star %s should grow seven percent from level 1 to level 2" % stat_key)
	_assert(int(level_2.get("def", 0)) == int(level_1.get("def", 0)), "DEF should use small flat increments instead of percentage growth")
	var expected_level_20_hp := int(float(level_1.get("hp", 0)) * pow(1.07, 19.0))
	_assert(int(level_20.get("hp", 0)) == expected_level_20_hp, "level 20 HP should use compounded growth")
	_assert(float(level_20.get("hp", 0)) / float(level_1.get("hp", 1)) > 3.5, "two-star level 20 should exceed three and a half times its level 1 HP")

	if _failures.is_empty():
		print("[CompoundGrowth] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[CompoundGrowth] " + failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

extends SceneTree

func _init() -> void:
	var one_star := StatCalculator.calc("monster_002", 1)
	_expect_scale(one_star, 0.8, "1-star monster should use 0.8x visual scale")

	var two_star := StatCalculator.calc("monster_003", 1)
	_expect_scale(two_star, 1.0, "2-star monster should use 1.0x visual scale")

	var three_star := StatCalculator.calc("monster_004", 1)
	_expect_scale(three_star, 1.2, "3-star monster should use 1.2x visual scale")

	var four_star := StatCalculator.calc("monster_boss_001", 1)
	_expect_scale(four_star, 1.4, "4-star monster should use 1.4x visual scale")

	var five_star := StatCalculator.calc("monster_002", 1, "", 5)
	_expect_scale(five_star, 1.6, "5-star monster should use 1.6x visual scale")

	var elite := StatCalculator.calc_with_tier("monster_002", 1, "", StatCalculator.EnemyTier.ELITE)
	_expect_scale(elite, 0.96, "elite monster should multiply rarity scale by 1.2")

	var phase_handler := PhaseHandler.new(null)
	var phase_enemies := phase_handler.execute_phase_transition({
		"phase": 2,
		"trigger": "on_enter",
		"hpMultiplier": 1.3,
		"enemies": ["monster_boss_001"],
	}, 5, 0.5)
	_expect_scale(phase_enemies[0], 2.1, "phase 2 should multiply the rarity scale by the existing 1.5x phase scale")

	print("[MonsterVisualScale] OK")
	quit(0)

func _expect_scale(monster: Dictionary, expected: float, message: String) -> void:
	var actual := float(monster.get("_visualScale", -1.0))
	assert(is_equal_approx(actual, expected), "%s: got %.3f expected %.3f" % [message, actual, expected])

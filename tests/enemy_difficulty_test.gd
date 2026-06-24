extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_assert(StatCalculator.enemy_combat_level("enemy_001", 10) == 15, "ordinary enemy should gain five levels")
	_assert(StatCalculator.enemy_combat_level("monster_boss_001", 10) == 10, "boss should keep its stage level")
	_assert(StatCalculator.enemy_combat_level("enemy_001", StatCalculator.MAX_LEVEL) == StatCalculator.MAX_LEVEL, "enemy level bonus should respect the level cap")

	var boosted := StatCalculator.apply_enemy_difficulty({"hp": 100, "maxHP": 100, "atk": 100})
	_assert(int(boosted.get("hp", 0)) == 100 and int(boosted.get("maxHP", 0)) == 100, "enemy compatibility path must not add a second HP formula")
	_assert(int(boosted.get("atk", 0)) == 100, "enemy compatibility path must not add a second attack formula")

	var ordinary := StatCalculator.calc_enemy("enemy_001", 10)
	var boss := StatCalculator.calc_enemy("monster_boss_001", 10)
	_assert(int(ordinary.get("level", 0)) == 15, "runtime ordinary enemy should use the boosted level")
	_assert(int(boss.get("level", 0)) == 10, "runtime boss should not receive the ordinary level bonus")
	_test_boss_owned_base_near_chapter_enemies()
	_test_enemy_boss_multiplier_is_runtime_only()

	var player_base := StatCalculator.calc("monster_001", 10, "")
	var player_tier := StatCalculator.calc_with_tier("monster_001", 10, "", StatCalculator.EnemyTier.NORMAL)
	_assert(int(player_tier.get("level", 0)) == 10, "captured player monster level should remain unchanged")
	_assert(player_tier == player_base, "tier compatibility path must use the same base, level, and nature formula")

	var owned_base := StatCalculator.calc("enemy_001", 10, "brave")
	var owned_elite := StatCalculator.calc_with_tier("enemy_001", 10, "brave", StatCalculator.EnemyTier.ELITE)
	_assert(int(owned_elite.get("hp", 0)) == int(float(owned_base.get("hp", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent HP")
	_assert(int(owned_elite.get("atk", 0)) == int(float(owned_base.get("atk", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent ATK")
	_assert(int(owned_elite.get("def", 0)) == int(float(owned_base.get("def", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent DEF")
	_assert(int(owned_elite.get("spd", 0)) == int(float(owned_base.get("spd", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent SPD")

	var enemy_elite := StatCalculator.calc_enemy("enemy_001", 10, StatCalculator.EnemyTier.ELITE)
	var enemy_base := StatCalculator.calc("enemy_001", StatCalculator.enemy_combat_level("enemy_001", 10), str(enemy_elite.get("nature", "")))
	var elite_base_hp := int(float(enemy_base.get("hp", 0)) * StatCalculator.ELITE_BASE_STAT_MULT)
	var elite_base_atk := int(float(enemy_base.get("atk", 0)) * StatCalculator.ELITE_BASE_STAT_MULT)
	_assert(int(enemy_elite.get("hp", 0)) == int(float(elite_base_hp) * StatCalculator.ELITE_ENEMY_HP_MULT), "enemy elite should double HP after elite base bonus")
	_assert(int(enemy_elite.get("atk", 0)) == int(float(elite_base_atk) * StatCalculator.ELITE_ENEMY_ATK_MULT), "enemy elite should gain 1.5x ATK after elite base bonus")

	if _failures.is_empty():
		print("[EnemyDifficulty] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[EnemyDifficulty] " + failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)


func _test_boss_owned_base_near_chapter_enemies() -> void:
	var chapter_enemy_ids := {
		1: ["enemy_001", "enemy_002", "enemy_003"],
		2: ["enemy_047", "enemy_048", "enemy_049"],
		3: ["enemy_004", "enemy_005", "enemy_006", "enemy_007", "enemy_008"],
		4: ["enemy_009", "enemy_010", "enemy_011"],
		5: ["enemy_012", "enemy_013", "enemy_014", "enemy_015", "enemy_016"],
		6: ["enemy_017", "enemy_018", "enemy_019", "enemy_020", "enemy_021"],
		7: ["enemy_022", "enemy_023", "enemy_024", "enemy_025", "enemy_026"],
		8: ["enemy_027", "enemy_028", "enemy_029", "enemy_030", "enemy_031"],
		9: ["enemy_032", "enemy_033", "enemy_034", "enemy_035", "enemy_036"],
		10: ["enemy_037", "enemy_038", "enemy_039", "enemy_040", "enemy_041"],
		11: ["enemy_042", "enemy_043", "enemy_044", "enemy_045", "enemy_046"]
	}
	var stat_keys := {
		"baseHP": "hp",
		"baseATK": "atk",
		"baseDEF": "def",
		"baseSPD": "spd"
	}
	for chapter_num in chapter_enemy_ids.keys():
		var ids: Array = chapter_enemy_ids[chapter_num]
		var boss_data: Dictionary = MonsterDb.MONSTER_DB.get("monster_boss_%03d" % int(chapter_num), {})
		_assert(not boss_data.is_empty(), "chapter %d should have a boss monster template" % int(chapter_num))
		if boss_data.is_empty():
			continue
		for base_key in stat_keys.keys():
			var total := 0.0
			for enemy_id in ids:
				var enemy_data: Dictionary = MonsterDb.MONSTER_DB.get(str(enemy_id), {})
				total += float(enemy_data.get(str(base_key), 0))
			var average := total / float(ids.size())
			var ratio := float(boss_data.get(str(base_key), 0)) / maxf(1.0, average)
			_assert(ratio >= 0.95 and ratio <= 1.16, "boss chapter %d %s should stay near ordinary enemy baseline" % [int(chapter_num), str(base_key)])


func _test_enemy_boss_multiplier_is_runtime_only() -> void:
	var owned_boss := StatCalculator.calc("monster_boss_001", 20, "")
	var enemy_boss := StatCalculator.calc_enemy("monster_boss_001", 20)
	var multiplier: Dictionary = enemy_boss.get("enemyBossMultiplier", {})
	_assert(not owned_boss.has("enemyBossMultiplier"), "owned boss stats should not include enemy-only boss multiplier")
	_assert(enemy_boss.has("enemyBossMultiplier"), "enemy boss stats should expose the applied boss multiplier for debugging")
	_assert(is_equal_approx(float(multiplier.get("hp", 0.0)), 5.0), "enemy boss HP multiplier should use the clean boss pressure value")
	_assert(is_equal_approx(float(multiplier.get("atk", 0.0)), 1.2), "enemy boss ATK multiplier should use the clean boss pressure value")
	_assert(is_equal_approx(float(multiplier.get("def", 0.0)), 2.0), "enemy boss DEF multiplier should use the clean boss pressure value")
	_assert(is_equal_approx(float(multiplier.get("spd", 0.0)), 1.0), "enemy boss SPD multiplier should stay neutral")
	_assert(int(enemy_boss.get("hp", 0)) >= int(owned_boss.get("hp", 0)) * 4, "enemy boss HP should gain boss pressure after level growth")
	_assert(int(enemy_boss.get("atk", 0)) >= int(owned_boss.get("atk", 0)), "enemy boss ATK should not be lower than the owned baseline")

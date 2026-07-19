extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_assert(StatCalculator.enemy_combat_level("monster_001", 10) == 13, "ordinary enemy should gain three levels")
	_assert(StatCalculator.enemy_combat_level("monster_boss_001", 10) == 10, "boss should keep its stage level")
	_assert(StatCalculator.enemy_combat_level("monster_001", StatCalculator.MAX_LEVEL) == StatCalculator.MAX_LEVEL, "enemy level bonus should respect the level cap")

	var boosted := StatCalculator.apply_enemy_difficulty({"hp": 100, "maxHP": 100, "atk": 100})
	_assert(int(boosted.get("hp", 0)) == 100 and int(boosted.get("maxHP", 0)) == 100, "enemy compatibility path must not add a second HP formula")
	_assert(int(boosted.get("atk", 0)) == 100, "enemy compatibility path must not add a second attack formula")

	var ordinary := StatCalculator.calc_enemy("monster_001", 10)
	var boss := StatCalculator.calc_enemy("monster_boss_001", 10)
	_assert(int(ordinary.get("level", 0)) == 13, "runtime ordinary enemy should use the boosted level")
	_assert(int(boss.get("level", 0)) == 10, "runtime boss should not receive the ordinary level bonus")
	_test_stage_enemy_modifier(ordinary)
	_test_boss_owned_base_near_chapter_enemies()
	_test_enemy_boss_multiplier_is_runtime_only()

	var player_base := StatCalculator.calc("monster_001", 10, "")
	var player_tier := StatCalculator.calc_with_tier("monster_001", 10, "", StatCalculator.EnemyTier.NORMAL)
	_assert(int(player_tier.get("level", 0)) == 10, "captured player monster level should remain unchanged")
	_assert(player_tier == player_base, "tier compatibility path must use the same base, level, and nature formula")

	var owned_base := StatCalculator.calc("monster_001", 10, "brave")
	var owned_elite := StatCalculator.calc_with_tier("monster_001", 10, "brave", StatCalculator.EnemyTier.ELITE)
	_assert(int(owned_elite.get("hp", 0)) == int(float(owned_base.get("hp", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent HP")
	_assert(int(owned_elite.get("atk", 0)) == int(float(owned_base.get("atk", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent ATK")
	_assert(int(owned_elite.get("def", 0)) == int(float(owned_base.get("def", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent DEF")
	_assert(int(owned_elite.get("spd", 0)) == int(float(owned_base.get("spd", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite should gain 10 percent SPD")

	var enemy_elite := StatCalculator.calc_enemy("monster_001", 10, StatCalculator.EnemyTier.ELITE)
	var enemy_base := StatCalculator.calc("monster_001", StatCalculator.enemy_combat_level("monster_001", 10), str(enemy_elite.get("nature", "")))
	var elite_base_hp := int(float(enemy_base.get("hp", 0)) * StatCalculator.ELITE_BASE_STAT_MULT)
	var elite_base_atk := int(float(enemy_base.get("atk", 0)) * StatCalculator.ELITE_BASE_STAT_MULT)
	var elite_enemy_hp := int(float(elite_base_hp) * StatCalculator.ELITE_ENEMY_HP_MULT)
	var elite_enemy_atk := int(float(elite_base_atk) * StatCalculator.ELITE_ENEMY_ATK_MULT)
	_assert(int(enemy_elite.get("hp", 0)) == int(float(elite_enemy_hp) * StatCalculator.STAGE_ENEMY_HP_MULT), "enemy elite should receive the runtime-only 15 percent HP increase")
	_assert(int(enemy_elite.get("atk", 0)) == int(float(elite_enemy_atk) * StatCalculator.STAGE_ENEMY_ATK_MULT), "enemy elite should receive the runtime-only 15 percent ATK reduction")

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


func _test_stage_enemy_modifier(enemy: Dictionary) -> void:
	var owned_same_roll := StatCalculator.calc("monster_001", int(enemy.get("level", 1)), str(enemy.get("nature", "")))
	var species: Dictionary = MonsterDb.get_monster("monster_001")
	_assert(int(enemy.get("hp", 0)) == int(float(owned_same_roll.get("hp", 0)) * StatCalculator.STAGE_ENEMY_HP_MULT), "stage enemy HP should increase by 15 percent after normal stat calculation")
	_assert(int(enemy.get("maxHP", 0)) == int(enemy.get("hp", 0)), "stage enemy current and maximum HP should receive the same multiplier")
	_assert(int(enemy.get("atk", 0)) == int(float(owned_same_roll.get("atk", 0)) * StatCalculator.STAGE_ENEMY_ATK_MULT), "stage enemy ATK should decrease by 15 percent after normal stat calculation")
	_assert(enemy.get("enemyStageMultiplier", {}) == {"hp": 1.15, "atk": 0.85}, "stage enemy should expose its runtime-only balance multiplier")
	_assert(not owned_same_roll.has("enemyStageMultiplier"), "owned monster calculation should not contain the enemy-only multiplier")
	_assert(int(species.get("baseHP", 0)) == 160 and int(species.get("baseATK", 0)) == 32 and not species.has("enemyStageMultiplier"), "enemy runtime balance must not rewrite monster species data")


func _test_boss_owned_base_near_chapter_enemies() -> void:
	for chapter_num in StageDB.CHAPTER_BOSS_IDS.keys():
		var ids: Array = StageDB.CHAPTER_ENEMY_POOLS.get(chapter_num, [])
		var boss_data: Dictionary = MonsterDb.MONSTER_DB.get(str(StageDB.CHAPTER_BOSS_IDS.get(chapter_num, "")), {})
		_assert(not boss_data.is_empty(), "chapter %d should have a boss monster template" % int(chapter_num))
		_assert(not ids.is_empty(), "chapter %d should have an ordinary enemy pool" % int(chapter_num))
		if boss_data.is_empty():
			continue
		for base_key in ["baseHP", "baseATK", "baseDEF", "baseSPD"]:
			_assert(float(boss_data.get(base_key, 0.0)) > 0.0, "boss chapter %d %s should be configured" % [int(chapter_num), base_key])


func _test_enemy_boss_multiplier_is_runtime_only() -> void:
	var owned_boss := StatCalculator.calc("monster_boss_001", 20, "")
	var enemy_boss := StatCalculator.calc_enemy("monster_boss_001", 20)
	var same_roll_boss := StatCalculator.calc("monster_boss_001", 20, str(enemy_boss.get("nature", "")))
	var multiplier: Dictionary = enemy_boss.get("enemyBossMultiplier", {})
	_assert(not owned_boss.has("enemyBossMultiplier"), "owned boss stats should not include enemy-only boss multiplier")
	_assert(enemy_boss.has("enemyBossMultiplier"), "enemy boss stats should expose the applied boss multiplier for debugging")
	_assert(is_equal_approx(float(multiplier.get("hp", 0.0)), 2.5), "enemy boss HP multiplier should use the softened boss pressure value")
	_assert(is_equal_approx(float(multiplier.get("atk", 0.0)), 0.6), "enemy boss ATK multiplier should use the softened boss pressure value")
	_assert(is_equal_approx(float(multiplier.get("def", 0.0)), 1.0), "enemy boss DEF multiplier should use the softened boss pressure value")
	_assert(is_equal_approx(float(multiplier.get("spd", 0.0)), 0.5), "enemy boss SPD multiplier should use the softened boss pressure value")
	var boss_hp_before_stage_balance := int(float(same_roll_boss.get("hp", 0)) * float(multiplier.get("hp", 1.0)))
	var boss_atk_before_stage_balance := int(float(same_roll_boss.get("atk", 0)) * float(multiplier.get("atk", 1.0)))
	_assert(int(enemy_boss.get("hp", 0)) == int(float(boss_hp_before_stage_balance) * StatCalculator.STAGE_ENEMY_HP_MULT), "enemy boss HP should receive the runtime-only 15 percent increase after its boss multiplier")
	_assert(int(enemy_boss.get("atk", 0)) == int(float(boss_atk_before_stage_balance) * StatCalculator.STAGE_ENEMY_ATK_MULT), "enemy boss ATK should receive the runtime-only 15 percent reduction after its boss multiplier")
	_assert(int(enemy_boss.get("hp", 0)) >= int(float(owned_boss.get("hp", 0)) * 2.0), "enemy boss HP should keep moderate boss pressure after level growth")
	_assert(int(enemy_boss.get("atk", 0)) <= int(owned_boss.get("atk", 0)), "enemy boss ATK should be softened below the owned baseline")

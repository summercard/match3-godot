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

extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var base := StatCalculator.calc("monster_001", 10, "brave")
	var normal := StatCalculator.calc_with_tier("monster_001", 10, "brave", StatCalculator.EnemyTier.NORMAL)
	var elite := StatCalculator.calc_with_tier("monster_001", 10, "brave", StatCalculator.EnemyTier.ELITE)

	assert(normal == base, "normal tier should keep the regular owned formula")
	assert(bool(elite.get("isElite", false)), "elite tier should mark stats as elite")
	assert(int(elite.get("hp", 0)) == int(float(base.get("hp", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite HP should gain 10 percent")
	assert(int(elite.get("atk", 0)) == int(float(base.get("atk", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite ATK should gain 10 percent")
	assert(int(elite.get("def", 0)) == int(float(base.get("def", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite DEF should gain 10 percent")
	assert(int(elite.get("spd", 0)) == int(float(base.get("spd", 0)) * StatCalculator.ELITE_BASE_STAT_MULT), "owned elite SPD should gain 10 percent")

	var inst_normal := MonsterPool.create_instance("monster_001", {"level": 10, "nature": "brave"})
	var inst_elite := MonsterPool.create_instance("monster_001", {"level": 10, "isElite": true, "nature": "brave"})
	var view_normal := MonsterService.build_instance_view(inst_normal)
	var view_elite := MonsterService.build_instance_view(inst_elite)
	assert(view_normal.get("stats", {}) == base, "normal owned instance should use regular stats")
	assert(view_elite.get("stats", {}) == elite, "elite owned instance should use elite stats")
	assert(bool(view_elite.get("isElite", false)), "elite view should keep isElite")

	var enemy_elite := StatCalculator.calc_enemy("enemy_001", 10, StatCalculator.EnemyTier.ELITE)
	var enemy_base := StatCalculator.calc("enemy_001", StatCalculator.enemy_combat_level("enemy_001", 10), str(enemy_elite.get("nature", "")))
	var elite_base_hp := int(float(enemy_base.get("hp", 0)) * StatCalculator.ELITE_BASE_STAT_MULT)
	var elite_base_atk := int(float(enemy_base.get("atk", 0)) * StatCalculator.ELITE_BASE_STAT_MULT)
	assert(int(enemy_elite.get("hp", 0)) == int(float(elite_base_hp) * StatCalculator.ELITE_ENEMY_HP_MULT), "enemy elite HP should apply base bonus then enemy HP multiplier")
	assert(int(enemy_elite.get("atk", 0)) == int(float(elite_base_atk) * StatCalculator.ELITE_ENEMY_ATK_MULT), "enemy elite ATK should apply base bonus then enemy ATK multiplier")

	print("[EliteTier] OK")
	quit(0)

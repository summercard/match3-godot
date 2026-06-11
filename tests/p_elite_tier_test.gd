extends SceneTree

# P1-elite-tier-test
# 验证主人定 2026-06-11 精英怪/精英宠物 tier 系数
# 跑：godot --headless --script tests/p_elite_tier_test.gd --quit

func _init() -> void:
	print("=".repeat(70))
	print("P1 - 精英 tier 系数验证")
	print("=".repeat(70))

	# 1) calc 基线（无 tier）
	var base = StatCalculator.calc("monster_001", 10, "")
	print("\n[基线] monster_001 Lv10 无性格:")
	print("  HP=%d  ATK=%d" % [base.hp, base.atk])

	# 2) calc_with_tier(NORMAL) = HP × 2
	var normal = StatCalculator.calc_with_tier("monster_001", 10, "", StatCalculator.EnemyTier.NORMAL)
	print("\n[NORMAL] HP=%d (期望 %d = base × 2)" % [normal.hp, base.hp * 2])
	assert(normal.hp == base.hp * 2, "NORMAL HP 应该是 base × 2")
	assert(normal.atk == base.atk, "NORMAL ATK 应保持不变")
	print("  ✓ NORMAL tier OK")

	# 3) calc_with_tier(ELITE) = HP × 5, ATK + 20%
	var elite = StatCalculator.calc_with_tier("monster_001", 10, "", StatCalculator.EnemyTier.ELITE)
	print("\n[ELITE] HP=%d (期望 %d = base × 5)  ATK=%d (期望 %d = base × 1.2)" %
		[elite.hp, base.hp * 5, elite.atk, int(base.atk * 1.2)])
	assert(elite.hp == base.hp * 5, "ELITE HP 应该是 base × 5")
	assert(elite.atk == int(base.atk * 1.2), "ELITE ATK 应该是 base × 1.2")
	print("  ✓ ELITE tier OK")

	# 4) MonsterPool.create_instance 默认带 isElite（从模板继承）
	var inst_normal = MonsterPool.create_instance("monster_001")
	print("\n[Pool] monster_001 (非精英) isElite=%s" % str(inst_normal.get("isElite", null)))
	assert(inst_normal.get("isElite", true) == false, "monster_001 不应是精英")

	# 5) 强制 isElite=true 创建实例
	var inst_elite = MonsterPool.create_instance("monster_001", {"isElite": true})
	print("[Pool] monster_001 (强制精英) isElite=%s" % str(inst_elite.get("isElite", null)))
	assert(inst_elite.get("isElite", false) == true, "强制精英应保留 isElite=true")

	# 6) normalize_instance 老存档兜底
	var legacy = MonsterPool.normalize_instance({
		"instanceId": "x",
		"monsterId": "monster_001",
		"level": 5,
	})
	print("[Pool] 老存档 normalize: isElite=%s" % str(legacy.get("isElite", null)))
	assert(legacy.has("isElite"), "老存档应被加上 isElite 字段")

	# 7) MonsterService.build_instance_view 对精英应用 ELITE tier
	var view_normal = MonsterService.build_instance_view(inst_normal)
	var view_elite = MonsterService.build_instance_view(inst_elite)
	print("\n[Service] view_normal.stats.hp=%d" % view_normal.stats.hp)
	print("[Service] view_elite.stats.hp=%d (期望 = normal × 2.5 = %d)" %
		[view_elite.stats.hp, view_normal.stats.hp * 5 / 2])
	# normal (HP×2) vs elite (HP×5) → 比例 = 5/2 = 2.5x
	# 注意 int 截断可能导致 ±1 误差
	var expected_elite_hp: int = view_normal.stats.hp * 5 / 2
	assert(abs(view_elite.stats.hp - expected_elite_hp) <= 2, "ELITE pet HP 应该约等于 normal × 2.5")
	assert(view_elite.get("isElite", false) == true, "view.isElite 应为 true")
	assert(view_normal.get("isElite", true) == false, "view.isElite 应为 false")
	print("  ✓ Service build_instance_view 应用 tier OK")

	# 8) calc_enemy_auto 读取 MONSTER_DB.isElite
	# enemy_003 = 精英 (已在 monster_db 标 isElite=true)
	var auto_elite = StatCalculator.calc_enemy_auto("enemy_003", 10)
	var manual_elite = StatCalculator.calc_enemy("enemy_003", 10, StatCalculator.EnemyTier.ELITE)
	print("\n[Auto] enemy_003 Lv10 auto.hp=%d  manual_elite.hp=%d" %
		[auto_elite.hp, manual_elite.hp])
	# 由于 random nature，两次值会有偏差。但都应该是精英 tier（明显大于 NORMAL）
	var normal_check = StatCalculator.calc_enemy("enemy_003", 10, StatCalculator.EnemyTier.NORMAL)
	assert(auto_elite.hp > normal_check.hp, "auto 应识别 enemy_003 为精英 (HP 应大于 NORMAL)")
	print("  ✓ calc_enemy_auto 自动识别 enemy_003 为精英 OK")

	print("\n" + "=".repeat(70))
	print("所有 elite tier 验证通过 ✓")
	print("=".repeat(70))
	quit()

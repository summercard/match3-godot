extends SceneTree

# P1-elite-tier-test
# 验证敌方精英 tier，以及仓库实例统一属性公式
# 跑：godot --headless --script tests/p_elite_tier_test.gd --quit

func _init() -> void:
	print("=".repeat(70))
	print("P1 - 精英 tier 系数验证")
	print("=".repeat(70))

	# 1) calc 基线（无 tier）
	var base = StatCalculator.calc("monster_001", 10, "")
	print("\n[基线] monster_001 Lv10 无性格:")
	print("  HP=%d  ATK=%d" % [base.hp, base.atk])

	# 2) 旧 NORMAL 入口不再改变统一公式
	var normal = StatCalculator.calc_with_tier("monster_001", 10, "", StatCalculator.EnemyTier.NORMAL)
	print("\n[NORMAL兼容入口] HP=%d (期望与 base 相同 %d)" % [normal.hp, base.hp])
	assert(normal == base, "NORMAL 兼容入口不应改变统一公式")
	print("  ✓ NORMAL 统一公式 OK")

	# 3) 旧 ELITE 入口也不再改变统一公式
	var elite = StatCalculator.calc_with_tier("monster_001", 10, "", StatCalculator.EnemyTier.ELITE)
	print("\n[ELITE兼容入口] HP=%d ATK=%d" % [elite.hp, elite.atk])
	assert(elite == base, "ELITE 兼容入口不应改变统一公式")
	print("  ✓ ELITE 统一公式 OK")

	# 4) MonsterPool.create_instance 默认带 isElite（从模板继承）
	var inst_normal = MonsterPool.create_instance("monster_001", {"nature": "brave"})
	print("\n[Pool] monster_001 (非精英) isElite=%s" % str(inst_normal.get("isElite", null)))
	assert(inst_normal.get("isElite", true) == false, "monster_001 不应是精英")

	# 5) 强制 isElite=true 创建实例
	var inst_elite = MonsterPool.create_instance("monster_001", {"isElite": true, "nature": "brave"})
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
	print("[Service] view_elite.stats.hp=%d (仓库统一公式，期望 = normal %d)" %
		[view_elite.stats.hp, view_normal.stats.hp])
	assert(view_normal.stats.hp == StatCalculator.calc("monster_001", 1, "brave").hp, "普通我方精灵应使用基础 HP")
	assert(view_elite.stats == view_normal.stats, "仓库精灵无论精英标签都应使用基础属性、等级和性格公式")
	assert(view_elite.get("isElite", false) == true, "view.isElite 应为 true")
	assert(view_normal.get("isElite", true) == false, "view.isElite 应为 false")
	print("  ✓ Service build_instance_view 仓库统一公式 OK")

	# 8) 敌方兼容入口只随机性格，不叠加第二套属性倍率
	var auto_elite = StatCalculator.calc_enemy_auto("enemy_003", 10)
	var manual_elite = StatCalculator.calc_enemy("enemy_003", 10, StatCalculator.EnemyTier.ELITE)
	print("\n[Auto] enemy_003 Lv10 auto.hp=%d  manual_elite.hp=%d" %
		[auto_elite.hp, manual_elite.hp])
	assert(auto_elite.level == manual_elite.level, "敌方兼容入口应解析相同实际等级")
	print("  ✓ calc_enemy_auto 统一公式 OK")

	print("\n" + "=".repeat(70))
	print("所有 elite tier 验证通过 ✓")
	print("=".repeat(70))
	quit()

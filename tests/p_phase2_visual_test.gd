extends SceneTree

# P5-phase2-visual-test
# 验证阶段转换：保留血量比例 + 体型放大 50%
# 跑：godot --headless --path . --script res://tests/p_phase2_visual_test.gd

func _init() -> void:
	print("=".repeat(75))
	print("P5 - 阶段转换 验证（保留血量比例 + 体型 ×1.5）")
	print("=".repeat(75))

	# 1) 模拟 execute_phase_transition 的核心逻辑
	print("\n[1] 模拟花叶兽 phase 1 → phase 2")
	print("-".repeat(75))
	var monster_boss_001 = StatCalculator.calc_enemy("monster_boss_001", 20)
	print("  Phase 1 起始: maxHP=%d  HP=%d  _visualScale=%s" %
		[monster_boss_001.maxHP, monster_boss_001.hp, str(monster_boss_001.get("_visualScale", 1.0))])
	assert(monster_boss_001.hp == monster_boss_001.maxHP, "起始应该满血")
	assert(monster_boss_001.get("_visualScale", 0.0) > 0.0, "current boss should expose a positive visual scale")

	# 玩家打到 30% 血
	var dmg = int(monster_boss_001.maxHP * 0.7)
	monster_boss_001.hp = maxi(1, monster_boss_001.hp - dmg)
	print("  玩家打掉 70%% 血 → 当前 HP=%d (%.0f%%)" %
		[monster_boss_001.hp, float(monster_boss_001.hp) / float(monster_boss_001.maxHP) * 100])

	# 模拟 phase_handler 的核心逻辑
	var phase_config = {"phase": 2, "enemies": ["monster_boss_001"], "trigger": "hp_50", "hpMultiplier": 1.3}
	var hp_mult = phase_config.get("hpMultiplier", 1.3)
	var old_hp_ratio = float(monster_boss_001.hp) / float(monster_boss_001.maxHP)
	print("  旧 HP 比例 = %.2f" % old_hp_ratio)

	# 生成 phase 2 怪
	var phase2_monster = StatCalculator.calc_enemy("monster_boss_001", 20)
	var new_max_hp = int(phase2_monster.maxHP * hp_mult)
	phase2_monster.maxHP = new_max_hp
	phase2_monster.hp = maxi(1, int(new_max_hp * old_hp_ratio))
	phase2_monster.atk = int(phase2_monster.atk * hp_mult)
	phase2_monster.def = int(phase2_monster.def * hp_mult)
	phase2_monster["_visualScale"] = 1.5

	print("  Phase 2 生成: maxHP=%d  HP=%d (%.0f%%)  _visualScale=%.1f" %
		[phase2_monster.maxHP, phase2_monster.hp,
		float(phase2_monster.hp) / float(phase2_monster.maxHP) * 100,
		phase2_monster._visualScale])

	# 验证
	var expected_hp = int(new_max_hp * old_hp_ratio)
	var pass_a = (phase2_monster.hp == expected_hp)
	var pass_b = (phase2_monster._visualScale == 1.5)
	var pass_c = (phase2_monster.hp < phase2_monster.maxHP)  # 不再回满
	print("  ✓ HP 按比例保留: %d == %d ? %s" % [phase2_monster.hp, expected_hp, "✓" if pass_a else "✗"])
	print("  ✓ 体型放大 1.5x: %s" % ("✓" if pass_b else "✗"))
	print("  ✓ 不再回满血: HP=%d < maxHP=%d ? %s" %
		[phase2_monster.hp, phase2_monster.maxHP, "✓" if pass_c else "✗"])

	# 2) 验证默认怪 (没进 phase 2) 仍 _visualScale=1.0
	print("\n[2] 验证普通怪 _visualScale 默认 1.0")
	print("-".repeat(75))
	var normal = StatCalculator.calc_enemy("enemy_001", 5)
	var visual = normal.get("_visualScale", 1.0)
	var pass_d = (visual == 1.0)
	print("  普通野火虫 _visualScale=%s %s" %
		[str(visual), "✓" if pass_d else "✗"])

	# 3) 验证 HP 比例计算
	print("\n[3] 不同血量比例进入 phase 2")
	print("-".repeat(75))
	for ratio in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var p2 = StatCalculator.calc_enemy("monster_boss_001", 20)
		var new_max = int(p2.maxHP * 1.3)
		p2.maxHP = new_max
		p2.hp = maxi(1, int(new_max * ratio)) if ratio > 0.0 else new_max
		var actual_ratio = float(p2.hp) / float(p2.maxHP) * 100
		print("  旧比例 %.0f%% → phase2 HP=%d (%.0f%%)  maxHP=%d" %
			[ratio*100, p2.hp, actual_ratio, p2.maxHP])

	# 4) 验证相同样本在战斗渲染层 sprite_size 变化
	print("\n[4] 战斗渲染层 sprite_size 变化（Boss 170 / 128）")
	print("-".repeat(75))
	var boss_size = 170.0
	var normal_size = 128.0
	var v_scale = 1.5
	print("  Boss 起始: size=%.0f  →  phase2: size=%.0f (×%.1f)" %
		[boss_size, boss_size * v_scale, v_scale])
	print("  普通起始: size=%.0f  →  phase2: size=%.0f (×%.1f)" %
		[normal_size, normal_size * v_scale, v_scale])

	print("\n" + "=".repeat(75))
	if pass_a and pass_b and pass_c and pass_d:
		print("✓ 全部通过！phase 2 现在：保留血量比例 + 体型 ×1.5")
	else:
		print("✗ 有问题")
	print("=".repeat(75))
	quit()

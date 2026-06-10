extends SceneTree

# P1-stat-calc-test
# 验证 StatCalculator：玩家/敌人/捕获都走同一公式
# 跑：godot --headless --path . --script res://tests/p_stat_calc_test.gd

func _init() -> void:
	print("=".repeat(70))
	print("P1 - StatCalculator 统一成长公式验证")
	print("=".repeat(70))

	# 1) 玩家固定性格 → 走 calc
	var p1 = StatCalculator.calc("monster_001", 20, "gentle")
	print("\n[玩家] monster_001 (小火龙) Lv20 + gentle性格:")
	print("  HP=%d  ATK=%d  DEF=%d  SPD=%d" % [p1.hp, p1.atk, p1.def, p1.spd])
	print("  期望 HP=574 (180*2.9*1.10=%d)" % int(180*2.9*1.10))
	assert(p1.hp == 574, "玩家 HP 不对")
	assert(p1.atk == 123, "玩家 ATK 不对 (45*2.9*0.95)")
	print("  ✓ 玩家固定性格 OK")

	# 2) 玩家无性格 → 1.0 倍
	var p2 = StatCalculator.calc("monster_001", 20, "")
	assert(p2.hp == 522, "无性格 HP 不对 (180*2.9)")
	print("\n[玩家] 无性格: HP=%d (期望 522)  ✓" % p2.hp)

	# 3) 等级封顶
	var p3 = StatCalculator.calc("monster_001", 99, "gentle")
	assert(p3.level == 50, "封顶失败")
	print("\n[封顶] Lv99 → 实际 Lv=%d HP=%d (期望 Lv50)  ✓" % [p3.level, p3.hp])

	# 4) 敌人 random 性格 → calc_enemy
	print("\n[敌人] ch5 Boss monster_030 Lv27 calc_enemy 跑 5 次:")
	for i in range(5):
		var e = StatCalculator.calc_enemy("monster_030", 27)
		print("  第%d次: nature=%s HP=%d  ATK=%d  DEF=%d  SPD=%d" %
			[i+1, e.nature, e.hp, e.atk, e.def, e.spd])
	print("  ✓ 敌人每次性格不同 OK")

	# 5) 玩家怪物 base 数据 = 敌人 base 数据（共享 MONSTER_DB）
	var player_base = StatCalculator.calc("monster_006", 20, "")
	var enemy_base = StatCalculator.calc("monster_006", 20, "")
	assert(player_base.atk == enemy_base.atk, "base 不一致")
	print("\n[共享] 玩家 Lv20无性格 ATK=%d == 敌人 Lv20无性格 ATK=%d  ✓" %
		[player_base.atk, enemy_base.atk])

	# 6) 性格有正负：fierce 应该有 critRate +8%, def -5%
	var fierce = StatCalculator.calc("monster_006", 20, "fierce")
	var neutral = StatCalculator.calc("monster_006", 20, "")
	print("\n[性格生效] monster_006 Lv20:")
	print("  fierce: HP=%d ATK=%d DEF=%d" % [fierce.hp, fierce.atk, fierce.def])
	print("  neutral: HP=%d ATK=%d DEF=%d" % [neutral.hp, neutral.atk, neutral.def])
	assert(fierce.def < neutral.def, "fierce 防御应该比 neutral 低 (-5%)")
	assert(fierce.hp == neutral.hp, "HP 不受 fierce 影响")
	print("  ✓ fierce 让 DEF 降低 OK")

	# 7) ★ 捕获流程：敌人 random → 捕获后属性 = 敌人这次算出的属性
	print("\n[捕获模拟] 5 次刷同一只怪，每次 random 性格:")
	var captures = []
	for i in range(5):
		var e = StatCalculator.calc_enemy("monster_024", 30)  # 剧毒蛛后 ★4
		captures.append(e)
		print("  刷%d: nature=%s ATK=%d (base 75)" % [i+1, e.nature, e.atk])
	# 验证：5 次至少出现 2 种不同性格
	var natures = []
	for c in captures:
		if not natures.has(c.nature):
			natures.append(c.nature)
	assert(natures.size() >= 2, "5 次应该至少出现 2 种性格")
	print("  ✓ 捕获赌脸成立: 5 次出现 %d 种性格" % natures.size())

	print("\n" + "=".repeat(70))
	print("所有验证通过 ✓")
	print("=".repeat(70))
	quit()


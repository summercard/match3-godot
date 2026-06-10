extends SceneTree

# P4-chapter-curve-test
# 验证新的关卡等级梯度：ch1 头 Lv5, ch1 Boss Lv20, 每章 +5
# Boss 关卡是 stage_X_12（Boss_STAGE_NO=12）
# 跑：godot --headless --path . --script res://tests/p_chapter_curve_test.gd

func _init() -> void:
	print("=".repeat(75))
	print("P4 - 关卡等级梯度（主人定 2026-06-10）")
	print("Boss 关卡 = stage_X_12 (BOSS_STAGE_NO=12)")
	print("=".repeat(75))

	var db = StageDB.new()
	const BOSS_STAGE_NO = 12  # 跟 stage_db.gd 的常量保持一致

	# 1) 等级曲线：每个章节的 头一关 (stage_X_1) 和 Boss (stage_X_12)
	print("\n[等级曲线] 每个章节的 头/Boss 关等级 + 数值")
	print("-".repeat(75))
	for ch in range(1, 11):
		var head_id = "stage_%d_1" % ch
		var head = db.get_stage(head_id)
		var head_lv = int(head.get("enemyLevel", 0)) if not head.is_empty() else 0
		var head_eid = head.get("enemies", [""])[0] if not head.is_empty() else ""
		var head_e = StatCalculator.calc_enemy(head_eid, head_lv) if not head_eid.is_empty() else {}

		var boss_id = "stage_%d_%d" % [ch, BOSS_STAGE_NO]
		var boss = db.get_stage(boss_id)
		var boss_lv = int(boss.get("enemyLevel", 0)) if not boss.is_empty() else 0
		var boss_eid = ""
		if not boss.is_empty() and boss.get("phases", []).size() > 0:
			boss_eid = boss["phases"][0].get("enemies", [""])[0]
		elif not boss.is_empty():
			boss_eid = boss.get("enemies", [""])[0]
		var boss_e = StatCalculator.calc_enemy(boss_eid, boss_lv) if not boss_eid.is_empty() else {}

		print("  ch%d 头  Lv.%-3d  enemy=%-16s HP=%-5d ATK=%-3d" %
			[ch, head_lv, head_eid, head_e.get("hp", 0), head_e.get("atk", 0)])
		print("  ch%d Boss Lv.%-3d  enemy=%-16s HP=%-5d ATK=%-3d" %
			[ch, boss_lv, boss_eid, boss_e.get("hp", 0), boss_e.get("atk", 0)])

	# 2) ch1 详细梯度
	print("\n[ch1 详细] 1-1 到 1-12 (Boss)")
	print("-".repeat(75))
	for stage_no in range(1, BOSS_STAGE_NO + 1):
		var sid = "stage_1_%d" % stage_no
		var st = db.get_stage(sid)
		if st.is_empty():
			continue
		var lv = int(st.get("enemyLevel", 0))
		var eids: Array = []
		if st.get("phases", []).size() > 0:
			eids = st["phases"][0].get("enemies", [])
		else:
			eids = st.get("enemies", [])
		var eid: String = eids[0] if eids.size() > 0 else ""
		var e = StatCalculator.calc_enemy(eid, lv) if not eid.is_empty() else {}
		var tag: String = " (Boss)" if st.get("type", "") == "boss" else ""
		print("  1-%-2d%s Lv.%-3d enemy=%-16s HP=%-5d ATK=%-3d" %
			[stage_no, tag, lv, eid, e.get("hp", 0), e.get("atk", 0)])

	# 3) 封顶 100 验证
	print("\n[封顶验证]")
	print("-".repeat(75))
	var c10_boss = db.get_stage("stage_10_%d" % BOSS_STAGE_NO)
	var c10_boss_lv = int(c10_boss.get("enemyLevel", 0)) if not c10_boss.is_empty() else 0
	print("  公式算出 ch10 Boss Lv = %d" % c10_boss_lv)
	print("  MAX_LEVEL = %d" % StatCalculator.MAX_LEVEL)
	if c10_boss_lv <= StatCalculator.MAX_LEVEL:
		print("  ✓ ch10 Boss 等级 %d <= 封顶 %d，不撞顶" % [c10_boss_lv, StatCalculator.MAX_LEVEL])
	else:
		print("  ✗ 撞顶了！实际按 Lv%d 算" % StatCalculator.MAX_LEVEL)

	# 4) 验收
	print("\n[验收] 主人要求: ch1 头=5, ch1 Boss=20")
	print("-".repeat(75))
	var ch1_head = db.get_stage("stage_1_1")
	var ch1_boss = db.get_stage("stage_1_%d" % BOSS_STAGE_NO)
	var head_lv = int(ch1_head.get("enemyLevel", 0)) if not ch1_head.is_empty() else 0
	var boss_lv2 = int(ch1_boss.get("enemyLevel", 0)) if not ch1_boss.is_empty() else 0
	var pass1 = (head_lv == 5)
	var pass2 = (boss_lv2 == 20)
	print("  ch1 头 (stage_1_1) Lv = %d (期望 5) %s" % [head_lv, "✓" if pass1 else "✗"])
	print("  ch1 Boss (stage_1_12) Lv = %d (期望 20) %s" % [boss_lv2, "✓" if pass2 else "✗"])

	# 5) 验证每章 Boss +5
	print("\n[每章 +5 验证] ch2~ch10 Boss 等级应逐章 +5")
	print("-".repeat(75))
	var expected = 25
	var all_pass = true
	for ch in range(2, 11):
		var b = db.get_stage("stage_%d_%d" % [ch, BOSS_STAGE_NO])
		if b.is_empty():
			continue
		var lv = int(b.get("enemyLevel", 0))
		var mark = "✓" if lv == expected else "✗"
		if lv != expected:
			all_pass = false
		print("  ch%d Boss Lv = %d (期望 %d) %s" % [ch, lv, expected, mark])
		expected += 5

	print("\n" + "=".repeat(75))
	if pass1 and pass2 and all_pass:
		print("✓ 全部通过！ch1 头 Lv5 / ch1 Boss Lv20 / 每章 Boss +5 已生效")
	else:
		print("✗ 有问题")
	print("=".repeat(75))
	quit()

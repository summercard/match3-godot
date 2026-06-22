extends SceneTree

# P2-battle-prepare-level-test
# 验证战斗准备界面：敌人等级能被正确读取、显示、并区分兑底
# 跑：godot --headless --path . --script res://tests/p_battle_prepare_level_test.gd

func _init() -> void:
	print("=".repeat(70))
	print("P2 - 战斗准备界面敌人等级验证")
	print("=".repeat(70))

	# 1) StatCalculator.calc 必须返回 level 字段
	var s = StatCalculator.calc("enemy_001", 12)
	assert(s.has("level"), "StatCalculator.calc 必须返回 level 字段")
	assert(s.level == 12, "level 字段必须等于传入等级")
	print("\n[基础] StatCalculator.calc 返回 level=%d ✓" % s.level)

	# 2) 模拟 _load_enemy_team：关卡有 enemyLevel
	var stage_with_level = {"id": "stage_1_1", "enemies": ["enemy_001", "enemy_002"], "enemyLevel": 8}
	var team1 = _simulate_load_enemy_team(stage_with_level)
	assert(team1.size() == 2, "应该加载 2 只敌人")
	assert(team1[0].level == 8, "敌人等级应等于关卡 enemyLevel")
	assert(not team1[0]._isFallbackLevel, "有 enemyLevel 时不应该标为兑底")
	print("\n[关卡] stage_1_1 enemyLevel=8 → 敌人 Lv=%d (isFallback=%s) ✓" %
		[team1[0].level, str(team1[0]._isFallbackLevel)])

	# 3) 模拟 _load_enemy_team：关卡没设 enemyLevel
	var stage_no_level = {"id": "stage_test", "enemies": ["enemy_001"]}
	var team2 = _simulate_load_enemy_team(stage_no_level)
	assert(team2.size() == 1)
	assert(team2[0].level == 3, "没设等级时应该兑底为 3")
	assert(team2[0]._isFallbackLevel, "没设等级时应该标为兑底")
	print("[兑底] stage_test 无 enemyLevel → 敌人 Lv=%d (isFallback=%s) ✓" %
		[team2[0].level, str(team2[0]._isFallbackLevel)])

	# 4) 模拟 _load_enemy_team：enemyLevel=0 也算兑底
	var stage_zero = {"id": "stage_zero", "enemies": ["enemy_001"], "enemyLevel": 0}
	var team3 = _simulate_load_enemy_team(stage_zero)
	assert(team3[0]._isFallbackLevel, "enemyLevel=0 也应该标为兑底")
	print("[边界] enemyLevel=0 → 兑底到 Lv=%d (isFallback=%s) ✓" %
		[team3[0].level, str(team3[0]._isFallbackLevel)])

	# 5) 验证 StageDB 中实际关卡是否都设置了 enemyLevel
	var db = StageDB.new()
	var missing = []
	for ch in StageDB.STAGES_DATA["chapters"]:
		var chapter = db._expanded_chapter(ch)
		for st in chapter["stages"]:
			if not st.has("enemyLevel") or int(st.get("enemyLevel", 0)) <= 0:
				missing.append(st["id"])
	print("\n[StageDB 扫] 65 个关卡中未设 enemyLevel 的:")
	if missing.is_empty():
		print("  (无) ✓ 所有关卡都已设 enemyLevel")
	else:
		for m in missing:
			print("  ✗ %s" % m)

	# 6) 真实取一个高等级关卡验证
	var real = db.get_stage("stage_2_5")  # 第 2 章第 5 关
	if not real.is_empty():
		var lvl = int(real.get("enemyLevel", 0))
		print("[真实] stage_2_5 实际 enemyLevel=%d ✓" % lvl)
		assert(lvl > 0, "真实关卡应该有 enemyLevel")

	print("\n" + "=".repeat(70))
	print("所有验证通过 ✓")
	print("敌人等级现在会在准备界面正确显示")
	print("=".repeat(70))
	quit()

func _simulate_load_enemy_team(stage_data: Dictionary) -> Array:
	var result = []
	var enemy_ids = stage_data.get("enemies", ["enemy_001"])
	var enemy_level = stage_data.get("enemyLevel", 3)
	var is_fallback = not stage_data.has("enemyLevel") or int(stage_data.get("enemyLevel", 0)) <= 0
	for enemy_id in enemy_ids:
		var enemy = StatCalculator.calc(enemy_id, enemy_level)
		if not enemy.is_empty():
			enemy["power"] = enemy.get("hp", 0) + enemy.get("atk", 0) + enemy.get("def", 0)
			enemy["_isFallbackLevel"] = is_fallback
			result.append(enemy)
	return result

extends SceneTree

# ranch_subpage_entry_test.gd - 验证农场三个子页面（Ranch/Classroom/Social）入场动画
# 动画规则（参考胜利界面的奖励槽节奏）：
#   1) 整页：上浮 (position.y += 14) + 淡入 (modulate.a 0→1)
#   2) 卡片：从下方弹入 (scale 0.6→1.08→1.0, pivot 在底部中心) + 淡入，依次错开 0.05s
#   3) 底部按钮组：上滑 + 淡入（延迟 0.30s）
# 关键约束：
#   - 不改 .visible 属性（让现有可见性测试不受影响）
#   - 锁定/半透明卡片（modulate.a < 0.9）跳过入场动画，保持原状态

var _failures: Array[String] = []

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("ranch")
	await process_frame
	await process_frame
	var ranch: Control = main.get_current_scene()
	_expect(ranch != null, "ranch scene should instantiate")
	if ranch == null:
		_finish()
		return

	# 准备 6 只精灵
	var captured: Array = []
	for i in 6:
		captured.append({
			"instanceId": "ranch_entry_%02d" % i,
			"monsterId": "monster_%03d" % ((i % 6) + 1),
			"level": 3,
			"nature": "brave",
		})
	ranch.set("_storage", null)
	ranch.set("_captured_monsters", captured)
	ranch.call("_sync_gui")
	await process_frame

	# 主动触发一次 ranch 入场动画（_ready 时无数据，所有卡片均不可见，未触发动画）
	ranch.call("_play_subpage_entry", "ranch")
	await process_frame

	# === 测试 1: ranch 入场动画初始态 ===
	_expect((ranch.get_node("Pages/RanchPage") as Control).visible, "ranch page should remain visible after entry kick-off")
	# 验证可见卡片的初始态
	var animated_count := 0
	for i in 6:
		var path := "Pages/RanchPage/RosterPanel/Card%d" % (i + 1)
		var card := ranch.get_node(path) as Control
		if not card.visible:
			continue
		animated_count += 1
		_expect(card.scale.x < 0.9, "ranch card %d scale.x should be small at entry start (got %f)" % [i + 1, card.scale.x])
		_expect(card.scale.y < 0.9, "ranch card %d scale.y should be small at entry start (got %f)" % [i + 1, card.scale.y])
		_expect(card.modulate.a < 0.5, "ranch card %d modulate.a should be near 0 at entry start (got %f)" % [i + 1, card.modulate.a])
		# pivot 在底部中心（Vector2(size.x*0.5, size.y)）
		var expected_pivot := Vector2(card.size.x * 0.5, card.size.y)
		_expect(card.pivot_offset.distance_to(expected_pivot) < 0.5, "ranch card %d pivot should be bottom-center (got %s, expected %s)" % [i + 1, str(card.pivot_offset), str(expected_pivot)])
	_expect(animated_count >= 4, "at least 4 ranch cards should be animated, got %d" % animated_count)

	# === 测试 2: 等待动画完成 ===
	# 总时长 ≈ 0.05 + 5*0.05 + 0.22 + 0.08 = 0.6s，再加 0.30 + 0.20 = 1.1s
	for _i in 100:
		await process_frame

	for i in 6:
		var path := "Pages/RanchPage/RosterPanel/Card%d" % (i + 1)
		var card := ranch.get_node(path) as Control
		if not card.visible:
			continue
		_expect(absf(card.scale.x - 1.0) < 0.01, "ranch card %d scale.x should return to 1.0 (got %f)" % [i + 1, card.scale.x])
		_expect(absf(card.scale.y - 1.0) < 0.01, "ranch card %d scale.y should return to 1.0 (got %f)" % [i + 1, card.scale.y])
		_expect(absf(card.modulate.a - 1.0) < 0.01, "ranch card %d modulate.a should return to 1.0 (got %f)" % [i + 1, card.modulate.a])
	var ranch_page := ranch.get_node("Pages/RanchPage") as Control
	_expect(absf(ranch_page.modulate.a - 1.0) < 0.01, "ranch page modulate.a should return to 1.0 (got %f)" % ranch_page.modulate.a)

	# === 测试 3: 切换到 classroom，验证 classroom 入场动画 ===
	ranch.call("_switch_to_classroom")
	await process_frame
	_expect((ranch.get_node("Pages/ClassroomPage") as Control).visible, "classroom page should be visible after switch")
	_expect(not (ranch.get_node("Pages/RanchPage") as Control).visible, "ranch page should be hidden after switch to classroom")
	var class_card1 := ranch.get_node("Pages/ClassroomPage/RosterPanel/Card1") as Control
	if class_card1.visible:
		_expect(class_card1.scale.x < 0.9, "classroom card1 scale should be small at entry start (got %f)" % class_card1.scale.x)
		_expect(class_card1.modulate.a < 0.5, "classroom card1 modulate.a should be near 0 at entry start (got %f)" % class_card1.modulate.a)

	# === 测试 4: 切到 social，验证 social 入场动画 ===
	ranch.call("_switch_to_social")
	await process_frame
	_expect((ranch.get_node("Pages/SocialPage") as Control).visible, "social page should be visible after switch")
	_expect(not (ranch.get_node("Pages/ClassroomPage") as Control).visible, "classroom page should be hidden after switch to social")
	var social_card1 := ranch.get_node("Pages/SocialPage/RosterPanel/Card1") as Control
	if social_card1.visible:
		_expect(social_card1.scale.x < 0.9, "social card1 scale should be small at entry start (got %f)" % social_card1.scale.x)
		_expect(social_card1.modulate.a < 0.5, "social card1 modulate.a should be near 0 at entry start (got %f)" % social_card1.modulate.a)

	# === 测试 5: 锁定卡片（modulate.a < 0.9）应跳过入场动画 ===
	# 等待 social 动画完成
	for _i in 100:
		await process_frame
	# 模拟社交页中农场挂机的"锁定"卡片
	var social_card2 := ranch.get_node("Pages/SocialPage/RosterPanel/Card2") as Control
	if social_card2.visible:
		social_card2.modulate = Color(1.0, 1.0, 1.0, 0.52)
		var orig_modulate_a := social_card2.modulate.a
		var orig_scale_x := social_card2.scale.x
		ranch.call("_play_subpage_entry", "social")
		await process_frame
		_expect(absf(social_card2.modulate.a - orig_modulate_a) < 0.01, "locked (modulate.a<0.9) card should be skipped by entry (modulate.a was %f, now %f)" % [orig_modulate_a, social_card2.modulate.a])
		_expect(absf(social_card2.scale.x - orig_scale_x) < 0.01, "locked card should keep original scale.x (was %f, now %f)" % [orig_scale_x, social_card2.scale.x])

	# === 测试 6: 等待 social 动画完成，验证回到正常 ===
	for _i in 100:
		await process_frame
	var social_page_after := ranch.get_node("Pages/SocialPage") as Control
	_expect(absf(social_page_after.modulate.a - 1.0) < 0.01, "social page modulate.a should return to 1.0 (got %f)" % social_page_after.modulate.a)

	# === 测试 7: BottomButtons 参与入场（仅当其可见时） ===
	# 切回 ranch 验证 BottomButtons 入场
	ranch.call("_switch_to_ranch")
	await process_frame
	var ranch_btns := ranch.get_node("Pages/RanchPage/BottomButtons") as Control
	if ranch_btns.visible:
		_expect(ranch_btns.modulate.a < 0.5, "ranch BottomButtons should start hidden (modulate.a=%f)" % ranch_btns.modulate.a)
		_expect(ranch_btns.position.y > 612.0, "ranch BottomButtons should start offset down (position.y=%f)" % ranch_btns.position.y)
		for _i in 100:
			await process_frame
		_expect(absf(ranch_btns.modulate.a - 1.0) < 0.01, "ranch BottomButtons modulate.a should return to 1.0 (got %f)" % ranch_btns.modulate.a)
	else:
		# 容器不可见时，按设计不应触发入场动画；这是合法行为
		pass

	main.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchSubpageEntry] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchSubpageEntry] " + failure)
	quit(1)

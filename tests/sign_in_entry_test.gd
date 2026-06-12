extends SceneTree

# sign_in_entry_test.gd - 验证签到页入场动画（参考胜利界面奖励槽节奏）
# 动画规则：
#   1) 全局淡入：self.modulate.a 0→1 over 0.42s
#   2) hero 面板（连续签到 + 今日奖励）：顶部滑下 offset_y -18→0
#   3) 7 张周奖励卡片：依次 scale bounce (0.55→1.08→1.0) + 上滑 offset_y 16→0
#   4) 月度累计面板：从下方滑入 offset_y 22→0
#   5) 4 个里程碑宝箱：依次 scale bounce (0.5→1.12→1.0)
#   6) _entry_t 推进到 ENTRY_TOTAL_DURATION (1.30s) 才停

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
	main.switch_scene("sign_in")
	await process_frame
	await process_frame
	var sign_in: Control = main.get_current_scene()
	_expect(sign_in != null, "sign-in scene should instantiate")
	if sign_in == null:
		_finish()
		return

	# === 测试 1: _entry_t 已经在跑（场景挂到树后立即开始），值在 (0, 0.42) 之间 ===
	# 此时全局淡入尚未完成，modulate.a 应在 (0, 1) 范围内
	var init_t := float(sign_in.get("_entry_t"))
	_expect(init_t > 0.0, "entry_t should be > 0 after scene is added, got %f" % init_t)
	_expect(init_t < 0.42, "entry_t should still be < 0.42 (within fade window) early on, got %f" % init_t)
	_expect(sign_in.modulate.a > 0.0, "modulate.a should be > 0 during fade, got %f" % sign_in.modulate.a)
	_expect(sign_in.modulate.a < 1.0, "modulate.a should be < 1 during fade, got %f" % sign_in.modulate.a)

	# === 测试 2: 等待 _entry_t 推进 ===
	for _i in 30:
		await process_frame
	var entry_t := float(sign_in.get("_entry_t"))
	_expect(entry_t > 0.1, "entry_t should advance, got %f" % entry_t)
	_expect(sign_in.modulate.a > 0.0, "modulate.a should rise from 0, got %f" % sign_in.modulate.a)

	# === 测试 3: 等待 _entry_t 推进到 ENTRY_TOTAL_DURATION (1.30s) 附近 ===
	for _i in 200:
		await process_frame
	entry_t = float(sign_in.get("_entry_t"))
	_expect(entry_t >= 1.29, "entry_t should reach ENTRY_TOTAL_DURATION, got %f" % entry_t)
	_expect(absf(sign_in.modulate.a - 1.0) < 0.01, "modulate.a should be 1.0 after fade, got %f" % sign_in.modulate.a)

	# === 测试 4: _hero_entry_offset_y() 在 _entry_t 较小时为 -18，结束后为 0 ===
	sign_in.set("_entry_t", 0.05)
	var hero_off: float = sign_in.call("_hero_entry_offset_y")
	_expect(hero_off < 0.0, "hero offset_y should be negative at start, got %f" % hero_off)
	_expect(absf(hero_off - (-18.0)) < 0.01, "hero offset_y should be -18 at start, got %f" % hero_off)

	sign_in.set("_entry_t", 0.30)
	hero_off = sign_in.call("_hero_entry_offset_y")
	_expect(absf(hero_off) < 6.0, "hero offset_y should be near 0 mid-entry (t=0.30), got %f" % hero_off)

	sign_in.set("_entry_t", 0.50)
	hero_off = sign_in.call("_hero_entry_offset_y")
	_expect(absf(hero_off) < 0.01, "hero offset_y should be 0 after entry, got %f" % hero_off)

	# === 测试 5: _week_card_xform 起始态、中间态、结束态 ===
	sign_in.set("_entry_t", 0.20)
	var card0: Dictionary = sign_in.call("_week_card_xform", 0)
	_expect(card0["scale"] < 0.9, "week card 0 scale should be small at start (t=0.20), got %f" % card0["scale"])
	_expect(card0["offset_y"] > 10.0, "week card 0 offset_y should be > 10 at start, got %f" % card0["offset_y"])

	# card 6 在 t=0.20 还没启动（start = 0.22 + 6*0.05 = 0.52），应在初始态
	var card6: Dictionary = sign_in.call("_week_card_xform", 6)
	_expect(card6["scale"] < 0.9, "week card 6 (delayed) scale should be small at t=0.20, got %f" % card6["scale"])
	_expect(card6["offset_y"] > 10.0, "week card 6 (delayed) offset_y should be > 10 at t=0.20, got %f" % card6["offset_y"])

	# card 0 在 t=0.50 应在 phase 2（0.6..1.0 区间），scale 应 < 1.08 但 > 1.0
	sign_in.set("_entry_t", 0.50)
	card0 = sign_in.call("_week_card_xform", 0)
	_expect(card0["scale"] < 1.08, "week card 0 should be in phase 2 (< overshoot) at t=0.50, got scale=%f" % card0["scale"])
	_expect(card0["scale"] > 1.0, "week card 0 should be > 1.0 (settling) at t=0.50, got scale=%f" % card0["scale"])
	_expect(card0["offset_y"] < 2.0, "week card 0 offset_y should be near 0 at t=0.50, got %f" % card0["offset_y"])

	# card 0 在 t=0.60 应已完全回到 (scale=1, offset=0)
	sign_in.set("_entry_t", 0.60)
	card0 = sign_in.call("_week_card_xform", 0)
	_expect(absf(card0["scale"] - 1.0) < 0.01, "week card 0 should be 1.0 at t=0.60, got scale=%f" % card0["scale"])
	_expect(absf(card0["offset_y"]) < 0.01, "week card 0 offset_y should be 0 at t=0.60, got %f" % card0["offset_y"])

	# card 6 在 t=0.50 还在中间态（start=0.52，已经开始）
	sign_in.set("_entry_t", 0.60)
	card6 = sign_in.call("_week_card_xform", 6)
	_expect(card6["scale"] < 1.0, "week card 6 should be < 1.0 mid-entry at t=0.60, got scale=%f" % card6["scale"])

	# 所有卡片在 ENTRY_TOTAL_DURATION 之后都应回归 1.0
	sign_in.set("_entry_t", 2.0)
	for i in 7:
		var c: Dictionary = sign_in.call("_week_card_xform", i)
		_expect(absf(c["scale"] - 1.0) < 0.01, "week card %d scale should be 1.0 at t=2.0, got %f" % [i, c["scale"]])
		_expect(absf(c["offset_y"]) < 0.01, "week card %d offset_y should be 0 at t=2.0, got %f" % [i, c["offset_y"]])

	# === 测试 6: _month_panel_offset_y ===
	sign_in.set("_entry_t", 0.40)
	var month_off: float = sign_in.call("_month_panel_offset_y")
	_expect(absf(month_off - 22.0) < 0.01, "month panel offset should be 22 at start (t=0.40), got %f" % month_off)

	sign_in.set("_entry_t", 0.70)
	month_off = sign_in.call("_month_panel_offset_y")
	_expect(absf(month_off) < 8.0, "month panel offset should be near 0 at t=0.70, got %f" % month_off)

	sign_in.set("_entry_t", 1.0)
	month_off = sign_in.call("_month_panel_offset_y")
	_expect(absf(month_off) < 0.01, "month panel offset should be 0 after entry, got %f" % month_off)

	# === 测试 7: _milestone_xform (stagger 应生效) ===
	sign_in.set("_entry_t", 0.60)
	var m0: Dictionary = sign_in.call("_milestone_xform", 0)
	_expect(absf(m0["scale"] - 0.5) < 0.01, "milestone 0 scale should be 0.5 at start (t=0.60), got %f" % m0["scale"])

	# milestone 3 启动更晚（start=0.62+3*0.07=0.83）
	var m3: Dictionary = sign_in.call("_milestone_xform", 3)
	_expect(absf(m3["scale"] - 0.5) < 0.01, "milestone 3 (delayed) scale should be 0.5 at t=0.60, got %f" % m3["scale"])

	sign_in.set("_entry_t", 0.75)
	m0 = sign_in.call("_milestone_xform", 0)
	_expect(m0["scale"] > 0.5, "milestone 0 scale should bounce up at t=0.75, got %f" % m0["scale"])

	sign_in.set("_entry_t", 2.0)
	for i in 4:
		var mm: Dictionary = sign_in.call("_milestone_xform", i)
		_expect(absf(mm["scale"] - 1.0) < 0.01, "milestone %d scale should be 1.0 at t=2.0, got %f" % [i, mm["scale"]])

	# === 测试 8: _draw 调用不崩溃（即使有矩阵变换） ===
	# 重置 _entry_t 到 0.40 模拟动画进行中
	sign_in.set("_entry_t", 0.40)
	sign_in.set("_sign_in_data", {"consecutiveDays": 2, "totalDays": 5, "lastSignInDate": null})
	# 触发重绘
	sign_in.queue_redraw()
	await process_frame
	await process_frame
	_expect(true, "drawing with mid-entry transforms should not crash")

	# === 测试 9: 动画结束后 _entry_t 不再变化 ===
	sign_in.set("_entry_t", 1.30)
	await process_frame
	await process_frame
	var final_t := float(sign_in.get("_entry_t"))
	_expect(absf(final_t - 1.30) < 0.01, "_entry_t should cap at ENTRY_TOTAL_DURATION (1.30), got %f" % final_t)

	main.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		print("[SignInEntry] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SignInEntry] " + failure)
	quit(1)

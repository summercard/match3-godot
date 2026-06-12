extends SceneTree

# battle_end_overlay_entry_test.gd - 验证战局结束小弹窗入场动画
# 动画规则（参考 _draw_battle_end_overlay 注释）：
#   1) 背景遮罩：纯 fade   start=0.00 duration=0.18
#   2) Victory burst：scale bounce + 上滑 + fade   start=0.04 duration=0.32 scale_start=0.70 offset_y=12
#   3) Panel：scale 0.92→1.0 + fade   start=0.14 duration=0.24
#   4) Banner 条幅：scale bounce + 上滑 + fade   start=0.08 duration=0.28 scale_start=0.80 offset_y=-22
#   5) 下划线光晕：横向伸展   start=0.28 duration=0.24
#   6) Plaque / state text：scale bounce + fade   start=0.36 duration=0.22 scale_start=0.78
#   7) Tap strip / 继续按钮：scale bounce + 上滑 + fade   start=0.46 duration=0.22 scale_start=0.85 offset_y=10
#   8) TOTAL_DURATION = 0.70

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

	var stage_db = load("res://src/data/stage_db.gd").new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame

	var battle: Control = main.get_current_scene()
	_expect(battle != null, "battle scene should instantiate")
	if battle == null:
		_finish()
		return

	# === 测试 1: _overlay_fade（背景）行为 ===
	# t<start: alpha=0；t>=start+duration: alpha=1；区间内随 ease(-1.5) 上升
	battle.set("_battle_end_overlay_timer", 0.0)
	var bg_a: float = battle.call("_overlay_fade", 0.00, 0.18)
	_expect(absf(bg_a - 0.0) < 0.01, "bg fade should be 0 at t=0 (start of fade), got %f" % bg_a)

	battle.set("_battle_end_overlay_timer", 0.09)
	bg_a = battle.call("_overlay_fade", 0.00, 0.18)
	_expect(bg_a > 0.0 and bg_a < 1.0, "bg fade should be in (0,1) at t=0.09, got %f" % bg_a)

	battle.set("_battle_end_overlay_timer", 0.30)
	bg_a = battle.call("_overlay_fade", 0.00, 0.18)
	_expect(absf(bg_a - 1.0) < 0.01, "bg fade should be 1 after duration, got %f" % bg_a)

	# === 测试 2: _overlay_bounce_scale 三段式 ===
	# local_t<=0: start_scale
	var s0: float = battle.call("_overlay_bounce_scale", 0.0, 0.70, 1.08)
	_expect(absf(s0 - 0.70) < 0.01, "bounce at local_t=0 should be start_scale (0.70), got %f" % s0)

	# 中段 (0.6, 1.0)：在 overshoot 与 1.0 之间
	var s_mid: float = battle.call("_overlay_bounce_scale", 0.8, 0.70, 1.08)
	_expect(s_mid > 1.0 and s_mid < 1.08, "bounce at local_t=0.8 should be in (1.0, 1.08), got %f" % s_mid)

	# local_t>=1: 1.0
	var s_end: float = battle.call("_overlay_bounce_scale", 1.0, 0.70, 1.08)
	_expect(absf(s_end - 1.0) < 0.01, "bounce at local_t=1 should be 1.0, got %f" % s_end)

	# === 测试 3: _overlay_ease_offset 起始/中段/结束 ===
	var off0: float = battle.call("_overlay_ease_offset", 0.0, 12.0)
	_expect(absf(off0 - 12.0) < 0.01, "offset at local_t=0 should be full (12), got %f" % off0)

	var off_end: float = battle.call("_overlay_ease_offset", 1.0, 12.0)
	_expect(absf(off_end) < 0.01, "offset at local_t=1 should be 0, got %f" % off_end)

	var off_mid: float = battle.call("_overlay_ease_offset", 0.5, 12.0)
	_expect(off_mid > 0.0 and off_mid < 12.0, "offset at local_t=0.5 should be in (0, 12), got %f" % off_mid)

	# === 测试 4: _overlay_xform 完整流（burst：start=0.04, dur=0.32, scale_start=0.70, offset=12） ===
	# t<start: alpha=0, scale=start, offset=full
	battle.set("_battle_end_overlay_timer", 0.0)
	var bx: Dictionary = battle.call("_overlay_xform", 0.04, 0.32, 0.70, 1.08, 12.0)
	_expect(absf(bx["alpha"]) < 0.01, "burst alpha should be 0 before start, got %f" % bx["alpha"])
	_expect(absf(bx["scale"] - 0.70) < 0.01, "burst scale should be start (0.70) before start, got %f" % bx["scale"])
	_expect(absf(bx["offset_y"] - 12.0) < 0.01, "burst offset should be full (12) before start, got %f" % bx["offset_y"])

	# 中间态：t=0.20 → local_t = (0.20-0.04)/0.32 = 0.5（第一段中段）
	battle.set("_battle_end_overlay_timer", 0.20)
	bx = battle.call("_overlay_xform", 0.04, 0.32, 0.70, 1.08, 12.0)
	_expect(bx["alpha"] > 0.0 and bx["alpha"] < 1.0, "burst alpha should be in (0,1) at t=0.20, got %f" % bx["alpha"])
	_expect(bx["scale"] > 0.70 and bx["scale"] <= 1.08, "burst scale should grow towards overshoot at t=0.20, got %f" % bx["scale"])
	_expect(bx["offset_y"] > 0.0 and bx["offset_y"] < 12.0, "burst offset should shrink at t=0.20, got %f" % bx["offset_y"])

	# 结束态：t=0.40 (>=0.04+0.32=0.36) → alpha=1, scale=1, offset=0
	battle.set("_battle_end_overlay_timer", 0.40)
	bx = battle.call("_overlay_xform", 0.04, 0.32, 0.70, 1.08, 12.0)
	_expect(absf(bx["alpha"] - 1.0) < 0.01, "burst alpha should be 1 at t=0.40, got %f" % bx["alpha"])
	_expect(absf(bx["scale"] - 1.0) < 0.01, "burst scale should be 1 at t=0.40, got %f" % bx["scale"])
	_expect(absf(bx["offset_y"]) < 0.01, "burst offset should be 0 at t=0.40, got %f" % bx["offset_y"])

	# === 测试 5: _overlay_stretch_x（下划线）行为 ===
	# t<start (0.28): alpha=0, scale_x=0
	battle.set("_battle_end_overlay_timer", 0.10)
	var ux: Dictionary = battle.call("_overlay_stretch_x", 0.28, 0.24)
	_expect(absf(ux["alpha"]) < 0.01, "underline alpha should be 0 before start, got %f" % ux["alpha"])
	_expect(absf(ux["scale_x"]) < 0.01, "underline scale_x should be 0 before start, got %f" % ux["scale_x"])

	# 中段：t=0.40 → local_t=(0.40-0.28)/0.24=0.5；scale_x ≈ 0.5（线性）
	battle.set("_battle_end_overlay_timer", 0.40)
	ux = battle.call("_overlay_stretch_x", 0.28, 0.24)
	_expect(ux["alpha"] > 0.0 and ux["alpha"] < 1.0, "underline alpha should be in (0,1) at t=0.40, got %f" % ux["alpha"])
	_expect(absf(ux["scale_x"] - 0.5) < 0.05, "underline scale_x should be ~0.5 at local_t=0.5, got %f" % ux["scale_x"])

	# 结束：t=0.60 (>=0.52) → alpha=1, scale_x=1
	battle.set("_battle_end_overlay_timer", 0.60)
	ux = battle.call("_overlay_stretch_x", 0.28, 0.24)
	_expect(absf(ux["alpha"] - 1.0) < 0.01, "underline alpha should be 1 at t=0.60, got %f" % ux["alpha"])
	_expect(absf(ux["scale_x"] - 1.0) < 0.01, "underline scale_x should be 1 at t=0.60, got %f" % ux["scale_x"])

	# === 测试 6: 不同元素的 stagger（确保后续元素更晚启动） ===
	# 在 t=0.10 时：bg 在中段，burst 刚启动一会儿，banner 刚启动，panel/underline/plaque/tap 还没启动
	battle.set("_battle_end_overlay_timer", 0.10)
	var bg2: float = battle.call("_overlay_fade", 0.00, 0.18)
	_expect(bg2 > 0.0, "bg should have alpha > 0 at t=0.10, got %f" % bg2)

	var panel_x: Dictionary = battle.call("_overlay_xform", 0.14, 0.24, 0.92, 1.0, 0.0)
	_expect(absf(panel_x["alpha"]) < 0.01, "panel should not start before t=0.14, got alpha=%f" % panel_x["alpha"])

	var underline_x: Dictionary = battle.call("_overlay_stretch_x", 0.28, 0.24)
	_expect(absf(underline_x["alpha"]) < 0.01, "underline should not start at t=0.10, got alpha=%f" % underline_x["alpha"])

	var plaque_x: Dictionary = battle.call("_overlay_xform", 0.36, 0.22, 0.78, 1.05, 0.0)
	_expect(absf(plaque_x["alpha"]) < 0.01, "plaque should not start at t=0.10, got alpha=%f" % plaque_x["alpha"])

	var tap_x: Dictionary = battle.call("_overlay_xform", 0.46, 0.22, 0.85, 1.06, 10.0)
	_expect(absf(tap_x["alpha"]) < 0.01, "tap strip should not start at t=0.10, got alpha=%f" % tap_x["alpha"])

	# === 测试 7: t >= TOTAL_DURATION (0.70) 后所有元素已完成 ===
	battle.set("_battle_end_overlay_timer", 0.80)
	_expect(absf(battle.call("_overlay_fade", 0.00, 0.18) - 1.0) < 0.01, "bg should be 1 after total duration")

	var burst_done: Dictionary = battle.call("_overlay_xform", 0.04, 0.32, 0.70, 1.08, 12.0)
	_expect(absf(burst_done["scale"] - 1.0) < 0.01, "burst scale should be 1 after total duration")
	_expect(absf(burst_done["alpha"] - 1.0) < 0.01, "burst alpha should be 1 after total duration")
	_expect(absf(burst_done["offset_y"]) < 0.01, "burst offset should be 0 after total duration")

	var banner_done: Dictionary = battle.call("_overlay_xform", 0.08, 0.28, 0.80, 1.05, -22.0)
	_expect(absf(banner_done["scale"] - 1.0) < 0.01, "banner scale should be 1 after total duration")
	_expect(absf(banner_done["offset_y"]) < 0.01, "banner offset should be 0 after total duration")

	var panel_done: Dictionary = battle.call("_overlay_xform", 0.14, 0.24, 0.92, 1.0, 0.0)
	_expect(absf(panel_done["scale"] - 1.0) < 0.01, "panel scale should be 1 after total duration")

	var underline_done: Dictionary = battle.call("_overlay_stretch_x", 0.28, 0.24)
	_expect(absf(underline_done["scale_x"] - 1.0) < 0.01, "underline scale_x should be 1 after total duration")

	var plaque_done: Dictionary = battle.call("_overlay_xform", 0.36, 0.22, 0.78, 1.05, 0.0)
	_expect(absf(plaque_done["scale"] - 1.0) < 0.01, "plaque scale should be 1 after total duration")

	var tap_done: Dictionary = battle.call("_overlay_xform", 0.46, 0.22, 0.85, 1.06, 10.0)
	_expect(absf(tap_done["scale"] - 1.0) < 0.01, "tap strip scale should be 1 after total duration")
	_expect(absf(tap_done["offset_y"]) < 0.01, "tap strip offset should be 0 after total duration")

	# === 测试 8: _make_centered_scale_xform / stretch / scale_offset 矩阵生成 ===
	var center := Vector2(100.0, 80.0)
	var m_scale: Transform2D = battle.call("_make_centered_scale_xform", center, 2.0)
	# 围绕 center scale 2.0：center 自身不动；origin 应位于 center - scale*center = -center
	_expect(absf((m_scale * center).x - center.x) < 0.5, "scale matrix should keep center.x fixed")
	_expect(absf((m_scale * center).y - center.y) < 0.5, "scale matrix should keep center.y fixed")

	var m_stretch: Transform2D = battle.call("_make_centered_stretch_x_xform", center, 0.5)
	_expect(absf((m_stretch * center).x - center.x) < 0.5, "stretch matrix should keep center.x fixed")
	_expect(absf((m_stretch * center).y - center.y) < 0.5, "stretch matrix should keep center.y fixed")

	# === 测试 9: _draw 在中段状态不崩溃 ===
	# 强制启用 overlay 并把 timer 推到中段，触发重绘
	battle.set("_battle_end_overlay_started", true)
	battle.set("_battle_end_overlay_timer", 0.20)
	battle.queue_redraw()
	await process_frame
	await process_frame
	_expect(true, "drawing battle-end overlay mid-entry should not crash")

	# 结束态
	battle.set("_battle_end_overlay_timer", 0.80)
	battle.queue_redraw()
	await process_frame
	await process_frame
	_expect(true, "drawing battle-end overlay after total duration should not crash")

	main.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleEndOverlayEntry] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleEndOverlayEntry] " + failure)
	quit(1)

extends SceneTree

## 伤害飘字 + 血条扣血升级回归：
## 1. 参数口径：字体链 / 字重 / 字号 / 描边 / 上升 / 时长 / 快显 / 淡出 / 错峰 / 层数；
## 2. 调用方随机量：范围正确，同一 context 重复生成逐位一致，渲染阶段不再取随机数；
## 3. 血条：红条 0.08s 落位、白段停 0.22s 后按 0.55 条/秒追、回血 / 换兵立即对齐、
##    <30% 时 1.2Hz / 8% 脉冲；
## 4. 总开关：关闭时回到基线 2f50f09 表现，且固定战局的日志与结算 JSON 与基线逐位一致；
## 5. 真实战斗场景：命中帧之前不出现飘字，命中帧当帧生成飘字。

const DamageFeedbackScript = preload("res://src/ui/components/damage_feedback.gd")
const BattleHpBarScript = preload("res://src/ui/components/battle_hp_bar.gd")
const BattleHitReactionScript = preload("res://src/ui/components/battle_hit_reaction.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const BASELINE_PATH := "res://docs/qa/damage_feedback/baseline_combat_log.json"
const GEM_TYPES := ["fire", "water", "grass", "thunder", "light"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_config()
	_test_styles()
	_test_call_site_randomness()
	_test_curve_helpers()
	_test_hp_bar_upgraded()
	_test_hp_bar_full_drain()
	_test_heal_and_snap()
	_test_low_hp_pulse()
	_test_hp_bar_switch_off()
	_test_combat_logs_match_baseline()
	await _test_scene_popup_context_determinism()
	await _test_no_popup_before_hit_frame()
	DamageFeedbackScript.enabled = true
	BattleHitReactionScript.enabled = true
	_finish()


func _test_config() -> void:
	_expect(DamageFeedbackScript.enabled, "伤害反馈总开关默认开启")
	_expect(DamageFeedbackScript.FONT_NAMES.size() == 3, "字体链应为三档")
	_expect(str(DamageFeedbackScript.FONT_NAMES[0]) == "Impact", "字体链第一档应为 Impact")
	_expect(str(DamageFeedbackScript.FONT_NAMES[1]) == "Arial Black", "字体链第二档应为 Arial Black")
	_expect(str(DamageFeedbackScript.FONT_NAMES[2]) == "sans-serif", "字体链末尾应保留泛型族名")
	_expect(DamageFeedbackScript.FONT_WEIGHT == 900, "字重应为 900")
	_expect(DamageFeedbackScript.STROKE_COLOR.to_html(false) == "050508", "描边颜色应为 #050508")
	_expect(is_equal_approx(DamageFeedbackScript.STROKE_NORMAL, 2.0), "普通描边应为 2px")
	_expect(is_equal_approx(DamageFeedbackScript.STROKE_HEAVY, 3.0), "重击描边应为 3px")
	_expect(is_equal_approx(DamageFeedbackScript.STROKE_CRIT, 3.0), "暴击描边应为 3px")
	_expect(is_equal_approx(DamageFeedbackScript.FADE_IN, 0.04), "快显应为 0.04s")
	_expect(is_equal_approx(DamageFeedbackScript.FADE_OUT_START, 0.62), "0.62 起淡出")
	_expect(is_equal_approx(DamageFeedbackScript.STAGGER, 0.12), "错峰应为 0.12s")
	_expect(DamageFeedbackScript.MAX_LAYERS == 3, "最多应为 3 层")
	_expect(is_equal_approx(DamageFeedbackScript.rise_for_anchor(66.0), 30.0), "单体上升应为 30px")
	_expect(is_equal_approx(DamageFeedbackScript.rise_for_anchor(212.0), 12.0), "多敌横排上升应为 12px")
	_expect(is_equal_approx(DamageFeedbackScript.HP_RED_EASE, 0.08), "红条落位应 <=0.08s")
	_expect(is_equal_approx(DamageFeedbackScript.HP_TRAIL_HOLD, 0.22), "白段旧值停留应为 0.22s")
	_expect(is_equal_approx(DamageFeedbackScript.HP_TRAIL_RATE, 0.55), "白段追赶应为 0.55 条/秒")
	_expect(is_equal_approx(DamageFeedbackScript.HP_PULSE_HZ, 1.2), "低血脉冲应为 1.2Hz")
	_expect(is_equal_approx(DamageFeedbackScript.HP_PULSE_AMPLITUDE, 0.08), "脉冲幅度应为 8%")
	var font: Font = DamageFeedbackScript.comic_font()
	_expect(font != null, "漫画粗体字体应可创建")
	if font is SystemFont:
		_expect((font as SystemFont).font_weight == 900, "系统字体应请求 900 字重")
		_expect((font as SystemFont).font_names.size() == 3, "系统字体应带三档回退链")


func _test_styles() -> void:
	var normal: Dictionary = DamageFeedbackScript.damage_style(false, false, false)
	var heavy: Dictionary = DamageFeedbackScript.damage_style(false, false, true)
	var crit: Dictionary = DamageFeedbackScript.damage_style(true, false, false)
	var weak: Dictionary = DamageFeedbackScript.damage_style(false, true, false)
	_expect(str(normal["style"]) == "normal", "普通伤害应使用普通样式")
	_expect(is_equal_approx(float(normal["size"]), 21.0), "普通字号应为 21")
	_expect(is_equal_approx(float(heavy["size"]), 26.0), "重击字号应为 26")
	_expect(is_equal_approx(float(crit["size"]), 32.0), "暴击字号应为 32")
	_expect(is_equal_approx(float(normal["duration"]), 0.85), "普通时长应为 0.85s")
	_expect(is_equal_approx(float(heavy["duration"]), 0.85), "重击时长应为 0.85s")
	_expect(is_equal_approx(float(crit["duration"]), 0.95), "暴击时长应为 0.95s")
	_expect(str(crit["prefix"]) == "暴击", "暴击应保留「暴击」标签")
	_expect(str(heavy["prefix"]) == "", "重击不应带暴击标签")
	_expect(is_equal_approx(float(heavy["stroke"]), 3.0), "重击描边应为 3px")
	_expect(is_equal_approx(float(crit["stroke"]), 3.0), "暴击描边应为 3px")
	_expect(not DamageFeedbackScript.is_heavy_damage(39), "39 伤害不算重击")
	_expect(DamageFeedbackScript.is_heavy_damage(40), "40 伤害算重击")
	_expect((weak["color"] as Color) != (normal["color"] as Color), "弱效仍应视觉区分")


func _test_call_site_randomness() -> void:
	var first: Dictionary = DamageFeedbackScript.popup_random("enemy:0", 0)
	var second: Dictionary = DamageFeedbackScript.popup_random("enemy:0", 0)
	_expect(JSON.stringify(first) == JSON.stringify(second), "同一 context / 序号应得到逐位一致的随机量")
	var jitter: Vector2 = first["jitter"]
	_expect(absf(jitter.x) <= DamageFeedbackScript.JITTER_PX + 0.001, "出生抖动 X 应在 ±3px 内")
	_expect(absf(jitter.y) <= DamageFeedbackScript.JITTER_PX + 0.001, "出生抖动 Y 应在 ±3px 内")
	var rise_scale := float(first["rise_scale"])
	_expect(
		rise_scale >= DamageFeedbackScript.RISE_SCALE_MIN - 0.001 and rise_scale <= DamageFeedbackScript.RISE_SCALE_MAX + 0.001,
		"上升倍率应在 0.85–1.15"
	)
	_expect(absf(float(first["drift"])) <= DamageFeedbackScript.DRIFT_PX + 0.001, "横漂应在 ±6px 内")
	var pop := float(first["pop"])
	_expect(pop >= DamageFeedbackScript.POP_MIN - 0.001 and pop <= DamageFeedbackScript.POP_MAX + 0.001, "弹出应在 1.28–1.48")
	var third: Dictionary = DamageFeedbackScript.popup_random("enemy:0", 1)
	_expect(JSON.stringify(first) != JSON.stringify(third), "同一 context 的不同序号应得到不同随机量")
	var other_context: Dictionary = DamageFeedbackScript.popup_random("enemy:1", 0)
	_expect(JSON.stringify(first) != JSON.stringify(other_context), "不同 context 应得到不同随机量")


func _test_curve_helpers() -> void:
	_expect(is_equal_approx(DamageFeedbackScript.ease_out_cubic(0.0), 0.0), "ease-out cubic 起点应为 0")
	_expect(is_equal_approx(DamageFeedbackScript.ease_out_cubic(1.0), 1.0), "ease-out cubic 终点应为 1")
	_expect(is_equal_approx(DamageFeedbackScript.ease_out_cubic(0.5), 0.875), "ease-out cubic 中点应为 0.875")
	_expect(is_zero_approx(DamageFeedbackScript.fade_alpha(0.0, 0.85)), "命中帧当帧飘字不透明度应为 0")
	_expect(is_equal_approx(DamageFeedbackScript.fade_alpha(0.02, 0.85), 0.5), "0.02s 时应处于快显中段")
	_expect(is_equal_approx(DamageFeedbackScript.fade_alpha(0.04, 0.85), 1.0), "0.04s 时应完全显现")
	_expect(is_equal_approx(DamageFeedbackScript.fade_alpha(0.85 * 0.62, 0.85), 1.0), "0.62 之前应保持不透明")
	_expect(is_zero_approx(DamageFeedbackScript.fade_alpha(0.85, 0.85)), "时长结束时应完全淡出")
	var pop := 1.4
	_expect(is_equal_approx(DamageFeedbackScript.pop_scale(0.0, pop), pop), "弹出应从调用方给定的倍率开始")
	_expect(
		DamageFeedbackScript.pop_scale(0.06, pop) < pop and DamageFeedbackScript.pop_scale(0.06, pop) >= 1.0,
		"弹出应在 0.12s 内回落"
	)
	_expect(is_equal_approx(DamageFeedbackScript.pop_scale(0.12, pop), 1.0), "0.12s 后缩放应回到 1.0")
	_expect(is_equal_approx(DamageFeedbackScript.stroke_width(3.0, 1.0), 3.0), "字高不缩放时描边应保持 3px")


func _test_hp_bar_upgraded() -> void:
	_reset_switches()
	var bar = _make_bar(100.0)
	bar.set_target_value(40.0)
	_expect(bar.call("is_easing"), "红条应开始落位")
	_expect(is_equal_approx(bar.value, 100.0), "落位第一帧不应瞬跳")
	bar._process(0.02)
	_expect(bar.value > 40.0 + 0.001, "落位不应瞬跳（0.02s 时仍在旧值与目标值之间）")
	bar._process(0.061)
	_expect(is_equal_approx(bar.value, 40.0), "红条应在 0.08s 内落位")
	_expect(not bar.call("is_easing"), "落位完成后应结束缓动")
	_expect(is_equal_approx(bar.trail_value, 100.0), "白段在落位后应仍停在旧值")
	bar._process(0.10)
	_expect(is_equal_approx(bar.trail_value, 100.0), "白段 0.22s 内不应移动")
	bar.free()

	# 掉 30% 血：0.10s 时白段仍 >= 原值 - 2%，1.0s 时已明显缩短。
	var loss = _make_bar(100.0)
	loss.set_target_value(70.0)
	loss._process(0.10)
	_expect(is_equal_approx(loss.value, 70.0), "红条 0.10s 时应已落位")
	print("[DamageFeedback] 掉 30%%：0.10s 红条=%.2f 白段=%.2f（要求白段 >= 98）" % [loss.value, loss.trail_value])
	_expect(loss.trail_value >= 98.0, "掉 30%% 后 0.10s 白段应 >= 原值 - 2%%（实际 %.2f）" % loss.trail_value)
	loss._process(0.90)
	print("[DamageFeedback] 掉 30%%：1.0s 红条=%.2f 白段=%.2f（要求白段明显缩短）" % [loss.value, loss.trail_value])
	_expect(loss.trail_value <= 70.001, "1.0s 时白段应已明显缩短（实际 %.2f）" % loss.trail_value)
	loss.free()


func _test_hp_bar_full_drain() -> void:
	_reset_switches()
	var bar = _make_bar(100.0)
	bar.set_target_value(0.0)
	var total := 0.0
	var moving_start := -1.0
	for _i in range(600):
		bar._process(1.0 / 60.0)
		total += 1.0 / 60.0
		if moving_start < 0.0 and bar.trail_value < 99.999:
			moving_start = total
		if not bar.call("is_trailing") and is_zero_approx(bar.trail_value):
			break
	_expect(moving_start > 0.0, "白段应开始追赶")
	var catch_up := total - moving_start
	# 0.55 条/秒 → 满格到空格约 1/0.55 = 1.82s（不含 0.22s 停留）。
	print("[DamageFeedback] 满格到 0：白段追赶 %.3fs（1/0.55=1.82s），含 0.22s 停留总时长 %.3fs" % [catch_up, total])
	_expect(
		catch_up >= 1.6 and catch_up <= 2.0,
		"满格到空格的白段追赶时长应在 1.8s±0.2s（实际 %.3fs）" % catch_up
	)
	_expect(
		total >= DamageFeedbackScript.HP_TRAIL_HOLD + 1.6 and total <= DamageFeedbackScript.HP_TRAIL_HOLD + 2.0,
		"含 0.22s 停留的总时长应约为 2.04s（实际 %.3fs）" % total
	)
	bar.free()


func _test_heal_and_snap() -> void:
	_reset_switches()
	var bar = _make_bar(100.0)
	bar.set_target_value(50.0)
	bar._process(1.2)
	_expect(bar.trail_value <= 50.001, "掉血后白段应已追上红条")
	bar.set_target_value(90.0)
	_expect(is_equal_approx(bar.value, 90.0), "回血应立即对齐红条")
	_expect(is_equal_approx(bar.trail_value, 90.0), "回血应立即对齐白段")
	_expect(not bar.call("is_trailing"), "回血后不应残留白段追赶")
	bar.set_target_value(40.0)
	_expect(bar.trail_value >= 89.9, "再次掉血应重新记录旧白段")
	bar.call("snap_to_value", 30.0)
	_expect(is_equal_approx(bar.value, 30.0) and is_equal_approx(bar.trail_value, 30.0), "换兵应立即对齐")
	_expect(not bar.call("is_easing") and not bar.call("is_trailing"), "换兵后不应残留动画")
	bar.free()


func _test_low_hp_pulse() -> void:
	_reset_switches()
	var quarter := 1.0 / (DamageFeedbackScript.HP_PULSE_HZ * 4.0)
	_expect(is_equal_approx(DamageFeedbackScript.pulse_factor(0.0), 1.0), "脉冲起点亮度应为 1.0")
	_expect(
		absf(DamageFeedbackScript.pulse_factor(quarter) - 1.08) < 0.0001,
		"1/4 周期峰值应为 1.08"
	)
	_expect(
		absf(DamageFeedbackScript.pulse_factor(quarter * 3.0) - 0.92) < 0.0001,
		"3/4 周期谷值应为 0.92"
	)
	var bar = _make_bar(20.0)
	var lowest := 10.0
	var highest := 0.0
	for _i in range(120):
		bar._process(1.0 / 60.0)
		var factor: float = bar.call("pulse_factor")
		lowest = minf(lowest, factor)
		highest = maxf(highest, factor)
	_expect(highest >= 1.07, "低血红条应出现 8%% 正向脉冲（实际峰值 %.3f）" % highest)
	_expect(lowest <= 0.93, "低血红条应出现 8%% 负向脉冲（实际谷值 %.3f）" % lowest)
	bar.free()
	var safe = _make_bar(40.0)
	safe._process(0.1)
	_expect(is_equal_approx(safe.call("pulse_factor"), 1.0), "血量 >=30%% 时不应脉冲")
	safe.free()


func _test_hp_bar_switch_off() -> void:
	# 总开关关闭 = 基线 0.25s 缓降；受击反应总开关关闭 = 立即跳转（旧口径保留）。
	DamageFeedbackScript.enabled = false
	BattleHitReactionScript.enabled = true
	var bar = _make_bar(100.0)
	bar.set_target_value(40.0)
	_expect(bar.call("is_easing"), "总开关关闭时应沿用基线 0.25s 缓降")
	bar._process(0.10)
	_expect(bar.value < 100.0 and bar.value > 40.0, "基线缓降 0.10s 应处于中间值")
	_expect(is_equal_approx(bar.trail_value, bar.value), "总开关关闭时不应出现白段")
	bar._process(0.16)
	_expect(is_equal_approx(bar.value, 40.0), "基线缓降应在 0.25s 内完成")
	bar.free()

	DamageFeedbackScript.enabled = true
	BattleHitReactionScript.enabled = false
	var snapped = _make_bar(100.0)
	snapped.set_target_value(40.0)
	_expect(not snapped.call("is_easing"), "受击反应关闭时红条不应缓动")
	_expect(is_equal_approx(snapped.value, 40.0), "受击反应关闭时红条应瞬跳")
	_expect(is_equal_approx(snapped.trail_value, 40.0), "受击反应关闭时不应留白段")
	snapped.free()
	_reset_switches()


## 固定 20 回合战斗：开关开启 / 关闭两种状态都必须与基线 2f50f09 的日志和结算 JSON 逐位一致。
func _test_combat_logs_match_baseline() -> void:
	var file := FileAccess.open(BASELINE_PATH, FileAccess.READ)
	if file == null:
		_failures.append("缺少基线战斗日志：%s" % BASELINE_PATH)
		return
	var expected_text := file.get_as_text()
	file.close()
	var expected: Variant = JSON.parse_string(expected_text)
	if not expected is Dictionary:
		_failures.append("基线战斗日志无法解析")
		return
	var expected_canonical := _canonical_json(expected)

	DamageFeedbackScript.enabled = true
	var enabled_payload := _run_deterministic_battle()
	var enabled_text := _canonical_json(enabled_payload)
	_expect(enabled_text == expected_canonical, "开启伤害反馈后固定战局日志与结算 JSON 应与基线 2f50f09 逐位一致")

	DamageFeedbackScript.enabled = false
	var disabled_payload := _run_deterministic_battle()
	var disabled_text := _canonical_json(disabled_payload)
	_expect(disabled_text == expected_canonical, "关闭伤害反馈后固定战局日志与结算 JSON 应与基线 2f50f09 逐位一致")
	_expect(enabled_text == disabled_text, "总开关开 / 关不应改动战斗日志与结算 JSON")
	DamageFeedbackScript.enabled = true


func _run_deterministic_battle() -> Dictionary:
	seed(20261109)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], ["enemy_001"], 5, 1, stage, "stage_1_1")
	battle.enemies[0]["maxHP"] = 900
	battle.enemies[0]["hp"] = 900
	battle.max_turns = 50

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	battle.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))

	var combos: Array = [4, 3, 2, 1]
	var turns: Array = []
	for turn in range(1, 21):
		battle.turn_count = turn
		var combo := int(combos[(turn - 1) % combos.size()])
		var result: Dictionary = battle.process_match_result({"fire": 3, "water": 3, "grass": 3}, combo)
		turns.append({
			"turn": turn,
			"combo": combo,
			"damage_log": result.get("damage_log", [])
		})
		if battle.check_battle_end():
			break
		var enemy: Dictionary = battle.enemy_action()
		turns[turns.size() - 1]["actions"] = enemy.get("actions", [])
		if battle.battle_over:
			break

	var result: Dictionary = battle.get_battle_result()
	var payload := {
		"source_commit": "2f50f09",
		"seed": 20261109,
		"stage_id": "stage_1_1",
		"player_level": 5,
		"enemy_level": 1,
		"turns": turns,
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"battle_result": result
	}
	battle.free()
	return payload


func _canonical_json(value: Variant) -> String:
	var text := JSON.stringify(value, "\t")
	var parsed: Variant = JSON.parse_string(text)
	return JSON.stringify(parsed, "\t")


## 同一段飘字调用序列渲染两次：与 context 绑定的随机量应逐位一致。
func _test_scene_popup_context_determinism() -> void:
	_reset_switches()
	var first := await _spawn_popup_sequence()
	var second := await _spawn_popup_sequence()
	_expect(first.size() == 3, "应生成三条飘字（普通 / 重击 / 暴击），实际 %d" % first.size())
	_expect(JSON.stringify(first) == JSON.stringify(second), "同一 context 的两次渲染位置与随机量应逐位一致")
	var heavy_count := 0
	var crit_count := 0
	for entry: Dictionary in first:
		if str(entry.get("damage_style", "")) == "heavy":
			heavy_count += 1
		if str(entry.get("damage_style", "")) == "crit":
			crit_count += 1
		_expect(bool(entry.get("comic", false)), "开启时飘字应走漫画渲染路径")
		_expect(float(entry.get("stroke", 0.0)) >= 2.0, "开启时飘字应带描边")
	_expect(heavy_count == 1, "伤害 >=40 应使用重击样式")
	_expect(crit_count == 1, "暴击应使用暴击样式")


func _spawn_popup_sequence() -> Array:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1")
	})
	await process_frame
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	_expect(battle_scene != null and battle_scene.get("_battle") != null, "战斗场景应初始化")
	if battle_scene == null or battle_scene.get("_battle") == null:
		main.queue_free()
		await process_frame
		return []
	battle_scene.call("_spawn_enemy_damage_popup", "-27", 0, false, false, false, 27)
	battle_scene.call("_spawn_enemy_damage_popup", "-94", 0, false, false, false, 94)
	battle_scene.call("_spawn_enemy_damage_popup", "-368", 0, true, false, false, 368)
	await process_frame
	var snapshot: Array = []
	for entry: Dictionary in battle_scene.get("_floating_texts"):
		if str(entry.get("damage_style", "")).is_empty():
			continue
		snapshot.append({
			"text": entry.get("text", ""),
			"x": entry.get("x", 0.0),
			"y": entry.get("y", 0.0),
			"start_x": entry.get("start_x", 0.0),
			"start_y": entry.get("start_y", 0.0),
			"rise": entry.get("rise", 0.0),
			"rise_scale": entry.get("rise_scale", 0.0),
			"drift": entry.get("drift", 0.0),
			"pop": entry.get("pop", 0.0),
			"size": entry.get("size", 0.0),
			"duration": entry.get("duration", 0.0),
			"delay": entry.get("delay", 0.0),
			"lane": entry.get("lane", 0),
			"stroke": entry.get("stroke", 0.0),
			"comic": entry.get("comic", false),
			"damage_style": entry.get("damage_style", "")
		})
	main.queue_free()
	await process_frame
	await process_frame
	return snapshot


## 真实战斗场景：命中造成掉血的那一帧才允许出现飘字，之前任何一帧都不许有。
func _test_no_popup_before_hit_frame() -> void:
	_reset_switches()
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1")
	})
	await process_frame
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	var battle = battle_scene.get("_battle") if battle_scene != null else null
	if battle == null or battle.enemies.is_empty():
		_failures.append("命中帧检查需要可用的战斗场景")
		main.queue_free()
		await process_frame
		return
	battle_scene.set("_message_text", "")
	battle_scene.set("_message_timer", 0.0)
	var board = battle_scene.get("_board")
	_fill_demo_board(board)
	board.grid[0][0] = "water"
	board.grid[0][1] = "fire"
	board.grid[0][2] = "water"
	board.grid[0][3] = "water"
	board.grid[1][0] = "fire"
	board.grid[2][0] = "fire"
	board.cascade_count = 0
	var enemy: Dictionary = battle.enemies[0]
	var hp_before := int(enemy.get("hp", 0))
	var first_hit_frame := -1
	var first_popup_frame := -1
	var popup_before_hit := false
	var popup_at_hit := false
	battle_scene.call("_do_swap", 0, 0, 0, 1)
	for frame in range(1, 180):
		await process_frame
		var has_damage_popup := _damage_popup_count(battle_scene) > 0
		var hp_now := int(enemy.get("hp", 0))
		if hp_now < hp_before and first_hit_frame < 0:
			first_hit_frame = frame
		if has_damage_popup and first_popup_frame < 0:
			first_popup_frame = frame
		if has_damage_popup and first_hit_frame < 0:
			popup_before_hit = true
		if first_hit_frame >= 0 and has_damage_popup:
			popup_at_hit = true
		if first_hit_frame >= 0 and first_popup_frame >= 0:
			break
	print("[DamageFeedback] 命中帧=%d 首个伤害飘字帧=%d" % [first_hit_frame, first_popup_frame])
	_expect(first_hit_frame > 0, "固定交换应造成敌方掉血")
	_expect(not popup_before_hit, "命中帧之前不得出现伤害飘字")
	_expect(first_popup_frame == first_hit_frame, "伤害飘字应在命中帧当帧生成（飘字帧 %d / 命中帧 %d）" % [first_popup_frame, first_hit_frame])
	_expect(popup_at_hit, "命中帧应出现伤害飘字")
	var hit_flashes: Array = battle_scene.get("_hit_flashes")
	_expect(not hit_flashes.is_empty() or first_hit_frame < 0, "命中帧之前不应有受击闪烁")
	main.queue_free()
	await process_frame
	await process_frame


func _damage_popup_count(battle_scene: Control) -> int:
	var count := 0
	for entry: Dictionary in battle_scene.get("_floating_texts"):
		if not str(entry.get("damage_style", "")).is_empty():
			count += 1
	return count


func _fill_demo_board(board) -> void:
	if board == null:
		return
	for r in range(board.rows):
		for c in range(board.cols):
			board.grid[r][c] = GEM_TYPES[(r + c * 2) % GEM_TYPES.size()]
			board.obstacles[r][c] = null
			board.locked_gems[r][c] = null
			board.poison_fog[r][c] = null


func _make_bar(initial: float):
	var bar = BattleHpBarScript.new()
	bar.value = initial
	bar.maximum = 100.0
	bar._ready()
	return bar


func _reset_switches() -> void:
	DamageFeedbackScript.enabled = true
	BattleHitReactionScript.enabled = true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[DamageFeedback] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[DamageFeedback] " + failure)
	quit(1)

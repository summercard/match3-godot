extends SceneTree

## 三消命中反馈回归：
## - 参数区间：普通消除顿帧 60–90ms / 位移 ≤6px / 整段 ≤0.15s；
##   4 连锁及以上顿帧 120–160ms / 位移 ≤10px
## - 总开关：关闭时不插入额外等待、不产生震屏与爆散，消除时序回到基线
## - 真实战斗场景：按引擎帧时钟对比关闭（基线）与开启（基线 + 顿帧）

const MatchHitFeedbackScript = preload("res://src/ui/components/match_hit_feedback.gd")
const GEM_TYPES := ["fire", "water", "grass", "thunder", "light"]
const BASE_PARTICLES_PER_GEM := 8  # spawn_eliminate_particles 的旧版粒子数
const ELIMINATE_DURATION := 0.25

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_config_ranges()
	_test_tier_resolution()
	_test_master_switch_off()
	var timing := await _measure_scene_timing()
	_test_baseline_timing(timing)
	_test_hitstop_timing(timing)
	await _test_chain_hitstop_in_scene()
	MatchHitFeedbackScript.enabled = true
	_finish()


func _test_config_ranges() -> void:
	var normal: Dictionary = MatchHitFeedbackScript.resolve(1)
	var chain: Dictionary = MatchHitFeedbackScript.resolve(4)
	_expect(str(normal.get("tier", "")) == "normal", "1 连锁应命中普通档")
	_expect(str(chain.get("tier", "")) == "chain", "4 连锁应命中连锁档")

	var normal_hitstop := float(normal.get("hitstop", 0.0))
	var chain_hitstop := float(chain.get("hitstop", 0.0))
	_expect(normal_hitstop >= 0.060 and normal_hitstop <= 0.090,
		"普通消除顿帧应在 60–90ms，实际 %.1fms" % (normal_hitstop * 1000.0))
	_expect(chain_hitstop >= 0.120 and chain_hitstop <= 0.160,
		"4 连锁顿帧应在 120–160ms，实际 %.1fms" % (chain_hitstop * 1000.0))
	_expect(float(normal.get("shake_amplitude", 99.0)) <= 6.0,
		"普通消除棋盘位移应 ≤6px")
	_expect(float(chain.get("shake_amplitude", 99.0)) <= 10.0,
		"4 连锁棋盘位移应 ≤10px")
	_expect(float(normal.get("beat", 99.0)) <= float(MatchHitFeedbackScript.CONFIG["normal_beat_max"]),
		"普通消除整段（顿帧 + 震屏）应 ≤0.15s，实际 %.3fs" % float(normal.get("beat", 0.0)))


func _test_tier_resolution() -> void:
	for level: int in [1, 2, 3]:
		_expect(str(MatchHitFeedbackScript.resolve(level).get("tier", "")) == "normal",
			"%d 连锁应使用普通档" % level)
	for level: int in [4, 5, 6, 8]:
		_expect(str(MatchHitFeedbackScript.resolve(level).get("tier", "")) == "chain",
			"%d 连锁应使用连锁档" % level)


func _test_master_switch_off() -> void:
	MatchHitFeedbackScript.enabled = false
	_expect(MatchHitFeedbackScript.resolve(1).is_empty(), "总开关关闭后普通档应整段跳过")
	_expect(MatchHitFeedbackScript.resolve(4).is_empty(), "总开关关闭后连锁档应整段跳过")
	_expect(is_zero_approx(MatchHitFeedbackScript.added_delay(1)), "总开关关闭后普通档额外等待应为 0")
	_expect(is_zero_approx(MatchHitFeedbackScript.added_delay(4)), "总开关关闭后连锁档额外等待应为 0")
	var shake: Dictionary = MatchHitFeedbackScript.update_shake(0.1, 0.06, 9.0, 0.016)
	_expect((shake.get("offset", Vector2.ONE) as Vector2).is_zero_approx(), "总开关关闭后不应产生震动位移")
	MatchHitFeedbackScript.enabled = true


func _measure_scene_timing() -> Dictionary:
	return {
		"off": await _measure_match_beat(false),
		"on": await _measure_match_beat(true),
	}


func _measure_match_beat(enabled_flag: bool) -> Dictionary:
	MatchHitFeedbackScript.enabled = enabled_flag
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var stage_db = load("res://src/data/stage_db.gd").new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		_failures.append("战斗场景应能加载")
		main.queue_free()
		await process_frame
		return {}
	var board = battle.get("_board")
	if board == null:
		_failures.append("战斗场景应创建棋盘")
		main.queue_free()
		await process_frame
		return {}
	_seed_swap_demo_board(board)
	await process_frame

	battle.call("_do_swap", 0, 0, 0, 1)
	var immediate_elim: bool = not (battle.get("_eliminating_gems") as Array).is_empty()
	var hitstop_at_start := float(battle.get("_match_hitstop_timer"))
	var shake_amplitude_at_start := float(battle.get("_match_shake_amplitude"))
	var particles_at_hit := (battle.get("_gem_particles") as Array).size()
	var glows_at_hit := (battle.get("_match_hit_glows") as Array).size()
	var glow_duration := 0.0
	for glow: Dictionary in battle.get("_match_hit_glows"):
		glow_duration = maxf(glow_duration, float(glow.get("duration", 0.0)))

	# 用战斗场景实际收到的帧时间累计引擎时间：--fixed-fps 60 下与 create_timer 同一时钟。
	# 消除列表在命中瞬间就已填好，顿帧冻结的是列表内动画进度（timer）。
	var elapsed := 0.0
	var time_to_anim := -1.0
	var guard := 0
	while time_to_anim < 0.0 and guard < 180:
		await process_frame
		elapsed += float(battle.get_process_delta_time())
		if _first_elim_timer(battle) > 0.0:
			time_to_anim = elapsed
		guard += 1
	guard = 0
	while not (battle.get("_eliminating_gems") as Array).is_empty() and guard < 180:
		await process_frame
		elapsed += float(battle.get_process_delta_time())
		guard += 1
	var total := elapsed

	main.queue_free()
	await process_frame
	return {
		"enabled": enabled_flag,
		"immediate_elim": immediate_elim,
		"hitstop_at_start": hitstop_at_start,
		"shake_amplitude_at_start": shake_amplitude_at_start,
		"particles_at_hit": particles_at_hit,
		"glows_at_hit": glows_at_hit,
		"glow_duration": glow_duration,
		"time_to_anim": time_to_anim,
		"elim_duration": total - maxf(time_to_anim, 0.0),
		"total": total,
	}


func _first_elim_timer(battle: Control) -> float:
	var eliminating: Array = battle.get("_eliminating_gems")
	if eliminating.is_empty():
		return 0.0
	return float(eliminating[0].get("timer", 0.0))


func _test_baseline_timing(timing: Dictionary) -> void:
	var off: Dictionary = timing.get("off", {})
	var configured := float(MatchHitFeedbackScript.CONFIG["normal"]["hitstop"])
	_expect(bool(off.get("immediate_elim", false)), "开关关闭时消除列表应在交换同帧填好（基线时序）")
	_expect(is_zero_approx(float(off.get("hitstop_at_start", -1.0))), "开关关闭时顿帧计时应为 0")
	_expect(is_zero_approx(float(off.get("shake_amplitude_at_start", -1.0))), "开关关闭时命中位移应为 0")
	_expect(int(off.get("particles_at_hit", -1)) == 6 * BASE_PARTICLES_PER_GEM,
		"开关关闭时爆散粒子数应保持旧版（6 格 × 8 粒），实际 %d" % int(off.get("particles_at_hit", -1)))
	_expect(int(off.get("glows_at_hit", -1)) == 0, "开关关闭时不应产生元素爆散光斑")
	_expect(float(off.get("time_to_anim", 9.9)) >= 0.0 and float(off.get("time_to_anim", 9.9)) <= 0.05,
		"开关关闭时消除动画应立即开始（基线时序），实际 %.3fs" % float(off.get("time_to_anim", -1.0)))
	_expect(absf(float(off.get("elim_duration", 0.0)) - ELIMINATE_DURATION) <= 0.08,
		"开关关闭时消除动画时长应与基线一致，实际 %.3fs" % float(off.get("elim_duration", 0.0)))
	_expect(float(off.get("total", 0.0)) <= ELIMINATE_DURATION + 0.08,
		"开关关闭时整段消除耗时应回到基线")
	_expect(configured > 0.0, "配置中的普通顿帧应大于 0")


func _test_hitstop_timing(timing: Dictionary) -> void:
	var on: Dictionary = timing.get("on", {})
	var off: Dictionary = timing.get("off", {})
	var configured := float(MatchHitFeedbackScript.CONFIG["normal"]["hitstop"])
	print("[MatchHitFeedback] off: anim_start=%.3fs elim=%.3fs total=%.3fs particles=%d" % [
		float(off.get("time_to_anim", -1.0)),
		float(off.get("elim_duration", 0.0)),
		float(off.get("total", 0.0)),
		int(off.get("particles_at_hit", -1)),
	])
	print("[MatchHitFeedback] on:  anim_start=%.3fs elim=%.3fs total=%.3fs particles=%d" % [
		float(on.get("time_to_anim", -1.0)),
		float(on.get("elim_duration", 0.0)),
		float(on.get("total", 0.0)),
		int(on.get("particles_at_hit", -1)),
	])
	_expect(absf(float(on.get("hitstop_at_start", 0.0)) - configured) <= 0.001,
		"开启后顿帧计时应等于配置值 %.3fs，实际 %.3fs" % [configured, float(on.get("hitstop_at_start", 0.0))])
	_expect(float(on.get("shake_amplitude_at_start", 0.0)) > 0.0 and float(on.get("shake_amplitude_at_start", 99.0)) <= 6.0,
		"开启后普通消除棋盘位移应在 (0, 6px]")
	_expect(int(on.get("particles_at_hit", 0)) > int(off.get("particles_at_hit", 0)),
		"开启后应追加元素爆散粒子")
	_expect(int(on.get("glows_at_hit", 0)) == 6, "开启后每个被消除格都应有元素爆散光斑，实际 %d" % int(on.get("glows_at_hit", 0)))
	_expect(float(on.get("glow_duration", 9.9)) <= 0.15,
		"元素爆散光斑应落在 0.15s 的整段反馈内，实际 %.3fs" % float(on.get("glow_duration", -1.0)))
	_expect(float(on.get("time_to_anim", 0.0)) >= configured - 0.02,
		"开启后消除动画应至少等待顿帧时长，实际 %.3fs" % float(on.get("time_to_anim", 0.0)))
	_expect(float(on.get("time_to_anim", 9.9)) <= configured + 0.08,
		"开启后顿帧不应明显超出配置，实际 %.3fs" % float(on.get("time_to_anim", 0.0)))
	_expect(absf(float(on.get("elim_duration", 0.0)) - float(off.get("elim_duration", 0.0))) <= 0.05,
		"开启顿帧后消除动画本身时长应保持不变")
	var added := float(on.get("total", 0.0)) - float(off.get("total", 0.0))
	_expect(added >= configured - 0.03 and added <= configured + 0.08,
		"开启后整段消除只应增加一个顿帧时长，实际增加 %.3fs" % added)


func _test_chain_hitstop_in_scene() -> void:
	MatchHitFeedbackScript.enabled = true
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var stage_db = load("res://src/data/stage_db.gd").new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		_failures.append("战斗场景应能加载（连锁档）")
		main.queue_free()
		await process_frame
		return
	var board = battle.get("_board")
	if board == null:
		_failures.append("战斗场景应创建棋盘（连锁档）")
		main.queue_free()
		await process_frame
		return
	_seed_ready_match_board(board)
	board.cascade_count = 3
	battle.call("_process_matches")
	var hitstop := float(battle.get("_match_hitstop_timer"))
	var amplitude := float(battle.get("_match_shake_amplitude"))
	_expect(hitstop >= 0.120 and hitstop <= 0.160,
		"第 4 连锁顿帧应在 120–160ms，实际 %.1fms" % (hitstop * 1000.0))
	_expect(amplitude > 0.0 and amplitude <= 10.0,
		"第 4 连锁棋盘位移应 ≤10px，实际 %.1fpx" % amplitude)
	main.queue_free()
	await process_frame


## 与 capture_runtime_scene.gd 的 --battle-demo-match 相同的棋盘：
## 交换 (0,0)/(0,1) 后形成水 3 消与火 3 消，共 6 个被消除格。
func _seed_swap_demo_board(board) -> void:
	if board == null:
		return
	_fill_pattern_board(board)
	board.grid[0][0] = "water"
	board.grid[0][1] = "fire"
	board.grid[0][2] = "water"
	board.grid[0][3] = "water"
	board.grid[1][0] = "fire"
	board.grid[2][0] = "fire"
	board.cascade_count = 0


## 第 4 连锁场景：棋盘上直接摆一组水 3 消，跳过交换直接处理命中。
func _seed_ready_match_board(board) -> void:
	if board == null:
		return
	_fill_pattern_board(board)
	board.grid[0][0] = "water"
	board.grid[0][1] = "water"
	board.grid[0][2] = "water"
	board.grid[0][3] = "thunder"  # 避免与基础图案拼成 4 连
	board.cascade_count = 0


func _fill_pattern_board(board) -> void:
	for r in range(board.rows):
		for c in range(board.cols):
			board.grid[r][c] = GEM_TYPES[(r + c * 2) % GEM_TYPES.size()]
			board.obstacles[r][c] = null
			board.locked_gems[r][c] = null
			board.poison_fog[r][c] = null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MatchHitFeedback] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[MatchHitFeedback] " + failure)
	quit(1)

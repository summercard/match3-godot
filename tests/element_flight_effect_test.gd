extends SceneTree

## 三消元素飞行三段式特效回归：
## 1. 参数口径：施法 0.18s / 飞行 0.24s / 总 0.42s（飞行 55%±10%）/ 命中 0.25s；
## 2. 坐标：出生点 = 被消除宝石中心，落点 = 怪物锚点，误差 ≤2px；
## 3. 命中段：扩环 10→46px 在 0.25s 内完成；白闪峰值帧不早于落点帧；
## 4. 粒子：单次 ≤5，轻量 / 均衡 / 华丽按 0.5 / 1.0 / 1.5 缩放，轻量不超过华丽一半；
## 5. 纯表现：a322404 固定种子战斗日志与结算 JSON 在开关开 / 关时逐字节一致。

const EffectScript = preload("res://src/ui/components/element_flight_effect.gd")
const PresentationProfileScript = preload("res://src/ui/components/presentation_profile.gd")
const BattleAnimationControllerScript = preload("res://src/ui/components/battle_animation_controller.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const BASELINE_PATH := "res://docs/qa/element_flight/baseline_combat_log.json"
const GEM_TYPES := ["fire", "water", "grass", "thunder", "light"]
## 一次双三消的 6 个被消除格；交叉格 (4,3) 同时属于水横排与火竖排。
const GEM_CENTERS := [
	[4, 4],
	[4, 5],
	[4, 6],
	[4, 3],
	[5, 3],
	[6, 3],
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_config()
	_test_master_switch()
	var timing := _test_timing_measurements()
	_test_tier_scaling()
	_test_battle_logs_match_baseline()
	await _test_scene_spawn_coordinates()
	EffectScript.enabled = true
	_finish()


func _test_config() -> void:
	var config: Dictionary = EffectScript.CONFIG
	var cast_duration := float(config["cast_duration"])
	var flight_duration := float(config["flight_duration"])
	var total_duration := float(config["total_duration"])
	_expect(is_equal_approx(cast_duration, 0.18), "施法段应为 0.18s")
	_expect(is_equal_approx(flight_duration, 0.24), "飞行段应为 0.24s")
	_expect(is_equal_approx(total_duration, 0.42), "总时长应为 0.42s")
	_expect(is_equal_approx(cast_duration + flight_duration, total_duration), "施法 + 飞行应等于总时长")
	_expect(is_equal_approx(float(config["hit_duration"]), 0.25), "命中段应为 0.25s")
	_expect(is_equal_approx(float(config["flash_peak_time"]), 0.06), "白闪应在 0.06s 达峰")
	_expect(is_equal_approx(float(config["ring_start_diameter"]), 10.0), "扩环起始直径应为 10px")
	_expect(is_equal_approx(float(config["ring_end_diameter"]), 46.0), "扩环结束直径应为 46px")
	_expect(
		float(config["control_raise_px"]) >= 40.0 and float(config["control_raise_px"]) <= 60.0,
		"贝塞尔控制点应抬高 40–60px，实际 %.1fpx" % float(config["control_raise_px"])
	)
	_expect(int(config["max_particles"]) <= 5, "单次效果粒子硬上限应为 5")
	_expect(EffectScript.enabled, "特效总开关默认开启")


func _test_master_switch() -> void:
	EffectScript.enabled = false
	var holder := Node2D.new()
	root.add_child(holder)
	var effect = EffectScript.spawn(holder, Vector2(10.0, 20.0), Vector2(30.0, 40.0), Color.WHITE, {})
	_expect(effect == null, "总开关关闭时 spawn 应返回 null")
	_expect(holder.get_child_count() == 0, "总开关关闭时不应创建任何表现节点")
	holder.queue_free()
	EffectScript.enabled = true


func _test_timing_measurements() -> Dictionary:
	var origin := Vector2(192.5, 475.5)
	var anchor := Vector2(187.5, 66.0)
	var effect = EffectScript.new()
	effect.setup(origin, anchor, Color(0.1, 0.4, 1.0), {"effect_density": 1.0})

	var step := 0.001
	var elapsed := 0.0
	var cast_end := -1.0
	var landing := -1.0
	var cast_scale_end := 0.0
	var glow_mid := 0.0
	var max_trail := 0
	var flight_start_pos := origin
	var flight_mid_pos := origin
	var ring_min := -1.0
	var ring_max := 0.0
	var ring_reach := -1.0
	var flash_peak := -1.0
	var particles_at_landing := 0
	var frame_landing := -1
	var frame_peak := -1
	var frame_peak_alpha := 0.0
	while elapsed < 0.75 and not effect.is_finished():
		effect.advance(step)
		elapsed += step
		var snapshot: Dictionary = effect.get_snapshot()
		if cast_end < 0.0 and str(snapshot["phase"]) == "flight":
			cast_end = float(snapshot["cast_end_time"])
			cast_scale_end = float(snapshot["scale"])
			flight_start_pos = snapshot["position"]
		if absf(elapsed - 0.09) < step * 0.5:
			glow_mid = float(snapshot["glow_alpha"])
		if absf(elapsed - 0.30) < step * 0.5:
			flight_mid_pos = snapshot["position"]
		max_trail = maxi(max_trail, int(snapshot["trail_count"]))
		if landing < 0.0 and float(snapshot["landing_time"]) >= 0.0:
			landing = float(snapshot["landing_time"])
			particles_at_landing = int(snapshot["particles_alive"])
			ring_min = float(snapshot["ring_diameter"])
		if float(snapshot["flash_peak_time"]) >= 0.0:
			flash_peak = float(snapshot["flash_peak_time"])
		var ring_now := float(snapshot["ring_diameter"])
		ring_max = maxf(ring_max, ring_now)
		if ring_reach < 0.0 and ring_now >= 45.9:
			ring_reach = elapsed - landing

	var total_observed := landing
	var flight_observed := landing - cast_end
	var flight_ratio := flight_observed / total_observed
	var first_half := flight_start_pos.distance_to(flight_mid_pos)
	var second_half := flight_mid_pos.distance_to(anchor)
	var control_raise: float = ((origin + anchor) * 0.5).y - float(effect.control.y)
	var final_snapshot: Dictionary = effect.get_snapshot()

	_expect(total_observed >= 0.37 and total_observed <= 0.47,
		"总时长应在 0.42s±0.05s，实测 %.3fs" % total_observed)
	_expect(flight_ratio >= 0.45 and flight_ratio <= 0.65,
		"飞行段应占总时长 55%%±10%%，实测 %.1f%%" % (flight_ratio * 100.0))
	_expect(cast_end >= 0.17 and cast_end <= 0.20, "施法段实测应接近 0.18s，实际 %.3fs" % cast_end)
	_expect(is_equal_approx(cast_scale_end, 1.25), "施法段结束元素应放大到 1.25，实际 %.3f" % cast_scale_end)
	_expect(glow_mid > 0.5 and glow_mid < 1.0,
		"施法段中光晕应处于递增区间，0.09s 实际 %.3f" % glow_mid)
	_expect(max_trail >= 4, "飞行段应留下拖尾采样，实际最多 %d 个采样点" % max_trail)
	_expect(float(final_snapshot["spawn_error"]) <= 2.0,
		"出生点与传入宝石中心误差应 ≤2px，实际 %.3fpx" % float(final_snapshot["spawn_error"]))
	_expect(float(final_snapshot["landing_error"]) <= 2.0,
		"落点与怪物锚点误差应 ≤2px，实际 %.3fpx" % float(final_snapshot["landing_error"]))
	_expect(anchor.distance_to(final_snapshot["landing_position"]) <= 2.0,
		"记录落点应等于怪物锚点")
	_expect(control_raise >= 40.0 and control_raise <= 60.0,
		"控制点应比两点中点抬高 40–60px，实际 %.1fpx" % control_raise)
	_expect(first_half > second_half,
		"飞行应前快后慢（前半 %.1fpx > 后半 %.1fpx）" % [first_half, second_half])
	_expect(ring_min >= 9.0 and ring_min <= 12.0,
		"落点当帧扩环直径应在 10px 附近，实际 %.2fpx" % ring_min)
	_expect(ring_max >= 45.9 and ring_max <= 46.1,
		"扩环应达到 46px，实际 %.2fpx" % ring_max)
	_expect(ring_reach >= 0.0 and ring_reach <= 0.25,
		"扩环 10→46px 应在落点后 0.25s 内完成，实际 %.3fs" % ring_reach)
	_expect(landing >= 0.37 and landing <= 0.47, "落点时间应落在总时长区间内")
	_expect(flash_peak >= landing,
		"白闪峰值不得早于落点帧（峰值 %.3fs / 落点 %.3fs）" % [flash_peak, landing])
	_expect(flash_peak - landing >= 0.05 and flash_peak - landing <= 0.08,
		"白闪应在落点后约 0.06s 达峰，实际 %.3fs" % (flash_peak - landing))
	_expect(particles_at_landing >= 3 and particles_at_landing <= 5,
		"均衡档命中粒子应为 3–5 枚，实际 %d" % particles_at_landing)
	_expect(ring_max <= 46.1 and effect.ring_diameter() <= 46.1, "扩环直径不得超过 46px")

	# 用 60fps 帧采样复核「白闪峰值帧不早于落点帧」。
	var frame_effect = EffectScript.new()
	frame_effect.setup(origin, anchor, Color(0.1, 0.4, 1.0), {"effect_density": 1.0})
	for index in range(50):
		frame_effect.advance(1.0 / 60.0)
		var snapshot: Dictionary = frame_effect.get_snapshot()
		if frame_landing < 0 and float(snapshot["landing_time"]) >= 0.0:
			frame_landing = index + 1
		if float(snapshot["flash_alpha"]) > frame_peak_alpha + 0.0001:
			frame_peak_alpha = float(snapshot["flash_alpha"])
			frame_peak = index + 1
	_expect(frame_landing > 0 and frame_peak > 0, "60fps 采样应记录到落点帧与白闪峰值帧")
	_expect(frame_peak >= frame_landing,
		"白闪峰值帧不得早于落点帧（峰值帧 %d / 落点帧 %d）" % [frame_peak, frame_landing])
	frame_effect.free()

	print("[ElementFlight] cast=%.3fs flight=%.3fs total=%.3fs flight_ratio=%.1f%%" % [
		cast_end, flight_observed, total_observed, flight_ratio * 100.0
	])
	print("[ElementFlight] stages cast=0.000-%.3fs flight=%.3f-%.3fs hit=%.3f-%.3fs" % [
		cast_end, cast_end, landing, landing, landing + float(EffectScript.CONFIG["hit_duration"])
	])
	print("[ElementFlight] cast_scale=1.000->%.3f glow_at_0.09s=%.3f trail_samples=%d" % [
		cast_scale_end, glow_mid, max_trail
	])
	print("[ElementFlight] origin=(%.1f,%.1f) anchor=(%.1f,%.1f) spawn_error=%.3fpx landing_error=%.3fpx" % [
		origin.x, origin.y, anchor.x, anchor.y,
		float(final_snapshot["spawn_error"]), float(final_snapshot["landing_error"])
	])
	print("[ElementFlight] control_raise=%.1fpx first_half=%.1fpx second_half=%.1fpx" % [
		control_raise, first_half, second_half
	])
	print("[ElementFlight] ring=%.1f->%.1fpx in %.3fs flash_peak=%.3fs landing=%.3fs peak_frame=%d landing_frame=%d" % [
		ring_min, ring_max, ring_reach, flash_peak, landing, frame_peak, frame_landing
	])
	print("[ElementFlight] particles_at_landing=%d" % particles_at_landing)
	effect.free()
	return {
		"cast": cast_end,
		"flight": flight_observed,
		"total": total_observed,
		"flight_ratio": flight_ratio,
		"ring_min": ring_min,
		"ring_max": ring_max,
		"flash_peak": flash_peak,
		"landing": landing,
		"particles": particles_at_landing
	}


func _test_tier_scaling() -> void:
	var counts: Dictionary = {}
	for mode: String in ["lite", "balanced", "rich"]:
		var profile: Dictionary = PresentationProfileScript.from_settings({
			"qualityLevel": "high",
			"performanceMode": mode
		})
		var effect = EffectScript.new()
		effect.setup(Vector2(192.5, 475.5), Vector2(187.5, 66.0), Color.WHITE, profile)
		counts[mode] = effect.particle_count
		_expect(effect.particle_count >= 1 and effect.particle_count <= 5,
			"%s 档单次效果粒子应在 1–5 枚，实际 %d" % [mode, effect.particle_count])
		effect.free()
	_expect(counts["lite"] <= counts["rich"] / 2,
		"轻量档粒子数不得超过华丽档一半（%d / %d）" % [counts["lite"], counts["rich"]])
	_expect(counts["balanced"] >= counts["lite"] and counts["rich"] >= counts["balanced"],
		"三档粒子数应单调递增")

	# 同一屏 6 个同时存在的效果，模拟一次三消 6 格，量测同屏峰值。
	var screen_peaks: Dictionary = {}
	for mode: String in ["lite", "balanced", "rich"]:
		var profile: Dictionary = PresentationProfileScript.from_settings({
			"qualityLevel": "high",
			"performanceMode": mode
		})
		var effects: Array = []
		for i in range(6):
			var effect = EffectScript.new()
			effect.setup(
				Vector2(192.5 + i * 3.0, 475.5),
				Vector2(187.5, 66.0),
				Color.WHITE,
				profile
			)
			effects.append(effect)
		for step_index in range(500):
			for effect in effects:
				effect.advance(0.001)
		var peak := 0
		for effect in effects:
			peak += effect.alive_particle_count()
			effect.free()
		screen_peaks[mode] = peak
	_expect(screen_peaks["lite"] <= screen_peaks["rich"] / 2,
		"轻量档同屏粒子峰值不得超过华丽档一半（%d / %d）" % [screen_peaks["lite"], screen_peaks["rich"]])
	print("[ElementFlight] particle_tier counts=%s screen_peak_6_effects=%s" % [
		JSON.stringify(counts), JSON.stringify(screen_peaks)
	])


func _test_battle_logs_match_baseline() -> void:
	var file := FileAccess.open(BASELINE_PATH, FileAccess.READ)
	if file == null:
		_failures.append("缺少 a322404 基线战斗日志：%s" % BASELINE_PATH)
		return
	var expected_text := file.get_as_text()
	file.close()
	EffectScript.enabled = true
	var enabled_payload := _run_deterministic_battle()
	var enabled_text := JSON.stringify(enabled_payload, "\t")
	EffectScript.enabled = false
	var disabled_payload := _run_deterministic_battle()
	var disabled_text := JSON.stringify(disabled_payload, "\t")
	_expect(enabled_text == expected_text, "特效开启时固定战局日志与结算 JSON 应与 a322404 逐字节一致")
	_expect(disabled_text == expected_text, "特效关闭时固定战局日志与结算 JSON 应与 a322404 逐字节一致")
	_expect(enabled_text == disabled_text, "总开关开 / 关不应改动战斗日志与结算 JSON")
	EffectScript.enabled = true
	print("[ElementFlight] baseline identical=true bytes=%d on_off_identical=%s" % [
		expected_text.length(), str(enabled_text == disabled_text)
	])


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
		"source_commit": "a322404",
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


func _test_scene_spawn_coordinates() -> void:
	EffectScript.enabled = true
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
	var battle: Control = main.get_current_scene()
	if battle == null:
		_failures.append("战斗场景应能加载")
		main.queue_free()
		await process_frame
		return
	var board = battle.get("_board")
	_seed_swap_demo_board(board)
	await process_frame
	battle.set("_message_timer", 0.0)
	battle.call("_do_swap", 4, 3, 4, 4)
	await process_frame

	var effects: Array = _collect_effects(battle)
	# T3 起均衡档同屏弹体硬上限 3：一次双三消 6 格只生成 3 个节点，其余 3 个计入丢弃。
	var expected_spawned := 3
	_expect(effects.size() == expected_spawned,
		"均衡档一次双三消应生成 %d 个元素（预算 3），实际 %d" % [expected_spawned, effects.size()])
	var budget_stats: Dictionary = battle.call("get_element_flight_budget_stats")
	_expect(int(budget_stats.get("dropped_projectiles", -1)) == GEM_CENTERS.size() - expected_spawned,
		"超出同屏弹体预算的 %d 个应计入丢弃，实际 %d" % [
			GEM_CENTERS.size() - expected_spawned,
			int(budget_stats.get("dropped_projectiles", -1))
		])
	var battle_manager = battle.get("_battle")
	var target_idx: int = battle.call("_weakest_enemy_visual_index")
	var expected_anchor: Vector2 = BattleAnimationControllerScript.enemy_damage_anchor(
		battle_manager.enemies.size(), target_idx
	)
	var cell_size := float(board.cell_size)
	var board_x := float(board.offset_x)
	var board_y := float(board.offset_y)
	var max_spawn_error := 0.0
	var max_landing_error := 0.0
	for effect in effects:
		var best := 1.0e9
		for center_spec: Array in GEM_CENTERS:
			var expected := Vector2(
				board_x + (float(center_spec[1]) + 0.5) * cell_size,
				board_y + (float(center_spec[0]) + 0.5) * cell_size
			)
			best = minf(best, effect.origin.distance_to(expected))
		max_spawn_error = maxf(max_spawn_error, best)
		max_landing_error = maxf(max_landing_error, effect.anchor.distance_to(expected_anchor))
	for effect in effects:
		_expect(effect.anchor.distance_to(expected_anchor) <= 2.0,
			"特效落点应等于怪物锚点，误差 %.3fpx" % effect.anchor.distance_to(expected_anchor))
		_expect(effect.control.y <= ((effect.origin + effect.anchor) * 0.5).y - 39.9,
			"控制点应抬高 40–60px")
	_expect(max_spawn_error <= 2.0, "出生点与宝石中心误差应 ≤2px，实际 %.3fpx" % max_spawn_error)
	_expect(max_landing_error <= 2.0, "落点与怪物锚点误差应 ≤2px，实际 %.3fpx" % max_landing_error)
	print("[ElementFlight] scene effects=%d spawn_error_max=%.3fpx landing_error_max=%.3fpx anchor=(%.1f,%.1f)" % [
		effects.size(), max_spawn_error, max_landing_error, expected_anchor.x, expected_anchor.y
	])

	for effect in effects:
		effect.queue_free()
	await process_frame
	EffectScript.enabled = false
	battle.call("_spawn_element_flights", [{"row": 0, "col": 0, "type": "water"}])
	await process_frame
	_expect(_collect_effects(battle).is_empty(), "总开关关闭时战斗场景不应生成特效节点")
	EffectScript.enabled = true
	main.queue_free()
	await process_frame
	await process_frame


func _collect_effects(battle: Control) -> Array:
	var effects: Array = []
	for child in battle.get_children():
		if child.get_script() == EffectScript:
			effects.append(child)
	return effects


func _seed_swap_demo_board(board) -> void:
	if board == null:
		return
	for r in range(board.rows):
		for c in range(board.cols):
			board.grid[r][c] = GEM_TYPES[(r + c * 2) % GEM_TYPES.size()]
			board.obstacles[r][c] = null
			board.locked_gems[r][c] = null
			board.poison_fog[r][c] = null
	board.grid[4][3] = "water"
	board.grid[4][4] = "fire"
	board.grid[4][5] = "water"
	board.grid[4][6] = "water"
	board.grid[5][3] = "fire"
	board.grid[6][3] = "fire"
	board.cascade_count = 0


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ElementFlight] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[ElementFlight] " + failure)
	quit(1)

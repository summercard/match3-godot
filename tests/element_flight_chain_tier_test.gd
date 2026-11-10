extends SceneTree

## T3 连锁升级 / 画质档 / 同屏预算验收：
## 1. 连锁：1 / 2 / 4 连锁实测首圈峰值半径与亮度；2 连锁 = 1 连锁 ×1.20±0.02，
##    亮度差 ≥10%；4 连锁首圈同 2 连锁，第二圈起点 = 首圈起点 +0.06s±1 帧，
##    峰值半径 = 首圈 60%±5%，且元素飞行本身不产生任何震屏记录；
## 2. 画质档：轻量首圈 = 均衡 ×0.80±0.02 且无第二圈；华丽与均衡同首圈；
## 3. 同屏预算：弹体 2/3/3、环 1/2/3、单次命中粒子 ≤4/8/12，超出丢弃并计数；
## 4. 战斗接线：cascade_count 传入连锁等级；总开关关闭时不创建节点、不占用预算。

const EffectScript = preload("res://src/ui/components/element_flight_effect.gd")
const PresentationProfileScript = preload("res://src/ui/components/presentation_profile.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const ORIGIN := Vector2(192.5, 475.5)
const ANCHOR := Vector2(187.5, 66.0)

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EffectScript.reset_budgets()
	var chain := _test_chain_ring()
	_test_tier_ring(chain)
	_test_budgets()
	await _test_scene_wiring()
	EffectScript.enabled = true
	EffectScript.reset_budgets()
	_finish()


## 以 240Hz 推进完整生命周期，记录首圈 / 第二圈的峰值半径与亮度。
func _measure(chain_level: int, performance: String) -> Dictionary:
	var profile: Dictionary = PresentationProfileScript.from_settings({
		"qualityLevel": "high",
		"performanceMode": performance,
	})
	profile["chain_level"] = chain_level
	var effect = EffectScript.new()
	effect.setup(ORIGIN, ANCHOR, Color(0.1, 0.4, 1.0), profile)
	var dt := 1.0 / 240.0
	var elapsed := 0.0
	var first_start := -1.0
	var second_start := -1.0
	var first_peak := 0.0
	var first_luminance := 0.0
	var second_peak := 0.0
	var second_luminance := 0.0
	while elapsed < 0.75 and not effect.is_finished():
		effect.advance(dt)
		elapsed += dt
		var snapshot: Dictionary = effect.get_snapshot()
		first_peak = maxf(first_peak, float(snapshot["ring_radius"]))
		first_luminance = maxf(first_luminance, float(snapshot["ring_luminance"]))
		second_peak = maxf(second_peak, float(snapshot["second_ring_radius"]))
		second_luminance = maxf(second_luminance, float(snapshot["second_ring_luminance"]))
		if first_start < 0.0 and float(snapshot["ring_start_time"]) >= 0.0:
			first_start = float(snapshot["ring_start_time"])
		if second_start < 0.0 and float(snapshot["second_ring_start_time"]) >= 0.0:
			second_start = float(snapshot["second_ring_start_time"])
	var result := {
		"chain": chain_level,
		"tier": performance,
		"first_peak": first_peak,
		"first_luminance": first_luminance,
		"first_start": first_start,
		"second_start": second_start,
		"second_peak": second_peak,
		"second_luminance": second_luminance,
		"landing": float(effect.get_snapshot()["landing_time"]),
	}
	effect.free()
	print("[ElementFlightT3] chain=%d tier=%s first_peak=%.3fpx first_lum=%.3f first_start=%.3fs second_start=%.3fs second_peak=%.3fpx second_lum=%.3f" % [
		chain_level,
		performance,
		first_peak,
		first_luminance,
		first_start,
		second_start,
		second_peak,
		second_luminance,
	])
	return result


func _test_chain_ring() -> Dictionary:
	var chain1 := _measure(1, "balanced")
	var chain2 := _measure(2, "balanced")
	var chain4 := _measure(4, "balanced")
	var frame := 1.0 / 60.0

	var radius_ratio := float(chain2["first_peak"]) / maxf(float(chain1["first_peak"]), 0.001)
	_expect(absf(radius_ratio - 1.2) <= 0.02,
		"2 连锁首圈半径应为 1 连锁的 1.20±0.02，实测 %.3fx" % radius_ratio)
	var luminance_ratio := float(chain2["first_luminance"]) / maxf(float(chain1["first_luminance"]), 0.001)
	_expect(luminance_ratio - 1.0 >= 0.10,
		"2 连锁环亮度应比 1 连锁高 ≥10%%，实测 %.1f%%" % ((luminance_ratio - 1.0) * 100.0))
	_expect(absf(float(chain4["first_peak"]) - float(chain2["first_peak"])) <= 0.02,
		"4 连锁首圈峰值应与 2 连锁一致（连锁 ≥2 起 ×1.2）")
	_expect(float(chain1["second_start"]) < 0.0 and float(chain2["second_start"]) < 0.0,
		"1 / 2 连锁不应出现第二圈")
	var delay := float(chain4["second_start"]) - float(chain4["first_start"])
	_expect(absf(delay - 0.06) <= frame,
		"4 连锁第二圈起点应为首圈起点 +0.06s±1 帧，实测 +%.3fs" % delay)
	var second_ratio := float(chain4["second_peak"]) / maxf(float(chain4["first_peak"]), 0.001)
	_expect(absf(second_ratio - 0.6) <= 0.05,
		"4 连锁第二圈峰值半径应为首圈 60%%±5%%，实测 %.1f%%" % (second_ratio * 100.0))
	_expect(float(chain4["second_luminance"]) > 0.0, "4 连锁第二圈应有可见亮度")

	print("[ElementFlightT3] chain_radius_ratio=%.4fx luminance_ratio=%.4fx second_delay=%.3fs second_peak_ratio=%.4f" % [
		radius_ratio, luminance_ratio, delay, second_ratio
	])
	return chain4


func _test_tier_ring(chain4: Dictionary) -> void:
	var balanced := chain4
	var lite := _measure(4, "lite")
	var rich := _measure(4, "rich")
	var lite_ratio := float(lite["first_peak"]) / maxf(float(balanced["first_peak"]), 0.001)
	_expect(absf(lite_ratio - 0.80) <= 0.02,
		"轻量档首圈半径应为均衡 ×0.80±0.02，实测 %.3fx" % lite_ratio)
	_expect(float(lite["second_start"]) < 0.0 and float(lite["second_peak"]) <= 0.0,
		"轻量档 4 连锁不应出现第二圈")
	_expect(absf(float(rich["first_peak"]) - float(balanced["first_peak"])) <= 0.02,
		"华丽档首圈档位倍率应为 1.0（与均衡同径）")
	_expect(float(rich["second_peak"]) > 0.0, "华丽档 4 连锁应保留第二圈")
	print("[ElementFlightT3] tier_ring lite/balanced=%.4f balanced=%.3fpx rich=%.3fpx lite_second=%.3fpx" % [
		lite_ratio, float(balanced["first_peak"]), float(rich["first_peak"]), float(lite["second_peak"])
	])


func _test_budgets() -> void:
	var cases := {
		"lite": {"projectiles": 2, "rings": 1, "particles": 4},
		"balanced": {"projectiles": 3, "rings": 2, "particles": 8},
		"rich": {"projectiles": 3, "rings": 3, "particles": 12},
	}
	for tier: String in ["lite", "balanced", "rich"]:
		var expected: Dictionary = cases[tier]
		var batch := _spawn_batch(tier, 6, 1)
		var effects: Array = batch["effects"]
		var stats: Dictionary = batch["stats"]
		# 本波消除 6 格：三档都必须 6 个全飞、0 丢弃，弹体上限不得低于格数。
		_expect(effects.size() == 6,
			"%s 档双三消 6 格应生成 6 个弹体，实际 %d" % [tier, effects.size()])
		_expect(int(stats["dropped_projectiles"]) == 0,
			"%s 档双三消 6 格不应丢弃弹体，实际 %d" % [tier, int(stats["dropped_projectiles"])])
		_expect(int(stats["projectile_cap"]) >= 6,
			"%s 档双三消弹体上限应 ≥6，实际 %d" % [tier, int(stats["projectile_cap"])])
		_expect(int(stats["wave_cells"]) == 6,
			"%s 档应记录本波 6 个消除格，实际 %d" % [tier, int(stats["wave_cells"])])
		for effect in effects:
			_expect(effect.particle_count <= int(expected["particles"]),
				"%s 档单次命中粒子应 ≤%d，实际 %d" % [tier, int(expected["particles"]), effect.particle_count])
		var ring_peak := 0
		var projectile_peak := 0
		for _step in range(450):
			for effect in effects:
				effect.advance(0.001)
			var live: Dictionary = EffectScript.get_budget_stats()
			ring_peak = maxi(ring_peak, int(live["active_rings"]))
			projectile_peak = maxi(projectile_peak, int(live["active_projectiles"]))
		var landed: Dictionary = EffectScript.get_budget_stats()
		_expect(projectile_peak == 6,
			"%s 档双三消同屏弹体峰值应为 6，实际 %d" % [tier, projectile_peak])
		_expect(ring_peak <= int(expected["rings"]),
			"%s 档同屏环峰值应 ≤%d，实际 %d" % [tier, int(expected["rings"]), ring_peak])
		_expect(int(landed["active_rings"]) == int(expected["rings"]),
			"%s 档落点后应占用 %d 个环预算，实际 %d" % [
				tier, int(expected["rings"]), int(landed["active_rings"])
			])
		_expect(int(landed["dropped_rings"]) == 6 - int(expected["rings"]),
			"%s 档应丢弃 %d 个环，实际 %d" % [
				tier, 6 - int(expected["rings"]), int(landed["dropped_rings"])
			])
		print("[ElementFlightT3] budget tier=%s spawned=%d dropped=%d cap=%d wave_cells=%d rings=%d ring_drops=%d particles<=%d" % [
			tier,
			effects.size(),
			int(stats["dropped_projectiles"]),
			int(stats["projectile_cap"]),
			int(stats["wave_cells"]),
			int(landed["active_rings"]),
			int(landed["dropped_rings"]),
			int(expected["particles"]),
		])
		_release_batch(batch)

	# 4 连锁 + 华丽档：首圈占满 3 个环预算后，3 个第二圈都应丢弃且不超预算。
	var chain4 := _spawn_batch("rich", 3, 4)
	var chain4_effects: Array = chain4["effects"]
	_expect(int(chain4["stats"]["projectile_cap"]) == 3,
		"4 连锁华丽档 3 格弹体上限应为 3，实际 %d" % int(chain4["stats"]["projectile_cap"]))
	for _step in range(520):
		for effect in chain4_effects:
			effect.advance(0.001)
	var chain4_stats: Dictionary = EffectScript.get_budget_stats()
	_expect(int(chain4_stats["active_rings"]) <= 3,
		"4 连锁华丽档同屏环不得超过 3，实际 %d" % int(chain4_stats["active_rings"]))
	_expect(int(chain4_stats["dropped_rings"]) >= 3,
		"预算占满后第二圈应丢弃并计数，实际丢弃 %d" % int(chain4_stats["dropped_rings"]))
	print("[ElementFlightT3] budget chain4 rings=%d ring_drops=%d" % [
		int(chain4_stats["active_rings"]), int(chain4_stats["dropped_rings"])
	])
	_release_batch(chain4)
	EffectScript.reset_budgets()


func _spawn_batch(tier: String, count: int, chain_level: int) -> Dictionary:
	EffectScript.reset_budgets()
	var holder := Node2D.new()
	root.add_child(holder)
	var profile: Dictionary = PresentationProfileScript.from_settings({
		"qualityLevel": "high",
		"performanceMode": tier,
	})
	profile["chain_level"] = chain_level
	profile["wave_cells"] = count
	var effects: Array = []
	for i in range(count):
		var effect = EffectScript.spawn(
			holder,
			Vector2(120.0 + float(i) * 8.0, 470.0),
			ANCHOR,
			Color(0.1, 0.4, 1.0),
			profile
		)
		if effect != null:
			effects.append(effect)
	return {
		"holder": holder,
		"effects": effects,
		"stats": EffectScript.get_budget_stats(),
	}


func _release_batch(batch: Dictionary) -> void:
	var holder: Node = batch["holder"]
	if is_instance_valid(holder):
		holder.free()
	EffectScript.reset_budgets()


func _test_scene_wiring() -> void:
	EffectScript.enabled = true
	EffectScript.reset_budgets()
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
	if board == null:
		_failures.append("战斗棋盘应能加载")
		main.queue_free()
		await process_frame
		return

	EffectScript.reset_budgets()
	board.cascade_count = 1
	battle.call("_spawn_element_flights", [{"row": 4, "col": 4, "type": "fire"}])
	await process_frame
	var effects: Array = _collect_effects(battle)
	_expect(effects.size() == 1, "接线后单格应生成 1 个元素，实际 %d" % effects.size())
	if not effects.is_empty():
		_expect(effects[0].chain_level == 1, "1 连锁应传入 chain_level=1，实际 %d" % effects[0].chain_level)
	for effect in effects:
		_free_effect(effect)
	await process_frame

	EffectScript.reset_budgets()
	board.cascade_count = 4
	battle.call("_spawn_element_flights", [{"row": 4, "col": 4, "type": "fire"}])
	await process_frame
	effects = _collect_effects(battle)
	_expect(effects.size() == 1, "4 连锁单格应生成 1 个元素，实际 %d" % effects.size())
	if not effects.is_empty():
		_expect(effects[0].chain_level == 4, "4 连锁应传入 chain_level=4，实际 %d" % effects[0].chain_level)

	# 元素飞行本身不许新增震屏：清空震屏记录后推进到第二圈出现，仍应保持 0。
	battle.set("_match_shake_timer", 0.0)
	battle.set("_match_shake_duration", 0.0)
	battle.set("_match_shake_amplitude", 0.0)
	battle.set("_match_shake_offset", Vector2.ZERO)
	battle.set("_board_shake_timer", 0.0)
	for _frame in range(45):
		await process_frame
	_expect(float(battle.get("_match_shake_timer")) == 0.0,
		"元素飞行（含第二圈）不应新增命中震屏，实际 timer=%.3f" % float(battle.get("_match_shake_timer")))
	_expect(float(battle.get("_match_shake_amplitude")) == 0.0,
		"元素飞行（含第二圈）不应写入震屏振幅，实际 %.3f" % float(battle.get("_match_shake_amplitude")))
	_expect(float(battle.get("_board_shake_timer")) == 0.0, "元素飞行不应触发棋盘震屏")
	for effect in effects:
		_free_effect(effect)
	await process_frame

	# 场景接线：均衡档 6 格只生成 3 个，丢弃 3 个。
	EffectScript.reset_budgets()
	board.cascade_count = 1
	var matches: Array = []
	for i in range(6):
		matches.append({"row": 4, "col": 3 + (i % 3), "type": "fire"})
	battle.call("_spawn_element_flights", matches)
	await process_frame
	effects = _collect_effects(battle)
	var stats: Dictionary = battle.call("get_element_flight_budget_stats")
	_expect(effects.size() == 6, "均衡档双三消应生成 6 个弹体，实际 %d" % effects.size())
	_expect(int(stats.get("dropped_projectiles", -1)) == 0,
		"双三消 6 格不应丢弃弹体，实际 %d" % int(stats.get("dropped_projectiles", -1)))
	_expect(int(stats.get("projectile_cap", -1)) >= 6,
		"场景接线弹体上限应 ≥6，实际 %d" % int(stats.get("projectile_cap", -1)))
	for effect in effects:
		_free_effect(effect)
	await process_frame

	# 总开关关闭：不创建节点、不占预算、不累计丢弃。
	EffectScript.reset_budgets()
	EffectScript.enabled = false
	battle.call("_spawn_element_flights", [{"row": 4, "col": 4, "type": "fire"}])
	await process_frame
	_expect(_collect_effects(battle).is_empty(), "总开关关闭时不应生成元素节点")
	var off_stats: Dictionary = battle.call("get_element_flight_budget_stats")
	_expect(int(off_stats.get("active_projectiles", -1)) == 0
		and int(off_stats.get("dropped_projectiles", -1)) == 0,
		"总开关关闭时不应占用 / 丢弃预算")
	EffectScript.enabled = true

	print("[ElementFlightT3] scene wiring chain_level=1/4, budget drops observable, shake_records_from_effect=0")
	main.queue_free()
	await process_frame
	await process_frame


func _free_effect(effect) -> void:
	if effect != null and is_instance_valid(effect):
		effect.queue_free()


func _collect_effects(battle: Control) -> Array:
	var effects: Array = []
	for child in battle.get_children():
		if child.get_script() == EffectScript:
			effects.append(child)
	return effects


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ElementFlightT3] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[ElementFlightT3] " + failure)
	quit(1)

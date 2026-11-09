extends SceneTree

## 画质等级 / 战斗表现档位回归：
## 1. 中央映射：均衡档保持接通前的基准（粒子 1.0 / 震屏 1.0 / 飘字 3 层），
##    轻量档粒子与震屏减半，华丽档更高；画质档位提供可测的特效密度差；
## 2. 同一固定种子、同一关卡的轻量 / 均衡 / 华丽三档战斗，伤害日志、承伤日志
##    与结算 JSON 逐位一致；
## 3. 记录三档实测粒子峰值与最大震屏位移，轻量档两项都不超过华丽档的一半；
## 4. 运行中切换档位下一帧生效，且不新增常驻节点；
## 5. 离开战斗回大厅不把表现档位带过去（大厅固定 18 粒背景粒子不变）；
## 6. 画质档位在真实战斗中只改粒子密度，不改战斗日志与结算。
##
## 用法：
##   MATCH3_SAVE_PATH=/tmp/match3_presentation.cfg \
##     Godot --headless --path . --script res://tests/battle_presentation_test.gd

const StageDBScript = preload("res://src/data/stage_db.gd")
const PresentationProfileScript = preload("res://src/ui/components/presentation_profile.gd")

const SEED := 20261110
const TEST_ENEMY_HP := 420
const MAX_BATTLE_MS := 120000
const QUALITY_CHECK_MAX_RATIO := 0.65

var _failures: Array[String] = []
var _save_manager: Node = null
var _original_settings: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_save_manager = root.get_node_or_null("SaveManager")
	if _save_manager == null:
		_failures.append("应挂载 SaveManager Autoload")
		_finish()
		return
	_original_settings = _save_manager.load_settings().duplicate(true)

	_test_central_mapping()
	await _test_next_frame_and_lobby()

	var runs: Dictionary = {}
	for mode: String in ["lite", "balanced", "rich"]:
		_set_presentation("high", mode)
		runs[mode] = await _run_scene_battle("high", mode)
	_test_tier_identity(runs)
	_test_tier_measurements(runs)

	# 画质等级：固定华丽战斗表现，流畅档的粒子密度应明显低于精细档。
	_set_presentation("low", "rich")
	var low_quality := await _run_scene_battle("low", "rich")
	_test_quality_density(runs.get("rich", {}), low_quality)

	_restore_settings()
	_finish()


## ============================================
## 1. 中央映射
## ============================================

func _test_central_mapping() -> void:
	var defaults := PresentationProfileScript.from_settings({})
	_expect(str(defaults.get("quality", "")) == PresentationProfileScript.DEFAULT_QUALITY,
		"缺少 qualityLevel 时应回落到默认画质档")
	_expect(str(defaults.get("performance", "")) == PresentationProfileScript.DEFAULT_PERFORMANCE,
		"缺少 performanceMode 时应回落到默认战斗表现档")

	var lite := PresentationProfileScript.from_settings({"qualityLevel": "high", "performanceMode": "lite"})
	var balanced := PresentationProfileScript.from_settings({"qualityLevel": "high", "performanceMode": "balanced"})
	var rich := PresentationProfileScript.from_settings({"qualityLevel": "high", "performanceMode": "rich"})
	_expect(float(lite["effect_density"]) < float(balanced["effect_density"]),
		"轻量档粒子密度应低于均衡档")
	_expect(float(balanced["effect_density"]) < float(rich["effect_density"]),
		"华丽档粒子密度应高于均衡档")
	_expect(is_equal_approx(float(balanced["effect_density"]), 1.0),
		"均衡档应保持接通前的基准粒子密度 1.0")
	_expect(float(lite["shake_scale"]) <= 0.5 and float(rich["shake_scale"]) > 1.0,
		"轻量档震屏应减半，华丽档应高于基准")
	_expect(int(lite["popup_layers"]) == 1 and int(balanced["popup_layers"]) == 3,
		"轻量档飘字应只保留 1 层，均衡档应保留基准 3 层")

	var low_quality := PresentationProfileScript.from_settings({"qualityLevel": "low", "performanceMode": "balanced"})
	var high_quality := PresentationProfileScript.from_settings({"qualityLevel": "high", "performanceMode": "balanced"})
	_expect(float(low_quality["effect_density"]) < float(high_quality["effect_density"]),
		"流畅画质的特效密度应低于精细画质")
	_expect(is_equal_approx(float(high_quality["quality_effect_density"]), 1.0),
		"精细画质应保持基准特效密度 1.0")
	_expect(PresentationProfileScript.scaled_particle_count(12, rich) == 18,
		"华丽档 12 粒基准应缩放为 18 粒，实际 %d" % PresentationProfileScript.scaled_particle_count(12, rich))
	_expect(PresentationProfileScript.scaled_particle_count(12, lite) == 6,
		"轻量档 12 粒基准应缩放为 6 粒，实际 %d" % PresentationProfileScript.scaled_particle_count(12, lite))
	print("[Presentation] mapping lite=%s balanced=%s rich=%s quality_low=%.2f quality_high=%.2f" % [
		str(lite["performance"]), str(balanced["performance"]), str(rich["performance"]),
		float(low_quality["effect_density"]), float(high_quality["effect_density"]),
	])


## ============================================
## 2. 切档下一帧生效 / 不新增节点 / 大厅不继承
## ============================================

func _test_next_frame_and_lobby() -> void:
	_set_presentation("high", "balanced")
	var main := await _load_main()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		_failures.append("切档测试应能加载战斗场景")
		await _free_main(main)
		return
	_expect(str(battle.call("get_presentation_profile").get("performance", "")) == "balanced",
		"战斗初始应读取均衡战斗表现档")
	var nodes_before := _node_count(battle)
	var particles_before := int(battle.call("_scaled_particles", 8))

	_set_presentation("high", "lite")
	await process_frame
	var profile: Dictionary = battle.call("get_presentation_profile")
	var nodes_after := _node_count(battle)
	var particles_after := int(battle.call("_scaled_particles", 8))
	_expect(str(profile.get("performance", "")) == "lite", "运行中切到轻量档应在下一帧生效")
	_expect(float(profile.get("shake_scale", 1.0)) <= 0.5, "下一帧生效后震屏倍率也应减半")
	_expect(particles_after < particles_before,
		"轻量档同一基准的粒子数应更少（%d -> %d）" % [particles_before, particles_after])
	_expect(nodes_after == nodes_before,
		"切换最低档不应新增常驻节点（%d -> %d）" % [nodes_before, nodes_after])
	print("[Presentation] next_frame balanced_to_lite particles=%d->%d nodes=%d->%d" % [
		particles_before, particles_after, nodes_before, nodes_after,
	])

	# 离开战斗回大厅：战斗场景释放，大厅固定 18 粒背景粒子不随档位变化。
	main.switch_scene("main")
	await process_frame
	await process_frame
	_expect(str(main.get_current_scene_name()) == "main", "离开战斗后应回到大厅")
	_expect(not is_instance_valid(battle), "离开战斗后战斗场景应释放")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "离开战斗后时间尺度应恢复 1.0")
	var lobby: Control = main.get_current_scene()
	var lobby_particles := lobby.get_node_or_null("Particles") if lobby != null else null
	var lobby_count: int = (lobby_particles.get("_particles") as Array).size() if lobby_particles != null else -1
	_expect(lobby_count == 18, "大厅背景粒子应保持固定 18 粒，实际 %d" % lobby_count)
	print("[Presentation] lobby_after_lite current=%s battle_freed=%s lobby_particles=%d" % [
		str(main.get_current_scene_name()), str(not is_instance_valid(battle)), lobby_count,
	])
	await _free_main(main)


## ============================================
## 3. 同种子三档整场战斗
## ============================================

func _run_scene_battle(quality: String, performance_mode: String) -> Dictionary:
	_set_presentation(quality, performance_mode)
	var main := await _load_main()
	seed(SEED)
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1"),
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		_failures.append("整场战斗场景应能加载（%s/%s）" % [quality, performance_mode])
		await _free_main(main)
		return {}
	var board = battle.get("_board")
	var battle_manager = battle.get("_battle")
	if board == null or battle_manager == null:
		_failures.append("整场战斗应创建棋盘与战斗管理器（%s/%s）" % [quality, performance_mode])
		await _free_main(main)
		return {}
	# 固定测试战局长度：不修改数据表，只把本场敌人血量设为测试口径。
	battle_manager.enemies[0]["maxHP"] = TEST_ENEMY_HP
	battle_manager.enemies[0]["hp"] = TEST_ENEMY_HP

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle_manager.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	battle_manager.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))

	var peak_particles := 0
	var max_shake_px := 0.0
	var actions := 0
	var start_ms := Time.get_ticks_msec()
	while int(battle.get("_state")) != 6 and Time.get_ticks_msec() - start_ms < MAX_BATTLE_MS:
		await process_frame
		peak_particles = maxi(peak_particles, _particle_total(battle))
		max_shake_px = maxf(max_shake_px, _shake_length(battle))
		if int(battle.get("_state")) != 0:
			continue
		var move := _find_valid_move(board)
		if move.is_empty():
			break
		battle.call("_do_swap", move["r1"], move["c1"], move["r2"], move["c2"])
		actions += 1
	# 战斗结束后的胜利粒子也要计入峰值。
	for _i in range(45):
		await process_frame
		peak_particles = maxi(peak_particles, _particle_total(battle))
		max_shake_px = maxf(max_shake_px, _shake_length(battle))

	var result: Dictionary = battle_manager.get_battle_result()
	var payload := {
		"seed": SEED,
		"turns": int(battle_manager.turn_count),
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"result": result,
	}
	var json := JSON.stringify(payload, "\t")
	var data := {
		"quality": quality,
		"performance": performance_mode,
		"actions": actions,
		"turns": int(battle_manager.turn_count),
		"damage_logs": damage_logs.size(),
		"taken_logs": taken_logs.size(),
		"result": str(result.get("result", "")),
		"json": json,
		"peak_particles": peak_particles,
		"max_shake_px": max_shake_px,
		"profile": battle.call("get_presentation_profile"),
	}
	print("[Presentation] run quality=%s performance=%s actions=%d turns=%d logs=%d/%d result=%s peak_particles=%d max_shake=%.2fpx" % [
		quality, performance_mode, actions, int(battle_manager.turn_count), damage_logs.size(), taken_logs.size(),
		str(result.get("result", "")), peak_particles, max_shake_px,
	])
	await _free_main(main)
	return data


func _test_tier_identity(runs: Dictionary) -> void:
	if runs.size() < 3:
		_failures.append("三档整场战斗都应完整跑完")
		return
	var lite: Dictionary = runs["lite"]
	var balanced: Dictionary = runs["balanced"]
	var rich: Dictionary = runs["rich"]
	for key: String in ["lite", "balanced", "rich"]:
		var run: Dictionary = runs[key]
		_expect(int(run.get("damage_logs", 0)) > 0, "%s 档应产生伤害日志" % key)
		_expect(int(run.get("taken_logs", 0)) > 0, "%s 档应产生承伤日志" % key)
	_expect(str(lite["json"]) == str(rich["json"]), "轻量档与华丽档的战斗日志、承伤日志与结算 JSON 应逐位一致")
	_expect(str(balanced["json"]) == str(rich["json"]), "均衡档与华丽档的战斗日志、承伤日志与结算 JSON 应逐位一致")
	print("[Presentation] fixed_seed=%d identical lite=rich:%s balanced=rich:%s" % [
		SEED, str(str(lite["json"]) == str(rich["json"])), str(str(balanced["json"]) == str(rich["json"])),
	])


func _test_tier_measurements(runs: Dictionary) -> void:
	if runs.size() < 3:
		return
	var lite: Dictionary = runs["lite"]
	var rich: Dictionary = runs["rich"]
	var lite_particles := int(lite.get("peak_particles", 0))
	var rich_particles := int(rich.get("peak_particles", 0))
	var lite_shake := float(lite.get("max_shake_px", 0.0))
	var rich_shake := float(rich.get("max_shake_px", 0.0))
	_expect(rich_particles > 0, "华丽档应测到粒子峰值")
	_expect(rich_shake > 0.0, "华丽档应测到震屏位移")
	_expect(float(lite_particles) <= float(rich_particles) * 0.5,
		"轻量档粒子峰值应不超过华丽档的一半，实际 %d vs %d" % [lite_particles, rich_particles])
	_expect(lite_shake <= rich_shake * 0.5 + 0.001,
		"轻量档最大震屏位移应不超过华丽档的一半，实际 %.2f vs %.2f" % [lite_shake, rich_shake])
	print("[Presentation] peak_particles lite=%d balanced=%d rich=%d ratio=%.3f" % [
		lite_particles, int(runs["balanced"].get("peak_particles", 0)), rich_particles,
		float(lite_particles) / float(maxi(rich_particles, 1)),
	])
	print("[Presentation] max_shake_px lite=%.2f balanced=%.2f rich=%.2f ratio=%.3f" % [
		lite_shake, float(runs["balanced"].get("max_shake_px", 0.0)), rich_shake,
		lite_shake / maxf(rich_shake, 0.001),
	])
	print("[Presentation] popup_layers lite=%d balanced=%d rich=%d" % [
		int(lite["profile"].get("popup_layers", 0)),
		int(runs["balanced"]["profile"].get("popup_layers", 0)),
		int(rich["profile"].get("popup_layers", 0)),
	])


## ============================================
## 4. 画质等级：只改特效密度
## ============================================

func _test_quality_density(high_run: Dictionary, low_run: Dictionary) -> void:
	if high_run.is_empty() or low_run.is_empty():
		_failures.append("画质档位对比需要两场完整战斗")
		return
	var high_peak := int(high_run.get("peak_particles", 0))
	var low_peak := int(low_run.get("peak_particles", 0))
	_expect(high_peak > 0 and low_peak > 0, "画质档位对比应测到粒子峰值")
	_expect(float(low_peak) <= float(high_peak) * QUALITY_CHECK_MAX_RATIO,
		"流畅画质粒子峰值应明显低于精细画质（≤%.0f%%），实际 %d vs %d" % [
			QUALITY_CHECK_MAX_RATIO * 100.0, low_peak, high_peak,
		])
	_expect(str(low_run["json"]) == str(high_run["json"]),
		"画质档位只改表现，战斗日志、承伤日志与结算 JSON 应逐位一致")
	print("[Presentation] quality peak_particles low=%d high=%d ratio=%.3f identical=%s" % [
		low_peak, high_peak, float(low_peak) / float(maxi(high_peak, 1)),
		str(str(low_run["json"]) == str(high_run["json"])),
	])


## ============================================
## 工具
## ============================================

func _set_presentation(quality: String, performance_mode: String) -> void:
	if _save_manager == null:
		return
	var settings: Dictionary = _save_manager.load_settings()
	settings["qualityLevel"] = quality
	settings["performanceMode"] = performance_mode
	_save_manager.save_settings(settings)


func _restore_settings() -> void:
	if _save_manager == null or _original_settings.is_empty():
		return
	_save_manager.save_settings(_original_settings)


func _load_main() -> Control:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main


func _free_main(main: Control) -> void:
	if is_instance_valid(main):
		main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0


func _particle_total(battle: Control) -> int:
	var total := 0
	for key: String in ["_gem_particles", "_obstacle_particles", "_defeat_explosions", "_victory_particles"]:
		var particles = battle.get(key)
		if particles is Array:
			total += (particles as Array).size()
	return total


func _shake_length(battle: Control) -> float:
	var attack := absf(float(battle.get("_attack_shake_offset_x")))
	var board_offset: Vector2 = battle.get("_board_shake_offset")
	var match_offset: Vector2 = battle.get("_match_shake_offset")
	return maxf(attack, (board_offset + match_offset).length())


func _node_count(node: Node) -> int:
	var count := 1
	for child: Node in node.get_children():
		count += _node_count(child)
	return count


func _find_valid_move(board) -> Dictionary:
	for r in range(board.rows):
		for c in range(board.cols):
			for delta in [Vector2i(1, 0), Vector2i(0, 1)]:
				var r2: int = r + delta.y
				var c2: int = c + delta.x
				if r2 < 0 or r2 >= board.rows or c2 < 0 or c2 >= board.cols:
					continue
				if not board.swap(r, c, r2, c2):
					continue
				var matched: bool = not board.find_matches().get("gems", []).is_empty()
				board.swap(r, c, r2, c2)
				if matched:
					return {"r1": r, "c1": c, "r2": r2, "c2": c2}
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("[Presentation] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[Presentation] " + failure)
	quit(1)

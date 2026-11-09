extends SceneTree

## 战斗内 x2 倍速回归：
## 1. 底栏 x2 按钮在 1x / 2x 间切换，按钮文字直接显示当前档位；
## 2. 倍速只改 Engine.time_scale，不触碰伤害、承伤、回合数与战斗随机数；
## 3. 固定种子整场战斗在 1x / 2x 下伤害日志、承伤日志、结算 JSON 逐位一致；
## 4. 2x 整场真实耗时接近 1x 的一半（输出两段实测秒数）；
## 5. 运行中切档立即生效，战斗继续且日志/结算与不切档一致；
## 6. 离开战斗恢复 1x，不把时间尺度带到大厅或结算。
##
## 用法：
##   Godot --headless --path . --script res://tests/battle_speed_test.gd

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

const SEED := 20261110
const TEST_ENEMY_HP := 420
const MAX_BATTLE_MS := 120000
const DURATION_RATIO_MIN := 1.55
const DURATION_RATIO_MAX := 2.55

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_ui_toggle()
	var one := await _run_scene_battle(1, -1)
	var two := await _run_scene_battle(2, -1)
	_test_identity_and_durations(one, two)
	var mixed := await _run_scene_battle(1, 1)
	_test_mid_battle_switch(one, mixed)
	Engine.time_scale = 1.0
	_finish()


## ============================================
## 1. 按钮与档位
## ============================================

func _test_ui_toggle() -> void:
	var main := await _load_main()
	seed(SEED)
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		_failures.append("战斗场景应能加载")
		await _free_main(main)
		return

	var label := battle.get_node("TopHud/SpeedLabel") as Label
	var board = battle.get("_board")
	var battle_manager = battle.get("_battle")
	var grid_before: Array = board.grid.duplicate(true)
	var turn_before := int(battle_manager.turn_count)

	_expect(int(battle.call("get_battle_speed")) == 1, "战斗默认档位应为 1x")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "默认时间尺度应为 1.0")
	_expect(label.text == "1x", "默认按钮文字应显示 1x，实际 %s" % label.text)

	var speed_rect: Rect2 = battle.call("_get_speed_button_rect")
	_send_mouse_click(battle, speed_rect.get_center())
	await process_frame
	_expect(int(battle.call("get_battle_speed")) == 2, "点击一次应切到 2x")
	_expect(is_equal_approx(Engine.time_scale, 2.0), "切到 2x 后时间尺度应为 2.0")
	_expect(label.text == "2x", "2x 时按钮文字应显示 2x，实际 %s" % label.text)
	print("[BattleSpeed] default=1x click->2x label=%s time_scale=%.2f" % [label.text, Engine.time_scale])

	_send_mouse_click(battle, speed_rect.get_center())
	await process_frame
	_expect(int(battle.call("get_battle_speed")) == 1, "再次点击应切回 1x")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "切回 1x 后时间尺度应为 1.0")
	_expect(label.text == "1x", "1x 时按钮文字应显示 1x，实际 %s" % label.text)
	print("[BattleSpeed] click->1x label=%s time_scale=%.2f" % [label.text, Engine.time_scale])

	# 切换按钮不能把点击落到棋盘或技能上。
	_expect(board.grid == grid_before, "切换倍速不应改变棋盘")
	_expect(int(battle_manager.turn_count) == turn_before, "切换倍速不应推进回合")
	_expect((battle.get("_selected_gem") as Vector2i) == Vector2i(-1, -1), "切换倍速不应选中宝石")
	print("[BattleSpeed] ui_click board_unchanged=%s turn=%d" % [
		str(board.grid == grid_before), int(battle_manager.turn_count),
	])

	var speed_after_mid := int(battle.call("get_battle_speed"))
	_expect(speed_after_mid == 1, "测试结束时速度应回到 1x")
	await _free_main(main)
	_expect(is_equal_approx(Engine.time_scale, 1.0), "释放战斗场景后应恢复时间尺度 1.0")


## ============================================
## 2. 固定种子整场战斗：1x vs 2x
## ============================================

func _test_identity_and_durations(one: Dictionary, two: Dictionary) -> void:
	if one.is_empty() or two.is_empty():
		_failures.append("固定种子整场战斗应完整跑完")
		return
	var identical: bool = str(one["json"]) == str(two["json"])
	var d1 := float(one["duration_ms"]) / 1000.0
	var d2 := float(two["duration_ms"]) / 1000.0
	var ratio := d1 / d2 if d2 > 0.001 else 0.0
	_expect(identical, "1x/2x 下同一固定种子的战斗日志与结算 JSON 应逐位一致")
	_expect(int(one["damage_logs"]) > 0, "1x 整场战斗应产生伤害日志")
	_expect(int(one["taken_logs"]) > 0, "1x 整场战斗应产生承伤日志")
	_expect(int(one["turns"]) == int(one["actions"]), "每次有效交换只应推进 1 回合（1x）")
	_expect(int(two["turns"]) == int(two["actions"]), "每次有效交换只应推进 1 回合（2x）")
	_expect(ratio >= DURATION_RATIO_MIN and ratio <= DURATION_RATIO_MAX,
		"2x 整场真实耗时应接近 1x 的一半，实际 1x=%.2fs 2x=%.2fs ratio=%.2f" % [d1, d2, ratio])
	print("[BattleSpeed] fixed_seed=%d identical=%s" % [SEED, str(identical)])
	print("[BattleSpeed] durations 1x=%.2fs 2x=%.2fs ratio=%.2f turns=%d damage_logs=%d taken_logs=%d result=%s" % [
		d1, d2, ratio,
		int(one["turns"]), int(one["damage_logs"]), int(one["taken_logs"]), str(one["result"]),
	])


## ============================================
## 3. 运行中切档
## ============================================

func _test_mid_battle_switch(one: Dictionary, mixed: Dictionary) -> void:
	if one.is_empty() or mixed.is_empty():
		_failures.append("运行中切档的战斗应完整跑完")
		return
	var identical: bool = str(one["json"]) == str(mixed["json"])
	_expect(bool(mixed["switched"]), "战斗运行中应实际完成一次切档")
	_expect(int(mixed["switch_state"]) != 0, "切档应发生在非空闲的战斗进行状态")
	_expect(is_equal_approx(float(mixed["switch_scale"]), 2.0), "切档后应立刻进入 2x 时间尺度")
	_expect(float(mixed["switch_timer_ms"]) >= 60.0 and float(mixed["switch_timer_ms"]) <= 180.0,
		"切档后 0.2s 计时器应在约 100ms 内结束，实际 %.1fms" % float(mixed["switch_timer_ms"]))
	_expect(identical, "运行中切档不应改变战斗日志或结算 JSON")
	_expect(int(mixed["turns"]) == int(mixed["actions"]), "运行中切档不应产生重复结算")
	var d1 := float(one["duration_ms"]) / 1000.0
	var dm := float(mixed["duration_ms"]) / 1000.0
	_expect(dm < d1, "运行中切到 2x 后整场耗时应短于纯 1x")
	print("[BattleSpeed] mid_switch state=%d immediate_0.2s_timer=%.1fms identical=%s duration=%.2fs (1x=%.2fs) turns=%d" % [
		int(mixed["switch_state"]), float(mixed["switch_timer_ms"]), str(identical), dm, d1, int(mixed["turns"]),
	])


## ============================================
## 整场战斗驱动
## ============================================

func _run_scene_battle(speed_level: int, toggle_after_actions: int) -> Dictionary:
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
		_failures.append("整场战斗场景应能加载")
		await _free_main(main)
		return {}
	var board = battle.get("_board")
	var battle_manager = battle.get("_battle")
	if board == null or battle_manager == null:
		_failures.append("整场战斗应创建棋盘与战斗管理器")
		await _free_main(main)
		return {}
	# 固定测试战局长度：不修改数据表，只把本场敌人血量设为测试口径。
	battle_manager.enemies[0]["maxHP"] = TEST_ENEMY_HP
	battle_manager.enemies[0]["hp"] = TEST_ENEMY_HP

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle_manager.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	battle_manager.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))

	battle.call("set_battle_speed", speed_level)
	var start_ms := Time.get_ticks_msec()
	var actions := 0
	var switched := toggle_after_actions < 0
	var switch_state := 0
	var switch_scale := 0.0
	var switch_timer_ms := 0.0
	var guard_frames := 0
	while int(battle.get("_state")) != 6 and Time.get_ticks_msec() - start_ms < MAX_BATTLE_MS:
		await process_frame
		guard_frames += 1
		if not switched and actions >= toggle_after_actions and int(battle.get("_state")) != 0:
			switched = true
			switch_state = int(battle.get("_state"))
			battle.call("set_battle_speed", 2)
			switch_scale = Engine.time_scale
			var timer_start := Time.get_ticks_msec()
			await create_timer(0.2).timeout
			switch_timer_ms = float(Time.get_ticks_msec() - timer_start)
		if int(battle.get("_state")) != 0:
			continue
		var move := _find_valid_move(board)
		if move.is_empty():
			break
		battle.call("_do_swap", move["r1"], move["c1"], move["r2"], move["c2"])
		actions += 1
	var duration_ms := Time.get_ticks_msec() - start_ms

	var result: Dictionary = battle_manager.get_battle_result()
	var payload := {
		"seed": SEED,
		"turns": int(battle_manager.turn_count),
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"result": result,
	}
	var json := JSON.stringify(payload, "\t")
	if OS.get_environment("BATTLE_SPEED_DEBUG") == "1":
		var debug_path := "/tmp/battle_speed_%dx_toggle_%d.json" % [speed_level, toggle_after_actions]
		var debug_file := FileAccess.open(debug_path, FileAccess.WRITE)
		if debug_file != null:
			debug_file.store_string(json)
			debug_file.close()
			print("[BattleSpeed][debug] %s" % debug_path)
	var data := {
		"duration_ms": duration_ms,
		"actions": actions,
		"turns": int(battle_manager.turn_count),
		"damage_logs": damage_logs.size(),
		"taken_logs": taken_logs.size(),
		"result": str(result.get("result", "")),
		"json": json,
		"switched": switched,
		"switch_state": switch_state,
		"switch_scale": switch_scale,
		"switch_timer_ms": switch_timer_ms,
		"frames": guard_frames,
	}
	print("[BattleSpeed] run speed=%dx actions=%d turns=%d logs=%d/%d result=%s duration=%.2fs" % [
		speed_level, actions, int(battle_manager.turn_count), damage_logs.size(), taken_logs.size(),
		str(result.get("result", "")), float(duration_ms) / 1000.0,
	])
	await _free_main(main)
	_expect(is_equal_approx(Engine.time_scale, 1.0), "结束整场战斗后应恢复时间尺度 1.0")
	return data


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


func _send_mouse_click(battle_scene: Control, local_pos: Vector2) -> void:
	var transform := battle_scene.get_global_transform_with_canvas()
	var global_pos: Vector2 = transform * local_pos
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_pos
	battle_scene.call("_input", press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_pos
	battle_scene.call("_input", release)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("[BattleSpeed] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleSpeed] " + failure)
	quit(1)

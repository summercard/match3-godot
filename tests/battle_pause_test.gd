extends SceneTree

## 战斗内暂停面板回归：
## 1. 右上角设置按钮打开浮层，继续按钮关闭；二者都播放 button_click；
## 2. 音效 / 音乐 / 震动三个开关写回 SaveManager 的同一份 settings，并立即驱动场上节点；
## 3. 暂停 3 秒期间回合数、伤害日志、前摇计时、倍速计时与战斗状态不变；
## 4. 继续后从原处推进；带暂停的固定种子整场战斗与不暂停逐字节一致；
## 5. 退出战斗回到选关，不写星级与资源；
## 6. 不点暂停时固定种子转录与 59181c5 基线逐字节一致。
##
## 用法：
##   Godot --headless --path . --fixed-fps 60 --script res://tests/battle_pause_test.gd

const StageDBScript = preload("res://src/data/stage_db.gd")
const TranscriptScript = preload("res://tests/prepare_matchup_transcript.gd")

const SEED := 20261110
const TEST_ENEMY_HP := 420
const MAX_BATTLE_MS := 120000
const PAUSE_SECONDS := 3.0
const BASELINE_TRANSCRIPT_SHA256 := "0d6d3c718332bd2a09e2bf44b9f1116d23d6fd962216cc3fa77fb93153490adb"
const STATE_IDLE := 0
const STATE_ENEMY_TURN := 4
const STATE_BATTLE_END := 6

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_pause_ui_and_settings()
	await _test_freeze_window()
	var control := await _run_full_battle(-1)
	var paused := await _run_full_battle(2)
	_test_full_run_equivalence(control, paused)
	await _test_exit_keeps_save()
	_test_fixed_seed_transcript()
	_finish()


## ============================================
## 1. 浮层、开关与点击音
## ============================================

func _test_pause_ui_and_settings() -> void:
	var storage := _storage()
	storage.clear_all_data()
	var settings: Dictionary = storage.load_settings()
	settings["soundOn"] = true
	settings["musicOn"] = true
	settings["vibrationOn"] = true
	storage.save_settings(settings)

	var main := await _load_main()
	seed(SEED)
	await _enter_battle(main, true)
	var battle: Control = main.get_current_scene()
	var overlay = battle.get("_pause_overlay")
	var sfx = battle.get("_battle_sfx")
	var bgm = battle.get("_battle_bgm")
	var vibration := root.get_node_or_null("VibrationFeedback")
	_expect(overlay != null, "战斗场景应创建暂停浮层")
	_expect(not bool(battle.call("is_paused")), "战斗开始时应处于非暂停状态")
	_expect(not bool(overlay.get("visible")), "暂停浮层默认不可见")

	var played_before: int = int(sfx.played_count)
	battle.call("set_battle_speed", 2)
	_send_mouse_click(battle, (battle.call("_get_settings_button_rect") as Rect2).get_center())
	await process_frame
	_expect(bool(battle.call("is_paused")), "点击右上角设置按钮应打开暂停浮层")
	_expect(is_equal_approx(Engine.time_scale, 0.0), "暂停后时间尺度应冻结为 0，实际 %.2f" % Engine.time_scale)
	_expect(bool(overlay.get("visible")) and bool(overlay.get("paused")), "暂停浮层应可见并处于打开状态")
	_expect(int(sfx.played_count) == played_before + 1 and str(sfx.last_sound_id) == "button_click",
		"打开暂停的按钮应复用 button_click，实际 played=%d last=%s" % [int(sfx.played_count), str(sfx.last_sound_id)])
	print("[BattlePause] open settings_click played=%d last=%s time_scale=%.2f" % [
		int(sfx.played_count), str(sfx.last_sound_id), Engine.time_scale,
	])

	# 音效：写回存档并立即释放场上播放器。
	var toggle_rect: Rect2 = overlay.call("toggle_rect", 0)
	_send_mouse_click(battle, toggle_rect.get_center())
	await process_frame
	settings = storage.load_settings()
	_expect(not bool(settings.get("soundOn", true)), "音效开关关闭后应写回 settings.soundOn=false")
	_expect(not bool(sfx.enabled), "音效关闭后 BattleSfx.enabled 应为 false")
	_expect(int(sfx.player_count()) == 0, "音效关闭后场上不应保留特效播放器，实际 %d" % int(sfx.player_count()))
	_expect(battle.get("_combo_sfx") == null, "音效关闭后连锁音效节点应被释放")
	print("[BattlePause] toggle soundOff saved=%s enabled=%s players=%d" % [
		str(settings.get("soundOn", true)), str(sfx.enabled), int(sfx.player_count()),
	])

	# 音乐：写回存档并立即释放 BGM 播放器。
	_send_mouse_click(battle, (overlay.call("toggle_rect", 1) as Rect2).get_center())
	await process_frame
	settings = storage.load_settings()
	_expect(not bool(settings.get("musicOn", true)), "音乐开关关闭后应写回 settings.musicOn=false")
	_expect(not bool(bgm.enabled), "音乐关闭后 BattleBgm.enabled 应为 false")
	_expect(int(bgm.player_count()) == 0, "音乐关闭后场上不应保留 BGM 播放器，实际 %d" % int(bgm.player_count()))
	print("[BattlePause] toggle musicOff saved=%s enabled=%s players=%d" % [
		str(settings.get("musicOn", true)), str(bgm.enabled), int(bgm.player_count()),
	])

	# 震动：写回存档，关闭后的后续请求只累计丢弃、不产生请求。
	_send_mouse_click(battle, (overlay.call("toggle_rect", 2) as Rect2).get_center())
	await process_frame
	settings = storage.load_settings()
	_expect(not bool(settings.get("vibrationOn", true)), "震动开关关闭后应写回 settings.vibrationOn=false")
	_expect(not bool(vibration.enabled), "震动关闭后 VibrationFeedback.enabled 应为 false")
	var requests_before := int(vibration.request_count)
	var dropped_before := int(vibration.dropped_count)
	var accepted: bool = bool(vibration.request("button_tap"))
	_expect(not accepted, "震动关闭后的请求应被拒绝")
	_expect(int(vibration.request_count) == requests_before, "震动关闭后 request_count 不应增加")
	_expect(int(vibration.dropped_count) == dropped_before + 1, "震动关闭后请求应计入 dropped_count")
	print("[BattlePause] toggle vibrationOff saved=%s enabled=%s requests=%d->%d dropped=%d->%d" % [
		str(settings.get("vibrationOn", true)), str(vibration.enabled),
		requests_before, int(vibration.request_count), dropped_before, int(vibration.dropped_count),
	])

	# 依次打开三个开关，确认设置页与浮层互通。
	_send_mouse_click(battle, (overlay.call("toggle_rect", 0) as Rect2).get_center())
	await process_frame
	_send_mouse_click(battle, (overlay.call("toggle_rect", 1) as Rect2).get_center())
	await process_frame
	_send_mouse_click(battle, (overlay.call("toggle_rect", 2) as Rect2).get_center())
	await process_frame
	settings = storage.load_settings()
	_expect(bool(settings.get("soundOn", false)) and bool(settings.get("musicOn", false)) and bool(settings.get("vibrationOn", false)),
		"再次点击三个开关应全部恢复为 true")
	_expect(bool(sfx.enabled) and int(sfx.player_count()) >= 0, "音效恢复后 BattleSfx.enabled 应为 true")
	_expect(battle.get("_combo_sfx") != null, "音效恢复后连锁音效节点应重新创建")
	_expect(bool(bgm.enabled) and int(bgm.player_count()) == 1, "音乐恢复后应回到 1 个 BGM 播放器")
	_expect(bool(vibration.enabled), "震动恢复后 VibrationFeedback.enabled 应为 true")
	print("[BattlePause] toggles restored sound=%s music=%s vibration=%s bgm_players=%d" % [
		str(settings.get("soundOn", true)), str(settings.get("musicOn", true)),
		str(settings.get("vibrationOn", true)), int(bgm.player_count()),
	])

	# 继续：恢复时间尺度并播放 button_click。
	var played_before_resume := int(sfx.played_count)
	_send_mouse_click(battle, (overlay.call("resume_rect") as Rect2).get_center())
	await process_frame
	_expect(not bool(battle.call("is_paused")), "点击继续应关闭暂停浮层")
	_expect(is_equal_approx(Engine.time_scale, 2.0), "继续后应恢复暂停前的 2x 时间尺度，实际 %.2f" % Engine.time_scale)
	_expect(not bool(overlay.get("visible")), "继续后暂停浮层应隐藏")
	_expect(int(sfx.played_count) == played_before_resume + 1 and str(sfx.last_sound_id) == "button_click",
		"继续按钮应复用 button_click，实际 played=%d last=%s" % [int(sfx.played_count), str(sfx.last_sound_id)])
	print("[BattlePause] resume time_scale=%.2f played=%d last=%s" % [
		Engine.time_scale, int(sfx.played_count), str(sfx.last_sound_id),
	])
	await _free_main(main)
	Engine.time_scale = 1.0


## ============================================
## 2. 暂停 3 秒冻结窗口
## ============================================

func _test_freeze_window() -> void:
	var main := await _load_main()
	await _enter_battle(main, false, SEED)
	var battle: Control = main.get_current_scene()
	var bm = battle.get("_battle")
	var board = battle.get("_board")
	bm.enemies[0]["maxHP"] = TEST_ENEMY_HP
	bm.enemies[0]["hp"] = TEST_ENEMY_HP
	var damage_logs: Array = []
	bm.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	battle.call("set_battle_speed", 2)
	var overlay = battle.get("_pause_overlay")

	var move := _find_valid_move(board)
	_expect(not move.is_empty(), "固定棋盘应能找到有效交换")
	if move.is_empty():
		await _free_main(main)
		return
	battle.call("_do_swap", move["r1"], move["c1"], move["r2"], move["c2"])

	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(battle.get("_state")) == STATE_ENEMY_TURN and float(battle.get("_enemy_windup_timer")) > 0.0:
			break
	_expect(int(battle.get("_state")) == STATE_ENEMY_TURN and float(battle.get("_enemy_windup_timer")) > 0.0,
		"暂停前战斗应进入敌方前摇")

	var turn_before := int(bm.turn_count)
	var damage_before := damage_logs.size()
	var windup_before := float(battle.get("_enemy_windup_timer"))
	var windup_indices_before: Array = (battle.get("_enemy_windup_indices") as Array).duplicate()
	var state_before := int(battle.get("_state"))
	var probe_fired := [false]
	var probe := create_timer(0.2)
	probe.timeout.connect(func(): probe_fired[0] = true)

	_send_mouse_click(battle, (battle.call("_get_settings_button_rect") as Rect2).get_center())
	await process_frame
	_expect(bool(battle.call("is_paused")), "敌方前摇中点击设置应进入暂停")
	_expect(is_equal_approx(Engine.time_scale, 0.0), "暂停后倍速时间尺度应冻结为 0")

	var wait_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - wait_start < int(PAUSE_SECONDS * 1000.0):
		await process_frame
	var waited_ms := Time.get_ticks_msec() - wait_start
	_expect(int(bm.turn_count) == turn_before, "暂停 %.1fs 后回合数不应变化" % PAUSE_SECONDS)
	_expect(damage_logs.size() == damage_before, "暂停 %.1fs 后伤害日志条数不应变化" % PAUSE_SECONDS)
	_expect(is_equal_approx(float(battle.get("_enemy_windup_timer")), windup_before), "暂停期间敌方前摇计时不应推进")
	_expect((battle.get("_enemy_windup_indices") as Array) == windup_indices_before, "暂停期间敌方前摇目标不应变化")
	_expect(int(battle.get("_state")) == state_before, "暂停期间战斗状态不应变化")
	_expect(not bool(probe_fired[0]), "暂停期间 0.2s 计时器不应触发")
	print("[BattlePause] freeze %.0fms turn=%d->%d damage_logs=%d->%d windup=%.3f->%.3f state=%d->%d timer_fired=%s" % [
		float(waited_ms), turn_before, int(bm.turn_count),
		damage_before, damage_logs.size(), windup_before, float(battle.get("_enemy_windup_timer")),
		state_before, int(battle.get("_state")), str(probe_fired[0]),
	])

	_send_mouse_click(battle, (overlay.call("resume_rect") as Rect2).get_center())
	await process_frame
	_expect(not bool(battle.call("is_paused")), "继续后应退出暂停")
	_expect(is_equal_approx(Engine.time_scale, 2.0), "继续后应恢复 2x 倍速")
	var probe_deadline := Time.get_ticks_msec() + 2000
	while not bool(probe_fired[0]) and Time.get_ticks_msec() < probe_deadline:
		await process_frame
	_expect(bool(probe_fired[0]), "继续后暂停期间未触发的 0.2s 计时器应继续并触发")
	_expect(int(bm.turn_count) == turn_before, "继续后不应重复推进回合")
	_expect(damage_logs.size() == damage_before, "继续后不应重复结算伤害")
	print("[BattlePause] resume_continue turn=%d damage_logs=%d timer_fired=%s" % [
		int(bm.turn_count), damage_logs.size(), str(probe_fired[0]),
	])
	await _free_main(main)
	Engine.time_scale = 1.0


## ============================================
## 3. 整场固定种子：暂停 vs 不暂停
## ============================================

func _test_full_run_equivalence(control: Dictionary, paused: Dictionary) -> void:
	if control.is_empty() or paused.is_empty():
		_failures.append("固定种子整场战斗应完整跑完")
		return
	var identical: bool = str(control["json"]) == str(paused["json"])
	_expect(identical, "暂停 3 秒不应改变固定种子整场战斗的日志与结算 JSON")
	_expect(bool(paused["paused_once"]), "整场战斗应实际发生一次暂停")
	_expect(int(paused["turns"]) == int(paused["actions"]), "带暂停的整场战斗每次有效交换只应推进 1 回合")
	_expect(int(control["turns"]) == int(paused["turns"]), "暂停不应改变回合数")
	var hash_control := str(control["json"]).sha256_text()
	var hash_paused := str(paused["json"]).sha256_text()
	_expect(hash_control == hash_paused, "暂停与不暂停的 JSON SHA-256 应相同")
	print("[BattlePause] full_run identical=%s sha256=%s turns=%d damage_logs=%d taken_logs=%d result=%s" % [
		str(identical), hash_control, int(paused["turns"]), int(paused["damage_logs"]),
		int(paused["taken_logs"]), str(paused["result"]),
	])


## ============================================
## 4. 退出战斗不写星级 / 资源
## ============================================

func _test_exit_keeps_save() -> void:
	var storage := _storage()
	storage.clear_all_data()
	storage.get_monster_pool()
	var player: Dictionary = storage.get_player()
	player["level"] = 7
	player["gold"] = 1234
	player["gems"] = 56
	storage.save_player(player)
	storage.save_stage_stars("stage_1_1", 2)
	storage.save_stage_stars("stage_1_2", 1)
	var player_before := JSON.stringify(storage.load_player(), "\t")
	var progress_before := JSON.stringify(storage.load_stage_progress(), "\t")
	var stars_before := int(storage.get_stage_stars("stage_1_1"))

	var main := await _load_main()
	await _enter_battle(main, false, SEED)
	var battle: Control = main.get_current_scene()
	battle.call("open_pause_panel")
	await process_frame
	_expect(bool(battle.call("is_paused")), "退出测试前战斗应处于暂停")
	var overlay = battle.get("_pause_overlay")
	_send_mouse_click(battle, (overlay.call("exit_rect") as Rect2).get_center())

	var switched := false
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if main.get_current_scene_name() == "stage_select":
			switched = true
			break
	_expect(switched, "退出战斗后应回到选关场景，实际 %s" % main.get_current_scene_name())
	_expect(is_equal_approx(Engine.time_scale, 1.0), "退出战斗后应恢复时间尺度 1.0")

	var player_after := JSON.stringify(storage.load_player(), "\t")
	var progress_after := JSON.stringify(storage.load_stage_progress(), "\t")
	_expect(player_after == player_before, "退出战斗后玩家资源与战前应完全一致")
	_expect(progress_after == progress_before, "退出战斗后关卡星级与战前应完全一致")
	_expect(int(storage.get_stage_stars("stage_1_1")) == stars_before, "退出战斗后 stage_1_1 星级不应变化")
	print("[BattlePause] exit scene=%s time_scale=%.2f player_equal=%s progress_equal=%s stars=%d" % [
		main.get_current_scene_name(), Engine.time_scale, str(player_after == player_before),
		str(progress_after == progress_before), int(storage.get_stage_stars("stage_1_1")),
	])
	await _free_main(main)
	Engine.time_scale = 1.0


## ============================================
## 5. 不点暂停：固定种子转录与 59181c5 基线一致
## ============================================

func _test_fixed_seed_transcript() -> void:
	var json: String = TranscriptScript.build_payload_json()
	var hash := json.sha256_text()
	_expect(hash == BASELINE_TRANSCRIPT_SHA256, "不点暂停的固定种子转录应与 59181c5 基线逐字节一致")
	var baseline_path := "res://docs/evidence/ui_button_sfx/battle_before.json"
	if FileAccess.file_exists(baseline_path):
		var baseline := FileAccess.get_file_as_string(baseline_path)
		_expect(json == baseline, "转录内容应与基线文件完全一致")
	print("[BattlePause] fixed_seed_transcript sha256=%s baseline=%s bytes=%d" % [
		hash, BASELINE_TRANSCRIPT_SHA256, json.length(),
	])


## ============================================
## 整场战斗驱动
## ============================================

func _run_full_battle(pause_after_actions: int) -> Dictionary:
	var main := await _load_main()
	await _enter_battle(main, false, SEED)
	var battle: Control = main.get_current_scene()
	var bm = battle.get("_battle")
	var board = battle.get("_board")
	if battle == null or bm == null or board == null:
		_failures.append("整场战斗应创建棋盘与战斗管理器")
		await _free_main(main)
		return {}
	bm.enemies[0]["maxHP"] = TEST_ENEMY_HP
	bm.enemies[0]["hp"] = TEST_ENEMY_HP
	var damage_logs: Array = []
	var taken_logs: Array = []
	bm.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	bm.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))
	var overlay = battle.get("_pause_overlay")

	var start_ms := Time.get_ticks_msec()
	var actions := 0
	var paused_once := false
	while int(battle.get("_state")) != STATE_BATTLE_END and Time.get_ticks_msec() - start_ms < MAX_BATTLE_MS:
		await process_frame
		var state := int(battle.get("_state"))
		if pause_after_actions >= 0 and not paused_once and actions >= pause_after_actions \
				and state != STATE_IDLE and state != STATE_BATTLE_END:
			paused_once = true
			_send_mouse_click(battle, (battle.call("_get_settings_button_rect") as Rect2).get_center())
			await process_frame
			_expect(bool(battle.call("is_paused")), "整场战斗应在进行中成功暂停")
			var wait_start := Time.get_ticks_msec()
			while Time.get_ticks_msec() - wait_start < int(PAUSE_SECONDS * 1000.0):
				await process_frame
			_send_mouse_click(battle, (overlay.call("resume_rect") as Rect2).get_center())
			await process_frame
			_expect(not bool(battle.call("is_paused")), "整场战斗暂停后应能继续")
		if int(battle.get("_state")) != STATE_IDLE:
			continue
		var move := _find_valid_move(board)
		if move.is_empty():
			break
		battle.call("_do_swap", move["r1"], move["c1"], move["r2"], move["c2"])
		actions += 1

	var result: Dictionary = bm.get_battle_result()
	var payload := {
		"seed": SEED,
		"turns": int(bm.turn_count),
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"result": result,
	}
	var json := JSON.stringify(payload, "\t")
	var turns_total := int(bm.turn_count)
	var result_name := str(result.get("result", ""))
	print("[BattlePause] run pause_after=%d actions=%d turns=%d damage_logs=%d taken_logs=%d result=%s" % [
		pause_after_actions, actions, turns_total, damage_logs.size(), taken_logs.size(), result_name,
	])
	await _free_main(main)
	Engine.time_scale = 1.0
	return {
		"json": json,
		"turns": turns_total,
		"actions": actions,
		"damage_logs": damage_logs.size(),
		"taken_logs": taken_logs.size(),
		"result": result_name,
		"paused_once": paused_once,
	}


## ============================================
## 公共辅助
## ============================================

func _enter_battle(main: Control, input_test_only: bool, battle_seed: int = -1) -> void:
	if battle_seed >= 0:
		seed(battle_seed)
	var data := {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1"),
	}
	if input_test_only:
		data["inputTestOnly"] = true
	main.switch_scene("battle", data)
	await process_frame
	await process_frame


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


func _storage() -> Node:
	return root.get_node("SaveManager")


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
		print("[BattlePause] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattlePause] " + failure)
	quit(1)

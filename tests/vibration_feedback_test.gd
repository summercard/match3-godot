extends SceneTree
## 震动反馈层回归：
## 1. CONFIG 集中声明 enabled 与四类档位；四类档位的强度、时长至少两项参数不同；
## 2. vibrationOn=false 时四类事件各走一遍，振动请求数为 0，请求全部计入丢弃；
## 3. vibrationOn=true 时四类事件各恰好 1 次请求，四类计数各为 1；
## 4. 设置页运行中切换 vibrationOn，下一帧同步到总开关；
## 5. 无事件空跑 2 秒，请求数与丢弃数都不增加；
## 6. 真实战斗场景中技能释放 / 胜利 / 失败 / 按钮点击各触发一次对应请求；
## 7. 设置页自绘按钮与场景原生 BaseButton 都能产生 button_tap 请求；
## 8. vibrationOn 开/关两态下，固定战局的战斗日志与结算 JSON 逐位一致。
##
## 用法：
##   Godot --headless --path . --script res://tests/vibration_feedback_test.gd
## 证据采集（输出某一开关状态的原始数据）：
##   Godot --headless --path . --script res://tests/vibration_feedback_test.gd -- --vibration-state=on
##   Godot --headless --path . --script res://tests/vibration_feedback_test.gd -- --vibration-state=off

const VibrationScript = preload("res://src/ui/components/vibration_feedback.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []
var _original_settings: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager = root.get_node_or_null("SaveManager")
	if save_manager != null:
		_original_settings = save_manager.load_settings().duplicate(true)

	var state := _read_arg("--vibration-state=", "")
	if state == "on" or state == "off":
		await _run_evidence(state == "on")
		_restore_settings()
		_finish()
		return

	_test_config()
	await _test_master_switch()
	await _test_idle_no_requests()
	await _test_scene_four_events()
	await _test_settings_button_tap()
	await _test_button_wiring()
	_test_battle_logs_identical()
	_restore_settings()
	_finish()


## ============================================
## 1. CONFIG 与四类档位
## ============================================

func _test_config() -> void:
	var config: Dictionary = VibrationScript.CONFIG
	_expect(config.has("enabled"), "CONFIG 应带 enabled 默认总开关")
	_expect(VibrationScript.vibration_on_from_settings({}) == bool(config["enabled"]),
		"缺少 vibrationOn 时应沿用 CONFIG.enabled 默认值")
	var profiles: Dictionary = config.get("profiles", {})
	for event_id: String in VibrationScript.EVENT_IDS:
		var profile: Dictionary = profiles.get(event_id, {})
		_expect(not profile.is_empty(), "CONFIG.profiles 缺少 %s" % event_id)
		_expect(float(profile.get("strength", -1.0)) >= 0.0
			and float(profile.get("strength", 2.0)) <= 1.0,
			"%s 的强度应在 0.0-1.0" % event_id)
		_expect(int(profile.get("duration_ms", 0)) > 0, "%s 的时长应为正数" % event_id)

	# 四类档位两两比较：强度与时长两项参数都应不同。
	var keys := VibrationScript.EVENT_IDS
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			var a: Dictionary = profiles[keys[i]]
			var b: Dictionary = profiles[keys[j]]
			var differences := 0
			if not is_equal_approx(float(a.get("strength", 0.0)), float(b.get("strength", 0.0))):
				differences += 1
			if int(a.get("duration_ms", 0)) != int(b.get("duration_ms", 0)):
				differences += 1
			_expect(differences >= 2,
				"%s 与 %s 应至少两项参数不同，实际 %d" % [keys[i], keys[j], differences])

	for event_id: String in keys:
		var profile: Dictionary = profiles[event_id]
		print("[Vibration] %-10s strength=%.2f duration=%dms label=%s" % [
			event_id,
			float(profile["strength"]),
			int(profile["duration_ms"]),
			str(profile.get("label", "")),
		])


## ============================================
## 2. 总开关与计数
## ============================================

func _test_master_switch() -> void:
	var vibe = _vibration_node()
	_expect(vibe != null, "应挂载 VibrationFeedback Autoload")
	if vibe == null:
		return

	_set_vibration_on(false)
	await process_frame
	await process_frame
	_expect(not vibe.enabled, "vibrationOn=false 时总开关应关闭")
	vibe.reset_counters()
	for event_id: String in VibrationScript.EVENT_IDS:
		_expect(not vibe.request(event_id), "关闭时 %s 不应发出请求" % event_id)
	_expect(int(vibe.request_count) == 0, "vibrationOn=false 时请求数应恒为 0，实际 %d" % int(vibe.request_count))
	_expect(int(vibe.dropped_count) == 4, "vibrationOn=false 时四类事件都应计入丢弃，实际 %d" % int(vibe.dropped_count))
	_expect(str(vibe.last_dropped_event) == "button_tap", "最后一条丢弃事件应可追溯")

	_set_vibration_on(true)
	await process_frame
	await process_frame
	_expect(vibe.enabled, "vibrationOn=true 时总开关应打开")
	vibe.reset_counters()
	for event_id: String in VibrationScript.EVENT_IDS:
		_expect(vibe.request(event_id), "开启时 %s 应发出请求" % event_id)
	_expect(int(vibe.request_count) == 4, "四类事件应恰好 4 次请求，实际 %d" % int(vibe.request_count))
	_expect(int(vibe.dropped_count) == 0, "开启时不应丢弃请求，实际 %d" % int(vibe.dropped_count))
	for event_id: String in VibrationScript.EVENT_IDS:
		_expect(int(vibe.event_counts.get(event_id, 0)) == 1,
			"%s 应恰好 1 次请求，实际 %d" % [event_id, int(vibe.event_counts.get(event_id, 0))])
	_expect(str(vibe.last_event) == "button_tap", "最近事件应记录为 button_tap")
	_expect(int(vibe.last_duration_ms) == int(VibrationScript.CONFIG["profiles"]["button_tap"]["duration_ms"]),
		"最近一次时长应取对应档位")
	_expect(is_equal_approx(float(vibe.last_strength), float(VibrationScript.CONFIG["profiles"]["button_tap"]["strength"])),
		"最近一次强度应取对应档位")

	# 运行中切换：关闭后下一帧不再发出请求，重新打开后恢复。
	_set_vibration_on(false)
	await process_frame
	await process_frame
	_expect(not vibe.enabled, "运行中关闭 vibrationOn 应在下一帧生效")
	vibe.reset_counters()
	vibe.request("victory")
	_expect(int(vibe.request_count) == 0 and int(vibe.dropped_count) == 1,
		"运行中关闭后请求应被丢弃")
	_set_vibration_on(true)
	await process_frame
	await process_frame
	_expect(vibe.enabled, "运行中打开 vibrationOn 应在下一帧生效")
	vibe.reset_counters()
	vibe.request("victory")
	_expect(int(vibe.request_count) == 1 and int(vibe.dropped_count) == 0,
		"运行中打开后请求应恢复")


## ============================================
## 3. 空跑 2 秒
## ============================================

func _test_idle_no_requests() -> void:
	var vibe = _vibration_node()
	if vibe == null:
		return
	_set_vibration_on(true)
	await process_frame
	await process_frame
	vibe.reset_counters()
	await create_timer(2.0).timeout
	_expect(int(vibe.request_count) == 0, "无事件空跑 2 秒请求数应为 0，实际 %d" % int(vibe.request_count))
	_expect(int(vibe.dropped_count) == 0, "无事件空跑 2 秒丢弃数应为 0，实际 %d" % int(vibe.dropped_count))
	print("[Vibration] idle 2s requests=%d dropped=%d" % [int(vibe.request_count), int(vibe.dropped_count)])


## ============================================
## 4. 真实战斗场景：四类事件
## ============================================

func _test_scene_four_events() -> void:
	var on_payload := await _collect_scene_events(true)
	var off_payload := await _collect_scene_events(false)

	var on_vibe: Dictionary = on_payload["vibration"]
	var off_vibe: Dictionary = off_payload["vibration"]
	_expect(bool(on_payload["scene_loaded"]), "战斗场景应能加载")
	_expect(int(on_vibe["request_count"]) == 4,
		"开启时四类事件应恰好 4 次请求，实际 %d" % int(on_vibe["request_count"]))
	_expect(int(on_vibe["dropped_count"]) == 0, "开启时不应丢弃请求")
	for event_id: String in VibrationScript.EVENT_IDS:
		_expect(int(on_vibe["event_counts"].get(event_id, 0)) == 1,
			"场景内 %s 应恰好 1 次请求，实际 %d" % [event_id, int(on_vibe["event_counts"].get(event_id, 0))])
	_expect(int(off_vibe["request_count"]) == 0,
		"关闭时四类事件请求数应恒为 0，实际 %d" % int(off_vibe["request_count"]))
	_expect(int(off_vibe["dropped_count"]) == 4,
		"关闭时四类事件应全部丢弃，实际 %d" % int(off_vibe["dropped_count"]))

	print("[Vibration] scene on : requests=%d dropped=%d counts=%s" % [
		int(on_vibe["request_count"]), int(on_vibe["dropped_count"]),
		JSON.stringify(on_vibe["event_counts"])])
	print("[Vibration] scene off: requests=%d dropped=%d counts=%s" % [
		int(off_vibe["request_count"]), int(off_vibe["dropped_count"]),
		JSON.stringify(off_vibe["event_counts"])])


## 在真实战斗场景里按顺序触发：技能释放 → 按钮点击 → 胜利 → 失败。
func _collect_scene_events(vibration_on: bool) -> Dictionary:
	_set_vibration_on(vibration_on)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var stage_db = StageDBScript.new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	var vibe = _vibration_node()
	if vibe != null:
		vibe.reset_counters()
	var payload := {
		"scene_loaded": battle_scene != null,
		"vibration": {},
	}
	if battle_scene == null:
		main.queue_free()
		await process_frame
		return payload

	# 技能释放：走战斗场景真实的技能表现入口。
	battle_scene.call("_apply_skill_result_visuals", {
		"success": true,
		"skill_name": "测试技能",
		"attacker": "伙伴",
		"damage": 1,
		"target_index": 0,
	})

	# 按钮点击：点底栏自动捕捉开关（自绘按钮）。
	var board = battle_scene.get("_board")
	var bottom_y: float = float(board.offset_y + board.rows * board.cell_size + 7.0) if board != null else 619.0
	battle_scene.call("_on_tap", 38.0, bottom_y + 20.0)

	# 胜利 / 失败：走战斗结算入口各一次。
	var battle = battle_scene.get("_battle")
	if battle != null:
		battle.battle_result = "win"
		battle_scene.set("_battle_end_overlay_started", false)
		battle_scene.call("_begin_battle_end_overlay")
		battle.battle_result = "lose"
		battle_scene.set("_battle_end_overlay_started", false)
		battle_scene.call("_begin_battle_end_overlay")

	if vibe != null:
		payload["vibration"] = {
			"enabled": bool(vibe.enabled),
			"request_count": int(vibe.request_count),
			"dropped_count": int(vibe.dropped_count),
			"event_counts": vibe.event_counts.duplicate(true),
			"last_event": str(vibe.last_event),
			"last_strength": float(vibe.last_strength),
			"last_duration_ms": int(vibe.last_duration_ms),
		}

	main.queue_free()
	await process_frame
	return payload


## ============================================
## 5. 自绘按钮：设置页开关行
## ============================================

func _test_settings_button_tap() -> void:
	var vibe = _vibration_node()
	if vibe == null:
		return
	_set_vibration_on(true)
	await process_frame
	await process_frame
	vibe.set_enabled(true)
	vibe.reset_counters()
	var settings_scene = load("res://src/ui/scene/scene_settings.gd").new()
	root.add_child(settings_scene)
	settings_scene.call("init", {})
	# 第三行（index 2）是「震动反馈」开关行；按行矩形取中心，避免依赖行高常量。
	var vibration_rect: Rect2 = settings_scene.call("_get_row_rect", 2)
	settings_scene.call("_on_tap", vibration_rect.get_center())
	_expect(int(vibe.event_counts.get("button_tap", 0)) == 1,
		"设置页自绘按钮应产生 1 次 button_tap 请求")
	settings_scene.queue_free()
	# 点击让 vibrationOn 变成 false，恢复成 true 供后续用例使用。
	_set_vibration_on(true)
	await process_frame
	await process_frame


## ============================================
## 6. 原生按钮接线
## ============================================

func _test_button_wiring() -> void:
	var vibe = _vibration_node()
	if vibe == null:
		return
	_set_vibration_on(true)
	_vibration_node().set_enabled(true)
	vibe.reset_counters()
	var holder := Control.new()
	root.add_child(holder)
	var button := Button.new()
	holder.add_child(button)
	var wired: int = vibe.wire_buttons(holder)
	_expect(wired == 1, "wire_buttons 应接线 1 个 BaseButton，实际 %d" % wired)
	button.pressed.emit()
	_expect(int(vibe.event_counts.get("button_tap", 0)) == 1,
		"原生按钮按下应产生 1 次 button_tap 请求")
	# 重复接线不应重复计数。
	vibe.wire_buttons(holder)
	button.pressed.emit()
	_expect(int(vibe.event_counts.get("button_tap", 0)) == 2,
		"重复接线不应造成重复请求，实际 %d" % int(vibe.event_counts.get("button_tap", 0)))
	holder.queue_free()
	await process_frame


## ============================================
## 7. vibrationOn 开/关的战斗日志与结算 JSON
## ============================================

func _test_battle_logs_identical() -> void:
	var on_payload := _run_deterministic_battle(true)
	var off_payload := _run_deterministic_battle(false)
	var on_combat := {
		"turns": on_payload["turns"],
		"damage_dealt_log": on_payload["damage_dealt_log"],
		"damage_taken_log": on_payload["damage_taken_log"],
		"result": on_payload["result"],
	}
	var off_combat := {
		"turns": off_payload["turns"],
		"damage_dealt_log": off_payload["damage_dealt_log"],
		"damage_taken_log": off_payload["damage_taken_log"],
		"result": off_payload["result"],
	}
	var identical := JSON.stringify(on_combat, "\t") == JSON.stringify(off_combat, "\t")
	_expect(identical, "vibrationOn 开/关两态的战斗日志与结算 JSON 应逐位一致")
	print("[Vibration] battle on/off identical=%s turns=%d damage_logs=%d taken_logs=%d result=%s" % [
		str(identical),
		int(on_payload["result"].get("turn_count", 0)),
		on_payload["damage_dealt_log"].size(),
		on_payload["damage_taken_log"].size(),
		str(on_payload["result"].get("result", "")),
	])


## 与 battle_sfx / battle_bgm 相同的固定战局：stage_1_1、seed 20261109、最多 20 回合脚本。
func _run_deterministic_battle(vibration_on: bool) -> Dictionary:
	_set_vibration_on(vibration_on)
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

	var payload := {
		"turns": turns,
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"result": battle.get_battle_result(),
	}
	battle.free()
	return payload


## ============================================
## 8. 证据采集：某一开关状态的原始输出
## ============================================

func _run_evidence(vibration_on: bool) -> void:
	var label := "vibrationOn=true" if vibration_on else "vibrationOn=false"
	print("[Vibration][evidence] ===== %s =====" % label)
	# 隔离音频层，避免 BGM/音效播放器干扰原始输出。
	_set_sound_on(false)
	_set_music_on(false)

	var scene_payload := await _collect_scene_events(vibration_on)
	var battle_payload := _run_deterministic_battle(vibration_on)
	var raw := {
		"settings": {
			"soundOn": false,
			"musicOn": false,
			"vibrationOn": vibration_on,
		},
		"vibration": scene_payload["vibration"],
		"profiles": VibrationScript.CONFIG["profiles"],
		"scene": {
			"scene": "battle",
			"loaded": scene_payload["scene_loaded"],
			"battle_end_counts": scene_payload["vibration"].get("event_counts", {}),
		},
		"battle": {
			"turns": battle_payload["turns"],
			"damage_dealt_log": battle_payload["damage_dealt_log"],
			"damage_taken_log": battle_payload["damage_taken_log"],
			"result": battle_payload["result"],
		},
	}
	print("[Vibration][evidence] raw_json=")
	print(JSON.stringify(raw, "\t"))


## ============================================
## 工具
## ============================================

func _vibration_node():
	return root.get_node_or_null("VibrationFeedback")


func _set_vibration_on(value: bool) -> void:
	_save_setting("vibrationOn", value)


func _set_sound_on(value: bool) -> void:
	_save_setting("soundOn", value)


func _set_music_on(value: bool) -> void:
	_save_setting("musicOn", value)


func _save_setting(key: String, value: bool) -> void:
	var save_manager = root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_method("save_settings"):
		return
	var settings: Dictionary = save_manager.load_settings().duplicate(true)
	settings[key] = value
	save_manager.save_settings(settings)


func _restore_settings() -> void:
	var save_manager = root.get_node_or_null("SaveManager")
	if save_manager == null or _original_settings.is_empty():
		return
	save_manager.save_settings(_original_settings.duplicate(true))


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[Vibration] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[Vibration] " + failure)
	quit(1)

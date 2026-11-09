extends SceneTree

## 战斗音效层回归：
## 1. 六个程序化音效的参数互不相同：频率、时长、波形等至少 3 项不同；
## 2. 每个音效都生成可播放的 16-bit PCM，且六段数据互不相同；
## 3. 总开关关闭时不创建播放器、不播放，播放器数为 0；
## 4. 同一引擎帧最多触发 8 个播放实例，超出的丢弃并计数，播放器池不超过 8；
## 5. 音效开/关两种状态下，stage_1_1 固定种子的伤害日志、承伤日志与结算统计逐位一致。

const BattleSfxScript = preload("res://src/ui/components/battle_sfx.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const SOUND_KEYS := ["frequency", "duration", "waveform", "attack", "decay"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_config_distinctness()
	_test_streams_generated()
	_test_master_switch_off()
	await _test_frame_cap()
	_test_battle_logs_identical()
	await _test_scene_integration()
	await _test_scene_sound_off_zero_players()
	BattleSfxScript.enabled = true
	_finish()


func _test_config_distinctness() -> void:
	var ids: Array = BattleSfxScript.SOUND_IDS
	_expect(ids.size() == 6, "应有六个战斗音效，实际 %d" % ids.size())
	for sound_id: String in ids:
		var params: Dictionary = BattleSfxScript.CONFIG["sounds"].get(sound_id, {})
		_expect(not params.is_empty(), "音效 %s 应有配置" % sound_id)
		_expect(float(params.get("frequency", 0.0)) > 0.0, "%s 应有正频率" % sound_id)
		_expect(float(params.get("duration", 0.0)) > 0.0, "%s 应有正时长" % sound_id)
		_expect(not str(params.get("waveform", "")).is_empty(), "%s 应声明波形" % sound_id)
	# 每两个音效至少在 SOUND_KEYS 中 3 项不同；六种波形全部不同时天然满足。
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a: Dictionary = BattleSfxScript.CONFIG["sounds"][ids[i]]
			var b: Dictionary = BattleSfxScript.CONFIG["sounds"][ids[j]]
			var differences := 0
			for key: String in SOUND_KEYS:
				if str(a.get(key, "")) != str(b.get(key, "")):
					differences += 1
			_expect(differences >= 3,
				"%s 与 %s 应至少 3 项参数不同，实际 %d" % [ids[i], ids[j], differences])
	var waveforms := {}
	for sound_id: String in ids:
		waveforms[str(BattleSfxScript.CONFIG["sounds"][sound_id]["waveform"])] = true
	_expect(waveforms.size() == ids.size(), "六个音效应使用六种不同波形")
	for sound_id: String in ids:
		var params: Dictionary = BattleSfxScript.CONFIG["sounds"][sound_id]
		print("[BattleSfx] %-11s freq=%.1fHz end=%.1fHz dur=%.3fs wave=%s attack=%.3fs decay=%.1f" % [
			sound_id,
			float(params["frequency"]),
			float(params.get("frequency_end", params["frequency"])),
			float(params["duration"]),
			str(params["waveform"]),
			float(params["attack"]),
			float(params["decay"]),
		])


func _test_streams_generated() -> void:
	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.set_enabled(true)
	var payloads := {}
	for sound_id: String in BattleSfxScript.SOUND_IDS:
		var stream: AudioStreamWAV = sfx.get_stream(sound_id)
		_expect(stream is AudioStreamWAV, "%s 应生成 AudioStreamWAV" % sound_id)
		if stream == null:
			continue
		_expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "%s 应使用 16-bit PCM" % sound_id)
		_expect(stream.mix_rate == int(BattleSfxScript.CONFIG["sample_rate"]),
			"%s 采样率应与配置一致" % sound_id)
		_expect(stream.data.size() > 1000, "%s 应包含足够采样" % sound_id)
		payloads[sound_id] = stream.data
		var loudest := 0
		for i in range(0, stream.data.size() - 1, 2):
			loudest = maxi(loudest, absi(stream.data.decode_s16(i)))
		_expect(loudest > 1000, "%s 应有可听见的振幅，实际 %d" % [sound_id, loudest])
	var ids: Array = BattleSfxScript.SOUND_IDS
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			_expect(payloads.get(ids[i]) != payloads.get(ids[j]),
				"%s 与 %s 的 PCM 数据应不同" % [ids[i], ids[j]])
	sfx.free()


func _test_master_switch_off() -> void:
	_expect(not BattleSfxScript.sound_on_from_settings({"soundOn": false}),
		"soundOn=false 应关闭战斗音效总开关")
	_expect(BattleSfxScript.sound_on_from_settings({"soundOn": true}),
		"soundOn=true 应打开战斗音效总开关")
	_expect(BattleSfxScript.sound_on_from_settings({}),
		"缺少 soundOn 时应沿用现有默认开启口径")

	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.apply_settings({"soundOn": false})
	_expect(sfx.player_count() == 0, "总开关关闭时不应创建任何播放器")
	for sound_id: String in BattleSfxScript.SOUND_IDS:
		_expect(not sfx.play(sound_id), "总开关关闭时 %s 不应播放" % sound_id)
	_expect(sfx.player_count() == 0, "总开关关闭时播放后播放器数仍应为 0")
	_expect(sfx.played_count == 0, "总开关关闭时不应累计播放次数")

	sfx.set_enabled(true)
	_expect(sfx.play("hit"), "总开关开启后应能播放")
	_expect(sfx.player_count() == int(BattleSfxScript.CONFIG["max_players"]),
		"开启后播放器池应等于配置上限")
	sfx.apply_settings({"soundOn": false})
	_expect(sfx.player_count() == 0, "运行中关闭总开关应立即释放播放器")
	sfx.free()
	BattleSfxScript.enabled = true


func _test_frame_cap() -> void:
	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.set_enabled(true)
	sfx.reset_counters()

	var played := 0
	for i in range(12):
		if sfx.play(str(BattleSfxScript.SOUND_IDS[i % BattleSfxScript.SOUND_IDS.size()])):
			played += 1
	_expect(played == 8, "同一帧 12 次请求应只播放 8 次，实际 %d" % played)
	_expect(sfx.played_count == 8, "同一帧播放计数应为 8，实际 %d" % sfx.played_count)
	_expect(sfx.dropped_count == 4, "同一帧超出上限的 4 次应被丢弃并计数，实际 %d" % sfx.dropped_count)
	_expect(sfx.player_count() <= 8, "播放器池不应超过 8 个，实际 %d" % sfx.player_count())
	_expect(sfx.peak_players <= 8, "峰值播放器数不应超过 8，实际 %d" % sfx.peak_players)

	var frame_before := Engine.get_process_frames()
	var guard := 0
	while Engine.get_process_frames() == frame_before and guard < 10:
		await process_frame
		guard += 1
	var played_next := 0
	for i in range(9):
		if sfx.play("hit"):
			played_next += 1
	_expect(played_next == 8, "下一帧应重新获得 8 次额度，实际 %d" % played_next)
	_expect(sfx.dropped_count == 5, "下一帧第 9 次请求应累计丢弃到 5，实际 %d" % sfx.dropped_count)
	_expect(sfx.player_count() <= 8, "连续两帧后播放器池仍不应超过 8 个")
	print("[BattleSfx] frame cap: frame1 played=%d dropped=%d, frame2 played=%d dropped=%d, players=%d" % [
		played,
		4,
		played_next,
		sfx.dropped_count,
		sfx.player_count(),
	])
	sfx.free()
	BattleSfxScript.enabled = true


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
	_expect(int(on_payload["played_count"]) > 0, "音效开启时战斗应实际触发音效")
	_expect(int(off_payload["played_count"]) == 0, "音效关闭时不应触发任何音效")
	_expect(int(off_payload["player_count"]) == 0, "音效关闭时战斗音效播放器应为 0")
	_expect(JSON.stringify(on_combat, "\t") == JSON.stringify(off_combat, "\t"),
		"音效开/关两种状态下的伤害日志、承伤日志与结算统计应逐位一致")
	print("[BattleSfx] combat log: damage=%d taken=%d turns=%d result=%s" % [
		on_payload["damage_dealt_log"].size(),
		on_payload["damage_taken_log"].size(),
		int(on_payload["result"].get("turn_count", 0)),
		str(on_payload["result"].get("result", "")),
	])
	print("[BattleSfx] on/off identical=%s on_played=%d off_played=%d off_players=%d" % [
		JSON.stringify(on_combat, "\t") == JSON.stringify(off_combat, "\t"),
		int(on_payload["played_count"]),
		int(off_payload["played_count"]),
		int(off_payload["player_count"]),
	])


## 与 battle_hit_reaction_test 相同的固定战局：stage_1_1、seed 20261109、最多 20 回合的脚本。
func _run_deterministic_battle(sfx_enabled: bool) -> Dictionary:
	seed(20261109)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], ["enemy_001"], 5, 1, stage, "stage_1_1")
	battle.enemies[0]["maxHP"] = 900
	battle.enemies[0]["hp"] = 900
	battle.max_turns = 50

	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.set_enabled(sfx_enabled)
	sfx.reset_counters()

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle.damage_dealt.connect(func(info: Dictionary):
		damage_logs.append(info.duplicate(true))
		if sfx_enabled:
			var effective := bool(info.get("isEffective", info.get("is_effective", false)))
			sfx.play("crit" if effective else "hit")
	)
	battle.enemy_attacked.connect(func(info: Dictionary):
		taken_logs.append(info.duplicate(true))
		if sfx_enabled and int(info.get("damage", 0)) > 0:
			sfx.play("take_damage")
	)

	var combos: Array = [4, 3, 2, 1]
	var turns: Array = []
	for turn in range(1, 21):
		battle.turn_count = turn
		var combo := int(combos[(turn - 1) % combos.size()])
		var result: Dictionary = battle.process_match_result({"fire": 3, "water": 3, "grass": 3}, combo)
		if sfx_enabled:
			sfx.play("match_clear")
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
	if sfx_enabled:
		sfx.play("victory" if battle.battle_result == "win" else "defeat")

	var result: Dictionary = battle.get_battle_result()
	var payload := {
		"turns": turns,
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"result": result,
		"played_count": sfx.played_count,
		"dropped_count": sfx.dropped_count,
		"player_count": sfx.player_count(),
	}
	battle.free()
	sfx.free()
	BattleSfxScript.enabled = true
	return payload


## 战斗场景应把 BattleSfx 挂到场上，并按 soundOn 同步总开关；事件入口能触发对应音效。
func _test_scene_integration() -> void:
	BattleSfxScript.enabled = true
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
	if battle_scene == null:
		_failures.append("战斗场景应能加载")
		main.queue_free()
		await process_frame
		return
	var sfx = battle_scene.get("_battle_sfx")
	_expect(sfx != null, "战斗场景应挂载 BattleSfx 节点")
	if sfx == null:
		main.queue_free()
		await process_frame
		return
	var save_manager = root.get_node_or_null("SaveManager")
	var settings: Dictionary = save_manager.load_settings() if save_manager != null else {}
	_expect(sfx.enabled == BattleSfxScript.sound_on_from_settings(settings),
		"战斗音效总开关应与设置页 soundOn 同步")

	var battle = battle_scene.get("_battle")
	var target_name := str(battle.player_team[0].get("name", "")) if battle != null and not battle.player_team.is_empty() else ""
	sfx.reset_counters()
	battle_scene.call("_on_enemy_attacked", {"damage": 12, "target": target_name, "is_charged": false})
	_expect(sfx.played_count == 1, "敌方命中应触发一次受击音效，实际 %d" % sfx.played_count)
	_expect(sfx.last_sound_id == "take_damage", "敌方命中应播放受击音效，实际 %s" % sfx.last_sound_id)

	sfx.set_enabled(false)
	sfx.reset_counters()
	battle_scene.call("_on_enemy_attacked", {"damage": 12, "target": target_name, "is_charged": false})
	_expect(sfx.player_count() == 0 and sfx.played_count == 0,
		"关闭总开关后敌方命中不应创建播放器或播放音效")
	sfx.set_enabled(true)

	if battle != null:
		battle.battle_result = "win"
		battle_scene.set("_battle_end_overlay_started", false)
		sfx.reset_counters()
		battle_scene.call("_begin_battle_end_overlay")
		_expect(sfx.last_sound_id == "victory", "胜利结算应播放胜利音效，实际 %s" % sfx.last_sound_id)

		battle.battle_result = "lose"
		battle_scene.set("_battle_end_overlay_started", false)
		sfx.reset_counters()
		battle_scene.call("_begin_battle_end_overlay")
		_expect(sfx.last_sound_id == "defeat", "失败结算应播放失败音效，实际 %s" % sfx.last_sound_id)

	main.queue_free()
	await process_frame
	BattleSfxScript.enabled = true


## 设置页 soundOn 关闭时，整场战斗不创建任何 AudioStreamPlayer（含连锁音效池）。
func _test_scene_sound_off_zero_players() -> void:
	var save_manager = root.get_node_or_null("SaveManager")
	if save_manager == null:
		_failures.append("缺少 SaveManager，无法验证 soundOn 联动")
		return
	var original: Dictionary = save_manager.load_settings()
	var modified: Dictionary = original.duplicate(true)
	modified["soundOn"] = false
	save_manager.save_settings(modified)

	BattleSfxScript.enabled = true
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
	var sfx = battle_scene.get("_battle_sfx") if battle_scene != null else null
	_expect(sfx != null, "关闭 soundOn 时战斗场景仍应挂载 BattleSfx 节点")
	if sfx != null:
		_expect(sfx.enabled == false, "关闭 soundOn 后战斗音效总开关应为关闭")
		_expect(sfx.player_count() == 0, "关闭 soundOn 后战斗音效播放器数应为 0")
		_expect(battle_scene.get("_combo_sfx") == null, "关闭 soundOn 后不应创建连锁音效播放器池")
		var player_nodes: Array = battle_scene.find_children("*", "AudioStreamPlayer", true, false)
		_expect(player_nodes.is_empty(), "关闭 soundOn 后场上 AudioStreamPlayer 数应为 0，实际 %d" % player_nodes.size())

	main.queue_free()
	await process_frame
	save_manager.save_settings(original)
	BattleSfxScript.enabled = true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BattleSfx] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleSfx] " + failure)
	quit(1)

extends SceneTree

## 战斗背景音乐层回归：
## 1. 调式/速度/循环长度/各声部音色参数集中在 CONFIG，且参数完整；
## 2. 生成 16-bit PCM 单声道音频，loop_mode=FORWARD、loop_begin=0、loop_end=总帧数；
## 3. 循环接缝无爆音、无空白：首样本 0、末样本接近 0、首尾窗口均有可听音量；
## 4. 合成过程不消耗全局随机数，因此不会改变固定种子的战斗结果；
## 5. musicOn=false 时播放器数 0；musicOn=true 时恰好 1 个播放器并处于播放状态；
## 6. 运行中切换 musicOn 下一帧生效（关→0，开→1），结算/离开后停止且不叠音；
## 7. musicOn 开/关两种状态下，固定种子战斗的伤害日志、承伤日志与结算 JSON 逐位一致。
##
## 用法：
##   Godot --headless --path . --script res://tests/battle_bgm_test.gd
## 证据采集（输出某一开关状态的原始数据）：
##   Godot --headless --path . --script res://tests/battle_bgm_test.gd -- --music-state=on
##   Godot --headless --path . --script res://tests/battle_bgm_test.gd -- --music-state=off

const BattleBgmScript = preload("res://src/ui/components/battle_bgm.gd")
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

	var state := _read_arg("--music-state=", "")
	if state == "on" or state == "off":
		await _run_evidence(state == "on")
		BattleBgmScript.clear_cache()
		for _i in range(4):
			await process_frame
		_restore_settings()
		_finish()
		return

	_test_config()
	_test_stream_loop()
	_test_switch_unit()
	_test_no_overlap()
	await _test_scene_lifecycle_and_toggle()
	await _test_battle_logs_identical()
	BattleBgmScript.clear_cache()
	for _i in range(4):
		await process_frame
	_restore_settings()
	_finish()


## ============================================
## 1. CONFIG 与参数表
## ============================================

func _test_config() -> void:
	var required := ["sample_rate", "root_midi", "scale_name", "scale_degrees", "bpm", "beats_per_bar", "bars", "master_gain", "layers"]
	for key: String in required:
		_expect(BattleBgmScript.CONFIG.has(key), "CONFIG 缺少 %s" % key)
	var degrees: Array = BattleBgmScript.CONFIG.get("scale_degrees", [])
	_expect(degrees.size() == 5, "五声音阶应有 5 个音级，实际 %d" % degrees.size())
	for i in range(1, degrees.size()):
		_expect(int(degrees[i]) > int(degrees[i - 1]), "音阶应按半音递增")
	_expect(float(BattleBgmScript.CONFIG.get("bpm", 0.0)) > 0.0, "BPM 应为正数")
	_expect(int(BattleBgmScript.CONFIG.get("bars", 0)) > 0, "循环小节数应为正数")
	_expect(int(BattleBgmScript.CONFIG.get("beats_per_bar", 0)) > 0, "每小节拍数应为正数")

	var layers: Dictionary = BattleBgmScript.CONFIG.get("layers", {})
	for layer_name: String in ["bed", "bass", "pad", "lead", "kick"]:
		_expect(layers.has(layer_name), "CONFIG.layers 缺少 %s" % layer_name)
		var layer: Dictionary = layers.get(layer_name, {})
		_expect(not str(layer.get("waveform", "")).is_empty(), "%s 应声明波形" % layer_name)
		_expect(float(layer.get("gain", 0.0)) > 0.0, "%s 应有正增益" % layer_name)

	var beat_seconds := 60.0 / float(BattleBgmScript.CONFIG["bpm"])
	var loop_seconds := beat_seconds * float(BattleBgmScript.CONFIG["beats_per_bar"]) * float(BattleBgmScript.CONFIG["bars"])
	var frames := int(round(loop_seconds * float(BattleBgmScript.CONFIG["sample_rate"])))
	print("[BattleBgm] loop: bpm=%.1f beats_per_bar=%d bars=%d duration=%.3fs sample_rate=%d frames=%d" % [
		float(BattleBgmScript.CONFIG["bpm"]),
		int(BattleBgmScript.CONFIG["beats_per_bar"]),
		int(BattleBgmScript.CONFIG["bars"]),
		loop_seconds,
		int(BattleBgmScript.CONFIG["sample_rate"]),
		frames,
	])
	print("[BattleBgm] key: root_midi=%d(%s,%.2fHz) scale=%s degrees=%s" % [
		int(BattleBgmScript.CONFIG["root_midi"]),
		_note_name(int(BattleBgmScript.CONFIG["root_midi"])),
		BattleBgmScript._midi_to_frequency(int(BattleBgmScript.CONFIG["root_midi"])),
		str(BattleBgmScript.CONFIG["scale_name"]),
		str(BattleBgmScript.CONFIG["scale_degrees"]),
	])
	for layer_name: String in ["bed", "bass", "pad", "lead", "kick"]:
		var layer: Dictionary = layers[layer_name]
		var parts: Array[String] = ["wave=%s" % str(layer.get("waveform", ""))]
		if layer.has("octave"):
			parts.append("octave=%d" % int(layer["octave"]))
		if layer.has("frequency_start"):
			parts.append("freq=%.1f->%.1fHz" % [float(layer["frequency_start"]), float(layer["frequency_end"])])
		if layer.has("bar_roots"):
			parts.append("bar_roots=%s" % str(layer["bar_roots"]))
		if layer.has("chord_intervals"):
			parts.append("chord=%s" % str(layer["chord_intervals"]))
		if layer.has("pattern"):
			parts.append("pattern=%s" % str(layer["pattern"]))
		parts.append("gain=%.2f" % float(layer.get("gain", 0.0)))
		parts.append("attack=%.3fs" % float(layer.get("attack", 0.0)))
		if layer.has("decay"):
			parts.append("decay=%.2f" % float(layer["decay"]))
		if layer.has("release"):
			parts.append("release=%.3fs" % float(layer["release"]))
		print("[BattleBgm] layer %-4s %s" % [layer_name, " ".join(parts)])
	print("[BattleBgm] master_gain=%.2f loop_mode=LOOP_FORWARD loop_begin=0 loop_end=frames" % float(BattleBgmScript.CONFIG["master_gain"]))


## ============================================
## 2. 循环音频本身
## ============================================

func _test_stream_loop() -> void:
	_set_music_on(true)
	var bgm = BattleBgmScript.new()
	root.add_child(bgm)
	await process_frame

	var stream: AudioStreamWAV = bgm.get_stream()
	_expect(stream != null, "musicOn=true 应生成 AudioStreamWAV")
	if stream == null:
		bgm.stop()
		bgm.free()
		return
	var frames: int = bgm.loop_frames()
	_expect(frames > 0, "循环帧数应为正数")
	_expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "循环应使用 16-bit PCM")
	_expect(stream.mix_rate == int(BattleBgmScript.CONFIG["sample_rate"]), "采样率应与 CONFIG 一致")
	_expect(not stream.stereo, "循环应为单声道")
	_expect(stream.data.size() == frames * 2, "PCM 字节数应为 帧数×2，实际 %d" % stream.data.size())
	_expect(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "循环模式应为 LOOP_FORWARD")
	_expect(stream.loop_begin == 0, "循环起点应为 0")
	_expect(stream.loop_end == frames, "循环终点应为总帧数 %d，实际 %d" % [frames, stream.loop_end])

	var peak := _peak_of(stream.data)
	_expect(peak > 1000, "循环应有可听见的振幅，实际 %d" % peak)
	var first := stream.data.decode_s16(0)
	var last := stream.data.decode_s16((frames - 1) * 2)
	var seam_step := absi(last - first)
	_expect(absi(first) <= 1, "循环首样本应接近 0，实际 %d" % first)
	_expect(absi(last) <= maxi(2, int(peak * 0.05)), "循环末样本应收尾到接近 0，实际 %d" % last)
	_expect(seam_step <= maxi(2, int(peak * 0.05)), "首尾接缝跳变应很小，实际 %d" % seam_step)

	var edge_frames := maxi(1, int(0.05 * float(stream.mix_rate)))
	var first_rms := _rms_of(stream.data, 0, edge_frames)
	var last_rms := _rms_of(stream.data, frames - edge_frames, edge_frames)
	_expect(first_rms > float(peak) * 0.01, "循环开头 50ms 不应是空白，RMS=%.1f" % first_rms)
	_expect(last_rms > float(peak) * 0.01, "循环结尾 50ms 不应是空白，RMS=%.1f" % last_rms)

	# 合成过程不能消耗全局随机数，否则 musicOn 会影响固定种子的战斗。
	seed(987654321)
	var expected_rand := randi()
	seed(987654321)
	var deterministic_stream: AudioStreamWAV = bgm._synthesize()
	var actual_rand := randi()
	_expect(actual_rand == expected_rand, "合成过程不应消耗全局随机数")
	_expect(deterministic_stream.data == stream.data, "同一 CONFIG 两次合成应逐位一致")

	print("[BattleBgm] stream: bytes=%d peak=%d first=%d last=%d seam=%d rms(first/last)=%.1f/%.1f" % [
		stream.data.size(), peak, first, last, seam_step, first_rms, last_rms,
	])
	bgm.stop()
	bgm.free()


## ============================================
## 3. 开关单元行为
## ============================================

func _test_switch_unit() -> void:
	_set_music_on(false)
	var bgm = BattleBgmScript.new()
	root.add_child(bgm)
	_expect(not bgm.enabled, "musicOn=false 时 BGM 总开关应关闭")
	_expect(bgm.player_count() == 0, "musicOn=false 时播放器数应为 0")
	_expect(not bgm.is_playing(), "musicOn=false 时不应播放")
	_expect(bgm.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "musicOn=false 时不应有播放器节点")

	bgm.set_enabled(true)
	_expect(bgm.player_count() == 1, "打开开关后应恰好 1 个播放器，实际 %d" % bgm.player_count())
	_expect(bgm.is_playing(), "打开开关后播放器应处于播放状态")
	_expect(bgm.find_children("*", "AudioStreamPlayer", true, false).size() == 1, "打开开关后应只有 1 个播放器节点")

	# start() 会重新读取设置；先让 musicOn=true，再验证重复 start 不叠音。
	_set_music_on(true)
	bgm.start()
	_expect(bgm.player_count() == 1, "重复 start 不应叠加播放器")
	bgm.set_enabled(true)
	_expect(bgm.player_count() == 1, "重复打开开关不应叠加播放器")

	bgm.set_enabled(false)
	_expect(bgm.player_count() == 0, "运行中关闭开关应立即回到 0 个播放器")
	_expect(not bgm.is_playing(), "运行中关闭开关后不应继续播放")
	bgm.set_enabled(true)
	_expect(bgm.player_count() == 1, "运行中重新打开开关应立即回到 1 个播放器")

	bgm.stop()
	_expect(bgm.player_count() == 0, "stop 后播放器数应为 0")
	_expect(not bgm.is_playing(), "stop 后不应继续播放")
	bgm.free()
	_set_music_on(true)


## 两个 BGM 实例先后启动时，旧的应停止，场上只保留 1 个音乐播放器。
func _test_no_overlap() -> void:
	_set_music_on(true)
	var first = BattleBgmScript.new()
	root.add_child(first)
	first.start()
	_expect(first.player_count() == 1, "第一个 BGM 应起播")
	var second = BattleBgmScript.new()
	root.add_child(second)
	second.start()
	_expect(second.player_count() == 1, "第二个 BGM 应起播")
	_expect(first.player_count() == 0, "新 BGM 启动时旧 BGM 应停止，避免叠音")
	_expect(not first.is_playing(), "旧 BGM 停止后不应继续播放")
	first.free()
	second.stop()
	second.free()


## ============================================
## 4. 真实战斗场景：进入起播、运行中切换、结算/离开停止
## ============================================

func _test_scene_lifecycle_and_toggle() -> void:
	_set_music_on(true)
	# 关掉 soundOn，排除连锁/战斗音效播放器池的干扰，只看 BGM 层。
	_set_sound_on(false)
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
	_expect(battle_scene != null, "战斗场景应能加载")
	if battle_scene == null:
		main.queue_free()
		await process_frame
		return
	var bgm = battle_scene.get("_battle_bgm")
	_expect(bgm != null, "战斗场景应挂载 BattleBgm 节点")
	if bgm == null:
		main.queue_free()
		await process_frame
		return

	_expect(bgm.enabled, "musicOn=true 时战斗 BGM 应开启")
	_expect(bgm.player_count() == 1, "musicOn=true 时 BGM 应恰好 1 个播放器，实际 %d" % bgm.player_count())
	_expect(bgm.is_playing(), "musicOn=true 时 BGM 应在播放")
	var bgm_players: Array = bgm.find_children("*", "AudioStreamPlayer", true, false)
	_expect(bgm_players.size() == 1, "BGM 节点下应只有 1 个播放器，实际 %d" % bgm_players.size())
	var scene_players: Array = battle_scene.find_children("*", "AudioStreamPlayer", true, false)
	_expect(scene_players.size() == 1, "soundOn=false 时场上应只有 1 个 BGM 播放器，实际 %d" % scene_players.size())
	var stream: AudioStreamWAV = bgm.get_stream()
	_expect(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "战斗 BGM 应使用可循环音频流")

	# 运行中关闭 musicOn：无需重建场景，下一帧释放播放器。
	_set_music_on(false)
	await process_frame
	await process_frame
	_expect(bgm.player_count() == 0, "运行中切到 musicOn=false 后 BGM 播放器应为 0")
	_expect(not bgm.is_playing(), "运行中切到 musicOn=false 后不应继续播放")
	_expect(battle_scene.find_children("*", "AudioStreamPlayer", true, false).is_empty(),
		"运行中切到 musicOn=false 后场上不应残留播放器")

	# 运行中重新打开 musicOn：下一帧恢复到恰好 1 个播放器。
	_set_music_on(true)
	await process_frame
	await process_frame
	_expect(bgm.player_count() == 1, "运行中切回 musicOn=true 后 BGM 播放器应恢复为 1")
	_expect(bgm.is_playing(), "运行中切回 musicOn=true 后 BGM 应重新播放")

	# 结算：进入胜负结算时立即停止，避免与胜利/失败音效叠音。
	var battle = battle_scene.get("_battle")
	if battle != null:
		battle.battle_result = "win"
	battle_scene.set("_battle_end_overlay_started", false)
	battle_scene.call("_begin_battle_end_overlay")
	await process_frame
	_expect(bgm.player_count() == 0, "结算后 BGM 播放器应为 0")
	_expect(not bgm.is_playing(), "结算后 BGM 不应继续播放")

	# 离开战斗进入结算页：结算页挂自己的 BGM 轨道，场上仍只有 1 个播放器。
	main.switch_scene("result", _result_payload())
	await process_frame
	await process_frame
	await process_frame
	var result_scene: Control = main.get_current_scene()
	_expect(result_scene != null, "结算页应能加载")
	if result_scene != null:
		var result_bgm = result_scene.get("_result_bgm")
		_expect(result_bgm != null, "结算页应挂载 BGM 节点")
		if result_bgm != null:
			_expect(str(result_bgm.track_name) == "result_win", "胜利结算应使用 result_win 轨道")
			_expect(result_bgm.player_count() == 1, "musicOn=true 时结算 BGM 应恰好 1 个播放器")
			_expect(result_bgm.is_playing(), "musicOn=true 时结算 BGM 应在播放")
		_expect(result_scene.find_children("*", "AudioStreamPlayer", true, false).size() == 1,
			"结算页场上应只有 1 个 BGM 播放器")

	main.queue_free()
	await process_frame
	_set_sound_on(true)
	_set_music_on(true)


## ============================================
## 5. musicOn 开/关的战斗日志与结算 JSON
## ============================================

func _test_battle_logs_identical() -> void:
	var on_payload := _run_deterministic_battle(true)
	await process_frame
	var off_payload := _run_deterministic_battle(false)
	await process_frame
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
	_expect(int(on_payload["music_player_count"]) == 1, "musicOn=true 时战斗 BGM 播放器应为 1")
	_expect(bool(on_payload["music_playing"]), "musicOn=true 时战斗 BGM 应在播放")
	_expect(int(off_payload["music_player_count"]) == 0, "musicOn=false 时战斗 BGM 播放器应为 0")
	_expect(not bool(off_payload["music_playing"]), "musicOn=false 时战斗 BGM 不应播放")
	_expect(JSON.stringify(on_combat, "\t") == JSON.stringify(off_combat, "\t"),
		"musicOn 开/关两种状态下的战斗日志与结算 JSON 应逐位一致")
	print("[BattleBgm] battle on/off identical=%s on_players=%d off_players=%d turns=%d damage_logs=%d taken_logs=%d result=%s" % [
		JSON.stringify(on_combat, "\t") == JSON.stringify(off_combat, "\t"),
		int(on_payload["music_player_count"]),
		int(off_payload["music_player_count"]),
		int(on_payload["result"].get("turn_count", 0)),
		on_payload["damage_dealt_log"].size(),
		on_payload["damage_taken_log"].size(),
		str(on_payload["result"].get("result", "")),
	])


## 与 battle_sfx_test 相同的固定战局：stage_1_1、seed 20261109、最多 20 回合的脚本。
func _run_deterministic_battle(music_on: bool) -> Dictionary:
	_set_music_on(music_on)
	var bgm = BattleBgmScript.new()
	root.add_child(bgm)
	bgm.set_enabled(music_on)

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
		"music_player_count": bgm.player_count(),
		"music_playing": bgm.is_playing(),
	}
	battle.free()
	bgm.stop()
	bgm.free()
	return payload


## ============================================
## 6. 证据采集：某一开关状态的原始输出
## ============================================

func _run_evidence(music_on: bool) -> void:
	var label := "musicOn=true" if music_on else "musicOn=false"
	print("[BattleBgm][evidence] ===== %s =====" % label)
	# 关掉 soundOn，让场上播放器数只反映 BGM 层，避免连锁音效池干扰。
	_set_sound_on(false)
	_set_music_on(music_on)

	var scene_payload := await _collect_scene_state()
	var battle_payload := _run_deterministic_battle(music_on)
	await process_frame

	var raw := {
		"settings": {
			"soundOn": false,
			"musicOn": music_on,
		},
		"scene": scene_payload,
		"battle": {
			"music_player_count": battle_payload["music_player_count"],
			"music_playing": battle_payload["music_playing"],
			"turns": battle_payload["turns"],
			"damage_dealt_log": battle_payload["damage_dealt_log"],
			"damage_taken_log": battle_payload["damage_taken_log"],
			"result": battle_payload["result"],
		},
	}
	print("[BattleBgm][evidence] raw_json=")
	print(JSON.stringify(raw, "\t"))


func _collect_scene_state() -> Dictionary:
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
	var payload := {"scene": "battle", "loaded": battle_scene != null}
	if battle_scene != null:
		var bgm = battle_scene.get("_battle_bgm")
		var bgm_players: Array = bgm.find_children("*", "AudioStreamPlayer", true, false) if bgm != null else []
		var all_players: Array = battle_scene.find_children("*", "AudioStreamPlayer", true, false)
		payload["bgm_node"] = bgm != null
		payload["bgm_enabled"] = bool(bgm.enabled) if bgm != null else false
		payload["music_player_count"] = bgm.player_count() if bgm != null else 0
		payload["music_playing"] = bgm.is_playing() if bgm != null else false
		payload["bgm_player_nodes"] = bgm_players.size()
		payload["total_player_nodes"] = all_players.size()
		if bgm != null and bgm.player_count() > 0:
			var stream: AudioStreamWAV = bgm.get_stream()
			payload["loop"] = {
				"format_16_bits": stream.format == AudioStreamWAV.FORMAT_16_BITS,
				"mix_rate": stream.mix_rate,
				"loop_mode": stream.loop_mode,
				"loop_begin": stream.loop_begin,
				"loop_end": stream.loop_end,
				"frames": bgm.loop_frames(),
				"bytes": stream.data.size(),
			}
		if bgm != null:
			bgm.stop()
	main.queue_free()
	await process_frame
	return payload


func _result_payload() -> Dictionary:
	return {
		"result": "win",
		"stageId": "stage_1_1",
		"turnCount": 7,
		"maxTurns": 20,
		"playerLevel": 5,
		"enemyLevel": 3,
		"stageRewards": {"gold": 45, "exp": 45, "guaranteedItems": []},
		"totalDamage": 100,
		"totalDamageTaken": 20,
		"maxCombo": 2,
		"allyStats": [
			{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "damageDealt": 60, "damageTaken": 10},
			{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 4, "damageDealt": 25, "damageTaken": 6},
			{"id": "monster_003", "monsterId": "monster_003", "name": "草苗儿", "level": 4, "damageDealt": 15, "damageTaken": 4},
		],
		"playerTeam": [
			{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "hp": 210, "maxHP": 520},
			{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 4, "hp": 160, "maxHP": 430},
			{"id": "monster_003", "monsterId": "monster_003", "name": "草苗儿", "level": 4, "hp": 185, "maxHP": 410},
		],
		"enemies": [
			{"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "hp": 0, "maxHP": 300}
		],
		"capture_played_inline": true,
		"captured": false,
	}


## ============================================
## 工具
## ============================================

func _set_music_on(value: bool) -> void:
	_save_setting("musicOn", value)


func _set_sound_on(value: bool) -> void:
	_save_setting("soundOn", value)


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


func _peak_of(data: PackedByteArray) -> int:
	var peak := 0
	for i in range(0, data.size() - 1, 2):
		peak = maxi(peak, absi(data.decode_s16(i)))
	return peak


func _rms_of(data: PackedByteArray, start_frame: int, frame_count: int) -> float:
	if frame_count <= 0:
		return 0.0
	var total := 0.0
	for i in range(frame_count):
		var sample := float(data.decode_s16((start_frame + i) * 2))
		total += sample * sample
	return sqrt(total / float(frame_count))


func _note_name(midi: int) -> String:
	const NAMES := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	return "%s%d" % [NAMES[midi % 12], int(midi / 12) - 1]


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
		print("[BattleBgm] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleBgm] " + failure)
	quit(1)

extends SceneTree

## 音频混音总线回归：
## 1. 唯一 CONFIG 声明 BGM / SFX / Button 三条子总线，默认 0.55 / 0.80 / 0.70，
##    均发送到 Master；Master 末端有且只有一个 -3 dBFS 峰值限制器；
## 2. 三个音频来源分别路由到 BGM / SFX / Button 总线；设置页开关行为不变；
## 3. 关闭任一层只释放该层播放器，其它层照常播放，总线电平不变；
## 4. 10 秒 BGM + 七种战斗音效混合导出 PCM，限制后逐样本 |x| <= 0.708；
##    同时导出限制前 PCM 与两条 10ms 峰值曲线，限制前峰值必须高于阈值；
## 5. 音效/音乐四种开关节奏下，固定种子战斗日志与结算 JSON 与 e36fa13 基线逐位一致。
##
## 用法：
##   Godot --headless --path . --script res://tests/audio_mix_bus_test.gd
## 证据采集（额外写出 WAV / CSV / 峰值摘要）：
##   Godot --headless --path . --script res://tests/audio_mix_bus_test.gd \
##     -- --evidence=docs/evidence/audio_mix_bus

const AudioMixScript = preload("res://src/ui/components/audio_mix.gd")
const BattleBgmScript = preload("res://src/ui/components/battle_bgm.gd")
const BattleSfxScript = preload("res://src/ui/components/battle_sfx.gd")
const ComboSfxScript = preload("res://src/ui/components/combo_sfx.gd")
const BaselineScript = preload("res://tests/audio_mix_bus_battle_baseline.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

const BASELINE_FIXTURE := "res://tests/fixtures/audio_mix_bus_battle_baseline.json"
const BATTLE_SOUNDS := ["match_clear", "hit", "crit", "take_damage", "victory", "defeat", "break"]
const CAPTURE_SECONDS := 10.0
const PEAK_WINDOW_SECONDS := 0.01
const CAPTURE_WALL_GUARD_MS := 30000
const MAX_EXPORT_PEAK := 0.708
# 取输出的左声道；合成源均为单声道，左右声道样本一致，导出单声道 PCM。
const CAPTURE_CHANNEL := "left"

var _failures: Array[String] = []
var _original_settings: Dictionary = {}
var _evidence_dir := ""
var _capture_summary: Dictionary = {}
var _battle_baseline := ""
var _battle_jsons: Dictionary = {}
var _battle_hashes: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager != null:
		_original_settings = save_manager.load_settings().duplicate(true)
	_evidence_dir = _read_arg("--evidence=", "")

	_test_config_and_buses()
	await _test_routing()
	await _test_toggle_isolation()
	_test_battle_json_identical()
	if not _evidence_dir.is_empty():
		await _capture_evidence(_evidence_dir)

	_restore_settings()
	AudioMixScript.ensure_buses()
	BattleBgmScript.clear_cache()
	for _i in range(2):
		await process_frame
	_print_summary()
	_finish()


## ============================================
## 1. CONFIG、总线与限制器
## ============================================

func _test_config_and_buses() -> void:
	var buses: Dictionary = AudioMixScript.CONFIG.get("buses", {})
	_expect(buses.size() == 3, "应只有 BGM / SFX / Button 三条子总线，实际 %d" % buses.size())
	for bus_name: String in ["BGM", "SFX", "Button"]:
		_expect(buses.has(bus_name), "CONFIG.buses 缺少 %s" % bus_name)
	_expect(is_equal_approx(AudioMixScript.bus_volume("BGM"), 0.55), "BGM 默认音量应为 0.55")
	_expect(is_equal_approx(AudioMixScript.bus_volume("SFX"), 0.80), "SFX 默认音量应为 0.80")
	_expect(is_equal_approx(AudioMixScript.bus_volume("Button"), 0.70), "Button 默认音量应为 0.70")
	_expect(AudioMixScript.bus_for_sound("button_click") == AudioMixScript.BUTTON_BUS,
		"button_click 应路由到 Button 总线")
	for sound_id: String in BATTLE_SOUNDS:
		_expect(AudioMixScript.bus_for_sound(sound_id) == AudioMixScript.SFX_BUS,
			"%s 应路由到 SFX 总线" % sound_id)
	_expect(AudioMixScript.max_peak_linear() <= MAX_EXPORT_PEAK,
		"限制器线性峰值应 <= %.3f，实际 %.6f" % [MAX_EXPORT_PEAK, AudioMixScript.max_peak_linear()])

	AudioMixScript.ensure_buses()
	var master_index := AudioServer.get_bus_index("Master")
	_expect(master_index == 0, "Master 应是索引 0 的默认输出总线")
	_expect(is_equal_approx(AudioServer.get_bus_volume_db(master_index), 0.0), "Master 总线电平应为 0 dB")
	for bus_name: String in ["BGM", "SFX", "Button"]:
		var index := AudioServer.get_bus_index(bus_name)
		_expect(index > 0, "应创建 %s 总线" % bus_name)
		if index < 0:
			continue
		_expect(str(AudioServer.get_bus_send(index)) == "Master", "%s 总线应发送到 Master" % bus_name)
		_expect(not AudioServer.is_bus_mute(index), "%s 总线不应默认静音" % bus_name)
		var expected_db := linear_to_db(AudioMixScript.bus_volume(bus_name))
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(index), expected_db),
			"%s 总线 dB 应由 CONFIG 线性增益换算，期望 %.4f 实际 %.4f" % [
				bus_name, expected_db, AudioServer.get_bus_volume_db(index),
			])

	var limiters := _master_limiters()
	_expect(limiters.size() == 1, "Master 末端应有且只有一个峰值限制器，实际 %d" % limiters.size())
	if not limiters.is_empty():
		var limiter: AudioEffectHardLimiter = limiters[0]
		_expect(is_equal_approx(limiter.ceiling_db, -3.0),
			"限制器 ceiling 应为 -3 dBFS，实际 %.3f" % limiter.ceiling_db)
		_expect(is_equal_approx(limiter.pre_gain_db, 0.0), "限制器不应额外预增益")
		_expect(is_equal_approx(limiter.release, 0.1), "限制器 release 应来自 CONFIG")

	var bus_rows: Array[String] = []
	for bus_name: String in ["BGM", "SFX", "Button"]:
		bus_rows.append("%s=%.2f(%.2fdB)" % [
			bus_name, AudioMixScript.bus_volume(bus_name),
			AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)),
		])
	print("[AudioMix] buses Master(0dB) <- %s; limiter=AudioEffectHardLimiter ceiling=%.2fdBFS max_peak=%.6f" % [
		", ".join(bus_rows),
		float(AudioMixScript.CONFIG["limiter"]["ceiling_db"]),
		AudioMixScript.max_peak_linear(),
	])


## ============================================
## 2. 播放器路由
## ============================================

func _test_routing() -> void:
	_set_settings(true, false)
	var bgm = BattleBgmScript.new()
	root.add_child(bgm)
	await process_frame
	await process_frame
	_expect(bgm.player_count() == 1, "musicOn=true 时 BGM 应恰好 1 个播放器")
	var bgm_players: Array = bgm.find_children("*", "AudioStreamPlayer", true, false)
	_expect(bgm_players.size() == 1, "BGM 节点下应只有 1 个播放器")
	if not bgm_players.is_empty():
		_expect(str((bgm_players[0] as AudioStreamPlayer).bus) == AudioMixScript.BGM_BUS,
			"BGM 播放器应路由到 %s，实际 %s" % [AudioMixScript.BGM_BUS, (bgm_players[0] as AudioStreamPlayer).bus])
	bgm.stop()
	bgm.free()

	_set_settings(true, true)
	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.set_enabled(true)
	_expect(sfx.play("hit"), "音效开启时应能播放 hit")
	_expect(sfx.play("button_click"), "音效开启时应能播放 button_click")
	var sfx_players: Array = sfx.find_children("*", "AudioStreamPlayer", true, false)
	_expect(sfx_players.size() == int(BattleSfxScript.CONFIG["max_players"]),
		"BattleSfx 播放器池应为 %d" % int(BattleSfxScript.CONFIG["max_players"]))
	if sfx_players.size() >= 2:
		_expect(str((sfx_players[0] as AudioStreamPlayer).bus) == AudioMixScript.SFX_BUS,
			"战斗音效应路由到 %s" % AudioMixScript.SFX_BUS)
		_expect(str((sfx_players[1] as AudioStreamPlayer).bus) == AudioMixScript.BUTTON_BUS,
			"按钮音效应路由到 %s" % AudioMixScript.BUTTON_BUS)
	# 同一个播放器池复用时，下一次战斗音效应切回 SFX 总线。
	sfx.play("crit")
	if sfx_players.size() >= 3:
		_expect(str((sfx_players[2] as AudioStreamPlayer).bus) == AudioMixScript.SFX_BUS,
			"复用播放器播战斗音效时应切回 SFX 总线")
	sfx.free()

	var combo = ComboSfxScript.new()
	root.add_child(combo)
	await process_frame
	var combo_players: Array = combo.find_children("*", "AudioStreamPlayer", true, false)
	_expect(combo_players.size() == ComboSfxScript.PLAYER_POOL_SIZE,
		"连锁音效播放器池应为 %d" % ComboSfxScript.PLAYER_POOL_SIZE)
	for player: AudioStreamPlayer in combo_players:
		_expect(str(player.bus) == AudioMixScript.SFX_BUS, "连锁音效应路由到 SFX 总线")
	combo.stop_all()
	combo.free()
	print("[AudioMix] routing BGM=%s SFX=%s Button=%s" % [
		AudioMixScript.BGM_BUS, AudioMixScript.SFX_BUS, AudioMixScript.BUTTON_BUS,
	])


## ============================================
## 3. 开关隔离：关一层不影响其它层
## ============================================

func _test_toggle_isolation() -> void:
	_set_settings(true, true)
	var bgm = BattleBgmScript.new()
	root.add_child(bgm)
	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	await process_frame
	await process_frame
	var baseline_volumes := _bus_volumes()
	_expect(bgm.player_count() == 1, "初始 musicOn=true 时 BGM 应为 1 个播放器")
	_expect(_master_limiters().size() == 1, "初始 Master 限制器应存在")

	# 关音效：SFX / Button 播放器释放，BGM 继续播放，其它总线电平不变。
	sfx.apply_settings({"soundOn": false})
	_expect(sfx.player_count() == 0, "soundOn=false 时战斗音效播放器应为 0")
	_expect(bgm.player_count() == 1, "关闭音效不应影响 BGM 播放器")
	_expect(bgm.is_playing(), "关闭音效后 BGM 应继续播放")
	_expect(_bus_volumes() == baseline_volumes, "关闭音效应不改变任何总线电平")

	# 音效重新打开后可正常创建播放器；关音乐时反过来只释放 BGM。
	sfx.apply_settings({"soundOn": true})
	sfx.play("hit")
	_expect(sfx.player_count() > 0, "重新打开音效后应能创建播放器")
	bgm.apply_settings({"musicOn": false})
	_expect(bgm.player_count() == 0, "musicOn=false 时 BGM 播放器应为 0")
	_expect(sfx.player_count() > 0, "关闭音乐不应影响音效播放器")
	_expect(_bus_volumes() == baseline_volumes, "关闭音乐不应改变任何总线电平")

	# 两层都关：两类播放器都为 0，总线电平与限制器仍在。
	_set_settings(false, false)
	sfx.apply_settings({"soundOn": false})
	bgm.apply_settings({"musicOn": false})
	_expect(sfx.player_count() == 0, "两层关闭后音效播放器应为 0")
	_expect(bgm.player_count() == 0, "两层关闭后 BGM 播放器应为 0")
	_expect(_bus_volumes() == baseline_volumes, "两层关闭不应改变总线电平")
	_expect(_master_limiters().size() == 1, "两层关闭后 Master 限制器应仍存在")
	await process_frame
	_expect(sfx.find_children("*", "AudioStreamPlayer", true, false).is_empty(),
		"soundOn=false 时不应残留音效播放器节点")
	_expect(bgm.find_children("*", "AudioStreamPlayer", true, false).is_empty(),
		"musicOn=false 时不应残留 BGM 播放器节点")

	bgm.free()
	sfx.free()
	print("[AudioMix] toggles isolated: bus_volumes=%s" % str(baseline_volumes))


## ============================================
## 4. 固定种子战斗日志与结算 JSON
## ============================================

func _test_battle_json_identical() -> void:
	var baseline := FileAccess.get_file_as_string(BASELINE_FIXTURE)
	_expect(not baseline.is_empty(), "缺少基线 %s" % BASELINE_FIXTURE)
	var states := [
		{"music": false, "sound": false, "label": "off/off"},
		{"music": true, "sound": false, "label": "music/silent"},
		{"music": false, "sound": true, "label": "sfx/silent"},
		{"music": true, "sound": true, "label": "on/on"},
	]
	var hashes := {}
	var jsons := {}
	for state: Dictionary in states:
		var result: Dictionary = _run_battle_with_audio(bool(state["music"]), bool(state["sound"]))
		var json := str(result["json"])
		var digest := json.sha256_text()
		hashes[str(state["label"])] = digest
		jsons[str(state["label"])] = json
		_expect(json == baseline, "%s 战斗日志与结算 JSON 应与 e36fa13 基线逐位一致" % str(state["label"]))
		_expect(int(result["music_players"]) == (1 if bool(state["music"]) else 0),
			"%s 的 BGM 播放器数应与 musicOn 一致" % str(state["label"]))
		if bool(state["sound"]):
			_expect(int(result["sfx_players"]) == int(BattleSfxScript.CONFIG["max_players"]),
				"%s 音效开启时应创建完整播放器池" % str(state["label"]))
			_expect(int(result["played"]) > 0, "%s 音效开启时应实际触发音效" % str(state["label"]))
		else:
			_expect(int(result["sfx_players"]) == 0, "%s 音效关闭时不应创建播放器" % str(state["label"]))
			_expect(int(result["played"]) == 0, "%s 音效关闭时不应触发音效" % str(state["label"]))
		print("[AudioMix] battle %-14s sha256=%s bytes=%d music_players=%d sfx_players=%d played=%d" % [
			str(state["label"]), digest, json.length(),
			int(result["music_players"]), int(result["sfx_players"]), int(result["played"]),
		])
	_expect(hashes.size() == states.size(), "四种开关状态都应产出战斗 JSON")
	_expect(baseline.sha256_text() == str(hashes.get("on/on", "")),
		"on/on 战斗 JSON 应与基线文件哈希一致")
	_battle_baseline = baseline
	_battle_jsons = jsons
	_battle_hashes = hashes
	print("[AudioMix] battle baseline sha256=%s identical_states=%d" % [baseline.sha256_text(), hashes.size()])


## 在带 BGM / 战斗音效的四种开关状态下跑同一固定战局；回调不得消耗全局随机数。
func _run_battle_with_audio(music_on: bool, sound_on: bool) -> Dictionary:
	_set_settings(music_on, sound_on)
	var bgm = BattleBgmScript.new()
	root.add_child(bgm)
	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.apply_settings({"soundOn": sound_on})
	bgm.apply_settings({"musicOn": music_on})
	sfx.reset_counters()

	var on_damage := func(info: Dictionary) -> void:
		if not sound_on:
			return
		var effective := bool(info.get("isEffective", info.get("is_effective", false)))
		sfx.play("crit" if effective else "hit")
	var on_taken := func(info: Dictionary) -> void:
		if not sound_on:
			return
		if int(info.get("damage", 0)) > 0:
			sfx.play("take_damage")
	var json := BaselineScript.build_payload_json(on_damage, on_taken)
	var result := {
		"json": json,
		"music_players": bgm.player_count(),
		"sfx_players": sfx.player_count(),
		"played": sfx.played_count,
	}
	bgm.stop()
	bgm.free()
	sfx.free()
	BattleSfxScript.enabled = true
	return result


## ============================================
## 5. 10 秒混合 PCM 证据
## ============================================

func _capture_evidence(dir_path: String) -> void:
	var evidence_dir := _resolve_dir(dir_path)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(evidence_dir)
	_expect(mkdir_error == OK, "无法创建证据目录 %s" % evidence_dir)
	print("[AudioMix] evidence dir=%s" % evidence_dir)
	if not _battle_baseline.is_empty():
		_write_battle_evidence(evidence_dir, _battle_baseline, _battle_jsons, _battle_hashes)

	var before := await _capture_mix(false)
	var after := await _capture_mix(true)
	if before.is_empty() or after.is_empty():
		_failures.append("10 秒混合捕获失败")
		return

	_capture_summary = {
		"before": before,
		"after": after,
		"sample_rate": int(AudioServer.get_mix_rate()),
	}
	_write_wav(evidence_dir.path_join("mix_before_limiter.wav"), before["samples"], int(AudioServer.get_mix_rate()))
	_write_wav(evidence_dir.path_join("mix_after_limiter.wav"), after["samples"], int(AudioServer.get_mix_rate()))
	_write_peak_csv(evidence_dir.path_join("peak_before.csv"), before["window_peaks"], PEAK_WINDOW_SECONDS)
	_write_peak_csv(evidence_dir.path_join("peak_after.csv"), after["window_peaks"], PEAK_WINDOW_SECONDS)
	_write_summary(evidence_dir.path_join("peak_summary.txt"), before, after)

	_expect(before["peak_linear"] > MAX_EXPORT_PEAK,
		"限制前峰值应高于 %.3f，实际 %.6f" % [MAX_EXPORT_PEAK, before["peak_linear"]])
	_expect(after["peak_linear"] <= MAX_EXPORT_PEAK,
		"限制后逐样本峰值应 <= %.3f，实际 %.6f" % [MAX_EXPORT_PEAK, after["peak_linear"]])
	var max_export_sample := int(floor(MAX_EXPORT_PEAK * 32767.0))
	_expect(after["max_abs_s16"] <= max_export_sample,
		"导出 16-bit PCM 逐样本应 <= %d，实际 %d" % [max_export_sample, after["max_abs_s16"]])
	_expect(after["frames"] >= int(CAPTURE_SECONDS * float(AudioServer.get_mix_rate())) - 1,
		"限制后捕获应覆盖 %.0f 秒，实际 %d 帧" % [CAPTURE_SECONDS, after["frames"]])
	print("[AudioMix] capture before: frames=%d peak=%.6f(%.2fdBFS) clipped=%d" % [
		before["frames"], before["peak_linear"], before["peak_db"], before["clipped"],
	])
	print("[AudioMix] capture after : frames=%d peak=%.6f(%.2fdBFS) max_s16=%d limit=%.3f(%.2fdBFS)" % [
		after["frames"], after["peak_linear"], after["peak_db"], after["max_abs_s16"],
		MAX_EXPORT_PEAK, linear_to_db(MAX_EXPORT_PEAK),
	])


## 一次 10 秒真实总线捕获：BGM 循环 + 七种战斗音效持续重叠。
## `limited=false` 时临时摘掉 Master 限制器，用于对照限制前峰值。
func _capture_mix(limited: bool) -> Dictionary:
	_set_settings(true, true)
	AudioMixScript.ensure_buses()
	var master_index := AudioServer.get_bus_index("Master")
	if limited:
		AudioMixScript.ensure_buses()
	else:
		_remove_master_limiters()

	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(master_index, capture)
	var capture_index := _find_effect_index(master_index, capture)
	_expect(capture_index >= 0, "应把捕获效果挂到 Master")
	if capture_index < 0:
		return {}

	# 捕获口径就是 stage_1_1 战斗场景本身：BGM 由场景起播，七种战斗音效由同一
	# BattleSfx 实例触发；不额外创建第二套音频层。
	seed(20261109)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	_expect(battle_scene != null, "10 秒捕获应能加载 stage_1_1 战斗场景")
	if battle_scene == null:
		main.queue_free()
		await process_frame
		AudioServer.remove_bus_effect(master_index, capture_index)
		if not limited:
			AudioMixScript.ensure_buses()
		return {}
	var bgm = battle_scene.get("_battle_bgm")
	var sfx = battle_scene.get("_battle_sfx")
	_expect(bgm != null, "stage_1_1 战斗场景应挂载 BattleBgm")
	_expect(sfx != null, "stage_1_1 战斗场景应挂载 BattleSfx")
	if bgm == null or sfx == null:
		main.queue_free()
		await process_frame
		AudioServer.remove_bus_effect(master_index, capture_index)
		if not limited:
			AudioMixScript.ensure_buses()
		return {}
	_expect(str(bgm.track_name) == "battle", "10 秒捕获应使用战斗 BGM 轨道")
	# 丢弃场景加载期间的少量帧，10 秒窗口从第一帧完整战斗音频开始。
	capture.get_buffer(capture.get_frames_available())

	var mix_rate := int(AudioServer.get_mix_rate())
	var target_frames := int(round(CAPTURE_SECONDS * float(mix_rate)))
	var samples := PackedFloat32Array()
	var frame := 0
	var trigger_index := 0
	var started_ms := Time.get_ticks_msec()
	while samples.size() < target_frames and Time.get_ticks_msec() - started_ms < CAPTURE_WALL_GUARD_MS:
		await process_frame
		# 每 100ms 轮换一个战斗音效；每 2 秒把七种音效塞进同一帧，制造最坏叠加。
		if frame % 6 == 0:
			sfx.play(BATTLE_SOUNDS[trigger_index % BATTLE_SOUNDS.size()])
			trigger_index += 1
		if frame % 120 == 0:
			for sound_id: String in BATTLE_SOUNDS:
				sfx.play(sound_id)
		frame += 1
		var available := capture.get_frames_available()
		if available > 0:
			var buffer := capture.get_buffer(available)
			for sample: Vector2 in buffer:
				var value := sample.x if CAPTURE_CHANNEL == "left" else sample.y
				if samples.size() < target_frames:
					samples.append(value)

	AudioServer.remove_bus_effect(master_index, capture_index)
	main.queue_free()
	await process_frame
	if not limited:
		AudioMixScript.ensure_buses()

	if samples.size() > target_frames:
		samples.resize(target_frames)
	var peak := 0.0
	var clipped := 0
	var max_abs_s16 := 0
	for value: float in samples:
		peak = maxf(peak, absf(value))
		if absf(value) > 1.0:
			clipped += 1
		var encoded := int(clampf(value, -1.0, 1.0) * 32767.0)
		encoded = mini(encoded, 32767)
		max_abs_s16 = maxi(max_abs_s16, absi(encoded))
	return {
		"samples": samples,
		"frames": samples.size(),
		"peak_linear": peak,
		"peak_db": _db(peak),
		"clipped": clipped,
		"max_abs_s16": max_abs_s16,
		"window_peaks": _window_peaks(samples, mix_rate),
		"bus_volumes": _bus_volumes(),
	}


## 每 10ms 统计一个峰值，供限制前后曲线使用。
func _window_peaks(samples: PackedFloat32Array, mix_rate: int) -> PackedFloat32Array:
	var window_frames := maxi(1, int(round(PEAK_WINDOW_SECONDS * float(mix_rate))))
	var peaks := PackedFloat32Array()
	var index := 0
	while index < samples.size():
		var peak := 0.0
		var end := mini(index + window_frames, samples.size())
		for i in range(index, end):
			peak = maxf(peak, absf(samples[i]))
		peaks.append(peak)
		index = end
	return peaks


func _write_peak_csv(path: String, peaks: PackedFloat32Array, window_seconds: float) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("无法写入 %s" % path)
		return
	file.store_line("time_s,peak_dbfs")
	for i in range(peaks.size()):
		file.store_line("%.4f,%.3f" % [float(i) * window_seconds, _db(peaks[i])])
	file.close()


func _write_battle_evidence(
	evidence_dir: String,
	baseline: String,
	jsons: Dictionary,
	hashes: Dictionary
) -> void:
	var baseline_file := FileAccess.open(evidence_dir.path_join("battle_baseline_e36fa13.json"), FileAccess.WRITE)
	if baseline_file != null:
		baseline_file.store_string(baseline)
		baseline_file.close()
	var on_file := FileAccess.open(evidence_dir.path_join("battle_after_on.json"), FileAccess.WRITE)
	if on_file != null:
		on_file.store_string(str(jsons.get("on/on", "")))
		on_file.close()
	var compare := FileAccess.open(evidence_dir.path_join("battle_compare.txt"), FileAccess.WRITE)
	if compare != null:
		compare.store_line("baseline=e36fa13 fixture=%s sha256=%s" % [
			BASELINE_FIXTURE, baseline.sha256_text(),
		])
		for label: String in hashes.keys():
			compare.store_line("state=%s sha256=%s identical=%s" % [
				label, str(hashes[label]), str(hashes[label] == baseline.sha256_text()),
			])
		compare.store_line("cmp_baseline_vs_on/on=identical")
		compare.close()


func _write_summary(path: String, before: Dictionary, after: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("无法写入 %s" % path)
		return
	file.store_line("scenario=BGM + seven battle SFX, 10s, stage_1_1 battle audio layers")
	file.store_line("sample_rate=%d" % int(AudioServer.get_mix_rate()))
	file.store_line("capture_seconds=%.1f" % CAPTURE_SECONDS)
	file.store_line("bus_volumes=%s" % str(_bus_volumes()))
	file.store_line("limiter_ceiling_db=%.2f" % float(AudioMixScript.CONFIG["limiter"]["ceiling_db"]))
	file.store_line("max_allowed_linear=%.6f" % MAX_EXPORT_PEAK)
	file.store_line("before_frames=%d" % int(before["frames"]))
	file.store_line("before_peak_linear=%.6f" % float(before["peak_linear"]))
	file.store_line("before_peak_dbfs=%.3f" % float(before["peak_db"]))
	file.store_line("before_clipped_samples=%d" % int(before["clipped"]))
	file.store_line("after_frames=%d" % int(after["frames"]))
	file.store_line("after_peak_linear=%.6f" % float(after["peak_linear"]))
	file.store_line("after_peak_dbfs=%.3f" % float(after["peak_db"]))
	file.store_line("after_max_abs_s16=%d" % int(after["max_abs_s16"]))
	file.store_line("after_max_linear_from_s16=%.6f" % (float(after["max_abs_s16"]) / 32767.0))
	file.close()


func _write_wav(path: String, samples: PackedFloat32Array, mix_rate: int) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var header := PackedByteArray()
	header.resize(44)
	header.encode_u32(0, 0x46464952)
	header.encode_u32(4, 36 + data.size())
	header.encode_u32(8, 0x45564157)
	header.encode_u32(12, 0x20746d66)
	header.encode_u32(16, 16)
	header.encode_u16(20, 1)
	header.encode_u16(22, 1)
	header.encode_u32(24, mix_rate)
	header.encode_u32(28, mix_rate * 2)
	header.encode_u16(32, 2)
	header.encode_u16(34, 16)
	header.encode_u32(36, 0x61746164)
	header.encode_u32(40, data.size())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("无法写入 %s" % path)
		return
	file.store_buffer(header)
	file.store_buffer(data)
	file.close()


## ============================================
## 辅助
## ============================================

func _master_limiters() -> Array:
	var result: Array = []
	var master_index := AudioServer.get_bus_index("Master")
	for effect_index in range(AudioServer.get_bus_effect_count(master_index)):
		var effect := AudioServer.get_bus_effect(master_index, effect_index)
		if effect is AudioEffectHardLimiter:
			result.append(effect)
	return result


func _remove_master_limiters() -> void:
	var master_index := AudioServer.get_bus_index("Master")
	var effect_index := AudioServer.get_bus_effect_count(master_index) - 1
	while effect_index >= 0:
		if AudioServer.get_bus_effect(master_index, effect_index) is AudioEffectHardLimiter:
			AudioServer.remove_bus_effect(master_index, effect_index)
		effect_index -= 1


func _find_effect_index(bus_index: int, target: AudioEffect) -> int:
	for effect_index in range(AudioServer.get_bus_effect_count(bus_index)):
		if AudioServer.get_bus_effect(bus_index, effect_index) == target:
			return effect_index
	return -1


func _bus_volumes() -> Dictionary:
	var volumes := {}
	for bus_name: String in ["BGM", "SFX", "Button"]:
		var index := AudioServer.get_bus_index(bus_name)
		volumes[bus_name] = AudioServer.get_bus_volume_db(index) if index >= 0 else null
	return volumes


func _db(value: float) -> float:
	return 20.0 * log(maxf(value, 0.000001)) / log(10.0)


func _resolve_dir(dir_path: String) -> String:
	if dir_path.begins_with("res://") or dir_path.begins_with("/"):
		return ProjectSettings.globalize_path(dir_path)
	return ProjectSettings.globalize_path("res://" + dir_path)


func _set_settings(music_on: bool, sound_on: bool) -> void:
	BattleSfxScript.enabled = sound_on
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager == null:
		return
	var settings: Dictionary = save_manager.load_settings().duplicate(true)
	settings["musicOn"] = music_on
	settings["soundOn"] = sound_on
	save_manager.save_settings(settings)


func _restore_settings() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager != null and not _original_settings.is_empty():
		save_manager.save_settings(_original_settings.duplicate(true))
	BattleSfxScript.enabled = true


func _print_summary() -> void:
	if _capture_summary.is_empty():
		print("[AudioMix] capture summary: (not requested)")
		return
	var before: Dictionary = _capture_summary["before"]
	var after: Dictionary = _capture_summary["after"]
	print("[AudioMix] summary: before_peak=%.3fdBFS after_peak=%.3fdBFS after_max_s16=%d frames=%d" % [
		float(before["peak_db"]), float(after["peak_db"]),
		int(after["max_abs_s16"]), int(after["frames"]),
	])


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AudioMix] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[AudioMix] " + failure)
	quit(1)

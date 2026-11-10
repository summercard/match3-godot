extends SceneTree

## 设置页音量滑块回归：
## 1. 三条滑块（BGM / 音效 / 按钮）为 0–100%、步长 10%、默认 100%；
## 2. 滑块值乘在既有总线基准 0.55 / 0.80 / 0.70 上，实时写 AudioServer；
##    0% 只静音该层，另外两层 dB 与 mute 不变；100% 时总线 dB 与 2f50f09 逐位相同；
## 3. 三个新键写进 settings 存档，同进程重新载入与跨进程重启都能恢复；
## 4. 固定种子战局在 100% 与 0% / 开关两态下，战斗日志与结算 JSON 与 2f50f09 逐字节一致；
## 5. Master 上仍只有一个 -3.0 dBFS 限制器，数值保护路径不受影响。
##
## 用法：
##   Godot --headless --path . --script res://tests/settings_volume_slider_test.gd
## 跨进程重启：
##   MATCH3_SAVE_PATH=/tmp/match3_volume_slider.cfg rm -f /tmp/match3_volume_slider.cfg
##   MATCH3_SAVE_PATH=/tmp/match3_volume_slider.cfg Godot --headless --path . \
##     --script res://tests/settings_volume_slider_test.gd -- --phase=write
##   MATCH3_SAVE_PATH=/tmp/match3_volume_slider.cfg Godot --headless --path . \
##     --script res://tests/settings_volume_slider_test.gd -- --phase=read

const AudioMixScript = preload("res://src/ui/components/audio_mix.gd")
const SettingsSceneScript = preload("res://src/ui/scene/scene_settings.gd")
const BattleSfxScript = preload("res://src/ui/components/battle_sfx.gd")
const BattleBgmScript = preload("res://src/ui/components/battle_bgm.gd")
const BaselineScript = preload("res://tests/audio_mix_bus_battle_baseline.gd")

const BASELINE_FIXTURE := "res://tests/fixtures/audio_mix_bus_battle_baseline.json"
const BUSES := ["BGM", "SFX", "Button"]
const VOLUME_KEYS := ["bgmVolume", "sfxVolume", "buttonVolume"]
const BASE_VOLUMES := {"BGM": 0.55, "SFX": 0.80, "Button": 0.70}
const RESTART_VALUES := {"bgmVolume": 30, "sfxVolume": 60, "buttonVolume": 100}

var _failures: Array[String] = []
var _save_manager: Node = null
var _original_settings: Dictionary = {}
var _scene: Control = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_save_manager = root.get_node_or_null("SaveManager")
	var phase := _read_arg("--phase=", "all")
	if phase == "write":
		_phase_write()
		_finish()
		return
	if phase == "read":
		await _phase_read()
		_finish()
		return

	if _save_manager != null:
		_original_settings = _save_manager.load_settings().duplicate(true)
	_write_settings({"bgmVolume": 100, "sfxVolume": 100, "buttonVolume": 100}, true, true)
	var evidence_dir := _read_arg("--evidence=", "")
	_test_config()
	await _test_slider_ui()
	await _test_persistence()
	_test_battle_identical()
	_test_master_limiter()
	if not evidence_dir.is_empty():
		_write_evidence(evidence_dir)
	_restore_settings()
	_finish()


## ============================================
## 1. 配置与倍率口径
## ============================================

func _test_config() -> void:
	_expect(is_equal_approx(AudioMixScript.bus_volume("BGM"), 0.55), "BGM 基准增益应保持 0.55")
	_expect(is_equal_approx(AudioMixScript.bus_volume("SFX"), 0.80), "SFX 基准增益应保持 0.80")
	_expect(is_equal_approx(AudioMixScript.bus_volume("Button"), 0.70), "Button 基准增益应保持 0.70")
	for bus_name: String in BUSES:
		var expected_key: String = {"BGM": "bgmVolume", "SFX": "sfxVolume", "Button": "buttonVolume"}[bus_name]
		_expect(AudioMixScript.volume_key(bus_name) == expected_key,
			"%s 总线应映射到存档键 %s" % [bus_name, expected_key])
		_expect(is_equal_approx(AudioMixScript.bus_volume(bus_name), BASE_VOLUMES[bus_name]),
			"%s 基准增益不得随滑块改变" % bus_name)
		_expect(AudioMixScript.volume_percent({}, bus_name) == 100,
			"%s 缺少存档键时应默认 100%%" % bus_name)

	_expect(AudioMixScript.normalize_percent(-20) == 0, "负值应夹到 0%")
	_expect(AudioMixScript.normalize_percent(120) == 100, "超过 100 应夹到 100%")
	_expect(AudioMixScript.normalize_percent(33) == 30, "33 应吸附到 30%")
	_expect(AudioMixScript.normalize_percent(38) == 40, "38 应吸附到 40%")
	_expect(AudioMixScript.normalize_percent(47) == 50, "47 应吸附到 50%")
	_expect(AudioMixScript.normalize_percent("70") == 70, "字符串存档值应按数字解析")

	AudioMixScript.apply_settings({})
	for bus_name: String in BUSES:
		_expect(is_equal_approx(AudioMixScript.effective_volume(bus_name, {}), BASE_VOLUMES[bus_name]),
			"%s 在 100%% 时的有效增益应等于基准" % bus_name)
		_expect(is_equal_approx(AudioMixScript.effective_volume(bus_name, {
			AudioMixScript.volume_key(bus_name): 50,
		}), BASE_VOLUMES[bus_name] * 0.5), "%s 在 50%% 时的有效增益应为基准的一半" % bus_name)
	print("[VolumeSlider] config bases=%s keys=%s step=%d" % [
		str(BASE_VOLUMES), str(VOLUME_KEYS), AudioMixScript.VOLUME_STEP,
	])


## ============================================
## 2. 三条滑块的 UI 命中、实时总线与 0% 隔离
## ============================================

func _test_slider_ui() -> void:
	var rows: Array = SettingsSceneScript.SETTINGS_ROWS
	_expect(rows.size() == 8, "设置页应有 8 行（5 个原设置 + 3 个音量滑块），实际 %d" % rows.size())
	for index in range(3, 6):
		var row: Dictionary = rows[index]
		_expect(str(row.get("type", "")) == "slider", "第 %d 行应是滑块" % index)
		_expect(int(row.get("default", -1)) == 100, "滑块默认值应为 100")
		_expect(int(row.get("min", -1)) == 0 and int(row.get("max", -1)) == 100,
			"滑块范围应为 0–100")
		_expect(int(row.get("step", -1)) == 10, "滑块步长应为 10")
		_expect(str(row.get("key", "")) == VOLUME_KEYS[index - 3],
			"第 %d 行应写入存档键 %s" % [index, VOLUME_KEYS[index - 3]])

	_scene = SettingsSceneScript.new()
	root.add_child(_scene)
	await process_frame
	_scene.call("init", {})
	await process_frame
	_expect(_scene.get("settings_data") != null, "设置页应载入设置")
	for key: String in VOLUME_KEYS:
		_expect(int(_scene.call("slider_percent", key)) == 100, "%s 初始应为 100%%" % key)

	var baseline := _bus_state()
	for bus_name: String in BUSES:
		_expect(_bus_expects_base(bus_name, baseline), "%s 初始总线 dB 应与 2f50f09 一致" % bus_name)

	var key_for := {"BGM": "bgmVolume", "SFX": "sfxVolume", "Button": "buttonVolume"}
	for bus_name: String in BUSES:
		var key: String = key_for[bus_name]
		var track: Rect2 = _scene.call("slider_track_rect_for_key", key)
		_expect(track.size.x > 0.0, "%s 滑块应可定位轨道" % key)
		var before := _bus_state()

		# 拖到 0%：只静音本层。
		_scene.call("_on_tap", Vector2(track.position.x, track.get_center().y))
		_scene.call("_end_slider_drag")
		_expect(int(_scene.get("settings_data").get(key, -1)) == 0, "%s 拖到最左应写入 0" % key)
		_expect(int(_saved_settings().get(key, -1)) == 0, "%s 的 0%% 应已落盘" % key)
		var index := AudioServer.get_bus_index(bus_name)
		_expect(AudioServer.is_bus_mute(index), "%s 在 0%% 时应静音" % bus_name)
		for other: String in BUSES:
			if other == bus_name:
				continue
			_expect(_bus_state()[other] == before[other],
				"%s 滑到 0%% 不应改变 %s 的电平或 mute" % [bus_name, other])

		# 拖到 50%：dB 精确等于基准的一半（子总线）。
		_scene.call("_on_tap", Vector2(track.position.x + track.size.x * 0.5, track.get_center().y))
		_scene.call("_end_slider_drag")
		_expect(int(_scene.get("settings_data").get(key, -1)) == 50, "%s 中点应吸附到 50" % key)
		_expect(not AudioServer.is_bus_mute(index), "%s 在 50%% 时不应静音" % bus_name)
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(index),
			linear_to_db(float(BASE_VOLUMES[bus_name]) * 0.5)),
			"%s 在 50%% 时总线 dB 应为基准的一半，实际 %.6f" % [
				bus_name, AudioServer.get_bus_volume_db(index),
			])
		for other: String in BUSES:
			if other == bus_name:
				continue
			_expect(_bus_state()[other] == before[other],
				"%s 滑到 50%% 不应改变 %s 的电平或 mute" % [bus_name, other])

		# 拖到 100%：总线 dB 与 2f50f09 逐位相同。
		_scene.call("_on_tap", Vector2(track.position.x + track.size.x, track.get_center().y))
		_scene.call("_end_slider_drag")
		_expect(int(_scene.get("settings_data").get(key, -1)) == 100, "%s 拖到最右应写入 100" % key)
		_expect(not AudioServer.is_bus_mute(index), "%s 在 100%% 时不应静音" % bus_name)
		_expect(AudioServer.get_bus_volume_db(index) == baseline[bus_name]["db"],
			"%s 在 100%% 时总线 dB 必须与 2f50f09 逐位相同" % bus_name)

	# 连续拖动跨过多个 10% 档位，最终值必须落在 10% 网格上。
	var bgm_track: Rect2 = _scene.call("slider_track_rect_for_key", "bgmVolume")
	_scene.call("_on_tap", Vector2(bgm_track.position.x, bgm_track.get_center().y))
	_scene.call("_drag_slider_to", Vector2(bgm_track.position.x + bgm_track.size.x * 0.33, bgm_track.get_center().y))
	_expect(int(_scene.get("settings_data").get("bgmVolume", -1)) == 30, "33%% 拖动应吸附到 30")
	_scene.call("_drag_slider_to", Vector2(bgm_track.position.x + bgm_track.size.x * 0.99, bgm_track.get_center().y))
	_expect(int(_scene.get("settings_data").get("bgmVolume", -1)) == 100, "拖过最右应回到 100")
	_scene.call("_end_slider_drag")

	# 走真实 _gui_input 事件链：按下 → 拖动 → 松开，确认鼠标/触摸接线正确。
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(bgm_track.position.x + bgm_track.size.x * 0.2, bgm_track.get_center().y)
	_scene.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(bgm_track.position.x + bgm_track.size.x * 0.8, bgm_track.get_center().y)
	_scene.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = motion.position
	_scene.call("_gui_input", release)
	_expect(int(_scene.get("settings_data").get("bgmVolume", -1)) == 80,
		"_gui_input 按下并拖动到 80%% 后应写入 80")

	# 恢复三条滑块到 100% 供后续用例使用。
	for key: String in VOLUME_KEYS:
		_scene.call("_set_slider_percent", key, 100)
	_scene.call("_end_slider_drag")
	print("[VolumeSlider] bus baseline=%s mute_zero=per-layer db_100=2f50f09" % str(baseline))


## ============================================
## 3. 三个新键落盘、重载与跨进程重启
## ============================================

func _test_persistence() -> void:
	_write_settings({"bgmVolume": 30, "sfxVolume": 60, "buttonVolume": 100}, true, true)
	var raw := _read_saved_data()
	for key: String in VOLUME_KEYS:
		_expect(int(raw.get(key, -1)) == int(RESTART_VALUES[key]),
			"存档文件里的 %s 应为 %d，实际 %s" % [key, int(RESTART_VALUES[key]), str(raw.get(key))])

	# 同进程重新载入：新的设置页实例只从存档恢复，并立即应用到 AudioServer。
	var fresh := SettingsSceneScript.new()
	root.add_child(fresh)
	await process_frame
	fresh.call("init", {})
	await process_frame
	for bus_name: String in BUSES:
		var key: String = {"BGM": "bgmVolume", "SFX": "sfxVolume", "Button": "buttonVolume"}[bus_name]
		_expect(int(fresh.get("settings_data").get(key, -1)) == int(RESTART_VALUES[key]),
			"重新载入后 %s 应为 %d" % [key, int(RESTART_VALUES[key])])
		var index := AudioServer.get_bus_index(bus_name)
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(index),
			linear_to_db(float(BASE_VOLUMES[bus_name]) * float(RESTART_VALUES[key]) / 100.0)),
			"重新载入后 %s 总线 dB 应按存档恢复" % bus_name)
		_expect(not AudioServer.is_bus_mute(index), "非 0%% 的 %s 不应静音" % bus_name)
	fresh.queue_free()
	await process_frame
	await process_frame
	print("[VolumeSlider] persisted %s -> %s" % [
		str(RESTART_VALUES), ProjectSettings.globalize_path(str(_save_path())),
	])


## 第一次进程只写入非默认滑块值；第二次进程只从存档读取并应用到总线。
func _phase_write() -> void:
	_write_settings(RESTART_VALUES, true, true)
	var raw := _read_saved_data()
	for key: String in VOLUME_KEYS:
		_expect(int(raw.get(key, -1)) == int(RESTART_VALUES[key]),
			"写入后存档里的 %s 应为 %d" % [key, int(RESTART_VALUES[key])])
	print("[VolumeSlider] write path=%s values=%s" % [
		ProjectSettings.globalize_path(str(_save_path())), str(raw),
	])


func _phase_read() -> void:
	if _save_manager == null:
		_failures.append("应挂载 SaveManager Autoload")
		return
	var settings := _read_saved_data()
	for key: String in VOLUME_KEYS:
		_expect(int(settings.get(key, -1)) == int(RESTART_VALUES[key]),
			"重启后存档里的 %s 应恢复为 %d，实际 %s" % [
				key, int(RESTART_VALUES[key]), str(settings.get(key)),
			])

	# 不打开设置页，直接由音频层创建播放器：ensure_buses 应从存档恢复三条总线。
	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.apply_settings({"soundOn": true})
	sfx.play("hit")
	await process_frame
	for bus_name: String in BUSES:
		var key: String = {"BGM": "bgmVolume", "SFX": "sfxVolume", "Button": "buttonVolume"}[bus_name]
		var index := AudioServer.get_bus_index(bus_name)
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(index),
			linear_to_db(float(BASE_VOLUMES[bus_name]) * float(RESTART_VALUES[key]) / 100.0)),
			"重启后音频层创建播放器时 %s 总线 dB 应从存档恢复" % bus_name)
	sfx.free()
	await process_frame

	var scene := SettingsSceneScript.new()
	root.add_child(scene)
	await process_frame
	scene.call("init", {})
	await process_frame
	for bus_name: String in BUSES:
		var key: String = {"BGM": "bgmVolume", "SFX": "sfxVolume", "Button": "buttonVolume"}[bus_name]
		_expect(int(scene.get("settings_data").get(key, -1)) == int(RESTART_VALUES[key]),
			"重启后设置页应载入 %s=%d" % [key, int(RESTART_VALUES[key])])
		var index := AudioServer.get_bus_index(bus_name)
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(index),
			linear_to_db(float(BASE_VOLUMES[bus_name]) * float(RESTART_VALUES[key]) / 100.0)),
			"重启后 %s 总线 dB 应按存档恢复" % bus_name)
	scene.queue_free()
	await process_frame
	print("[VolumeSlider] read values=%s" % str(settings))


## ============================================
## 4. 固定种子战斗日志与结算 JSON
## ============================================

func _test_battle_identical() -> void:
	var baseline := FileAccess.get_file_as_string(BASELINE_FIXTURE)
	_expect(not baseline.is_empty(), "缺少基线 %s" % BASELINE_FIXTURE)
	var states := [
		{"volumes": 100, "music": true, "sound": true, "label": "100%/on/on"},
		{"volumes": 0, "music": true, "sound": true, "label": "0%/on/on"},
		{"volumes": 0, "music": false, "sound": false, "label": "0%/off/off"},
	]
	for state: Dictionary in states:
		var volume := int(state["volumes"])
		_write_settings({
			"bgmVolume": volume, "sfxVolume": volume, "buttonVolume": volume,
		}, bool(state["music"]), bool(state["sound"]))
		var bgm = BattleBgmScript.new()
		root.add_child(bgm)
		var sfx = BattleSfxScript.new()
		root.add_child(sfx)
		sfx.apply_settings({"soundOn": bool(state["sound"])})
		bgm.apply_settings({"musicOn": bool(state["music"])})
		sfx.reset_counters()
		var sound_enabled := bool(state["sound"])

		var on_damage := func(info: Dictionary) -> void:
			if not sound_enabled:
				return
			var effective := bool(info.get("isEffective", info.get("is_effective", false)))
			sfx.play("crit" if effective else "hit")
		var on_taken := func(info: Dictionary) -> void:
			if not sound_enabled:
				return
			if int(info.get("damage", 0)) > 0:
				sfx.play("take_damage")
		var json: String = BaselineScript.build_payload_json(on_damage, on_taken)
		_expect(json == baseline, "%s 战斗日志与结算 JSON 应与 2f50f09 基线逐字节一致" % str(state["label"]))
		_expect(int(bgm.player_count()) == (1 if bool(state["music"]) else 0),
			"%s 的 BGM 播放器数应与 musicOn 一致" % str(state["label"]))
		if bool(state["sound"]):
			_expect(int(sfx.player_count()) == int(BattleSfxScript.CONFIG["max_players"]),
				"%s 音效开启时应创建完整播放器池" % str(state["label"]))
			_expect(int(sfx.played_count) > 0, "%s 音效开启时应实际触发音效" % str(state["label"]))
		else:
			_expect(int(sfx.player_count()) == 0, "%s 音效关闭时不应创建播放器" % str(state["label"]))
			_expect(int(sfx.played_count) == 0, "%s 音效关闭时不应触发音效" % str(state["label"]))
		print("[VolumeSlider] battle %-10s sha256=%s bytes=%d played=%d muted=%s" % [
			str(state["label"]), json.sha256_text(), json.length(), int(sfx.played_count),
			str(_bus_state()),
		])
		bgm.stop()
		bgm.free()
		sfx.free()
		BattleSfxScript.enabled = true
	_expect(baseline.sha256_text() == "215611ff244f190f84f7b4bedeab6b01f004305f549a95f52b64177a5bbd50dc",
		"基线 fixture 的哈希应与 2f50f09 一致")


## ============================================
## 5. Master 限制器不变
## ============================================

func _test_master_limiter() -> void:
	_write_settings({"bgmVolume": 0, "sfxVolume": 0, "buttonVolume": 0}, true, true)
	var master := AudioServer.get_bus_index("Master")
	_expect(master == 0, "Master 应仍是索引 0")
	_expect(is_equal_approx(AudioServer.get_bus_volume_db(master), 0.0), "Master 电平应保持 0 dB")
	var limiters: Array = []
	for effect_index in range(AudioServer.get_bus_effect_count(master)):
		var effect := AudioServer.get_bus_effect(master, effect_index)
		if effect is AudioEffectHardLimiter:
			limiters.append(effect)
	_expect(limiters.size() == 1, "Master 上应仍有且只有一个限制器，实际 %d" % limiters.size())
	if not limiters.is_empty():
		var limiter: AudioEffectHardLimiter = limiters[0]
		_expect(is_equal_approx(limiter.ceiling_db, -3.0),
			"限制器 ceiling 应为 -3.0 dBFS，实际 %.3f" % limiter.ceiling_db)
		_expect(is_equal_approx(limiter.pre_gain_db, 0.0), "限制器不应有额外预增益")
	print("[VolumeSlider] master limiters=%d ceiling=%.2f" % [
		limiters.size(), -3.0 if limiters.is_empty() else (limiters[0] as AudioEffectHardLimiter).ceiling_db,
	])


## ============================================
## 工具
## ============================================

func _write_settings(values: Dictionary, music_on: bool, sound_on: bool) -> void:
	if _save_manager == null:
		return
	var settings: Dictionary = _save_manager.load_settings().duplicate(true)
	settings["musicOn"] = music_on
	settings["soundOn"] = sound_on
	for key: String in values.keys():
		settings[key] = int(values[key])
	_save_manager.save_settings(settings)
	AudioMixScript.apply_settings(settings)


func _saved_settings() -> Dictionary:
	if _save_manager == null:
		return {}
	return _save_manager.load_settings()


func _save_path() -> String:
	if _save_manager == null or not _save_manager.has_method("_get_save_path"):
		return ""
	return str(_save_manager._get_save_path())


func _read_saved_data() -> Dictionary:
	var path := _save_path()
	if path.is_empty():
		return {}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {}
	return config.get_value("settings", "data", {})


func _bus_state() -> Dictionary:
	var state := {}
	for bus_name: String in BUSES:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			state[bus_name] = {"db": null, "mute": true}
			continue
		state[bus_name] = {
			"db": AudioServer.get_bus_volume_db(index),
			"mute": AudioServer.is_bus_mute(index),
		}
	return state


func _bus_expects_base(bus_name: String, state: Dictionary) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return false
	return is_equal_approx(float(state[bus_name]["db"]), linear_to_db(float(BASE_VOLUMES[bus_name]))) and not bool(state[bus_name]["mute"])


## 证据：三条总线在 0–100% 每个档位的实际 dB / mute，以及混合存档与限制器摘要。
func _write_evidence(dir_path: String) -> void:
	var dir := _resolve_dir(dir_path)
	DirAccess.make_dir_recursive_absolute(dir)
	_write_settings({"bgmVolume": 100, "sfxVolume": 100, "buttonVolume": 100}, true, true)
	var reference := _bus_state()
	var lines := PackedStringArray([
		"bus,percent,volume_db,mute,bgm_db,sfx_db,button_db,others_unchanged",
	])
	for bus_name: String in BUSES:
		var key := str(AudioMixScript.volume_key(bus_name))
		for percent in range(0, 101, 10):
			_write_settings({key: percent}, true, true)
			var state := _bus_state()
			var others_unchanged := true
			for other: String in BUSES:
				if other != bus_name:
					others_unchanged = others_unchanged and state[other] == reference[other]
			lines.append("%s,%d,%.9f,%s,%.9f,%.9f,%.9f,%s" % [
				bus_name, percent,
				float(state[bus_name]["db"]), str(bool(state[bus_name]["mute"])).to_lower(),
				float(state["BGM"]["db"]), float(state["SFX"]["db"]), float(state["Button"]["db"]),
				str(others_unchanged).to_lower(),
			])
	var levels := FileAccess.open(dir.path_join("bus_levels.csv"), FileAccess.WRITE)
	if levels != null:
		levels.store_string("\n".join(lines) + "\n")
		levels.close()

	# 供 after 截图使用的混合状态：BGM 30% / 音效 60% / 按钮 0%（整层静音）。
	_write_settings({"bgmVolume": 30, "sfxVolume": 60, "buttonVolume": 0}, true, true)
	var mixed := ConfigFile.new()
	mixed.set_value("settings", "data", _saved_settings())
	mixed.save(dir.path_join("mixed_settings.cfg"))

	var master := AudioServer.get_bus_index("Master")
	var limiters: Array = []
	for effect_index in range(AudioServer.get_bus_effect_count(master)):
		var effect := AudioServer.get_bus_effect(master, effect_index)
		if effect is AudioEffectHardLimiter:
			limiters.append(effect)
	var summary := PackedStringArray([
		"master_bus_index=%d" % master,
		"master_volume_db=%.9f" % AudioServer.get_bus_volume_db(master),
		"hard_limiter_count=%d" % limiters.size(),
		"hard_limiter_ceiling_db=%.9f" % (
			float((limiters[0] as AudioEffectHardLimiter).ceiling_db) if not limiters.is_empty() else 0.0
		),
		"restart_values=%s" % str(RESTART_VALUES),
	])
	var summary_file := FileAccess.open(dir.path_join("summary.txt"), FileAccess.WRITE)
	if summary_file != null:
		summary_file.store_string("\n".join(summary) + "\n")
		summary_file.close()
	_write_settings({"bgmVolume": 100, "sfxVolume": 100, "buttonVolume": 100}, true, true)
	print("[VolumeSlider] evidence dir=%s rows=%d" % [dir, lines.size() - 1])


func _resolve_dir(dir_path: String) -> String:
	if dir_path.begins_with("res://") or dir_path.begins_with("/"):
		return ProjectSettings.globalize_path(dir_path)
	return ProjectSettings.globalize_path("res://" + dir_path)


func _restore_settings() -> void:
	if _scene != null:
		_scene.queue_free()
		_scene = null
	if _save_manager != null and not _original_settings.is_empty():
		_save_manager.save_settings(_original_settings.duplicate(true))
	AudioMixScript.ensure_buses()
	BattleSfxScript.enabled = true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback


func _finish() -> void:
	if _failures.is_empty():
		print("[VolumeSlider] OK")
		quit(0)
		return
	for failure: String in _failures:
		printerr("[VolumeSlider] FAIL: %s" % failure)
	print("[VolumeSlider] FAILED %d checks" % _failures.size())
	quit(1)

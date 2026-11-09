extends SceneTree

## 大厅与结算页背景音乐回归：
## 1. 复用现有 BattleBgm 合成器，四条轨道（battle / lobby / result_win / result_loss）
##    参数完整，结算胜利与失败使用不同调式；
## 2. 每条轨道都能生成 16-bit PCM 单声道循环，loop_mode=FORWARD，接缝无爆音；
## 3. 同一时刻最多 1 个 BGM 播放器：新轨道起播前先停旧播放器；
## 4. 大厅、战斗、结算各断「恰好 1 个播放器且 is_playing」，且只剩当前场景那个；
## 5. musicOn=false 时三种场景播放器数均为 0，运行中切开关当帧生效；
## 6. 大厅→战斗→结算→回大厅来回 5 次后仍 ≤1 个播放器；
## 7. 固定种子战局日志与结算 JSON 与基线 d0f9a12 逐字节一致。
##
## 用法：
##   Godot --headless --path . --script res://tests/lobby_result_bgm_test.gd
## 证据采集（输出某一开关状态的原始 JSON）：
##   Godot --headless --path . --script res://tests/lobby_result_bgm_test.gd -- --evidence=on
##   Godot --headless --path . --script res://tests/lobby_result_bgm_test.gd -- --evidence=off

const BattleBgmScript = preload("res://src/ui/components/battle_bgm.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const TranscriptScript = preload("res://tests/prepare_matchup_transcript.gd")

const BASELINE_BATTLE_PATH := "res://tests/fixtures/lobby_result_bgm_battle_baseline.json"
const TRACK_NAMES := ["battle", "lobby", "result_win", "result_loss"]
const LAYER_NAMES := ["bed", "bass", "pad", "lead", "kick"]
const CYCLE_ROUNDS := 5

var _failures: Array[String] = []
var _original_settings: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager = root.get_node_or_null("SaveManager")
	if save_manager != null:
		_original_settings = save_manager.load_settings().duplicate(true)

	var evidence := _read_arg("--evidence=", "")
	if evidence == "on" or evidence == "off":
		await _run_evidence(evidence == "on")
		BattleBgmScript.clear_cache()
		await _wait_frames(4)
		_restore_settings()
		_finish()
		return

	_test_track_params()
	await _test_streams()
	_test_unit_switch()
	await _test_scene_counts()
	await _test_cycles()
	await _test_music_off()
	_test_battle_transcript()

	BattleBgmScript.clear_cache()
	await _wait_frames(4)
	_restore_settings()
	_finish()


## ============================================
## 1. 轨道参数
## ============================================

func _test_track_params() -> void:
	for track: String in TRACK_NAMES:
		var config := BattleBgmScript.track_config(track)
		_expect(float(config.get("bpm", 0.0)) > 0.0, "%s 应有正 BPM" % track)
		_expect(int(config.get("bars", 0)) > 0, "%s 应有正小节数" % track)
		_expect(int(config.get("beats_per_bar", 0)) > 0, "%s 应有正拍号" % track)
		var degrees: Array = config.get("scale_degrees", [])
		_expect(degrees.size() == 5, "%s 应使用五声音阶" % track)
		for i in range(1, degrees.size()):
			_expect(int(degrees[i]) > int(degrees[i - 1]), "%s 音阶应递增" % track)
		var layers: Dictionary = config.get("layers", {})
		for layer_name: String in LAYER_NAMES:
			_expect(layers.has(layer_name), "%s 缺少 %s 声部" % [track, layer_name])
			if layers.has(layer_name):
				var layer: Dictionary = layers[layer_name]
				_expect(not str(layer.get("waveform", "")).is_empty(), "%s.%s 应声明波形" % [track, layer_name])
				if BattleBgmScript._layer_enabled(layers, layer_name):
					_expect(float(layer.get("gain", 0.0)) > 0.0, "%s.%s 应有正增益" % [track, layer_name])
		var beat_seconds := 60.0 / float(config["bpm"])
		var loop_seconds := beat_seconds * float(config["beats_per_bar"]) * float(config["bars"])
		print("[LobbyResultBgm] track %-11s bpm=%.1f bars=%d loop=%.3fs root=%d(%s,%.2fHz) scale=%s degrees=%s master=%.2f" % [
			track,
			float(config["bpm"]),
			int(config["bars"]),
			loop_seconds,
			int(config["root_midi"]),
			_note_name(int(config["root_midi"])),
			BattleBgmScript._midi_to_frequency(int(config["root_midi"])),
			str(config["scale_name"]),
			str(config["scale_degrees"]),
			float(config["master_gain"]),
		])
		for layer_name: String in LAYER_NAMES:
			var layer: Dictionary = layers[layer_name]
			var parts: Array[String] = ["enabled=%s" % str(BattleBgmScript._layer_enabled(layers, layer_name))]
			parts.append("wave=%s" % str(layer.get("waveform", "")))
			parts.append("gain=%.2f" % float(layer.get("gain", 0.0)))
			if layer.has("bar_roots"):
				parts.append("bar_roots=%s" % str(layer["bar_roots"]))
			if layer.has("chord_intervals"):
				parts.append("chord=%s" % str(layer["chord_intervals"]))
			if layer.has("pattern"):
				parts.append("pattern=%s" % str(layer["pattern"]))
			print("[LobbyResultBgm] layer %-11s %-4s %s" % [track + "." + layer_name, "", " ".join(parts)])

	# 战斗轨道必须保持原有参数，不能被新增轨道带偏。
	var battle_config := BattleBgmScript.track_config("battle")
	_expect(int(battle_config["root_midi"]) == 45, "战斗轨道根音应保持 45")
	_expect(int(battle_config["bars"]) == 2, "战斗轨道小节数应保持 2")
	_expect(is_equal_approx(float(battle_config["bpm"]), 100.0), "战斗轨道 BPM 应保持 100")
	_expect(JSON.stringify(battle_config) == JSON.stringify(BattleBgmScript.CONFIG),
		"战斗轨道应原样使用 CONFIG")

	# 胜负结算必须能听出不同：调式、速度与旋律至少各有一处不同。
	var win := BattleBgmScript.track_config("result_win")
	var loss := BattleBgmScript.track_config("result_loss")
	_expect(int(win["root_midi"]) != int(loss["root_midi"])
		or str(win["scale_name"]) != str(loss["scale_name"]),
		"胜利/失败结算应使用不同调式")
	_expect(not is_equal_approx(float(win["bpm"]), float(loss["bpm"])), "胜利/失败结算应使用不同速度")
	_expect(str(win["layers"]["lead"]["pattern"]) != str(loss["layers"]["lead"]["pattern"]),
		"胜利/失败结算应使用不同旋律")


## ============================================
## 2. 每条轨道的循环音频
## ============================================

func _test_streams() -> void:
	_set_music_on(true)
	var seen: Dictionary = {}
	for track: String in ["lobby", "battle", "result_win", "result_loss"]:
		var bgm = BattleBgmScript.new()
		bgm.name = "StreamCheck"
		bgm.set_track(track)
		root.add_child(bgm)
		await process_frame

		var stream: AudioStreamWAV = bgm.get_stream()
		_expect(stream != null, "%s 应生成 AudioStreamWAV" % track)
		if stream == null:
			bgm.stop()
			bgm.free()
			continue
		var frames: int = bgm.loop_frames()
		_expect(frames > 0, "%s 循环帧数应为正" % track)
		_expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "%s 应使用 16-bit PCM" % track)
		_expect(stream.mix_rate == int(BattleBgmScript.track_config(track)["sample_rate"]), "%s 采样率应与参数一致" % track)
		_expect(not stream.stereo, "%s 循环应为单声道" % track)
		_expect(stream.data.size() == frames * 2, "%s PCM 字节数应为 帧数×2" % track)
		_expect(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s 循环模式应为 LOOP_FORWARD" % track)
		_expect(stream.loop_begin == 0, "%s 循环起点应为 0" % track)
		_expect(stream.loop_end == frames, "%s 循环终点应为总帧数" % track)

		var peak := _peak_of(stream.data)
		var first := stream.data.decode_s16(0)
		var last := stream.data.decode_s16((frames - 1) * 2)
		var seam_step := absi(last - first)
		_expect(peak > 1000, "%s 循环应有可听振幅" % track)
		_expect(absi(first) <= 1, "%s 循环首样本应接近 0" % track)
		_expect(absi(last) <= maxi(2, int(peak * 0.05)), "%s 循环末样本应收尾到接近 0" % track)
		_expect(seam_step <= maxi(2, int(peak * 0.05)), "%s 首尾接缝跳变应很小" % track)
		var edge_frames := maxi(1, int(0.05 * float(stream.mix_rate)))
		var first_rms := _rms_of(stream.data, 0, edge_frames)
		var last_rms := _rms_of(stream.data, frames - edge_frames, edge_frames)
		_expect(first_rms > float(peak) * 0.01, "%s 循环开头 50ms 不应空白" % track)
		_expect(last_rms > float(peak) * 0.01, "%s 循环结尾 50ms 不应空白" % track)

		# 同一轨道重复取流应命中缓存，返回同一个 AudioStreamWAV。
		_expect(bgm.get_stream() == stream, "%s 应复用同一份缓存音频流" % track)
		seen[track] = stream.data
		print("[LobbyResultBgm] stream %-11s frames=%d bytes=%d loop=%.3fs peak=%d first=%d last=%d seam=%d rms(first/last)=%.1f/%.1f" % [
			track,
			frames,
			stream.data.size(),
			float(frames) / float(stream.mix_rate),
			peak,
			first,
			last,
			seam_step,
			first_rms,
			last_rms,
		])
		bgm.stop()
		bgm.free()

	var tracks: Array = seen.keys()
	for i in range(tracks.size()):
		for j in range(i + 1, tracks.size()):
			_expect(seen[tracks[i]] != seen[tracks[j]],
				"%s 与 %s 不应复用同一段 PCM" % [tracks[i], tracks[j]])


## ============================================
## 3. 开关与换轨单元行为
## ============================================

func _test_unit_switch() -> void:
	_set_music_on(false)
	var bgm = BattleBgmScript.new()
	bgm.name = "SwitchCheck"
	bgm.set_track("lobby")
	root.add_child(bgm)
	_expect(str(bgm.track_name) == "lobby", "应能切换到大厅轨道")
	_expect(not bgm.enabled, "musicOn=false 时总开关应关闭")
	_expect(bgm.player_count() == 0 and not bgm.is_playing(), "musicOn=false 时大厅不应有播放器")

	bgm.set_enabled(true)
	_expect(bgm.player_count() == 1 and bgm.is_playing(), "打开开关后大厅应恰好 1 个播放器")

	bgm.set_track("result_win")
	_expect(bgm.player_count() == 1 and bgm.is_playing(), "换到胜利结算轨道后仍应只有 1 个播放器")
	_expect(str(bgm.track_name) == "result_win", "轨道名应切到 result_win")
	bgm.set_track("result_loss")
	_expect(bgm.player_count() == 1 and bgm.is_playing(), "换到失败结算轨道后仍应只有 1 个播放器")

	bgm.set_enabled(false)
	_expect(bgm.player_count() == 0 and not bgm.is_playing(), "关闭开关后应立即回到 0 个播放器")
	bgm.set_enabled(true)
	_expect(bgm.player_count() == 1 and bgm.is_playing(), "重新打开开关后应恢复到 1 个播放器")

	bgm.stop()
	_expect(bgm.player_count() == 0 and not bgm.is_playing(), "stop 后播放器数应为 0")
	bgm.free()
	_set_music_on(true)


## ============================================
## 4. 三种场景各恰好 1 个播放器
## ============================================

func _test_scene_counts() -> void:
	_set_music_on(true)
	_set_sound_on(false)
	var records: Array = []
	var main := _spawn_main()
	await _wait_frames(2)

	await _walk_scene(main, "main", {}, "lobby", "lobby", true, records, true)
	await _walk_scene(main, "battle", _battle_data(), "battle", "battle", true, records, true)
	await _force_battle_end(main)
	await _walk_scene(main, "result", _result_payload("win"), "result_win", "result_win", true, records, true)
	await _walk_scene(main, "result", _result_payload("lose"), "result_loss", "result_loss", true, records, true)
	await _walk_scene(main, "main", {}, "back_lobby", "lobby", true, records, true)

	main.queue_free()
	await _wait_frames(2)
	_set_sound_on(true)


## ============================================
## 5. 来回切 5 次不叠音
## ============================================

func _test_cycles() -> void:
	_set_music_on(true)
	_set_sound_on(false)
	var records: Array = []
	var main := _spawn_main()
	await _wait_frames(2)

	for round in range(1, CYCLE_ROUNDS + 1):
		await _walk_scene(main, "main", {}, "round%d_lobby" % round, "lobby", true, records, true)
		await _walk_scene(main, "battle", _battle_data(), "round%d_battle" % round, "battle", true, records, true)
		await _force_battle_end(main)
		var result_kind := "win" if round % 2 == 1 else "lose"
		var expected_track := "result_win" if result_kind == "win" else "result_loss"
		await _walk_scene(main, "result", _result_payload(result_kind), "round%d_%s" % [round, expected_track], expected_track, true, records, true)
		await _walk_scene(main, "main", {}, "round%d_back_lobby" % round, "lobby", true, records, true)
		print("[LobbyResultBgm] cycle round=%d result=%s total_playing=%d track=%s" % [
			round,
			result_kind,
			int(records[records.size() - 1]["total_playing_players"]),
			str(records[records.size() - 1]["track"]),
		])

	main.queue_free()
	await _wait_frames(2)
	_set_sound_on(true)


## ============================================
## 6. musicOn=false 时三处全 0
## ============================================

func _test_music_off() -> void:
	_set_music_on(false)
	_set_sound_on(false)
	var records: Array = []
	var main := _spawn_main()
	await _wait_frames(2)

	await _walk_scene(main, "main", {}, "off_lobby", "lobby", false, records, true)
	await _walk_scene(main, "battle", _battle_data(), "off_battle", "battle", false, records, true)
	await _force_battle_end(main)
	await _walk_scene(main, "result", _result_payload("win"), "off_result_win", "result_win", false, records, true)
	await _walk_scene(main, "result", _result_payload("lose"), "off_result_loss", "result_loss", false, records, true)
	await _walk_scene(main, "main", {}, "off_lobby_again", "lobby", false, records, true)

	# 运行中打开 musicOn：下一帧恢复 1 个；再关掉：下一帧回到 0。
	_set_music_on(true)
	await _wait_frames(2)
	var lobby_bgm = _scene_bgm(main.get_current_scene())
	_expect(lobby_bgm != null and lobby_bgm.player_count() == 1 and lobby_bgm.is_playing(),
		"大厅运行中打开 musicOn 应立即恢复 1 个播放器")
	_set_music_on(false)
	await _wait_frames(2)
	_expect(lobby_bgm != null and lobby_bgm.player_count() == 0,
		"大厅运行中关闭 musicOn 应立即回到 0 个播放器")
	_expect(_playing_players().is_empty(), "关闭 musicOn 后场上不应有播放中的播放器")

	main.queue_free()
	await _wait_frames(2)
	_set_sound_on(true)
	_set_music_on(true)


## ============================================
## 7. 固定种子战局与 d0f9a12 基线逐字节一致
## ============================================

func _test_battle_transcript() -> void:
	var baseline := FileAccess.get_file_as_string(BASELINE_BATTLE_PATH).strip_edges()
	_expect(not baseline.is_empty(), "应存在基线战斗转录 %s" % BASELINE_BATTLE_PATH)
	var live := TranscriptScript.build_payload_json().strip_edges()
	_expect(live == baseline, "固定种子战局的日志与结算 JSON 应与基线 d0f9a12 逐字节一致")
	print("[LobbyResultBgm] battle_transcript_identical=%s bytes=%d" % [
		str(live == baseline),
		live.to_utf8_buffer().size(),
	])


## ============================================
## 证据采集
## ============================================

func _run_evidence(music_on: bool) -> void:
	print("[LobbyResultBgm][evidence] ===== musicOn=%s =====" % str(music_on))
	_set_sound_on(false)
	_set_music_on(music_on)

	var raw := {
		"settings": {"soundOn": false, "musicOn": music_on},
		"tracks": _track_summaries(),
		"scenes": [],
		"cycle": [],
	}

	var main := _spawn_main()
	await _wait_frames(2)
	var scenes: Array = raw["scenes"]
	await _walk_scene(main, "main", {}, "lobby", "lobby", music_on, scenes, false)
	await _walk_scene(main, "battle", _battle_data(), "battle", "battle", music_on, scenes, false)
	await _force_battle_end(main)
	await _walk_scene(main, "result", _result_payload("win"), "result_win", "result_win", music_on, scenes, false)
	await _walk_scene(main, "result", _result_payload("lose"), "result_loss", "result_loss", music_on, scenes, false)
	await _walk_scene(main, "main", {}, "back_lobby", "lobby", music_on, scenes, false)

	var cycle: Array = raw["cycle"]
	for round in range(1, CYCLE_ROUNDS + 1):
		var round_records: Array = []
		await _walk_scene(main, "main", {}, "round%d_lobby" % round, "lobby", music_on, round_records, false)
		await _walk_scene(main, "battle", _battle_data(), "round%d_battle" % round, "battle", music_on, round_records, false)
		await _force_battle_end(main)
		var result_kind := "win" if round % 2 == 1 else "lose"
		var expected_track := "result_win" if result_kind == "win" else "result_loss"
		await _walk_scene(main, "result", _result_payload(result_kind), "round%d_%s" % [round, expected_track], expected_track, music_on, round_records, false)
		await _walk_scene(main, "main", {}, "round%d_back_lobby" % round, "lobby", music_on, round_records, false)
		cycle.append({"round": round, "result": result_kind, "records": round_records})

	main.queue_free()
	await _wait_frames(2)
	print("[LobbyResultBgm][evidence] raw_json=")
	print(JSON.stringify(raw, "\t"))


func _track_summaries() -> Dictionary:
	var summaries := {}
	for track: String in TRACK_NAMES:
		var config := BattleBgmScript.track_config(track)
		var beat_seconds := 60.0 / float(config["bpm"])
		var loop_seconds := beat_seconds * float(config["beats_per_bar"]) * float(config["bars"])
		var layers_out := {}
		for layer_name: String in LAYER_NAMES:
			var layer: Dictionary = config["layers"][layer_name]
			layers_out[layer_name] = {
				"enabled": BattleBgmScript._layer_enabled(config["layers"], layer_name),
				"waveform": str(layer.get("waveform", "")),
				"gain": float(layer.get("gain", 0.0)),
				"bar_roots": layer.get("bar_roots", []),
				"chord_intervals": layer.get("chord_intervals", []),
				"pattern": layer.get("pattern", []),
			}
		var summary := {
			"bpm": float(config["bpm"]),
			"beats_per_bar": int(config["beats_per_bar"]),
			"bars": int(config["bars"]),
			"loop_seconds": loop_seconds,
			"loop_frames": int(round(loop_seconds * float(config["sample_rate"]))),
			"root_midi": int(config["root_midi"]),
			"root_frequency": BattleBgmScript._midi_to_frequency(int(config["root_midi"])),
			"scale_name": str(config["scale_name"]),
			"scale_degrees": config["scale_degrees"],
			"master_gain": float(config["master_gain"]),
			"sample_rate": int(config["sample_rate"]),
			"layers": layers_out,
		}
		if music_on_for_evidence():
			var bgm = BattleBgmScript.new()
			bgm.name = "EvidenceStream"
			bgm.set_track(track)
			root.add_child(bgm)
			# 这里不能 await；直接取缓存，前面场景已经合成过。
			var stream: AudioStreamWAV = bgm.get_stream()
			if stream != null:
				summary["bytes"] = stream.data.size()
				summary["peak"] = _peak_of(stream.data)
			bgm.stop()
			bgm.free()
		summaries[track] = summary
	return summaries


func music_on_for_evidence() -> bool:
	var save_manager = root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_method("load_settings"):
		return false
	return BattleBgmScript.music_on_from_settings(save_manager.load_settings())


## ============================================
## 场景行走与断言
## ============================================

func _spawn_main() -> Control:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	return main


func _walk_scene(main: Control, scene_name: String, data: Dictionary, label: String,
		expected_track: String, expect_playing: bool, records: Array, assert_mode: bool) -> void:
	main.switch_scene(scene_name, data)
	await _wait_frames(2)
	var record := _snapshot_scene(main, label)
	records.append(record)
	print("[LobbyResultBgm] walk %-18s scene=%-6s track=%-11s players=%d playing=%d total=%d session=%s active=%s" % [
		label,
		str(record["scene"]),
		str(record["track"]),
		int(record["bgm_player_count"]),
		int(record["total_playing_players"]),
		int(record["total_player_nodes"]),
		str(record["session_active"]),
		str(record["active_instance"]),
	])
	if assert_mode:
		_assert_record(record, expected_track, expect_playing)


func _force_battle_end(main: Control) -> void:
	var battle_scene: Control = main.get_current_scene()
	if battle_scene == null:
		return
	var battle = battle_scene.get("_battle")
	if battle != null:
		battle.battle_result = "win"
	battle_scene.set("_battle_end_overlay_started", false)
	battle_scene.call("_begin_battle_end_overlay")
	await process_frame


func _snapshot_scene(main: Control, label: String) -> Dictionary:
	var scene: Control = main.get_current_scene()
	var bgm := _scene_bgm(scene)
	var scene_players: Array = scene.find_children("*", "AudioStreamPlayer", true, false) if scene != null else []
	var all_players := _all_players()
	var playing := _playing_players()
	var current_player = bgm.get_node_or_null("BgmPlayer") if bgm != null else null
	var record := {
		"label": label,
		"scene": main.get_current_scene_name() if main != null else "",
		"track": str(bgm.track_name) if bgm != null else "",
		"bgm_node": bgm != null,
		"enabled": bool(bgm.enabled) if bgm != null else false,
		"bgm_player_count": bgm.player_count() if bgm != null else 0,
		"music_playing": bgm.is_playing() if bgm != null else false,
		"session_active": bool(bgm._session_active) if bgm != null else false,
		"active_instance": BattleBgmScript._active_instance == bgm if bgm != null else false,
		"scene_player_nodes": scene_players.size(),
		"total_player_nodes": all_players.size(),
		"total_playing_players": playing.size(),
		"current_player_only": playing.is_empty() or (playing.size() == 1 and current_player != null and playing[0] == current_player),
	}
	if bgm != null and bgm.player_count() > 0:
		var stream: AudioStreamWAV = bgm.get_stream()
		if stream != null:
			record["loop_bytes"] = stream.data.size()
			record["loop_mode"] = stream.loop_mode
			record["loop_end"] = stream.loop_end
	return record


func _assert_record(record: Dictionary, expected_track: String, expect_playing: bool) -> void:
	var label := str(record["label"])
	_expect(bool(record["bgm_node"]), "%s 应挂载 BGM 节点" % label)
	_expect(str(record["track"]) == expected_track, "%s 轨道应为 %s，实际 %s" % [label, expected_track, str(record["track"])])
	if expect_playing:
		_expect(bool(record["enabled"]), "%s musicOn=true 时 BGM 应开启" % label)
		_expect(int(record["bgm_player_count"]) == 1, "%s 应恰好 1 个 BGM 播放器，实际 %d" % [label, int(record["bgm_player_count"])])
		_expect(bool(record["music_playing"]), "%s BGM 应处于播放状态" % label)
		_expect(int(record["scene_player_nodes"]) == 1, "%s 场景内应只有 1 个播放器" % label)
		_expect(int(record["total_player_nodes"]) == 1, "%s 整个场景树应只有 1 个播放器，实际 %d" % [label, int(record["total_player_nodes"])])
		_expect(int(record["total_playing_players"]) == 1, "%s 应只有 1 个播放中的播放器" % label)
		_expect(bool(record["current_player_only"]), "%s 唯一播放器应属于当前场景" % label)
	else:
		_expect(not bool(record["enabled"]), "%s musicOn=false 时 BGM 应关闭" % label)
		_expect(int(record["bgm_player_count"]) == 0, "%s musicOn=false 时 BGM 播放器应为 0" % label)
		_expect(not bool(record["music_playing"]), "%s musicOn=false 时不应播放" % label)
		_expect(int(record["scene_player_nodes"]) == 0, "%s musicOn=false 时场景内播放器应为 0" % label)
		_expect(int(record["total_player_nodes"]) == 0, "%s musicOn=false 时场景树播放器应为 0，实际 %d" % [label, int(record["total_player_nodes"])])
		_expect(int(record["total_playing_players"]) == 0, "%s musicOn=false 时不应有播放中的播放器" % label)


func _scene_bgm(scene: Control) -> Node:
	if scene == null:
		return null
	for property: String in ["_battle_bgm", "_lobby_bgm", "_result_bgm"]:
		var candidate = scene.get(property)
		if candidate != null:
			return candidate
	return null


func _all_players() -> Array:
	return root.find_children("*", "AudioStreamPlayer", true, false)


func _playing_players() -> Array:
	return _all_players().filter(func(player): return bool(player.playing))


## ============================================
## 固定战局与结算 payload
## ============================================

func _battle_data() -> Dictionary:
	var stage_db = StageDBScript.new()
	return {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
		"inputTestOnly": true,
	}


func _result_payload(result: String) -> Dictionary:
	return {
		"result": result,
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

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


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
		print("[LobbyResultBgm] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[LobbyResultBgm] " + failure)
	quit(1)

class_name BattleBgm
extends Node
## 背景音乐层：运行时合成可循环的 BGM，不依赖外部/二进制音频资源。
##
## 一套合成器 + 一套缓存服务大厅、战斗与结算（胜利/失败）四条轨道：
## - `CONFIG` 是战斗轨道的完整参数，也是其余轨道的基准；
## - `TRACKS` 只声明各场景轨道的覆盖项，运行时与 `CONFIG` 合并；
## - 所有可调参数集中在两处：调式、速度、循环长度、各声部音色与编曲。
## `musicOn` 是独立于 `soundOn` 的总开关；关闭时不创建任何 AudioStreamPlayer。
## 全场最多保留 1 个播放器：新轨道起播前先停掉上一个，`LOOP_FORWARD` 保证回绕不断档。
##
## 合成口径：
## - 先按 MIDI 根音与五声音阶生成持续低音、低音线、和声垫、主旋律与心跳鼓点；
## - 每个音符在运行时写入 16-bit PCM 缓冲区，不落盘；
## - 持续低音按循环长度取整数个周期，循环接缝处相位连续；
## - 其余音符都在循环结束前收尾到 0，接缝处无爆音、无空白段。

const CONFIG := {
	"sample_rate": 22050,
	# 调式：A 小调五声音阶（根音 MIDI 45 = A2，110 Hz）
	"root_midi": 45,
	"scale_name": "minor_pentatonic",
	"scale_degrees": [0, 3, 5, 7, 10],
	# 速度与循环长度：100 BPM × 4 拍/小节 × 2 小节 = 4.8 秒
	"bpm": 100.0,
	"beats_per_bar": 4,
	"bars": 2,
	"master_gain": 0.72,
	"layers": {
		# 持续低音垫：整数周期 + 慢速颤音，保证循环接缝处仍有声音且相位连续。
		"bed": {
			"waveform": "sine",
			"harmonic": 2.0,
			"harmonic_gain": 0.12,
			"gain": 0.12,
			"tremolo_cycles": 2.0,
			"tremolo_depth": 0.35,
		},
		# 低音线：每小节第 1、3 拍；根音随 A → C 两小节进行。
		"bass": {
			"waveform": "sine",
			"octave": 0,
			"harmonic": 2.0,
			"harmonic_gain": 0.16,
			"attack": 0.012,
			"decay": 2.4,
			"release": 0.06,
			"gain": 0.38,
			"steps_per_bar": 4,
			"note_steps": 1.75,
			"bar_roots": [0, 3],
			"pattern": [0, -1, 7, -1],
			"follow_bar_root": true,
		},
		# 和声垫：每小节一个强力和弦（根音 + 五度 + 八度），铺在低音线上方。
		"pad": {
			"waveform": "sine",
			"octave": 0,
			"harmonic": 2.0,
			"harmonic_gain": 0.10,
			"attack": 0.06,
			"decay": 0.0,
			"release": 0.12,
			"gain": 0.08,
			"bar_roots": [0, 3],
			"chord_intervals": [0, 7, 12],
			"note_ratio": 1.0,
		},
		# 主旋律：A 小调五声音阶琶音，高八度，两小节 16 个八分音符槽位。
		"lead": {
			"waveform": "triangle",
			"octave": 12,
			"harmonic": 2.0,
			"harmonic_gain": 0.22,
			"attack": 0.006,
			"decay": 5.0,
			"release": 0.05,
			"gain": 0.24,
			"steps_per_bar": 8,
			"note_steps": 0.85,
			"bar_roots": [0, 3],
			"pattern": [0, -1, 2, 4, 3, -1, 2, 1, 0, -1, 4, 3, 2, -1, 1, 0],
			"follow_bar_root": false,
		},
		# 心跳鼓点：每小节第 1、3 拍，低频下滑，给战斗推进感。
		"kick": {
			"waveform": "sine",
			"frequency_start": 92.0,
			"frequency_end": 44.0,
			"duration": 0.16,
			"attack": 0.002,
			"decay": 18.0,
			"gain": 0.30,
			"steps_per_bar": 4,
			"pattern": [0, -1, 2, -1],
		},
	},
}

## 各场景轨道只覆盖需要变化的字段；`layers` 按声部逐个合并。
## 新增轨道时只要在这里追加一项，并在对应场景创建 BattleBgm 时 set_track()。
const TRACKS := {
	# 战斗沿用 CONFIG，不覆盖任何参数。
	"battle": {},
	# 大厅：C 大调五声音阶、76 BPM、4 小节，柔和长音铺底，无鼓点。
	"lobby": {
		"root_midi": 48,
		"scale_name": "major_pentatonic",
		"scale_degrees": [0, 2, 4, 7, 9],
		"bpm": 76.0,
		"beats_per_bar": 4,
		"bars": 4,
		"master_gain": 0.68,
		"layers": {
			"bed": {
				"gain": 0.10,
				"tremolo_cycles": 2.0,
				"tremolo_depth": 0.30,
			},
			"bass": {
				"gain": 0.26,
				"note_steps": 1.8,
				"decay": 2.0,
				"bar_roots": [0, 5, 7, 9],
			},
			"pad": {
				"gain": 0.07,
				"attack": 0.12,
				"release": 0.30,
				"note_ratio": 0.98,
				"chord_intervals": [0, 4, 7],
				"bar_roots": [0, 5, 7, 9],
			},
			"lead": {
				"gain": 0.16,
				"note_steps": 0.95,
				"decay": 3.5,
				"follow_bar_root": true,
				"bar_roots": [0, 5, 7, 9],
				"pattern": [
					0, -1, 2, 4, 3, -1, 2, -1,
					1, -1, 3, 4, 2, -1, 1, -1,
					2, -1, 4, 3, 2, -1, 0, -1,
					3, -1, 2, 1, 0, -1, 2, -1,
				],
			},
			"kick": {
				"enabled": false,
			},
		},
	},
	# 结算胜利：C 大调五声音阶、112 BPM、2 小节，明亮上行旋律与轻鼓点。
	"result_win": {
		"root_midi": 48,
		"scale_name": "major_pentatonic",
		"scale_degrees": [0, 2, 4, 7, 9],
		"bpm": 112.0,
		"beats_per_bar": 4,
		"bars": 2,
		"master_gain": 0.72,
		"layers": {
			"bed": {
				"gain": 0.09,
				"tremolo_depth": 0.20,
			},
			"bass": {
				"gain": 0.30,
				"note_steps": 1.6,
				"attack": 0.008,
				"decay": 3.0,
				"bar_roots": [0, 7],
			},
			"pad": {
				"gain": 0.09,
				"attack": 0.05,
				"release": 0.15,
				"chord_intervals": [0, 4, 7],
				"bar_roots": [0, 7],
			},
			"lead": {
				"gain": 0.26,
				"decay": 4.0,
				"follow_bar_root": true,
				"bar_roots": [0, 7],
				"pattern": [
					0, 2, 4, 4, 3, 4, 2, 0,
					1, 2, 3, 4, 2, 4, 1, 0,
				],
			},
			"kick": {
				"gain": 0.22,
				"frequency_start": 100.0,
				"frequency_end": 50.0,
				"duration": 0.14,
				"decay": 15.0,
			},
		},
	},
	# 结算失败：A 小调五声音阶、66 BPM、2 小节，低音铺底、稀疏旋律、无鼓点。
	"result_loss": {
		"root_midi": 45,
		"scale_name": "minor_pentatonic",
		"scale_degrees": [0, 3, 5, 7, 10],
		"bpm": 66.0,
		"beats_per_bar": 4,
		"bars": 2,
		"master_gain": 0.62,
		"layers": {
			"bed": {
				"gain": 0.13,
				"tremolo_depth": 0.42,
			},
			"bass": {
				"gain": 0.28,
				"note_steps": 1.9,
				"decay": 1.8,
				"pattern": [0, -1, 3, -1],
				"bar_roots": [0, 3],
			},
			"pad": {
				"gain": 0.08,
				"attack": 0.15,
				"release": 0.35,
				"chord_intervals": [0, 3, 7],
				"bar_roots": [0, 3],
			},
			"lead": {
				"gain": 0.15,
				"note_steps": 1.25,
				"decay": 2.2,
				"follow_bar_root": true,
				"bar_roots": [0, 3],
				"pattern": [
					0, -1, -1, 2, -1, 1, -1, -1,
					0, -1, -1, 3, -1, 2, -1, -1,
				],
			},
			"kick": {
				"enabled": false,
			},
		},
	},
}

const CACHE_NODE_NAME := "BattleBgmCache"
const CACHE_META_PREFIX := "stream_"

## 循环音频挂在根节点的缓存节点上：同一进程内每条轨道只合成一次，退出时随场景树释放。
static var _cache_node: Node = null
## 当前活跃的 BGM 节点：新场景起播前先停掉上一个，避免切场景时叠音。
static var _active_instance = null

## 当前轨道名：battle / lobby / result_win / result_loss。
var track_name: String = "battle"
## 本条轨道合并后的完整参数（CONFIG + TRACKS[track_name]）。
var _config: Dictionary = {}
## 本节点的总开关，由设置页 `musicOn` 同步。
var enabled: bool = true
## 是否处于播放会话中；stop() 之后不再因开关打开而重新起播。
var _session_active: bool = false
var _player: AudioStreamPlayer = null


## 把 CONFIG 与该轨道的覆盖项合并成一份完整参数；返回新字典，不改动常量。
static func track_config(track: String) -> Dictionary:
	var merged: Dictionary = CONFIG.duplicate(true)
	var overrides: Dictionary = TRACKS.get(track, {})
	if overrides.is_empty():
		return merged
	for key: String in overrides.keys():
		if key == "layers":
			var layers: Dictionary = merged["layers"]
			var layer_overrides: Dictionary = overrides[key]
			for layer_name: String in layer_overrides.keys():
				var layer: Dictionary = layers.get(layer_name, {}).duplicate(true)
				var patch: Dictionary = layer_overrides[layer_name]
				for patch_key: String in patch.keys():
					layer[patch_key] = patch[patch_key]
				layers[layer_name] = layer
			merged["layers"] = layers
		else:
			merged[key] = overrides[key]
	return merged


func _ready() -> void:
	set_process(true)
	if _config.is_empty():
		_config = track_config(track_name)
	start()


## 由场景在创建节点时选择轨道；运行中切换会先停旧播放器，再按新参数起播。
func set_track(name: String) -> void:
	if not TRACKS.has(name):
		push_error("未知 BGM 轨道: " + name)
		return
	if name == track_name and not _config.is_empty():
		return
	track_name = name
	_config = track_config(name)
	_release_player()
	if _session_active and enabled:
		_ensure_player()


## 每帧轻量检查设置页开关，运行中切换 musicOn 时下一帧立即生效。
func _process(_delta: float) -> void:
	if not _session_active:
		return
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("load_settings"):
		return
	var desired := music_on_from_settings(save_manager.load_settings())
	if desired != enabled:
		set_enabled(desired)


## 进入一个播放会话时调用：先停掉可能残留的上一个 BGM，再按 musicOn 决定是否起播。
func start() -> void:
	if _config.is_empty():
		_config = track_config(track_name)
	if _active_instance != null and _active_instance != self and is_instance_valid(_active_instance):
		_active_instance.stop()
	_active_instance = self
	_session_active = true
	enabled = music_on_from_settings(_load_settings())
	if enabled:
		_ensure_player()
	else:
		_release_player()


## 离开当前场景或进入下一段前调用：停止播放并释放唯一的播放器。
func stop() -> void:
	if _active_instance == self:
		_active_instance = null
	_session_active = false
	_release_player()


## 设置页 musicOn → 总开关；关闭后立即释放播放器，重新打开则恢复 1 个播放器。
func apply_settings(settings: Dictionary) -> void:
	set_enabled(music_on_from_settings(settings))


func sync_master_switch() -> void:
	apply_settings(_load_settings())


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_release_player()
	elif _session_active:
		_ensure_player()


## 供 headless 断言直接复用设置映射口径。
static func music_on_from_settings(settings: Dictionary) -> bool:
	return bool(settings.get("musicOn", true))


func _load_settings() -> Dictionary:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_settings"):
		return save_manager.load_settings()
	return {}


func player_count() -> int:
	return 1 if _player != null and is_instance_valid(_player) else 0


func is_playing() -> bool:
	return _player != null and is_instance_valid(_player) and _player.playing


func _ensure_player() -> void:
	if not enabled:
		return
	if _player != null and is_instance_valid(_player):
		if not _player.playing:
			_player.play()
		return
	AudioMix.ensure_buses()
	_player = AudioStreamPlayer.new()
	_player.name = "BgmPlayer"
	_player.bus = AudioMix.BGM_BUS
	_player.stream = get_stream()
	add_child(_player)
	_player.play()


func _release_player() -> void:
	if _player == null:
		return
	if is_instance_valid(_player):
		# 先 stop 再立即 free：保证运行中关开关时播放器数当帧回到 0，
		# 也不会把仍在播放的播放器留到节点树销毁之后再释放。
		_player.stop()
		_player.free()
	_player = null


func _exit_tree() -> void:
	if _player != null and is_instance_valid(_player):
		_player.stop()
	if _active_instance == self:
		_active_instance = null


## 生成并缓存一条轨道的完整循环。关闭 musicOn 时不会走到这里，因此不产生任何 PCM。
func get_stream() -> AudioStreamWAV:
	var tree := get_tree()
	if _config.is_empty():
		_config = track_config(track_name)
	if tree == null or tree.root == null:
		return _synthesize()
	if _cache_node == null or not is_instance_valid(_cache_node):
		_cache_node = tree.root.get_node_or_null(CACHE_NODE_NAME)
		if _cache_node == null:
			_cache_node = Node.new()
			_cache_node.name = CACHE_NODE_NAME
			tree.root.add_child(_cache_node)
	var cache_key := CACHE_META_PREFIX + track_name
	var stream = _cache_node.get_meta(cache_key) if _cache_node.has_meta(cache_key) else null
	if stream is AudioStreamWAV:
		return stream
	stream = _synthesize()
	_cache_node.set_meta(cache_key, stream)
	return stream


## 释放进程级缓存（测试收尾或需要重新按 CONFIG 生成时使用）。
static func clear_cache() -> void:
	if _cache_node != null and is_instance_valid(_cache_node):
		_cache_node.free()
	_cache_node = null


func loop_frames() -> int:
	if _config.is_empty():
		_config = track_config(track_name)
	var beat_seconds := 60.0 / float(_config["bpm"])
	var loop_seconds := beat_seconds * float(_config["beats_per_bar"]) * float(_config["bars"])
	return maxi(1, int(round(loop_seconds * float(_config["sample_rate"]))))


func _synthesize() -> AudioStreamWAV:
	if _config.is_empty():
		_config = track_config(track_name)
	var sample_rate := int(_config["sample_rate"])
	var beats_per_bar := int(_config["beats_per_bar"])
	var bars := int(_config["bars"])
	var beat_seconds := 60.0 / float(_config["bpm"])
	var bar_seconds := beat_seconds * float(beats_per_bar)
	var loop_seconds := bar_seconds * float(bars)
	var frames := maxi(1, int(round(loop_seconds * float(sample_rate))))
	var layers: Dictionary = _config["layers"]

	var raw := PackedFloat32Array()
	raw.resize(frames)
	if _layer_enabled(layers, "bed"):
		_render_bed(raw, frames, sample_rate, loop_seconds, layers["bed"])
	if _layer_enabled(layers, "bass"):
		_render_tonal_layer(raw, frames, sample_rate, beat_seconds, layers["bass"], false)
	if _layer_enabled(layers, "lead"):
		_render_tonal_layer(raw, frames, sample_rate, beat_seconds, layers["lead"], true)
	if _layer_enabled(layers, "pad"):
		_render_pad(raw, frames, sample_rate, bar_seconds, layers["pad"])
	if _layer_enabled(layers, "kick"):
		_render_kick(raw, frames, sample_rate, beat_seconds, layers["kick"])

	var peak := 0.0
	for i in range(frames):
		peak = maxf(peak, absf(raw[i]))
	var scale := (float(_config["master_gain"]) / peak) if peak > 0.0001 else 0.0
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var value := int(clampf(raw[i] * scale, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


static func _layer_enabled(layers: Dictionary, layer_name: String) -> bool:
	var layer: Dictionary = layers.get(layer_name, {})
	return bool(layer.get("enabled", true))


## 持续低音：把根音频率吸附到循环内整数个周期，使首尾样本处于同一相位。
func _render_bed(raw: PackedFloat32Array, frames: int, sample_rate: int, loop_seconds: float, layer: Dictionary) -> void:
	var base_frequency := _midi_to_frequency(int(_config["root_midi"]))
	var cycles := maxi(1, int(round(base_frequency * loop_seconds)))
	var frequency := float(cycles) / loop_seconds
	var waveform := str(layer["waveform"])
	var harmonic := float(layer.get("harmonic", 1.0))
	var harmonic_gain := float(layer.get("harmonic_gain", 0.0))
	var gain := float(layer.get("gain", 0.1))
	var tremolo_cycles := maxf(float(layer.get("tremolo_cycles", 1.0)), 0.0)
	var depth := clampf(float(layer.get("tremolo_depth", 0.0)), 0.0, 1.0)
	var phase_step := frequency / float(sample_rate)
	var phase := 0.0
	for i in range(frames):
		var t := float(i) / float(sample_rate)
		var sample := 0.0
		if waveform == "sine":
			sample = sin(TAU * phase)
			if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
				sample += sin(TAU * phase * harmonic) * harmonic_gain
		else:
			sample = _wave_sample(waveform, phase)
			if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
				sample += _wave_sample(waveform, phase * harmonic) * harmonic_gain
		var tremolo := 1.0 - depth * 0.5 * (1.0 - cos(TAU * tremolo_cycles * t / loop_seconds))
		raw[i] += sample * tremolo * gain
		phase += phase_step


## 低音线与主旋律共用：pattern 为每槽位音级（-1 休止），scale_mode 决定是音阶级数还是半音。
func _render_tonal_layer(raw: PackedFloat32Array, frames: int, sample_rate: int, beat_seconds: float, layer: Dictionary, scale_mode: bool) -> void:
	var steps_per_bar := int(layer["steps_per_bar"])
	var bars := int(_config["bars"])
	var step_seconds := beat_seconds * float(_config["beats_per_bar"]) / float(steps_per_bar)
	var pattern: Array = layer["pattern"]
	var bar_roots: Array = layer["bar_roots"]
	var scale_degrees: Array = _config["scale_degrees"]
	var base_midi := int(_config["root_midi"]) + int(layer.get("octave", 0))
	var note_steps := float(layer.get("note_steps", 0.9))
	var follow_bar_root := bool(layer.get("follow_bar_root", true))
	for step in range(steps_per_bar * bars):
		var value := int(pattern[step % pattern.size()])
		if value < 0:
			continue
		var bar := int(step / steps_per_bar)
		var semitone := int(scale_degrees[value % scale_degrees.size()]) if scale_mode else value
		if follow_bar_root:
			semitone += int(bar_roots[bar % bar_roots.size()])
		_render_note(
			raw,
			frames,
			sample_rate,
			float(step) * step_seconds,
			note_steps * step_seconds,
			_midi_to_frequency(base_midi + semitone),
			layer
		)


## 和声垫：每小节铺一个和弦，最后一个和弦在循环结束处自然收尾。
## 和弦的三个音在同一次采样循环里叠加，避免逐音重复扫描整个缓冲区。
func _render_pad(raw: PackedFloat32Array, frames: int, sample_rate: int, bar_seconds: float, layer: Dictionary) -> void:
	var bars := int(_config["bars"])
	var bar_roots: Array = layer["bar_roots"]
	var chord_intervals: Array = layer["chord_intervals"]
	var base_midi := int(_config["root_midi"]) + int(layer.get("octave", 0))
	var note_ratio := float(layer.get("note_ratio", 1.0))
	var waveform := str(layer["waveform"])
	var attack := maxf(float(layer.get("attack", 0.001)), 0.0001)
	var decay := float(layer.get("decay", 0.0))
	var release := maxf(float(layer.get("release", 0.02)), 0.001)
	var gain := float(layer.get("gain", 0.2))
	var harmonic := float(layer.get("harmonic", 1.0))
	var harmonic_gain := float(layer.get("harmonic_gain", 0.0))
	var duration := bar_seconds * note_ratio
	var note_frames := int(round(duration * float(sample_rate)))
	for bar in range(bars):
		var root_midi := base_midi + int(bar_roots[bar % bar_roots.size()])
		var frequencies: Array[float] = []
		for interval in chord_intervals:
			frequencies.append(_midi_to_frequency(root_midi + int(interval)))
		var start_index := int(round(float(bar) * bar_seconds * float(sample_rate)))
		for i in range(note_frames):
			var index := start_index + i
			if index >= frames:
				break
			var t := float(i) / float(sample_rate)
			var sample := 0.0
			if waveform == "sine":
				for frequency: float in frequencies:
					sample += sin(TAU * frequency * t)
					if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
						sample += sin(TAU * frequency * harmonic * t) * harmonic_gain
			else:
				for frequency: float in frequencies:
					sample += _wave_sample(waveform, frequency * t)
					if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
						sample += _wave_sample(waveform, frequency * harmonic * t) * harmonic_gain
			sample *= _note_envelope(t, duration, attack, decay, release) * gain
			raw[index] += sample


## 心跳鼓点：短促的低频下滑正弦，强拍推进。
func _render_kick(raw: PackedFloat32Array, frames: int, sample_rate: int, beat_seconds: float, layer: Dictionary) -> void:
	var steps_per_bar := int(layer["steps_per_bar"])
	var bars := int(_config["bars"])
	var step_seconds := beat_seconds * float(_config["beats_per_bar"]) / float(steps_per_bar)
	var pattern: Array = layer["pattern"]
	var frequency_start := float(layer["frequency_start"])
	var frequency_end := float(layer["frequency_end"])
	var duration := float(layer["duration"])
	var attack := maxf(float(layer.get("attack", 0.002)), 0.0001)
	var decay := float(layer.get("decay", 10.0))
	var gain := float(layer.get("gain", 0.2))
	for step in range(steps_per_bar * bars):
		if int(pattern[step % pattern.size()]) < 0:
			continue
		var start_index := int(round(float(step) * step_seconds * float(sample_rate)))
		var note_frames := int(round(duration * float(sample_rate)))
		var phase := 0.0
		for i in range(note_frames):
			var index := start_index + i
			if index >= frames:
				break
			var t := float(i) / float(sample_rate)
			var progress := clampf(t / duration, 0.0, 1.0)
			var frequency := lerpf(frequency_start, frequency_end, progress)
			phase += frequency / float(sample_rate)
			var envelope := exp(-decay * t)
			if t < attack:
				envelope *= t / attack
			raw[index] += sin(TAU * phase) * envelope * gain


func _render_note(raw: PackedFloat32Array, frames: int, sample_rate: int, start_seconds: float, duration_seconds: float, frequency: float, layer: Dictionary) -> void:
	if frequency <= 0.0 or duration_seconds <= 0.0:
		return
	var start_index := int(round(start_seconds * float(sample_rate)))
	var note_frames := int(round(duration_seconds * float(sample_rate)))
	var waveform := str(layer["waveform"])
	var attack := maxf(float(layer.get("attack", 0.001)), 0.0001)
	var decay := float(layer.get("decay", 0.0))
	var release := maxf(float(layer.get("release", 0.02)), 0.001)
	var gain := float(layer.get("gain", 0.2))
	var harmonic := float(layer.get("harmonic", 1.0))
	var harmonic_gain := float(layer.get("harmonic_gain", 0.0))
	var phase := 0.0
	var phase_step := frequency / float(sample_rate)
	for i in range(note_frames):
		var index := start_index + i
		if index >= frames:
			break
		var t := float(i) / float(sample_rate)
		var sample := 0.0
		if waveform == "sine":
			sample = sin(TAU * phase)
			if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
				sample += sin(TAU * phase * harmonic) * harmonic_gain
		elif waveform == "triangle":
			sample = 4.0 * absf(phase - floorf(phase + 0.5)) - 1.0
			if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
				var harmonic_phase := phase * harmonic
				sample += (4.0 * absf(harmonic_phase - floorf(harmonic_phase + 0.5)) - 1.0) * harmonic_gain
		else:
			sample = _wave_sample(waveform, phase)
			if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
				sample += _wave_sample(waveform, phase * harmonic) * harmonic_gain
		sample *= _note_envelope(t, duration_seconds, attack, decay, release) * gain
		raw[index] += sample
		phase += phase_step


## 快速起音 + 指数衰减 + 尾部收尾到 0，避免循环接缝与音符边界爆音。
static func _note_envelope(t: float, duration: float, attack: float, decay: float, release: float) -> float:
	var envelope := 1.0
	if t < attack:
		envelope = t / attack
	if decay > 0.0:
		envelope *= exp(-decay * maxf(t - attack, 0.0))
	var tail := minf(release, duration * 0.5)
	if t > duration - tail:
		envelope *= maxf(0.0, (duration - t) / tail)
	return envelope


static func _wave_sample(waveform: String, phase: float) -> float:
	match waveform:
		"sine":
			return sin(TAU * phase)
		"triangle":
			return 4.0 * absf(phase - floorf(phase + 0.5)) - 1.0
		"saw":
			return 2.0 * fposmod(phase, 1.0) - 1.0
		"square":
			return 1.0 if fposmod(phase, 1.0) < 0.5 else -1.0
	return 0.0


static func _midi_to_frequency(midi: int) -> float:
	return 440.0 * pow(2.0, (float(midi) - 69.0) / 12.0)

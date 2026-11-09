class_name BattleSfx
extends Node
## 战斗音效层：七个运行时合成的短音，不依赖外部/二进制音频资源。
##
## 所有可调参数集中在本文件 CONFIG；`enabled` 是总开关，由设置页的
## `soundOn` 在战斗场景创建时同步。总开关关闭时不会创建任何
## AudioStreamPlayer，也不会播放已有音效。
##
## 合成口径：
## - 每个音效由频率、时长、波形、起音、衰减与泛音决定；
## - 波形在运行时写入 AudioStreamWAV（16-bit PCM），不落盘；
## - 同一个引擎帧最多触发 CONFIG.max_plays_per_frame 个实例，超出丢弃并计数。

const SOUND_IDS := ["match_clear", "hit", "crit", "take_damage", "victory", "defeat", "break"]

const CONFIG := {
	"sample_rate": 22050,
	"max_players": 8,
	"max_plays_per_frame": 8,
	# 参数说明：frequency 为基频 Hz；duration 为整段时长秒；waveform 为波形；
	# attack 为起音秒；decay 为指数衰减速度；harmonic 为泛音倍频，
	# harmonic_gain 为泛音占比；frequency_end 存在时做线性滑音。
	"sounds": {
		"match_clear": {
			"label": "消除",
			"frequency": 880.0,
			"duration": 0.12,
			"waveform": "sine",
			"attack": 0.004,
			"decay": 30.0,
			"harmonic": 2.0,
			"harmonic_gain": 0.25,
		},
		"hit": {
			"label": "普通打击",
			"frequency": 220.0,
			"duration": 0.09,
			"waveform": "triangle",
			"attack": 0.002,
			"decay": 35.0,
			"harmonic": 3.0,
			"harmonic_gain": 0.15,
		},
		"crit": {
			"label": "暴击",
			"frequency": 520.0,
			"duration": 0.22,
			"waveform": "square",
			"attack": 0.002,
			"decay": 14.0,
			"harmonic": 1.5,
			"harmonic_gain": 0.30,
		},
		"take_damage": {
			"label": "受击",
			"frequency": 110.0,
			"duration": 0.18,
			"waveform": "noise",
			"attack": 0.003,
			"decay": 18.0,
			"harmonic": 1.0,
			"harmonic_gain": 0.0,
		},
		"victory": {
			"label": "胜利",
			"frequency": 660.0,
			"frequency_end": 990.0,
			"duration": 0.50,
			"waveform": "saw",
			"attack": 0.010,
			"decay": 3.5,
			"harmonic": 2.0,
			"harmonic_gain": 0.20,
		},
		"defeat": {
			"label": "失败",
			"frequency": 300.0,
			"frequency_end": 120.0,
			"duration": 0.60,
			"waveform": "pulse",
			"attack": 0.005,
			"decay": 4.0,
			"harmonic": 0.5,
			"harmonic_gain": 0.20,
		},
		"break": {
			"label": "破招",
			"frequency": 440.0,
			"frequency_end": 880.0,
			"duration": 0.30,
			"waveform": "saw",
			"attack": 0.006,
			"decay": 8.0,
			"harmonic": 3.0,
			"harmonic_gain": 0.30,
		},
	},
}

## 总开关：由 `soundOn` 同步；关闭时释放所有播放器。
static var enabled: bool = true

var played_count: int = 0
var dropped_count: int = 0
var peak_players: int = 0
var last_sound_id: String = ""

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_player: int = 0
var _frame_id: int = -1
var _frame_plays: int = 0


func _ready() -> void:
	sync_master_switch()


## 设置页的 soundOn → 总开关；关闭后立即释放播放器，回到 0 个实例。
func sync_master_switch() -> void:
	apply_settings(_load_settings())


func apply_settings(settings: Dictionary) -> void:
	enabled = sound_on_from_settings(settings)
	if not enabled:
		release_players()


## 供 headless 断言直接复用设置映射口径。
static func sound_on_from_settings(settings: Dictionary) -> bool:
	return bool(settings.get("soundOn", true))


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		release_players()


func _load_settings() -> Dictionary:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_settings"):
		return save_manager.load_settings()
	return {}


## 同一帧最多触发 max_plays_per_frame 次；超过的请求直接丢弃并累计 dropped_count。
func play(sound_id: String) -> bool:
	if not enabled or not CONFIG["sounds"].has(sound_id):
		return false
	var frame := Engine.get_process_frames()
	if frame != _frame_id:
		_frame_id = frame
		_frame_plays = 0
	if _frame_plays >= int(CONFIG["max_plays_per_frame"]):
		dropped_count += 1
		return false
	_frame_plays += 1
	_ensure_players()
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = get_stream(sound_id)
	player.pitch_scale = 1.0
	player.play()
	played_count += 1
	last_sound_id = sound_id
	return true


func stop_all() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()


func release_players() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.queue_free()
	_players.clear()
	_next_player = 0


func player_count() -> int:
	return _players.size()


func reset_counters() -> void:
	played_count = 0
	dropped_count = 0
	peak_players = _players.size()
	last_sound_id = ""
	_frame_id = -1
	_frame_plays = 0


func get_stream(sound_id: String) -> AudioStreamWAV:
	if _streams.has(sound_id):
		return _streams[sound_id]
	if not CONFIG["sounds"].has(sound_id):
		return null
	_streams[sound_id] = _synthesize(sound_id, CONFIG["sounds"][sound_id])
	return _streams[sound_id]


## 按配置生成 16-bit PCM 单声道音频；同一音效只生成一次并缓存。
func _synthesize(sound_id: String, params: Dictionary) -> AudioStreamWAV:
	var sample_rate := int(CONFIG["sample_rate"])
	var duration := float(params["duration"])
	var frames := maxi(1, int(round(sample_rate * duration)))
	var waveform := str(params["waveform"])
	var frequency := float(params["frequency"])
	var frequency_end := float(params.get("frequency_end", frequency))
	var attack := maxf(float(params["attack"]), 0.0001)
	var decay := float(params["decay"])
	var harmonic := float(params["harmonic"])
	var harmonic_gain := float(params["harmonic_gain"])
	var rng := RandomNumberGenerator.new()
	rng.seed = sound_id.hash()

	var raw := PackedFloat32Array()
	raw.resize(frames)
	var peak := 0.0
	var phase := 0.0
	for i in range(frames):
		var t := float(i) / float(sample_rate)
		var progress := clampf(t / duration, 0.0, 1.0)
		var instant_frequency := lerpf(frequency, frequency_end, progress)
		phase += instant_frequency / float(sample_rate)
		var sample := _wave_sample(waveform, phase, rng)
		if harmonic_gain > 0.0 and not is_zero_approx(harmonic):
			sample += _wave_sample(waveform, phase * harmonic, rng) * harmonic_gain
		sample *= _envelope(t, duration, attack, decay)
		raw[i] = sample
		peak = maxf(peak, absf(sample))

	# 统一峰值，避免不同波形叠加后削波；音色差异由波形与包络保留。
	var scale := (0.85 / peak) if peak > 0.0001 else 0.0
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
	return stream


static func _wave_sample(waveform: String, phase: float, rng: RandomNumberGenerator) -> float:
	match waveform:
		"sine":
			return sin(TAU * phase)
		"triangle":
			return 4.0 * absf(phase - floorf(phase + 0.5)) - 1.0
		"square":
			return 1.0 if fposmod(phase, 1.0) < 0.5 else -1.0
		"saw":
			return 2.0 * fposmod(phase, 1.0) - 1.0
		"pulse":
			return 1.0 if fposmod(phase, 1.0) < 0.25 else -0.35
		"noise":
			return rng.randf_range(-1.0, 1.0)
	return 0.0


## 快速起音 + 指数衰减 + 末尾淡出，避免爆音。
static func _envelope(t: float, duration: float, attack: float, decay: float) -> float:
	var envelope := 1.0
	if t < attack:
		envelope = t / attack
	envelope *= exp(-decay * maxf(t - attack, 0.0))
	var tail := minf(0.02, duration * 0.2)
	if t > duration - tail:
		envelope *= maxf(0.0, (duration - t) / tail)
	return envelope


func _ensure_players() -> void:
	if not _players.is_empty():
		peak_players = maxi(peak_players, _players.size())
		return
	for i in range(int(CONFIG["max_players"])):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
	peak_players = maxi(peak_players, _players.size())

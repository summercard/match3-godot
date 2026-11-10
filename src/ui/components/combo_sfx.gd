# ============================================
# ui/components/combo_sfx.gd - 连锁音效
# ============================================
# 每升一级连锁播放一次短促铃声，音高逐级升高。
# 音色在运行时生成，避免为单次反馈引入外部音频资源。

class_name ComboSfx
extends Node

const SAMPLE_RATE := 22050
const BASE_FREQUENCY := 660.0
const SEMITONES_PER_LEVEL := 2.0
const MAX_PITCH_SCALE := 4.0
const TONE_DURATION := 0.18
const PLAYER_POOL_SIZE := 4

var _players: Array[AudioStreamPlayer] = []
var _tone_stream: AudioStreamWAV = null
var _next_player: int = 0

## 第 2 连锁用基准音高，之后每级升高 2 个半音，并封顶避免高频刺耳。
static func pitch_scale_for_chain(level: int) -> float:
	if level < 2:
		return 1.0
	var steps := float(level - 2)
	return minf(MAX_PITCH_SCALE, pow(2.0, steps * SEMITONES_PER_LEVEL / 12.0))

func _ready() -> void:
	_ensure_players()

func _ensure_players() -> void:
	if not _players.is_empty():
		return
	AudioMix.ensure_buses()
	for i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = AudioMix.SFX_BUS
		add_child(player)
		_players.append(player)

func _next_player_node() -> AudioStreamPlayer:
	_ensure_players()
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return player

## 播放第 N 连锁的音效；第 1 连锁只是普通消除，不发声。
func play_chain(level: int) -> void:
	if level < 2 or not _sound_enabled():
		return
	var player := _next_player_node()
	player.stream = get_tone_stream()
	player.pitch_scale = pitch_scale_for_chain(level)
	player.play()

func stop_all() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()

## 生成一段带快速起音与自然衰减的短音，供不同连锁等级以不同音高复用。
func get_tone_stream() -> AudioStreamWAV:
	if _tone_stream != null:
		return _tone_stream

	var frames := int(SAMPLE_RATE * TONE_DURATION)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(SAMPLE_RATE)
		var envelope := _tone_envelope(t)
		var sample := sin(TAU * BASE_FREQUENCY * t) * 0.62 \
			+ sin(TAU * BASE_FREQUENCY * 2.0 * t) * 0.18
		var value := int(clampf(sample * envelope, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	_tone_stream = stream
	return stream

static func _tone_envelope(t: float) -> float:
	# 起音 12ms，随后指数衰减，末 30ms 收尾，避免爆音。
	var envelope := exp(-t * 14.0)
	if t < 0.012:
		envelope *= t / 0.012
	var tail_start := TONE_DURATION - 0.03
	if t > tail_start:
		envelope *= maxf(0.0, (TONE_DURATION - t) / 0.03)
	return envelope

func _sound_enabled() -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_settings"):
		return bool(save_manager.load_settings().get("soundOn", true))
	return true

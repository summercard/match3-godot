# ============================================
# core/audio_manager.gd - 音频管理器（autoload 单例）
# ============================================
## 集中管理 SFX/BGM 的播放、音量、限流、设置联动。
##
## 用法：
##   AudioManager.play_sfx("ui_button_soft_pop")
##   AudioManager.play_sfx("match_eliminate_fire_warm")
##   AudioManager.set_mute(true)
##
## 事件 key 与 manifest.json 中 file 同名。
## 音量区间参考 README.md：UI -12~-8 dB / 消除 -9~-6 dB / 攻击 -8~-5 dB 等。
## 限流：同 key 在 60~90 ms 内不重复触发（可配）。

extends Node
## Autoload 名: AudioManager（不要加 class_name，与 autoload 名冲突）

## 信号：静音状态改变
signal mute_changed(muted: bool)

## ========== 事件 → 资源路径 映射 ==========
## key 与 manifest.json 的 file 字段同名；category 用于限流分组和音量分组
const SFX_LIBRARY: Dictionary = {
	# ---- UI ----
	"ui_button_soft_pop":         { "path": "res://assets/audio/sfx/ui_button_soft_pop.wav",         "category": "ui",        "volume_db": -10.0 },
	"ui_tile_select_leaf":        { "path": "res://assets/audio/sfx/ui_tile_select_leaf.wav",        "category": "ui",        "volume_db": -10.0 },
	"ui_tile_swap_soft":          { "path": "res://assets/audio/sfx/ui_tile_swap_soft.wav",          "category": "ui",        "volume_db": -10.0 },
	"ui_invalid_move_bouncy":     { "path": "res://assets/audio/sfx/ui_invalid_move_bouncy.wav",     "category": "ui",        "volume_db": -10.0 },

	# ---- 消除（基础 3/4/5 连）----
	"match_eliminate_3_rounded":  { "path": "res://assets/audio/sfx/match_eliminate_3_rounded.wav",  "category": "match",     "volume_db": -7.0  },
	"match_eliminate_4_rounded":  { "path": "res://assets/audio/sfx/match_eliminate_4_rounded.wav",  "category": "match",     "volume_db": -7.0  },
	"match_eliminate_5_rounded":  { "path": "res://assets/audio/sfx/match_eliminate_5_rounded.wav",  "category": "match",     "volume_db": -7.0  },

	# ---- 消除（按元素变体）----
	"match_eliminate_fire_warm":  { "path": "res://assets/audio/sfx/match_eliminate_fire_warm.wav",  "category": "match",     "volume_db": -8.0  },
	"match_eliminate_water_bubble":{ "path": "res://assets/audio/sfx/match_eliminate_water_bubble.wav","category": "match",     "volume_db": -8.0  },
	"match_eliminate_wind_puff":  { "path": "res://assets/audio/sfx/match_eliminate_wind_puff.wav",  "category": "match",     "volume_db": -8.0  },
	"match_eliminate_leaf_pluck": { "path": "res://assets/audio/sfx/match_eliminate_leaf_pluck.wav", "category": "match",     "volume_db": -8.0  },
	"match_eliminate_star_glow":  { "path": "res://assets/audio/sfx/match_eliminate_star_glow.wav",  "category": "match",     "volume_db": -8.0  },

	# ---- Combo（按层数选 1~5）----
	"combo_1_soft_rise":          { "path": "res://assets/audio/sfx/combo_1_soft_rise.wav",          "category": "combo",     "volume_db": -9.0  },
	"combo_2_soft_rise":          { "path": "res://assets/audio/sfx/combo_2_soft_rise.wav",          "category": "combo",     "volume_db": -8.5  },
	"combo_3_soft_rise":          { "path": "res://assets/audio/sfx/combo_3_soft_rise.wav",          "category": "combo",     "volume_db": -8.0  },
	"combo_4_soft_rise":          { "path": "res://assets/audio/sfx/combo_4_soft_rise.wav",          "category": "combo",     "volume_db": -7.5  },
	"combo_5_soft_rise":          { "path": "res://assets/audio/sfx/combo_5_soft_rise.wav",          "category": "combo",     "volume_db": -7.0  },

	# ---- 战斗 / 攻击（按元素）----
	"attack_fire_cub_pounce":     { "path": "res://assets/audio/sfx/attack_fire_cub_pounce.wav",     "category": "attack",    "volume_db": -7.0  },
	"attack_water_bubble_splash": { "path": "res://assets/audio/sfx/attack_water_bubble_splash.wav", "category": "attack",    "volume_db": -7.0  },
	"attack_leaf_sprite_seed":    { "path": "res://assets/audio/sfx/attack_leaf_sprite_seed.wav",    "category": "attack",    "volume_db": -7.0  },
	"attack_wind_sprite_gust":    { "path": "res://assets/audio/sfx/attack_wind_sprite_gust.wav",    "category": "attack",    "volume_db": -7.0  },

	# ---- 战斗 / 受击 ----
	"battle_enemy_hit_soft":      { "path": "res://assets/audio/sfx/battle_enemy_hit_soft.wav",      "category": "hit",       "volume_db": -7.0  },
	"battle_player_hit_cushion":  { "path": "res://assets/audio/sfx/battle_player_hit_cushion.wav",  "category": "hit",       "volume_db": -7.0  },

	# ---- 战斗 / 防御 + 治疗 ----
	"battle_shield_soft_bloom":   { "path": "res://assets/audio/sfx/battle_shield_soft_bloom.wav",   "category": "defense",   "volume_db": -8.0  },
	"battle_heal_leaf_bubble":    { "path": "res://assets/audio/sfx/battle_heal_leaf_bubble.wav",    "category": "heal",      "volume_db": -8.0  },

	# ---- 击败 ----
	"enemy_defeated_bubble_poof": { "path": "res://assets/audio/sfx/enemy_defeated_bubble_poof.wav", "category": "defeat",    "volume_db": -8.0  },
	"player_ko_soft_fall":        { "path": "res://assets/audio/sfx/player_ko_soft_fall.wav",        "category": "defeat",    "volume_db": -8.0  },

	# ---- 结算 ----
	"battle_victory_fresh_fanfare":{ "path": "res://assets/audio/sfx/battle_victory_fresh_fanfare.wav","category": "result",    "volume_db": -8.0  },
	"battle_defeat_gentle":       { "path": "res://assets/audio/sfx/battle_defeat_gentle.wav",       "category": "result",    "volume_db": -8.0  },

	# ---- 道具 ----
	"powerup_created_star":       { "path": "res://assets/audio/sfx/powerup_created_star.wav",       "category": "powerup",   "volume_db": -7.5  },
	"powerup_burst_soft":         { "path": "res://assets/audio/sfx/powerup_burst_soft.wav",         "category": "powerup",   "volume_db": -7.0  },
	"powerup_line_clear_air":     { "path": "res://assets/audio/sfx/powerup_line_clear_air.wav",     "category": "powerup",   "volume_db": -7.5  },

	# ---- 奖励 ----
	"reward_coin_soft":           { "path": "res://assets/audio/sfx/reward_coin_soft.wav",           "category": "reward",    "volume_db": -9.0  },

	# ---- BGM ----
	"bgm_town":                   { "path": "res://assets/audio/bgm/elf_valley.mp3", "category": "bgm", "volume_db": -8.0, "loop": true },
	"bgm_battle":                 { "path": "res://assets/audio/bgm/elf_cha_cha.mp3", "category": "bgm", "volume_db": -8.0, "loop": true },
}

## ========== 元素 → 攻击 / 消除 音效别名 ==========
## 用于代码中按 element 字段查表
const ELEMENT_ATTACK_SFX := {
	"fire":   "attack_fire_cub_pounce",
	"water":  "attack_water_bubble_splash",
	"grass":  "attack_leaf_sprite_seed",
	"wind":   "attack_wind_sprite_gust",
	"thunder": "attack_wind_sprite_gust",   # 雷借用风
	"light":  "attack_fire_cub_pounce",    # 光借用火
	"earth":  "attack_leaf_sprite_seed",   # 地借用草
	"dark":   "attack_water_bubble_splash",
	"ice":    "attack_water_bubble_splash",
	"void":   "attack_wind_sprite_gust",
	"temporal": "attack_wind_sprite_gust",
	"star":   "attack_fire_cub_pounce",
	"chaos":  "attack_fire_cub_pounce",
}

const ELEMENT_MATCH_SFX := {
	"fire":   "match_eliminate_fire_warm",
	"water":  "match_eliminate_water_bubble",
	"grass":  "match_eliminate_leaf_pluck",
	"wind":   "match_eliminate_wind_puff",
	"thunder": "match_eliminate_wind_puff",
	"light":  "match_eliminate_star_glow",
	"earth":  "match_eliminate_leaf_pluck",
	"dark":   "match_eliminate_star_glow",
	"ice":    "match_eliminate_water_bubble",
	"void":   "match_eliminate_star_glow",
	"temporal": "match_eliminate_star_glow",
	"star":   "match_eliminate_star_glow",
	"chaos":  "match_eliminate_fire_warm",
}

## ========== 限流配置（ms） ==========
const RATE_LIMIT_MS := {
	"ui":      80,
	"match":   60,
	"combo":   70,
	"attack":  80,
	"hit":     60,
	"defense": 100,
	"heal":    100,
	"defeat":  150,
	"result":  300,
	"powerup": 80,
	"reward":  70,
	"ambient": 500,
}

## ========== 状态 ==========
var _muted: bool = false
var _bgm_muted: bool = false
var _sfx_volume_db: float = 0.0   # 叠加在 SFX 库自带 volume_db 之上
var _bgm_volume_db: float = -6.0  # BGM 主音量
var _sfx_bus: AudioStreamPlayer = null
var _bgm_player: AudioStreamPlayer = null
var _resource_cache: Dictionary = {}    # path -> AudioStream
var _last_played_at_ms: Dictionary = {} # key -> int msec

## ========== 单例 ==========
static var instance: AudioManager

func _enter_tree() -> void:
	instance = self
	_init_buses()

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	_sync_with_settings()

## 监听 SaveManager 设置变化（由 save_manager.gd 在写入时调用）
func _sync_with_settings() -> void:
	var storage := get_node_or_null("/root/SaveManager")
	if storage == null:
		return
	if storage.has_method("load_settings"):
		var settings: Dictionary = storage.load_settings()
		var sound_on: bool = bool(settings.get("soundOn", true))
		var music_on: bool = bool(settings.get("musicOn", true))
		set_mute(not sound_on)
		set_bgm_mute(not music_on)

## ========== 公共 API ==========

## 播放 SFX 事件。event_key 取 SFX_LIBRARY 中的 key。
## 可选参数:
##   volume_scale: 1.0 正常, 0.5 半音量
##   pitch_scale:  1.0 正常音高, 1.1 略快/略高
func play_sfx(event_key: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	if _muted:
		return
	if not SFX_LIBRARY.has(event_key):
		push_warning("AudioManager: unknown sfx key '%s'" % event_key)
		return
	var entry: Dictionary = SFX_LIBRARY[event_key]
	var category: String = entry.get("category", "ui")
	# 同类限流
	var cooldown: int = int(RATE_LIMIT_MS.get(category, 80))
	var now_ms: int = Time.get_ticks_msec()
	var last: int = int(_last_played_at_ms.get(event_key, -100000))
	if now_ms - last < cooldown:
		return
	_last_played_at_ms[event_key] = now_ms

	var path: String = str(entry.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = _get_stream(path)
	if stream == null:
		return

	# 每个事件一个一次性播放器，避免被同类打断
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = float(entry.get("volume_db", -8.0)) + _sfx_volume_db + linear_to_db(maxf(0.01, volume_scale))
	player.pitch_scale = maxf(0.5, pitch_scale)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

## 播放 BGM。loop=true 时循环。
func play_bgm(event_key: String, volume_db: float = INF) -> void:
	if not SFX_LIBRARY.has(event_key):
		push_warning("AudioManager: unknown bgm key '%s'" % event_key)
		return
	var entry: Dictionary = SFX_LIBRARY[event_key]
	var path: String = str(entry.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = _get_stream(path)
	if stream == null:
		return
	if _bgm_player == null:
		_bgm_player = AudioStreamPlayer.new()
		_bgm_player.bus = "BGM"
		_bgm_player.name = "BgmPlayer"
		add_child(_bgm_player)
	_bgm_player.stream = stream
	# OGG 等流媒体支持的 loop 由 stream.loop 控制
	if "loop" in stream:
		stream.set("loop", bool(entry.get("loop", false)))
	_bgm_player.volume_db = volume_db if volume_db != INF else _bgm_volume_db
	# 若已设置过静音，强制覆盖新启动 BGM 的音量
	if _bgm_muted:
		_bgm_player.volume_db = -80.0
	if not _bgm_player.playing:
		_bgm_player.play()

## 停止 BGM
func stop_bgm() -> void:
	if _bgm_player != null and _bgm_player.playing:
		_bgm_player.stop()

## 设置全局静音（SFX）。通过静音整个 SFX 音频总线实现，对所有
## 后续 SFX 播放（无论是否新创建 AudioStreamPlayer）立即生效。
func set_mute(muted: bool) -> void:
	if _muted == muted:
		return
	_muted = muted
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, muted)
	# 兼容旧的占位 _sfx_bus（不再使用，但保留赋值避免引用空对象）
	if _sfx_bus != null:
		_sfx_bus.volume_db = -80.0 if muted else 0.0
	mute_changed.emit(muted)

## 设置 BGM 静音。始终记录 _bgm_muted 状态，下次 play_bgm 时也会读取。
func set_bgm_mute(muted: bool) -> void:
	_bgm_muted = muted
	if _bgm_player == null:
		return
	_bgm_player.volume_db = -80.0 if muted else _bgm_volume_db

func is_muted() -> bool:
	return _muted

func is_bgm_muted() -> bool:
	return _bgm_muted

## 元素 → 攻击音效
func play_attack_by_element(element: String) -> void:
	var key: String = ELEMENT_ATTACK_SFX.get(element, "attack_fire_cub_pounce")
	play_sfx(key)

## 元素 → 消除音效
func play_match_by_element(element: String) -> void:
	var key: String = ELEMENT_MATCH_SFX.get(element, "match_eliminate_3_rounded")
	play_sfx(key)

## 按 3/4/5 连选基础消除音
func play_match_by_count(count: int) -> void:
	var key: String
	if count >= 5:
		key = "match_eliminate_5_rounded"
	elif count == 4:
		key = "match_eliminate_4_rounded"
	else:
		key = "match_eliminate_3_rounded"
	play_sfx(key)

## 按 combo 层数选 combo 音（1~5）
func play_combo(level: int) -> void:
	var clamped: int = clampi(level, 1, 5)
	play_sfx("combo_%d_soft_rise" % clamped)

## ========== 内部 ==========

func _init_buses() -> void:
	# 确保 SFX / BGM AudioBus 存在（不强依赖 .tres，由 Godot 在缺失时用默认 Master）
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	if AudioServer.get_bus_index("BGM") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "BGM")
	_sfx_bus = AudioStreamPlayer.new()
	_sfx_bus.bus = "SFX"
	add_child(_sfx_bus)

func _get_stream(path: String) -> AudioStream:
	if _resource_cache.has(path):
		return _resource_cache[path] as AudioStream
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream != null:
		_resource_cache[path] = stream
	return stream

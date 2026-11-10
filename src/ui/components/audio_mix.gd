class_name AudioMix
extends RefCounted
## 音频混音总线：Master ← BGM / SFX / Button。
##
## 所有总线电平与限制器参数集中在 `CONFIG` 一处，播放器只声明自己属于哪条总线：
## - `Master` 是默认输出总线（索引 0），末端挂峰值限制器；
## - `BGM` / `SFX` / `Button` 是三条子总线，分别发送到 `Master`；
## - 基准线性增益 0.55 / 0.80 / 0.70，换算成 dB 后写入 AudioServer；
## - 设置页三条滑块（0–100%，步长 10%）作为倍率乘在基准上；
## - `ensure_buses()` 幂等：运行时不依赖 `default_bus_layout.tres`，场景切换后总线仍在。
##
## 峰值限制口径：
## - 限制器使用 `AudioEffectHardLimiter`，`ceiling_db = -3.0`；
## - 多音叠加时 Master 输出峰值不超过 -3 dBFS（线性约 0.708），任何采样点不越界；
## - 限制器只作用于 Master，不改变各子总线的默认电平。
##
## 关闭某一层（设置页 `musicOn` / `soundOn`）时只释放该层的播放器，
## 不改动任何总线的音量，因此另外两层不受影响。
## 滑块 0% 只静音该层总线，另外两层的 dB 与 mute 状态保持不变；
## 100% 时总线 dB 与只有基准增益时逐位相同。

const MASTER_BUS := "Master"
const BGM_BUS := "BGM"
const SFX_BUS := "SFX"
const BUTTON_BUS := "Button"
const BUTTON_SOUND_ID := "button_click"
const VOLUME_STEP := 10
const VOLUME_DEFAULT := 100

## 总线与限制器的唯一配置源：新增/调整电平只改这里。
## `settings_key` 是对应的设置页滑块存档键，0–100 的百分比。
const CONFIG := {
	"buses": {
		"BGM": {"volume": 0.55, "settings_key": "bgmVolume"},
		"SFX": {"volume": 0.80, "settings_key": "sfxVolume"},
		"Button": {"volume": 0.70, "settings_key": "buttonVolume"},
	},
	"limiter": {
		"ceiling_db": -3.0,
		"release": 0.1,
	},
}


## 幂等地把三条子总线与 Master 限制器装到 AudioServer 上，并按存档滑块值应用电平。
## 总线已存在时只重新应用电平；主总线只保留一个限制器。
static func ensure_buses() -> void:
	apply_settings(_load_saved_settings())


## 把设置字典里的三条滑块值实时写到 AudioServer。
## 0% 只静音对应子总线；其它子总线的 dB 与 mute 不变。
static func apply_settings(settings: Dictionary) -> void:
	_create_buses()
	for bus_name: String in CONFIG["buses"].keys():
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var base := bus_volume(bus_name)
		var percent := volume_percent(settings, bus_name)
		# 先写基准 dB，保证 100% 与基准版本逐位一致；0% 再单独 mute。
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(base))
		AudioServer.set_bus_mute(bus_index, percent <= 0)
		if percent > 0:
			AudioServer.set_bus_volume_db(
				bus_index, linear_to_db(base * float(percent) / float(VOLUME_DEFAULT))
			)


## 设置页音效开关对应的总线：按钮点击走 Button 子总线，其余战斗音走 SFX。
static func bus_for_sound(sound_id: String) -> String:
	return BUTTON_BUS if sound_id == BUTTON_SOUND_ID else SFX_BUS


## 某条总线的配置线性增益（滑块 100% 时的固定基准，不随存档变化）。
static func bus_volume(bus_name: String) -> float:
	var buses: Dictionary = CONFIG["buses"]
	return float(buses.get(bus_name, {}).get("volume", 1.0))


## 某条总线对应的设置页滑块存档键。
static func volume_key(bus_name: String) -> String:
	var buses: Dictionary = CONFIG["buses"]
	return str(buses.get(bus_name, {}).get("settings_key", ""))


## 把任意存档值规范成 0–100、步长 10 的整数百分比。
static func normalize_percent(value) -> int:
	var percent := VOLUME_DEFAULT
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			percent = int(round(float(value)))
		TYPE_STRING:
			var text := str(value).strip_edges()
			if text.is_valid_float():
				percent = int(round(float(text)))
	var stepped := int(round(float(percent) / float(VOLUME_STEP))) * VOLUME_STEP
	return clampi(stepped, 0, VOLUME_DEFAULT)


## 设置字典中某条总线的滑块百分比；缺少该键时按 100% 处理。
static func volume_percent(settings: Dictionary, bus_name: String) -> int:
	var key := volume_key(bus_name)
	if key.is_empty():
		return VOLUME_DEFAULT
	return normalize_percent(settings.get(key, VOLUME_DEFAULT))


## 滑块倍率乘上基准后的线性增益；0% 时为 0。
static func effective_volume(bus_name: String, settings: Dictionary) -> float:
	return bus_volume(bus_name) * float(volume_percent(settings, bus_name)) / float(VOLUME_DEFAULT)


## 限制器 ceiling 对应的线性峰值；导出 PCM 的 `|x| <= max_peak_linear()` 即通过。
static func max_peak_linear() -> float:
	return db_to_linear(float(CONFIG["limiter"]["ceiling_db"]))


static func _create_buses() -> void:
	for bus_name: String in CONFIG["buses"].keys():
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			AudioServer.add_bus()
			bus_index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, MASTER_BUS)
	_ensure_master_limiter()


## 从存档读取设置，用于场景切换后重新创建播放器时恢复滑块值。
## 没有 SaveManager（例如纯单元测试）时按默认 100% 处理。
static func _load_saved_settings() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return {}
	var save_manager := tree.root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_method("load_settings"):
		return {}
	var settings = save_manager.load_settings()
	return settings if settings is Dictionary else {}


static func _ensure_master_limiter() -> void:
	var master_index := AudioServer.get_bus_index(MASTER_BUS)
	if master_index < 0:
		return
	var limiter: AudioEffectHardLimiter = null
	for effect_index in range(AudioServer.get_bus_effect_count(master_index)):
		var effect := AudioServer.get_bus_effect(master_index, effect_index)
		if effect is AudioEffectHardLimiter:
			limiter = effect
			break
	if limiter == null:
		limiter = AudioEffectHardLimiter.new()
		limiter.resource_name = "MasterPeakLimiter"
		AudioServer.add_bus_effect(master_index, limiter)
	limiter.ceiling_db = float(CONFIG["limiter"]["ceiling_db"])
	limiter.release = float(CONFIG["limiter"]["release"])
	limiter.pre_gain_db = 0.0

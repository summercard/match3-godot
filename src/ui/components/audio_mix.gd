class_name AudioMix
extends RefCounted
## 音频混音总线：Master ← BGM / SFX / Button。
##
## 所有总线电平与限制器参数集中在 `CONFIG` 一处，播放器只声明自己属于哪条总线：
## - `Master` 是默认输出总线（索引 0），末端挂峰值限制器；
## - `BGM` / `SFX` / `Button` 是三条子总线，分别发送到 `Master`；
## - 默认线性增益 0.55 / 0.80 / 0.70，换算成 dB 后写入 AudioServer；
## - `ensure_buses()` 幂等：运行时不依赖 `default_bus_layout.tres`，场景切换后总线仍在。
##
## 峰值限制口径：
## - 限制器使用 `AudioEffectHardLimiter`，`ceiling_db = -3.0`；
## - 多音叠加时 Master 输出峰值不超过 -3 dBFS（线性约 0.708），任何采样点不越界；
## - 限制器只作用于 Master，不改变各子总线的默认电平。
##
## 关闭某一层（设置页 `musicOn` / `soundOn`）时只释放该层的播放器，
## 不改动任何总线的音量，因此另外两层不受影响。

const MASTER_BUS := "Master"
const BGM_BUS := "BGM"
const SFX_BUS := "SFX"
const BUTTON_BUS := "Button"
const BUTTON_SOUND_ID := "button_click"

## 总线与限制器的唯一配置源：新增/调整电平只改这里。
const CONFIG := {
	"buses": {
		"BGM": {"volume": 0.55},
		"SFX": {"volume": 0.80},
		"Button": {"volume": 0.70},
	},
	"limiter": {
		"ceiling_db": -3.0,
		"release": 0.1,
	},
}


## 幂等地把三条子总线与 Master 限制器装到 AudioServer 上。
## 总线已存在时只重新应用电平；主总线只保留一个限制器。
static func ensure_buses() -> void:
	for bus_name: String in CONFIG["buses"].keys():
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			AudioServer.add_bus()
			bus_index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, MASTER_BUS)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(bus_volume(bus_name)))
		AudioServer.set_bus_mute(bus_index, false)
	_ensure_master_limiter()


## 设置页音效开关对应的总线：按钮点击走 Button 子总线，其余战斗音走 SFX。
static func bus_for_sound(sound_id: String) -> String:
	return BUTTON_BUS if sound_id == BUTTON_SOUND_ID else SFX_BUS


## 某条总线的配置线性增益。
static func bus_volume(bus_name: String) -> float:
	var buses: Dictionary = CONFIG["buses"]
	return float(buses.get(bus_name, {}).get("volume", 1.0))


## 限制器 ceiling 对应的线性峰值；导出 PCM 的 `|x| <= max_peak_linear()` 即通过。
static func max_peak_linear() -> float:
	return db_to_linear(float(CONFIG["limiter"]["ceiling_db"]))


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

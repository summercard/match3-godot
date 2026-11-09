extends Node
## 震动反馈层：把设置页的 `vibrationOn` 接到四类事件，并统计请求/丢弃次数。
##
## 所有可调参数集中在本文件 CONFIG：总开关默认值、四类事件的强度与时长。
## 强度为 0.0-1.0，时长单位为毫秒；四类档位至少强度与时长两项参数不同。
##
## 总开关每帧同步设置页（`vibrationOn`），运行中切换下一帧生效：
## - 关闭时 `request()` 不发出任何请求，只累计 `dropped_count`；
## - 桌面/headless 没有马达时 `Input.vibrate_handheld()` 本身是空操作，
##   但请求仍会累计到 `request_count`，因此可以逐次断言。
##
## 作为 Autoload 挂载；按钮事件通过 `wire_buttons()` 统一接线，
## 自定义绘制的按钮（设置页、战斗底栏）直接在点击处调用 `request("button_tap")`。

const EVENT_IDS := ["skill_cast", "victory", "defeat", "button_tap"]

const CONFIG := {
	# 设置页缺少 vibrationOn 时的默认总开关。
	"enabled": true,
	# strength：马达强度 0.0-1.0；duration_ms：震动时长（毫秒）。
	"profiles": {
		"skill_cast": {
			"label": "技能释放",
			"strength": 0.60,
			"duration_ms": 40,
		},
		"victory": {
			"label": "战斗胜利",
			"strength": 0.90,
			"duration_ms": 160,
		},
		"defeat": {
			"label": "战斗失败",
			"strength": 0.75,
			"duration_ms": 240,
		},
		"button_tap": {
			"label": "按钮点击",
			"strength": 0.30,
			"duration_ms": 18,
		},
	},
}

## 总开关，由设置页 `vibrationOn` 每帧同步。
var enabled: bool = bool(CONFIG["enabled"])
## 实际发出的振动请求数（不受平台是否支持马达影响）。
var request_count: int = 0
## 被丢弃的请求数：总开关关闭，或事件 id 不在 CONFIG.profiles 内。
var dropped_count: int = 0
## 四类事件各自的请求数。
var event_counts: Dictionary = {}
## 最近一次请求/丢弃的事件与参数，便于测试和现场排查。
var last_event: String = ""
var last_strength: float = 0.0
var last_duration_ms: int = 0
var last_dropped_event: String = ""


func _ready() -> void:
	_reset_event_counts()
	set_process(true)
	sync_from_settings()


## 每帧轻量检查设置页开关，运行中切换 vibrationOn 时下一帧立即生效。
func _process(_delta: float) -> void:
	sync_from_settings()


func sync_from_settings() -> void:
	apply_settings(_load_settings())


func apply_settings(settings: Dictionary) -> void:
	set_enabled(vibration_on_from_settings(settings))


## 供 headless 断言直接复用设置映射口径；缺少 vibrationOn 时沿用 CONFIG.enabled。
static func vibration_on_from_settings(settings: Dictionary) -> bool:
	return bool(settings.get("vibrationOn", CONFIG["enabled"]))


func set_enabled(value: bool) -> void:
	enabled = value


## 发出一次震动请求。总开关关闭或事件未配置时返回 false 并累计 dropped_count。
## 请求计数先于平台调用完成，桌面/headless 无马达时同样可测。
func request(event_id: String) -> bool:
	var profiles: Dictionary = CONFIG["profiles"]
	if not profiles.has(event_id):
		dropped_count += 1
		last_dropped_event = event_id
		return false
	if not enabled:
		dropped_count += 1
		last_dropped_event = event_id
		return false

	var profile: Dictionary = profiles[event_id]
	var strength := clampf(float(profile.get("strength", 0.5)), 0.0, 1.0)
	var duration_ms := maxi(1, int(profile.get("duration_ms", 50)))
	request_count += 1
	event_counts[event_id] = int(event_counts.get(event_id, 0)) + 1
	last_event = event_id
	last_strength = strength
	last_duration_ms = duration_ms
	Input.vibrate_handheld(duration_ms, strength)
	return true


func reset_counters() -> void:
	request_count = 0
	dropped_count = 0
	last_event = ""
	last_strength = 0.0
	last_duration_ms = 0
	last_dropped_event = ""
	_reset_event_counts()


func profile_for(event_id: String) -> Dictionary:
	var profiles: Dictionary = CONFIG["profiles"]
	return profiles.get(event_id, {})


## 给场景树里的原生按钮统一接线：所有 BaseButton 的 pressed → button_tap。
## 自定义绘制的按钮不在节点树里，由各自点击处理直接调用 request("button_tap")。
func wire_buttons(scene_root: Node) -> int:
	if scene_root == null:
		return 0
	var wired := 0
	for child: Node in scene_root.find_children("*", "BaseButton", true, false):
		var button := child as BaseButton
		if button == null:
			continue
		if button.pressed.is_connected(_on_ui_button_pressed):
			continue
		button.pressed.connect(_on_ui_button_pressed)
		wired += 1
	return wired


func _on_ui_button_pressed() -> void:
	request("button_tap")


func _load_settings() -> Dictionary:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_settings"):
		return save_manager.load_settings()
	return {}


func _reset_event_counts() -> void:
	event_counts = {}
	for event_id: String in EVENT_IDS:
		event_counts[event_id] = 0

class_name BattleHitReaction
extends RefCounted
## 战斗受击反应与血条缓降：参数集中在本文件 CONFIG，`enabled` 是总开关。
##
## 表现口径（需求）：
## - 伙伴 / 怪物挨打：0.2s 抖动 + 闪白；
## - 血条在 0.25s 内缓降到新值，不许瞬跳；
## - 总开关关闭时完全不产生抖动、闪白与缓降，直接回到原表现。
##
## 本文件只做表现层计算，不读写战斗数值、伤害日志或结算统计。

const CONFIG := {
	"hit": {
		"shake_duration": 0.20,
		"shake_amplitude": 6.0,
		"flash_duration": 0.20,
		"flash_alpha": 0.85
	},
	"hp": {
		"ease_duration": 0.25
	}
}

## 总开关：关掉后不触发任何受击反应，血条立即跳到目标值。
static var enabled: bool = true

const FLASH_SHADER := preload("res://assets/shaders/hit_flash.gdshader")


## 一次受击的总时长取抖动与闪白中较长者，两者都按各自时长独立衰减。
static func hit_duration() -> float:
	var hit: Dictionary = CONFIG["hit"]
	return maxf(float(hit["shake_duration"]), float(hit["flash_duration"]))


static func hp_ease_duration() -> float:
	return float(CONFIG["hp"]["ease_duration"])


## 触发某个目标的受击反应；同一目标连续受击时从当前帧重新开始。
static func trigger(entries: Array, is_enemy: bool, index: int) -> Dictionary:
	if not enabled or index < 0:
		return {}
	var hit: Dictionary = CONFIG["hit"]
	var duration := hit_duration()
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("monsterIndex", -1)) == index:
			entries.remove_at(i)
	var entry := {
		"isEnemy": is_enemy,
		"monsterIndex": index,
		"timer": duration,
		"duration": duration,
		"shake_duration": float(hit["shake_duration"]),
		"shake_amplitude": float(hit["shake_amplitude"]),
		"flash_duration": float(hit["flash_duration"]),
		"flash_alpha": float(hit["flash_alpha"])
	}
	entries.append(entry)
	return entry


## 推进受击反应计时；总开关关闭时清空所有残留，避免留下抖动/闪白。
static func tick(entries: Array, dt: float) -> void:
	if not enabled:
		entries.clear()
		return
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		entry["timer"] = maxf(0.0, float(entry.get("timer", 0.0)) - dt)
		if float(entry["timer"]) <= 0.0:
			entries.remove_at(i)


static func find(entries: Array, is_enemy: bool, index: int) -> Dictionary:
	for entry in entries:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("monsterIndex", -1)) == index:
			return entry
	return {}


## 抖动位移：按受击进度做衰减的正弦摆动，单帧长度不超过配置振幅。
static func shake_offset(entry: Dictionary) -> Vector2:
	if entry.is_empty():
		return Vector2.ZERO
	var duration := maxf(float(entry.get("shake_duration", 0.0)), 0.001)
	var elapsed := float(entry.get("duration", duration)) - float(entry.get("timer", duration))
	if elapsed >= duration:
		return Vector2.ZERO
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var decay := 1.0 - progress
	var amplitude := float(entry.get("shake_amplitude", 0.0))
	return Vector2(
		sin(progress * TAU * 5.0),
		cos(progress * TAU * 6.5)
	) * amplitude * decay


## 闪白强度：从配置峰值线性衰减到 0。
static func flash_alpha(entry: Dictionary) -> float:
	if entry.is_empty():
		return 0.0
	var duration := maxf(float(entry.get("flash_duration", 0.0)), 0.001)
	var elapsed := float(entry.get("duration", duration)) - float(entry.get("timer", duration))
	if elapsed >= duration:
		return 0.0
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	return float(entry.get("flash_alpha", 0.0)) * (1.0 - progress)


## 血条缓降曲线：0–1 进度映射到 0–1 的缓出插值。
static func ease_progress(progress: float) -> float:
	var clamped := clampf(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - clamped, 3.0)


static func eased_value(from_value: float, to_value: float, elapsed: float, duration: float) -> float:
	if duration <= 0.0:
		return to_value
	return lerpf(from_value, to_value, ease_progress(elapsed / duration))


## GUI 头像闪白材质；每个头像独享一个 ShaderMaterial。
static func new_flash_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FLASH_SHADER
	material.set_shader_parameter("flash_amount", 0.0)
	return material

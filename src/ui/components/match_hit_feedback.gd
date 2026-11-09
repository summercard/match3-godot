class_name MatchHitFeedback
extends RefCounted
## 三消消除命中反馈：顿帧 + 微震屏 + 元素爆散。
##
## 所有可调参数集中在本文件 CONFIG；`enabled` 是总开关。
## 关闭总开关时，战斗场景不会插入任何等待、震屏或新增粒子，
## 消除/下落时序与旧版逐帧一致。
##
## 目标区间（需求口径）：
## - 普通消除：顿帧 60–90ms，棋盘位移 ≤6px，整段 ≤0.15s
## - 4 连锁及以上：顿帧 120–160ms，棋盘位移 ≤10px

const CONFIG := {
	"normal": {
		"hitstop": 0.075,
		"shake_duration": 0.06,
		"shake_amplitude": 5.0
	},
	"chain": {
		"min_chain": 4,
		"hitstop": 0.14,
		"shake_duration": 0.10,
		"shake_amplitude": 9.0
	},
	"normal_beat_max": 0.15,
	"burst": {
		"particles_per_gem": 12,
		"core_particles": 3,
		"speed": 190.0,
		"life": 0.24,
		"size": 5.5,
		"glow_duration": 0.14,
		"glow_alpha": 0.85,
		"glow_radius": 0.95
	}
}

## 总开关：关掉后完全回到旧时序（无顿帧 / 震屏 / 爆散）。
static var enabled: bool = true


## 按连锁等级取本档命中反馈配置；总开关关闭时返回空字典，
## 调用方据此整段跳过，不产生任何额外等待或位移。
static func resolve(chain_level: int) -> Dictionary:
	if not enabled:
		return {}
	var tier_key := "chain" if chain_level >= int(CONFIG["chain"]["min_chain"]) else "normal"
	var tier: Dictionary = CONFIG[tier_key]
	return {
		"tier": tier_key,
		"hitstop": float(tier["hitstop"]),
		"shake_duration": float(tier["shake_duration"]),
		"shake_amplitude": float(tier["shake_amplitude"]),
		"beat": maxf(
			float(tier["hitstop"]) + float(tier["shake_duration"]),
			float(CONFIG["burst"]["glow_duration"])
		),
		"burst": CONFIG["burst"]
	}


## 关闭总开关时额外等待恒为 0，供基线时序断言使用。
static func added_delay(chain_level: int) -> float:
	return float(resolve(chain_level).get("hitstop", 0.0))


## 命中震屏：振幅随剩余时间线性衰减，单帧位移长度不超过 amplitude。
## rng 由战斗场景传入独立的表现层随机源，避免帧数变化影响战斗逻辑随机数。
static func update_shake(timer: float, duration: float, amplitude: float, dt: float, rng: RandomNumberGenerator = null) -> Dictionary:
	if not enabled or timer <= 0.0 or duration <= 0.0 or amplitude <= 0.0:
		return {"timer": 0.0, "offset": Vector2.ZERO}
	timer = maxf(0.0, timer - dt)
	if timer <= 0.0:
		return {"timer": 0.0, "offset": Vector2.ZERO}
	var intensity: float = clampf(timer / duration, 0.0, 1.0)
	var angle: float
	if rng != null:
		angle = rng.randf() * TAU
	else:
		angle = randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * amplitude * intensity
	return {"timer": timer, "offset": offset}

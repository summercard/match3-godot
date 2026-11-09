class_name PresentationProfile
extends RefCounted

## 表现层档位映射（唯一配置处）
##
## 设置页两个档位在这里翻译成战斗可直接使用的参数：
## - performanceMode（轻量 / 均衡 / 华丽）：粒子倍率、震屏倍率与震屏上限、飘字错峰层数；
## - qualityLevel（流畅 / 标准 / 精细）：特效密度倍率。
##
## 这套映射只影响画面表现，不参与伤害、承伤、回合或战斗随机数；
## 不创建任何常驻节点。战斗场景每帧重新解析设置，切档后下一帧生效；
## 映射本身不保存运行时状态，因此离开战斗后不会把档位带进大厅。
##
## 数值口径：
## - 均衡档 = 接通设置前的基准表现（粒子 1.0、震屏 1.0、飘字 3 层）；
## - 轻量档粒子与震屏都减半，且飘字只保留 1 层；
## - 华丽档粒子更多、震屏略强，但受各自上限约束；
## - 精细画质 = 特效密度 1.0；标准 / 流畅依次降低，与战斗表现档相乘。

const DEFAULT_QUALITY := "high"
const DEFAULT_PERFORMANCE := "balanced"

const QUALITY_LEVELS := {
	"low": {
		"label": "流畅",
		"effect_density": 0.5,
	},
	"medium": {
		"label": "标准",
		"effect_density": 0.75,
	},
	"high": {
		"label": "精细",
		"effect_density": 1.0,
	},
}

const PERFORMANCE_MODES := {
	"lite": {
		"label": "轻量",
		"particle_scale": 0.5,
		"shake_scale": 0.5,
		"shake_cap_px": 5.0,
		"popup_layers": 1,
	},
	"balanced": {
		"label": "均衡",
		"particle_scale": 1.0,
		"shake_scale": 1.0,
		"shake_cap_px": 10.0,
		"popup_layers": 3,
	},
	"rich": {
		"label": "华丽",
		"particle_scale": 1.5,
		"shake_scale": 1.25,
		"shake_cap_px": 12.0,
		"popup_layers": 3,
	},
}

## 把设置字典解析成战斗使用的表现参数；缺失或未知值回落到默认档。
## effect_density 是画质密度与战斗表现粒子倍率的乘积，调用方只需读这一项。
static func from_settings(settings: Dictionary) -> Dictionary:
	var quality_key := _normalize_key(
		str(settings.get("qualityLevel", DEFAULT_QUALITY)), QUALITY_LEVELS, DEFAULT_QUALITY
	)
	var performance_key := _normalize_key(
		str(settings.get("performanceMode", DEFAULT_PERFORMANCE)), PERFORMANCE_MODES, DEFAULT_PERFORMANCE
	)
	var quality: Dictionary = QUALITY_LEVELS[quality_key]
	var performance: Dictionary = PERFORMANCE_MODES[performance_key]
	var quality_density := float(quality.get("effect_density", 1.0))
	var particle_scale := float(performance.get("particle_scale", 1.0))
	return {
		"quality": quality_key,
		"quality_label": str(quality.get("label", "")),
		"quality_effect_density": quality_density,
		"performance": performance_key,
		"performance_label": str(performance.get("label", "")),
		"performance_particle_scale": particle_scale,
		"effect_density": quality_density * particle_scale,
		"shake_scale": float(performance.get("shake_scale", 1.0)),
		"shake_cap_px": float(performance.get("shake_cap_px", 0.0)),
		"popup_layers": clampi(int(performance.get("popup_layers", 3)), 1, 3),
	}

## 按当前特效密度缩放基准粒子数。向下取整保证轻量档确实更省；
## 至少保留 minimum 粒，避免“有事件但完全看不到反馈”。
static func scaled_particle_count(base_count: int, profile: Dictionary, minimum: int = 1) -> int:
	var density := maxf(0.0, float(profile.get("effect_density", 1.0)))
	return maxi(minimum, int(floor(float(base_count) * density)))

## 把单次震屏位移限制在档位上限内，不改变方向。
static func clamp_shake(offset: Vector2, profile: Dictionary) -> Vector2:
	var cap := float(profile.get("shake_cap_px", 0.0))
	if cap <= 0.0:
		return offset
	return offset.limit_length(cap)

static func _normalize_key(raw: String, table: Dictionary, fallback: String) -> String:
	return raw if table.has(raw) else fallback

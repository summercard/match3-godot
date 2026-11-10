class_name DamageFeedback
extends RefCounted
## 战斗伤害反馈升级：漫画超粗飘字 + 血条白段扣血。
##
## 本文件是这一轮表现升级的唯一参数来源，`enabled` 是总开关：
## - 开启：飘字用 Impact → Arial Black → 泛型 sans-serif（字重 900）+ 近黑描边，
##   字号 21 / 26 / 32，单体上升 30px、多敌横排 12px；血条红条先落位，
##   白段停 0.22s 后按 0.55 条/秒追上，血量 <30% 时红条 1.2Hz / 8% 脉冲。
## - 关闭：飘字与血条都回到基线 2f50f09 的表现（旧字号、旧上升、
##   旧 0.25s 血条缓降，没有白段与脉冲）。
##
## 只做表现层：不读写伤害公式、关卡 / 怪物数据、战斗随机数、日志或结算统计。
## 飘字随机量只在调用方生成一次并写进飘字数据，渲染阶段不再取随机数，
## 因此同一 context 的重复渲染位置逐位一致。

## 总开关：关闭时回到基线表现，战斗日志与结算 JSON 与基线逐位一致。
static var enabled: bool = true

## 字体链：Impact → Arial Black → 泛型 sans-serif（链尾保留泛型族名）。
## 字重 900 交给系统字体匹配最粗一档；Impact 缺中文字形时由系统回退补齐。
const FONT_NAMES: Array[String] = ["Impact", "Arial Black", "sans-serif"]
const FONT_WEIGHT := 900

## 描边：近黑 #050508，约为字高的 11%；普通 2px，重击 / 暴击 3px。
const STROKE_COLOR := Color("#050508")
const STROKE_NORMAL := 2.0
const STROKE_HEAVY := 3.0
const STROKE_CRIT := 3.0

## 飘字节奏：0.04s 快显、0.62 起淡出、0.12s 错峰、最多 3 层。
const FADE_IN := 0.04
const FADE_OUT_START := 0.62
const STAGGER := 0.12
const MAX_LAYERS := 3

## 上升距离：单体 30px，多敌横排（锚点落在中段）12px。
const RISE_SINGLE := 30.0
const RISE_MULTI := 12.0
const RISE_BAND_THRESHOLD_Y := 100.0

## 只在调用方生成的随机量范围。
const JITTER_PX := 3.0
const RISE_SCALE_MIN := 0.85
const RISE_SCALE_MAX := 1.15
const DRIFT_PX := 6.0
const POP_MIN := 1.28
const POP_MAX := 1.48

## 重击阈值：伤害 >= 40 视为重击（暴击仍优先用暴击样式）。
const HEAVY_DAMAGE_THRESHOLD := 40

const STYLES := {
	"normal": {
		"size": 21.0,
		"duration": 0.85,
		"stroke": STROKE_NORMAL,
		"color": Color(1.0, 0.96, 0.88),
		"prefix": ""
	},
	"heavy": {
		"size": 26.0,
		"duration": 0.85,
		"stroke": STROKE_HEAVY,
		"color": Color(1.0, 0.32, 0.24),
		"prefix": ""
	},
	"crit": {
		"size": 32.0,
		"duration": 0.95,
		"stroke": STROKE_CRIT,
		"color": Color(1.0, 0.28, 0.06),
		"prefix": "暴击"
	},
	"weak": {
		"size": 21.0,
		"duration": 0.85,
		"stroke": STROKE_NORMAL,
		"color": Color(0.68, 0.72, 0.78),
		"prefix": ""
	}
}

## 血条：红条 0.08s 内落位；白段停 0.22s 后按 0.55 条/秒追上；
## 满格追到 0 的追赶时长为 1/0.55 ≈ 1.82s（不含 0.22s 停留）。
const HP_RED_EASE := 0.08
const HP_TRAIL_HOLD := 0.22
const HP_TRAIL_RATE := 0.55
const HP_TRAIL_COLOR := Color(0.97, 0.98, 1.0, 0.95)
const HP_LOW_RATIO := 0.3
const HP_PULSE_HZ := 1.2
const HP_PULSE_AMPLITUDE := 0.08

static var _comic_font: SystemFont = null


## 飘字样式：暴击 > 重击 > 弱效 > 普通。
static func damage_style(critical: bool, weak: bool, heavy: bool = false) -> Dictionary:
	var style_name := "normal"
	if critical:
		style_name = "crit"
	elif heavy:
		style_name = "heavy"
	elif weak:
		style_name = "weak"
	var style: Dictionary = STYLES[style_name]
	return {
		"style": style_name,
		"color": style["color"],
		"size": float(style["size"]),
		"duration": float(style["duration"]),
		"stroke": float(style["stroke"]),
		"prefix": str(style["prefix"])
	}


## 重击判定：暴击由 critical 单独处理，这里只看伤害数值。
static func is_heavy_damage(amount: int) -> bool:
	return amount >= HEAVY_DAMAGE_THRESHOLD


## 单体 / 多敌横排的上升距离，按飘字锚点所在高度区分。
static func rise_for_anchor(anchor_y: float) -> float:
	return RISE_SINGLE if anchor_y < RISE_BAND_THRESHOLD_Y else RISE_MULTI


## 调用方随机量：以 context + 该 context 的第几次飘字为种子，
## 同一 context 的重复渲染会得到完全相同的一组值。
static func popup_random(context: String, ordinal: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d" % [context, ordinal])
	return {
		"jitter": Vector2(
			rng.randf_range(-JITTER_PX, JITTER_PX),
			rng.randf_range(-JITTER_PX, JITTER_PX)
		),
		"rise_scale": rng.randf_range(RISE_SCALE_MIN, RISE_SCALE_MAX),
		"drift": rng.randf_range(-DRIFT_PX, DRIFT_PX),
		"pop": rng.randf_range(POP_MIN, POP_MAX)
	}


## ease-out cubic：飘字上升与弹出回落的共同曲线。
static func ease_out_cubic(progress: float) -> float:
	var clamped := clampf(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - clamped, 3.0)


## 飘字透明度：0.04s 快显 + 0.62 起淡出，其余时间保持不透明。
static func fade_alpha(timer: float, duration: float) -> float:
	var safe_duration := maxf(duration, 0.01)
	var fade_in := clampf(timer / FADE_IN, 0.0, 1.0)
	var fade_out := clampf(
		1.0 - maxf(0.0, timer - safe_duration * FADE_OUT_START) / maxf(0.01, safe_duration * (1.0 - FADE_OUT_START)),
		0.0,
		1.0
	)
	return minf(fade_in, fade_out)


## 弹出缩放：从调用方给定的 1.28–1.48 倍在 0.12s 内回落到 1.0。
static func pop_scale(timer: float, pop: float) -> float:
	if timer >= 0.12:
		return 1.0
	return lerpf(pop, 1.0, ease_out_cubic(timer / 0.12))


## 血条低血脉冲：1.2Hz、幅度 8%，返回红条亮度倍率。
static func pulse_factor(pulse_time: float) -> float:
	return 1.0 + HP_PULSE_AMPLITUDE * sin(pulse_time * TAU * HP_PULSE_HZ)


## 漫画粗体字体：只创建一次，避免每帧分配。
static func comic_font() -> Font:
	if _comic_font == null:
		_comic_font = SystemFont.new()
		_comic_font.font_names = PackedStringArray(FONT_NAMES)
		_comic_font.font_weight = FONT_WEIGHT
		_comic_font.allow_system_fallback = true
	return _comic_font


## 按字高比例换算描边宽度，至少 1px。
static func stroke_width(base_stroke: float, scale: float) -> float:
	return maxf(1.0, base_stroke * scale)


## 画一个居中的描边飘字：先画近黑描边，再画字身。
static func draw_popup_text(
	canvas: CanvasItem,
	text: String,
	center_x: float,
	baseline_y: float,
	size: float,
	color: Color,
	alpha: float,
	stroke: float
) -> void:
	if text.is_empty() or alpha <= 0.0:
		return
	var font := comic_font()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size)
	var pos := Vector2(center_x - text_size.x * 0.5, baseline_y)
	var outline_color := STROKE_COLOR
	outline_color.a = alpha
	var fill_color := color
	fill_color.a *= alpha
	# draw_string_outline 的 size 按光栅像素计；2x 画布下乘上画布缩放，
	# 描边视觉宽度才等于设计的「2px / 3px」。
	var canvas_scale := maxf(1.0, canvas.get_viewport_transform().get_scale().x)
	canvas.draw_string_outline(
		font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size,
		maxi(1, int(round(stroke * canvas_scale))), outline_color
	)
	canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, fill_color)

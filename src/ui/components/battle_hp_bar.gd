class_name BattleHpBar
extends Control

const BattleHitReactionScript = preload("res://src/ui/components/battle_hit_reaction.gd")
const DamageFeedbackScript = preload("res://src/ui/components/damage_feedback.gd")

@export var value: float = 100.0:
	set(next_value):
		value = next_value
		queue_redraw()

@export var maximum: float = 100.0:
	set(next_value):
		maximum = maxf(next_value, 1.0)
		queue_redraw()

@export var fill_color := Color(0.95, 0.12, 0.18, 1.0):
	set(next_color):
		fill_color = next_color
		queue_redraw()

@export var track_color := Color(0.075, 0.105, 0.16, 1.0):
	set(next_color):
		track_color = next_color
		queue_redraw()

## 实际要显示的目标值；`value` 是红条当前绘制值。
## 升级开启时红条在 0.08s 内落位；关闭时沿用基线 0.25s 缓降。
var target_value: float = 100.0
## 白段（旧血量）绘制值：掉血后先停在旧值，再按 0.55 条/秒追上红条。
var trail_value: float = 100.0
var _ease_from: float = 100.0
var _ease_elapsed: float = 0.0
var _easing: bool = false
var _trail_delay: float = 0.0
var _trailing: bool = false
var _pulse_time: float = 0.0
var _initialized: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_initialized = true
	target_value = value
	trail_value = value
	set_process(true)


func _process(delta: float) -> void:
	if not DamageFeedbackScript.enabled:
		# 基线表现：受击反应总开关也接管血条缓动（0.25s 缓出）。
		if not BattleHitReactionScript.enabled:
			if _easing or not is_equal_approx(value, target_value):
				_easing = false
				value = target_value
			trail_value = value
			return
		if not _easing:
			_sync_trail_to_value()
			return
		_ease_elapsed += delta
		var duration := BattleHitReactionScript.hp_ease_duration()
		value = BattleHitReactionScript.eased_value(_ease_from, target_value, _ease_elapsed, duration)
		if _ease_elapsed >= duration:
			value = target_value
			_easing = false
		trail_value = value
		return

	if not BattleHitReactionScript.enabled:
		# 受击反应总开关优先：关闭时血条立即到目标值，不留白段与脉冲。
		_easing = false
		value = target_value
		trail_value = target_value
		_trailing = false
		_trail_delay = 0.0
		return
	_update_red_bar(delta)
	_update_trail(delta)
	_update_pulse(delta)


## 升级后的红条：0.08s 缓出落位（≤0.08s）。
func _update_red_bar(delta: float) -> void:
	if not _easing:
		return
	_ease_elapsed += delta
	value = BattleHitReactionScript.eased_value(
		_ease_from, target_value, _ease_elapsed, DamageFeedbackScript.HP_RED_EASE
	)
	if _ease_elapsed >= DamageFeedbackScript.HP_RED_EASE:
		value = target_value
		_easing = false


## 白段：停留 0.22s 后按 0.55 条/秒追赶；回血由 set_target_value 立即对齐。
func _update_trail(delta: float) -> void:
	if not _trailing:
		if trail_value < value:
			trail_value = value
		return
	var remaining := delta
	if _trail_delay > 0.0:
		var held := minf(_trail_delay, remaining)
		_trail_delay -= held
		remaining -= held
	if remaining <= 0.0:
		return
	var step := DamageFeedbackScript.HP_TRAIL_RATE * maximum * remaining
	trail_value = maxf(target_value, trail_value - step)
	if trail_value <= target_value + 0.001:
		trail_value = target_value
		_trailing = false


## 低血脉冲：只累计红条低于 30% 的时间，回到安全线立即归零。
func _update_pulse(delta: float) -> void:
	if _hp_ratio() < DamageFeedbackScript.HP_LOW_RATIO:
		_pulse_time += delta
	else:
		_pulse_time = 0.0


## 设置新的血条目标值：开启时红条 0.08s 落位、白段留旧值；
## 回血立即对齐；关闭时沿用基线 0.25s 缓降或立即跳转。
func set_target_value(next_value: float) -> void:
	var next := clampf(next_value, 0.0, maximum)
	if not _initialized:
		_initialized = true
		target_value = next
		value = next
		trail_value = next
		return
	if is_equal_approx(next, target_value):
		return
	target_value = next
	if not DamageFeedbackScript.enabled:
		if not BattleHitReactionScript.enabled:
			_easing = false
			value = next
			trail_value = next
			return
		_ease_from = value
		_ease_elapsed = 0.0
		_easing = true
		return
	if not BattleHitReactionScript.enabled:
		_easing = false
		value = next
		trail_value = next
		_trailing = false
		_trail_delay = 0.0
		return
	if next > value:
		# 回血 / 对齐：红条与白段都立即到新值，不留反向白段。
		_easing = false
		value = next
		trail_value = next
		_trailing = false
		_trail_delay = 0.0
		return
	# 掉血：记录旧白段，红条快速落位；白段停 0.22s 后开始追赶。
	trail_value = maxf(trail_value, value)
	_trail_delay = DamageFeedbackScript.HP_TRAIL_HOLD
	_trailing = trail_value > next
	_ease_from = value
	_ease_elapsed = 0.0
	_easing = true


## 兵员 / 波次切换时直接对齐到新目标，不把上一场血条缓动带过来。
func snap_to_value(next_value: float) -> void:
	_initialized = true
	target_value = clampf(next_value, 0.0, maximum)
	_easing = false
	_ease_elapsed = 0.0
	value = target_value
	trail_value = target_value
	_trailing = false
	_trail_delay = 0.0
	_pulse_time = 0.0


func is_easing() -> bool:
	return _easing


func is_trailing() -> bool:
	return _trailing


## 低血脉冲当前亮度倍率；测试与绘制共用同一计算。
func pulse_factor() -> float:
	if _hp_ratio() >= DamageFeedbackScript.HP_LOW_RATIO:
		return 1.0
	return DamageFeedbackScript.pulse_factor(_pulse_time)


func _hp_ratio() -> float:
	return clampf(value / maximum, 0.0, 1.0)


func _sync_trail_to_value() -> void:
	trail_value = value
	_trailing = false
	_trail_delay = 0.0


func _draw() -> void:
	var track_rect := Rect2(Vector2.ZERO, size)
	var radius := size.y * 0.5
	_draw_capsule(track_rect, track_color, radius)
	var ratio := clampf(value / maximum, 0.0, 1.0)
	if DamageFeedbackScript.enabled:
		var trail_ratio := clampf(trail_value / maximum, 0.0, 1.0)
		if trail_ratio > ratio + 0.001:
			var trail_width := maxf(size.y, floor(size.x * trail_ratio))
			_draw_capsule(
				Rect2(0.0, 0.0, minf(trail_width, size.x), size.y),
				DamageFeedbackScript.HP_TRAIL_COLOR,
				radius
			)
	if ratio <= 0.0:
		return
	var pulse := pulse_factor() if DamageFeedbackScript.enabled else 1.0
	var body_color := _pulse_color(fill_color, pulse)
	var edge_color := _pulse_color(fill_color.darkened(0.20), pulse)
	var fill_width := maxf(size.y, floor(size.x * ratio))
	var fill_rect := Rect2(0.0, 0.0, minf(fill_width, size.x), size.y)
	_draw_capsule(fill_rect, edge_color, radius)
	var body_rect := fill_rect.grow(-1.0)
	if body_rect.size.x > 0.0 and body_rect.size.y > 0.0:
		_draw_capsule(body_rect, body_color, maxf(radius - 1.0, 1.0))
	var highlight_rect := Rect2(2.0, 1.0, maxf(fill_rect.size.x - 4.0, 0.0), maxf(size.y * 0.28, 1.0))
	if highlight_rect.size.x > 0.0:
		_draw_capsule(highlight_rect, Color(1.0, 1.0, 1.0, 0.28), highlight_rect.size.y * 0.5)


func _pulse_color(base: Color, pulse: float) -> Color:
	var color := Color(
		clampf(base.r * pulse, 0.0, 1.0),
		clampf(base.g * pulse, 0.0, 1.0),
		clampf(base.b * pulse, 0.0, 1.0),
		base.a
	)
	return color


func _draw_capsule(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	var corner_radius := maxi(int(round(radius)), 1)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	draw_style_box(style, rect)

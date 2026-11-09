class_name BattleHpBar
extends Control

const BattleHitReactionScript = preload("res://src/ui/components/battle_hit_reaction.gd")

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

## 实际要显示的目标值；`value` 是当前绘制值，会按 0.25s 缓动追上去。
var target_value: float = 100.0
var _ease_from: float = 100.0
var _ease_elapsed: float = 0.0
var _easing: bool = false
var _initialized: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_initialized = true
	target_value = value
	set_process(true)


func _process(delta: float) -> void:
	if not BattleHitReactionScript.enabled:
		if _easing or not is_equal_approx(value, target_value):
			_easing = false
			value = target_value
		return
	if not _easing:
		return
	_ease_elapsed += delta
	var duration := BattleHitReactionScript.hp_ease_duration()
	value = BattleHitReactionScript.eased_value(_ease_from, target_value, _ease_elapsed, duration)
	if _ease_elapsed >= duration:
		value = target_value
		_easing = false


## 设置新的血条目标值：开启时从当前绘制值缓降到目标，关闭时立即跳转。
func set_target_value(next_value: float) -> void:
	var next := clampf(next_value, 0.0, maximum)
	if not _initialized:
		_initialized = true
		target_value = next
		value = next
		return
	if is_equal_approx(next, target_value):
		return
	target_value = next
	if not BattleHitReactionScript.enabled:
		_easing = false
		value = next
		return
	_ease_from = value
	_ease_elapsed = 0.0
	_easing = true


## 兵员/波次切换时直接对齐到新目标，不把上一场血条缓动带过来。
func snap_to_value(next_value: float) -> void:
	_initialized = true
	target_value = clampf(next_value, 0.0, maximum)
	_easing = false
	_ease_elapsed = 0.0
	value = target_value


func is_easing() -> bool:
	return _easing


func _draw() -> void:
	var track_rect := Rect2(Vector2.ZERO, size)
	var radius := size.y * 0.5
	_draw_capsule(track_rect, track_color, radius)
	var ratio := clampf(value / maximum, 0.0, 1.0)
	if ratio <= 0.0:
		return
	var fill_width := maxf(size.y, floor(size.x * ratio))
	var fill_rect := Rect2(0.0, 0.0, minf(fill_width, size.x), size.y)
	_draw_capsule(fill_rect, fill_color.darkened(0.20), radius)
	var body_rect := fill_rect.grow(-1.0)
	if body_rect.size.x > 0.0 and body_rect.size.y > 0.0:
		_draw_capsule(body_rect, fill_color, maxf(radius - 1.0, 1.0))
	var highlight_rect := Rect2(2.0, 1.0, maxf(fill_rect.size.x - 4.0, 0.0), maxf(size.y * 0.28, 1.0))
	if highlight_rect.size.x > 0.0:
		_draw_capsule(highlight_rect, Color(1.0, 1.0, 1.0, 0.28), highlight_rect.size.y * 0.5)


func _draw_capsule(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	var corner_radius := maxi(int(round(radius)), 1)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	draw_style_box(style, rect)

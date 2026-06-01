class_name BattleHpBar
extends Control

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


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

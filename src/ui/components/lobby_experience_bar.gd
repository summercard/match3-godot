class_name LobbyExperienceBar
extends Control

@export var value: float = 100.0:
	set(next_value):
		value = next_value
		queue_redraw()

@export var maximum: float = 100.0:
	set(next_value):
		maximum = maxf(next_value, 1.0)
		queue_redraw()

@export var fill_color := Color(0.46, 0.86, 0.16, 1.0):
	set(next_color):
		fill_color = next_color
		queue_redraw()

@export var track_color := Color(0.09, 0.13, 0.19, 1.0):
	set(next_color):
		track_color = next_color
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_visual_profile() -> Dictionary:
	return {
		"style": "lobby_refresh",
		"draws_frame": true,
		"draws_track": true,
		"draws_fill": true,
		"draws_highlight": true,
	}


func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return

	var rect := Rect2(Vector2.ZERO, size)
	var shadow_rect := rect
	shadow_rect.position.y += 1.0
	_draw_capsule(shadow_rect, Color(0.30, 0.13, 0.04, 0.38), size.y * 0.5)

	_draw_capsule(rect, Color(0.96, 0.58, 0.11, 1.0), size.y * 0.5)
	_draw_capsule(rect.grow(-1.0), Color(1.0, 0.88, 0.45, 1.0), maxf(size.y * 0.5 - 1.0, 1.0))
	_draw_capsule(rect.grow(-2.0), Color(0.71, 0.31, 0.07, 1.0), maxf(size.y * 0.5 - 2.0, 1.0))

	var groove := rect.grow(-3.0)
	if groove.size.x <= 0.0 or groove.size.y <= 0.0:
		return
	_draw_capsule(groove, track_color, groove.size.y * 0.5)

	var ratio := clampf(value / maximum, 0.0, 1.0)
	if ratio <= 0.0:
		return

	var fill_rect := groove.grow(-1.0)
	fill_rect.size.x = minf(fill_rect.size.x, maxf(fill_rect.size.y, floor(fill_rect.size.x * ratio)))
	if fill_rect.size.x <= 0.0 or fill_rect.size.y <= 0.0:
		return

	_draw_capsule(fill_rect, fill_color.darkened(0.22), fill_rect.size.y * 0.5)
	var body_rect := fill_rect.grow(-1.0)
	if body_rect.size.x > 0.0 and body_rect.size.y > 0.0:
		_draw_capsule(body_rect, fill_color, body_rect.size.y * 0.5)

	var top_gloss := Rect2(body_rect.position + Vector2(1.0, 1.0), Vector2(maxf(body_rect.size.x - 2.0, 0.0), maxf(body_rect.size.y * 0.35, 1.0)))
	if top_gloss.size.x > 0.0:
		_draw_capsule(top_gloss, Color(1.0, 1.0, 1.0, 0.32), top_gloss.size.y * 0.5)

	var stripe_gap := 9.0
	var stripe_x := body_rect.position.x - body_rect.size.y
	while stripe_x < body_rect.end.x:
		var start := Vector2(stripe_x, body_rect.end.y)
		var finish := Vector2(stripe_x + body_rect.size.y, body_rect.position.y)
		draw_line(start, finish, Color(1.0, 1.0, 1.0, 0.10), 2.0)
		stripe_x += stripe_gap


func _draw_capsule(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	var corner_radius := maxi(int(round(radius)), 1)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	draw_style_box(style, rect)

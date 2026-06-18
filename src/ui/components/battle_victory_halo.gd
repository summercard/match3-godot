extends Control

@export var glow_color := Color(1.0, 0.86, 0.16, 1.0)
@export var ray_color := Color(1.0, 0.96, 0.34, 1.0)

var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.56)
	var pulse := 0.96 + sin(_time * 2.0) * 0.035
	var max_radius := maxf(size.x, size.y) * 0.48 * pulse
	for i in range(10, 0, -1):
		var t := float(i) / 10.0
		var radius := max_radius * t
		var alpha := 0.018 + (1.0 - t) * 0.058
		draw_circle(center, radius, Color(glow_color.r, glow_color.g, glow_color.b, alpha))

	var ray_count := 22
	for i in range(ray_count):
		var angle := _time * 0.18 + TAU * float(i) / float(ray_count)
		var wave := sin(_time * 1.4 + float(i) * 0.83)
		var half_width := 0.035 + 0.014 * wave
		var inner := max_radius * 0.12
		var outer := max_radius * (0.82 + 0.12 * sin(_time * 1.15 + float(i)))
		var points := PackedVector2Array([
			center + Vector2(cos(angle - half_width), sin(angle - half_width)) * inner,
			center + Vector2(cos(angle), sin(angle)) * outer,
			center + Vector2(cos(angle + half_width), sin(angle + half_width)) * inner,
		])
		var color := ray_color.lerp(glow_color, 0.45 + 0.25 * wave)
		color.a = 0.14
		draw_colored_polygon(points, color)

	for i in range(5):
		var radius := max_radius * (0.10 + float(i) * 0.07)
		var alpha := 0.15 - float(i) * 0.02
		draw_circle(center, radius, Color(1.0, 0.96, 0.40, alpha))

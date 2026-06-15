extends Control

@export var base_color := Color(1.0, 0.86, 0.18, 1.0)
@export var accent_color := Color(0.62, 1.0, 0.18, 1.0)

var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.42)
	var pulse := 0.92 + sin(_time * 2.1) * 0.05
	var max_radius := minf(size.x, size.y) * 0.62 * pulse
	for i in range(8, 0, -1):
		var t := float(i) / 8.0
		var radius := max_radius * t
		var alpha := 0.03 + (1.0 - t) * 0.052
		draw_circle(center, radius, Color(base_color.r, base_color.g, base_color.b, alpha))

	var ray_count := 18
	for i in range(ray_count):
		var angle := _time * 0.22 + TAU * float(i) / float(ray_count)
		var half_width := 0.045 + 0.015 * sin(_time * 1.7 + float(i))
		var inner := max_radius * 0.16
		var outer := max_radius * (0.82 + 0.10 * sin(_time * 1.3 + float(i) * 0.9))
		var points := PackedVector2Array([
			center + Vector2(cos(angle - half_width), sin(angle - half_width)) * inner,
			center + Vector2(cos(angle), sin(angle)) * outer,
			center + Vector2(cos(angle + half_width), sin(angle + half_width)) * inner,
		])
		var color := accent_color.lerp(base_color, 0.55 + 0.25 * sin(_time + float(i)))
		color.a = 0.13
		draw_colored_polygon(points, color)

	for i in range(5):
		var radius := max_radius * (0.10 + float(i) * 0.08)
		var alpha := 0.16 - float(i) * 0.022
		draw_circle(center, radius, Color(1.0, 0.96, 0.38, alpha))

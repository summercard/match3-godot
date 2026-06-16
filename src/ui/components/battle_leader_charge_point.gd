class_name BattleLeaderChargePoint
extends Control

@export_range(0.0, 1.0, 0.01) var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

@export var element: String = "fire":
	set(value):
		element = value
		queue_redraw()

@export_range(1, 8, 1) var point_count: int = 5:
	set(value):
		point_count = clampi(value, 1, 8)
		queue_redraw()

var _pulse: float = 0.0

const COLORS := {
	"fire": Color(1.0, 0.34, 0.12, 1.0),
	"water": Color(0.20, 0.62, 1.0, 1.0),
	"grass": Color(0.34, 0.88, 0.30, 1.0),
	"thunder": Color(1.0, 0.86, 0.16, 1.0),
	"light": Color(1.0, 0.96, 0.58, 1.0),
	"earth": Color(0.72, 0.50, 0.25, 1.0),
	"wind": Color(0.58, 0.92, 0.82, 1.0),
	"dark": Color(0.42, 0.25, 0.72, 1.0),
	"ice": Color(0.62, 0.92, 1.0, 1.0),
	"void": Color(0.55, 0.36, 0.95, 1.0),
	"temporal": Color(0.54, 0.78, 1.0, 1.0),
	"star": Color(1.0, 0.86, 0.34, 1.0),
	"chaos": Color(0.95, 0.22, 0.70, 1.0),
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	if progress > 0.0:
		queue_redraw()


func _draw() -> void:
	if point_count <= 0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var color: Color = COLORS.get(element, Color(1.0, 0.75, 0.24, 1.0))
	var full := progress >= 1.0
	var gap := 1.4
	var diameter := minf(size.y - 1.2, (size.x - gap * float(point_count - 1)) / float(point_count))
	var radius := maxf(2.0, diameter * 0.5)
	var total_w := diameter * float(point_count) + gap * float(point_count - 1)
	var start_x := (size.x - total_w) * 0.5 + radius
	var center_y := size.y * 0.5
	var fill_progress := clampf(progress * float(point_count), 0.0, float(point_count))
	var pulse := 0.5 + 0.5 * sin(_pulse * 7.0)

	for i in point_count:
		var bead_progress := clampf(fill_progress - float(i), 0.0, 1.0)
		var center := Vector2(start_x + float(i) * (diameter + gap), center_y)
		var lit_color := color.lerp(Color(1.0, 0.96, 0.72, 1.0), 0.28 + 0.12 * bead_progress)
		var scale := 1.0 + 0.10 * bead_progress
		if full:
			scale += 0.05 * pulse
		var bead_radius := radius * scale
		var shadow_offset := Vector2(0.0, 1.0)
		if bead_progress >= 1.0:
			draw_circle(center, bead_radius + 1.4 + pulse * 0.5, Color(color.r, color.g, color.b, 0.12 + pulse * 0.06))
		draw_circle(center + shadow_offset, bead_radius + 0.7, Color(0.16, 0.09, 0.03, 0.34))
		draw_circle(center, bead_radius + 0.55, Color(0.96, 0.63, 0.18, 0.92))
		draw_circle(center, bead_radius, Color(0.39, 0.23, 0.08, 0.88))
		if bead_progress > 0.0:
			var alpha := 0.35 + 0.65 * bead_progress
			draw_circle(center, bead_radius * (0.74 + 0.20 * bead_progress), Color(lit_color.r, lit_color.g, lit_color.b, alpha))
			draw_circle(center - Vector2(bead_radius * 0.27, bead_radius * 0.32), bead_radius * 0.22, Color(1.0, 1.0, 0.86, 0.42 + 0.36 * bead_progress))
		else:
			draw_circle(center, bead_radius * 0.70, Color(0.62, 0.38, 0.12, 0.76))
			draw_circle(center - Vector2(bead_radius * 0.22, bead_radius * 0.26), bead_radius * 0.15, Color(1.0, 0.78, 0.36, 0.28))

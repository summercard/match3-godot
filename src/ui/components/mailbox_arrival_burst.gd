class_name MailboxArrivalBurst
extends Control

const PARTICLE_COUNT := 8
const DURATION := 0.48
const COLORS := [
	Color(1.0, 0.78, 0.22, 1.0),
	Color(1.0, 0.43, 0.62, 1.0),
	Color(0.38, 0.82, 1.0, 1.0),
	Color(0.50, 0.94, 0.66, 1.0),
]

var _center := Vector2.ZERO
var _elapsed := DURATION


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func play(center: Vector2) -> void:
	_center = center
	_elapsed = 0.0
	set_process(true)
	queue_redraw()


func is_playing() -> bool:
	return _elapsed < DURATION


func _process(delta: float) -> void:
	_elapsed = minf(DURATION, _elapsed + delta)
	queue_redraw()
	if _elapsed >= DURATION:
		set_process(false)


func _draw() -> void:
	if _elapsed >= DURATION:
		return
	var progress := clampf(_elapsed / DURATION, 0.0, 1.0)
	var fade := pow(1.0 - progress, 1.7)
	for index in PARTICLE_COUNT:
		var angle := TAU * float(index) / float(PARTICLE_COUNT) - PI * 0.5
		var distance := lerpf(5.0, 22.0 + float(index % 3) * 3.0, pow(progress, 0.72))
		var position := _center + Vector2.from_angle(angle) * distance
		var color: Color = COLORS[index % COLORS.size()]
		color.a = fade * (0.72 if index % 2 == 0 else 0.50)
		var size := lerpf(3.5, 1.1, progress)
		draw_circle(position, size, color)
		if index % 2 == 0:
			draw_line(_center + Vector2.from_angle(angle) * (distance * 0.45), position, Color(color.r, color.g, color.b, color.a * 0.72), 1.2)

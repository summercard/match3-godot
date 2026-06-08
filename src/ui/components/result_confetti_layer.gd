class_name ResultConfettiLayer
extends Control

var _time := 0.0
var _pieces: Array[Dictionary] = []

const CONFETTI_COLORS := [
	Color(0.22, 0.64, 1.0),
	Color(1.0, 0.32, 0.50),
	Color(1.0, 0.72, 0.08),
	Color(0.44, 0.86, 0.28),
	Color(0.62, 0.26, 1.0),
	Color(1.0, 0.48, 0.12),
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_pieces()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for piece in _pieces:
		var phase := float(piece.get("phase", 0.0))
		var side := float(piece.get("side", 1.0))
		var pos := piece.get("pos", Vector2.ZERO) as Vector2
		var amp := float(piece.get("amp", 5.0))
		var speed := float(piece.get("speed", 1.0))
		var swing := sin(_time * speed + phase)
		var draw_pos := pos + Vector2(swing * amp * side, sin(_time * speed * 0.72 + phase) * 3.0)
		var size := piece.get("size", Vector2(7.0, 14.0)) as Vector2
		var color := piece.get("color", Color.WHITE) as Color
		var angle := float(piece.get("angle", 0.0)) + swing * 0.45
		var alpha := 0.72 + 0.20 * sin(_time * speed * 1.2 + phase)
		color.a *= alpha
		draw_set_transform(draw_pos, angle, Vector2.ONE)
		draw_rect(Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y), color)
		draw_rect(Rect2(-size.x * 0.25, -size.y * 0.42, maxf(1.0, size.x * 0.18), size.y * 0.82), Color(1.0, 1.0, 1.0, color.a * 0.30))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in range(10):
		var x := 45.0 + float(i) * 34.0
		var y := 30.0 + sin(_time * 1.7 + float(i)) * 8.0
		var a := 0.25 + 0.28 * sin(_time * 3.2 + float(i) * 1.7)
		_draw_sparkle(Vector2(x, y), 2.0 + float(i % 3) * 0.35, Color(1.0, 0.95, 0.22, a))


func _draw_sparkle(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center - Vector2(radius, 0.0), center + Vector2(radius, 0.0), color, 1.2)
	draw_line(center - Vector2(0.0, radius), center + Vector2(0.0, radius), color, 1.2)


func _build_pieces() -> void:
	_pieces.clear()
	var positions := [
		Vector2(24, 66), Vector2(38, 86), Vector2(54, 60), Vector2(70, 92), Vector2(88, 72),
		Vector2(285, 68), Vector2(303, 88), Vector2(322, 60), Vector2(342, 92), Vector2(358, 72),
		Vector2(106, 46), Vector2(132, 38), Vector2(251, 42), Vector2(232, 56)
	]
	for i in range(positions.size()):
		var pos: Vector2 = positions[i]
		var side := -1.0 if pos.x < 187.5 else 1.0
		_pieces.append({
			"pos": pos,
			"side": side,
			"size": Vector2(6.0 + float(i % 3) * 2.0, 12.0 + float(i % 4) * 3.0),
			"color": CONFETTI_COLORS[i % CONFETTI_COLORS.size()],
			"angle": -0.7 + float(i % 5) * 0.32,
			"phase": float(i) * 0.73,
			"speed": 1.0 + float(i % 4) * 0.22,
			"amp": 3.0 + float(i % 5) * 1.4,
		})

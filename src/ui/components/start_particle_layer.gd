extends Control

const DESIGN_SIZE := Vector2(375.0, 667.0)
const PARTICLE_COUNT := 22
const REDRAW_INTERVAL := 1.0 / 30.0

var _particles: Array[Dictionary] = []
var _elapsed := 0.0
var _redraw_accum := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for _i in range(PARTICLE_COUNT):
		_particles.append({
			"position": Vector2(randf() * DESIGN_SIZE.x, randf() * DESIGN_SIZE.y),
			"size": 1.2 + randf() * 2.2,
			"opacity": 0.22 + randf() * 0.42,
			"velocity": Vector2((randf() - 0.5) * 0.45, 0.12 + randf() * 0.22),
			"phase": randf() * TAU,
			"speed": 1.1 + randf() * 1.2,
		})

func _process(delta: float) -> void:
	_elapsed += delta
	_redraw_accum += delta
	for particle in _particles:
		var position: Vector2 = particle["position"] + particle["velocity"] * delta * 60.0
		if position.x < -4.0:
			position.x = DESIGN_SIZE.x + 4.0
		elif position.x > DESIGN_SIZE.x + 4.0:
			position.x = -4.0
		if position.y > DESIGN_SIZE.y + 4.0:
			position.y = -4.0
		particle["position"] = position
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = 0.0
		queue_redraw()

func _draw() -> void:
	for particle in _particles:
		var pulse := 0.62 + sin(_elapsed * particle["speed"] + particle["phase"]) * 0.34
		var position: Vector2 = particle["position"]
		var size: float = particle["size"]
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(position.x, position.y - size),
				Vector2(position.x + size * 0.58, position.y),
				Vector2(position.x, position.y + size),
				Vector2(position.x - size * 0.58, position.y),
			]),
			Color(0.86, 0.96, 1.0, particle["opacity"] * pulse)
		)

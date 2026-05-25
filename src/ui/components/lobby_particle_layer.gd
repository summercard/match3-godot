extends Control

const DESIGN_SIZE := Vector2(375.0, 667.0)
const PARTICLE_COUNT := 18
const REDRAW_INTERVAL := 1.0 / 30.0

var _particles: Array[Dictionary] = []
var _elapsed := 0.0
var _redraw_accum := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for _i in range(PARTICLE_COUNT):
		_particles.append({
			"position": Vector2(randf() * DESIGN_SIZE.x, randf() * DESIGN_SIZE.y),
			"radius": 1.0 + randf() * 1.5,
			"opacity": 0.18 + randf() * 0.32,
			"velocity": Vector2((randf() - 0.5) * 0.3, (randf() - 0.5) * 0.2),
			"phase": randf() * TAU,
			"speed": 1.0 + randf() * 0.8
		})

func _process(delta: float) -> void:
	_elapsed += delta
	_redraw_accum += delta
	for particle in _particles:
		var position: Vector2 = particle["position"] + particle["velocity"] * delta * 60.0
		if position.x < 0.0:
			position.x = DESIGN_SIZE.x
		elif position.x > DESIGN_SIZE.x:
			position.x = 0.0
		if position.y < 0.0:
			position.y = DESIGN_SIZE.y
		elif position.y > DESIGN_SIZE.y:
			position.y = 0.0
		particle["position"] = position
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = 0.0
		queue_redraw()

func _draw() -> void:
	for particle in _particles:
		var pulse := 0.55 + sin(_elapsed * particle["speed"] + particle["phase"]) * 0.35
		var color := Color(0.32, 0.72, 1.0, particle["opacity"] * pulse)
		draw_circle(particle["position"], particle["radius"], color)

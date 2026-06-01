extends Control

const DESIGN_SIZE := Vector2(375.0, 667.0)
const MOTE_COUNT := 18
const REDRAW_INTERVAL := 1.0 / 24.0
const SUN_RAYS := [
	{
		"origin": Vector2(-18.0, 52.0),
		"direction": Vector2(0.42, 1.0),
		"length": 430.0,
		"start_width": 20.0,
		"end_width": 88.0,
		"opacity": 0.105,
		"phase": 0.0,
	},
	{
		"origin": Vector2(36.0, 45.0),
		"direction": Vector2(0.35, 1.0),
		"length": 370.0,
		"start_width": 16.0,
		"end_width": 68.0,
		"opacity": 0.082,
		"phase": 1.7,
	},
	{
		"origin": Vector2(88.0, 61.0),
		"direction": Vector2(0.26, 1.0),
		"length": 310.0,
		"start_width": 12.0,
		"end_width": 54.0,
		"opacity": 0.062,
		"phase": 3.2,
	},
]
const SPARKLES := [
	{"position": Vector2(324.0, 187.0), "phase": 0.2, "speed": 1.15, "size": 6.5},
	{"position": Vector2(275.0, 340.0), "phase": 2.4, "speed": 0.95, "size": 5.5},
	{"position": Vector2(80.0, 476.0), "phase": 4.1, "speed": 1.05, "size": 6.0},
	{"position": Vector2(301.0, 481.0), "phase": 5.3, "speed": 0.90, "size": 5.2},
	{"position": Vector2(131.0, 291.0), "phase": 3.4, "speed": 1.08, "size": 4.8},
	{"position": Vector2(347.0, 421.0), "phase": 1.5, "speed": 0.98, "size": 5.0},
]

var _motes: Array[Dictionary] = []
var _elapsed := 0.0
var _redraw_accum := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for _i in range(MOTE_COUNT):
		_motes.append(_create_mote(randf() * DESIGN_SIZE.y))


func _process(delta: float) -> void:
	_elapsed += delta
	_redraw_accum += delta
	for mote in _motes:
		var position: Vector2 = mote["position"] + mote["velocity"] * delta * 60.0
		if position.x < -8.0:
			position.x = DESIGN_SIZE.x + 8.0
		elif position.x > DESIGN_SIZE.x + 8.0:
			position.x = -8.0
		if position.y < 92.0:
			position = Vector2(randf() * DESIGN_SIZE.x, DESIGN_SIZE.y + randf() * 24.0)
		mote["position"] = position
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = 0.0
		queue_redraw()


func _draw() -> void:
	_draw_sunlight()
	_draw_motes()
	_draw_sparkles()


func get_effect_profile() -> Dictionary:
	return {
		"sun_rays": SUN_RAYS.size(),
		"motes": MOTE_COUNT,
		"sparkles": SPARKLES.size(),
	}


func _create_mote(y: float) -> Dictionary:
	var warm_tint := Color(1.0, 0.82, 0.45, 1.0)
	var soft_tint := Color(1.0, 0.96, 0.72, 1.0)
	return {
		"position": Vector2(randf() * DESIGN_SIZE.x, y),
		"radius": 1.15 + randf() * 1.65,
		"opacity": 0.20 + randf() * 0.22,
		"velocity": Vector2((randf() - 0.5) * 0.28, -0.12 - randf() * 0.22),
		"phase": randf() * TAU,
		"speed": 0.75 + randf() * 0.65,
		"tint": warm_tint.lerp(soft_tint, randf()),
	}


func _draw_sunlight() -> void:
	var haze_pulse := 0.88 + sin(_elapsed * 0.34) * 0.12
	draw_circle(Vector2(8.0, 74.0), 128.0, Color(1.0, 0.91, 0.62, 0.052 * haze_pulse))
	draw_circle(Vector2(8.0, 74.0), 82.0, Color(1.0, 0.94, 0.72, 0.075 * haze_pulse))
	for ray in SUN_RAYS:
		var pulse := 0.86 + sin(_elapsed * 0.38 + float(ray["phase"])) * 0.14
		_draw_sun_ray(
			ray["origin"],
			ray["direction"],
			float(ray["length"]),
			float(ray["start_width"]),
			float(ray["end_width"]),
			float(ray["opacity"]) * pulse
		)


func _draw_sun_ray(origin: Vector2, direction: Vector2, length: float, start_width: float, end_width: float, opacity: float) -> void:
	var ray_direction := direction.normalized()
	var normal := Vector2(-ray_direction.y, ray_direction.x)
	var end := origin + ray_direction * length
	var points := PackedVector2Array([
		origin - normal * start_width,
		origin + normal * start_width,
		end + normal * end_width,
		end - normal * end_width,
	])
	var start_color := Color(1.0, 0.90, 0.58, opacity)
	var end_color := Color(1.0, 0.94, 0.72, 0.0)
	draw_polygon(points, PackedColorArray([start_color, start_color, end_color, end_color]))


func _draw_motes() -> void:
	for mote in _motes:
		var pulse := 0.62 + sin(_elapsed * mote["speed"] + mote["phase"]) * 0.28
		var tint: Color = mote["tint"]
		var opacity := float(mote["opacity"]) * pulse
		var radius := float(mote["radius"])
		draw_circle(mote["position"], radius * 3.2, Color(tint.r, tint.g, tint.b, opacity * 0.22))
		draw_circle(mote["position"], radius * 1.8, Color(tint.r, tint.g, tint.b, opacity * 0.30))
		draw_circle(mote["position"], radius, Color(tint.r, tint.g, tint.b, opacity))


func _draw_sparkles() -> void:
	for sparkle in SPARKLES:
		var intensity := maxf(0.0, sin(_elapsed * float(sparkle["speed"]) + float(sparkle["phase"])) - 0.66) / 0.34
		if intensity <= 0.0:
			continue
		var position: Vector2 = sparkle["position"]
		var size := float(sparkle["size"]) * intensity
		var color := Color(1.0, 0.94, 0.64, 0.86 * intensity)
		draw_circle(position, size * 1.35, Color(1.0, 0.88, 0.48, 0.12 * intensity))
		draw_line(position - Vector2(size, 0.0), position + Vector2(size, 0.0), color, 1.35)
		draw_line(position - Vector2(0.0, size), position + Vector2(0.0, size), color, 1.35)
		draw_circle(position, maxf(size * 0.30, 0.65), Color(1.0, 1.0, 0.86, 0.78 * intensity))

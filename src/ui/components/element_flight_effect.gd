class_name ElementFlightEffect
extends Node2D

## 三消元素飞行三段式特效：施法 → 飞行 → 命中。
##
## 纯表现层：只读调用方传入的出生点 / 落点与当前表现档位，不改棋盘、
## 战斗状态、伤害或随机数；不插入任何 await，因此不会改变战斗时序。
## 所有可调参数集中在 CONFIG，`enabled` 是总开关。
##
## 时间轴（从出生点开始计时）：
## - 施法 0–0.18s：宝石中心亮起，元素从 1.0 放大到 1.25，光晕递增，拖尾起点就位；
## - 飞行 0.18–0.42s：沿二次贝塞尔曲线飞向怪物锚点，控制点抬高 50px，速度先快后慢；
## - 命中 0.42–0.67s（0.25s）：白闪 0.06s 达峰，扩环直径 10→46px，粒子爆散。
##
## 粒子数按表现档位 effect_density 缩放：轻量 0.5 / 均衡 1.0 / 华丽 1.5，
## 单次效果硬上限 5 枚。拖尾是连续的轨迹采样，不计入爆散粒子数。

const CONFIG := {
	"cast_duration": 0.18,
	"flight_duration": 0.24,
	"total_duration": 0.42,
	"hit_duration": 0.25,
	"flash_peak_time": 0.06,
	"flash_fade_duration": 0.12,
	"ring_start_diameter": 10.0,
	"ring_end_diameter": 46.0,
	"ring_grow_duration": 0.22,
	"control_raise_px": 50.0,
	"base_particles": 4,
	"max_particles": 5,
	"min_particles": 1,
	"particle_life": 0.22,
	"particle_speed_min": 86.0,
	"particle_speed_max": 138.0,
	"particle_size_min": 2.0,
	"particle_size_max": 3.4,
	"trail_interval": 0.016,
	"trail_max": 14,
	"orb_radius": 7.0,
	"glow_radius": 15.0,
	"flash_radius": 24.0,
	"ring_width": 3.0,
}

## 总开关：关闭时不创建任何节点、不绘制、不推进计时，
## 战斗画面与基线逐字节一致。
static var enabled: bool = true

var origin: Vector2 = Vector2.ZERO
var anchor: Vector2 = Vector2.ZERO
var control: Vector2 = Vector2.ZERO
var gem_color: Color = Color.WHITE
var particle_count: int = int(CONFIG["base_particles"])

var _density: float = 1.0
var _time: float = 0.0
var _phase: String = "cast"
var _finished: bool = false
var _cast_end_time: float = -1.0
var _landing_time: float = -1.0
var _landing_position: Vector2 = Vector2.ZERO
var _flash_peak_time: float = -1.0
var _flash_peak_alpha: float = 0.0
var _trail: Array[Vector2] = []
var _trail_timer: float = 0.0
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


## 便捷静态入口：总开关关闭、父节点不可用或没有存活敌人锚点时返回 null。
static func spawn(parent: Node, from: Vector2, to: Vector2, color: Color, profile: Dictionary = {}) -> ElementFlightEffect:
	if not enabled:
		return null
	if parent == null or not parent.is_inside_tree():
		return null
	var effect := ElementFlightEffect.new()
	effect.setup(from, to, color, profile)
	parent.add_child(effect)
	effect.z_index = 20
	return effect


func setup(from: Vector2, to: Vector2, color: Color, profile: Dictionary = {}) -> void:
	origin = from
	anchor = to
	gem_color = color
	control = (from + to) * 0.5 + Vector2(0.0, -float(CONFIG["control_raise_px"]))
	_density = maxf(0.0, float(profile.get("effect_density", 1.0)))
	particle_count = clampi(
		int(floor(float(CONFIG["base_particles"]) * _density)),
		int(CONFIG["min_particles"]),
		int(CONFIG["max_particles"])
	)
	_rng.seed = _seed_for(from, to, color)
	_trail = [origin]
	set_process(true)


## 显式推进（测试按固定步长调用，_process 在场景里按帧调用）。
func advance(dt: float) -> void:
	if _finished or dt <= 0.0:
		return
	var previous := _time
	_time += dt

	if previous < float(CONFIG["cast_duration"]) and _time >= float(CONFIG["cast_duration"]):
		_cast_end_time = _time
		_phase = "flight"

	if previous < float(CONFIG["total_duration"]) and _time >= float(CONFIG["total_duration"]):
		_landing_time = _time
		_landing_position = current_position()
		_phase = "hit"
		_spawn_hit_particles()

	if _time <= float(CONFIG["total_duration"]):
		_append_trail_sample(dt)
	elif not _particles.is_empty():
		_update_particles(dt)

	var flash := flash_alpha()
	if flash > _flash_peak_alpha:
		_flash_peak_alpha = flash
		_flash_peak_time = _time

	if _time >= float(CONFIG["total_duration"]) + float(CONFIG["hit_duration"]):
		_phase = "done"
		_finished = true


func current_position() -> Vector2:
	var cast_duration := float(CONFIG["cast_duration"])
	var total_duration := float(CONFIG["total_duration"])
	if _time < cast_duration:
		return origin
	if _time >= total_duration:
		return anchor
	var progress := clampf((_time - cast_duration) / float(CONFIG["flight_duration"]), 0.0, 1.0)
	var eased := ease_out_quad(progress)
	return _quadratic_bezier(origin, control, anchor, eased)


func current_scale() -> float:
	var cast_duration := float(CONFIG["cast_duration"])
	if _time >= float(CONFIG["total_duration"]):
		return 1.0
	if _time >= cast_duration:
		return 1.25
	return lerpf(1.0, 1.25, ease_out_cubic(clampf(_time / cast_duration, 0.0, 1.0)))


## 施法段光晕从 0 增至 1；飞行段保持满亮。
func glow_alpha() -> float:
	var cast_duration := float(CONFIG["cast_duration"])
	if _time >= cast_duration:
		return 1.0
	return ease_out_cubic(clampf(_time / cast_duration, 0.0, 1.0))


func ring_diameter() -> float:
	var hit_time := _time - float(CONFIG["total_duration"])
	if hit_time <= 0.0:
		return 0.0
	var progress := clampf(hit_time / float(CONFIG["ring_grow_duration"]), 0.0, 1.0)
	return lerpf(
		float(CONFIG["ring_start_diameter"]),
		float(CONFIG["ring_end_diameter"]),
		ease_out_cubic(progress)
	)


## 落地前恒为 0；落地后 0.06s 达峰，再在 0.12s 内淡出。
func flash_alpha() -> float:
	var hit_time := _time - float(CONFIG["total_duration"])
	if hit_time <= 0.0:
		return 0.0
	var peak := float(CONFIG["flash_peak_time"])
	if hit_time <= peak:
		return clampf(hit_time / peak, 0.0, 1.0)
	return clampf(1.0 - (hit_time - peak) / float(CONFIG["flash_fade_duration"]), 0.0, 1.0)


func alive_particle_count() -> int:
	return _particles.size()


func is_finished() -> bool:
	return _finished


## 供测试与验收读取的整帧快照；落点误差使用效果实际记录的位置。
func get_snapshot() -> Dictionary:
	var effect_position := current_position()
	return {
		"time": _time,
		"phase": _phase,
		"position": effect_position,
		"origin": origin,
		"anchor": anchor,
		"control": control,
		"scale": current_scale(),
		"glow_alpha": glow_alpha(),
		"ring_diameter": ring_diameter(),
		"flash_alpha": flash_alpha(),
		"particles_alive": alive_particle_count(),
		"particle_count": particle_count,
		"trail_count": _trail.size(),
		"cast_end_time": _cast_end_time,
		"landing_time": _landing_time,
		"landing_position": _landing_position,
		"landing_error": _landing_position.distance_to(anchor) if _landing_time >= 0.0 else -1.0,
		"spawn_error": effect_position.distance_to(origin) if _time <= float(CONFIG["cast_duration"]) else 0.0,
		"flash_peak_time": _flash_peak_time,
		"flash_peak_alpha": _flash_peak_alpha,
		"finished": _finished
	}


func _process(delta: float) -> void:
	advance(delta)
	queue_redraw()
	if _finished:
		queue_free()


func _draw() -> void:
	if _finished or _time < 0.0:
		return
	var total_duration := float(CONFIG["total_duration"])
	if _time < total_duration:
		_draw_travel()
	else:
		_draw_hit()


func _draw_travel() -> void:
	var cast_duration := float(CONFIG["cast_duration"])
	var trail_count := _trail.size()
	for i in range(trail_count):
		var ratio := float(i + 1) / float(maxi(trail_count, 1))
		var point := _trail[i]
		var alpha := ratio * 0.32
		draw_circle(point, 2.0 + ratio * 3.5, Color(gem_color.r, gem_color.g, gem_color.b, alpha))
	var effect_position := current_position()
	var effect_scale := current_scale()
	var glow_strength := glow_alpha()
	var glow_radius := float(CONFIG["glow_radius"]) * effect_scale
	draw_circle(
		effect_position,
		glow_radius,
		Color(gem_color.r, gem_color.g, gem_color.b, 0.22 * glow_strength)
	)
	draw_circle(
		effect_position,
		glow_radius * 0.55,
		Color(1.0, 1.0, 1.0, 0.18 * glow_strength)
	)
	# 元素本体：白芯 + 宝石色外壳，施法段由小放大。
	var birth := clampf(_time / maxf(cast_duration, 0.001), 0.0, 1.0)
	draw_circle(effect_position, float(CONFIG["orb_radius"]) * effect_scale, Color(gem_color.r, gem_color.g, gem_color.b, 1.0))
	draw_circle(effect_position, float(CONFIG["orb_radius"]) * effect_scale * 0.55, Color(1.0, 1.0, 1.0, 0.92))
	var core_alpha := lerpf(0.25, 1.0, birth)
	draw_circle(effect_position, float(CONFIG["orb_radius"]) * 0.32, Color(1.0, 1.0, 1.0, core_alpha))


func _draw_hit() -> void:
	var hit_time := _time - float(CONFIG["total_duration"])
	var flash := flash_alpha()
	if flash > 0.0:
		draw_circle(anchor, float(CONFIG["flash_radius"]) * (0.7 + 0.3 * flash), Color(1.0, 1.0, 1.0, 0.9 * flash))
		draw_circle(anchor, float(CONFIG["flash_radius"]) * 0.45, Color(1.0, 1.0, 1.0, flash))
	var diameter := ring_diameter()
	if diameter > 0.0:
		var radius := diameter * 0.5
		draw_arc(anchor, radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.9), float(CONFIG["ring_width"]), true)
		draw_arc(anchor, radius * 0.86, 0.0, TAU, 40, Color(gem_color.r, gem_color.g, gem_color.b, 0.55), 1.5, true)
	for particle: Dictionary in _particles:
		var life_ratio := clampf(float(particle["life"]) / maxf(float(particle["max_life"]), 0.001), 0.0, 1.0)
		var particle_color: Color = particle["color"]
		draw_circle(
			particle["position"],
			float(particle["size"]) * (0.35 + 0.65 * life_ratio),
			Color(particle_color.r, particle_color.g, particle_color.b, life_ratio)
		)
		draw_circle(
			particle["position"],
			float(particle["size"]) * 0.45 * life_ratio,
			Color(1.0, 1.0, 1.0, life_ratio * 0.9)
		)
	if hit_time < 0.1:
		var core_ratio := 1.0 - clampf(hit_time / 0.1, 0.0, 1.0)
		draw_circle(anchor, float(CONFIG["orb_radius"]) * core_ratio, Color(gem_color.r, gem_color.g, gem_color.b, core_ratio))


func _append_trail_sample(dt: float) -> void:
	_trail_timer += dt
	if _trail_timer < float(CONFIG["trail_interval"]):
		return
	_trail_timer = 0.0
	_trail.append(current_position())
	if _trail.size() > int(CONFIG["trail_max"]):
		_trail.remove_at(0)


func _spawn_hit_particles() -> void:
	_particles.clear()
	var count := particle_count
	for i in range(count):
		var angle := TAU * float(i) / float(maxi(count, 1)) + _rng.randf_range(-0.22, 0.22)
		var speed := _rng.randf_range(
			float(CONFIG["particle_speed_min"]),
			float(CONFIG["particle_speed_max"])
		)
		var size := _rng.randf_range(
			float(CONFIG["particle_size_min"]),
			float(CONFIG["particle_size_max"])
		)
		_particles.append({
			"position": anchor,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": float(CONFIG["particle_life"]),
			"max_life": float(CONFIG["particle_life"]),
			"color": gem_color,
			"size": size
		})


func _update_particles(dt: float) -> void:
	for i in range(_particles.size() - 1, -1, -1):
		var particle: Dictionary = _particles[i]
		particle["life"] = float(particle["life"]) - dt
		if float(particle["life"]) <= 0.0:
			_particles.remove_at(i)
			continue
		particle["position"] = particle["position"] + particle["velocity"] * dt
		particle["velocity"] = particle["velocity"] * 0.92


static func _quadratic_bezier(from: Vector2, control_point: Vector2, to: Vector2, t: float) -> Vector2:
	var inverse := 1.0 - t
	return from * inverse * inverse + control_point * 2.0 * inverse * t + to * t * t


static func ease_out_quad(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return 1.0 - (1.0 - clamped) * (1.0 - clamped)


static func ease_out_cubic(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - clamped, 3.0)


static func _seed_for(from: Vector2, to: Vector2, color: Color) -> int:
	var value := int(from.x * 17.0) + int(from.y * 31.0) + int(to.x * 13.0) + int(to.y * 7.0)
	value += int(color.r * 1000.0) + int(color.g * 1000.0) + int(color.b * 1000.0)
	return value & 0x7fffffff

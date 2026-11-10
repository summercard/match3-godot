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
## 基准 2 / 4 / 5 枚。拖尾是连续的轨迹采样，不计入爆散粒子数。
##
## 连锁与画质档（T3）：
## - 2 连锁起命中环半径 ×1.2、白环亮度提到 ≥+10%；
## - 4 连锁起追加第二圈，首圈起点后 0.06s 出现，峰值半径 = 首圈 60%，
##   不新增震屏；轻量档没有第二圈，且首圈半径 = 均衡 ×0.8；
## - 同屏弹体 / 同屏环 / 单次命中粒子按画质档设置硬上限，超出即丢弃并计数。
##   预算只决定表现节点是否创建，不插入等待，不影响消除 / 战斗时序。

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
	"ring_alpha": 0.9,
	"ring_inner_alpha": 0.55,
	"chain_ring_min": 2,
	"chain_ring_radius_scale": 1.2,
	## 0.90 → 1.00：相对 1 连锁 +11.1%，高于验收的 +10%，
	## 避免 8bit 量化 / 抗锯齿后实测跌破 10%。
	"chain_ring_luminance_scale": 1.12,
	"second_ring_min_chain": 4,
	"second_ring_delay": 0.06,
	"second_ring_peak_ratio": 0.6,
	"second_ring_grow_duration": 0.14,
	"second_ring_alpha_ratio": 0.6,
	"second_ring_width": 2.0,
	"tier_ring_scale": {
		"lite": 0.8,
		"balanced": 1.0,
		"rich": 1.0,
	},
	"tier_budgets": {
		## projectile_floor 是本档保底上限；实际同屏上限 = max(保底, 本波消除格数)，
		## 保证本轮每一格都能起飞（双三消 6 格就至少 6 个），轻量档同理。
		"lite": {"projectile_floor": 2, "rings": 1, "particles": 4},
		"balanced": {"projectile_floor": 3, "rings": 2, "particles": 8},
		"rich": {"projectile_floor": 3, "rings": 3, "particles": 12},
	},
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

## 同屏预算与丢弃计数（只统计经由 spawn 创建的表现节点）。
## 战斗场景进入时调用 reset_budgets()；测试逐档重置后读取 get_budget_stats()。
static var _active_projectiles: int = 0
static var _active_rings: int = 0
static var _dropped_projectiles: int = 0
static var _dropped_rings: int = 0
static var _dropped_particles: int = 0
static var _last_budget_tier: String = "balanced"
static var _last_wave_cells: int = 0
static var _last_projectile_cap: int = 0

var origin: Vector2 = Vector2.ZERO
var anchor: Vector2 = Vector2.ZERO
var control: Vector2 = Vector2.ZERO
var gem_color: Color = Color.WHITE
var particle_count: int = int(CONFIG["base_particles"])
var chain_level: int = 1

var _density: float = 1.0
var _tier: String = "balanced"
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

# 连锁 / 档位派生值（均来自 CONFIG，不在这里写死数值）。
var _tier_ring_scale: float = 1.0
var _chain_radius_scale: float = 1.0
var _chain_luminance_scale: float = 1.0
var _second_ring_enabled: bool = false
var _second_ring_started: bool = false
var _second_ring_allowed: bool = true
var _ring_allowed: bool = true
var _ring_start_time: float = -1.0
var _second_ring_start_time: float = -1.0

# 预算槽位：只有 spawn 出来的节点参与，直接 new()/setup() 的量测对象不受影响。
var _uses_budget: bool = false
var _projectile_slot_held: bool = false
var _ring_slot_held: bool = false
var _second_ring_slot_held: bool = false


static func reset_budgets() -> void:
	_active_projectiles = 0
	_active_rings = 0
	_dropped_projectiles = 0
	_dropped_rings = 0
	_dropped_particles = 0
	_last_budget_tier = "balanced"
	_last_wave_cells = 0
	_last_projectile_cap = 0


## 供测试 / 验收读取：当前同屏占用与累计丢弃数。
static func get_budget_stats() -> Dictionary:
	return {
		"tier": _last_budget_tier,
		"active_projectiles": maxi(0, _active_projectiles),
		"active_rings": maxi(0, _active_rings),
		"dropped_projectiles": _dropped_projectiles,
		"dropped_rings": _dropped_rings,
		"dropped_particles": _dropped_particles,
		"wave_cells": _last_wave_cells,
		"projectile_cap": _last_projectile_cap,
	}


## 战斗表现档位：优先读 PresentationProfile 的 performance；
## 缺少该字段时按 effect_density 反推（旧测试只传密度）。
static func resolve_tier(profile: Dictionary) -> String:
	var key := str(profile.get("performance", ""))
	if CONFIG["tier_budgets"].has(key):
		return key
	var density := float(profile.get("effect_density", 1.0))
	if density <= 0.5:
		return "lite"
	if density >= 1.5:
		return "rich"
	return "balanced"


static func budget_for(tier: String) -> Dictionary:
	return CONFIG["tier_budgets"].get(tier, CONFIG["tier_budgets"]["balanced"])


## 同屏弹体实际上限：本档保底与「本波消除格数」取大，保证本轮每格都能飞。
static func projectile_cap_for(tier: String, wave_cells: int) -> int:
	return maxi(int(budget_for(tier)["projectile_floor"]), maxi(0, wave_cells))


## 便捷静态入口：总开关关闭、父节点不可用、没有存活敌人锚点或同屏弹体预算
## 已满时返回 null。预算不足只累加丢弃计数，不创建节点、不插入等待。
static func spawn(parent: Node, from: Vector2, to: Vector2, color: Color, profile: Dictionary = {}) -> ElementFlightEffect:
	if not enabled:
		return null
	if parent == null or not parent.is_inside_tree():
		return null
	var tier := resolve_tier(profile)
	_last_budget_tier = tier
	var wave_cells := maxi(0, int(profile.get("wave_cells", 0)))
	var projectile_cap := projectile_cap_for(tier, wave_cells)
	_last_wave_cells = wave_cells
	_last_projectile_cap = projectile_cap
	if _active_projectiles >= projectile_cap:
		_dropped_projectiles += 1
		return null
	var effect := ElementFlightEffect.new()
	effect._uses_budget = true
	effect.setup(from, to, color, profile)
	_active_projectiles += 1
	effect._projectile_slot_held = true
	parent.add_child(effect)
	effect.z_index = 20
	return effect


func setup(from: Vector2, to: Vector2, color: Color, profile: Dictionary = {}) -> void:
	origin = from
	anchor = to
	gem_color = color
	control = (from + to) * 0.5 + Vector2(0.0, -float(CONFIG["control_raise_px"]))
	chain_level = maxi(1, int(profile.get("chain_level", 1)))
	_tier = resolve_tier(profile)
	var budget := budget_for(_tier)
	_tier_ring_scale = float(CONFIG["tier_ring_scale"].get(_tier, 1.0))
	_chain_radius_scale = (
		float(CONFIG["chain_ring_radius_scale"])
		if chain_level >= int(CONFIG["chain_ring_min"])
		else 1.0
	)
	_chain_luminance_scale = (
		float(CONFIG["chain_ring_luminance_scale"])
		if chain_level >= int(CONFIG["chain_ring_min"])
		else 1.0
	)
	_second_ring_enabled = (
		chain_level >= int(CONFIG["second_ring_min_chain"]) and _tier != "lite"
	)
	_density = maxf(0.0, float(profile.get("effect_density", 1.0)))
	var raw_count := clampi(
		int(floor(float(CONFIG["base_particles"]) * _density)),
		int(CONFIG["min_particles"]),
		int(CONFIG["max_particles"])
	)
	var particle_budget := int(budget["particles"])
	particle_count = mini(raw_count, particle_budget)
	if raw_count > particle_budget and _uses_budget:
		_dropped_particles += raw_count - particle_budget
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
		_on_landing()
		_spawn_hit_particles()

	if (
		_ring_allowed
		and _second_ring_enabled
		and not _second_ring_started
		and _second_ring_start_time >= 0.0
		and _time >= _second_ring_start_time
	):
		_second_ring_started = true
		if _uses_budget:
			var budget := budget_for(_tier)
			if _active_rings < int(budget["rings"]):
				_active_rings += 1
				_second_ring_slot_held = true
			else:
				_second_ring_allowed = false
				_dropped_rings += 1

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
		_release_ring_slots()
		_release_projectile_slot()


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
	return ring_radius() * 2.0


## 首圈半径：起始 10px、峰值 46px 按连锁 ×1.2、轻量档 ×0.8 缩放；
## 被同屏环预算拒绝时返回 0。
func ring_radius() -> float:
	if not _ring_allowed:
		return 0.0
	var hit_time := _time - float(CONFIG["total_duration"])
	if hit_time <= 0.0:
		return 0.0
	var progress := clampf(hit_time / float(CONFIG["ring_grow_duration"]), 0.0, 1.0)
	return lerpf(ring_start_radius(), ring_peak_radius(), ease_out_cubic(progress))


func ring_start_radius() -> float:
	return (
		float(CONFIG["ring_start_diameter"])
		* 0.5
		* _tier_ring_scale
		* _chain_radius_scale
	)


func ring_peak_radius() -> float:
	return (
		float(CONFIG["ring_end_diameter"])
		* 0.5
		* _tier_ring_scale
		* _chain_radius_scale
	)


## 白环实际绘制亮度（alpha）：1 连锁 0.90；2 连锁起 1.00（+11.1%）。
func ring_luminance() -> float:
	if ring_radius() <= 0.0:
		return 0.0
	return minf(1.0, float(CONFIG["ring_alpha"]) * _chain_luminance_scale)


## 第二圈：首圈起点后 0.06s 出现，峰值半径 = 首圈峰值 60%；轻量档恒为 0。
func second_ring_radius() -> float:
	if not _second_ring_enabled or not _second_ring_allowed or not _second_ring_started:
		return 0.0
	var local := _time - _second_ring_start_time
	if local <= 0.0:
		return 0.0
	var progress := clampf(local / float(CONFIG["second_ring_grow_duration"]), 0.0, 1.0)
	return lerpf(
		ring_start_radius() * float(CONFIG["second_ring_peak_ratio"]),
		second_ring_peak_radius(),
		ease_out_cubic(progress)
	)


func second_ring_peak_radius() -> float:
	if not _second_ring_enabled:
		return 0.0
	return ring_peak_radius() * float(CONFIG["second_ring_peak_ratio"])


func second_ring_luminance() -> float:
	if second_ring_radius() <= 0.0:
		return 0.0
	return minf(1.0, ring_luminance() * float(CONFIG["second_ring_alpha_ratio"]))


func _on_landing() -> void:
	_release_projectile_slot()
	if _uses_budget:
		var budget := budget_for(_tier)
		if _active_rings < int(budget["rings"]):
			_active_rings += 1
			_ring_slot_held = true
		else:
			_ring_allowed = false
			_second_ring_enabled = false
			_dropped_rings += 1
	if _ring_allowed:
		_ring_start_time = _time
		if _second_ring_enabled:
			_second_ring_start_time = _time + float(CONFIG["second_ring_delay"])


func _release_projectile_slot() -> void:
	if _projectile_slot_held:
		_active_projectiles = maxi(0, _active_projectiles - 1)
		_projectile_slot_held = false


func _release_ring_slots() -> void:
	if _ring_slot_held:
		_active_rings = maxi(0, _active_rings - 1)
		_ring_slot_held = false
	if _second_ring_slot_held:
		_active_rings = maxi(0, _active_rings - 1)
		_second_ring_slot_held = false


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
		"chain_level": chain_level,
		"tier": _tier,
		"ring_radius": ring_radius(),
		"ring_diameter": ring_diameter(),
		"ring_peak_radius": ring_peak_radius(),
		"ring_luminance": ring_luminance(),
		"ring_start_time": _ring_start_time,
		"second_ring_enabled": _second_ring_enabled,
		"second_ring_started": _second_ring_started,
		"second_ring_start_time": _second_ring_start_time,
		"second_ring_radius": second_ring_radius(),
		"second_ring_diameter": second_ring_radius() * 2.0,
		"second_ring_peak_radius": second_ring_peak_radius(),
		"second_ring_luminance": second_ring_luminance(),
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


## 场景提前退出 / 节点被手动释放时归还预算槽位，避免静态计数泄漏。
func _exit_tree() -> void:
	_release_projectile_slot()
	_release_ring_slots()


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
	var first_luminance := ring_luminance()
	if first_luminance > 0.0:
		var radius := ring_radius()
		draw_arc(
			anchor, radius, 0.0, TAU, 48,
			Color(1.0, 1.0, 1.0, first_luminance),
			float(CONFIG["ring_width"]), true
		)
		draw_arc(
			anchor, radius * 0.86, 0.0, TAU, 40,
			Color(
				gem_color.r, gem_color.g, gem_color.b,
				minf(1.0, float(CONFIG["ring_inner_alpha"]) * _chain_luminance_scale)
			),
			1.5, true
		)
	var second_luminance := second_ring_luminance()
	if second_luminance > 0.0:
		var second_radius := second_ring_radius()
		draw_arc(
			anchor, second_radius, 0.0, TAU, 40,
			Color(1.0, 1.0, 1.0, second_luminance),
			float(CONFIG["second_ring_width"]), true
		)
		draw_arc(
			anchor, second_radius * 0.86, 0.0, TAU, 32,
			Color(gem_color.r, gem_color.g, gem_color.b, 0.4 * second_luminance),
			1.0, true
		)
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

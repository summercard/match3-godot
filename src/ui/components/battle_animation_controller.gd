class_name BattleAnimationController
extends RefCounted

## 伤害飘字：普通 / 暴击样式与同目标多段伤害的错位编排。
## 只负责表现层，不参与伤害公式与数值。
const DAMAGE_MAX_LAYERS := 3
const DAMAGE_STAGGER_SECONDS := 0.12
const DAMAGE_RISE := 14.0
const DAMAGE_BAND_RISE := 4.0
const DAMAGE_NORMAL_SIZE := 21.0
const DAMAGE_CRIT_SIZE := 28.0
const DAMAGE_WEAK_SIZE := 16.0
const DAMAGE_NORMAL_COLOR := Color(1.0, 0.96, 0.88)
const DAMAGE_CRIT_COLOR := Color(1.0, 0.28, 0.06)
const DAMAGE_WEAK_COLOR := Color(0.68, 0.72, 0.78)
const DAMAGE_CRIT_PREFIX := "暴击"

static func damage_style(critical: bool, weak: bool, heavy: bool = false) -> Dictionary:
	if critical:
		return {
			"style": "crit",
			"color": DAMAGE_CRIT_COLOR,
			"size": DAMAGE_CRIT_SIZE,
			"duration": 1.0,
			"prefix": DAMAGE_CRIT_PREFIX
		}
	if heavy:
		return {
			"style": "heavy",
			"color": Color(1.0, 0.32, 0.24),
			"size": 28.0,
			"duration": 0.95,
			"prefix": ""
		}
	if weak:
		return {
			"style": "weak",
			"color": DAMAGE_WEAK_COLOR,
			"size": DAMAGE_WEAK_SIZE,
			"duration": 0.85,
			"prefix": ""
		}
	return {
		"style": "normal",
		"color": DAMAGE_NORMAL_COLOR,
		"size": DAMAGE_NORMAL_SIZE,
		"duration": 0.85,
		"prefix": ""
	}

## 敌方受击飘字锚点：避开血条、头像与顶部 HUD。
## 单体敌人在名字上方显示；多体敌人在敌方区与玩家卡片之间的空档显示。
static func enemy_damage_anchor(enemy_count: int, index: int) -> Vector2:
	if enemy_count <= 1:
		return Vector2(187.5, 66.0)
	if enemy_count == 2:
		var two := [Vector2(130.0, 212.0), Vector2(245.0, 212.0)]
		return two[clampi(index, 0, 1)]
	var three := [Vector2(72.0, 212.0), Vector2(187.5, 212.0), Vector2(303.0, 212.0)]
	return three[clampi(index, 0, 2)]

## 我方受击飘字锚点：统一放在玩家卡片上方的空档。
static func player_damage_anchor(index: int) -> Vector2:
	return Vector2(71.0 + clampi(index, 0, 2) * 116.0, 212.0)

## 同一目标的多段伤害最多叠三层，按左/中/右错开，避免互相压住。
static func damage_lane_offset(anchor: Vector2, lane: int) -> Vector2:
	if lane <= 0:
		return Vector2.ZERO
	var step := 57.0 if anchor.y < 100.0 else 75.0
	if anchor.y >= 100.0 and anchor.x <= 140.0:
		return Vector2(step * lane, 0.0)
	if anchor.y >= 100.0 and anchor.x >= 237.0:
		return Vector2(-step * lane, 0.0)
	return Vector2(step * float(lane * 2 - 3), 0.0)

## 计算新伤害飘字的出现时间与层位：
## - 同一目标连续命中按 0.12s 依次出现；
## - 同一时刻最多 3 层，第 4 段排队到最早一层结束后。
static func schedule_damage_popup(existing: Array, anchor_key: String, now: float, duration: float, prefer_center: bool = false) -> Dictionary:
	var intervals: Array[Dictionary] = []
	var latest_start := -INF
	for entry in existing:
		if str(entry.get("damage_anchor", "")) != anchor_key:
			continue
		var entry_duration := maxf(float(entry.get("duration", duration)), 0.01)
		var timer := float(entry.get("timer", 0.0))
		var delay := maxf(float(entry.get("delay", 0.0)), 0.0)
		var start := now + delay - timer
		latest_start = maxf(latest_start, start)
		intervals.append({
			"start": start,
			"end": start + entry_duration,
			"lane": int(entry.get("lane", 0))
		})
	var start_at := now
	if latest_start > -INF:
		start_at = maxf(now, latest_start + DAMAGE_STAGGER_SECONDS)
	var lane_order := [0, 1, 2] if prefer_center else [1, 2, 0]
	var guard := 0
	while guard < 64:
		var overlapping: Array[Dictionary] = []
		for interval in intervals:
			if start_at < float(interval["end"]) - 0.001 and start_at + duration > float(interval["start"]) + 0.001:
				overlapping.append(interval)
		if overlapping.size() < DAMAGE_MAX_LAYERS:
			if overlapping.is_empty():
				return {"delay": maxf(0.0, start_at - now), "lane": 0}
			var used: Array[int] = []
			for interval in overlapping:
				used.append(int(interval["lane"]))
			var lane := -1
			for candidate in lane_order:
				if not used.has(int(candidate)):
					lane = int(candidate)
					break
			if lane < 0:
				lane = 0
				while used.has(lane) and lane < DAMAGE_MAX_LAYERS:
					lane += 1
			return {"delay": maxf(0.0, start_at - now), "lane": lane}
		var next_end := INF
		for interval in overlapping:
			next_end = minf(next_end, float(interval["end"]))
		start_at = next_end + 0.001
		guard += 1
	return {"delay": maxf(0.0, start_at - now), "lane": lane_order[0]}

static func tick_countdown(value: float, dt: float) -> float:
	return maxf(0.0, value - dt) if value > 0.0 else 0.0

static func tick_timed_entries(entries: Array, dt: float, timer_key: String = "timer") -> void:
	for i in range(entries.size() - 1, -1, -1):
		entries[i][timer_key] -= dt
		if entries[i][timer_key] <= 0.0:
			entries.remove_at(i)

static func update_attack_shake(timer: float, flash_timer: float, dt: float) -> Dictionary:
	if timer <= 0.0:
		return {"timer": 0.0, "flash_timer": tick_countdown(flash_timer, dt), "offset_x": 0.0}
	timer = maxf(0.0, timer - dt)
	var shake_speed := TAU / 0.05
	var offset_x := sin(timer * shake_speed) * 4.0
	return {"timer": timer, "flash_timer": tick_countdown(flash_timer, dt), "offset_x": offset_x}

static func update_hp_display(trackers: Array, dt: float) -> void:
	for i in range(trackers.size() - 1, -1, -1):
		var h: Dictionary = trackers[i]
		h["timer"] += dt
		if h["timer"] >= h["maxTimer"]:
			h["displayHP"] = h["targetHP"]
			trackers.remove_at(i)
		else:
			var progress: float = h["timer"] / h["maxTimer"]
			var eased: float = 1.0 - pow(1.0 - progress, 2.0)
			h["displayHP"] = h["displayHP"] - (h["displayHP"] - h["targetHP"]) * eased

static func update_floating_texts(floating_texts: Array, element_glow: Dictionary, swipe_trail: Array, dt: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = floating_texts[i]
		# 同目标多段伤害会带入场延迟，延迟结束前不进入显示计时。
		var delay := float(ft.get("delay", 0.0))
		if delay > 0.0:
			ft["delay"] = maxf(0.0, delay - dt)
			continue
		ft["timer"] += dt
		if ft["timer"] >= ft.get("duration", 1.0):
			floating_texts.remove_at(i)

	if element_glow.get("timer", 0.0) > 0.0:
		element_glow["timer"] -= dt

	tick_timed_entries(swipe_trail, dt)

static func update_board_shake(timer: float, dt: float, rng: RandomNumberGenerator = null) -> Dictionary:
	if timer <= 0.0:
		return {"timer": 0.0, "offset": Vector2.ZERO}
	timer = maxf(0.0, timer - dt)
	var intensity: float = maxf(0.0, timer / 0.3)
	var rx := rng.randf() if rng != null else randf()
	var ry := rng.randf() if rng != null else randf()
	return {
		"timer": timer,
		"offset": Vector2((rx - 0.5) * 6.0 * intensity, (ry - 0.5) * 4.0 * intensity)
	}

static func update_particle_list(particles: Array, dt: float, default_gravity: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["x"] += p["vx"] * dt
		p["y"] += p["vy"] * dt
		p["vy"] += p.get("gravity", default_gravity) * dt
		p["life"] -= dt
		if p["life"] <= 0.0:
			particles.remove_at(i)

static func update_element_ripple(ripple: Dictionary, dt: float) -> void:
	if not ripple.get("active", false):
		return
	ripple["timer"] -= dt
	if ripple["timer"] <= 0.0:
		ripple["active"] = false

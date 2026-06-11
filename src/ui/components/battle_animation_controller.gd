class_name BattleAnimationController
extends RefCounted

static func tick_countdown(value: float, dt: float) -> float:
	return maxf(0.0, value - dt) if value > 0.0 else 0.0

static func tick_timed_entries(entries: Array, dt: float, timer_key: String = "timer") -> void:
	for i in range(entries.size() - 1, -1, -1):
		entries[i][timer_key] -= dt
		if entries[i][timer_key] <= 0.0:
			entries.remove_at(i)

static func update_combo_popup(combo_popup: Dictionary, dt: float) -> void:
	if not combo_popup.has("combo"):
		return
	combo_popup["timer"] += dt
	var t: float = combo_popup["timer"]
	var phase: String = combo_popup["phase"]
	if phase == "in":
		if t < 0.15:
			var progress: float = t / 0.15
			combo_popup["scale"] = 0.5 + 0.7 * progress
			combo_popup["opacity"] = progress
		else:
			combo_popup["phase"] = "peak"
			combo_popup["timer"] = 0.0
			combo_popup["scale"] = 1.2
			combo_popup["opacity"] = 1.0
	elif phase == "peak":
		if t < 0.15:
			var progress: float = t / 0.15
			combo_popup["scale"] = 1.2 - 0.2 * progress
		else:
			combo_popup["phase"] = "out"
			combo_popup["timer"] = 0.0
			combo_popup["scale"] = 1.0
	elif phase == "out":
		if t < 0.3:
			var progress: float = t / 0.3
			combo_popup["opacity"] = 1.0 - progress
		else:
			combo_popup.clear()

static func update_attack_shake(timer: float, flash_timer: float, dt: float) -> Dictionary:
	# ★ 主人定 2026-06-11：缩减震动幅度（9→2.4），去掉垂直分量和屏幕白闪
	if timer <= 0.0:
		return {"timer": 0.0, "flash_timer": tick_countdown(flash_timer, dt), "offset_x": 0.0, "offset_y": 0.0}
	timer = maxf(0.0, timer - dt)
	var shake_speed := TAU / 0.05
	var offset_x := sin(timer * shake_speed) * 2.4
	return {"timer": timer, "flash_timer": tick_countdown(flash_timer, dt), "offset_x": offset_x, "offset_y": 0.0}

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

static func update_floating_texts(floating_texts: Array, popup_queue: Array, element_glow: Dictionary, swipe_trail: Array, dt: float) -> void:
	for i in range(popup_queue.size() - 1, -1, -1):
		var entry: Dictionary = popup_queue[i]
		entry["elapsed"] += dt
		if entry["elapsed"] >= entry["delay"]:
			floating_texts.append({
				"text": entry["text"],
				"x": entry["x"],
				"y": entry["y"],
				"color": entry["color"],
				"size": entry["size"],
				"timer": entry["elapsed"] - entry["delay"],
				"duration": entry["duration"],
				"critical": entry.get("critical", false)
			})
			popup_queue.remove_at(i)

	for i in range(floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = floating_texts[i]
		ft["timer"] += dt
		if ft["timer"] >= ft.get("duration", 1.0):
			floating_texts.remove_at(i)

	if element_glow.get("timer", 0.0) > 0.0:
		element_glow["timer"] -= dt

	tick_timed_entries(swipe_trail, dt)

static func update_board_shake(timer: float, dt: float) -> Dictionary:
	if timer <= 0.0:
		return {"timer": 0.0, "offset": Vector2.ZERO}
	timer = maxf(0.0, timer - dt)
	var intensity: float = maxf(0.0, timer / 0.3)
	return {
		"timer": timer,
		"offset": Vector2((randf() - 0.5) * 6.0 * intensity, (randf() - 0.5) * 4.0 * intensity)
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

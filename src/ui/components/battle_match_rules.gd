class_name BattleMatchRules
extends RefCounted

static func build_context(board, match_result: Dictionary, eliminate_duration: float) -> Dictionary:
	var matches: Array = match_result.get("gems", [])
	var enhanced_matches: Array = match_result.get("enhanced", [])
	var bomb_matches: Array = match_result.get("bomb", [])
	var rainbow_matches: Array = match_result.get("rainbow", [])
	var explosion_gems: Array = _collect_explosion_gems(board, enhanced_matches, matches)
	var all_excluded: Array = matches + explosion_gems
	var bomb_gems: Array = _collect_bomb_gems(board, bomb_matches, all_excluded)
	var all_excluded_2: Array = all_excluded + bomb_gems
	var rainbow_gems: Array = _collect_rainbow_gems(board, rainbow_matches, all_excluded_2)
	return {
		"matches": matches,
		"enhanced_matches": enhanced_matches,
		"bomb_matches": bomb_matches,
		"rainbow_matches": rainbow_matches,
		"has_matches": not matches.is_empty() or not enhanced_matches.is_empty() or not bomb_matches.is_empty() or not rainbow_matches.is_empty(),
		"total_elim": matches.size() + enhanced_matches.size() + bomb_matches.size() + rainbow_matches.size(),
		"explosion_gems": explosion_gems,
		"bomb_gems": bomb_gems,
		"rainbow_gems": rainbow_gems,
		"special_phases": _build_special_phases(enhanced_matches, bomb_matches, rainbow_matches, explosion_gems, bomb_gems, rainbow_gems),
		"special_transform": _build_special_transform(board, enhanced_matches, eliminate_duration)
	}

static func apply_removals(board, context: Dictionary) -> Dictionary:
	var matches: Array = context.get("matches", [])
	var enhanced_matches: Array = context.get("enhanced_matches", [])
	var bomb_matches: Array = context.get("bomb_matches", [])
	var rainbow_matches: Array = context.get("rainbow_matches", [])
	var explosion_gems: Array = context.get("explosion_gems", [])
	var bomb_gems: Array = context.get("bomb_gems", [])
	var affected_gems: Array = matches.duplicate()
	var gem_counts: Dictionary = board.remove_matches(matches, false)

	for enh in enhanced_matches:
		var positions: Array = board.get_cross_explosion_positions(enh["row"], enh["col"])
		affected_gems.append_array(positions)
		_merge_counts(gem_counts, board.remove_explosion_gems(positions, false))

	for bomb in bomb_matches:
		var positions: Array = board.get_bomb_explosion_positions(bomb["row"], bomb["col"])
		affected_gems.append_array(positions)
		_merge_counts(gem_counts, board.remove_explosion_gems(positions, false))

	var rainbow_removed_set: Array = []
	for m in matches:
		rainbow_removed_set.append("%d,%d" % [m["row"], m["col"]])
	for g in explosion_gems:
		rainbow_removed_set.append("%d,%d" % [g["row"], g["col"]])
	for g in bomb_gems:
		rainbow_removed_set.append("%d,%d" % [g["row"], g["col"]])
	for rainbow in rainbow_matches:
		var positions: Array = board.get_rainbow_positions(rainbow["type"], rainbow_removed_set)
		affected_gems.append_array(positions)
		_merge_counts(gem_counts, board.remove_explosion_gems(positions, false))
		for p in positions:
			rainbow_removed_set.append("%d,%d" % [p["row"], p["col"]])

	var obstacle_damage: Array = board.damage_obstacles_for_resolution(affected_gems, bomb_matches)

	return {
		"gem_counts": gem_counts,
		"special_gems": explosion_gems + bomb_gems + context.get("rainbow_gems", []),
		"obstacle_damage": obstacle_damage
	}

static func get_special_wait(phases: Array, eliminate_duration: float, fall_duration: float) -> float:
	if phases.is_empty():
		return fall_duration
	var last_phase: Dictionary = phases[phases.size() - 1]
	return maxf(fall_duration, last_phase.get("delay", 0.0) + eliminate_duration)

static func _build_special_phases(enhanced_matches: Array, bomb_matches: Array, rainbow_matches: Array, explosion_gems: Array, bomb_gems: Array, rainbow_gems: Array) -> Array:
	var phases: Array = []
	if not explosion_gems.is_empty():
		phases.append({"type": "explosion", "gems": explosion_gems, "matches": enhanced_matches, "delay": 0.1, "timer": 0.0, "triggered": false})
	if not bomb_gems.is_empty():
		phases.append({"type": "bomb", "gems": bomb_gems, "matches": bomb_matches, "delay": 0.15, "timer": 0.0, "triggered": false})
	if not rainbow_gems.is_empty():
		phases.append({"type": "rainbow", "gems": rainbow_gems, "matches": rainbow_matches, "delay": 0.2, "timer": 0.0, "triggered": false})
	return phases

static func _build_special_transform(board, enhanced_matches: Array, duration: float) -> Dictionary:
	if enhanced_matches.is_empty() or board == null:
		return {}
	var first_enh: Dictionary = enhanced_matches[0]
	var gem_type: String = "fire"
	if first_enh["row"] >= 0 and first_enh["row"] < board.rows and first_enh["col"] >= 0 and first_enh["col"] < board.cols:
		gem_type = board.grid[first_enh["row"]][first_enh["col"]]
	return {"row": first_enh["row"], "col": first_enh["col"], "type": gem_type, "timer": duration, "duration": duration, "triggered": false}

static func _collect_explosion_gems(board, enhanced_matches: Array, normal_gems: Array) -> Array:
	var gems: Array = []
	var normal_set: Dictionary = {}
	for m in normal_gems:
		normal_set["%d,%d" % [m["row"], m["col"]]] = true
	for enh in enhanced_matches:
		var positions: Array = board.get_cross_explosion_positions(enh["row"], enh["col"])
		for p in positions:
			var key: String = "%d,%d" % [p["row"], p["col"]]
			if not normal_set.has(key):
				normal_set[key] = true
				gems.append(_gem_entry(board, p, {"is_explosion": true}))
	return gems

static func _collect_bomb_gems(board, bomb_matches: Array, excluded_gems: Array) -> Array:
	var gems: Array = []
	var removed_set: Dictionary = {}
	for g in excluded_gems:
		removed_set["%d,%d" % [g.get("row", -1), g.get("col", -1)]] = true
	for bomb in bomb_matches:
		var positions: Array = board.get_bomb_explosion_positions(bomb["row"], bomb["col"])
		for p in positions:
			var key: String = "%d,%d" % [p["row"], p["col"]]
			if not removed_set.has(key):
				removed_set[key] = true
				gems.append(_gem_entry(board, p, {"is_bomb": true}))
	return gems

static func _collect_rainbow_gems(board, rainbow_matches: Array, all_removed: Array) -> Array:
	var gems: Array = []
	var removed_set: Dictionary = {}
	for g in all_removed:
		removed_set["%d,%d" % [g.get("row", -1), g.get("col", -1)]] = true
	for rainbow in rainbow_matches:
		var positions: Array = board.get_rainbow_positions(rainbow["type"], removed_set.keys())
		for p in positions:
			var key: String = "%d,%d" % [p["row"], p["col"]]
			removed_set[key] = true
			gems.append(_gem_entry(board, p, {"is_rainbow": true}))
	return gems

static func _gem_entry(board, pos: Dictionary, flags: Dictionary) -> Dictionary:
	var cell_size: float = float(board.cell_size)
	var entry: Dictionary = {
		"row": pos["row"],
		"col": pos["col"],
		"type": pos["type"],
		"x": float(board.offset_x + pos["col"] * cell_size + cell_size / 2.0),
		"y": float(board.offset_y + pos["row"] * cell_size + cell_size / 2.0)
	}
	for key in flags:
		entry[key] = flags[key]
	return entry

static func _merge_counts(target: Dictionary, addition: Dictionary) -> void:
	for type_key in addition:
		target[type_key] = target.get(type_key, 0) + addition[type_key]

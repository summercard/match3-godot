class_name BattleHazardRules
extends RefCounted

static func process_poison_turn(board, battle, damage_per_tile: float = 0.03) -> Dictionary:
	if board == null or not has_poison_fog(board):
		return {"spread_tiles": [], "hits": [], "fog_count": 0, "total_damage": 0, "all_dead": false}

	var spread_tiles: Array = _with_positions(board, board.spread_poison_fog())
	var fog_count: int = board.get_poison_fog_damage_count()
	if fog_count <= 0 or battle == null:
		return {"spread_tiles": spread_tiles, "hits": [], "fog_count": fog_count, "total_damage": 0, "all_dead": false}

	var alive_team: Array = []
	for m in battle.player_team:
		if m != null and m.get("hp", 0) > 0:
			alive_team.append(m)
	if alive_team.is_empty():
		return {"spread_tiles": spread_tiles, "hits": [], "fog_count": fog_count, "total_damage": 0, "all_dead": false}

	var avg_max_hp: float = 0.0
	for m in alive_team:
		avg_max_hp += float(m.get("maxHP", 1))
	avg_max_hp /= alive_team.size()
	var total_damage: int = int(avg_max_hp * damage_per_tile * fog_count)
	if total_damage <= 0:
		return {"spread_tiles": spread_tiles, "hits": [], "fog_count": fog_count, "total_damage": 0, "all_dead": false}

	var damage_per_member: int = total_damage / alive_team.size()
	var damage_remainder: int = total_damage % alive_team.size()
	var hits: Array = []
	var actual_total_damage := 0
	for i in range(alive_team.size()):
		var member: Dictionary = alive_team[i]
		var requested_damage := damage_per_member + (1 if i < damage_remainder else 0)
		var hp_before := int(member.get("hp", 0))
		member["hp"] = maxi(hp_before - requested_damage, 0)
		var actual_damage := hp_before - int(member.get("hp", 0))
		actual_total_damage += actual_damage
		hits.append({"team_index": battle.player_team.find(member), "damage": actual_damage})

	var all_dead := true
	for m in battle.player_team:
		if m != null and m.get("hp", 0) > 0:
			all_dead = false
			break
	if all_dead:
		battle.battle_over = true
		battle.battle_result = "lose"

	return {
		"spread_tiles": spread_tiles,
		"hits": hits,
		"fog_count": fog_count,
		"total_damage": actual_total_damage,
		"all_dead": all_dead
	}

static func process_fountain_turn(board) -> Dictionary:
	if board == null or not has_fountains(board):
		return {"erupted": [], "soaked": [], "extinguished": []}
	var result: Dictionary = board.process_fountain_eruption()
	return {
		"erupted": _with_positions(board, result.get("erupted", [])),
		"soaked": _with_positions(board, result.get("soaked", [])),
		"extinguished": _with_positions(board, result.get("extinguished", []))
	}


static func fountain_attack_sources(board, removed_gems: Array) -> Array:
	var sources: Array = []
	var seen: Dictionary = {}
	if board == null:
		return sources
	for gem in removed_gems:
		if not gem is Dictionary or str((gem as Dictionary).get("type", "")) != "water":
			continue
		var row := int((gem as Dictionary).get("row", -1))
		var col := int((gem as Dictionary).get("col", -1))
		for offset in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
			var fountain_row := row + int(offset[0])
			var fountain_col := col + int(offset[1])
			if not board.is_fountain(fountain_row, fountain_col):
				continue
			var key := "%d:%d" % [fountain_row, fountain_col]
			if seen.has(key):
				continue
			seen[key] = true
			sources.append(_position_entry(board, {"row": fountain_row, "col": fountain_col}))
	return sources


static func process_destroyed_rock_backlash(battle, obstacle_damage: Array, damage_ratio: float = 0.10) -> Dictionary:
	var destroyed_sources: Array = []
	for hit in obstacle_damage:
		if hit is Dictionary and bool((hit as Dictionary).get("destroyed", false)):
			destroyed_sources.append((hit as Dictionary).duplicate(true))
	var hits: Array = []
	if battle == null or destroyed_sources.is_empty():
		return {"destroyed_sources": destroyed_sources, "hits": hits, "total_damage": 0}
	var total_damage := 0
	for source_index in range(destroyed_sources.size()):
		for team_index in range(battle.player_team.size()):
			var member = battle.player_team[team_index]
			if member == null or int(member.get("hp", 0)) <= 0 or str(member.get("element", "")) == "earth":
				continue
			var before := int(member.get("hp", 0))
			var requested := maxi(1, int(floor(float(member.get("maxHP", 1)) * clampf(damage_ratio, 0.0, 1.0))))
			member["hp"] = maxi(0, before - requested)
			var actual := before - int(member.get("hp", 0))
			total_damage += actual
			hits.append({"source_index": source_index, "team_index": team_index, "damage": actual, "target_died": int(member.get("hp", 0)) <= 0})
	return {"destroyed_sources": destroyed_sources, "hits": hits, "total_damage": total_damage}

static func process_tide_turn(board) -> Dictionary:
	if board == null or not has_tide(board):
		return {"old_level": 0, "new_level": 0, "risen_rows": [], "ebbed_rows": [], "flooded": [], "phase": "none"}
	var result: Dictionary = board.process_tide_rise()
	var flooded: Array = []
	for row in range(board.rows):
		for col in range(board.cols):
			if board.is_tide_flooded(row, col):
				flooded.append(_position_entry(board, {"row": row, "col": col}))
	var risen_rows: Array = []
	for row in result.get("risen_rows", []):
		var row_tiles: Array = []
		for col in range(board.cols):
			row_tiles.append(_position_entry(board, {"row": int(row), "col": col}))
		risen_rows.append({"row": int(row), "tiles": row_tiles})
	var ebbed_rows: Array = []
	for row in result.get("ebbed_rows", []):
		var row_tiles: Array = []
		for col in range(board.cols):
			row_tiles.append(_position_entry(board, {"row": int(row), "col": col}))
		ebbed_rows.append({"row": int(row), "tiles": row_tiles})
	return {
		"old_level": int(result.get("old_level", 0)),
		"new_level": int(result.get("new_level", 0)),
		"risen_rows": risen_rows,
		"ebbed_rows": ebbed_rows,
		"flooded": flooded,
		"phase": str(result.get("phase", "none"))
	}

static func process_vine_resolution(board, battle, removed_gems: Array, rule: Dictionary = {}) -> Dictionary:
	if board == null or removed_gems.is_empty():
		return {"burned": [], "backlash": [], "hits": [], "total_damage": 0, "all_dead": false}

	var removed: Dictionary = {}
	var fire_removed: Array = []
	for gem in removed_gems:
		if not gem is Dictionary:
			continue
		var row := int(gem.get("row", -1))
		var col := int(gem.get("col", -1))
		if row < 0 or row >= board.rows or col < 0 or col >= board.cols:
			continue
		var key := _cell_key(row, col)
		removed[key] = {"row": row, "col": col, "type": str(gem.get("type", ""))}
		if str(gem.get("type", "")) == "fire":
			fire_removed.append({"row": row, "col": col})

	var burned_keys: Dictionary = {}
	if bool(rule.get("burnedByAdjacentFire", true)):
		for fire: Dictionary in fire_removed:
			for pos: Dictionary in _orthogonal_positions(int(fire["row"]), int(fire["col"]), board.rows, board.cols):
				if board.is_vined(pos["row"], pos["col"]):
					burned_keys[_cell_key(pos["row"], pos["col"])] = pos

	var burned: Array = []
	for key in burned_keys.keys():
		var pos: Dictionary = burned_keys[key]
		if board.clear_vine(pos["row"], pos["col"]):
			burned.append(_position_entry(board, pos))

	var backlash: Array = []
	for key in removed.keys():
		if burned_keys.has(key):
			continue
		var pos: Dictionary = removed[key]
		if board.is_vined(pos["row"], pos["col"]):
			backlash.append(_position_entry(board, pos))

	var damage_result := _apply_vine_backlash_damage(battle, backlash.size(), float(rule.get("backlashPercent", 0.04)))
	return {
		"burned": burned,
		"backlash": backlash,
		"hits": damage_result.get("hits", []),
		"total_damage": int(damage_result.get("total_damage", 0)),
		"all_dead": bool(damage_result.get("all_dead", false))
	}

static func clear_poison_for_gems(board, gems: Array) -> Array:
	if board == null:
		return []
	var clears: Array = []
	for g in gems:
		if g is Dictionary and g.has("row") and g.has("col") and board.is_poison_fog(g["row"], g["col"]):
			board.clear_poison_fog(g["row"], g["col"])
			clears.append(_position_entry(board, g))
	return clears

static func check_unlocks(board, matches: Array, extra_gems: Array = []) -> Array:
	if board == null:
		return []
	var unlock_results: Array = []
	var checked: Dictionary = {}
	var all_gems: Array = matches + extra_gems
	for m in all_gems:
		if not m is Dictionary or not m.has("row"):
			continue
		var results: Array = board.check_adjacent_unlocks(m["row"], m["col"], m.get("type", ""))
		for r in results:
			var key: String = "%d,%d" % [r["row"], r["col"]]
			if checked.has(key):
				continue
			checked[key] = true
			var entry: Dictionary = _position_entry(board, r)
			for result_key in r:
				entry[result_key] = r[result_key]
			unlock_results.append(entry)
	return unlock_results

static func has_poison_fog(board) -> bool:
	if board == null:
		return false
	for row in range(board.rows):
		for col in range(board.cols):
			if board.is_poison_fog(row, col):
				return true
	return false

static func has_fountains(board) -> bool:
	if board == null:
		return false
	for row in range(board.rows):
		for col in range(board.cols):
			if board.is_fountain(row, col):
				return true
	return false

static func has_tide(board) -> bool:
	return board != null and board.has_method("has_tide") and board.has_tide()

static func has_vines(board) -> bool:
	if board == null:
		return false
	for row in range(board.rows):
		for col in range(board.cols):
			if board.is_vined(row, col):
				return true
	return false

static func _apply_vine_backlash_damage(battle, vine_count: int, damage_percent: float) -> Dictionary:
	if battle == null or vine_count <= 0:
		return {"hits": [], "total_damage": 0, "all_dead": false}
	var alive_team: Array = []
	for m in battle.player_team:
		if m != null and m.get("hp", 0) > 0:
			alive_team.append(m)
	if alive_team.is_empty():
		return {"hits": [], "total_damage": 0, "all_dead": false}
	var avg_max_hp := 0.0
	for m in alive_team:
		avg_max_hp += float(m.get("maxHP", 1))
	avg_max_hp /= alive_team.size()
	var total_damage := maxi(1, int(round(avg_max_hp * damage_percent * float(vine_count))))
	var damage_per_member: int = total_damage / alive_team.size()
	var damage_remainder: int = total_damage % alive_team.size()
	var hits: Array = []
	var actual_total := 0
	for i in range(alive_team.size()):
		var member: Dictionary = alive_team[i]
		var requested_damage := damage_per_member + (1 if i < damage_remainder else 0)
		var hp_before := int(member.get("hp", 0))
		member["hp"] = maxi(hp_before - requested_damage, 0)
		var actual_damage := hp_before - int(member.get("hp", 0))
		actual_total += actual_damage
		hits.append({"team_index": battle.player_team.find(member), "damage": actual_damage})

	var all_dead := true
	for m in battle.player_team:
		if m != null and m.get("hp", 0) > 0:
			all_dead = false
			break
	if all_dead:
		battle.battle_over = true
		battle.battle_result = "lose"
	return {"hits": hits, "total_damage": actual_total, "all_dead": all_dead}

static func _orthogonal_positions(row: int, col: int, rows: int, cols: int) -> Array:
	var result: Array = []
	for offset: Array in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
		var nr := row + int(offset[0])
		var nc := col + int(offset[1])
		if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
			result.append({"row": nr, "col": nc})
	return result

static func _cell_key(row: int, col: int) -> String:
	return "%d,%d" % [row, col]

static func _with_positions(board, tiles: Array) -> Array:
	var result: Array = []
	for tile in tiles:
		result.append(_position_entry(board, tile))
	return result

static func _position_entry(board, source: Dictionary) -> Dictionary:
	var cell_size: float = float(board.cell_size)
	return {
		"row": source["row"],
		"col": source["col"],
		"x": float(board.offset_x) + source["col"] * cell_size + cell_size / 2.0,
		"y": float(board.offset_y) + source["row"] * cell_size + cell_size / 2.0
	}

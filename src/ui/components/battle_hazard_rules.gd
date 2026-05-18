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
	var hits: Array = []
	for member in alive_team:
		member["hp"] = maxi(member.get("hp", 0) - damage_per_member, 0)
		hits.append({"team_index": battle.player_team.find(member), "damage": damage_per_member})

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
		"total_damage": total_damage,
		"all_dead": all_dead
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

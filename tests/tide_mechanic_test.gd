extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")
const HazardRulesScript = preload("res://src/ui/components/battle_hazard_rules.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_stage_pressure_assignment()
	_test_tide_rises_from_bottom()
	_test_flooded_non_water_blocks_swap_and_match()
	_test_flooded_water_remains_playable()
	_test_tide_excluded_from_valid_move_pool()
	_finish()


func _test_stage_pressure_assignment() -> void:
	var db := StageDBScript.new()
	var early_ch4 := db.get_stage("stage_4_1")
	var intro_ch4 := db.get_stage("stage_4_2")
	var late_ch4 := db.get_stage("stage_4_9")
	var boss_ch4 := db.get_stage("stage_4_12")
	_expect(not early_ch4.has("tideRule"), "chapter 4 stage 1 should be a no-tide island primer")
	_expect(intro_ch4.has("tideRule"), "chapter 4 stage 2 should introduce tide pressure")
	_expect(int(intro_ch4.get("tideRule", {}).get("maxLevel", 0)) == 1, "chapter 4 intro tide should only flood one row")
	_expect(int(late_ch4.get("tideRule", {}).get("startLevel", 0)) == 1, "late chapter 4 should start with one flooded row")
	_expect(int(boss_ch4.get("tideRule", {}).get("maxLevel", 0)) == 4, "chapter 4 boss should allow a four-row high tide")
	_expect(not intro_ch4.has("obstacles"), "chapter 4 tide stages should not also generate old rock pressure")


func _test_tide_rises_from_bottom() -> void:
	var board = BoardScript.new(5, 5)
	board.set_tide({"startLevel": 0, "risePerTurn": 1, "maxLevel": 2})
	var first: Dictionary = HazardRulesScript.process_tide_turn(board)
	_expect(int(first.get("new_level", 0)) == 1, "first tide turn should flood one row")
	_expect(board.is_tide_flooded(4, 2), "tide should flood from the bottom row")
	_expect(not board.is_tide_flooded(3, 2), "first tide turn should not flood the second row yet")
	var second: Dictionary = HazardRulesScript.process_tide_turn(board)
	_expect(int(second.get("new_level", 0)) == 2, "second tide turn should flood the second row")
	_expect(board.is_tide_flooded(3, 2), "second tide turn should flood row above bottom")


func _test_flooded_non_water_blocks_swap_and_match() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.set_tide({"startLevel": 1, "risePerTurn": 1, "maxLevel": 2})
	board.grid[4][0] = "fire"
	board.grid[4][1] = "fire"
	board.grid[4][2] = "fire"
	_expect(board.find_matches().get("gems", []).is_empty(), "non-water gems under tide should not match")
	_expect(not board.swap(4, 0, 4, 1), "non-water gems under tide should not be swappable")


func _test_flooded_water_remains_playable() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.set_tide({"startLevel": 1, "risePerTurn": 1, "maxLevel": 2})
	board.grid[4][0] = "water"
	board.grid[4][1] = "water"
	board.grid[4][2] = "water"
	var matches: Array = board.find_matches().get("gems", [])
	_expect(_has_match_cell(matches, 4, 0) and _has_match_cell(matches, 4, 1) and _has_match_cell(matches, 4, 2), "water gems under tide should still match")
	_expect(board.swap(4, 0, 3, 0), "a water gem under tide should still be operable")


func _test_tide_excluded_from_valid_move_pool() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.set_tide({"startLevel": 1, "risePerTurn": 1, "maxLevel": 2})
	for col in range(board.cols):
		board.grid[4][col] = "fire"
	_expect(not board.is_gem_playable(4, 0), "non-water flooded cells should be outside the playable pool")
	var shuffle_result: Dictionary = board.shuffle()
	_expect(shuffle_result.has("success"), "shuffle should still return a structured result while tide is active")


func _fill_checker(board) -> void:
	var types := ["fire", "water", "grass", "thunder", "light"]
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = types[(row * 2 + col) % types.size()]


func _has_match_cell(matches: Array, row: int, col: int) -> bool:
	for match_cell in matches:
		if int(match_cell.get("row", -1)) == row and int(match_cell.get("col", -1)) == col:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TideMechanic] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TideMechanic] " + failure)
	quit(1)

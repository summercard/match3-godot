extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_stage_assignment()
	_test_single_ice_slide()
	_test_continuous_ice_slide()
	_test_slide_exposes_stepped_animation_data()
	_test_slide_stops_before_blocked_cell()
	_test_new_gem_slides_down_two_cells_on_ice()
	_finish()


func _test_stage_assignment() -> void:
	var db := StageDBScript.new()
	var early_ch6 := db.get_stage("stage_6_1")
	var intro_ch6 := db.get_stage("stage_6_2")
	var mid_ch6 := db.get_stage("stage_6_8")
	var boss_ch6 := db.get_stage("stage_6_12")
	_expect(not early_ch6.has("iceTiles"), "chapter 6 stage 1 should introduce the setting without ice")
	_expect(intro_ch6.has("iceTiles"), "chapter 6 stage 2 should introduce ice tiles")
	_expect((intro_ch6.get("iceTiles", []) as Array).size() == 2, "chapter 6 stage 2 should start with a short ice strip")
	_expect((mid_ch6.get("iceTiles", []) as Array).size() > (intro_ch6.get("iceTiles", []) as Array).size(), "later chapter 6 stages should use denser ice layouts")
	_expect((boss_ch6.get("iceTiles", []) as Array).size() >= 10, "chapter 6 boss should use a dense ice board pattern")
	_expect(not _has_adjacent_heavy_rows(boss_ch6.get("iceTiles", [])), "chapter 6 boss ice should avoid awkward double horizontal lanes")
	_expect(not intro_ch6.has("poisonFog"), "chapter 6 ice stages should not also teach poison fog")
	_expect(ResourceLoader.exists("res://assets/images/ui/gems/battle_tile_ice.png"), "ice tile art should exist")


func _test_single_ice_slide() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.grid[2][1] = "water"
	board.grid[2][2] = "grass"
	board.grid[2][3] = "thunder"
	board.grid[2][4] = "light"
	board.set_ice_tiles([[2, 2]])
	var result: Dictionary = board.swap_with_ice_slide(2, 1, 2, 2)
	_expect(bool(result.get("success", false)), "swap into an ice tile should succeed")
	_expect(bool(result.get("slid", false)), "gem entering ice should slide forward")
	_expect(board.grid[2][1] == "grass", "target gem should move back to the source cell")
	_expect(board.grid[2][2] == "thunder", "next gem should be pushed into the ice cell")
	_expect(board.grid[2][3] == "light", "second pushed gem should occupy the first non-ice cell")
	_expect(board.grid[2][4] == "water", "active gem should slide two cells after entering ice")


func _test_continuous_ice_slide() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.grid[2][1] = "water"
	board.grid[2][2] = "grass"
	board.grid[2][3] = "thunder"
	board.grid[2][4] = "light"
	board.set_ice_tiles([[2, 2], [2, 3]])
	var result: Dictionary = board.swap_with_ice_slide(2, 1, 2, 2)
	_expect(bool(result.get("slid", false)), "continuous ice should keep sliding")
	_expect(board.grid[2][2] == "thunder", "first pushed gem should occupy the first ice cell")
	_expect(board.grid[2][3] == "light", "second pushed gem should occupy the second ice cell")
	_expect(board.grid[2][4] == "water", "active gem should stop after leaving the ice strip")
	_expect((result.get("movements", []) as Array).size() >= 4, "ice slide should expose movement data for animation")

func _test_slide_exposes_stepped_animation_data() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.grid[2][1] = "water"
	board.grid[2][2] = "grass"
	board.grid[2][3] = "thunder"
	board.grid[2][4] = "light"
	board.set_ice_tiles([[2, 2], [2, 3]])
	var result: Dictionary = board.swap_with_ice_slide(2, 1, 2, 2)
	var movements: Array = result.get("movements", [])
	var active_move := _movement_for(movements, "water", 2, 4)
	_expect(not active_move.is_empty(), "active gem should expose a final movement entry")
	_expect((active_move.get("points", []) as Array).size() == 4, "active gem should expose source plus each slide stop")
	_expect(_has_step(movements, 1), "first slide exchange should be tagged as step 1")
	_expect(_has_step(movements, 2), "second slide exchange should be tagged as step 2")


func _test_slide_stops_before_blocked_cell() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.grid[2][1] = "water"
	board.grid[2][2] = "grass"
	board.grid[2][3] = ""
	board.set_obstacles([{"row": 2, "col": 3, "type": "rock", "hp": 2}])
	board.set_ice_tiles([[2, 2]])
	var result: Dictionary = board.swap_with_ice_slide(2, 1, 2, 2)
	_expect(bool(result.get("success", false)), "swap onto ice should still succeed when the forward cell is blocked")
	_expect(not bool(result.get("slid", false)), "ice slide should stop before a blocked cell")
	_expect(board.grid[2][2] == "water", "active gem should remain on the ice when forward movement is blocked")

func _test_new_gem_slides_down_two_cells_on_ice() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.grid[0][2] = ""
	board.grid[1][2] = ""
	board.grid[2][2] = "grass"
	board.grid[3][2] = "thunder"
	board.grid[4][2] = "light"
	board.set_ice_tiles([[0, 2], [1, 2]])
	var movements: Array = board.apply_gravity()
	_expect(not board.is_empty(2, 2), "new gem should slide down from the top ice strip")
	_expect(_has_ice_slide_new_move(movements), "gravity should report new-gem ice slide movement")


func _fill_checker(board) -> void:
	var types := ["fire", "water", "grass", "thunder", "light"]
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = types[(row * 2 + col) % types.size()]


func _has_adjacent_heavy_rows(tiles: Array) -> bool:
	var row_counts := {}
	for tile in tiles:
		if not tile is Dictionary:
			continue
		var row := int(tile.get("row", -1))
		row_counts[row] = int(row_counts.get(row, 0)) + 1
	for row in range(7):
		if int(row_counts.get(row, 0)) >= 4 and int(row_counts.get(row + 1, 0)) >= 4:
			return true
	return false

func _movement_for(movements: Array, gem_type: String, row: int, col: int) -> Dictionary:
	for move in movements:
		if move is Dictionary and str(move.get("type", "")) == gem_type and int(move.get("row", -1)) == row and int(move.get("col", -1)) == col:
			return move
	return {}

func _has_step(movements: Array, step: int) -> bool:
	for move in movements:
		if move is Dictionary and int(move.get("step", -1)) == step:
			return true
	return false

func _has_ice_slide_new_move(movements: Array) -> bool:
	for move in movements:
		if move is Dictionary and bool(move.get("iceSlide", false)) and bool(move.get("isNew", false)):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[IceMechanic] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[IceMechanic] " + failure)
	quit(1)

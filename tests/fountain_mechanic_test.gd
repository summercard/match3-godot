extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")
const HazardRulesScript = preload("res://src/ui/components/battle_hazard_rules.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_stage_pressure_assignment()
	_test_fountain_soaks_and_extinguishes()
	_test_soaked_gem_blocks_swap_and_match()
	_test_fountain_blocks_gravity()
	_finish()


func _test_stage_pressure_assignment() -> void:
	var db := StageDBScript.new()
	var stage_2_1 := db.get_stage("stage_2_1")
	var stage_2_2 := db.get_stage("stage_2_2")
	var stage_2_3 := db.get_stage("stage_2_3")
	var stage_2_4 := db.get_stage("stage_2_4")
	var fountain_ch2 := db.get_stage("stage_2_5")
	var boss_ch2 := db.get_stage("stage_2_12")
	_expect(not stage_2_1.has("fountains"), "chapter 2 stage 1 should stay free of fountain pressure")
	_expect(_positions_equal(stage_2_2.get("fountains", []), [[3, 3]]), "chapter 2 stage 2 should teach one center fountain")
	_expect(_positions_equal(stage_2_3.get("fountains", []), [[2, 2], [5, 5]]), "chapter 2 stage 3 should use the 3,3 and 6,6 fountain points")
	_expect(_positions_equal(stage_2_4.get("fountains", []), [[1, 1], [1, 6]]), "chapter 2 stage 4 should use upper-left and upper-right fountain points")
	_expect(_positions_equal(fountain_ch2.get("fountains", []), [[1, 1], [1, 6], [3, 3]]), "chapter 2 stage 5 should use upper-left, upper-right, and center fountains")
	_expect(fountain_ch2.has("fountains"), "chapter 2 mid stage should contain fountains")
	_expect(not fountain_ch2.has("obstacles"), "chapter 2 fountain stages should not keep rock obstacles")
	_expect(int(boss_ch2.get("fountainRule", {}).get("eruptionCount", 0)) == 1, "chapter 2 boss should only erupt one fountain per turn")
	_expect(str(boss_ch2.get("fountainRule", {}).get("range", "")) == "orthogonal_1", "chapter 2 boss should use the normal four-direction fountain range")


func _test_fountain_soaks_and_extinguishes() -> void:
	var board = BoardScript.new(5, 5)
	board.set_fountains([{"row": 2, "col": 2}], {"eruptionCount": 1, "range": "orthogonal_1"})
	board.init_board()
	_fill_board(board, "grass")
	board.grid[2][1] = "fire"
	board.grid[2][3] = "water"
	board.grid[1][2] = "grass"
	board.grid[3][2] = "thunder"
	var result: Dictionary = HazardRulesScript.process_fountain_turn(board)
	_expect(result.get("erupted", []).size() == 1, "one fountain should erupt")
	_expect(result.get("extinguished", []).size() == 1, "adjacent fire gem should be extinguished")
	_expect(board.grid[2][1] == "", "extinguished fire should leave an empty cell")
	_expect(result.get("soaked", []).size() == 3, "non-fire adjacent gems should become soaked")
	_expect(board.is_soaked(2, 3), "water gem next to fountain should be soaked")
	_expect(board.grid[0][1] != "", "fountain eruption should not refill or apply gravity immediately")


func _test_soaked_gem_blocks_swap_and_match() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.grid[1][0] = "water"
	board.grid[1][1] = "water"
	board.grid[1][2] = "water"
	board.soaked_gems[1][1] = {"turns": 1}
	_expect(board.find_matches().get("gems", []).is_empty(), "soaked gems should not participate in matches")
	_expect(not board.swap(1, 1, 1, 2), "soaked gems should not be swappable")


func _test_fountain_blocks_gravity() -> void:
	var board = BoardScript.new(5, 5)
	board.set_fountains([{"row": 2, "col": 2}], {})
	board.init_board()
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = ""
	board.grid[1][2] = "grass"
	board.grid[3][2] = "water"
	board.apply_gravity()
	_expect(board.grid[1][2] == "grass", "gem above a fountain should stay in the upper gravity segment")
	_expect(board.grid[4][2] == "water", "gem below a fountain should fall within the lower gravity segment")


func _fill_board(board, gem_type: String) -> void:
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = "" if board.is_fountain(row, col) else gem_type


func _fill_checker(board) -> void:
	var types := ["fire", "water", "grass", "thunder", "light"]
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = types[(row * 2 + col) % types.size()]


func _positions_equal(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for i in range(expected.size()):
		var pos: Dictionary = actual[i]
		var coord: Array = expected[i]
		if int(pos.get("row", -1)) != int(coord[0]) or int(pos.get("col", -1)) != int(coord[1]):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FountainMechanic] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[FountainMechanic] " + failure)
	quit(1)

extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_impossible_color_distribution_uses_bounded_regeneration()
	_test_no_movable_cells_returns_failure_without_recursion()
	_test_repeated_shuffles_remain_playable()
	_finish()


func _test_impossible_color_distribution_uses_bounded_regeneration() -> void:
	var board = BoardScript.new(5, 5)
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = "fire"
	var result: Dictionary = board.shuffle()
	_expect(bool(result.get("success", false)), "all-one-color board should recover through bounded regeneration")
	_expect(bool(result.get("regenerated", false)), "impossible color distribution should report regeneration")
	_expect(int(result.get("attempts", 0)) <= BoardScript.SHUFFLE_MAX_ATTEMPTS + BoardScript.SHUFFLE_REGENERATE_ATTEMPTS, "shuffle attempts must stay bounded")
	_expect(board.find_matches().get("gems", []).is_empty(), "recovered board must not contain an immediate match")
	_expect(board.has_valid_moves(), "recovered board must contain a valid move")


func _test_no_movable_cells_returns_failure_without_recursion() -> void:
	var board = BoardScript.new(3, 3)
	var snapshot: Array = board.grid.duplicate(true)
	for row in range(board.rows):
		for col in range(board.cols):
			board.locked_gems[row][col] = {"hp": 1}
	var result: Dictionary = board.shuffle()
	_expect(not bool(result.get("success", true)), "fully locked board should report that it cannot shuffle")
	_expect(int(result.get("attempts", -1)) == 0, "fully locked board should fail immediately")
	_expect(board.grid == snapshot, "failed shuffle must preserve the original grid")


func _test_repeated_shuffles_remain_playable() -> void:
	seed(20260622)
	for iteration in range(100):
		var board = BoardScript.new(8, 8)
		var result: Dictionary = board.shuffle()
		_expect(bool(result.get("success", false)), "shuffle %d should succeed" % iteration)
		_expect(board.find_matches().get("gems", []).is_empty(), "shuffle %d should not create immediate matches" % iteration)
		_expect(board.has_valid_moves(), "shuffle %d should retain a valid move" % iteration)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BoardShuffleStress] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[BoardShuffleStress] " + failure)
	quit(1)

extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var board := Match3Board.new(8, 8)
	board.cell_size = 42
	board.offset_x = 19
	board.offset_y = 280

	_expect(board.screen_to_grid(18.8, 300.0).is_empty(), "slight left overflow should not map to column 0")
	_expect(board.screen_to_grid(30.0, 279.8).is_empty(), "slight top overflow should not map to row 0")
	_expect(board.screen_to_grid(18.8, 279.8).is_empty(), "diagonal overflow should not map to row 0 col 0")
	_expect(board.screen_to_grid(19.2, 280.2) == {"row": 0, "col": 0}, "slight inside point should map to row 0 col 0")
	_expect(board.screen_to_grid(19.0 + 8.0 * 42.0, 280.0 + 12.0).is_empty(), "right edge should be outside")
	_expect(board.screen_to_grid(19.0 + 12.0, 280.0 + 8.0 * 42.0).is_empty(), "bottom edge should be outside")

	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BoardInputBounds] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[BoardInputBounds] " + failure)
	quit(1)

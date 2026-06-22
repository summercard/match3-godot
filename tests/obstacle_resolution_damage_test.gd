extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")
const MatchRulesScript = preload("res://src/ui/components/battle_match_rules.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_multiple_normal_gems_damage_one_obstacle_once()
	_test_normal_and_bomb_overlap_share_one_damage_set()
	_test_overlapping_bombs_damage_one_obstacle_once()
	_test_cross_and_rainbow_overlap_share_one_damage_set()
	_finish()


func _test_multiple_normal_gems_damage_one_obstacle_once() -> void:
	var board = _board_with_center_rock(3)
	board.remove_matches([
		{"row": 2, "col": 1, "type": "fire"},
		{"row": 2, "col": 3, "type": "fire"},
		{"row": 1, "col": 2, "type": "fire"}
	])
	_expect(int(board.obstacles[2][2].get("hp", 0)) == 2, "one match resolution should damage an adjacent rock only once")


func _test_normal_and_bomb_overlap_share_one_damage_set() -> void:
	var board = _board_with_center_rock(3)
	var result: Dictionary = MatchRulesScript.apply_removals(board, {
		"matches": [{"row": 2, "col": 1, "type": "fire"}],
		"enhanced_matches": [],
		"bomb_matches": [{"row": 1, "col": 1, "type": "fire"}],
		"rainbow_matches": [],
		"explosion_gems": [],
		"bomb_gems": [],
		"rainbow_gems": []
	})
	_expect(int(board.obstacles[2][2].get("hp", 0)) == 2, "normal and bomb overlap should still deal one rock damage")
	_expect(result.get("obstacle_damage", []).size() == 1, "overlapping sources should emit one obstacle damage event")


func _test_overlapping_bombs_damage_one_obstacle_once() -> void:
	var board = _board_with_center_rock(3)
	var result: Dictionary = MatchRulesScript.apply_removals(board, {
		"matches": [],
		"enhanced_matches": [],
		"bomb_matches": [
			{"row": 1, "col": 1, "type": "fire"},
			{"row": 1, "col": 2, "type": "fire"}
		],
		"rainbow_matches": [],
		"explosion_gems": [],
		"bomb_gems": [],
		"rainbow_gems": []
	})
	_expect(int(board.obstacles[2][2].get("hp", 0)) == 2, "two overlapping bombs should damage the same rock once per resolution")
	_expect(result.get("obstacle_damage", []).size() == 1, "overlapping bombs should emit one obstacle damage event")


func _test_cross_and_rainbow_overlap_share_one_damage_set() -> void:
	var board = _board_with_center_rock(3)
	var result: Dictionary = MatchRulesScript.apply_removals(board, {
		"matches": [{"row": 2, "col": 0, "type": "fire"}],
		"enhanced_matches": [{"row": 2, "col": 0, "type": "fire"}],
		"bomb_matches": [],
		"rainbow_matches": [{"row": 0, "col": 0, "type": "fire"}],
		"explosion_gems": [],
		"bomb_gems": [],
		"rainbow_gems": []
	})
	_expect(int(board.obstacles[2][2].get("hp", 0)) == 2, "cross and rainbow overlap should damage the same rock once")
	_expect(result.get("obstacle_damage", []).size() == 1, "cross and rainbow overlap should emit one obstacle damage event")


func _board_with_center_rock(hp: int):
	var board = BoardScript.new(5, 5)
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = "fire"
	board.set_obstacles([{"row": 2, "col": 2, "type": "rock", "hp": hp}])
	return board


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ObstacleResolutionDamage] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[ObstacleResolutionDamage] " + failure)
	quit(1)

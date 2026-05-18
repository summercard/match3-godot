extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")
const MatchRules = preload("res://src/ui/components/battle_match_rules.gd")
const HazardRules = preload("res://src/ui/components/battle_hazard_rules.gd")

class FakeBattle:
	extends RefCounted
	var player_team: Array = [
		{"id": "monster_001", "hp": 100, "maxHP": 100},
		{"id": "monster_002", "hp": 80, "maxHP": 80}
	]
	var battle_over: bool = false
	var battle_result: String = ""

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var board = BoardScript.new(5, 5)
	board.offset_x = 0
	board.offset_y = 0
	board.cell_size = 10
	_fill_board(board, "fire")

	var match_result: Dictionary = {
		"gems": [{"row": 2, "col": 2, "type": "fire"}],
		"enhanced": [{"row": 2, "col": 2, "type": "fire"}],
		"bomb": [],
		"rainbow": []
	}
	var context: Dictionary = MatchRules.build_context(board, match_result, 0.5)
	_expect(context.get("has_matches", false), "match context should report matches")
	_expect(context.get("explosion_gems", []).size() == 8, "cross explosion should collect 8 surrounding gems")
	_expect(context.get("special_phases", []).size() == 1, "cross explosion should create one special phase")

	var removal: Dictionary = MatchRules.apply_removals(board, context)
	_expect(int(removal.get("gem_counts", {}).get("fire", 0)) == 9, "normal + cross removal should count 9 fire gems")
	_expect(removal.get("special_gems", []).size() == 8, "special gems should be exposed for visual/hazard follow-up")

	board.grid[2][2] = "fire"
	board.grid[2][3] = "fire"
	board.locked_gems[2][3] = {"hp": 1}
	var unlocks: Array = HazardRules.check_unlocks(board, [{"row": 2, "col": 2, "type": "fire"}])
	_expect(unlocks.size() == 1 and unlocks[0].get("fullyUnlocked", false), "adjacent same-color locked gem should unlock")

	board.set_poison_fog({"tiles": [{"row": 1, "col": 1}], "spreadInterval": 1})
	var battle := FakeBattle.new()
	var poison_result: Dictionary = HazardRules.process_poison_turn(board, battle)
	_expect(int(poison_result.get("fog_count", 0)) >= 1, "poison fog should count damaging tiles")
	_expect(int(poison_result.get("total_damage", 0)) > 0, "poison fog should deal visible damage")
	_expect(poison_result.get("hits", []).size() == 2, "poison fog should damage all living team members")

	var clears: Array = HazardRules.clear_poison_for_gems(board, [{"row": 1, "col": 1}])
	_expect(clears.size() == 1, "matching a fog tile should clear poison fog")
	_expect(not board.is_poison_fog(1, 1), "cleared poison fog should be removed from board")

	_finish()

func _fill_board(board, gem_type: String) -> void:
	board.grid = []
	for r in range(board.rows):
		board.grid.append([])
		for c in range(board.cols):
			board.grid[r].append(gem_type)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleRules] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[BattleRules] " + failure)
		quit(1)

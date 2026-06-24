extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")
const HazardRulesScript = preload("res://src/ui/components/battle_hazard_rules.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

class FakeBattle:
	extends RefCounted
	var player_team: Array = [
		{"id": "a", "hp": 100, "maxHP": 100},
		{"id": "b", "hp": 100, "maxHP": 100},
		{"id": "c", "hp": 100, "maxHP": 100}
	]
	var battle_over := false
	var battle_result := ""

class FakeVineDrawScene:
	extends RefCounted
	var line_count := 0
	var circle_count := 0
	func _get_texture(_path: String):
		return null
	func draw_line(_from: Vector2, _to: Vector2, _color: Color, _width: float = 1.0, _antialiased: bool = false) -> void:
		line_count += 1
	func draw_circle(_position: Vector2, _radius: float, _color: Color) -> void:
		circle_count += 1

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_stage_pressure_assignment()
	_test_vined_cell_deals_backlash_without_clearing()
	_test_adjacent_fire_burns_vine_without_backlash()
	_test_vines_stay_on_board_cell_during_gravity()
	_test_vines_render_on_empty_cells()
	_finish()


func _test_stage_pressure_assignment() -> void:
	var db := StageDBScript.new()
	var early_ch3 := db.get_stage("stage_3_2")
	var vine_ch3 := db.get_stage("stage_3_5")
	var gate_ch3 := db.get_stage("stage_3_6")
	var outer_ch3 := db.get_stage("stage_3_10")
	var boss_ch3 := db.get_stage("stage_3_12")
	_expect(not early_ch3.has("vines"), "chapter 3 should keep the first stages free of vines")
	_expect(vine_ch3.has("vines"), "chapter 3 mid stages should introduce vine pressure")
	_expect(vine_ch3.get("vines", []).size() == 4, "chapter 3 stage 5 should use a four-corner vine lesson")
	_expect(gate_ch3.get("vines", []) != vine_ch3.get("vines", []), "chapter 3 should vary vine layouts between stages")
	_expect(outer_ch3.get("vines", []).size() == 6, "chapter 3 late stages should use denser vine pressure")
	_expect(boss_ch3.get("vines", []).size() == 10, "chapter 3 boss should use a thorn-cage layout")
	_expect(float(boss_ch3.get("vineRule", {}).get("backlashPercent", 0.0)) > float(vine_ch3.get("vineRule", {}).get("backlashPercent", 0.0)), "chapter 3 boss should have stronger vine backlash")


func _test_vined_cell_deals_backlash_without_clearing() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.set_vines([{"row": 2, "col": 2}])
	var battle := FakeBattle.new()
	var result: Dictionary = HazardRulesScript.process_vine_resolution(board, battle, [{"row": 2, "col": 2, "type": "water"}], {"backlashPercent": 0.06})
	_expect(result.get("backlash", []).size() == 1, "removed gem on a vined cell should trigger one backlash")
	_expect(result.get("burned", []).is_empty(), "removed gem on a vined cell without adjacent fire should not burn")
	_expect(board.is_vined(2, 2), "backlash should not clear a persistent vine")
	_expect(int(result.get("total_damage", 0)) == 6, "one vine at 6 percent of 100 average max HP should deal 6 damage")
	_expect(_team_hp_sum(battle.player_team) == 294, "vine backlash should damage the player team")


func _test_adjacent_fire_burns_vine_without_backlash() -> void:
	var board = BoardScript.new(5, 5)
	_fill_checker(board)
	board.set_vines([{"row": 2, "col": 2}])
	var battle := FakeBattle.new()
	var removed := [
		{"row": 2, "col": 1, "type": "fire"},
		{"row": 2, "col": 2, "type": "water"}
	]
	var result: Dictionary = HazardRulesScript.process_vine_resolution(board, battle, removed, {"backlashPercent": 0.06, "burnedByAdjacentFire": true})
	_expect(result.get("burned", []).size() == 1, "adjacent removed fire should burn the vine")
	_expect(result.get("backlash", []).is_empty(), "burned vine should not trigger backlash")
	_expect(not board.is_vined(2, 2), "burned vine should be cleared")
	_expect(_team_hp_sum(battle.player_team) == 300, "burned vine should not damage the player team")


func _test_vines_stay_on_board_cell_during_gravity() -> void:
	var board = BoardScript.new(5, 5)
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = ""
	board.grid[1][2] = "grass"
	board.set_vines([{"row": 1, "col": 2}])
	board.apply_gravity()
	_expect(board.grid[4][2] == "grass", "vined gem should fall to the bottom")
	_expect(board.is_vined(1, 2), "vine should stay on its board cell during gravity")
	_expect(not board.is_vined(4, 2), "vine should not move with the falling gem")


func _test_vines_render_on_empty_cells() -> void:
	var renderer = load("res://src/ui/components/battle_board_renderer.gd")
	var board = BoardScript.new(5, 5)
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = ""
	board.set_vines([{"row": 2, "col": 2}])
	var scene := FakeVineDrawScene.new()
	renderer.draw_vines(scene, board, {"idle_time": 0.0, "vine_backlash_anims": [{"row": 2, "col": 2, "timer": 0.14}]})
	_expect(scene.line_count > 0, "persistent vines should render even when their board cell is temporarily empty")


func _fill_checker(board) -> void:
	var types := ["fire", "water", "grass", "thunder", "light"]
	for row in range(board.rows):
		for col in range(board.cols):
			board.grid[row][col] = types[(row * 2 + col) % types.size()]


func _team_hp_sum(team: Array) -> int:
	var total := 0
	for member: Dictionary in team:
		total += int(member.get("hp", 0))
	return total


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[VineMechanic] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[VineMechanic] " + failure)
	quit(1)

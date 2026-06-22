extends SceneTree

const BoardScript = preload("res://src/match3/board.gd")
const HazardRulesScript = preload("res://src/ui/components/battle_hazard_rules.gd")

class FakeBattle:
	extends RefCounted
	var player_team: Array = [
		{"id": "a", "hp": 100, "maxHP": 100},
		{"id": "b", "hp": 100, "maxHP": 100},
		{"id": "c", "hp": 100, "maxHP": 100}
	]
	var battle_over := false
	var battle_result := ""

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var board = BoardScript.new(3, 3)
	board.set_poison_fog({"tiles": [{"row": 1, "col": 1}], "spreadInterval": 999})
	var battle := FakeBattle.new()
	var result: Dictionary = HazardRulesScript.process_poison_turn(board, battle, 0.01)
	var actual_sum := 0
	for hit: Dictionary in result.get("hits", []):
		actual_sum += int(hit.get("damage", 0))
	_expect(int(result.get("total_damage", 0)) == 1, "one point of poison damage should remain one point")
	_expect(actual_sum == 1, "reported poison total should equal the sum of actual hits")
	_expect(_team_hp_sum(battle.player_team) == 299, "poison remainder should deal one real point instead of three zeroes")
	_expect(result.get("hits", []).size() == 3, "all living members should receive a hit entry")
	_finish()


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
		print("[PoisonDamageDistribution] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[PoisonDamageDistribution] " + failure)
	quit(1)

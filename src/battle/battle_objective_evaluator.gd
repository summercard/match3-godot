class_name BattleObjectiveEvaluator
extends RefCounted

const BOARD_GOAL_IDS: Array[String] = ["break_rocks", "fog_control", "unlock_path"]

var _goal: Dictionary = {}
var _mode := "defeat_enemies"
var _initial_target := 0
var _target := 0
var _last_state: Dictionary = {}


func configure(stage: Dictionary, board, enemies: Array) -> Dictionary:
	_goal = stage.get("stageGoal", {}).duplicate(true) if stage.get("stageGoal", {}) is Dictionary else {}
	var goal_id := str(_goal.get("id", "defeat_enemies"))
	_mode = goal_id if BOARD_GOAL_IDS.has(goal_id) else "defeat_enemies"
	_initial_target = _count_remaining(board, enemies)
	if _mode != "defeat_enemies" and _initial_target <= 0:
		_mode = "defeat_enemies"
		_initial_target = _count_alive_enemies(enemies)
	_target = _initial_target
	_last_state = evaluate(board, enemies, 0, 1)
	return _last_state.duplicate(true)


func is_non_defeat_goal() -> bool:
	return _mode != "defeat_enemies"


func evaluate(board, enemies: Array, turn_count: int, max_turns: int) -> Dictionary:
	var remaining := _count_remaining(board, enemies)
	_target = maxi(_target, remaining)
	var target := _target
	var completed := remaining <= 0
	var failed := not completed and turn_count >= max_turns
	var progress := maxi(0, target - remaining)
	var ratio := 1.0 if target <= 0 and completed else clampf(float(progress) / float(maxi(target, 1)), 0.0, 1.0)
	var goal_id := str(_goal.get("id", "defeat_enemies"))
	var label := str(_goal.get("label", _default_label(_mode)))
	_last_state = {
		"id": goal_id,
		"mode": _mode,
		"label": label,
		"target": target,
		"progress": progress,
		"remaining": remaining,
		"ratio": ratio,
		"completed": completed,
		"failed": failed,
		"reason": _completion_reason(_mode) if completed else "",
		"display": "%s %d/%d" % [label, progress, target]
	}
	return _last_state.duplicate(true)


func get_state() -> Dictionary:
	return _last_state.duplicate(true)


func _count_remaining(board, enemies: Array) -> int:
	match _mode:
		"break_rocks":
			return _count_board_cells(board, "obstacle")
		"fog_control":
			return _count_board_cells(board, "poison")
		"unlock_path":
			return _count_board_cells(board, "locked")
		_:
			return _count_alive_enemies(enemies)


func _count_board_cells(board, kind: String) -> int:
	if board == null:
		return _initial_target
	var count := 0
	for row in range(int(board.rows)):
		for col in range(int(board.cols)):
			if kind == "obstacle" and board.is_obstacle(row, col):
				count += 1
			elif kind == "poison" and board.is_poison_fog(row, col):
				count += 1
			elif kind == "locked" and board.is_locked(row, col):
				count += 1
	return count


func _count_alive_enemies(enemies: Array) -> int:
	var count := 0
	for enemy in enemies:
		if enemy is Dictionary and int(enemy.get("hp", 0)) > 0:
			count += 1
	return count


func _default_label(mode: String) -> String:
	match mode:
		"break_rocks":
			return "破障"
		"fog_control":
			return "控雾"
		"unlock_path":
			return "解锁"
		_:
			return "击败敌人"


func _completion_reason(mode: String) -> String:
	match mode:
		"break_rocks":
			return "全部岩石障碍已清除"
		"fog_control":
			return "全部毒雾已清除"
		"unlock_path":
			return "全部锁链已解除"
		_:
			return "敌人已全部击败"

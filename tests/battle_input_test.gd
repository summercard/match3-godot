extends SceneTree

var _main: Control = null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	_main = main
	root.add_child(main)
	await process_frame
	await process_frame
	
	var stage_db = load("res://src/data/stage_db.gd").new()
	var stage_data: Dictionary = stage_db.get_stage("stage_1_1")

	var battle_scene = await _load_battle(main, stage_data)
	var board = battle_scene.get("_board")
	var battle = battle_scene.get("_battle")
	var move := _find_valid_move(board)
	if move.is_empty():
		push_error("[BattleInput] no valid move found")
		await _finish(1)
		return
	
	var start := _cell_center(board, move["r1"], move["c1"])
	var end := _cell_center(board, move["r2"], move["c2"])
	battle_scene.call("_begin_pointer", start)
	battle_scene.call("_end_pointer", end)
	await process_frame
	await _wait_for_idle(battle_scene)
	
	if battle.turn_count <= 0:
		push_error("[BattleInput] drag did not trigger a valid swap")
		await _finish(1)
		return

	battle_scene = await _load_battle(main, stage_data)
	board = battle_scene.get("_board")
	battle = battle_scene.get("_battle")
	move = _find_valid_move(board)
	if move.is_empty():
		push_error("[BattleInput] no valid move found for event path")
		await _finish(1)
		return

	start = _cell_center(board, move["r1"], move["c1"])
	end = _cell_center(board, move["r2"], move["c2"])
	_send_mouse_drag(battle_scene, start, end)
	await process_frame
	await _wait_for_idle(battle_scene)

	if battle.turn_count <= 0:
		push_error("[BattleInput] scaled mouse event did not trigger a valid swap")
		await _finish(1)
		return

	battle_scene = await _load_battle(main, stage_data)
	board = battle_scene.get("_board")
	battle = battle_scene.get("_battle")
	move = _find_valid_move(board)
	if move.is_empty():
		push_error("[BattleInput] no valid move found for viewport dispatch")
		await _finish(1)
		return

	start = _cell_center(board, move["r1"], move["c1"])
	end = _cell_center(board, move["r2"], move["c2"])
	await _dispatch_mouse_drag(battle_scene, start, end)
	await process_frame
	await _wait_for_idle(battle_scene)

	if battle.turn_count <= 0:
		push_error("[BattleInput] viewport mouse dispatch did not trigger a valid swap")
		await _finish(1)
		return

	battle_scene = await _load_battle(main, stage_data)
	battle_scene.set("_auto_capture_enabled", false)
	var toggle_pos := _capture_toggle_center(battle_scene)
	_send_mouse_click(battle_scene, toggle_pos)
	await process_frame
	if not bool(battle_scene.get("_auto_capture_enabled")):
		push_error("[BattleInput] capture toggle should activate once per click")
		await _finish(1)
		return
	
	await _finish(0)

func _finish(exit_code: int) -> void:
	for _i in range(120):
		await process_frame
	if is_instance_valid(_main):
		_main.queue_free()
		_main = null
	await process_frame
	await process_frame
	if exit_code == 0:
		print("[BattleInput] OK")
	quit(exit_code)

func _load_battle(main: Control, stage_data: Dictionary) -> Control:
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_data,
		"inputTestOnly": true
	})
	await process_frame
	return main.get_current_scene()

func _wait_for_idle(battle_scene: Control) -> void:
	for _i in range(180):
		await process_frame
		if not is_instance_valid(battle_scene):
			return
		var state: int = int(battle_scene.get("_state"))
		if state == 0 or state == 5:
			return

func _find_valid_move(board) -> Dictionary:
	for r in range(board.rows):
		for c in range(board.cols):
			for delta in [Vector2i(1, 0), Vector2i(0, 1)]:
				var r2: int = r + delta.y
				var c2: int = c + delta.x
				if r2 < 0 or r2 >= board.rows or c2 < 0 or c2 >= board.cols:
					continue
				if not board.swap(r, c, r2, c2):
					continue
				var matched: bool = not board.find_matches().get("gems", []).is_empty()
				board.swap(r, c, r2, c2)
				if matched:
					return {"r1": r, "c1": c, "r2": r2, "c2": c2}
	return {}

func _cell_center(board, row: int, col: int) -> Vector2:
	return Vector2(
		board.offset_x + col * board.cell_size + board.cell_size / 2.0,
		board.offset_y + row * board.cell_size + board.cell_size / 2.0
	)

func _send_mouse_drag(battle_scene: Control, local_start: Vector2, local_end: Vector2) -> void:
	var transform := battle_scene.get_global_transform_with_canvas()
	var global_start: Vector2 = transform * local_start
	var global_end: Vector2 = transform * local_end

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_start
	battle_scene.call("_input", press)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_end
	battle_scene.call("_input", release)

func _send_mouse_click(battle_scene: Control, local_pos: Vector2) -> void:
	var transform := battle_scene.get_global_transform_with_canvas()
	var global_pos: Vector2 = transform * local_pos

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_pos
	battle_scene.call("_input", press)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_pos
	battle_scene.call("_input", release)

func _capture_toggle_center(battle_scene: Control) -> Vector2:
	var board = battle_scene.get("_board")
	var bottom_y: float = float(board.offset_y + board.rows * board.cell_size + 15.0)
	var rect: Rect2 = battle_scene.call("_get_capture_toggle_rect", bottom_y)
	return rect.get_center()

func _dispatch_mouse_drag(battle_scene: Control, local_start: Vector2, local_end: Vector2) -> void:
	var transform := battle_scene.get_global_transform_with_canvas()
	var global_start: Vector2 = transform * local_start
	var global_end: Vector2 = transform * local_end

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_start
	press.global_position = global_start
	root.push_input(press, false)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_end
	release.global_position = global_end
	root.push_input(release, false)

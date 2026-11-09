extends SceneTree

## 战斗倍速录像驱动：固定种子、固定落子顺序，分别以 1x / 2x 跑完同一场战斗。
## 2x 通过点击底栏 x2 按钮切入，按钮文字会从 1x 变为 2x。
##
## 录像：
##   Godot --path . --write-movie /tmp/battle_1x.avi --fixed-fps 30 \
##     --script res://tests/battle_speed_demo.gd -- --speed-level=1
##   Godot --path . --write-movie /tmp/battle_2x.avi --fixed-fps 30 \
##     --script res://tests/battle_speed_demo.gd -- --speed-level=2

const StageDBScript = preload("res://src/data/stage_db.gd")

var _speed_level := 1
var _stage_id := "stage_1_1"
var _seed := 20261110
var _settle_seconds := 0.8
var _post_seconds := 1.6


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_speed_level = int(_read_arg("--speed-level=", "1"))
	_stage_id = _read_arg("--stage-id=", "stage_1_1")
	_seed = int(_read_arg("--seed=", "20261110"))
	_settle_seconds = float(_read_arg("--settle-seconds=", "0.8"))
	_post_seconds = float(_read_arg("--post-seconds=", "1.6"))

	seed(_seed)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var stage_db = StageDBScript.new()
	main.switch_scene("battle", {
		"stageId": _stage_id,
		"stageData": stage_db.get_stage(_stage_id),
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		push_error("[BattleSpeedDemo] battle scene failed to load")
		quit(1)
		return
	var board = battle.get("_board")
	var battle_manager = battle.get("_battle")
	var start_frames := Engine.get_process_frames()

	await create_timer(_settle_seconds).timeout
	if _speed_level == 2:
		var speed_rect: Rect2 = battle.call("_get_speed_button_rect")
		_send_mouse_click(battle, speed_rect.get_center())
		await process_frame
		await create_timer(0.2).timeout

	var actions := 0
	var guard := 0
	while int(battle.get("_state")) != 6 and guard < 20000:
		await process_frame
		guard += 1
		if int(battle.get("_state")) != 0:
			continue
		await create_timer(0.12).timeout
		if int(battle.get("_state")) != 0:
			continue
		var move := _find_valid_move(board)
		if move.is_empty():
			break
		battle.call("_do_swap", move["r1"], move["c1"], move["r2"], move["c2"])
		actions += 1

	await create_timer(_post_seconds).timeout
	var end_frames := Engine.get_process_frames()
	var result: Dictionary = battle_manager.get_battle_result() if battle_manager != null else {}
	print("[BattleSpeedDemo] speed=%dx stage=%s seed=%d actions=%d turns=%d result=%s frames=%d fps=30 simulated=%.2fs label=%s" % [
		_speed_level,
		_stage_id,
		_seed,
		actions,
		int(battle_manager.turn_count) if battle_manager != null else 0,
		str(result.get("result", "")),
		end_frames - start_frames,
		float(end_frames - start_frames) / 30.0,
		(battle.get_node("TopHud/SpeedLabel") as Label).text if battle.has_node("TopHud/SpeedLabel") else "?",
	])
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	quit(0)


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


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

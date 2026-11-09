extends SceneTree

## 表现档位同帧截图驱动：
## 固定种子 + 同一关卡 + 同一棋盘 + 同一交换，按相同帧数截图；
## 仅切换 performanceMode（画质固定 high），用于三档同帧对比。
##
## 用法（窗口渲染，不用 --headless）：
##   Godot --path . --fixed-fps 60 --script res://tests/battle_presentation_capture.gd -- \
##     --performance-mode=lite --output=docs/evidence/presentation_settings/after_lite.png

const StageDBScript = preload("res://src/data/stage_db.gd")

var _quality := "high"
var _performance := "balanced"
var _stage_id := "stage_1_1"
var _seed := 20261110
var _frames_after := 4
var _output := "user://battle_presentation_capture.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_quality = _read_arg("--quality-level=", _quality)
	_performance = _read_arg("--performance-mode=", _performance)
	_stage_id = _read_arg("--stage-id=", _stage_id)
	_seed = int(_read_arg("--seed=", str(_seed)))
	_frames_after = int(_read_arg("--frames-after=", str(_frames_after)))
	_output = _read_arg("--output=", _output)
	_write_settings()

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
		push_error("[PresentationCapture] battle scene failed to load")
		quit(1)
		return
	var board = battle.get("_board")
	if board == null:
		push_error("[PresentationCapture] board missing")
		quit(1)
		return

	# 与 match_hit_feedback_test 相同的确定性棋盘：交换 (0,0)/(0,1) 后形成
	# 水 3 消与火 3 消，共 6 个被消除格，便于在相同帧比较粒子密度与震屏。
	_seed_swap_demo_board(board)
	await process_frame
	battle.call("_do_swap", 0, 0, 0, 1)
	if _read_arg("--hide-message=", "1") == "1":
		battle.set("_message_timer", 0.0)
	for _i in range(_frames_after):
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	var error := image.save_png(_output)
	if error != OK:
		push_error("[PresentationCapture] save failed: %s" % error_string(error))
		quit(1)
		return

	var profile: Dictionary = battle.call("get_presentation_profile") if battle.has_method("get_presentation_profile") else {}
	var particles := _particle_total(battle)
	var shake := _shake_length(battle)
	print("[PresentationCapture] quality=%s performance=%s seed=%d frame=%d particles=%d shake=%.2fpx output=%s" % [
		str(profile.get("quality", _quality)),
		str(profile.get("performance", _performance)),
		_seed,
		Engine.get_process_frames(),
		particles,
		shake,
		ProjectSettings.globalize_path(_output),
	])
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	quit(0)


func _write_settings() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_method("save_settings"):
		return
	var settings: Dictionary = save_manager.load_settings()
	settings["qualityLevel"] = _quality
	settings["performanceMode"] = _performance
	save_manager.save_settings(settings)


func _seed_swap_demo_board(board) -> void:
	_fill_pattern_board(board)
	board.grid[0][0] = "water"
	board.grid[0][1] = "fire"
	board.grid[0][2] = "water"
	board.grid[0][3] = "water"
	board.grid[1][0] = "fire"
	board.grid[2][0] = "fire"
	board.cascade_count = 0


func _fill_pattern_board(board) -> void:
	for r in range(board.rows):
		for c in range(board.cols):
			board.grid[r][c] = ["fire", "water", "grass", "thunder", "light"][(r + c) % 5]


func _particle_total(battle: Control) -> int:
	var total := 0
	for key: String in ["_gem_particles", "_obstacle_particles", "_defeat_explosions", "_victory_particles"]:
		var particles = battle.get(key)
		if particles is Array:
			total += (particles as Array).size()
	return total


func _shake_length(battle: Control) -> float:
	var attack := absf(float(battle.get("_attack_shake_offset_x")))
	var board_offset: Vector2 = battle.get("_board_shake_offset")
	var match_offset: Vector2 = battle.get("_match_shake_offset")
	return maxf(attack, (board_offset + match_offset).length())


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

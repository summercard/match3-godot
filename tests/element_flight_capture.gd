extends SceneTree

## 三消元素飞行特效证据采集：
## 固定 stage_1_1、固定棋盘、同一交换 (4,3)/(4,4)，只切换特效总开关。
## 基础工作树（a322404）没有 element_flight_effect.gd 时自动跳过开关设置，
## 因此同一脚本可以直接在基线上录制 before。
##
## 用法（窗口渲染 + 录像）：
##   Godot --path . --fixed-fps 60 --write-movie /tmp/element_on.avi \
##     --script res://tests/element_flight_capture.gd -- \
##     --stage-id=stage_1_1 --effect=on --record-seconds=1.1
##
## 用法（单帧截图）：
##   Godot --path . --fixed-fps 60 --script res://tests/element_flight_capture.gd -- \
##     --effect=on --hold-seconds=0.30 --output=/tmp/element_flight.png

const StageDBScript = preload("res://src/data/stage_db.gd")
const GEM_TYPES := ["fire", "water", "grass", "thunder", "light"]
const EFFECT_SCRIPT_PATH := "res://src/ui/components/element_flight_effect.gd"

var _quality := "high"
var _performance := "balanced"
var _stage_id := "stage_1_1"
var _seed := 20261109
var _effect_mode := "on"
var _output := "user://element_flight_capture.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_quality = _read_arg("--quality-level=", _quality)
	_performance = _read_arg("--performance-mode=", _performance)
	_stage_id = _read_arg("--stage-id=", _stage_id)
	_seed = int(_read_arg("--seed=", str(_seed)))
	_effect_mode = _read_arg("--effect=", _effect_mode)
	_output = _read_arg("--output=", _output)
	_write_settings()
	seed(_seed)

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("battle", {
		"stageId": _stage_id,
		"stageData": StageDBScript.new().get_stage(_stage_id)
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		push_error("[ElementFlightCapture] battle scene failed to load")
		quit(1)
		return
	var board = battle.get("_board")
	if board == null:
		push_error("[ElementFlightCapture] board missing")
		quit(1)
		return

	_apply_effect_switch()
	battle.set("_message_text", "")
	battle.set("_message_timer", 0.0)
	_seed_demo_board(board)
	await process_frame
	battle.call("_do_swap", 4, 3, 4, 4)

	var record_seconds := float(_read_arg("--record-seconds=", "0"))
	if record_seconds > 0.0:
		await create_timer(record_seconds).timeout
		quit(0)
		return

	for _frame in range(maxi(int(_read_arg("--settle-frames=", "0")), 1)):
		await process_frame
	var hold_seconds := float(_read_arg("--hold-seconds=", "0"))
	if hold_seconds > 0.0:
		await create_timer(hold_seconds).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(_output)
	if error != OK:
		push_error("[ElementFlightCapture] save failed: %s" % error_string(error))
		quit(1)
		return
	print("[ElementFlightCapture] effect=%s quality=%s performance=%s seed=%d output=%s" % [
		_effect_mode, _quality, _performance, _seed, ProjectSettings.globalize_path(_output)
	])
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	quit(0)


func _apply_effect_switch() -> void:
	if not ResourceLoader.exists(EFFECT_SCRIPT_PATH):
		return
	var effect_script = load(EFFECT_SCRIPT_PATH)
	if effect_script == null:
		return
	effect_script.enabled = _effect_mode != "off"


func _write_settings() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_method("save_settings"):
		return
	var settings: Dictionary = save_manager.load_settings()
	settings["qualityLevel"] = _quality
	settings["performanceMode"] = _performance
	save_manager.save_settings(settings)


func _seed_demo_board(board) -> void:
	for r in range(board.rows):
		for c in range(board.cols):
			board.grid[r][c] = GEM_TYPES[(r + c * 2) % GEM_TYPES.size()]
			board.obstacles[r][c] = null
			board.locked_gems[r][c] = null
			board.poison_fog[r][c] = null
	# 交换 (4,3)/(4,4)：第 4 行形成水 3 消，第 3 列形成火 3 消。
	board.grid[4][3] = "water"
	board.grid[4][4] = "fire"
	board.grid[4][5] = "water"
	board.grid[4][6] = "water"
	board.grid[5][3] = "fire"
	board.grid[6][3] = "fire"
	board.cascade_count = 0


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

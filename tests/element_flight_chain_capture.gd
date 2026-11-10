extends SceneTree

## T3 连锁 / 画质档证据采集：在真实战斗场景里把 cascade_count 固定为指定连锁，
## 生成指定档位 / 连锁的元素飞行，并在施法 / 飞行 / 命中环阶段截图或录像。
## 同一脚本可直接在基线 37b5277 工作树运行：基线没有连锁 / 档位参数，
## 会按基线行为生成同一发元素，用于 Before / After 对照。
##
## 截图：
##   Godot --path . --fixed-fps 60 --script res://tests/element_flight_chain_capture.gd -- \
##     --chain=2 --performance-mode=balanced --phase=ring --output=/tmp/after_chain2.png
## 录像：
##   Godot --path . --fixed-fps 60 --write-movie /tmp/after_chain2.avi \
##     --script res://tests/element_flight_chain_capture.gd -- \
##     --chain=2 --performance-mode=balanced --record-seconds=1.1

const StageDBScript = preload("res://src/data/stage_db.gd")
const GEM_TYPES := ["fire", "water", "grass", "thunder", "light"]
const EFFECT_SCRIPT_PATH := "res://src/ui/components/element_flight_effect.gd"

var _quality := "high"
var _performance := "balanced"
var _stage_id := "stage_1_1"
var _seed := 20261109
var _chain := 1
var _projectiles := 1
var _phase := "ring"
var _output := "user://element_flight_chain.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_quality = _read_arg("--quality-level=", _quality)
	_performance = _read_arg("--performance-mode=", _performance)
	_stage_id = _read_arg("--stage-id=", _stage_id)
	_seed = int(_read_arg("--seed=", str(_seed)))
	_chain = maxi(1, int(_read_arg("--chain=", "1")))
	_projectiles = maxi(1, int(_read_arg("--projectiles=", "1")))
	_phase = _read_arg("--phase=", _phase)
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
		push_error("[ChainCapture] battle scene failed to load")
		quit(1)
		return
	var board = battle.get("_board")
	if board == null:
		push_error("[ChainCapture] board missing")
		quit(1)
		return

	_seed_demo_board(board)
	await process_frame
	battle.set("_message_text", "")
	battle.set("_message_timer", 0.0)
	# 强制连锁等级：战斗内由 cascade_count 映射到元素飞行的连锁参数。
	board.cascade_count = _chain
	var matches: Array = []
	for i in range(_projectiles):
		matches.append({
			"row": 4,
			"col": 3 + i,
			"type": ["fire", "water", "grass"][i % 3],
		})
	battle.call("_spawn_element_flights", matches)

	var record_seconds := float(_read_arg("--record-seconds=", "0"))
	if record_seconds > 0.0:
		await create_timer(record_seconds).timeout
		quit(0)
		return

	await create_timer(_phase_seconds(_phase)).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(_output)
	if error != OK:
		push_error("[ChainCapture] save failed: %s" % error_string(error))
		quit(1)
		return
	var stats: Dictionary = battle.call("get_element_flight_budget_stats") if battle.has_method("get_element_flight_budget_stats") else {}
	print("[ChainCapture] chain=%d tier=%s phase=%s projectiles=%d stats=%s output=%s" % [
		_chain,
		_performance,
		_phase,
		_projectiles,
		JSON.stringify(stats),
		ProjectSettings.globalize_path(_output),
	])
	main.queue_free()
	await process_frame
	await process_frame
	quit(0)


## 阶段对应的等待时长（从生成元素开始计时）。
func _phase_seconds(phase: String) -> float:
	match phase:
		"cast":
			return 0.09
		"flight":
			return 0.30
		"ring":
			return 0.66
		"second_ring":
			return 0.70
		_:
			return 0.66


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
	board.cascade_count = 0


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

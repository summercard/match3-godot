extends SceneTree

## 命中粒子颗粒度证据采集：固定画面 / 固定种子 / 一次真实命中，
## 在命中后指定时刻冻结画面并截图，同时输出本次命中的粒子数与单颗尺寸。
##
## 同一脚本只读现有表现接口，可直接在基线工作树（7585b9b）运行，
## 用于 Before / After 同条件对照。
##
## 截图：
##   Godot --path . --fixed-fps 60 \
##     --script res://tests/particle_granularity_capture.gd -- \
##     --performance-mode=balanced --chain=1 --projectiles=1 --gem-type=grass \
##     --at=0.46 --output=/tmp/particles_after.png

const StageDBScript = preload("res://src/data/stage_db.gd")
const GEM_TYPES := ["fire", "water", "grass", "thunder", "light"]
const EFFECT_SCRIPT_PATH := "res://src/ui/components/element_flight_effect.gd"

var _quality := "high"
var _performance := "balanced"
var _stage_id := "stage_1_1"
var _seed := 20261109
var _chain := 1
var _projectiles := 1
var _gem_type := "grass"
var _at := 0.46
var _output := "user://particle_granularity.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_quality = _read_arg("--quality-level=", _quality)
	_performance = _read_arg("--performance-mode=", _performance)
	_stage_id = _read_arg("--stage-id=", _stage_id)
	_seed = int(_read_arg("--seed=", str(_seed)))
	_chain = maxi(1, int(_read_arg("--chain=", "1")))
	_projectiles = maxi(1, int(_read_arg("--projectiles=", "1")))
	_gem_type = _read_arg("--gem-type=", _gem_type)
	_at = maxf(0.0, float(_read_arg("--at=", "0.46")))
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
		push_error("[ParticleGranularity] battle scene failed to load")
		quit(1)
		return
	var board = battle.get("_board")
	if board == null:
		push_error("[ParticleGranularity] board missing")
		quit(1)
		return

	_seed_demo_board(board)
	await process_frame
	battle.set("_message_text", "")
	battle.set("_message_timer", 0.0)
	board.cascade_count = _chain
	var matches: Array = []
	for i in range(_projectiles):
		matches.append({
			"row": 4,
			"col": 3 + i,
			"type": _gem_type,
		})
	battle.call("_spawn_element_flights", matches)

	await create_timer(_at).timeout
	paused = true
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(_output)
	if error != OK:
		push_error("[ParticleGranularity] save failed: %s" % error_string(error))
		quit(1)
		return

	var effects := _collect_effects(battle)
	for effect in effects:
		_print_effect(effect)
	paused = false
	print("[ParticleGranularity] tier=%s chain=%d projectiles=%d at=%.3fs output=%s" % [
		_performance, _chain, _projectiles, _at, ProjectSettings.globalize_path(_output)
	])
	main.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _print_effect(effect) -> void:
	var particles: Array = effect.get("_particles")
	var sizes: Array = []
	var positions: Array = []
	for particle: Dictionary in particles:
		sizes.append(snappedf(float(particle["size"]), 0.01))
		var position: Vector2 = particle["position"]
		positions.append([snappedf(position.x, 0.1), snappedf(position.y, 0.1)])
	var script = load(EFFECT_SCRIPT_PATH)
	var config: Dictionary = script.CONFIG if script != null else {}
	var size_min := float(config.get("particle_size_min", 0.0))
	var size_max := float(config.get("particle_size_max", 0.0))
	var scale := float(root.get_visible_rect().size.x) / 375.0
	print("[ParticleGranularity] hit count=%d sizes=%s config_size=%.1f-%.1fpx anchor=(%.1f,%.1f) window_scale=%.2fx positions=%s" % [
		int(effect.get("particle_count")),
		JSON.stringify(sizes),
		size_min,
		size_max,
		float(effect.anchor.x),
		float(effect.anchor.y),
		scale,
		JSON.stringify(positions),
	])


func _collect_effects(battle: Control) -> Array:
	var effects: Array = []
	for child in battle.get_children():
		if child.get_script() == load(EFFECT_SCRIPT_PATH):
			effects.append(child)
	return effects


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

extends SceneTree

const TowerRunControllerScript = preload("res://src/core/tower_run_controller.gd")
const TowerRulesScript = preload("res://src/core/tower_rules.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var output_path := _read_arg("--output=", "res://.godot/tower_battle_qa_v1.png")
	var storage := root.get_node_or_null("/root/SaveManager")
	if storage == null:
		push_error("[TowerBattleCapture] SaveManager is unavailable")
		quit(1)
		return
	storage.clear_all_data()
	storage.save_stage_stars("stage_1_8", 1)
	var controller := TowerRunControllerScript.new(storage)
	var started := controller.start_new_run()
	if not bool(started.get("ok", false)):
		push_error("[TowerBattleCapture] tower run could not start")
		quit(1)
		return
	var state: Dictionary = started.get("state", {})
	var stage := TowerRulesScript.current_floor_data(state)
	stage["towerBuffs"] = state.get("buffs", []).duplicate(true)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("battle", {"stageId": stage.get("id", ""), "stageData": stage, "towerMode": true, "towerState": state})
	for _frame in range(8 + int(_read_arg("--settle-frames=", "24"))):
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("[TowerBattleCapture] save failed: %s" % error_string(error))
		quit(1)
		return
	print("[TowerBattleCapture] %s" % ProjectSettings.globalize_path(output_path))
	quit(0)


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

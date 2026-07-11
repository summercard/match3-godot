extends SceneTree

const TowerRunControllerScript = preload("res://src/core/tower_run_controller.gd")
const TowerRulesScript = preload("res://src/core/tower_rules.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var output_path := _read_arg("--output=", "res://.godot/tower_card_choice_qa_v2.png")
	var storage := root.get_node_or_null("/root/SaveManager")
	if storage == null:
		push_error("[TowerCardCapture] SaveManager is unavailable")
		quit(1)
		return
	storage.clear_all_data()
	storage.save_stage_stars("stage_1_8", 1)
	var controller := TowerRunControllerScript.new(storage)
	var started := controller.start_new_run()
	if not bool(started.get("ok", false)):
		push_error("[TowerCardCapture] tower run could not start")
		quit(1)
		return
	var state: Dictionary = started.get("state", {})
	var stage := TowerRulesScript.current_floor_data(state)
	stage["towerBuffs"] = state.get("buffs", []).duplicate(true)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("battle", {"stageId": stage.get("id", ""), "stageData": stage, "towerMode": true, "towerState": state})
	await process_frame
	await process_frame
	var battle_scene := main.get_current_scene() as Control
	for _floor in range(5):
		var battle = battle_scene.get("_battle")
		for raw_enemy in battle.get("enemies"):
			if raw_enemy is Dictionary:
				(raw_enemy as Dictionary)["hp"] = 0
		battle_scene.call("_check_battle_end")
		await create_timer(1.0).timeout
	for _frame in range(int(_read_arg("--settle-frames=", "18"))):
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("[TowerCardCapture] save failed: %s" % error_string(error))
		quit(1)
		return
	print("[TowerCardCapture] %s" % ProjectSettings.globalize_path(output_path))
	quit(0)


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

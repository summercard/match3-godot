extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_name := "stage_select"
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--scene-name="):
			scene_name = arg.trim_prefix("--scene-name=")
	
	var main := Control.new()
	main.name = "Main"
	main.set_script(load("res://main.gd"))
	root.add_child(main)
	await process_frame
	await process_frame
	
	if scene_name == "battle":
		var stage_db = load("res://src/data/stage_db.gd").new()
		var stage_data: Dictionary = stage_db.get_stage("stage_1_1")
		main.switch_scene("battle", {
			"stageId": "stage_1_1",
			"stageData": stage_data
		})
	else:
		main.switch_scene(scene_name)
	
	while true:
		await process_frame

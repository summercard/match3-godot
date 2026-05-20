extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(450, 800)
	var main := Control.new()
	main.name = "Main"
	main.set_script(load("res://main.gd"))
	root.add_child(main)
	await process_frame
	await process_frame

	main.switch_scene("start")
	await process_frame
	var start_scene = main.get("_current_scene")
	start_scene._do_enter()
	for i in range(40):
		await process_frame
	var after_start: String = main.get("_current_scene_name")
	if after_start != "main" and after_start != "tutorial":
		push_error("start click did not enter game, got: " + after_start)
		quit(1)
	if after_start == "tutorial":
		main.switch_scene("main")
		await process_frame

	var main_scene = main.get("_current_scene")
	main_scene._on_touch_start(70.0, 290.0)
	for i in range(80):
		await process_frame
	var after_lobby: String = main.get("_current_scene_name")
	if after_lobby != "stage_select":
		push_error("main adventure press did not enter stage_select, got: " + after_lobby)
		quit(1)
		return

	print("[tmp_test_main_start_click] ok")
	quit()

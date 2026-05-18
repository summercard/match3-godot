extends SceneTree

var _failures: Array[String] = []
var _owned_roots: Array[Node] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		await _finish()
		return

	save_manager.clear_all_data()
	var legacy_main: Control = load("res://main.tscn").instantiate()
	_owned_roots.append(legacy_main)
	root.add_child(legacy_main)
	await process_frame
	await process_frame
	await _enter_from_start(legacy_main)
	_expect(legacy_main.get_current_scene_name() == "main", "save without tutorial progress should enter main")
	legacy_main.queue_free()
	await process_frame

	save_manager.save_tutorial_progress(0)
	var main: Control = load("res://main.tscn").instantiate()
	_owned_roots.append(main)
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.get_current_scene_name() == "start", "start scene should load")
	await _enter_from_start(main)
	_expect(main.get_current_scene_name() == "tutorial", "fresh player should enter tutorial from start")

	var tutorial: Control = main.get_current_scene()
	_expect(tutorial != null and int(tutorial.get("_current_step")) == 0, "tutorial should start at step 0")
	tutorial.call("_next_step")
	await process_frame

	var progress: Dictionary = save_manager.load_tutorial_progress()
	_expect(not progress.get("completed", true), "tutorial should remain incomplete after first step")
	_expect(int(progress.get("currentStep", -1)) == 1, "tutorial should save current step")

	main.switch_scene("main")
	await process_frame
	main.switch_scene("tutorial")
	await process_frame
	tutorial = main.get_current_scene()
	_expect(tutorial != null and int(tutorial.get("_current_step")) == 1, "tutorial should resume saved step")

	for _i in range(4):
		tutorial.call("_next_step")
		await process_frame
	await _wait_for_scene(main, "main")

	progress = save_manager.load_tutorial_progress()
	_expect(main.get_current_scene_name() == "main", "completed tutorial should return to main")
	_expect(progress.get("completed", false), "completed tutorial should be saved")
	_expect(int(progress.get("currentStep", 0)) >= 5, "completed tutorial should save final step")

	save_manager.save_tutorial_progress(0)
	main.switch_scene("tutorial")
	await process_frame
	tutorial = main.get_current_scene()
	tutorial.call("_skip_tutorial")
	await _wait_for_scene(main, "main")

	progress = save_manager.load_tutorial_progress()
	_expect(main.get_current_scene_name() == "main", "skipped tutorial should return to main")
	_expect(progress.get("completed", false), "skipped tutorial should be saved as complete")

	main.switch_scene("start")
	await process_frame
	await _enter_from_start(main)
	_expect(main.get_current_scene_name() == "main", "completed player should enter main from start")

	await _finish()

func _enter_from_start(main: Control) -> void:
	var start_scene: Control = main.get_current_scene()
	_expect(start_scene != null, "start scene node should exist")
	if start_scene != null:
		start_scene.call("_do_enter")
	await _wait_for_non_start(main)

func _wait_for_non_start(main: Control) -> void:
	for _i in range(90):
		await process_frame
		if main.get_current_scene_name() != "start":
			return

func _wait_for_scene(main: Control, scene_name: String) -> void:
	for _i in range(90):
		await process_frame
		if main.get_current_scene_name() == scene_name:
			return

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	await create_timer(0.8).timeout
	for node in _owned_roots:
		if is_instance_valid(node):
			node.queue_free()
	_owned_roots.clear()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("[TutorialFlow] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[TutorialFlow] " + failure)
		quit(1)

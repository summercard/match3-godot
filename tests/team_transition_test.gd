extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	main.name = "Main"
	root.add_child(main)
	await process_frame
	await process_frame

	var manager := root.get_node_or_null("SceneManager")
	_expect(manager != null, "SceneManager should exist")
	if manager == null:
		_finish()
		return

	var start_button := main.get_current_scene().get_node_or_null("Content/StartButton") as Control
	var old_page_tap_position := Vector2(187.0, 520.0)
	if start_button != null:
		old_page_tap_position = start_button.get_global_rect().get_center()

	manager.switch_scene("team")
	var overlay: ColorRect = manager.get("_transition_overlay")
	_expect(manager.has_method("is_transitioning"), "SceneManager should expose transition state")
	_expect(bool(manager.call("is_transitioning")), "transition state should be active immediately after switch_scene")
	_expect(overlay != null, "transition overlay should exist")
	if overlay != null:
		_expect(overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "transition overlay should block input while transitioning")
	await _dispatch_click(old_page_tap_position)
	var frames := 0
	var peak_alpha := 0.0
	while bool(manager.get("_is_transitioning")) and frames < 60:
		await process_frame
		frames += 1
		if overlay != null:
			peak_alpha = maxf(peak_alpha, overlay.color.a)

	_expect(main.get_current_scene_name() == "team", "team transition should complete")
	if overlay != null:
		_expect(overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "transition overlay should release input after transition")
	_expect(not bool(manager.call("is_transitioning")), "transition state should be inactive after transition")
	_expect(peak_alpha <= 0.43, "team transition should not cover the page with a black screen")
	_expect(frames <= 18, "team transition should finish quickly on mobile")
	for _i in range(40):
		await process_frame
	var settle_frames := 0
	while bool(manager.get("_is_transitioning")) and settle_frames < 90:
		await process_frame
		settle_frames += 1
	_expect(main.get_current_scene_name() == "team", "clicks on the old page during transition should not enqueue another scene")
	_finish()

func _dispatch_click(position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	root.push_input(press, false)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	root.push_input(release, false)

func _finish() -> void:
	if _failures.is_empty():
		print("[TeamTransition] OK")
		quit(0)
	else:
		for failure in _failures:
			push_error("[TeamTransition] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

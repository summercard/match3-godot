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

	manager.switch_scene("team")
	var frames := 0
	var peak_alpha := 0.0
	while bool(manager.get("_is_transitioning")) and frames < 60:
		await process_frame
		frames += 1
		var overlay: ColorRect = manager.get("_transition_overlay")
		if overlay != null:
			peak_alpha = maxf(peak_alpha, overlay.color.a)

	_expect(main.get_current_scene_name() == "team", "team transition should complete")
	_expect(peak_alpha <= 0.43, "team transition should not cover the page with a black screen")
	_expect(frames <= 18, "team transition should finish quickly on mobile")
	_finish()

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

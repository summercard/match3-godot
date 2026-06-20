extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("ranch", {"page": "classroom"})
	await process_frame
	var ranch: Control = main.get_current_scene()
	_expect(ranch != null, "ranch route should create a scene")
	if ranch != null:
		_expect(str(ranch.get("_active_page")) == "classroom", "ranch route should preserve the classroom page parameter")
		_expect((ranch.get_node("Pages/ClassroomPage") as Control).visible, "classroom page should be visible immediately")
	main.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[ResultClassroomRoute] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[ResultClassroomRoute] " + failure)
	quit(1)

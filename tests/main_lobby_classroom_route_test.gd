extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("main")
	await process_frame

	var lobby := main.get_current_scene() as Control
	_expect(lobby != null, "main lobby should be available")
	if lobby != null:
		(lobby.get_node("PrimaryButtons/RanchButton") as TextureButton).pressed.emit()
		for _i in range(30):
			await process_frame
			var current: Control = main.get_current_scene() as Control
			if current != null and current.scene_file_path.ends_with("ranch_hub.tscn"):
				break

	var classroom := main.get_current_scene() as Control
	_expect(classroom != null and str(classroom.get("_active_page")) == "classroom", "clicking the lobby classroom entry should open the classroom page first")
	_expect(classroom != null and (classroom.get_node("Pages/ClassroomPage") as Control).visible, "classroom page should be visible immediately after lobby navigation")

	main.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[MainLobbyClassroomRoute] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[MainLobbyClassroomRoute] " + failure)
	quit(1)

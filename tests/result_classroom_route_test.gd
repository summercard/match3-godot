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
	main.switch_scene("result", _failure_result_data())
	await process_frame
	var result: Control = main.get_current_scene()
	_expect(result != null, "failure result route should create a scene")
	if result != null:
		_expect((result.get_node("Buttons/BackButton") as Control).visible, "failure result should show manor button")
		_expect((result.get_node("Buttons/NextButton") as Control).visible, "failure result should show classroom button")
		_expect((result.get_node("Buttons/RetryButton") as Control).visible, "failure result should keep retry button")
		_expect((result.get_node("Buttons/BackButton/Text") as Label).text == "返回庄园", "failure result left button should return to manor")
		_expect((result.get_node("Buttons/NextButton/Text") as Label).text == "回精灵课堂升级", "failure result middle button should go to classroom upgrade")
		result.call("_on_result_next_pressed")
		await _wait_frames(55)
		var classroom_scene: Control = main.get_current_scene()
		_expect(classroom_scene != null and classroom_scene.name == "SceneRanch", "failure classroom button should route to ranch")
		if classroom_scene != null and classroom_scene.has_node("Pages/ClassroomPage"):
			_expect(str(classroom_scene.get("_active_page")) == "classroom", "failure classroom button should open classroom page")
	main.switch_scene("result", _failure_result_data())
	await process_frame
	result = main.get_current_scene()
	if result != null:
		result.call("_on_result_back_pressed")
		await _wait_frames(55)
		var lobby_scene: Control = main.get_current_scene()
		_expect(lobby_scene != null and main.get_current_scene_name() == "main" and lobby_scene.scene_file_path == "res://src/ui/scenes/main_lobby.tscn", "failure manor button should route to the current main lobby scene")
	main.queue_free()
	await process_frame
	_finish()

func _failure_result_data() -> Dictionary:
	return {
		"result": "lose",
		"stageId": "stage_1_1",
		"turnCount": 7,
		"maxTurns": 8,
		"stageRewards": {"gold": 0, "exp": 0},
		"playerTeam": [],
		"enemies": [],
	}

func _wait_frames(count: int) -> void:
	for _i in count:
		await process_frame

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

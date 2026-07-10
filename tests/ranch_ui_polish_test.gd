extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("ranch")
	await process_frame
	var ranch := main.get_current_scene() as Control
	_expect(ranch != null, "ranch scene should load for UI polish checks")
	if ranch != null:
		for path in [
			"Pages/RanchPage/Slots/Slot1",
			"Pages/RanchPage/BottomButtons/ClassroomButton",
			"Pages/RanchPage/BottomButtons/SocialButton",
			"Pages/ClassroomPage/DetailPanel/EvolveButton",
			"Pages/ClassroomPage/DetailPanel/UpgradeButton",
			"Pages/SocialPage/PlacePanel/SwitchButton",
			"Pages/SocialPage/BottomButtons/ActionButton",
		]:
			var button := ranch.get_node(path) as BaseButton
			_expect(button != null and button.size.x > 0.0 and button.size.y > 0.0, "%s should keep an authored interactive hit area" % path)
		for label_path in [
			"Pages/RanchPage/CollectRow/ExpValue",
			"Pages/ClassroomPage/DetailPanel/MonsterExpText",
			"Pages/SocialPage/PlacePanel/Preview",
		]:
			var label := ranch.get_node(label_path) as Label
			_expect(label != null and label.get_line_height() > 0, "%s should keep readable typography" % label_path)
		ranch.call("_switch_to_classroom")
		_expect((ranch.get_node("Pages/ClassroomPage/DetailPanel/EvolveButton/butter02") as Control).visible, "classroom should use its authored evolve button art")
		ranch.call("_switch_to_social")
		var switch_button := ranch.get_node("Pages/SocialPage/PlacePanel/SwitchButton") as BaseButton
		switch_button.pressed.emit()
		_expect(not str(ranch.get("_status_text")).is_empty() or (ranch.get_node("Pages/SocialPage") as Control).visible, "social place control should remain interactive")

	root.remove_child(main)
	main.free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchUiPolish] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchUiPolish] " + failure)
	quit(1)

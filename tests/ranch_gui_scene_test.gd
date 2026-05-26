extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("ranch")
	await process_frame
	var ranch: Control = main.get_current_scene()
	_expect(ranch != null, "ranch scene should instantiate")
	if ranch != null:
		_expect(ranch.scene_file_path == "res://src/ui/scenes/ranch_hub.tscn", "ranch should load editable PackedScene")
		for path in [
			"Pages/RanchPage/Slots/Slot1",
			"Pages/RanchPage/RosterPanel/Card1",
			"Pages/ClassroomPage/DetailPanel/EvolveButton",
			"Pages/ClassroomPage/RosterPanel/Card1",
			"Pages/SocialPage/PlacePanel/SlotA",
			"Pages/SocialPage/RosterPanel/Card1",
			"Pages/SocialPage/ResultPopup/ConfirmButton",
		]:
			_expect(ranch.has_node(path), "editable node should exist: %s" % path)
			_expect(ranch.get_node(path) is TextureButton, "interactive node should be TextureButton: %s" % path)
		(ranch.get_node("Pages/RanchPage/BottomButtons/ClassroomButton") as TextureButton).pressed.emit()
		_expect((ranch.get_node("Pages/ClassroomPage") as Control).visible, "classroom button should reveal classroom GUI page")
		(ranch.get_node("Pages/ClassroomPage/BottomButtons/SocialButton") as TextureButton).pressed.emit()
		_expect((ranch.get_node("Pages/SocialPage") as Control).visible, "social button should reveal social GUI page")
		(ranch.get_node("Header/BackButton") as TextureButton).pressed.emit()
		_expect((ranch.get_node("Pages/RanchPage") as Control).visible, "back from subpage should reveal ranch GUI page")
		ranch.set("_storage", null)
		ranch.set("_captured_monsters", [
			{"instanceId": "monster_001", "monsterId": "monster_001", "level": 3, "nature": "brave"},
		])
		ranch.set("_slots_data", [
			{"instance_id": "monster_001", "placed_at": Time.get_unix_time_from_system() * 1000.0 - 10.0 * 60.0 * 1000.0},
			{"instance_id": null, "placed_at": null},
			{"instance_id": null, "placed_at": null},
			{"instance_id": null, "placed_at": null},
			{"instance_id": null, "placed_at": null},
		])
		ranch.call("_calc_idle_exp")
		ranch.call("_sync_gui")
		(ranch.get_node("Pages/RanchPage/CollectRow/CollectButton") as TextureButton).pressed.emit()
		_expect(str(ranch.get("_status_text")).begins_with("收获 +"), "GUI collect button should preserve ranch reward feedback")
		ranch.call("_switch_to_social")
		ranch.set("_social_result_popup", {"label": "社交完成", "majorOutcome": {"type": "none"}, "tags": []})
		ranch.call("_sync_gui")
		_expect((ranch.get_node("Pages/SocialPage/ResultPopup") as Control).visible, "result popup should be visible from GUI data")
		var outside_tap := InputEventMouseButton.new()
		outside_tap.button_index = MOUSE_BUTTON_LEFT
		outside_tap.pressed = true
		(ranch.get_node("Pages/SocialPage/ResultPopup/Shade") as Control).gui_input.emit(outside_tap)
		_expect(not (ranch.get_node("Pages/SocialPage/ResultPopup") as Control).visible, "popup shade should close result without click-through")
	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[RanchGuiScene] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchGuiScene] " + failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

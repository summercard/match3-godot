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
			"Pages/RanchPage/RosterPanel/PageText",
			"Pages/ClassroomPage/DetailPanel/EvolveButton",
			"Pages/ClassroomPage/RosterPanel/Card1",
			"Pages/SocialPage/PlacePanel/SlotA",
			"Pages/SocialPage/RosterPanel/Card1",
			"Pages/SocialPage/ResultPopup/ConfirmButton",
		]:
			_expect(ranch.has_node(path), "editable node should exist: %s" % path)
			if not path.ends_with("PageText"):
				_expect(ranch.get_node(path) is TextureButton, "interactive node should be TextureButton: %s" % path)
		_expect(ranch.get_node("Pages/RanchPage/RosterPanel/Frame") is TextureRect, "farm roster backing should match classroom and social TextureRect panels")
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
		var timer := ranch.get_node("Pages/RanchPage/Slots/Slot1/Timer") as Label
		var timer_before := timer.text
		var exp_before := int((ranch.get("_idle_exp_map") as Dictionary).get("monster_001", 0))
		var slots: Array = ranch.get("_slots_data")
		slots[0]["placed_at"] = float(slots[0]["placed_at"]) - 5.0 * 60.0 * 1000.0
		ranch.set("_slots_data", slots)
		ranch.call("_sync_dynamic_gui")
		_expect(timer.text.count(":") == 2, "farm slot timer should expose seconds so idle time visibly advances")
		_expect(timer.text != timer_before, "farm slot timer should refresh while the page remains open")
		_expect(int((ranch.get("_idle_exp_map") as Dictionary).get("monster_001", 0)) > exp_before, "farm dynamic refresh should recalculate idle rewards")
		(ranch.get_node("Pages/RanchPage/CollectRow/CollectButton") as TextureButton).pressed.emit()
		_expect(str(ranch.get("_status_text")).begins_with("收获 +"), "GUI collect button should preserve ranch reward feedback")
		ranch.call("_switch_to_social")
		ranch.set("_social_places", [{
			"place_id": "meadow_yard",
			"slot_a": null,
			"slot_b": null,
			"started_at": null,
			"last_result": {},
		}])
		ranch.call("_sync_gui")
		var ranch_locked_card := ranch.get_node("Pages/SocialPage/RosterPanel/Card1") as TextureButton
		_expect(ranch_locked_card.modulate.a < 1.0, "farm monster should appear unavailable in social roster")
		ranch_locked_card.pressed.emit()
		_expect(str(ranch.get("_status_text")).contains("农场挂机"), "farm monster social tap should explain how to unlock it")
		_expect((ranch.get("_social_places") as Array)[0].get("slot_a", null) == null, "farm monster should not enter social slot from GUI")
		ranch.set("_social_places", [{
			"place_id": "meadow_yard",
			"slot_a": null,
			"slot_b": null,
			"started_at": Time.get_unix_time_from_system() * 1000.0 - 1000.0,
			"last_result": {},
		}])
		ranch.call("_sync_gui")
		var social_action := ranch.get_node("Pages/SocialPage/BottomButtons/ActionButton") as TextureButton
		_expect(not social_action.disabled, "running social action should stay tappable for progress feedback")
		_expect((ranch.get_node("Pages/SocialPage/PlacePanel/FxLayer/HeartFx1") as TextureRect).visible, "running social should animate extracted floating hearts")
		social_action.pressed.emit()
		_expect(str(ranch.get("_status_text")).contains("%"), "running social tap should report live progress")
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

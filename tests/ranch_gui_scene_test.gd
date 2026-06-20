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
		for panel_path in [
			"Pages/RanchPage/RosterPanel",
			"Pages/ClassroomPage/RosterPanel",
			"Pages/SocialPage/RosterPanel",
		]:
			var roster_back := ranch.get_node("%s/Frame/black/NinePatch" % panel_path) as NinePatchRect
			_expect(roster_back.texture.resource_path.ends_with("black.png"), "%s roster backing should use the shared black nine-patch art" % panel_path)
			var card_back := ranch.get_node("%s/Card1/CardBack/NinePatch" % panel_path) as NinePatchRect
			_expect(card_back.texture.resource_path.ends_with("panel_base.png"), "%s card should use the album-style backing" % panel_path)
			_expect(ranch.get_node("%s/Card1/Level" % panel_path) is Label, "%s card should show a level label" % panel_path)
			_expect(not ranch.has_node("%s/Card1/Frame" % panel_path), "%s card should not keep the old roster frame" % panel_path)
			_expect((ranch.get_node("%s/Card1" % panel_path) as Control).position == Vector2(15.0, 14.0), "%s first roster card should follow the layered plaza card layout" % panel_path)
			_expect((ranch.get_node("%s/Card6" % panel_path) as Control).position == Vector2(280.0, 14.0), "%s roster cards should use the layered plaza spacing" % panel_path)
			_expect((ranch.get_node("%s/Card1" % panel_path) as CanvasItem).z_index == 1, "%s first roster card should start the layered draw order" % panel_path)
			_expect((ranch.get_node("%s/Card6" % panel_path) as CanvasItem).z_index == 6, "%s last roster card should draw above earlier cards" % panel_path)
			_expect((ranch.get_node("%s/Card1/Level" % panel_path) as Control).position == Vector2(6.0, 71.0), "%s level label should follow the farm card layout" % panel_path)
			_expect((ranch.get_node("%s/Card1/Level" % panel_path) as Label).get_theme_font_size("font_size") == 12, "%s level label should use the compact farm text size" % panel_path)
			_expect((ranch.get_node("%s/Card1/Check" % panel_path) as Control).position == Vector2(-3.0, 1.0), "%s selection check should follow the farm card layout" % panel_path)
			_expect((ranch.get_node("%s/Card1/Check" % panel_path) as Control).size == Vector2(26.0, 26.0), "%s selection check should use the glossy farm card size" % panel_path)
			_expect((ranch.get_node("%s/Card1/Check" % panel_path) as TextureRect).texture.resource_path.ends_with("ranch_icon_check_badge_glossy.png"), "%s selection check should use the glossy check art" % panel_path)
			_expect((ranch.get_node("%s/PreviousButton" % panel_path) as Control).position == Vector2(106.0, 109.0), "%s previous button should align with the shared roster pagination" % panel_path)
			_expect((ranch.get_node("%s/NextButton" % panel_path) as Control).position == Vector2(214.0, 108.0), "%s next button should align with the shared roster pagination" % panel_path)
			_expect((ranch.get_node("%s/PreviousButton/Frame" % panel_path) as TextureRect).texture.resource_path.ends_with("ranch_ui_btn_previous_round.png"), "%s previous button should use the shared ranch round art" % panel_path)
			_expect((ranch.get_node("%s/NextButton/Frame" % panel_path) as TextureRect).texture.resource_path.ends_with("ranch_ui_btn_next_round.png"), "%s next button should use the shared ranch round art" % panel_path)
		_expect((ranch.get_node("Pages/SocialPage/PlacePanel/SlotA/Portrait") as TextureRect).flip_h, "left social monster should face the right monster")
		(ranch.get_node("Pages/RanchPage/BottomButtons/ClassroomButton") as TextureButton).pressed.emit()
		_expect((ranch.get_node("Pages/ClassroomPage") as Control).visible, "classroom button should reveal classroom GUI page")
		(ranch.get_node("Pages/ClassroomPage/BottomButtons/SocialButton") as TextureButton).pressed.emit()
		_expect((ranch.get_node("Pages/SocialPage") as Control).visible, "social button should reveal social GUI page")
		(ranch.get_node("Header/BackButton") as TextureButton).pressed.emit()
		_expect((ranch.get_node("Pages/RanchPage") as Control).visible, "back from subpage should reveal ranch GUI page")
		ranch.init({"page": "classroom"})
		_expect((ranch.get_node("Pages/ClassroomPage") as Control).visible, "ranch route should support opening the classroom directly")
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
		ranch.call("_switch_to_classroom")
		ranch.set("_class_selected_instance_id", "monster_001")
		ranch.call("_sync_gui")
		_expect((ranch.get_node("Pages/ClassroomPage/RosterPanel/Card1/Check") as TextureRect).visible, "classroom selection should use the shared check art")
		_expect(not (ranch.get_node("Pages/ClassroomPage/RosterPanel/Card1/SelectionMark") as Label).visible, "classroom selection should not use the old text mark")
		ranch.call("_switch_to_ranch")
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
		_expect(not ranch.has_node("Pages/RanchPage/CollectRow/CollectButton"), "GUI ranch page should not show the collect-all button")
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

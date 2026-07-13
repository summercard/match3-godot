extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	if storage != null:
		storage.clear_all_data()
		var player: Dictionary = storage.get_player()
		player["level"] = 25
		storage.save_player(player)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("ranch")
	await process_frame
	var ranch := main.get_current_scene() as Control
	_expect(ranch != null, "ranch route should create a scene")
	if ranch != null:
		_expect(ranch.scene_file_path == "res://src/ui/scenes/ranch_hub.tscn", "ranch should use its editable PackedScene")
		for path in [
			"Pages/RanchPage/Slots/Slot1",
			"Pages/RanchPage/RosterPanel/Card1",
			"Pages/ClassroomPage/DetailPanel/EvolveButton",
			"Pages/ClassroomPage/DetailPanel/UpgradeButton",
			"Pages/SocialPage/PlacePanel/SlotA",
			"Pages/SocialPage/BottomButtons/ActionButton",
			"PetFarmResourceBar",
			"PetFarmBottomNav",
			"SharedToast",
		]:
			_expect(ranch.has_node(path), "current ranch UI should own %s" % path)
		_expect(ranch.get_node("Pages/RanchPage/Slots/Slot1") is TextureButton, "farm slot should be interactive")
		_expect(ranch.get_node("Pages/ClassroomPage/DetailPanel/EvolveButton") is TextureButton, "classroom evolve action should be interactive")
		_expect((ranch.get_node("Pages/RanchPage") as Control).visible, "ranch page should be the default page")

		ranch.call("_switch_to_classroom")
		_expect(str(ranch.get("_active_page")) == "classroom", "classroom action should switch the active page")
		_expect((ranch.get_node("Pages/ClassroomPage") as Control).visible, "classroom page should become visible")
		_expect((ranch.get_node("Pages/ClassroomPage/DetailPanel/MonsterExpBar") as ProgressBar).visible, "classroom should expose growth progress")

		ranch.call("_switch_to_social")
		var before_place := str((ranch.get("_social_places") as Array)[0].get("place_id", ""))
		ranch.call("_on_place_switch_pressed")
		var after_place := str((ranch.get("_social_places") as Array)[0].get("place_id", ""))
		_expect(str(ranch.get("_active_page")) == "social", "social action should switch the active page")
		_expect((ranch.get_node("Pages/SocialPage") as Control).visible, "social page should become visible")
		_expect(not after_place.is_empty() and after_place != before_place, "social place switch should update the selected place")

		ranch.call("_switch_to_ranch")
		_expect(str(ranch.get("_active_page")) == "ranch", "ranch action should return to the farm page")

	root.remove_child(main)
	main.free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchGuiScene] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchGuiScene] " + failure)
	quit(1)

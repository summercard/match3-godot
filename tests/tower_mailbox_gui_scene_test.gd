extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist for tower/mailbox UI")
	if storage != null:
		storage.clear_all_data()
		var owned: Array = storage.get_owned_monsters()
		if owned.size() >= 3:
			storage.save_team({
				"leader": str((owned[0] as Dictionary).get("instanceId", "")),
				"member1": str((owned[1] as Dictionary).get("instanceId", "")),
				"member2": str((owned[2] as Dictionary).get("instanceId", "")),
			})
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("tower")
	await process_frame
	_expect(main.get_current_scene_name() == "tower", "tower scene should load from packed scene map")
	var tower: Control = main.get_current_scene()
	_expect(tower != null and tower.has_method("_start_or_continue"), "tower scene should expose expedition action")
	if storage != null:
		_expect(storage.save_stage_stars("stage_5_12", 1), "tower UI test should unlock tower")
	main.switch_scene("tower")
	await process_frame
	tower = main.get_current_scene()
	_expect(tower != null and not (tower.get_node("%StartButton") as BaseButton).disabled, "tower start should enable after stage 5-12")
	var controller = tower.get("_controller")
	var started: Dictionary = controller.start_new_run() if controller != null and controller.has_method("start_new_run") else {}
	_expect(bool(started.get("ok", false)), "tower UI route test should create an active expedition")
	if bool(started.get("ok", false)):
		(tower.get_node("%StartButton") as BaseButton).pressed.emit()
		for _frame in range(44):
			await process_frame
		_expect(main.get_current_scene_name() == "tower_battle", "tower expedition should route to its dedicated battle scene")
		var tower_battle: Control = main.get_current_scene()
		_expect(tower_battle != null and tower_battle.has_node("TowerHud"), "tower battle should expose its dedicated floor and wave HUD")
	main.switch_scene("mailbox")
	await process_frame
	_expect(main.get_current_scene_name() == "mailbox", "mailbox scene should load from packed scene map")
	var mailbox: Control = main.get_current_scene()
	_expect(mailbox != null and mailbox.has_method("_send_blessing"), "mailbox scene should expose blessing action")
	root.remove_child(main)
	main.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TowerMailboxGui] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TowerMailboxGui] " + failure)
	quit(1)

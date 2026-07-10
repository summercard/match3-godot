extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist for tower/mailbox UI")
	if storage != null:
		storage.clear_all_data()
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
		_expect(storage.save_stage_stars("stage_1_8", 1), "tower UI test should unlock tower")
	main.switch_scene("tower")
	await process_frame
	tower = main.get_current_scene()
	_expect(tower != null and not (tower.get_node("%StartButton") as Button).disabled, "tower start should enable after stage 1-8")
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

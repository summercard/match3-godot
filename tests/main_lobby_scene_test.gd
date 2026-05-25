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
	var loaded_lobby: Control = main.get_current_scene()
	_expect(loaded_lobby != null, "main scene should instantiate")
	if loaded_lobby != null:
		_expect(loaded_lobby.scene_file_path == "res://src/ui/scenes/main_lobby.tscn", "main should load editable lobby PackedScene")
		_expect(loaded_lobby.has_node("%PlayerName"), "editable player-name node should exist")
		_expect(loaded_lobby.has_node("%ExperienceFill"), "editable experience fill node should exist")

	var lobby: Control = load("res://src/ui/scenes/main_lobby.tscn").instantiate()
	root.add_child(lobby)
	await process_frame
	var emitted_ids: Array[String] = []
	lobby.button_pressed.connect(func(button_id: String): emitted_ids.append(button_id))
	var expected_buttons := {
		"StartButton": "start",
		"TeamButton": "team",
		"RanchButton": "ranch",
		"ShopButton": "shop",
		"AlbumButton": "album",
		"InventoryButton": "inventory",
		"AchievementButton": "achievement",
		"SettingsButton": "settings",
		"SigninButton": "signin"
	}
	for button_name in expected_buttons:
		var button := lobby.get_node("%" + button_name) as TextureButton
		_expect(button != null, "%s should be editable TextureButton" % button_name)
		if button_name == "StartButton":
			button.button_down.emit()
		else:
			button.pressed.emit()
	_expect(emitted_ids == expected_buttons.values(), "all lobby buttons should preserve their navigation ids")

	main.queue_free()
	lobby.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[MainLobbyScene] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[MainLobbyScene] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

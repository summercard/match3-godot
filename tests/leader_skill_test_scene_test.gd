extends SceneTree

const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	TestSceneCleanup.mute_audio_for_test(self)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_expect(main.switch_scene("leader_skill_test"), "main should switch to leader skill test scene")
	await process_frame
	var current: Control = main.get_current_scene()
	_expect(current != null, "leader skill test scene should instantiate")
	if current != null:
		_expect(current.scene_file_path == "res://src/ui/scenes/leader_skill_test.tscn", "leader skill test should load editable PackedScene")
		var profile: Dictionary = current.call("get_test_profile")
		_expect(int(profile.get("team_count", 0)) == 3, "leader skill test should mock three allies")
		_expect(int(profile.get("enemy_count", 0)) == 3, "leader skill test should mock three enemies")
		for tone in profile.get("tones", []):
			var button_path := "SkillButton_%s" % str(tone)
			_expect(current.has_node(button_path), "%s should expose a release button" % button_path)
			if current.has_node(button_path):
				(current.get_node(button_path) as Button).pressed.emit()
				await process_frame
				var after_profile: Dictionary = current.call("get_test_profile")
				_expect(int(after_profile.get("active_fx", 0)) > 0, "%s should schedule leader skill VFX" % tone)
				if str(tone) == "fire":
					_expect(str(after_profile.get("last_dispatch", "")) == "fire_burst", "fire should use the dedicated particle burst dispatch")
					var active_kinds: Array = after_profile.get("active_kinds", [])
					_expect(active_kinds.has("fire_beam"), "fire should schedule the disturbed flame beam renderer")
					_expect(active_kinds.has("fire_impact"), "fire should schedule the target burn impact renderer")
					_expect(float(after_profile.get("fire_trail_width", 99.0)) <= 8.5, "fire beam should read as a controlled trail, not a thick texture band")
					_expect(float(after_profile.get("fire_particle_min_size", 0.0)) >= 38.0 and float(after_profile.get("fire_particle_min_size", 99.0)) <= 44.0, "fire particles should use fewer larger sprites for mobile performance")
					_expect(float(after_profile.get("fire_impact_size", 0.0)) >= 54.0 and float(after_profile.get("fire_impact_size", 99.0)) <= 62.0, "fire impact particles should be larger while keeping the draw count low")

	var lobby: Control = load("res://src/ui/scenes/main_lobby.tscn").instantiate()
	root.add_child(lobby)
	await process_frame
	_expect(lobby.has_node("%TestToolButton"), "lobby should expose the test tool button")
	var emitted: Array[String] = []
	lobby.button_pressed.connect(func(button_id: String): emitted.append(button_id))
	var test_button := lobby.get_node("%TestToolButton") as TextureButton
	_expect(test_button != null, "test tool entry should be a TextureButton")
	if test_button != null:
		_expect(test_button.position.x >= 270.0 and test_button.position.y <= 180.0, "test tool entry should sit in the lobby upper-right")
		_expect(test_button.size.x <= 95.0 and test_button.size.y <= 34.0, "test tool entry should be compact")
		test_button.pressed.emit()
		await create_timer(0.17).timeout
		_expect(emitted.has("test_tool"), "test tool entry should emit the test_tool navigation id")

	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("[LeaderSkillTestScene] OK")
		quit(0)
	for failure in _failures:
		push_error("[LeaderSkillTestScene] " + failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

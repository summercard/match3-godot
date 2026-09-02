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
		_expect(int(profile.get("caster_count", 0)) == 1, "leader skill test should mock one bottom caster")
		_expect(int(profile.get("enemy_count", 0)) == 3, "leader skill test should mock three top targets")
		for target_index in range(3):
			_expect(current.has_node("TargetButton_%d" % target_index), "each top target should be selectable")
		(current.get_node("TargetButton_2") as Button).pressed.emit()
		await process_frame
		var selected_profile: Dictionary = current.call("get_test_profile")
		_expect(int(selected_profile.get("selected_target_index", -1)) == 2, "selecting a top character should update the skill target")
		for tone in profile.get("tones", []):
			var button_path := "SkillButton_%s" % str(tone)
			_expect(current.has_node(button_path), "%s should expose a release button" % button_path)
			if current.has_node(button_path):
				(current.get_node(button_path) as Button).pressed.emit()
				await process_frame
				var after_profile: Dictionary = current.call("get_test_profile")
				_expect(int(after_profile.get("active_fx", 0)) > 0, "%s should schedule leader skill VFX" % tone)
				if str(tone) == "fire":
					_expect(str(after_profile.get("last_dispatch", "")) == "sequence_table", "fire should use the data-driven VFX sequence")
					var active_kinds: Array = after_profile.get("active_kinds", [])
					_expect(active_kinds.has("block_fire_release"), "fire should schedule the configured release block")
					_expect(active_kinds.has("block_fireball_sprite"), "fire should schedule its Y-forward flight block")
					_expect(active_kinds.has("block_fireball_trail"), "fire should schedule its single-particle trail block")
					_expect(active_kinds.has("block_fire_impact"), "fire should schedule the configured impact spark block")
				if str(tone) == "balanced":
					var active_kinds: Array = after_profile.get("active_kinds", [])
					_expect(active_kinds.has("block_heal_release"), "balanced should schedule the green healing release")
					_expect(active_kinds.has("block_heal_rise"), "balanced should schedule rising heal bars on the target")
					_expect(not active_kinds.has("block_link") and not active_kinds.has("block_flight"), "balanced heal should not schedule a flight or link block")
				if str(tone) == "speed":
					var active_kinds: Array = after_profile.get("active_kinds", [])
					_expect(active_kinds.has("block_wind_lightning_link"), "wind should schedule the persistent lightning curve link")
					_expect(active_kinds.has("block_wind_lightning_hit"), "wind should schedule the one-second target hit effect")
				if str(tone) == "heal":
					var active_kinds: Array = after_profile.get("active_kinds", [])
					_expect(active_kinds.has("block_gold_heal_release"), "heal should schedule the gold group-release block")
					_expect(active_kinds.count("block_gold_heal_rise") == 3, "heal should schedule one gold rise effect for each top target")
					_expect(not active_kinds.has("block_link") and not active_kinds.has("block_flight"), "group heal should not schedule a flight or link block")
				if str(tone) == "guard":
					var active_kinds: Array = after_profile.get("active_kinds", [])
					_expect(active_kinds.has("block_tidal_big_ball") and active_kinds.has("block_tidal_splash"), "tide should schedule the large A-to-B waterball and B splash")
					_expect(active_kinds.has("block_tidal_small_ball") and active_kinds.has("block_tidal_chain_splash"), "tide should schedule the B-to-C small waterball and C splash")
				if str(tone) == "bulwark":
					var active_kinds: Array = after_profile.get("active_kinds", [])
					_expect(active_kinds.count("block_rock_release") == 3, "bulwark should schedule three caster-side rock releases")
					_expect(active_kinds.count("block_rock_flight") == 3, "bulwark should schedule three large rolling rocks")
					_expect(active_kinds.count("block_rock_impact") == 3, "bulwark should schedule three rock impacts on the selected target")

	var lobby: Control = load("res://src/ui/scenes/main_lobby.tscn").instantiate()
	root.add_child(lobby)
	await process_frame
	_expect(lobby.has_node("%TestToolButton"), "test tool node may remain for editor compatibility")
	var emitted: Array[String] = []
	lobby.button_pressed.connect(func(button_id: String): emitted.append(button_id))
	var test_button := lobby.get_node("%TestToolButton") as TextureButton
	_expect(test_button != null and test_button.visible, "test tool should be a visible lobby entry")
	if test_button != null:
		test_button.pressed.emit()
		await create_timer(0.17).timeout
		_expect(emitted.has("test_tool"), "visible test tool must retain a lobby navigation route")

	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("[LeaderSkillTestScene] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[LeaderSkillTestScene] " + failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

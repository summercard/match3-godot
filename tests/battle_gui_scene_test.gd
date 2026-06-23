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
	var stage_db = load("res://src/data/stage_db.gd").new()

	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	var battle: Control = main.get_current_scene()
	_expect(battle.scene_file_path == "res://src/ui/scenes/battle_screen.tscn", "battle should load editable PackedScene")
	_expect(bool(battle.call("_uses_editable_gui")), "battle should enable editable GUI mode")
	_expect((battle.get_node("Background") as TextureRect).texture.resource_path.ends_with("warbackgrouds/map1.png"), "chapter 1 battle should use map1 war background")
	var victory_halo := battle.get_node("BattleEndOverlay/Burst")
	_expect(victory_halo is Control and not (victory_halo is TextureRect), "battle victory halo should be drawn by a Control, not a texture node")
	var victory_halo_script = (victory_halo as Control).get_script()
	_expect(victory_halo_script != null and str(victory_halo_script.resource_path).ends_with("battle_victory_halo.gd"), "battle victory halo should use the programmatic halo script")
	for path in [
		"Background",
		"TopHud/TurnBadge/Value",
		"TopHud/PauseButton",
		"PauseDialog/Panel/ResumeButton",
		"PauseDialog/Panel/QuitButton",
		"Combatants/SingleEnemy/Portrait",
		"Combatants/SingleEnemy/HpFrameBase",
		"Combatants/Players/Player1/HpBar",
		"Combatants/Players/Player1/HpFrameBase",
		"BottomControls/CaptureToggle/Image",
		"BottomControls/Item1/Base",
		"BottomControls/Item1/Icon",
		"BottomControls/Item2/Base",
		"BottomControls/Item2/Icon",
		"BottomControls/Item3/Base",
		"BottomControls/Item3/Icon",
		"BottomControls/Item4/Base",
		"BottomControls/Item4/Icon",
		"BottomControls/Item5/Base",
		"BottomControls/Item5/Icon",
		"ItemConfirmLayer/Panel/CancelButton",
		"ItemConfirmLayer/Panel/UseButton",
	]:
		_expect(battle.has_node(path), "battle GUI node should exist: %s" % path)
	_expect((battle.get_node("BottomControls/Item1") as Control).visible, "first capture ball slot should remain visible")
	_expect((battle.get_node("BottomControls/Item2") as Control).visible, "second capture ball slot should remain visible")
	_expect((battle.get_node("BottomControls/Item5") as Control).visible, "third active item slot should remain visible")
	var idle_sync_count := int(battle.get("_sync_gui_call_count"))
	for _i in range(6):
		await process_frame
	_expect(int(battle.get("_sync_gui_call_count")) == idle_sync_count, "battle GUI should not run full sync every idle frame")
	var manager = battle.get("_battle")
	manager.turn_count += 1
	await process_frame
	_expect(int(battle.get("_sync_gui_call_count")) > idle_sync_count, "battle GUI should sync when battle state changes")
	for button in _collect_base_buttons(battle):
		_expect(button.has_node("CartoonFeedback"), "%s should expose cartoon feedback" % button.get_path())
		if button.has_node("CartoonFeedback"):
			var profile: Dictionary = button.get_node("CartoonFeedback").call("get_feedback_profile")
			_expect(float(profile.get("press_scale", 1.0)) < 1.0, "%s feedback should compress on press" % button.get_path())
	await _dispatch_battle_input_click(battle, battle.get_node("TopHud/PauseButton") as Control)
	_expect((battle.get_node("PauseDialog") as Control).visible, "pause button should open the pause dialog from real input")
	(battle.get_node("PauseDialog/Panel/ResumeButton") as BaseButton).pressed.emit()
	_expect(not (battle.get_node("PauseDialog") as Control).visible, "resume button should close the pause dialog while the tree is paused")
	var board = battle.get("_board")
	_expect(board != null and int(board.offset_y) == 300, "board should keep the lower-screen y position")
	_expect((battle.call("_get_player_card_rect", 0) as Rect2).has_point(Vector2(75.0, 216.0)), "editable player slot should preserve skill hit area")
	_expect(not (battle.get_node("Combatants/SingleEnemy") as Control).visible, "a lone ordinary enemy should not use the enlarged single-enemy slot")
	_expect((battle.get_node("Combatants/MultiEnemies") as Control).visible, "a lone ordinary enemy should use the regular enemy layer")
	_expect((battle.get_node("Combatants/MultiEnemies/Enemy2") as Control).visible, "a lone ordinary enemy should occupy the centered regular slot")
	_expect(not (battle.get_node("Combatants/MultiEnemies/Enemy1") as Control).visible and not (battle.get_node("Combatants/MultiEnemies/Enemy3") as Control).visible, "a lone ordinary enemy should not duplicate into side slots")
	var normal_enemy_portrait_size := (battle.get_node("Combatants/MultiEnemies/Enemy2/Portrait") as TextureRect).size
	var ordinary_enemy: Dictionary = battle.get("_battle").enemies[0]
	ordinary_enemy["isElite"] = true
	ordinary_enemy["_visualScale"] = 1.35
	battle.call("_sync_enemy_slots")
	_expect((battle.get_node("Combatants/SingleEnemy") as Control).visible, "a lone elite enemy should retain the featured enlarged slot")
	_expect((battle.get_node("Combatants/SingleEnemy/Portrait") as TextureRect).size.x > normal_enemy_portrait_size.x, "elite single enemy portrait should remain larger than an ordinary enemy")
	var featured_non_boss_hp_y := (battle.get_node("Combatants/SingleEnemy/HpFrameBase") as TextureRect).position.y
	ordinary_enemy.erase("isElite")
	ordinary_enemy.erase("_visualScale")
	battle.call("_sync_enemy_slots")
	var player_slot := battle.get_node("Combatants/Players/Player1") as Control
	var player_hp_y := (player_slot.get_node("HpFrameBase") as TextureRect).position.y
	battle.call("_set_combatant", player_slot, {
		"id": "monster_boss_001",
		"name": "抓获 Boss",
		"isBoss": true,
		"hp": 100,
		"maxHP": 100,
		"element": "grass",
	}, "green", false)
	_expect(is_equal_approx((player_slot.get_node("HpFrameBase") as TextureRect).position.y, player_hp_y), "captured boss player hp frame should stay at the same bottom position as ordinary player monsters")

	main.switch_scene("battle", {
		"stageId": "stage_2_12",
		"stageData": stage_db.get_stage("stage_2_12"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	battle = main.get_current_scene()
	_expect((battle.get_node("Background") as TextureRect).texture.resource_path.ends_with("warbackgrouds/map2.png"), "chapter 2 battle should use map2 war background")
	var boss_portrait_size := (battle.get_node("Combatants/SingleEnemy/Portrait") as TextureRect).size
	var boss_hp_y := (battle.get_node("Combatants/SingleEnemy/HpFrameBase") as TextureRect).position.y
	_expect(boss_portrait_size.x > normal_enemy_portrait_size.x and boss_portrait_size.x <= 192.0, "boss portrait should stay emphasized without using the oversized 2x scale")
	_expect(boss_hp_y <= featured_non_boss_hp_y - 40.0, "boss battle hp frame should keep its special upward offset")

	main.switch_scene("battle", {
		"stageId": "stage_3_6",
		"stageData": stage_db.get_stage("stage_3_6"),
		"inputTestOnly": true,
	})
	await process_frame
	battle = main.get_current_scene()
	_expect((battle.get_node("Background") as TextureRect).texture.resource_path.ends_with("warbackgrouds/map3.png"), "chapter 3 battle should use map3 war background")
	_expect((battle.get_node("Combatants/MultiEnemies") as Control).visible, "multi-enemy layer should show for three enemies")
	_expect((battle.get_node("Combatants/MultiEnemies/Enemy3") as Control).visible, "third enemy slot should remain editable and visible")
	_expect(battle.has_node("Combatants/MultiEnemies/Enemy3/HpFrameBase"), "multi-enemy hp bars should keep the base frame layer")

	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _collect_base_buttons(node: Node) -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	if node is BaseButton:
		buttons.append(node as BaseButton)
	for child in node.get_children():
		buttons.append_array(_collect_base_buttons(child))
	return buttons

func _dispatch_battle_input_click(battle: Control, control: Control) -> void:
	var center := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.position = center
	press.global_position = center
	battle.call("_input", press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.button_mask = 0
	release.position = center
	release.global_position = center
	battle.call("_input", release)
	await process_frame

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleGuiScene] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleGuiScene] " + failure)
	quit(1)

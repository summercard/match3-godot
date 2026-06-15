extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
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
	await _dispatch_battle_input_click(battle, battle.get_node("TopHud/PauseButton") as Control)
	_expect((battle.get_node("PauseDialog") as Control).visible, "pause button should open the pause dialog from real input")
	(battle.get_node("PauseDialog/Panel/ResumeButton") as BaseButton).pressed.emit()
	_expect(not (battle.get_node("PauseDialog") as Control).visible, "resume button should close the pause dialog while the tree is paused")
	var board = battle.get("_board")
	_expect(board != null and int(board.offset_y) == 300, "board should keep the lower-screen y position")
	_expect((battle.call("_get_player_card_rect", 0) as Rect2).has_point(Vector2(75.0, 216.0)), "editable player slot should preserve skill hit area")
	var normal_enemy_portrait_size := (battle.get_node("Combatants/SingleEnemy/Portrait") as TextureRect).size
	var normal_enemy_hp_y := (battle.get_node("Combatants/SingleEnemy/HpFrameBase") as TextureRect).position.y

	main.switch_scene("battle", {
		"stageId": "stage_2_12",
		"stageData": stage_db.get_stage("stage_2_12"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	battle = main.get_current_scene()
	var boss_portrait_size := (battle.get_node("Combatants/SingleEnemy/Portrait") as TextureRect).size
	var boss_hp_y := (battle.get_node("Combatants/SingleEnemy/HpFrameBase") as TextureRect).position.y
	_expect(boss_portrait_size.x >= normal_enemy_portrait_size.x * 2.0 and boss_portrait_size.y >= normal_enemy_portrait_size.y * 2.0, "boss battle portrait should be at least twice the normal single enemy size")
	_expect(boss_hp_y <= normal_enemy_hp_y - 40.0, "boss battle hp frame should move upward without affecting normal enemies")

	main.switch_scene("battle", {
		"stageId": "stage_3_6",
		"stageData": stage_db.get_stage("stage_3_6"),
		"inputTestOnly": true,
	})
	await process_frame
	battle = main.get_current_scene()
	_expect((battle.get_node("Combatants/MultiEnemies") as Control).visible, "multi-enemy layer should show for three enemies")
	_expect((battle.get_node("Combatants/MultiEnemies/Enemy3") as Control).visible, "third enemy slot should remain editable and visible")
	_expect(battle.has_node("Combatants/MultiEnemies/Enemy3/HpFrameBase"), "multi-enemy hp bars should keep the base frame layer")

	main.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

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

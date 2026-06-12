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
		"TopHud/SpeedButton",
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
	var board = battle.get("_board")
	_expect(board != null and int(board.offset_y) == 300, "board should keep the lower-screen y position")
	_expect((battle.call("_get_player_card_rect", 0) as Rect2).has_point(Vector2(75.0, 216.0)), "editable player slot should preserve skill hit area")

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

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleGuiScene] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleGuiScene] " + failure)
	quit(1)

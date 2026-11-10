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
		"TopHud/SettingsButton",
		"Combatants/SingleEnemy/Portrait",
		"Combatants/Players/Player1/HpBar",
		"BottomControls/CaptureToggle/Image",
		"BottomControls/Item1/Icon",
	]:
		_expect(battle.has_node(path), "battle GUI node should exist: %s" % path)
	# 单体怪血条：控件组水平居中，尺寸/字号保持既有的 T1 数值。
	var enemy_slot := battle.get_node("Combatants/SingleEnemy") as Control
	var hp_bar := enemy_slot.get_node("HpBar") as Control
	var hp_frame := enemy_slot.get_node("HpFrame") as Control
	var hp_text := enemy_slot.get_node("HpText") as Label
	var hp_left: float = INF
	var hp_right: float = -INF
	for rect: Rect2 in [hp_bar.get_rect(), hp_frame.get_rect(), hp_text.get_rect(), (enemy_slot.get_node("Orb") as Control).get_rect()]:
		hp_left = minf(hp_left, rect.position.x)
		hp_right = maxf(hp_right, rect.end.x)
	_expect(is_equal_approx((hp_left + hp_right) / 2.0, 187.5), "single enemy HP widget should be horizontally centred")
	_expect(is_equal_approx(hp_bar.size.x, 144.0) and is_equal_approx(hp_bar.size.y, 14.0), "single enemy HP bar size should stay 144x14")
	_expect(is_equal_approx(hp_frame.size.x, 156.0), "single enemy HP frame width should stay 156")
	_expect(hp_text.get_theme_font_size("font_size") == 10, "single enemy HP text font size should stay 10")

	var board = battle.get("_board")
	_expect(board != null and int(board.offset_y) == 300, "board should keep the lower-screen y position")
	_expect((battle.call("_get_player_card_rect", 0) as Rect2).has_point(Vector2(75.0, 216.0)), "editable player slot should preserve skill hit area")

	main.switch_scene("battle", {
		"stageId": "stage_3_3",
		"stageData": stage_db.get_stage("stage_3_3"),
		"inputTestOnly": true,
	})
	await process_frame
	battle = main.get_current_scene()
	var battle_manager = battle.get("_battle")
	_expect(battle_manager.enemies.size() == 1, "first wave should only spawn one enemy")
	_expect((battle.get_node("Combatants/SingleEnemy") as Control).visible, "single enemy layer should show during the first wave")
	_expect(not (battle.get_node("Combatants/MultiEnemies") as Control).visible, "multi-enemy layer should stay hidden during the first wave")
	_expect((battle.get_node("TopHud/WaveLabel") as Label).visible, "wave label should show for multi-wave battles")
	_expect((battle.get_node("TopHud/WaveLabel") as Label).text == "波次 1/2", "wave label should show the current wave")
	battle_manager.enemies[0]["hp"] = 0
	battle.call("_check_battle_end")
	_expect(int(battle.get("_state")) == SceneBattle.BattleState.WAVE_TRANSITION, "clearing a non-final wave should enter the wave transition state")
	await create_timer(1.25).timeout
	await process_frame
	_expect(battle_manager.wave_index == 2, "wave transition should start the next wave after the gap")
	_expect((battle.get_node("Combatants/MultiEnemies") as Control).visible, "multi-enemy layer should show when the next wave arrives")
	_expect(not (battle.get_node("Combatants/SingleEnemy") as Control).visible, "single enemy layer should hide when the next wave has multiple enemies")
	_expect((battle.get_node("Combatants/MultiEnemies/Enemy2") as Control).visible, "second enemy slot should be visible in the second wave")
	_expect((battle.get_node("TopHud/WaveLabel") as Label).text == "波次 2/2", "wave label should advance with the wave")

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

extends SceneTree

var _failures: Array[String] = []
var _started_stage_id := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager != null:
		save_manager.clear_all_data()

	var prepare: Control = load("res://src/ui/scenes/battle_prepare.tscn").instantiate()
	root.add_child(prepare)
	prepare.battle_started.connect(func(stage_id: String, _stage_data: Dictionary): _started_stage_id = stage_id)
	prepare.init({"stageId": "stage_1_1"})
	_expect(prepare.scene_file_path == "res://src/ui/scenes/battle_prepare.tscn", "battle prepare should be an editable PackedScene")
	for path in [
		"Header/BackButton",
		"EnemyPanel/Cards/EnemyCard1/Portrait",
		"TeamPanel/Cards/TeamCard1/Portrait",
		"PowerPanel/PlayerPower",
		"MechanicPanel/Line1",
		"RewardPreview/Slots/RewardSlot3/Icon",
		"StartButton/Frame",
		"AlertPopup",
	]:
		_expect(prepare.has_node(path), "battle prepare GUI node should exist: %s" % path)
	(prepare.get_node("StartButton") as TextureButton).pressed.emit()
	_expect(_started_stage_id == "stage_1_1", "editable start button should preserve battle start behavior")
	prepare.queue_free()
	await process_frame

	var result: Control = load("res://src/ui/scenes/battle_result.tscn").instantiate()
	root.add_child(result)
	result.init({
		"result": "win",
		"stageId": "stage_1_1",
		"turnCount": 5,
		"maxTurns": 20,
		"playerLevel": 5,
		"enemyLevel": 3,
		"stageRewards": {"gold": 80, "exp": 30, "guaranteedItems": [{"id": "capture_ball", "count": 1}]},
		"playerTeam": [
			{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "hp": 20, "maxHP": 20},
			{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 3, "hp": 18, "maxHP": 18},
		],
		"enemies": [
			{"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "hp": 0, "maxHP": 16},
		],
		"capture_played_inline": true,
		"captured": true,
		"capture_target": {"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "rarity": 1},
		"capture_result_text": {"title": "收服成功", "reason": "窗口稳定"},
		"capture_item_used": {"name": "捕捉球"},
		"capture_window": {"label": "稳定", "stability": 0.82},
	})
	_expect(result.scene_file_path == "res://src/ui/scenes/battle_result.tscn", "battle result should be an editable PackedScene")
	_expect((result.get_node("CaptureResultPanel") as Control).scene_file_path == "res://src/ui/scenes/capture_result_panel.tscn", "capture pet result should be an independent editable GUI panel")
	for path in [
		"Banner/Frame",
		"StarRow/Star1",
		"BattleInfo/TurnLabel",
		"CaptureResultPanel/MonsterPortrait",
		"CaptureResultPanel/Title",
		"RewardPanel/Slots/RewardSlot1/Icon",
		"ExpPanel/Cards/ExpCard1/Portrait",
		"Buttons/BackButton",
		"Buttons/NextButton",
		"Buttons/RetryButton",
	]:
		_expect(result.has_node(path), "battle result GUI node should exist: %s" % path)
	_expect((result.get_node("CaptureResultPanel") as Control).visible, "capture pet panel should show captured result")
	_expect((result.get_node("CaptureResultPanel/Title") as Label).text == "收服成功", "capture pet panel should bind result text")
	result.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattlePrepareResultGuiScene] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattlePrepareResultGuiScene] " + failure)
	quit(1)

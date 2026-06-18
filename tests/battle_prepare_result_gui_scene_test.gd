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
	_expect((prepare.get_node("Background") as TextureRect).texture.resource_path.ends_with("warbackgrouds/map1.png"), "chapter 1 battle prepare should use map1 war background")
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
	var normal_enemy_card := prepare.get_node("EnemyPanel/Cards/EnemyCard1") as Control
	var normal_enemy_portrait := normal_enemy_card.get_node("Portrait") as Control
	var normal_enemy_portrait_size := normal_enemy_portrait.size
	_expect((prepare.get_node("EnemyPanel/ElementPill") as Control).visible, "normal enemy panel should show element info")
	_expect((normal_enemy_card.get_node("Level") as Control).visible, "normal enemy card should show level")
	_expect((normal_enemy_card.get_node("Power") as Control).visible, "normal enemy card should show power")
	_expect((prepare.get_node("EnemyPanel/PowerIcon") as TextureRect).texture.resource_path.ends_with("battle_prepare_new_icon_power_swords.png"), "enemy power icon should use the cleaned crossed swords art")
	for reward_slot_path in ["RewardPreview/Slots/RewardSlot1", "RewardPreview/Slots/RewardSlot2", "RewardPreview/Slots/RewardSlot3"]:
		var reward_label := prepare.get_node(reward_slot_path + "/Label") as Label
		var reward_icon := prepare.get_node(reward_slot_path + "/Icon") as TextureRect
		_expect(not reward_label.visible and reward_label.text.is_empty(), "%s should hide reward text and quantity" % reward_slot_path)
		_expect(reward_icon.position.x >= 8.0 and reward_icon.size.x >= 38.0, "%s icon should stay centered after label removal" % reward_slot_path)
	(prepare.get_node("StartButton") as TextureButton).pressed.emit()
	_expect(_started_stage_id == "stage_1_1", "editable start button should preserve battle start behavior")
	prepare.init({"stageId": "stage_2_12"})
	_expect((prepare.get_node("Background") as TextureRect).texture.resource_path.ends_with("warbackgrouds/map2.png"), "chapter 2 battle prepare should use map2 war background")
	var enemy_card := prepare.get_node("EnemyPanel/Cards/EnemyCard1") as Control
	var enemy_name := enemy_card.get_node("Name") as Control
	var enemy_level := enemy_card.get_node("Level") as Control
	var enemy_power := enemy_card.get_node("Power") as Control
	var enemy_portrait := enemy_card.get_node("Portrait") as Control
	var enemy_stars := enemy_card.get_node("Stars") as Control
	_expect(not (prepare.get_node("EnemyPanel/Title") as Control).visible, "boss enemy panel should hide the ordinary title")
	_expect(not (prepare.get_node("EnemyPanel/ElementPill") as Control).visible, "boss enemy panel should hide element info")
	_expect(not enemy_level.visible and not enemy_power.visible and not enemy_stars.visible, "boss enemy card should hide ordinary enemy details")
	_expect((enemy_name as Label).text == "烈焰龙", "boss enemy card should show boss name")
	_expect(enemy_name.size.x >= 280.0, "boss enemy name should be centered across the panel")
	_expect(enemy_name.position.y >= 120.0, "boss enemy name should sit below the portrait")
	_expect(enemy_portrait.size.x >= normal_enemy_portrait_size.x * 2.0 and enemy_portrait.size.y >= normal_enemy_portrait_size.y * 2.0, "boss enemy portrait should be at least twice the normal enemy portrait size")
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
		"stageRewards": {"gold": 80, "exp": 30, "guaranteedItems": [{"id": "capture_ball_plus", "count": 2}]},
		"playerTeam": [
			{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "hp": 20, "maxHP": 20},
			{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 3, "hp": 18, "maxHP": 18},
		],
		"enemies": [
			{"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "hp": 0, "maxHP": 16},
		],
		"capture_played_inline": true,
		"captured": true,
		"capture_target": {"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "rarity": 1, "isElite": true},
		"capture_result_text": {"title": "收服成功", "reason": "窗口稳定"},
		"capture_item_used": {"name": "捕捉球"},
		"capture_window": {"label": "稳定", "stability": 0.82},
	})
	_expect(result.scene_file_path == "res://src/ui/scenes/battle_result.tscn", "battle result should be an editable PackedScene")
	_expect((result.get_node("Background") as TextureRect).texture.resource_path.ends_with("warbackgrouds/map1.png"), "chapter 1 battle result should use map1 war background")
	_expect((result.get_node("CaptureResultPanel") as Control).scene_file_path == "res://src/ui/scenes/capture_result_panel.tscn", "capture pet result should be an independent editable GUI panel")
	for path in [
		"Banner/Frame",
		"StarRow/Star1",
		"BattleInfo/TurnLabel",
		"CaptureResultPanel/MonsterPortrait",
		"CaptureResultPanel/Title",
		"CaptureSuccessLayer/Stage/MonsterPortrait",
		"CaptureSuccessLayer/InfoPlaque/PetName",
		"CaptureSuccessLayer/Buttons/ConfirmButton",
		"CaptureSuccessLayer/Buttons/ViewDexButton",
		"RewardPanel/Slots/RewardSlot1/Icon",
		"ExpPanel/Cards/ExpCard1/Portrait",
		"Buttons/BackButton",
		"Buttons/NextButton",
		"Buttons/RetryButton",
	]:
		_expect(result.has_node(path), "battle result GUI node should exist: %s" % path)
	_expect((result.get_node("CaptureSuccessLayer") as Control).visible, "capture success layer should show captured result")
	_expect(not (result.get_node("CaptureResultPanel") as Control).visible, "old capture pet panel should be hidden behind success layer")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot3/Amount") as Label).text == "超级捕获球 x2", "result reward slot should name the same item it grants")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot1/Icon") as TextureRect).texture.resource_path.ends_with("main_icon_gold_coin_v3.png"), "result gold reward should use the formal art icon")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot2/Icon") as TextureRect).texture.resource_path.ends_with("ranch_icon_exp_badge.png"), "result exp reward should use the formal art icon")
	var exp_card := result.get_node("ExpPanel/Cards/ExpCard1") as Control
	var exp_label := exp_card.get_node("Exp") as Label
	_expect(exp_label.get_theme_font_size("font_size") <= 8 and exp_label.clip_text, "result monster exp text should stay compact and clipped inside the card")
	_expect(exp_label.position.x >= 0.0 and exp_label.position.x + exp_label.size.x <= exp_card.size.x + 0.5, "result monster exp text box should stay inside the card width")
	var inventory_after_result: Dictionary = save_manager.load_inventory() if save_manager != null else {}
	_expect(int(inventory_after_result.get("capture_ball_plus", 0)) == 2, "result should grant the same guaranteed item count shown in the reward slot")
	var captured_instances: Array = save_manager.get_instances_by_monster_id("enemy_001") if save_manager != null and save_manager.has_method("get_instances_by_monster_id") else []
	_expect(not captured_instances.is_empty() and bool((captured_instances[0] as Dictionary).get("isElite", false)), "captured random elite target should keep isElite on the owned instance")
	result.queue_free()
	await process_frame

	var missed_result: Control = load("res://src/ui/scenes/battle_result.tscn").instantiate()
	root.add_child(missed_result)
	missed_result.init({
		"result": "win",
		"stageId": "stage_1_1",
		"turnCount": 5,
		"maxTurns": 20,
		"stageRewards": {"gold": 80, "exp": 30},
		"playerTeam": [
			{"id": "monster_001", "monsterId": "monster_001", "level": 5, "hp": 20, "maxHP": 20},
			{"id": "monster_002", "monsterId": "monster_002", "level": 3, "hp": 18, "maxHP": 18},
		],
		"enemies": [
			{"id": "enemy_001", "monsterId": "enemy_001", "name": "wild", "hp": 0, "maxHP": 16},
		],
		"capture_played_inline": true,
		"captured": false,
		"capture_target": {"id": "enemy_001", "monsterId": "enemy_001", "name": "wild", "rarity": 1},
		"capture_result_text": {"title": "auto off", "reason": "long text should not render"},
	})
	var missed_panel := missed_result.get_node("CaptureResultPanel") as Control
	_expect(missed_panel.visible, "missed capture should keep a compact status plaque")
	_expect((missed_panel.get_node("Title") as Label).text == "未捕捉", "missed capture should only show the uncaptured status")
	for line_path in ["Line1", "Line2", "Line3"]:
		var line := missed_panel.get_node(line_path) as Label
		_expect(not line.visible and line.text.is_empty(), "missed capture should hide extra explanation line %s" % line_path)
	for button_path in ["Buttons/BackButton", "Buttons/NextButton", "Buttons/RetryButton"]:
		var button := missed_result.get_node(button_path) as TextureButton
		var frame := button.get_node("Frame") as TextureRect
		_expect(button.size.y >= 50.0 and frame.size == button.size, "%s frame should fit its button without cropping" % button_path)
	_expect((missed_result.get_node("Buttons/NextButton/Frame") as TextureRect).texture.resource_path == "res://assets/images/ui/buttons/result_refresh_ui_btn_gold_full.png", "next button should use the completed original-style next texture")
	_expect((missed_result.get_node("Buttons/RetryButton/Frame") as TextureRect).texture.resource_path == "res://assets/images/ui/buttons/result_refresh_ui_btn_blue_full.png", "retry button should use the completed original-style retry texture")
	for star_path in ["StarRow/Star1", "StarRow/Star2", "StarRow/Star3"]:
		var star := missed_result.get_node(star_path) as TextureRect
		_expect(star.size.x >= 52.0 and star.size.y >= 56.0, "%s should have enough room for the large star art" % star_path)
	missed_result.queue_free()
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

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
	# Entry animation temporarily offsets panels; reset to the authored target layout
	# before checking spacing and alignment.
	prepare.call("_apply_concept_layout")
	for chip_path in ["TopResourceBar/GoldChip", "TopResourceBar/DiamondChip", "TopResourceBar/HeartChip"]:
		_expect(not (prepare.get_node(chip_path + "/Plus") as Control).visible, "%s currency add icon should be hidden" % chip_path)
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
	var enemy_power_caption := prepare.get_node("EnemyPanel/PowerCaption") as Label
	var enemy_power_value := normal_enemy_card.get_node("Power") as Label
	_expect((prepare.get_node("EnemyPanel/ElementPill") as Control).visible, "normal enemy panel should show element info")
	_expect((normal_enemy_card.get_node("Level") as Control).visible, "normal enemy card should show level")
	_expect((normal_enemy_card.get_node("Power") as Control).visible, "normal enemy card should show power")
	_expect((prepare.get_node("EnemyPanel/PowerIcon") as TextureRect).texture.resource_path.ends_with("battle_prepare_new_icon_power_swords.png"), "enemy power icon should use the cleaned crossed swords art")
	_expect(enemy_power_caption.position.x + enemy_power_caption.size.x <= enemy_power_value.position.x, "enemy power caption and value should form one clean row without overlap")
	for plain_label_path in [
		"TopResourceBar/GoldChip/Value",
		"TopResourceBar/DiamondChip/Value",
		"TopResourceBar/HeartChip/Value",
		"Header/StageName",
		"EnemyPanel/Title",
		"EnemyPanel/ElementText",
		"EnemyPanel/PowerCaption",
		"EnemyPanel/Cards/EnemyCard1/Name",
		"EnemyPanel/Cards/EnemyCard1/Level",
		"EnemyPanel/Cards/EnemyCard1/Power",
		"PowerPanel/PlayerPower",
		"PowerPanel/EnemyPower",
		"PowerPanel/Diff",
		"TeamPanel/Title",
		"TeamPanel/Cards/TeamCard1/Name",
		"TeamPanel/Cards/TeamCard1/Level",
		"TeamPanel/Cards/TeamCard1/Power",
		"RewardPreview/Title",
	]:
		_expect((prepare.get_node(plain_label_path) as Label).get_theme_constant("outline_size") == 0, "%s should not retain a white text edge" % plain_label_path)
	var enemy_panel := prepare.get_node("EnemyPanel") as Control
	var power_panel := prepare.get_node("PowerPanel") as Control
	var team_panel := prepare.get_node("TeamPanel") as Control
	var reward_panel := prepare.get_node("RewardPreview") as Control
	_expect(enemy_panel.position.y + enemy_panel.size.y < power_panel.position.y, "enemy and power sections should have a visible gap")
	_expect(power_panel.position.y + power_panel.size.y < team_panel.position.y, "power and team sections should have a visible gap")
	_expect(team_panel.position.y + team_panel.size.y < reward_panel.position.y, "team and reward sections should have a visible gap")
	for team_card_path in ["TeamPanel/Cards/TeamCard1", "TeamPanel/Cards/TeamCard2", "TeamPanel/Cards/TeamCard3"]:
		var team_card := prepare.get_node(team_card_path) as Control
		var element_badge := team_card.get_node("ElementBadge") as TextureRect
		var power_stars := team_card.get_node("Stars") as Label
		var card_panel := team_card.get_node("ui底图2/NinePatch") as NinePatchRect
		_expect(not power_stars.visible and power_stars.text.is_empty(), "%s should hide power stars" % team_card_path)
		_expect(is_equal_approx(element_badge.position.y, -2.0), "%s should align its element badge near the top edge" % team_card_path)
		_expect(card_panel.texture.resource_path.ends_with("panel_base2.png"), "%s should reuse the first team card panel" % team_card_path)
		_expect(not team_card.has_node("Frame"), "%s should not keep the old team card frame" % team_card_path)
	for reward_slot_path in ["RewardPreview/Slots/RewardSlot1", "RewardPreview/Slots/RewardSlot2", "RewardPreview/Slots/RewardSlot3"]:
		var reward_label := prepare.get_node(reward_slot_path + "/Label") as Label
		var reward_icon := prepare.get_node(reward_slot_path + "/Icon") as TextureRect
		_expect(not reward_label.visible and reward_label.text.is_empty(), "%s should hide reward text and quantity" % reward_slot_path)
		_expect(reward_icon.size == Vector2(26.0, 26.0), "%s icon should use the compact reward size" % reward_slot_path)
	var prepare_shade := prepare.get_node("Shade") as TextureRect
	_expect(prepare_shade.texture.resource_path.ends_with("ui/backgrounds/black.png"), "battle prepare should use black.png between the background and UI")
	_expect(is_equal_approx(prepare_shade.modulate.a, 0.5), "battle prepare black overlay should be 50 percent transparent")
	_expect((prepare.get_node("RewardPreview/Slots/RewardSlot3/Icon") as TextureRect).texture.resource_path.ends_with("main_icon_diamond_gem_v3.png"), "first-clear diamond preview should use the diamond icon")
	prepare.init({"stageId": "stage_1_2"})
	_expect(prepare.has_node("RewardPreview/Slots/RewardSlot4"), "battle prepare should support a fourth reward preview slot")
	var reward_slots := prepare.get_node("RewardPreview/Slots") as Control
	var first_reward_slot := prepare.get_node("RewardPreview/Slots/RewardSlot1") as Control
	var last_reward_slot := prepare.get_node("RewardPreview/Slots/RewardSlot4") as Control
	var reward_group_center := (first_reward_slot.position.x + last_reward_slot.position.x + last_reward_slot.size.x) * 0.5
	_expect(is_equal_approx(reward_slots.position.x, 0.0), "reward slot container should not retain the old left offset")
	_expect(is_equal_approx(reward_group_center, reward_slots.size.x * 0.5), "visible reward icons should be centered as one group")
	_expect((prepare.get_node("RewardPreview/Slots/RewardSlot3/Icon") as TextureRect).texture.resource_path.ends_with("main_icon_diamond_gem_v3.png"), "stage with guaranteed item should still preview first-clear diamonds by icon")
	_expect((prepare.get_node("RewardPreview/Slots/RewardSlot4/Icon") as TextureRect).texture.resource_path.ends_with("items_new_icon_capture_ball.png"), "stage guaranteed item should show its real item icon")
	_expect(not (prepare.get_node("RewardPreview/Slots/RewardSlot4/Label") as Label).visible and (prepare.get_node("RewardPreview/Slots/RewardSlot4/Label") as Label).text.is_empty(), "stage guaranteed item should not show reward text")
	save_manager.save_stage_stars("stage_1_2", 3)
	prepare.init({"stageId": "stage_1_2"})
	_expect((prepare.get_node("RewardPreview/Slots/RewardSlot3/Icon") as TextureRect).texture.resource_path.ends_with("items_new_icon_capture_ball.png"), "cleared stage should replace first-clear diamonds with the guaranteed item icon")
	_expect(not (prepare.get_node("RewardPreview/Slots/RewardSlot4") as Control).visible, "cleared stage with three reward types should hide unused fourth preview slot")
	(prepare.get_node("StartButton") as TextureButton).pressed.emit()
	_expect(_started_stage_id == "stage_1_2", "editable start button should preserve battle start behavior")
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
		"capture_target": {"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "rarity": 1, "level": 9, "isElite": true},
		"capture_result_text": {"title": "收服成功", "reason": "窗口稳定"},
		"capture_item_used": {"name": "捕捉球"},
		"capture_window": {"label": "稳定", "stability": 0.82},
	})
	_expect((result.get_node("RewardPanel/Slots/RewardSlot1/Amount") as Label).text == "+0", "gold reward should begin its count-up at zero")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot2/Amount") as Label).text.contains("获得 +0"), "shared experience gain should begin its count-up at zero")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot3/Amount") as Label).text == "+0", "diamond reward should begin its count-up at zero")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot4/Amount") as Label).text.ends_with("x0"), "item count should begin its count-up at zero")
	result.set("_reward_anim_progress", 1.0)
	result.call("_sync_gui")
	_expect(result.scene_file_path == "res://src/ui/scenes/battle_result.tscn", "battle result should be an editable PackedScene")
	_expect((result.get_node("Background") as TextureRect).texture.resource_path.ends_with("warbackgrouds/map1.png"), "chapter 1 battle result should use map1 war background")
	var result_shade := result.get_node("Shade") as TextureRect
	_expect(result_shade.texture.resource_path.ends_with("ui/backgrounds/black.png"), "battle victory should use black.png between the background and UI")
	_expect(is_equal_approx(result_shade.modulate.a, 0.5), "battle victory black overlay should be 50 percent transparent")
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
	_expect((result.get_node("RewardPanel/Slots/RewardSlot3/Amount") as Label).text == "+3", "first clear should show the normal-stage diamond reward")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot3/Icon") as TextureRect).texture.resource_path.ends_with("main_icon_diamond_gem_v3.png"), "first-clear diamonds should use the formal diamond icon")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot4/Amount") as Label).text == "超级捕获球 x2", "result reward slot should name the same item it grants")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot1/Icon") as TextureRect).texture.resource_path.ends_with("main_icon_gold_coin_v3.png"), "result gold reward should use the formal art icon")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot2/Icon") as TextureRect).texture.resource_path.ends_with("ranch_icon_exp_badge.png"), "result exp reward should use the formal art icon")
	var exp_card := result.get_node("ExpPanel/Cards/ExpCard1") as Control
	var exp_label := exp_card.get_node("Exp") as Label
	_expect(not (exp_card.get_node("Level") as Label).visible and not exp_label.visible, "result monster cards should hide level and allocation text")
	_expect((result.get_node("RewardPanel/Slots/RewardSlot2/Amount") as Label).text.contains("总槽") and (result.get_node("RewardPanel/Slots/RewardSlot2/Amount") as Label).text.contains("获得 +"), "experience reward should show total pool and gained experience")
	_expect((result.get_node("Buttons/RetryButton/Text") as Label).text == "课堂升级精灵", "victory result should offer classroom upgrading")
	var inventory_after_result: Dictionary = save_manager.load_inventory() if save_manager != null else {}
	_expect(int(inventory_after_result.get("capture_ball_plus", 0)) == 2, "result should grant the same guaranteed item count shown in the reward slot")
	var captured_instances: Array = save_manager.get_instances_by_monster_id("enemy_001") if save_manager != null and save_manager.has_method("get_instances_by_monster_id") else []
	_expect(not captured_instances.is_empty() and bool((captured_instances[0] as Dictionary).get("isElite", false)), "captured random elite target should keep isElite on the owned instance")
	_expect(not captured_instances.is_empty() and int((captured_instances[0] as Dictionary).get("level", 0)) == 9, "captured target should keep its battle level instead of falling back to stage enemyLevel")
	if not captured_instances.is_empty():
		var captured_instance: Dictionary = captured_instances[0]
		var captured_view: Dictionary = MonsterService.build_instance_view(captured_instance)
		_expect(int(captured_view.get("stats", {}).get("level", 0)) == 9, "captured target stats should be recalculated from saved level and nature")
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

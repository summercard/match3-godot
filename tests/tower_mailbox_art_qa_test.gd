extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist")
	if storage == null:
		_finish()
		return
	var regular_battle := load("res://src/ui/scenes/battle_screen.tscn").instantiate() as Control
	var tower_battle := load("res://src/ui/scenes/tower_battle.tscn").instantiate() as Control
	for player_name in ["Player1", "Player2", "Player3"]:
		var regular_slot := regular_battle.get_node("Combatants/Players/%s" % player_name) as Control
		var tower_slot := tower_battle.get_node("Combatants/Players/%s" % player_name) as Control
		_expect(regular_slot.position == tower_slot.position, "tower %s should align with the main-battle player slot" % player_name)
	regular_battle.free()
	tower_battle.free()
	storage.clear_all_data()
	_expect(storage.save_stage_stars("stage_5_12", 3), "tower QA should unlock the 1.3.2 mainline gate")

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("tower")
	for _frame in range(45):
		await process_frame
	var tower := main.get_current_scene() as Control
	_expect(tower != null, "tower scene should load")
	if tower != null:
		_expect((tower.get_node("Background") as TextureRect).texture.resource_path == "res://assets/images/tower_new/tower_resonance_casual_bg_v2.png", "tower should use its bright casual resonance background art")
		_expect(tower.has_node("Shade"), "tower should place a readability shade over the background art")
		_expect(not (tower.get_node("StartButton") as BaseButton).disabled, "tower should be directly testable after its gate is unlocked")
		_expect(tower.get_node("StartButton").get_child_count() > 0, "tower start action should keep press feedback attached")
		_expect(not (tower.get_node("UnlockPill") as Control).visible, "tower should hide the unlock hint after its gate is met")
		_expect((tower.get_node("StartButton/ButtonVisual") as TextureRect).texture.resource_path.ends_with("button_butter_gold.png"), "tower start should use the Cocos gold expedition button")
		var tower_start := tower.get_node("StartButton") as Control
		_expect(tower_start.position.is_equal_approx(Vector2(208.0, 283.0)) and tower_start.size.is_equal_approx(Vector2(157.0, 63.0)), "tower start button should match the Cocos 1.3.2 bounds (position=%s size=%s)" % [tower_start.position, tower_start.size])
		_expect((tower.get_node("StatusPanel") as Control).position.is_equal_approx(Vector2(14.0, 193.0)), "tower status card should share the Cocos baseline with the expedition action")
		_expect((tower.get_node("BackButton") as TextureButton).texture_normal.resource_path.ends_with("ranch_ui_btn_previous_round.png"), "tower back action should use the shared map paging art")
		_expect((tower.get_node("RankPanel/ClimbTab") as TextureButton).texture_normal.resource_path.ends_with("battle_flow_new_ui_battle_continue_button.png"), "tower rank tabs should use the Cocos blue map-button art")
		var rank_scroll := tower.get_node("RankPanel/RankScroll") as ScrollContainer
		_expect(rank_scroll.size.y == 154.0, "tower rankings should preserve the exact seven-row Cocos viewport")
		_expect((tower.get_node("RankPanel/RankScroll/RankList/Rank0") as Control).custom_minimum_size.y == 22.0, "tower ranking rows should use the Cocos 22-pixel cadence")

	main.switch_scene("mailbox")
	for _frame in range(45):
		await process_frame
	var mailbox := main.get_current_scene() as Control
	_expect(mailbox != null, "mailbox scene should load")
	if mailbox != null:
		_expect((mailbox.get_node("Background") as TextureRect).texture.resource_path == "res://assets/images/mailbox_new/mailbox_travel_casual_bg_v2.png", "mailbox should use its bright casual travel background art")
		_expect(mailbox.has_node("TitleTrail"), "mailbox should present its travel-story header treatment")
		_expect((mailbox.get_node("BlessingPanel/FlyingStar") as TextureRect).texture != null, "mailbox should use a formal star asset for its blessing flight")
		_expect(not mailbox.has_node("ArrivalStar") and not mailbox.has_node("ArrivalTrail"), "new-mail arrival animation should no longer play in the mailbox")
		_expect(mailbox.has_node("BlessingPanel/BlessingStarTrail"), "sending a blessing should have a visible star trail")
		_expect((mailbox.get_node("BlessingPanel/Panel/ActionRail/RailTitle") as Label).text == "给远方的陌生人\n送出祝福", "blessing prompt should address distant strangers")
		_expect((mailbox.get_node("InboxTab") as Control).position.is_equal_approx(Vector2(18.0, 72.0)) and (mailbox.get_node("InboxTab") as Control).size.is_equal_approx(Vector2(164.0, 42.0)), "mailbox tabs should match the Cocos 1.3.2 bounds")
		_expect((mailbox.get_node("InboxTab") as TextureButton).texture_normal.resource_path.ends_with("battle_flow_new_ui_battle_continue_button.png"), "mailbox tabs should use the Cocos blue map-button art")
		_expect(mailbox.has_node("InboxPanel/ListPanel/PrevMailPage") and mailbox.has_node("InboxPanel/ListPanel/NextMailPage"), "mailbox should expose four-item page navigation")
		_expect((mailbox.get_node("InboxPanel/MailboxTotals") as Control).size.y == 79.0, "mailbox star totals should use the shortened Cocos card")
		_expect((mailbox.get_node("InboxPanel/DetailPanel") as Control).position.y == 240.0, "mailbox detail card should start at the Cocos vertical baseline")
		_expect((mailbox.get_node("BlessingPanel/Panel/TravelCard") as Control).size.is_equal_approx(Vector2(198.0, 478.0)), "mailbox travel card should match the Cocos blessing layout")
		_expect((mailbox.get_node("BlessingPanel/Panel/PrevAdventurer") as TextureButton).texture_normal.resource_path.ends_with("ranch_ui_btn_previous_round.png"), "mailbox previous-adventurer action should use shared paging art")
		_expect((mailbox.get_node("BlessingPanel/Panel/NextAdventurer") as TextureButton).texture_normal.resource_path.ends_with("ranch_ui_btn_next_round.png"), "mailbox next-adventurer action should use shared paging art")
		_expect(mailbox.has_node("BlessingPanel/Panel/DailyRemaining") and (mailbox.get_node("BlessingPanel/Panel/ActionRail/RailStep") as Control).visible, "mailbox blessing rail should show Cocos steps and daily remaining count")
		var action_rail := mailbox.get_node("BlessingPanel/Panel/ActionRail") as Control
		_expect(action_rail.position.x > 200.0 and action_rail.position.y > 200.0, "mailbox action rail should sit in the lower-right thumb zone")
		mailbox.call("_show_blessing")
		var portrait := mailbox.get_node("BlessingPanel/Panel/AdventurerFrame/AdventurerPortrait") as TextureRect
		_expect(portrait.visible and portrait.texture != null, "blessing page should visibly show the selected adventurer")
		var before_send: Dictionary = storage.get_mailbox_state()
		var pending_before := (before_send.get("pending_blessings", []) as Array).size()
		var unread_before := int(before_send.get("unread_count", 0))
		mailbox.call("_send_blessing")
		for _frame in range(60):
			await process_frame
		var state: Dictionary = storage.get_mailbox_state()
		_expect(int(state.get("daily_send_count", 0)) == 1, "sending a blessing should persist the daily send count")
		_expect(int(state.get("unread_count", 0)) == unread_before, "sending a blessing should not create a new unread reply")
		_expect((state.get("pending_blessings", []) as Array).size() == pending_before, "sending a blessing should remain independent from daily inbound mail")
		_expect(int(state.get("collection_stars", 0)) == 3, "sending a blessing should not change the three starter collection stars")

	root.remove_child(main)
	main.free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[TowerMailboxArtQA] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TowerMailboxArtQA] " + failure)
	quit(1)

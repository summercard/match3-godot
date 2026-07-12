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
	storage.clear_all_data()
	_expect(storage.save_stage_stars("stage_1_8", 3), "tower QA should unlock the required mainline gate")

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("tower")
	await process_frame
	var tower := main.get_current_scene() as Control
	_expect(tower != null, "tower scene should load")
	if tower != null:
		_expect((tower.get_node("Background") as TextureRect).texture.resource_path == "res://assets/images/tower_new/tower_resonance_casual_bg_v2.png", "tower should use its bright casual resonance background art")
		_expect(tower.has_node("Shade"), "tower should place a readability shade over the background art")
		_expect(not (tower.get_node("StartButton") as BaseButton).disabled, "tower should be directly testable after its gate is unlocked")
		_expect(tower.get_node("StartButton").get_child_count() > 0, "tower start action should keep press feedback attached")
		_expect(not (tower.get_node("UnlockPill") as Control).visible, "tower should hide the unlock hint after its gate is met")
		_expect((tower.get_node("StartButton") as TextureButton).texture_normal.resource_path.ends_with("main_ui_entry_shop_v3.png"), "tower start should use the shared glossy entry-button style")
		var rank_scroll := tower.get_node("RankPanel/RankScroll") as ScrollContainer
		_expect(rank_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_SHOW_NEVER, "tower rankings should be vertically scrollable")
		_expect(rank_scroll.get_v_scroll_bar().max_value > 0.0, "tower rankings should overflow into the vertical scroll area")

	main.switch_scene("mailbox")
	await process_frame
	var mailbox := main.get_current_scene() as Control
	_expect(mailbox != null, "mailbox scene should load")
	if mailbox != null:
		_expect((mailbox.get_node("Background") as TextureRect).texture.resource_path == "res://assets/images/mailbox_new/mailbox_travel_casual_bg_v2.png", "mailbox should use its bright casual travel background art")
		_expect(mailbox.has_node("TitleTrail"), "mailbox should present its travel-story header treatment")
		_expect((mailbox.get_node("BlessingPanel/FlyingStar") as TextureRect).texture != null, "mailbox should use a formal star asset for its blessing flight")
		_expect(not mailbox.has_node("ArrivalStar") and not mailbox.has_node("ArrivalTrail"), "new-mail arrival animation should no longer play in the mailbox")
		_expect(mailbox.has_node("BlessingPanel/BlessingStarTrail"), "sending a blessing should have a visible star trail")
		var action_rail := mailbox.get_node("BlessingPanel/Panel/ActionRail") as Control
		_expect(action_rail.position.x > 200.0 and action_rail.position.y > 200.0, "mailbox action rail should sit in the lower-right thumb zone")
		mailbox.call("_show_blessing")
		var portrait := mailbox.get_node("BlessingPanel/Panel/AdventurerFrame/AdventurerPortrait") as TextureRect
		_expect(portrait.visible and portrait.texture != null, "blessing page should visibly show the selected adventurer")
		mailbox.call("_send_blessing")
		for _frame in range(60):
			await process_frame
		var state: Dictionary = storage.get_mailbox_state()
		_expect(int(state.get("daily_send_count", 0)) == 1, "sending a blessing should persist the daily send count")
		_expect(int(state.get("unread_count", 0)) > 0, "sending a blessing should create a readable reply mail")
		_expect(int(state.get("sent_blessing_stars", 0)) == 1 and int(state.get("received_blessing_stars", 0)) == 1, "mailbox should retain sent and received star totals")

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

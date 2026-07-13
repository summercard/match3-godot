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
	var owned: Array = storage.get_owned_monsters()
	_expect(not owned.is_empty(), "mailbox should have an owned adventurer to select")

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("mailbox")
	await process_frame
	var mailbox := main.get_current_scene() as Control
	_expect(mailbox != null, "mailbox scene should load")
	if mailbox != null:
		var inbox_tab := mailbox.get_node("InboxTab") as Button
		var blessing_tab := mailbox.get_node("BlessingTab") as Button
		var next_adventurer := mailbox.get_node("BlessingPanel/Panel/NextAdventurer") as Button
		var prev_adventurer := mailbox.get_node("BlessingPanel/Panel/PrevAdventurer") as Button
		var send_button := mailbox.get_node("BlessingPanel/Panel/SendButton") as Button
		var claim_button := mailbox.get_node("InboxPanel/DetailPanel/ClaimButton") as Button
		var delete_button := mailbox.get_node("InboxPanel/DetailPanel/DeleteButton") as Button
		var detail_scroll := mailbox.get_node("InboxPanel/DetailPanel/MailDetailScroll") as ScrollContainer
		var back_button := mailbox.get_node("BackButton") as Button
		for button in [inbox_tab, blessing_tab, prev_adventurer, next_adventurer, send_button, claim_button, delete_button, back_button]:
			_expect(button.has_node("CartoonFeedback"), "%s should retain press feedback" % button.name)
		_expect((mailbox.get_node("InboxPanel") as Control).visible, "inbox should be the default tab")
		blessing_tab.pressed.emit()
		_expect((mailbox.get_node("BlessingPanel") as Control).visible and not (mailbox.get_node("InboxPanel") as Control).visible, "blessing tab should switch the visible panel")
		var first_id := str(mailbox.get("_selected_instance_id"))
		if owned.size() > 1:
			next_adventurer.pressed.emit()
			_expect(str(mailbox.get("_selected_instance_id")) != first_id, "next adventurer button should change the selected adventurer")
			prev_adventurer.pressed.emit()
			_expect(str(mailbox.get("_selected_instance_id")) == first_id, "previous adventurer button should restore the prior adventurer")
		send_button.pressed.emit()
		for _frame in range(60):
			await process_frame
		var state: Dictionary = storage.get_mailbox_state()
		_expect(int(state.get("daily_send_count", 0)) == 1, "send button should consume one daily blessing")
		_expect(int(state.get("unread_count", 0)) == 1, "send button should create a reply mail")
		_expect((mailbox.get_node("InboxPanel/MailboxTotals/SentStarTotal") as Label).text == "3", "mailbox should show the three initially unlocked species")
		_expect((mailbox.get_node("InboxPanel/MailboxTotals/ReceivedStarTotal") as Label).text == "3", "sending a blessing should not change collection-star rewards")
		_expect((mailbox.get_node("BlessingPanel/Panel/ActionRail/RailTitle") as Label).text == "给远方的陌生人\n送出祝福", "blessing page should use the stranger-blessing prompt")
		_expect((mailbox.get_node("BlessingPanel/Panel/BlessingStatus") as Label).text == "图鉴星星：3", "blessing page should show the collection-star total")
		inbox_tab.pressed.emit()
		_expect((mailbox.get_node("InboxPanel") as Control).visible, "inbox tab should return to the mail list")
		var mail_row := mailbox.get_node("InboxPanel/ListPanel/Mail0") as Button
		var read_status := mailbox.get_node("InboxPanel/ListPanel/Mail0/Mail0ReadStatus") as Label
		_expect(mail_row.visible, "new reply should appear in the first mail row")
		_expect(read_status.text == "未读", "an unread mail row should show its unread marker")
		mail_row.pressed.emit()
		state = storage.get_mailbox_state()
		_expect(int(state.get("unread_count", 0)) == 0, "opening a mail row should mark it as read")
		_expect(read_status.text == "已读", "opened mail should update to the read marker")
		var sender_portrait := mailbox.get_node("InboxPanel/DetailPanel/SenderPortraitFrame/SenderPortrait") as TextureRect
		_expect(sender_portrait.visible and sender_portrait.texture != null, "blessing mail should show its sender spirit portrait")
		var inbox_with_long_mail: Array = state.get("inbox", [])
		var long_mail: Dictionary = inbox_with_long_mail[0]
		long_mail["body"] = "愿这段旅途的祝福陪伴你继续前进。".repeat(24)
		inbox_with_long_mail[0] = long_mail
		state["inbox"] = inbox_with_long_mail
		storage.save_mailbox_state(state)
		mailbox.call("_refresh")
		await process_frame
		await process_frame
		_expect(detail_scroll.get_v_scroll_bar().max_value > 0.0, "long mail content should be vertically scrollable without covering the action buttons")
		claim_button.pressed.emit()
		state = storage.get_mailbox_state()
		var inbox: Array = state.get("inbox", [])
		_expect(not inbox.is_empty() and (inbox[0] as Dictionary).get("claimed_at", null) != null, "claim button should persist attachment collection")
		_expect(claim_button.disabled, "claimed mail should disable its claim button")
		_expect(claim_button.get_theme_stylebox("disabled") != null, "claimed mail should retain a colored disabled button style")
		_expect(not delete_button.disabled, "claimed mail should allow safe deletion")
		_expect(delete_button.get_theme_stylebox("normal") != claim_button.get_theme_stylebox("disabled"), "delete should use the claimed-button shape with a distinct warning color")
		delete_button.pressed.emit()
		state = storage.get_mailbox_state()
		_expect((state.get("inbox", []) as Array).is_empty(), "delete button should remove claimed mail")
		var back_events: Array = []
		mailbox.back_pressed.connect(func(): back_events.append(true))
		back_button.pressed.emit()
		_expect(not back_events.is_empty(), "back button should emit the mailbox return action")

	root.remove_child(main)
	main.free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[MailboxButtonFlow] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[MailboxButtonFlow] " + failure)
	quit(1)

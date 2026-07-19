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
	var seeded_state: Dictionary = storage.get_mailbox_state()
	var seeded_inbox: Array = []
	for index in range(5):
		seeded_inbox.append({
			"id": "mailbox_page_seed:%d" % index,
			"source": "qa",
			"sender_name": "分页旅人 %d" % (index + 1),
			"sender_monster_id": "monster_049",
			"title": "分页测试来信 %d" % (index + 1),
			"body": "用于验证四封一页的邮箱布局。",
			"attachments": [],
			"created_at": index + 1,
			"read_at": 1,
			"claimed_at": 1,
			"reward_receipt_id": "mail_reward:mailbox_page_seed:%d" % index,
		})
	seeded_state["inbox"] = seeded_inbox
	storage.save_mailbox_state(seeded_state)

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("mailbox")
	await process_frame
	var mailbox := main.get_current_scene() as Control
	_expect(mailbox != null, "mailbox scene should load")
	if mailbox != null:
		var inbox_tab := mailbox.get_node("InboxTab") as BaseButton
		var blessing_tab := mailbox.get_node("BlessingTab") as BaseButton
		var next_adventurer := mailbox.get_node("BlessingPanel/Panel/NextAdventurer") as BaseButton
		var prev_adventurer := mailbox.get_node("BlessingPanel/Panel/PrevAdventurer") as BaseButton
		var send_button := mailbox.get_node("BlessingPanel/Panel/SendButton") as Button
		var claim_button := mailbox.get_node("InboxPanel/DetailPanel/ClaimButton") as Button
		var delete_button := mailbox.get_node("InboxPanel/DetailPanel/DeleteButton") as Button
		var prev_mail_page := mailbox.get_node("InboxPanel/ListPanel/PrevMailPage") as BaseButton
		var next_mail_page := mailbox.get_node("InboxPanel/ListPanel/NextMailPage") as BaseButton
		var detail_scroll := mailbox.get_node("InboxPanel/DetailPanel/MailDetailScroll") as ScrollContainer
		var back_button := mailbox.get_node("BackButton") as Button
		for button in [inbox_tab, blessing_tab, prev_adventurer, next_adventurer, prev_mail_page, next_mail_page, send_button, claim_button, delete_button, back_button]:
			_expect(button.has_node("CartoonFeedback"), "%s should retain press feedback" % button.name)
		_expect((mailbox.get_node("InboxPanel") as Control).visible, "inbox should be the default tab")
		_expect(not next_mail_page.disabled, "five messages should enable the second four-item inbox page")
		next_mail_page.pressed.emit()
		_expect(int(mailbox.get("_mail_page")) == 1, "next page should advance the inbox page index")
		prev_mail_page.pressed.emit()
		_expect(int(mailbox.get("_mail_page")) == 0, "previous page should return to the first inbox page")
		blessing_tab.pressed.emit()
		_expect((mailbox.get_node("BlessingPanel") as Control).visible and not (mailbox.get_node("InboxPanel") as Control).visible, "blessing tab should switch the visible panel")
		var first_id := str(mailbox.get("_selected_instance_id"))
		if owned.size() > 1:
			next_adventurer.pressed.emit()
			for _frame in range(28):
				await process_frame
			_expect(str(mailbox.get("_selected_instance_id")) != first_id, "next adventurer button should change the selected adventurer")
			prev_adventurer.pressed.emit()
			for _frame in range(28):
				await process_frame
			_expect(str(mailbox.get("_selected_instance_id")) == first_id, "previous adventurer button should restore the prior adventurer")
		var before_send: Dictionary = storage.get_mailbox_state()
		var pending_before := (before_send.get("pending_blessings", []) as Array).size()
		var unread_before := int(before_send.get("unread_count", 0))
		send_button.pressed.emit()
		for _frame in range(60):
			await process_frame
		var state: Dictionary = storage.get_mailbox_state()
		_expect(int(state.get("daily_send_count", 0)) == 1, "send button should consume one daily blessing")
		_expect(int(state.get("unread_count", 0)) == unread_before, "send button should not create an unread reply mail")
		var pending: Array = state.get("pending_blessings", []).duplicate(true)
		_expect(pending.size() == pending_before, "send button should remain independent from the daily inbound schedule")
		# 1.3.2 keeps already-queued legacy mail deliverable once after migration.
		pending.append({
			"id": "legacy_reply:mailbox_button_flow",
			"source": "stranger_blessing",
			"sender_name": "远方的冒险者",
			"sender_monster_id": "monster_049",
			"title": "迁移前排队的祝福",
			"body": "这封信在旧版本中已经排队，升级后仍应按时抵达。",
			"attachments": [{"kind": "gold", "amount": 1}],
			"created_at": int(Time.get_unix_time_from_system()) - 2,
			"deliver_at": int(Time.get_unix_time_from_system()) - 1,
			"read_at": null,
			"claimed_at": null,
			"reward_receipt_id": "mail_reward:legacy_reply:mailbox_button_flow",
		})
		state["pending_blessings"] = pending
		storage.save_mailbox_state(state)
		mailbox.call("_refresh")
		await process_frame
		state = storage.get_mailbox_state()
		_expect(int(state.get("unread_count", 0)) == unread_before + 1, "a due legacy reply should appear once as unread after refresh")
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
		_expect(int(state.get("unread_count", 0)) == unread_before, "opening a mail row should mark that message as read without changing other daily arrivals")
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
		var inbox_size_before_delete := inbox.size()
		_expect(not inbox.is_empty() and (inbox[0] as Dictionary).get("claimed_at", null) != null, "claim button should persist attachment collection")
		_expect(claim_button.disabled, "claimed mail should disable its claim button")
		_expect(claim_button.get_theme_stylebox("disabled") != null, "claimed mail should retain a colored disabled button style")
		_expect(not delete_button.disabled, "claimed mail should allow safe deletion")
		_expect(delete_button.get_theme_stylebox("normal") != claim_button.get_theme_stylebox("disabled"), "delete should use the claimed-button shape with a distinct warning color")
		delete_button.pressed.emit()
		state = storage.get_mailbox_state()
		_expect((state.get("inbox", []) as Array).size() == inbox_size_before_delete - 1, "delete button should remove the claimed mail without discarding other daily arrivals")
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

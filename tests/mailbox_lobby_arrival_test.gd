extends SceneTree

const MailboxServiceScript = preload("res://src/core/mailbox_service.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist for lobby-arrival tests")
	if storage == null:
		_finish()
		return
	storage.clear_all_data()
	var service := MailboxServiceScript.new(storage)
	var queued_state: Dictionary = storage.get_mailbox_state()
	var pending: Array = queued_state.get("pending_blessings", []).duplicate(true)
	var mail_id := "legacy_lobby_arrival:first"
	var second_mail_id := "legacy_lobby_arrival:second"
	for index in range(2):
		pending.append({
			"id": mail_id if index == 0 else second_mail_id,
			"source": "stranger_blessing",
			"sender_name": "远方的冒险者",
			"sender_monster_id": "monster_049",
			"title": "迁移前排队的祝福",
			"body": "旧存档中已经排队的来信仍会抵达。",
			"attachments": [],
			"created_at": int(Time.get_unix_time_from_system()) - 2,
			"deliver_at": int(Time.get_unix_time_from_system()) - 1,
			"read_at": null,
			"claimed_at": null,
			"reward_receipt_id": "mail_reward:%s" % (mail_id if index == 0 else second_mail_id),
		})
	queued_state["pending_blessings"] = pending
	storage.save_mailbox_state(queued_state)

	var main := load("res://main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	main.switch_scene("main")
	await create_timer(0.40).timeout
	var state: Dictionary = storage.get_mailbox_state()
	var shown_ids: Array = state.get("lobby_arrival_shown_blessing_ids", [])
	_expect(shown_ids.has(mail_id), "first lobby entry should persist the delivered blessing arrival")
	_expect(shown_ids.has(second_mail_id), "one lobby effect should mark the entire delivered batch so effects cannot overlap")

	main.switch_scene("mailbox")
	await process_frame
	main.switch_scene("main")
	await create_timer(0.40).timeout
	state = storage.get_mailbox_state()
	shown_ids = state.get("lobby_arrival_shown_blessing_ids", [])
	var appearances := 0
	for shown_id in shown_ids:
		if str(shown_id) == mail_id:
			appearances += 1
	_expect(appearances == 1, "re-entering the lobby must not replay the same blessing arrival")
	var second_appearances := 0
	for shown_id in shown_ids:
		if str(shown_id) == second_mail_id:
			second_appearances += 1
	_expect(second_appearances == 1, "the second mail in the delivered batch must also remain marked without replay")

	root.remove_child(main)
	main.free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MailboxLobbyArrival] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[MailboxLobbyArrival] " + failure)
	quit(1)

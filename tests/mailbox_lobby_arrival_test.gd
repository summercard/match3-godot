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
	var owned: Array = storage.get_owned_monsters()
	_expect(not owned.is_empty(), "default save should contain an adventurer")
	if owned.is_empty():
		_finish()
		return
	_expect(service.select_adventurer(str((owned[0] as Dictionary).get("instanceId", ""))), "an adventurer should be selectable for blessing delivery")
	var sent := service.send_blessing()
	_expect(bool(sent.get("ok", false)), "a simulated blessing should be available for the lobby arrival")
	var mail: Dictionary = sent.get("mail", {})
	var mail_id := str(mail.get("id", ""))
	var second_sent := service.send_blessing()
	_expect(bool(second_sent.get("ok", false)), "a second blessing should join the same unread arrival batch")
	var second_mail: Dictionary = second_sent.get("mail", {})
	var second_mail_id := str(second_mail.get("id", ""))

	var main := load("res://main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	main.switch_scene("main")
	await create_timer(0.40).timeout
	var state: Dictionary = storage.get_mailbox_state()
	var shown_ids: Array = state.get("lobby_arrival_shown_blessing_ids", [])
	_expect(shown_ids.has(mail_id), "first lobby entry should persist the delivered blessing arrival")
	_expect(shown_ids.has(second_mail_id), "first lobby entry should consume the entire unread blessing batch")

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
	_expect(second_appearances == 1, "re-entering the lobby must not replay another mail from the same arrival batch")

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

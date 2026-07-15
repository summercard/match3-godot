extends SceneTree

const MailboxServiceScript = preload("res://src/core/mailbox_service.gd")
const MailboxRulesScript = preload("res://src/core/mailbox_rules.gd")
const MailContentDBScript = preload("res://src/data/mail_content_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist for mailbox tests")
	if storage != null:
		storage.clear_all_data()
		_test_blessing_and_claim(storage)
		_test_tower_reward_idempotency(storage)
	_finish()


func _test_blessing_and_claim(storage: Node) -> void:
	var service := MailboxServiceScript.new(storage)
	var owned: Array = storage.get_owned_monsters()
	_expect(not owned.is_empty(), "default save should have an adventurer for blessing")
	if owned.is_empty():
		return
	var instance_id := str((owned[0] as Dictionary).get("instanceId", ""))
	_expect(service.select_adventurer(instance_id), "mailbox should select owned adventurer")
	var initial_state: Dictionary = service.get_state()
	_expect(MailboxRulesScript.collection_star_total(initial_state) == 3, "the three starter album entries should grant the initial three mailbox stars")
	var new_species: Dictionary = storage.add_monster_instance("monster_005", {"source": "mailbox_star_test"})
	_expect(not new_species.is_empty(), "capturing a new species should add it to the monster pool")
	var state: Dictionary = service.get_state()
	_expect(MailboxRulesScript.collection_star_total(state) == 4, "unlocking a new species should award exactly one mailbox star")
	storage.add_monster_instance("monster_005", {"source": "mailbox_star_duplicate_test"})
	state = service.get_state()
	_expect(MailboxRulesScript.collection_star_total(state) == 4, "duplicate instances of an unlocked species must not award another star")
	var sent := service.send_blessing()
	_expect(bool(sent.get("ok", false)), "blessing should queue a simulated inbound mail")
	state = service.get_state()
	_expect(int(state.get("daily_send_count", 0)) == 1, "sending blessing should consume daily count")
	_expect(int(state.get("unread_count", 0)) == 0, "a queued blessing must not become unread before its delivery batch")
	_expect((state.get("pending_blessings", []) as Array).size() == 1, "sending blessing should persist one pending reply")
	_expect(MailboxRulesScript.collection_star_total(state) == 4, "sending or receiving a blessing must not change collection-star rewards")
	var queued_mail: Dictionary = sent.get("pending_mail", {})
	_expect(int(queued_mail.get("deliver_at", 0)) > int(Time.get_unix_time_from_system()), "queued blessing should use a future delivery timestamp")
	var pending: Array = state.get("pending_blessings", []).duplicate(true)
	if not pending.is_empty():
		var due_mail: Dictionary = pending[0]
		due_mail["deliver_at"] = int(Time.get_unix_time_from_system()) - 1
		pending[0] = due_mail
		state["pending_blessings"] = pending
		storage.save_mailbox_state(state)
	state = service.get_state()
	_expect(int(state.get("unread_count", 0)) == 1, "due pending blessing should materialize as unread mail")
	var arrival_mail_id := MailboxRulesScript.next_lobby_arrival_blessing_id(state)
	_expect(arrival_mail_id == str(queued_mail.get("id", "")), "a delivered blessing should be eligible for one lobby arrival")
	state = MailboxRulesScript.mark_lobby_arrival_shown(state, arrival_mail_id)
	_expect(MailboxRulesScript.next_lobby_arrival_blessing_id(state).is_empty(), "the same blessing must not replay its lobby arrival after re-entering")
	var mail: Dictionary = (state.get("inbox", []) as Array)[0] if not (state.get("inbox", []) as Array).is_empty() else {}
	_expect(str(mail.get("source", "")) == "stranger_blessing", "mail source should identify simulated stranger")
	_expect(not str(mail.get("sender_monster_id", "")).is_empty(), "blessing mail should identify its sender spirit portrait")
	var blocked_delete := service.delete_mail(str(mail.get("id", "")))
	_expect(str(blocked_delete.get("error", "")) == "unclaimed_attachment", "unclaimed attachments must not be silently deleted")
	var claim := service.claim_mail(str(mail.get("id", "")))
	_expect(bool(claim.get("ok", false)), "blessing attachment should claim")
	var repeat := service.claim_mail(str(mail.get("id", "")))
	_expect(not bool(repeat.get("ok", false)) and str(repeat.get("error", "")) == "already_claimed", "mail attachment must not claim twice")
	_expect(bool(service.delete_mail(str(mail.get("id", ""))).get("ok", false)), "claimed mail should be deletable")
	state = service.get_state()
	_expect(MailboxRulesScript.collection_star_total(state) == 4, "deleting mail must not change collection-star rewards")
	state = service.get_state()
	state["daily_send_count"] = MailContentDBScript.DAILY_SEND_LIMIT
	storage.save_mailbox_state(state)
	var limited := service.send_blessing()
	_expect(str(limited.get("error", "")) == "daily_limit", "daily send limit should be enforced")


func _test_tower_reward_idempotency(storage: Node) -> void:
	var service := MailboxServiceScript.new(storage)
	var reward := {"gold": 120, "shared_exp": 60, "item_id": "hp_potion", "item_count": 1}
	var first := service.create_tower_reward_mail("tower_s1", 5, reward)
	var second := service.create_tower_reward_mail("tower_s1", 5, reward)
	_expect(bool(first.get("ok", false)) and bool(second.get("ok", false)), "tower reward mail creation should be idempotent")
	var state := service.get_state()
	var count := 0
	for raw_mail in state.get("inbox", []):
		if raw_mail is Dictionary and str((raw_mail as Dictionary).get("id", "")) == "tower_reward:tower_s1:5":
			count += 1
	_expect(count == 1, "same tower boss should create only one reward mail")
	var claim := service.claim_mail("tower_reward:tower_s1:5")
	_expect(bool(claim.get("ok", false)), "tower reward attachment should claim")
	_expect(not bool(service.claim_mail("tower_reward:tower_s1:5").get("ok", false)), "tower reward should not claim twice")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MailboxRules] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[MailboxRules] " + failure)
	quit(1)

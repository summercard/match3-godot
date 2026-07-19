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
	var before_pending := (state.get("pending_blessings", []) as Array).size()
	var before_inbox := (state.get("inbox", []) as Array).size()
	var sent := service.send_blessing()
	_expect(bool(sent.get("ok", false)), "sending should persist an outbound blessing")
	state = service.get_state()
	_expect(int(state.get("daily_send_count", 0)) == 1, "sending blessing should consume daily count")
	_expect((state.get("sent_history", []) as Array).size() == 1, "sending should retain outbound history")
	_expect(not sent.has("pending_mail"), "1.3.2 outbound mail must not create a reply")
	_expect((state.get("pending_blessings", []) as Array).size() == before_pending, "outbound mail must not change the independent daily delivery queue")
	_expect((state.get("inbox", []) as Array).size() == before_inbox, "outbound mail must not create immediate inbound mail")
	_expect(MailboxRulesScript.collection_star_total(state) == 4, "sending or receiving a blessing must not change collection-star rewards")

	# The independent daily schedule is stable and always contains 1—3 deliveries
	# between local 09:00 and 21:00, regardless of outbound activity.
	var fixed_now := Time.get_unix_time_from_system()
	var generated_a: Dictionary = MailboxRulesScript.ensure_daily_blessings(MailboxRulesScript.default_state(), fixed_now).get("state", {})
	var generated_b: Dictionary = MailboxRulesScript.ensure_daily_blessings(MailboxRulesScript.default_state(), fixed_now).get("state", {})
	var day_key := MailboxRulesScript.day_key_for_unix(fixed_now)
	var batches: Array = generated_a.get("delivery_schedule", {}).get(day_key, [])
	_expect(batches.size() >= 1 and batches.size() <= 3, "daily stranger mail count should be independently generated in the 1—3 range")
	_expect(generated_a.get("delivery_schedule", {}) == generated_b.get("delivery_schedule", {}), "same-day delivery schedule must be deterministic")
	_expect(generated_a.get("pending_blessings", []) == generated_b.get("pending_blessings", []), "same-day mail content and attachments must not reroll")
	var latest_delivery := 0
	for raw_time in batches:
		latest_delivery = maxi(latest_delivery, int(raw_time))
	var delivered: Dictionary = MailboxRulesScript.materialize_due_blessings(generated_a, float(latest_delivery + 1)).get("state", {})
	_expect((delivered.get("inbox", []) as Array).size() == batches.size(), "scheduled daily mails should materialize when due")
	var arrival_mail_id := MailboxRulesScript.next_lobby_arrival_blessing_id(delivered)
	_expect(not arrival_mail_id.is_empty(), "a delivered stranger blessing should be eligible for one lobby arrival")
	delivered = MailboxRulesScript.mark_lobby_arrival_shown(delivered, arrival_mail_id)
	_expect(MailboxRulesScript.next_lobby_arrival_blessing_id(delivered).is_empty(), "the delivered batch should not replay its lobby arrival")
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

extends SceneTree

const MailboxServiceScript = preload("res://src/core/mailbox_service.gd")
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
	var sent := service.send_blessing()
	_expect(bool(sent.get("ok", false)), "blessing should send and create simulated inbound mail")
	var state: Dictionary = service.get_state()
	_expect(int(state.get("daily_send_count", 0)) == 1, "sending blessing should consume daily count")
	_expect(int(state.get("unread_count", 0)) == 1, "simulated blessing should create unread mail")
	var mail: Dictionary = sent.get("mail", {})
	_expect(str(mail.get("source", "")) == "stranger_blessing", "mail source should identify simulated stranger")
	var claim := service.claim_mail(str(mail.get("id", "")))
	_expect(bool(claim.get("ok", false)), "blessing attachment should claim")
	var repeat := service.claim_mail(str(mail.get("id", "")))
	_expect(not bool(repeat.get("ok", false)) and str(repeat.get("error", "")) == "already_claimed", "mail attachment must not claim twice")
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

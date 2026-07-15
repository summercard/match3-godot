extends SceneTree

const MailboxRulesScript = preload("res://src/core/mailbox_rules.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var day_start := 200 * 86400
	var now := float(day_start + 10 * 60 * 60)
	var batches_a := MailboxRulesScript.delivery_batches_for_day(day_start)
	var batches_b := MailboxRulesScript.delivery_batches_for_day(day_start)
	_expect(batches_a == batches_b, "delivery batches must be stable for the same day")
	_expect(batches_a.size() >= 1 and batches_a.size() <= 6, "a day must have one to six delivery batches")
	for timestamp in batches_a:
		_expect(timestamp >= day_start + 9 * 60 * 60 and timestamp < day_start + 21 * 60 * 60, "delivery batch must stay inside the 09:00-21:00 window")

	var mail := {
		"id": "schedule:test:1",
		"source": "stranger_blessing",
		"title": "稳定排程测试",
		"body": "这封邮件的附件必须在入队时固定。",
		"attachments": [{"kind": "gold", "amount": 60}],
		"read_at": null,
		"claimed_at": null,
	}
	var queued := MailboxRulesScript.queue_blessing_for_delivery(MailboxRulesScript.default_state(), mail, now)
	_expect(bool(queued.get("ok", false)), "a blessing should be assigned to a future batch")
	var deliver_at := int(queued.get("deliver_at", 0))
	_expect(deliver_at > int(now), "the selected batch must be after the send time")
	var queued_state: Dictionary = queued.get("state", {})
	var pending: Array = queued_state.get("pending_blessings", [])
	_expect(pending.size() == 1, "queued blessing should be persisted in pending mail")
	if not pending.is_empty():
		_expect((pending[0] as Dictionary).get("attachments", []) == mail.get("attachments", []), "queued attachment snapshot must not reroll")

	var before_due := MailboxRulesScript.materialize_due_blessings(queued_state, deliver_at - 1)
	_expect(not bool(before_due.get("changed", true)), "a pending mail must not materialize before its batch")
	var due := MailboxRulesScript.materialize_due_blessings(queued_state, deliver_at)
	_expect(bool(due.get("changed", false)), "a pending mail must materialize at its batch")
	var delivered_state: Dictionary = due.get("state", {})
	_expect((delivered_state.get("pending_blessings", []) as Array).is_empty(), "materialized mail must leave the pending queue")
	_expect((delivered_state.get("inbox", []) as Array).size() == 1, "materialized mail must enter the inbox")
	var twice := MailboxRulesScript.materialize_due_blessings(delivered_state, deliver_at + 1)
	_expect(not bool(twice.get("changed", true)) and (twice.get("state", {}).get("inbox", []) as Array).size() == 1, "materialization must be idempotent")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MailboxDeliverySchedule] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[MailboxDeliverySchedule] " + failure)
	quit(1)

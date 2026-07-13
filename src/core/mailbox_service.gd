class_name MailboxService
extends RefCounted

const MailboxRulesScript = preload("res://src/core/mailbox_rules.gd")
const BlessingProviderScript = preload("res://src/core/blessing_provider.gd")

var _storage: Node
var _provider: BlessingProvider


func _init(storage: Node, provider: BlessingProvider = null) -> void:
	_storage = storage
	_provider = provider if provider != null else BlessingProviderScript.new()


func get_state() -> Dictionary:
	if _storage == null or not _storage.has_method("get_mailbox_state"):
		return MailboxRulesScript.default_state()
	return _storage.call("get_mailbox_state") as Dictionary


func select_adventurer(instance_id: String) -> bool:
	if _storage == null or not _storage.has_method("get_monster_instance"):
		return false
	if (_storage.call("get_monster_instance", instance_id) as Dictionary).is_empty():
		return false
	var state := get_state()
	state["selected_adventurer_id"] = instance_id
	return _save_state(state)


func send_blessing() -> Dictionary:
	var state := get_state()
	if not MailboxRulesScript.can_send(state):
		return {"ok": false, "error": "daily_limit"}
	var adventurer_id := str(state.get("selected_adventurer_id", ""))
	if adventurer_id.is_empty() or _storage == null or not _storage.has_method("get_monster_instance"):
		return {"ok": false, "error": "no_adventurer"}
	var adventurer: Dictionary = _storage.call("get_monster_instance", adventurer_id)
	if adventurer.is_empty():
		return {"ok": false, "error": "no_adventurer"}
	var now := Time.get_unix_time_from_system()
	var seed := int(now) + int(state.get("daily_send_count", 0)) * 97 + adventurer_id.hash()
	var incoming := _provider.build_simulated_blessing(seed, adventurer)
	incoming["id"] = "blessing:%d:%d" % [int(now * 1000.0), int(state.get("daily_send_count", 0))]
	incoming["created_at"] = now
	incoming["read_at"] = null
	incoming["claimed_at"] = null
	incoming["reward_receipt_id"] = "mail_reward:%s" % str(incoming.get("id", ""))
	state["daily_send_count"] = int(state.get("daily_send_count", 0)) + 1
	var history: Array = state.get("sent_history", []).duplicate(true)
	history.push_front({"adventurer_id": adventurer_id, "sent_at": now})
	state["sent_history"] = history.slice(0, 20)
	state = MailboxRulesScript.append_mail(state, incoming)
	if not _save_state(state):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "mail": incoming, "state": state}


func create_tower_reward_mail(season_id: String, floor: int, reward: Dictionary) -> Dictionary:
	if _storage == null:
		return {"ok": false, "error": "storage_unavailable"}
	var mail_id := "tower_reward:%s:%d" % [season_id, floor]
	var attachments: Array = []
	if int(reward.get("gold", 0)) > 0:
		attachments.append({"kind": "gold", "amount": int(reward.get("gold", 0))})
	if int(reward.get("shared_exp", 0)) > 0:
		attachments.append({"kind": "shared_exp", "amount": int(reward.get("shared_exp", 0))})
	if not str(reward.get("item_id", "")).is_empty():
		attachments.append({"kind": "item", "item_id": str(reward.get("item_id", "")), "count": maxi(1, int(reward.get("item_count", 1)))})
	var mail := {
		"id": mail_id,
		"source": "tower_reward",
		"sender_name": "共鸣塔补给站",
		"title": "第 %d 层阶段补给" % floor,
		"body": "你已突破共鸣塔第 %d 层，阶段补给已寄入信箱。" % floor,
		"attachments": attachments,
		"created_at": Time.get_unix_time_from_system(),
		"read_at": null,
		"claimed_at": null,
		"reward_receipt_id": "mail_reward:%s" % mail_id,
	}
	var state := MailboxRulesScript.append_mail(get_state(), mail)
	if not _save_state(state):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "mail": mail, "state": state}


func create_tower_consolation_mail(season_id: String, checkpoint_floor: int, reward: Dictionary) -> Dictionary:
	if _storage == null:
		return {"ok": false, "error": "storage_unavailable"}
	var mail_id := "tower_consolation:%s:%d" % [season_id, checkpoint_floor]
	var attachments: Array = []
	if int(reward.get("gold", 0)) > 0:
		attachments.append({"kind": "gold", "amount": int(reward.get("gold", 0))})
	if int(reward.get("shared_exp", 0)) > 0:
		attachments.append({"kind": "shared_exp", "amount": int(reward.get("shared_exp", 0))})
	var mail := {
		"id": mail_id,
		"source": "tower_consolation",
		"sender_name": "旅行精灵驿站",
		"title": "第 %d 层远征鼓励" % checkpoint_floor,
		"body": "这次远征先在第 %d 层休整吧。旅行精灵送来一份轻松补给，整理好队伍再来挑战！" % checkpoint_floor,
		"attachments": attachments,
		"created_at": Time.get_unix_time_from_system(),
		"read_at": null,
		"claimed_at": null,
		"reward_receipt_id": "mail_reward:%s" % mail_id,
	}
	var state := MailboxRulesScript.append_mail(get_state(), mail)
	if not _save_state(state):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "mail": mail, "state": state}


func mark_read(mail_id: String) -> bool:
	var state := get_state()
	var index := MailboxRulesScript.find_mail_index(state, mail_id)
	if index < 0:
		return false
	var inbox: Array = state.get("inbox", []).duplicate(true)
	var mail: Dictionary = inbox[index]
	if mail.get("read_at", null) == null:
		mail["read_at"] = Time.get_unix_time_from_system()
		inbox[index] = mail
		state["inbox"] = inbox
	return _save_state(state)


func claim_mail(mail_id: String) -> Dictionary:
	var state := get_state()
	var index := MailboxRulesScript.find_mail_index(state, mail_id)
	if index < 0:
		return {"ok": false, "error": "not_found"}
	var mail: Dictionary = (state.get("inbox", []) as Array)[index]
	if mail.get("claimed_at", null) != null:
		return {"ok": false, "error": "already_claimed"}
	var receipt_id := str(mail.get("reward_receipt_id", "mail_reward:%s" % mail_id))
	if _storage == null or not _storage.has_method("begin_reward_receipt_claim") or not bool(_storage.call("begin_reward_receipt_claim", receipt_id)):
		return {"ok": false, "error": "already_claimed"}
	var tx: Dictionary = _storage.call("run_transaction", func() -> Dictionary:
		var latest := get_state()
		var latest_index := MailboxRulesScript.find_mail_index(latest, mail_id)
		if latest_index < 0:
			return {"ok": false, "error": "not_found"}
		var latest_inbox: Array = latest.get("inbox", []).duplicate(true)
		var latest_mail: Dictionary = latest_inbox[latest_index]
		if latest_mail.get("claimed_at", null) != null:
			return {"ok": false, "error": "already_claimed"}
		for attachment in latest_mail.get("attachments", []):
			if not attachment is Dictionary:
				continue
			var data: Dictionary = attachment
			match str(data.get("kind", "")):
				"gold":
					if not bool(_storage.call("add_gold", int(data.get("amount", 0)))):
						return {"ok": false, "error": "gold_failed"}
				"shared_exp":
					_storage.call("add_shared_monster_exp", int(data.get("amount", 0)))
				"item":
					if not bool(_storage.call("add_item", str(data.get("item_id", "")), int(data.get("count", 1)))):
						return {"ok": false, "error": "item_failed"}
		latest_mail["claimed_at"] = Time.get_unix_time_from_system()
		latest_mail["read_at"] = latest_mail.get("read_at", latest_mail["claimed_at"])
		latest_inbox[latest_index] = latest_mail
		latest["inbox"] = latest_inbox
		if not _save_state(latest):
			return {"ok": false, "error": "mail_save_failed"}
		if not bool(_storage.call("complete_reward_receipt_claim", receipt_id)):
			return {"ok": false, "error": "receipt_failed"}
		return {"ok": true, "mail": latest_mail}
	)
	if not bool(tx.get("ok", false)):
		_storage.call("cancel_reward_receipt_claim", receipt_id)
	return tx


func delete_mail(mail_id: String) -> Dictionary:
	var state := get_state()
	var index := MailboxRulesScript.find_mail_index(state, mail_id)
	if index < 0:
		return {"ok": false, "error": "not_found"}
	var inbox: Array = state.get("inbox", []).duplicate(true)
	var mail: Dictionary = inbox[index]
	# Never let deleting a message silently discard an unclaimed reward.
	if mail.get("claimed_at", null) == null and not (mail.get("attachments", []) as Array).is_empty():
		return {"ok": false, "error": "unclaimed_attachment"}
	inbox.remove_at(index)
	state["inbox"] = inbox
	if not _save_state(state):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "mail": mail, "state": get_state()}


func _save_state(state: Dictionary) -> bool:
	if _storage == null or not _storage.has_method("save_mailbox_state"):
		return false
	return bool(_storage.call("save_mailbox_state", state))

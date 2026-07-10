class_name MailboxRules
extends RefCounted

const MailContentDBScript = preload("res://src/data/mail_content_db.gd")


static func default_state() -> Dictionary:
	return {
		"selected_adventurer_id": "",
		"daily_send_count": 0,
		"daily_reset_key": "",
		"inbox": [],
		"sent_history": [],
		"unread_count": 0,
	}


static func normalize_state(raw: Variant, today_key: String = "") -> Dictionary:
	var state := default_state()
	if raw is Dictionary:
		for key in state.keys():
			if raw.has(key):
				state[key] = raw.get(key)
	if not state.get("inbox", []) is Array:
		state["inbox"] = []
	if not state.get("sent_history", []) is Array:
		state["sent_history"] = []
	if not today_key.is_empty() and str(state.get("daily_reset_key", "")) != today_key:
		state["daily_reset_key"] = today_key
		state["daily_send_count"] = 0
	state["daily_send_count"] = maxi(0, int(state.get("daily_send_count", 0)))
	state["unread_count"] = count_unread(state.get("inbox", []))
	return state


static func can_send(state: Dictionary) -> bool:
	return int(state.get("daily_send_count", 0)) < MailContentDBScript.DAILY_SEND_LIMIT


static func count_unread(inbox: Array) -> int:
	var count := 0
	for raw_mail in inbox:
		if raw_mail is Dictionary and (raw_mail as Dictionary).get("read_at", null) == null:
			count += 1
	return count


static func append_mail(state: Dictionary, mail: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var inbox: Array = next.get("inbox", []).duplicate(true)
	var mail_id := str(mail.get("id", ""))
	for existing in inbox:
		if existing is Dictionary and str((existing as Dictionary).get("id", "")) == mail_id:
			return normalize_state(next)
	inbox.push_front(mail.duplicate(true))
	while inbox.size() > MailContentDBScript.MAX_INBOX_SIZE:
		var candidate: Dictionary = inbox[inbox.size() - 1]
		if candidate.get("claimed_at", null) == null:
			break
		inbox.pop_back()
	next["inbox"] = inbox
	return normalize_state(next)


static func find_mail_index(state: Dictionary, mail_id: String) -> int:
	var inbox: Array = state.get("inbox", [])
	for index in inbox.size():
		if inbox[index] is Dictionary and str((inbox[index] as Dictionary).get("id", "")) == mail_id:
			return index
	return -1

class_name MailboxRules
extends RefCounted

const MailContentDBScript = preload("res://src/data/mail_content_db.gd")
const MonsterPoolScript = preload("res://src/core/monster_pool.gd")

const DELIVERY_WINDOW_START_SEC := 9 * 60 * 60
const DELIVERY_WINDOW_DURATION_SEC := 12 * 60 * 60
const DELIVERY_BATCH_MIN := 1
const DELIVERY_BATCH_MAX := 6


static func default_state() -> Dictionary:
	return {
		"selected_adventurer_id": "",
		"daily_send_count": 0,
		"daily_reset_key": "",
		"inbox": [],
		"sent_history": [],
		# Date-keyed, deterministic batch timestamps and mail snapshots awaiting
		# delivery. Pending mail has already rolled its attachment package.
		"delivery_schedule": {},
		"pending_blessings": [],
		"unread_count": 0,
		# The three starter species unlock as the initial album entries. Every
		# subsequently unlocked species contributes exactly one collection star.
		"collection_stars": MonsterPoolScript.DEFAULT_STARTERS.size(),
		"collection_star_species_ids": MonsterPoolScript.DEFAULT_STARTERS.duplicate(),
		# Tracks which inbound blessings have already used the lobby arrival effect.
		# A delivered blessing should animate once, even if the player re-enters the lobby.
		"lobby_arrival_shown_blessing_ids": [],
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
	if not state.get("delivery_schedule", {}) is Dictionary:
		state["delivery_schedule"] = {}
	if not state.get("pending_blessings", []) is Array:
		state["pending_blessings"] = []
	if not state.get("lobby_arrival_shown_blessing_ids", []) is Array:
		state["lobby_arrival_shown_blessing_ids"] = []
	if not today_key.is_empty() and str(state.get("daily_reset_key", "")) != today_key:
		state["daily_reset_key"] = today_key
		state["daily_send_count"] = 0
	state["daily_send_count"] = maxi(0, int(state.get("daily_send_count", 0)))
	var starred_species: Array[String] = []
	for raw_id in state.get("collection_star_species_ids", []):
		var monster_id := str(raw_id)
		if not monster_id.is_empty() and not starred_species.has(monster_id):
			starred_species.append(monster_id)
	state["collection_star_species_ids"] = starred_species
	state["collection_stars"] = maxi(starred_species.size(), int(state.get("collection_stars", starred_species.size())))
	var normalized_schedule := {}
	for raw_key in (state.get("delivery_schedule", {}) as Dictionary):
		var key := str(raw_key)
		var raw_batches: Variant = (state.get("delivery_schedule", {}) as Dictionary).get(raw_key, [])
		if key.is_empty() or not raw_batches is Array:
			continue
		var batches: Array[int] = []
		for raw_time in raw_batches:
			var timestamp := int(raw_time)
			if timestamp > 0 and not batches.has(timestamp):
				batches.append(timestamp)
		batches.sort()
		if not batches.is_empty():
			normalized_schedule[key] = batches
	state["delivery_schedule"] = normalized_schedule
	var pending: Array = []
	var pending_ids := {}
	for raw_pending in state.get("pending_blessings", []):
		if not raw_pending is Dictionary:
			continue
		var pending_mail: Dictionary = (raw_pending as Dictionary).duplicate(true)
		var pending_id := str(pending_mail.get("id", ""))
		if pending_id.is_empty() or pending_ids.has(pending_id) or int(pending_mail.get("deliver_at", 0)) <= 0:
			continue
		pending_ids[pending_id] = true
		pending.append(pending_mail)
	pending.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("deliver_at", 0)) < int(b.get("deliver_at", 0)))
	state["pending_blessings"] = pending
	var shown_arrival_ids: Array[String] = []
	for raw_id in state.get("lobby_arrival_shown_blessing_ids", []):
		var mail_id := str(raw_id)
		if not mail_id.is_empty() and not shown_arrival_ids.has(mail_id):
			shown_arrival_ids.append(mail_id)
	state["lobby_arrival_shown_blessing_ids"] = shown_arrival_ids
	state["unread_count"] = count_unread(state.get("inbox", []))
	return state


static func can_send(state: Dictionary) -> bool:
	return int(state.get("daily_send_count", 0)) < MailContentDBScript.DAILY_SEND_LIMIT


static func day_key_for_unix(now_unix: float) -> String:
	return str(int(floor(now_unix / 86400.0)))


static func _day_start_unix(now_unix: float) -> int:
	return int(floor(now_unix / 86400.0) * 86400.0)


static func _stable_seed(value: String) -> int:
	return posmod(value.hash(), 2147483647)


static func delivery_batches_for_day(day_start_unix: int) -> Array[int]:
	var seed := _stable_seed("mail_delivery:%d" % day_start_unix)
	var count := DELIVERY_BATCH_MIN + posmod(seed, DELIVERY_BATCH_MAX - DELIVERY_BATCH_MIN + 1)
	var batches: Array[int] = []
	for index in count:
		var offset := posmod(seed + (index + 1) * 7919 + index * index * 173, DELIVERY_WINDOW_DURATION_SEC)
		var timestamp := day_start_unix + DELIVERY_WINDOW_START_SEC + offset
		while batches.has(timestamp):
			timestamp += 1
		batches.append(timestamp)
	batches.sort()
	return batches


static func queue_blessing_for_delivery(state: Dictionary, mail: Dictionary, now_unix: float) -> Dictionary:
	var next := normalize_state(state)
	var schedule: Dictionary = next.get("delivery_schedule", {}).duplicate(true)
	var day_start := _day_start_unix(now_unix)
	var deliver_at := 0
	for _day_offset in 8:
		var day_key := day_key_for_unix(day_start)
		var batches: Array[int] = []
		for raw_time in schedule.get(day_key, []):
			batches.append(int(raw_time))
		if batches.is_empty():
			batches = delivery_batches_for_day(day_start)
			schedule[day_key] = batches.duplicate()
		for timestamp in batches:
			if timestamp > int(now_unix):
				deliver_at = timestamp
				break
		if deliver_at > 0:
			break
		day_start += 86400
	if deliver_at <= 0:
		return {"ok": false, "error": "delivery_schedule_unavailable", "state": next}
	var queued_mail := mail.duplicate(true)
	queued_mail["deliver_at"] = deliver_at
	var pending: Array = next.get("pending_blessings", []).duplicate(true)
	var mail_id := str(queued_mail.get("id", ""))
	for existing in pending:
		if existing is Dictionary and str((existing as Dictionary).get("id", "")) == mail_id:
			next["delivery_schedule"] = schedule
		return {"ok": true, "state": normalize_state(next), "deliver_at": int((existing as Dictionary).get("deliver_at", deliver_at))}
	pending.append(queued_mail)
	next["delivery_schedule"] = schedule
	next["pending_blessings"] = pending
	return {"ok": true, "state": normalize_state(next), "deliver_at": deliver_at}


static func materialize_due_blessings(state: Dictionary, now_unix: float) -> Dictionary:
	var next := normalize_state(state)
	var remaining: Array = []
	var changed := false
	for raw_pending in next.get("pending_blessings", []):
		if not raw_pending is Dictionary:
			continue
		var mail: Dictionary = (raw_pending as Dictionary).duplicate(true)
		if int(mail.get("deliver_at", 0)) > int(now_unix):
			remaining.append(mail)
			continue
		mail.erase("deliver_at")
		next = append_mail(next, mail)
		changed = true
	if changed:
		next["pending_blessings"] = remaining
	return {"state": normalize_state(next), "changed": changed}


static func count_unread(inbox: Array) -> int:
	var count := 0
	for raw_mail in inbox:
		if raw_mail is Dictionary and (raw_mail as Dictionary).get("read_at", null) == null:
			count += 1
	return count


static func count_unread_blessings(inbox: Array) -> int:
	var count := 0
	for raw_mail in inbox:
		if raw_mail is Dictionary:
			var mail := raw_mail as Dictionary
			if str(mail.get("source", "")) == "stranger_blessing" and mail.get("read_at", null) == null:
				count += 1
	return count


static func collection_star_total(state: Dictionary) -> int:
	return maxi(0, int(state.get("collection_stars", 0)))


## Award one mailbox star for a species that has never unlocked an album entry.
## The species list makes the grant idempotent, even if an instance is later sold.
static func award_new_species_star(state: Dictionary, monster_id: String) -> Dictionary:
	var next := normalize_state(state)
	if monster_id.is_empty():
		return next
	var starred_species: Array = next.get("collection_star_species_ids", []).duplicate(true)
	if starred_species.has(monster_id):
		return next
	starred_species.append(monster_id)
	next["collection_star_species_ids"] = starred_species
	next["collection_stars"] = collection_star_total(next) + 1
	return normalize_state(next)


static func next_lobby_arrival_blessing_id(state: Dictionary) -> String:
	var shown_ids: Array = state.get("lobby_arrival_shown_blessing_ids", [])
	for raw_mail in state.get("inbox", []):
		if not raw_mail is Dictionary:
			continue
		var mail := raw_mail as Dictionary
		var mail_id := str(mail.get("id", ""))
		if str(mail.get("source", "")) == "stranger_blessing" and mail.get("read_at", null) == null and not mail_id.is_empty() and not shown_ids.has(mail_id):
			return mail_id
	return ""


static func mark_lobby_arrival_shown(state: Dictionary, mail_id: String) -> Dictionary:
	var next := state.duplicate(true)
	if mail_id.is_empty():
		return normalize_state(next)
	var shown_ids: Array = next.get("lobby_arrival_shown_blessing_ids", []).duplicate(true)
	# A single lobby arrival represents the current unread blessing batch. Mark the
	# entire batch now so switching away and back cannot replay older messages.
	for raw_mail in next.get("inbox", []):
		if not raw_mail is Dictionary:
			continue
		var mail := raw_mail as Dictionary
		var pending_id := str(mail.get("id", ""))
		if str(mail.get("source", "")) == "stranger_blessing" and mail.get("read_at", null) == null and not pending_id.is_empty() and not shown_ids.has(pending_id):
			shown_ids.append(pending_id)
	next["lobby_arrival_shown_blessing_ids"] = shown_ids
	return normalize_state(next)


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

class_name TowerRules
extends RefCounted

const TowerDBScript = preload("res://src/data/tower_db.gd")


static func default_state() -> Dictionary:
	return {
		"season_id": "tower_s1",
		"active": false,
		"current_floor": 1,
		"checkpoint_floor": 1,
		"party_instance_ids": [],
		"party_snapshot": [],
		"skill_charges": {},
		"leader_charge_points": {},
		"buffs": [],
		"supplies": [],
		"stage_seed": 12017,
		"checkpoint_snapshot": {},
		"highest_floor": 0,
		"total_player_turns": 0,
		"highest_turn_damage": 0,
		"claimed_stage_rewards": [],
		"pending_cards": [],
		"pending_reward_floor": 0,
		"completed": false,
	}


static func normalize_state(raw: Variant) -> Dictionary:
	var state := default_state()
	if raw is Dictionary:
		for key in state.keys():
			if raw.has(key):
				state[key] = raw.get(key)
	state["current_floor"] = clampi(int(state.get("current_floor", 1)), 1, TowerDBScript.MAX_FLOOR)
	state["checkpoint_floor"] = clampi(int(state.get("checkpoint_floor", 1)), 1, TowerDBScript.MAX_FLOOR)
	state["highest_floor"] = clampi(int(state.get("highest_floor", 0)), 0, TowerDBScript.MAX_FLOOR)
	state["total_player_turns"] = maxi(0, int(state.get("total_player_turns", 0)))
	state["highest_turn_damage"] = maxi(0, int(state.get("highest_turn_damage", 0)))
	for array_key in ["party_instance_ids", "party_snapshot", "buffs", "supplies", "claimed_stage_rewards", "pending_cards"]:
		if not state.get(array_key, []) is Array:
			state[array_key] = []
	for dict_key in ["skill_charges", "leader_charge_points", "checkpoint_snapshot"]:
		if not state.get(dict_key, {}) is Dictionary:
			state[dict_key] = {}
	return state


static func begin_run(state: Dictionary, party_instance_ids: Array, party_snapshot: Array) -> Dictionary:
	var previous := normalize_state(state)
	var next := default_state()
	next["season_id"] = str(previous.get("season_id", next["season_id"]))
	next["highest_floor"] = int(previous.get("highest_floor", 0))
	next["total_player_turns"] = int(previous.get("total_player_turns", 0))
	next["highest_turn_damage"] = int(previous.get("highest_turn_damage", 0))
	next["claimed_stage_rewards"] = previous.get("claimed_stage_rewards", []).duplicate()
	next["active"] = true
	next["party_instance_ids"] = party_instance_ids.duplicate()
	next["party_snapshot"] = party_snapshot.duplicate(true)
	next["checkpoint_snapshot"] = _snapshot_for_checkpoint(next)
	return next


static func current_floor_data(state: Dictionary) -> Dictionary:
	return TowerDBScript.get_floor(int(state.get("current_floor", 1)))


static func complete_wave(state: Dictionary, continuation: Dictionary, wave_turns: int, turn_damage: int) -> Dictionary:
	var next := normalize_state(state).duplicate(true)
	var floor := int(next.get("current_floor", 1))
	if not TowerDBScript.is_valid_floor(floor):
		return {"ok": false, "error": "invalid_floor", "state": next}
	next["party_snapshot"] = (continuation.get("party_snapshot", []) as Array).duplicate(true)
	next["skill_charges"] = (continuation.get("skill_charges", {}) as Dictionary).duplicate(true)
	next["leader_charge_points"] = (continuation.get("leader_charge_points", {}) as Dictionary).duplicate(true)
	next["total_player_turns"] = int(next.get("total_player_turns", 0)) + maxi(0, wave_turns)
	next["highest_floor"] = maxi(int(next.get("highest_floor", 0)), floor)
	next["highest_turn_damage"] = maxi(int(next.get("highest_turn_damage", 0)), maxi(0, turn_damage))
	if TowerDBScript.is_boss_floor(floor):
		next["pending_cards"] = TowerDBScript.get_card_candidates(floor, int(next.get("stage_seed", 0)))
		next["pending_reward_floor"] = floor
		return {
			"ok": true,
			"state": next,
			"event": "boss_cleared",
			"reward": TowerDBScript.get_stage_reward(floor),
			"cards": next["pending_cards"].duplicate(true),
		}
	next["current_floor"] = floor + 1
	return {"ok": true, "state": next, "event": "wave_cleared"}


static func choose_card(state: Dictionary, card_id: String) -> Dictionary:
	var next := normalize_state(state).duplicate(true)
	var floor := int(next.get("pending_reward_floor", 0))
	if floor <= 0 or not TowerDBScript.is_boss_floor(floor):
		return {"ok": false, "error": "no_pending_choice", "state": next}
	var card := TowerDBScript.get_card(card_id)
	if card.is_empty() or not _contains_card(next.get("pending_cards", []), card_id):
		return {"ok": false, "error": "invalid_card", "state": next}
	if not _can_apply_card(next, card):
		return {"ok": false, "error": "card_cap", "state": next}
	_apply_card(next, card)
	next["pending_cards"] = []
	next["pending_reward_floor"] = 0
	if floor >= TowerDBScript.MAX_FLOOR:
		next["completed"] = true
		next["active"] = false
		next["current_floor"] = TowerDBScript.MAX_FLOOR
		return {"ok": true, "state": next, "event": "tower_completed", "card": card}
	next["current_floor"] = floor + 1
	next["checkpoint_floor"] = floor + 1
	next["checkpoint_snapshot"] = _snapshot_for_checkpoint(next)
	return {"ok": true, "state": next, "event": "card_chosen", "card": card}


static func restore_checkpoint(state: Dictionary) -> Dictionary:
	var normalized := normalize_state(state)
	var snapshot: Dictionary = normalized.get("checkpoint_snapshot", {})
	if snapshot.is_empty():
		return normalized
	var restored := normalize_state(snapshot).duplicate(true)
	restored["highest_floor"] = maxi(int(restored.get("highest_floor", 0)), int(normalized.get("highest_floor", 0)))
	restored["highest_turn_damage"] = maxi(int(restored.get("highest_turn_damage", 0)), int(normalized.get("highest_turn_damage", 0)))
	restored["claimed_stage_rewards"] = normalized.get("claimed_stage_rewards", []).duplicate()
	return restored


static func mark_stage_reward_claimed(state: Dictionary, floor: int) -> Dictionary:
	var next := normalize_state(state).duplicate(true)
	var claimed: Array = next.get("claimed_stage_rewards", []).duplicate()
	if not claimed.has(floor):
		claimed.append(floor)
	next["claimed_stage_rewards"] = claimed
	return next


static func damage_multiplier(state: Dictionary) -> float:
	var multiplier := 1.0
	for raw_buff in state.get("buffs", []):
		if raw_buff is Dictionary:
			multiplier += float((raw_buff as Dictionary).get("damage_bonus", 0.0))
	return multiplier


static func enemy_damage_multiplier(state: Dictionary) -> float:
	var multiplier := 1.0
	for raw_buff in state.get("buffs", []):
		if raw_buff is Dictionary:
			multiplier -= float((raw_buff as Dictionary).get("enemy_damage_reduction", 0.0))
	return clampf(multiplier, 0.35, 1.0)


static func bonus_charge_per_match(state: Dictionary) -> int:
	var bonus := 0
	for raw_buff in state.get("buffs", []):
		if raw_buff is Dictionary:
			bonus += int((raw_buff as Dictionary).get("bonus_charge_per_match", 0))
	return bonus


static func _snapshot_for_checkpoint(state: Dictionary) -> Dictionary:
	var snapshot := state.duplicate(true)
	snapshot["checkpoint_snapshot"] = {}
	return snapshot


static func _contains_card(cards: Array, card_id: String) -> bool:
	for raw_card in cards:
		if raw_card is Dictionary and str((raw_card as Dictionary).get("id", "")) == card_id:
			return true
	return false


static func _can_apply_card(state: Dictionary, card: Dictionary) -> bool:
	var card_id := str(card.get("id", ""))
	var count := 0
	for raw_buff in state.get("buffs", []):
		if raw_buff is Dictionary and str((raw_buff as Dictionary).get("id", "")) == card_id:
			count += 1
	if bool(card.get("unique", false)) and count > 0:
		return false
	return count < int(card.get("max_stacks", 99))


static func _apply_card(state: Dictionary, card: Dictionary) -> void:
	var party: Array = state.get("party_snapshot", [])
	var heal_ratio := float(card.get("heal_ratio", 0.0))
	var hp_loss := float(card.get("current_hp_loss", 0.0))
	for idx in party.size():
		if not party[idx] is Dictionary:
			continue
		var unit: Dictionary = party[idx]
		var max_hp := maxi(1, int(unit.get("maxHP", 1)))
		var hp := int(unit.get("hp", max_hp))
		if heal_ratio > 0.0:
			hp = mini(max_hp, hp + int(round(float(max_hp) * heal_ratio)))
		if hp_loss > 0.0:
			hp = maxi(1, hp - int(round(float(hp) * hp_loss)))
		unit["hp"] = hp
		party[idx] = unit
	state["party_snapshot"] = party
	var charge_gain := int(card.get("charge_gain", 0))
	if charge_gain > 0:
		var charges: Dictionary = state.get("skill_charges", {}).duplicate(true)
		for unit in party:
			if unit is Dictionary:
				var unit_id := str((unit as Dictionary).get("id", ""))
				if not unit_id.is_empty():
					charges[unit_id] = int(charges.get(unit_id, 0)) + charge_gain
		state["skill_charges"] = charges
	if str(card.get("kind", "")) != "supply":
		var buffs: Array = state.get("buffs", []).duplicate(true)
		buffs.append(card.duplicate(true))
		state["buffs"] = buffs

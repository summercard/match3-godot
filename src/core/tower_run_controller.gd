class_name TowerRunController
extends RefCounted

const TowerDBScript = preload("res://src/data/tower_db.gd")
const TowerRulesScript = preload("res://src/core/tower_rules.gd")

var _storage: Node


func _init(storage: Node) -> void:
	_storage = storage


func is_unlocked() -> bool:
	return _storage != null and _storage.has_method("is_tower_unlocked") and bool(_storage.call("is_tower_unlocked"))


func get_state() -> Dictionary:
	if _storage == null or not _storage.has_method("get_tower_state"):
		return TowerRulesScript.default_state()
	return _storage.call("get_tower_state") as Dictionary


func start_new_run() -> Dictionary:
	if not is_unlocked():
		return {"ok": false, "error": "locked"}
	if _storage == null or not _storage.has_method("get_team_battle_stats"):
		return {"ok": false, "error": "storage_unavailable"}
	var team: Array = _storage.call("get_team_battle_stats")
	if team.is_empty():
		return {"ok": false, "error": "empty_team"}
	var ids: Array = []
	for raw_unit in team:
		if raw_unit is Dictionary:
			ids.append(str((raw_unit as Dictionary).get("id", "")))
	var next := TowerRulesScript.begin_run(get_state(), ids, team)
	if not _save_state(next):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "state": next, "floor": TowerRulesScript.current_floor_data(next)}


func get_current_floor() -> Dictionary:
	return TowerRulesScript.current_floor_data(get_state())


func complete_wave(continuation: Dictionary, wave_turns: int, highest_turn_damage: int) -> Dictionary:
	var result := TowerRulesScript.complete_wave(get_state(), continuation, wave_turns, highest_turn_damage)
	if not bool(result.get("ok", false)):
		return result
	var state: Dictionary = result.get("state", {})
	if not _save_state(state):
		return {"ok": false, "error": "save_failed"}
	return result


func choose_card(card_id: String) -> Dictionary:
	var previous := get_state()
	var result := TowerRulesScript.choose_card(previous, card_id)
	if not bool(result.get("ok", false)):
		return result
	var state: Dictionary = result.get("state", {})
	if not _save_state(state):
		return {"ok": false, "error": "save_failed"}
	return result


func restore_checkpoint() -> Dictionary:
	var restored := TowerRulesScript.restore_checkpoint(get_state())
	if not _save_state(restored):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "state": restored, "floor": TowerRulesScript.current_floor_data(restored)}


func mark_reward_delivered(floor: int) -> bool:
	var next := TowerRulesScript.mark_stage_reward_claimed(get_state(), floor)
	return _save_state(next)


func _save_state(state: Dictionary) -> bool:
	if _storage == null or not _storage.has_method("save_tower_state"):
		return false
	return bool(_storage.call("save_tower_state", state))

extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		_finish()
		return

	save_manager.clear_all_data()
	save_manager.init_monster_pokedex("monster_001")

	var old_placed_at_seconds := Time.get_unix_time_from_system() - 10.0 * 60.0
	save_manager.set_ranch_state({
		"slots": [
			{ "monsterId": "monster_001", "placedAt": old_placed_at_seconds },
			{ "monsterId": null, "placedAt": null }
		],
		"unlockedSlots": 3
	})

	var ranch: Dictionary = save_manager.get_ranch_state()
	_expect(ranch.has("unlocked_slots"), "ranch should expose snake_case unlocked_slots")
	_expect(not ranch.has("unlockedSlots"), "ranch should not expose camelCase unlockedSlots")
	_expect(ranch.get("slots", []).size() >= 3, "ranch should keep unlocked slot count")

	var first_slot: Dictionary = ranch.get("slots", [])[0]
	_expect(first_slot.get("monster_id", "") == "monster_001", "ranch slot should expose snake_case monster_id")
	_expect(first_slot.has("placed_at"), "ranch slot should expose snake_case placed_at")
	_expect(not first_slot.has("monsterId") and not first_slot.has("placedAt"), "ranch slot should not expose camelCase keys")
	_expect(float(first_slot.get("placed_at", 0.0)) > 100000000000.0, "ranch placed_at should be normalized to milliseconds")

	var exp_before: int = save_manager.get_monster_exp("monster_001")
	var collected: float = save_manager.collect_idle_exp("monster_001")
	var exp_after: int = save_manager.get_monster_exp("monster_001")
	_expect(collected > 0.0, "collect_idle_exp should collect from migrated ranch timestamp")
	_expect(exp_after > exp_before, "collect_idle_exp should add monster exp")

	ranch = save_manager.get_ranch_state()
	first_slot = ranch.get("slots", [])[0]
	_expect(first_slot.get("monster_id", "") == "monster_001", "collect should keep monster in ranch")
	_expect(float(first_slot.get("placed_at", 0.0)) > old_placed_at_seconds * 1000.0, "collect should reset placed_at in milliseconds")

	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchSchema] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[RanchSchema] " + failure)
		quit(1)

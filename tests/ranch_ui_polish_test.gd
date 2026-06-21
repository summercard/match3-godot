extends SceneTree

var _failures: Array[String] = []


class FakeStorage:
	extends Node
	var added_shared_exp: int = 0
	var saved_ranch_state: Dictionary = {}

	func add_shared_monster_exp(amount: int) -> Dictionary:
		added_shared_exp += amount
		return {"added": amount, "overflow": 0, "current": added_shared_exp}

	func set_ranch_state(state: Dictionary) -> bool:
		saved_ranch_state = state.duplicate(true)
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ranch: Control = load("res://src/ui/controllers/ranch_logic.gd").new()
	root.add_child(ranch)
	var constants: Dictionary = ranch.get_script().get_script_constant_map()

	for key: String in [
		"BACK_RECT", "COLLECT_RECT", "RANCH_FOCUS_RECT", "RANCH_CLASSROOM_RECT",
		"RANCH_SOCIAL_RECT", "BOTTOM_LEFT_RECT", "BOTTOM_RIGHT_RECT",
		"CLASS_EVOLVE_RECT", "SOCIAL_PLACE_SWITCH_RECT", "SOCIAL_RESULT_CLOSE_RECT",
		"SLOT_RECTS",
	]:
		_expect(constants.has(key), "%s should remain defined" % key)
		if constants.has(key) and constants[key] is Rect2:
			var rect: Rect2 = constants[key]
			_expect(rect.size.y >= 44.0, "%s should preserve a mobile-sized tap height" % key)

	ranch.set("_storage", null)
	ranch.set("_captured_monsters", [
		{"instanceId": "monster_001", "monsterId": "monster_001", "level": 3, "nature": "brave"},
		{"instanceId": "monster_002", "monsterId": "monster_002", "level": 4, "nature": "gentle"},
	])
	var now := Time.get_unix_time_from_system() * 1000.0
	ranch.set("_slots_data", [
		{"instance_id": "monster_001", "placed_at": now - 10.0 * 60.0 * 1000.0},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
	])
	_expect(int(ranch.call("_get_monster_level", "monster_001")) == 3, "offline preview should keep the instance level shown across panels")
	ranch.call("_calc_idle_exp")
	ranch.call("_handle_ranch_tap", (constants["COLLECT_RECT"] as Rect2).get_center())
	_expect(str(ranch.get("_status_text")).begins_with("收获 +"), "collect button should trigger idle reward feedback")

	var fake_storage := FakeStorage.new()
	root.add_child(fake_storage)
	var now2 := Time.get_unix_time_from_system() * 1000.0
	ranch.set("_storage", fake_storage)
	ranch.set("_captured_monsters", [
		{"instanceId": "monster_001", "monsterId": "monster_001", "level": 3, "nature": "brave"},
		{"instanceId": "monster_002", "monsterId": "monster_002", "level": 4, "nature": "gentle"},
	])
	ranch.set("_slots_data", [
		{"instance_id": "monster_001", "placed_at": now2 - 10.0 * 60.0 * 1000.0},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
	])
	ranch.call("_rebuild_instance_index")
	ranch.call("_calc_idle_exp")
	ranch.call("_handle_ranch_tap", (constants["SLOT_RECTS"] as Array)[0].get_center())
	_expect(fake_storage.added_shared_exp > 0, "tapping an occupied ranch slot should collect its pending shared exp")
	ranch.set("_slots_data", [
		{"instance_id": "monster_001", "placed_at": now2 - 10.0 * 60.0 * 1000.0},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
		{"instance_id": null, "placed_at": null},
	])
	fake_storage.added_shared_exp = 0
	ranch.call("_calc_idle_exp")
	ranch.call("_on_picker_item_pressed", "monster_002")
	_expect(fake_storage.added_shared_exp == 0, "replacing a slot with pending idle exp should not auto-collect")
	var slots_after_replace_attempt: Array = ranch.get("_slots_data")
	_expect(str((slots_after_replace_attempt[0] as Dictionary).get("instance_id", "")) == "monster_001", "pending idle exp should block replacement until collected")
	fake_storage.queue_free()

	ranch.call("_handle_ranch_tap", (constants["RANCH_CLASSROOM_RECT"] as Rect2).get_center())
	_expect(str(ranch.get("_active_page")) == "classroom", "classroom navigation button should open its page")
	ranch.call("_switch_to_ranch")
	ranch.call("_handle_ranch_tap", (constants["RANCH_SOCIAL_RECT"] as Rect2).get_center())
	_expect(str(ranch.get("_active_page")) == "social", "social navigation button should open its page")

	ranch.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RanchUiPolish] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[RanchUiPolish] " + failure)
		quit(1)

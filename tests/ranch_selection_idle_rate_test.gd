extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist")
	if storage == null:
		_finish()
		return
	storage.clear_all_data()
	var player: Dictionary = storage.get_player()
	player["level"] = 10
	storage.save_player(player)
	var low_wise: Dictionary = storage.add_monster_instance("monster_001", {"level": 1, "nature": "wise", "source": "idle_test"})
	var high_wise: Dictionary = storage.add_monster_instance("monster_002", {"level": 10, "nature": "wise", "source": "idle_test"})
	var low_fierce: Dictionary = storage.add_monster_instance("monster_003", {"level": 1, "nature": "fierce", "source": "idle_test"})
	var low_id := str(low_wise.get("instanceId", ""))
	var high_id := str(high_wise.get("instanceId", ""))
	var fierce_id := str(low_fierce.get("instanceId", ""))
	storage.place_instance_in_ranch(low_id, 0)
	storage.place_instance_in_ranch(high_id, 1)
	storage.place_instance_in_ranch(fierce_id, 2)

	var low_rate: float = storage.get_idle_exp_rate_for_instance(low_id)
	var high_rate: float = storage.get_idle_exp_rate_for_instance(high_id)
	var fierce_rate: float = storage.get_idle_exp_rate_for_instance(fierce_id)
	_expect(high_rate > low_rate, "higher-level pet should earn more idle experience")
	_expect(low_rate > fierce_rate, "nature should modify idle experience at the same level")

	var ranch: Control = load("res://src/ui/scenes/ranch_hub.tscn").instantiate()
	root.add_child(ranch)
	ranch.init()
	ranch.call("_select_slot", 1)
	ranch.call("_sync_gui")
	var selected_level := ranch.get_node("Pages/RanchPage/Slots/Slot2/Level") as Label
	var selected_exp := ranch.get_node("Pages/RanchPage/Slots/Slot2/Status") as Label
	var normal_level := ranch.get_node("Pages/RanchPage/Slots/Slot1/Level") as Label
	var normal_exp := ranch.get_node("Pages/RanchPage/Slots/Slot1/Status") as Label
	_expect(selected_level.get_theme_constant("outline_size") >= 4, "selected slot level should gain a strong outline")
	_expect(selected_exp.get_theme_constant("outline_size") >= 4, "selected slot EXP UI should gain a strong outline")
	_expect(normal_level.get_theme_constant("outline_size") < selected_level.get_theme_constant("outline_size"), "unselected level should keep the normal outline")
	_expect(normal_exp.get_theme_constant("outline_size") < selected_exp.get_theme_constant("outline_size"), "unselected EXP UI should keep the normal outline")
	_expect(selected_exp.text == "EXP +%d/h" % roundi(high_rate * 12.0), "displayed hourly EXP should match the actual idle rate")
	ranch.queue_free()
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchSelectionIdleRate] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchSelectionIdleRate] " + failure)
	quit(1)

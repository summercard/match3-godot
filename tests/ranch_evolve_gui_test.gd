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
	var starter: Dictionary = save_manager.add_monster_instance("monster_002", {"level": 1, "nature": "brave", "source": "test"})
	var instance_id := str(starter.get("instanceId", ""))
	var evolution: Dictionary = MonsterDb.get_monster("monster_002").get("evolution", {})
	var target_id := str(evolution.get("target", ""))
	var required_level := int(evolution.get("level", 1))

	var ranch: Control = load("res://src/ui/scenes/ranch_hub.tscn").instantiate()
	root.add_child(ranch)
	ranch.init({"page": "classroom"})
	ranch.set("_class_selected_instance_id", instance_id)
	ranch.call("_sync_gui")
	var evolve := ranch.get_node("Pages/ClassroomPage/DetailPanel/EvolveButton") as TextureButton
	var upgrade := ranch.get_node("Pages/ClassroomPage/DetailPanel/UpgradeButton") as TextureButton
	_expect(not evolve.disabled and not upgrade.disabled, "classroom actions should stay tappable to explain their state")
	_expect((ranch.get_node("Pages/ClassroomPage/DetailPanel/MonsterExpBar") as ProgressBar).visible, "classroom should expose the individual growth bar")
	_expect((ranch.get_node("Pages/ClassroomPage/DetailPanel/PoolBar") as ProgressBar).visible, "classroom should expose the shared growth pool")
	evolve.pressed.emit()
	_expect(str(ranch.get("_status_text")).contains("Lv.%d" % required_level), "low-level evolution should explain the required level")

	save_manager.update_monster_instance(instance_id, {"level": required_level})
	save_manager.add_item("evolution_stone_grass", 1)
	save_manager.add_gold(3000)
	ranch.call("_load_data")
	ranch.set("_class_selected_instance_id", instance_id)
	ranch.call("_sync_gui")
	evolve.pressed.emit()
	var evolved: Dictionary = save_manager.get_monster_instance(instance_id)
	_expect(str(evolved.get("monsterId", "")) == target_id, "classroom evolution should use the current monster evolution target")
	_expect(save_manager.get_item_count("evolution_stone_grass") == 0, "successful evolution should consume one current element stone")
	_expect(int(save_manager.get_player().get("gold", -1)) == 0, "successful first-stage evolution should consume 3000 gold")
	_expect(str(ranch.get("_status_text")).begins_with("进化成功"), "successful evolution should show confirmation feedback")
	_expect(int(evolved.get("evolutionCount", 0)) == 1, "successful evolution should record its growth history")

	ranch.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchEvolveGui] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchEvolveGui] " + failure)
	quit(1)

extends SceneTree

var _failures: Array[String] = []

class FailingEvolutionStorage extends Node:
	var item_count: int = 1
	var instance := {"instanceId": "failure_case", "monsterId": "monster_001", "level": 16, "nature": "brave"}

	func get_monster_instance(_instance_id: String) -> Dictionary:
		return instance

	func get_item_count(_item_id: String) -> int:
		return item_count

	func use_item(_item_id: String, count: int) -> bool:
		item_count -= count
		return true

	func add_item(_item_id: String, count: int) -> bool:
		item_count += count
		return true

	func evolve_instance(_instance_id: String) -> Dictionary:
		return {"ok": false, "reason": "test_failure"}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		_finish()
		return

	save_manager.clear_all_data()
	var instance: Dictionary = save_manager.add_monster_instance("monster_001", {"level": 3, "nature": "brave", "source": "test"})
	var instance_id := str(instance.get("instanceId", ""))
	_expect(save_manager.place_instance_in_ranch(instance_id, 0), "test monster should enter ranch")

	var ranch: Control = load("res://src/ui/scenes/ranch_hub.tscn").instantiate()
	root.add_child(ranch)
	ranch.init()
	ranch.call("_switch_to_classroom")
	ranch.set("_class_selected_instance_id", instance_id)
	ranch.call("_sync_gui")
	var evolve := ranch.get_node("Pages/ClassroomPage/DetailPanel/EvolveButton") as TextureButton
	var frame := evolve.get_node("Frame") as TextureRect

	_expect(not evolve.disabled, "unavailable evolution button should remain tappable for feedback")
	_expect(_texture_path(frame).ends_with("ui_btn_secondary_blue.png"), "unavailable evolution should use the blue secondary visual")
	evolve.pressed.emit()
	_expect(str(ranch.get("_status_text")) == "需要 Lv.16", "low level tap should state the required level")
	_expect(not (ranch.get_node("Header/Status") as Label).visible, "classroom feedback should not overlap the detail-panel header")
	_expect((ranch.get_node("Pages/ClassroomPage/Ribbon/RibbonText") as Label).text == "需要 Lv.16", "classroom feedback should appear in its formal ribbon")

	save_manager.update_monster_instance(instance_id, {"level": 16})
	ranch.call("_load_data")
	ranch.call("_sync_gui")
	_expect(_texture_path(frame).ends_with("ui_btn_secondary_blue.png"), "missing-item state should remain visually inactive")
	evolve.pressed.emit()
	_expect(str(ranch.get("_status_text")).contains("不足"), "missing-item tap should explain the unavailable material")

	save_manager.add_item("evolution_stone_fire", 1)
	ranch.call("_load_data")
	ranch.call("_sync_gui")
	_expect(_texture_path(frame).ends_with("ui_btn_collect_gold.png"), "ready evolution should use the gold action visual")
	evolve.pressed.emit()
	var evolved: Dictionary = save_manager.get_monster_instance(instance_id)
	_expect(str(evolved.get("monsterId", "")) == "monster_006", "GUI evolve action should update the monster")
	_expect(save_manager.get_item_count("evolution_stone_fire") == 0, "successful evolution should consume one material")
	_expect(str(ranch.get("_status_text")).begins_with("进化成功"), "successful evolution should show confirmation feedback")

	var failing_storage := FailingEvolutionStorage.new()
	ranch.add_child(failing_storage)
	ranch.set("_storage", failing_storage)
	ranch.set("_class_selected_instance_id", "failure_case")
	ranch.call("_sync_gui")
	evolve.pressed.emit()
	_expect(failing_storage.item_count == 1, "failed evolution should refund its consumed material")
	_expect(str(ranch.get("_status_text")).begins_with("进化失败"), "failed evolution should show failure feedback")

	ranch.queue_free()
	await process_frame
	_finish()

func _texture_path(frame: TextureRect) -> String:
	return frame.texture.resource_path if frame.texture != null else ""

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchEvolveGui] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[RanchEvolveGui] " + failure)
	quit(1)

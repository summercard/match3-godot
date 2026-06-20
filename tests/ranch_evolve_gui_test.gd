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
	var upgrade := ranch.get_node("Pages/ClassroomPage/DetailPanel/UpgradeButton") as TextureButton
	var frame := evolve.get_node("Frame") as TextureRect
	var authored_art := evolve.get_node("butter02") as CanvasItem

	_expect(not evolve.disabled, "unavailable evolution button should remain tappable for feedback")
	_expect(not frame.visible, "classroom evolution should hide the legacy texture frame")
	_expect(not evolve.has_node("ModernFrame"), "evolution should not overlay generated code UI")
	_expect(authored_art.modulate.a < 1.0, "unavailable evolution should tint the authored art")
	_expect(not (ranch.get_node("Pages/ClassroomPage/DetailPanel/TargetPortrait") as TextureRect).visible, "classroom should remove the evolution preview portrait")
	_expect(ranch.has_node("Pages/ClassroomPage/DetailPanel/MonsterExpBar"), "classroom should show the selected monster exp bar")
	_expect(ranch.has_node("Pages/ClassroomPage/DetailPanel/PoolBar"), "classroom should show the shared exp pool")
	_expect(not upgrade.disabled, "upgrade action should remain tappable for empty-pool feedback")
	upgrade.pressed.emit()
	_expect(str(ranch.get("_status_text")) == "共享经验槽为空", "empty upgrade should explain the shared pool state")
	save_manager.add_shared_monster_exp(110)
	ranch.call("_sync_gui")
	upgrade.pressed.emit()
	_expect(int(save_manager.get_monster_instance(instance_id).get("level", 1)) == 4, "upgrade should consume shared exp and raise one level")
	_expect(save_manager.get_shared_monster_exp() == 0, "upgrade should consume only the exp needed for the next level")
	_expect((ranch.get_node("Pages/ClassroomPage/DetailPanel/UpgradeFeedback") as Control).visible, "upgrade should immediately show authored success feedback")
	for _frame in 90:
		await process_frame
	_expect(not (ranch.get_node("Pages/ClassroomPage/DetailPanel/UpgradeFeedback") as Control).visible, "upgrade feedback should finish cleanly")
	_expect((ranch.get_node("Pages/ClassroomPage/DetailPanel/Info") as Label).text.begins_with("Lv.4"), "classroom detail should refresh to the new level")
	_expect((ranch.get_node("Pages/ClassroomPage/DetailPanel/MonsterExpText") as Label).text == "当前经验 0 / 120", "monster exp text should settle on the latest post-level values")
	_expect(is_zero_approx((ranch.get_node("Pages/ClassroomPage/DetailPanel/MonsterExpBar") as ProgressBar).value), "monster exp bar should settle on the latest post-level value")
	evolve.pressed.emit()
	_expect(str(ranch.get("_status_text")) == "需要 Lv.16", "low level tap should state the required level")
	_expect(not (ranch.get_node("Header/Status") as Label).visible, "classroom feedback should not overlap the detail-panel header")
	_expect((ranch.get_node("Pages/ClassroomPage/Ribbon/RibbonText") as Label).text == "需要 Lv.16", "classroom feedback should appear in its formal ribbon")

	save_manager.update_monster_instance(instance_id, {"level": 16})
	ranch.call("_load_data")
	ranch.call("_sync_gui")
	_expect(authored_art.modulate.a < 1.0, "missing-item state should keep the authored art inactive")
	evolve.pressed.emit()
	_expect(str(ranch.get("_status_text")).contains("不足"), "missing-item tap should explain the unavailable material")

	save_manager.add_item("evolution_stone_fire", 1)
	ranch.call("_load_data")
	ranch.call("_sync_gui")
	_expect(authored_art.modulate.is_equal_approx(Color.WHITE), "ready evolution should show the authored art without an overlay")
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

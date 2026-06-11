extends SceneTree

const SceneResultScript = preload("res://src/ui/controllers/result_logic.gd")

var _failures: Array[String] = []


class MockStorage:
	extends Node

	var inventory: Dictionary = {}
	var settings: Dictionary = {"autoCapture": false, "equippedItem": ""}
	var player: Dictionary = {"captureFails": 0}

	func load_inventory() -> Dictionary:
		return inventory.duplicate(true)

	func use_item(item_id: String, count: int = 1) -> bool:
		if int(inventory.get(item_id, 0)) < count:
			return false
		inventory[item_id] = int(inventory.get(item_id, 0)) - count
		if int(inventory.get(item_id, 0)) <= 0:
			inventory.erase(item_id)
		return true

	func load_capture_settings() -> Dictionary:
		return settings.duplicate(true)

	func load_player() -> Dictionary:
		return player.duplicate(true)

	func save_player(next_player: Dictionary) -> bool:
		player = next_player.duplicate(true)
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_auto_off_skips_without_consuming()
	_test_auto_on_requires_selected_ball()
	_test_selected_ball_is_consumed_exactly()
	_finish()


func _test_auto_off_skips_without_consuming() -> void:
	var storage := MockStorage.new()
	storage.inventory = {"capture_ball_plus": 2}
	storage.settings = {"autoCapture": false, "equippedItem": "capture_ball_plus"}
	var scene: Control = _make_result_scene(storage)
	scene.call("_process_capture")
	_expect(int(storage.inventory.get("capture_ball_plus", 0)) == 2, "auto off should not consume selected capture ball")
	_expect(str(scene.get("_capture_result").get("skip_reason", "")) == "auto_off", "auto off should produce skip result")
	scene.queue_free()
	storage.queue_free()


func _test_auto_on_requires_selected_ball() -> void:
	var storage := MockStorage.new()
	storage.inventory = {"capture_ball": 3}
	storage.settings = {"autoCapture": true, "equippedItem": ""}
	var scene: Control = _make_result_scene(storage)
	scene.call("_process_capture")
	_expect(int(storage.inventory.get("capture_ball", 0)) == 3, "auto capture without selected ball should not consume anything")
	_expect(str(scene.get("_capture_result").get("skip_reason", "")) == "no_item", "auto capture should require a selected capture ball")
	scene.queue_free()
	storage.queue_free()


func _test_selected_ball_is_consumed_exactly() -> void:
	var storage := MockStorage.new()
	storage.inventory = {"capture_ball": 5, "capture_ball_plus": 2}
	storage.settings = {"autoCapture": true, "equippedItem": "capture_ball_plus"}
	var scene: Control = _make_result_scene(storage)
	scene.call("_process_capture")
	var item_used: Dictionary = scene.get("_capture_item_used")
	_expect(str(item_used.get("id", "")) == "capture_ball_plus", "result capture should consume the selected ball")
	_expect(int(storage.inventory.get("capture_ball_plus", 0)) == 1, "selected capture ball should decrease by one")
	_expect(int(storage.inventory.get("capture_ball", 0)) == 5, "unselected capture balls should remain untouched")
	scene.queue_free()
	storage.queue_free()


func _make_result_scene(storage: MockStorage) -> Control:
	var scene: Control = SceneResultScript.new()
	root.add_child(scene)
	scene.set("_storage", storage)
	scene.set("_battle_result", {
		"stageId": "stage_1_2",
		"playerLevel": 5,
		"enemyLevel": 5,
		"enemies": [
			{"id": "monster_001", "name": "火苗兽", "hp": 20, "maxHP": 100, "rarity": 1, "element": "fire"}
		]
	})
	return scene


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CaptureAutoItem] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[CaptureAutoItem] " + failure)
		quit(1)

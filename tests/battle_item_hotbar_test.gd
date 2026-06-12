extends SceneTree

class FakeStorage:
	extends Node
	var inventory: Dictionary = {}
	var settings: Dictionary = {"autoCapture": false, "equippedItem": "", "equippedBattleItems": []}

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

	func save_capture_settings(next_settings: Dictionary) -> bool:
		settings = next_settings.duplicate(true)
		return true

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://src/ui/scenes/battle_screen.tscn").instantiate() as Control
	root.add_child(scene)
	await process_frame
	var stage_db = load("res://src/data/stage_db.gd").new()
	scene.call("init", {
		"stageId": "stage_10_6",
		"stageData": stage_db.get_stage("stage_10_6"),
		"inputTestOnly": true,
	})
	await process_frame

	var storage := FakeStorage.new()
	root.add_child(storage)
	scene.set("_storage", storage)

	_test_equipped_items_drive_hotbar(scene, storage)
	_test_capture_slots_are_passive(scene, storage)
	_test_tap_opens_confirm_before_use(scene, storage)
	_test_confirm_popup_blocks_board_selection(scene, storage)
	_test_rock_hammer_confirm_button_clears_obstacle(scene, storage)
	_test_heal_consumes_item(scene, storage)
	_test_rock_hammer_clears_obstacle(scene, storage)
	_test_rock_hammer_only_clears_one_obstacle(scene, storage)
	_test_advanced_rock_hammer_clears_all_obstacles(scene, storage)
	_test_missing_inventory_blocks_effect(scene, storage)

	scene.queue_free()
	storage.queue_free()
	await process_frame
	_finish()

func _test_equipped_items_drive_hotbar(scene: Control, storage: FakeStorage) -> void:
	storage.inventory = {
		"capture_ball_plus": 9,
		"hp_potion_large": 2,
		"guard_charm": 1,
		"rock_hammer": 1,
		"mist_cleanser": 1,
	}
	storage.settings = {"autoCapture": true, "equippedItem": "capture_ball_plus", "equippedBattleItems": ["hp_potion_large", "guard_charm", "rock_hammer", "mist_cleanser"]}
	scene.call("_load_capture_preferences")
	scene.call("_load_hotbar_items")
	var hotbar: Array = scene.get("_hotbar_items")
	_expect(hotbar.size() == 3, "battle hotbar should expose exactly three equipped active items")
	_expect(str(hotbar[0].get("id", "")) == "hp_potion_large", "first equipped battle item should keep slot order")
	_expect(str(hotbar[1].get("id", "")) == "guard_charm", "second equipped battle item should keep slot order")
	_expect(str(hotbar[2].get("id", "")) == "rock_hammer", "third equipped battle item should keep slot order")
	var capture_slots: Array = scene.get("_capture_slot_items")
	_expect(capture_slots.size() == 1 and str(capture_slots[0].get("id", "")) == "capture_ball_plus", "capture ball slots should stay separate from active item hotbar")

func _test_capture_slots_are_passive(scene: Control, storage: FakeStorage) -> void:
	storage.inventory = {"capture_ball": 2, "capture_ball_plus": 1, "hp_potion_large": 1}
	storage.settings = {"autoCapture": false, "equippedItem": "", "equippedBattleItems": ["hp_potion_large"]}
	scene.call("_load_capture_preferences")
	scene.call("_load_hotbar_items")
	var board = scene.get("_board")
	var bottom_y: float = float(board.offset_y + board.rows * board.cell_size + 7.0)
	var rect: Rect2 = scene.call("_get_capture_item_slot_rect", bottom_y, 0)
	scene.set("_pending_hotbar_slot", -1)
	scene.call("_try_tap_hotbar", rect.get_center().x, rect.get_center().y)
	_expect(str(storage.settings.get("equippedItem", "")) == "capture_ball", "capture slot tap should activate the ball")
	_expect(int(storage.inventory.get("capture_ball", 0)) == 2, "capture slot tap should not consume passive ball")
	_expect(int(scene.get("_pending_hotbar_slot")) == -1, "capture slot tap should not open active item confirm")

func _test_tap_opens_confirm_before_use(scene: Control, storage: FakeStorage) -> void:
	var battle = scene.get("_battle")
	var first: Dictionary = battle.player_team[0]
	first["hp"] = maxi(1, int(int(first.get("maxHP", 100)) / 4))
	var before_hp := int(first.get("hp", 0))
	storage.inventory = {"hp_potion_large": 1}
	var hotbar: Array[Dictionary] = [{"id": "hp_potion_large", "count": 1, "rarity": 2, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.set("_pending_hotbar_slot", -1)
	var board = scene.get("_board")
	var bottom_y: float = float(board.offset_y + board.rows * board.cell_size + 7.0)
	var rect: Rect2 = scene.call("_get_hotbar_slot_rect", bottom_y, 0)
	scene.call("_try_tap_hotbar", rect.get_center().x, rect.get_center().y)
	_expect(int(scene.get("_pending_hotbar_slot")) == 0, "tap should open the item use confirmation")
	_expect(int(first.get("hp", 0)) == before_hp, "tap should not consume or apply an active item before confirmation")
	_expect(storage.inventory.has("hp_potion_large"), "tap should not consume item before confirmation")
	if scene.has_node("ItemConfirmLayer"):
		scene.call("_sync_gui")
		_expect((scene.get_node("ItemConfirmLayer") as Control).visible, "item confirm popup should become visible")
	scene.call("_cancel_hotbar_item_confirm")

func _test_confirm_popup_blocks_board_selection(scene: Control, storage: FakeStorage) -> void:
	storage.inventory = {"rock_hammer": 1}
	var hotbar: Array[Dictionary] = [{"id": "rock_hammer", "count": 1, "rarity": 2, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.set("_pending_hotbar_slot", 0)
	scene.set("_selected_gem", Vector2i(-1, -1))
	var board = scene.get("_board")
	var board_point := Vector2(float(board.offset_x) + 7.5 * float(board.cell_size), float(board.offset_y) + 0.5 * float(board.cell_size))
	scene.call("_on_tap", board_point.x, board_point.y)
	_expect(scene.get("_selected_gem") == Vector2i(-1, -1), "open item confirm popup should block board selection")
	_expect(int(scene.get("_pending_hotbar_slot")) == 0, "clicking board behind popup should keep item confirm open")
	scene.call("_cancel_hotbar_item_confirm")

func _test_rock_hammer_confirm_button_clears_obstacle(scene: Control, storage: FakeStorage) -> void:
	var board = scene.get("_board")
	board.set_obstacles([{"row": 1, "col": 1, "type": "rock", "hp": 1}])
	board.init_board()
	storage.inventory = {"rock_hammer": 1}
	var hotbar: Array[Dictionary] = [{"id": "rock_hammer", "count": 1, "rarity": 2, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.set("_pending_hotbar_slot", 0)
	scene.set("_selected_gem", Vector2i(-1, -1))
	var use_rect: Rect2 = scene.call("_item_confirm_use_rect")
	scene.call("_on_tap", use_rect.get_center().x, use_rect.get_center().y)
	_expect(not board.is_obstacle(1, 1), "rock hammer confirm button should remove a weak rock obstacle")
	_expect(not storage.inventory.has("rock_hammer"), "rock hammer confirm button should consume the item")
	_expect(scene.get("_selected_gem") == Vector2i(-1, -1), "rock hammer confirm click should not select the board")

func _test_heal_consumes_item(scene: Control, storage: FakeStorage) -> void:
	var battle = scene.get("_battle")
	var first: Dictionary = battle.player_team[0]
	first["hp"] = maxi(1, int(int(first.get("maxHP", 100)) / 4))
	var before_hp := int(first.get("hp", 0))
	storage.inventory = {"hp_potion_large": 1}
	var hotbar: Array[Dictionary] = [{"id": "hp_potion_large", "count": 1, "rarity": 2, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.call("_try_use_item_at_slot", 0)
	_expect(int(first.get("hp", 0)) > before_hp, "large HP potion should heal the team")
	_expect(not storage.inventory.has("hp_potion_large"), "large HP potion should be consumed")

func _test_rock_hammer_clears_obstacle(scene: Control, storage: FakeStorage) -> void:
	var board = scene.get("_board")
	board.set_obstacles([{"row": 1, "col": 1, "type": "rock", "hp": 1}])
	board.init_board()
	storage.inventory = {"rock_hammer": 1}
	var hotbar: Array[Dictionary] = [{"id": "rock_hammer", "count": 1, "rarity": 2, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.call("_try_use_item_at_slot", 0)
	_expect(not board.is_obstacle(1, 1), "rock hammer should remove a weak rock obstacle")
	_expect(not storage.inventory.has("rock_hammer"), "rock hammer should be consumed")

func _test_rock_hammer_only_clears_one_obstacle(scene: Control, storage: FakeStorage) -> void:
	var board = scene.get("_board")
	board.set_obstacles([
		{"row": 1, "col": 1, "type": "rock", "hp": 1},
		{"row": 1, "col": 2, "type": "rock", "hp": 1},
	])
	board.init_board()
	storage.inventory = {"rock_hammer": 1}
	var hotbar: Array[Dictionary] = [{"id": "rock_hammer", "count": 1, "rarity": 2, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.call("_try_use_item_at_slot", 0)
	_expect(not board.is_obstacle(1, 1), "rock hammer should remove the first weak rock obstacle")
	_expect(board.is_obstacle(1, 2), "rock hammer should leave additional rock obstacles intact")
	_expect(not storage.inventory.has("rock_hammer"), "single-target rock hammer should be consumed")

func _test_advanced_rock_hammer_clears_all_obstacles(scene: Control, storage: FakeStorage) -> void:
	var board = scene.get("_board")
	board.set_obstacles([
		{"row": 2, "col": 1, "type": "rock", "hp": 1},
		{"row": 2, "col": 2, "type": "rock", "hp": 1},
	])
	board.init_board()
	storage.inventory = {"rock_hammer_plus": 1}
	var hotbar: Array[Dictionary] = [{"id": "rock_hammer_plus", "count": 1, "rarity": 3, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.call("_try_use_item_at_slot", 0)
	_expect(not board.is_obstacle(2, 1), "advanced rock hammer should remove the first weak rock obstacle")
	_expect(not board.is_obstacle(2, 2), "advanced rock hammer should remove every weak rock obstacle")
	_expect(not storage.inventory.has("rock_hammer_plus"), "advanced rock hammer should be consumed")

func _test_missing_inventory_blocks_effect(scene: Control, storage: FakeStorage) -> void:
	var board = scene.get("_board")
	board.set_obstacles([{"row": 2, "col": 2, "type": "rock", "hp": 1}])
	board.init_board()
	storage.inventory = {}
	var hotbar: Array[Dictionary] = [{"id": "rock_hammer", "count": 1, "rarity": 2, "type": "battle"}]
	scene.set("_hotbar_items", hotbar)
	scene.call("_try_use_item_at_slot", 0)
	_expect(board.is_obstacle(2, 2), "missing inventory should block hotbar item effect")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleItemHotbar] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleItemHotbar] " + failure)
	quit(1)

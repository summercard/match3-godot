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
	player["level"] = 3
	storage.save_player(player)
	_expect(storage.get_shared_monster_exp_capacity() == 2500, "shared exp capacity should scale with player level")
	var added: Dictionary = storage.add_shared_monster_exp(2600)
	_expect(int(added.get("added", 0)) == 2500, "shared exp should stop at capacity")
	_expect(int(added.get("overflow", 0)) == 100, "shared exp should report overflow")
	var monster: Dictionary = storage.add_monster_instance("monster_001", {"level": 1, "exp": 0, "source": "shared_exp_test"})
	var instance_id := str(monster.get("instanceId", ""))
	var result: Dictionary = storage.feed_instance_from_shared_exp(instance_id)
	_expect(bool(result.get("leveledUp", false)), "feeding should level the monster once")
	_expect(int(result.get("consumed", 0)) == 90, "level one should consume exactly the next-level requirement")
	_expect(storage.get_shared_monster_exp() == 2410, "unused shared exp should remain in the pool")
	storage.consume_shared_monster_exp(999999)
	storage.add_item("exp_potion", 1)
	var inventory_scene: Control = load("res://src/ui/controllers/inventory_logic.gd").new()
	root.add_child(inventory_scene)
	inventory_scene.set("_storage", storage)
	inventory_scene.call("_use_item", "exp_potion")
	_expect(storage.get_shared_monster_exp() == 100, "experience potion should add to the shared monster exp pool")
	_expect(storage.get_item_count("exp_potion") == 0, "experience potion should be consumed")
	inventory_scene.queue_free()
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[SharedMonsterExp] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SharedMonsterExp] " + failure)
	quit(1)

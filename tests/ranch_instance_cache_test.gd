extends SceneTree

class CountingStorage:
	extends Node
	var instance_reads := 0
	var level_reads := 0
	var care_reads := 0

	func get_monster_instance(_instance_id: String) -> Dictionary:
		instance_reads += 1
		return {}

	func get_instance_level(_instance_id: String) -> int:
		level_reads += 1
		return 1

	func get_ranch_care_state(instance_id: String) -> Dictionary:
		care_reads += 1
		return {"rate": 10.0, "label": instance_id}

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ranch: Control = load("res://src/ui/controllers/ranch_logic.gd").new()
	root.add_child(ranch)
	var storage := CountingStorage.new()
	root.add_child(storage)
	ranch.set("_storage", storage)

	var owned: Array = []
	for i in 500:
		owned.append({
			"instanceId": "cache_%03d" % i,
			"monsterId": "monster_001",
			"level": i % 50 + 1,
			"nature": "",
		})
	ranch.set("_captured_monsters", owned)
	ranch.call("_rebuild_instance_index")

	for _pass in 100:
		for i in 6:
			var instance_id := "cache_%03d" % i
			ranch.call("_get_monster_id", instance_id)
			ranch.call("_get_monster_level", instance_id)
			ranch.call("_get_instance", instance_id)
	_expect(storage.instance_reads == 0, "indexed card refresh must not reread the monster pool")
	_expect(storage.level_reads == 0, "indexed card refresh must not reread instance levels")

	var now := Time.get_unix_time_from_system() * 1000.0
	var slots: Array = []
	for i in 5:
		slots.append({"instance_id": "cache_%03d" % i, "placed_at": now - 600000.0})
	ranch.set("_slots_data", slots)
	ranch.set("_care_state_map", {})
	ranch.call("_calc_idle_exp")
	ranch.call("_calc_idle_exp")
	_expect(storage.care_reads == 5, "care state should be read once per occupied slot, not once per timer tick")

	ranch.queue_free()
	storage.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[RanchInstanceCache] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchInstanceCache] " + failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

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
	var now_ms := Time.get_unix_time_from_system() * 1000.0
	var player: Dictionary = storage.get_player()
	player["stamina"] = 0
	player["staminaUpdatedAt"] = now_ms - 12.0 * 60.0 * 60.0 * 1000.0
	storage.save_player(player)
	_expect(int(storage.get_player().get("stamina", -1)) == 2, "stamina should recover 1 point every 6 hours")

	player = storage.get_player()
	player["stamina"] = 4
	player["staminaUpdatedAt"] = now_ms - 60.0 * 60.0 * 60.0 * 1000.0
	storage.save_player(player)
	_expect(int(storage.get_player().get("stamina", -1)) == 5, "stamina recovery should cap at 5")

	player = storage.get_player()
	player["gold"] = 0
	player["exp"] = 0
	player["stamina"] = 1
	player["staminaUpdatedAt"] = Time.get_unix_time_from_system() * 1000.0
	storage.save_player(player)
	storage.save_stage_stars("stage_1_1", 3)
	var reward: Dictionary = storage.do_sweep("stage_1_1")
	_expect(not reward.is_empty(), "sweep should run when stamina is available")
	_expect(int(storage.get_player().get("stamina", -1)) == 0, "sweep should consume 1 stamina")
	var gold_after := int(storage.get_player().get("gold", 0))
	var second: Dictionary = storage.do_sweep("stage_1_1")
	_expect(second.is_empty(), "sweep should be blocked when stamina is empty")
	_expect(int(storage.get_player().get("gold", 0)) == gold_after, "blocked sweep should not grant rewards")
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[StaminaSweep] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[StaminaSweep] " + failure)
	quit(1)

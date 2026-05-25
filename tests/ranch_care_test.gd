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
	var low: Dictionary = save_manager.add_monster_instance("monster_001", {"level": 2, "source": "test"})
	var peer: Dictionary = save_manager.add_monster_instance("monster_002", {"level": 5, "source": "test"})
	var high: Dictionary = save_manager.add_monster_instance("monster_003", {"level": 8, "source": "test"})
	var low_id := str(low.get("instanceId", ""))
	var peer_id := str(peer.get("instanceId", ""))
	var high_id := str(high.get("instanceId", ""))

	save_manager.save_team({"leader": high_id, "member1": null, "member2": null})
	_expect(save_manager.place_instance_in_ranch(low_id, 0), "low monster should enter ranch")
	_expect(save_manager.place_instance_in_ranch(peer_id, 1), "peer monster should enter ranch")
	_expect(save_manager.set_ranch_care_focus(low_id), "ranch focus should target placed monster")

	var low_state: Dictionary = save_manager.get_ranch_care_state(low_id)
	_expect(bool(low_state.get("isFocus", false)), "focused monster should expose focus state")
	_expect(float(low_state.get("catchupMultiplier", 1.0)) > 1.0, "focused low monster should receive catchup multiplier")
	_expect(float(low_state.get("companionMultiplier", 1.0)) > 1.0, "focused monster should receive companion bonus")
	_expect(float(low_state.get("rate", 0.0)) > float(low_state.get("baseRate", 0.0)), "focused care rate should exceed base rate")

	var peer_state: Dictionary = save_manager.get_ranch_care_state(peer_id)
	_expect(not bool(peer_state.get("isFocus", false)), "non-focused monster should not be focus")
	_expect(float(peer_state.get("catchupMultiplier", 1.0)) == 1.0, "non-focused monster should not receive focus catchup")
	_expect(float(peer_state.get("companionMultiplier", 1.0)) > 1.0, "non-focused monster should still receive companion bonus")

	var ranch: Dictionary = save_manager.get_ranch_state()
	var slots: Array = ranch.get("slots", [])
	slots[0]["placed_at"] = Time.get_unix_time_from_system() * 1000.0 - 10.0 * 60.0 * 1000.0
	ranch["slots"] = slots
	save_manager.set_ranch_state(ranch)
	var before_exp: int = save_manager.get_instance_exp(low_id)
	var collected: float = save_manager.collect_idle_exp_for_instance(low_id)
	var after_exp: int = save_manager.get_instance_exp(low_id)
	_expect(collected > 0.0, "focused ranch collect should return exp")
	_expect(after_exp > before_exp, "focused ranch collect should add exp")

	ranch = save_manager.get_ranch_state()
	slots = ranch.get("slots", [])
	slots[1]["placed_at"] = Time.get_unix_time_from_system() * 1000.0 - 10.0 * 60.0 * 60.0 * 1000.0
	ranch["slots"] = slots
	save_manager.set_ranch_state(ranch)
	var peer_rate: float = save_manager.get_idle_exp_rate_for_instance(peer_id)
	var capped_collect: float = save_manager.collect_idle_exp_for_instance(peer_id)
	var expected_cap: int = int((8.0 * 60.0 / 5.0) * peer_rate)
	_expect(int(capped_collect) == expected_cap, "ranch idle collect should cap at 8 hours")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RanchCare] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[RanchCare] " + failure)
		quit(1)

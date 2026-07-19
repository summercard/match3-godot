extends SceneTree

const TowerRunControllerScript = preload("res://src/core/tower_run_controller.gd")
const TowerRulesScript = preload("res://src/core/tower_rules.gd")
const TowerRankProviderScript = preload("res://src/core/tower_rank_provider.gd")
const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	TestSceneCleanup.mute_audio_for_test(self)
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist for tower failure flow")
	if storage == null:
		_finish()
		return
	storage.clear_all_data()
	storage.save_stage_stars("stage_5_12", 1)
	var controller := TowerRunControllerScript.new(storage)
	var started := controller.start_new_run()
	_expect(bool(started.get("ok", false)), "tower failure flow should start a run")
	if not bool(started.get("ok", false)):
		_finish()
		return
	var state: Dictionary = started.get("state", {})
	var checkpoint_party: Array = state.get("party_snapshot", []).duplicate(true)
	var stage := TowerRulesScript.current_floor_data(state)
	stage["towerBuffs"] = state.get("buffs", []).duplicate(true)

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("battle", {"stageId": stage.get("id", ""), "stageData": stage, "towerMode": true, "towerState": state})
	await process_frame
	await process_frame
	var battle_scene := main.get_current_scene() as Control
	_expect(battle_scene != null, "tower failure test should enter the shared battle scene")
	if battle_scene != null:
		var battle = battle_scene.get("_battle")
		_expect(battle != null, "tower battle should expose BattleManager")
		if battle != null:
			for index in range(battle.player_team.size()):
				var unit: Dictionary = battle.player_team[index]
				unit["hp"] = 0
				battle.player_team[index] = unit
			battle.highest_player_turn_damage = 777
			battle.enemy_action()
			_expect(battle.battle_result == "lose", "all defeated tower party should produce a loss")
			battle_scene.call("_handle_tower_battle_end")
			await create_timer(0.5).timeout

			var overlay := battle_scene.get("_tower_failure_overlay") as Control
			_expect(overlay != null and is_instance_valid(overlay), "tower loss should open the dedicated failure overlay")
			_expect(not (battle_scene.get_node("BattleEndOverlay") as Control).visible, "tower loss should not show the normal battle settlement overlay")
			if overlay != null and is_instance_valid(overlay):
				_expect((overlay.get_node("Panel/RetryButton") as BaseButton).has_node("CartoonFeedback"), "tower retry button should have press feedback")
				_expect((overlay.get_node("Panel/ReturnButton") as BaseButton).has_node("CartoonFeedback"), "tower return button should have press feedback")

			var saved_after_loss: Dictionary = storage.get_tower_state()
			_expect(int(saved_after_loss.get("highest_floor", -1)) == 0, "a failed floor must not increase the climb leaderboard record")
			_expect(int(saved_after_loss.get("highest_turn_damage", 0)) == 777, "a failed attempt should retain its real burst-damage record")
			_expect((saved_after_loss.get("claimed_failure_rewards", []) as Array).has(1), "first failure at a checkpoint should mark its consolation reward as delivered")
			var consolation_mail_count := 0
			for raw_mail in storage.get_mailbox_state().get("inbox", []):
				if raw_mail is Dictionary and str((raw_mail as Dictionary).get("source", "")) == "tower_consolation":
					consolation_mail_count += 1
			_expect(consolation_mail_count == 1, "first failure should send one consolation reward to the mailbox")
			var burst_entries := TowerRankProviderScript.get_burst_entries("测试者", saved_after_loss)
			var player_burst: Dictionary = burst_entries.filter(func(entry): return bool((entry as Dictionary).get("is_player", false)))[0]
			_expect(int(player_burst.get("damage", 0)) == 777, "burst leaderboard should use the peak earned before defeat")

			if overlay != null and is_instance_valid(overlay):
				(overlay.get_node("Panel/RetryButton") as BaseButton).pressed.emit()
				await process_frame
				await process_frame
				_expect(battle_scene.get("_tower_failure_overlay") == null, "retry should close the tower failure overlay")
				_expect(str(battle_scene.get("_stage_id")) == "tower_floor_001", "retry should restart from the saved checkpoint floor")
				for saved_unit in checkpoint_party:
					if not saved_unit is Dictionary:
						continue
					var saved: Dictionary = saved_unit
					var restored := _find_unit(battle.player_team, str(saved.get("id", "")))
					_expect(not restored.is_empty() and int(restored.get("hp", 0)) == int(saved.get("hp", 0)), "retry should restore every spirit HP from the checkpoint")

			battle.battle_over = true
			battle.battle_result = "draw"
			battle_scene.call("_handle_tower_battle_end")
			await create_timer(0.5).timeout
			var timeout_overlay := battle_scene.get("_tower_failure_overlay") as Control
			_expect(timeout_overlay != null and is_instance_valid(timeout_overlay), "turn-limit draw should also open the tower failure overlay")
			if timeout_overlay != null and is_instance_valid(timeout_overlay):
				_expect((timeout_overlay.get_node("Panel/ReasonLabel") as Label).text == "本波回合已经用完啦", "tower failure overlay should explain a turn-limit draw")
				_expect((timeout_overlay.get_node("Panel/RewardCards") as Control).visible == false, "repeated failure at one checkpoint should not create a duplicate consolation reward")
				(timeout_overlay.get_node("Panel/ReturnButton") as BaseButton).pressed.emit()
				await create_timer(0.8).timeout
				_expect(main.get_current_scene_name() == "tower", "return button should route back to the tower page")

	await _cleanup_runtime(main)
	_finish()


func _find_unit(team: Array, unit_id: String) -> Dictionary:
	for raw_unit in team:
		if raw_unit is Dictionary and str((raw_unit as Dictionary).get("id", "")) == unit_id:
			return raw_unit
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _cleanup_runtime(main: Control) -> void:
	if main != null and is_instance_valid(main):
		root.remove_child(main)
		main.free()
	for _frame in range(4):
		await process_frame


func _finish() -> void:
	if _failures.is_empty():
		print("[TowerFailureFlow] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TowerFailureFlow] " + failure)
	quit(1)

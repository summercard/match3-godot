extends SceneTree

const TowerRunControllerScript = preload("res://src/core/tower_run_controller.gd")
const TowerRulesScript = preload("res://src/core/tower_rules.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist for tower battle flow")
	if storage == null:
		_finish()
		return
	storage.clear_all_data()
	storage.save_stage_stars("stage_5_12", 1)
	var controller := TowerRunControllerScript.new(storage)
	var started := controller.start_new_run()
	_expect(bool(started.get("ok", false)), "tower battle flow should start run")
	if not bool(started.get("ok", false)):
		_finish()
		return
	var state: Dictionary = started.get("state", {})
	var stage := TowerRulesScript.current_floor_data(state)
	stage["towerBuffs"] = state.get("buffs", []).duplicate(true)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("battle", {"stageId": stage.get("id", ""), "stageData": stage, "towerMode": true, "towerState": state})
	await process_frame
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	_expect(main.get_current_scene_name() == "battle", "tower should enter shared battle scene")
	for enemy_group_path in ["Combatants/SingleEnemy", "Combatants/MultiEnemies"]:
		var enemy_group := battle_scene.get_node(enemy_group_path) as Control
		_expect(enemy_group.has_meta("v132_base_y") and is_equal_approx(enemy_group.position.y, float(enemy_group.get_meta("v132_base_y")) - 10.0), "tower %s should move its complete enemy HUD up ten pixels" % enemy_group_path)
	_expect((battle_scene.get_node("Background") as TextureRect).texture.resource_path == "res://assets/images/tower_new/battle/tower_crystal_garden_battle_v1.png", "tower battle should use its dedicated crystal garden background")
	var initial_enemies: Array = battle_scene.get("_battle").get("enemies")
	for raw_enemy in initial_enemies:
		if raw_enemy is Dictionary:
			_expect(is_equal_approx(float((raw_enemy as Dictionary).get("_towerVisualScale", 0.0)), 1.30), "tower enemies should use the 30 percent visual-size boost")
	for expected_floor in range(1, 5):
		await _clear_current_wave(battle_scene)
		await create_timer(0.95).timeout
		_expect(main.get_current_scene_name() == "battle", "normal tower wave should remain in battle scene")
		_expect(str(battle_scene.get("_stage_id")) == "tower_floor_%03d" % (expected_floor + 1), "normal tower wave should advance in place")
	await _clear_current_wave(battle_scene)
	await create_timer(0.65).timeout
	_expect(main.get_current_scene_name() == "battle", "boss clear should keep battle scene for card choice")
	var card_overlay: Control = battle_scene.get("_tower_card_overlay")
	_expect(card_overlay != null and is_instance_valid(card_overlay), "boss clear should show formal card overlay")
	if card_overlay != null and is_instance_valid(card_overlay):
		card_overlay.call("_select_index", 0)
	await create_timer(0.45).timeout
	_expect(str(battle_scene.get("_stage_id")) == "tower_floor_006", "card selection should start next stage in same battle scene")
	var mailbox: Dictionary = storage.get_mailbox_state()
	var found_reward := false
	for raw_mail in mailbox.get("inbox", []):
		if raw_mail is Dictionary and str((raw_mail as Dictionary).get("id", "")) == "tower_reward:tower_s1:5":
			found_reward = true
	_expect(found_reward, "boss reward should be delivered to independent mailbox")
	await _cleanup_runtime(main)
	_finish()


func _clear_current_wave(scene: Control) -> void:
	var battle: Node = scene.get("_battle")
	_expect(battle != null, "tower battle should have BattleManager")
	if battle == null:
		return
	for raw_enemy in battle.get("enemies"):
		if raw_enemy is Dictionary:
			(raw_enemy as Dictionary)["hp"] = 0
	scene.call("_check_battle_end")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _cleanup_runtime(main: Control) -> void:
	if main != null and is_instance_valid(main):
		root.remove_child(main)
		main.free()
	var audio_manager := root.get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		if audio_manager.has_method("stop_bgm"):
			audio_manager.call("stop_bgm")
		var bgm_player: Variant = audio_manager.get("_bgm_player")
		if bgm_player is AudioStreamPlayer:
			(bgm_player as AudioStreamPlayer).stop()
			(bgm_player as AudioStreamPlayer).stream = null
			(bgm_player as AudioStreamPlayer).queue_free()
			audio_manager.set("_bgm_player", null)
		for child in audio_manager.get_children():
			if child is AudioStreamPlayer:
				(child as AudioStreamPlayer).stop()
				(child as AudioStreamPlayer).stream = null
				child.queue_free()
		var cache: Variant = audio_manager.get("_resource_cache")
		if cache is Dictionary:
			(cache as Dictionary).clear()
	for _i in range(5):
		await process_frame


func _finish() -> void:
	if _failures.is_empty():
		print("[TowerBattleFlow] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TowerBattleFlow] " + failure)
	quit(1)

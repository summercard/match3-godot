extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_upcoming_attackers()
	await _test_scene_windup()
	_finish()


func _test_upcoming_attackers() -> void:
	var battle := BattleManagerScript.new()
	# 波次规则：首波 1 只。4 只敌人会分成 1/3 两波，补第二波后才有 3 只在场。
	battle.init(["monster_001", "monster_002", "monster_003"], ["enemy_006", "enemy_007", "enemy_008", "enemy_009"], 5, 9)
	battle.start_next_wave()

	var attackers: Array = battle.get_upcoming_attackers()
	_expect(attackers.size() == 3, "three alive enemies should all be marked as upcoming attackers")
	_expect(attackers == [0, 1, 2], "upcoming attackers should keep enemy order")

	battle.enemies[1]["hp"] = 0
	var after_kill: Array = battle.get_upcoming_attackers()
	_expect(after_kill == [0, 2], "dead enemies should be excluded from the windup")

	battle.battle_over = true
	_expect(battle.get_upcoming_attackers().is_empty(), "battle over should not produce a windup")
	battle.free()


func _test_scene_windup() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# 用 4 只敌人的测试关卡补出 3 只在场，验证三敌人前摇；不修改波次规则。
	var stage_data := {
		"id": "test_windup_stage",
		"name": "前摇测试",
		"type": "normal",
		"enemies": ["enemy_006", "enemy_007", "enemy_008", "enemy_009"],
		"enemyLevel": 9,
		"maxTurns": 20
	}
	main.switch_scene("battle", {
		"stageId": "test_windup_stage",
		"stageData": stage_data,
		"inputTestOnly": true,
	})
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	_expect(battle_scene != null, "battle scene should load")
	if battle_scene == null:
		main.queue_free()
		return
	var battle = battle_scene.get("_battle")
	if battle != null:
		battle.start_next_wave()

	var hp_before: int = _team_hp(battle_scene)
	battle_scene.call("_start_enemy_turn")
	var indices: Array = battle_scene.get("_enemy_windup_indices")
	var total: float = float(battle_scene.get("_enemy_windup_total"))
	var timer: float = float(battle_scene.get("_enemy_windup_timer"))
	_expect(not indices.is_empty(), "enemy turn should start with a windup on upcoming attackers")
	_expect(indices.size() == 3, "windup should mark every alive enemy")
	_expect(total >= 0.4 and total <= 0.8, "windup duration should stay within 0.4-0.8s")
	_expect(timer > 0.0 and timer <= total, "windup timer should be running")
	_expect(_team_hp(battle_scene) == hp_before, "enemy damage should not resolve during the windup")

	var state: Dictionary = battle_scene.call("_combatant_render_state")
	_expect(state.get("enemy_windup_indices", []).size() == 3, "render state should expose windup targets")
	_expect(float(state.get("enemy_windup_total", 0.0)) >= 0.4, "render state should expose windup duration")

	await create_timer(total + 0.15).timeout
	_expect((battle_scene.get("_enemy_windup_indices") as Array).is_empty(), "windup should clear before enemy actions resolve")
	_expect(float(battle_scene.get("_enemy_windup_timer")) == 0.0, "windup timer should reset after the cue")
	_expect(_team_hp(battle_scene) < hp_before, "enemy damage should resolve after the windup")
	main.queue_free()
	await process_frame


func _team_hp(scene: Control) -> int:
	var battle = scene.get("_battle")
	if battle == null:
		return 0
	var total: int = 0
	for monster in battle.player_team:
		if monster != null:
			total += maxi(int(monster.get("hp", 0)), 0)
	return total


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EnemyWindup] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[EnemyWindup] " + failure)
		quit(1)

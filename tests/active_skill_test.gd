extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var stage_db = load("res://src/data/stage_db.gd").new()
	var stage_data: Dictionary = stage_db.get_stage("stage_1_1")
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_data
	})
	await process_frame

	var battle_scene: Control = main.get_current_scene()
	_expect(battle_scene != null, "battle scene should load")
	if battle_scene == null:
		_finish()
		return

	var battle = battle_scene.get("_battle")
	_expect(battle != null, "battle manager should initialize")
	if battle == null:
		_finish()
		return

	var monster: Dictionary = battle.player_team[0]
	var monster_id: String = monster.get("id", "")
	var cost: int = int(monster.get("skill", {}).get("cost", 0))
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	var enemy_hp_before: int = int(battle.enemies[0].get("hp", 0))

	battle.skill_charges[monster_id] = maxi(0, cost - 1)
	var not_ready: Dictionary = battle.use_active_skill(monster_id)
	_expect(not not_ready.get("success", true), "skill should not release before full charge")
	_expect(int(battle.enemies[0].get("hp", 0)) == enemy_hp_before, "not-ready skill should not damage enemy")

	battle.skill_charges[monster_id] = cost
	var result: Dictionary = battle.use_active_skill(monster_id)
	_expect(result.get("success", false), "ready skill should release")
	_expect(int(result.get("damage", 0)) > 0, "ready skill should deal damage")
	_expect(int(battle.skill_charges.get(monster_id, -1)) == 0, "released skill should consume charge")
	_expect(int(battle.enemies[0].get("hp", 0)) < enemy_hp_before, "released skill should reduce enemy hp")

	var enemy_hp_after_direct: int = int(battle.enemies[0].get("hp", 0))
	battle.skill_charges[monster_id] = cost
	var handled: bool = battle_scene.call("_try_use_skill_at_position", Vector2(75.0, 216.0))
	await process_frame
	_expect(handled, "clicking ready player card should be handled as skill use")
	_expect(int(battle.skill_charges.get(monster_id, -1)) == 0, "card skill use should consume charge")
	_expect(int(battle.enemies[0].get("hp", 0)) < enemy_hp_after_direct, "card skill use should damage enemy")

	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[ActiveSkill] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[ActiveSkill] " + failure)
		quit(1)

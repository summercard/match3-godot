extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_expect(main.get_current_scene_name() == "start", "start scene should load")
	
	main.switch_scene("main")
	await process_frame
	_expect(main.get_current_scene_name() == "main", "main scene should load")

	for scene_name: String in ["team", "album", "shop", "inventory", "ranch", "achievement", "settings", "sign_in", "tutorial"]:
		main.switch_scene(scene_name)
		await process_frame
		await process_frame
		_expect(main.get_current_scene_name() == scene_name, "%s scene should load" % scene_name)
	
	var stage_db = load("res://src/data/stage_db.gd").new()
	var stage_data: Dictionary = stage_db.get_stage("stage_1_1")
	_expect(not stage_data.is_empty(), "stage_1_1 should exist")
	
	main.switch_scene("stage_select")
	await process_frame
	_expect(main.get_current_scene_name() == "stage_select", "stage select should load")
	
	main.switch_scene("battle_prepare", {
		"stageId": "stage_1_1",
		"stageData": stage_data,
		"chapterIndex": 0
	})
	await process_frame
	_expect(main.get_current_scene_name() == "battle_prepare", "battle prepare should load")
	
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_data
	})
	await process_frame
	_expect(main.get_current_scene_name() == "battle", "battle scene should load")
	var battle_scene = main.get_current_scene()
	_expect(battle_scene != null and battle_scene.get("_board") != null, "battle board should initialize")
	_expect(battle_scene != null and battle_scene.get("_battle") != null, "battle manager should initialize")
	
	main.switch_scene("result", _mock_battle_result(stage_data))
	await process_frame
	_expect(main.get_current_scene_name() == "result", "result scene should load")
	
	if _failures.is_empty():
		print("[P0Smoke] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[P0Smoke] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _mock_battle_result(stage_data: Dictionary) -> Dictionary:
	return {
		"result": "win",
		"stageId": "stage_1_1",
		"turnCount": 3,
		"maxTurns": 20,
		"playerLevel": 5,
		"enemyLevel": stage_data.get("enemyLevel", 1),
		"stageRewards": stage_data.get("rewards", {}),
		"totalDamageDealt": {"fire": 120},
		"playerTeam": [
			{"id": "monster_001", "name": "小火龙", "hp": 160, "maxHP": 180},
			{"id": "monster_002", "name": "水龟仔", "hp": 170, "maxHP": 200}
		],
		"enemies": [
			{"id": "enemy_001", "name": "训练兽", "emoji": "", "hp": 0, "maxHP": 80, "rarity": 1}
		]
	}

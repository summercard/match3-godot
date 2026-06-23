extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_mute_audio_for_smoke()
	_scan_formal_tscn_resources()

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
	
	await _cleanup_runtime(main)
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

func _mute_audio_for_smoke() -> void:
	var audio_manager := root.get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	if audio_manager.has_method("set_mute"):
		audio_manager.call("set_mute", true)
	if audio_manager.has_method("set_bgm_mute"):
		audio_manager.call("set_bgm_mute", true)

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

func _scan_formal_tscn_resources() -> void:
	var scene_paths: Array = ["res://main.tscn"]
	_collect_tscn_paths("res://src", scene_paths)
	for scene_path: String in scene_paths:
		_scan_tscn_resource_paths(scene_path)

func _collect_tscn_paths(dir_path: String, result: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		_failures.append("formal resource scan should open %s" % dir_path)
		return
	for file_name: String in dir.get_files():
		if file_name.ends_with(".tscn"):
			result.append("%s/%s" % [dir_path, file_name])
	for child_name: String in dir.get_directories():
		if child_name.begins_with("."):
			continue
		_collect_tscn_paths("%s/%s" % [dir_path, child_name], result)

func _scan_tscn_resource_paths(scene_path: String) -> void:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		_failures.append("formal scene should be readable: %s" % scene_path)
		return
	var line_number := 0
	while not file.eof_reached():
		line_number += 1
		var line := file.get_line()
		var res_path := _extract_resource_path(line)
		if res_path.is_empty():
			continue
		if res_path.begins_with("res://.godot/imported") or res_path.begins_with("res://assets/MATCH3美术资产") or res_path.begins_with("res://assets/新美术资产"):
			_failures.append("%s:%d should not reference banned resource path %s" % [scene_path, line_number, res_path])
			continue
		if not ResourceLoader.exists(res_path) and not FileAccess.file_exists(res_path):
			_failures.append("%s:%d missing resource %s" % [scene_path, line_number, res_path])

func _extract_resource_path(line: String) -> String:
	if not line.contains("[ext_resource"):
		return ""
	var marker := "path=\""
	var start := line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	if end < 0:
		return ""
	var path := line.substr(start, end - start)
	return path if path.begins_with("res://") else ""

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

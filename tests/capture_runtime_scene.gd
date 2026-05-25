extends SceneTree

const DEFAULT_OUTPUT := "user://runtime_scene_capture.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene_name := _read_arg("--scene-name=", "stage_select")
	var output_path := _read_arg("--output=", DEFAULT_OUTPUT)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene(scene_name, _scene_data(scene_name))
	await process_frame
	await process_frame
	await process_frame
	_seed_demo_state(main, scene_name)
	await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("[RuntimeCapture] save failed: %s" % error_string(error))
		quit(1)
		return
	print("[RuntimeCapture] logical viewport=%s main=%s window=%s framebuffer=%dx%d" % [
		root.get_visible_rect().size,
		main.size,
		DisplayServer.window_get_size(),
		image.get_width(),
		image.get_height()
	])
	print("[RuntimeCapture] %s -> %s" % [scene_name, ProjectSettings.globalize_path(output_path)])
	quit(0)

func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

func _scene_data(scene_name: String) -> Dictionary:
	if scene_name == "stage_select":
		return {"chapterIndex": int(_read_arg("--chapter-index=", "0"))}
	if scene_name == "battle" or scene_name == "battle_prepare":
		var stage_id := _read_arg("--stage-id=", "stage_1_1")
		var stage_db = load("res://src/data/stage_db.gd").new()
		return {
			"stageId": stage_id,
			"stageData": stage_db.get_stage(stage_id)
		}
	return {}

func _seed_demo_state(main: Control, scene_name: String) -> void:
	if scene_name == "battle":
		_seed_battle_demo_fx(main)
		return
	if scene_name != "team":
		return
	var count := int(_read_arg("--team-demo-count=", "0"))
	if count <= 0:
		return
	var team_scene := main.get_node_or_null("Team")
	if team_scene == null:
		return
	var roster: Array = []
	for i in range(count):
		var monster_id := "monster_%03d" % ((i % 12) + 1)
		roster.append({
			"instanceId": monster_id if i < 12 else "%s_demo_%02d" % [monster_id, i + 1],
			"monsterId": monster_id,
			"level": 1 + i,
			"nature": ""
		})
	team_scene.set("_captured_monsters", roster)
	team_scene.set("_team", {
		"leader": roster[0].get("instanceId", "") if roster.size() > 0 else null,
		"member1": roster[1].get("instanceId", "") if roster.size() > 1 else null,
		"member2": roster[2].get("instanceId", "") if roster.size() > 2 else null
	})
	team_scene.set("_roster_page", int(_read_arg("--team-demo-page=", "0")))
	team_scene.call("_clamp_roster_page")
	team_scene.queue_redraw()

func _seed_battle_demo_fx(main: Control) -> void:
	var battle_scene: Control = main.get_current_scene() if main.has_method("get_current_scene") else null
	if battle_scene == null:
		return
	if _read_arg("--battle-art-aspect-qa=", "0") == "1":
		_seed_battle_art_aspect_qa(battle_scene)
	if _read_arg("--battle-demo-fx=", "0") != "1":
		battle_scene.queue_redraw()
		return
	battle_scene.set("_message_text", "效果拔群!")
	battle_scene.set("_message_timer", 1.2)
	battle_scene.set("_combo_popup", {
		"combo": 3,
		"timer": 0.18,
		"phase": "peak",
		"scale": 1.12,
		"opacity": 1.0
	})
	var floating_texts: Array[Dictionary] = [
		{"text": "-5687", "x": 248.0, "y": 162.0, "color": Color(1.0, 0.74, 0.10), "size": 23.0, "timer": 0.18, "duration": 1.0, "critical": true},
		{"text": "-243", "x": 128.0, "y": 184.0, "color": Color(0.78, 0.84, 0.92), "size": 15.0, "timer": 0.25, "duration": 1.0},
		{"text": "+340", "x": 282.0, "y": 218.0, "color": Color(0.30, 1.0, 0.45), "size": 16.0, "timer": 0.15, "duration": 1.0}
	]
	var hit_flashes: Array[Dictionary] = [
		{"isEnemy": true, "monsterIndex": 0, "timer": 0.22, "maxTimer": 0.3},
		{"isEnemy": false, "monsterIndex": 1, "timer": 0.24, "maxTimer": 0.35}
	]
	battle_scene.set("_floating_texts", floating_texts)
	battle_scene.set("_hit_flashes", hit_flashes)
	battle_scene.set("_screen_flash_timer", 0.06)
	battle_scene.set("_boss_skill_visuals", {
		0: {
			"shield_hp": 42.0,
			"shield_max_hp": 80.0,
			"charge_timer": 0.8
		}
	})
	battle_scene.queue_redraw()

func _seed_battle_art_aspect_qa(battle_scene: Control) -> void:
	var battle = battle_scene.get("_battle")
	if battle == null:
		return
	var portraits: Array[Dictionary] = [
		{"monsterId": "monster_006", "id": "monster_006", "name": "火恐龙"},
		{"monsterId": "monster_007", "id": "monster_007", "name": "水箭龟"},
		{"monsterId": "monster_017", "id": "monster_017", "name": "暗影猫"}
	]
	for i in range(mini(portraits.size(), battle.player_team.size())):
		for key in portraits[i]:
			battle.player_team[i][key] = portraits[i][key]

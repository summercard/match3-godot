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
	for _frame in range(int(_read_arg("--settle-frames=", "0"))):
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
	if scene_name == "result":
		return {
			"result": "win",
			"stageId": "stage_1_1",
			"turnCount": 5,
			"maxTurns": 20,
			"playerLevel": 5,
			"enemyLevel": 3,
			"stageRewards": {"gold": 80, "exp": 30, "guaranteedItems": [{"id": "capture_ball", "count": 1}]},
			"playerTeam": [
				{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "hp": 20, "maxHP": 20},
				{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 3, "hp": 18, "maxHP": 18},
				{"id": "monster_003", "monsterId": "monster_003", "name": "草苗儿", "level": 5, "hp": 22, "maxHP": 22}
			],
			"enemies": [
				{"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "hp": 0, "maxHP": 16}
			],
			"capture_played_inline": true,
			"captured": true,
			"capture_target": {"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "rarity": 1},
			"capture_result_text": {"title": "收服成功", "reason": "窗口稳定"},
			"capture_item_used": {"name": "捕捉球"},
			"capture_window": {"label": "稳定", "stability": 0.82}
		}
	return {}

func _seed_demo_state(main: Control, scene_name: String) -> void:
	if scene_name == "battle":
		_seed_battle_demo_fx(main)
		return
	if scene_name == "ranch":
		_seed_ranch_demo(main)
		return
	if scene_name == "inventory":
		_seed_inventory_demo(main)
		return
	if scene_name == "shop":
		_seed_shop_demo(main)
		return
	if scene_name == "achievement":
		_seed_achievement_scroll_demo(main)
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

func _seed_ranch_demo(main: Control) -> void:
	if _read_arg("--ranch-demo=", "0") != "1":
		return
	var ranch_scene: Control = main.get_current_scene() if main.has_method("get_current_scene") else main.get_node_or_null("SceneRanch")
	if ranch_scene == null:
		return
	var roster: Array = ranch_scene.get("_captured_monsters")
	if roster.is_empty():
		return
	var visual_roster: Array = []
	var natures := ["brave", "gentle", "cautious"]
	var genders := ["male", "female", "neutral"]
	for i in range(mini(3, roster.size())):
		var monster_id := str(ranch_scene.call("_get_monster_id", roster[i]))
		visual_roster.append({
			"instanceId": monster_id,
			"monsterId": monster_id,
			"level": i + 3,
			"nature": natures[i],
			"gender": genders[i],
		})
	ranch_scene.set("_storage", null)
	ranch_scene.set("_captured_monsters", visual_roster)
	ranch_scene.set("_class_selected_instance_id", str(visual_roster[0].get("instanceId", "")))
	ranch_scene.set("_care_focus_instance_id", str(visual_roster[0].get("instanceId", "")))
	var social_places: Array = ranch_scene.get("_social_places")
	if not social_places.is_empty() and visual_roster.size() >= 2:
		social_places[0]["slot_a"] = str(visual_roster[0].get("instanceId", ""))
		social_places[0]["slot_b"] = str(visual_roster[1].get("instanceId", ""))
		ranch_scene.set("_social_places", social_places)
	var now := Time.get_unix_time_from_system() * 1000.0
	var slots: Array = []
	for i in range(5):
		if i < visual_roster.size():
			slots.append({
				"instance_id": str(visual_roster[i].get("instanceId", "")),
				"placed_at": now - float((i + 1) * 32) * 60.0 * 1000.0
			})
		else:
			slots.append({"instance_id": null, "placed_at": null})
	ranch_scene.set("_slots_data", slots)
	ranch_scene.set("_selected_slot", 0)
	ranch_scene.call("_calc_idle_exp")
	ranch_scene.call("_init_bubbles")
	ranch_scene.call("_update_list_scroll_limit")
	ranch_scene.call("_update_class_scroll_limit")
	var page := _read_arg("--ranch-page=", "ranch")
	if page == "classroom":
		ranch_scene.call("_switch_to_classroom")
	elif page == "social":
		ranch_scene.call("_switch_to_social")
		if _read_arg("--ranch-popup=", "0") == "1":
			ranch_scene.set("_social_result_popup", {
				"label": "社交完成",
				"score": 88,
				"relation_label": "默契",
				"exp_each": 36,
				"gold": 120,
				"summary": "两只精灵在草坪上建立了默契。",
				"tags": ["友好交流", "同伴默契"],
				"event": {
					"name": "追逐花瓣",
					"flavor": "微风卷起花瓣，它们并肩跑过草坡。",
				},
				"majorOutcome": {"type": "none"},
			})
	if ranch_scene.has_method("_sync_gui"):
		ranch_scene.call("_sync_gui")
	else:
		ranch_scene.queue_redraw()

func _seed_inventory_demo(main: Control) -> void:
	var inventory_scene: Control = main.get_current_scene() if main.has_method("get_current_scene") else main.get_node_or_null("InventoryGui")
	if inventory_scene == null:
		return
	inventory_scene.set("_inventory", {
		"capture_ball": 12,
		"capture_ball_plus": 3,
		"exp_potion": 8,
		"exp_crystal": 2,
		"hp_potion": 5,
		"gold_bag": 4,
		"gold_chest": 1,
		"evolution_stone_fire": 2,
		"evolution_stone_water": 2,
		"evolution_stone_grass": 2,
		"evolution_stone_thunder": 1,
		"evolution_stone_light": 1,
		"evolution_stone_earth": 1,
		"evolution_stone_wind": 1,
		"evolution_stone_dark": 1,
	})
	inventory_scene.set("_player", {"gold": 1280, "gems": 36})
	inventory_scene.set("_capture_settings", {"autoCapture": true, "equippedItem": "capture_ball_plus"})
	inventory_scene.set("_active_tab", _read_arg("--inventory-tab=", "all"))
	inventory_scene.set("_selected_item", {})
	inventory_scene.call("_build_item_list")
	if inventory_scene.has_method("_sync_gui"):
		inventory_scene.call("_sync_gui")
	else:
		inventory_scene.queue_redraw()

func _seed_achievement_scroll_demo(main: Control) -> void:
	var achievement_scene: Control = main.get_current_scene() if main.has_method("get_current_scene") else main.get_node_or_null("SceneAchievement")
	if achievement_scene == null:
		return
	var offset := float(_read_arg("--achievement-scroll=", "168"))
	achievement_scene.set("_scroll_offset", offset)
	achievement_scene.queue_redraw()

func _seed_shop_demo(main: Control) -> void:
	var shop_scene: Control = main.get_current_scene() if main.has_method("get_current_scene") else main.get_node_or_null("ShopGui")
	if shop_scene == null:
		return
	shop_scene.set("player_data", {"gold": 5000, "gems": 120})
	shop_scene.set("_active_tab", _read_arg("--shop-tab=", "recommend"))
	if shop_scene.has_method("_sync_gui"):
		shop_scene.call("_sync_gui")
	if _read_arg("--shop-popup=", "0") == "1":
		var items: Array = shop_scene.call("_get_visible_shop_items")
		if not items.is_empty():
			shop_scene.call("_show_purchase_popup", items[0])
	elif _read_arg("--shop-toast=", "0") == "1":
		shop_scene.call("_show_toast", "获得 经验药水 x1", "success")
	else:
		shop_scene.queue_redraw()

func _seed_battle_demo_fx(main: Control) -> void:
	var battle_scene: Control = main.get_current_scene() if main.has_method("get_current_scene") else null
	if battle_scene == null:
		return
	if _read_arg("--battle-art-aspect-qa=", "0") == "1":
		_seed_battle_art_aspect_qa(battle_scene)
	if _read_arg("--battle-demo-hp=", "0") == "1":
		_seed_battle_demo_hp(battle_scene)
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

func _seed_battle_demo_hp(battle_scene: Control) -> void:
	var battle = battle_scene.get("_battle")
	if battle == null:
		return
	for i in range(battle.enemies.size()):
		var enemy: Dictionary = battle.enemies[i]
		var max_hp := maxi(int(enemy.get("maxHP", 1)), 1)
		enemy["hp"] = maxi(int(max_hp * (0.68 - i * 0.20)), 1)
	if battle.player_team.size() > 1:
		var player: Dictionary = battle.player_team[1]
		var max_hp := maxi(int(player.get("maxHP", 1)), 1)
		player["hp"] = maxi(int(max_hp * 0.30), 1)
	if battle_scene.has_method("_sync_gui"):
		battle_scene.call("_sync_gui")

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

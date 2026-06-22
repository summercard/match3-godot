extends SceneTree

const MAIN_SCENE := "res://main.tscn"
const CAPTURE_SIZE := Vector2i(375, 667)
const CASES := [
	{
		"id": "start_default",
		"scene": "start",
		"expected": "res://src/ui/scenes/start_screen.tscn",
		"settle": 10,
	},
	{
		"id": "stage_select_locked",
		"scene": "stage_select",
		"expected": "res://src/ui/scenes/stage_select_map.tscn",
		"settle": 12,
	},
	{
		"id": "battle_default_hotbar",
		"scene": "battle",
		"expected": "res://src/ui/scenes/battle_screen.tscn",
		"settle": 12,
	},
	{
		"id": "settings_confirm_popup",
		"scene": "settings",
		"expected": "res://src/ui/scenes/settings.tscn",
		"settle": 12,
	},
	{
		"id": "achievement_scroll_end",
		"scene": "achievement",
		"expected": "res://src/ui/scenes/achievement.tscn",
		"settle": 12,
	},
	{
		"id": "album_locked_grid",
		"scene": "album",
		"expected": "res://src/ui/scenes/album.tscn",
		"settle": 12,
	},
	{
		"id": "album_selected_detail",
		"scene": "album",
		"expected": "res://src/ui/scenes/album.tscn",
		"settle": 12,
	},
	{
		"id": "inventory_empty",
		"scene": "inventory",
		"expected": "res://src/ui/scenes/inventory.tscn",
		"settle": 12,
	},
	{
		"id": "result_defeat_error",
		"scene": "result",
		"expected": "res://src/ui/scenes/battle_result.tscn",
		"settle": 18,
	},
]

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = CAPTURE_SIZE
	for capture_case: Dictionary in CASES:
		await _capture_case(capture_case)
	_finish()

func _capture_case(capture_case: Dictionary) -> void:
	var main := load(MAIN_SCENE).instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame

	var scene_name := str(capture_case.get("scene", ""))
	var switched := bool(main.call("switch_scene", scene_name, _scene_data(scene_name)))
	_expect(switched, "%s should enter through main.switch_scene" % capture_case.get("id", "case"))
	await process_frame
	await process_frame

	var current := main.call("get_current_scene") as Control
	_expect(current != null, "%s should have a current scene" % capture_case.get("id", "case"))
	if current != null:
		_expect(current.scene_file_path == str(capture_case.get("expected", "")), "%s should use its formal PackedScene path" % capture_case.get("id", "case"))
		await _apply_case_state(str(capture_case.get("id", "")), current)

	for _i in range(int(capture_case.get("settle", 8))):
		await process_frame

	if DisplayServer.get_name() == "headless":
		print("[RuntimeScreenshotGate] %s route/state checked; pixel capture skipped under headless renderer" % capture_case.get("id", "case"))
	else:
		var viewport_texture := root.get_texture()
		if viewport_texture == null:
			_expect(false, "%s should expose a viewport texture for screenshot capture" % capture_case.get("id", "case"))
		else:
			var image := viewport_texture.get_image()
			if image == null:
				_expect(false, "%s should expose a viewport image for screenshot capture" % capture_case.get("id", "case"))
			else:
				_assert_meaningful_image(image, str(capture_case.get("id", "")))
				var output_path := "user://runtime_screenshot_gate_%s.png" % str(capture_case.get("id", "case"))
				var error := image.save_png(output_path)
				_expect(error == OK, "%s should save runtime screenshot: %s" % [capture_case.get("id", "case"), error_string(error)])

	main.queue_free()
	await process_frame

func _scene_data(scene_name: String) -> Dictionary:
	if scene_name == "stage_select":
		return {"chapterIndex": 0}
	if scene_name == "battle":
		var stage_db = load("res://src/data/stage_db.gd").new()
		return {
			"stageId": "stage_1_1",
			"stageData": stage_db.get_stage("stage_1_1"),
			"inputTestOnly": true,
		}
	if scene_name == "result":
		return {
			"result": "lose",
			"stageId": "stage_1_1",
			"turnCount": 20,
			"maxTurns": 20,
			"playerLevel": 5,
			"enemyLevel": 3,
			"stageRewards": {"gold": 0, "exp": 0, "guaranteedItems": []},
			"playerTeam": [
				{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "hp": 0, "maxHP": 20},
				{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 3, "hp": 0, "maxHP": 18},
				{"id": "monster_003", "monsterId": "monster_003", "name": "草苗儿", "level": 5, "hp": 0, "maxHP": 22},
			],
			"enemies": [
				{"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "hp": 8, "maxHP": 16},
			],
			"captured": false,
			"capture_played_inline": false,
			"capture_result_text": {"title": "挑战失败", "reason": "回合耗尽"},
		}
	return {}

func _apply_case_state(case_id: String, scene: Control) -> void:
	match case_id:
		"stage_select_locked":
			if scene.has_method("_show_chapter_locked_hint"):
				scene.call("_show_chapter_locked_hint", 1)
		"battle_default_hotbar":
			scene.set("_capture_slot_items", [
				{"id": "capture_ball", "count": 2, "rarity": 1, "type": "capture"},
				{"id": "capture_ball_plus", "count": 1, "rarity": 2, "type": "capture"},
			])
			scene.set("_equipped_capture_item_id", "capture_ball")
			scene.set("_hotbar_items", [
				{"id": "hp_potion_large", "count": 2, "rarity": 2, "type": "battle"},
				{"id": "guard_charm", "count": 2, "rarity": 2, "type": "battle"},
				{"id": "rock_hammer", "count": 3, "rarity": 2, "type": "battle"},
			])
			scene.set("_selected_hotbar_slot", 0)
			scene.set("_pending_hotbar_slot", 0)
			if scene.has_method("_mark_gui_dirty"):
				scene.call("_mark_gui_dirty")
			if scene.has_method("_sync_gui"):
				scene.call("_sync_gui")
		"album_selected_detail":
			scene.set("_captured_ids", ["monster_001"])
			scene.set("_selected_tab", "album")
			scene.set("_selected_element", "all")
			if scene.has_method("_apply_filter"):
				scene.call("_apply_filter")
			scene.set("_selected_monster_id", "monster_001")
			if scene.has_method("_sync_gui"):
				scene.call("_sync_gui")
			_expect((scene.get_node("DetailPanel") as Control).visible, "album selected case should show the detail panel")
		"settings_confirm_popup":
			scene.set("confirm_dialog", true)
			if scene.has_method("_sync_authored_controls"):
				scene.call("_sync_authored_controls")
			scene.queue_redraw()
		"achievement_scroll_end":
			var max_scroll := float(scene.call("_get_max_scroll_offset")) if scene.has_method("_get_max_scroll_offset") else 0.0
			scene.set("_scroll_offset", max_scroll)
			scene.queue_redraw()
		"album_locked_grid":
			scene.set("_captured_ids", [])
			scene.set("_selected_monster_id", "")
			if scene.has_method("_apply_filter"):
				scene.call("_apply_filter")
			elif scene.has_method("_sync_gui"):
				scene.call("_sync_gui")
		"inventory_empty":
			scene.set("_inventory", {})
			scene.set("_item_list", [])
			scene.set("_selected_item", {})
			if scene.has_method("_sync_gui"):
				scene.call("_sync_gui")
			var empty_items: Variant = scene.get("_item_list")
			_expect(empty_items is Array and empty_items.is_empty(), "inventory empty case should keep the item list empty")
		_:
			scene.queue_redraw()

func _assert_meaningful_image(image: Image, case_id: String) -> void:
	var width := image.get_width()
	var height := image.get_height()
	_expect(width >= CAPTURE_SIZE.x and height >= CAPTURE_SIZE.y, "%s screenshot should use runtime viewport size" % case_id)
	var step_x := maxi(1, int(width / 16))
	var step_y := maxi(1, int(height / 20))
	var samples := 0
	var min_luma := 999.0
	var max_luma := -999.0
	var color_keys := {}
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var color := image.get_pixel(x, y)
			var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			min_luma = minf(min_luma, luma)
			max_luma = maxf(max_luma, luma)
			var key := "%d:%d:%d" % [int(color.r * 8.0), int(color.g * 8.0), int(color.b * 8.0)]
			color_keys[key] = true
			samples += 1
	_expect(samples >= 40, "%s screenshot should provide enough sampled pixels" % case_id)
	_expect(max_luma - min_luma > 0.08, "%s screenshot should not be a flat blank image" % case_id)
	_expect(color_keys.size() >= 6, "%s screenshot should contain varied UI colors" % case_id)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RuntimeScreenshotGate] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[RuntimeScreenshotGate] " + failure)
	quit(1)

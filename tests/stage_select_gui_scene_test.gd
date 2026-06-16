extends SceneTree

var _failures: Array[String] = []
var _selected_stage_id: String = ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		_finish()
		return

	save_manager.clear_all_data()
	var scene: Control = load("res://src/ui/scenes/stage_select_map.tscn").instantiate()
	root.add_child(scene)
	scene.stage_selected.connect(_on_stage_selected)
	scene.init({"chapterIndex": 8})

	_expect(scene.scene_file_path == "res://src/ui/scenes/stage_select_map.tscn", "stage select should be an editable PackedScene")
	var map_scroll := scene.get_node("MapScroll") as ScrollContainer
	_expect(map_scroll != null, "chapter maps should be hosted in a vertical scroll container")
	_expect(map_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "map should not allow desktop horizontal scrollbar behavior")
	_expect(map_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER, "map should hide the desktop-style vertical scrollbar")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).custom_minimum_size.y > map_scroll.size.y, "active chapter map should be taller than the visible viewport")
	await process_frame
	_expect(map_scroll.scroll_vertical > 0, "chapter map should start at the bottom for mobile upward progression")
	map_scroll.scroll_vertical = 120
	await process_frame
	_expect(map_scroll.scroll_vertical > 0, "chapter map scroll position should be movable at runtime")
	map_scroll.scroll_vertical = 0
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(180.0, 420.0)
	scene._input(press)
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.position = Vector2(180.0, 300.0)
	drag.relative = Vector2(0.0, -120.0)
	scene._input(drag)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(180.0, 300.0)
	scene._input(release)
	await process_frame
	_expect(map_scroll.scroll_vertical > 0, "press-dragging the map should scroll vertically without a visible scrollbar")
	_expect((scene.get_node("CloudLayerNear") as Control).position.length() > 0.0, "foreground cloud layer should move subtly with map dragging")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).scene_file_path == "res://src/ui/scenes/stage_select/chapter_maps/chapter_09_starlit_temple.tscn", "chapter 9 should be an independent editable PackedScene")
	for path in [
		"MapScroll/ChapterMaps/Chapter01Grassland/Background",
		"MapScroll/ChapterMaps/Chapter09StarlitTemple/Background",
		"MapScroll/ChapterMaps/Chapter11RadiantTemple/BossStage",
		"Header/BackButton",
		"MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01",
		"MapScroll/ChapterMaps/Chapter09StarlitTemple/StageNodes/Stage05",
		"MapScroll/ChapterMaps/Chapter08TemporalRift/BossStage",
		"MapScroll/ChapterMaps/Chapter09StarlitTemple/BossStage",
		"BottomNav/PrevMapButton",
		"BottomNav/ReturnButton",
		"BottomNav/NextMapButton",
		"CloudLayerFar/Cloud01",
		"CloudLayerNear/Cloud03",
		"PopupLayer/SweepDialog/ConfirmBtn",
	]:
		_expect(scene.has_node(path), "editable map node should exist: %s" % path)

	_expect(not scene.has_node("RewardPanel"), "old reward panel should be removed from the map")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/Background") as TextureRect).texture.resource_path.ends_with("bg_chapter_01_grassland_540x960.png"), "chapter 1 should use the optimized formal background")
	_expect((scene.get_node("Header/Bar") as TextureRect).texture.resource_path.ends_with("ui_shop_title_plaque_image2.png"), "top chapter info bar should reuse the shop title plaque art")
	_expect((scene.get_node("Header/BackButton/Frame") as TextureRect).texture.resource_path.ends_with("ranch_ui_btn_previous_round.png"), "top back button should reuse the shared round previous button art")
	var chapter_badge := scene.get_node_or_null("Header/Badge") as TextureRect
	if chapter_badge != null:
		_expect(chapter_badge.texture.resource_path.ends_with("ui_inventory_icon_badge.png"), "chapter badge should reuse the inventory badge art")
	_expect((scene.get_node("BottomNav/Panel") as TextureRect).texture.resource_path.ends_with("main_ui_bottom_nav_panel_v3.png"), "bottom nav should stay on the shared lobby navigation art")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "chapter 9 should show its independent editable map group")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift") as Control).visible, "inactive chapter maps should stay hidden")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_09_starlit_temple.png"), "chapter 9 group should carry its own formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.contains("stage_node_star"), "chapter 9 group should carry its own themed platform asset")
	var star_frame := scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/BossStage/Platform") as TextureRect
	_expect(star_frame.size.x >= 200.0 and star_frame.size.y >= 260.0, "chapter 9 boss platform should remain large and editable")

	(scene.get_node("Header/PreviousButton") as TextureButton).pressed.emit()
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift") as Control).visible, "previous chapter should display its independent temporal map group")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "chapter switch should hide the previous map group")
	(scene.get_node("BottomNav/NextMapButton") as TextureButton).pressed.emit()
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "bottom next map button should switch to the next background")

	scene.init({"chapterIndex": 0})
	await process_frame
	_expect((scene.get_node("BottomNav/PrevMapButton") as TextureButton).disabled, "bottom previous map button should be disabled on the first chapter")
	_expect(scene.has_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage11"), "chapter 1 should dynamically render eleven normal stage nodes")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("node_base_gold.png"), "chapter 1 normal stages should use the new gold base asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage11/StageNumber") as Label).text == "11", "chapter 1 should render the eleventh normal stage node")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("boss_base_dark.png"), "chapter 1 boss should use the new boss base asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter01Grassland/BossStage/BossArt"), "chapter 1 boss should not keep the old boss art overlay")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01/SelectionRing") as TextureRect).texture.resource_path.ends_with("selection_ring_pink.png"), "chapter 1 stages should carry the new selection ring asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01/Stars/Star01") as TextureRect).texture.resource_path.ends_with("star_gold_new.png"), "chapter 1 stars should use the new formal star asset")
	(scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01") as TextureButton).pressed.emit()
	_expect(_selected_stage_id == "stage_1_1", "editable stage button should preserve enter-stage behavior")

	save_manager.save_stage_stars("stage_1_1", 3)
	scene.init({"chapterIndex": 0})
	var sweep := scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01/SweepButton") as Button
	_expect(sweep.visible, "cleared stage should reveal its editable sweep button")
	_expect((sweep.get_node("Frame") as NinePatchRect).texture.resource_path.ends_with("ui_inventory_use_button.png"), "sweep button should reuse the inventory action button art")
	sweep.pressed.emit()
	_expect((scene.get_node("PopupLayer/SweepDialog") as Control).visible, "sweep action should reveal the GUI dialog")
	_expect((scene.get_node("PopupLayer/SweepDialog/ExpLabel") as Label).text.contains("经验"), "GUI dialog should retain sweep reward feedback")
	var outside_tap := InputEventMouseButton.new()
	outside_tap.button_index = MOUSE_BUTTON_LEFT
	outside_tap.pressed = true
	(scene.get_node("PopupLayer/Shade") as ColorRect).gui_input.emit(outside_tap)
	_expect(not (scene.get_node("PopupLayer/SweepDialog") as Control).visible, "tapping outside should close the GUI sweep dialog")
	sweep.pressed.emit()
	(scene.get_node("PopupLayer/SweepDialog/ConfirmBtn") as Button).pressed.emit()
	_expect((scene.get_node("PopupLayer/SweepResult") as Control).visible, "sweep confirmation should show its GUI feedback panel")
	scene.call("_update_sweep_animation", 1.0)
	_expect(not (scene.get_node("PopupLayer/Shade") as ColorRect).visible, "sweep completion should remove its modal shade")

	scene.queue_free()
	await process_frame
	_finish()

func _on_stage_selected(stage_id: String, _stage_data: Dictionary, _chapter_index: int) -> void:
	_selected_stage_id = stage_id

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[StageSelectGuiScene] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[StageSelectGuiScene] " + failure)
	quit(1)

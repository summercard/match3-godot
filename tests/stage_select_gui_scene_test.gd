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
		"TransitionCloudLayer/LeftCloud01",
		"TransitionCloudLayer/RightCloud01",
		"PopupLayer/SweepDialog/ConfirmBtn",
	]:
		_expect(scene.has_node(path), "editable map node should exist: %s" % path)

	_expect(not scene.has_node("RewardPanel"), "old reward panel should be removed from the map")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_02_grassland.png"), "chapter 1 should use the swapped chapter 2 formal background")
	_expect((scene.get_node("Header/Bar") as TextureRect).texture.resource_path.ends_with("ui_shop_title_plaque_image2.png"), "top chapter info bar should reuse the shop title plaque art")
	_expect((scene.get_node("Header/BackButton/Frame") as TextureRect).texture.resource_path.ends_with("ranch_ui_btn_previous_round.png"), "top back button should reuse the shared round previous button art")
	var chapter_badge := scene.get_node_or_null("Header/Badge") as TextureRect
	if chapter_badge != null:
		_expect(chapter_badge.texture.resource_path.ends_with("ui_inventory_icon_badge.png"), "chapter badge should reuse the inventory badge art")
	var return_patch := scene.get_node("BottomNav/ReturnButton/butter01/NinePatch") as NinePatchRect
	_expect(return_patch.texture != null and return_patch.texture.resource_path.ends_with("butter01.png"), "bottom return button should stay on shared navigation button art")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "chapter 9 should show its independent editable map group")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift") as Control).visible, "inactive chapter maps should stay hidden")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/PathDecorations") as Control).visible, "stage path dot decorations should be hidden")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_09_starlit_temple.png"), "chapter 9 group should carry its own formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.contains("stage_node_ch09_star"), "chapter 9 group should carry its own themed platform asset")
	var star_frame := scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/BossStage/Platform") as TextureRect
	_expect(star_frame.size.x >= 200.0 and star_frame.size.y >= 260.0, "chapter 9 boss platform should remain large and editable")
	_expect(not (scene.get_node("TransitionCloudLayer") as Control).visible, "chapter transition clouds should start offscreen and hidden")

	(scene.get_node("BottomNav/PrevMapButton") as TextureButton).pressed.emit()
	await _wait_frames(120)
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift") as Control).visible, "previous chapter should display its independent temporal map group")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "chapter switch should hide the previous map group")
	_expect(not (scene.get_node("TransitionCloudLayer") as Control).visible, "chapter transition clouds should hide after switching")
	(scene.get_node("BottomNav/NextMapButton") as TextureButton).pressed.emit()
	await _wait_frames(120)
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "bottom next map button should switch to the next background")

	scene.init({"chapterIndex": 0})
	await process_frame
	_expect((scene.get_node("BottomNav/PrevMapButton") as TextureButton).disabled, "bottom previous map button should be disabled on the first chapter")
	_expect(scene.has_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage11"), "chapter 1 should dynamically render eleven normal stage nodes")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch01_grass_normal.png"), "chapter 1 normal stages should use the redesigned grass pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage11/StageNumber") as Label).text == "11", "chapter 1 should render the eleventh normal stage node")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch01_grass_normal.png"), "chapter 1 boss should use the compact ordinary grass pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter01Grassland/BossStage/BossArt"), "chapter 1 boss should not keep the old boss art overlay")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01/SelectionRing") as TextureRect).visible, "chapter 1 stage selection ring should be hidden")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01/Stars/Star01") as TextureRect).texture.resource_path.ends_with("star_gold_new.png"), "chapter 1 stars should use the new formal star asset")
	(scene.get_node("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes/Stage01") as TextureButton).pressed.emit()
	_expect(_selected_stage_id == "stage_1_1", "editable stage button should preserve enter-stage behavior")

	scene.init({"chapterIndex": 1})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter02FireValley/Background") as TextureRect).texture.resource_path.ends_with("stage_bg_chapter_01_grassland_540x960.png"), "chapter 2 should use the swapped castle hill formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter02FireValley/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch02_castle_normal.png"), "chapter 2 stages should use the castle hill pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter02FireValley/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch02_castle_normal.png"), "chapter 2 boss should use the compact ordinary castle hill pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter02FireValley/BossStage/BossArt"), "chapter 2 boss should not keep the old boss art overlay")
	var chapter_2_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter02FireValley/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_2_boss_portrait.visible and chapter_2_boss_portrait.texture != null, "chapter 2 boss portrait should show by default")

	scene.init({"chapterIndex": 2})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter03MysticForest/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_03_forest.png"), "chapter 3 should use the mystic forest formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter03MysticForest/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch03_mystic_normal.png"), "chapter 3 stages should use the mystic forest pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter03MysticForest/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch03_mystic_normal.png"), "chapter 3 boss should use the compact ordinary mystic forest pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter03MysticForest/BossStage/BossArt"), "chapter 3 boss should not keep the old boss art overlay")
	var chapter_3_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter03MysticForest/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_3_boss_portrait.visible and chapter_3_boss_portrait.texture != null, "chapter 3 boss portrait should show by default")

	scene.init({"chapterIndex": 3})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter04EclipseCanopy/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_04_desert.png"), "chapter 4 should use the desert palace formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter04EclipseCanopy/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch04_desert_normal.png"), "chapter 4 stages should use the desert pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter04EclipseCanopy/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch04_desert_normal.png"), "chapter 4 boss should use the compact ordinary desert pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter04EclipseCanopy/BossStage/BossArt"), "chapter 4 boss should not keep the old boss art overlay")
	var chapter_4_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter04EclipseCanopy/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_4_boss_portrait.visible and chapter_4_boss_portrait.texture != null, "chapter 4 boss portrait should show by default")

	scene.init({"chapterIndex": 4})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05ThunderTemple/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_05_island.png"), "chapter 5 should use the island palace formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05ThunderTemple/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch05_island_normal.png"), "chapter 5 normal stages should use the island pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05ThunderTemple/StageNodes/Stage05/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch05_island_elite.png"), "chapter 5 elite stages should use the island elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05ThunderTemple/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch05_island_normal.png"), "chapter 5 boss should use the compact ordinary island pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter05ThunderTemple/BossStage/BossArt"), "chapter 5 boss should not keep the old boss art overlay")
	var chapter_5_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter05ThunderTemple/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_5_boss_portrait.visible and chapter_5_boss_portrait.texture != null, "chapter 5 boss portrait should show by default")
	var chapter_5_lock_node := scene.get_node("MapScroll/ChapterMaps/Chapter05ThunderTemple/StageNodes/Stage02/LockState")
	_expect(chapter_5_lock_node is TextureRect, "locked stages should use the transparent lock icon node")
	if chapter_5_lock_node is TextureRect:
		var chapter_5_lock := chapter_5_lock_node as TextureRect
		_expect(chapter_5_lock.visible, "locked stages should show the lock icon")
		_expect(chapter_5_lock.texture != null and chapter_5_lock.texture.resource_path.ends_with("stage_lock_icon.png"), "locked stages should use the transparent lock icon asset")

	scene.init({"chapterIndex": 5})
	await process_frame
	_expect((scene.get_node("Header/ChapterName") as Label).text == "冰霜王座", "chapter 6 title should match the frost throne theme")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06FrostThrone/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_06_frost_throne.png"), "chapter 6 should use the frost throne formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06FrostThrone/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch06_frost_normal.png"), "chapter 6 normal stages should use the frost pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06FrostThrone/StageNodes/Stage05/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch06_frost_elite.png"), "chapter 6 elite stages should use the frost elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06FrostThrone/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch06_frost_normal.png"), "chapter 6 boss should use the compact ordinary frost pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter06FrostThrone/BossStage/BossArt"), "chapter 6 boss should not keep the old boss art overlay")
	var chapter_6_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter06FrostThrone/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_6_boss_portrait.visible and chapter_6_boss_portrait.texture != null, "chapter 6 boss portrait should show by default")

	scene.init({"chapterIndex": 6})
	await process_frame
	_expect((scene.get_node("Header/ChapterName") as Label).text == "虚空领域", "chapter 7 title should match the void domain theme")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07VoidDomain/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_07_void_domain.png"), "chapter 7 should use the void domain formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07VoidDomain/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch07_void_normal.png"), "chapter 7 normal stages should use the void pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07VoidDomain/StageNodes/Stage04/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch07_void_elite.png"), "chapter 7 elite stages should use the void elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07VoidDomain/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch07_void_normal.png"), "chapter 7 boss should use the compact ordinary void pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter07VoidDomain/BossStage/BossArt"), "chapter 7 boss should not keep the old boss art overlay")
	var chapter_7_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter07VoidDomain/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_7_boss_portrait.visible and chapter_7_boss_portrait.texture != null, "chapter 7 boss portrait should show by default")

	scene.init({"chapterIndex": 7})
	await process_frame
	_expect((scene.get_node("Header/ChapterName") as Label).text == "时空裂隙", "chapter 8 title should match the temporal rift theme")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_08_temporal_rift.png"), "chapter 8 should use the temporal rift formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch08_temporal_normal.png"), "chapter 8 normal stages should use the temporal pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift/StageNodes/Stage04/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch08_temporal_elite.png"), "chapter 8 elite stages should use the temporal elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch08_temporal_normal.png"), "chapter 8 boss should use the compact ordinary temporal pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter08TemporalRift/BossStage/BossArt"), "chapter 8 boss should not keep the old boss art overlay")
	var chapter_8_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter08TemporalRift/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_8_boss_portrait.visible and chapter_8_boss_portrait.texture != null, "chapter 8 boss portrait should show by default")

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

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _finish() -> void:
	if _failures.is_empty():
		print("[StageSelectGuiScene] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[StageSelectGuiScene] " + failure)
	quit(1)

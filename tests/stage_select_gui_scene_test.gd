extends SceneTree

const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")

var _failures: Array[String] = []
var _selected_stage_id: String = ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	TestSceneCleanup.mute_audio_for_test(self)
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		await _finish()
		return

	save_manager.clear_all_data()
	for chapter_no in range(1, 9):
		save_manager.save_stage_stars("stage_%d_12" % chapter_no, 1)
	var scene: Control = load("res://src/ui/scenes/stage_select_map.tscn").instantiate()
	root.add_child(scene)
	scene.stage_selected.connect(_on_stage_selected)
	scene.init({"chapterIndex": 8})

	_expect(scene.scene_file_path == "res://src/ui/scenes/stage_select_map.tscn", "stage select should be an editable PackedScene")
	var map_scroll := scene.get_node("MapScroll") as ScrollContainer
	_expect(map_scroll != null, "chapter maps should be hosted in a vertical scroll container")
	_expect(map_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "map should not allow desktop horizontal scrollbar behavior")
	_expect(map_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER, "map should hide the desktop-style vertical scrollbar")
	var chapter_maps := scene.get_node("MapScroll/ChapterMaps") as Control
	_expect(chapter_maps.get_child_count() == 1, "stage select should only instance the active chapter map")
	_expect(scene.has_node("MapScroll/ChapterMaps/Chapter09StarlitTemple"), "chapter 9 should be loaded on demand as the active map")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter08BarbecueRock"), "inactive chapter 8 should not be instanced before switching")
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
		"MapScroll/ChapterMaps/Chapter09StarlitTemple/Background",
		"Header/BackButton",
		"MapScroll/ChapterMaps/Chapter09StarlitTemple/StageNodes/Stage05",
		"MapScroll/ChapterMaps/Chapter09StarlitTemple/BossStage",
		"BottomNav/PrevMapButton",
		"BottomNav/ReturnButton",
		"BottomNav/NextMapButton",
		"CloudLayerFar/Cloud01",
		"CloudLayerNear/Cloud03",
		"TransitionCloudLayer/LeftCloud01",
		"TransitionCloudLayer/LeftCloud10",
		"TransitionCloudLayer/RightCloud01",
		"TransitionCloudLayer/RightCloud10",
		"PopupLayer/SweepDialog/ConfirmBtn",
	]:
		_expect(scene.has_node(path), "editable map node should exist: %s" % path)

	_expect(not scene.has_node("RewardPanel"), "old reward panel should be removed from the map")
	_expect((scene.get_node("Header/Bar") as TextureRect).texture.resource_path.ends_with("ui_shop_title_plaque_image2.png"), "top chapter info bar should reuse the shop title plaque art")
	_expect((scene.get_node("Header/BackButton/Frame") as TextureRect).texture.resource_path.ends_with("ranch_ui_btn_previous_round.png"), "top back button should reuse the shared round previous button art")
	var chapter_badge := scene.get_node_or_null("Header/Badge") as TextureRect
	if chapter_badge != null:
		_expect(chapter_badge.texture.resource_path.ends_with("ui_inventory_icon_badge.png"), "chapter badge should reuse the inventory badge art")
	var return_patch := scene.get_node("BottomNav/ReturnButton/butter01/NinePatch") as NinePatchRect
	_expect(return_patch.texture != null and return_patch.texture.resource_path.ends_with("button_butter_gold.png"), "bottom return button should stay on shared navigation button art")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "chapter 9 should show its independent editable map group")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/PathDecorations") as Control).visible, "stage path dot decorations should be hidden")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_09_starlit_temple.png"), "chapter 9 group should carry its own formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.contains("stage_node_ch09_star"), "chapter 9 group should carry its own themed platform asset")
	var star_frame := scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple/BossStage/Platform") as TextureRect
	_expect(star_frame.size.x >= 200.0 and star_frame.size.y >= 260.0, "chapter 9 boss platform should remain large and editable")
	_expect(not (scene.get_node("TransitionCloudLayer") as Control).visible, "chapter transition clouds should start offscreen and hidden")
	_expect((scene.get_node("TransitionCloudLayer") as Control).z_index >= 4096, "chapter transition clouds should render above map bosses and UI")

	(scene.get_node("BottomNav/PrevMapButton") as TextureButton).pressed.emit()
	await _wait_frames(35)
	var transition_layer := scene.get_node("TransitionCloudLayer") as Control
	var transition_mist := scene.get_node("TransitionCloudLayer/Mist") as ColorRect
	_expect(transition_layer.visible, "chapter transition clouds should be visible during map switching")
	_expect(transition_layer.z_index >= 4096, "chapter transition clouds should stay above boss portraits during switching")
	_expect(transition_mist.color.a >= 0.95, "chapter transition white mist should fully cover the outgoing map")
	await _wait_frames(120)
	_expect(chapter_maps.get_child_count() == 1, "chapter switch should keep only one instanced chapter")
	_expect(scene.has_node("MapScroll/ChapterMaps/Chapter08BarbecueRock"), "previous chapter should display its independent chapter 8 map group")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter09StarlitTemple"), "chapter switch should release the previous map group")
	_expect(not (scene.get_node("TransitionCloudLayer") as Control).visible, "chapter transition clouds should hide after switching")
	(scene.get_node("BottomNav/NextMapButton") as TextureButton).pressed.emit()
	await _wait_frames(120)
	_expect(chapter_maps.get_child_count() == 1, "switching back should still keep one instanced chapter")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter09StarlitTemple") as Control).visible, "bottom next map button should switch to the next background")

	scene.init({"chapterIndex": 0})
	await process_frame
	_expect((scene.get_node("BottomNav/PrevMapButton") as TextureButton).disabled, "bottom previous map button should be disabled on the first chapter")
	_expect(scene.has_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage11"), "chapter 1 should dynamically render eleven normal stage nodes")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch01_grass_normal.png"), "chapter 1 normal stages should use the redesigned grass pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage11/StageNumber") as Label).text == "1-11", "chapter 1 should render the eleventh normal stage node with chapter-stage numbering")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch01_grass_normal.png"), "chapter 1 boss should use the compact ordinary grass pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter01BreezePlain/BossStage/BossArt"), "chapter 1 boss should not keep the old boss art overlay")
	_expect(not (scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage01/SelectionRing") as TextureRect).visible, "chapter 1 stage selection ring should be hidden")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage01/Stars/Star01") as TextureRect).texture.resource_path.ends_with("star_gold_new.png"), "chapter 1 stars should use the new formal star asset")
	(scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage01") as TextureButton).pressed.emit()
	_expect(_selected_stage_id == "stage_1_1", "editable stage button should preserve enter-stage behavior")

	scene.init({"chapterIndex": 1})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter02WaterfallKingdom/Background") as TextureRect).texture.resource_path.ends_with("stage_bg_chapter_01_grassland_540x960.png"), "chapter 2 should use the swapped castle hill formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter02WaterfallKingdom/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch02_castle_normal.png"), "chapter 2 stages should use the castle hill pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter02WaterfallKingdom/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch02_castle_normal.png"), "chapter 2 boss should use the compact ordinary castle hill pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter02WaterfallKingdom/BossStage/BossArt"), "chapter 2 boss should not keep the old boss art overlay")
	var chapter_2_boss_platform := scene.get_node("MapScroll/ChapterMaps/Chapter02WaterfallKingdom/BossStage/Platform") as TextureRect
	var chapter_2_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter02WaterfallKingdom/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_2_boss_portrait.visible and chapter_2_boss_portrait.texture != null, "chapter 2 boss portrait should show by default")
	_expect(absf((chapter_2_boss_portrait.position.x + chapter_2_boss_portrait.size.x * 0.5) - (chapter_2_boss_platform.position.x + chapter_2_boss_platform.size.x * 0.5)) <= 1.0, "chapter 2 boss portrait should be centered on its platform")
	_expect(absf((chapter_2_boss_portrait.position.y + chapter_2_boss_portrait.size.y) - (chapter_2_boss_platform.position.y + chapter_2_boss_platform.size.y * 0.58)) <= 1.0, "chapter 2 boss portrait should sit on the platform anchor")
	_expect(not (chapter_2_boss_portrait.texture is AtlasTexture), "chapter 2 boss portrait should use the full source art without stage-select cropping")

	scene.init({"chapterIndex": 2})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter03FeatherForest/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_03_forest.png"), "chapter 3 should use the mystic forest formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter03FeatherForest/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch03_mystic_normal.png"), "chapter 3 stages should use the mystic forest pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter03FeatherForest/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch03_mystic_normal.png"), "chapter 3 boss should use the compact ordinary mystic forest pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter03FeatherForest/BossStage/BossArt"), "chapter 3 boss should not keep the old boss art overlay")
	var chapter_3_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter03FeatherForest/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_3_boss_portrait.visible and chapter_3_boss_portrait.texture != null, "chapter 3 boss portrait should show by default")

	scene.init({"chapterIndex": 3})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter04PassionDesert/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_04_desert.png"), "chapter 4 should use the desert palace formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter04PassionDesert/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch04_desert_normal.png"), "chapter 4 stages should use the desert pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter04PassionDesert/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch04_desert_normal.png"), "chapter 4 boss should use the compact ordinary desert pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter04PassionDesert/BossStage/BossArt"), "chapter 4 boss should not keep the old boss art overlay")
	var chapter_4_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter04PassionDesert/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_4_boss_portrait.visible and chapter_4_boss_portrait.texture != null, "chapter 4 boss portrait should show by default")

	scene.init({"chapterIndex": 4})
	await process_frame
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05SouthernSea/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_05_island.png"), "chapter 5 should use the island palace formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05SouthernSea/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch05_island_normal.png"), "chapter 5 normal stages should use the island pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05SouthernSea/StageNodes/Stage05/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch05_island_elite.png"), "chapter 5 elite stages should use the island elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter05SouthernSea/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch05_island_normal.png"), "chapter 5 boss should use the compact ordinary island pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter05SouthernSea/BossStage/BossArt"), "chapter 5 boss should not keep the old boss art overlay")
	var chapter_5_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter05SouthernSea/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_5_boss_portrait.visible and chapter_5_boss_portrait.texture != null, "chapter 5 boss portrait should show by default")
	var chapter_5_lock_node := scene.get_node("MapScroll/ChapterMaps/Chapter05SouthernSea/StageNodes/Stage02/LockState")
	_expect(chapter_5_lock_node is TextureRect, "locked stages should use the transparent lock icon node")
	if chapter_5_lock_node is TextureRect:
		var chapter_5_lock := chapter_5_lock_node as TextureRect
		_expect(chapter_5_lock.visible, "locked stages should show the lock icon")
		_expect(chapter_5_lock.texture != null and chapter_5_lock.texture.resource_path.ends_with("stage_lock_icon.png"), "locked stages should use the transparent lock icon asset")

	scene.init({"chapterIndex": 5})
	await process_frame
	_expect((scene.get_node("Header/ChapterName") as Label).text == "冰之国", "chapter 6 title should match the configured folder-derived name")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06IceKingdom/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_08_icefield.png"), "chapter 6 should keep its configured formal background asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06IceKingdom/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch06_frost_normal.png"), "chapter 6 normal stages should use the frost pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06IceKingdom/StageNodes/Stage05/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch06_frost_elite.png"), "chapter 6 elite stages should use the frost elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter06IceKingdom/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch06_frost_normal.png"), "chapter 6 boss should use the compact ordinary frost pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter06IceKingdom/BossStage/BossArt"), "chapter 6 boss should not keep the old boss art overlay")
	var chapter_6_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter06IceKingdom/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_6_boss_portrait.visible and chapter_6_boss_portrait.texture != null, "chapter 6 boss portrait should show by default")

	scene.init({"chapterIndex": 6})
	await process_frame
	_expect((scene.get_node("Header/ChapterName") as Label).text == "精灵虚空", "chapter 7 title should match the configured folder-derived name")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_07_underground.png"), "chapter 7 should keep its configured formal background asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch07_void_normal.png"), "chapter 7 normal stages should use the void pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/StageNodes/Stage04/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch07_void_elite.png"), "chapter 7 elite stages should use the void elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/StageNodes/Stage01/StageNumber") as Label).text == "7-1", "chapter 7 stage numbers should use chapter-stage format")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/StageNodes/Stage02/StageNumber") as Label).visible, "locked chapter 7 stages should still show their chapter-stage number")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch07_void_normal.png"), "chapter 7 boss should use the compact ordinary void pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/BossStage/BossArt"), "chapter 7 boss should not keep the old boss art overlay")
	var chapter_7_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter07SpiritVoid/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_7_boss_portrait.visible and chapter_7_boss_portrait.texture != null, "chapter 7 boss portrait should show by default")

	scene.init({"chapterIndex": 7})
	await process_frame
	_expect((scene.get_node("Header/ChapterName") as Label).text == "烧烤岩", "chapter 8 title should match the configured folder-derived name")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_06_volcano.png"), "chapter 8 should use the lava volcano formal background")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch08_lava_normal.png"), "chapter 8 normal stages should use the lava pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/StageNodes/Stage04/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch08_lava_elite.png"), "chapter 8 elite stages should use the lava elite pedestal asset")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/StageNodes/Stage01/StageNumber") as Label).text == "8-1", "chapter 8 stage numbers should use chapter-stage format")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/StageNodes/Stage02/StageNumber") as Label).visible, "locked chapter 8 stages should still show their chapter-stage number")
	_expect((scene.get_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/BossStage/Platform") as TextureRect).texture.resource_path.ends_with("stage_node_ch08_lava_normal.png"), "chapter 8 boss should use the compact ordinary lava pedestal asset")
	_expect(not scene.has_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/BossStage/BossArt"), "chapter 8 boss should not keep the old boss art overlay")
	var chapter_8_boss_portrait := scene.get_node("MapScroll/ChapterMaps/Chapter08BarbecueRock/BossStage/MonsterPortrait") as TextureRect
	_expect(chapter_8_boss_portrait.visible and chapter_8_boss_portrait.texture != null, "chapter 8 boss portrait should show by default")

	save_manager.save_stage_stars("stage_1_1", 3)
	scene.init({"chapterIndex": 0})
	_selected_stage_id = ""
	var cleared_stage := scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage01") as TextureButton
	var sweep := scene.get_node("MapScroll/ChapterMaps/Chapter01BreezePlain/StageNodes/Stage01/SweepButton") as Button
	_expect(sweep.visible, "cleared stage should reveal its editable sweep button")
	_expect(sweep.mouse_filter == Control.MOUSE_FILTER_IGNORE, "sweep indicator should not own a separate touch area")
	_expect((sweep.get_node("butter02/NinePatch") as NinePatchRect).texture.resource_path.ends_with("button_butter_blue.png"), "sweep indicator should use the shared redesigned art")
	sweep.pressed.emit()
	_expect(not (scene.get_node("PopupLayer/SweepDialog") as Control).is_visible_in_tree(), "sweep indicator should be display-only")
	cleared_stage.pressed.emit()
	_expect((scene.get_node("PopupLayer/SweepDialog") as Control).visible, "pressing a sweep-enabled stage should reveal the action choice dialog")
	_expect((scene.get_node("PopupLayer") as Control).visible, "action choice should reveal its popup parent layer")
	_expect((scene.get_node("PopupLayer/SweepDialog") as Control).is_visible_in_tree(), "action choice should be visible on screen")
	_expect((scene.get_node("PopupLayer/SweepDialog/black3/NinePatch") as NinePatchRect).texture.resource_path.ends_with("black2.png"), "action choice should use the edited black3 panel")
	_expect((scene.get_node("PopupLayer/SweepDialog/TitleRibbon/NinePatch") as NinePatchRect).texture.resource_path.ends_with("ribbon_side_01.png"), "action choice should use the library title ribbon component")
	_expect((scene.get_node("PopupLayer/SweepDialog/black2/NinePatch") as NinePatchRect).texture.resource_path.ends_with("black2.png"), "action choice should use the edited black2 panel")
	_expect((scene.get_node("PopupLayer/SweepDialog/ConfirmBtn/butter02/NinePatch") as NinePatchRect).texture.resource_path.ends_with("button_butter_blue.png"), "sweep choice should use the edited button component")
	_expect((scene.get_node("PopupLayer/SweepDialog/CancelBtn/butter02/NinePatch") as NinePatchRect).texture.resource_path.ends_with("button_butter_blue.png"), "stage entry choice should use the edited button component")
	_expect((scene.get_node("PopupLayer/SweepDialog") as Control).size == Vector2(315.0, 238.0), "action choice should use the compact mobile dialog size")
	_expect((scene.get_node("PopupLayer/SweepDialog/ConfirmBtn") as Button).size == Vector2(140.0, 52.0), "sweep choice should keep a mobile-friendly touch target")
	_expect((scene.get_node("PopupLayer/SweepDialog/CancelBtn") as Button).size == Vector2(140.0, 52.0), "stage entry choice should keep a mobile-friendly touch target")
	_expect((scene.get_node("PopupLayer/SweepDialog/ConfirmBtn/butter02") as Control).scale == Vector2(0.28, 0.28), "sweep component should preserve the edited wrapper scale")
	_expect((scene.get_node("PopupLayer/SweepDialog/CancelBtn/butter02") as Control).scale == Vector2(0.28, 0.28), "stage entry component should preserve the edited wrapper scale")
	_expect(_selected_stage_id.is_empty(), "sweep-enabled stages should wait for the player's choice")
	_expect((scene.get_node("PopupLayer/SweepDialog/ConfirmBtn/Text") as Label).text == "扫荡", "choice dialog should offer sweep")
	_expect((scene.get_node("PopupLayer/SweepDialog/CancelBtn/Text") as Label).text == "进入关卡", "choice dialog should offer normal stage entry")
	_expect((scene.get_node("PopupLayer/SweepDialog/ExpLabel") as Label).text.contains("经验"), "GUI dialog should retain sweep reward feedback")
	var outside_tap := InputEventMouseButton.new()
	outside_tap.button_index = MOUSE_BUTTON_LEFT
	outside_tap.pressed = true
	(scene.get_node("PopupLayer/Shade") as ColorRect).gui_input.emit(outside_tap)
	_expect(not (scene.get_node("PopupLayer/SweepDialog") as Control).visible, "tapping outside should close the GUI sweep dialog")
	cleared_stage.pressed.emit()
	(scene.get_node("PopupLayer/SweepDialog/CancelBtn") as Button).pressed.emit()
	_expect(_selected_stage_id == "stage_1_1", "enter-stage choice should preserve normal stage entry")
	_selected_stage_id = ""
	cleared_stage.pressed.emit()
	(scene.get_node("PopupLayer/SweepDialog/ConfirmBtn") as Button).pressed.emit()
	var sweep_result := scene.get_node("PopupLayer/SweepResult") as Control
	_expect(sweep_result.visible, "sweep confirmation should show its GUI feedback panel")
	_expect(sweep_result.position == (scene.get_node("PopupLayer/SweepDialog") as Control).position and sweep_result.size == (scene.get_node("PopupLayer/SweepDialog") as Control).size, "sweep result should copy the edited dialog bounds")
	_expect((sweep_result.get_node("black3/NinePatch") as NinePatchRect).texture.resource_path.ends_with("black2.png"), "sweep result should copy the edited black3 panel")
	_expect((sweep_result.get_node("TitleRibbon/NinePatch") as NinePatchRect).texture.resource_path.ends_with("ribbon_side_01.png"), "sweep result should copy the edited title ribbon")
	_expect((sweep_result.get_node("black2/NinePatch") as NinePatchRect).texture.resource_path.ends_with("black2.png"), "sweep result should copy the edited reward panel")
	_expect(not sweep_result.has_node("Frame") and not sweep_result.has_node("ConfirmBtn") and not sweep_result.has_node("CancelBtn"), "sweep result should remove the old frame and action buttons")
	scene.call("_update_sweep_animation", 1.0)
	_expect(not (scene.get_node("PopupLayer/Shade") as ColorRect).visible, "sweep completion should remove its modal shade")

	await _finish()

func _on_stage_selected(stage_id: String, _stage_data: Dictionary, _chapter_index: int) -> void:
	_selected_stage_id = stage_id

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _finish() -> void:
	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("[StageSelectGuiScene] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[StageSelectGuiScene] " + failure)
	quit(1)

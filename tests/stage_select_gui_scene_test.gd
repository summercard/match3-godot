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
	_expect((scene.get_node("ChapterMaps/Chapter09StarlitTemple") as Control).scene_file_path == "res://src/ui/scenes/stage_select/chapter_maps/chapter_09_starlit_temple.tscn", "chapter 9 should be an independent editable PackedScene")
	for path in [
		"ChapterMaps/Chapter01Grassland/Background",
		"ChapterMaps/Chapter09StarlitTemple/Background",
		"ChapterMaps/Chapter11RadiantTemple/BossStage",
		"Header/BackButton",
		"ChapterMaps/Chapter01Grassland/StageNodes/Stage01",
		"ChapterMaps/Chapter09StarlitTemple/StageNodes/Stage05",
		"ChapterMaps/Chapter08TemporalRift/BossStage",
		"ChapterMaps/Chapter09StarlitTemple/BossStage",
		"RewardPanel/Items/Item1",
		"PopupLayer/SweepDialog/ConfirmBtn",
	]:
		_expect(scene.has_node(path), "editable map node should exist: %s" % path)

	_expect((scene.get_node("ChapterMaps/Chapter09StarlitTemple") as Control).visible, "chapter 9 should show its independent editable map group")
	_expect(not (scene.get_node("ChapterMaps/Chapter08TemporalRift") as Control).visible, "inactive chapter maps should stay hidden")
	_expect((scene.get_node("ChapterMaps/Chapter09StarlitTemple/Background") as TextureRect).texture.resource_path.ends_with("stage_map_bg_chapter_09_starlit_temple.png"), "chapter 9 group should carry its own formal background")
	_expect((scene.get_node("ChapterMaps/Chapter09StarlitTemple/StageNodes/Stage01/Platform") as TextureRect).texture.resource_path.contains("chapter_09_star"), "chapter 9 group should carry its own themed platform asset")
	var star_frame := scene.get_node("ChapterMaps/Chapter09StarlitTemple/BossStage/Platform") as TextureRect
	_expect(star_frame.size.x >= 200.0 and star_frame.size.y >= 260.0, "chapter 9 boss platform should remain large and editable")

	(scene.get_node("Header/PreviousButton") as TextureButton).pressed.emit()
	_expect((scene.get_node("ChapterMaps/Chapter08TemporalRift") as Control).visible, "previous chapter should display its independent temporal map group")
	_expect(not (scene.get_node("ChapterMaps/Chapter09StarlitTemple") as Control).visible, "chapter switch should hide the previous map group")

	scene.init({"chapterIndex": 0})
	(scene.get_node("ChapterMaps/Chapter01Grassland/StageNodes/Stage01") as TextureButton).pressed.emit()
	_expect(_selected_stage_id == "stage_1_1", "editable stage button should preserve enter-stage behavior")

	save_manager.save_stage_stars("stage_1_1", 3)
	scene.init({"chapterIndex": 0})
	var sweep := scene.get_node("ChapterMaps/Chapter01Grassland/StageNodes/Stage01/SweepButton") as Button
	_expect(sweep.visible, "cleared stage should reveal its editable sweep button")
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

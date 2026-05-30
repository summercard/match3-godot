extends SceneTree

const SCENE_PATH := "res://src/ui/scenes/album.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "album scene should load")
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	await process_frame
	scene.call("init", {})
	await process_frame

	_assert(scene.scene_file_path == SCENE_PATH, "album should be a PackedScene GUI")
	_assert(scene.has_node("AlbumPage/Grid/Card1"), "card nodes should be editable")
	_assert(scene.has_node("AlbumPage/PageControls/PreviousButton"), "previous page button should exist")
	_assert(scene.has_node("AlbumPage/PageControls/NextButton"), "next page button should exist")
	_assert(scene.has_node("DetailPanel"), "detail panel should be editable")
	_assert(scene.has_node("BottomTabs/BondTab"), "bottom tabs should be editable")

	var next := scene.get_node("AlbumPage/PageControls/NextButton") as BaseButton
	next.pressed.emit()
	await process_frame
	_assert(int(scene.get("_album_page")) >= 0, "next page press should keep a valid page")
	if int(scene.call("_max_album_page")) > 0:
		_assert(int(scene.get("_album_page")) == 1, "next page should advance when a second page exists")

	var prev := scene.get_node("AlbumPage/PageControls/PreviousButton") as BaseButton
	prev.pressed.emit()
	await process_frame
	_assert(int(scene.get("_album_page")) == 0, "previous page should return to first page")

	var fire := scene.get_node("AlbumPage/Filters/Fire") as BaseButton
	fire.pressed.emit()
	await process_frame
	_assert(str(scene.get("_selected_element")) == "fire", "filter button should update element")
	_assert(int(scene.get("_album_page")) == 0, "filter should reset page")

	var card := scene.get_node("AlbumPage/Grid/Card1") as BaseButton
	card.pressed.emit()
	await process_frame
	_assert((scene.get_node("DetailPanel") as Control).visible, "card press should open detail for QA-unlocked album")

	var close := scene.get_node("DetailPanel/CloseButton") as BaseButton
	close.pressed.emit()
	await process_frame
	_assert(not (scene.get_node("DetailPanel") as Control).visible, "close button should hide detail")

	var bond := scene.get_node("BottomTabs/BondTab") as BaseButton
	bond.pressed.emit()
	await process_frame
	_assert((scene.get_node("BondPage") as Control).visible, "bond tab should show bond page")

	var collection := scene.get_node("BottomTabs/CollectionTab") as BaseButton
	collection.pressed.emit()
	await process_frame
	_assert((scene.get_node("CollectionPage") as Control).visible, "collection tab should show collection page")

	print("[AlbumGuiSceneTest] passed")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[AlbumGuiSceneTest] %s" % message)
	quit(1)

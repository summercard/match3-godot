extends SceneTree

const SCENE_PATH := "res://src/ui/scenes/album.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "album scene should load")
	var scene := packed.instantiate() as Control
	_assert((scene.get_node("Header/Title") as Label).text == "精灵图鉴", "album tscn editor title should not be mojibake")
	_assert((scene.get_node("LobbyBottomNav/PetsButton/Text") as Label).text == "图鉴", "album tscn bottom dex label should not be mojibake")
	_assert((scene.get_node("LobbyBottomNav/BattleButton/Text") as Label).text == "羁绊", "album tscn bottom bond label should not be mojibake")
	_assert((scene.get_node("LobbyBottomNav/ShopButton/Text") as Label).text == "目标", "album tscn bottom target label should not be mojibake")
	_assert(not (scene.get_node("AlbumPage/Grid/Card1/Frame") as TextureRect).visible, "album tscn should hide the legacy card frame before runtime sync")
	_assert(not (scene.get_node("AlbumPage/Grid/Card1/LockIcon") as TextureRect).visible, "album tscn should hide the legacy lock icon before runtime sync")
	_assert((scene.get_node("AlbumPage/Grid/Card1/Portrait") as TextureRect).texture != null, "album tscn should show a concept-style portrait in the editor")
	_assert((scene.get_node("AlbumPage/Grid/Card1/Portrait") as TextureRect).texture.resource_path.ends_with("album/portraits/monster_001_album_thumb.png"), "album tscn should use normalized dex portraits instead of raw battle art")
	_assert(not scene.has_node("AlbumPage/PreviewPanel"), "album should remove the right-side persistent pet detail panel")
	_assert(not scene.has_node("AlbumPage/PreviewEmpty"), "album should remove the right-side empty preview hint")
	_assert((scene.get_node("AlbumPage/Grid") as Control).size.x > 330.0, "album roster grid should use the space freed by the removed preview")
	root.add_child(scene)
	await process_frame
	scene.call("init", {})
	await process_frame

	_assert(scene.scene_file_path == SCENE_PATH, "album should be a PackedScene GUI")
	_assert(scene.has_node("AlbumPage/Grid/Card1"), "card nodes should be editable")
	_assert(scene.has_node("AlbumPage/Grid/Card15"), "concept-style roster should provide a full-width five-column pet list")
	_assert(scene.has_node("AlbumPage/PageControls/PreviousButton"), "previous page button should exist")
	_assert(scene.has_node("AlbumPage/PageControls/NextButton"), "next page button should exist")
	_assert(scene.has_node("DetailPanel"), "detail panel should be editable")
	_assert(scene.has_node("LobbyBottomNav/BattleButton"), "bond tab should live in the bottom navigation")
	_assert(scene.has_node("AlbumResourceBar/GoldCapsule/Value"), "shared resource bar should be editable")
	_assert(scene.has_node("LobbyBottomNav/PetsButton/Selected"), "shared bottom navigation should identify the pet section")
	_assert(not (scene.get_node("Header/BackButton") as TextureButton).visible, "album should not expose the lobby back button")
	var bottom_panel := scene.get_node("LobbyBottomNav/Panel") as TextureRect
	_assert(bottom_panel.texture.resource_path.ends_with("main/lobby_refresh/ui_bottom_nav_panel_v3.png"), "album bottom navigation should reuse the main lobby bottom panel art")
	var bottom_selected := scene.get_node("LobbyBottomNav/PetsButton/Selected") as TextureRect
	_assert(bottom_selected.texture.resource_path.ends_with("album/ui_dex_bottom_nav_selected.png"), "album selected nav state should use dex-specific art")
	_assert(scene.get_node("DetailPanel/Frame") is Panel, "detail popup should use the light dex board instead of the old dark art")
	_assert(scene.get_node("DetailPanel/PortraitStage/Frame") is Panel, "detail portrait area should not use the old blue frame art")
	_assert(scene.get_node("DetailPanel/Stats/Stat1/Frame") is ColorRect, "detail stat rows should not use old blue image strips")
	_assert(scene.get_node("DetailPanel/SkillPanel/Frame") is Panel, "detail skill area should not use old blue panel art")
	_assert(scene.get_node("DetailPanel/EvolutionStrip/Frame") is Panel, "detail evolution area should not use old blue strip art")
	_assert(scene.get_node("BondPage/Frame") is Panel, "bond page should use the light dex board")
	_assert(scene.get_node("CollectionPage/Frame") is Panel, "target page should use the light dex board")
	_assert(not (scene.get_node("BottomTabs") as Control).visible, "legacy floating mode tabs should be hidden when modes live in the bottom navigation")
	_assert((scene.get_node("AlbumPage/Grid/Card1") as Control).scale.x > 0.44, "dex monster portraits should be large enough for concept-style browsing")
	_assert((scene.get_node("BottomTabs/AlbumTab/Text") as Label).text == "图鉴", "album mode tab labels should render as Chinese text")
	_assert((scene.get_node("LobbyBottomNav/PetsButton/Text") as Label).text == "图鉴", "album bottom nav labels should render as Chinese text")
	_assert((scene.get_node("LobbyBottomNav/BattleButton/Text") as Label).text == "羁绊", "bottom nav should expose the bond album mode")
	_assert((scene.get_node("LobbyBottomNav/ShopButton/Text") as Label).text == "目标", "bottom nav should expose the target album mode")
	_assert((scene.get_node("LobbyBottomNav/PetsButton/Icon") as TextureRect).texture.resource_path.ends_with("common_nav/icon_nav_album.png"), "dex bottom nav should use the common album icon")
	_assert((scene.get_node("LobbyBottomNav/BattleButton/Icon") as TextureRect).texture.resource_path.ends_with("common_nav/icon_nav_bond.png"), "dex bottom nav should use the common bond icon")
	_assert((scene.get_node("LobbyBottomNav/ShopButton/Icon") as TextureRect).texture.resource_path.ends_with("common_nav/icon_nav_goal.png"), "dex bottom nav should use the common target icon")

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
	_assert(not scene.has_node("AlbumPage/PreviewPanel"), "card press should not recreate the removed right-side preview")
	_assert(not scene.has_node("AlbumPage/PreviewEmpty"), "card press should not recreate the removed empty preview hint")
	_assert(not (scene.get_node("AlbumPage/Grid/Card1/Frame") as TextureRect).visible, "unlocked roster portrait should not use the legacy card frame")
	_assert((scene.get_node("AlbumPage/Grid/Card1/Portrait") as TextureRect).texture.resource_path.contains("album/portraits/"), "runtime album grid should keep normalized dex portraits")

	var close := scene.get_node("DetailPanel/CloseButton") as BaseButton
	close.pressed.emit()
	await process_frame
	_assert(not (scene.get_node("DetailPanel") as Control).visible, "close button should hide detail")

	scene.set("_captured_ids", [])
	scene.call("_sync_gui")
	await process_frame
	card.pressed.emit()
	await process_frame
	var locked_portrait := scene.get_node("AlbumPage/Grid/Card1/Portrait") as TextureRect
	_assert(locked_portrait.visible, "locked card should keep its monster portrait silhouette")
	_assert(locked_portrait.material is ShaderMaterial, "locked portrait should use a solid-color silhouette shader")
	_assert(not (scene.get_node("AlbumPage/Grid/Card1/Frame") as TextureRect).visible, "locked silhouette should not keep a card frame behind the monster")
	_assert(not (scene.get_node("AlbumPage/Grid/Card1/ElementIcon") as TextureRect).visible, "locked silhouette should not reveal its element badge")
	_assert(not (scene.get_node("AlbumPage/Grid/Card1/Stars") as Control).visible, "locked silhouette should not keep unlocked card metadata")
	_assert(not (scene.get_node("AlbumPage/Grid/Card1/LockIcon") as TextureRect).visible, "locked silhouette should not add a lock marker")
	_assert(not (scene.get_node("DetailPanel") as Control).visible, "locked card should not reveal the complete detail panel")
	_assert(not scene.has_node("AlbumPage/PreviewPanel"), "locked card should not reveal the removed right-side preview")

	var filter_frame := scene.get_node("AlbumPage/Filters/Fire/Frame") as TextureRect
	_assert(filter_frame.texture.resource_path.ends_with("ui_dex_filter_normal.png") or filter_frame.texture.resource_path.ends_with("ui_dex_filter_selected.png"), "filters should use the new light dex art")
	var prev_frame := scene.get_node("AlbumPage/PageControls/PreviousButton/Frame") as TextureRect
	var next_frame := scene.get_node("AlbumPage/PageControls/NextButton/Frame") as TextureRect
	_assert(prev_frame.texture.resource_path.ends_with("ui_dex_page_prev.png"), "previous page should use the new green dex button")
	_assert(next_frame.texture.resource_path.ends_with("ui_dex_page_next.png"), "next page should use the new green dex button")
	var bond := scene.get_node("LobbyBottomNav/BattleButton") as BaseButton
	bond.pressed.emit()
	await process_frame
	_assert((scene.get_node("BondPage") as Control).visible, "bond tab should show bond page")
	_assert((scene.get_node("LobbyBottomNav/BattleButton/Selected") as TextureRect).visible, "bottom bond button should show selected feedback")

	var collection := scene.get_node("LobbyBottomNav/ShopButton") as BaseButton
	collection.pressed.emit()
	await process_frame
	_assert((scene.get_node("CollectionPage") as Control).visible, "collection tab should show collection page")
	_assert((scene.get_node("LobbyBottomNav/ShopButton/Selected") as TextureRect).visible, "bottom target button should show selected feedback")

	print("[AlbumGuiSceneTest] passed")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[AlbumGuiSceneTest] %s" % message)
	quit(1)

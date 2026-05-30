extends SceneTree

const SCENE_PATH := "res://src/ui/scenes/shop.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "shop scene should load")
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	await process_frame
	scene.call("init", {})
	scene.set("player_data", {"gold": 5000, "gems": 120})
	scene.call("_sync_gui")
	await process_frame

	_assert(scene.scene_file_path == SCENE_PATH, "shop should be a PackedScene GUI")
	_assert(scene.has_node("Tabs/Recommend"), "tab nodes should be editable")
	_assert(scene.has_node("ProductGrid/Cards/Card9"), "nine product cards should be editable")
	_assert(not scene.has_node("ProductGrid/Cards/Card1/BuyButton"), "product cards should not use a separate buy button")
	_assert(not (scene.get_node("FeatureBanner") as Control).visible, "starter bundle banner should be hidden")
	_assert(scene.has_node("PopupOverlay/Panel/ConfirmButton"), "popup should be editable")
	_assert(scene.has_node("Toast/Tail"), "purchase toast should have an editable speech-bubble tail")
	_assert((scene.get_node("Toast") as Control).position.y < 340.0, "purchase toast should sit near the shopkeeper, not over the item grid bottom")
	_assert(str((scene.get_node("Header/GoldChip/Amount") as Label).text) == "5,000", "gold chip should sync")

	var gems_tab := scene.get_node("Tabs/Gems") as BaseButton
	gems_tab.pressed.emit()
	await process_frame
	_assert(str(scene.get("_active_tab")) == "gems", "gems tab should filter")
	_assert(int(scene.get("_shop_page")) == 0, "tab switch should reset page")
	_assert((scene.get_node("ProductGrid/Cards/Card1") as Control).visible, "filtered card should render")

	var card := scene.get_node("ProductGrid/Cards/Card1") as BaseButton
	card.pressed.emit()
	await process_frame
	_assert((scene.get_node("PopupOverlay") as Control).visible, "card tap should open popup")
	_assert(str((scene.get_node("PopupOverlay/Panel/Quantity") as Label).text) == "1", "popup quantity should start at one")

	var plus_ten := scene.get_node("PopupOverlay/Panel/PlusTenButton") as BaseButton
	plus_ten.pressed.emit()
	await process_frame
	_assert(str((scene.get_node("PopupOverlay/Panel/Quantity") as Label).text) == "11", "plus ten should update quantity")

	var minus := scene.get_node("PopupOverlay/Panel/MinusButton") as BaseButton
	minus.pressed.emit()
	await process_frame
	_assert(str((scene.get_node("PopupOverlay/Panel/Quantity") as Label).text) == "10", "minus should update quantity")

	var cancel := scene.get_node("PopupOverlay/Panel/CancelButton") as BaseButton
	cancel.pressed.emit()
	await process_frame
	_assert(not (scene.get_node("PopupOverlay") as Control).visible, "cancel should hide popup")

	scene.call("_show_toast", "获得 经验药水 x1", "success")
	await process_frame
	_assert((scene.get_node("Toast") as Control).visible, "purchase toast should show as a speech bubble")

	print("[ShopGuiSceneTest] passed")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[ShopGuiSceneTest] %s" % message)
	quit(1)

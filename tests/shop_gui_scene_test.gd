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
	_assert(scene.has_node("TitlePlaque/Title"), "shop should use the concept-style title plaque")
	_assert(not scene.has_node("Header/BackButton"), "shop concept should not keep the legacy top-left back button")
	_assert(scene.has_node("Tabs/Gems"), "gems tab should be editable")
	_assert(scene.has_node("Tabs/Coins"), "coins tab should be editable")
	_assert(scene.has_node("Tabs/Hearts"), "hearts tab should be editable")
	_assert(scene.has_node("Tabs/Boosters"), "boosters tab should be editable")
	_assert(scene.has_node("Tabs/Chest"), "element chest tab should be editable")
	_assert(scene.has_node("ProductGrid/Cards/Card9"), "nine product cards should be editable")
	_assert(int(scene.call("_max_shop_page")) >= 2, "expanded shop item list should paginate beyond the first 9 cards")
	_assert(not (scene.get_node("ProductGrid/PageControls/NextButton") as BaseButton).disabled, "expanded shop should enable next-page control on all-items tab")
	_assert(not scene.has_node("ProductGrid/Cards/Card1/BuyButton"), "product cards should not use a separate buy button")
	_assert(scene.get_node("ProductGrid/Cards/Card1/Frame") is TextureRect, "product cards should use image-2 extracted card art")
	_assert((scene.get_node("ProductGrid/Cards/Card1/Frame") as TextureRect).texture.resource_path.ends_with("assets/images/ui/cards/shop_ui_shop_card_panel_image2_clean.png"), "product card art should come from the current image-2 transparent asset")
	_assert(scene.get_node("ProductGrid/Cards/Card1/Price/Frame") is TextureRect, "price buttons should use image-2 extracted art")
	_assert(scene.get_node("Tabs/Gems/Frame") is TextureRect, "shop tabs should use image-2 extracted tab art")
	_assert((scene.get_node("BottomNav/HomeButton") as Control).visible, "shop bottom nav should keep only the home button")
	_assert(not (scene.get_node("BottomNav/PetsButton") as Control).visible, "shop bottom nav pets slot should be empty")
	_assert(not (scene.get_node("BottomNav/BattleButton") as Control).visible, "shop bottom nav battle slot should be empty")
	_assert(not (scene.get_node("BottomNav/ShopButton") as Control).visible, "shop bottom nav shop slot should be empty")
	_assert(not (scene.get_node("BottomNav/MenuButton") as Control).visible, "shop bottom nav menu slot should be empty")
	_assert((scene.get_node("BottomNav/Frame") as TextureRect).texture.resource_path.ends_with("assets/images/ui/icons/main_ui_bottom_nav_panel_v3.png"), "shop bottom nav should reuse main lobby art")
	_assert(scene.has_node("PopupOverlay/Panel/ConfirmButton"), "popup should be editable")
	_assert(scene.has_node("Toast/Tail"), "purchase toast should have an editable speech-bubble tail")
	_assert((scene.get_node("Toast") as Control).position.y < 340.0, "purchase toast should sit near the shopkeeper, not over the item grid bottom")
	_assert(str((scene.get_node("Header/GoldChip/Amount") as Label).text) == "5,000", "gold chip should sync with concept-style value")
	_assert(str((scene.get_node("Header/DiamondChip/Amount") as Label).text) == "120", "diamond chip should sync with concept-style value")
	_assert(str((scene.get_node("Header/EnergyChip/Amount") as Label).text) == "5 Full", "energy chip should be present")

	var chest_tab := scene.get_node("Tabs/Chest") as BaseButton
	chest_tab.pressed.emit()
	await process_frame
	_assert(str(scene.get("_active_tab")) == "chest", "element chest tab should filter")
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

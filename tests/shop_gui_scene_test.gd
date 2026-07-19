extends SceneTree

const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")
const SCENE_PATH := "res://src/ui/scenes/shop.tscn"
var _failures: Array[String] = []
var _inventory_pressed := false

class FakeShopStorage extends Node:
	var player := {"gold": 5000, "gems": 120, "stamina": 3}
	var inventory := {}
	var purchases := {}

	func load_player() -> Dictionary:
		return player.duplicate(true)

	func save_player(value: Dictionary) -> bool:
		player = value.duplicate(true)
		return true

	func load_inventory() -> Dictionary:
		return inventory.duplicate(true)

	func add_item(item_id: String, count: int = 1) -> bool:
		inventory[item_id] = int(inventory.get(item_id, 0)) + count
		return true

	func get_shop_daily_purchase_count(item_id: String) -> int:
		return int(purchases.get(item_id, 0))

	func record_shop_daily_purchase(item_id: String, count: int = 1) -> bool:
		purchases[item_id] = int(purchases.get(item_id, 0)) + count
		return true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	TestSceneCleanup.mute_audio_for_test(self)
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "shop scene should load")
	if packed == null:
		await _finish()
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	await process_frame
	scene.call("init", {})
	scene.set("player_data", {"gold": 5000, "gems": 120})
	scene.call("_sync_gui")
	await process_frame

	_assert(scene.scene_file_path == SCENE_PATH, "shop should be a PackedScene GUI")
	for chip_path in ["Header/GoldChip", "Header/DiamondChip", "Header/EnergyChip"]:
		_assert(not (scene.get_node(chip_path + "/Plus") as Control).visible, "%s currency add icon should be hidden" % chip_path)
	_assert(scene.has_node("TitlePlaque/Title"), "shop should use the concept-style title plaque")
	_assert(not scene.has_node("Header/BackButton"), "shop concept should not keep the legacy top-left back button")
	_assert(scene.has_node("Tabs/Gems"), "all tab should be editable")
	_assert(scene.has_node("Tabs/Coins"), "capture tab should be editable")
	_assert(scene.has_node("Tabs/Hearts"), "battle tab should be editable")
	_assert(scene.has_node("Tabs/Boosters"), "other tab should be editable")
	_assert(not (scene.get_node("Tabs/Chest") as Control).visible, "legacy fifth tab should be hidden")
	_assert(scene.has_node("ProductGrid/Cards/Card9"), "nine product cards should be editable")
	_assert(int(scene.call("_max_shop_page")) >= 2, "expanded shop item list should paginate beyond the first 9 cards")
	_assert(not (scene.get_node("ProductGrid/PageControls/NextButton") as BaseButton).disabled, "expanded shop should enable next-page control on all-items tab")
	_assert(not scene.has_node("ProductGrid/Cards/Card1/BuyButton"), "product cards should not use a separate buy button")
	_assert(scene.get_node("ProductGrid/Cards/Card1/Frame") is TextureRect, "product cards should use image-2 extracted card art")
	_assert((scene.get_node("ProductGrid/Cards/Card1/Frame") as TextureRect).texture.resource_path.ends_with("assets/images/ui/cards/shop_ui_shop_card_panel_image2_clean.png"), "product card art should come from the current image-2 transparent asset")
	_assert(scene.get_node("ProductGrid/Cards/Card1/Price/Frame") is TextureRect, "price buttons should use image-2 extracted art")
	_assert(scene.get_node("Tabs/Gems/Frame") is TextureRect, "shop tabs should use image-2 extracted tab art")
	_assert((scene.get_node("BottomNav/HomeButton") as Control).visible, "shop bottom nav should keep the home button")
	_assert((scene.get_node("BottomNav/InventoryButton") as Control).visible, "shop bottom nav second slot should open inventory")
	scene.inventory_pressed.connect(func(): _inventory_pressed = true)
	(scene.get_node("BottomNav/InventoryButton") as TextureButton).pressed.emit()
	await process_frame
	_assert(_inventory_pressed, "shop inventory navigation should emit a route signal")
	_assert((scene.get_node("BottomNav/BattleButton") as Control).visible, "shop bottom nav should expose the battle map")
	_assert((scene.get_node("BottomNav/ShopButton") as Control).visible and (scene.get_node("BottomNav/ShopButton/Text") as Label).text == "课堂", "shop bottom nav should expose classroom")
	_assert((scene.get_node("BottomNav/MenuButton") as Control).visible and (scene.get_node("BottomNav/MenuButton/Text") as Label).text == "旅馆", "shop bottom nav should expose hotel/team")
	_assert((scene.get_node("BottomNav/Frame") as TextureRect).texture.resource_path.ends_with("assets/images/ui/icons/main_ui_bottom_nav_panel_v3.png"), "shop bottom nav should reuse main lobby art")
	_assert(scene.has_node("PopupOverlay/Panel/ConfirmButton"), "popup should be editable")
	_assert(scene.has_node("Toast/Tail"), "purchase toast should have an editable speech-bubble tail")
	_assert((scene.get_node("Toast") as Control).position.y < 340.0, "purchase toast should sit near the shopkeeper, not over the item grid bottom")
	_assert(str((scene.get_node("Header/GoldChip/Amount") as Label).text) == "5,000", "gold chip should sync with concept-style value")
	_assert(str((scene.get_node("Header/DiamondChip/Amount") as Label).text) == "120", "diamond chip should sync with concept-style value")
	scene.set("player_data", {"gold": 5000, "gems": 120, "stamina": 3})
	scene.call("_sync_gui")
	_assert(str((scene.get_node("Header/EnergyChip/Amount") as Label).text) == "3/5", "energy chip should sync with player stamina")

	var capture_tab := scene.get_node("Tabs/Coins") as BaseButton
	capture_tab.pressed.emit()
	await process_frame
	_assert(str(scene.get("_active_tab")) == "capture", "capture tab should filter")
	_assert(int(scene.get("_shop_page")) == 0, "tab switch should reset page")
	_assert((scene.get_node("ProductGrid/Cards/Card1") as Control).visible, "filtered card should render")

	var card := scene.get_node("ProductGrid/Cards/Card1") as BaseButton
	card.pressed.emit()
	await process_frame
	_assert((scene.get_node("PopupOverlay") as Control).visible, "card tap should open popup")
	_assert(str((scene.get_node("PopupOverlay/Panel/Quantity") as Label).text) == "1", "popup quantity should start at one")
	_assert(str((scene.get_node("PopupOverlay/Panel/EffectText") as Label).text).contains("+20%"), "capture-ball popup should show its actual success-rate bonus")
	_assert(str((scene.get_node("PopupOverlay/Panel/UsageText") as Label).text).contains("自动捕捉球"), "capture item popup should explain where it is activated")
	_assert((scene.get_node("PopupOverlay/Panel") as Control).size.y >= 345.0, "popup should reserve enough vertical space for effect and usage")

	var plus_ten := scene.get_node("PopupOverlay/Panel/PlusTenButton") as BaseButton
	plus_ten.pressed.emit()
	await process_frame
	_assert(str((scene.get_node("PopupOverlay/Panel/Quantity") as Label).text) == "10", "quantity should stop at the daily purchase limit")

	var minus := scene.get_node("PopupOverlay/Panel/MinusButton") as BaseButton
	minus.pressed.emit()
	await process_frame
	_assert(str((scene.get_node("PopupOverlay/Panel/Quantity") as Label).text) == "9", "minus should update quantity")

	var cancel := scene.get_node("PopupOverlay/Panel/CancelButton") as BaseButton
	cancel.pressed.emit()
	await process_frame
	_assert(not (scene.get_node("PopupOverlay") as Control).visible, "cancel should hide popup")

	var fake_storage := FakeShopStorage.new()
	root.add_child(fake_storage)
	scene.set("_storage", fake_storage)
	scene.set("player_data", fake_storage.player.duplicate(true))
	scene.call("_confirm_purchase", "capture_ball", 10)
	_assert(int(fake_storage.inventory.get("capture_ball", 0)) == 10, "purchase should grant items up to the daily limit")
	_assert(int(fake_storage.purchases.get("capture_ball", 0)) == 10, "purchase should persist today's purchase count")
	_assert(int(fake_storage.player.get("gold", 0)) == 2000, "purchase should deduct the 1.3.2 configured gold price")
	scene.call("_confirm_purchase", "capture_ball", 1)
	_assert(int(fake_storage.inventory.get("capture_ball", 0)) == 10, "purchase beyond the daily limit should be rejected")
	_assert(int(fake_storage.player.get("gold", 0)) == 2000, "rejected purchase should not deduct currency")
	_assert(str(scene.call("_get_limit_text", scene.get("shop_list")[0])) == "每日限购 0/10", "limit label should show today's remaining quantity")

	scene.call("_show_toast", "获得 经验药水 x1", "success")
	await process_frame
	_assert((scene.get_node("Toast") as Control).visible, "purchase toast should show as a speech bubble")

	await _finish()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)

func _finish() -> void:
	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("[ShopGuiSceneTest] passed")
		quit(0)
	else:
		for failure in _failures:
			push_error("[ShopGuiSceneTest] %s" % failure)
		quit(1)

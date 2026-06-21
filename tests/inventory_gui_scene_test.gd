extends SceneTree

const SCENE_PATH := "res://src/ui/scenes/inventory.tscn"
var _shop_pressed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "inventory scene should load")
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	await process_frame
	scene.call("init", {})
	await process_frame

	_assert(scene.scene_file_path == SCENE_PATH, "inventory should be a PackedScene GUI")
	_assert(scene.has_node("Tabs/All"), "tab nodes should be editable")
	_assert(scene.has_node("GridPanel/Slots/Slot1"), "slot nodes should be editable")
	_assert(scene.has_node("GridPanel/PageControls/NextButton"), "page buttons should exist")
	_assert(scene.has_node("DetailPanel/UseButton"), "use button should be editable")
	_assert(scene.has_node("DetailPanel/BattleSlots/Slot1"), "battle equip slot 1 should be editable")
	_assert(scene.has_node("DetailPanel/BattleSlots/Slot2"), "battle equip slot 2 should be editable")
	_assert(scene.has_node("DetailPanel/BattleSlots/Slot3"), "battle equip slot 3 should be editable")
	_assert(scene.has_node("BottomNav/HomeButton"), "inventory should reuse the shop home navigation button")
	_assert(scene.has_node("BottomNav/ShopButton"), "inventory should provide a shop navigation button")
	_assert(not (scene.get_node("BottomNav/ShopButton/Selected") as Control).visible, "shop navigation should not look selected while viewing inventory")
	_assert((scene.get_node("BottomNav/ShopButton/Text") as Label).text == "商店", "shop navigation should use the shop label")
	_assert((scene.get_node("BottomNav/ShopButton/Icon") as TextureRect).texture.resource_path.ends_with("common_nav_icon_nav_shop.png"), "shop navigation should use the shop icon")
	_shop_pressed = false
	scene.shop_pressed.connect(_on_shop_pressed)
	(scene.get_node("BottomNav/ShopButton") as TextureButton).pressed.emit()
	await process_frame
	_assert(_shop_pressed, "shop navigation should trigger the shop action")
	_assert((scene.get_node("DetailPanel") as Control).position.y + (scene.get_node("DetailPanel") as Control).size.y <= (scene.get_node("BottomNav") as Control).position.y, "compact detail panel should leave room for bottom navigation")

	scene.set("_inventory", {
		"capture_ball": 3,
		"capture_ball_plus": 1,
		"exp_potion": 5,
		"exp_crystal": 2,
		"hp_potion": 1,
		"gold_bag": 4,
		"gold_chest": 1,
		"evolution_stone_fire": 1,
		"evolution_stone_water": 1,
		"evolution_stone_grass": 1,
		"evolution_stone_thunder": 1,
		"evolution_stone_light": 1,
		"evolution_stone_earth": 1,
		"evolution_stone_wind": 1,
		"evolution_stone_dark": 1,
	})
	scene.set("_player", {"gold": 1280, "gems": 36})
	scene.call("_build_item_list")
	scene.call("_sync_gui")
	await process_frame

	_assert(str((scene.get_node("Header/GoldChip/Amount") as Label).text) == "1,280", "gold chip should sync")
	_assert(not (scene.get_node("DetailPanel/EmptyText") as Label).visible, "first item should auto-select")

	var gems := scene.get_node("Tabs/Gems") as BaseButton
	gems.pressed.emit()
	await process_frame
	_assert(str(scene.get("_active_tab")) == "gems", "gems tab should filter")
	_assert(int(scene.get("_inventory_page")) == 0, "tab switch should reset page")
	_assert(not (scene.get_node("GridPanel/Slots/Slot1/Icon") as TextureRect).texture == null, "filtered item should render")

	var slot := scene.get_node("GridPanel/Slots/Slot1") as BaseButton
	slot.pressed.emit()
	await process_frame
	_assert(not (scene.get_node("DetailPanel/Content/IconFrame/Icon") as TextureRect).texture == null, "slot press should show detail icon")

	var all := scene.get_node("Tabs/All") as BaseButton
	all.pressed.emit()
	await process_frame
	var next := scene.get_node("GridPanel/PageControls/NextButton") as BaseButton
	next.pressed.emit()
	await process_frame
	_assert(int(scene.get("_inventory_page")) == 0, "single page inventory should not advance")

	var use_button := scene.get_node("DetailPanel/UseButton") as BaseButton
	_assert(not use_button.disabled, "use button should be enabled with selected item")

	print("[InventoryGuiSceneTest] passed")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[InventoryGuiSceneTest] %s" % message)
	quit(1)

func _on_shop_pressed() -> void:
	_shop_pressed = true

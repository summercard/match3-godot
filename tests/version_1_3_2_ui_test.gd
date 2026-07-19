extends SceneTree

const ItemDBScript := preload("res://src/data/item_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_shared_navigation_and_shop_popup()
	await _test_album_detail_tabs()
	_test_ranch_layout_and_timing()
	_finish()


func _test_shared_navigation_and_shop_popup() -> void:
	var inventory := load("res://src/ui/scenes/inventory.tscn").instantiate() as Control
	var inventory_paths := ["HomeButton", "ShopButton", "BattleButton", "ClassroomButton", "HotelButton"]
	var inventory_labels := ["主页", "商店", "战场", "课堂", "旅馆"]
	for index in inventory_paths.size():
		var path := "BottomNav/%s" % inventory_paths[index]
		_expect(inventory.has_node(path) and (inventory.get_node(path) as Control).visible, "inventory should expose the complete five-entry bottom navigation")
		_expect((inventory.get_node(path + "/Text") as Label).text == inventory_labels[index], "inventory navigation labels should match the shared destination order")
	inventory.free()

	var shop := load("res://src/ui/scenes/shop.tscn").instantiate() as Control
	root.add_child(shop)
	await process_frame
	shop.call("init", {})
	await process_frame
	for index in range(1, 10):
		_expect(not (shop.get_node("ProductGrid/Cards/Card%d/BestRibbon" % index) as Control).visible, "shop card %d should hide the removed best-value ribbon" % index)
	var popup := shop.get_node("PopupOverlay/Panel") as Control
	_expect(popup.size.y >= 385.0, "shop popup should reserve full-height effect and usage copy")
	_expect(str(shop.call("_shop_effect_text", ItemDBScript.get_item("capture_ball"))).contains("+20%"), "shop popup formatter should expose the capture ball's actual numeric effect")
	_expect(str(shop.call("_shop_usage_text", ItemDBScript.get_item("capture_ball"))).contains("自动捕捉球"), "shop popup formatter should explain the capture ball activation path")
	shop.queue_free()
	await process_frame


func _test_album_detail_tabs() -> void:
	var album := load("res://src/ui/scenes/album.tscn").instantiate() as Control
	root.add_child(album)
	await process_frame
	album.call("init", {})
	await process_frame
	_expect((album.get_node("DetailPanel/SkillPanel/Name") as Label).get_theme_font_size("font_size") >= 18, "album skill name should use at least 18px type")
	_expect((album.get_node("DetailPanel/SkillPanel/Desc") as Label).get_theme_font_size("font_size") >= 18, "album skill description should use at least 18px type")
	_expect((album.get_node("DetailPanel/EcologyPanel") as RichTextLabel).get_theme_font_size("normal_font_size") >= 18, "album ecology copy should use readable 18px type")
	var captured: Array = album.get("_captured_ids")
	_expect(not captured.is_empty(), "album UI test should have a starter species to open")
	if not captured.is_empty():
		album.set("_selected_monster_id", str(captured[0]))
		album.call("_sync_gui")
		album.call("_on_detail_info_tab_pressed", "ecology")
		_expect((album.get_node("DetailPanel/EcologyPanel") as Control).visible, "ecology tab should replace the skill/evolution content")
		_expect(not (album.get_node("DetailPanel/SkillPanel") as Control).visible, "ecology tab should hide the skill panel")
		album.call("_on_detail_info_tab_pressed", "skill")
		_expect((album.get_node("DetailPanel/SkillPanel") as Control).visible, "skill tab should restore the skill panel")
	album.queue_free()
	await process_frame


func _test_ranch_layout_and_timing() -> void:
	var ranch := load("res://src/ui/scenes/ranch_hub.tscn").instantiate() as Control
	var slots := ranch.get_node("Pages/RanchPage/Slots") as Control
	_expect(is_equal_approx(slots.position.y, 10.0), "the five idle ranch slots should move down ten pixels as a group")
	for index in range(1, 6):
		_expect(slots.has_node("Slot%d" % index), "ranch should retain idle slot %d" % index)
	var constants: Dictionary = (ranch.get_script() as GDScript).get_script_constant_map()
	_expect(is_equal_approx(float(constants.get("HARVEST_FEEDBACK_DURATION", 0.0)), 0.44), "ranch harvest feedback should finish in 0.44 seconds")
	ranch.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[Version132UI] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[Version132UI] " + failure)
	quit(1)

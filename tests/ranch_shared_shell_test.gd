extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed_ranch := load("res://src/ui/scenes/ranch_hub.tscn") as PackedScene
	var static_ranch := packed_ranch.instantiate() as Control
	for path in [
		"PetFarmResourceBar",
		"PetFarmBottomNav/Nav5",
		"Pages/ClassroomPage/DetailPanel/EvolveButton/ModernFrame",
		"Pages/SocialPage/BondPanel",
		"Pages/SocialPage/BondPanel/Heart",
		"Pages/SocialPage/PlacePanel/FxLayer/HeartFx4",
		"Pages/SocialPage/PlacePanel/SwitchButton/SocialFrame",
		"Pages/SocialPage/BottomButtons/ActionButton/SocialFrame",
	]:
		_expect(static_ranch.has_node(path), "ranch_hub.tscn should own formal UI node before _ready: %s" % path)
	static_ranch.free()

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("ranch")
	await process_frame
	var ranch: Control = main.get_current_scene()
	_expect(ranch != null, "ranch scene should instantiate")
	if ranch == null:
		_finish()
		return

	_expect(ranch.has_node("PetFarmResourceBar"), "ranch shell should expose a shared resource bar")
	_expect(ranch.has_node("PetFarmBottomNav"), "ranch shell should expose a shared bottom navigation bar")
	_expect(ranch.has_node("SharedToast"), "ranch shell should expose animated shared text feedback")
	for path in [
		"Pages/ClassroomPage/RosterPanel/Card6",
		"Pages/SocialPage/RosterPanel/Card6",
		"Pages/SocialPage/BondPanel",
		"PetFarmBottomNav/Nav2/Selected",
		"PetFarmBottomNav/Nav3/Selected",
		"PetFarmBottomNav/Nav4/Selected",
	]:
		_expect(ranch.has_node(path), "shared shell node should exist: %s" % path)

	var roster: Array = []
	for i in 13:
		roster.append({
			"instanceId": "shared_shell_%02d" % i,
			"monsterId": "monster_%03d" % ((i % 6) + 1),
			"level": i + 1,
			"nature": "brave",
		})
	ranch.set("_storage", null)
	ranch.set("_captured_monsters", roster)
	ranch.call("_switch_to_classroom")
	_expect(not (ranch.get_node("Header/BackButton") as TextureButton).visible, "classroom should hide the legacy back arrow")
	_expect(ranch.has_node("Pages/ClassroomPage/DetailPanel/EvolveButton/ModernFrame"), "classroom evolve action should use the modern green frame")
	_expect(not (ranch.get_node("Pages/ClassroomPage/DetailPanel/EvolveButton/Frame") as TextureRect).visible, "classroom evolve action should hide the legacy frame")
	ranch.call("_on_class_next_pressed")
	_expect(int(ranch.get("_class_page")) == 1, "classroom pagination should advance independently")
	_expect(int(ranch.get("_social_page")) == 0, "classroom pagination should not alter social pagination")
	_expect((ranch.get_node("PetFarmBottomNav/Nav3/Selected") as TextureRect).visible, "classroom nav marker should be visible")
	_expect((ranch.get_node("Background") as TextureRect).texture.resource_path.ends_with("bg_pet_academy_750.png"), "classroom should switch to academy background")
	(ranch.get_node("PetFarmBottomNav/Nav2") as Button).pressed.emit()
	_expect(str(ranch.get("_active_page")) == "ranch", "farm nav should return from classroom")
	_expect((ranch.get_node("Header/BackButton") as TextureButton).visible, "farm page should retain the lobby back arrow")

	ranch.call("_switch_to_social")
	_expect(not (ranch.get_node("Header/BackButton") as TextureButton).visible, "social page should hide the legacy back arrow")
	ranch.call("_on_social_next_pressed")
	_expect(int(ranch.get("_social_page")) == 1, "social pagination should advance independently")
	_expect(int(ranch.get("_class_page")) == 1, "social pagination should not alter classroom pagination")
	_expect((ranch.get_node("PetFarmBottomNav/Nav4/Selected") as TextureRect).visible, "social nav marker should be visible")
	_expect((ranch.get_node("Background") as TextureRect).texture.resource_path.ends_with("bg_social_meadow_yard_750.png"), "social should start with clean lodge background")
	_expect(not (ranch.get_node("Pages/SocialPage/PlacePanel/Frame") as TextureRect).visible, "social stage should hide the legacy dark panel")
	_expect(ranch.get_node("Pages/SocialPage/PlacePanel/HeartBubble") is TextureRect, "social center heart should use extracted art asset")
	_expect(ranch.get_node("Pages/SocialPage/BondPanel/Heart") is TextureRect, "social bond heart should use extracted art asset")
	_expect(not (ranch.get_node("Pages/SocialPage/PlacePanel/SwitchButton/Frame") as TextureRect).visible, "social place switch should hide the legacy texture button")
	_expect(ranch.has_node("Pages/SocialPage/PlacePanel/SwitchButton/SocialFrame"), "social place switch should use the modern orange frame")
	_expect(ranch.has_node("Pages/SocialPage/BottomButtons/ActionButton/SocialFrame"), "social action should use the card-level orange frame")
	ranch.call("_on_place_switch_pressed")
	_expect((ranch.get_node("Background") as TextureRect).texture.resource_path.ends_with("bg_social_sunny_yard_750.png"), "social place cycling should replace the scene background")
	(ranch.get_node("PetFarmBottomNav/Nav2") as Button).pressed.emit()
	_expect(str(ranch.get("_active_page")) == "ranch", "farm nav should return from social page")

	main.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchSharedShell] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchSharedShell] " + failure)
	quit(1)

extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	if storage != null:
		storage.clear_all_data()
		var player: Dictionary = storage.get_player()
		player["level"] = 25
		storage.save_player(player)
	var packed := load("res://src/ui/scenes/ranch_hub.tscn") as PackedScene
	_expect(packed != null, "ranch hub should load as a formal PackedScene")
	if packed != null:
		var authored := packed.instantiate() as Control
		for path in [
			"PetFarmResourceBar",
			"PetFarmBottomNav/Nav2/Selected",
			"Pages/ClassroomPage/DetailPanel/EvolveButton/butter02",
			"Pages/SocialPage/PlacePanel/SwitchButton/butter01",
			"Pages/SocialPage/BottomButtons/ActionButton/butter01",
			"Pages/SocialPage/PlacePanel/FxLayer/HeartFx4",
		]:
			_expect(authored.has_node(path), "ranch hub should keep authored shell node: %s" % path)
		authored.free()

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.switch_scene("ranch")
	await process_frame
	var ranch := main.get_current_scene() as Control
	_expect(ranch != null, "ranch scene should instantiate")
	if ranch != null:
		ranch.call("_switch_to_classroom")
		_expect((ranch.get_node("PetFarmBottomNav/Nav3/Selected") as TextureRect).visible, "classroom navigation marker should be visible")
		_expect((ranch.get_node("Background") as TextureRect).texture != null, "classroom should render a background")
		ranch.call("_switch_to_social")
		_expect((ranch.get_node("PetFarmBottomNav/Nav4/Selected") as TextureRect).visible, "social navigation marker should be visible")
		_expect((ranch.get_node("Pages/SocialPage/PlacePanel/HeartBubble") as TextureRect).texture != null, "social page should render its relationship art")
		ranch.call("_on_pet_farm_pets")
		_expect(str(ranch.get("_active_page")) == "ranch", "pet-farm navigation should return to the ranch page")

	root.remove_child(main)
	main.free()
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

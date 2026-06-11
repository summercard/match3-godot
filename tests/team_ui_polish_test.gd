extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Control.new()
	scene.set_script(load("res://src/ui/controllers/team_logic.gd"))
	scene.size = Vector2(375.0, 667.0)
	root.add_child(scene)
	scene.call("init", {})
	await process_frame

	var touch_targets := [
		"_back_btn", "_help_btn", "_filter_all_btn", "_filter_cycle_btn",
		"_sort_btn", "_roster_prev_btn", "_roster_next_btn", "_cancel_btn", "_save_btn"
	]
	for property_name in touch_targets:
		var rect: Rect2 = scene.get(property_name)
		_expect(rect.size.y >= 44.0, "%s must keep a 44px mobile touch height" % property_name)

	scene.set("_captured_monsters", [
		{"instanceId": "fire_a", "monsterId": "monster_001", "level": 12},
		{"instanceId": "water_a", "monsterId": "monster_002", "level": 10},
		{"instanceId": "grass_a", "monsterId": "monster_003", "level": 9}
	])
	scene.set("_team", {"leader": null, "member1": null, "member2": null})

	_tap(scene, scene.get("_help_btn"))
	_expect(bool(scene.get("_show_help")), "help button should open instructions")
	_tap(scene, Rect2(96.0, 385.0, 183.0, 46.0))
	_expect(not bool(scene.get("_show_help")), "help dialog should dismiss on tap")

	_tap(scene, scene.get("_filter_cycle_btn"))
	_expect(str(scene.get("_active_filter")) == "fire", "attribute filter should cycle to fire")
	var filtered: Array = scene.call("_get_display_monsters")
	_expect(filtered.size() == 1 and filtered[0].get("monsterId") == "monster_001", "fire filter should change visible roster")

	_tap(scene, scene.get("_filter_all_btn"))
	_tap(scene, scene.get("_sort_btn"))
	_expect(int(scene.get("_sort_option")) == 1, "sort button should cycle sort mode")

	var first_card := Rect2(24.0, 377.0, 74.0, 84.0)
	_tap(scene, first_card)
	_expect(scene.get("_team").get("leader") != null, "monster card should assign into an open team slot")

	scene.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[TeamUiPolish] OK")
		quit(0)
	else:
		for failure in _failures:
			push_error("[TeamUiPolish] " + failure)
		quit(1)

func _tap(scene: Control, rect: Rect2) -> void:
	var pos := rect.get_center()
	scene.call("_on_tap", pos.x, pos.y)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

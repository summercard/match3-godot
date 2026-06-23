extends SceneTree

const SCENE_PATH := "res://src/ui/scenes/team.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_expect(packed != null, "team polish test should load the formal team.tscn")
	if packed == null:
		_finish()
		return
	var scene := packed.instantiate() as Control
	_expect(scene != null, "team.tscn should instantiate")
	if scene == null:
		_finish()
		return
	root.add_child(scene)
	await process_frame

	_expect(scene.scene_file_path == SCENE_PATH, "team polish test should keep team.tscn as the runtime source")
	_expect(not str(scene.get_script().resource_path).contains("team_logic.gd"), "team polish test should not attach the old draw controller")

	var touch_targets := [
		"TeamSlots/Member1Slot",
		"TeamSlots/LeaderSlot",
		"TeamSlots/Member2Slot",
		"RosterPanel/Cards/Card1",
		"RosterPanel/Cards/Card2",
		"RosterPanel/PageControls/PreviousButton",
		"RosterPanel/PageControls/NextButton",
		"BottomNav/HomeButton",
		"BottomNav/PetsButton",
		"BottomNav/BattleButton",
		"BottomNav/ShopButton",
		"BottomNav/MenuButton",
	]
	for path in touch_targets:
		var control := scene.get_node_or_null(path) as Control
		_expect(control != null, "%s should exist in team.tscn" % path)
		if control != null:
			_expect(control.size.x >= 44.0 and control.size.y >= 44.0, "%s must keep a 44px mobile touch target" % path)

	for path in ["TeamSlots/LeaderSlot", "RosterPanel/Cards/Card1", "BottomNav/BattleButton"]:
		var button := scene.get_node_or_null(path) as BaseButton
		_expect(button != null and button.has_node("CartoonFeedback"), "%s should have formal button feedback" % path)

	scene.set("_captured_monsters", [
		{"instanceId": "fire_a", "monsterId": "monster_001", "level": 12},
		{"instanceId": "water_a", "monsterId": "monster_002", "level": 10},
		{"instanceId": "grass_a", "monsterId": "monster_003", "level": 9},
	])
	scene.set("_team", {"leader": null, "member1": null, "member2": null})
	scene.call("_rebuild_instance_index")
	scene.call("_rebuild_display_monsters_cache")
	scene.call("_assign_to_slot", "fire_a")
	var team: Dictionary = scene.get("_team")
	_expect(team.get("leader") == "fire_a", "formal team assignment should fill an open leader slot")

	scene.set_process(false)
	for property_name in ["_texture_cache", "_team_portrait_cache", "_roster_texture_cache", "_pending_portrait_loads"]:
		var value: Variant = scene.get(property_name)
		if value is Dictionary:
			(value as Dictionary).clear()
	root.remove_child(scene)
	scene.free()
	for _i in range(3):
		await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TeamUiPolish] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TeamUiPolish] " + failure)
	quit(1)

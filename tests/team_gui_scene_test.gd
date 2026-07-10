extends SceneTree

const SCENE_PATH := "res://src/ui/scenes/team.tscn"
const GUI_SCRIPT_PATH := "res://src/ui/scene/scene_team_gui.gd"

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_script := load("res://main.gd") as GDScript
	_assert(main_script != null, "main script should load")
	var scene_map: Dictionary = main_script.get_script_constant_map().get("PACKED_SCENE_MAP", {})
	_assert(str(scene_map.get("team", "")) == SCENE_PATH, "team route should use the editable team.tscn PackedScene")

	var packed := load(SCENE_PATH) as PackedScene
	_assert(packed != null, "team scene should load as PackedScene")
	var scene := packed.instantiate() as Control
	_assert(scene != null, "team scene should instantiate as Control")
	_assert(scene.scene_file_path == SCENE_PATH, "team scene should keep team.tscn as its formal source")
	_assert(scene.get_script() != null and scene.get_script().resource_path == GUI_SCRIPT_PATH, "team root should use the GUI sync script")
	for chip_path in ["CurrencyBar/GoldChip", "CurrencyBar/DiamondChip", "CurrencyBar/HeartChip"]:
		_assert(not (scene.get_node(chip_path + "/Plus") as Control).visible, "%s currency add icon should be hidden" % chip_path)

	for path in [
		"CurrencyBar/GoldChip/Amount",
		"TeamSlots/Member1Slot/EmptyPlus",
		"TeamSlots/Member1Slot/MonsterPosition/Portrait",
		"TeamSlots/LeaderSlot/MonsterPosition/Portrait",
		"TeamSlots/Member2Slot/MonsterPosition/Portrait",
		"TeamSlots/LeaderSlot/Label/LeaderBadge",
		"TeamSlots/LeaderSlot/Label/Text",
		"TeamSlots/Member2Slot/Label/Text",
		"PowerPanel/Power",
		"PowerPanel/Stats/Hp/Value",
		"PowerPanel/Stats/Atk/Value",
		"PowerPanel/Stats/Def/Value",
		"PowerPanel/Stats/Spd/Value",
		"RosterPanel/Frame/black/NinePatch",
		"RosterPanel/Cards/Card1/Portrait",
		"RosterPanel/Cards/Card4/Check",
		"RosterPanel/PageControls/PageLabel",
		"BottomNav/BattleButton/Selected",
		"EntryAnim",
	]:
		_assert(scene.has_node(path), "team.tscn should own editable node: %s" % path)

	root.add_child(scene)
	await process_frame
	scene.call("init", {})
	await process_frame

	_assert(scene.scene_file_path == SCENE_PATH, "runtime init should not replace the editable PackedScene")
	_assert(scene.has_node("RosterPanel/Cards/Card6/Level"), "runtime sync should keep roster card nodes editable")
	_assert(not str(scene.get_script().resource_path).contains("team_logic.gd"), "team GUI should not inherit the old draw controller")
	for slot_path in ["TeamSlots/Member1Slot", "TeamSlots/LeaderSlot", "TeamSlots/Member2Slot"]:
		var position_component := scene.get_node(slot_path + "/MonsterPosition") as Control
		var portrait := position_component.get_node("Portrait") as TextureRect
		_assert(position_component.size.x > 0.0 and position_component.size.y > 0.0, "%s should expose an editable monster position component" % slot_path)
		_assert(portrait.texture != null, "%s should show a preview monster in team.tscn" % slot_path)
	scene.set("_team", {"leader": "monster_001", "member1": null, "member2": null})
	scene.call("_sync_team_slots")
	_assert((scene.get_node("TeamSlots/LeaderSlot/Label/LeaderBadge") as CanvasItem).visible, "nested leader badge should show for an occupied leader slot")
	_assert((scene.get_node("TeamSlots/LeaderSlot/Label/Text") as CanvasItem).visible, "leader text should show for an occupied leader slot")

	scene.set("_team", {"leader": null, "member1": null, "member2": null})
	scene.set("_selected_slot", "")
	scene.call("_assign_to_slot", "monster_001")
	var team: Dictionary = scene.get("_team")
	_assert(team.get("leader") == "monster_001", "first roster tap should assign the monster to the leader slot")
	_assert(team.get("member1") == null and team.get("member2") == null, "first roster tap should not duplicate the monster into other slots")
	scene.call("_assign_to_slot", "monster_001")
	team = scene.get("_team")
	_assert(team.get("leader") == null and team.get("member1") == null and team.get("member2") == null, "second roster tap on an assigned monster should remove it from the team")

	scene.set("_team", {"leader": "monster_002", "member1": "monster_002", "member2": "monster_002"})
	scene.set("_selected_slot", "")
	scene.call("_assign_to_slot", "monster_002")
	team = scene.get("_team")
	_assert(team.get("leader") == null and team.get("member1") == null and team.get("member2") == null, "tapping a duplicated assigned monster should clear all duplicate slots")

	scene.set_process(false)
	for _i in range(30):
		var pending: Dictionary = scene.get("_pending_portrait_loads")
		if pending.is_empty():
			break
		scene.call("_poll_portrait_loads")
		await process_frame
	for property_name in ["_texture_cache", "_team_portrait_cache", "_roster_texture_cache", "_pending_portrait_loads"]:
		var value: Variant = scene.get(property_name)
		if value is Dictionary:
			(value as Dictionary).clear()
	root.remove_child(scene)
	scene.free()
	for _i in range(3):
		await process_frame

	print("[TeamGuiSceneTest] passed")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[TeamGuiSceneTest] %s" % message)
	quit(1)

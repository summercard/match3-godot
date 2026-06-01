extends SceneTree

class StartHarness:
	extends Control

	var switched_to := ""

	func switch_scene(scene_name: String, _data: Dictionary = {}) -> void:
		switched_to = scene_name


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var harness := StartHarness.new()
	root.add_child(harness)
	var scene: Control = load("res://src/ui/scenes/start_screen.tscn").instantiate()
	harness.add_child(scene)
	await process_frame

	for path in [
		"Background",
		"Content/Logo",
		"Content/Monsters/FireMonster",
		"Content/Monsters/WaterMonster",
		"Content/Monsters/GrassMonster",
		"Content/Gems/FireGem",
		"Content/Gems/WaterGem",
		"Content/Gems/GrassGem",
		"Content/Gems/ThunderGem",
		"Content/Gems/LightGem",
		"Content/StartButton",
		"Content/HintGroup",
		"Content/VersionPlaque",
	]:
		_expect(scene.get_node_or_null(path) != null, "editable node should exist: %s" % path)

	var button := scene.get_node("Content/StartButton") as TextureButton
	_expect(not button.disabled, "start button should begin enabled")
	button.button_down.emit()
	await process_frame
	_expect(button.disabled, "single button-down should enter immediately")
	_expect(not harness.switched_to.is_empty(), "single button-down should request a destination scene")

	harness.free()
	if _failed:
		quit(1)
		return
	print("[StartGuiScene] OK")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[StartGuiScene] %s" % message)

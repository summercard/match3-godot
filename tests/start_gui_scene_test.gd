extends SceneTree

const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")

class StartHarness:
	extends Control

	var switched_to := ""

	func switch_scene(scene_name: String, _data: Dictionary = {}) -> void:
		switched_to = scene_name


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	TestSceneCleanup.mute_audio_for_test(self)
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
	_expect(button.has_node("CartoonFeedback"), "start button should expose cartoon feedback")
	var feedback_profile: Dictionary = button.get_node("CartoonFeedback").call("get_feedback_profile")
	_expect(float(feedback_profile.get("press_scale", 1.0)) < 1.0, "start feedback should compress on press")
	_expect(float(feedback_profile.get("hover_scale", 1.0)) > 1.0, "start feedback should lift on hover")
	_expect(bool(feedback_profile.get("burst", false)), "start feedback should expose a release burst")
	button.button_down.emit()
	button.button_up.emit()
	button.pressed.emit()
	await create_timer(0.28).timeout
	_expect(button.disabled, "single press should enter after the feedback beat")
	_expect(not harness.switched_to.is_empty(), "single press should request a destination scene")

	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
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

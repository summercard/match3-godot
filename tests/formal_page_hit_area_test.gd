extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_scene("achievement", "res://src/ui/scenes/achievement.tscn", [
		"ContentPanels/AchievementListScroll",
		"HitAreas/Tabs/TabAll",
		"HitAreas/Tabs/TabBattle",
		"HitAreas/BottomNav/HomeButton",
		"HitAreas/BottomNav/SettingsButton",
	])
	await _check_scene("settings", "res://src/ui/scenes/settings.tscn", [
		"ContentPanels/MainPanel",
		"HitAreas/BackButton",
		"HitAreas/Rows/SoundRow",
		"HitAreas/Rows/MusicRow",
		"HitAreas/Actions/ResetButton",
		"HitAreas/ConfirmDialog/YesButton",
	])
	await _check_scene("sign_in", "res://src/ui/scenes/sign_in.tscn", [
		"ContentPanels/HeroPanel",
		"ContentPanels/MonthPanel",
		"HitAreas/BackButton",
		"HitAreas/ClaimButton",
	])
	await _check_scene("tutorial", "res://src/ui/scenes/tutorial.tscn", [
		"ContentPanels/BoardPreview",
		"ContentPanels/PromptPanel",
		"HitAreas/SkipButton",
		"HitAreas/NextButton",
	])
	_finish()

func _check_scene(label: String, scene_path: String, required_paths: Array[String]) -> void:
	var scene := load(scene_path).instantiate() as Control
	root.add_child(scene)
	await process_frame
	_expect(scene.get_child_count() > 1, "%s should expose editable child controls, not only a root node" % label)
	for path in required_paths:
		var node := scene.get_node_or_null(path)
		_expect(node != null, "%s should contain %s" % [label, path])
		if path.begins_with("HitAreas/"):
			_expect(node is BaseButton, "%s/%s should be a real BaseButton" % [label, path])
			if node is BaseButton:
				var button := node as BaseButton
				_expect(button.gui_input.get_connections().size() > 0, "%s/%s should route input through authored controls" % [label, path])
	if label == "settings":
		var confirm := scene.get_node_or_null("HitAreas/ConfirmDialog") as Control
		_expect(confirm != null and not confirm.visible, "settings confirm controls should be hidden until reset is requested")
	scene.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[FormalPageHitArea] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[FormalPageHitArea] " + failure)
	quit(1)

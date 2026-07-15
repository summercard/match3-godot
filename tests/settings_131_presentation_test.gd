extends SceneTree

const SceneSettingsScript = preload("res://src/ui/scene/scene_settings.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings := load("res://src/ui/scenes/settings.tscn").instantiate() as Control
	root.add_child(settings)
	await process_frame
	var rows: Array = SceneSettingsScript.SETTINGS_ROWS
	_expect(rows.size() == 2, "settings should expose only sound and music rows")
	if rows.size() == 2:
		_expect(str((rows[0] as Dictionary).get("key", "")) == "soundOn", "first row should control sound")
		_expect(str((rows[1] as Dictionary).get("key", "")) == "musicOn", "second row should control music")
	for removed_path in [
		"HitAreas/Rows/VibrationRow",
		"HitAreas/Rows/QualityLow",
		"HitAreas/Rows/PerformanceLite",
	]:
		_expect(not settings.has_node(removed_path), "%s should not retain an interactive area" % removed_path)
	_expect(settings.has_node("HitAreas/Actions/ResetButton"), "reset action must remain available")
	_expect(settings.has_node("HitAreas/Actions/DefaultButton"), "restore-default action must remain available")
	settings.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[Settings131Presentation] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[Settings131Presentation] " + failure)
	quit(1)

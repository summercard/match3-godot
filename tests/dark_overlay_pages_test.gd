extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var album := load("res://src/ui/scenes/album.tscn").instantiate() as Control
	var shade := album.get_node("Shade") as TextureRect
	_expect(shade.texture.resource_path.ends_with("ui/backgrounds/black.png"), "album should use the shared black background overlay")
	_expect(is_equal_approx(shade.modulate.a, 0.5), "album overlay should be 50 percent transparent")
	album.queue_free()

	for script_path in [
		"res://src/ui/scene/scene_achievement_gui.gd",
		"res://src/ui/scene/scene_settings.gd",
		"res://src/ui/scene/scene_sign_in.gd",
	]:
		var script := load(script_path) as GDScript
		_expect(script != null, "%s should load" % script_path)
		if script == null:
			continue
		var constants := script.get_script_constant_map()
		var assets: Dictionary = constants.get("GUI_ASSETS", constants.get("SETTINGS_ASSETS", constants.get("SIGN_ASSETS", {})))
		_expect(str(assets.get("dark_overlay", "")).ends_with("ui/backgrounds/black.png"), "%s should register the shared black overlay" % script_path)

	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[DarkOverlayPages] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[DarkOverlayPages] " + failure)
	quit(1)

extends SceneTree

const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")
const LOCALES: PackedStringArray = ["zh_CN", "zh_TW", "en", "ja", "ko", "fr", "de", "es_419"]
const TITLE_PATTERN := "res://assets/images/ui/icons/localized/start_title_logo_%s.png"
const NORMAL_PATTERN := "res://assets/images/ui/buttons/localized/start_ui_btn_start_normal_%s.png"
const PRESSED_PATTERN := "res://assets/images/ui/buttons/localized/start_ui_btn_start_pressed_%s.png"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	TestSceneCleanup.mute_audio_for_test(self)
	var localization := root.get_node_or_null("Localization")
	_expect(localization != null, "Localization autoload must be available")
	if localization == null:
		_finish()
		return

	var scene := load("res://src/ui/scenes/start_screen.tscn").instantiate() as Control
	root.add_child(scene)
	await process_frame
	var logo := scene.get_node("Content/Logo") as TextureRect
	var glow := scene.get_node("Content/StartGlow") as TextureRect
	var button := scene.get_node("Content/StartButton") as TextureButton

	for locale in LOCALES:
		_check_texture(TITLE_PATTERN % locale, Vector2i(1617, 935))
		_check_texture(NORMAL_PATTERN % locale, Vector2i(1667, 618))
		_check_texture(PRESSED_PATTERN % locale, Vector2i(1667, 618))
		localization.call("set_language_preference", locale, false)
		await process_frame
		_expect(logo.texture.resource_path == TITLE_PATTERN % locale, "%s title texture should be active" % locale)
		_expect(glow.texture.resource_path == NORMAL_PATTERN % locale, "%s glow texture should follow the localized button" % locale)
		_expect(button.texture_normal.resource_path == NORMAL_PATTERN % locale, "%s normal button texture should be active" % locale)
		_expect(button.texture_pressed.resource_path == PRESSED_PATTERN % locale, "%s pressed button texture should be active" % locale)

	localization.call("set_language_preference", "auto", false)
	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	_finish()


func _check_texture(path: String, expected_size: Vector2i) -> void:
	_expect(ResourceLoader.exists(path), "localized texture should exist: %s" % path)
	var texture := load(path) as Texture2D
	_expect(texture != null, "localized texture should load: %s" % path)
	if texture != null:
		_expect(texture.get_size() == Vector2(expected_size), "%s should keep source dimensions" % path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[WelcomeLocalizedArt] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[WelcomeLocalizedArt] " + failure)
	quit(1)

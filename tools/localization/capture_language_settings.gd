extends SceneTree

const LOCALES := ["zh_CN", "zh_TW", "en", "ja", "ko", "fr", "de", "es_419"]
const DESIGN_SIZE := Vector2(375.0, 667.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := OS.get_environment("MATCH3_LOCALIZATION_CAPTURE_DIR")
	if output_dir.is_empty():
		push_error("MATCH3_LOCALIZATION_CAPTURE_DIR is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	var localization := root.get_node_or_null("Localization")
	if localization == null:
		push_error("Localization autoload is unavailable")
		quit(1)
		return

	for locale in LOCALES:
		localization.call("set_language_preference", locale, false)
		var scene := load("res://src/ui/scenes/settings.tscn").instantiate() as Control
		scene.size = DESIGN_SIZE
		root.add_child(scene)
		for _frame in range(36):
			await process_frame
		var base_image := root.get_viewport().get_texture().get_image()
		var base_output_path := output_dir.path_join("settings_%s_base.png" % locale)
		var base_error := base_image.save_png(base_output_path)
		if base_error != OK:
			push_error("Failed to save %s (%d)" % [base_output_path, base_error])
			quit(1)
			return
		scene.set("language_dialog", true)
		if scene.has_method("_sync_authored_controls"):
			scene.call("_sync_authored_controls")
		scene.queue_redraw()
		await process_frame
		await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var output_path := output_dir.path_join("settings_%s.png" % locale)
		var error := image.save_png(output_path)
		if error != OK:
			push_error("Failed to save %s (%d)" % [output_path, error])
			quit(1)
			return
		print("[LocalizationCapture] " + output_path)
		scene.queue_free()
		await process_frame

	localization.call("set_language_preference", "auto", false)
	quit(0)

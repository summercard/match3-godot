extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var localization := root.get_node_or_null("Localization")
	print("test_env=%s os_locale=%s server_locale=%s preference=%s active=%s sample=%s" % [
		OS.get_environment("MATCH3_TEST_LOCALE"),
		OS.get_locale(),
		TranslationServer.get_locale(),
		localization.call("get_language_preference") if localization != null else "missing",
		localization.call("get_active_locale") if localization != null else "missing",
		TranslationServer.translate("克制！-%d") % 321,
	])
	var album: Control = load("res://src/ui/scenes/album.tscn").instantiate() as Control
	root.add_child(album)
	await process_frame
	var album_font := (album.get_node("AlbumPage/Grid/Card1/Name") as Label).get_theme_font("font")
	var base_path := ""
	if album_font is FontVariation and (album_font as FontVariation).base_font != null:
		base_path = (album_font as FontVariation).base_font.resource_path
	print("album_font=%s path=%s base=%s" % [album_font.get_class(), album_font.resource_path, base_path])
	album.free()
	quit(0)

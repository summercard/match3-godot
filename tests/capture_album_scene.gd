extends SceneTree

const DEFAULT_OUTPUT := "res://.godot/album_scene_check.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var output_path := _read_arg("--output=", DEFAULT_OUTPUT)
	var packed := load("res://src/ui/scenes/album.tscn") as PackedScene
	if packed == null:
		push_error("[AlbumCapture] album scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	await process_frame
	if scene.has_method("init"):
		scene.call("init", {})
	await process_frame
	var mode := _read_arg("--album-mode=", "album")
	if mode == "bond" and scene.has_node("LobbyBottomNav/BattleButton"):
		(scene.get_node("LobbyBottomNav/BattleButton") as BaseButton).pressed.emit()
	elif mode == "collection" and scene.has_node("LobbyBottomNav/ShopButton"):
		(scene.get_node("LobbyBottomNav/ShopButton") as BaseButton).pressed.emit()
	await process_frame
	if _read_arg("--open-card=", "0") == "1" and scene.has_node("AlbumPage/Grid/Card1"):
		(scene.get_node("AlbumPage/Grid/Card1") as BaseButton).pressed.emit()
		await process_frame
	for _i in range(int(_read_arg("--settle-frames=", "6"))):
		await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("[AlbumCapture] viewport texture is unavailable")
		quit(1)
		return
	var image := viewport_texture.get_image()
	if image == null:
		push_error("[AlbumCapture] viewport image is unavailable")
		quit(1)
		return
	var error := image.save_png(output_path)
	if error != OK:
		push_error("[AlbumCapture] save failed: %s" % error_string(error))
		quit(1)
		return
	print("[AlbumCapture] saved %s" % ProjectSettings.globalize_path(output_path))
	quit(0)

func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

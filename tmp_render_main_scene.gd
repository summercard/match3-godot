extends SceneTree

const OUT_PATH := "res://tmp_main_scene_render.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(450, 800)
	var main := Control.new()
	main.name = "MainPreview"
	main.set_script(load("res://main.gd"))
	root.add_child(main)
	await process_frame
	await process_frame
	if main.has_method("switch_scene"):
		main.switch_scene("main")
	for i in range(8):
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png(OUT_PATH)
	quit()

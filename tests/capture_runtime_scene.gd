extends SceneTree

const DEFAULT_OUTPUT := "user://runtime_scene_capture.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene_name := _read_arg("--scene-name=", "stage_select")
	var output_path := _read_arg("--output=", DEFAULT_OUTPUT)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene(scene_name, _scene_data(scene_name))
	await process_frame
	await process_frame
	await process_frame
	_seed_demo_state(main, scene_name)
	await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("[RuntimeCapture] save failed: %s" % error_string(error))
		quit(1)
		return
	print("[RuntimeCapture] logical viewport=%s main=%s window=%s framebuffer=%dx%d" % [
		root.get_visible_rect().size,
		main.size,
		DisplayServer.window_get_size(),
		image.get_width(),
		image.get_height()
	])
	print("[RuntimeCapture] %s -> %s" % [scene_name, ProjectSettings.globalize_path(output_path)])
	quit(0)

func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback

func _scene_data(scene_name: String) -> Dictionary:
	if scene_name == "stage_select":
		return {"chapterIndex": int(_read_arg("--chapter-index=", "0"))}
	return {}

func _seed_demo_state(main: Control, scene_name: String) -> void:
	if scene_name != "team":
		return
	var count := int(_read_arg("--team-demo-count=", "0"))
	if count <= 0:
		return
	var team_scene := main.get_node_or_null("Team")
	if team_scene == null:
		return
	var roster: Array = []
	for i in range(count):
		var monster_id := "monster_%03d" % ((i % 12) + 1)
		roster.append({
			"instanceId": monster_id if i < 12 else "%s_demo_%02d" % [monster_id, i + 1],
			"monsterId": monster_id,
			"level": 1 + i,
			"nature": ""
		})
	team_scene.set("_captured_monsters", roster)
	team_scene.set("_team", {
		"leader": roster[0].get("instanceId", "") if roster.size() > 0 else null,
		"member1": roster[1].get("instanceId", "") if roster.size() > 1 else null,
		"member2": roster[2].get("instanceId", "") if roster.size() > 2 else null
	})
	team_scene.set("_roster_page", int(_read_arg("--team-demo-page=", "0")))
	team_scene.call("_clamp_roster_page")
	team_scene.queue_redraw()

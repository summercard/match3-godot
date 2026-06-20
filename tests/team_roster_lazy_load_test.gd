extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://src/ui/scenes/team.tscn") as PackedScene
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	await process_frame
	_expect(not bool(scene.get("_initialized")), "_ready should not read the save before init")
	scene.call("init", {})
	await process_frame

	var roster: Array = []
	for i in 12:
		roster.append({
			"instanceId": "team_lazy_%02d" % i,
			"monsterId": "monster_%03d" % (i + 1),
			"level": i + 1,
			"nature": "",
		})
	scene.set("_captured_monsters", roster)
	scene.call("_rebuild_instance_index")
	scene.call("_rebuild_display_monsters_cache")
	(scene.get("_roster_texture_cache") as Dictionary).clear()
	scene.set("_loaded_roster_page", -1)
	scene.set("_roster_page", 0)
	scene.call("_sync_pet_roster")
	await _wait_for_portraits(scene)
	var first_cache: Dictionary = scene.get("_roster_texture_cache")
	var first_paths := first_cache.keys()
	_expect(first_cache.size() > 0 and first_cache.size() <= 6, "first page should retain at most six portraits")

	scene.call("_turn_roster_page", 1)
	scene.call("_sync_pet_roster")
	await _wait_for_portraits(scene)
	var second_cache: Dictionary = scene.get("_roster_texture_cache")
	_expect(int(scene.get("_loaded_roster_page")) == 1, "second page should replace the loaded page")
	_expect(second_cache.size() > 0 and second_cache.size() <= 6, "second page should retain at most six portraits")
	for old_path: Variant in first_paths:
		_expect(not second_cache.has(old_path), "page turn should release first-page portrait references")

	scene.queue_free()
	await process_frame
	_finish()

func _wait_for_portraits(scene: Control) -> void:
	var frames := 0
	while not (scene.get("_pending_portrait_loads") as Dictionary).is_empty() and frames < 120:
		await process_frame
		frames += 1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[TeamRosterLazyLoad] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[TeamRosterLazyLoad] " + failure)
	quit(1)

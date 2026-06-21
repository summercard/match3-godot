extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		_finish()
		return

	save_manager.clear_all_data()
	var scene: Control = load("res://src/ui/scenes/stage_select_map.tscn").instantiate() as Control
	root.add_child(scene)
	scene.init({"chapterIndex": 0})
	await process_frame

	var next_button := scene.get_node("BottomNav/NextMapButton") as TextureButton
	_expect(not next_button.disabled, "locked next chapter button should remain pressable so it can explain the requirement")
	_expect(next_button.modulate.a < 1.0, "locked next chapter button should look muted")
	_expect((next_button.get_node("Text") as Label).text == "第2章", "next chapter button should show the target chapter number")
	_expect((next_button.get_node("LockIcon") as TextureRect).visible, "locked next chapter button should show a lock icon")
	next_button.pressed.emit()
	await process_frame
	_expect(int(scene.get("_current_chapter_index")) == 0, "next chapter should stay locked before the current boss is cleared")
	var hint := scene.get_node_or_null("ChapterLockHint") as Label
	_expect(hint != null and hint.visible, "pressing a locked next chapter button should show a hint")
	_expect(hint != null and hint.text == "第2章尚未解锁，请先击败第1章 Boss", "locked chapter hint should name both the locked chapter and required boss chapter")

	var direct_scene: Control = load("res://src/ui/scenes/stage_select_map.tscn").instantiate() as Control
	root.add_child(direct_scene)
	direct_scene.init({"chapterIndex": 1})
	await process_frame
	_expect(int(direct_scene.get("_current_chapter_index")) == 0, "a fresh save should not bypass the lock through the initial chapter index")
	direct_scene.queue_free()
	await process_frame

	save_manager.save_stage_stars("stage_1_12", 1)
	scene.call("_update_chapter_buttons")
	_expect(next_button.modulate.a >= 0.99, "next chapter button should return to its normal appearance after the boss is cleared")
	_expect(not (next_button.get_node("LockIcon") as TextureRect).visible, "next chapter lock icon should hide after the boss is cleared")
	_expect((next_button.get_node("Arrow") as TextureRect).visible, "next chapter arrow should reappear after the boss is cleared")
	scene.call("_switch_chapter", 1)
	for _i in range(120):
		await process_frame
		if int(scene.get("_current_chapter_index")) == 1:
			break
	_expect(int(scene.get("_current_chapter_index")) == 1, "clearing the current boss should allow entering the next chapter")
	_expect((scene.get_node("Header/ChapterTitle") as Label).text == "第2章", "chapter header should update to the entered chapter number")

	scene.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[ChapterNavigationLock] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[ChapterNavigationLock] " + failure)
	quit(1)

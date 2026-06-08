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
	_expect(save_manager.is_stage_unlocked("stage_1_1"), "first stage should be unlocked on a fresh save")
	_expect(not save_manager.is_stage_unlocked("stage_1_2"), "second stage should be locked before stage 1-1 is cleared")
	_expect(not save_manager.is_stage_unlocked("stage_2_1"), "chapter 2 should be locked before chapter 1 boss is cleared")

	save_manager.save_stage_stars("stage_1_1", 1)
	_expect(save_manager.is_stage_unlocked("stage_1_2"), "clearing stage 1-1 should unlock stage 1-2")

	save_manager.save_stage_stars("stage_1_2", 1)
	save_manager.save_stage_stars("stage_1_3", 1)
	save_manager.save_stage_stars("stage_1_4", 1)
	_expect(not save_manager.is_stage_unlocked("stage_2_1"), "chapter 2 should still require stage 1-5 boss")
	save_manager.save_stage_stars("stage_1_5", 1)
	_expect(save_manager.is_stage_unlocked("stage_2_1"), "clearing chapter 1 boss should unlock chapter 2")

	var elite_state: Dictionary = save_manager.get_stage_unlock_state("stage_2_4e")
	_expect(not bool(elite_state.get("unlocked", true)), "chapter 2 elite should be locked before stage 2-4")
	save_manager.save_stage_stars("stage_2_1", 1)
	save_manager.save_stage_stars("stage_2_2", 1)
	save_manager.save_stage_stars("stage_2_3", 1)
	save_manager.save_stage_stars("stage_2_4", 1)
	_expect(save_manager.is_stage_unlocked("stage_2_4e"), "elite branch should unlock from the previous main stage")
	_expect(save_manager.is_stage_unlocked("stage_2_5"), "boss should not require optional elite clear")

	save_manager.clear_all_data()
	save_manager.save_player({
		"level": 1,
		"gold": 0,
		"gems": 0,
		"exp": 0,
		"team": ["monster_001", "monster_002", "monster_003"],
		"captured": ["monster_001", "monster_002", "monster_003"],
		"monster_pool": [],
		"monsterPoolVersion": 0,
		"stageProgress": {"chapter": 2, "stage": 1},
		"pokedex": {}
	})
	_expect(save_manager.is_stage_unlocked("stage_2_1"), "legacy player progress should unlock the first stage of chapter 2")
	_expect(save_manager.is_stage_cleared("stage_1_5"), "legacy player progress should migrate cleared prerequisite stages")

	save_manager.clear_all_data()
	save_manager.save_stage_stars("stage_1_1", 3)
	var player: Dictionary = save_manager.load_player()
	player["stageProgress"] = {"chapter": 1, "stage": 3}
	save_manager.save_player(player)
	_expect(save_manager.get_stage_stars("stage_1_1") == 3, "legacy migration should not lower existing stars")
	_expect(save_manager.is_stage_unlocked("stage_1_3"), "legacy progress should merge missing cleared stages with existing stage progress")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[StageUnlock] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[StageUnlock] " + failure)
		quit(1)

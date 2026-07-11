extends SceneTree

func _init() -> void:
	call_deferred("_unlock")

func _unlock() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager == null:
		push_error("[TowerPreviewUnlock] SaveManager is unavailable")
		quit(1)
		return
	var saved := bool(save_manager.save_stage_stars("stage_1_8", 3))
	var unlocked := bool(save_manager.is_tower_unlocked())
	print("[TowerPreviewUnlock] saved=%s unlocked=%s" % [saved, unlocked])
	quit(0 if saved and unlocked else 1)

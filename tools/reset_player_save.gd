extends SceneTree

func _init() -> void:
	call_deferred("_reset")


func _reset() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	if storage == null or not storage.has_method("reset_to_initial_state"):
		push_error("[ResetPlayerSave] SaveManager.reset_to_initial_state is unavailable")
		quit(1)
		return
	if not bool(storage.reset_to_initial_state()):
		push_error("[ResetPlayerSave] failed to write the initial save state")
		quit(1)
		return
	print("[ResetPlayerSave] reset " + ProjectSettings.globalize_path("user://save_game.cfg"))
	quit(0)

class_name TestSceneCleanup
extends RefCounted

static func queue_free_root(tree: SceneTree) -> void:
	tree.paused = false
	_cleanup_audio(tree)
	for child in tree.root.get_children():
		if is_instance_valid(child):
			child.queue_free()

static func mute_audio_for_test(tree: SceneTree) -> void:
	var audio_manager := tree.root.get_node_or_null("AudioManager")
	if audio_manager == null:
		return
	if audio_manager.has_method("set_mute"):
		audio_manager.call("set_mute", true)
	if audio_manager.has_method("set_bgm_mute"):
		audio_manager.call("set_bgm_mute", true)
	_cleanup_audio(tree)

static func _cleanup_audio(tree: SceneTree) -> void:
	var audio_manager := tree.root.get_node_or_null("AudioManager")
	if audio_manager == null:
		return
	if audio_manager.has_method("stop_bgm"):
		audio_manager.call("stop_bgm")
	var bgm_player: Variant = audio_manager.get("_bgm_player")
	if bgm_player is AudioStreamPlayer:
		_release_audio_player(bgm_player as AudioStreamPlayer)
		audio_manager.set("_bgm_player", null)
	var sfx_bus: Variant = audio_manager.get("_sfx_bus")
	if sfx_bus is AudioStreamPlayer:
		_release_audio_player(sfx_bus as AudioStreamPlayer)
		audio_manager.set("_sfx_bus", null)
	audio_manager.set("_resource_cache", {})
	for child in audio_manager.get_children():
		if child is AudioStreamPlayer:
			_release_audio_player(child as AudioStreamPlayer)

static func _release_audio_player(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null
	if player.is_inside_tree():
		player.queue_free()
	else:
		player.free()

extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://src/ui/scenes/battle_prepare.tscn") as PackedScene
	_expect(scene != null, "battle_prepare.tscn should load")
	if scene == null:
		_finish()
		return

	var prepare := scene.instantiate() as Control
	var frame := prepare.get_node("PowerPanel/Frame") as TextureRect
	var authored_visible := frame.visible
	var authored_position := frame.position
	var authored_size := frame.size

	root.add_child(prepare)
	prepare.init({"stageId": "stage_1_1"})
	prepare.call("_apply_concept_layout")
	await process_frame

	_expect(frame.visible == authored_visible, "PowerPanel/Frame visibility should be owned by battle_prepare.tscn")
	_expect(frame.position == authored_position, "PowerPanel/Frame position should be owned by battle_prepare.tscn")
	_expect(frame.size == authored_size, "PowerPanel/Frame size should be owned by battle_prepare.tscn")
	var reward_preview := prepare.get_node_or_null("RewardPreview") as Control
	_expect(reward_preview != null and not reward_preview.visible, "battle preparation must not reveal settlement rewards")
	var start_frame := prepare.get_node("StartButton/Frame") as TextureRect
	_expect(start_frame.texture != null and start_frame.texture.resource_path == "res://assets/images/ui/buttons/main_ui_start_adventure_v3.png", "battle preparation should use the lobby primary-action art")
	prepare.queue_free()
	await process_frame
	_finish()

func _expect(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattlePrepareTscnPresentation] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[BattlePrepareTscnPresentation] " + failure)
	quit(1)

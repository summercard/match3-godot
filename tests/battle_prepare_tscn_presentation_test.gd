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

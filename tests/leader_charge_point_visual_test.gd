extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var point := BattleLeaderChargePoint.new()
	point.name = "LeaderChargePoint"
	point.size = Vector2(72.0, 14.0)
	root.add_child(point)
	for i in range(5):
		var bead := BattleLeaderChargeBead.new()
		bead.name = "Point%d" % (i + 1)
		bead.size = Vector2(8.0, 8.0)
		point.add_child(bead)
	await process_frame

	point.animate_to(0.2)
	point.animate_to(0.2)
	var first_peak := await _max_bead_scale_over_frames(point, 0, 8)
	_expect(point.scale == Vector2.ONE, "leader charge group should not scale when one point is gained")
	_expect(first_peak > 1.0, "first gained charge bead should pulse")
	for i in range(1, 5):
		_expect(is_equal_approx(_bead_scale(point, i), 1.0), "unchanged charge bead %d should not pulse" % (i + 1))

	await create_timer(0.22).timeout
	point.animate_to(0.4)
	var second_peak := await _max_bead_scale_over_frames(point, 1, 8)
	_expect(is_equal_approx(_bead_scale(point, 0), 1.0), "previously filled charge bead should not pulse again")
	_expect(second_peak > 1.0, "newly gained second charge bead should pulse")
	for i in range(2, 5):
		_expect(is_equal_approx(_bead_scale(point, i), 1.0), "still-empty charge bead %d should not pulse" % (i + 1))

	point.animate_to(0.0)
	await process_frame
	_expect(point.scale == Vector2.ONE, "leader charge group should remain unscaled after reset")

	point.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[LeaderChargePointVisual] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[LeaderChargePointVisual] " + failure)
	quit(1)


func _bead_scale(point: Control, index: int) -> float:
	var bead := point.get_node("Point%d" % (index + 1)) as Control
	return bead.scale.x


func _max_bead_scale_over_frames(point: Control, index: int, frames: int) -> float:
	var peak := _bead_scale(point, index)
	for _i in range(frames):
		await process_frame
		peak = maxf(peak, _bead_scale(point, index))
	return peak


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

class_name BattleInputMapper
extends RefCounted

static func pointer_candidates(owner: Control, event: InputEvent, already_local: bool) -> Array[Vector2]:
	var raw_pos: Vector2 = event.position
	if already_local:
		return [raw_pos]

	var candidates: Array[Vector2] = []
	var local_event := owner.make_input_local(event)
	candidates.append(local_event.position)
	candidates.append(raw_pos)
	if event is InputEventMouseButton:
		candidates.append(event.global_position)
	elif event is InputEventMouseMotion:
		candidates.append(event.global_position)

	var inverse := owner.get_global_transform_with_canvas().affine_inverse()
	var count := candidates.size()
	for i in range(count):
		candidates.append(inverse * candidates[i])
	return candidates

static func direction_from_delta(delta: Vector2, threshold: float) -> String:
	if delta.length() < threshold:
		return ""
	if abs(delta.x) > abs(delta.y):
		return "left" if delta.x < 0.0 else "right"
	return "up" if delta.y < 0.0 else "down"

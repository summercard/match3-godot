class_name TransitionProgress
extends RefCounted


static func advance(elapsed: float, duration: float, delta: float) -> float:
	if duration <= 0.0:
		return 0.0
	return minf(duration, elapsed + maxf(delta, 0.0))


static func fade_alpha(elapsed: float, duration: float, max_alpha: float, fading_out: bool) -> float:
	if duration <= 0.0:
		return max_alpha if fading_out else 0.0
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	return (progress if fading_out else 1.0 - progress) * max_alpha


static func frames_to_finish(duration: float, frame_delta: float) -> int:
	if duration <= 0.0:
		return 0
	if frame_delta <= 0.0:
		return 0
	return int(ceil(duration / frame_delta))

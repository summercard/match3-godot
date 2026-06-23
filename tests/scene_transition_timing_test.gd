extends SceneTree

const TransitionProgressScript = preload("res://src/core/transition_progress.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for fps in [30.0, 60.0, 120.0]:
		_test_duration_at_fps(0.3, fps)
	_test_alpha_curve()
	_finish()


func _test_duration_at_fps(duration: float, fps: float) -> void:
	var delta := 1.0 / fps
	var elapsed := 0.0
	var frames := 0
	while elapsed < duration and frames < 240:
		elapsed = TransitionProgressScript.advance(elapsed, duration, delta)
		frames += 1
	var expected_frames := TransitionProgressScript.frames_to_finish(duration, delta)
	_expect(frames == expected_frames, "transition should finish in %d frames at %.0f FPS, got %d" % [expected_frames, fps, frames])
	_expect(elapsed == duration, "transition elapsed should clamp exactly to configured duration at %.0f FPS" % fps)


func _test_alpha_curve() -> void:
	_expect(is_equal_approx(TransitionProgressScript.fade_alpha(0.15, 0.3, 0.42, true), 0.21), "fade-out alpha should scale with elapsed time")
	_expect(is_equal_approx(TransitionProgressScript.fade_alpha(0.15, 0.3, 0.42, false), 0.21), "fade-in alpha should mirror fade-out")
	_expect(is_equal_approx(TransitionProgressScript.fade_alpha(0.3, 0.3, 0.42, false), 0.0), "fade-in should end transparent")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SceneTransitionTiming] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SceneTransitionTiming] " + failure)
	quit(1)

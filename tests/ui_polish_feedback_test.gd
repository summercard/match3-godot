extends SceneTree
## UI 打磨回归：中文字形回退、按钮按下反馈、章节圆点居中。

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(ThemeDB.fallback_font.fallbacks.any(func(font): return font is SystemFont), "default font should carry a CJK fallback")

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main.switch_scene("main")
	await process_frame
	var lobby: Control = main.get_current_scene()
	var button := lobby.get_node("%TeamButton") as TextureButton
	_expect(button.has_meta("ui_press_feedback_attached"), "lobby buttons should receive press feedback")
	button.button_down.emit()
	await create_timer(0.15).timeout
	_expect(button.scale.x < 0.98, "button should shrink while pressed")
	button.button_up.emit()
	await create_timer(0.25).timeout
	_expect(is_equal_approx(button.scale.x, 1.0), "button should return to its normal size after release")

	main.switch_scene("stage_select")
	await process_frame
	await process_frame
	var stage_scene: Control = main.get_current_scene()
	var dots := stage_scene.get_node("Header/Dots") as Control
	var left := INF
	var right := -INF
	for dot in dots.get_children():
		if dot.visible:
			left = minf(left, dot.position.x)
			right = maxf(right, dot.position.x + (dot as Control).size.x)
	_expect(left < INF, "chapter dots should be visible")
	_expect(absf(dots.position.x + (left + right) * 0.5 - 187.5) < 2.0, "chapter dots should be horizontally centered")

	if _failures.is_empty():
		print("[UiPolishFeedback] OK")
		quit(0)
	else:
		for failure in _failures:
			push_error("[UiPolishFeedback] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

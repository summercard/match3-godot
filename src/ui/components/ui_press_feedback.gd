# ui_press_feedback.gd - 统一按钮按下反馈
# 给所有 BaseButton 加一个轻微的按下缩放，补足没有 pressed 贴图时的触感。
class_name UiPressFeedback
extends RefCounted

const PRESS_SCALE := Vector2(0.94, 0.94)
const DOWN_TIME := 0.06
const UP_TIME := 0.10
const META_ATTACHED := "ui_press_feedback_attached"
const META_TWEEN := "ui_press_feedback_tween"

static func attach(root: Node) -> void:
	_walk(root)

static func _walk(node: Node) -> void:
	if node is BaseButton:
		_attach_button(node as BaseButton)
	for child in node.get_children():
		_walk(child)

static func _attach_button(button: BaseButton) -> void:
	if button.has_meta(META_ATTACHED):
		return
	button.set_meta(META_ATTACHED, true)
	button.button_down.connect(func(): _animate(button, PRESS_SCALE, DOWN_TIME))
	button.button_up.connect(func(): _animate(button, Vector2.ONE, UP_TIME))
	button.mouse_exited.connect(func():
		if not button.button_pressed:
			_animate(button, Vector2.ONE, UP_TIME)
	)
	button.visibility_changed.connect(func():
		if not button.visible:
			button.scale = Vector2.ONE
	)

static func _animate(button: BaseButton, target: Vector2, duration: float) -> void:
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	var running: Tween = null
	if button.has_meta(META_TWEEN):
		var candidate = button.get_meta(META_TWEEN)
		if candidate is Tween:
			running = candidate
	if running != null and running.is_valid():
		running.kill()
	var tween := button.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, duration)
	button.set_meta(META_TWEEN, tween)

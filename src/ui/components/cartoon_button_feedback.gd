class_name CartoonButtonFeedback
extends Control

enum Profile {
	PRIMARY,
	ENTRY,
	NAV,
	ICON,
}

const REDRAW_INTERVAL := 1.0 / 30.0

var _button: BaseButton = null
var _profile := Profile.NAV
var _rest_scale := Vector2.ONE
var _rest_rotation := 0.0
var _rest_self_modulate := Color.WHITE
var _hovered := false
var _pressed := false
var _burst_enabled := true
var _elapsed := 0.0
var _redraw_accum := 0.0
var _burst_progress := 1.0
var _button_tween: Tween = null
var _burst_tween: Tween = null


func setup(button: BaseButton, profile: int = Profile.NAV) -> void:
	_button = button
	_profile = profile
	name = "CartoonFeedback"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 20
	_rest_scale = button.scale
	_rest_rotation = button.rotation
	_rest_self_modulate = button.self_modulate
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.focus_entered.connect(_on_focus_entered)
	button.focus_exited.connect(_on_focus_exited)
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	button.pressed.connect(_on_pressed)
	_update_processing()
	queue_redraw()


func set_burst_enabled(enabled: bool) -> void:
	_burst_enabled = enabled
	if not _burst_enabled:
		_burst_progress = 1.0
	_update_processing()


func get_feedback_profile() -> Dictionary:
	return {
		"profile": _profile,
		"press_scale": _press_scale(),
		"hover_scale": _hover_scale(),
		"burst": _burst_enabled,
	}


func _process(delta: float) -> void:
	if _button == null:
		set_process(false)
		return
	_elapsed += delta
	_redraw_accum += delta
	if _button.pivot_offset != _button.size * 0.5:
		_button.pivot_offset = _button.size * 0.5
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = 0.0
		queue_redraw()
	if not _should_process_feedback():
		set_process(false)


func _draw() -> void:
	if _button == null:
		return
	var center := size * 0.5
	var idle_pulse := 0.5 + sin(_elapsed * 2.6) * 0.5
	var glow_alpha := 0.0
	if _profile == Profile.PRIMARY:
		glow_alpha = 0.08 + idle_pulse * 0.08
	elif _hovered:
		glow_alpha = 0.10
	if _pressed:
		glow_alpha += 0.09
	if glow_alpha > 0.0:
		var glow_radius := maxf(size.x, size.y) * (0.50 + idle_pulse * 0.025)
		draw_circle(center, glow_radius, Color(1.0, 0.82, 0.30, glow_alpha * 0.18))
	if not _burst_enabled or _burst_progress >= 1.0:
		return
	var burst_alpha := 1.0 - _burst_progress
	var base_radius := maxf(size.x, size.y) * (0.34 + _burst_progress * 0.30)
	var accent := _accent_color()
	accent.a = burst_alpha * 0.82
	draw_arc(center, base_radius, 0.0, TAU, 32, accent, _burst_line_width())
	for i in range(_burst_ray_count()):
		var angle := TAU * float(i) / float(_burst_ray_count()) + _burst_progress * 0.28
		var direction := Vector2.from_angle(angle)
		var start := center + direction * (base_radius + 2.0)
		var finish := center + direction * (base_radius + 8.0 + _burst_progress * 9.0)
		draw_line(start, finish, Color(accent.r, accent.g, accent.b, burst_alpha * 0.72), _burst_line_width())


func _on_mouse_entered() -> void:
	_hovered = true
	_update_processing()
	if not _pressed:
		_animate_to(_hover_scale(), -0.7, 0.10, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	_hovered = false
	_update_processing()
	if not _pressed:
		_animate_to(1.0, 0.0, 0.12, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_focus_entered() -> void:
	_on_mouse_entered()


func _on_focus_exited() -> void:
	_on_mouse_exited()


func _on_button_down() -> void:
	_pressed = true
	_update_processing()
	_animate_to(_press_scale(), 1.1, 0.065, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_button_up() -> void:
	_pressed = false
	_update_processing()
	_play_release_bounce()


func _on_pressed() -> void:
	if _burst_enabled:
		_play_burst()
	if _profile == Profile.PRIMARY or _profile == Profile.ENTRY:
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx("ui_button_soft_pop")


func _animate_to(scale_factor: float, rotation_degrees: float, duration: float, transition: int, easing: int) -> void:
	_kill_button_tween()
	_button_tween = create_tween().set_parallel(true)
	_button_tween.tween_property(_button, "scale", _rest_scale * scale_factor, duration).set_trans(transition).set_ease(easing)
	_button_tween.tween_property(_button, "rotation", _rest_rotation + deg_to_rad(rotation_degrees), duration).set_trans(transition).set_ease(easing)
	_button_tween.tween_property(_button, "self_modulate", _target_modulate(scale_factor), duration).set_trans(transition).set_ease(easing)


func _play_release_bounce() -> void:
	_kill_button_tween()
	var target_scale := _hover_scale() if _hovered else 1.0
	_button_tween = create_tween()
	_button_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_button_tween.tween_property(_button, "scale", _rest_scale * (_release_scale() + target_scale - 1.0), 0.12)
	_button_tween.parallel().tween_property(_button, "rotation", _rest_rotation - deg_to_rad(0.8), 0.10)
	_button_tween.parallel().tween_property(_button, "self_modulate", _target_modulate(_release_scale()), 0.10)
	_button_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_button_tween.tween_property(_button, "scale", _rest_scale * target_scale, 0.10)
	_button_tween.parallel().tween_property(_button, "rotation", _rest_rotation, 0.10)
	_button_tween.parallel().tween_property(_button, "self_modulate", _target_modulate(target_scale), 0.10)


func _play_burst() -> void:
	if _burst_tween != null and _burst_tween.is_valid():
		_burst_tween.kill()
	_burst_progress = 0.0
	_update_processing()
	queue_redraw()
	_burst_tween = create_tween()
	_burst_tween.tween_method(_set_burst_progress, 0.0, 1.0, _burst_duration()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_burst_progress(value: float) -> void:
	_burst_progress = value
	queue_redraw()
	if _burst_progress >= 1.0:
		_update_processing()


func _should_process_feedback() -> bool:
	if _profile == Profile.PRIMARY:
		return true
	return _hovered or _pressed or (_burst_enabled and _burst_progress < 1.0)


func _update_processing() -> void:
	set_process(_should_process_feedback())
	queue_redraw()


func _kill_button_tween() -> void:
	if _button_tween != null and _button_tween.is_valid():
		_button_tween.kill()


func _target_modulate(scale_factor: float) -> Color:
	if scale_factor < 0.99:
		return _rest_self_modulate.darkened(0.12)
	if scale_factor > 1.01:
		return Color(
			_rest_self_modulate.r * 1.08,
			_rest_self_modulate.g * 1.08,
			_rest_self_modulate.b * 1.08,
			_rest_self_modulate.a
		)
	return _rest_self_modulate


func _press_scale() -> float:
	match _profile:
		Profile.PRIMARY:
			return 0.90
		Profile.ENTRY:
			return 0.93
		Profile.ICON:
			return 0.88
		_:
			return 0.91


func _hover_scale() -> float:
	match _profile:
		Profile.PRIMARY:
			return 1.035
		Profile.ENTRY:
			return 1.025
		_:
			return 1.045


func _release_scale() -> float:
	match _profile:
		Profile.PRIMARY:
			return 1.075
		Profile.ENTRY:
			return 1.055
		_:
			return 1.065


func _burst_duration() -> float:
	return 0.28 if _profile == Profile.PRIMARY else 0.22


func _burst_ray_count() -> int:
	return 10 if _profile == Profile.PRIMARY else 6


func _burst_line_width() -> float:
	return 1.6 if _profile == Profile.PRIMARY else 1.1


func _accent_color() -> Color:
	match _profile:
		Profile.ENTRY:
			return Color(1.0, 0.84, 0.38, 1.0)
		Profile.ICON:
			return Color(0.70, 0.90, 1.0, 1.0)
		_:
			return Color(1.0, 0.72, 0.20, 1.0)

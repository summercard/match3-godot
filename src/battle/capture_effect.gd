# ============================================
# battle/capture_effect.gd - 收服成功/失败特效
# 翻译自 CaptureEffectManager.js
# ============================================
extends Node2D
class_name CaptureEffect

## 特效状态
var success: bool = false
var center_pos: Vector2 = Vector2.ZERO
var timer: float = 0.0
var done: bool = false
var total_duration: float = 0.0

## 成功序列时间节点
var flash_start: float = 0.0
var flash_end: float = 0.15
var bounce_start: float = 0.15
var bounce_end: float = 0.55
var get_text_start: float = 0.4
var get_text_end: float = 1.2

## 失败序列时间节点
var shake_start: float = 0.0
var shake_end: float = 0.2
var miss_start: float = 0.2
var miss_end: float = 0.8

## 当前帧状态（供外部读取）
var flash_opacity: float = 0.0
var monster_scale: float = 1.0
var get_text_scale: float = 0.0
var get_text_opacity: float = 0.0
var shake_offset_x: float = 0.0
var miss_text_opacity: float = 0.0
var miss_text_y: float = 0.0

## Godot 节点引用
var _flash_rect: ColorRect
var _monster_sprite: TextureRect
var _get_label: Label
var _miss_label: Label
var _parent: Control

## ============================================
## 初始化
## ============================================

func setup(parent: Control, is_success: bool, pos: Vector2) -> void:
	success = is_success
	center_pos = pos
	_parent = parent
	miss_text_y = pos.y

	# 创建闪白覆盖层
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color.WHITE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.z_index = 300
	_flash_rect.modulate.a = 0.0
	parent.add_child(_flash_rect)

	if success:
		total_duration = 1.2
		_setup_success()
	else:
		total_duration = 0.8
		_setup_fail()

func _setup_success() -> void:
	# 创建 GET! 标签
	_get_label = Label.new()
	_get_label.text = "GET!"
	_get_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_get_label.add_theme_font_size_override("font_size", 48)
	_get_label.add_theme_color_override("font_color", Color("#ffd700"))
	_get_label.position = center_pos - Vector2(60, 30)
	_get_label.size = Vector2(120, 60)
	_get_label.z_index = 250
	_get_label.modulate.a = 0.0
	_get_label.scale = Vector2.ZERO
	_parent.add_child(_get_label)

func _setup_fail() -> void:
	# 创建 MISS 标签
	_miss_label = Label.new()
	_miss_label.text = "MISS"
	_miss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_miss_label.add_theme_font_size_override("font_size", 32)
	_miss_label.add_theme_color_override("font_color", Color("#b4b4b4"))
	_miss_label.position = center_pos - Vector2(50, 16)
	_miss_label.size = Vector2(100, 32)
	_miss_label.z_index = 250
	_miss_label.modulate.a = 0.0
	_parent.add_child(_miss_label)

## ============================================
## 启动动画（使用 Godot Tween）
## ============================================

func play() -> void:
	if success:
		_play_success()
	else:
		_play_fail()

	# 超时清理
	get_tree().create_timer(total_duration + 0.1).timeout.connect(_cleanup)

func _play_success() -> void:
	var tween = get_tree().create_tween()

	# 阶段1：屏幕闪白 0→0.8→0 (0-150ms)
	tween.tween_property(_flash_rect, "modulate:a", 0.8, 0.075)
	tween.tween_property(_flash_rect, "modulate:a", 0.0, 0.075)

	# 阶段2：怪物弹跳 1→1.3→0.8→1.05→1 (150-550ms)
	tween.parallel().tween_property(_parent, "scale", Vector2(1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT).set_delay(0.15)
	tween.tween_property(_parent, "scale", Vector2(0.8, 0.8), 0.1).set_ease(Tween.EASE_IN)
	tween.tween_property(_parent, "scale", Vector2(1.05, 1.05), 0.05).set_ease(Tween.EASE_OUT)
	tween.tween_property(_parent, "scale", Vector2.ONE, 0.05)

	# 阶段3：GET! 文字弹出 (400-1200ms)
	tween.tween_callback(_show_get_text).set_delay(0.4)

func _show_get_text() -> void:
	if not _get_label or not is_instance_valid(_get_label):
		return
	_get_label.modulate.a = 1.0
	var tween = get_tree().create_tween()
	# 弹出：0 → 1.2
	_get_label.scale = Vector2.ZERO
	tween.tween_property(_get_label, "scale", Vector2(1.2, 1.2), 0.24).set_ease(Tween.EASE_OUT)
	# 回弹：1.2 → 1
	tween.tween_property(_get_label, "scale", Vector2.ONE, 0.16)
	# 停留后淡出
	tween.tween_interval(0.3)
	tween.tween_property(_get_label, "modulate:a", 0.0, 0.24)

func _play_fail() -> void:
	var tween = get_tree().create_tween()

	# 阶段1：屏幕震动 (0-200ms)
	var original_pos = _parent.position
	for i in range(6):
		var offset = Vector2(randf_range(-3.0, 3.0), 0.0)
		tween.tween_property(_parent, "position", original_pos + offset, 0.033)
	tween.tween_property(_parent, "position", original_pos, 0.033)

	# 阶段2：MISS 文字 (200-800ms)
	tween.tween_callback(_show_miss_text).set_delay(0.2)

func _show_miss_text() -> void:
	if not _miss_label or not is_instance_valid(_miss_label):
		return
	_miss_label.modulate.a = 1.0
	var start_y = _miss_label.position.y
	var tween = get_tree().create_tween()
	# 上飘 + 淡出
	tween.tween_property(_miss_label, "position:y", start_y - 20.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_miss_label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)

## ============================================
## 清理
## ============================================

func _cleanup() -> void:
	if _flash_rect and is_instance_valid(_flash_rect):
		_flash_rect.queue_free()
	if _get_label and is_instance_valid(_get_label):
		_get_label.queue_free()
	if _miss_label and is_instance_valid(_miss_label):
		_miss_label.queue_free()
	done = true

func is_active() -> bool:
	return not done

## ============================================
## 便捷静态方法：直接在父节点上播放收服特效
## ============================================

static func play_capture(parent: Control, success: bool, pos: Vector2) -> CaptureEffect:
	var effect = CaptureEffect.new()
	effect.setup(parent, success, pos)
	# 添加到场景树以便 timer 工作
	parent.add_child(effect)
	effect.play()
	return effect

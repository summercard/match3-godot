# ============================================
# engine/animation_player.gd - 通用动画系统
# Godot 4.x Tween 封装
# ============================================
extends Node
class_name AnimationHelper

## 动画实例上限
const MAX_FLOATING_TEXT := 10
const MAX_TOAST := 3
const MAX_CAPTURE_EFFECT := 2
const MAX_GLOBAL := 100

## 活跃动画计数
var _active_count: int = 0
var _type_counts: Dictionary = {
	"floating_text": 0,
	"toast": 0,
	"capture_effect": 0,
}

## 延迟执行回调
func delay_call(duration: float, callback: Callable) -> void:
	get_tree().create_timer(duration).timeout.connect(callback)

## ============================================
## 通用属性动画（Tween 封装）
## ============================================

## 对节点做属性动画
func tween_property(node: Node, property: NodePath, from: Variant, to: Variant, duration: float, easing: String = "ease_out", on_complete: Callable = Callable()) -> Tween:
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, property, to, duration).from(from)
	_apply_ease(tween, easing)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)
	return tween

## 淡入
func fade_in(node: CanvasItem, duration: float = 0.3, on_complete: Callable = Callable()) -> Tween:
	node.modulate.a = 0.0
	node.visible = true
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)
	return tween

## 淡出
func fade_out(node: CanvasItem, duration: float = 0.3, on_complete: Callable = Callable()) -> Tween:
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): node.visible = false)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)
	return tween

## 弹跳缩放（0 → 1.1 → 1）
func pop_in(node: Control, duration: float = 0.3, on_complete: Callable = Callable()) -> Tween:
	node.scale = Vector2.ZERO
	node.visible = true
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), duration * 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.4).set_ease(Tween.EASE_IN_OUT)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)
	return tween

## 弹跳缩放（1 → 0）
func pop_out(node: Control, duration: float = 0.2, on_complete: Callable = Callable()) -> Tween:
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, "scale", Vector2.ZERO, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): node.visible = false)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)
	return tween

## 按钮按下反馈
func button_press(node: Control) -> Tween:
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, "scale", Vector2(0.95, 0.95), 0.08).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector2.ONE, 0.08).set_ease(Tween.EASE_OUT)
	_track_tween(tween)
	return tween

## 屏幕震动
func screen_shake(node: Control, amplitude: float = 4.0, duration: float = 0.2) -> Tween:
	var original_pos = node.position
	var tween = get_tree().create_tween().bind_node(node)
	var steps := 6
	for i in steps:
		var offset = Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude))
		tween.tween_property(node, "position", original_pos + offset, duration / steps)
	tween.tween_property(node, "position", original_pos, duration / steps)
	_track_tween(tween)
	return tween

## ============================================
## 宝石消除特效
## ============================================

## 宝石消除动画：放大闪白 → 缩小消失
func gem_eliminate(node: Control, on_complete: Callable = Callable()) -> void:
	# 记录原始颜色
	var original_modulate = node.modulate
	var tween = get_tree().create_tween().bind_node(node)
	# 阶段1：放大 + 闪白（100ms）
	tween.tween_property(node, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate", Color.WHITE, 0.1)
	# 阶段2：缩小 + 消失（150ms）
	tween.tween_property(node, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node, "modulate:a", 0.0, 0.15)
	# 完成回调
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	else:
		tween.tween_callback(func(): node.queue_free())
	_track_tween(tween)

## 宝石下落弹跳
func gem_bounce_fall(node: Control, target_y: float, on_complete: Callable = Callable()) -> void:
	var tween = get_tree().create_tween().bind_node(node)
	# 下落到目标位置
	tween.tween_property(node, "position:y", target_y, 0.15).set_ease(Tween.EASE_IN)
	# 弹跳效果：超过目标 → 回弹 → 稳定
	var overshoot = target_y - 6.0
	tween.tween_property(node, "position:y", overshoot, 0.06).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", target_y, 0.04).set_ease(Tween.EASE_IN_OUT)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)

## ============================================
## 连击特效
## ============================================

## Combo 数字弹出
func combo_popup(parent: Control, text: String, position: Vector2, on_complete: Callable = Callable()) -> void:
	if _type_counts["floating_text"] >= MAX_FLOATING_TEXT:
		return
	_type_counts["floating_text"] += 1

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("#ffd700"))
	label.position = position
	label.z_index = 100
	parent.add_child(label)

	var tween = get_tree().create_tween().bind_node(label)
	# 弹出
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.1)
	# 上飘 + 淡出
	tween.tween_property(label, "position:y", position.y - 30.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		label.queue_free()
		_type_counts["floating_text"] = max(0, _type_counts["floating_text"] - 1)
		if on_complete.is_valid():
			on_complete.call()
	)
	_track_tween(tween)

## ============================================
## 怪物 idle 动画
## ============================================

## 怪物轻微上下浮动
func monster_idle(node: Control, amplitude: float = 3.0, period: float = 1.5) -> Tween:
	var original_y = node.position.y
	var tween = get_tree().create_tween().bind_node(node).set_loops()
	tween.tween_property(node, "position:y", original_y - amplitude, period * 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", original_y + amplitude, period * 0.5).set_ease(Tween.EASE_IN_OUT)
	return tween

## 宝石微发光脉动
func gem_idle_glow(node: CanvasItem, period: float = 2.0) -> Tween:
	var tween = get_tree().create_tween().bind_node(node).set_loops()
	tween.tween_property(node, "modulate:a", 0.85, period * 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate:a", 1.0, period * 0.5).set_ease(Tween.EASE_IN_OUT)
	return tween

## ============================================
## 页面切换动画
## ============================================

## 场景淡入
func scene_transition_in(node: Control, duration: float = 0.3) -> Tween:
	node.modulate.a = 0.0
	node.visible = true
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)
	_track_tween(tween)
	return tween

## 场景淡出
func scene_transition_out(node: Control, duration: float = 0.2, on_complete: Callable = Callable()) -> Tween:
	var tween = get_tree().create_tween().bind_node(node)
	tween.tween_property(node, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)
	return tween

## ============================================
## 进化/升级特效
## ============================================

## 进化特效：白光扩散 + 弹跳
func evolve_effect(node: Control, on_complete: Callable = Callable()) -> void:
	# 白闪
	var flash = ColorRect.new()
	flash.color = Color.WHITE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 200
	flash.modulate.a = 0.0
	node.add_child(flash)

	var tween = get_tree().create_tween().bind_node(node)
	# 白光 0→0.8→0
	tween.tween_property(flash, "modulate:a", 0.8, 0.15)
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	# 弹跳 1→1.3→0.8→1.05→1
	tween.parallel().tween_property(node, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(0.8, 0.8), 0.15).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.05)
	tween.tween_callback(func(): flash.queue_free())
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_track_tween(tween)

## 升级数字弹出
func level_up_popup(parent: Control, level: int, position: Vector2, on_complete: Callable = Callable()) -> void:
	var label = Label.new()
	label.text = "Lv.%d" % level
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color("#4caf50"))
	label.position = position
	label.z_index = 100
	parent.add_child(label)

	var tween = get_tree().create_tween().bind_node(label)
	label.scale = Vector2.ZERO
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.1)
	# 停留
	tween.tween_interval(0.5)
	# 淡出上飘
	tween.tween_property(label, "position:y", position.y - 40.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		label.queue_free()
		if on_complete.is_valid():
			on_complete.call()
	)
	_track_tween(tween)

## ============================================
## 辅助方法
## ============================================

func _apply_ease(tween: Tween, easing: String) -> void:
	match easing:
		"ease_in":
			tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
		"ease_out":
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
		"ease_in_out":
			tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
		"bounce":
			tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		"linear":
			tween.set_trans(Tween.TRANS_LINEAR)
		_:
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)

func _track_tween(tween: Tween) -> void:
	_active_count += 1
	tween.finished.connect(func(): _active_count = max(0, _active_count - 1))

## 清理所有动画
func clear_all() -> void:
	_active_count = 0
	_type_counts = {"floating_text": 0, "toast": 0, "capture_effect": 0}

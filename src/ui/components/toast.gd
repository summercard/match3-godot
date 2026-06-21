# ============================================
# ui/components/toast.gd - Toast 提示组件
# 翻译自: minigame-1/js/engine/ToastManager.js
# ============================================
# ToastManager: 管理场景中所有 Toast 提示
# - 顶部弹出提示（success/warning/info/error）
# - 自动消失（2-3秒）
# - 队列管理，避免重叠

class_name Toast
extends Node2D

const PROJECT_ROUND_FONT: Font = preload("res://assets/fonts/jf-openhuninn-2.1.ttf")

## 单例模式
static var instance: Toast

## Toast 类型枚举
enum Type { INFO, SUCCESS, WARNING, ERROR }

## 配置
const MAX_WIDTH := 280.0
const TOAST_HEIGHT := 44.0
const PADDING := 12.0
const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0

## 动画时长配置（毫秒）
const IN_DURATION := 200.0
const STAY_DURATION := 1500.0
const OUT_DURATION := 300.0

## 预设颜色
const COLOR_MAP := {
	Type.INFO: Color("#1890ff"),      # primary blue
	Type.SUCCESS: Color("#52c41a"),   # success green
	Type.WARNING: Color("#faad14"),   # warning gold
	Type.ERROR: Color("#ff4d4f")       # danger red
}

## 位置目标 Y
const TARGET_Y_TOP := 80.0
const TARGET_Y_BOTTOM := DESIGN_HEIGHT - 80.0

## 私有变量
var _toasts: Array[Dictionary] = []
var _toast_id_counter := 0

## 用于动画的状态
var _phase: String = ""
var _timer: float = 0.0
var _opacity: float = 0.0
var _done: bool = false
var _text: String = ""
var _type: Type = Type.INFO
var _position: String = "top"  # top | bottom
var _y_offset: float = 0.0  # 用于多个 toast 垂直排列

## Tween 引用（用于清理）
var _tween: Tween

## ============================================
# 生命周期
## ============================================

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS

## ============================================
# 单例访问
## ============================================

static func get_instance() -> Toast:
	if instance == null:
		var scene = preload("res://src/ui/components/toast.tscn").instantiate()
		var root = Engine.get_main_loop().root
		root.add_child(scene)
		instance = scene
	return instance

## ============================================
# 便捷调用方法
## ============================================

## 添加 Toast
func add(text: String, toast_type: Type = Type.INFO, position: String = "top") -> int:
	_toast_id_counter += 1
	var toast_data := {
		"id": _toast_id_counter,
		"text": text,
		"type": toast_type,
		"position": position,
		"x": (DESIGN_WIDTH - MAX_WIDTH) / 2.0,
		"start_y": DESIGN_HEIGHT + 60.0 if position == "bottom" else -60.0,
		"target_y": TARGET_Y_BOTTOM if position == "bottom" else TARGET_Y_TOP,
		"y": DESIGN_HEIGHT + 60.0 if position == "bottom" else -60.0,
		"phase": "in",
		"timer": 0.0,
		"opacity": 0.0,
		"done": false,
		"max_width": MAX_WIDTH
	}
	_toasts.append(toast_data)
	return _toast_id_counter

func info(text: String, position: String = "top") -> int:
	return add(text, Type.INFO, position)

func success(text: String, position: String = "top") -> int:
	return add(text, Type.SUCCESS, position)

func warning(text: String, position: String = "top") -> int:
	return add(text, Type.WARNING, position)

func error(text: String, position: String = "top") -> int:
	return add(text, Type.ERROR, position)

## ============================================
# 更新逻辑（帧更新）
## ============================================

func _process(delta: float) -> void:
	var dt_ms := delta * 1000.0
	
	# 从后往前遍历，移除完成的 toast
	var i := _toasts.size() - 1
	while i >= 0:
		var toast = _toasts[i]
		if toast["done"]:
			_toasts.remove_at(i)
		else:
			_update_toast(toast, dt_ms)
		i -= 1

## 更新单个 toast 的动画状态机
func _update_toast(toast: Dictionary, dt_ms: float) -> void:
	if toast["done"]:
		return
	
	toast["timer"] += dt_ms
	var t: float = toast["timer"]
	var phase: String = toast["phase"]
	
	if phase == "in":
		# in 阶段：0→200ms，从屏幕外滑入 + opacity 0→1
		var progress := mini(t / IN_DURATION, 1.0)
		# ease-out 滑入
		var ease_out := 1.0 - pow(1.0 - progress, 3.0)
		var start_y: float = toast["start_y"]
		var target_y: float = toast["target_y"]
		toast["y"] = start_y + (target_y - start_y) * ease_out
		toast["opacity"] = progress
		
		if progress >= 1.0:
			toast["phase"] = "stay"
			toast["timer"] = 0.0
			toast["y"] = target_y
			toast["opacity"] = 1.0
	
	elif phase == "stay":
		# stay 阶段：保持显示
		if t >= STAY_DURATION:
			toast["phase"] = "out"
			toast["timer"] = 0.0
	
	elif phase == "out":
		# out 阶段：0→300ms，opacity 1→0 + 轻微上滑
		var progress := mini(t / OUT_DURATION, 1.0)
		toast["opacity"] = 1.0 - progress
		toast["y"] = toast["target_y"] - 15.0 * progress  # 轻微上滑
		
		if progress >= 1.0:
			toast["opacity"] = 0.0
			toast["done"] = true

## ============================================
# 渲染（每帧绘制）
## ============================================

func _draw() -> void:
	# 计算每个 toast 的实际 Y 偏移（同方向多个 toast 垂直排列）
	var offsets: Dictionary = {}
	for toast in _toasts:
		var pos: String = toast["position"]
		var y_val: float = toast["y"]
		if not offsets.has(pos):
			offsets[pos] = []
		offsets[pos].append(y_val)
	
	for idx in range(_toasts.size()):
		var toast = _toasts[idx]
		if toast["opacity"] <= 0.0:
			continue
		
		var pos: String = toast["position"]
		var y_val: float = toast["y"]
		
		# 计算偏移量（同方向且在上方的 toast）
		var offset_y := 0.0
		for other_y in offsets[pos]:
			if other_y < y_val + 10.0:
				offset_y += TOAST_HEIGHT + 8.0
		offset_y = offsets[pos].filter(func(v): return v < y_val + 10.0).size() * (TOAST_HEIGHT + 8.0)
		
		var draw_y: float = y_val - offset_y
		var draw_x: float = toast["x"]
		var max_w: float = toast["max_width"]
		
		# 背景：圆角矩形，黑色半透明
		var bg_color := Color(0.0, 0.0, 0.0, 0.85 * toast["opacity"])
		var rect := Rect2(draw_x, draw_y, max_w, TOAST_HEIGHT)
		_draw_round_rect(rect, bg_color, 8.0)
		
		# 左侧色条
		var type_color: Color = COLOR_MAP.get(toast["type"], COLOR_MAP[Type.INFO])
		type_color.a = toast["opacity"]
		var color_bar_rect := Rect2(draw_x + 8.0, draw_y + 8.0, 4.0, TOAST_HEIGHT - 16.0)
		_draw_rect(color_bar_rect, type_color)
		
		# 文字：居中显示
		var text_color := Color(1.0, 1.0, 1.0, toast["opacity"])
		var text_pos := Vector2(draw_x + max_w / 2.0, draw_y + TOAST_HEIGHT / 2.0 + 5.0)
		draw_string(PROJECT_ROUND_FONT, text_pos + Vector2(0.0, -2.0), toast["text"], HORIZONTAL_ALIGNMENT_CENTER, max_w - 24.0, 14.0, text_color)

## 绘制圆角矩形
func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var points := 12
	var verts = PackedVector2Array()
	# 简化：直接用多个矩形块拼成圆角矩形
	# 这里用 fill_rect 配合 corner 绘制
	# 先画主体矩形（不含圆角）
	draw_rect(Rect2(rect.position.x + radius, rect.position.y, rect.size.x - radius * 2, rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + radius, rect.size.x, rect.size.y - radius * 2), color)
	# 四角用小矩形模拟圆角
	draw_rect(Rect2(rect.position.x, rect.position.y, radius, radius), color)
	draw_rect(Rect2(rect.position.x + rect.size.x - radius, rect.position.y, radius, radius), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - radius, radius, radius), color)
	draw_rect(Rect2(rect.position.x + rect.size.x - radius, rect.position.y + rect.size.y - radius, radius, radius), color)

## 绘制普通矩形
func _draw_rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)

## ============================================
# 公共方法
## ============================================

## 查询是否有活跃提示
func is_active() -> bool:
	return _toasts.size() > 0

## 清空所有 Toast
func clear() -> void:
	_toasts.clear()

## 获取当前 toast 数量
func get_count() -> int:
	return _toasts.size()

# ============================================
# ui/components/floating_text.gd - 浮动文字组件
# 翻译自: minigame-1/js/engine/FloatingTextManager.js
# ============================================
# FloatingTextManager: 管理场景中所有浮动文字
# - 战斗伤害飘字
# - 经验获取提示
# - 收服成功/失败提示
# 动画：pop(弹出) → rise(上浮) → fade(淡出)

class_name FloatingText
extends Node2D

const PROJECT_ROUND_FONT: Font = preload("res://assets/fonts/noto-cjk/NotoSansCJK-Regular.ttc")

## 单例
static var instance: FloatingText

## 默认配置
const DEFAULT_DURATION_MS := 800.0
const POP_END_MS := 150.0
const RISE_END_MS := 300.0
const OFFSET_Y := 40.0

## 浮动文字类型（决定颜色）
enum TextType {
	NEUTRAL,   # 白色
	DAMAGE,    # 红色 - 伤害
	HEAL,      # 绿色 - 治疗
	EXP,       # 金色 - 经验
	CRITICAL,  # 橙色 - 暴击
	CAPTURE_SUCCESS,  # 彩虹 - 收服成功
	CAPTURE_FAIL      # 灰色 - 收服失败
}

const TYPE_COLORS := {
	TextType.NEUTRAL: Color.WHITE,
	TextType.DAMAGE: Color(1.0, 0.3, 0.2),      # 红色
	TextType.HEAL: Color(0.2, 1.0, 0.4),         # 绿色
	TextType.EXP: Color(1.0, 0.85, 0.2),        # 金色
	TextType.CRITICAL: Color(1.0, 0.5, 0.0),    # 橙色
	TextType.CAPTURE_SUCCESS: Color(1.0, 0.8, 0.0),  # 金黄
	TextType.CAPTURE_FAIL: Color(0.6, 0.6, 0.6)    # 灰色
}

## 私有变量
var _texts: Array[Dictionary] = []

## ============================================
# 生命周期
## ============================================

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS

## ============================================
# 单例访问
## ============================================

static func get_instance() -> FloatingText:
	if instance == null:
		var scene = preload("res://src/ui/components/floating_text.tscn").instantiate()
		var root = Engine.get_main_loop().root
		root.add_child(scene)
		instance = scene
	return instance

## ============================================
# 添加浮动文字
## ============================================

## 添加浮动文字
## text: 显示文字
## x, y: 世界坐标位置
## text_type: TextType 枚举
## duration_ms: 动画持续时间（毫秒）
func add(text: String, x: float, y: float, text_type: TextType = TextType.NEUTRAL, duration_ms: float = DEFAULT_DURATION_MS) -> void:
	var entry := {
		"text": text,
		"x": x,
		"y": y,
		"start_y": y,
		"type": text_type,
		"phase": "pop",
		"timer": 0.0,
		"duration": duration_ms,
		"scale": 0.5,
		"opacity": 0.0,
		"critical": text_type == TextType.CRITICAL,
		"done": false
	}
	_texts.append(entry)

## 便捷方法
func add_damage(text: String, x: float, y: float, critical: bool = false) -> void:
	add(text, x, y, TextType.CRITICAL if critical else TextType.DAMAGE)

func add_heal(text: String, x: float, y: float) -> void:
	add(text, x, y, TextType.HEAL)

func add_exp(text: String, x: float, y: float) -> void:
	add(text, x, y, TextType.EXP)

func add_capture_success(text: String, x: float, y: float) -> void:
	add(text, x, y, TextType.CAPTURE_SUCCESS)

func add_capture_fail(text: String, x: float, y: float) -> void:
	add(text, x, y, TextType.CAPTURE_FAIL)

## ============================================
# 更新逻辑（帧更新）
## ============================================

func _process(delta: float) -> void:
	var dt_ms := delta * 1000.0
	
	# 从后往前遍历，移除完成的条目
	var i := _texts.size() - 1
	while i >= 0:
		var t_data = _texts[i]
		if t_data["done"]:
			_texts.remove_at(i)
		else:
			_update_text(t_data, dt_ms)
		i -= 1

func _update_text(t_data: Dictionary, dt_ms: float) -> void:
	if t_data["done"]:
		return
	
	t_data["timer"] += dt_ms
	var t: float = t_data["timer"]
	var phase: String = t_data["phase"]
	var duration: float = t_data["duration"]
	
	if phase == "pop":
		if t < POP_END_MS:
			var progress: float = t / POP_END_MS
			t_data["scale"] = 0.5 + 0.7 * progress  # 0.5 → 1.2
			t_data["opacity"] = progress             # 0 → 1
		else:
			t_data["phase"] = "rise"
			t_data["timer"] = t - POP_END_MS
			var crit_scale: float = 1.3 if t_data["critical"] else 1.0
			t_data["scale"] = 1.2 * crit_scale
			t_data["opacity"] = 1.0
	
	elif phase == "rise":
		var rise_duration := RISE_END_MS - POP_END_MS
		if t < rise_duration:
			var progress: float = t / rise_duration
			var crit_scale: float = 1.3 if t_data["critical"] else 1.0
			t_data["scale"] = (1.2 - 0.2 * progress) * crit_scale  # 1.2 → 1.0
			t_data["y"] = t_data["start_y"] - OFFSET_Y * progress  # 上浮
		else:
			t_data["phase"] = "fade"
			t_data["timer"] = t - rise_duration
			var crit_scale: float = 1.3 if t_data["critical"] else 1.0
			t_data["scale"] = 1.0 * crit_scale
			t_data["opacity"] = 1.0
			t_data["y"] = t_data["start_y"] - OFFSET_Y  # 停在最高点
	
	elif phase == "fade":
		var fade_duration := duration - RISE_END_MS
		if t < fade_duration:
			var progress: float = t / fade_duration
			t_data["opacity"] = 1.0 - progress
			t_data["y"] = t_data["start_y"] - OFFSET_Y - 10.0 * progress  # 继续轻微上飘
		else:
			t_data["opacity"] = 0.0
			t_data["done"] = true

## ============================================
# 渲染
## ============================================

func _draw() -> void:
	for t_data in _texts:
		if t_data["opacity"] <= 0.0:
			continue
		
		var display_size: float = 16.0 * t_data["scale"]  # 基准16px
		var color: Color = TYPE_COLORS.get(t_data["type"], Color.WHITE)
		color.a = t_data["opacity"]
		
		var pos := Vector2(t_data["x"], t_data["y"])
		var localized_text := TranslationServer.translate(str(t_data["text"]))
		draw_string(PROJECT_ROUND_FONT, pos + Vector2(0.0, -2.0), localized_text, HORIZONTAL_ALIGNMENT_CENTER, -1, display_size, color)

## ============================================
# 公共方法
## ============================================

## 清空所有浮动文字
func clear() -> void:
	_texts.clear()

## 获取当前文字数量
func get_count() -> int:
	return _texts.size()

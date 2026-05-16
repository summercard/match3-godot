# ============================================
# ui/scene/scene_tutorial.gd - 新手引导场景
# 翻译自: minigame-1/js/ui/sceneTutorial.js
# ============================================
# 核心职责：
# - 多步骤引导流程（遮罩 + 高亮提示）
# - 步骤状态管理（当前步骤 / 完成状态）
# - 引导完成后标记已看过的状态

class_name SceneTutorial
extends Control

## 信号定义
signal tutorial_completed()

## 设计尺寸
const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0

## 引导步骤内容
class TutorialStep:
	var title: String
	var content: String
	var icon: String
	var hint: String
	
	func _init(p_title: String, p_content: String, p_icon: String, p_hint: String = "") -> void:
		title = p_title
		content = p_content
		icon = p_icon
		hint = p_hint

## 当前状态
var _current_step: int = 0
var _total_steps: int = 5
var _opacity: float = 0.0
var _tutorial_ready: bool = false

## 单例
static var instance: SceneTutorial

## 引导步骤配置
var _steps: Array[TutorialStep] = []

## 跳过按钮区域
var _skip_rect: Rect2 = Rect2(0, 0, 80, 36)

## 下一步按钮区域
var _next_btn_rect: Rect2 = Rect2(0, 0, 200, 56)

## 主题颜色
const C := {
	"bg_medium": Color(0.04, 0.07, 0.15),
	"bg_card": Color(0.1, 0.15, 0.25),
	"primary": Color(0.1, 0.5, 1.0),
	"success": Color(0.2, 0.8, 0.3),
	"text_primary": Color(1.0, 1.0, 1.0),
	"text_secondary": Color(0.7, 0.75, 0.85),
	"text_muted": Color(0.5, 0.55, 0.65)
}

## Font sizes
const FONT_SIZES := {
	"title": 22.0,
	"subtitle": 16.0,
	"body": 14.0,
	"small": 12.0,
	"tiny": 10.0,
	"icon": 28.0,
	"number": 16.0,
	"display": 32.0
}

## ============================================
# 生命周期
## ============================================

var _bg_texture: ColorRect

func _add_dark_background() -> void:
	_bg_texture = ColorRect.new()
	_bg_texture.color = Color(0.04, 0.07, 0.15, 1.0)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

func _ready() -> void:
	_add_dark_background()
	instance = self
	_init_steps()

func _init_steps() -> void:
	_steps = [
		TutorialStep.new(
			"欢迎来到三消宝可梦",
			"一款融合三消玩法的宝可梦冒险游戏！\n通过消除宝石来攻击野生怪物，\n收服它们成为你的伙伴！",
			"🎮",
			""
		),
		TutorialStep.new(
			"滑动消除宝石",
			"在8x8的棋盘上滑动手指，\n将3个或以上相同的宝石连成一线即可消除。\n消除越多，伤害越大！",
			"👆",
			"示例：左右滑动或上下滑动"
		),
		TutorialStep.new(
			"击败野生怪物",
			"每次消除宝石都会对敌方怪物造成伤害。\n合理规划消除顺序，\n将怪物血量降为零即可获胜！",
			"⚔️",
			""
		),
		TutorialStep.new(
			"收服你的伙伴",
			"战斗胜利后有几率收服怪物！\n使用【精灵球】可以提高收服成功率。\n组建强力队伍挑战更强关卡！",
			"🪨",
			""
		),
		TutorialStep.new(
			"组建你的队伍",
			"在【队伍编成】中放置至少1只怪物，\n才能开始战斗。\n合理搭配属性克制，让战斗更轻松！",
			"👥",
			""
		)
	]

func init(data: Dictionary = {}) -> void:
	print("[SceneTutorial] 新手引导初始化")
	_opacity = 0.0
	_tutorial_ready = false
	
	# 从保存的进度恢复（最多从步骤3开始，避免跳过太多）
	var progress := _load_tutorial_progress()
	if progress.get("completed", false) and progress.get("currentStep", 0) > 0:
		_current_step = mini(progress["currentStep"], _total_steps - 2)
	else:
		_current_step = 0

func _load_tutorial_progress() -> Dictionary:
	# TODO: 从 SaveManager 加载引导进度
	return { "completed": false, "currentStep": 0 }

func _save_tutorial_progress(step: int) -> void:
	# TODO: 保存引导进度到 SaveManager
	pass

## ============================================
# 输入处理
## ============================================

func _gui_input(event: InputEvent) -> void:
	if not _tutorial_ready:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)

func _on_tap(x: float, y: float) -> void:
	if not _tutorial_ready:
		return
	
	# 跳过按钮区域（左上角）
	if _skip_rect.has_point(Vector2(x, y)):
		_skip_tutorial()
		return
	
	# 下一步按钮区域（底部中央）
	if _next_btn_rect.has_point(Vector2(x, y)):
		_next_step()

## ============================================
# 引导逻辑
## ============================================

func _next_step() -> void:
	_current_step += 1
	
	if _current_step >= _total_steps:
		_complete_tutorial()
	else:
		# 播放步骤切换动画（简单淡出淡入）
		_opacity = 0.0
		_save_tutorial_progress(_current_step)

func _skip_tutorial() -> void:
	print("[SceneTutorial] 跳过引导")
	_complete_tutorial()

func _complete_tutorial() -> void:
	# 标记引导完成
	_save_tutorial_progress(_total_steps)
	
	_opacity = 0.0
	_tutorial_ready = false
	
	emit_signal("tutorial_completed")
	
	# 延迟进入主菜单
	await get_tree().create_timer(0.5).timeout
	# TODO: 切换到主菜单场景

## ============================================
# 更新逻辑
## ============================================

func _process(delta: float) -> void:
	# 淡入动画
	if _opacity < 1.0:
		_opacity += delta * 2.0
		if _opacity >= 1.0:
			_opacity = 1.0
			_tutorial_ready = true

## ============================================
# 渲染
## ============================================

func _draw() -> void:
	var w := DESIGN_WIDTH
	var h := DESIGN_HEIGHT
	var a := _opacity
	
	if a <= 0.0:
		return
	
	# 半透明黑色背景
	draw_rect(Rect2(0, 0, w, h), Color(0.0, 0.0, 0.0, 0.85 * a))
	
	# 跳过按钮
	var skip_x := w * 0.08
	var skip_y := h * 0.05
	_skip_rect = Rect2(skip_x, skip_y, 80, 36)
	_draw_rounded_rect(skip_x, skip_y, 80, 36, 8.0, Color(1.0, 1.0, 1.0, 0.1 * a))
	_draw_text_with_shadow("跳过", skip_x + 40, skip_y + 18, Color(1.0, 1.0, 1.0, 0.6 * a), FONT_SIZES["body"])
	
	# 进度点
	var dot_y := h * 0.12
	var dot_spacing := 28.0
	var start_x := w / 2.0 - ((_total_steps - 1) * dot_spacing) / 2.0
	
	for i in range(_total_steps):
		var dx := start_x + i * dot_spacing
		var is_active := i == _current_step
		var dot_radius: float = 8.0 if is_active else 5.0
		var dot_color := Color(1.0, 1.0, 1.0, a) if is_active else Color(1.0, 1.0, 1.0, 0.3 * a)
		_draw_circle(dx, dot_y, dot_radius, dot_color)
	
	# 步骤指示文字
	_draw_text_with_shadow("%d / %d" % [_current_step + 1, _total_steps], w / 2.0, h * 0.18, Color(1.0, 1.0, 1.0, 0.5 * a), FONT_SIZES["small"])
	
	var step: TutorialStep = _steps[_current_step]
	
	# 大图标
	_draw_text_with_shadow(step.icon, w / 2.0, h * 0.32, Color(1.0, 1.0, 1.0, a), 64.0)
	
	# 步骤标题
	_draw_text_with_shadow(step.title, w / 2.0, h * 0.44, Color(1.0, 1.0, 1.0, a), FONT_SIZES["title"], true)
	
	# 内容说明（多行居中）
	var lines: Array = step.content.split("\n")
	var line_y: float = h * 0.52
	for line in lines:
		_draw_text_with_shadow(line, w / 2.0, line_y, Color(0.78, 0.78, 0.86, a), FONT_SIZES["body"])
		line_y += 28.0
	
	# 手势提示（如果有）
	if step.hint != "":
		_draw_text_with_shadow(step.hint, w / 2.0, h * 0.66, Color(0.59, 0.59, 0.71, 0.6 * a), FONT_SIZES["small"])
	
	# 手势示意图（步骤2显示滑动示意）
	if _current_step == 1:
		_draw_swipe_demo(w, h)
	
	# 下一步按钮
	if _tutorial_ready:
		_draw_next_button(w, h, a)

func _draw_swipe_demo(w: float, h: float) -> void:
	# 棋盘示意
	var grid_size := 40.0
	var grid_x := w / 2.0 - grid_size * 1.5
	var grid_y := h * 0.72 - grid_size * 0.5
	
	var colors := [
		Color(1.0, 0.42, 0.42),
		Color(1.0, 0.85, 0.24),
		Color(0.42, 0.8, 0.47),
		Color(0.3, 0.59, 1.0),
		Color(0.61, 0.35, 0.71)
	]
	
	for row in range(3):
		for col in range(3):
			var color_idx := (row + col) % colors.size()
			var rx := grid_x + col * grid_size + 2.0
			var ry := grid_y + row * grid_size + 2.0
			_draw_rounded_rect(rx, ry, grid_size - 4.0, grid_size - 4.0, 6.0, colors[color_idx])
	
	# 滑动箭头
	_draw_text_with_shadow("⟷", w / 2.0, h * 0.72 + grid_size * 2.8, Color(1.0, 1.0, 1.0, 0.5 * _opacity), FONT_SIZES["title"])

func _draw_next_button(w: float, h: float, a: float) -> void:
	var btn_w := 200.0
	var btn_h := 56.0
	var btn_x := (w - btn_w) / 2.0
	var btn_y := h * 0.78
	
	_next_btn_rect = Rect2(btn_x, btn_y, btn_w, btn_h)
	
	# 按钮发光
	_draw_rounded_rect(btn_x - 3.0, btn_y - 3.0, btn_w + 6.0, btn_h + 6.0, 16.0, Color(0.39, 0.71, 1.0, 0.3 * a))
	
	# 按钮主体
	var is_last := _current_step == _total_steps - 1
	var btn_color: Color = C["success"] if is_last else C["primary"]
	_draw_rounded_rect(btn_x, btn_y, btn_w, btn_h, 12.0, Color(btn_color.r, btn_color.g, btn_color.b, a))
	
	# 按钮文字
	var btn_text: String = "开始冒险" if is_last else "下一步"
	_draw_text_with_shadow(btn_text, btn_x + btn_w / 2.0, btn_y + btn_h / 2.0, Color(1.0, 1.0, 1.0, a), FONT_SIZES["subtitle"], true)

## ============================================
# 辅助绘制方法
## ============================================

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	draw_rect(Rect2(x + r, y, w - r * 2.0, h), color)
	draw_rect(Rect2(x, y + r, w, h - r * 2.0), color)
	draw_rect(Rect2(x, y, r, r), color)
	draw_rect(Rect2(x + w - r, y, r, r), color)
	draw_rect(Rect2(x, y + h - r, r, r), color)
	draw_rect(Rect2(x + w - r, y + h - r, r, r), color)

func _draw_circle(cx: float, cy: float, r: float, color: Color) -> void:
	for dy in range(-int(r), int(r) + 1):
		for dx in range(-int(r), int(r) + 1):
			if dx * dx + dy * dy <= r * r:
				draw_rect(Rect2(cx + dx, cy + dy, 1, 1), color)

func _draw_text_with_shadow(text: String, x: float, y: float, color: Color, size: float, bold: bool = false) -> void:
	var shadow_color := Color(0.0, 0.0, 0.0, 0.55)
	draw_string(ThemeDB.fallback_font, Vector2(x + 1, y + 2), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, size, shadow_color)
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, size, color)

## ============================================
# 清理
## ============================================

func destroy() -> void:
	_tutorial_ready = false

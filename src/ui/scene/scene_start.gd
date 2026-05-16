extends Control
class_name SceneStart

# ============================================
# ui/scene/scene_start.gd - 启动/欢迎画面
# 来源: js/ui/sceneStart.js
# ============================================

# ---- 依赖 ----
const ThemeConstants = preload("res://src/core/theme.gd")

# ---- 常量 ----
const START_ASSETS := {
	"bg": "res://assets/images/start/start_bg_grassland.png",
	"logo": "res://assets/images/start/start_title_logo.png",
	"fire_monster": "res://assets/images/start/monster_fire_lizard.png",
	"water_monster": "res://assets/images/start/monster_water_cub.png",
	"grass_monster": "res://assets/images/start/monster_grass_leaf.png",
	"gem_fire": "res://assets/images/start/gem_fire.png",
	"gem_water": "res://assets/images/start/gem_water.png",
	"gem_grass": "res://assets/images/start/gem_grass.png",
	"gem_thunder": "res://assets/images/start/gem_thunder.png",
	"gem_light": "res://assets/images/start/gem_light.png",
	"btn_start": "res://assets/images/start/ui_btn_start.png",
	"btn_start_normal": "res://assets/images/start/ui_btn_start_normal.png",
	"btn_start_pressed": "res://assets/images/start/ui_btn_start_pressed.png",
	"btn_start_disabled": "res://assets/images/start/ui_btn_start_disabled.png",
	"hint_ribbon": "res://assets/images/start/ui_hint_ribbon.png",
	"version_plaque": "res://assets/images/start/ui_version_plaque.png",
}

# ---- 节点引用 ----
var _label_title: Label = null
var _label_subtitle: Label = null
var _btn_enter: Button = null
var _label_hint: Label = null
var _label_version: Label = null
var _particle_container: Node2D = null
var _fade_tween: Tween = null

# ---- 状态变量 ----
var _opacity: float = 0.0          # 淡入动画
var _is_ready: bool = false          # 淡入完成后才能点击
var _pulse: float = 0.0            # 按钮呼吸动画
var _pulse_dir: int = 1
var _touched_btn: String = ""      # 当前按下的按钮
var _long_press_glow: float = 0.0  # 长按光晕强度（0~1）
var _art_assets: Dictionary = {}    # 美术资源字典
var _art_ready: bool = false
var _bg_cache: bool = false         # 背景缓存是否有效
var _particles: Array = []          # 粒子数组

# ---- 设计分辨率 ----
const DESIGN_WIDTH: float = 375.0
const DESIGN_HEIGHT: float = 667.0

# ============================================
# 生命周期
# ============================================

func _ready() -> void:
	name = "SceneStart"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_ui()
	_init_particles()
	_load_art_assets()
	_fade_in()


func _process(delta: float) -> void:
	_update_fade(delta)
	_update_pulse(delta)
	_update_long_press_glow(delta)
	_update_particles(delta)
	queue_redraw()


# ============================================
# UI 创建
# ============================================

func _create_ui() -> void:
	# 1. ParticleContainer
	_particle_container = Node2D.new()
	_particle_container.name = "ParticleContainer"
	add_child(_particle_container)

	# 2. LabelTitle - 主标题
	_label_title = Label.new()
	_label_title.name = "LabelTitle"
	_label_title.text = "宝可梦三消"
	_label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label_title.add_theme_font_size_override("font_size", 42)
	_label_title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0, 1.0))
	_label_title.position = Vector2(0, DESIGN_HEIGHT * 0.18)
	_label_title.size = Vector2(DESIGN_WIDTH, 60)
	add_child(_label_title)

	# 3. LabelSubtitle - 副标题
	_label_subtitle = Label.new()
	_label_subtitle.name = "LabelSubtitle"
	_label_subtitle.text = "Pokémon Match 3"
	_label_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_subtitle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label_subtitle.add_theme_font_size_override("font_size", 22)
	_label_subtitle.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0, 0.8))
	_label_subtitle.position = Vector2(0, DESIGN_HEIGHT * 0.26)
	_label_subtitle.size = Vector2(DESIGN_WIDTH, 40)
	add_child(_label_subtitle)

	# 4. BtnEnter - 进入按钮
	_btn_enter = Button.new()
	_btn_enter.name = "BtnEnter"
	_btn_enter.text = "开始冒险"
	_btn_enter.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_btn_enter.custom_minimum_size = Vector2(280, 72)
	_btn_enter.position = Vector2((DESIGN_WIDTH - 280.0) / 2.0, DESIGN_HEIGHT * 0.78)
	_btn_enter.size = Vector2(280, 72)
	_btn_enter.add_theme_font_size_override("font_size", 26)
	_btn_enter.pressed.connect(_on_enter_pressed)
	add_child(_btn_enter)

	# 5. LabelHint - 底部提示
	_label_hint = Label.new()
	_label_hint.name = "LabelHint"
	_label_hint.text = "长按按钮进入"
	_label_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label_hint.add_theme_font_size_override("font_size", 16)
	_label_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	_label_hint.position = Vector2(0, DESIGN_HEIGHT * 0.88)
	_label_hint.size = Vector2(DESIGN_WIDTH, 30)
	add_child(_label_hint)

	# 6. LabelVersion - 版本号
	_label_version = Label.new()
	_label_version.name = "LabelVersion"
	_label_version.text = "v1.0.0"
	_label_version.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label_version.add_theme_font_size_override("font_size", 14)
	_label_version.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	_label_version.position = Vector2(0, DESIGN_HEIGHT - 30.0)
	_label_version.size = Vector2(DESIGN_WIDTH, 30)
	add_child(_label_version)


# ============================================
# 初始化
# ============================================

func _fade_in() -> void:
	_opacity = 0.0
	modulate = Color(1, 1, 1, 0)

	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 1.2).from(0.0)
	await _fade_tween.finished
	_is_ready = true


func _load_art_assets() -> void:
	_art_assets.clear()

	var keys = START_ASSETS.keys()
	var loaded_count = 0
	var total = keys.size()

	for key in keys:
		var path = START_ASSETS[key]
		var tex = load(path) if ResourceLoader.exists(path) else null
		var item = {"texture": tex, "loaded": tex != null}
		_art_assets[key] = item

		if tex:
			loaded_count += 1



# ============================================
# 粒子系统
# ============================================

class ParticleData:
	var x: float
	var y: float
	var size: float
	var speed_y: float
	var speed_x: float
	var alpha: float
	var twinkle: float

func _init_particles() -> void:
	_particles.clear()
	var count = 25

	for i in count:
		var p = ParticleData.new()
		p.x = randf() * DESIGN_WIDTH
		p.y = randf() * DESIGN_HEIGHT
		p.size = 1.5 + randf() * 2.5
		p.speed_y = 8.0 + randf() * 15.0
		p.speed_x = -2.0 + randf() * 4.0
		p.alpha = 0.3 + randf() * 0.5
		p.twinkle = randf() * TAU
		_particles.append(p)


func _update_particles(delta: float) -> void:
	for p in _particles:
		p.y += p.speed_y * delta
		p.x += p.speed_x * delta
		p.twinkle += delta * 2.0

		# 从底部回到顶部
		if p.y > DESIGN_HEIGHT + 5:
			p.y = -5
			p.x = randf() * DESIGN_WIDTH
		# 左右边界循环
		if p.x < -5:
			p.x = DESIGN_WIDTH + 5
		elif p.x > DESIGN_WIDTH + 5:
			p.x = -5


# ============================================
# 动画更新
# ============================================

func _update_fade(delta: float) -> void:
	if _opacity < 1.0:
		_opacity += delta * 1.5
		if _opacity >= 1.0:
			_opacity = 1.0
			_is_ready = true


func _update_pulse(delta: float) -> void:
	_pulse += delta * 2.0 * _pulse_dir
	if _pulse > 1.0:
		_pulse = 1.0
		_pulse_dir = -1
	elif _pulse < 0.0:
		_pulse = 0.0
		_pulse_dir = 1


func _update_long_press_glow(delta: float) -> void:
	if _long_press_glow > 0.0 and _touched_btn != "enterBtn":
		_long_press_glow = maxf(0.0, _long_press_glow - delta * 2.0)


# ============================================
# 输入处理
# ============================================

func _on_enter_pressed() -> void:
	if not _is_ready:
		return

	# 检测新手引导状态，决定跳转目标
	# TODO: 连接 SaveManager 的 get_tutorial_progress()
	var tutorial_completed = true  # 暂时默认已完成

	if tutorial_completed:
		_change_to_scene("main")
	else:
		_change_to_scene("tutorial")


func _change_to_scene(scene_name: String) -> void:
	_is_ready = false

	# 淡出动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished

	var sm := get_node_or_null("/root/SceneManager")
	if sm:
		sm.switch_scene(scene_name)


# ============================================
# 绘制辅助
# ============================================

func _draw() -> void:
	var bg_item: Dictionary = _art_assets.get("bg", {})
	var bg_tex: Texture2D = bg_item.get("texture", null)
	if bg_tex:
		# 保持宽高比，居中绘制背景
		var tex_size := bg_tex.get_size()
		var scale_x := size.x / tex_size.x
		var scale_y := size.y / tex_size.y
		var scale := maxf(scale_x, scale_y)  # 覆盖整个区域
		var final_size := tex_size * scale
		var offset := (size - final_size) / 2.0
		draw_texture_rect(bg_tex, Rect2(offset, final_size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.15, 0.18))
	
	# 绘制粒子（小星星菱形）
	var scale_x = size.x / DESIGN_WIDTH
	var scale_y = size.y / DESIGN_HEIGHT
	var scale = minf(scale_x, scale_y)

	for p in _particles:
		var sx = p.x * scale_x
		var sy = p.y * scale_y

		var twinkle_alpha = 0.7 + 0.3 * sin(p.twinkle)
		var final_alpha = p.alpha * twinkle_alpha * _opacity

		var diamond_size = p.size * scale
		var alpha_color = Color(1, 1, 1, final_alpha)

		# 菱形顶点
		var points = [
			Vector2(sx, sy - diamond_size),
			Vector2(sx + diamond_size * 0.6, sy),
			Vector2(sx, sy + diamond_size),
			Vector2(sx - diamond_size * 0.6, sy),
		]
		var color = Color(1, 1, 1, final_alpha)
		draw_colored_polygon(points, color)


func _get_btn_rect() -> Rect2:
	var btn_w = 280.0
	var btn_h = 72.0
	var btn_x = (size.x - btn_w) / 2.0
	var btn_y = size.y * 0.78
	return Rect2(btn_x, btn_y, btn_w, btn_h)

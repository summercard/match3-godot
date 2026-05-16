extends Control
class_name SceneStart

# ============================================
# ui/scene/scene_start.gd - 启动/欢迎画面
# 来源: js/ui/sceneStart.js
# 全图片渲染：bg/logo/怪物立绘/宝石/按钮/提示条/版本牌
# ============================================

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

# ---- 状态 ----
var _art_assets: Dictionary = {}   # { key: { texture: Texture2D, loaded: bool } }
var _opacity: float = 0.0
var _is_ready: bool = false
var _pulse: float = 0.0           # 按钮呼吸脉动 0~1
var _pulse_dir: int = 1
var _idle_time: float = 0.0       # 累计时间（怪物/宝石浮动）
var _touched_btn: String = ""     # "enterBtn" or ""
var _is_pressed: bool = false     # 按钮是否被按下
var _long_press_time: float = 0.0 # 长按计时
var _long_press_glow: float = 0.0 # 长按光晕 0~1
var _long_press_triggered: bool = false  # 长按是否已触发
var _fade_tween: Tween = null
var _particles: Array = []

const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0
const LONG_PRESS_DURATION: float = 0.5  # 长按触发时间（秒）

# ============================================
# 生命周期
# ============================================

func _ready() -> void:
	name = "SceneStart"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_init_particles()
	_load_art_assets()
	_fade_in()


func _process(delta: float) -> void:
	_idle_time += delta
	_update_pulse(delta)
	_update_long_press(delta)
	_update_particles(delta)
	queue_redraw()


# ============================================
# 资产加载
# ============================================

func _load_art_assets() -> void:
	_art_assets.clear()
	for key in START_ASSETS.keys():
		var path: String = START_ASSETS[key]
		var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
		_art_assets[key] = { "texture": tex, "loaded": tex != null }


func _get_tex(key: String) -> Texture2D:
	var item: Dictionary = _art_assets.get(key, {})
	if item.get("loaded", false):
		return item["texture"]
	return null


# ============================================
# 淡入
# ============================================

func _fade_in() -> void:
	_opacity = 0.0
	modulate = Color(1, 1, 1, 0)
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 1.2).from(0.0)
	await _fade_tween.finished
	_is_ready = true


# ============================================
# 粒子
# ============================================

func _init_particles() -> void:
	_particles.clear()
	for i in range(25):
		_particles.append({
			"x": randf() * DESIGN_W,
			"y": randf() * DESIGN_H,
			"size": 1.5 + randf() * 2.5,
			"speed_y": 8.0 + randf() * 15.0,
			"speed_x": -2.0 + randf() * 4.0,
			"alpha": 0.3 + randf() * 0.5,
			"twinkle": randf() * TAU,
		})


func _update_particles(delta: float) -> void:
	for p in _particles:
		p["y"] = p["y"] + p["speed_y"] * delta
		p["x"] = p["x"] + p["speed_x"] * delta
		p["twinkle"] = float(p["twinkle"]) + delta * 2.0
		if float(p["y"]) > DESIGN_H + 5:
			p["y"] = -5.0
			p["x"] = randf() * DESIGN_W
		if float(p["x"]) < -5:
			p["x"] = DESIGN_W + 5
		elif float(p["x"]) > DESIGN_W + 5:
			p["x"] = -5.0


# ============================================
# 动画更新
# ============================================

func _update_pulse(delta: float) -> void:
	_pulse += delta * 2.0 * _pulse_dir
	if _pulse > 1.0:
		_pulse = 1.0
		_pulse_dir = -1
	elif _pulse < 0.0:
		_pulse = 0.0
		_pulse_dir = 1


func _update_long_press(delta: float) -> void:
	if _is_pressed and not _long_press_triggered:
		_long_press_time += delta
		_long_press_glow = minf(1.0, _long_press_time / LONG_PRESS_DURATION)
		if _long_press_time >= LONG_PRESS_DURATION:
			_long_press_triggered = true
			_on_enter()
	elif not _is_pressed:
		if _long_press_glow > 0 and not _long_press_triggered:
			_long_press_glow = maxf(0.0, _long_press_glow - delta * 2.0)


# ============================================
# 输入（长按交互）
# ============================================

func _gui_input(event: InputEvent) -> void:
	if not _is_ready:
		return
	
	var btn_rect := _get_btn_rect()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if btn_rect.has_point(event.position):
					_is_pressed = true
					_touched_btn = "enterBtn"
					_long_press_time = 0.0
					_long_press_triggered = false
			else:
				_is_pressed = false
				_touched_btn = ""
				_long_press_time = 0.0
				_long_press_triggered = false
	
	elif event is InputEventScreenTouch:
		if event.pressed:
			if btn_rect.has_point(event.position):
				_is_pressed = true
				_touched_btn = "enterBtn"
				_long_press_time = 0.0
				_long_press_triggered = false
		else:
			_is_pressed = false
			_touched_btn = ""
			_long_press_time = 0.0
			_long_press_triggered = false


func _on_enter() -> void:
	if not _is_ready:
		return
	_is_ready = false
	
	# 淡出
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	
	# 跳转
	var tutorial_completed = true
	var sm := get_node_or_null("/root/SceneManager")
	if sm:
		sm.switch_scene("main" if tutorial_completed else "tutorial")


# ============================================
# 按钮区域
# ============================================

func _get_btn_rect() -> Rect2:
	var sx: float = size.x / DESIGN_W
	var sy: float = size.y / DESIGN_H
	var s: float = minf(sx, sy)
	# 微信版按钮位置：居中，y ≈ 0.78
	var btn_w: float = 265.0 * s
	var btn_h: float = 72.0 * s
	var btn_x: float = (size.x - btn_w) / 2.0
	var btn_y: float = size.y * 0.78
	return Rect2(btn_x, btn_y, btn_w, btn_h)


# ============================================
# 绘制
# ============================================

func _draw() -> void:
	var sx: float = size.x / DESIGN_W
	var sy: float = size.y / DESIGN_H
	var s: float = minf(sx, sy)
	var ox: float = (size.x - DESIGN_W * s) / 2.0
	var oy: float = (size.y - DESIGN_H * s) / 2.0
	var a: float = _opacity
	
	# 1. 背景
	var bg_tex := _get_tex("bg")
	if bg_tex:
		var tex_size := bg_tex.get_size()
		var scale_cover_x := size.x / tex_size.x
		var scale_cover_y := size.y / tex_size.y
		var cover_scale := maxf(scale_cover_x, scale_cover_y)
		var final_size := tex_size * cover_scale
		var offset := (size - final_size) / 2.0
		draw_texture_rect(bg_tex, Rect2(offset, final_size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.15, 0.18))
	
	# 2. 粒子
	for p in _particles:
		var px: float = ox + float(p["x"]) * s
		var py: float = oy + float(p["y"]) * s
		var twinkle_alpha: float = 0.7 + 0.3 * sin(float(p["twinkle"]))
		var final_alpha: float = float(p["alpha"]) * twinkle_alpha * a
		var dsize: float = float(p["size"]) * s
		var pts := [
			Vector2(px, py - dsize),
			Vector2(px + dsize * 0.6, py),
			Vector2(px, py + dsize),
			Vector2(px - dsize * 0.6, py),
		]
		draw_colored_polygon(pts, Color(1, 1, 1, final_alpha))
	
	# 3. Logo（标题图片）
	var logo_tex := _get_tex("logo")
	if logo_tex:
		var logo_w: float = 335.0 * s
		var logo_h: float = 178.0 * s
		var logo_x: float = ox + 20.0 * s
		var logo_y: float = oy + 20.0 * s
		draw_texture_rect(logo_tex, Rect2(logo_x, logo_y, logo_w, logo_h), false, Color(1, 1, 1, a))
	
	# 4. 三只怪物立绘浮动
	_draw_monster("fire_monster", ox + 38.0 * s, oy + 270.0 * s, 140.0 * s, a, -2.0)
	_draw_monster("water_monster", ox + 118.0 * s, oy + 252.0 * s, 144.0 * s, a, 0.0)
	_draw_monster("grass_monster", ox + 205.0 * s, oy + 274.0 * s, 138.0 * s, a, 2.0)
	
	# 5. 五颗宝石浮动
	var gem_y_base: float = 424.0
	_draw_gem("gem_fire", ox + 112.0 * s, oy + gem_y_base * s, 48.0 * s, a)
	_draw_gem("gem_water", ox + 164.0 * s, oy + (gem_y_base - 16.0) * s, 52.0 * s, a)
	_draw_gem("gem_grass", ox + 218.0 * s, oy + gem_y_base * s, 48.0 * s, a)
	_draw_gem("gem_thunder", ox + 140.0 * s, oy + (gem_y_base + 42.0) * s, 46.0 * s, a)
	_draw_gem("gem_light", ox + 194.0 * s, oy + (gem_y_base + 42.0) * s, 46.0 * s, a)
	
	# 6. 开始按钮（图片 + 光晕 + 按压缩放）
	if _is_ready:
		_draw_enter_button(ox, oy, s, a)
	
	# 7. 提示条（图片）
	var hint_tex := _get_tex("hint_ribbon")
	if hint_tex:
		var hint_w: float = 265.0 * s
		var hint_h: float = hint_w * (float(hint_tex.get_height()) / float(hint_tex.get_width()))
		var hint_x: float = ox + 55.0 * s
		var hint_y: float = oy + DESIGN_H * 0.887 * s
		var hint_alpha: float = (0.58 + _pulse * 0.25) * a
		draw_texture_rect(hint_tex, Rect2(hint_x, hint_y, hint_w, hint_h), false, Color(1, 1, 1, hint_alpha))
	
	# 8. 版本牌（图片）
	var ver_tex := _get_tex("version_plaque")
	if ver_tex:
		var ver_w: float = 80.0 * s
		var ver_h: float = ver_w * (float(ver_tex.get_height()) / float(ver_tex.get_width()))
		var ver_x: float = (size.x - ver_w) / 2.0
		var ver_y: float = oy + (DESIGN_H - 40.0) * s
		draw_texture_rect(ver_tex, Rect2(ver_x, ver_y, ver_w, ver_h), false, Color(1, 1, 1, 0.7 * a))


# ============================================
# 绘制辅助
# ============================================

func _draw_monster(key: String, x: float, y: float, h: float, alpha: float, phase_offset: float) -> void:
	var tex := _get_tex(key)
	if tex == null:
		return
	var tex_w: float = float(tex.get_width())
	var tex_h: float = float(tex.get_height())
	var draw_h: float = h
	var draw_w: float = draw_h * (tex_w / tex_h) if tex_h > 0 else draw_h
	# sin 浮动动画（amplitude 3px，period 1.5s）
	var float_offset: float = sin(_idle_time * TAU / 1.5 + phase_offset) * 3.0
	draw_texture_rect(tex, Rect2(x, y + float_offset, draw_w, draw_h), false, Color(1, 1, 1, alpha))


func _draw_gem(key: String, x: float, y: float, size_px: float, alpha: float) -> void:
	var tex := _get_tex(key)
	if tex == null:
		return
	# sin 浮动（amplitude 4px，period 2s，各宝石有相位差）
	var phase: float = hash(key) % 100 * 0.0628  # 基于 key 的固定相位差
	var float_offset: float = sin(_idle_time * TAU / 2.0 + phase) * 4.0
	draw_texture_rect(tex, Rect2(x, y + float_offset, size_px, size_px), false, Color(1, 1, 1, alpha))


func _draw_enter_button(ox: float, oy: float, s: float, a: float) -> void:
	# 按钮区域
	var btn_rect := _get_btn_rect()
	var is_pressed: bool = _touched_btn == "enterBtn" and _is_pressed
	var press_scale: float = 0.95 if is_pressed else 1.0
	
	# 光晕强度 = 脉动 + 长按加成
	var glow_intensity: float = _pulse + _long_press_glow * 0.5
	
	# 光晕效果（径向渐变圆）
	if glow_intensity > 0.1:
		var glow_alpha: float = glow_intensity * 0.35 * a
		var glow_color := Color(0.2, 0.6, 1.0, glow_alpha)
		var center := btn_rect.position + btn_rect.size / 2.0
		var glow_r: float = btn_rect.size.x * 0.7
		draw_circle(center, glow_r, Color(glow_color.r, glow_color.g, glow_color.b, glow_alpha * 0.3))
		draw_circle(center, glow_r * 0.6, glow_color)
	
	# 按钮图片
	var btn_key: String = "btn_start_pressed" if is_pressed else "btn_start_normal"
	var btn_tex := _get_tex(btn_key)
	if btn_tex == null:
		btn_tex = _get_tex("btn_start")
	if btn_tex:
		var scaled_w: float = btn_rect.size.x * press_scale
		var scaled_h: float = btn_rect.size.y * press_scale
		var draw_x: float = btn_rect.position.x + (btn_rect.size.x - scaled_w) / 2.0
		var draw_y: float = btn_rect.position.y + (btn_rect.size.y - scaled_h) / 2.0
		draw_texture_rect(btn_tex, Rect2(draw_x, draw_y, scaled_w, scaled_h), false, Color(1, 1, 1, a if not is_pressed else a * 0.86))

extends Control
class_name SceneStart

# ============================================
# ui/scene/scene_start.gd - 启动/欢迎画面
# Phase 5.1: 开屏视觉还原
# 来源: js/ui/sceneStart.js
# ============================================

# ---- 资源路径 ----
const ASSET_PATHS := {
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
	"btn_normal": "res://assets/images/start/ui_btn_start_normal.png",
	"btn_pressed": "res://assets/images/start/ui_btn_start_pressed.png",
	"hint_ribbon": "res://assets/images/start/ui_hint_ribbon.png",
	"version_plaque": "res://assets/images/start/ui_version_plaque.png",
}

# ---- 颜色常量（对齐微信 THEME/COLORS）----
const C_PRIMARY := Color(0.35, 0.55, 1.0)
const C_GOLD := Color(1.0, 0.84, 0.0)
const C_WHITE := Color(1.0, 1.0, 1.0)
const C_BG_DARK := Color(0.08, 0.15, 0.18)
const C_BG_PANEL := Color(0.1, 0.12, 0.2)
const C_TEXT_MUTED := Color(0.6, 0.6, 0.7)
const C_TEXT_SECONDARY := Color(0.7, 0.75, 0.85)

# ---- 设计分辨率 ----
const DW := 375.0
const DH := 667.0

# ---- 长按阈值（秒）----
const LONG_PRESS_SEC := 0.5

# ---- 状态 ----
var _opacity: float = 0.0
var _ready_flag: bool = false
var _pulse: float = 0.0
var _pulse_dir: int = 1
var _touching: bool = false
var _lp_glow: float = 0.0
var _hold_time: float = 0.0
var _lp_done: bool = false
var _assets: Dictionary = {}
var _particles: Array = []
var _has_bg: bool = false
var _font: Font

# ---- 缩放（每帧更新）----
var _sx: float = 1.0
var _sy: float = 1.0
var _sc: float = 1.0

# ============================================
# 生命周期
# ============================================

func _ready() -> void:
	name = "SceneStart"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	_load_assets()
	_init_particles()
	_opacity = 0.0
	_ready_flag = false


func _process(delta: float) -> void:
	# 淡入动画
	if _opacity < 1.0:
		_opacity = minf(_opacity + delta * 1.5, 1.0)
		if _opacity >= 1.0:
			_ready_flag = true

	# 呼吸脉冲
	_pulse += delta * 2.0 * _pulse_dir
	if _pulse > 1.0:
		_pulse = 1.0
		_pulse_dir = -1
	elif _pulse < 0.0:
		_pulse = 0.0
		_pulse_dir = 1

	# 长按光晕衰减（未按住时渐消）
	if _lp_glow > 0.0:
		_lp_glow = maxf(0.0, _lp_glow - delta * 2.0)

	# 长按检测
	if _touching and _ready_flag and not _lp_done:
		_hold_time += delta
		_lp_glow = minf(_hold_time / LONG_PRESS_SEC, 1.0)
		if _hold_time >= LONG_PRESS_SEC:
			_lp_done = true
			_do_enter()

	# 粒子更新
	_update_particles(delta)

	# 缩放因子
	_sx = size.x / DW
	_sy = size.y / DH
	_sc = minf(_sx, _sy)

	queue_redraw()


# ============================================
# 输入处理（长按交互）
# ============================================

func _gui_input(event: InputEvent) -> void:
	# ---- 触摸：按下开始计时，松开停止 ----
	if event is InputEventScreenTouch:
		if event.pressed:
			if _in_btn(event.position):
				_begin_hold()
		else:
			_end_hold()
		accept_event()
		return

	# ---- 鼠标：按下开始计时，松开停止 ----
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _in_btn(event.position):
					_begin_hold()
			else:
				_end_hold()
		accept_event()
		return


func _begin_hold() -> void:
	_touching = true
	_hold_time = 0.0
	_lp_done = false


func _end_hold() -> void:
	_touching = false
	_hold_time = 0.0


func _in_btn(pos: Vector2) -> bool:
	return _btn_rect().has_point(pos)


## 获取按钮区域（设计坐标 → 屏幕坐标）
func _btn_rect(press_scale: float = 1.0) -> Rect2:
	var bw = 280.0 * press_scale
	var bh = 72.0 * press_scale
	var sw = bw * _sx
	var sh = bh * _sy
	return Rect2(
		(size.x - sw) / 2.0,
		size.y * 0.78 + (72.0 * _sy - sh) / 2.0,
		sw, sh
	)


func _do_enter() -> void:
	_ready_flag = false
	_touching = false
	_lp_glow = 0.0

	# 淡出后切换场景
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished

	var sm := get_node_or_null("/root/SceneManager")
	if sm:
		sm.switch_scene(_get_entry_scene())

func _get_entry_scene() -> String:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_tutorial_progress"):
		if save_manager.has_method("has_tutorial_progress") and not save_manager.has_tutorial_progress():
			return "main"
		var progress: Dictionary = save_manager.load_tutorial_progress()
		if not progress.get("completed", false):
			return "tutorial"
	return "main"


# ============================================
# 资源加载
# ============================================

func _load_assets() -> void:
	_assets.clear()
	for key in ASSET_PATHS:
		var path: String = ASSET_PATHS[key]
		if ResourceLoader.exists(path):
			var tex = load(path)
			_assets[key] = {"tex": tex, "ok": tex != null}
		else:
			_assets[key] = {"tex": null, "ok": false}
	_has_bg = _assets.get("bg", {}).get("ok", false)


func _tex(key: String) -> Texture2D:
	var d = _assets.get(key, {})
	return d.get("tex") as Texture2D if d.get("ok", false) else null


# ============================================
# 粒子系统（菱形星星飘落）
# ============================================

class Star:
	var x: float = 0.0
	var y: float = 0.0
	var sz: float = 0.0
	var vy: float = 0.0
	var vx: float = 0.0
	var a: float = 0.0
	var tw: float = 0.0


func _init_particles() -> void:
	_particles.clear()
	for _i in range(25):
		var p := Star.new()
		p.x = randf() * DW
		p.y = randf() * DH
		p.sz = 1.5 + randf() * 2.5
		p.vy = 8.0 + randf() * 15.0
		p.vx = -2.0 + randf() * 4.0
		p.a = 0.3 + randf() * 0.5
		p.tw = randf() * TAU
		_particles.append(p)


func _update_particles(dt: float) -> void:
	for p in _particles:
		p.y += p.vy * dt
		p.x += p.vx * dt
		p.tw += dt * 2.0
		if p.y > DH + 5.0:
			p.y = -5.0
			p.x = randf() * DW
		if p.x < -5.0:
			p.x = DW + 5.0
		elif p.x > DW + 5.0:
			p.x = -5.0


# ============================================
# _draw 主入口
# ============================================

func _draw() -> void:
	_draw_bg()
	_draw_stars()
	if _has_bg:
		_draw_art_content()
	else:
		_draw_fallback_content()
	if _ready_flag:
		_draw_glow_button()


# ============================================
# 背景
# ============================================

func _draw_bg() -> void:
	var tex := _tex("bg")
	if tex:
		var ts := tex.get_size()
		var s := maxf(size.x / ts.x, size.y / ts.y)
		var fs := ts * s
		var off := (size - fs) / 2.0
		draw_texture_rect(tex, Rect2(off, fs), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), C_BG_DARK)


# ============================================
# 粒子绘制
# ============================================

func _draw_stars() -> void:
	for p in _particles:
		var px: float = p.x * _sx
		var py: float = p.y * _sy
		var ta: float = 0.7 + 0.3 * sin(p.tw)
		var fa: float = p.a * ta * _opacity
		var ss: float = p.sz * _sc
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(px, py - ss),
				Vector2(px + ss * 0.6, py),
				Vector2(px, py + ss),
				Vector2(px - ss * 0.6, py),
			]),
			Color(1.0, 1.0, 1.0, fa)
		)


# ============================================
# 美术资源模式内容
# ============================================

func _draw_art_content() -> void:
	var w := size.x
	var h := size.y

	# ---- Logo 或回退标题 ----
	var logo := _tex("logo")
	if logo:
		var lw := 335.0 * _sx
		var lh := 178.0 * _sy
		draw_texture_rect(logo, Rect2(20.0 * _sx, 20.0 * _sy, lw, lh), false,
			Color(1, 1, 1, _opacity))
		# 渐变标题文字（对齐微信 art 模式）
		_draw_gradient_text("萌灵消消大冒险", w / 2.0, h * 0.40,
			28.0 * _sc, C_PRIMARY, C_GOLD, _opacity)
		# 副标题渐变（✦ 三消冒险 ✦）
		_draw_gradient_text("✦ 三消冒险 ✦", w / 2.0, h * 0.51,
			20.0 * _sc, C_PRIMARY, C_GOLD, _opacity)
	else:
		_draw_stroke_text("萌灵消消大冒险", w / 2.0, h * 0.15,
			C_GOLD, Color(0.04, 0.06, 0.16), 28.0 * _sc, 4.0 * _sc)
		_draw_gradient_text("三消宝可梦", w / 2.0, h * 0.32,
			44.0 * _sc, C_PRIMARY, C_GOLD, _opacity)

	# ---- 三只怪物 sin 浮动 ----
	_draw_monster("fire_monster",  38.0, 270.0, 140.0, -2.0)
	_draw_monster("water_monster", 118.0, 252.0, 144.0,  0.0)
	_draw_monster("grass_monster", 205.0, 274.0, 138.0,  2.0)

	# ---- 三颗属性宝石浮动（错相 sin）----
	_draw_gem("gem_fire",    gem_center_x - 48.0, gem_top_y + 2.0,  46.0,  0.0)
	_draw_gem("gem_water",   gem_center_x,        gem_top_y - 6.0,  50.0,  PI / 3.0)
	_draw_gem("gem_grass",   gem_center_x + 48.0, gem_top_y + 2.0,  46.0,  PI * 2.0 / 3.0)

	# ---- ◈ 两侧装饰 ----
	_draw_centered_text("◈", 52.0 * _sx, h * 0.862, 18.0 * _sc,
		Color(C_GOLD, _opacity * 0.65))
	_draw_centered_text("◈", w - 52.0 * _sx, h * 0.862, 18.0 * _sc,
		Color(C_GOLD, _opacity * 0.65))

	# ---- 提示横幅 ----
	if _ready_flag:
		_draw_hint_art(w, h)

	# ---- 版本号 ----
	_draw_version_art(w, h)


func _draw_monster(key: String, mx: float, my: float, ms: float, bob_off: float) -> void:
	var tex := _tex(key)
	if not tex:
		return
	var bob := sin(_pulse * PI * 2.0 + bob_off) * 4.0 * _sc
	var ds := ms * _sc
	draw_texture_rect(tex,
		Rect2(mx * _sx, my * _sy + bob, ds, ds),
		false, Color(1, 1, 1, _opacity))


func _draw_gem(key: String, gx: float, gy: float, gs: float, bob_off: float = 0.0) -> void:
	var tex := _tex(key)
	if not tex:
		return
	var bob := sin(_pulse * PI * 2.0 + bob_off) * 4.0 * _sc
	var glow := 1.0 + _pulse * 0.08
	var ds := gs * _sc * glow
	draw_texture_rect(tex,
		Rect2(gx * _sx - ds / 2.0, gy * _sy + bob - ds / 2.0, ds, ds),
		false, Color(1, 1, 1, _opacity))


func _draw_hint_art(w: float, h: float) -> void:
	var ha := 0.58 + _pulse * 0.25
	var hfs := 16.0 * _sc
	_draw_centered_text("点击开始你的冒险之旅",
		w / 2.0, h * 0.887 + 4.0 * _sc, hfs,
		Color(1, 1, 1, _opacity * ha * 0.85))


func _draw_version_art(w: float, h: float) -> void:
	var plaque := _tex("version_plaque")
	var pw := 82.0 * _sx
	var ph := 30.0 * _sy
	var px := (w - pw) / 2.0
	var py := h * 0.952

	if plaque:
		draw_texture_rect(plaque, Rect2(px, py, pw, ph), false,
			Color(1, 1, 1, _opacity * 0.72))

	var vfs := 12.0 * _sc
	_draw_centered_text("v0.1.0", w / 2.0, py + ph / 2.0, vfs,
		Color(1, 1, 1, _opacity * 0.72))


# ============================================
# 回退模式内容（无美术资源）
# ============================================

func _draw_fallback_content() -> void:
	var w := size.x
	var h := size.y

	# ---- 装饰星点 ----
	var dots := [
		[0.15, 0.12, 2.0, 0.4],
		[0.75, 0.18, 1.5, 0.3],
		[0.55, 0.08, 1.0, 0.5],
		[0.85, 0.35, 2.0, 0.2],
		[0.25, 0.45, 1.5, 0.3],
	]
	for d in dots:
		draw_circle(Vector2(w * d[0], h * d[1]), d[2] * _sc,
			Color(1, 1, 1, d[3] * _opacity))

	# ---- 主标题（描边 + 渐变）----
	var ty := h * 0.32
	var title_fs := 44.0 * _sc
	_draw_stroke_text("三消宝可梦", w / 2.0, ty,
		C_WHITE, Color.BLACK, title_fs, 4.0 * _sc)
	_draw_gradient_text("三消宝可梦", w / 2.0, ty,
		title_fs, C_PRIMARY, C_GOLD, _opacity)

	# ---- 副标题 ----
	var sty := h * 0.42
	_draw_stroke_text("✦ 三消冒险 ✦", w / 2.0, sty,
		C_GOLD, Color.BLACK, 20.0 * _sc, 2.0 * _sc)

	# ---- 装饰星 emoji（上排）----
	var efs := 16.0 * _sc
	_draw_centered_text("✨ ⭐ ✨ ⭐ ✨", w / 2.0, h * 0.86, efs,
		Color(C_GOLD, 0.5 * _opacity))

	# ---- ◈ 两侧装饰 ----
	_draw_centered_text("◈", w * 0.15, h * 0.88, 16.0 * _sc,
		Color(C_GOLD, _opacity * 0.6))
	_draw_centered_text("◈", w * 0.85, h * 0.88, 16.0 * _sc,
		Color(C_GOLD, _opacity * 0.6))

	# ---- 装饰横线 ----
	var line_w := 60.0 * _sc
	var line_cx := w / 2.0
	draw_line(
		Vector2(line_cx - line_w / 2.0, h * 0.88),
		Vector2(line_cx + line_w / 2.0, h * 0.88),
		Color(C_GOLD, 0.3 * _opacity), 1.0)

	# ---- 版本号 ----
	_draw_centered_text("v0.1.0", w / 2.0, h * 0.93, 12.0 * _sc,
		Color(C_TEXT_MUTED, _opacity))

	# ---- 底部星 emoji ----
	_draw_centered_text("✨ ⭐ ✨ ⭐ ✨", w / 2.0, h * 0.96, 12.0 * _sc,
		Color(C_GOLD, 0.5 * _opacity))

	# ---- 提示文字（动态透明度）----
	if _ready_flag:
		var ha := 0.4 + _pulse * 0.3
		_draw_centered_text("点击开始你的冒险之旅",
			w / 2.0, size.y * 0.82 + 8.0 * _sc, 16.0 * _sc,
			Color(C_TEXT_SECONDARY, ha * _opacity))


# ============================================
# 光晕按钮绘制
# ============================================

func _draw_glow_button() -> void:
	var pressed := _touching and not _lp_done
	var ps := 0.95 if pressed else 1.0
	var btn := _btn_rect(ps)
	var center := btn.position + btn.size / 2.0

	# ---- 发光光晕（多层径向渐变模拟）----
	var glow_i := _pulse + _lp_glow * 0.5
	var glow_a := 0.3 + glow_i * 0.4
	var radius := maxf(btn.size.x, btn.size.y) * 0.8

	for i in range(6):
		var t := float(i) / 6.0
		var r := radius * (1.0 - t * 0.4)
		var a := glow_a * (1.0 - t) * 0.12 * _opacity
		draw_circle(center, r,
			Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, a))

	# ---- 按钮背景 ----
	var tex_key := "btn_pressed" if pressed else "btn_normal"
	var tex := _tex(tex_key)
	if not tex:
		tex = _tex("btn_normal")

	if tex:
		# 使用原始纹理尺寸居中绘制（避免 draw_texture_rect 拉伸变形）
		var ts := tex.get_size()
		var scale2 := minf(btn.size.x / ts.x, btn.size.y / ts.y)
		var dw := ts.x * scale2
		var dh := ts.y * scale2
		var dx := btn.position.x + (btn.size.x - dw) / 2.0
		var dy := btn.position.y + (btn.size.y - dh) / 2.0
		draw_texture_rect(tex, Rect2(dx, dy, dw, dh), false, Color(1, 1, 1, _opacity))
	else:
		# 回退：纯色圆角矩形
		draw_rect(btn, Color(0.25, 0.45, 0.85, _opacity))
		if pressed:
			draw_rect(btn, Color(0, 0, 0, 0.15))

	# ---- 按钮文字（阴影 + 正文）----
	var label := "开 始 冒 险" if _has_bg else "进 入 游 戏"
	var bfs := 24.0 * _sc
	var ty := center.y + bfs * 0.35

	# 阴影
	_draw_centered_text(label, center.x + 1.0 * _sc, ty + 2.0 * _sc, bfs,
		Color(0, 0, 0, 0.45 * _opacity))
	# 正文
	_draw_centered_text(label, center.x, ty, bfs,
		Color(1, 1, 1, _opacity))


# ============================================
# 绘制辅助：居中文字
# ============================================

func _draw_centered_text(text: String, cx: float, y: float, fs: float, color: Color) -> void:
	var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_font, Vector2(cx - tw / 2.0, y), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


# ============================================
# 绘制辅助：渐变文字（逐字符着色）
# ============================================

func _draw_gradient_text(text: String, cx: float, cy: float, fs: float,
		from: Color, to: Color, alpha: float) -> void:
	var n := text.length()
	if n == 0:
		return

	# 测量各字符宽度
	var widths := []
	var total_w := 0.0
	for i in range(n):
		var cw := _font.get_string_size(text.substr(i, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		widths.append(cw)
		total_w += cw

	var x := cx - total_w / 2.0
	var y := cy + fs * 0.35  # baseline 近似

	for i in range(n):
		var t := float(i) / maxf(float(n - 1), 1.0)
		# from → to → from（对称渐变）
		var ct := t * 2.0
		if ct > 1.0:
			ct = 2.0 - ct
		var c := from.lerp(to, ct)
		c.a = alpha
		draw_string(_font, Vector2(x, y), text.substr(i, 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
		x += widths[i]


# ============================================
# 绘制辅助：描边文字
# ============================================

func _draw_stroke_text(text: String, cx: float, cy: float,
		fill: Color, stroke: Color, fs: float, sw: float) -> void:
	var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := cx - tw / 2.0
	var y := cy + fs * 0.35
	var sc := Color(stroke.r, stroke.g, stroke.b, _opacity)

	# 8 方向描边
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			draw_string(_font, Vector2(x + dx * sw, y + dy * sw), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, sc)

	# 填充
	var fc := Color(fill.r, fill.g, fill.b, _opacity)
	draw_string(_font, Vector2(x, y), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fc)

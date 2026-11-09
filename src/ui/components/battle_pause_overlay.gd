class_name BattlePauseOverlay
extends Control
## 战斗内暂停浮层：全屏压暗 + 居中面板。
##
## 面板只负责绘制和命中区域，不改战斗状态：场景在打开时冻结时间尺度，
## 点击「继续」恢复；三个开关写回同一份 settings，与设置页互通。
## 命中区域与绘制共用同一组常量，避免输入和画面各写一套坐标。

const DESIGN_SIZE := Vector2(375.0, 667.0)

## 面板与内部控件坐标（设计分辨率 375×667）。
const PANEL_RECT := Rect2(42.0, 132.0, 291.0, 414.0)
const RESUME_RECT := Rect2(67.0, 242.0, 241.0, 52.0)
const EXIT_RECT := Rect2(67.0, 458.0, 241.0, 48.0)
const ROW_RECTS := [
	Rect2(67.0, 308.0, 241.0, 40.0),
	Rect2(67.0, 354.0, 241.0, 40.0),
	Rect2(67.0, 400.0, 241.0, 40.0),
]
const TOGGLE_SIZE := Vector2(56.0, 27.0)
const TOGGLE_KEYS := ["soundOn", "musicOn", "vibrationOn"]
const TOGGLE_LABELS := ["游戏音效", "背景音乐", "震动反馈"]

const COL_GOLD := Color(1.0, 0.80, 0.28)
const COL_TEXT := Color(1.0, 1.0, 1.0)
const COL_MUTED := Color(0.66, 0.72, 0.83)
const COL_DIM := Color(0.42, 0.49, 0.60)
const COL_SHADOW := Color(0.03, 0.04, 0.09, 0.92)
const COL_ROW := Color(0.06, 0.10, 0.18, 0.68)
const COL_TOGGLE_ON := Color(0.18, 0.72, 0.28)
const COL_TOGGLE_OFF := Color(0.21, 0.27, 0.36)
const COL_KNOB := Color(1.0, 0.95, 0.77)

var paused: bool = false
var settings: Dictionary = {
	"soundOn": true,
	"musicOn": true,
	"vibrationOn": true,
}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200
	visible = false


func open(settings_data: Dictionary) -> void:
	settings = settings_data.duplicate(true)
	_ensure_defaults()
	paused = true
	visible = true
	queue_redraw()


func close() -> void:
	paused = false
	visible = false
	queue_redraw()


func refresh_settings(settings_data: Dictionary) -> void:
	settings = settings_data.duplicate(true)
	_ensure_defaults()
	queue_redraw()


func toggle_index_at(pos: Vector2) -> int:
	for i in range(ROW_RECTS.size()):
		if toggle_rect(i).has_point(pos):
			return i
	return -1


func resume_rect() -> Rect2:
	return RESUME_RECT


func exit_rect() -> Rect2:
	return EXIT_RECT


func toggle_rect(index: int) -> Rect2:
	var row: Rect2 = ROW_RECTS[index]
	return Rect2(
		row.position.x + row.size.x - TOGGLE_SIZE.x - 12.0,
		row.position.y + (row.size.y - TOGGLE_SIZE.y) * 0.5,
		TOGGLE_SIZE.x,
		TOGGLE_SIZE.y
	)


func toggle_key(index: int) -> String:
	if index < 0 or index >= TOGGLE_KEYS.size():
		return ""
	return TOGGLE_KEYS[index]


func is_on(index: int) -> bool:
	return bool(settings.get(toggle_key(index), true))


func _ensure_defaults() -> void:
	for key: String in TOGGLE_KEYS:
		if not settings.has(key):
			settings[key] = true


## ============================================
## 绘制
## ============================================

func _draw() -> void:
	if not paused:
		return
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.01, 0.02, 0.05, 0.68), true)
	_draw_panel()
	_draw_title()
	_draw_button(RESUME_RECT, "继续", Color(0.11, 0.33, 0.70, 1.0), COL_GOLD, 20.0)
	for i in range(ROW_RECTS.size()):
		_draw_row(i)
	_draw_button(EXIT_RECT, "退出战斗", Color(0.38, 0.10, 0.12, 1.0), Color(0.95, 0.45, 0.35, 0.95), 18.0)
	_draw_center_text("设置会同步到设置页", 524.0, COL_DIM, 10.0, 240.0)


func _draw_panel() -> void:
	_draw_style_box(PANEL_RECT.grow(5.0), Color(0.0, 0.0, 0.0, 0.38), Color(0.0, 0.0, 0.0, 0.0), 0, 20)
	_draw_style_box(PANEL_RECT, Color(0.08, 0.11, 0.20, 1.0), COL_GOLD, 2, 16)
	_draw_style_box(PANEL_RECT.grow(-4.0), Color(0.035, 0.07, 0.15, 0.98), Color(1.0, 0.82, 0.36, 0.35), 1, 13)
	# 顶部高光与标题分隔线，让深色面板在棋盘上仍有层次。
	draw_rect(Rect2(PANEL_RECT.position.x + 22.0, PANEL_RECT.position.y + 8.0, PANEL_RECT.size.x - 44.0, 2.0), Color(1.0, 1.0, 1.0, 0.10), true)
	draw_rect(Rect2(PANEL_RECT.position.x + 26.0, 236.0, PANEL_RECT.size.x - 52.0, 1.0), Color(1.0, 0.82, 0.36, 0.28), true)


func _draw_title() -> void:
	var gear := _load_texture("res://assets/images/battle/ui/ui_settings_button.png")
	if gear != null:
		_draw_texture_contain(gear, Rect2(PANEL_RECT.get_center().x - 18.0, 146.0, 36.0, 36.0))
	_draw_center_text("战斗暂停", 210.0, COL_GOLD, 24.0, 220.0)
	_draw_center_text("战斗已暂停", 230.0, COL_MUTED, 11.0, 180.0)


func _draw_row(index: int) -> void:
	var row: Rect2 = ROW_RECTS[index]
	_draw_style_box(row, COL_ROW, Color(1.0, 0.82, 0.36, 0.16), 1, 8)
	draw_rect(Rect2(row.position.x + 9.0, row.position.y + 10.0, 3.0, row.size.y - 20.0), COL_GOLD, true)
	_draw_left_text(TOGGLE_LABELS[index], Vector2(row.position.x + 22.0, row.position.y + 26.0), COL_TEXT, 15.0, 140.0)
	_draw_toggle(toggle_rect(index), is_on(index))


func _draw_toggle(track: Rect2, is_on_state: bool) -> void:
	var color: Color = COL_TOGGLE_ON if is_on_state else COL_TOGGLE_OFF
	var radius: float = track.size.y * 0.5
	draw_circle(track.position + Vector2(radius, radius), radius, color)
	draw_circle(track.position + Vector2(track.size.x - radius, radius), radius, color)
	draw_rect(Rect2(track.position.x + radius, track.position.y, track.size.x - track.size.y, track.size.y), color, true)
	var knob_x: float = track.position.x + track.size.x - radius if is_on_state else track.position.x + radius
	draw_circle(Vector2(knob_x, track.position.y + radius), 11.0, COL_KNOB)
	# 文案放在旋钮另一侧，避免被滑块压住。
	var label_center_x: float = track.position.x + radius if is_on_state else track.position.x + track.size.x - radius
	_draw_center_text("ON" if is_on_state else "OFF", track.position.y + 19.0, COL_TEXT, 10.0, 30.0, label_center_x)


func _draw_button(rect: Rect2, label: String, fill: Color, border: Color, font_size: float) -> void:
	_draw_style_box(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.0, 0.0, 0.0, 0.35), Color(0.0, 0.0, 0.0, 0.0), 0, 13)
	_draw_style_box(rect, fill, border, 2, 13)
	draw_rect(Rect2(rect.position.x + 10.0, rect.position.y + 4.0, rect.size.x - 20.0, 2.0), Color(1.0, 1.0, 1.0, 0.18), true)
	_draw_center_text(label, rect.position.y + rect.size.y * 0.5 + font_size * 0.36, COL_TEXT, font_size, rect.size.x - 16.0, rect.get_center().x)


func _draw_style_box(rect: Rect2, bg: Color, border: Color, border_width: int, radius: float) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)


func _draw_center_text(text: String, y: float, color: Color, font_size: float, width: float, center_x: float = -1.0) -> void:
	var use_x: float = PANEL_RECT.get_center().x if center_x < 0.0 else center_x
	var font := ThemeDB.fallback_font
	var size_i := int(font_size)
	draw_string(font, Vector2(use_x - width / 2.0 + 1.0, y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, COL_SHADOW)
	draw_string(font, Vector2(use_x - width / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, color)


func _draw_left_text(text: String, pos: Vector2, color: Color, font_size: float, width: float) -> void:
	var font := ThemeDB.fallback_font
	var size_i := int(font_size)
	draw_string(font, Vector2(pos.x + 1.0, pos.y + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, COL_SHADOW)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, color)


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded = load(path)
	return loaded if loaded is Texture2D else null


func _draw_texture_contain(tex: Texture2D, rect: Rect2) -> void:
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var draw_size := size * scale
	var draw_pos := rect.position + (rect.size - draw_size) * 0.5
	draw_texture_rect(tex, Rect2(draw_pos, draw_size), false)

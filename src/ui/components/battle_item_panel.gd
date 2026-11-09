class_name BattleItemPanel
extends Control
## 战斗内道具列表：顶栏「道具」按钮展开的浮动卡片。
##
## 只负责绘制和命中区域，道具数据与使用逻辑由战斗场景持有；
## 作为独立子节点绘制，保证盖在敌人血条等 HUD 之上，但低于暂停浮层。

const PANEL_RIGHT := 367.0
const PANEL_WIDTH := 276.0
const PANEL_TOP := 60.0
const HEADER_H := 34.0
const ROW_H := 54.0
const PAD := 8.0

const COL_PANEL := Color(0.045, 0.075, 0.15, 0.98)
const COL_BORDER := Color(1.0, 0.82, 0.36, 0.85)
const COL_GOLD := Color(1.0, 0.80, 0.28)
const COL_TEXT := Color(1.0, 1.0, 1.0)
const COL_MUTED := Color(0.66, 0.72, 0.83)
const COL_ROW := Color(0.08, 0.13, 0.23, 0.92)
const COL_ROW_DIM := Color(0.06, 0.09, 0.15, 0.72)
const COL_DIM_TEXT := Color(0.55, 0.60, 0.68)

var items: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 150
	visible = false


func open(items_data: Array) -> void:
	items = items_data.duplicate(true)
	visible = true
	queue_redraw()


func close() -> void:
	visible = false
	queue_redraw()


func set_items(items_data: Array) -> void:
	items = items_data.duplicate(true)
	queue_redraw()


func panel_rect() -> Rect2:
	var rows: int = maxi(items.size(), 1)
	return Rect2(
		PANEL_RIGHT - PANEL_WIDTH,
		PANEL_TOP,
		PANEL_WIDTH,
		HEADER_H + float(rows) * ROW_H + PAD
	)


func row_rect(index: int) -> Rect2:
	var panel := panel_rect()
	return Rect2(
		panel.position.x + 8.0,
		panel.position.y + HEADER_H + float(index) * ROW_H + 3.0,
		panel.size.x - 16.0,
		ROW_H - 6.0
	)


func row_at(pos: Vector2) -> int:
	for i in range(items.size()):
		if row_rect(i).has_point(pos):
			return i
	return -1


func close_rect() -> Rect2:
	var panel := panel_rect()
	return Rect2(panel.end.x - 34.0, panel.position.y + 6.0, 26.0, 26.0)


func contains(pos: Vector2) -> bool:
	return panel_rect().has_point(pos)


## ============================================
## 绘制
## ============================================

func _draw() -> void:
	if not visible:
		return
	var panel := panel_rect()
	_draw_style_box(Rect2(panel.position + Vector2(3.0, 4.0), panel.size), Color(0.0, 0.0, 0.0, 0.38), Color(0.0, 0.0, 0.0, 0.0), 0, 10)
	_draw_style_box(panel, COL_PANEL, COL_BORDER, 2, 9)
	_draw_left_text("道具", Vector2(panel.position.x + 16.0, panel.position.y + 23.0), COL_GOLD, 15.0, 120.0)
	var close_box := close_rect()
	_draw_style_box(close_box, Color(0.12, 0.18, 0.30, 0.95), Color(1.0, 0.82, 0.36, 0.25), 1, 6)
	_draw_center_text("×", close_box.get_center().x, close_box.position.y + 18.0, COL_TEXT, 14.0, 26.0)
	draw_rect(Rect2(panel.position.x + 12.0, panel.position.y + HEADER_H - 1.0, panel.size.x - 24.0, 1.0), Color(1.0, 0.82, 0.36, 0.22), true)
	if items.is_empty():
		_draw_center_text("暂无战斗道具", panel.get_center().x, panel.position.y + HEADER_H + 28.0, COL_MUTED, 11.0, 200.0)
		return
	for i in range(items.size()):
		_draw_row(i)


func _draw_row(index: int) -> void:
	var row := row_rect(index)
	var item: Dictionary = items[index]
	var count := int(item.get("count", 0))
	var usable := bool(item.get("usable", false)) and count > 0
	var alpha := 1.0 if usable else 0.42
	_draw_style_box(row, COL_ROW if usable else COL_ROW_DIM, Color(1.0, 0.82, 0.36, 0.30) if usable else Color(0.0, 0.0, 0.0, 0.0), 1 if usable else 0, 7)
	var icon_rect := Rect2(row.position.x + 9.0, row.position.y + 7.0, 34.0, 34.0)
	var icon: Variant = item.get("icon", null)
	if not icon is Texture2D:
		icon = _load_texture(str(item.get("icon_path", "")))
	if icon != null:
		_draw_texture_contain(icon, icon_rect, alpha)
	else:
		_draw_center_text(str(item.get("emoji", "?")), icon_rect.get_center().x, icon_rect.position.y + 24.0, Color(1.0, 1.0, 1.0, alpha), 18.0, 34.0)
	_draw_left_text(str(item.get("name", "")), Vector2(row.position.x + 50.0, row.position.y + 22.0), Color(1.0, 1.0, 1.0, alpha), 14.0, row.size.x - 120.0)
	var ratio := float(item.get("ratio", 0.0))
	var subtitle := "恢复 %d%% 最大生命" % int(round(ratio * 100.0)) if ratio > 0.0 else str(item.get("desc", ""))
	_draw_left_text(subtitle, Vector2(row.position.x + 50.0, row.position.y + 39.0), Color(COL_MUTED.r, COL_MUTED.g, COL_MUTED.b, alpha), 9.0, row.size.x - 120.0)
	var count_color := COL_GOLD if usable else Color(COL_DIM_TEXT.r, COL_DIM_TEXT.g, COL_DIM_TEXT.b, 0.75)
	_draw_right_text("x%d" % count, row.end.x - 10.0, row.position.y + 30.0, count_color, 13.0)
	if count <= 0:
		_draw_right_text("已用完", row.end.x - 10.0, row.position.y + 44.0, Color(COL_DIM_TEXT.r, COL_DIM_TEXT.g, COL_DIM_TEXT.b, 0.65), 8.0)


## ============================================
## 绘制辅助
## ============================================

func _draw_style_box(rect: Rect2, bg: Color, border: Color, border_width: int, radius: float) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)


func _draw_left_text(text: String, pos: Vector2, color: Color, font_size: float, width: float) -> void:
	var font := ThemeDB.fallback_font
	var size_i := int(font_size)
	var fitted := BattleUIFeedback.fit_text(font, text, width, font_size)
	draw_string(font, Vector2(pos.x + 1.0, pos.y + 2.0), fitted, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, Color(0.03, 0.05, 0.10, 0.75))
	draw_string(font, pos, fitted, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, color)


func _draw_center_text(text: String, x: float, y: float, color: Color, font_size: float, width: float) -> void:
	var font := ThemeDB.fallback_font
	var size_i := int(font_size)
	var left := x - width / 2.0
	draw_string(font, Vector2(left + 1.0, y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, Color(0.03, 0.05, 0.10, 0.75))
	draw_string(font, Vector2(left, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, color)


func _draw_right_text(text: String, right_x: float, y: float, color: Color, font_size: float) -> void:
	var font := ThemeDB.fallback_font
	var size_i := int(font_size)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var left := right_x - width
	draw_string(font, Vector2(left + 1.0, y + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_i, Color(0.03, 0.05, 0.10, 0.75))
	draw_string(font, Vector2(left, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_i, color)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded = load(path)
	return loaded if loaded is Texture2D else null


func _draw_texture_contain(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var draw_size := size * scale
	var draw_pos := rect.position + (rect.size - draw_size) * 0.5
	draw_texture_rect(tex, Rect2(draw_pos, draw_size), false, Color(1.0, 1.0, 1.0, opacity))

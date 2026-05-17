# ============================================
# scene_inventory.gd - 背包场景
# 翻译来源: js/ui/sceneInventory.js
# 重构版本: _draw() 绘制 + _gui_input 交互
# ============================================

class_name SceneInventory
extends Control

const ItemDB = preload("res://src/data/item_db.gd")

signal back_pressed()

# 布局常量
const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0
const COLS := 3
const CELL_SIZE := 100
const CELL_GAP := 10

# 内部状态
var _inventory: Dictionary = {}
var _player: Dictionary = {}
var _item_list: Array = []
var _selected_item: Dictionary = {}
var _popup: Dictionary = {}
var _toast_text: String = ""
var _toast_timer: float = 0.0
var _scroll_offset: float = 0.0
var _storage: Node = null
var _grid_start_x: float = 0.0
var _grid_top: float = 0.0
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
	_storage = get_node_or_null("/root/SaveManager")
	var grid_w := COLS * CELL_SIZE + (COLS - 1) * CELL_GAP
	_grid_start_x = (DESIGN_WIDTH - grid_w) / 2.0
	_grid_top = 160.0 + 45.0  # gridY + 标题行高
	mouse_filter = Control.MOUSE_FILTER_STOP

func init(_data: Dictionary = {}) -> void:
	print("[SceneInventory] 背包初始化")
	_storage = get_node_or_null("/root/SaveManager")
	_inventory = _storage.load_inventory() if _storage else {}
	_player = _storage.load_player() if _storage else {}
	_selected_item = {}
	_popup = {}
	_toast_text = ""
	_toast_timer = 0.0
	_scroll_offset = 0.0
	_build_item_list()

func _build_item_list() -> void:
	_item_list.clear()
	for item_id in _inventory:
		var count: int = _inventory[item_id]
		if count > 0 and ItemDB.has_item(item_id):
			var item_data: Dictionary = ItemDB.get_item(item_id)
			_item_list.append({"id": item_id, "count": count, "data": item_data})

# ============ 输入 ============
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)
		elif event is InputEventMouseButton:
			pass  # mouse up
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag_y: float = event.relative.y
		if abs(drag_y) > 10:
			var step: float = CELL_SIZE + CELL_GAP
			var max_offset := _get_max_scroll_offset()
			if drag_y < 0:
				_scroll_offset = min(max_offset, _scroll_offset + step)
			else:
				_scroll_offset = max(0.0, _scroll_offset - step)
			queue_redraw()
		accept_event()

func _on_tap(x: float, y: float) -> void:
	# 弹窗打开时
	if not _popup.is_empty():
		var px: float = _popup.get("x", 0.0)
		var py: float = _popup.get("y", 0.0)
		var pw: float = _popup.get("w", 0.0)
		var ph: float = _popup.get("h", 0.0)
		# 点击弹窗外关闭
		if not (x >= px and x <= px + pw and y >= py and y <= py + ph):
			_popup = {}
			queue_redraw()
			return
		# 使用按钮
		var bx: float = px + (pw - 120.0) / 2.0
		var by: float = py + ph - 60.0
		if x >= bx and x <= bx + 120.0 and y >= by and y <= by + 40.0:
			var item_id: String = _popup.get("id", "")
			_use_item(item_id)
			_popup = {}
			queue_redraw()
			return
		return
	
	# 返回按钮 (10, 12, 60, 36)
	if x >= 10 and x <= 70 and y >= 12 and y <= 48:
		back_pressed.emit()
		return
	
	# 道具格子点击
	var idx: int = _get_item_index_at(x, y)
	if idx != -1 and idx < _item_list.size():
		_selected_item = _item_list[idx]
		_show_item_popup(_selected_item)
		queue_redraw()

func _get_item_index_at(x: float, y: float) -> int:
	var rel_x: float = x - _grid_start_x
	var rel_y: float = y - _grid_top + _scroll_offset
	if y < _grid_top or y > DESIGN_HEIGHT - 24.0:
		return -1
	if rel_x < 0.0 or rel_y < 0.0:
		return -1
	var col: int = int(rel_x / (CELL_SIZE + CELL_GAP))
	var row: int = int(rel_y / (CELL_SIZE + CELL_GAP))
	if col >= COLS:
		return -1
	return row * COLS + col

func _get_max_scroll_offset() -> float:
	var rows: int = ceili(float(_item_list.size()) / float(COLS))
	var content_h: float = rows * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var view_h: float = DESIGN_HEIGHT - 24.0 - _grid_top
	return maxf(0.0, content_h - view_h)

func _show_item_popup(item: Dictionary) -> void:
	var pw := 280.0
	var ph := 220.0
	_popup = {
		"x": (DESIGN_WIDTH - pw) / 2.0,
		"y": (DESIGN_HEIGHT - ph) / 2.0,
		"w": pw, "h": ph,
		"id": item.get("id", ""),
		"data": item.get("data", {}),
		"count": item.get("count", 0)
	}

func _use_item(item_id: String) -> void:
	if item_id.is_empty() or not _storage:
		return
	var item_data: Dictionary = ItemDB.get_item(item_id)
	if item_data.is_empty():
		return
	var item_type: String = item_data.get("type", "")
	var effect: Dictionary = item_data.get("effect", {})
	
	match item_type:
		"exp":
			var exp_gain: int = effect.get("expGain", 0)
			if exp_gain > 0:
				if _storage.use_item(item_id, 1):
					_storage.add_player_exp(exp_gain)
					_player = _storage.load_player()
					_show_toast("获得 %d 经验" % exp_gain)
				else:
					_show_toast("道具数量不足")
		"gold":
			var gold_gain: int = effect.get("goldGain", 0)
			if gold_gain > 0:
				if _storage.use_item(item_id, 1):
					_storage.add_gold(gold_gain)
					_player = _storage.load_player()
					_show_toast("获得 %d 金币" % gold_gain)
				else:
					_show_toast("道具数量不足")
		"capture":
			_show_toast("捕获球会在胜利结算时自动使用")
		"battle":
			_show_toast("战斗道具请在战斗中使用")
		"evolution":
			_show_toast("进化石请在怪物进化中使用")
		_:
			_show_toast("该道具暂时无法使用")
	
	# 刷新列表
	_inventory = _storage.load_inventory() if _storage else {}
	_build_item_list()
	_scroll_offset = min(_scroll_offset, _get_max_scroll_offset())
	queue_redraw()

func _show_toast(text: String) -> void:
	_toast_text = text
	_toast_timer = 1.8

# ============ 帧更新 ============
func _process(dt: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= dt
		if _toast_timer <= 0.0:
			_toast_text = ""
	queue_redraw()

# ============ 绘制 ============
func _draw() -> void:
	var font := ThemeDB.fallback_font
	
	# 背景
	draw_rect(Rect2(0, 0, DESIGN_WIDTH, DESIGN_HEIGHT), Color(0.06, 0.08, 0.16))
	
	# 顶栏
	draw_rect(Rect2(0, 0, DESIGN_WIDTH, 60), Color(0.10, 0.12, 0.20))
	
	# 返回按钮
	draw_rect(Rect2(10, 12, 60, 36), Color(0.18, 0.20, 0.30))
	draw_rect(Rect2(10, 12, 60, 36), Color(0.30, 0.35, 0.50), false)
	draw_string(font, Vector2(20, 36), "← 返回", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9))
	
	# 标题
	draw_string(font, Vector2(DESIGN_WIDTH / 2, 40), "背包", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color.WHITE)
	
	# 货币
	var gold: int = _player.get("gold", 0)
	var gems: int = _player.get("gems", 0)
	draw_string(font, Vector2(30, 130), "💰 %d" % gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.84, 0.0))
	draw_string(font, Vector2(DESIGN_WIDTH - 80, 130), "💎 %d" % gems, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.4, 0.6, 1.0))
	
	# 分割线
	draw_line(Vector2(10, 150), Vector2(DESIGN_WIDTH - 10, 150), Color(0.3, 0.3, 0.4), 1.0)
	
	# 道具标签
	draw_string(font, Vector2(20, 185), "道具", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.6))
	draw_string(font, Vector2(DESIGN_WIDTH - 80, 185), "共 %d 件" % _item_list.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.3, 0.4))
	
	var grid_bottom: float = DESIGN_HEIGHT - 24.0
	
	if _item_list.is_empty():
		draw_string(font, Vector2(DESIGN_WIDTH / 2 - 100, _grid_top + 80), "还没有道具，赶快去战斗获取吧！", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.4, 0.5))
		draw_string(font, Vector2(DESIGN_WIDTH / 2 - 15, _grid_top + 120), "💪", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
	else:
		for idx in range(_item_list.size()):
			var row: int = idx / COLS
			var col: int = idx % COLS
			var gx: float = _grid_start_x + col * (CELL_SIZE + CELL_GAP)
			var gy: float = _grid_top + row * (CELL_SIZE + CELL_GAP) - _scroll_offset
			
			if gy + CELL_SIZE < _grid_top or gy > grid_bottom:
				continue
			
			var cell_color := Color(0.10, 0.12, 0.20)
			draw_rect(Rect2(gx, gy, CELL_SIZE, CELL_SIZE), cell_color)
			draw_rect(Rect2(gx, gy, CELL_SIZE, CELL_SIZE), Color(0.22, 0.25, 0.35), false)
			
			var item: Dictionary = _item_list[idx]
			var item_data: Dictionary = item.get("data", {})
			
			# emoji
			draw_string(font, Vector2(gx + CELL_SIZE / 2 - 12, gy + 42), item_data.get("emoji", "🎁"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
			# 名称
			draw_string(font, Vector2(gx + CELL_SIZE / 2 - 20, gy + 66), item_data.get("name", "?"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.85, 0.9))
			# 数量
			draw_string(font, Vector2(gx + CELL_SIZE / 2 - 15, gy + 85), "×%d" % item.get("count", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.84, 0.0))
		
		# 滚动条
		var max_off := _get_max_scroll_offset()
		if max_off > 0:
			var track_h := grid_bottom - _grid_top
			var thumb_h := maxf(34.0, track_h * (track_h / (track_h + max_off)))
			var thumb_y := _grid_top + (track_h - thumb_h) * (_scroll_offset / max_off)
			draw_rect(Rect2(368, _grid_top, 3, track_h), Color(1, 1, 1, 0.12))
			draw_rect(Rect2(367, thumb_y, 5, thumb_h), Color(1, 1, 1, 0.45))
	
	# 弹窗
	if not _popup.is_empty():
		var px: float = _popup.get("x", 0.0)
		var py: float = _popup.get("y", 0.0)
		var pw: float = _popup.get("w", 0.0)
		var ph: float = _popup.get("h", 0.0)
		
		draw_rect(Rect2(0, 0, DESIGN_WIDTH, DESIGN_HEIGHT), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(px, py, pw, ph), Color(0.14, 0.16, 0.26))
		draw_rect(Rect2(px, py, pw, ph), Color(0.30, 0.35, 0.50), false)
		draw_rect(Rect2(px + 20, py + 10, pw - 40, 3), Color(0.35, 0.55, 1.0))
		
		var popup_data: Dictionary = _popup.get("data", {})
		var popup_count: int = _popup.get("count", 0)
		
		draw_string(font, Vector2(px + pw / 2 - 16, py + 55), popup_data.get("emoji", "🎁"), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color.WHITE)
		draw_string(font, Vector2(px + pw / 2 - 30, py + 95), popup_data.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		draw_string(font, Vector2(px + pw / 2 - 50, py + 120), popup_data.get("desc", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.7))
		draw_string(font, Vector2(px + pw / 2 - 25, py + 145), "拥有: ×%d" % popup_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.84, 0.0))
		
		var btn_x: float = px + (pw - 120.0) / 2.0
		var btn_y: float = py + ph - 60.0
		draw_rect(Rect2(btn_x, btn_y, 120, 40), Color(0.35, 0.55, 1.0))
		draw_string(font, Vector2(btn_x + 35, btn_y + 27), "使 用", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	# Toast
	if _toast_text != "" and _toast_timer > 0.0:
		var alpha: float = minf(_toast_timer / 0.5, 1.0)
		draw_rect(Rect2(55, 585, 265, 42), Color(0, 0, 0, 0.72 * alpha))
		draw_string(font, Vector2(DESIGN_WIDTH / 2, 610), _toast_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1, 1, 1, alpha))

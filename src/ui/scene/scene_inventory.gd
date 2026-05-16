# ============================================
# scene_inventory.gd - 背包场景
# 翻译来源: js/ui/sceneInventory.js
# ============================================
# 使用说明：
# - 继承 Control，作为场景根节点
# - 通过 SaveManager 读写存档
# - 道具数据来自 ItemDB
# ============================================

class_name SceneInventory
extends Control

const ItemDB = preload("res://src/data/item_db.gd")

# 信号
signal back_pressed()

# 道具数据引用
const ITEMS_DB_KEY = "items_db"

# 布局常量
const COLS := 3
const CELL_SIZE := 100
const CELL_GAP := 10

# UI 区域坐标
const BACK_BTN := Rect2(10, 10, 60, 36)
const TITLE_Y := 60
const CURRENCY_Y := 110
const GRID_Y := 160

# 内部状态
var _game: Node = null
var _inventory: Dictionary = {}
var _player: Dictionary = {}
var _item_list: Array = []
var _selected_item: Dictionary = {}
var _popup: Dictionary = {}
var _toast_text: String = ""
var _toast_timer: float = 0.0
var _scroll_offset: float = 0.0
var _storage: Node = null

# UI 节点引用（Build 时赋值）
var _back_btn_rect: Rect2
var _grid_start_x: float = 0.0
var _grid_top: float = 0.0

# 设计分辨率（参考值）
const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0

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
	# 从游戏管理器获取引用
	_game = get_node_or_null("/root/Game")
	_storage = get_node_or_null("/root/SaveManager")
	
	# 计算网格起始 X 坐标（居中）
	var grid_w := COLS * CELL_SIZE + (COLS - 1) * CELL_GAP
	_grid_start_x = (DESIGN_WIDTH - grid_w) / 2.0
	_grid_top = GRID_Y + 45.0

# 初始化入口（由 SceneManager 调用）
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
	_update_layout()

# 构建道具列表
func _build_item_list() -> void:
	_item_list.clear()
	for item_id in _inventory:
		var count: int = _inventory[item_id]
		if count > 0 and ItemDB.has_item(item_id):
			var item_data: Dictionary = ItemDB.get_item(item_id)
			_item_list.append({
				"id": item_id,
				"count": count,
				"data": item_data
			})

# 更新布局计算
func _update_layout() -> void:
	_back_btn_rect = Rect2(10.0, 10.0, 60.0, 36.0)

# 输入处理
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			_on_tap(pos.x, pos.y)
	elif event is InputEventScreenDrag:
		var pos: Vector2 = event.position
		var direction: String = ""
		var drag_vec: Vector2 = event.relative
		if abs(drag_vec.y) > abs(drag_vec.x):
			if drag_vec.y < -10:
				direction = "up"
			elif drag_vec.y > 10:
				direction = "down"
		if direction:
			_on_swipe(pos.x, pos.y, direction)

# 点击处理
func _on_tap(x: float, y: float) -> void:
	# 关闭弹窗
	if not _popup.is_empty():
		var px: float = _popup.get("x", 0.0)
		var py: float = _popup.get("y", 0.0)
		var pw: float = _popup.get("w", 0.0)
		var ph: float = _popup.get("h", 0.0)
		
		# 遮罩点击关闭
		if not (x >= px and x <= px + pw and y >= py and y <= py + ph):
			_popup = {}
			return
		
		# 按钮区域
		var bx: float = px + (pw - 120.0) / 2.0
		var by: float = py + ph - 60.0
		if x >= bx and x <= bx + 120.0 and y >= by and y <= by + 40.0:
			var item_id: String = _popup.get("id", "")
			_use_item(item_id)
			_popup = {}
			return
		return
	
	# 返回按钮
	if _in_rect(x, y, _back_btn_rect):
		back_pressed.emit()
		return
	
	# 道具格子点击
	var idx: int = _get_item_index_at(x, y)
	if idx != -1 and idx < _item_list.size():
		_selected_item = _item_list[idx]
		_show_item_popup(_selected_item)

# 判断点是否在矩形内
func _in_rect(x: float, y: float, rect: Rect2) -> bool:
	return x >= rect.position.x and x <= rect.position.x + rect.size.x and y >= rect.position.y and y <= rect.position.y + rect.size.y

# 获取点击的道具索引
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
	
	var idx: int = row * COLS + col
	return idx

# 滑动处理
func _on_swipe(_x: float, _y: float, direction: String) -> void:
	if not _popup.is_empty():
		return
	if _y < _grid_top + 45.0:
		return
	
	var step: float = CELL_SIZE + CELL_GAP
	var max_offset: float = _get_max_scroll_offset()
	
	if direction == "up":
		_scroll_offset = min(max_offset, _scroll_offset + step)
	elif direction == "down":
		_scroll_offset = max(0.0, _scroll_offset - step)

# 获取最大滚动偏移
func _get_max_scroll_offset() -> float:
	var rows: int = ceili(float(_item_list.size()) / float(COLS))
	var content_h: float = rows * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var view_h: float = DESIGN_HEIGHT - 24.0 - _grid_top
	return maxf(0.0, content_h - view_h)

# 显示道具弹窗
func _show_item_popup(item: Dictionary) -> void:
	var pw: float = 280.0
	var ph: float = 220.0
	var px: float = (DESIGN_WIDTH - pw) / 2.0
	var py: float = (DESIGN_HEIGHT - ph) / 2.0
	
	_popup = {
		"x": px, "y": py, "w": pw, "h": ph,
		"id": item.get("id", ""),
		"data": item.get("data", {}),
		"count": item.get("count", 0)
	}

# 使用道具
func _use_item(item_id: String) -> void:
	if item_id.is_empty():
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
				if _storage and _storage.use_item(item_id, 1):
					_storage.add_player_exp(exp_gain)
					_player = _storage.load_player()
					_show_toast("获得 %d 经验" % exp_gain)
				else:
					_show_toast("道具数量不足")
		"gold":
			var gold_gain: int = effect.get("goldGain", 0)
			if gold_gain > 0:
				if _storage and _storage.use_item(item_id, 1):
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

# 显示 Toast 提示
func _show_toast(text: String) -> void:
	_toast_text = text
	_toast_timer = 1.8

# 帧更新
func _process(dt: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= dt
		if _toast_timer <= 0.0:
			_toast_text = ""

# 主渲染函数（从 draw_tree 调用）
# 注意：Godot 4.x 使用 _draw() 配合 CustomCanvasItem 或直接控制子节点
# 此处通过子节点方式来构建 UI（推荐模式）
func setup_ui() -> void:
	# UI 节点已在 _ready 中准备好
	# 如需动态创建请重写此方法
	pass

# 获取道具图标（用于 Grid 单元格）
static func get_item_emoji(item_data: Dictionary) -> String:
	return item_data.get("emoji", "🎁")

# 获取道具名称
static func get_item_name(item_data: Dictionary) -> String:
	return item_data.get("name", "未知道具")

# 清理资源
func destroy() -> void:
	_toast_text = ""
	_item_list.clear()
	_popup = {}
	_selected_item = {}

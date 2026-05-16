# scene_album.gd - 怪物图鉴场景（纯代码重构版）
# 来源: js/ui/sceneAlbum.js
# 重构: 删除所有 @onready，在 _create_ui() 中动态创建所有节点
class_name SceneAlbum
extends Control

# ============================================
# 常量
# ============================================
const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0
const COLS: int = 3
const ITEM_W: float = 100.0
const ITEM_H: float = 110.0
const GAP: float = 15.0
const MARGIN: float = 15.0
const HEADER_H: float = 98.0

# ============================================
# 节点引用（成员变量，非 @onready）
# ============================================
var _back_btn: Button
var _title_label: Label
var _stat_label: Label
var _filter_scroll: ScrollContainer
var _filter_container: HBoxContainer
var _monster_grid: GridContainer
var _detail_panel: PanelContainer

# detail_panel 内部节点
var _detail_vbox: VBoxContainer
var _card_panel: PanelContainer
var _emoji_label: Label
var _name_label: Label
var _stars_label: Label
var _element_panel: PanelContainer
var _element_label: Label
var _hp_label: Label
var _atk_label: Label
var _def_label: Label
var _spd_label: Label
var _skill_name_label: Label
var _skill_desc_label: Label
var _status_label: Label
var _evolve_btn: Button
var _close_btn: Button

# ============================================
# 成员变量
# ============================================
var _game: Node = null
var _storage = null

# 状态机
var _state: String = "list"  # list | detail

# 怪物数据
var _all_monsters: Array = []
var _filtered_monsters: Array = []
var _selected_monster: Dictionary = {}

# 布局计算
var _total_w: float = COLS * ITEM_W + (COLS - 1) * GAP
var _start_x: float = (DESIGN_W - _total_w) / 2.0

# 属性筛选
var _elements: Array = ["fire", "water", "grass", "thunder", "light", "earth", "wind", "dark"]
var _element_names: Dictionary = {
	"fire": "火", "water": "水", "grass": "草", "thunder": "雷",
	"light": "光", "earth": "土", "wind": "风", "dark": "暗"
}
var _all_elements: Array = ["all", "fire", "water", "grass", "thunder", "light", "earth", "wind", "dark"]
var _selected_element: String = "all"

# 滚动
var _scroll_y: float = 0.0
var _max_scroll_y: float = 0.0
var _is_dragging: bool = false
var _last_mouse_y: float = 0.0
var _drag_start_y: float = 0.0

# ============================================
# 生命周期
# ============================================

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
	name = "SceneAlbum"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_ui()
	_init_data()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pos: Vector2
		var pressed: bool
		if event is InputEventScreenTouch:
			pos = event.position
			pressed = event.pressed
		else:
			pos = event.position
			pressed = event.pressed

		if pressed:
			_last_mouse_y = pos.y
			_drag_start_y = pos.y
			_handle_tap(pos.x, pos.y)
		else:
			_is_dragging = false
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and _is_dragging):
		var current_y: float
		if event is InputEventScreenDrag:
			current_y = event.position.y
		else:
			current_y = event.position.y

		if abs(current_y - _drag_start_y) > 10 or _is_dragging:
			_is_dragging = true
			var delta_y: float = _last_mouse_y - current_y
			if abs(delta_y) > 5:
				var direction: int = 1 if delta_y > 0 else -1
				_scroll_by_direction(direction)
				_last_mouse_y = current_y

# ============================================
# UI 创建
# ============================================

func _create_ui() -> void:
	# ---- 返回按钮 ----
	_back_btn = Button.new()
	_back_btn.name = "BackBtn"
	_back_btn.text = "← 返回"
	_back_btn.anchor_left = 0.0
	_back_btn.anchor_top = 0.0
	_back_btn.anchor_right = 0.0
	_back_btn.anchor_bottom = 0.0
	_back_btn.offset_left = 15.0
	_back_btn.offset_top = 15.0
	_back_btn.offset_right = 85.0
	_back_btn.offset_bottom = 50.0
	_back_btn.add_theme_font_size_override("font_size", 14)
	_back_btn.pressed.connect(_on_back_pressed)
	add_child(_back_btn)

	# ---- 标题标签 ----
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "📖 怪物图鉴"
	_title_label.anchor_left = 0.5
	_title_label.anchor_right = 0.5
	_title_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title_label.anchor_top = 0.0
	_title_label.anchor_bottom = 0.0
	_title_label.offset_top = 18.0
	_title_label.offset_bottom = 48.0
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_title_label)

	# ---- 统计标签 ----
	_stat_label = Label.new()
	_stat_label.name = "StatLabel"
	_stat_label.text = "已收集: 0/0"
	_stat_label.anchor_left = 0.0
	_stat_label.anchor_right = 1.0
	_stat_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_stat_label.anchor_top = 0.0
	_stat_label.anchor_bottom = 0.0
	_stat_label.offset_top = 50.0
	_stat_label.offset_bottom = 68.0
	_stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stat_label.add_theme_font_size_override("font_size", 12)
	_stat_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(_stat_label)

	# ---- 属性筛选滚动容器 ----
	_filter_scroll = ScrollContainer.new()
	_filter_scroll.name = "FilterScroll"
	_filter_scroll.anchor_left = 0.0
	_filter_scroll.anchor_top = 0.0
	_filter_scroll.anchor_right = 1.0
	_filter_scroll.anchor_bottom = 0.0
	_filter_scroll.offset_top = 65.0
	_filter_scroll.offset_bottom = 95.0
	_filter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_filter_scroll)

	# ---- 属性筛选容器 ----
	_filter_container = HBoxContainer.new()
	_filter_container.name = "FilterContainer"
	_filter_container.anchor_left = 0.0
	_filter_container.anchor_right = 0.0
	_filter_container.anchor_top = 0.0
	_filter_container.anchor_bottom = 0.0
	_filter_scroll.add_child(_filter_container)

	# 动态创建 9 个属性筛选按钮
	for el: String in _all_elements:
		var btn: Button = Button.new()
		btn.name = "FilterBtn_" + el
		btn.text = "全部" if el == "all" else _element_names.get(el, el)
		btn.custom_minimum_size = Vector2(34.0, 26.0)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_filter_pressed.bind(el))
		_filter_container.add_child(btn)

	# ---- 怪物网格 ----
	_monster_grid = GridContainer.new()
	_monster_grid.name = "MonsterGrid"
	_monster_grid.columns = COLS
	_monster_grid.anchor_left = 0.0
	_monster_grid.anchor_right = 1.0
	_monster_grid.anchor_top = 0.0
	_monster_grid.anchor_bottom = 1.0
	_monster_grid.offset_top = HEADER_H
	_monster_grid.position.x = _start_x
	add_child(_monster_grid)

	# ---- 详情面板 ----
	_detail_panel = PanelContainer.new()
	_detail_panel.name = "DetailPanel"
	_detail_panel.anchor_left = 0.0
	_detail_panel.anchor_right = 1.0
	_detail_panel.anchor_top = 0.0
	_detail_panel.anchor_bottom = 1.0
	_detail_panel.visible = false

	var detail_style: StyleBoxFlat = StyleBoxFlat.new()
	detail_style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	detail_style.set_corner_radius_all(12.0)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	add_child(_detail_panel)

	# ---- 详情面板内部 VBox ----
	_detail_vbox = VBoxContainer.new()
	_detail_vbox.name = "DetailVBox"
	_detail_vbox.anchor_left = 0.0
	_detail_vbox.anchor_right = 1.0
	_detail_vbox.anchor_top = 0.0
	_detail_vbox.anchor_bottom = 1.0
	_detail_vbox.add_theme_constant_override("separation", 10)
	_detail_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_detail_panel.add_child(_detail_vbox)

	# ---- 怪物卡片区 ----
	_card_panel = PanelContainer.new()
	_card_panel.name = "CardPanel"
	_card_panel.custom_minimum_size = Vector2(160.0, 180.0)
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.15)
	card_style.set_corner_radius_all(10.0)
	_card_panel.add_theme_stylebox_override("panel", card_style)
	_detail_vbox.add_child(_card_panel)

	var card_vbox: VBoxContainer = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_panel.add_child(card_vbox)

	_emoji_label = Label.new()
	_emoji_label.name = "EmojiLabel"
	_emoji_label.text = "❓"
	_emoji_label.add_theme_font_size_override("font_size", 48)
	_emoji_label.add_theme_color_override("font_color", Color.WHITE)
	card_vbox.add_child(_emoji_label)

	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.text = "???"
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	card_vbox.add_child(_name_label)

	_stars_label = Label.new()
	_stars_label.name = "StarsLabel"
	_stars_label.text = "★"
	_stars_label.add_theme_font_size_override("font_size", 16)
	_stars_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	card_vbox.add_child(_stars_label)

	# ---- 属性标签 ----
	var elem_hbox: HBoxContainer = HBoxContainer.new()
	elem_hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
	_detail_vbox.add_child(elem_hbox)

	_element_panel = PanelContainer.new()
	_element_panel.name = "ElementPanel"
	var elem_tag_style: StyleBoxFlat = StyleBoxFlat.new()
	elem_tag_style.set_corner_radius_all(4.0)
	_element_panel.add_theme_stylebox_override("panel", elem_tag_style)
	elem_hbox.add_child(_element_panel)

	_element_label = Label.new()
	_element_label.name = "ElementLabel"
	_element_label.text = "火"
	_element_label.add_theme_font_size_override("font_size", 12)
	_element_label.add_theme_color_override("font_color", Color.WHITE)
	_element_panel.add_child(_element_label)

	# ---- 属性面板 (HP/ATK/DEF/SPD) ----
	var stats_hbox: HBoxContainer = HBoxContainer.new()
	stats_hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
	_detail_vbox.add_child(stats_hbox)

	var stat_items: Array = [["HP", "HPLabel"], ["ATK", "ATKLabel"], ["DEF", "DEFLabel"], ["SPD", "SPDLabel"]]
	for item: Array in stat_items:
		var col: VBoxContainer = VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		stats_hbox.add_child(col)

		var lbl_name: Label = Label.new()
		lbl_name.text = item[0]
		lbl_name.add_theme_font_size_override("font_size", 10)
		lbl_name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lbl_name)

		var lbl_val: Label = Label.new()
		lbl_val.name = item[1]
		lbl_val.text = "0"
		lbl_val.add_theme_font_size_override("font_size", 16)
		lbl_val.add_theme_color_override("font_color", Color.WHITE)
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lbl_val)

		if item[0] == "HP":
			_hp_label = lbl_val
		elif item[0] == "ATK":
			_atk_label = lbl_val
		elif item[0] == "DEF":
			_def_label = lbl_val
		elif item[0] == "SPD":
			_spd_label = lbl_val

	# ---- 技能面板 ----
	var skill_vbox: VBoxContainer = VBoxContainer.new()
	skill_vbox.add_theme_constant_override("separation", 4)
	skill_vbox.custom_minimum_size = Vector2(280.0, 0.0)
	_detail_vbox.add_child(skill_vbox)

	var skill_title: Label = Label.new()
	skill_title.text = "技能"
	skill_title.add_theme_font_size_override("font_size", 12)
	skill_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	skill_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_vbox.add_child(skill_title)

	_skill_name_label = Label.new()
	_skill_name_label.name = "SkillNameLabel"
	_skill_name_label.text = "未知技能"
	_skill_name_label.add_theme_font_size_override("font_size", 14)
	_skill_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_skill_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_vbox.add_child(_skill_name_label)

	_skill_desc_label = Label.new()
	_skill_desc_label.name = "SkillDescLabel"
	_skill_desc_label.text = "消耗: 0 能量 | 倍率: 1.0x"
	_skill_desc_label.add_theme_font_size_override("font_size", 11)
	_skill_desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_skill_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_vbox.add_child(_skill_desc_label)

	# ---- 状态标签 ----
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "❓ 未收服"
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_vbox.add_child(_status_label)

	# ---- 进化按钮 ----
	_evolve_btn = Button.new()
	_evolve_btn.name = "EvolveBtn"
	_evolve_btn.text = "🔀 进化"
	_evolve_btn.custom_minimum_size = Vector2(180.0, 40.0)
	_evolve_btn.add_theme_font_size_override("font_size", 16)
	_evolve_btn.visible = false
	_evolve_btn.pressed.connect(_on_evolve_pressed)
	_detail_vbox.add_child(_evolve_btn)

	# ---- 关闭按钮 ----
	_close_btn = Button.new()
	_close_btn.name = "CloseBtn"
	_close_btn.text = "✕ 关闭"
	_close_btn.custom_minimum_size = Vector2(180.0, 40.0)
	_close_btn.add_theme_font_size_override("font_size", 16)
	_close_btn.pressed.connect(_on_close_pressed)
	_detail_vbox.add_child(_close_btn)

# ============================================
# 数据初始化
# ============================================

func _init_data() -> void:
	_build_monster_list()
	_update_ui()
	_detail_panel.visible = false

# ============================================
# 怪物列表构建
# ============================================

func init(_data: Dictionary = {}) -> void:
	_game = get_node_or_null("/root/GameManager")
	_storage = get_node_or_null("/root/SaveManager")

	_state = "list"
	_selected_monster = {}
	_selected_element = "all"
	_scroll_y = 0.0

	_init_data()

func _build_monster_list() -> void:
	_all_monsters = []

	# 从 MONSTER_DB 加载（通过 game.monster_db）
	if _game and _game.has("monster_db"):
		var db = _game.monster_db
		if db.has_method("get_all"):
			_all_monsters = db.get_all()

	_apply_element_filter()

func _apply_element_filter() -> void:
	_filtered_monsters = []

	if _selected_element == "all":
		for el: String in _elements:
			for m: Dictionary in _all_monsters:
				if m.get("element", "") == el:
					_filtered_monsters.append(m)
	else:
		for m: Dictionary in _all_monsters:
			if m.get("element", "") == _selected_element:
				_filtered_monsters.append(m)

	# 计算最大滚动
	var total_rows: int = ceili(float(_filtered_monsters.size()) / COLS)
	var content_h: float = total_rows * (ITEM_H + GAP)
	_max_scroll_y = maxf(0.0, content_h - (DESIGN_H - HEADER_H))

	_rebuild_grid()

func _rebuild_grid() -> void:
	# 清除旧卡片
	for child: Node in _monster_grid.get_children():
		child.queue_free()

	# 构建新卡片
	for m: Dictionary in _filtered_monsters:
		var card: Control = _create_monster_card(m)
		_monster_grid.add_child(card)

func _create_monster_card(monster: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(ITEM_W, ITEM_H)

	var elem: String = monster.get("element", "fire")
	var elem_color: Color = _get_element_color(elem)
	var player: Dictionary = _storage.load_player() if _storage and _storage.has_method("load_player") else {}
	var captured: Array = player.get("captured", [])
	var is_unlocked: bool = captured.has(monster.get("id", ""))

	# 背景样式
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = elem_color * 0.27 if is_unlocked else Color(0.2, 0.2, 0.2)
	style.border_color = elem_color if is_unlocked else Color(0.3, 0.3, 0.3)
	style.border_width_left = 2.0
	style.border_width_right = 2.0
	style.border_width_top = 2.0
	style.border_width_bottom = 2.0
	style.set_corner_radius_all(6.0)
	card.add_theme_stylebox_override("panel", style)

	# 内部布局
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# 属性标签
	var tag_hbox: HBoxContainer = HBoxContainer.new()
	tag_hbox.alignment = HBoxContainer.ALIGNMENT_CENTER

	var tag_lbl: Label = Label.new()
	tag_lbl.text = _element_names.get(elem, elem)
	tag_lbl.add_theme_font_size_override("font_size", 10)
	var tag_style: StyleBoxFlat = StyleBoxFlat.new()
	tag_style.bg_color = elem_color
	tag_style.set_corner_radius_all(4.0)
	var tag_panel: PanelContainer = PanelContainer.new()
	tag_panel.add_theme_stylebox_override("panel", tag_style)
	tag_hbox.add_child(tag_panel)
	tag_panel.add_child(tag_lbl)
	vbox.add_child(tag_hbox)

	# Emoji / 锁定图标
	var icon_lbl: Label = Label.new()
	if is_unlocked:
		icon_lbl.text = monster.get("emoji", "❓")
	else:
		icon_lbl.text = "🔒"
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.5, 0.5, 0.5))
	vbox.add_child(icon_lbl)

	# 名称
	var name_lbl: Label = Label.new()
	if is_unlocked:
		name_lbl.text = monster.get("name", "???")
	else:
		name_lbl.text = "???"
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.3, 0.3, 0.3))
	vbox.add_child(name_lbl)

	# 稀有度星星
	var rarity: int = monster.get("rarity", 1)
	var stars: String = "★".repeat(rarity)
	var stars_lbl: Label = Label.new()
	stars_lbl.text = stars
	stars_lbl.add_theme_font_size_override("font_size", 10)
	stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # gold
	vbox.add_child(stars_lbl)

	card.add_child(vbox)

	# 存储怪物数据用于点击检测
	card.set_meta("monster_id", monster.get("id", ""))
	card.set_meta("unlocked", is_unlocked)

	return card

func _get_element_color(elem: String) -> Color:
	var colors: Dictionary = {
		"fire": Color(0.96, 0.26, 0.21),
		"water": Color(0.20, 0.56, 0.98),
		"grass": Color(0.18, 0.80, 0.44),
		"thunder": Color(0.98, 0.82, 0.18),
		"light": Color(0.98, 0.98, 0.90),
		"earth": Color(0.76, 0.62, 0.44),
		"wind": Color(0.44, 0.90, 0.88),
		"dark": Color(0.38, 0.30, 0.68)
	}
	return colors.get(elem, Color.WHITE)

# ============================================
# 点击处理
# ============================================

func _handle_tap(x: float, y: float) -> void:
	if _state == "detail":
		# 详情面板关闭检测（通过全局位置检测）
		var close_rect: Rect2 = _close_btn.get_global_rect()
		if close_rect.has_point(Vector2(x, y)):
			_state = "list"
			_selected_monster = {}
			_detail_panel.visible = false
			return

		var evolve_rect: Rect2 = _evolve_btn.get_global_rect()
		if evolve_rect.has_point(Vector2(x, y)) and _evolve_btn.visible:
			# 进化按钮在详情面板中
			pass
		return

	# 返回按钮
	var back_rect: Rect2 = Rect2(15.0, 15.0, 70.0, 35.0)
	if back_rect.has_point(Vector2(x, y)):
		_on_back_pressed()
		return

	# 属性筛选标签（动态计算位置，与创建时一致）
	var filter_y: float = 65.0
	var filter_h: float = 26.0
	var filter_start_x: float = 15.0
	var filter_gap: float = 6.0
	var current_x: float = filter_start_x

	for el: String in _all_elements:
		var btn_w: float = 34.0
		if y >= filter_y and y <= filter_y + filter_h and x >= current_x and x <= current_x + btn_w:
			_selected_element = el
			_scroll_y = 0.0
			_apply_element_filter()
			return
		current_x += btn_w + filter_gap

	# 怪物网格点击
	var rel_x: float = x - _start_x
	var rel_y: float = y + _scroll_y - HEADER_H

	if rel_x < 0.0 or rel_y < 0.0:
		return

	var col: int = int(rel_x / (ITEM_W + GAP))
	var row: int = int(rel_y / (ITEM_H + GAP))

	if col >= COLS:
		return

	var index: int = row * COLS + col
	if index >= _filtered_monsters.size():
		return

	var monster: Dictionary = _filtered_monsters[index]
	var player: Dictionary = _storage.load_player() if _storage and _storage.has_method("load_player") else {}
	var is_unlocked: bool = (player.get("captured", [])).has(monster.get("id", ""))

	if is_unlocked:
		_selected_monster = monster
		_state = "detail"
		_show_detail_panel()

func _scroll_by_direction(direction: int) -> void:
	_scroll_y = clampf(_scroll_y + direction * (ITEM_H + GAP), 0.0, _max_scroll_y)
	# 通过移动网格容器实现滚动
	var new_offset: float = HEADER_H - _scroll_y
	_monster_grid.position.y = new_offset

# ============================================
# 详情面板
# ============================================

func _show_detail_panel() -> void:
	_detail_panel.visible = true
	_update_detail_panel()

func _update_detail_panel() -> void:
	var m: Dictionary = _selected_monster
	if m.is_empty():
		return

	var elem_color: Color = _get_element_color(m.get("element", "fire"))

	# 更新卡片样式
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.1)
	card_style.border_color = elem_color
	card_style.border_width_left = 2.0
	card_style.border_width_right = 2.0
	card_style.border_width_top = 2.0
	card_style.border_width_bottom = 2.0
	card_style.set_corner_radius_all(8.0)
	_card_panel.add_theme_stylebox_override("panel", card_style)

	# 更新内容
	_emoji_label.text = m.get("emoji", "❓")
	_name_label.text = m.get("name", "???")

	var rarity: int = m.get("rarity", 1)
	_stars_label.text = "★".repeat(rarity)

	# 更新属性标签
	_element_label.text = _element_names.get(m.get("element", ""), "")
	var elem_tag_style: StyleBoxFlat = StyleBoxFlat.new()
	elem_tag_style.bg_color = elem_color
	elem_tag_style.set_corner_radius_all(4.0)
	_element_panel.add_theme_stylebox_override("panel", elem_tag_style)

	# 更新属性值
	_hp_label.text = "%d" % m.get("baseHP", 0)
	_atk_label.text = "%d" % m.get("baseATK", 0)
	_def_label.text = "%d" % m.get("baseDEF", 0)
	_spd_label.text = "%d" % m.get("baseSPD", 0)

	# 更新技能
	var skill: Dictionary = m.get("skill", {})
	_skill_name_label.text = skill.get("name", "未知技能")
	_skill_desc_label.text = "消耗: %d 能量 | 倍率: %.1fx" % [skill.get("cost", 0), skill.get("multiplier", 1.0)]

	# 收服状态
	var player: Dictionary = _storage.load_player() if _storage and _storage.has_method("load_player") else {}
	var is_captured: bool = (player.get("captured", [])).has(m.get("id", ""))
	if is_captured:
		_status_label.text = "✅ 已收服"
	else:
		_status_label.text = "❓ 未收服"

	# 进化按钮
	var has_evolution: bool = false
	if m.has("evolution") and m["evolution"].has("target"):
		has_evolution = true

	_evolve_btn.visible = has_evolution and is_captured

# ============================================
# 按钮回调
# ============================================

func _on_back_pressed() -> void:
	SceneManager.switch_scene("start")

func _on_evolve_pressed() -> void:
	if not _selected_monster.is_empty():
		SceneManager.switch_scene("evolve")

func _on_close_pressed() -> void:
	_state = "list"
	_selected_monster = {}
	_detail_panel.visible = false

func _on_filter_pressed(element: String) -> void:
	_selected_element = element
	_scroll_y = 0.0
	_apply_element_filter()
	_update_filter_buttons()

# ============================================
# UI 更新
# ============================================

func _update_ui() -> void:
	_title_label.text = "📖 怪物图鉴"

	# 统计
	var player: Dictionary = _storage.load_player() if _storage and _storage.has_method("load_player") else {}
	var captured: Array = player.get("captured", [])
	var total: int = _filtered_monsters.size()
	_stat_label.text = "已收集: %d/%d" % [captured.size(), total]

	_update_filter_buttons()

func _update_filter_buttons() -> void:
	for i: int in range(_all_elements.size()):
		var el: String = _all_elements[i]
		var btn: Button = (_filter_container.get_child(i) as Button) if i < _filter_container.get_child_count() else null
		if btn:
			btn.button_pressed = (_selected_element == el)

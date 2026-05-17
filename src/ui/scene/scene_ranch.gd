# ============================================
# scene_ranch.gd - 牧场场景（挂机培养）
# 翻译来源: js/ui/sceneRanch.js
# 重构版本: 移除 @onready，标准化 _create_ui() 布局
# ============================================
class_name SceneRanch
extends Control

# ============================================
# 信号定义
# ============================================
signal exp_collected(total_exp: int)

# ============================================
# 常量定义
# ============================================
const DESIGN_W := 375.0
const DESIGN_H := 667.0
const SLOT_SIZE := 90.0
const SLOT_GAP := 15.0
const SLOT_COUNT := 3
const SLOT_Y := 150.0
const IDLE_INTERVAL_MS := 5 * 60 * 1000  # 5分钟

const BUBBLE_TYPES := ["💤", "⭐", "❤️", "💪"]
const BUBBLE_LIFE_MIN := 2.0
const BUBBLE_LIFE_MAX := 4.0
const BUBBLE_INTERVAL_MIN := 3.0
const BUBBLE_INTERVAL_MAX := 6.0

# ============================================
# 节点引用（重构后：无 @onready）
# ============================================
var _back_btn: Button
var _collect_btn: Button
var _slots_container: HBoxContainer
var _detail_panel: PanelContainer
var _picker_container: ScrollContainer
var _picker_grid: GridContainer
var _title_label: Label
var _hint_label: Label

# ============================================
# 状态变量
# ============================================
var _game: Node = null
var _selected_slot: int = 0
var _slots_data: Array = []  # [{monster_id, placed_at}]
var _captured_monsters: Array = []
var _detail_monster: Dictionary = {}
var _detail_stats: Dictionary = {}
var _detail_nature: Dictionary = {}
var _idle_exp_map: Dictionary = {}  # monster_id -> exp
var _bubbles: Array = []
var _bubble_timer: float = 0.0
var _touched_btn: Control = null
var _scroll_y: float = 0.0

# ============================================
# 气泡数据结构
# ============================================
class BubbleData:
	var slot_index: int
	var type: String
	var x: float
	var y: float
	var base_y: float
	var opacity: float
	var life: float
	var age: float
	var speed_y: float
	var drift: float

# ============================================
# 入口
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
	name = "SceneRanch"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_ui()

# ============================================
# 初始化（外部调用）
# ============================================
func init(data: Dictionary = {}) -> void:
	# 兼容 main.gd 的 init(data) 调用
	if _game == null:
		_game = get_node_or_null("/root/GameManager")
	_load_data()
	_calc_idle_exp()
	_init_bubbles()
	_build_slot_buttons()
	_build_picker_buttons()
	_update_detail_panel()
	_update_collect_button()

func initialize(game: Node) -> void:
	_game = game
	_load_data()
	_calc_idle_exp()
	_init_bubbles()
	_build_slot_buttons()
	_build_picker_buttons()
	_update_detail_panel()
	_update_collect_button()

# ============================================
# UI 构建（重构后）
# ============================================
func _create_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# === Header ===
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 50
	header.alignment = BoxContainer.ALIGNMENT_CENTER

	_back_btn = Button.new()
	_back_btn.text = "← 返回"
	_back_btn.pressed.connect(_on_back_pressed)
	header.add_child(_back_btn)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size.x = 20
	header.add_child(spacer1)

	_title_label = Label.new()
	_title_label.text = "牧场"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	header.add_child(_title_label)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size.x = 20
	header.add_child(spacer2)

	_collect_btn = Button.new()
	_collect_btn.text = "收取"
	_collect_btn.pressed.connect(_on_collect_pressed)
	header.add_child(_collect_btn)

	vbox.add_child(header)

	# === Hint ===
	_hint_label = Label.new()
	_hint_label.text = "放置怪物挂机获取经验"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	vbox.add_child(_hint_label)

	# === Slots ===
	var slots_center = CenterContainer.new()
	slots_center.custom_minimum_size.y = SLOT_SIZE + 20

	_slots_container = HBoxContainer.new()
	_slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_container.add_theme_constant_override("separation", SLOT_GAP)
	# 槽位按钮在 initialize() → _build_slot_buttons() 中按数据创建

	slots_center.add_child(_slots_container)
	vbox.add_child(slots_center)

	# === Detail Panel ===
	var detail_margin = MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 12)
	detail_margin.add_theme_constant_override("margin_top", 8)
	detail_margin.add_theme_constant_override("margin_right", 12)
	detail_margin.add_theme_constant_override("margin_bottom", 8)
	detail_margin.custom_minimum_size.y = 160

	_detail_panel = PanelContainer.new()
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 4)
	_detail_panel.add_child(detail_vbox)
	detail_margin.add_child(_detail_panel)
	vbox.add_child(detail_margin)

	# === Picker ===
	_picker_container = ScrollContainer.new()
	_picker_container.custom_minimum_size.y = 180
	_picker_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_picker_grid = GridContainer.new()
	_picker_grid.add_theme_constant_override("h_separation", 6)
	_picker_grid.add_theme_constant_override("v_separation", 6)
	_picker_grid.custom_minimum_size.x = DESIGN_W - 24
	_picker_grid.columns = 5

	_picker_container.add_child(_picker_grid)
	vbox.add_child(_picker_container)

# ============================================
# 数据加载
# ============================================
func _load_data() -> void:
	_slots_data = []
	for i in range(SLOT_COUNT):
		_slots_data.append({"monster_id": null, "placed_at": null})

	_captured_monsters = []
	if _game and _game.storage:
		var ranch_state = _game.storage.get_ranch_state()
		if ranch_state and ranch_state.has("slots"):
			var saved_slots = ranch_state["slots"]
			for i in range(min(saved_slots.size(), SLOT_COUNT)):
				_slots_data[i] = _normalize_slot(saved_slots[i])

		_captured_monsters = _game.storage.get_captured_monsters()

	_select_slot(0)

func _normalize_slot(slot_data: Variant) -> Dictionary:
	if not slot_data is Dictionary:
		return {"monster_id": null, "placed_at": null}
	var slot: Dictionary = slot_data
	return {
		"monster_id": slot.get("monster_id", slot.get("monsterId", null)),
		"placed_at": slot.get("placed_at", slot.get("placedAt", null))
	}

func _save_ranch_state() -> void:
	if _game and _game.storage:
		var unlocked = 3
		_game.storage.set_ranch_state({
			"slots": _slots_data,
			"unlocked_slots": unlocked
		})

# ============================================
# 挂机经验计算
# ============================================
func _calc_idle_exp() -> void:
	_idle_exp_map = {}
	var now = Time.get_unix_time_from_system() * 1000

	for i in range(_slots_data.size()):
		var slot = _slots_data[i]
		if not slot["monster_id"] or not slot["placed_at"]:
			continue

		var elapsed = now - slot["placed_at"]
		var intervals = int(elapsed / IDLE_INTERVAL_MS)

		if intervals > 0:
			var level = 1
			if _game and _game.storage:
				level = _game.storage.get_monster_level(slot["monster_id"])

			var rate = 2.0 + level * 0.5
			if _game and _game.storage:
				rate = _game.storage.get_idle_exp_rate(slot["monster_id"])

			_idle_exp_map[slot["monster_id"]] = intervals * rate

# ============================================
# 气泡系统
# ============================================
func _init_bubbles() -> void:
	_bubbles = []
	for i in range(_slots_data.size()):
		var slot = _slots_data[i]
		if slot["monster_id"]:
			_add_bubble(i, slot["monster_id"])

func _add_bubble(slot_index: int, monster_id: int) -> void:
	var type_idx = randi() % BUBBLE_TYPES.size()
	var life = BUBBLE_LIFE_MIN + randf() * (BUBBLE_LIFE_MAX - BUBBLE_LIFE_MIN)

	var bubble = BubbleData.new()
	bubble.slot_index = slot_index
	bubble.type = BUBBLE_TYPES[type_idx]
	bubble.x = 0
	bubble.y = 0
	bubble.base_y = 0
	bubble.opacity = 1.0
	bubble.life = life
	bubble.age = 0
	bubble.speed_y = -0.3 - randf() * 0.3
	bubble.drift = (randf() - 0.5) * 0.5

	_bubbles.append(bubble)

func _update_bubbles(delta: float) -> void:
	_bubble_timer += delta

	if _bubble_timer > BUBBLE_INTERVAL_MIN + randf() * (BUBBLE_INTERVAL_MAX - BUBBLE_INTERVAL_MIN):
		_bubble_timer = 0
		for i in range(_slots_data.size()):
			var slot = _slots_data[i]
			if slot["monster_id"] and randf() > 0.5:
				_add_bubble(i, slot["monster_id"])

	# 更新现有气泡
	for i in range(_bubbles.size() - 1, -1, -1):
		var b: BubbleData = _bubbles[i]
		b.age += delta
		b.y += b.speed_y
		b.x += b.drift * delta * 30

		# 最后0.5秒淡出
		if b.age > b.life - 0.5:
			b.opacity = maxf(0, (b.life - b.age) / 0.5)

		if b.age >= b.life:
			_bubbles.remove_at(i)

# ============================================
# 选中槽位
# ============================================
func _select_slot(index: int) -> void:
	_selected_slot = index

	if index < 0 or index >= _slots_data.size():
		_detail_monster = {}
		_detail_stats = {}
		_detail_nature = {}
		return

	var slot = _slots_data[index]

	if slot["monster_id"] and MonsterDb.has_monster(slot["monster_id"]):
		var db = MonsterDb.get_monster(slot["monster_id"])
		var level = 1
		if _game and _game.storage:
			level = _game.storage.get_monster_level(slot["monster_id"])

		_detail_monster = db.duplicate()
		_detail_monster["level"] = level

		_detail_stats = MonsterDb.get_monster_stats(slot["monster_id"], level)

		var nature_id = null
		if _game and _game.storage:
			nature_id = _game.storage.get_monster_nature(slot["monster_id"])

		if nature_id and NatureDB.has_nature(nature_id):
			_detail_nature = NatureDB.get_nature(nature_id)
		else:
			_detail_nature = {}
	else:
		_detail_monster = {}
		_detail_stats = {}
		_detail_nature = {}

# ============================================
# UI 构建
# ============================================
func _build_slot_buttons() -> void:
	# 清除旧按钮
	for child in _slots_container.get_children():
		child.queue_free()

	var total_w = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP
	var start_x = (DESIGN_W - total_w) / 2

	for i in range(SLOT_COUNT):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_btn.add_theme_stylebox_override("normal", _create_slot_style(i, false, false))
		slot_btn.add_theme_stylebox_override("pressed", _create_slot_style(i, false, true))
		slot_btn.pressed.connect(_on_slot_pressed.bind(i))

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var emoji_label = Label.new()
		emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji_label.add_theme_font_size_override("font_size", 32)

		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)

		var exp_label = Label.new()
		exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_label.add_theme_color_override("font_color", Color.YELLOW)
		exp_label.add_theme_font_size_override("font_size", 12)

		vbox.add_child(emoji_label)
		vbox.add_child(name_label)
		vbox.add_child(exp_label)

		slot_btn.add_child(vbox)
		_slots_container.add_child(slot_btn)

		_update_slot_button(slot_btn, i)

func _create_slot_style(slot_index: int, has_monster: bool, pressed: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12

	if has_monster:
		style.bg_color = Color(0.16, 0.35, 0.16, 0.9)
	else:
		style.bg_color = Color(0.1, 0.23, 0.1, 0.9)

	if pressed:
		style.bg_color = Color(0.29, 0.55, 0.29, 0.9)

	if slot_index == _selected_slot:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.7, 0.3, 1.0)

	return style

func _update_slot_button(btn: Button, index: int) -> void:
	if index >= _slots_data.size():
		return

	var slot = _slots_data[index]
	var vbox: VBoxContainer = btn.get_child(0)
	var emoji_label: Label = vbox.get_child(0)
	var name_label: Label = vbox.get_child(1)
	var exp_label: Label = vbox.get_child(2)

	if slot["monster_id"] and MonsterDb.has_monster(slot["monster_id"]):
		var db = MonsterDb.get_monster(slot["monster_id"])
		emoji_label.text = db.get("emoji", "❓")
		name_label.text = db.get("name", "???")
		name_label.add_theme_color_override("font_color", Color.WHITE)

		var idle_exp = _idle_exp_map.get(slot["monster_id"], 0)
		if idle_exp > 0:
			exp_label.text = "+%d" % int(idle_exp)
			exp_label.visible = true
		else:
			exp_label.visible = false
	else:
		emoji_label.text = "➕"
		name_label.text = "空位"
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		exp_label.visible = false

	var has_monster := slot.get("monster_id", null) != null
	btn.add_theme_stylebox_override("normal", _create_slot_style(index, has_monster, false))
	btn.add_theme_stylebox_override("pressed", _create_slot_style(index, has_monster, true))

func _build_picker_buttons() -> void:
	# 清除旧按钮
	for child in _picker_grid.get_children():
		child.queue_free()

	var used_ids = {}
	for slot in _slots_data:
		if slot["monster_id"]:
			used_ids[slot["monster_id"]] = true

	var available: Array = []
	for mid in _captured_monsters:
		if MonsterDb.has_monster(mid):
			available.append(mid)

	for i in range(available.size()):
		var monster_id = available[i]
		var db = MonsterDb.get_monster(monster_id)

		var item_btn = Button.new()
		item_btn.custom_minimum_size = Vector2(55, 65)

		var in_use = used_ids.has(monster_id)
		item_btn.add_theme_stylebox_override("normal", _create_picker_item_style(in_use))
		item_btn.add_theme_stylebox_override("pressed", _create_picker_item_style(in_use, true))
		item_btn.pressed.connect(_on_picker_item_pressed.bind(monster_id))

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var emoji_label = Label.new()
		emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji_label.add_theme_font_size_override("font_size", 24)
		emoji_label.text = db.get("emoji", "❓")

		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.text = db.get("name", "???")

		if in_use:
			name_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))

		vbox.add_child(emoji_label)
		vbox.add_child(name_label)

		item_btn.add_child(vbox)
		_picker_grid.add_child(item_btn)

func _create_picker_item_style(in_use: bool, pressed: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if in_use:
		style.bg_color = Color(0.23, 0.35, 0.23, 0.9)
	else:
		style.bg_color = Color(0.1, 0.23, 0.1, 0.9)

	if pressed:
		style.bg_color = Color(0.29, 0.55, 0.29, 0.9)

	return style

# ============================================
# 详情面板更新
# ============================================
func _update_detail_panel() -> void:
	var detail_vbox: VBoxContainer = _detail_panel.get_child(0) if _detail_panel.get_child_count() > 0 else null
	if not detail_vbox:
		return

	# 清除旧内容
	for child in detail_vbox.get_children():
		child.queue_free()

	if _detail_monster.is_empty():
		var empty_label = Label.new()
		empty_label.text = "点击下方怪物放入牧场"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_vbox.add_child(empty_label)

		var empty_label2 = Label.new()
		empty_label2.text = "怪物将在此挂机获得经验"
		empty_label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_vbox.add_child(empty_label2)
		return

	var m = _detail_monster
	var s = _detail_stats

	# 名称行
	var name_hbox = HBoxContainer.new()

	var emoji_label = Label.new()
	emoji_label.text = m.get("emoji", "❓")
	emoji_label.add_theme_font_size_override("font_size", 28)
	name_hbox.add_child(emoji_label)

	var name_label = Label.new()
	name_label.text = m.get("name", "???")
	name_label.add_theme_font_size_override("font_size", 18)
	name_hbox.add_child(name_label)

	var level_label = Label.new()
	level_label.text = "Lv.%d" % m.get("level", 1)
	level_label.add_theme_color_override("font_color", Color.YELLOW)
	level_label.add_theme_font_size_override("font_size", 14)
	name_hbox.add_child(level_label)

	detail_vbox.add_child(name_hbox)

	# 性格
	if not _detail_nature.is_empty():
		var nature_hbox = HBoxContainer.new()
		var nature_label = Label.new()
		nature_label.text = "%s %s" % [_detail_nature.get("emoji", ""), _detail_nature.get("name", "")]
		nature_label.add_theme_font_size_override("font_size", 12)
		nature_hbox.add_child(nature_label)
		detail_vbox.add_child(nature_hbox)

	# 属性条
	var stats = [
		{"label": "HP", "value": s.get("hp", 0), "color": Color.RED},
		{"label": "ATK", "value": s.get("atk", 0), "color": Color.ORANGE},
		{"label": "DEF", "value": s.get("def", 0), "color": Color.BLUE},
		{"label": "SPD", "value": s.get("spd", 0), "color": Color.GREEN}
	]

	for stat in stats:
		var stat_hbox = HBoxContainer.new()

		var label_l = Label.new()
		label_l.text = stat["label"]
		label_l.add_theme_font_size_override("font_size", 12)
		label_l.custom_minimum_size = Vector2(40, 0)
		stat_hbox.add_child(label_l)

		var value_l = Label.new()
		value_l.text = str(int(stat["value"]))
		value_l.add_theme_color_override("font_color", stat["color"])
		value_l.add_theme_font_size_override("font_size", 12)
		stat_hbox.add_child(value_l)

		detail_vbox.add_child(stat_hbox)

	# 挂机信息
	var slot = _slots_data[_selected_slot] if _selected_slot < _slots_data.size() else null
	var idle_exp = 0.0
	var rate = 0.0

	if slot and slot["monster_id"]:
		idle_exp = _idle_exp_map.get(slot["monster_id"], 0.0)
		if _game and _game.storage:
			rate = _game.storage.get_idle_exp_rate(slot["monster_id"])

	var info_label = Label.new()
	info_label.text = "🏋️ 收益: +%.1f EXP/5min" % rate
	info_label.add_theme_font_size_override("font_size", 12)
	detail_vbox.add_child(info_label)

	if idle_exp > 0:
		var exp_label = Label.new()
		exp_label.text = "待领取: +%d EXP" % int(idle_exp)
		exp_label.add_theme_color_override("font_color", Color.YELLOW)
		exp_label.add_theme_font_size_override("font_size", 12)
		detail_vbox.add_child(exp_label)

# ============================================
# 操作：放置/移除怪物
# ============================================
func _on_slot_pressed(index: int) -> void:
	_select_slot(index)
	_build_slot_buttons()
	_update_detail_panel()

func _on_picker_item_pressed(monster_id: int) -> void:
	# 检查是否已在其他槽位
	for i in range(_slots_data.size()):
		if _slots_data[i]["monster_id"] == monster_id:
			# 移除
			_slots_data[i] = {"monster_id": null, "placed_at": null}
			_save_ranch_state()
			_build_slot_buttons()
			_select_slot(_selected_slot)
			return

	# 放入当前选中槽位
	if _selected_slot >= _slots_data.size():
		return

	var slot = _slots_data[_selected_slot]

	# 如果槽位已有怪物，先结算经验
	if slot["monster_id"]:
		var idle_exp = _idle_exp_map.get(slot["monster_id"], 0)
		if idle_exp > 0 and _game and _game.storage:
			_game.storage.add_monster_exp(slot["monster_id"], idle_exp)

	var now_ms = Time.get_unix_time_from_system() * 1000
	_slots_data[_selected_slot] = {"monster_id": monster_id, "placed_at": now_ms}

	_save_ranch_state()
	_build_slot_buttons()
	_select_slot(_selected_slot)
	_calc_idle_exp()
	_init_bubbles()

func _on_collect_pressed() -> void:
	var total_collected = 0
	var results = []

	for slot in _slots_data:
		if not slot["monster_id"]:
			continue

		var exp = _idle_exp_map.get(slot["monster_id"], 0)
		if exp > 0:
			if _game and _game.storage:
				_game.storage.add_monster_exp(slot["monster_id"], exp)
			total_collected += exp
			results.append({"monster_id": slot["monster_id"], "exp": exp})
			# 重置放置时间
			slot["placed_at"] = Time.get_unix_time_from_system() * 1000

	_save_ranch_state()
	_idle_exp_map = {}
	_calc_idle_exp()
	_build_slot_buttons()
	_select_slot(_selected_slot)

	if total_collected > 0:
		print("[SceneRanch] 收取挂机经验: %d EXP" % total_collected)
		exp_collected.emit(total_collected)

func _on_back_pressed() -> void:
	_go_to_scene("main")

# ============================================
# 场景跳转
# ============================================
func _go_to_scene(scene_name: String) -> void:
	SceneManager.switch_scene(scene_name)

# ============================================
# 收集按钮更新
# ============================================
func _update_collect_button() -> void:
	var total_idle = 0.0
	for exp in _idle_exp_map.values():
		total_idle += exp

	if total_idle > 0:
		_collect_btn.text = "收取 +%d" % int(total_idle)
		_collect_btn.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_collect_btn.text = "收取"
		_collect_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))

# ============================================
# 帧更新
# ============================================
func _process(delta: float) -> void:
	_update_bubbles(delta)

# ============================================
# 销毁
# ============================================
func _exit_tree() -> void:
	_bubbles = []
	_touched_btn = null

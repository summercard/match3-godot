# scene_achievement.gd - 成就系统场景
# 源文件: js/ui/sceneAchievement.js
# 纯代码重构版本（无 .tscn 依赖）
class_name SceneAchievement
extends Control

const AchievementDB = preload("res://src/data/achievement_db.gd")

# === 静态常量 ===
const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0
const LIST_START_Y: float = 160.0
const LIST_BOTTOM_Y: float = 647.0
const ITEM_H: float = 70.0
const TAB_W: float = 62.0
const TAB_GAP: float = 7.0
const TAB_START_X: float = 16.0
const TAB_Y: float = 112.0
const BACK_BTN: Rect2 = Rect2(15.0, 15.0, 60.0, 35.0)

# === 节点引用（纯代码赋值） ===
var back_btn: Button
var title_label: Label
var stat_label: Label
var tabs_container: HBoxContainer
var scroll_container: ScrollContainer
var achievement_list: VBoxContainer
var claimed_dialog: PanelContainer
var target_dialog: PanelContainer

# === 成员变量 ===
var _game: Node = null
var _storage = null

# 成就数据
var _all_achievements: Array = []
var _filtered_achievements: Array = []
var _current_category: String = "all"
var _categories: Array = ["all", "battle", "collect", "numeric", "continuous"]
var _category_labels: Dictionary = {
	"all": "全部",
	"battle": "战斗",
	"collect": "收集",
	"numeric": "数值",
	"continuous": "连续"
}

# 选中/领取状态
var _selected_ach: Dictionary = {}
var _claimed_ach: Dictionary = {}
var _claim_timer: float = 0.0

# 滚动
var _scroll_offset: float = 0.0
var _is_dragging: bool = false
var _last_mouse_y: float = 0.0

# ==================== 生命周期 ====================

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
	_create_ui()
	_init_data()

func init(data: Dictionary = {}) -> void:
	# 兼容 main.gd 的 init(data) 调用，_ready 已经初始化过了
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventScreenTouch:
			if event.pressed:
				_last_mouse_y = event.position.y
				_handle_tap(event.position.x, event.position.y)
			else:
				_is_dragging = false
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					_last_mouse_y = event.position.y
					_handle_tap(event.position.x, event.position.y)
				else:
					_is_dragging = false
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and _is_dragging):
		var drag_y: float
		if event is InputEventScreenDrag:
			drag_y = event.position.y
		else:
			drag_y = event.position.y

		if _is_dragging or abs(drag_y - _last_mouse_y) > 5:
			_is_dragging = true
			var direction: int = 0
			var current_y: float = drag_y if event is InputEventScreenDrag else event.position.y
			if current_y - _last_mouse_y > 10:
				direction = -1  # 向下拖（内容向上）
			elif _last_mouse_y - current_y > 10:
				direction = 1   # 向上拖（内容向下）

			if direction != 0:
				_scroll_by_direction(direction)
			_last_mouse_y = current_y

# ==================== UI 创建 ====================

func _create_ui() -> void:
	# 背景
	add_theme_stylebox_override("panel", _make_bg_style())

	# 返回按钮
	back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.position = Vector2(15.0, 15.0)
	back_btn.custom_minimum_size = Vector2(60.0, 35.0)
	back_btn.pressed.connect(_on_back_pressed)
	_back_btn_style(back_btn, false)
	add_child(back_btn)

	# 标题
	title_label = Label.new()
	title_label.text = "🏆 成就"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.position = Vector2(DESIGN_W / 2.0, 70.0)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # gold
	add_child(title_label)

	# 统计标签
	stat_label = Label.new()
	stat_label.text = "已解锁 0/0"
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stat_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stat_label.position = Vector2(DESIGN_W / 2.0, 94.0)
	stat_label.add_theme_font_size_override("font_size", 12)
	stat_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(stat_label)

	# 分类标签容器
	tabs_container = HBoxContainer.new()
	tabs_container.position = Vector2(TAB_START_X, TAB_Y)
	tabs_container.add_theme_constant_override("separation", TAB_GAP)
	add_child(tabs_container)

	# 创建分类按钮
	for cat: String in _categories:
		var btn: Button = _make_tab_button(cat, _category_labels[cat])
		tabs_container.add_child(btn)

	# 滚动容器
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(0.0, LIST_START_Y)
	scroll_container.size = Vector2(DESIGN_W, DESIGN_H - LIST_START_Y - 20.0)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.scroll_started.connect(_on_scroll_started)
	scroll_container.scroll_ended.connect(_on_scroll_ended)
	add_child(scroll_container)

	# 成就列表
	achievement_list = VBoxContainer.new()
	achievement_list.add_theme_constant_override("separation", 10)
	achievement_list.custom_minimum_size = Vector2(DESIGN_W - 30.0, 0.0)
	scroll_container.add_child(achievement_list)

	# 已领取弹窗
	claimed_dialog = _make_dialog("claimed")
	claimed_dialog.visible = false
	add_child(claimed_dialog)

	# 目标详情弹窗
	target_dialog = _make_dialog("target")
	target_dialog.visible = false
	add_child(target_dialog)

func _make_bg_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.20)  # bgMedium
	style.corner_radius_top_left = 0.0
	style.corner_radius_top_right = 0.0
	style.corner_radius_bottom_left = 0.0
	style.corner_radius_bottom_right = 0.0
	return style

func _back_btn_style(btn: Button, pressed: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.22, 0.30) if not pressed else Color(0.18, 0.18, 0.24)
	style.corner_radius_top_left = 6.0
	style.corner_radius_top_right = 6.0
	style.corner_radius_bottom_left = 6.0
	style.corner_radius_bottom_right = 6.0
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	btn.add_theme_font_size_override("font_size", 12)

func _make_tab_button(category: String, label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(TAB_W, 34.0)
	btn.pressed.connect(_on_tab_pressed.bind(category))
	_set_tab_style(btn, category == _current_category)
	return btn

func _set_tab_style(btn: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(1.0, 0.84, 0.0)  # gold
		style.corner_radius_top_left = 6.0
		style.corner_radius_top_right = 6.0
		style.corner_radius_bottom_left = 6.0
		style.corner_radius_bottom_right = 6.0
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_color_override("font_color", Color(0.15, 0.15, 0.20))
	else:
		style.bg_color = Color(0.20, 0.20, 0.28)  # bgCard
		style.corner_radius_top_left = 6.0
		style.corner_radius_top_right = 6.0
		style.corner_radius_bottom_left = 6.0
		style.corner_radius_bottom_right = 6.0
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	btn.add_theme_font_size_override("font_size", 12)

func _make_dialog(type: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(DESIGN_W - 80.0, 80.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.20, 0.28)  # bgCard
	style.corner_radius_top_left = 12.0
	style.corner_radius_top_right = 12.0
	style.corner_radius_bottom_left = 12.0
	style.corner_radius_bottom_right = 12.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 14)
	if type == "claimed":
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # gold
	else:
		title_lbl.add_theme_color_override("font_color", Color(0.89, 0.19, 0.19))  # danger
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.name = "DescLabel"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(desc_lbl)

	return panel

# ==================== 数据初始化 ====================

func _init_data() -> void:
	_game = get_node_or_null("/root/GameManager")
	_storage = get_node_or_null("/root/SaveManager")
	if _storage == null and _game and _game.get("storage"):
		_storage = _game.storage

	_all_achievements = _build_achievement_view_models()

	_filter_by_category("all")
	_update_ui()

func _build_achievement_view_models() -> Array:
	var save_data: Dictionary = _storage.load_achievements() if _storage and _storage.has_method("load_achievements") else {}
	var unlocked_ids: Array = save_data.get("unlockedIds", [])
	var stats: Dictionary = save_data.get("stats", {}).duplicate(true)
	_apply_derived_stats(stats)

	var achievements: Array = []
	for ach: Dictionary in AchievementDB.ACHIEVEMENTS:
		var item: Dictionary = ach.duplicate(true)
		var progress_key: String = item.get("progressKey", "")
		var progress: int = int(stats.get(progress_key, 0))
		var target: int = int(item.get("target", 1))
		var unlocked: bool = unlocked_ids.has(item.get("id", "")) or progress >= target
		item["progress"] = progress
		item["unlocked"] = unlocked
		achievements.append(item)
	return achievements

func _apply_derived_stats(stats: Dictionary) -> void:
	if not _storage:
		return

	if _storage.has_method("load_rewards"):
		var rewards: Dictionary = _storage.load_rewards()
		for key: String in ["battleCount", "captureCount", "totalGoldEarned", "totalItemsGained"]:
			stats[key] = maxi(int(stats.get(key, 0)), int(rewards.get(key, 0)))

	if _storage.has_method("load_player"):
		var player: Dictionary = _storage.load_player()
		stats["captureCount"] = maxi(int(stats.get("captureCount", 0)), player.get("captured", []).size())

	if _storage.has_method("load_stage_progress"):
		var cleared_count: int = 0
		var progress_data: Dictionary = _storage.load_stage_progress()
		for stage_id: String in progress_data.keys():
			var stage_state: Dictionary = progress_data.get(stage_id, {})
			if stage_state.get("cleared", false):
				cleared_count += 1
		stats["stageClearedCount"] = maxi(int(stats.get("stageClearedCount", 0)), cleared_count)

	if _storage.has_method("load_sign_in_data"):
		var sign_in_data: Dictionary = _storage.load_sign_in_data()
		stats["maxConsecutiveSignIn"] = maxi(int(stats.get("maxConsecutiveSignIn", 0)), int(sign_in_data.get("consecutiveDays", 0)))
		stats["totalSignInDays"] = maxi(int(stats.get("totalSignInDays", 0)), int(sign_in_data.get("totalDays", 0)))

# ==================== 分类筛选 ====================

func _on_tab_pressed(category: String) -> void:
	_filter_by_category(category)

func _filter_by_category(category: String) -> void:
	_current_category = category
	if category == "all":
		_filtered_achievements = _all_achievements.duplicate()
	else:
		_filtered_achievements = _all_achievements.filter(
			func(ach): return ach.get("category", "") == category
		)
	_scroll_offset = 0.0
	if scroll_container:
		scroll_container.scroll_vertical = 0
	_rebuild_achievement_list()
	_update_tabs()

func _rebuild_achievement_list() -> void:
	if not achievement_list:
		return
	# 清除旧列表
	for child: Node in achievement_list.get_children():
		child.queue_free()

	# 构建新列表
	for ach: Dictionary in _filtered_achievements:
		var item: HBoxContainer = _create_achievement_item(ach)
		achievement_list.add_child(item)

func _create_achievement_item(ach: Dictionary) -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(DESIGN_W - 30.0, 60.0)
	hbox.add_theme_constant_override("separation", 10)

	# 背景面板
	var bg_panel: PanelContainer = PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var bg_color: Color
	if ach.get("unlocked", false):
		bg_color = Color(0.29, 0.69, 0.31, 0.15)  # success tint
	else:
		bg_color = Color(0.16, 0.16, 0.20)  # bgMedium
	style.bg_color = bg_color
	style.corner_radius_top_left = 6.0
	style.corner_radius_top_right = 6.0
	style.corner_radius_bottom_left = 6.0
	style.corner_radius_bottom_right = 6.0
	bg_panel.add_theme_stylebox_override("panel", style)
	hbox.add_child(bg_panel)

	# 内部布局
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# 第一行：图标 + 名称 + 进度条
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)

	# 图标
	var icon_lbl: Label = Label.new()
	icon_lbl.text = ach.get("icon", "🏆")
	icon_lbl.add_theme_font_size_override("font_size", 24)
	top_row.add_child(icon_lbl)

	# 名称
	var name_lbl: Label = Label.new()
	name_lbl.text = ach.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 14)
	if ach.get("unlocked", false):
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_lbl)

	# 进度条（未解锁时）
	if not ach.get("unlocked", false):
		var progress: float = ach.get("progress", 0)
		var target: float = ach.get("target", 1)
		var ratio: float = clampf(progress / target, 0.0, 1.0)

		var progress_container: HBoxContainer = HBoxContainer.new()
		progress_container.add_theme_constant_override("separation", 4)

		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(80.0, 8.0)
		bar.max_value = 100.0
		bar.value = ratio * 100.0
		bar.add_theme_color_override("fill_color", Color(0.89, 0.19, 0.19))  # danger
		var bar_style: StyleBoxFlat = StyleBoxFlat.new()
		bar_style.bg_color = Color(0.15, 0.15, 0.15)
		bar_style.set_corner_radius_all(4.0)
		bar.add_theme_stylebox_override("background", bar_style)
		progress_container.add_child(bar)

		var ratio_lbl: Label = Label.new()
		ratio_lbl.text = "%d/%d" % [progress, target]
		ratio_lbl.add_theme_font_size_override("font_size", 10)
		ratio_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		progress_container.add_child(ratio_lbl)

		top_row.add_child(progress_container)
	else:
		# 已解锁标记
		var check_lbl: Label = Label.new()
		check_lbl.text = "✓"
		check_lbl.add_theme_font_size_override("font_size", 20)
		check_lbl.add_theme_color_override("font_color", Color(0.30, 0.69, 0.31))  # success green
		top_row.add_child(check_lbl)

	vbox.add_child(top_row)

	# 第二行：描述 + 奖励
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = ach.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(desc_lbl)

	# 奖励
	var reward: Dictionary = ach.get("reward", {})
	if reward.has("gold"):
		var gold_lbl: Label = Label.new()
		gold_lbl.text = "💰 %d" % reward["gold"]
		gold_lbl.add_theme_font_size_override("font_size", 11)
		gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # gold
		bottom_row.add_child(gold_lbl)

	vbox.add_child(bottom_row)
	hbox.add_child(vbox)

	return hbox

# ==================== 点击处理 ====================

func _handle_tap(x: float, y: float) -> void:
	# 返回按钮
	if BACK_BTN.has_point(Vector2(x, y)):
		_on_back_pressed()
		return

	# 分类标签
	if y >= TAB_Y and y <= TAB_Y + 34.0:
		for i: int in range(_categories.size()):
			var btn_rect: Rect2 = _get_category_button(i)
			if btn_rect.has_point(Vector2(x, y)):
				_filter_by_category(_categories[i])
				return

	# 成就列表点击
	if y >= LIST_START_Y and y <= LIST_BOTTOM_Y:
		var index: int = int((y - LIST_START_Y + _scroll_offset) / ITEM_H)
		if index >= 0 and index < _filtered_achievements.size():
			var ach: Dictionary = _filtered_achievements[index]
			_on_achievement_tap(ach)

func _on_achievement_tap(ach: Dictionary) -> void:
	if ach.get("unlocked", false):
		# 已解锁：显示奖励已领取
		_claimed_ach = ach
		_claim_timer = 2.0
		claimed_dialog.visible = true
		_update_claimed_dialog()
	else:
		# 未解锁：高亮该成就目标
		_selected_ach = ach
		target_dialog.visible = true
		_update_target_dialog()

func _get_category_button(index: int) -> Rect2:
	var start_x: float = TAB_START_X + index * (TAB_W + TAB_GAP)
	return Rect2(start_x, TAB_Y, TAB_W, 34.0)

func _scroll_by_direction(direction: int) -> void:
	var max_offset: float = _get_max_scroll_offset()
	_scroll_offset = clampf(_scroll_offset - direction * ITEM_H, 0.0, max_offset)
	if scroll_container:
		scroll_container.scroll_vertical = int(_scroll_offset)

func _get_max_scroll_offset() -> float:
	var content_h: float = _filtered_achievements.size() * ITEM_H
	var visible_h: float = LIST_BOTTOM_Y - LIST_START_Y
	return maxf(0.0, content_h - visible_h)

func _on_scroll_started() -> void:
	_is_dragging = true

func _on_scroll_ended() -> void:
	_is_dragging = false

# ==================== UI 更新 ====================

func _update_ui() -> void:
	# 标题
	if title_label:
		title_label.text = "🏆 成就"

	# 统计
	var unlocked_count: int = _all_achievements.filter(func(a): return a.get("unlocked", false)).size()
	var total_count: int = _all_achievements.size()
	if stat_label:
		stat_label.text = "已解锁 %d/%d" % [unlocked_count, total_count]

	# Tab高亮
	_update_tabs()

	# 成就列表
	_rebuild_achievement_list()

func _update_tabs() -> void:
	if not tabs_container:
		return
	for i: int in range(_categories.size()):
		var btn: Button = (tabs_container.get_child(i) as Button) if i < tabs_container.get_child_count() else null
		if btn:
			var is_selected: bool = _current_category == _categories[i]
			_set_tab_style(btn, is_selected)

func _update_claimed_dialog() -> void:
	if _claimed_ach.is_empty() or not claimed_dialog:
		return
	var vbox: VBoxContainer = claimed_dialog.get_node_or_null("VBox") as VBoxContainer
	if vbox:
		var title_lbl: Label = vbox.get_node_or_null("TitleLabel") as Label
		var desc_lbl: Label = vbox.get_node_or_null("DescLabel") as Label
		if title_lbl:
			title_lbl.text = "✅ %s" % _claimed_ach.get("name", "")
		if desc_lbl:
			desc_lbl.text = "奖励已领取"

func _update_target_dialog() -> void:
	if _selected_ach.is_empty() or not target_dialog:
		return
	var vbox: VBoxContainer = target_dialog.get_node_or_null("VBox") as VBoxContainer
	if vbox:
		var title_lbl: Label = vbox.get_node_or_null("TitleLabel") as Label
		var desc_lbl: Label = vbox.get_node_or_null("DescLabel") as Label
		if title_lbl:
			title_lbl.text = "🎯 目标: %s" % _selected_ach.get("desc", "")
		if desc_lbl:
			var progress: float = _selected_ach.get("progress", 0)
			var target: float = _selected_ach.get("target", 1)
			desc_lbl.text = "进度: %d/%d" % [progress, target]

# ==================== 按钮回调 ====================

func _on_back_pressed() -> void:
	SceneManager.switch_scene("main")

# ==================== 定时器 ====================

func _process(delta: float) -> void:
	if _claim_timer > 0.0:
		_claim_timer -= delta
		if _claim_timer <= 0.0:
			_claimed_ach = {}
			if claimed_dialog:
				claimed_dialog.visible = false

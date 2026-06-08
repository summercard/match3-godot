# ============================================
# ui/scene/scene_evolve.gd - 精灵进化场景
# 翻译自: js/ui/sceneEvolve.js
# 重构: 纯代码驱动，删除所有 @onready
# ============================================
# 精灵进化界面，支持：
# - 进化素材选择（优先通过instanceId传入，兼容monsterId）
# - 进化预览（前后对比）
# - 进化条件检查（等级+道具）
# - 进化动画（粒子+淡入淡出）
# ============================================

class_name SceneEvolve
extends Control

const EvolutionRulesScript = preload("res://src/core/evolution_rules.gd")

# ============ 信号 ============
signal evolution_complete(new_monster_id: String)

# ============ 布局常量 ============
const DESIGN_W := 375.0
const DESIGN_H := 667.0

# ============ 节点引用（成员变量，非 @onready） ============
var _back_button: Button
var _title_label: Label
var _current_monster_container: VBoxContainer
var _evolve_arrow: Label
var _evolved_monster_container: VBoxContainer
var _condition_container: PanelContainer
var _condition_label: Label
var _evolve_button: Button
var _particle_container: Node2D
var _complete_panel: PanelContainer
var _complete_vbox: VBoxContainer  # complete_panel 内的 VBox

# ============ 游戏引用 ============
var _game: Node = null
var _storage: Node = null

# ============ 状态数据 ============
var instance_id: String = ""
var monster_id: String = ""
var monster_data: Dictionary = {}
var evolve_data: Dictionary = {}
var evolved_monster: Dictionary = {}
var can_evolve: bool = false
var condition_text: String = ""
var evolution_report: Dictionary = {}

# ============ 动画状态 ============
var anim_state: Dictionary = {
	"progress": 0.0,
	"particles": [],
	"is_evolving": false,
	"evolve_complete": false
}

# ============ 元素名称映射 ============
const ELEMENT_NAMES: Dictionary = {
	"fire": "火", "water": "水", "grass": "草", "thunder": "雷",
	"light": "光", "earth": "土", "wind": "风", "dark": "暗"
}

# ============ 生命周期 ============

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
	name = "SceneEvolve"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_ui()

func _create_ui() -> void:
	# ---- VBox 主容器 ----
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# ---- Header ----
	_build_header(vbox)

	# ---- EvolveSection ----
	_build_evolve_section(vbox)

	# ---- ConditionContainer ----
	_build_condition(vbox)

	# ---- Buttons ----
	_build_buttons(vbox)

	# ---- CompletePanel ----
	_build_complete_panel(vbox)

	# ---- ParticleContainer (不在 VBox 内) ----
	_particle_container = Node2D.new()
	_particle_container.name = "ParticleContainer"
	_particle_container.visible = false
	add_child(_particle_container)

func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.name = "Header"
	header.alignment = BoxContainer.ALIGNMENT_CENTER

	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "← 返回"
	_back_button.add_theme_font_size_override("font_size", 14)
	_back_button.pressed.connect(_on_back_pressed)
	header.add_child(_back_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "进化"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(_title_label)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer2)

	# 占位，保持对称
	var right_spacer := Label.new()
	right_spacer.text = ""
	right_spacer.custom_minimum_size = Vector2(50, 0)
	header.add_child(right_spacer)

	parent.add_child(header)

func _build_evolve_section(parent: VBoxContainer) -> void:
	var section := HBoxContainer.new()
	section.name = "EvolveSection"
	section.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_theme_constant_override("separation", 20)

	_current_monster_container = VBoxContainer.new()
	_current_monster_container.name = "CurrentMonsterContainer"
	_current_monster_container.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(_current_monster_container)

	_evolve_arrow = Label.new()
	_evolve_arrow.name = "EvolveArrow"
	_evolve_arrow.text = "→"
	_evolve_arrow.add_theme_font_size_override("font_size", 28)
	_evolve_arrow.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	section.add_child(_evolve_arrow)

	_evolved_monster_container = VBoxContainer.new()
	_evolved_monster_container.name = "EvolvedMonsterContainer"
	_evolved_monster_container.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(_evolved_monster_container)

	parent.add_child(section)

func _build_condition(parent: VBoxContainer) -> void:
	_condition_container = PanelContainer.new()
	_condition_container.name = "ConditionContainer"

	var cond_style := StyleBoxFlat.new()
	cond_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	cond_style.corner_radius_top_left = 8
	cond_style.corner_radius_top_right = 8
	cond_style.corner_radius_bottom_left = 8
	cond_style.corner_radius_bottom_right = 8
	cond_style.content_margin_left = 12
	cond_style.content_margin_top = 8
	cond_style.content_margin_right = 12
	cond_style.content_margin_bottom = 8
	_condition_container.add_theme_stylebox_override("panel", cond_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)

	_condition_label = Label.new()
	_condition_label.name = "ConditionLabel"
	_condition_label.text = ""
	_condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_condition_label.add_theme_font_size_override("font_size", 14)
	margin.add_child(_condition_label)

	_condition_container.add_child(margin)
	parent.add_child(_condition_container)

func _build_buttons(parent: VBoxContainer) -> void:
	var btn_container := HBoxContainer.new()
	btn_container.name = "Buttons"
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER

	_evolve_button = Button.new()
	_evolve_button.name = "EvolveButton"
	_evolve_button.text = "✨ 开始进化 ✨"
	_evolve_button.custom_minimum_size = Vector2(200, 45)
	_evolve_button.add_theme_font_size_override("font_size", 16)
	_evolve_button.pressed.connect(_on_evolve_pressed)
	btn_container.add_child(_evolve_button)

	parent.add_child(btn_container)

func _build_complete_panel(parent: VBoxContainer) -> void:
	_complete_panel = PanelContainer.new()
	_complete_panel.name = "CompletePanel"
	_complete_panel.visible = false

	var complete_style := StyleBoxFlat.new()
	complete_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	complete_style.corner_radius_top_left = 12
	complete_style.corner_radius_top_right = 12
	complete_style.corner_radius_bottom_left = 12
	complete_style.corner_radius_bottom_right = 12
	complete_style.content_margin_left = 16
	complete_style.content_margin_top = 16
	complete_style.content_margin_right = 16
	complete_style.content_margin_bottom = 16
	_complete_panel.add_theme_stylebox_override("panel", complete_style)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"

	_complete_vbox = VBoxContainer.new()
	_complete_vbox.name = "VBox"
	_complete_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_complete_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(_complete_vbox)

	_complete_panel.add_child(margin)
	parent.add_child(_complete_panel)

# ============ 数据初始化 ============
func _init_data() -> void:
	pass

func init(data: Dictionary = {}) -> void:
	# print("[SceneEvolve] 进化场景初始化")

	_game = get_node_or_null("/root/GameManager")
	_storage = get_node_or_null("/root/SaveManager")

	instance_id = str(data.get("instanceId", ""))
	monster_id = str(data.get("monsterId", ""))
	if instance_id.is_empty() and not monster_id.is_empty() and _storage and _storage.has_method("get_instances_by_monster_id"):
		var instances: Array = _storage.get_instances_by_monster_id(monster_id)
		if not instances.is_empty():
			instance_id = str((instances[0] as Dictionary).get("instanceId", ""))
	if not instance_id.is_empty() and _storage and _storage.has_method("get_monster_instance"):
		var instance: Dictionary = _storage.get_monster_instance(instance_id)
		if not instance.is_empty():
			monster_id = str(instance.get("monsterId", monster_id))

	# 重置动画状态
	anim_state = {
		"progress": 0.0,
		"particles": [],
		"is_evolving": false,
		"evolve_complete": false
	}
	evolution_report = {}

	# 获取精灵数据
	var MonsterDB = load("res://src/data/monster_db.gd")
	if monster_id and MonsterDB:
		monster_data = MonsterDB.get_monster(monster_id).duplicate()
		if monster_data.is_empty():
			monster_data = {}
			evolve_data = {}
			evolved_monster = {}
		else:
			evolve_data = monster_data.get("evolution", {})
			var target_id = evolve_data.get("target", "")
			if target_id:
				evolved_monster = MonsterDB.get_monster(target_id).duplicate()
			else:
				evolved_monster = {}
	else:
		monster_data = {}
		evolve_data = {}
		evolved_monster = {}

	_update_evolve_condition()
	_update_ui()

func _process(delta: float) -> void:
	if anim_state["is_evolving"] and not anim_state["evolve_complete"]:
		anim_state["progress"] += delta * 1.5

		# 更新粒子
		var particles: Array = anim_state["particles"]
		for p in particles:
			p["x"] += (p["tx"] - p["x"]) * 0.1
			p["y"] += (p["ty"] - p["y"]) * 0.1
			p["life"] -= delta * 0.8

		# 更新粒子容器
		_update_particles()

		if anim_state["progress"] >= 1.0:
			anim_state["progress"] = 1.0
			_execute_evolution()

# ============ UI 更新 ============
func _update_ui() -> void:
	_update_monster_cards()
	_update_condition()
	_update_buttons()

func _update_monster_cards() -> void:
	# 当前形态卡片
	_update_monster_card(_current_monster_container, monster_data)

	# 进化后形态卡片
	_update_monster_card(_evolved_monster_container, evolved_monster)

	# 箭头和进化后容器的可见性
	_evolve_arrow.visible = not evolved_monster.is_empty()
	_evolved_monster_container.visible = not evolved_monster.is_empty()

func _update_monster_card(container: VBoxContainer, data: Dictionary) -> void:
	# 清空容器
	for child in container.get_children():
		child.queue_free()

	if data.is_empty():
		var empty := Label.new()
		empty.text = "无数据"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(empty)
		return

	# 精灵卡片面板
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 140)

	var theme := _get_element_color(data.get("element", "fire"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = theme
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Emoji
	var emoji := Label.new()
	emoji.text = data.get("emoji", "❓")
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.add_theme_font_size_override("font_size", 36)
	vbox.add_child(emoji)

	# 名字
	var name := Label.new()
	name.text = data.get("name", "未知")
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name)

	# 稀有度
	var rarity: int = data.get("rarity", 1)
	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 10)
	vbox.add_child(stars)

	# 属性标签
	var element: String = data.get("element", "fire")
	var element_lbl := Label.new()
	element_lbl.text = ELEMENT_NAMES.get(element, element)
	element_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_lbl.add_theme_font_size_override("font_size", 10)

	var element_style := StyleBoxFlat.new()
	element_style.bg_color = theme
	element_style.corner_radius_top_left = 4
	element_style.corner_radius_top_right = 4
	element_style.corner_radius_bottom_left = 4
	element_style.corner_radius_bottom_right = 4
	element_lbl.add_theme_stylebox_override("normal", element_style)
	vbox.add_child(element_lbl)

	container.add_child(card)

func _update_condition() -> void:
	if _condition_label:
		_condition_label.text = condition_text
		if can_evolve:
			_condition_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3, 1.0))  # success
		else:
			_condition_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))  # danger

func _update_buttons() -> void:
	if _evolve_button:
		if can_evolve and not anim_state["evolve_complete"]:
			_evolve_button.text = "✨ 开始进化 ✨"
			_evolve_button.disabled = false
		else:
			_evolve_button.text = "条件不足" if not can_evolve else "返回图鉴"
			_evolve_button.disabled = can_evolve

func _update_evolve_condition() -> void:
	if monster_data.is_empty() or evolve_data.is_empty():
		can_evolve = false
		condition_text = "无法进化"
		return

	# 检查等级条件
	var monster_level := 1
	if _storage and _storage.has_method("get_instance_level") and not instance_id.is_empty():
		monster_level = _storage.get_instance_level(instance_id)
	elif _storage and _storage.has_method("get_monster_level"):
		monster_level = _storage.get_monster_level(monster_id)

	var level_required: int = evolve_data.get("level", 10)
	var level_ok := monster_level >= level_required

	# 检查道具条件
	var required_item: String = evolve_data.get("item", _get_default_evolution_item(monster_id))
	var item_count := 0
	if _storage and _storage.has_method("get_item_count"):
		item_count = _storage.get_item_count(required_item)
	var item_ok := item_count > 0

	can_evolve = level_ok and item_ok

	# 条件文本
	var level_req := "需要 Lv.%d" % level_required
	var ItemDB = load("res://src/data/item_db.gd")
	var item_name := "进化道具"
	if ItemDB:
		var item_data = ItemDB.get_item(required_item)
		if item_data:
			item_name = item_data.get("name", "进化道具")
	var item_req := "%s ×1" % item_name

	if not level_ok and not item_ok:
		condition_text = "%s + %s" % [level_req, item_req]
	elif not level_ok:
		condition_text = "%s（当前 Lv.%d）" % [level_req, monster_level]
	elif not item_ok:
		condition_text = "%s（背包 %d 个）" % [item_req, item_count]
	else:
		condition_text = "✅ 满足进化条件！"
	var preview := _get_evolution_preview()
	if not preview.is_empty():
		condition_text += "\n%s\n玩法: %s\n%s" % [
			str(preview.get("stat_summary", "")),
			str(preview.get("play_upgrade", "稳定成长")),
			str(preview.get("social_text", "社交启发: 无"))
		]

func _get_default_evolution_item(monster_id: String) -> String:
	var monster_data_local = _get_monster_data_local(monster_id)
	var element: String = monster_data_local.get("element", "fire") if not monster_data_local.is_empty() else "fire"
	var map: Dictionary = {
		"fire": "evolution_stone_fire",
		"water": "evolution_stone_water",
		"grass": "evolution_stone_grass",
		"thunder": "evolution_stone_thunder",
		"light": "evolution_stone_light",
		"earth": "evolution_stone_earth",
		"wind": "evolution_stone_wind",
		"dark": "evolution_stone_dark"
	}
	return map.get(element, "evolution_stone_fire")

func _get_monster_data_local(monster_id: String) -> Dictionary:
	var MonsterDB = load("res://src/data/monster_db.gd")
	if MonsterDB == null:
		return {}
	var data = MonsterDB.get_monster(monster_id)
	if data == null:
		return {}
	return data

func _get_evolution_preview() -> Dictionary:
	if _storage and _storage.has_method("get_monster_instance") and not instance_id.is_empty():
		var instance: Dictionary = _storage.get_monster_instance(instance_id)
		return EvolutionRulesScript.build_preview(instance)
	return EvolutionRulesScript.build_preview({
		"instanceId": instance_id,
		"monsterId": monster_id,
		"level": 1,
		"nature": "",
		"evolutionInsight": {}
	})

# ============ 进化逻辑 ============
func _on_evolve_pressed() -> void:
	if anim_state["evolve_complete"]:
		_switch_scene("album", {}, "slide")
		return

	if can_evolve and not anim_state["is_evolving"]:
		_start_evolution()

func _start_evolution() -> void:
	anim_state["is_evolving"] = true
	anim_state["progress"] = 0.0

	# 生成粒子
	anim_state["particles"] = []
	var cx := DESIGN_W / 2.0
	var cy := DESIGN_H / 2.0 - 30.0
	var theme_color := _get_element_color(monster_data.get("element", "fire"))

	for i in range(30):
		var angle := (float(i) / 30.0) * TAU
		var dist := 80.0 + randf() * 60.0
		anim_state["particles"].append({
			"x": cx,
			"y": cy,
			"tx": cx + cos(angle) * dist,
			"ty": cy + sin(angle) * dist,
			"life": 1.0,
			"size": 4.0 + randf() * 6.0,
			"color": theme_color
		})

	_particle_container.visible = true
	_update_particles()

func _update_particles() -> void:
	# 清空现有粒子
	for child in _particle_container.get_children():
		child.queue_free()

	var particles: Array = anim_state["particles"]
	for p in particles:
		if p["life"] <= 0:
			continue
		var label := Label.new()
		label.text = "✨"
		label.global_position = Vector2(p["x"], p["y"])
		var alpha: float = p["life"]
		label.modulate = Color(1, 1, 1, alpha)
		_particle_container.add_child(label)

func _execute_evolution() -> void:
	if not can_evolve or evolved_monster.is_empty():
		return

	# 消耗道具
	var required_item: String = evolve_data.get("item", _get_default_evolution_item(monster_id))
	if _storage and _storage.has_method("use_item"):
		_storage.use_item(required_item, 1)

	if _storage and _storage.has_method("evolve_instance") and not instance_id.is_empty():
		var result: Dictionary = _storage.evolve_instance(instance_id)
		if not bool(result.get("ok", false)):
			can_evolve = false
			condition_text = "进化失败：%s" % str(result.get("reason", "unknown"))
			_update_condition()
			return
		evolution_report = result.get("evolutionReport", {})
	else:
		# 兼容旧入口：没有实例时不再直接改写 captured/team/pokedex，避免破坏精灵池。
		can_evolve = false
		condition_text = "缺少精灵实例"
		_update_condition()
		return

	if _storage and _storage.has_method("add_achievement_progress"):
		_storage.add_achievement_progress("evolveCount", 1)

	anim_state["evolve_complete"] = true
	_update_complete_ui()

func _update_complete_ui() -> void:
	# 隐藏普通界面
	_current_monster_container.visible = false
	_evolve_arrow.visible = false
	_evolved_monster_container.visible = false
	_condition_container.visible = false
	_evolve_button.visible = false

	# 显示完成面板
	_complete_panel.visible = true

	# 清空并重建完成面板内容
	for child in _complete_vbox.get_children():
		child.queue_free()

	# 成功提示
	var title := Label.new()
	title.text = "🎉 进化成功！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))
	_complete_vbox.add_child(title)

	# 进化后的精灵卡片
	_update_monster_card_to_container(_complete_vbox, evolved_monster)

	# 属性变化
	var stats_panel := PanelContainer.new()
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_top_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_vbox)

	var name_change := Label.new()
	name_change.text = "%s → %s" % [monster_data.get("name", "?"), evolved_monster.get("name", "?")]
	name_change.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_vbox.add_child(name_change)

	var stats_title := Label.new()
	stats_title.text = "HP / ATK / DEF / SPD"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_vbox.add_child(stats_title)

	var old_stats := "%s/%s/%s/%s" % [
		monster_data.get("baseHP", 0),
		monster_data.get("baseATK", 0),
		monster_data.get("baseDEF", 0),
		monster_data.get("baseSPD", 0)
	]
	var new_stats := "%s/%s/%s/%s" % [
		evolved_monster.get("baseHP", 0),
		evolved_monster.get("baseATK", 0),
		evolved_monster.get("baseDEF", 0),
		evolved_monster.get("baseSPD", 0)
	]

	var old_lbl := Label.new()
	old_lbl.text = "基础: %s" % old_stats
	old_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_vbox.add_child(old_lbl)

	var new_lbl := Label.new()
	new_lbl.text = "进化后: %s" % new_stats
	new_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3, 1.0))
	stats_vbox.add_child(new_lbl)

	_complete_vbox.add_child(stats_panel)

	if not evolution_report.is_empty():
		var play_lbl := Label.new()
		play_lbl.text = "玩法变化: %s" % str(evolution_report.get("play_upgrade", "稳定成长"))
		play_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		play_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		play_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 1.0, 1.0))
		_complete_vbox.add_child(play_lbl)

		var social_lbl := Label.new()
		social_lbl.text = str(evolution_report.get("social_text", "社交启发: 无"))
		social_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		social_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		social_lbl.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55, 1.0))
		_complete_vbox.add_child(social_lbl)

	# 返回按钮
	var return_btn := Button.new()
	return_btn.text = "返回牧场"
	return_btn.pressed.connect(_on_return_to_album)
	_complete_vbox.add_child(return_btn)

func _update_monster_card_to_container(container: VBoxContainer, data: Dictionary) -> void:
	# 与 _update_monster_card 逻辑相同，但用于指定容器
	if data.is_empty():
		var empty := Label.new()
		empty.text = "无数据"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(empty)
		return

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 140)

	var theme := _get_element_color(data.get("element", "fire"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = theme
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var emoji := Label.new()
	emoji.text = data.get("emoji", "❓")
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.add_theme_font_size_override("font_size", 36)
	vbox.add_child(emoji)

	var name := Label.new()
	name.text = data.get("name", "未知")
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name)

	var rarity: int = data.get("rarity", 1)
	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 10)
	vbox.add_child(stars)

	var element: String = data.get("element", "fire")
	var element_lbl := Label.new()
	element_lbl.text = ELEMENT_NAMES.get(element, element)
	element_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_lbl.add_theme_font_size_override("font_size", 10)

	var element_style := StyleBoxFlat.new()
	element_style.bg_color = theme
	element_style.corner_radius_top_left = 4
	element_style.corner_radius_top_right = 4
	element_style.corner_radius_bottom_left = 4
	element_style.corner_radius_bottom_right = 4
	element_lbl.add_theme_stylebox_override("normal", element_style)
	vbox.add_child(element_lbl)

	container.add_child(card)

func _on_return_to_album() -> void:
	_switch_scene("ranch", {}, "slide")

# ============ 事件处理 ============
func _on_back_pressed() -> void:
	_switch_scene("ranch", {}, "slide")

# ============ 工具方法 ============
func _switch_scene(scene_name: String, data: Dictionary = {}, transition: String = "fade") -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager != null and scene_manager.has_method("switch_scene"):
		scene_manager.switch_scene(scene_name, data, transition)

func _get_element_color(element: String) -> Color:
	var colors: Dictionary = {
		"fire": Color(0.9, 0.3, 0.2, 1.0),
		"water": Color(0.2, 0.5, 0.9, 1.0),
		"grass": Color(0.2, 0.8, 0.3, 1.0),
		"thunder": Color(0.9, 0.8, 0.2, 1.0),
		"light": Color(1.0, 0.9, 0.3, 1.0),
		"earth": Color(0.7, 0.5, 0.3, 1.0),
		"wind": Color(0.4, 0.8, 0.9, 1.0),
		"dark": Color(0.5, 0.3, 0.7, 1.0)
	}
	return colors.get(element, Color(0.5, 0.5, 0.5, 1.0))

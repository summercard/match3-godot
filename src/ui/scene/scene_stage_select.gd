# scene_stage_select.gd - 关卡选择场景（章节分页版）
# 源文件: js/ui/sceneStageSelect.js
# 翻译版本: GDScript 4.x
# 重构: 移除 @onready，改为 _create_ui() 动态创建
class_name SceneStageSelect
extends Control

# === 静态常量 ===
const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0

const MAP_NODE_POSITIONS: Array[Vector2] = [
	Vector2(62, 500), Vector2(96, 420), Vector2(144, 358), Vector2(202, 386),
	Vector2(276, 350), Vector2(268, 292), Vector2(188, 292), Vector2(106, 238),
	Vector2(116, 176), Vector2(178, 128)
]
const MAP_BOSS_POSITION: Vector2 = Vector2(292, 158)
const BOSS_LAYOUT_DEFAULT := {
	"position": MAP_BOSS_POSITION,
	"card_size": Vector2(118.0, 126.0),
	"badge_path": "res://assets/images/stage/boss_badge.png",
	"badge_rect": Rect2(-63.0, -74.0, 126.0, 142.0),
	"art_rect": Rect2(-57.0, -97.0, 114.0, 102.0),
	"label_y": 25.0,
	"stars_y": 45.0
}
const CHAPTER_BOSS_LAYOUT_OVERRIDES := {
	"chapter_8": {
		"position": Vector2(282.0, 182.0),
		"card_size": Vector2(204.0, 224.0),
		"badge_path": "res://assets/images/stage/chapter_08_temporal/boss_badge_temporal.png",
		"badge_rect": Rect2(-101.0, -132.0, 202.0, 268.0),
		"art_rect": Rect2(-98.0, -134.0, 196.0, 176.0),
		"label_y": 84.0,
		"stars_y": 108.0
	},
	"chapter_9": {
		"position": Vector2(274.0, 182.0),
		"card_size": Vector2(208.0, 236.0),
		"badge_path": "res://assets/images/stage/chapter_09_star/boss_badge_star.png",
		"art_path": "res://assets/images/stage/chapter_09_star/boss_star_dragon.png",
		"badge_rect": Rect2(-104.0, -148.0, 208.0, 304.0),
		"art_rect": Rect2(-102.0, -142.0, 204.0, 184.0),
		"label_y": 90.0,
		"stars_y": 114.0
	}
}
const STAGE_NODE_ASSETS_DEFAULT := {
	"node_normal": "res://assets/images/stage/node_normal.png",
	"node_selected": "res://assets/images/stage/node_selected.png",
	"node_crystal": "res://assets/images/stage/node_crystal.png",
	"node_chest": "res://assets/images/stage/node_chest.png",
	"node_locked": "res://assets/images/stage/node_locked.png"
}
const CHAPTER_STAGE_NODE_ASSET_OVERRIDES := {
	"chapter_8": {
		"node_normal": "res://assets/images/stage/chapter_08_temporal/node_temporal_normal.png",
		"node_selected": "res://assets/images/stage/chapter_08_temporal/node_temporal_selected.png",
		"node_crystal": "res://assets/images/stage/chapter_08_temporal/node_temporal_elite.png"
	},
	"chapter_9": {
		"node_normal": "res://assets/images/stage/chapter_09_star/node_star_normal.png",
		"node_selected": "res://assets/images/stage/chapter_09_star/node_star_selected.png",
		"node_crystal": "res://assets/images/stage/chapter_09_star/node_star_elite.png"
	}
}
const CHAPTER_STAGE_NODE_SIZE_OVERRIDES := {
	"chapter_8": {
		"normal": Vector2(78.0, 62.0),
		"elite": Vector2(80.0, 98.0)
	},
	"chapter_9": {
		"normal": Vector2(80.0, 64.0),
		"elite": Vector2(82.0, 100.0)
	}
}
const MAP_CONTENT_TOP: float = 78.0
const MAP_REWARD_TOP: float = 566.0
const HEADER_BAR_RECT: Rect2 = Rect2(76.0, 12.0, 286.0, 66.0)
const HEADER_BADGE_RECT: Rect2 = Rect2(84.0, 21.0, 38.0, 42.0)
const HEADER_TITLE_RECT: Rect2 = Rect2(126.0, 23.0, 190.0, 22.0)
const HEADER_CHAPTER_TEXT_RECT: Rect2 = Rect2(126.0, 23.0, 64.0, 22.0)
const HEADER_NAME_TEXT_RECT: Rect2 = Rect2(236.0, 23.0, 80.0, 22.0)
const HEADER_STAR_RECT: Rect2 = Rect2(147.0, 52.0, 18.0, 18.0)
const HEADER_STAR_TEXT_RECT: Rect2 = Rect2(169.0, 50.0, 74.0, 22.0)
const HEADER_PREV_RECT: Rect2 = Rect2(DESIGN_W - 89.0, 30.0, 34.0, 34.0)
const HEADER_NEXT_RECT: Rect2 = Rect2(DESIGN_W - 49.0, 30.0, 34.0, 34.0)
const REWARD_PANEL_RECT: Rect2 = Rect2(17.0, MAP_REWARD_TOP, DESIGN_W - 34.0, 84.0)
const REWARD_SLOT_SIZE: Vector2 = Vector2(32.0, 34.0)
const REWARD_SLOT_GAP: float = 7.0
const SWEEP_DIALOG_W: float = 270.0
const SWEEP_DIALOG_H: float = 190.0

const MAP_STAGE_POSITION_PRESETS := {
	4: [
		Vector2(74, 500), Vector2(134, 385), Vector2(278, 366),
		Vector2(194, 282)
	],
	5: [
		Vector2(78, 500), Vector2(118, 418), Vector2(176, 326),
		Vector2(276, 346), Vector2(168, 218)
	]
}

const CHAPTER_THEME_BACKGROUNDS := {
	"grass": "res://assets/images/stage/stage_map_bg_grass.png",
	"fire": "res://assets/images/stage/stage_map_bg_fire.png",
	"dark": "res://assets/images/stage/stage_map_bg_dark.png",
	"thunder": "res://assets/images/stage/stage_map_bg_thunder.png",
	"ice": "res://assets/images/stage/stage_map_bg_ice.png",
	"void": "res://assets/images/stage/stage_map_bg_void.png",
	"temporal": "res://assets/images/stage/stage_map_bg_temporal.png",
	"star": "res://assets/images/stage/stage_map_bg_star.png",
	"chaos": "res://assets/images/stage/stage_map_bg_chaos.png",
	"light": "res://assets/images/stage/stage_map_bg_light.png"
}

const CHAPTER_BACKGROUND_OVERRIDES := {
	"chapter_3": "res://assets/images/stage/stage_map_bg_chapter_03_mystic_forest.png",
	"chapter_4": "res://assets/images/stage/stage_map_bg_chapter_04_eclipse_canopy.png",
	"chapter_5": "res://assets/images/stage/stage_map_bg_chapter_05_thunder_temple.png",
	"chapter_6": "res://assets/images/stage/stage_map_bg_chapter_06_frost_throne.png",
	"chapter_7": "res://assets/images/stage/stage_map_bg_chapter_07_void_domain.png",
	"chapter_8": "res://assets/images/stage/stage_map_bg_chapter_08_temporal_rift.png",
	"chapter_9": "res://assets/images/stage/stage_map_bg_chapter_09_starlit_temple.png"
}

const CHAPTER_THEME_TINTS := {
	"grass": Color(0.30, 0.95, 0.34),
	"fire": Color(1.0, 0.45, 0.16),
	"dark": Color(0.76, 0.44, 1.0),
	"thunder": Color(1.0, 0.82, 0.15),
	"ice": Color(0.42, 0.86, 1.0),
	"void": Color(0.76, 0.34, 1.0),
	"temporal": Color(0.35, 0.95, 0.95),
	"star": Color(0.92, 0.82, 1.0),
	"chaos": Color(1.0, 0.30, 0.22),
	"light": Color(1.0, 0.92, 0.55)
}

const CHAPTER_BOSS_ART := {
	"grass": "res://assets/images/stage/boss_flower.png",
	"fire": "res://assets/images/battle/monsters/monster_boss_002_fire.png",
	"water": "res://assets/images/battle/monsters/monster_boss_003_water.png",
	"dark": "res://assets/images/battle/monsters/monster_boss_004_dark.png",
	"thunder": "res://assets/images/battle/monsters/monster_boss_005_thunder.png",
	"ice": "res://assets/images/battle/monsters/monster_boss_006_ice.png",
	"void": "res://assets/images/battle/monsters/monster_boss_007_void.png",
	"temporal": "res://assets/images/battle/monsters/monster_boss_008_temporal.png",
	"star": "res://assets/images/battle/monsters/monster_boss_009_star.png",
	"chaos": "res://assets/images/battle/monsters/monster_boss_010_chaos.png",
	"light": "res://assets/images/battle/monsters/monster_boss_011_light.png"
}

const REWARD_ITEMS: Array[Dictionary] = [
	{"key": "gold_coin", "count": "x500"},
	{"key": "exp_badge", "count": "x200"},
	{"key": "capture_ball", "count": "x1"},
	{"key": "gem_fire", "count": "x2"},
	{"key": "gem_water", "count": "x2"},
	{"key": "gem_grass", "count": "x2"},
	{"key": "gem_thunder", "count": "x2"},
	{"key": "gem_light", "count": "x1"}
]

const REWARD_ICON_PATHS := {
	"gold_coin": "res://assets/images/main/icon_gold_v2.png",
	"exp_badge": "res://assets/images/main/icon_exp_star.png",
	"capture_ball": "res://assets/images/items_new/icon_capture_ball.png",
	"gem_fire": "res://assets/images/battle/gems/gem_fire.png",
	"gem_water": "res://assets/images/battle/gems/gem_water.png",
	"gem_grass": "res://assets/images/battle/gems/gem_grass.png",
	"gem_thunder": "res://assets/images/battle/gems/gem_thunder.png",
	"gem_light": "res://assets/images/battle/gems/gem_light.png"
}

# === 成员变量（替代 @onready）===
var _back_btn: TextureButton
var _header_panel: PanelContainer
var _chapter_title: Label
var _chapter_name_label: Label
var _star_label: Label
var _prev_chapter_btn: TextureButton
var _next_chapter_btn: TextureButton
var _stage_container: Control
var _reward_panel: PanelContainer
var _dots_container: HBoxContainer
var _sweep_dialog: Control
var _sweep_anim_overlay: Control

# SweepDialog 内部子节点
var _sweep_title_label: Label
var _sweep_gold_label: Label
var _sweep_exp_label: Label
var _sweep_rule_label: Label
var _sweep_confirm_btn: Button
var _sweep_cancel_btn: Button

# SweepAnimOverlay 内部子节点
var _sweep_anim_title_label: Label
var _sweep_anim_gold_label: Label
var _sweep_anim_exp_label: Label

# === 信号 ===
signal stage_selected(stage_id: String, stage_data: Dictionary, chapter_index: int)
signal back_pressed

# === 成员变量 ===
var _game: Node = null
var _storage = null
var _chapters: Array = []
var _current_chapter_index: int = 0
var _cards: Array = []
var _touched_btn: Variant = null  # 可以是 String 或 null

# 扫荡确认弹窗
var _sweep_dialog_active: bool = false
var _sweep_dialog_stage_id: String = ""
var _sweep_dialog_stage_name: String = ""
var _sweep_dialog_reward: Dictionary = {}
var _sweep_dialog_stars: int = 0

# 扫荡动画
var _sweep_anim_active: bool = false
var _sweep_anim_progress: float = 0.0
var _sweep_anim_gold: int = 0
var _sweep_anim_exp: int = 0

# 章节切换动画
var _chapter_anim_active: bool = false
var _chapter_anim_progress: float = 0.0
var _chapter_anim_direction: int = 1  # 1=向左（下一章）, -1=向右（上一章）

# 美术资源字典（图片路径 → Texture）
var _art_assets: Dictionary = {}
var _art_ready: bool = false
var _art_loading_started: bool = false
var _texture_cache: Dictionary = {}

var _bg_texture: TextureRect

func _add_background(image_path: String) -> void:
	if not ResourceLoader.exists(image_path):
		return
	_bg_texture = TextureRect.new()
	_bg_texture.texture = load(image_path)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

# === 阶段控制 ===
var _phase: String = "idle"  # idle | dialog | anim

# ==================== 生命周期 ====================

func _ready() -> void:
	name = "SceneStageSelect"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	_sweep_dialog_active = false
	_sweep_anim_active = false
	_chapter_anim_active = false
	_create_ui()
	set_process(false)

func _process(delta: float) -> void:
	var was_animating := _chapter_anim_active or _sweep_anim_active
	_update_chapter_animation(delta)
	_update_sweep_animation(delta)
	if was_animating:
		queue_redraw()
	if not _chapter_anim_active and not _sweep_anim_active:
		set_process(false)

# ==================== UI 创建 ====================

func _create_ui() -> void:
	# BackBtn（左上角返回）
	_back_btn = TextureButton.new()
	_back_btn.name = "BackBtn"
	_back_btn.custom_minimum_size = Vector2(50, 50)
	_back_btn.position = Vector2(10, 10)
	_back_btn.pressed.connect(_on_back_btn_pressed)
	_back_btn.visible = false
	add_child(_back_btn)
	
	# HeaderPanel
	_header_panel = PanelContainer.new()
	_header_panel.name = "HeaderPanel"
	_header_panel.position = Vector2(0, 0)
	_header_panel.size = Vector2(DESIGN_W, 80)
	_header_panel.visible = false
	add_child(_header_panel)
	
	var header_vbox: VBoxContainer = VBoxContainer.new()
	_header_panel.add_child(header_vbox)
	
	# ChapterTitle
	_chapter_title = Label.new()
	_chapter_title.name = "ChapterTitle"
	_chapter_title.text = "第1章"
	_chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_title.add_theme_font_size_override("font_size", 18)
	header_vbox.add_child(_chapter_title)
	
	# ChapterName
	_chapter_name_label = Label.new()
	_chapter_name_label.name = "ChapterName"
	_chapter_name_label.text = ""
	_chapter_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_name_label.add_theme_font_size_override("font_size", 14)
	header_vbox.add_child(_chapter_name_label)
	
	# StarLabel
	_star_label = Label.new()
	_star_label.name = "StarLabel"
	_star_label.text = "0/3"
	_star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_star_label.add_theme_font_size_override("font_size", 12)
	header_vbox.add_child(_star_label)
	
	# PrevChapterBtn 和 NextChapterBtn
	var btn_container: HBoxContainer = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_child(btn_container)
	
	_prev_chapter_btn = TextureButton.new()
	_prev_chapter_btn.name = "PrevChapterBtn"
	_prev_chapter_btn.custom_minimum_size = Vector2(32, 32)
	_prev_chapter_btn.pressed.connect(_on_prev_chapter_btn_pressed)
	btn_container.add_child(_prev_chapter_btn)
	
	var spacer1: Control = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_container.add_child(spacer1)
	
	_next_chapter_btn = TextureButton.new()
	_next_chapter_btn.name = "NextChapterBtn"
	_next_chapter_btn.custom_minimum_size = Vector2(32, 32)
	_next_chapter_btn.pressed.connect(_on_next_chapter_btn_pressed)
	btn_container.add_child(_next_chapter_btn)
	
	# DotsContainer
	_dots_container = HBoxContainer.new()
	_dots_container.name = "DotsContainer"
	_dots_container.alignment = HBoxContainer.ALIGNMENT_CENTER
	header_vbox.add_child(_dots_container)
	
	# StageContainer
	_stage_container = Control.new()
	_stage_container.name = "StageContainer"
	_stage_container.custom_minimum_size = Vector2(DESIGN_W, DESIGN_H)
	_stage_container.size = Vector2(DESIGN_W, DESIGN_H)
	_stage_container.visible = false
	add_child(_stage_container)
	
	# RewardPanel
	_reward_panel = PanelContainer.new()
	_reward_panel.name = "RewardPanel"
	_reward_panel.position = Vector2(0, DESIGN_H - 120)
	_reward_panel.size = Vector2(DESIGN_W, 120)
	_reward_panel.visible = false
	add_child(_reward_panel)
	
	# SweepDialog
	_sweep_dialog = Control.new()
	_sweep_dialog.name = "SweepDialog"
	_sweep_dialog.custom_minimum_size = Vector2(SWEEP_DIALOG_W, SWEEP_DIALOG_H)
	_sweep_dialog.position = Vector2((DESIGN_W - SWEEP_DIALOG_W) / 2.0, (DESIGN_H - SWEEP_DIALOG_H) / 2.0)
	_sweep_dialog.visible = false
	add_child(_sweep_dialog)
	
	var sweep_vbox: VBoxContainer = VBoxContainer.new()
	sweep_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sweep_vbox.position = Vector2(0, 16)
	sweep_vbox.custom_minimum_size = Vector2(SWEEP_DIALOG_W, 150)
	_sweep_dialog.add_child(sweep_vbox)
	
	_sweep_title_label = Label.new()
	_sweep_title_label.name = "TitleLabel"
	_sweep_title_label.text = "确认扫荡"
	_sweep_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sweep_vbox.add_child(_sweep_title_label)
	
	_sweep_gold_label = Label.new()
	_sweep_gold_label.name = "GoldLabel"
	_sweep_gold_label.text = "+120 金币"
	_sweep_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sweep_vbox.add_child(_sweep_gold_label)

	_sweep_exp_label = Label.new()
	_sweep_exp_label.name = "ExpLabel"
	_sweep_exp_label.text = "+0 经验"
	_sweep_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sweep_vbox.add_child(_sweep_exp_label)

	_sweep_rule_label = Label.new()
	_sweep_rule_label.name = "RuleLabel"
	_sweep_rule_label.text = "3 星扫荡收益 80%"
	_sweep_rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sweep_rule_label.add_theme_font_size_override("font_size", 11)
	sweep_vbox.add_child(_sweep_rule_label)
	
	var sweep_btn_container: HBoxContainer = HBoxContainer.new()
	sweep_btn_container.alignment = HBoxContainer.ALIGNMENT_CENTER
	sweep_btn_container.custom_minimum_size = Vector2(220, 40)
	sweep_vbox.add_child(sweep_btn_container)
	
	_sweep_confirm_btn = Button.new()
	_sweep_confirm_btn.name = "ConfirmBtn"
	_sweep_confirm_btn.text = "确认"
	_sweep_confirm_btn.custom_minimum_size = Vector2(100, 40)
	_sweep_confirm_btn.pressed.connect(_do_sweep_confirm)
	sweep_btn_container.add_child(_sweep_confirm_btn)
	
	var btn_spacer: Control = Control.new()
	btn_spacer.custom_minimum_size = Vector2(20, 1)
	sweep_btn_container.add_child(btn_spacer)
	
	_sweep_cancel_btn = Button.new()
	_sweep_cancel_btn.name = "CancelBtn"
	_sweep_cancel_btn.text = "取消"
	_sweep_cancel_btn.custom_minimum_size = Vector2(100, 40)
	_sweep_cancel_btn.pressed.connect(_on_sweep_cancel_pressed)
	sweep_btn_container.add_child(_sweep_cancel_btn)
	
	# SweepAnimOverlay
	_sweep_anim_overlay = Control.new()
	_sweep_anim_overlay.name = "SweepAnimOverlay"
	_sweep_anim_overlay.custom_minimum_size = Vector2(DESIGN_W, DESIGN_H)
	_sweep_anim_overlay.size = Vector2(DESIGN_W, DESIGN_H)
	_sweep_anim_overlay.visible = false
	add_child(_sweep_anim_overlay)
	
	var anim_vbox: VBoxContainer = VBoxContainer.new()
	anim_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	anim_vbox.custom_minimum_size = Vector2(DESIGN_W, 200)
	anim_vbox.position = Vector2(0, (DESIGN_H - 200) / 2.0)
	_sweep_anim_overlay.add_child(anim_vbox)
	
	_sweep_anim_title_label = Label.new()
	_sweep_anim_title_label.name = "TitleLabel"
	_sweep_anim_title_label.text = "扫荡完成！"
	_sweep_anim_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sweep_anim_title_label.add_theme_font_size_override("font_size", 24)
	anim_vbox.add_child(_sweep_anim_title_label)
	
	_sweep_anim_gold_label = Label.new()
	_sweep_anim_gold_label.name = "GoldLabel"
	_sweep_anim_gold_label.text = "+0 金币"
	_sweep_anim_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sweep_anim_gold_label.add_theme_font_size_override("font_size", 18)
	anim_vbox.add_child(_sweep_anim_gold_label)
	
	_sweep_anim_exp_label = Label.new()
	_sweep_anim_exp_label.name = "ExpLabel"
	_sweep_anim_exp_label.text = ""
	_sweep_anim_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sweep_anim_exp_label.add_theme_font_size_override("font_size", 16)
	anim_vbox.add_child(_sweep_anim_exp_label)

# ==================== 初始化 ====================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(event.position.x, event.position.y)
	elif event is InputEventScreenTouch and event.pressed:
		_on_tap(event.position.x, event.position.y)

func initialize(game: Node, data: Dictionary = {}) -> void:
	_game = game
	_storage = get_node_or_null("/root/SaveManager")
	if _storage == null and game and game.get("storage"):
		_storage = game.storage
	_load_stage_data()
	
	if data.has("chapterIndex") and typeof(data.chapterIndex) == TYPE_INT:
		_current_chapter_index = int(clampi(data.chapterIndex, 0, _chapters.size() - 1))
	
	_build_cards()
	_update_header()
	_update_chapter_buttons()
	_update_page_dots()

# 别名：保留 init 方法兼容
func init(data: Dictionary = {}) -> void:
	initialize(get_node_or_null("/root/GameManager"), data)

# ==================== 场景切换 ====================

func _go_to_scene(scene_name: String, params: Dictionary = {}) -> void:
	if has_node("/root/SceneManager"):
		var sm = get_node("/root/SceneManager")
		sm.switch_scene(scene_name, params)
	else:
		get_tree().change_scene_to_file("res://src/ui/scene/%s.tscn" % scene_name)

# ==================== 数据加载 ====================

func _load_stage_data() -> void:
	# 从 stage_db 获取章节数据（与 JS 版本一致）
	if _storage and _storage.has_method("get_stage_chapters"):
		_chapters = _storage.get_stage_chapters()
	else:
		_chapters = []

func _build_cards() -> void:
	_cards = []
	if _chapters.is_empty() or _current_chapter_index >= _chapters.size():
		return
	
	var chapter: Dictionary = _chapters[_current_chapter_index]
	if not chapter.has("stages"):
		return
	
	var stages: Array = chapter["stages"]
	var normal_positions := _sample_stage_positions(_count_non_boss_stages(stages))
	var node_index: int = 0
	
	for i: int in range(stages.size()):
		var stage: Dictionary = stages[i]
		var is_boss: bool = stage.get("type", "normal") == "boss"
		var is_elite: bool = stage.get("type", "normal") == "elite"
		
		var stars: int = 0
		var can_sweep: bool = false
		var unlock_state: Dictionary = {"unlocked": true}
		if _storage:
			stars = _storage.get_stage_stars(stage["id"]) if _storage.has_method("get_stage_stars") else 0
			can_sweep = _storage.can_sweep(stage["id"]) if _storage.has_method("can_sweep") else false
			if _storage.has_method("get_stage_unlock_state"):
				unlock_state = _storage.get_stage_unlock_state(stage["id"])
		
		var pos: Vector2
		var boss_layout := _boss_layout_for_chapter(str(chapter.get("id", "")))
		if is_boss:
			pos = boss_layout["position"]
		else:
			pos = normal_positions[node_index] if node_index < normal_positions.size() else MAP_NODE_POSITIONS[-1]
			node_index += 1
		
		var boss_card_size: Vector2 = boss_layout["card_size"]
		var stage_node_size := _stage_node_size_for_chapter(str(chapter.get("id", "")), is_elite)
		var node_w: float = boss_card_size.x if is_boss else stage_node_size.x
		var node_h: float = boss_card_size.y if is_boss else stage_node_size.y
		
		var card: Dictionary = {
			"type": "stage",
			"id": stage["id"],
			"text": stage.get("name", ""),
			"stage_no": i + 1,
			"x": pos.x - node_w / 2.0,
			"y": pos.y - node_h / 2.0,
			"cx": pos.x,
			"cy": pos.y,
			"w": node_w,
			"h": node_h,
			"enabled": bool(unlock_state.get("unlocked", true)),
			"chapter_id": chapter.get("id", ""),
			"stage_data": stage,
			"stars": stars,
			"can_sweep": can_sweep,
			"is_elite": is_elite,
			"is_boss": is_boss,
			"unlock_state": unlock_state,
			"sweep_rect": Rect2(pos.x + 24, pos.y - 26, 30, 26)
		}
		_cards.append(card)
	
	# 刷新显示
	_refresh_stage_nodes()
	queue_redraw()

func _count_non_boss_stages(stages: Array) -> int:
	var count := 0
	for stage: Dictionary in stages:
		if stage.get("type", "normal") != "boss":
			count += 1
	return count

func _boss_layout_for_chapter(chapter_id: String) -> Dictionary:
	var layout := BOSS_LAYOUT_DEFAULT.duplicate(true)
	if CHAPTER_BOSS_LAYOUT_OVERRIDES.has(chapter_id):
		layout.merge(CHAPTER_BOSS_LAYOUT_OVERRIDES[chapter_id], true)
	return layout

func _stage_node_size_for_chapter(chapter_id: String, is_elite: bool) -> Vector2:
	var kind := "elite" if is_elite else "normal"
	var default_size := Vector2(66.0, 76.0) if is_elite else Vector2(64.0, 54.0)
	if not CHAPTER_STAGE_NODE_SIZE_OVERRIDES.has(chapter_id):
		return default_size
	return CHAPTER_STAGE_NODE_SIZE_OVERRIDES[chapter_id].get(kind, default_size)

func _stage_node_asset_path(chapter_id: String, node_key: String) -> String:
	var paths := STAGE_NODE_ASSETS_DEFAULT.duplicate(true)
	if CHAPTER_STAGE_NODE_ASSET_OVERRIDES.has(chapter_id):
		paths.merge(CHAPTER_STAGE_NODE_ASSET_OVERRIDES[chapter_id], true)
	return str(paths.get(node_key, STAGE_NODE_ASSETS_DEFAULT["node_normal"]))

func _sample_stage_positions(count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if count <= 0:
		return result
	if MAP_STAGE_POSITION_PRESETS.has(count):
		for pos: Vector2 in MAP_STAGE_POSITION_PRESETS[count]:
			result.append(pos)
		return result
	var index_presets := {
		1: [0],
		2: [0, 6],
		3: [0, 3, 7],
		4: [0, 2, 4, 6],
		5: [0, 2, 4, 6, 8],
		6: [0, 1, 3, 5, 7, 9],
		7: [0, 1, 2, 4, 5, 7, 9],
		8: [0, 1, 2, 3, 5, 6, 8, 9],
		9: [0, 1, 2, 3, 4, 5, 6, 7, 9],
		10: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	}
	var indices: Array = index_presets.get(mini(count, 10), [])
	for idx in indices:
		result.append(MAP_NODE_POSITIONS[int(idx)])
	if count > 10:
		for i in range(10, count):
			result.append(MAP_NODE_POSITIONS[-1])
	return result

# ==================== 章节切换 ====================

func _switch_chapter(direction: int) -> void:
	var new_index: int = _current_chapter_index + direction
	if new_index < 0 or new_index >= _chapters.size():
		return
	
	_chapter_anim_active = true
	_chapter_anim_progress = 0.0
	_chapter_anim_direction = direction
	set_process(true)
	_current_chapter_index = new_index
	_build_cards()
	_update_header()
	_update_chapter_buttons()
	_update_page_dots()

# ==================== 触摸处理 ====================

func _on_touch_start(x: float, y: float) -> void:
	if _sweep_dialog_active or _sweep_anim_active or _chapter_anim_active:
		_touched_btn = null
		return
	
	# 返回按钮区域（左上角 10-60, 10-60）
	if x >= 10 and x <= 60 and y >= 10 and y <= 60:
		_touched_btn = "backBtn"
		return
	
	# 上一章按钮
	if _current_chapter_index > 0 and HEADER_PREV_RECT.has_point(Vector2(x, y)):
		_touched_btn = "prevChapter"
		return
	
	# 下一章按钮（标题栏右侧）
	if _current_chapter_index < _chapters.size() - 1:
		if HEADER_NEXT_RECT.has_point(Vector2(x, y)):
			_touched_btn = "nextChapter"
		return
	
	# 检查关卡卡片
	for card: Dictionary in _cards:
		if x >= card["x"] and x <= card["x"] + card["w"] and y >= card["y"] and y <= card["y"] + card["h"]:
			if not card.get("enabled", false):
				_touched_btn = null
				return
			_touched_btn = card["id"]
			return
	
	_touched_btn = null

func _on_touch_end() -> void:
	_touched_btn = null

func _on_tap(x: float, y: float) -> void:
	# 扫荡确认弹窗
	if _sweep_dialog_active:
		_handle_sweep_dialog_tap(x, y)
		return
	
	# 扫荡动画进行中，忽略点击
	if _sweep_anim_active:
		return
	
	# 章节切换动画中，忽略点击
	if _chapter_anim_active:
		return
	
	# 上一章按钮
	if _current_chapter_index > 0 and HEADER_PREV_RECT.has_point(Vector2(x, y)):
		_switch_chapter(-1)
		return
	
	# 下一章按钮
	if _current_chapter_index < _chapters.size() - 1:
		if HEADER_NEXT_RECT.has_point(Vector2(x, y)):
			_switch_chapter(1)
			return
		
		# 检查关卡卡片
	for card: Dictionary in _cards:
		# 扫荡按钮
		var sweep: Rect2 = card.get("sweep_rect")
		if card.get("enabled", false) and sweep and card.get("can_sweep", false):
			if x >= sweep.position.x and x <= sweep.position.x + sweep.size.x and y >= sweep.position.y and y <= sweep.position.y + sweep.size.y:
				_show_sweep_dialog(card["id"], card.get("text", ""))
				return
		
		# 关卡主体
		if x >= card["x"] and x <= card["x"] + card["w"] and y >= card["y"] and y <= card["y"] + card["h"]:
			if not card.get("enabled", false):
				return
			if card.get("type") == "stage":
				stage_selected.emit(card["id"], card.get("stage_data", {}), _current_chapter_index)
			return
	
	# 返回区域
	if x >= 10 and x <= 60 and y >= 10 and y <= 60:
		_go_to_scene("main")

# ==================== 扫荡功能 ====================

func _show_sweep_dialog(stage_id: String, stage_name: String) -> void:
	_sweep_dialog_active = true
	_sweep_dialog_stage_id = stage_id
	_sweep_dialog_stage_name = stage_name
	_sweep_dialog.visible = true
	_refresh_sweep_dialog_content()

func _handle_sweep_dialog_tap(x: float, y: float) -> void:
	var dlg_w: float = SWEEP_DIALOG_W
	var dlg_h: float = SWEEP_DIALOG_H
	var dlg_x: float = (DESIGN_W - dlg_w) / 2.0
	var dlg_y: float = (DESIGN_H - dlg_h) / 2.0
	
	var confirm_btn: Rect2 = Rect2(dlg_x + 25, dlg_y + 128, 100, 40)
	var cancel_btn: Rect2 = Rect2(dlg_x + 145, dlg_y + 128, 100, 40)
	
	if confirm_btn.has_point(Vector2(x, y)):
		_do_sweep_confirm()
		return
	if cancel_btn.has_point(Vector2(x, y)):
		_on_sweep_cancel_pressed()
		return
	if not Rect2(dlg_x, dlg_y, dlg_w, dlg_h).has_point(Vector2(x, y)):
		_on_sweep_cancel_pressed()

func _on_sweep_cancel_pressed() -> void:
	_sweep_dialog_active = false
	_sweep_dialog.visible = false
	_sweep_dialog_reward = {}
	_sweep_dialog_stars = 0

func _do_sweep_confirm() -> void:
	if not _storage:
		_on_sweep_cancel_pressed()
		return
	
	var reward: Dictionary = _storage.do_sweep(_sweep_dialog_stage_id) if _storage.has_method("do_sweep") else {}
	_on_sweep_cancel_pressed()
	
	if reward.size() > 0:
		_sweep_anim_active = true
		_sweep_anim_progress = 0.0
		_sweep_anim_gold = reward.get("gold", 0)
		_sweep_anim_exp = reward.get("exp", 0)
		_sweep_anim_overlay.visible = true
		set_process(true)
		_refresh_sweep_anim_overlay()

func _refresh_sweep_dialog_content() -> void:
	var reward: Dictionary = {}
	if _storage and _storage.has_method("get_sweep_reward"):
		reward = _storage.get_sweep_reward(_sweep_dialog_stage_id)
	_sweep_dialog_reward = reward
	_sweep_dialog_stars = _storage.get_stage_stars(_sweep_dialog_stage_id) if _storage and _storage.has_method("get_stage_stars") else 0
	
	if _sweep_title_label:
		_sweep_title_label.text = "确认扫荡: %s" % _sweep_dialog_stage_name
	
	if _sweep_gold_label:
		_sweep_gold_label.text = "+%d 金币" % reward.get("gold", 120)

	if _sweep_exp_label:
		_sweep_exp_label.text = "+%d 经验" % reward.get("exp", 0)

	if _sweep_rule_label:
		_sweep_rule_label.text = "%d 星扫荡收益 80%%" % clampi(_sweep_dialog_stars, 1, 3)

# ==================== 动画更新 ====================

func _update_chapter_animation(delta: float) -> void:
	if not _chapter_anim_active:
		return
	_chapter_anim_progress = minf(1.0, _chapter_anim_progress + delta * 4.0)
	if _chapter_anim_progress >= 1.0:
		_chapter_anim_active = false

func _update_sweep_animation(delta: float) -> void:
	if not _sweep_anim_active:
		return
	_sweep_anim_progress = minf(1.0, _sweep_anim_progress + delta * 1.5)
	_refresh_sweep_anim_overlay()
	if _sweep_anim_progress >= 1.0:
		_sweep_anim_active = false
		_sweep_anim_overlay.visible = false
		_build_cards()  # 刷新显示

func _refresh_sweep_anim_overlay() -> void:
	var progress: float = _sweep_anim_progress
	
	if _sweep_anim_title_label:
		_sweep_anim_title_label.text = "扫荡完成！"
	if _sweep_anim_gold_label:
		_sweep_anim_gold_label.text = "+%d 金币" % _sweep_anim_gold
	if _sweep_anim_exp_label:
		_sweep_anim_exp_label.text = "+%d 经验" % _sweep_anim_exp if progress > 0.3 else ""

# ==================== UI 更新 ====================

func _update_header() -> void:
	if _chapters.is_empty() or _current_chapter_index >= _chapters.size():
		return
	
	var chapter: Dictionary = _chapters[_current_chapter_index]
	var current_num: int = _current_chapter_index + 1
	
	_chapter_title.text = "第%d章" % current_num
	_chapter_name_label.text = chapter.get("name", "")
	
	var chapter_stars: int = _get_chapter_stars(chapter)
	var total_stars: int = maxi((chapter.get("stages", []).size() as int) * 3, 1)
	_star_label.text = "%d/%d" % [chapter_stars, total_stars]

func _get_chapter_stars(chapter: Dictionary) -> int:
	if not chapter.has("stages"):
		return 0
	var total: int = 0
	for stage: Dictionary in chapter["stages"]:
		if _storage and _storage.has_method("get_stage_stars"):
			total += _storage.get_stage_stars(stage.get("id", ""))
	return total

func _update_chapter_buttons() -> void:
	_prev_chapter_btn.disabled = _current_chapter_index <= 0
	_next_chapter_btn.disabled = _current_chapter_index >= _chapters.size() - 1
	_prev_chapter_btn.visible = _current_chapter_index > 0
	_next_chapter_btn.visible = _current_chapter_index < _chapters.size() - 1

func _update_page_dots() -> void:
	# 动态生成分页圆点
	for child: Node in _dots_container.get_children():
		child.queue_free()
	
	var total: int = _chapters.size()
	var current: int = _current_chapter_index
	
	if total <= 7:
		_add_normal_dots(total, current)
	else:
		_add_truncated_dots(total, current)

func _add_normal_dots(total: int, current: int) -> void:
	var dot_spacing: float = 14.0
	var center_x: float = _dots_container.size.x
	var start_x: float = center_x / 2.0 - (total - 1) * dot_spacing / 2.0
	
	for i: int in range(total):
		var dot: ColorRect = ColorRect.new()
		dot.custom_minimum_size = Vector2(4, 4)
		_dots_container.add_child(dot)
		if i == current:
			dot.custom_minimum_size = Vector2(10, 6)
			dot.color = Color.YELLOW
		else:
			dot.color = Color(1, 1, 1, 0.3)

func _add_truncated_dots(total: int, current: int) -> void:
	var dots: Array[int] = [0]
	var half_range: int = 2
	var range_start: int = maxi(1, current - half_range)
	var range_end: int = mini(total - 2, current + half_range)
	
	for i: int in range(range_start, range_end + 1):
		if not dots.has(i):
			dots.append(i)
	if not dots.has(total - 1):
		dots.append(total - 1)
	dots.sort()
	
	for dot_idx: int in dots.size():
		var i: int = dots[dot_idx]
		if dot_idx > 0 and i - dots[dot_idx - 1] > 1:
			pass  # 省略号（简化处理，不画文字）

func _refresh_stage_nodes() -> void:
	# 清除旧节点
	for child: Node in _stage_container.get_children():
		child.queue_free()
	queue_redraw()

func _draw() -> void:
	_draw_stage_background()
	_draw_stage_paths()
	for card: Dictionary in _cards:
		_draw_stage_card(card)
	_draw_reward_panel()
	_draw_chapter_header()
	_draw_chapter_mechanic_banner()
	if _sweep_dialog_active:
		_draw_sweep_dialog()

func _draw_stage_background() -> void:
	var bg_path := _current_chapter_background_path()
	var tex := _get_texture(bg_path)
	if tex == null:
		tex = _get_texture("res://assets/images/stage/stage_map_bg.png")
	if tex:
		_draw_texture_cover(tex, Rect2(0, 0, DESIGN_W, DESIGN_H))
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.05, 0.11, 0.04))
	else:
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.04, 0.07, 0.15, 1.0))

func _current_chapter() -> Dictionary:
	if _chapters.is_empty() or _current_chapter_index < 0 or _current_chapter_index >= _chapters.size():
		return {}
	return _chapters[_current_chapter_index]

func _current_chapter_element() -> String:
	var chapter := _current_chapter()
	return str(chapter.get("element", "grass"))

func _current_chapter_mechanic() -> Dictionary:
	var chapter := _current_chapter()
	return chapter.get("chapterMechanic", {})

func _current_chapter_background_path() -> String:
	var chapter := _current_chapter()
	var chapter_id := str(chapter.get("id", ""))
	if CHAPTER_BACKGROUND_OVERRIDES.has(chapter_id):
		return str(CHAPTER_BACKGROUND_OVERRIDES[chapter_id])
	var element := str(chapter.get("element", "grass"))
	return str(CHAPTER_THEME_BACKGROUNDS.get(element, "res://assets/images/stage/stage_map_bg.png"))

func _draw_chapter_header() -> void:
	if _chapters.is_empty() or _current_chapter_index >= _chapters.size():
		return
	var chapter: Dictionary = _chapters[_current_chapter_index]
	var current_num := _current_chapter_index + 1
	var back_pressed: bool = _touched_btn == "backBtn"
	var theme_color: Color = CHAPTER_THEME_TINTS.get(_current_chapter_element(), Color(0.30, 0.95, 0.34))
	
	_draw_texture_contain(_get_texture("res://assets/images/stage/ui_back_button.png"), Rect2(9, 12, 56, 56), 0.82 if back_pressed else 1.0)
	_draw_texture_contain(_get_texture("res://assets/images/stage/icon_back_arrow.png"), Rect2(21, 24, 32, 32))
	
	var header := _get_texture("res://assets/images/stage/ui_header_bar.png")
	if header:
		_draw_texture_fit(header, HEADER_BAR_RECT)
	else:
		_draw_rounded_rect(HEADER_BAR_RECT.position.x, HEADER_BAR_RECT.position.y, HEADER_BAR_RECT.size.x, HEADER_BAR_RECT.size.y, 8, Color(0.1, 0.15, 0.25, 0.86))
	
	_draw_texture_contain(_get_texture("res://assets/images/stage/icon_chapter_badge.png"), HEADER_BADGE_RECT)
	_draw_text_center(str(current_num), 103, 41, Color.WHITE, 12, true, 34)
	
	if _current_chapter_index > 0:
		_draw_texture_contain(_get_texture("res://assets/images/stage/ui_arrow_button.png"), HEADER_PREV_RECT, 0.82 if _touched_btn == "prevChapter" else 1.0)
		_draw_texture_contain(_get_texture("res://assets/images/stage/icon_prev_arrow.png"), Rect2(HEADER_PREV_RECT.position.x + 6.0, HEADER_PREV_RECT.position.y + 6.0, 22, 22))
	if _current_chapter_index < _chapters.size() - 1:
		_draw_texture_contain(_get_texture("res://assets/images/stage/ui_arrow_button.png"), HEADER_NEXT_RECT, 0.82 if _touched_btn == "nextChapter" else 1.0)
		_draw_texture_contain(_get_texture("res://assets/images/stage/icon_next_arrow.png"), Rect2(HEADER_NEXT_RECT.position.x + 6.0, HEADER_NEXT_RECT.position.y + 6.0, 22, 22))
	
	_draw_text_in_rect("第%d章" % current_num, HEADER_CHAPTER_TEXT_RECT, theme_color, 15, true)
	_draw_text_in_rect(chapter.get("name", ""), HEADER_NAME_TEXT_RECT, Color.WHITE, 15, true)
	
	var chapter_stars := _get_chapter_stars(chapter)
	var total_stars: int = maxi((chapter.get("stages", []).size() as int) * 3, 1)
	_draw_texture_contain(_get_texture("res://assets/images/stage/icon_star_lit.png"), HEADER_STAR_RECT)
	_draw_text_in_rect("%d/%d" % [chapter_stars, total_stars], HEADER_STAR_TEXT_RECT, Color.WHITE, 14, true)
	_draw_page_dots(DESIGN_W / 2.0, HEADER_BAR_RECT.position.y + HEADER_BAR_RECT.size.y + 8.0, _chapters.size(), _current_chapter_index)

func _draw_chapter_mechanic_banner() -> void:
	var mechanic := _current_chapter_mechanic()
	if mechanic.is_empty():
		return
	var theme_color: Color = CHAPTER_THEME_TINTS.get(_current_chapter_element(), Color(0.30, 0.95, 0.34))
	var rect := Rect2(18.0, 86.0, DESIGN_W - 36.0, 52.0)
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 8.0, Color(0.03, 0.06, 0.12, 0.64))
	_draw_rounded_rect(rect.position.x, rect.position.y, 7.0, rect.size.y, 4.0, Color(theme_color.r, theme_color.g, theme_color.b, 0.9))
	_draw_text_in_rect("玩法：%s" % str(mechanic.get("name", "章节机制")), Rect2(rect.position.x + 16.0, rect.position.y + 5.0, rect.size.x - 28.0, 20.0), theme_color, 15, true, 11)
	_draw_text_in_rect(str(mechanic.get("tagline", "")), Rect2(rect.position.x + 16.0, rect.position.y + 28.0, rect.size.x - 28.0, 18.0), Color(0.88, 0.93, 1.0), 13, false, 10)

func _draw_page_dots(cx: float, cy: float, total: int, current: int) -> void:
	if total <= 0:
		return
	var dot_spacing := 14.0
	var start_x := cx - (total - 1) * dot_spacing / 2.0
	for i in range(total):
		var x := start_x + i * dot_spacing
		if i == current:
			_draw_rounded_rect(x - 5, cy - 3, 10, 6, 3, Color(1.0, 0.8, 0.0, 1.0))
		else:
			_draw_rounded_rect(x - 2, cy - 2, 4, 4, 2, Color(1, 1, 1, 0.3))

func _draw_stage_paths() -> void:
	var stage_cards: Array = _cards.filter(func(c): return c.get("type") == "stage")
	for i in range(stage_cards.size() - 1):
		_draw_path_dots(stage_cards[i].get("cx", 0.0), stage_cards[i].get("cy", 0.0), stage_cards[i + 1].get("cx", 0.0), stage_cards[i + 1].get("cy", 0.0))

func _draw_path_dots(x1: float, y1: float, x2: float, y2: float) -> void:
	var dx := x2 - x1
	var dy := y2 - y1
	var dist := sqrt(dx * dx + dy * dy)
	var steps := maxi(1, int(floor(dist / 16.0)))
	var dot := _get_texture("res://assets/images/stage/icon_path_dot.png")
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var x := x1 + dx * t
		var y := y1 + dy * t
		if dot:
			_draw_texture_fit(dot, Rect2(x - 4, y - 4, 8, 8), 0.92)
		else:
			draw_circle(Vector2(x, y), 3, Color(1.0, 0.94, 0.78, 0.9))

func _draw_stage_card(card: Dictionary) -> void:
	var is_boss: bool = card.get("is_boss", false)
	var is_elite: bool = card.get("is_elite", false)
	var is_pressed: bool = _touched_btn == card.get("id", "")
	var is_unlocked: bool = card.get("enabled", true)
	var draw_cx: float = card.get("cx", 0.0)
	var draw_y: float = card.get("y", 0.0)
	
	if is_boss:
		var boss_alpha := 0.42 if not is_unlocked else (0.82 if is_pressed else 1.0)
		var boss_layout := _boss_layout_for_chapter(str(card.get("chapter_id", "")))
		var badge_rect: Rect2 = boss_layout["badge_rect"]
		var art_rect: Rect2 = boss_layout["art_rect"]
		var boss_origin := Vector2(draw_cx, card.get("cy", 0.0))
		_draw_texture_contain(_get_texture(str(boss_layout["badge_path"])), Rect2(badge_rect.position + boss_origin, badge_rect.size), boss_alpha)
		var boss_path := str(boss_layout.get("art_path", CHAPTER_BOSS_ART.get(_current_chapter_element(), "res://assets/images/stage/boss_flower.png")))
		_draw_texture_contain(_get_texture(boss_path), Rect2(art_rect.position + boss_origin, art_rect.size), boss_alpha)
		_draw_text_center("BOSS", draw_cx, card.get("cy", 0.0) + float(boss_layout["label_y"]), Color(1.0, 0.82, 0.0), 13, true, 70)
		_draw_stars(draw_cx - 22, card.get("cy", 0.0) + float(boss_layout["stars_y"]), card.get("stars", 0))
		if not is_unlocked:
			_draw_stage_lock_overlay(card, true)
		return
	
	var node_key := "node_crystal" if is_elite else "node_normal"
	if not is_unlocked:
		node_key = "node_locked"
	if is_unlocked and card.get("stars", 0) >= 3 and card.get("stage_no", 0) == _cards.size():
		node_key = "node_chest"
	if is_pressed:
		node_key = "node_selected"
	var node_path := _stage_node_asset_path(str(card.get("chapter_id", "")), node_key)
	var node_w: float = float(card.get("w", 62.0 if is_elite else 60.0))
	var node_h: float = float(card.get("h", 70.0 if is_elite else 50.0))
	var node_x := draw_cx - node_w / 2.0
	var node_y: float = float(card.get("cy", 0.0)) - node_h / 2.0
	
	if _get_texture(node_path):
		_draw_texture_contain(_get_texture(node_path), Rect2(node_x, node_y, node_w, node_h), 0.55 if not is_unlocked else 1.0)
	else:
		draw_circle(Vector2(draw_cx, card.get("cy", 0.0)), 26, Color(0.08, 0.10, 0.14, 0.72) if not is_unlocked else Color(0.1, 0.5, 1.0, 0.95))
	_draw_text_center(str(card.get("stage_no", 1)), draw_cx, card.get("cy", 0.0) + (-1.0 if is_elite else -4.0), Color(0.62, 0.68, 0.76) if not is_unlocked else Color.WHITE, 15, true, 42)
	if is_unlocked:
		_draw_stars(draw_cx - 21, card.get("cy", 0.0) + 28, card.get("stars", 0))
	else:
		_draw_stage_lock_overlay(card, false)

func _draw_stage_lock_overlay(card: Dictionary, is_boss: bool) -> void:
	var cx: float = card.get("cx", 0.0)
	var cy: float = card.get("cy", 0.0)
	var required: Dictionary = card.get("unlock_state", {})
	var required_name := str(required.get("requiredStageName", "前置关卡"))
	var label := "通关%s解锁" % required_name if not required_name.is_empty() else "未解锁"
	var label_y := cy + (64.0 if is_boss else 36.0)
	_draw_text_center("锁", cx, cy + (-3.0 if is_boss else 0.0), Color(0.78, 0.84, 0.92), 14, true, 38)
	_draw_text_center(label, cx, label_y, Color(0.68, 0.76, 0.88), 8, false, 92)

func _draw_stars(x: float, y: float, count: int) -> void:
	for i in range(3):
		var lit := i < count
		var path := "res://assets/images/stage/icon_star_lit.png" if lit else "res://assets/images/stage/icon_star_dim.png"
		_draw_texture_fit(_get_texture(path), Rect2(x + i * 16.0, y - 7.0, 14, 14), 1.0 if lit else 0.45)

func _draw_reward_panel() -> void:
	var panel := _get_texture("res://assets/images/stage/ui_reward_panel_clean.png")
	if panel == null:
		return
	var panel_rect := REWARD_PANEL_RECT
	_draw_texture_fit(panel, panel_rect, 0.98)
	_draw_text_in_rect("通关奖励", Rect2(panel_rect.position.x + 86.0, panel_rect.position.y + 13.0, panel_rect.size.x - 172.0, 20.0), Color(0.86, 0.92, 1.0), 13, true)
	var total_w := REWARD_SLOT_SIZE.x * float(REWARD_ITEMS.size()) + REWARD_SLOT_GAP * float(REWARD_ITEMS.size() - 1)
	var start_x := panel_rect.position.x + (panel_rect.size.x - total_w) / 2.0
	for i in range(REWARD_ITEMS.size()):
		var item: Dictionary = REWARD_ITEMS[i]
		var rect := Rect2(start_x + float(i) * (REWARD_SLOT_SIZE.x + REWARD_SLOT_GAP), panel_rect.position.y + 38.0, REWARD_SLOT_SIZE.x, REWARD_SLOT_SIZE.y)
		_draw_reward_icon(str(item.get("key", "")), rect)

func _draw_reward_icon(key: String, rect: Rect2) -> void:
	_draw_texture_contain(_get_texture("res://assets/images/battle_prepare/ui_reward_slot.png"), rect)
	var path := str(REWARD_ICON_PATHS.get(key, "res://assets/images/stage/icon_%s.png" % key))
	var inset := 5.0
	_draw_texture_contain(_get_texture(path), rect.grow(-inset))

func _draw_sweep_dialog() -> void:
	var dlg_w := SWEEP_DIALOG_W
	var dlg_h := SWEEP_DIALOG_H
	var dlg_x := (DESIGN_W - dlg_w) / 2.0
	var dlg_y := (DESIGN_H - dlg_h) / 2.0
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0, 0, 0, 0.45))
	_draw_texture_fit(_get_texture("res://assets/images/stage/ui_reward_panel_clean.png"), Rect2(dlg_x, dlg_y, dlg_w, dlg_h), 0.96)
	_draw_text_center("确认扫荡", DESIGN_W / 2.0, dlg_y + 35, Color.WHITE, 18, true, 180)
	_draw_text_center(_sweep_dialog_stage_name, DESIGN_W / 2.0, dlg_y + 62, Color(0.8, 0.85, 1.0), 13, false, 200)
	_draw_text_center("+%d 金币    +%d 经验" % [int(_sweep_dialog_reward.get("gold", 0)), int(_sweep_dialog_reward.get("exp", 0))], DESIGN_W / 2.0, dlg_y + 91, Color(1.0, 0.86, 0.3), 15, true, 230)
	_draw_text_center("%d 星通关已解锁，扫荡获得对应奖励的 80%%" % clampi(_sweep_dialog_stars, 1, 3), DESIGN_W / 2.0, dlg_y + 116, Color(0.66, 0.78, 1.0), 10, false, 230)

	var confirm_rect := Rect2(dlg_x + 25, dlg_y + 128, 100, 40)
	var cancel_rect := Rect2(dlg_x + 145, dlg_y + 128, 100, 40)
	_draw_rounded_rect(confirm_rect.position.x, confirm_rect.position.y, confirm_rect.size.x, confirm_rect.size.y, 8.0, Color(0.18, 0.52, 0.95, 0.92))
	_draw_rounded_rect(cancel_rect.position.x, cancel_rect.position.y, cancel_rect.size.x, cancel_rect.size.y, 8.0, Color(0.18, 0.22, 0.32, 0.92))
	_draw_text_center("扫荡", confirm_rect.get_center().x, confirm_rect.position.y + 25.0, Color.WHITE, 14, true, 90)
	_draw_text_center("取消", cancel_rect.get_center().x, cancel_rect.position.y + 25.0, Color(0.82, 0.88, 0.96), 14, true, 90)

func _get_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var old_modulate := self_modulate
	var color := Color(1, 1, 1, opacity)
	draw_texture_rect(tex, rect, false, color)
	self_modulate = old_modulate

func _draw_texture_contain(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_pos := rect.position + (rect.size - draw_size) * 0.5
	draw_texture_rect(tex, Rect2(draw_pos, draw_size), false, Color(1, 1, 1, opacity))

func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	var scale := maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var source_size := rect.size / scale
	var source_pos := (tex_size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size), Color(1, 1, 1, opacity))

func _draw_text_center(text: String, x: float, y: float, color: Color, font_size: int, bold: bool = false, width: float = 200.0) -> void:
	var pos := Vector2(x - width / 2.0, y)
	draw_string(ThemeDB.fallback_font, pos + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(0, 0, 0, 0.55))
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _draw_text_in_rect(text: String, rect: Rect2, color: Color, max_font_size: int, bold: bool = false, min_font_size: int = 10) -> void:
	var font := ThemeDB.fallback_font
	var font_size := max_font_size
	while font_size > min_font_size:
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
		if text_size.x <= rect.size.x:
			break
		font_size -= 1
	var baseline_y := rect.position.y + rect.size.y * 0.5 + float(font_size) * 0.35
	var pos := Vector2(rect.position.x, baseline_y)
	draw_string(font, pos + Vector2(1.0, 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(0, 0, 0, 0.58))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	draw_rect(Rect2(x + r, y, w - r * 2.0, h), color)
	draw_rect(Rect2(x, y + r, w, h - r * 2.0), color)
	draw_rect(Rect2(x, y, r, r), color)
	draw_rect(Rect2(x + w - r, y, r, r), color)
	draw_rect(Rect2(x, y + h - r, r, r), color)
	draw_rect(Rect2(x + w - r, y + h - r, r, r), color)

func _create_stage_node(card: Dictionary) -> void:
	var is_boss: bool = card.get("is_boss", false)
	var is_elite: bool = card.get("is_elite", false)
	var stage_no: int = card.get("stage_no", 1)
	var stars: int = card.get("stars", 0)
	
	var node: Control = Control.new()
	node.name = "StageNode_%s" % card["id"]
	node.position = Vector2(card["x"], card["y"])
	node.custom_minimum_size = Vector2(card["w"], card["h"])
	
	# 节点背景图片
	var node_image_path: String = ""
	if is_boss:
		node_image_path = "res://assets/images/stage/node_crystal.png"
	else:
		var can_sweep: bool = card.get("can_sweep", false)
		if can_sweep:
			node_image_path = "res://assets/images/stage/node_selected.png"
		else:
			node_image_path = "res://assets/images/stage/node_normal.png"
	
	if ResourceLoader.exists(node_image_path):
		var bg_tex := TextureRect.new()
		bg_tex.texture = load(node_image_path)
		bg_tex.size = Vector2(card["w"], card["h"])
		bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
		node.add_child(bg_tex)
	else:
		# 降级：用 Panel 代替
		var bg: Panel = Panel.new()
		bg.custom_minimum_size = Vector2(card["w"], card["h"])
		bg.size = Vector2(card["w"], card["h"])
		if is_boss:
			bg.add_theme_stylebox_override("panel", _create_boss_style())
		else:
			bg.add_theme_stylebox_override("panel", _create_normal_style(card.get("can_sweep", false)))
		node.add_child(bg)
	
	# 关卡编号标签
	var no_label: Label = Label.new()
	no_label.text = str(stage_no)
	no_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_label.position = Vector2(card["w"] / 2.0 - 10, card["h"] / 2.0 - 8)
	no_label.add_theme_font_size_override("font_size", 16)
	node.add_child(no_label)
	
	# 星级显示
	var stars_label: Label = Label.new()
	stars_label.text = _repeat_text("★", stars) + _repeat_text("☆", 3 - stars)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.position = Vector2(card["w"] / 2.0 - 22, card["h"] - 10)
	stars_label.add_theme_font_size_override("font_size", 10)
	stars_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	node.add_child(stars_label)
	
	# BOSS 标签
	if is_boss:
		var boss_label: Label = Label.new()
		boss_label.text = "BOSS"
		boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_label.position = Vector2(card["w"] / 2.0 - 20, card["h"] - 24)
		boss_label.add_theme_font_size_override("font_size", 10)
		boss_label.add_theme_color_override("font_color", Color.YELLOW)
		node.add_child(boss_label)
	
	# 扫荡按钮（如果有）
	if card.get("can_sweep", false):
		var sweep_btn: Button = Button.new()
		sweep_btn.text = "⚡"
		sweep_btn.position = Vector2(card.get("sweep_rect", Rect2()).position.x - card["x"], card.get("sweep_rect", Rect2()).position.y - card["y"])
		sweep_btn.custom_minimum_size = Vector2(28, 24)
		sweep_btn.pressed.connect(func(): _show_sweep_dialog(card["id"], card.get("text", "")))
		node.add_child(sweep_btn)
	
	_stage_container.add_child(node)

func _repeat_text(text: String, count: int) -> String:
	var result := ""
	for i in range(maxi(0, count)):
		result += text
	return result

func _create_boss_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.1, 0.1, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _create_normal_style(can_sweep: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.8, 0.9) if can_sweep else Color(0.2, 0.6, 0.3, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

# ==================== 按钮信号 ====================

func _on_back_btn_pressed() -> void:
	_go_to_scene("main")

func _on_prev_chapter_btn_pressed() -> void:
	_switch_chapter(-1)

func _on_next_chapter_btn_pressed() -> void:
	_switch_chapter(1)

# ==================== 销毁 ====================

func destroy() -> void:
	# 清理节点
	for child: Node in get_tree().get_nodes_in_group("stage_node"):
		child.queue_free()

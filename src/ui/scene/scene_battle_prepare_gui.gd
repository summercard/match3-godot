# scene_battle_prepare_gui.gd - 可在 Godot 编辑器中调整的战斗准备界面
class_name SceneBattlePrepareGui
extends "res://src/ui/controllers/battle_prepare_logic.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")

const ENEMY_CARD_PATHS := [
	"EnemyPanel/Cards/EnemyCard1",
	"EnemyPanel/Cards/EnemyCard2",
	"EnemyPanel/Cards/EnemyCard3",
]
const TEAM_CARD_PATHS := [
	"TeamPanel/Cards/TeamCard1",
	"TeamPanel/Cards/TeamCard2",
	"TeamPanel/Cards/TeamCard3",
]
const REWARD_SLOT_PATHS := [
	"RewardPreview/Slots/RewardSlot1",
	"RewardPreview/Slots/RewardSlot2",
	"RewardPreview/Slots/RewardSlot3",
]

# === 入场动画时间线 ===
const ENTRY_HEADER_DELAY := 0.00
const ENTRY_RESOURCE_DELAY := 0.10
const ENTRY_ENEMY_DELAY := 0.22
const ENTRY_POWER_DELAY := 0.34
const ENTRY_TEAM_CARD_DELAY := 0.48
const ENTRY_TEAM_CARD_STAGGER := 0.10
const ENTRY_REWARD_DELAY := 0.80
const ENTRY_REWARD_STAGGER := 0.10
const ENTRY_BUTTON_DELAY := 1.00
const ENTRY_SLIDE_DURATION := 0.34
const ENTRY_POP_DURATION := 0.30
const ENTRY_CARD_DURATION := 0.24
const ENTRY_BUTTON_DURATION := 0.26
var _entry_played: bool = false
const BROWN_TEXT := Color(0.34, 0.16, 0.05, 1.0)
const BROWN_DARK := Color(0.22, 0.09, 0.03, 1.0)
const CREAM_OUTLINE := Color(1.0, 0.88, 0.56, 0.88)
const GOLD_TEXT := Color(1.0, 0.73, 0.16, 1.0)
const BLUE_TEXT := Color(0.08, 0.42, 0.95, 1.0)
const GREEN_TEXT := Color(0.08, 0.58, 0.18, 1.0)
const RED_TEXT := Color(0.9, 0.16, 0.09, 1.0)
const CREAM_PANEL := Color(1.0, 0.94, 0.74, 0.90)
const STAGE_PANEL := Color(1.0, 0.95, 0.76, 0.58)

func _ready() -> void:
	instance = self
	set_process(false)
	_ensure_concept_nodes()
	_connect_gui_actions()
	_sync_gui()
	# 战斗准备页留白：不重置大厅音乐，也不提前播放战斗音乐。
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("stop_bgm"):
		am.call("stop_bgm")

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_sync_gui()

func _draw() -> void:
	pass

func _gui_input(_event: InputEvent) -> void:
	pass

func _process(_delta: float) -> void:
	if _show_empty_team_alert:
		var elapsed := (Time.get_ticks_msec() / 1000.0) - _alert_show_time
		if elapsed > 2.0:
			_show_empty_team_alert = false
		_sync_alert()
		if not _show_empty_team_alert:
			set_process(false)

func _connect_gui_actions() -> void:
	_connect_button("Header/BackButton", _back_button_pressed)
	_connect_button("StartButton", _start_battle)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button == null:
		return
	if not button.pressed.is_connected(action):
		button.pressed.connect(action)
	var profile := CartoonButtonFeedback.Profile.PRIMARY if path == "StartButton" else CartoonButtonFeedback.Profile.ICON
	_attach_button_feedback(button, profile)

func _attach_button_feedback(button: BaseButton, profile: int) -> void:
	if button.has_node("CartoonFeedback"):
		return
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)

func _ensure_concept_nodes() -> void:
	# 兼容旧场景文件的兜底；新视觉节点应保留在 battle_prepare.tscn 中。
	if not has_node("TopResourceBar"):
		var top_bar := Control.new()
		top_bar.name = "TopResourceBar"
		top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(top_bar)
		move_child(top_bar, 3)
		_create_resource_chip(top_bar, "GoldChip", "gold")
		_create_resource_chip(top_bar, "DiamondChip", "diamond")
		_create_resource_chip(top_bar, "HeartChip", "heart")
	_create_panel_bg("EnemyPanel", "Bg", _rounded_style(STAGE_PANEL, Color(0.93, 0.62, 0.24, 1.0), 2, 14))
	var pill_style := _rounded_style(Color(1.0, 0.92, 0.72, 0.92), Color(0.93, 0.60, 0.25, 1.0), 2, 12)
	var pill := get_node_or_null("EnemyPanel/ElementPill") as Panel
	if pill == null:
		pill = Panel.new()
		pill.name = "ElementPill"
		_node("EnemyPanel").add_child(pill)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", pill_style)
	if not has_node("EnemyPanel/ElementText"):
		var element_text := Label.new()
		element_text.name = "ElementText"
		element_text.text = "火系"
		element_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		element_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_node("EnemyPanel").add_child(element_text)
	if not has_node("EnemyPanel/ElementIcon"):
		var element_icon := TextureRect.new()
		element_icon.name = "ElementIcon"
		element_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		element_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		element_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_node("EnemyPanel").add_child(element_icon)
	if not has_node("EnemyPanel/PowerIcon"):
		var power_icon := TextureRect.new()
		power_icon.name = "PowerIcon"
		power_icon.texture = _prepare_texture("sword")
		power_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		power_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		power_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_node("EnemyPanel").add_child(power_icon)
	if not has_node("EnemyPanel/PowerCaption"):
		var caption := Label.new()
		caption.name = "PowerCaption"
		caption.text = "敌方战力"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_node("EnemyPanel").add_child(caption)
	_create_panel_bg("PowerPanel", "Bg", _rounded_style(Color(1.0, 0.93, 0.74, 0.92), Color(0.94, 0.60, 0.22, 1.0), 2, 12))
	_create_panel_bg("TeamPanel", "Bg", _rounded_style(Color(1.0, 0.94, 0.76, 0.62), Color(0.94, 0.62, 0.22, 1.0), 2, 12))
	_create_panel_bg("RewardPreview", "Bg", _rounded_style(Color(1.0, 0.94, 0.76, 0.90), Color(0.94, 0.62, 0.22, 1.0), 2, 12))

func _create_panel_bg(parent_path: NodePath, node_name: String, style: StyleBoxFlat) -> void:
	var parent := get_node_or_null(parent_path) as Control
	if parent == null:
		return
	var bg := parent.get_node_or_null(node_name) as Panel
	if bg == null:
		bg = Panel.new()
		bg.name = node_name
		parent.add_child(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", style)
	parent.move_child(bg, 0)

func _create_resource_chip(parent: Control, node_name: String, icon_key: String) -> void:
	var chip := Control.new()
	chip.name = node_name
	parent.add_child(chip)
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = _prepare_texture("currency_chip")
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	chip.add_child(frame)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = _prepare_texture(icon_key)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.add_child(icon)
	var value := Label.new()
	value.name = "Value"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_color_override("font_color", BROWN_TEXT)
	value.add_theme_color_override("font_outline_color", Color.WHITE)
	value.add_theme_constant_override("outline_size", 1)
	value.add_theme_font_size_override("font_size", 12)
	chip.add_child(value)
	var plus := TextureRect.new()
	plus.name = "Plus"
	plus.texture = _prepare_texture("plus")
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.add_child(plus)

func _rounded_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style

func _start_battle() -> void:
	super._start_battle()
	_sync_gui()

func _sync_top_resource_bar() -> void:
	var storage := get_node_or_null("/root/SaveManager")
	var player: Dictionary = storage.get_player() if storage != null and storage.has_method("get_player") else {}
	_label("TopResourceBar/GoldChip/Value").text = _compact_number(int(player.get("gold", 12350)))
	_label("TopResourceBar/DiamondChip/Value").text = _compact_number(int(player.get("gems", 2548)))
	_label("TopResourceBar/HeartChip/Value").text = "%s  满" % str(player.get("stamina", 5))

func _compact_number(value: int) -> String:
	var text := str(value)
	var out := ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Header"):
		return
	_ensure_concept_nodes()
	_sync_background()
	_sync_top_resource_bar()
	_label("Header/Title").text = "战斗准备"
	_label("Header/StageName").text = str(_stage_data.get("name", _stage_id))
	_sync_enemy_cards()
	_sync_power_panel()
	_sync_team_cards()
	_sync_mechanic_hint()
	_sync_synergy()
	_sync_rewards()
	_sync_start_button()
	_sync_alert()
	_maybe_play_entry()

func _sync_background() -> void:
	var background := get_node_or_null("Background") as TextureRect
	if background == null:
		return
	var path := StageWarBackgroundsScript.path_for(_stage_id, _stage_data)
	background.texture = _get_texture(path)

func _sync_enemy_cards() -> void:
	_set_visible("EnemyPanel/Frame", false)
	var is_boss := not _enemy_team.is_empty() and bool((_enemy_team[0] as Dictionary).get("isBoss", false))
	_label("EnemyPanel/Title").text = "敌方信息"
	_set_visible("EnemyPanel/Title", not is_boss)
	_set_enemy_panel_info_visible(not is_boss)
	for i in ENEMY_CARD_PATHS.size():
		var card := _node(ENEMY_CARD_PATHS[i])
		card.visible = i == 0 and not _enemy_team.is_empty()
		if i != 0 or _enemy_team.is_empty():
			continue
		var enemy: Dictionary = _enemy_team[i]
		if bool(enemy.get("isBoss", false)):
			_set_enemy_boss_card(card, enemy)
		else:
			_set_enemy_hero_card(card, enemy)

func _sync_team_cards() -> void:
	_label("TeamPanel/Title").text = "我方队伍"
	_node("TeamPanel/EmptyLabel").visible = _player_team.is_empty()
	_layout_cards(TEAM_CARD_PATHS, _player_team.size(), 99.0, 9.0, 329.0)
	for i in TEAM_CARD_PATHS.size():
		var card := _node(TEAM_CARD_PATHS[i])
		card.visible = i < _player_team.size()
		if i >= _player_team.size():
			continue
		var monster: Dictionary = _player_team[i]
		_set_monster_card(card, monster, true)
		var rarity := int(monster.get("rarity", 1))
		(card.get_node("Stars") as Label).text = "★".repeat(clampi(rarity, 1, 5))

func _layout_cards(paths: Array, count: int, card_w: float, gap: float, total_w: float) -> void:
	var visible_count := mini(count, paths.size())
	if visible_count <= 0:
		return
	var used_w := float(visible_count) * card_w + float(maxi(0, visible_count - 1)) * gap
	var start_x := (total_w - used_w) * 0.5
	for i in visible_count:
		var card := _node(paths[i])
		card.position.x = start_x + float(i) * (card_w + gap)

func _apply_concept_layout() -> void:
	_set_rect("TopResourceBar", 0, 0, 375, 50)
	_set_top_chip_rect("TopResourceBar/GoldChip", 54, 10, 94, 32)
	_set_top_chip_rect("TopResourceBar/DiamondChip", 154, 10, 84, 32)
	_set_top_chip_rect("TopResourceBar/HeartChip", 244, 10, 82, 32)
	_set_rect("Header", 0, 0, 375, 118)
	_set_rect("Header/BackButton", 10, 9, 44, 44)
	_set_local_rect("Header/BackButton/Frame", 0, 0, 44, 44)
	_set_local_rect("Header/BackButton/Arrow", 8, 8, 27, 27)
	_set_rect("Header/Bar", 78, 48, 220, 57)
	_set_rect("Header/Title", 105, 59, 166, 32)
	_set_rect("Header/StageName", 112, 92, 150, 20)
	_set_rect("Header/SparklesLeft", 70, 72, 39, 18)
	_set_rect("Header/SparklesRight", 283, 72, 36, 17)
	_set_font("Header/Title", 28)
	_set_font("Header/StageName", 14)
	_style_label("Header/Title", Color.WHITE, Color(0.45, 0.18, 0.04, 0.88), 3)
	_style_label("Header/StageName", BROWN_TEXT, Color(1.0, 0.92, 0.62, 0.95), 2)

	_set_rect("EnemyPanel", 26, 119, 323, 158)
	_set_local_rect("EnemyPanel/Bg", 0, 0, 323, 158)
	_set_visible("EnemyPanel/Frame", false)
	_set_rect("EnemyPanel/Title", 18, 10, 96, 24)
	_set_rect("EnemyPanel/ElementPill", 18, 92, 96, 25)
	_set_rect("EnemyPanel/ElementIcon", 25, 94, 21, 21)
	_set_rect("EnemyPanel/ElementText", 47, 94, 58, 21)
	_set_rect("EnemyPanel/PowerIcon", 16, 116, 34, 34)
	_set_rect("EnemyPanel/PowerCaption", 48, 118, 72, 18)
	_set_font("EnemyPanel/Title", 18)
	_set_font("EnemyPanel/ElementText", 12)
	_set_font("EnemyPanel/PowerCaption", 11)
	_style_label("EnemyPanel/Title", Color.WHITE, Color(0.48, 0.12, 0.08, 0.92), 2)
	_style_label("EnemyPanel/ElementText", BROWN_TEXT, Color.WHITE, 1)
	_style_label("EnemyPanel/PowerCaption", BROWN_TEXT, Color.WHITE, 1)
	_set_rect("EnemyPanel/Cards", 0, 0, 323, 158)
	for path in ENEMY_CARD_PATHS:
		_layout_enemy_hero_card(path)

	_set_rect("PowerPanel", 25, 283, 325, 74)
	_set_local_rect("PowerPanel/Bg", 0, 0, 325, 74)
	_set_visible("PowerPanel/Frame", false)
	_set_rect("PowerPanel/Title", 112, -8, 101, 28)
	_set_rect("PowerPanel/PlayerPower", 24, 27, 105, 31)
	_set_rect("PowerPanel/VsLabel", 137, 20, 51, 42)
	_set_rect("PowerPanel/EnemyPower", 196, 27, 105, 31)
	_set_rect("PowerPanel/Diff", 98, 56, 129, 17)
	_set_font("PowerPanel/Title", 15)
	_set_font("PowerPanel/PlayerPower", 24)
	_set_font("PowerPanel/VsLabel", 30)
	_set_font("PowerPanel/EnemyPower", 24)
	_set_font("PowerPanel/Diff", 13)
	_style_label("PowerPanel/Title", Color.WHITE, Color(0.10, 0.32, 0.58, 0.9), 2)
	_style_label("PowerPanel/PlayerPower", BLUE_TEXT, Color.WHITE, 1)
	_style_label("PowerPanel/VsLabel", GOLD_TEXT, BROWN_DARK, 2)
	_style_label("PowerPanel/EnemyPower", RED_TEXT, Color.WHITE, 1)
	_style_label("PowerPanel/Diff", GREEN_TEXT, Color.WHITE, 1)

	_set_rect("TeamPanel", 20, 371, 335, 139)
	_set_local_rect("TeamPanel/Bg", 0, 18, 335, 121)
	_set_visible("TeamPanel/Frame", false)
	_set_rect("TeamPanel/Title", 110, 0, 115, 25)
	_set_rect("TeamPanel/EmptyLabel", 0, 61, 335, 24)
	_set_font("TeamPanel/Title", 15)
	_style_label("TeamPanel/Title", Color.WHITE, Color(0.08, 0.42, 0.13, 0.9), 2)
	_style_label("TeamPanel/EmptyLabel", BROWN_TEXT, Color.WHITE, 1)
	_set_rect("TeamPanel/Cards", 3, 26, 329, 113)
	for path in TEAM_CARD_PATHS:
		_layout_monster_card(path, 0, 0, 99, 113, true)

	_set_rect("MechanicPanel", 24, 508, 327, 1)
	_node("MechanicPanel").visible = false
	_set_local_rect("MechanicPanel/Frame", 0, 0, 327, 63)
	_set_rect("MechanicPanel/Title", 0, 2, 327, 22)
	_set_rect("MechanicPanel/Line1", 82, 27, 228, 17)
	_set_rect("MechanicPanel/Line2", 82, 43, 228, 17)
	_set_font("MechanicPanel/Title", 15)
	_set_font("MechanicPanel/Line1", 10)
	_set_font("MechanicPanel/Line2", 10)
	_style_label("MechanicPanel/Title", BROWN_TEXT, CREAM_OUTLINE, 2)
	_style_label("MechanicPanel/Line1", BROWN_TEXT, Color.WHITE, 1)
	_style_label("MechanicPanel/Line2", Color(0.47, 0.29, 0.1, 1.0), Color.WHITE, 1)
	_set_label_align("MechanicPanel/Line1", HORIZONTAL_ALIGNMENT_LEFT)
	_set_label_align("MechanicPanel/Line2", HORIZONTAL_ALIGNMENT_LEFT)

	_set_rect("SynergyPanel", 43, 510, 289, 1)
	_node("SynergyPanel").visible = false
	_set_local_rect("SynergyPanel/Frame", 0, 0, 291, 27)
	_set_visible("SynergyPanel/Frame", false)
	_set_rect("SynergyPanel/Line1", 8, 0, 273, 12)
	_set_rect("SynergyPanel/Line2", 8, 11, 273, 12)
	_set_font("SynergyPanel/Line1", 10)
	_set_font("SynergyPanel/Line2", 10)
	_style_label("SynergyPanel/Line1", BROWN_TEXT, Color.WHITE, 1)
	_style_label("SynergyPanel/Line2", GREEN_TEXT, Color.WHITE, 1)

	_set_rect("RewardPreview", 28, 516, 319, 86)
	_set_local_rect("RewardPreview/Bg", 0, 0, 319, 86)
	_set_visible("RewardPreview/Frame", false)
	_set_rect("RewardPreview/Title", 102, -5, 115, 24)
	_set_rect("RewardPreview/Slots", 42.5, 20, 234, 60)
	_set_font("RewardPreview/Title", 15)
	_style_label("RewardPreview/Title", Color.WHITE, Color(0.35, 0.08, 0.55, 0.90), 2)
	for i in REWARD_SLOT_PATHS.size():
		var slot_path: String = REWARD_SLOT_PATHS[i]
		_set_rect(slot_path, float(i) * 88.0, 0, 58, 60)
		_set_local_rect(slot_path + "/Frame", 0, 0, 58, 60)
		_set_visible(slot_path + "/Frame", true)
		_set_local_rect(slot_path + "/Icon", 9, 10, 40, 40)
		_set_local_rect(slot_path + "/Label", -10, 32, 78, 27)
		_set_visible(slot_path + "/Label", false)
		_set_font(slot_path + "/Label", 9)
		_style_label(slot_path + "/Label", BROWN_TEXT, Color.WHITE, 1)

	_set_rect("StartButton", 47, 613, 281, 48)
	_set_local_rect("StartButton/Frame", 0, 0, 281, 48)
	_set_local_rect("StartButton/Text", 27, 2, 227, 42)
	_set_font("StartButton/Text", 24)
	_style_label("StartButton/Text", Color.WHITE, Color(0.13, 0.35, 0.05, 0.9), 3)

func _layout_monster_card(path: String, x: float, y: float, w: float, h: float, _is_team_card: bool) -> void:
	_set_rect(path, x, y, w, h)
	_set_local_rect(path + "/Frame", 0, 0, w, h)
	_set_local_rect(path + "/Portrait", 18, 21, w - 36, 48)
	_set_local_rect(path + "/ElementBadge", 8, 5, 22, 22)
	_set_local_rect(path + "/Name", 31, 4, w - 38, 22)
	_set_local_rect(path + "/Level", 24, 72, w - 48, 17)
	_set_local_rect(path + "/Power", 16, 91, w - 24, 17)
	_set_local_rect(path + "/Stars", 8, h - 9, w - 16, 12)
	_set_font(path + "/Name", 13)
	_set_font(path + "/Level", 11)
	_set_font(path + "/Power", 10)
	_set_font(path + "/Stars", 9)
	_style_label(path + "/Name", BROWN_TEXT, Color.WHITE, 1)
	_style_label(path + "/Level", Color(0.42, 0.25, 0.12, 1.0), Color.WHITE, 1)
	_style_label(path + "/Power", Color(0.83, 0.29, 0.08, 1.0), Color.WHITE, 1)
	_style_label(path + "/Stars", GOLD_TEXT, Color(0.46, 0.22, 0.04, 0.65), 1)

func _layout_enemy_hero_card(path: String) -> void:
	_set_rect(path, 0, 0, 323, 158)
	_set_visible(path + "/Frame", false)
	_set_local_rect(path + "/Portrait", 143, 21, 156, 108)
	_set_local_rect(path + "/ElementBadge", 24, 94, 21, 21)
	_set_visible(path + "/ElementBadge", false)
	_set_local_rect(path + "/Name", 18, 39, 119, 28)
	_set_local_rect(path + "/Level", 18, 66, 119, 21)
	_set_local_rect(path + "/Power", 47, 132, 82, 22)
	_set_local_rect(path + "/Stars", 143, 132, 156, 17)
	_set_font(path + "/Name", 22)
	_set_font(path + "/Level", 15)
	_set_font(path + "/Power", 20)
	_set_font(path + "/Stars", 10)
	_style_label(path + "/Name", BROWN_DARK, Color.WHITE, 1)
	_style_label(path + "/Level", BROWN_DARK, Color.WHITE, 1)
	_style_label(path + "/Power", RED_TEXT, Color.WHITE, 1)
	_style_label(path + "/Stars", GOLD_TEXT, Color(0.46, 0.22, 0.04, 0.65), 1)

func _layout_enemy_boss_card(path: String) -> void:
	_set_rect(path, 0, 0, 323, 158)
	_set_visible(path + "/Frame", false)
	_set_local_rect(path + "/Portrait", 5, -42, 312, 216)
	_set_local_rect(path + "/Name", 16, 124, 291, 32)
	_set_local_rect(path + "/Level", 0, 0, 1, 1)
	_set_local_rect(path + "/Power", 0, 0, 1, 1)
	_set_local_rect(path + "/ElementBadge", 0, 0, 1, 1)
	_set_local_rect(path + "/Stars", 0, 0, 1, 1)
	_set_font(path + "/Name", 24)
	_style_label(path + "/Name", Color.WHITE, Color(0.55, 0.08, 0.02, 0.96), 3)

func _set_top_chip_rect(path: NodePath, x: float, y: float, w: float, h: float) -> void:
	_set_rect(path, x, y, w, h)
	_set_local_rect(String(path) + "/Frame", 0, 0, w, h)
	_set_local_rect(String(path) + "/Icon", 5, 4, 24, h - 8)
	_set_local_rect(String(path) + "/Value", 28, 3, w - 51, h - 6)
	_set_local_rect(String(path) + "/Plus", w - 24, 4, 21, h - 8)

func _set_rect(path: NodePath, x: float, y: float, w: float, h: float) -> void:
	var c := get_node_or_null(path) as Control
	if c == null:
		return
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)

func _set_local_rect(path: NodePath, x: float, y: float, w: float, h: float) -> void:
	_set_rect(path, x, y, w, h)

func _set_font(path: NodePath, size: int) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.add_theme_font_size_override("font_size", size)

func _set_visible(path: NodePath, visible: bool) -> void:
	var item := get_node_or_null(path) as CanvasItem
	if item != null:
		item.visible = visible

func _set_enemy_panel_info_visible(visible: bool) -> void:
	for path in ["EnemyPanel/ElementPill", "EnemyPanel/ElementIcon", "EnemyPanel/ElementText", "EnemyPanel/PowerIcon", "EnemyPanel/PowerCaption"]:
		_set_visible(path, visible)

func _set_enemy_card_details_visible(card: Control, visible: bool) -> void:
	for child_name in ["Level", "Power", "Stars"]:
		var item := card.get_node_or_null(child_name) as CanvasItem
		if item != null:
			item.visible = visible
	var badge := card.get_node_or_null("ElementBadge") as CanvasItem
	if badge != null:
		badge.visible = false

func _set_label_align(path: NodePath, align: HorizontalAlignment) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.horizontal_alignment = align

func _style_label(path: NodePath, color: Color, outline_color: Color, outline_size: int) -> void:
	var label := get_node_or_null(path) as Label
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", outline_size)
	label.clip_text = true

func _set_monster_card(card: Control, monster: Dictionary, is_team: bool) -> void:
	var portrait := card.get_node("Portrait") as TextureRect
	portrait.texture = _monster_texture(monster, "team" if is_team else "battle")
	# ★ 主人定 2026-06-11：精英宠物/精英怪名字前缀 ★精英
	var is_elite := bool(monster.get("isElite", false))
	var elite_prefix: String = "★精英 " if is_elite else ""
	var name_label := card.get_node("Name") as Label
	name_label.text = "%s%s" % [elite_prefix, str(monster.get("name", "精灵"))]
	name_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.10, 1.0) if is_elite else (BROWN_TEXT if is_team else BROWN_DARK))
	(card.get_node("Level") as Label).text = "Lv.%d" % int(monster.get("level", 1))
	var power := int(monster.get("power", 0))
	(card.get_node("Power") as Label).text = "战力 %d" % power if is_team else "%d" % power
	var element := MonsterDBScript.get_board_affinity(monster)
	var badge := card.get_node("ElementBadge") as TextureRect
	badge.texture = _element_texture(element)

func _set_enemy_hero_card(card: Control, enemy: Dictionary) -> void:
	_layout_enemy_hero_card(str(card.get_path()).trim_prefix(str(get_path()) + "/"))
	_set_enemy_card_details_visible(card, true)
	_set_monster_card(card, enemy, false)
	var element := MonsterDBScript.get_board_affinity(enemy)
	var element_name: String = MonsterDBScript.BOARD_AFFINITY_NAMES.get(element, _get_element_name(element))
	(get_node("EnemyPanel/ElementIcon") as TextureRect).texture = _element_texture(element)
	_label("EnemyPanel/ElementText").text = "%s系" % element_name
	_label("EnemyPanel/PowerCaption").text = "敌方战力"
	(card.get_node("Power") as Label).text = "%d" % int(enemy.get("power", 0))
	var stars := card.get_node("Stars") as Label
	stars.text = "★".repeat(clampi(int(enemy.get("rarity", 1)), 1, 5))

func _set_enemy_boss_card(card: Control, enemy: Dictionary) -> void:
	_layout_enemy_boss_card(str(card.get_path()).trim_prefix(str(get_path()) + "/"))
	_set_enemy_card_details_visible(card, false)
	var portrait := card.get_node("Portrait") as TextureRect
	portrait.texture = _monster_texture(enemy, "battle")
	var name_label := card.get_node("Name") as Label
	name_label.visible = true
	name_label.text = str(enemy.get("name", "BOSS"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _sync_power_panel() -> void:
	var player_power := _get_team_total_power(_player_team)
	var enemy_power := _get_team_total_power(_enemy_team)
	_label("PowerPanel/PlayerPower").text = "%d" % player_power
	_label("PowerPanel/EnemyPower").text = "%d" % enemy_power
	var diff := player_power - enemy_power
	var text := "势均力敌"
	var diff_color := GOLD_TEXT
	if _is_player_team_empty():
		text = "请先配置队伍"
		diff_color = Color(0.55, 0.43, 0.28, 1.0)
	elif diff > 0:
		text = "领先 %d" % diff
		diff_color = GREEN_TEXT
	elif diff < 0:
		text = "落后 %d" % -diff
		diff_color = RED_TEXT
	_label("PowerPanel/Diff").text = text
	_style_label("PowerPanel/Diff", diff_color, Color.WHITE, 1)

func _sync_mechanic_hint() -> void:
	var lines := str(_get_element_hint()).split("\n")
	_label("MechanicPanel/Line1").text = str(lines[0]) if lines.size() > 0 else ""
	_label("MechanicPanel/Line2").text = str(lines[1]) if lines.size() > 1 else ""

func _sync_synergy() -> void:
	var synergies := _calc_synergy_preview()
	if synergies.is_empty():
		_label("SynergyPanel/Line1").text = "属性协同：无（队伍属性分散）"
		_label("SynergyPanel/Line2").text = ""
	else:
		_label("SynergyPanel/Line1").text = str((synergies[0] as Dictionary).get("label", ""))
		_label("SynergyPanel/Line2").text = str((synergies[1] as Dictionary).get("label", "")) if synergies.size() > 1 else ""

func _sync_rewards() -> void:
	var stage_rewards: Dictionary = _stage_data.get("rewards", {})
	var rewards := [
		{"icon": "gold", "label": "金币\n%s" % _compact_number(int(stage_rewards.get("gold", 2400)))},
		{"icon": "exp", "label": "经验药水\n%s" % _compact_number(int(stage_rewards.get("exp", 120)))},
	]
	var guaranteed_items: Array = stage_rewards.get("guaranteedItems", [])
	if guaranteed_items.is_empty():
		rewards.append({"icon": "capture_ball", "label": "捕捉球\n5"})
	else:
		var item: Dictionary = guaranteed_items[0]
		var item_def := ItemDB.get_item(str(item.get("id", "")))
		rewards.append({"icon": "capture_ball", "label": "%s\n%s" % [str(item_def.get("name", "道具")), str(item.get("count", 1))]})
	for i in REWARD_SLOT_PATHS.size():
		var slot := _node(REWARD_SLOT_PATHS[i])
		var data: Dictionary = rewards[i]
		(slot.get_node("Icon") as TextureRect).texture = _prepare_texture(str(data.get("icon", "")))
		var label := slot.get_node("Label") as Label
		label.text = ""
		label.visible = false

func _sync_start_button() -> void:
	var is_empty := _is_player_team_empty()
	var player_power := _get_team_total_power(_player_team)
	var enemy_power := _get_team_total_power(_enemy_team)
	var is_ready := player_power > enemy_power and not is_empty
	var key := "start_button_disabled" if is_empty else ("start_button_ready" if is_ready else "start_button")
	(get_node("StartButton/Frame") as TextureRect).texture = _prepare_texture(key)
	_label("StartButton/Text").text = "请先编成队伍" if is_empty else "进入战斗"

func _sync_alert() -> void:
	if not has_node("AlertPopup"):
		return
	_node("AlertPopup").visible = _show_empty_team_alert

# 战斗准备面板入场序列：Header → 顶部资源 → 敌方 → 战力 → 队伍卡 → 奖励 → 开始按钮
func _maybe_play_entry() -> void:
	if _entry_played:
		return
	_entry_played = true
	_play_entry()

func _play_entry() -> void:
	# 1) Header：上方 30px 滑入 + 淡入
	var header := get_node_or_null("Header") as Control
	if header != null:
		var header_rest_y := header.position.y
		header.position.y = header_rest_y - 30.0
		header.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_HEADER_DELAY)
		tween.tween_property(header, "modulate:a", 1.0, ENTRY_SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(header, "position:y", header_rest_y, ENTRY_SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2) 顶部资源条：上方 20px 滑入 + 淡入
	var top_bar := get_node_or_null("TopResourceBar") as Control
	if top_bar != null:
		var top_rest_y := top_bar.position.y
		top_bar.position.y = top_rest_y - 20.0
		top_bar.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_RESOURCE_DELAY)
		tween.tween_property(top_bar, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(top_bar, "position:y", top_rest_y, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3) 敌方面板：下方 24px 滑入 + 淡入
	var enemy_panel := get_node_or_null("EnemyPanel") as Control
	if enemy_panel != null:
		var enemy_rest_y := enemy_panel.position.y
		enemy_panel.position.y = enemy_rest_y + 24.0
		enemy_panel.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_ENEMY_DELAY)
		tween.tween_property(enemy_panel, "modulate:a", 1.0, ENTRY_SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(enemy_panel, "position:y", enemy_rest_y, ENTRY_SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 4) 战力对比面板：scale 弹缩 + 淡入
	var power_panel := get_node_or_null("PowerPanel") as Control
	if power_panel != null:
		power_panel.pivot_offset = power_panel.size * 0.5
		power_panel.scale = Vector2(0.85, 0.85)
		power_panel.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_POWER_DELAY)
		tween.tween_property(power_panel, "modulate:a", 1.0, ENTRY_POP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(power_panel, "scale", Vector2(1.06, 1.06), ENTRY_POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(power_panel, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 5) 我方队伍卡：底部 pivot 弹入，依次错位
	for i in TEAM_CARD_PATHS.size():
		var card := _node(TEAM_CARD_PATHS[i])
		if not card.visible:
			continue
		card.pivot_offset = Vector2(card.size.x * 0.5, card.size.y)
		card.scale = Vector2(0.6, 0.6)
		card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_TEAM_CARD_DELAY + float(i) * ENTRY_TEAM_CARD_STAGGER)
		tween.tween_property(card, "modulate:a", 1.0, ENTRY_CARD_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(card, "scale", Vector2(1.08, 1.08), ENTRY_CARD_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 6) 奖励预览槽位：底部 pivot 弹入，依次错位
	for i in REWARD_SLOT_PATHS.size():
		var slot := _node(REWARD_SLOT_PATHS[i])
		slot.pivot_offset = Vector2(slot.size.x * 0.5, slot.size.y)
		slot.scale = Vector2(0.6, 0.6)
		slot.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_REWARD_DELAY + float(i) * ENTRY_REWARD_STAGGER)
		tween.tween_property(slot, "modulate:a", 1.0, ENTRY_CARD_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot, "scale", Vector2(1.08, 1.08), ENTRY_CARD_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(slot, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 7) 开始按钮：从大到小弹入 + 淡入（起始放大 1.25，靠 TRANS_BACK 轻微 undershoot 收敛到 1.0）
	var start := get_node_or_null("StartButton") as Control
	if start != null:
		start.pivot_offset = start.size * 0.5
		start.scale = Vector2(1.25, 1.25)
		start.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_BUTTON_DELAY)
		tween.tween_property(start, "modulate:a", 1.0, ENTRY_BUTTON_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(start, "scale", Vector2.ONE, ENTRY_BUTTON_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _prepare_texture(key: String) -> Texture2D:
	return _get_texture(str(PREPARE_ASSETS.get(key, "")))

func _element_texture(element: String) -> Texture2D:
	return _get_texture(str(ELEMENT_ICON_ASSETS.get(element, "")))

func _monster_texture(monster: Dictionary, variant: String) -> Texture2D:
	var monster_id := str(monster.get("monsterId", monster.get("id", "")))
	return _get_texture(MonsterArtDBScript.get_art_path(monster_id, variant))

func _node(path: String) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

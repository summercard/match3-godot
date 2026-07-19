# scene_battle_prepare.gd - battle_prepare.tscn node binding and sync logic
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
# Kept only for compatibility with editor/test callers of the retired preview helpers.
const REWARD_SLOT_PATHS := [
	"RewardPreview/Slots/RewardSlot1",
	"RewardPreview/Slots/RewardSlot2",
	"RewardPreview/Slots/RewardSlot3",
	"RewardPreview/Slots/RewardSlot4",
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

var _portrait_base_rect_cache: Dictionary = {}

func _ready() -> void:
	instance = self
	set_process(false)
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

func _start_battle() -> void:
	super._start_battle()
	_sync_gui()

func _sync_top_resource_bar() -> void:
	var storage := get_node_or_null("/root/SaveManager")
	var player: Dictionary = storage.get_player() if storage != null and storage.has_method("get_player") else {}
	_label("TopResourceBar/GoldChip/Value").text = _compact_number(int(player.get("gold", 12350)))
	_label("TopResourceBar/DiamondChip/Value").text = _compact_number(int(player.get("gems", 2548)))
	_label("TopResourceBar/HeartChip/Value").text = "%d/5" % int(player.get("stamina", 5))

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
	_sync_background()
	_sync_top_resource_bar()
	_label("Header/Title").text = "战斗准备"
	_label("Header/StageName").text = str(_stage_data.get("name", _stage_id))
	_sync_enemy_cards()
	_sync_power_panel()
	_sync_team_cards()
	_sync_mechanic_hint()
	_sync_synergy()
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
		var stars := card.get_node("Stars") as Label
		stars.text = ""
		stars.visible = false

func _layout_cards(_paths: Array, _count: int, _card_w: float, _gap: float, _total_w: float) -> void:
	pass

func _apply_concept_layout() -> void:
	# Visual layout is authored in battle_prepare.tscn.
	# Keep this method as a compatibility no-op for editor/test callers.
	pass

func _layout_monster_card(_path: String, _x: float, _y: float, _w: float, _h: float, _is_team_card: bool) -> void:
	pass

func _layout_enemy_hero_card(_path: String) -> void:
	pass

func _layout_enemy_boss_card(_path: String) -> void:
	pass

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
	_apply_portrait_visual_scale(portrait, _monster_visual_scale(monster))
	# ★ 主人定 2026-06-11：精英宠物/精英怪名字前缀 ★精英
	var is_elite := bool(monster.get("isElite", false))
	var elite_prefix: String = "★精英 " if is_elite else ""
	var name_label := card.get_node("Name") as Label
	name_label.text = "%s%s" % [TranslationServer.translate(elite_prefix), TranslationServer.translate(str(monster.get("name", "精灵")))]
	name_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.10, 1.0) if is_elite else (BROWN_TEXT if is_team else BROWN_DARK))
	(card.get_node("Level") as Label).text = "Lv.%d" % int(monster.get("level", 1))
	var power := int(monster.get("power", 0))
	(card.get_node("Power") as Label).text = TranslationServer.translate("战力 %d") % power if is_team else "%d" % power
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
	_label("EnemyPanel/ElementText").text = TranslationServer.translate("%s系") % TranslationServer.translate(element_name)
	_label("EnemyPanel/PowerCaption").text = "敌方战力"
	(card.get_node("Power") as Label).text = "%d" % int(enemy.get("power", 0))
	var stars := card.get_node("Stars") as Label
	stars.text = "★".repeat(clampi(int(enemy.get("rarity", 1)), 1, 5))

func _set_enemy_boss_card(card: Control, enemy: Dictionary) -> void:
	_layout_enemy_boss_card(str(card.get_path()).trim_prefix(str(get_path()) + "/"))
	_set_enemy_card_details_visible(card, false)
	var portrait := card.get_node("Portrait") as TextureRect
	portrait.texture = _monster_texture(enemy, "battle")
	_apply_portrait_visual_scale(portrait, _monster_visual_scale(enemy))
	var name_label := card.get_node("Name") as Label
	name_label.visible = true
	name_label.text = TranslationServer.translate(str(enemy.get("name", "BOSS")))
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
		text = TranslationServer.translate("领先 %d") % diff
		diff_color = GREEN_TEXT
	elif diff < 0:
		text = TranslationServer.translate("落后 %d") % -diff
		diff_color = RED_TEXT
	_label("PowerPanel/Diff").text = text

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
	var rewards := _build_reward_preview_items()
	var visible_count := mini(rewards.size(), REWARD_SLOT_PATHS.size())
	var slot_w := 48.0
	var gap := 10.0 if visible_count >= 4 else 14.0
	var total_w := float(visible_count) * slot_w + float(maxi(0, visible_count - 1)) * gap
	var start_x := (319.0 - total_w) * 0.5
	for i in REWARD_SLOT_PATHS.size():
		var slot := _node(REWARD_SLOT_PATHS[i])
		slot.visible = i < visible_count
		if i >= visible_count:
			continue
		var data: Dictionary = rewards[i]
		(slot.get_node("Icon") as TextureRect).texture = _reward_preview_texture(data)
		var label := slot.get_node("Label") as Label
		label.text = ""
		label.visible = false

func _build_reward_preview_items() -> Array[Dictionary]:
	var stage_rewards: Dictionary = _stage_data.get("rewards", {})
	var rewards: Array[Dictionary] = []
	var gold := int(stage_rewards.get("gold", 0))
	if gold > 0:
		rewards.append({"icon": "gold", "label": TranslationServer.translate("金币\n%s") % _compact_number(gold)})
	var exp := int(stage_rewards.get("exp", 0))
	if exp > 0:
		rewards.append({"icon": "exp", "label": TranslationServer.translate("经验\n%s") % _compact_number(exp)})
	var first_clear_gems := _preview_first_clear_gems()
	if first_clear_gems > 0:
		rewards.append({"icon": "diamond", "label": TranslationServer.translate("首通钻石\n+%d") % first_clear_gems})
	var guaranteed_items: Array = stage_rewards.get("guaranteedItems", [])
	for item: Dictionary in guaranteed_items:
		if rewards.size() >= REWARD_SLOT_PATHS.size():
			break
		var item_id := str(item.get("id", ""))
		if item_id.is_empty():
			continue
		var item_def := ItemDB.get_item(item_id)
		var item_name := str(item_def.get("name", item_id))
		var count := maxi(1, int(item.get("count", 1)))
		rewards.append({
			"icon": "item",
			"item_id": item_id,
			"label": "%s\nx%d" % [_short_reward_name(item_name), count],
		})
	if rewards.is_empty():
		rewards.append({"icon": "gold", "label": "通关后\n结算"})
	return rewards

func _preview_first_clear_gems() -> int:
	if _stage_id.is_empty():
		return 0
	var storage := get_node_or_null("/root/SaveManager")
	if storage != null and storage.has_method("is_stage_cleared") and storage.is_stage_cleared(_stage_id):
		return 0
	var is_boss := str(_stage_data.get("type", "")) == "boss"
	return 10 if is_boss else 3

func _short_reward_name(name: String) -> String:
	if name.length() <= 5:
		return name
	return name.substr(0, 5)

func _reward_preview_texture(data: Dictionary) -> Texture2D:
	var icon := str(data.get("icon", ""))
	if icon == "item":
		return _get_texture(_reward_item_icon_path(str(data.get("item_id", ""))))
	return _prepare_texture(icon)

func _reward_item_icon_path(item_id: String) -> String:
	if item_id in ["capture_ball_plus", "capture_ball_elite"]:
		return "res://assets/images/ui/icons/items_new_icon_capture_ball_plus.png"
	if item_id == "capture_ball":
		return "res://assets/images/ui/icons/items_new_icon_capture_ball.png"
	if item_id == "exp_crystal":
		return "res://assets/images/ui/icons/items_new_icon_exp_crystal.png"
	if item_id == "exp_potion":
		return "res://assets/images/ui/icons/items_new_icon_exp_potion.png"
	if item_id in ["gold_bag", "gold_chest"]:
		return "res://assets/images/ui/icons/items_new_icon_%s.png" % item_id
	if item_id in ["hp_potion", "hp_potion_large"]:
		return "res://assets/images/ui/icons/items_new_icon_hp_potion.png"
	if item_id in ["guard_charm", "absorb_shield"]:
		return "res://assets/images/ui/icons/battle_icon_guard_charm.png"
	if item_id in ["rock_hammer", "rock_hammer_plus"]:
		return "res://assets/images/ui/icons/battle_icon_rock_hammer.png"
	if item_id.begins_with("evolution_stone_"):
		return "res://assets/images/ui/gems/items_new_icon_%s.png" % item_id
	return "res://assets/images/ui/icons/items_new_icon_capture_ball.png"

func _sync_start_button() -> void:
	var is_empty := _is_player_team_empty()
	var player_power := _get_team_total_power(_player_team)
	var enemy_power := _get_team_total_power(_enemy_team)
	var is_ready := player_power > enemy_power and not is_empty
	var key := "start_button_disabled" if is_empty else ("start_button_ready" if is_ready else "start_button")
	var frame_texture := _prepare_texture(key)
	if frame_texture != null:
		(get_node("StartButton/Frame") as TextureRect).texture = frame_texture
	_label("StartButton/Text").text = "请先编成队伍" if is_empty else "进入战斗"

func _sync_alert() -> void:
	if not has_node("AlertPopup"):
		return
	_node("AlertPopup").visible = _show_empty_team_alert

# 战斗准备面板入场序列：Header → 顶部资源 → 敌方 → 战力 → 队伍卡 → 奖励 → 开始按钮
func _maybe_play_entry() -> void:
	_entry_played = true

func _play_entry() -> void:
	pass

func _prepare_texture(key: String) -> Texture2D:
	return _get_texture(str(PREPARE_ASSETS.get(key, "")))

func _element_texture(element: String) -> Texture2D:
	return _get_texture(str(ELEMENT_ICON_ASSETS.get(element, "")))

func _monster_texture(monster: Dictionary, variant: String) -> Texture2D:
	var monster_id := str(monster.get("monsterId", monster.get("id", "")))
	return _get_texture(MonsterArtDBScript.get_art_path(monster_id, variant))

func _monster_visual_scale(monster: Dictionary) -> float:
	return float(monster.get("_visualScale", StatCalculator.visual_scale_for_stats(monster)))

func _apply_portrait_visual_scale(portrait: TextureRect, visual_scale: float) -> void:
	var portrait_id := portrait.get_instance_id()
	if not _portrait_base_rect_cache.has(portrait_id):
		_portrait_base_rect_cache[portrait_id] = Rect2(portrait.position, portrait.size)
	var base_rect: Rect2 = _portrait_base_rect_cache[portrait_id]
	var scale := maxf(0.1, visual_scale)
	var scaled_size := base_rect.size * scale
	portrait.position = base_rect.position + (base_rect.size - scaled_size) * 0.5
	portrait.size = scaled_size
	portrait.pivot_offset = scaled_size * 0.5

func _node(path: String) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

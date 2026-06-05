# scene_battle_prepare_gui.gd - 可在 Godot 编辑器中调整的战斗准备界面
class_name SceneBattlePrepareGui
extends "res://src/ui/scene/scene_battle_prepare.gd"

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

func _ready() -> void:
	instance = self
	set_process(false)
	_connect_gui_actions()
	_sync_gui()

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
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _start_battle() -> void:
	super._start_battle()
	_sync_gui()

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Header"):
		return
	_apply_concept_layout()
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

func _sync_enemy_cards() -> void:
	_label("EnemyPanel/Title").text = "敌方信息"
	_layout_cards(ENEMY_CARD_PATHS, _enemy_team.size(), 92.0, 18.0, 327.0)
	for i in ENEMY_CARD_PATHS.size():
		var card := _node(ENEMY_CARD_PATHS[i])
		card.visible = i < _enemy_team.size()
		if i >= _enemy_team.size():
			continue
		var enemy: Dictionary = _enemy_team[i]
		_set_monster_card(card, enemy, false)

func _sync_team_cards() -> void:
	_label("TeamPanel/Title").text = "我方队伍"
	_node("TeamPanel/EmptyLabel").visible = _player_team.is_empty()
	_layout_cards(TEAM_CARD_PATHS, _player_team.size(), 92.0, 25.0, 327.0)
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
	_set_rect("Header/BackButton", 12, 22, 42, 42)
	_set_local_rect("Header/BackButton/Frame", 0, 0, 42, 42)
	_set_local_rect("Header/BackButton/Arrow", 8, 8, 26, 26)
	_set_rect("Header/Bar", 54, 14, 302, 76)
	_set_rect("Header/Title", 95, 30, 220, 34)
	_set_rect("Header/StageName", 108, 61, 194, 24)
	_set_font("Header/Title", 25)
	_set_font("Header/StageName", 12)

	_set_rect("EnemyPanel", 24, 106, 327, 142)
	_set_rect("EnemyPanel/Title", 0, 0, 327, 24)
	_set_font("EnemyPanel/Title", 16)
	_set_rect("EnemyPanel/Cards", 0, 28, 327, 114)
	for path in ENEMY_CARD_PATHS:
		_layout_monster_card(path, 0, 0, 92, 114, false)

	_set_rect("PowerPanel", 42, 254, 291, 72)
	_set_local_rect("PowerPanel/Frame", 0, 0, 291, 72)
	_set_rect("PowerPanel/Title", 0, 5, 291, 25)
	_set_rect("PowerPanel/PlayerPower", 12, 38, 105, 25)
	_set_rect("PowerPanel/EnemyPower", 174, 38, 105, 25)
	_set_rect("PowerPanel/Diff", 101, 43, 89, 22)
	_set_font("PowerPanel/Title", 17)
	_set_font("PowerPanel/PlayerPower", 15)
	_set_font("PowerPanel/EnemyPower", 15)
	_set_font("PowerPanel/Diff", 11)

	_set_rect("TeamPanel", 24, 340, 327, 126)
	_set_rect("TeamPanel/Title", 0, 0, 327, 24)
	_set_rect("TeamPanel/EmptyLabel", 0, 48, 327, 28)
	_set_font("TeamPanel/Title", 16)
	_set_rect("TeamPanel/Cards", 0, 27, 327, 114)
	for path in TEAM_CARD_PATHS:
		_layout_monster_card(path, 0, 0, 92, 114, true)

	_set_rect("MechanicPanel", 34, 486, 307, 56)
	_set_local_rect("MechanicPanel/Frame", 0, 0, 307, 56)
	_set_rect("MechanicPanel/Title", 0, 3, 307, 21)
	_set_rect("MechanicPanel/Line1", 14, 24, 279, 16)
	_set_rect("MechanicPanel/Line2", 14, 39, 279, 16)
	_set_font("MechanicPanel/Title", 14)
	_set_font("MechanicPanel/Line1", 9)
	_set_font("MechanicPanel/Line2", 9)

	_set_rect("SynergyPanel", 48, 545, 279, 28)
	_set_local_rect("SynergyPanel/Frame", 0, 0, 279, 32)
	_set_rect("SynergyPanel/Line1", 12, 0, 255, 14)
	_set_rect("SynergyPanel/Line2", 12, 14, 255, 14)
	_set_font("SynergyPanel/Line1", 9)
	_set_font("SynergyPanel/Line2", 9)

	_set_rect("RewardPreview", 36, 574, 303, 38)
	_set_rect("RewardPreview/Title", 0, 8, 82, 23)
	_set_rect("RewardPreview/Slots", 98, 0, 190, 41)
	for i in REWARD_SLOT_PATHS.size():
		var slot_path: String = REWARD_SLOT_PATHS[i]
		_set_rect(slot_path, float(i) * 62.0, 0, 46, 38)
		_set_local_rect(slot_path + "/Frame", 0, 0, 46, 38)
		_set_local_rect(slot_path + "/Icon", 8, 3, 25, 25)
		_set_local_rect(slot_path + "/Label", -4, 26, 54, 12)
		_set_font(slot_path + "/Label", 7)

	_set_rect("StartButton", 64, 612, 247, 49)
	_set_local_rect("StartButton/Frame", 0, 0, 247, 49)
	_set_local_rect("StartButton/Text", 22, 4, 203, 39)
	_set_font("StartButton/Text", 22)

func _layout_monster_card(path: String, x: float, y: float, w: float, h: float, _is_team_card: bool) -> void:
	_set_rect(path, x, y, w, h)
	_set_local_rect(path + "/Frame", 0, 0, w, h)
	_set_local_rect(path + "/Portrait", 14, 7, w - 28, 52)
	_set_local_rect(path + "/ElementBadge", 8, h - 29, 20, 20)
	_set_local_rect(path + "/Name", 8, 60, w - 16, 18)
	_set_local_rect(path + "/Level", 30, h - 31, w - 38, 14)
	_set_local_rect(path + "/Power", 30, h - 16, w - 38, 14)
	_set_local_rect(path + "/Stars", 8, h - 6, w - 16, 12)
	_set_font(path + "/Name", 10)
	_set_font(path + "/Level", 8)
	_set_font(path + "/Power", 8)
	_set_font(path + "/Stars", 7)

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

func _set_monster_card(card: Control, monster: Dictionary, is_team: bool) -> void:
	var portrait := card.get_node("Portrait") as TextureRect
	portrait.texture = _monster_texture(monster, "team" if is_team else "battle")
	(card.get_node("Name") as Label).text = str(monster.get("name", "怪物"))
	(card.get_node("Level") as Label).text = "Lv.%d" % int(monster.get("level", 1))
	(card.get_node("Power") as Label).text = "%d" % int(monster.get("power", 0))
	var element := MonsterDBScript.get_board_affinity(monster) if is_team else str(monster.get("element", ""))
	var badge := card.get_node("ElementBadge") as TextureRect
	badge.texture = _element_texture(element)

func _sync_power_panel() -> void:
	var player_power := _get_team_total_power(_player_team)
	var enemy_power := _get_team_total_power(_enemy_team)
	_label("PowerPanel/PlayerPower").text = "我方 %d" % player_power
	_label("PowerPanel/EnemyPower").text = "敌方 %d" % enemy_power
	var diff := player_power - enemy_power
	var text := "势均力敌"
	if _is_player_team_empty():
		text = "请先配置队伍"
	elif diff > 0:
		text = "领先 %d" % diff
	elif diff < 0:
		text = "落后 %d" % -diff
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
	var rewards := [
		{"icon": "gold", "label": "金币"},
		{"icon": "exp", "label": "EXP"},
	]
	var stage_rewards: Dictionary = _stage_data.get("rewards", {})
	var guaranteed_items: Array = stage_rewards.get("guaranteedItems", [])
	if guaranteed_items.is_empty():
		rewards.append({"icon": "capture_ball", "label": "捕获"})
	else:
		var item: Dictionary = guaranteed_items[0]
		var item_def := ItemDB.get_item(str(item.get("id", "")))
		rewards.append({"icon": "capture_ball", "label": str(item_def.get("name", "道具"))})
	for i in REWARD_SLOT_PATHS.size():
		var slot := _node(REWARD_SLOT_PATHS[i])
		var data: Dictionary = rewards[i]
		(slot.get_node("Icon") as TextureRect).texture = _prepare_texture(str(data.get("icon", "")))
		(slot.get_node("Label") as Label).text = str(data.get("label", ""))

func _sync_start_button() -> void:
	var is_empty := _is_player_team_empty()
	var player_power := _get_team_total_power(_player_team)
	var enemy_power := _get_team_total_power(_enemy_team)
	var is_ready := player_power > enemy_power and not is_empty
	var key := "start_button_disabled" if is_empty else ("start_button_ready" if is_ready else "start_button")
	(get_node("StartButton/Frame") as TextureRect).texture = _prepare_texture(key)
	_label("StartButton/Text").text = "请先编成队伍" if is_empty else "开始战斗"

func _sync_alert() -> void:
	if not has_node("AlertPopup"):
		return
	_node("AlertPopup").visible = _show_empty_team_alert

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

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
	_layout_cards(ENEMY_CARD_PATHS, _enemy_team.size(), 88.0, 12.0, 345.0)
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
	_layout_cards(TEAM_CARD_PATHS, _player_team.size(), 96.0, 14.0, 345.0)
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

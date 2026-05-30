# scene_result_gui.gd - 可在 Godot 编辑器中调整的战斗结算与捕捉结果界面
class_name SceneResultGui
extends "res://src/ui/scene/scene_result.gd"

const STAR_PATHS := ["StarRow/Star1", "StarRow/Star2", "StarRow/Star3"]
const REWARD_SLOT_PATHS := [
	"RewardPanel/Slots/RewardSlot1",
	"RewardPanel/Slots/RewardSlot2",
	"RewardPanel/Slots/RewardSlot3",
]
const EXP_CARD_PATHS := [
	"ExpPanel/Cards/ExpCard1",
	"ExpPanel/Cards/ExpCard2",
	"ExpPanel/Cards/ExpCard3",
]

func _ready() -> void:
	name = "SceneResult"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_connect_gui_actions()
	_sync_gui()

func init(data: Dictionary = {}) -> void:
	initialize(get_node_or_null("/root/GameManager"), data)

func initialize(game: Node, battle_result: Dictionary) -> void:
	super.initialize(game, battle_result)
	_sync_gui()

func _process(delta: float) -> void:
	super._process(delta)
	_sync_gui()

func _draw() -> void:
	pass

func _gui_input(_event: InputEvent) -> void:
	pass

func _connect_gui_actions() -> void:
	_connect_button("Buttons/BackButton", _on_back_btn_pressed)
	_connect_button("Buttons/NextButton", _on_next_btn_pressed)
	_connect_button("Buttons/RetryButton", _on_retry_btn_pressed)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Banner"):
		return
	_sync_banner()
	_sync_stars()
	_sync_battle_info()
	_sync_capture_panel()
	_sync_rewards()
	_sync_exp_panel()
	_sync_levelups()
	_sync_buttons()

func _sync_banner() -> void:
	var banner_key := "victory_banner" if _is_win else "defeat_banner"
	(get_node("Banner/Frame") as TextureRect).texture = _result_texture(banner_key)
	_label("Banner/Title").text = "战斗胜利" if _is_win else "战斗失败"
	_node("WinFx").visible = _is_win

func _sync_stars() -> void:
	for i in STAR_PATHS.size():
		var key := "star_lit" if i < _stars else "star_dim"
		(get_node(STAR_PATHS[i]) as TextureRect).texture = _result_texture(key)

func _sync_battle_info() -> void:
	var turn_count := int(_battle_result.get("turnCount", 0))
	var max_turns := int(_battle_result.get("maxTurns", 20))
	_label("BattleInfo/TurnLabel").text = "回合 %d / %d" % [turn_count, max_turns]
	var enemies: Array = _battle_result.get("enemies", [])
	var defeated := enemies.filter(func(e): return e and int(e.get("hp", 0)) <= 0)
	var alive := enemies.filter(func(e): return e and int(e.get("hp", 0)) > 0)
	if not defeated.is_empty():
		_label("BattleInfo/EnemyLabel").text = "击败：" + " / ".join(defeated.map(func(e): return str(e.get("name", e.get("emoji", "")))))
	elif not alive.is_empty():
		_label("BattleInfo/EnemyLabel").text = "仍在场：" + " / ".join(alive.map(func(e): return str(e.get("name", e.get("emoji", "")))))
	else:
		_label("BattleInfo/EnemyLabel").text = ""

func _sync_capture_panel() -> void:
	var panel := _node("CaptureResultPanel")
	panel.visible = _is_win and not _capture_result.is_empty()
	if not panel.visible:
		return
	(panel.get_node("Ring") as TextureRect).texture = _result_texture("fx_capture_ring")
	(panel.get_node("MonsterPortrait") as TextureRect).texture = _monster_texture(_capture_target, "result")
	(panel.get_node("Plaque") as TextureRect).texture = _result_texture("capture_plaque")
	(panel.get_node("Title") as Label).text = str(_capture_result.get("title", ""))
	var lines := _capture_lines()
	(panel.get_node("Line1") as Label).text = str(lines[0]) if lines.size() > 0 else ""
	(panel.get_node("Line2") as Label).text = str(lines[1]) if lines.size() > 1 else ""
	(panel.get_node("Line3") as Label).text = str(lines[2]) if lines.size() > 2 else ""

func _capture_lines() -> Array[String]:
	var lines: Array[String] = []
	if not _capture_target.is_empty():
		var target_tags: Array = _capture_result.get("target_tags", [])
		if target_tags.is_empty():
			target_tags = CaptureSystemScript.get_target_value_tags(_capture_target)
		lines.append("目标: %s  %s" % [str(_capture_target.get("name", "")), " / ".join(target_tags.slice(0, 3))])
	if not _capture_item_used.is_empty():
		lines.append("消耗: %s" % str(_capture_item_used.get("name", "")))
	var reason := str(_capture_result.get("reason", ""))
	if reason.is_empty() and not _capture_window.is_empty():
		reason = "窗口: %s %d%%" % [str(_capture_window.get("label", "")), int(round(float(_capture_window.get("stability", 0.0)) * 100.0))]
	if not reason.is_empty():
		lines.append(reason)
	var advice := str(_capture_result.get("advice", ""))
	if not advice.is_empty() and not _captured:
		lines.append(advice)
	return lines.slice(0, 3)

func _sync_rewards() -> void:
	var reward_items: Array[Dictionary] = [
		{"icon": "gold", "amount": "+%d" % int(_rewards.get("gold", 0))},
		{"icon": "exp", "amount": "+%d" % int(_rewards.get("exp", 0))},
	]
	if _rewards.get("item", null):
		reward_items.append({"icon": "capture_ball", "amount": "x%d" % maxi(1, int(_rewards.get("item_count", 1)))})
	elif _is_win:
		reward_items.append({"icon": "gem_grass", "amount": "x2"})
	for i in REWARD_SLOT_PATHS.size():
		var slot := _node(REWARD_SLOT_PATHS[i])
		slot.visible = i < reward_items.size()
		if i >= reward_items.size():
			continue
		var item := reward_items[i]
		(slot.get_node("Icon") as TextureRect).texture = _result_texture(str(item.get("icon", "")))
		(slot.get_node("Amount") as Label).text = str(item.get("amount", ""))

func _sync_exp_panel() -> void:
	var stage_rewards: Dictionary = _battle_result.get("stageRewards", {})
	var desc := "统一默认奖励"
	if stage_rewards.has("exp"):
		desc = "基础 %d × %.1fx 星级系数" % [int(stage_rewards.get("exp", 0)), RewardRulesScript.get_star_multiplier(_stars)]
	_label("ExpPanel/Desc").text = desc
	var team: Array = _battle_result.get("playerTeam", [])
	var display_team := team.filter(func(m): return m != null).slice(0, EXP_CARD_PATHS.size())
	for i in EXP_CARD_PATHS.size():
		var card := _node(EXP_CARD_PATHS[i])
		card.visible = i < display_team.size()
		if i >= display_team.size():
			continue
		var monster: Dictionary = display_team[i]
		var member_id := str(monster.get("id", ""))
		var award: Dictionary = _monster_exp_awards.get(member_id, {})
		var award_exp := int(award.get("exp", 0))
		var catchup: Dictionary = award.get("catchup", {})
		(card.get_node("Portrait") as TextureRect).texture = _monster_texture(monster, "result")
		(card.get_node("Level") as Label).text = "Lv.%d" % int(monster.get("level", 1))
		var exp_text := "+%d" % award_exp
		if bool(catchup.get("enabled", false)):
			exp_text = "+%d %s" % [award_exp, str(catchup.get("label", ""))]
		(card.get_node("Exp") as Label).text = exp_text

func _sync_levelups() -> void:
	_node("LevelUpPanel").visible = not _level_ups.is_empty()
	_node("SweepUnlocked").visible = _stars >= 3 and _level_ups.is_empty()
	if _level_ups.is_empty():
		return
	var first: Dictionary = _level_ups[0]
	_label("LevelUpPanel/Text").text = "%s Lv.%d -> Lv.%d" % [
		str(first.get("monsterId", "?")),
		int(first.get("oldLevel", 0)),
		int(first.get("newLevel", 0)),
	]

func _sync_buttons() -> void:
	_node("Buttons/BackButton").visible = _is_win or _has_next_stage
	_node("Buttons/NextButton").visible = _is_win and _has_next_stage
	_node("Buttons/RetryButton").visible = _has_next_stage or not _is_win
	_label("Buttons/BackButton/Text").text = "返回" if _has_next_stage else ("返回关卡" if _is_win else "重试")
	_label("Buttons/NextButton/Text").text = "下一关"
	_label("Buttons/RetryButton/Text").text = "再来一次" if _is_win else "重试"

func _result_texture(key: String) -> Texture2D:
	var path := str(RESULT_ASSETS.get(key, COMMON_ASSETS.get(key, "")))
	return _get_texture(path)

func _monster_texture(monster: Dictionary, variant: String) -> Texture2D:
	if monster.is_empty():
		return null
	var monster_id := str(monster.get("monsterId", monster.get("id", "")))
	return _get_texture(MonsterArtDBScript.get_art_path(monster_id, variant))

func _node(path: String) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

# scene_result.gd - 战斗结算场景
# 源文件: js/ui/sceneResult.js
# 翻译版本: GDScript 4.x
class_name SceneResult
extends Control

# === 静态常量 ===
const DESIGN_W: float = 375.0
const STAR_MULTIPLIERS: Array[float] = [0.0, 0.6, 0.8, 1.0, 1.2, 1.5]

# === 成员变量：UI 根节点 ===
var _title_label: Label
var _stars_container: HBoxContainer
var _battle_info_panel: PanelContainer
var _capture_panel: PanelContainer
var _rewards_panel: PanelContainer
var _exp_panel: PanelContainer
var _levelups_container: VBoxContainer
var _sweep_unlocked_label: Label
var _buttons_container: HBoxContainer
var _next_btn: Button
var _back_btn: Button

# === 成员变量：Panel 内部子节点 ===
var _turn_label: Label
var _defeated_label: Label
var _alive_label: Label
var _capture_title_label: Label
var _capture_desc_label: Label
var _gold_label: Label
var _item_label: Label
var _exp_label: Label
var _exp_source_label: Label

# === 成员变量：游戏数据 ===
var _game: Node = null
var _storage: Node = null
var _achievement_manager: Node = null

# 战斗结果
var _battle_result: Dictionary = {}
var _is_win: bool = false

# 星级计算
var _stars: int = 0

# 收服系统
var _capture_target: Dictionary = {}
var _captured: bool = false
var _capture_result: Dictionary = {}
var _capture_item_used: Dictionary = {}

# 奖励
var _rewards: Dictionary = {
	"gold": 0,
	"exp": 0,
	"item": null,
	"item_name": ""
}

# 升级记录
var _level_ups: Array[Dictionary] = []

# 动画进度
var _star_anim_progress: float = 0.0
var _reward_anim_progress: float = 0.0
var _exp_anim_progress: float = 0.0
var _button_anim_progress: float = 0.0

# 按钮状态
var _has_next_stage: bool = false

# 收服特效
var _shake_offset_x: float = 0.0
var _capture_anim_timer: float = 0.0
var _capture_effect_node: CaptureEffect = null

# 入场动画
var _entry_offset_y: float = 200.0  # 从下方200px开始滑入
var _entry_timer: float = 0.0
const ENTRY_DURATION: float = 0.4

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
	name = "SceneResult"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_ui()

func _process(delta: float) -> void:
	_update_animation(delta)

# ==================== UI 创建 ====================

func _create_ui() -> void:
	# 主滚动容器
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	
	# 主垂直容器
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)
	
	# 标题
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)
	
	# 星级容器
	_stars_container = HBoxContainer.new()
	_stars_container.name = "StarsContainer"
	_stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_stars_container)
	
	# 战斗信息面板
	_battle_info_panel = _create_battle_info_panel()
	vbox.add_child(_battle_info_panel)
	
	# 收服结果面板
	_capture_panel = _create_capture_panel()
	vbox.add_child(_capture_panel)
	
	# 奖励面板
	_rewards_panel = _create_rewards_panel()
	vbox.add_child(_rewards_panel)
	
	# 经验面板
	_exp_panel = _create_exp_panel()
	vbox.add_child(_exp_panel)
	
	# 升级提示容器
	_levelups_container = VBoxContainer.new()
	_levelups_container.name = "LevelupsContainer"
	vbox.add_child(_levelups_container)
	
	# 扫荡解锁提示
	_sweep_unlocked_label = Label.new()
	_sweep_unlocked_label.name = "SweepUnlockedLabel"
	_sweep_unlocked_label.text = "🔓 扫荡功能已解锁！"
	_sweep_unlocked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sweep_unlocked_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	_sweep_unlocked_label.visible = false
	vbox.add_child(_sweep_unlocked_label)
	
	# 按钮容器
	_buttons_container = HBoxContainer.new()
	_buttons_container.name = "ButtonsContainer"
	_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_buttons_container)
	
	# 下一关按钮
	_next_btn = Button.new()
	_next_btn.name = "NextBtn"
	_next_btn.text = "下一关"
	_next_btn.custom_minimum_size = Vector2(120, 40)
	_next_btn.pressed.connect(_on_next_btn_pressed)
	_next_btn.visible = false
	_buttons_container.add_child(_next_btn)
	
	# 返回/重试按钮
	_back_btn = Button.new()
	_back_btn.name = "BackBtn"
	_back_btn.text = "返回"
	_back_btn.custom_minimum_size = Vector2(120, 40)
	_back_btn.pressed.connect(_on_back_btn_pressed)
	_buttons_container.add_child(_back_btn)

func _create_battle_info_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "BattleInfoPanel"
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	_turn_label = Label.new()
	_turn_label.name = "TurnLabel"
	vbox.add_child(_turn_label)
	
	_defeated_label = Label.new()
	_defeated_label.name = "DefeatedLabel"
	vbox.add_child(_defeated_label)
	
	_alive_label = Label.new()
	_alive_label.name = "AliveLabel"
	vbox.add_child(_alive_label)
	
	return panel

func _create_capture_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "CapturePanel"
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	_capture_title_label = Label.new()
	_capture_title_label.name = "TitleLabel"
	_capture_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_capture_title_label)
	
	_capture_desc_label = Label.new()
	_capture_desc_label.name = "DescLabel"
	_capture_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_capture_desc_label)
	
	return panel

func _create_rewards_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "RewardsPanel"
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	vbox.add_child(_gold_label)
	
	_item_label = Label.new()
	_item_label.name = "ItemLabel"
	vbox.add_child(_item_label)
	
	return panel

func _create_exp_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ExpPanel"
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	_exp_label = Label.new()
	_exp_label.name = "ExpLabel"
	vbox.add_child(_exp_label)
	
	_exp_source_label = Label.new()
	_exp_source_label.name = "SourceLabel"
	_exp_source_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(_exp_source_label)
	
	return panel

# ==================== 初始化 ====================

func initialize(game: Node, battle_result: Dictionary) -> void:
	_game = game
	_storage = game.storage if game and "storage" in game else get_node_or_null("/root/SaveManager")
	if _game and _game.has_node("AchievementManager"):
		_achievement_manager = _game.get_node("AchievementManager")
	_battle_result = battle_result
	_is_win = battle_result.get("result", "") == "win"
	
	_calc_stars()
	
	# Phase 4: 检查收服特效是否已在 scene_battle 中 inline 播放
	var capture_played_inline: bool = battle_result.get("capture_played_inline", false)
	if capture_played_inline:
		# 直接使用 battle 传来的收服结果，不再重播特效
		_captured = battle_result.get("captured", false)
		_capture_target = battle_result.get("capture_target", {})
		_capture_result = battle_result.get("capture_result_text", {})
		_capture_item_used = battle_result.get("capture_item_used", {})
		# 跳过收服计算和特效播放，直接进入后续流程
		_save_rewards()
	else:
		if _is_win:
			_process_capture()
	
	if not capture_played_inline:
		_calc_rewards()
		_setup_buttons()
		_save_rewards()
	else:
		_calc_rewards()
		_setup_buttons()
	
	if _is_win and _battle_result.has("stageId"):
		if _storage and _storage.has_method("save_stage_stars"):
			_storage.save_stage_stars(_battle_result["stageId"], _stars)
	
	if not capture_played_inline:
		_trigger_achievements()
	else:
		_trigger_achievements()
	
	_update_ui()

func init(data: Dictionary = {}) -> void:
	var game := get_node_or_null("/root/GameManager")
	initialize(game, data)

func _calc_stars() -> void:
	var player_team: Array = _battle_result.get("playerTeam", [])
	var alive_hp: float = 0.0
	var max_hp: float = 0.0
	
	for monster: Dictionary in player_team:
		if monster:
			alive_hp += monster.get("hp", 0)
			max_hp += monster.get("maxHP", 0)
	
	var hp_ratio: float = alive_hp / max_hp if max_hp > 0.0 else 0.0
	var turn_count: int = _battle_result.get("turnCount", 0)
	var max_turns: int = _battle_result.get("maxTurns", 20)
	
	_stars = _calculate_battle_stars(turn_count, max_turns, hp_ratio)

func _calculate_battle_stars(turns: int, max_turns: int, hp_ratio: float) -> int:
	var ratio_score: float = hp_ratio
	var turn_score: float = 1.0 - (turns as float / max(1, max_turns) as float)
	
	var total: float = ratio_score * 0.6 + turn_score * 0.4
	
	if total >= 0.8:
		return 3
	elif total >= 0.5:
		return 2
	else:
		return 1

func _process_capture() -> void:
	var enemies: Array = _battle_result.get("enemies", [])
	
	var target_enemy: Dictionary = {}
	for enemy: Dictionary in enemies:
		if enemy and enemy.get("hp", 0) > 0:
			target_enemy = enemy
			break
	
	if target_enemy.is_empty():
		var valid_enemies: Array = enemies.filter(func(e): return e and e.has("id"))
		if not valid_enemies.is_empty():
			target_enemy = valid_enemies[randi() % valid_enemies.size()]
	
	if not target_enemy.is_empty():
		_capture_target = target_enemy
		var enemy_rarity: int = target_enemy.get("rarity", 1)
		
		var player: Dictionary = {}
		if _storage and _storage.has_method("load_player"):
			player = _storage.load_player()
		var consecutive_fails: int = player.get("captureFails", 0)
		
		var prob: float = _calc_capture_probability(target_enemy.get("hp", 0), target_enemy.get("maxHP", 1), _battle_result.get("playerLevel", 1), _battle_result.get("enemyLevel", 1), enemy_rarity, consecutive_fails)
		
		var bonus: float = _consume_best_capture_item()
		if bonus > 0:
			prob = minf(0.95, prob + bonus)
		
		_captured = randf() < prob
		_capture_result = _get_capture_result_text(prob, _captured)
		
		if _storage and _storage.has_method("load_player") and _storage.has_method("save_player"):
			var player_data: Dictionary = _storage.load_player()
			player_data["captureFails"] = 0 if _captured else (consecutive_fails + 1)
			_storage.save_player(player_data)
		
		# 播放收服特效（CaptureEffect 闪白+弹跳+GET! / 震动+MISS）
		_play_capture_effect()

func _calc_capture_probability(hp: float, max_hp: float, player_level: int, enemy_level: int, rarity: int, consecutive_fails: int) -> float:
	var hp_ratio: float = hp / max_hp if max_hp > 0.0 else 0.0
	var base_prob: float = 0.3 + (1.0 - hp_ratio) * 0.4
	base_prob += (player_level - enemy_level) * 0.02
	base_prob -= rarity * 0.05
	base_prob += mini(consecutive_fails * 0.05, 0.2)
	return clampf(base_prob, 0.05, 0.9)

func _consume_best_capture_item() -> float:
	if not _storage or not _storage.has_method("load_inventory") or not _storage.has_method("use_item"):
		return 0.0
	
	var inventory: Dictionary = _storage.load_inventory()
	var candidates: Array[Dictionary] = [
		{"id": "capture_ball_plus", "bonus": 0.30, "name": "超级捕获球"},
		{"id": "capture_ball", "bonus": 0.15, "name": "捕获球"}
	]
	
	for candidate: Dictionary in candidates:
		if inventory.get(candidate["id"], 0) > 0:
			if _storage.use_item(candidate["id"], 1):
				_capture_item_used = candidate
				return candidate["bonus"]
	
	return 0.0

func _get_capture_result_text(prob: float, captured: bool) -> Dictionary:
	if captured:
		return {"title": "🎉 收服成功！", "desc": "怪物已被收入囊中！"}
	else:
		return {"title": "💀 收服失败", "desc": "收服失败（概率 %.0f%%）" % (prob * 100.0)}

func _start_shake_animation() -> void:
	_capture_anim_timer = 0.5

func _play_capture_effect() -> void:
	# 计算收服目标怪物在屏幕上的中心位置（敌方区域 y≈80-170）
	var center_pos := Vector2(DESIGN_W / 2.0, 125.0)
	if not _capture_target.is_empty():
		var enemies: Array = _battle_result.get("enemies", [])
		var idx: int = enemies.find(_capture_target)
		if idx < 0:
			# 回退：在 enemies 数组中查找 id 匹配的
			for i: int in range(enemies.size()):
				if enemies[i] and enemies[i].get("id", "") == _capture_target.get("id", ""):
					idx = i
					break
		if idx >= 0:
			center_pos = Vector2(15.0 + idx * 120.0 + 55.0, 125.0)
	
	_capture_effect_node = CaptureEffect.play_capture(self, _captured, center_pos)

func _calc_rewards() -> void:
	var stage_rewards: Dictionary = _battle_result.get("stageRewards", {})
	
	var star_multiplier: float = STAR_MULTIPLIERS[_stars] if _stars < STAR_MULTIPLIERS.size() else 1.0
	
	if stage_rewards.has("gold") and stage_rewards.has("exp"):
		if _is_win:
			_rewards["gold"] = int(round(stage_rewards["gold"] * star_multiplier))
			_rewards["exp"] = int(round(stage_rewards["exp"] * star_multiplier))
		else:
			_rewards["gold"] = int(round(stage_rewards["gold"] * 0.3))
			_rewards["exp"] = int(round(stage_rewards["exp"] * 0.3))
	else:
		_rewards["gold"] = 100 + _stars * 50 if _is_win else 30
		_rewards["exp"] = 100 + _stars * 20 if _is_win else 30
	
	_rewards["item"] = null
	_rewards["item_name"] = ""
	if _is_win and randf() < 0.3:
		if _storage and _storage.has_method("roll_drop"):
			var item_id: String = _storage.roll_drop()
			if not item_id.is_empty():
				_rewards["item"] = item_id
				_rewards["item_name"] = item_id

# ==================== 按钮设置 ====================

func _setup_buttons() -> void:
	if _is_win and _battle_result.has("stageId"):
		_has_next_stage = not _find_next_stage(_battle_result["stageId"]).is_empty()
		if _has_next_stage:
			_next_btn.visible = true
			_back_btn.text = "返回关卡"
		else:
			_next_btn.visible = false
			_back_btn.text = "返回关卡"
	else:
		_has_next_stage = false
		_next_btn.visible = false
		_back_btn.text = "重试"

# ==================== 奖励保存 ====================

func _save_rewards() -> void:
	if not _storage:
		return
	
	if _rewards["gold"] > 0:
		if _storage.has_method("add_gold"):
			_storage.add_gold(_rewards["gold"])
	
	if _rewards["exp"] > 0:
		if _storage.has_method("add_player_exp"):
			_storage.add_player_exp(_rewards["exp"])
	
	_add_monster_exp_from_battle()
	
	if _captured and not _capture_target.is_empty() and _capture_target.has("id"):
		var player: Dictionary = _storage.load_player() if _storage.has_method("load_player") else {}
		var captured_list: Array = player.get("captured", [])
		if not captured_list.has(_capture_target["id"]):
			captured_list.append(_capture_target["id"])
			player["captured"] = captured_list
			_storage.save_player(player) if _storage.has_method("save_player") else null
			_storage.init_monster_pokedex(_capture_target["id"]) if _storage.has_method("init_monster_pokedex") else null
	
	if _rewards["item"]:
		if _storage.has_method("add_item"):
			_storage.add_item(_rewards["item"], 1)
	
	var rewards: Dictionary = _storage.load_rewards() if _storage.has_method("load_rewards") else {}
	rewards["totalGoldEarned"] = rewards.get("totalGoldEarned", 0) + _rewards["gold"]
	rewards["battleCount"] = rewards.get("battleCount", 0) + 1
	if _captured:
		rewards["captureCount"] = rewards.get("captureCount", 0) + 1
	if _rewards["item"]:
		rewards["totalItemsGained"] = rewards.get("totalItemsGained", 0) + 1
	_storage.save_rewards(rewards) if _storage.has_method("save_rewards") else null

func _add_monster_exp_from_battle() -> void:
	if not _is_win or not _storage:
		return
	
	var team: Dictionary = _storage.load_team() if _storage.has_method("load_team") else {}
	var team_members: Array = [team.get("leader"), team.get("member1"), team.get("member2")].filter(func(x): return x)
	
	if team_members.is_empty():
		return
	
	var stage_rewards: Dictionary = _battle_result.get("stageRewards", {})
	var base_exp: int = stage_rewards.get("exp", 100) if stage_rewards else 100
	var exp_to_add: int = int(round(base_exp * 0.5))
	
	var player_team: Array = _battle_result.get("playerTeam", [])
	
	for monster_id: String in team_members:
		var battle_monster: Dictionary = {}
		for m: Dictionary in player_team:
			if m and m.get("id") == monster_id:
				battle_monster = m
				break
		
		if not battle_monster.is_empty() and battle_monster.get("hp", 0) > 0:
			if _storage.has_method("init_monster_pokedex"):
				_storage.init_monster_pokedex(monster_id)
			
			if _storage.has_method("add_monster_exp"):
				var result: Dictionary = _storage.add_monster_exp(monster_id, exp_to_add)
				if result.get("leveledUp", false):
					_level_ups.append({
						"monsterId": monster_id,
						"oldLevel": result.get("oldLevel", 0),
						"newLevel": result.get("newLevel", 0),
						"expGained": result.get("expGained", 0)
					})

# ==================== 成就触发 ====================

func _trigger_achievements() -> void:
	if not _achievement_manager:
		return
	
	_achievement_manager.check_achievements("battleEnd", {"won": _is_win})
	
	if _is_win:
		_achievement_manager.check_achievements("stageClear", 1)
	
	var total_damage_dealt: Dictionary = _battle_result.get("totalDamageDealt", {})
	if not total_damage_dealt.is_empty():
		var total: float = 0.0
		for v: float in total_damage_dealt.values():
			total += v
		if total > 0:
			_achievement_manager.check_achievements("damageDealt", total)
	
	if _rewards["gold"] > 0:
		_achievement_manager.check_achievements("goldEarned", _rewards["gold"])
	
	if _captured:
		_achievement_manager.check_achievements("capture", 1)

# ==================== 关卡查找 ====================

func _find_next_stage(current_stage_id: String) -> String:
	if not _storage or not _storage.has_method("get_stage_chapters"):
		return ""
	
	var chapters: Array = _storage.get_stage_chapters()
	for chapter: Dictionary in chapters:
		var stages: Array = chapter.get("stages", [])
		for i: int in range(stages.size()):
			if stages[i].get("id") == current_stage_id:
				if i < stages.size() - 1:
					return stages[i + 1].get("id", "")
				var ch_idx: int = chapters.find(chapter)
				if ch_idx < chapters.size() - 1:
					var next_ch: Dictionary = chapters[ch_idx + 1]
					var next_stages: Array = next_ch.get("stages", [])
					if not next_stages.is_empty():
						return next_stages[0].get("id", "")
				return ""
	return ""

func _infer_chapter_index(stage_id: String) -> int:
	if stage_id.begins_with("stage_"):
		var parts: Array = stage_id.split("_")
		if parts.size() >= 2 and parts[1].is_valid_int():
			return int(parts[1]) - 1
	return 0

# ==================== UI 更新 ====================

func _update_ui() -> void:
	_title_label.text = "🎉 战斗胜利!" if _is_win else "💀 战斗失败"
	
	_update_stars_display()
	_update_battle_info()
	_update_capture_panel()
	_update_rewards_panel()
	_update_exp_panel()
	_update_levelups()
	
	_sweep_unlocked_label.visible = _button_anim_progress >= 1.0 and _stars >= 3

func _update_stars_display() -> void:
	for child: Node in _stars_container.get_children():
		child.queue_free()
	
	var display_stars: int = mini(_stars, 3)
	
	for i: int in range(3):
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(40, 40)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if i < display_stars:
			if ResourceLoader.exists("res://assets/images/stage/icon_star_lit.png"):
				tex_rect.texture = load("res://assets/images/stage/icon_star_lit.png")
			else:
				# Fallback to label
				var label := Label.new()
				label.text = "⭐"
				label.add_theme_font_size_override("font_size", 32)
				label.add_theme_color_override("font_color", Color(1, 0.84, 0))
				_stars_container.add_child(label)
				continue
		else:
			if ResourceLoader.exists("res://assets/images/stage/icon_star_dim.png"):
				tex_rect.texture = load("res://assets/images/stage/icon_star_dim.png")
			else:
				var label := Label.new()
				label.text = "☆"
				label.add_theme_font_size_override("font_size", 32)
				label.add_theme_color_override("font_color", Color(1, 0.84, 0, 0.3))
				_stars_container.add_child(label)
				continue
		tex_rect.modulate = Color(1, 0.84, 0, 1) if i < display_stars else Color(1, 1, 1, 0.3)
		_stars_container.add_child(tex_rect)

func _update_battle_info() -> void:
	if _turn_label:
		_turn_label.text = "回合: %d / %d" % [_battle_result.get("turnCount", 0), _battle_result.get("maxTurns", 20)]
	
	if _defeated_label or _alive_label:
		var enemies: Array = _battle_result.get("enemies", [])
		var defeated: Array = enemies.filter(func(e): return e and e.get("hp", 0) <= 0)
		var alive: Array = enemies.filter(func(e): return e and e.get("hp", 0) > 0)
		if _defeated_label:
			_defeated_label.text = "击败: %s" % " ".join(defeated.map(func(e): return e.get("emoji", "")))
		if _alive_label:
			_alive_label.text = "存活: %s" % " ".join(alive.map(func(e): return e.get("emoji", "")))

func _update_capture_panel() -> void:
	_capture_panel.visible = _reward_anim_progress >= 1.0 and _is_win
	if not _capture_panel.visible:
		return
	
	if _capture_title_label and not _capture_result.is_empty():
		_capture_title_label.text = _capture_result.get("title", "")
	if _capture_desc_label:
		_capture_desc_label.text = _capture_result.get("desc", "")

func _update_rewards_panel() -> void:
	if _gold_label:
		_gold_label.text = "+%d 金币" % _rewards["gold"]
	if _item_label:
		if _rewards["item"]:
			_item_label.text = "+1 %s" % _rewards["item_name"]
		else:
			_item_label.text = "(无道具)"

func _update_exp_panel() -> void:
	if _exp_label:
		_exp_label.text = "+%d 经验" % _rewards["exp"]
	if _exp_source_label:
		var stage_rewards: Dictionary = _battle_result.get("stageRewards", {})
		if stage_rewards.has("exp"):
			var mult = STAR_MULTIPLIERS[_stars] if _stars < STAR_MULTIPLIERS.size() else 1.0
			_exp_source_label.text = "(关卡基础 %d × %.1fx 星级系数)" % [stage_rewards["exp"], mult]
		else:
			var base_exp: int = 100 if _is_win else 30
			var star_bonus: int = _stars * 20
			_exp_source_label.text = "(基础 %d + 星级加成 %d)" % [base_exp, star_bonus]

func _update_levelups() -> void:
	for child: Node in _levelups_container.get_children():
		child.queue_free()
	
	if _level_ups.is_empty() or _exp_anim_progress < 1.0:
		_levelups_container.visible = false
		return
	
	_levelups_container.visible = true
	var display_ups: Array = _level_ups.slice(0, 2)
	
	for up: Dictionary in display_ups:
		var hbox: HBoxContainer = HBoxContainer.new()
		
		var icon: Label = Label.new()
		icon.text = "⬆️"
		hbox.add_child(icon)
		
		var name_lbl: Label = Label.new()
		name_lbl.text = up.get("monsterId", "?")
		name_lbl.add_theme_color_override("font_color", Color.YELLOW)
		hbox.add_child(name_lbl)
		
		var level_lbl: Label = Label.new()
		level_lbl.text = "Lv.%d → Lv.%d" % [up.get("oldLevel", 0), up.get("newLevel", 0)]
		level_lbl.add_theme_color_override("font_color", Color.GREEN)
		hbox.add_child(level_lbl)
		
		_levelups_container.add_child(hbox)

# ==================== 动画更新 ====================

func _update_animation(delta: float) -> void:
	# 入场动画：从下方滑入 + 淡入（0.4s）
	if _entry_timer < ENTRY_DURATION:
		_entry_timer += delta
		var progress: float = clamp(_entry_timer / ENTRY_DURATION, 0.0, 1.0)
		var ease_progress: float = ease(progress, 0.5)  # ease_out
		_entry_offset_y = lerp(200.0, 0.0, ease_progress)
	else:
		_entry_offset_y = 0.0
	
	# 应用偏移到主容器
	if has_node("ScrollContainer"):
		var scroll: ScrollContainer = get_node("ScrollContainer")
		scroll.position.y = _entry_offset_y
	
	if _capture_anim_timer > 0:
		_capture_anim_timer -= delta
		_shake_offset_x = sin(_capture_anim_timer * 80.0) * 5.0
	else:
		_shake_offset_x = 0.0
	
	if _star_anim_progress < 1.0:
		_star_anim_progress = minf(1.0, _star_anim_progress + delta * 2.5)
	elif _reward_anim_progress < 1.0:
		_reward_anim_progress = minf(1.0, _reward_anim_progress + delta * 2.0)
	elif _exp_anim_progress < 1.0:
		_exp_anim_progress = minf(1.0, _exp_anim_progress + delta * 2.0)
	elif _button_anim_progress < 1.0:
		_button_anim_progress = minf(1.0, _button_anim_progress + delta * 3.0)
	
	if _capture_panel and _shake_offset_x != 0.0:
		_capture_panel.position.x = _shake_offset_x
	
	_sweep_unlocked_label.visible = _button_anim_progress >= 1.0 and _stars >= 3

# ==================== 按钮回调 ====================

func _on_next_btn_pressed() -> void:
	if _is_win and _has_next_stage:
		var next_stage_id: String = _find_next_stage(_battle_result.get("stageId", ""))
		if not next_stage_id.is_empty():
			var chapters: Array = []
			if _storage and _storage.has_method("get_stage_chapters"):
				chapters = _storage.get_stage_chapters()
			
			var stage_data: Dictionary = {}
			for chapter: Dictionary in chapters:
				for stage: Dictionary in chapter.get("stages", []):
					if stage.get("id") == next_stage_id:
						stage_data = stage
						break
			
			_go_to_scene("battle_prepare", {"stageId": next_stage_id, "stageData": stage_data})

func _on_back_btn_pressed() -> void:
	var chapter_index: int = _infer_chapter_index(_battle_result.get("stageId", ""))
	
	if _is_win:
		_go_to_scene("stage_select", {"chapter_index": chapter_index})
	else:
		var stage_id: String = _battle_result.get("stageId", "stage_1_1")
		var chapters: Array = []
		if _storage and _storage.has_method("get_stage_chapters"):
			chapters = _storage.get_stage_chapters()
		
		var stage_data: Dictionary = {}
		for chapter: Dictionary in chapters:
			for stage: Dictionary in chapter.get("stages", []):
				if stage.get("id") == stage_id:
					stage_data = stage
					break
		
			_go_to_scene("battle_prepare", {"stageId": stage_id, "stageData": stage_data})

func _go_to_scene(scene_name: String, params: Dictionary = {}) -> void:
	if has_node("/root/SceneManager"):
		var sm = get_node("/root/SceneManager")
		sm.switch_scene(scene_name, params)
	else:
		push_error("SceneManager not found — pure code architecture requires SceneManager autoload")

func destroy() -> void:
	if _capture_effect_node and is_instance_valid(_capture_effect_node):
		_capture_effect_node.queue_free()
		_capture_effect_node = null
	_game = null
	_storage = null
	_achievement_manager = null
	_battle_result.clear()
	_capture_target.clear()
	_capture_result.clear()
	_capture_item_used.clear()
	_rewards.clear()
	_level_ups.clear()

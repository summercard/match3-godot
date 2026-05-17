# scene_result.gd - 战斗结算场景
# 源文件: js/ui/sceneResult.js
# 重构: _draw() 绘制 + 完整动画效果
class_name SceneResult
extends Control

# === 静态常量 ===
const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0
const STAR_MULTIPLIERS: Array[float] = [0.0, 0.6, 0.8, 1.0, 1.2, 1.5]

# === 颜色常量 ===
const C := {
	"bg_medium": Color(0.04, 0.07, 0.15),
	"bg_card": Color(0.10, 0.15, 0.25),
	"bg_panel": Color(0.08, 0.12, 0.22),
	"primary": Color(0.1, 0.5, 1.0),
	"success": Color(0.2, 0.8, 0.3),
	"gold": Color(1.0, 0.84, 0.0),
	"danger": Color(1.0, 0.15, 0.15),
	"danger_light": Color(1.0, 0.4, 0.4),
	"white": Color.WHITE,
	"text_primary": Color(1.0, 1.0, 1.0),
	"text_secondary": Color(0.7, 0.75, 0.85),
	"text_muted": Color(0.5, 0.55, 0.65),
	"thunder": Color(0.9, 0.8, 0.1)
}

# === 游戏数据 ===
var _game: Node = null
var _storage: Node = null
var _achievement_manager: Node = null

var _battle_result: Dictionary = {}
var _is_win: bool = false
var _stars: int = 0

# 收服
var _capture_target: Dictionary = {}
var _captured: bool = false
var _capture_result: Dictionary = {}
var _capture_item_used: Dictionary = {}

# 奖励
var _rewards: Dictionary = {"gold": 0, "exp": 0, "item": null, "item_name": ""}
var _level_ups: Array[Dictionary] = []

# 动画进度
var _star_anim_progress: float = 0.0
var _reward_anim_progress: float = 0.0
var _exp_anim_progress: float = 0.0
var _button_anim_progress: float = 0.0

# 按钮
var _has_next_stage: bool = false

# 收服特效
var _shake_offset_x: float = 0.0
var _capture_anim_timer: float = 0.0
var _capture_effect_node: CaptureEffect = null

# 入场动画
var _entry_offset_y: float = 200.0
var _entry_timer: float = 0.0
const ENTRY_DURATION: float = 0.4

# 按钮缓存区域
var _next_btn_rect := Rect2()
var _back_btn_rect := Rect2()

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
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	# 入场动画
	if _entry_timer < ENTRY_DURATION:
		_entry_timer += delta
		var progress := clampf(_entry_timer / ENTRY_DURATION, 0.0, 1.0)
		_entry_offset_y = lerp(200.0, 0.0, ease(progress, 0.5))
	else:
		_entry_offset_y = 0.0
	
	# 收服震动
	if _capture_anim_timer > 0:
		_capture_anim_timer -= delta
		_shake_offset_x = sin(_capture_anim_timer * 80.0) * 5.0
	else:
		_shake_offset_x = 0.0
	
	# 动画序列
	if _star_anim_progress < 1.0:
		_star_anim_progress = minf(1.0, _star_anim_progress + delta * 2.5)
	elif _reward_anim_progress < 1.0:
		_reward_anim_progress = minf(1.0, _reward_anim_progress + delta * 2.0)
	elif _exp_anim_progress < 1.0:
		_exp_anim_progress = minf(1.0, _exp_anim_progress + delta * 2.0)
	elif _button_anim_progress < 1.0:
		_button_anim_progress = minf(1.0, _button_anim_progress + delta * 3.0)
	
	queue_redraw()

# ==================== 初始化（保持原有逻辑） ====================

func initialize(game: Node, battle_result: Dictionary) -> void:
	_game = game
	_storage = get_node_or_null("/root/SaveManager")
	if _storage == null and game and game.get("storage"):
		_storage = game.storage
	if _game and _game.has_node("AchievementManager"):
		_achievement_manager = _game.get_node("AchievementManager")
	_battle_result = battle_result
	_is_win = battle_result.get("result", "") == "win"
	_calc_stars()
	var capture_played_inline: bool = battle_result.get("capture_played_inline", false)
	if capture_played_inline:
		_captured = battle_result.get("captured", false)
		_capture_target = battle_result.get("capture_target", {})
		_capture_result = battle_result.get("capture_result_text", {})
		_capture_item_used = battle_result.get("capture_item_used", {})
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
	_trigger_achievements()

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

func _play_capture_effect() -> void:
	var center_pos := Vector2(DESIGN_W / 2.0, 125.0)
	if not _capture_target.is_empty():
		var enemies: Array = _battle_result.get("enemies", [])
		var idx: int = enemies.find(_capture_target)
		if idx < 0:
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

func _setup_buttons() -> void:
	if _is_win and _battle_result.has("stageId"):
		_has_next_stage = not _find_next_stage(_battle_result["stageId"]).is_empty()
	else:
		_has_next_stage = false

func _save_rewards() -> void:
	if not _storage:
		return
	if _rewards["gold"] > 0 and _storage.has_method("add_gold"):
		_storage.add_gold(_rewards["gold"])
	if _rewards["exp"] > 0 and _storage.has_method("add_player_exp"):
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
	if _rewards["item"] and _storage.has_method("add_item"):
		_storage.add_item(_rewards["item"], 1)
	var rewards: Dictionary = _storage.load_rewards() if _storage.has_method("load_rewards") else {}
	rewards["totalGoldEarned"] = rewards.get("totalGoldEarned", 0) + _rewards["gold"]
	rewards["battleCount"] = rewards.get("battleCount", 0) + 1
	if _captured:
		rewards["captureCount"] = rewards.get("captureCount", 0) + 1
	if _rewards["item"]:
		rewards["totalItemsGained"] = rewards.get("totalItemsGained", 0) + 1
	_storage.save_rewards(rewards) if _storage.has_method("save_rewards") else null
	_record_achievement_progress()

func _record_achievement_progress() -> void:
	if not _storage:
		return
	if _storage.has_method("add_achievement_progress"):
		_storage.add_achievement_progress("battleCount", 1)
		if _is_win:
			_storage.add_achievement_progress("winCount", 1)
			_storage.add_achievement_progress("stageClearedCount", 1)
		if _captured:
			_storage.add_achievement_progress("captureCount", 1)
		if _rewards.get("gold", 0) > 0:
			_storage.add_achievement_progress("totalGoldEarned", int(_rewards["gold"]))
		var total_damage_dealt: Dictionary = _battle_result.get("totalDamageDealt", {})
		var total_damage: int = 0
		for value in total_damage_dealt.values():
			total_damage += int(value)
		if total_damage > 0:
			_storage.add_achievement_progress("totalDamageDealt", total_damage)

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

# ==================== 输入 ====================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_tap(event.position.x, event.position.y)
		accept_event()

func _on_tap(x: float, y: float) -> void:
	if _button_anim_progress < 1.0:
		return
	
	# 下一关
	if _has_next_stage and _next_btn_rect.has_point(Vector2(x, y)):
		_on_next_btn_pressed()
		return
	
	# 返回/重试
	if _back_btn_rect.has_point(Vector2(x, y)):
		_on_back_btn_pressed()
		return

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

func destroy() -> void:
	if _capture_effect_node and is_instance_valid(_capture_effect_node):
		_capture_effect_node.queue_free()
		_capture_effect_node = null
	_game = null
	_storage = null
	_achievement_manager = null

# ==================== 绘制 ====================

var _time_acc: float = 0.0

func _draw() -> void:
	var font := ThemeDB.fallback_font
	_time_acc += get_process_delta_time()
	
	var oy := _entry_offset_y  # 入场偏移
	
	# 背景
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), C["bg_medium"])
	
	# 标题
	var title_text := "🎉 战斗胜利!" if _is_win else "💀 战斗失败"
	var title_color := C["gold"] if _is_win else C["danger_light"]
	_draw_centered_text(font, title_text, DESIGN_W / 2.0, 35.0 + oy, title_color, 24.0)
	
	# === 星级区域 ===
	_draw_stars_section(font, 70.0 + oy)
	
	# === 战斗信息 ===
	if _star_anim_progress >= 1.0:
		_draw_battle_info(font, 135.0 + oy)
	
	# === 收服结果 ===
	if _reward_anim_progress >= 1.0 and _is_win:
		_draw_capture_section(font, 235.0 + oy + _shake_offset_x)
	
	# === 奖励 ===
	if _reward_anim_progress >= 1.0:
		_draw_rewards_section(font, 332.0 + oy)
	
	# === 经验 ===
	if _reward_anim_progress >= 1.0:
		_draw_exp_section(font, 446.0 + oy)
	
	# === 升级 ===
	if _exp_anim_progress >= 1.0:
		_draw_levelups_section(font, 536.0 + oy)
	
	# === 扫荡解锁 ===
	if _button_anim_progress >= 1.0 and _stars >= 3:
		var pulse := sin(_time_acc * 3.0) * 0.2 + 0.8
		_draw_centered_text(font, "⚡ 已解锁扫荡功能！", DESIGN_W / 2.0, 548.0 + oy, Color(1.0, 0.8, 0.2, pulse), 14.0)
	
	# === 按钮 ===
	if _button_anim_progress >= 1.0:
		_draw_buttons(font, 570.0 + oy)

func _draw_stars_section(font: Font, y: float) -> void:
	var progress := _star_anim_progress
	var display_stars: int = int(progress * _stars)
	var spacing := 48.0
	var start_x := DESIGN_W / 2.0 - spacing
	
	for i in range(3):
		var x := start_x + i * spacing
		var is_lit := i < display_stars
		var alpha := 1.0 if is_lit else 0.3
		
		# 发光效果 ✨
		if is_lit:
			_draw_centered_text(font, "✨", x - 2.0, y, Color(1.0, 0.84, 0.0, 0.3), 24.0)
		
		var emoji := "⭐" if is_lit else "☆"
		_draw_centered_text(font, emoji, x, y, Color(1.0, 0.84, 0.0, alpha), 32.0)

func _draw_battle_info(font: Font, y: float) -> void:
	_rounded_rect(20.0, y, DESIGN_W - 40.0, 90.0, 8.0, C["bg_card"])
	
	_draw_centered_text(font, "战斗信息", DESIGN_W / 2.0, y + 20.0, C["text_primary"], 14.0)
	
	var turn_count: int = _battle_result.get("turnCount", 0)
	var max_turns: int = _battle_result.get("maxTurns", 20)
	draw_string(font, Vector2(40, y + 45), "回合: %d" % turn_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C["text_primary"])
	draw_string(font, Vector2(200, y + 45), "最大回合: %d" % max_turns, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C["text_muted"])
	
	var enemies: Array = _battle_result.get("enemies", [])
	var defeated: Array = enemies.filter(func(e): return e and e.get("hp", 0) <= 0)
	var alive: Array = enemies.filter(func(e): return e and e.get("hp", 0) > 0)
	
	if not defeated.is_empty():
		var names := " ".join(defeated.map(func(e): return e.get("emoji", "")))
		draw_string(font, Vector2(40, y + 70), "击败: %s" % names, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C["danger_light"])
	if not alive.is_empty():
		var names := " ".join(alive.map(func(e): return e.get("emoji", "")))
		draw_string(font, Vector2(200, y + 70), "存活: %s" % names, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.5, 1.0))

func _draw_capture_section(font: Font, y: float) -> void:
	if _capture_result.is_empty():
		return
	
	_rounded_rect(20.0, y, DESIGN_W - 40.0, 82.0, 8.0, C["bg_panel"])
	
	_draw_centered_text(font, _capture_result.get("title", ""), DESIGN_W / 2.0, y + 25.0, C["success"], 18.0)
	
	var lines: Array = []
	if not _capture_target.is_empty():
		lines.append("目标: %s" % _capture_target.get("name", ""))
	if not _capture_item_used.is_empty():
		lines.append("消耗: %s" % _capture_item_used.get("name", ""))
	lines.append(_capture_result.get("desc", ""))
	
	for i in range(mini(lines.size(), 3)):
		_draw_centered_text(font, lines[i], DESIGN_W / 2.0, y + 48.0 + i * 14.0, C["text_secondary"], 10.0)

func _draw_rewards_section(font: Font, y: float) -> void:
	var progress := _reward_anim_progress
	
	_rounded_rect(20.0, y, DESIGN_W - 40.0, 100.0, 8.0, C["bg_panel"])
	
	_draw_centered_text(font, "获得奖励", DESIGN_W / 2.0, y + 18.0, C["text_primary"], 14.0)
	
	# 金币弹跳动画
	var gold_bounce := sin(progress * PI * 2.0) * 5.0 * (1.0 - progress)
	_draw_centered_text(font, "💰", 50.0, y + 52.0 + gold_bounce, C["gold"], 20.0)
	draw_string(font, Vector2(75, y + 55), "+%d 金币" % _rewards["gold"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14.0, C["gold"])
	
	# 道具闪光动画
	if _rewards["item"]:
		var sparkle := sin(progress * PI * 4.0) * 0.5 + 0.5
		var item_alpha := 0.5 + sparkle * 0.5
		_draw_centered_text(font, "🎁", 50.0, y + 82.0, Color(1, 1, 1, item_alpha), 16.0)
		draw_string(font, Vector2(75, y + 85), "+1 %s" % _rewards["item_name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C["text_primary"])
	else:
		draw_string(font, Vector2(75, y + 85), "(无道具)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C["text_muted"])

func _draw_exp_section(font: Font, y: float) -> void:
	_rounded_rect(20.0, y, DESIGN_W - 40.0, 80.0, 8.0, C["bg_card"])
	
	_draw_centered_text(font, "获得经验", DESIGN_W / 2.0, y + 20.0, C["text_primary"], 14.0)
	_draw_centered_text(font, "+%d 经验" % _rewards["exp"], DESIGN_W / 2.0, y + 48.0, C["thunder"], 16.0)
	
	var stage_rewards: Dictionary = _battle_result.get("stageRewards", {})
	if stage_rewards.has("exp"):
		var mult := STAR_MULTIPLIERS[_stars] if _stars < STAR_MULTIPLIERS.size() else 1.0
		_draw_centered_text(font, "(关卡基础 %d × %.1fx 星级系数)" % [stage_rewards["exp"], mult], DESIGN_W / 2.0, y + 70.0, C["text_muted"], 10.0)
	else:
		var base_exp: int = 100 if _is_win else 30
		var star_bonus: int = _stars * 20
		_draw_centered_text(font, "(基础 %d + 星级加成 %d)" % [base_exp, star_bonus], DESIGN_W / 2.0, y + 70.0, C["text_muted"], 10.0)

func _draw_levelups_section(font: Font, y: float) -> void:
	if _level_ups.is_empty():
		return
	var display_ups: Array = _level_ups.slice(0, 2)
	var pulse := sin(_time_acc * 5.0) * 0.2 + 0.8
	
	for i in range(display_ups.size()):
		var up: Dictionary = display_ups[i]
		var item_y := y + i * 28.0
		
		# 金色发光背景
		_rounded_rect(DESIGN_W / 2.0 - 120.0, item_y, 240.0, 24.0, 8.0, Color(1.0, 0.84, 0.0, 0.2 * pulse))
		
		# 升级图标
		draw_string(font, Vector2(DESIGN_W / 2.0 - 100.0, item_y + 17), "⬆️", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.84, 0.0, pulse))
		
		# 怪物名
		draw_string(font, Vector2(DESIGN_W / 2.0 - 70.0, item_y + 17), str(up.get("monsterId", "?")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C["gold"])
		
		# 等级变化
		draw_string(font, Vector2(DESIGN_W / 2.0 + 50.0, item_y + 17), "Lv.%d → Lv.%d" % [up.get("oldLevel", 0), up.get("newLevel", 0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C["success"])

func _draw_buttons(font: Font, y: float) -> void:
	var progress := _button_anim_progress
	var base_scale := 0.8 + progress * 0.2
	
	var btn_w := 140.0
	var btn_h := 42.0
	
	if _has_next_stage:
		# 下一关按钮
		var next_x := DESIGN_W / 2.0 - btn_w - 10.0
		var scaled_w := btn_w * base_scale
		var scaled_h := btn_h * base_scale
		var draw_x := next_x + (btn_w - scaled_w) / 2.0
		var draw_y := y + (btn_h - scaled_h) / 2.0
		_rounded_rect(draw_x, draw_y, scaled_w, scaled_h, 12.0, C["primary"])
		_draw_centered_text(font, "下一关 ▶", next_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 16.0)
		_next_btn_rect = Rect2(next_x, y, btn_w, btn_h)
		
		# 返回关卡按钮
		var back_x := DESIGN_W / 2.0 + 10.0
		_rounded_rect(back_x + (btn_w - scaled_w) / 2.0, draw_y, scaled_w, scaled_h, 12.0, C["bg_card"])
		_draw_centered_text(font, "返回关卡", back_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["text_primary"], 14.0)
		_back_btn_rect = Rect2(back_x, y, btn_w, btn_h)
	else:
		var btn_x := (DESIGN_W - btn_w) / 2.0
		var scaled_w := btn_w * base_scale
		var scaled_h := btn_h * base_scale
		var draw_x := btn_x + (btn_w - scaled_w) / 2.0
		var draw_y := y + (btn_h - scaled_h) / 2.0
		
		if _is_win:
			_rounded_rect(draw_x, draw_y, scaled_w, scaled_h, 12.0, C["primary"])
			_draw_centered_text(font, "返回关卡", btn_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 16.0)
		else:
			_rounded_rect(draw_x, draw_y, scaled_w, scaled_h, 12.0, C["danger"])
			_draw_centered_text(font, "重试", btn_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 16.0)
		_back_btn_rect = Rect2(btn_x, y, btn_w, btn_h)

# ==================== 绘制辅助 ====================

func _draw_centered_text(font: Font, text: String, x: float, y: float, color: Color, size: float) -> void:
	var tw := 200.0
	# 阴影
	draw_string(font, Vector2(x - tw / 2.0 + 1, y + 1), text, HORIZONTAL_ALIGNMENT_CENTER, tw, size, Color(0, 0, 0, 0.4))
	draw_string(font, Vector2(x - tw / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, tw, size, color)

func _rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	# 简易圆角矩形
	var rr := minf(r, minf(w, h) / 2.0)
	if rr > 0:
		draw_rect(Rect2(x + rr, y, w - rr * 2, h), color)
		draw_rect(Rect2(x, y + rr, w, h - rr * 2), color)
		draw_circle(Vector2(x + rr, y + rr), rr, color)
		draw_circle(Vector2(x + w - rr, y + rr), rr, color)
		draw_circle(Vector2(x + rr, y + h - rr), rr, color)
		draw_circle(Vector2(x + w - rr, y + h - rr), rr, color)
	else:
		draw_rect(Rect2(x, y, w, h), color)

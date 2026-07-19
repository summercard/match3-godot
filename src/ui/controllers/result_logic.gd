# result_logic.gd - 战斗结算界面的旧脚本逻辑父类
# 源文件: js/ui/sceneResult.js
# 重构: _draw() 绘制 + 完整动画效果
class_name SceneResult
extends Control

const PROJECT_ROUND_FONT: Font = preload("res://assets/fonts/noto-cjk/NotoSansCJK-Regular.ttc")
const MonsterDb = preload("res://src/data/monster_db.gd")
const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const CaptureSystemScript = preload("res://src/battle/capture_system.gd")
const RewardRulesScript = preload("res://src/battle/reward_rules.gd")
const ItemDBScript = preload("res://src/data/item_db.gd")
const StageWarBackgroundsScript = preload("res://src/ui/components/stage_war_backgrounds.gd")

# === 静态常量 ===
const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0

const RESULT_ASSETS := {
	"bg": StageWarBackgroundsScript.DEFAULT_PATH,
	"victory_banner": "res://assets/images/ui/panels/result_refresh_ui_victory_blue_banner_clean.png",
	"defeat_banner": "res://assets/images/ui/panels/result_refresh_ui_victory_wood_plaque.png",
	"reward_panel": "res://assets/images/ui/panels/result_refresh_ui_panel_large.png",
	"team_exp_panel": "res://assets/images/ui/panels/result_refresh_ui_panel_large.png",
	"reward_slot": "res://assets/images/ui/cards/result_refresh_ui_reward_card.png",
	"monster_exp_card": "res://assets/images/ui/cards/result_refresh_ui_monster_card.png",
	"btn_next": "res://assets/images/ui/buttons/result_refresh_ui_btn_gold.png",
	"btn_secondary": "res://assets/images/ui/buttons/result_refresh_ui_btn_blue.png",
	"btn_retry": "res://assets/images/ui/buttons/result_refresh_ui_btn_blue.png",
	"capture_plaque": "res://assets/images/ui/panels/result_refresh_ui_capture_status_plaque.png",
	"info_chip": "res://assets/images/ui/panels/result_refresh_ui_pill_blue.png",
	"star_lit": "res://assets/images/ui/icons/result_refresh_icon_star_gold.png",
	"star_dim": "res://assets/images/ui/icons/result_refresh_icon_star_silver.png",
	"fx_confetti": "res://assets/images/effects/result_refresh_fx_confetti.png",
	"fx_capture_ring": "res://assets/images/effects/capture_success_new_fx_magic_circle.png",
	"fx_levelup_glow": "res://assets/images/effects/result_refresh_fx_sparkles.png",
}

const COMMON_ASSETS := {
	"gold": "res://assets/images/ui/icons/main_icon_gold_coin_v3.png",
	"diamond": "res://assets/images/ui/gems/main_icon_diamond_gem_v3.png",
	"exp": "res://assets/images/ui/icons/ranch_icon_exp_badge.png",
	"capture_ball": "res://assets/images/ui/icons/battle_flow_new_icon_capture_ball.png",
	"item_capture": "res://assets/images/ui/icons/items_new_icon_capture_ball.png",
	"item_capture_plus": "res://assets/images/ui/icons/items_new_icon_capture_ball_plus.png",
	"item_exp": "res://assets/images/ui/icons/items_new_icon_exp_potion.png",
	"item_exp_crystal": "res://assets/images/ui/icons/items_new_icon_exp_crystal.png",
	"item_gold": "res://assets/images/ui/icons/items_new_icon_gold_bag.png",
	"item_gold_chest": "res://assets/images/ui/icons/items_new_icon_gold_chest.png",
	"item_hp": "res://assets/images/ui/icons/items_new_icon_hp_potion.png",
	"item_generic": "res://assets/images/ui/icons/inventory_new_ui_inventory_icon_badge.png",
	"gem_fire": "res://assets/images/ui/elements/element_fire.png",
	"gem_grass": "res://assets/images/ui/elements/element_grass.png",
	"gem_water": "res://assets/images/ui/elements/element_water.png",
}

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
var _capture_window: Dictionary = {}

# 奖励
var _rewards: Dictionary = {"gold": 0, "gems": 0, "first_clear": false, "exp": 0, "item": null, "item_name": "", "item_count": 0}
var _level_ups: Array[Dictionary] = []
var _monster_exp_awards: Dictionary = {}
var _reward_receipt_id: String = ""
var _reward_claim_allowed: bool = true
var _reward_already_claimed: bool = false

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
var _retry_btn_rect := Rect2()
var _texture_cache: Dictionary = {}

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
		if _star_anim_progress == 0.0 and _is_win:
			var am := get_node_or_null("/root/AudioManager")
			if am != null and am.has_method("play_sfx"):
				am.call("play_sfx", "powerup_created_star")
		_star_anim_progress = minf(1.0, _star_anim_progress + delta * 2.5)
	elif _reward_anim_progress < 1.0:
		if _reward_anim_progress == 0.0 and _is_win:
			var am := get_node_or_null("/root/AudioManager")
			if am != null and am.has_method("play_sfx"):
				am.call("play_sfx", "reward_coin_soft")
		_reward_anim_progress = minf(1.0, _reward_anim_progress + delta * 2.0)
	elif _exp_anim_progress < 1.0:
		if _exp_anim_progress == 0.0 and _is_win:
			var am := get_node_or_null("/root/AudioManager")
			if am != null and am.has_method("play_sfx"):
				am.call("play_sfx", "battle_heal_leaf_bubble")
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
	_battle_result = _normalize_battle_result(battle_result)
	_is_win = _battle_result.get("result", "") == "win"
	_reset_settlement_state()
	_reward_receipt_id = _resolve_reward_receipt_id(_battle_result)
	_reward_claim_allowed = _begin_reward_receipt_claim()
	_reward_already_claimed = not _reward_claim_allowed
	_battle_result["rewardReceiptId"] = _reward_receipt_id
	_battle_result["reward_receipt_id"] = _reward_receipt_id
	_battle_result["rewardAlreadyClaimed"] = _reward_already_claimed
	_calc_stars()
	var capture_played_inline: bool = _battle_result.get("capture_played_inline", false)
	if capture_played_inline:
		_captured = _battle_result.get("captured", false)
		_capture_target = _battle_result.get("capture_target", {})
		var invalid_capture_target := not _capture_target.is_empty() and not CaptureSystemScript.can_capture(_capture_target)
		if invalid_capture_target:
			_captured = false
			_capture_target = {}
			_capture_result = CaptureSystemScript.get_capture_skip_feedback("not_capturable")
		else:
			_capture_result = _battle_result.get("capture_result_text", {})
		_capture_item_used = _battle_result.get("capture_item_used", {})
		_capture_window = _battle_result.get("capture_window", {})
	else:
		if _is_win and _reward_claim_allowed:
			_process_capture()
		elif _is_win:
			_capture_result = CaptureSystemScript.get_capture_skip_feedback("already_claimed")
	_calc_rewards()
	_setup_buttons()
	var reward_claim_succeeded := false
	if _reward_claim_allowed:
		reward_claim_succeeded = _claim_rewards_atomically()
		if not reward_claim_succeeded:
			_cancel_reward_receipt_claim()
			_reward_claim_allowed = false
			push_warning(TranslationServer.translate("[ResultLogic] 结算奖励事务失败: %s") % _reward_receipt_id)
	if reward_claim_succeeded:
		_trigger_achievements()


func _reset_settlement_state() -> void:
	_capture_target = {}
	_captured = false
	_capture_result = {}
	_capture_item_used = {}
	_capture_window = {}
	_level_ups.clear()
	_monster_exp_awards.clear()


func _resolve_reward_receipt_id(result: Dictionary) -> String:
	var explicit_id := str(result.get("rewardReceiptId", result.get("reward_receipt_id", "")))
	if not explicit_id.is_empty():
		return explicit_id
	var source_battle_id := str(result.get("battleId", result.get("battle_id", "")))
	if not source_battle_id.is_empty():
		return "battle_reward:%s" % source_battle_id
	var legacy_signature := {
		"stage_id": str(result.get("stageId", result.get("stage_id", ""))),
		"result": str(result.get("result", "")),
		"turn_count": int(result.get("turnCount", result.get("turn_count", 0))),
		"max_turns": int(result.get("maxTurns", result.get("max_turns", 0))),
		"player_team": result.get("playerTeam", result.get("player_team", [])),
		"enemies": result.get("enemies", []),
		"total_damage": result.get("totalDamageDealt", result.get("total_damage_dealt", {}))
	}
	return "legacy_battle_reward:%s" % JSON.stringify(legacy_signature).sha256_text()


func _begin_reward_receipt_claim() -> bool:
	if not _storage or not _storage.has_method("begin_reward_receipt_claim"):
		return true
	return bool(_storage.begin_reward_receipt_claim(_reward_receipt_id))


func _complete_reward_receipt_claim() -> bool:
	if not _storage or not _storage.has_method("complete_reward_receipt_claim"):
		return true
	return bool(_storage.complete_reward_receipt_claim(_reward_receipt_id))


func _cancel_reward_receipt_claim() -> void:
	if _storage and _storage.has_method("cancel_reward_receipt_claim"):
		_storage.cancel_reward_receipt_claim(_reward_receipt_id)


func _claim_rewards_atomically() -> bool:
	if _storage and _storage.has_method("run_transaction"):
		var tx: Dictionary = _storage.run_transaction(func():
			_save_rewards()
			if _is_win and _battle_result.has("stageId"):
				if _storage.has_method("save_stage_stars") and not bool(_storage.save_stage_stars(_battle_result["stageId"], _stars)):
					return {"ok": false, "error": "stage_stars_save_failed"}
			if not _complete_reward_receipt_claim():
				return {"ok": false, "error": "receipt_complete_failed"}
			return {"ok": true}
		)
		return bool(tx.get("ok", false))
	_save_rewards()
	if _is_win and _battle_result.has("stageId"):
		if _storage and _storage.has_method("save_stage_stars") and not bool(_storage.save_stage_stars(_battle_result["stageId"], _stars)):
			return false
	return _complete_reward_receipt_claim()

func _normalize_battle_result(result: Dictionary) -> Dictionary:
	var normalized := result.duplicate(true)
	if not normalized.has("stageId") and normalized.has("stage_id"):
		normalized["stageId"] = normalized["stage_id"]
	if not normalized.has("stage_id") and normalized.has("stageId"):
		normalized["stage_id"] = normalized["stageId"]
	if not normalized.has("playerTeam") and normalized.has("player_team"):
		normalized["playerTeam"] = normalized["player_team"]
	if not normalized.has("player_team") and normalized.has("playerTeam"):
		normalized["player_team"] = normalized["playerTeam"]
	if not normalized.has("turnCount") and normalized.has("turn_count"):
		normalized["turnCount"] = normalized["turn_count"]
	if not normalized.has("maxTurns") and normalized.has("max_turns"):
		normalized["maxTurns"] = normalized["max_turns"]
	if not normalized.has("stageRewards") and normalized.has("stage_rewards"):
		normalized["stageRewards"] = normalized["stage_rewards"]
	if not normalized.has("totalDamageDealt") and normalized.has("total_damage_dealt"):
		normalized["totalDamageDealt"] = normalized["total_damage_dealt"]
	if not normalized.has("playerLevel") and normalized.has("player_level"):
		normalized["playerLevel"] = normalized["player_level"]
	if not normalized.has("enemyLevel") and normalized.has("enemy_level"):
		normalized["enemyLevel"] = normalized["enemy_level"]
	return normalized

func init(data: Dictionary = {}) -> void:
	var game := get_node_or_null("/root/GameManager")
	# 结算页：切回 town BGM（lobby 上下文）；具体胜负 sting 由 _process 内的动画钩子播放
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_bgm"):
		am.call("play_bgm", "bgm_town")
	initialize(game, data)

func _calc_stars() -> void:
	var player_team: Array = _battle_result.get("playerTeam", [])
	_stars = _calculate_battle_stars(player_team)

func _calculate_battle_stars(player_team: Array) -> int:
	return RewardRulesScript.calc_battle_stars_for_team(player_team)

func _process_capture() -> void:
	var enemies: Array = _battle_result.get("enemies", [])
	var target_enemy: Dictionary = {}
	for enemy: Dictionary in enemies:
		if enemy and bool(enemy.get("isElite", false)) and CaptureSystemScript.can_capture(enemy):
			target_enemy = enemy
			break
	for enemy: Dictionary in enemies:
		if not target_enemy.is_empty():
			break
		if enemy and enemy.get("hp", 0) > 0 and CaptureSystemScript.can_capture(enemy):
			target_enemy = enemy
			break
	if target_enemy.is_empty():
		var valid_enemies: Array = enemies.filter(func(e): return e and e.has("id") and CaptureSystemScript.can_capture(e))
		if not valid_enemies.is_empty():
			target_enemy = valid_enemies[randi() % valid_enemies.size()]
	if target_enemy.is_empty():
		_capture_result = CaptureSystemScript.get_capture_skip_feedback("no_target")
		return

	_capture_target = target_enemy
	var settings: Dictionary = _load_capture_preferences()
	if not bool(settings.get("autoCapture", false)):
		_captured = false
		_capture_item_used = {}
		_capture_result = CaptureSystemScript.get_capture_skip_feedback("auto_off", {"target": _capture_target})
		return

	var item_use: Dictionary = _consume_selected_capture_item(str(settings.get("equippedItem", "")))
	if not bool(item_use.get("ok", false)):
		_captured = false
		_capture_item_used = {}
		_capture_result = CaptureSystemScript.get_capture_skip_feedback(str(item_use.get("reason", "no_item")), {
			"target": _capture_target,
			"item_name": str(item_use.get("item_name", "捕捉球"))
		})
		return

	var enemy_rarity: int = target_enemy.get("rarity", 1)
	var player: Dictionary = {}
	if _storage and _storage.has_method("load_player"):
		player = _storage.load_player()
	var consecutive_fails: int = player.get("captureFails", 0)
	_capture_window = CaptureSystemScript.calc_taming_window(target_enemy.get("hp", 0), target_enemy.get("maxHP", 1))
	var prob: float = _calc_capture_probability(
		target_enemy.get("hp", 0), target_enemy.get("maxHP", 1),
		_battle_result.get("playerLevel", 1), _battle_result.get("enemyLevel", 1),
		enemy_rarity, consecutive_fails, float(item_use.get("bonus", 0.0)),
		bool(target_enemy.get("isElite", false))
	)
	_captured = randf() < prob
	_capture_result = _get_capture_result_text(prob, _captured)
	if _storage and _storage.has_method("load_player") and _storage.has_method("save_player"):
		var player_data: Dictionary = _storage.load_player()
		player_data["captureFails"] = 0 if _captured else (consecutive_fails + 1)
		_storage.save_player(player_data)
	_play_capture_effect()

func _calc_capture_probability(hp: float, max_hp: float, player_level: int, enemy_level: int, rarity: int, consecutive_fails: int, item_bonus: float = 0.0, is_elite: bool = false) -> float:
	var stage_id := str(_battle_result.get("stageId", _battle_result.get("stage_id", "")))
	var taming_window: Dictionary = _capture_window
	if taming_window.is_empty():
		taming_window = CaptureSystemScript.calc_taming_window(hp, max_hp)
	return CaptureSystemScript.calc_capture_probability(hp, max_hp, player_level, enemy_level, rarity, {
		"stage_id": stage_id,
		"consecutive_fails": consecutive_fails,
		"taming_window": taming_window,
		"item_bonus": item_bonus,
		"is_elite": is_elite
	})

func _load_capture_preferences() -> Dictionary:
	if _storage and _storage.has_method("load_capture_settings"):
		return _storage.load_capture_settings()
	return {"autoCapture": false, "equippedItem": ""}

func _consume_selected_capture_item(item_id: String) -> Dictionary:
	if not _storage or not _storage.has_method("load_inventory") or not _storage.has_method("use_item"):
		return {"ok": false, "reason": "storage_unavailable"}
	var inventory: Dictionary = _storage.load_inventory()
	item_id = _resolve_capture_item_id(item_id, inventory)
	if item_id.is_empty():
		return {"ok": false, "reason": "no_item"}
	var item_def: Dictionary = ItemDBScript.get_item(item_id)
	if str(item_def.get("type", "")) != "capture":
		return {"ok": false, "reason": "invalid_item", "item_name": str(item_def.get("name", "道具"))}
	if int(inventory.get(item_id, 0)) <= 0:
		return {"ok": false, "reason": "item_empty", "item_name": str(item_def.get("name", "捕捉球"))}
	if _storage.use_item(item_id, 1):
		var bonus := float(item_def.get("effect", {}).get("captureBonus", 0.0))
		_capture_item_used = {
			"id": item_id,
			"bonus": bonus,
			"name": str(item_def.get("name", "捕获球"))
		}
		return {"ok": true, "bonus": bonus, "item": _capture_item_used.duplicate(true)}
	return {"ok": false, "reason": "item_empty", "item_name": str(item_def.get("name", "捕捉球"))}

func _resolve_capture_item_id(preferred_id: String, inventory: Dictionary) -> String:
	if not preferred_id.is_empty():
		var preferred_def: Dictionary = ItemDBScript.get_item(preferred_id)
		if str(preferred_def.get("type", "")) == "capture" and int(inventory.get(preferred_id, 0)) > 0:
			return preferred_id
	for item_id in ["capture_ball", "capture_ball_plus", "capture_ball_elite"]:
		if int(inventory.get(item_id, 0)) <= 0:
			continue
		var item_def: Dictionary = ItemDBScript.get_item(item_id)
		if str(item_def.get("type", "")) != "capture":
			continue
		_save_resolved_capture_item(item_id)
		return item_id
	return ""

func _save_resolved_capture_item(item_id: String) -> void:
	if not _storage or not _storage.has_method("save_capture_settings"):
		return
	var settings := _load_capture_preferences()
	settings["equippedItem"] = item_id
	_storage.call("save_capture_settings", settings)

func _get_capture_result_text(prob: float, captured: bool) -> Dictionary:
	return CaptureSystemScript.get_capture_result_text(prob, captured, _capture_window, {
		"target": _capture_target,
		"item_used": _capture_item_used
	})

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
	var reward_result := RewardRulesScript.calc_battle_rewards(stage_rewards, _stars, _is_win)
	_rewards["gold"] = int(reward_result.get("gold", 0))
	_rewards["exp"] = int(reward_result.get("exp", 0))
	_rewards["gems"] = 0
	_rewards["first_clear"] = false
	var stage_id := str(_battle_result.get("stageId", ""))
	if _is_win and not stage_id.is_empty() and _storage and _storage.has_method("is_stage_cleared"):
		if not _storage.is_stage_cleared(stage_id):
			var stage_data: Dictionary = _battle_result.get("stageData", {})
			if stage_data.is_empty() and _storage.has_method("get_stage"):
				stage_data = _storage.get_stage(stage_id)
			var is_boss := str(stage_data.get("type", "")) == "boss"
			_rewards["gems"] = 10 if is_boss else 3
			_rewards["first_clear"] = true
	_rewards["item"] = null
	_rewards["item_name"] = ""
	_rewards["item_count"] = 0
	var first_item: Dictionary = RewardRulesScript.get_first_guaranteed_item(stage_rewards)
	if _is_win and bool(_rewards.get("first_clear", false)) and not first_item.is_empty():
		var item_id := str(first_item.get("id", ""))
		var item_def := ItemDBScript.get_item(item_id)
		_rewards["item"] = item_id
		_rewards["item_name"] = str(item_def.get("name", item_id))
		_rewards["item_count"] = maxi(1, int(first_item.get("count", 1)))

func _setup_buttons() -> void:
	if _is_win and _battle_result.has("stageId"):
		_has_next_stage = not _find_next_stage(_battle_result["stageId"]).is_empty()
	else:
		_has_next_stage = false

static func build_captured_instance_options(target: Dictionary, battle_result: Dictionary) -> Dictionary:
	var captured_nature := str(target.get("nature", ""))
	if captured_nature.is_empty():
		captured_nature = NatureDB.random_nature()
	var monster_id := str(target.get("monsterId", target.get("id", "")))
	var captured_level := maxi(1, int(target.get("level", battle_result.get("enemyLevel", 1))))
	var is_elite: bool = target.get("isElite", MonsterDb.MONSTER_DB.get(monster_id, {}).get("isElite", false)) == true
	return {
		"source": "capture",
		"level": captured_level,
		"nature": captured_nature,
		"isElite": is_elite,
	}

func _save_rewards() -> void:
	if not _storage:
		return
	if _rewards["gold"] > 0 and _storage.has_method("add_gold"):
		_storage.add_gold(_rewards["gold"])
	if int(_rewards.get("gems", 0)) > 0 and _storage.has_method("add_gems"):
		_storage.add_gems(int(_rewards["gems"]))
	if _rewards["exp"] > 0 and _storage.has_method("add_player_exp"):
		_storage.add_player_exp(_rewards["exp"])
	_add_monster_exp_from_battle()
	if _captured and not _capture_target.is_empty() and _capture_target.has("id") and CaptureSystemScript.can_capture(_capture_target):
		if _storage.has_method("add_monster_instance"):
			var captured_options := build_captured_instance_options(_capture_target, _battle_result)
			_capture_target["level"] = int(captured_options.get("level", _capture_target.get("level", 1)))
			_capture_target["nature"] = str(captured_options.get("nature", _capture_target.get("nature", "")))
			_capture_target["isElite"] = bool(captured_options.get("isElite", _capture_target.get("isElite", false)))
			_storage.add_monster_instance(
				str(_capture_target["id"]),
				captured_options
			)
		else:
			var player: Dictionary = _storage.load_player() if _storage.has_method("load_player") else {}
			var captured_list: Array = player.get("captured", [])
			if not captured_list.has(_capture_target["id"]):
				captured_list.append(_capture_target["id"])
				player["captured"] = captured_list
				_storage.save_player(player) if _storage.has_method("save_player") else null
				_storage.init_monster_pokedex(_capture_target["id"]) if _storage.has_method("init_monster_pokedex") else null
	if _rewards["item"] and _storage.has_method("add_item"):
		var item_count := maxi(1, int(_rewards.get("item_count", 1)))
		_storage.add_item(_rewards["item"], item_count)
	var rewards: Dictionary = _storage.load_rewards() if _storage.has_method("load_rewards") else {}
	rewards["totalGoldEarned"] = rewards.get("totalGoldEarned", 0) + _rewards["gold"]
	rewards["battleCount"] = rewards.get("battleCount", 0) + 1
	if _captured:
		rewards["captureCount"] = rewards.get("captureCount", 0) + 1
	if _rewards["item"]:
		rewards["totalItemsGained"] = rewards.get("totalItemsGained", 0) + maxi(1, int(_rewards.get("item_count", 1)))
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
	var stage_rewards: Dictionary = _battle_result.get("stageRewards", {})
	var exp_to_add := RewardRulesScript.calc_monster_exp(stage_rewards, _stars, _is_win)
	if exp_to_add <= 0:
		return
	if _storage.has_method("add_shared_monster_exp"):
		_monster_exp_awards["shared"] = _storage.add_shared_monster_exp(exp_to_add)

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
	if _next_btn_rect.has_point(Vector2(x, y)):
		if _is_win:
			_on_next_btn_pressed()
		else:
			_on_classroom_btn_pressed()
		return
	
	# 返回/重试
	if _back_btn_rect.has_point(Vector2(x, y)):
		_on_back_btn_pressed()
		return

	if _retry_btn_rect.has_point(Vector2(x, y)):
		if _is_win:
			_on_classroom_btn_pressed()
		else:
			_on_retry_btn_pressed()
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
			_go_to_scene("battle_prepare", {
				"stageId": next_stage_id,
				"stageData": stage_data,
				"chapterIndex": _infer_chapter_index(next_stage_id)
			})

func _on_back_btn_pressed() -> void:
	var chapter_index: int = _infer_chapter_index(_battle_result.get("stageId", ""))
	if _is_win:
		_go_to_scene("stage_select", {"chapter_index": chapter_index})
	else:
		_go_to_scene("main")

func _on_retry_btn_pressed() -> void:
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
	_go_to_scene("battle_prepare", {
		"stageId": stage_id,
		"stageData": stage_data,
		"chapterIndex": _infer_chapter_index(stage_id)
	})

func _on_classroom_btn_pressed() -> void:
	_go_to_scene("ranch", {"page": "classroom"})

func _go_to_scene(scene_name: String, params: Dictionary = {}) -> void:
	if has_node("/root/SceneManager"):
		var sm = get_node("/root/SceneManager")
		sm.switch_scene(scene_name, params)

func destroy() -> void:
	if _capture_effect_node and is_instance_valid(_capture_effect_node):
		_capture_effect_node.queue_free()
		_capture_effect_node = null
	# 动画状态清理
	_star_anim_progress = 0.0
	_reward_anim_progress = 0.0
	_exp_anim_progress = 0.0
	_button_anim_progress = 0.0
	_shake_offset_x = 0.0
	_entry_offset_y = 200.0
	_entry_timer = 0.0
	_time_acc = 0.0
	_capture_anim_timer = 0.0
	_has_next_stage = false
	_next_btn_rect = Rect2()
	_back_btn_rect = Rect2()
	_retry_btn_rect = Rect2()
	_game = null
	_storage = null
	_achievement_manager = null

# ==================== 绘制 ====================

var _time_acc: float = 0.0

func _draw() -> void:
	var font := PROJECT_ROUND_FONT
	_time_acc += get_process_delta_time()
	
	var oy := _entry_offset_y  # 入场偏移
	
	# 背景
	_draw_texture_cover(_tex("bg"), Rect2(0, 0, DESIGN_W, DESIGN_H))
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.05, 0.12, 0.34))
	if _is_win:
		_draw_victory_halo(Rect2(54.0, 12.0 + oy * 0.25, 267.0, 154.0))
		_draw_texture_fit(_tex("fx_confetti"), Rect2(8, 34, 92, 84), 0.78)
		_draw_texture_fit(_tex("fx_confetti"), Rect2(276, 36, 92, 84), 0.68)
	
	# 标题
	var title_text := "战斗胜利" if _is_win else "战斗失败"
	var title_color := C["gold"] if _is_win else C["danger_light"]
	var banner_key := "victory_banner" if _is_win else "defeat_banner"
	_draw_texture_fit(_tex(banner_key), Rect2(24.0, 8.0 + oy, DESIGN_W - 48.0, 102.0))
	_draw_centered_text(font, title_text, DESIGN_W / 2.0, 64.0 + oy, title_color, 26.0)
	
	# === 星级区域 ===
	_draw_stars_section(font, 122.0 + oy)
	
	# === 战斗信息 ===
	if _star_anim_progress >= 1.0:
		_draw_battle_info(font, 154.0 + oy)
	
	# === 收服结果 ===
	if _reward_anim_progress >= 1.0 and _is_win:
		_draw_capture_section(font, 204.0 + oy + _shake_offset_x)
	
	# === 奖励 ===
	if _reward_anim_progress >= 1.0:
		_draw_rewards_section(font, 326.0 + oy)
	
	# === 经验 ===
	if _reward_anim_progress >= 1.0:
		_draw_exp_section(font, 444.0 + oy)
	
	# === 升级 ===
	if _exp_anim_progress >= 1.0:
		_draw_levelups_section(font, 558.0 + oy)
	
	# === 按钮 ===
	if _button_anim_progress >= 1.0:
		_draw_buttons(font, 604.0 + oy)

func _draw_stars_section(font: Font, y: float) -> void:
	var progress := _star_anim_progress
	var display_stars: int = clampi(ceili(progress * _stars), 0, _stars)
	var spacing := 48.0
	var start_x := DESIGN_W / 2.0 - spacing
	
	for i in range(3):
		var x := start_x + i * spacing
		var is_lit := i < display_stars
		var alpha := 1.0 if is_lit else 0.42
		var pop := 1.0 + maxf(0.0, sin(progress * PI * 3.0 - i * 0.8)) * 0.10 if is_lit else 1.0
		var size := 54.0 * pop
		var key := "star_lit" if is_lit else "star_dim"
		_draw_texture_fit(_tex(key), Rect2(x - size / 2.0, y - size / 2.0, size, size), alpha)

func _draw_battle_info(font: Font, y: float) -> void:
	_draw_texture_fit(_tex("info_chip"), Rect2(28.0, y, DESIGN_W - 56.0, 40.0), 0.94)
	
	var turn_count: int = _battle_result.get("turnCount", 0)
	var max_turns: int = _battle_result.get("maxTurns", 20)
	_draw_centered_text(font, TranslationServer.translate("回合 %d / %d") % [turn_count, max_turns], DESIGN_W / 2.0, y + 25.0, C["text_primary"], 13.0)
	
	var enemies: Array = _battle_result.get("enemies", [])
	var defeated: Array = enemies.filter(func(e): return e and e.get("hp", 0) <= 0)
	var alive: Array = enemies.filter(func(e): return e and e.get("hp", 0) > 0)
	
	if not defeated.is_empty():
		var names := " / ".join(defeated.map(func(e): return TranslationServer.translate(str(e.get("name", e.get("emoji", ""))))))
		_draw_centered_text(font, TranslationServer.translate("击败：%s") % names, DESIGN_W / 2.0, y + 58.0, C["danger_light"], 11.0)
	elif not alive.is_empty():
		var names := " / ".join(alive.map(func(e): return TranslationServer.translate(str(e.get("name", e.get("emoji", ""))))))
		_draw_centered_text(font, TranslationServer.translate("仍在场：%s") % names, DESIGN_W / 2.0, y + 58.0, Color(0.5, 0.7, 1.0), 11.0)

func _draw_capture_section(font: Font, y: float) -> void:
	if _capture_result.is_empty():
		return
	
	var center_x := DESIGN_W / 2.0
	_draw_texture_fit(_tex("fx_capture_ring"), Rect2(center_x - 60.0, y - 18.0, 120.0, 66.0), 0.56)
	if not _capture_target.is_empty():
		_draw_monster_portrait(_capture_target, Rect2(center_x - 32.0, y - 20.0, 64.0, 64.0))
	
	_draw_texture_fit(_tex("capture_plaque"), Rect2(72.0, y + 44.0, 232.0, 48.0))
	_draw_centered_text(font, _capture_result.get("title", ""), DESIGN_W / 2.0, y + 65.0, C["success"] if _captured else C["danger_light"], 14.0)
	
	var lines: Array = []
	if not _capture_target.is_empty():
		var target_tags: Array = _capture_result.get("target_tags", [])
		if target_tags.is_empty():
			target_tags = CaptureSystemScript.get_target_value_tags(_capture_target)
		var tag_text := " / ".join(target_tags.slice(0, 3).map(func(tag): return TranslationServer.translate(str(tag))))
		lines.append(TranslationServer.translate("目标: %s  %s") % [TranslationServer.translate(str(_capture_target.get("name", ""))), tag_text])
	if not _capture_item_used.is_empty():
		lines.append(TranslationServer.translate("消耗: %s") % TranslationServer.translate(str(_capture_item_used.get("name", ""))))
	var reason := str(_capture_result.get("reason", ""))
	var advice := str(_capture_result.get("advice", ""))
	if reason.is_empty() and not _capture_window.is_empty():
		reason = TranslationServer.translate("窗口: %s %d%%") % [_capture_window.get("label", ""), int(round(float(_capture_window.get("stability", 0.0)) * 100.0))]
	if not reason.is_empty():
		lines.append(reason)
	if not advice.is_empty() and not _captured:
		lines.append(advice)
	
	for i in range(mini(lines.size(), 3)):
		_draw_centered_text(font, lines[i], DESIGN_W / 2.0, y + 82.0 + i * 11.0, C["text_secondary"], 8.0)

func _draw_rewards_section(font: Font, y: float) -> void:
	var progress := _reward_anim_progress
	
	_draw_texture_fit(_tex("reward_panel"), Rect2(16.0, y, DESIGN_W - 32.0, 110.0), 0.96)
	
	_draw_centered_text(font, "获得奖励", DESIGN_W / 2.0, y + 18.0, C["text_primary"], 14.0)
	
	var reward_items: Array[Dictionary] = [
		{"icon": "gold", "amount": "+%d" % _rewards["gold"], "color": C["gold"]},
		{"icon": "exp", "amount": "+%d" % _rewards["exp"], "color": C["thunder"]},
	]
	if int(_rewards.get("gems", 0)) > 0:
		reward_items.append({"icon": "diamond", "amount": "+%d" % int(_rewards["gems"]), "color": Color(1.0, 0.45, 0.8)})
	if _rewards["item"]:
		reward_items.append({
			"icon": _get_reward_item_icon_key(str(_rewards.get("item", ""))),
			"amount": "%s x%d" % [str(_rewards.get("item_name", _rewards.get("item", "道具"))), maxi(1, int(_rewards.get("item_count", 1)))],
			"color": C["text_primary"]
		})
	
	var slot_w := 54.0
	var gap := 13.0
	var total_w := reward_items.size() * slot_w + (reward_items.size() - 1) * gap
	var start_x := (DESIGN_W - total_w) / 2.0
	for i in range(reward_items.size()):
		var item := reward_items[i]
		var bounce := sin(progress * PI * 2.0 + i * 0.5) * 4.0 * (1.0 - progress)
		var x := start_x + i * (slot_w + gap)
		_draw_texture_fit(_tex("reward_slot"), Rect2(x, y + 34.0 + bounce, slot_w, 56.0))
		_draw_texture_fit(_tex(item["icon"]), Rect2(x + 8.0, y + 38.0 + bounce, 38.0, 38.0))
		_draw_centered_text(font, item["amount"], x + slot_w / 2.0, y + 91.0, item["color"], 11.0)

func _get_reward_item_icon_key(item_id: String) -> String:
	match item_id:
		"capture_ball":
			return "item_capture"
		"capture_ball_plus", "capture_ball_elite":
			return "item_capture_plus"
		"exp_potion":
			return "item_exp"
		"exp_crystal":
			return "item_exp_crystal"
		"gold_bag":
			return "item_gold"
		"gold_chest":
			return "item_gold_chest"
		"hp_potion", "hp_potion_large":
			return "item_hp"
		_:
			return "item_generic"

func _draw_exp_section(font: Font, y: float) -> void:
	_draw_texture_fit(_tex("team_exp_panel"), Rect2(16.0, y, DESIGN_W - 32.0, 116.0), 0.95)
	_draw_centered_text(font, "共享经验槽", DESIGN_W / 2.0, y + 18.0, C["text_primary"], 14.0)

	var shared: Dictionary = _monster_exp_awards.get("shared", {})
	var desc := TranslationServer.translate("本次 +%d · 经验槽 %d/%d") % [int(shared.get("added", _rewards.get("exp", 0))), int(shared.get("current", 0)), int(shared.get("capacity", 0))]
	_draw_centered_text(font, desc, DESIGN_W / 2.0, y + 106.0, C["text_muted"], 9.5)

	var team: Array = _battle_result.get("playerTeam", [])
	var display_team: Array = team.filter(func(m): return m != null).slice(0, 5)
	var card_w := 54.0
	var gap := 10.0
	var total_w: float = float(display_team.size()) * card_w + float(max(0, display_team.size() - 1)) * gap
	var start_x: float = (DESIGN_W - total_w) / 2.0
	for i in range(display_team.size()):
		var monster: Dictionary = display_team[i]
		var x: float = start_x + float(i) * (card_w + gap)
		_draw_texture_fit(_tex("monster_exp_card"), Rect2(x, y + 30.0, card_w, 68.0))
		_draw_monster_portrait(monster, Rect2(x + 6.0, y + 35.0, 42.0, 42.0))

func _draw_levelups_section(font: Font, y: float) -> void:
	if _level_ups.is_empty():
		return
	var display_ups: Array = _level_ups.slice(0, 2)
	var pulse := sin(_time_acc * 5.0) * 0.2 + 0.8
	
	for i in range(display_ups.size()):
		var up: Dictionary = display_ups[i]
		var item_y := y + i * 28.0
		var monster_id := str(up.get("monsterId", ""))
		var monster_name := str(MonsterDb.get_monster(monster_id).get("name", monster_id if not monster_id.is_empty() else "精灵"))
		
		_draw_texture_fit(_tex("fx_levelup_glow"), Rect2(DESIGN_W / 2.0 - 130.0, item_y - 2.0, 260.0, 28.0), 0.38 * pulse)
		draw_string(font, Vector2(DESIGN_W / 2.0 - 105.0, item_y + 17), TranslationServer.translate("升级"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.84, 0.0, pulse))
		draw_string(font, Vector2(DESIGN_W / 2.0 - 62.0, item_y + 17), TranslationServer.translate(monster_name), HORIZONTAL_ALIGNMENT_LEFT, 112.0, 11, C["gold"])
		draw_string(font, Vector2(DESIGN_W / 2.0 + 56.0, item_y + 17), "Lv.%d → Lv.%d" % [up.get("oldLevel", 0), up.get("newLevel", 0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C["success"])

func _draw_buttons(font: Font, y: float) -> void:
	var progress := _button_anim_progress
	var base_scale := 0.8 + progress * 0.2
	
	var btn_w := 112.0
	var btn_h := 46.0
	
	if _has_next_stage:
		var scaled_w := btn_w * base_scale
		var scaled_h := btn_h * base_scale
		var draw_y := y + (btn_h - scaled_h) / 2.0
		var back_x := 24.0
		var next_x := DESIGN_W / 2.0 - btn_w / 2.0
		var retry_x := DESIGN_W - btn_w - 24.0

		_draw_texture_fit(_tex("btn_secondary"), Rect2(back_x + (btn_w - scaled_w) / 2.0, draw_y, scaled_w, scaled_h))
		_draw_centered_text(font, "返回", back_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["text_primary"], 13.0)
		_back_btn_rect = Rect2(back_x, y, btn_w, btn_h)

		var next_scaled_w := btn_w * 1.25 * base_scale
		_draw_texture_fit(_tex("btn_next"), Rect2(next_x - (next_scaled_w - btn_w) / 2.0, draw_y, next_scaled_w, scaled_h))
		_draw_centered_text(font, "下一关", next_x + btn_w / 2.0, y + btn_h / 2.0 + 6, C["white"], 16.0)
		_next_btn_rect = Rect2(next_x, y, btn_w, btn_h)

		_draw_texture_fit(_tex("btn_secondary"), Rect2(retry_x + (btn_w - scaled_w) / 2.0, draw_y, scaled_w, scaled_h))
		_draw_centered_text(font, "课堂升级精灵", retry_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["text_primary"], 9.0)
		_retry_btn_rect = Rect2(retry_x, y, btn_w, btn_h)
	else:
		var btn_x := (DESIGN_W - btn_w) / 2.0
		var scaled_w := btn_w * base_scale
		var scaled_h := btn_h * base_scale
		var draw_x := btn_x + (btn_w - scaled_w) / 2.0
		var draw_y := y + (btn_h - scaled_h) / 2.0
		
		if _is_win:
			var back_x := 62.0
			var classroom_x := DESIGN_W - btn_w - 62.0
			_draw_texture_fit(_tex("btn_secondary"), Rect2(back_x, draw_y, scaled_w, scaled_h))
			_draw_centered_text(font, "返回关卡", back_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 13.0)
			_draw_texture_fit(_tex("btn_secondary"), Rect2(classroom_x, draw_y, scaled_w, scaled_h))
			_draw_centered_text(font, "课堂升级精灵", classroom_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 9.0)
			_back_btn_rect = Rect2(back_x, y, btn_w, btn_h)
			_retry_btn_rect = Rect2(classroom_x, y, btn_w, btn_h)
		else:
			_draw_texture_fit(_tex("btn_retry"), Rect2(draw_x, draw_y, scaled_w, scaled_h))
			_draw_centered_text(font, "重试", btn_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 16.0)
			_back_btn_rect = Rect2(btn_x, y, btn_w, btn_h)
			_retry_btn_rect = Rect2()
			var back_x := 24.0
			var next_x := DESIGN_W / 2.0 - btn_w / 2.0
			var retry_x := DESIGN_W - btn_w - 24.0
			_draw_texture_fit(_tex("btn_secondary"), Rect2(back_x + (btn_w - scaled_w) / 2.0, draw_y, scaled_w, scaled_h))
			_draw_centered_text(font, "返回庄园", back_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 12.0)
			_back_btn_rect = Rect2(back_x, y, btn_w, btn_h)

			var next_scaled_w := btn_w * 1.25 * base_scale
			_draw_texture_fit(_tex("btn_next"), Rect2(next_x - (next_scaled_w - btn_w) / 2.0, draw_y, next_scaled_w, scaled_h))
			_draw_centered_text(font, "回精灵课堂升级", next_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 9.0)
			_next_btn_rect = Rect2(next_x, y, btn_w, btn_h)

			_draw_texture_fit(_tex("btn_retry"), Rect2(retry_x + (btn_w - scaled_w) / 2.0, draw_y, scaled_w, scaled_h))
			_draw_centered_text(font, "重试", retry_x + btn_w / 2.0, y + btn_h / 2.0 + 5, C["white"], 16.0)
			_retry_btn_rect = Rect2(retry_x, y, btn_w, btn_h)
		if _is_win:
			_next_btn_rect = Rect2()

# ==================== 绘制辅助 ====================

func _draw_centered_text(font: Font, text: String, x: float, y: float, color: Color, size: float) -> void:
	text = TranslationServer.translate(text)
	var tw := 200.0
	# 阴影
	draw_string(font, Vector2(x - tw / 2.0 + 1, y + 1), text, HORIZONTAL_ALIGNMENT_CENTER, tw, size, Color(0, 0, 0, 0.4))
	draw_string(font, Vector2(x - tw / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, tw, size, color)

func _draw_victory_halo(rect: Rect2) -> void:
	var center := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.42)
	var pulse := 0.92 + sin(_time_acc * 2.1) * 0.05
	var max_radius := minf(rect.size.x, rect.size.y) * 0.62 * pulse
	for i in range(8, 0, -1):
		var t := float(i) / 8.0
		var radius := max_radius * t
		var alpha := 0.03 + (1.0 - t) * 0.052
		draw_circle(center, radius, Color(1.0, 0.86, 0.18, alpha))
	var ray_count := 18
	for i in range(ray_count):
		var angle := _time_acc * 0.22 + TAU * float(i) / float(ray_count)
		var half_width := 0.045 + 0.015 * sin(_time_acc * 1.7 + float(i))
		var inner := max_radius * 0.16
		var outer := max_radius * (0.82 + 0.10 * sin(_time_acc * 1.3 + float(i) * 0.9))
		var points := PackedVector2Array([
			center + Vector2(cos(angle - half_width), sin(angle - half_width)) * inner,
			center + Vector2(cos(angle), sin(angle)) * outer,
			center + Vector2(cos(angle + half_width), sin(angle + half_width)) * inner,
		])
		var color := Color(0.83, 0.93, 0.18, 0.13).lerp(Color(1.0, 0.86, 0.18, 0.13), 0.55 + 0.25 * sin(_time_acc + float(i)))
		draw_colored_polygon(points, color)
	for i in range(5):
		var radius := max_radius * (0.10 + float(i) * 0.08)
		var alpha := 0.16 - float(i) * 0.022
		draw_circle(center, radius, Color(1.0, 0.96, 0.38, alpha))

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

func _tex(key: String) -> Texture2D:
	var path: String = RESULT_ASSETS.get(key, "")
	if path.is_empty():
		path = COMMON_ASSETS.get(key, "")
	if path.is_empty():
		return null
	return _get_texture(path)

func _get_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex := load(path) as Texture2D
	_texture_cache[path] = tex
	return tex

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, opacity))

func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		draw_rect(rect, C["bg_medium"])
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var src_aspect := tex_size.x / tex_size.y
	var dst_aspect := rect.size.x / rect.size.y
	var src_rect := Rect2(Vector2.ZERO, tex_size)
	if src_aspect > dst_aspect:
		var crop_w := tex_size.y * dst_aspect
		src_rect.position.x = (tex_size.x - crop_w) / 2.0
		src_rect.size.x = crop_w
	else:
		var crop_h := tex_size.x / dst_aspect
		src_rect.position.y = (tex_size.y - crop_h) / 2.0
		src_rect.size.y = crop_h
	draw_texture_rect_region(tex, rect, src_rect, Color(1.0, 1.0, 1.0, opacity))

func _draw_monster_portrait(monster: Dictionary, rect: Rect2) -> void:
	var monster_id: String = monster.get("monsterId", monster.get("id", ""))
	var path: String = MonsterArtDBScript.get_art_path(monster_id, "result")
	var tex := _get_texture(path)
	if tex:
		_draw_texture_fit(tex, rect)
		return
	var font := PROJECT_ROUND_FONT
	_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 8.0, Color(0.05, 0.08, 0.16, 0.78))
	var fallback := str(monster.get("emoji", "?"))
	_draw_centered_text(font, fallback, rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y * 0.62, C["white"], minf(rect.size.x * 0.45, 20.0))

# ============================================
# battle/capture_system.gd - 收服系统
# 翻译自 js/collection/capture.js
# ============================================
class_name CaptureSystem
extends RefCounted

## 怪物收服逻辑：收服概率计算、战斗评价星级
## 作为工具类（静态方法），不需要 extends Node
## 使用 RefCounted 轻量对象

# ========== 稀有度基础收服率 ==========
## 稀有度 → 基础收服率（来自 balance-design.md §2.3，BD-P5 调优后）
## ★1=80%, ★2=45%, ★3=25%, ★4=15%, ★5=8%
static var BASE_CAPTURE_RATE: Dictionary = {
	1: 0.80,
	2: 0.45,
	3: 0.25,
	4: 0.15,
	5: 0.08
}

# ========== 新手收服保护机制 ==========
## 前3关(stage_1_1/1_2/1_3)连续失败3次后，下次收服概率+30%
static var ROOKIE_STAGES: Array = ["stage_1_1", "stage_1_2", "stage_1_3"]

## 获取新手保护加成
## @param stage_id - 当前关卡ID
## @param consecutive_fails - 连续收服失败次数
## @return 额外加成概率 (0 或 0.30)
static func get_rookie_bonus(stage_id: String, consecutive_fails: int) -> float:
	if not ROOKIE_STAGES.has(stage_id):
		return 0.0
	if consecutive_fails >= 3:
		return 0.30
	return 0.0


# ========== 收服概率计算 ==========

## 计算收服概率（与 balance-design.md §2.3 对齐）
##
## 收服概率 = baseCaptureRate × (1 - currentHP/maxHP) × levelBonus
## levelBonus = 1 + (playerLevel - enemyLevel) × 0.05  (上限 1.5x)
##
## @param remaining_hp - 怪物剩余血量
## @param max_hp - 怪物最大血量
## @param player_level - 玩家等级
## @param enemy_level - 敌人等级
## @param rarity - 怪物稀有度 1-5
## @param options - 额外选项字典
## @option stage_id - 当前关卡ID（用于新手保护）
## @option consecutive_fails - 连续收服失败次数
## @return 0-1 的概率值
static func calc_capture_probability(remaining_hp: float, max_hp: float, player_level: int, enemy_level: int, rarity: int, options: Dictionary = {}) -> float:
	# 基础收服率
	var base_rate = BASE_CAPTURE_RATE.get(rarity, BASE_CAPTURE_RATE[1])

	# 血量因子：敌人越虚弱概率越高（满血时为0，全灭时为1）
	var hp_factor = 1.0
	if max_hp > 0:
		hp_factor = 1.0 - maxi(0.0, remaining_hp) / max_hp

	# 等级差加成（上限1.5x）
	var level_bonus = mini(1.5, 1.0 + (player_level - enemy_level) * 0.05)

	var probability = base_rate * hp_factor * level_bonus

	# 新手收服保护加成（BD-P5）
	var stage_id = options.get("stage_id", "")
	var consecutive_fails = options.get("consecutive_fails", 0)
	if stage_id != "":
		var rookie_bonus = get_rookie_bonus(stage_id, consecutive_fails)
		if rookie_bonus > 0.0:
			probability = mini(1.0, probability + rookie_bonus)

	# 最终概率限制在 3% - 100%（新手保底可达100%）
	return clampf(probability, 0.03, 1.0)


## 执行收服判定
## @param probability - 收服概率 0-1
## @return 是否收服成功
static func attempt_capture(probability: float) -> bool:
	var roll = randf()
	return roll < probability


## 获取收服状态文本
## @param probability - 收服概率 0-1
## @param captured - 是否成功
## @return { title, desc }
static func get_capture_result_text(probability: float, captured: bool) -> Dictionary:
	var percent = int(roundi(probability * 100))
	if captured:
		return {
			"title": "✨ 收服成功！",
			"desc": "恭喜！你收服了野生精灵！\n（收服概率: %d%%）" % percent
		}
	else:
		return {
			"title": "💨 收服失败...",
			"desc": "精灵逃脱了！\n（收服概率: %d%%）" % percent
		}


## 计算战斗评价星级
## @param turn_count - 战斗回合数
## @param max_turns - 最大回合数
## @param player_hp_ratio - 玩家剩余血量比例
## @return 1-3 星级
static func calc_battle_stars(turn_count: int, max_turns: int, player_hp_ratio: float) -> int:
	# 3星：回合数 < 40% maxTurns 且 血量 > 50%
	# 2星：回合数 < 70% maxTurns 且 血量 > 20%
	# 1星：其他胜利情况
	var turn_ratio = float(turn_count) / float(maxi(max_turns, 1))
	if turn_ratio < 0.4 and player_hp_ratio > 0.5:
		return 3
	elif turn_ratio < 0.7 and player_hp_ratio > 0.2:
		return 2
	return 1
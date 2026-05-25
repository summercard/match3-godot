# ============================================
# battle/capture_system.gd - 收服系统
# 翻译自 js/collection/capture.js
# ============================================
class_name CaptureSystem
extends RefCounted

const RewardRulesScript = preload("res://src/battle/reward_rules.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")

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

## 计算战斗内驯服窗口。
## state:
## - locked: 目标状态太稳定，捕捉难以发生
## - unstable: 已出现机会，但还不稳定
## - open: 可捕捉窗口
## - prime: 理想捕捉窗口
## - overpowered: 已击倒，仍可尝试但稳定度下降
static func calc_taming_window(remaining_hp: float, max_hp: float, options: Dictionary = {}) -> Dictionary:
	var safe_max := maxf(max_hp, 1.0)
	var hp_ratio := clampf(remaining_hp / safe_max, 0.0, 1.0)
	var defeated := remaining_hp <= 0.0
	var suppressed := bool(options.get("suppressed", false))
	var state := "locked"
	var label := "未开启"
	var bonus := 0.0
	var stability := 0.15
	var reason := "目标状态稳定，先削弱或压制它。"

	if defeated:
		state = "overpowered"
		label = "过载"
		bonus = 0.04
		stability = 0.45
		reason = "目标已被击倒，仍可尝试捕捉，但稳定度下降。"
	elif hp_ratio <= 0.20:
		state = "prime"
		label = "最佳"
		bonus = 0.22
		stability = 0.95
		reason = "目标非常虚弱，是理想捕捉窗口。"
	elif hp_ratio <= 0.35:
		state = "open"
		label = "开启"
		bonus = 0.14
		stability = 0.78
		reason = "目标已被削弱，可以尝试捕捉。"
	elif hp_ratio <= 0.50:
		state = "unstable"
		label = "不稳"
		bonus = 0.06
		stability = 0.48
		reason = "目标开始动摇，但窗口还不稳定。"

	if suppressed and state != "locked":
		bonus += 0.06
		stability = minf(1.0, stability + 0.12)
		reason += " 压制效果提高了稳定度。"
	elif suppressed:
		state = "unstable"
		label = "压制"
		bonus = 0.06
		stability = 0.42
		reason = "目标被压制，捕捉窗口开始松动。"

	var score := bonus + stability * 0.18
	return {
		"state": state,
		"label": label,
		"bonus": clampf(bonus, 0.0, 0.35),
		"stability": clampf(stability, 0.0, 1.0),
		"hp_ratio": hp_ratio,
		"score": score,
		"suppressed": suppressed,
		"reason": reason
	}

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

	var taming_window: Dictionary = options.get("taming_window", {})
	if not taming_window.is_empty():
		probability += float(taming_window.get("bonus", 0.0))

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
static func get_capture_feedback(probability: float, captured: bool, taming_window: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var percent = int(roundi(probability * 100))
	var window_label := str(taming_window.get("label", ""))
	var window_line := ""
	if not window_label.is_empty():
		window_line = "\n窗口: %s（稳定度 %d%%）" % [window_label, int(round(float(taming_window.get("stability", 0.0)) * 100.0))]
	var reason := _build_capture_reason(probability, captured, taming_window, options)
	var advice := _build_capture_advice(probability, captured, taming_window, options)
	var target: Dictionary = options.get("target", {})
	var target_tags := get_target_value_tags(target)
	if captured:
		return {
			"title": "✨ 收服成功！",
			"desc": "收服成功（概率: %d%%）%s\n%s" % [percent, window_line, reason],
			"reason": reason,
			"advice": advice,
			"probability": probability,
			"target_tags": target_tags
		}
	else:
		return {
			"title": "💨 收服失败...",
			"desc": "收服失败（概率: %d%%）%s\n%s" % [percent, window_line, reason],
			"reason": reason,
			"advice": advice,
			"probability": probability,
			"target_tags": target_tags
		}

static func get_capture_result_text(probability: float, captured: bool, taming_window: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	return get_capture_feedback(probability, captured, taming_window, options)


static func get_capture_skip_feedback(reason_id: String, options: Dictionary = {}) -> Dictionary:
	var target: Dictionary = options.get("target", {})
	var item_name := str(options.get("item_name", "捕捉球"))
	var title := "未捕捉"
	var reason := "本场没有进行捕捉判定。"
	var advice := "开启自动捕捉并选择可用捕捉球后，胜利结算会自动尝试。"
	if reason_id == "auto_off":
		reason = "自动捕捉已关闭，本场默认不进行捕捉。"
		advice = "需要抓宠时，先打开战斗底部的自动捕捉开关。"
	elif reason_id == "no_item":
		reason = "未选择捕捉球，自动捕捉不会空手触发。"
		advice = "在背包装备捕捉球，或在战斗底部道具栏选择本场使用的捕捉球。"
	elif reason_id == "item_empty":
		reason = "%s数量不足，自动捕捉已跳过。" % item_name
		advice = "通过掉落、商店或奖励补充捕捉球后再开启自动捕捉。"
	elif reason_id == "invalid_item":
		reason = "当前选择的道具不是捕捉球，本场不进行捕捉判定。"
		advice = "请选择捕捉类道具作为自动捕捉消耗品。"
	elif reason_id == "storage_unavailable":
		reason = "背包数据暂不可用，本场不消耗道具也不捕捉。"
		advice = "返回主界面后重新进入战斗可刷新背包状态。"
	elif reason_id == "no_target":
		title = "无捕捉目标"
		reason = "本场没有可记录的捕捉目标。"
		advice = "遇到可捕捉敌人时再开启自动捕捉。"
	return {
		"title": title,
		"desc": "%s\n%s" % [reason, advice],
		"reason": reason,
		"advice": advice,
		"probability": 0.0,
		"target_tags": get_target_value_tags(target),
		"skipped": true,
		"skip_reason": reason_id
	}


static func get_target_value_tags(monster: Dictionary) -> Array[String]:
	if monster.is_empty():
		return []
	var tags: Array[String] = []
	var rarity := int(monster.get("rarity", 1))
	tags.append("★%d" % rarity)
	var affinity := str(monster.get("boardAffinity", ""))
	if affinity.is_empty():
		var monster_id := str(monster.get("monsterId", monster.get("id", "")))
		var template := MonsterDbScript.get_monster(monster_id)
		if not template.is_empty():
			affinity = MonsterDbScript.get_board_affinity(template)
	if affinity.is_empty():
		affinity = str(monster.get("element", ""))
	if not affinity.is_empty():
		tags.append("%s能量" % _element_label(affinity))
	var skill: Dictionary = monster.get("skill", {})
	var role := _skill_role_label(skill)
	if not role.is_empty():
		tags.append(role)
	if rarity <= 1:
		tags.append("易培养")
	elif rarity >= 3:
		tags.append("稀有")
	return tags


static func _build_capture_reason(probability: float, captured: bool, taming_window: Dictionary, options: Dictionary) -> String:
	var state := str(taming_window.get("state", ""))
	var item_used: Dictionary = options.get("item_used", {})
	if captured:
		if not item_used.is_empty():
			return "道具和窗口一起压住了目标。"
		if state == "prime":
			return "最佳窗口让目标足够稳定。"
		if state == "open":
			return "捕捉窗口已开启，目标被成功稳住。"
		return "这次判定成功，目标加入队伍。"
	if probability < 0.20:
		return "概率偏低，目标仍然不够虚弱。"
	if state == "locked":
		return "窗口未开启，目标状态还太稳定。"
	if state == "unstable":
		return "窗口不稳，目标挣脱了。"
	if state == "overpowered":
		return "目标过载，稳定度下降后挣脱。"
	return "窗口已开，但这次判定没有成功。"


static func _build_capture_advice(probability: float, captured: bool, taming_window: Dictionary, options: Dictionary) -> String:
	if captured:
		return "去队伍界面查看它的能量亲和与技能定位。"
	var state := str(taming_window.get("state", ""))
	var item_used: Dictionary = options.get("item_used", {})
	if state == "locked" or probability < 0.20:
		return "先把血量压到 35%% 以下，或用束缚/压制打开窗口。"
	if state == "unstable":
		return "再削弱一点，进入开启或最佳窗口后再抓。"
	if item_used.is_empty():
		return "装备捕捉球可以提高下次成功率。"
	return "下次尽量在最佳窗口使用更高阶捕捉球。"


static func _skill_role_label(skill: Dictionary) -> String:
	var skill_type := str(skill.get("type", ""))
	if skill_type == "strike":
		return "输出技"
	if skill_type == "ward":
		return "守护技"
	if skill_type == "tempo":
		return "控场技"
	var skill_name := str(skill.get("name", ""))
	return "技能:%s" % skill_name if not skill_name.is_empty() else ""


static func _element_label(element: String) -> String:
	var labels := {
		"fire": "火",
		"water": "水",
		"grass": "草",
		"thunder": "雷",
		"light": "光",
		"dark": "暗",
		"earth": "土",
		"wind": "风",
		"ice": "冰"
	}
	return labels.get(element, element)


## 计算战斗评价星级
## @param turn_count - 战斗回合数
## @param max_turns - 最大回合数
## @param player_hp_ratio - 玩家剩余血量比例
## @return 1-3 星级
static func calc_battle_stars(turn_count: int, max_turns: int, player_hp_ratio: float) -> int:
	return RewardRulesScript.calc_battle_stars(turn_count, max_turns, player_hp_ratio)

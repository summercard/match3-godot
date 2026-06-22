class_name StatCalculator
extends RefCounted
## 统一属性成长公式
## 设计目的：敌人/宠物/捕获后宠物都走同一套公式
## 输入: monster_id + level + nature_id(+ 可选 rarity_override)
## 输出: 完整属性字典 {hp, atk, def, spd, level, rarity, nature}
##
## 公式：
##   growth = (1 + growth_rate) ^ (level - 1)
##   growth_rate = MonsterDb.RARITY_GROWTH_RATE[rarity]   # HP/ATK/SPD 使用
##   DEF = baseDEF + (level - 1) × flat_def_growth
##
## 与旧 MonsterDb.get_monster_stats 兼容：保留其函数，新代码优先调 calc()

const MAX_LEVEL: int = 100  # 等级封顶：宠物/敌人共用上限（主人定 2026-06-10）

const NORMAL_ENEMY_LEVEL_BONUS: int = 5
const ELITE_BASE_STAT_MULT: float = 1.10
const ELITE_ENEMY_HP_MULT: float = 2.0
const ELITE_ENEMY_ATK_MULT: float = 1.5

enum EnemyTier { NORMAL, ELITE }

## 等级成长系数（复利：每级基于当前属性按百分比继续成长）
static func growth_mult(level: int, rarity: int) -> float:
	if level <= 1:
		return 1.0
	var rate: float = MonsterDb.RARITY_GROWTH_RATE.get(rarity, 0.08)
	return pow(1.0 + rate, float(level - 1))

## 等级封顶（主人定 MAX_LEVEL=50，敌人都受同一封顶限制）
static func clamp_level(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL)

## 性格对指定属性的修正倍率（无性格=1.0，包装一下方便调用）
static func nature_mult(nature_id: String, stat_key: String) -> float:
	if nature_id.is_empty():
		return 1.0
	return NatureDB.get_nature_stat_mult(nature_id, stat_key)

## ★ 统一入口
## monster_id: MONSTER_DB 中的 key（例 "monster_001"）
## level: 等级（自动封顶到 MAX_LEVEL）
## nature_id: 性格 ID（空字符串 = 中性 1.0 倍；随机生成用 NatureDB.random_nature()）
## rarity_override: 强制覆盖怪物自身 rarity（默认 -1 = 不覆盖）
static func calc(monster_id: String, level: int, nature_id: String = "", rarity_override: int = -1) -> Dictionary:
	return _calc(monster_id, level, nature_id, rarity_override)

static func _calc(monster_id: String, level: int, nature_id: String, rarity_override: int, force_elite: bool = false) -> Dictionary:
	var data: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
	if data.is_empty():
		return {}

	var lv := clamp_level(level)
	var rarity: int = rarity_override if rarity_override > 0 else int(data.get("rarity", 2))
	var g: float = growth_mult(lv, rarity)

	var hp  := int(float(data.get("baseHP",  0)) * g * nature_mult(nature_id, "hp"))
	var atk := int(float(data.get("baseATK", 0)) * g * nature_mult(nature_id, "atk"))
	var def_per_level: float = MonsterDb.RARITY_DEF_GROWTH_PER_LEVEL.get(rarity, 0.15)
	var flat_def: float = float(data.get("baseDEF", 0)) + float(lv - 1) * def_per_level
	var df  := int(flat_def * nature_mult(nature_id, "def"))
	var spd := int(float(data.get("baseSPD", 0)) * g * nature_mult(nature_id, "spd"))
	var is_boss := bool(data.get("isBoss", false))
	var is_elite := bool(data.get("isElite", false)) or force_elite

	var stats := {
		"id": str(data.get("id", monster_id)),
		"name": str(data.get("name", "")),
		"element": str(data.get("element", "")),
		"boardAffinity": MonsterDb.get_board_affinity(data),
		"rarity": rarity,
		"emoji": str(data.get("emoji", "")),
		"level": lv,
		"nature": nature_id,
		"hp": hp,
		"maxHP": hp,
		"atk": atk,
		"def": df,
		"spd": spd,
		"growth": g,
		"skill": MonsterDb.normalize_skill(data.get("skill", {})),
		"skillCharge": 0,
		"leaderSkill": str(data.get("leaderSkill", "")),
		"enemySkills": null if not data.has("enemySkills") else data.get("enemySkills", []).duplicate(true),
		"isBoss": is_boss,
		"isElite": is_elite,
		"capturable": bool(data.get("capturable", not is_boss)),
	}
	if is_elite:
		_apply_elite_base_modifier(stats)
	return stats

## 敌方只负责生成随机性格并解析实际战斗等级，属性仍走 calc()。
static func calc_enemy(monster_id: String, level: int, tier: int = EnemyTier.NORMAL) -> Dictionary:
	var nature := NatureDB.random_nature()  # ★ 主人定的：每次 random
	var stats := _calc(monster_id, enemy_combat_level(monster_id, level), nature, -1, tier == EnemyTier.ELITE)
	if bool(stats.get("isElite", false)):
		_apply_elite_enemy_modifier(stats)
	return stats

## 普通敌人比关卡标注等级高 5 级；Boss 保持原关卡等级。
static func enemy_combat_level(monster_id: String, base_level: int) -> int:
	var data: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
	var bonus := 0 if bool(data.get("isBoss", false)) else NORMAL_ENEMY_LEVEL_BONUS
	return clamp_level(base_level + bonus)

## 兼容旧调用；基础强度已经进入物种数据，不再额外乘倍率。
static func apply_enemy_difficulty(stats: Dictionary) -> Dictionary:
	return stats

static func calc_elite_enemy(monster_id: String, level: int) -> Dictionary:
	return calc_enemy(monster_id, level, EnemyTier.ELITE)

## 兼容旧入口；模板或随机精英都会应用敌方精英倍率。
static func calc_enemy_auto(monster_id: String, level: int) -> Dictionary:
	var data: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
	if data.is_empty():
		return {}
	return calc_enemy(monster_id, level)

## 兼容旧入口；ELITE tier 应用收服后的精英基础倍率。
static func calc_with_tier(monster_id: String, level: int, nature_id: String = "", tier: int = EnemyTier.NORMAL) -> Dictionary:
	return _calc(monster_id, level, nature_id, -1, tier == EnemyTier.ELITE)

static func _apply_tier_modifier(stats: Dictionary, tier: int) -> Dictionary:
	if tier != EnemyTier.ELITE or bool(stats.get("isElite", false)):
		return stats
	stats["isElite"] = true
	_apply_elite_base_modifier(stats)
	return stats

static func _apply_elite_base_modifier(stats: Dictionary) -> void:
	_scale_stats(stats, ["hp", "maxHP", "atk", "def", "spd"], ELITE_BASE_STAT_MULT)

static func _apply_elite_enemy_modifier(stats: Dictionary) -> void:
	_scale_stats(stats, ["hp", "maxHP"], ELITE_ENEMY_HP_MULT)
	_scale_stats(stats, ["atk"], ELITE_ENEMY_ATK_MULT)

static func _scale_stats(stats: Dictionary, keys: Array, multiplier: float) -> void:
	for key in keys:
		if stats.has(key):
			stats[key] = int(float(stats.get(key, 0)) * multiplier)

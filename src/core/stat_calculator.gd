class_name StatCalculator
extends RefCounted
## 统一属性成长公式
## 设计目的：敌人/宠物/捕获后宠物都走同一套公式
## 输入: monster_id + level + nature_id(+ 可选 rarity_override)
## 输出: 完整属性字典 {hp, atk, def, spd, level, rarity, nature}
##
## 公式：
##   growth = 1 + (level - 1) × growth_rate
##   growth_rate = MonsterDb.RARITY_GROWTH_RATE[rarity]   # ★1=8% ~ ★5=16%
##   stat = base × growth × nature_mult
##
## 与旧 MonsterDb.get_monster_stats 兼容：保留其函数，新代码优先调 calc()

const MAX_LEVEL: int = 100  # 等级封顶：宠物/敌人共用上限（主人定 2026-06-10）

## 等级成长系数（线性，与原公式完全一致）
static func growth_mult(level: int, rarity: int) -> float:
	if level <= 1:
		return 1.0
	var rate: float = MonsterDb.RARITY_GROWTH_RATE.get(rarity, 0.10)
	return 1.0 + float(level - 1) * rate

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
	var data: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
	if data.is_empty():
		return {}

	var lv := clamp_level(level)
	var rarity: int = rarity_override if rarity_override > 0 else int(data.get("rarity", 2))
	var g: float = growth_mult(lv, rarity)

	var hp  := int(float(data.get("baseHP",  0)) * g * nature_mult(nature_id, "hp"))
	var atk := int(float(data.get("baseATK", 0)) * g * nature_mult(nature_id, "atk"))
	var df  := int(float(data.get("baseDEF", 0)) * g * nature_mult(nature_id, "def"))
	var spd := int(float(data.get("baseSPD", 0)) * g * nature_mult(nature_id, "spd"))

	return {
		"id": str(data.get("id", monster_id)),
		"name": str(data.get("name", "")),
		"element": str(data.get("element", "")),
		"rarity": rarity,
		"level": lv,
		"nature": nature_id,
		"hp": hp,
		"maxHP": hp,
		"atk": atk,
		"def": df,
		"spd": spd,
		"growth": g,
		"isBoss": bool(data.get("isBoss", false)),
	}

## 给敌人用的便捷：随机一个性格 + 套上等级
static func calc_enemy(monster_id: String, level: int) -> Dictionary:
	var nature := NatureDB.random_nature()  # ★ 主人定的：每次 random
	return calc(monster_id, level, nature)

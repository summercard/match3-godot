# ============================================
# battle/damage_calculator.gd - 伤害计算器
# 来源: js/battle/battleManager.js 中的伤害公式
# ============================================
class_name DamageCalculator
extends RefCounted

# 属性克制表 (与 monster_db.gd 保持一致)
const ELEMENT_CHART: Dictionary = {
	"fire":    { "fire": 1.0, "water": 0.5, "grass": 2.0, "thunder": 1.0, "light": 1.0 },
	"water":   { "fire": 2.0, "water": 1.0, "grass": 0.5, "thunder": 1.0, "light": 1.0 },
	"grass":   { "fire": 0.5, "water": 2.0, "grass": 1.0, "thunder": 1.0, "light": 1.0 },
	"thunder": { "fire": 1.0, "water": 1.0, "grass": 1.0, "thunder": 1.0, "light": 2.0 },
	"light":   { "fire": 1.0, "water": 1.0, "grass": 1.0, "thunder": 0.5, "light": 1.0 }
}

# 属性克制倍率获取
static func get_element_multiplier(attacker_elem: String, defender_elem: String) -> float:
	if ELEMENT_CHART.has(attacker_elem) and ELEMENT_CHART[attacker_elem].has(defender_elem):
		return ELEMENT_CHART[attacker_elem][defender_elem]
	return 1.0

# ============================================
# 玩家伤害计算
# ============================================
# 基础伤害 = ATK × (消除数 / 3) × combo加成(1 + (combo-1)×0.3)
# 总伤害 = 基础伤害 × 属性克制 × 队长ATK加成 × 属性协同ATK加成
# 最终伤害 = 总伤害 × (1 - def/(def+100)) × 随机波动(0.9~1.1)
static func calc_player_damage(
	attacker_atk: float,
	attacker_element: String,
	target_def: float,
	gem_count: int,
	combo_count: int,
	element_mult: float = 1.0,
	leader_atk_boost: float = 1.0,
	synergy_atk_mult: float = 1.0
) -> int:
	# 新手保护：消除数 < 3 时按 3 计算（保底伤害）
	var effective_gem_count := maxi(gem_count, 3)
	
	# 基础伤害
	var base_damage := attacker_atk * (effective_gem_count / 3.0)
	
	# Combo 加成: 每次 combo +30%
	var combo_multiplier := 1.0 + (combo_count - 1) * 0.3
	
	# 总伤害雏形
	var total_damage := base_damage * combo_multiplier
	
	# 属性克制
	total_damage *= element_mult
	
	# 队长技能属性ATK加成
	total_damage *= leader_atk_boost
	
	# 属性协同ATK加成 (2同属性+15%, 3同属性+30%)
	total_damage *= synergy_atk_mult
	
	# 防御减免 (上限50%, def越高减免越多)
	var def_reduction := target_def / (target_def + 100.0)
	total_damage *= (1.0 - def_reduction)
	
	# ±10% 随机波动 (增加战斗变数)
	var random_variance := 0.9 + randf() * 0.2
	
	# 最终伤害 (最低1点)
	var final_damage := int(maxi(1, total_damage * random_variance))
	
	return final_damage

# ============================================
# 敌方伤害计算
# ============================================
# 基础伤害 = ATK × (0.6 + random×0.3)
# 总伤害 = 基础伤害 × 属性克制 × 冰冻降低 × (1 - def/(def+80))
# 最终伤害 = 总伤害 × 队长DEF加成 × 属性协同DEF降低
static func calc_enemy_damage(
	enemy_atk: float,
	enemy_element: String,
	target_def: float,
	target_element: String,
	freeze_mult: float = 1.0,
	leader_def_boost: float = 1.0,
	synergy_def_mult: float = 1.0
) -> int:
	# 基础伤害 (ATK 随机范围 0.6~0.9)
	var base_damage := enemy_atk * (0.6 + randf() * 0.3)
	
	# 属性克制
	var elem_mult := get_element_multiplier(enemy_element, target_element)
	base_damage *= elem_mult
	
	# 冰冻 ATK 降低 (冰冻时 freeze_mult=0.7)
	base_damage *= freeze_mult
	
	# 防御减免 (敌人视角用 def+80, 比玩家的 def+100 更有效)
	var def_reduction := target_def / (target_def + 80.0)
	base_damage *= (1.0 - def_reduction)
	
	# ±10% 随机波动
	base_damage *= (0.9 + randf() * 0.2)
	
	# 队长技能 DEF 加成 (DEF_BOOST: 受伤×0.85)
	base_damage *= leader_def_boost
	
	# 属性协同 DEF 加成
	# 2同属性 defMult=1.10 → 受伤×0.90 (减少10%)
	# 3同属性 defMult=1.20 → 受伤×0.80 (减少20%)
	var def_reduction_mult: float = 1.0
	if synergy_def_mult > 1.0:
		def_reduction_mult = 2.0 - synergy_def_mult
	else:
		def_reduction_mult = 1.0
	
	base_damage *= def_reduction_mult
	
	# 最终伤害 (最低1点)
	return int(maxi(1, base_damage))

# ============================================
# 护盾吸收计算
# ============================================
# 返回: { absorbed: int, remaining: int }
# absorbed = 实际被护盾吸收的伤害
# remaining = 穿透护盾后对目标HP的伤害
static func apply_shield(damage: int, shield_current_hp: int) -> Dictionary:
	var absorbed := mini(shield_current_hp, damage)
	var remaining := damage - absorbed
	return { "absorbed": absorbed, "remaining": remaining }

# ============================================
# 治疗量计算
# ============================================
static func calc_heal_amount(max_hp: int, heal_percent: float) -> int:
	return int(max_hp * heal_percent)
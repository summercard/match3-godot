## 技能类型总表。
##
## 这是技能配置的唯一类型字典：数据表只声明“可用类型、目标、参数和执行器”，
## 数值与组合仍由 monster_db / leader_skill_db 的具体技能条目维护。
class_name SkillTypeTable
extends RefCounted

const ACTIVE_EFFECTS: Dictionary = {
	"damage": {"name": "伤害", "target": "最弱敌人", "params": ["multiplier"], "handler": "_apply_damage"},
	"heal": {"name": "治疗", "target": "最低生命队友", "params": ["ratio", "min"], "handler": "_apply_heal"},
	"guard": {"name": "守护", "target": "最低生命队友/上一个治疗目标", "params": ["reduction", "turns"], "handler": "_apply_guard"},
	"weaken": {"name": "削弱", "target": "最弱敌人", "params": ["reduction", "turns"], "handler": "_apply_weaken"},
}

const LEADER_PASSIVE_EFFECTS: Dictionary = {
	"atk_boost": {"name": "属性攻击增益", "target": "全队对应属性", "params": ["element", "multiplier"]},
	"def_boost": {"name": "全队减伤", "target": "全队", "params": ["damageReduction"]},
	"hp_boost": {"name": "全队生命增益", "target": "全队", "params": ["hpMultiplier"]},
	"combo_start": {"name": "开场连击", "target": "战斗全局", "params": ["initialCombo"]},
}

const LEADER_BURST_EFFECTS: Dictionary = {
	"damage": {"name": "单体伤害", "target": "最弱敌人", "params": ["multiplier", "pierce"], "handler": "_damage_weakest"},
	"heal": {"name": "单体治疗", "target": "最低生命队友", "params": ["ratio", "minimum"], "handler": "_heal_lowest"},
	"heal_over_time": {"name": "持续治疗", "target": "自身/队友/全队", "params": ["target_mode", "ratio", "turns"], "handler": "_heal_over_time"},
	"heal_by_gem_count": {"name": "按宝石数治疗", "target": "最低生命队友", "params": ["source_element", "ratio", "target_count"], "handler": "_heal_by_gem_count"},
	"lifesteal": {"name": "吸血", "target": "最低生命队友", "params": ["ratio"], "handler": "_lifesteal_lowest"},
	"guard": {"name": "单体减伤", "target": "最低生命队友", "params": ["reduction", "turns"], "handler": "_guard_lowest"},
	"team_shield": {"name": "全队护盾", "target": "全队", "params": ["ratio", "turns"], "handler": "_team_shield"},
	"status": {"name": "状态异常", "target": "最弱/随机/全体敌人", "params": ["status", "turns", "ratio"], "handler": "_status_weakest"},
	"weaken": {"name": "敌方削弱", "target": "最弱敌人", "params": ["reduction", "turns"], "handler": "_weaken_weakest"},
	"convert_gems": {"name": "宝石转化", "target": "棋盘", "params": ["count", "target_element"], "handler": "_convert_gems"},
	"convert_element_gems_by_ratio": {"name": "按比例转化", "target": "棋盘同属性宝石", "params": ["source_element", "target_element", "ratio"], "handler": "_convert_element_gems_by_ratio"},
	"convert_adjacent_gems_from_random_source": {"name": "相邻宝石扩散", "target": "棋盘相邻格", "params": ["count", "source_element", "target_element"], "handler": "_convert_adjacent_gems"},
	"shuffle_board": {"name": "棋盘洗牌", "target": "棋盘", "params": [], "handler": "_shuffle_board"},
	"remove_random_element_gems": {"name": "元素宝石消除", "target": "棋盘同属性宝石", "params": ["target_element", "count", "clear_all"], "handler": "_remove_random_element_gems"},
	"clear_random_element_gems_damage_all": {"name": "消珠全体伤害", "target": "棋盘与全体敌人", "params": ["target_element", "count", "ratio"], "handler": "_clear_element_gems_damage_all"},
	"clear_element_gems_damage_highest_hp": {"name": "消珠斩杀", "target": "棋盘与最高生命敌人", "params": ["target_element", "ratio"], "handler": "_clear_element_gems_damage_highest"},
	"random_multi_hit": {"name": "随机连击", "target": "随机存活敌人", "params": ["count", "ratio"], "handler": "_random_multi_hit"},
	"damage_per_living_element_unit": {"name": "按属性单位连击", "target": "随机存活敌人", "params": ["source_element", "ratio"], "handler": "_damage_per_living_element_unit"},
	"self_atk_boost": {"name": "自身攻击增益", "target": "施放者", "params": ["multiplier"], "handler": "_self_atk_boost"},
	"self_damage_reduction": {"name": "自身永久减伤", "target": "施放者", "params": ["reduction"], "handler": "_self_damage_reduction"},
	"randomize_enemy_element": {"name": "敌人属性变换", "target": "随机/全体敌人", "params": ["target_count", "all_targets", "target_element"], "handler": "_randomize_enemy_element"},
	"grant_ally_charge": {"name": "队友蓄能", "target": "其他存活队友", "params": ["target_count", "charge_amount"], "handler": "_grant_ally_charge"},
	"reflect_damage": {"name": "伤害反射", "target": "自身/全队", "params": ["ratio", "turns", "all_targets"], "handler": "_reflect_damage"},
	"enemy_damage_vulnerability": {"name": "敌方易伤", "target": "全体敌人", "params": ["multiplier", "turns"], "handler": "_enemy_damage_vulnerability"},
	"confuse_enemy_attack": {"name": "敌人混乱", "target": "随机敌人", "params": ["ratio", "turns"], "handler": "_confuse_enemy_attack"},
}

# 执行器调用约定同样归表管理：true 表示 handler 需要施放者参数
# `(log, leader, effect)`，false 表示只读取效果与战斗状态 `(log, effect)`。
const LEADER_BURST_HANDLER_USES_LEADER: Dictionary = {
	"_damage_weakest": true,
	"_heal_lowest": true,
	"_heal_over_time": true,
	"_heal_by_gem_count": true,
	"_clear_element_gems_damage_all": true,
	"_clear_element_gems_damage_highest": true,
	"_random_multi_hit": true,
	"_damage_per_living_element_unit": true,
	"_self_atk_boost": true,
	"_self_damage_reduction": true,
	"_grant_ally_charge": true,
	"_reflect_damage": true,
	"_team_shield": true,
	"_status_weakest": true,
}


static func get_active_effect(kind: String) -> Dictionary:
	return ACTIVE_EFFECTS.get(kind, {}).duplicate(true)


static func get_leader_burst_effect(kind: String) -> Dictionary:
	return LEADER_BURST_EFFECTS.get(kind, {}).duplicate(true)


static func leader_burst_requires_leader(kind: String) -> bool:
	var handler := str(get_leader_burst_effect(kind).get("handler", ""))
	return bool(LEADER_BURST_HANDLER_USES_LEADER.get(handler, false))


static func get_management_rows(scope: String = "") -> Array:
	var rows: Array = []
	var tables := {
		"active": ACTIVE_EFFECTS,
		"leader_passive": LEADER_PASSIVE_EFFECTS,
		"leader_burst": LEADER_BURST_EFFECTS,
	}
	for table_scope in tables:
		if not scope.is_empty() and scope != table_scope:
			continue
		for kind in tables[table_scope]:
			var row: Dictionary = (tables[table_scope][kind] as Dictionary).duplicate(true)
			row["scope"] = table_scope
			row["kind"] = kind
			rows.append(row)
	return rows

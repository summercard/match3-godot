class_name LeaderSkillV132Db
extends RefCounted

## Cocos 1.3.2 已定稿的队长蓄能技覆写。未列出的技能继续沿用原 Godot 数据。
const OVERRIDES: Dictionary = {
	"LS_MONSTER_020": {"name": "迷途轮转", "desc": "随机使1名存活敌人的属性变为另一种属性，持续本局", "burstEffects": [{"kind": "randomize_enemy_element", "target_count": 1, "label": "迷途轮转"}]},
	"LS_MONSTER_021": {"name": "迷途轮转", "desc": "随机使2名存活敌人的属性各自变为另一种属性，持续本局", "burstEffects": [{"kind": "randomize_enemy_element", "target_count": 2, "label": "迷途轮转"}]},
	"LS_MONSTER_022": {"name": "迷途轮转", "desc": "使所有存活敌人的属性分别随机变为另一种属性，持续本局", "burstEffects": [{"kind": "randomize_enemy_element", "all_targets": true, "label": "迷途轮转"}]},
	"LS_MONSTER_023": {"name": "雨滴扩散", "desc": "随机选择2颗水宝石，将其相邻宝石转为水属性", "burstEffects": [{"kind": "convert_adjacent_gems_from_random_source", "count": 2, "source_element": "water", "target_element": "water", "label": "雨滴扩散"}]},
	"LS_MONSTER_024": {"name": "雨滴扩散", "desc": "随机选择3颗水宝石，将其相邻宝石转为水属性", "burstEffects": [{"kind": "convert_adjacent_gems_from_random_source", "count": 3, "source_element": "water", "target_element": "water", "label": "雨滴扩散"}]},
	"LS_MONSTER_025": {"name": "雨滴扩散", "desc": "随机选择5颗水宝石，将其相邻宝石转为水属性", "burstEffects": [{"kind": "convert_adjacent_gems_from_random_source", "count": 5, "source_element": "water", "target_element": "water", "label": "雨滴扩散"}]},
	"LS_MONSTER_029": {"name": "菌力蓄势", "desc": "本局自身攻击力提高30%", "burstEffects": [{"kind": "self_atk_boost", "multiplier": 1.3, "label": "菌力蓄势"}]},
	"LS_MONSTER_030": {"name": "菌力蓄势", "desc": "本局自身攻击力提高50%", "burstEffects": [{"kind": "self_atk_boost", "multiplier": 1.5, "label": "菌力蓄势"}]},
	"LS_MONSTER_031": {"name": "节拍洗牌", "desc": "将场上全部可操作宝石重新洗牌", "burstEffects": [{"kind": "shuffle_board", "label": "节拍洗牌"}]},
	"LS_MONSTER_032": {"name": "节拍洗牌", "desc": "将场上全部可操作宝石重新洗牌", "burstEffects": [{"kind": "shuffle_board", "label": "节拍洗牌"}]},
	"LS_MONSTER_033": {"name": "节拍洗牌", "desc": "将场上全部可操作宝石重新洗牌", "burstEffects": [{"kind": "shuffle_board", "label": "节拍洗牌"}]},
	"LS_MONSTER_034": {"name": "辉光调律", "desc": "在棋盘最外两圈随机转化4颗宝石为光属性", "burstEffects": [{"kind": "convert_gems", "count": 4, "edge_layers": 2, "target_element": "light", "label": "辉光调律"}]},
	"LS_MONSTER_035": {"name": "辉光调律", "desc": "在棋盘最外两圈随机转化8颗宝石为光属性", "burstEffects": [{"kind": "convert_gems", "count": 8, "edge_layers": 2, "target_element": "light", "label": "辉光调律"}]},
	"LS_MONSTER_036": {"name": "光耀裁决", "desc": "随机消除3颗光宝石，对全部敌人造成自身攻击力200%的光伤害", "burstEffects": [{"kind": "clear_random_element_gems_damage_all", "count": 3, "ratio": 2.0, "target_element": "light", "label": "光耀裁决"}]},
	"LS_MONSTER_037": {"name": "光耀裁决", "desc": "随机消除5颗光宝石，对全部敌人造成自身攻击力200%的光伤害", "burstEffects": [{"kind": "clear_random_element_gems_damage_all", "count": 5, "ratio": 2.0, "target_element": "light", "label": "光耀裁决"}]},
	"LS_MONSTER_038": {"name": "光耀裁决", "desc": "消除全部光宝石，对全部敌人造成自身攻击力200%的光伤害", "burstEffects": [{"kind": "clear_random_element_gems_damage_all", "clear_all": true, "ratio": 2.0, "target_element": "light", "label": "光耀裁决"}]},
	"LS_MONSTER_039": {"name": "暗影同化", "desc": "将全部存活敌人的属性变为暗属性", "burstEffects": [{"kind": "randomize_enemy_element", "all_targets": true, "target_element": "dark", "label": "暗影同化"}]},
	"LS_MONSTER_043": {"name": "荆棘反射", "desc": "自身获得30%反射伤害，持续2次敌方行动", "burstEffects": [{"kind": "reflect_damage", "ratio": 0.3, "turns": 2, "label": "荆棘反射"}]},
	"LS_MONSTER_044": {"name": "荆棘反射", "desc": "全队获得30%反射伤害，持续2次敌方行动", "burstEffects": [{"kind": "reflect_damage", "ratio": 0.3, "turns": 2, "all_targets": true, "label": "荆棘反射"}]},
	"LS_MONSTER_045": {"name": "醉心迷乱", "desc": "随机1名敌人有30%概率在下一次攻击时误伤友军", "burstEffects": [{"kind": "confuse_enemy_attack", "ratio": 0.3, "turns": 1, "label": "醉心迷乱"}]},
	"LS_MONSTER_046": {"name": "醉心迷乱", "desc": "随机1名敌人有50%概率在下一次攻击时误伤友军", "burstEffects": [{"kind": "confuse_enemy_attack", "ratio": 0.5, "turns": 1, "label": "醉心迷乱"}]},
	"LS_MONSTER_049": {"name": "林野拟态", "desc": "随机将场上其他3颗宝石转为草属性", "burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "grass", "label": "林野拟态"}]},
	"LS_MONSTER_050": {"name": "林野拟态", "desc": "随机将场上其他5颗宝石转为草属性", "burstEffects": [{"kind": "convert_gems", "count": 5, "target_element": "grass", "label": "林野拟态"}]},
	"LS_MONSTER_051": {"name": "沙暴裂隙", "desc": "随机消除1颗风系（雷）宝石，使所有敌人受到伤害×3，持续各自3次行动", "burstEffects": [{"kind": "remove_random_element_gems", "target_element": "wind", "count": 1, "label": "沙暴裂隙"}, {"kind": "enemy_damage_vulnerability", "multiplier": 3.0, "turns": 3, "label": "沙暴裂隙"}]},
	"LS_MONSTER_052": {"name": "沙暴裂隙", "desc": "消除全部风系（雷）宝石，使所有敌人受到伤害×3.5，持续各自3次行动", "burstEffects": [{"kind": "remove_random_element_gems", "target_element": "wind", "clear_all": true, "label": "沙暴裂隙"}, {"kind": "enemy_damage_vulnerability", "multiplier": 3.5, "turns": 3, "label": "沙暴裂隙"}]},
	"LS_MONSTER_056": {"name": "水潮共鸣", "desc": "场上每有1名水属性精灵，随机造成自身攻击力150%的伤害", "burstEffects": [{"kind": "damage_per_living_element_unit", "ratio": 1.5, "source_element": "water", "label": "水潮共鸣"}]},
	"LS_MONSTER_057": {"name": "水潮共鸣", "desc": "场上每有1名水属性精灵，随机造成自身攻击力180%的伤害", "burstEffects": [{"kind": "damage_per_living_element_unit", "ratio": 1.8, "source_element": "water", "label": "水潮共鸣"}]},
	"LS_MONSTER_062": {"name": "深海毒潮", "desc": "最低生命敌人中毒，首回合造成ATK 1%，之后每回合递增1%，直至死亡", "burstEffects": [{"kind": "status", "status": "poison", "ratio": 0.01, "increment_ratio": 0.01, "turns": -1, "label": "深海毒潮"}]},
	"LS_MONSTER_063": {"name": "深海毒潮", "desc": "最低生命敌人中毒，首回合造成ATK 1.5%，之后每回合递增1.5%，直至死亡", "burstEffects": [{"kind": "status", "status": "poison", "ratio": 0.015, "increment_ratio": 0.015, "turns": -1, "label": "深海毒潮"}]},
	"LS_MONSTER_070": {"name": "霜冻节奏", "desc": "冰冻全部敌人1次行动", "burstEffects": [{"kind": "status", "status": "freeze", "turns": 1, "all_targets": true, "label": "霜冻节奏"}]},
	"LS_MONSTER_071": {"name": "霜冻节奏", "desc": "冰冻全部敌人2次行动", "burstEffects": [{"kind": "status", "status": "freeze", "turns": 2, "all_targets": true, "label": "霜冻节奏"}]},
	"LS_MONSTER_072": {"name": "霜冻节奏", "desc": "冰冻全部敌人3次行动", "burstEffects": [{"kind": "status", "status": "freeze", "turns": 3, "all_targets": true, "label": "霜冻节奏"}]},
	"LS_MONSTER_073": {"name": "霜冻节奏", "desc": "随机冰冻1名敌人1次行动，并治疗最低生命队友30%HP", "burstEffects": [{"kind": "status", "status": "freeze", "turns": 1, "random_target": true, "label": "霜冻节奏"}, {"kind": "heal", "ratio": 0.3, "label": "霜冻节奏"}]},
	"LS_MONSTER_074": {"name": "霜冻节奏", "desc": "随机冰冻1名敌人1次行动，并治疗最低生命队友60%HP", "burstEffects": [{"kind": "status", "status": "freeze", "turns": 1, "random_target": true, "label": "霜冻节奏"}, {"kind": "heal", "ratio": 0.6, "label": "霜冻节奏"}]},
	"LS_MONSTER_075": {"name": "霜冻节奏", "desc": "随机冰冻1名敌人1次行动，并治疗最低生命队友80%HP", "burstEffects": [{"kind": "status", "status": "freeze", "turns": 1, "random_target": true, "label": "霜冻节奏"}, {"kind": "heal", "ratio": 0.8, "label": "霜冻节奏"}]},
	"LS_MONSTER_076": {"name": "净水映照", "desc": "随机将场上3颗非水宝石变为水属性", "burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "water", "label": "净水映照"}]},
	"LS_MONSTER_077": {"name": "净水映照", "desc": "随机将场上4颗非水宝石变为水属性", "burstEffects": [{"kind": "convert_gems", "count": 4, "target_element": "water", "label": "净水映照"}]},
	"LS_MONSTER_078": {"name": "净水映照", "desc": "随机将场上5颗非水宝石变为水属性", "burstEffects": [{"kind": "convert_gems", "count": 5, "target_element": "water", "label": "净水映照"}]},
	"LS_MONSTER_081": {"name": "星辉引导", "desc": "随机使另一名队友获得1个队长蓄能点", "burstEffects": [{"kind": "grant_ally_charge", "target_count": 1, "charge_amount": 1, "label": "星辉引导"}]},
	"LS_MONSTER_082": {"name": "星辉引导", "desc": "随机使两名其他队友各获得1个队长蓄能点", "burstEffects": [{"kind": "grant_ally_charge", "target_count": 2, "charge_amount": 1, "label": "星辉引导"}]},
	"LS_MONSTER_083": {"name": "星辉引导", "desc": "随机使两名其他队友各获得2个队长蓄能点", "burstEffects": [{"kind": "grant_ally_charge", "target_count": 2, "charge_amount": 2, "label": "星辉引导"}]},
	"LS_MONSTER_084": {"name": "安睡回春", "desc": "自身持续3次敌方行动，每次恢复20%最大生命", "passiveEffects": [], "burstEffects": [{"kind": "heal_over_time", "target_mode": "self", "ratio": 0.2, "turns": 3, "label": "安睡回春"}]},
	"LS_MONSTER_085": {"name": "安睡回春", "desc": "自身与随机1名队友持续3次敌方行动，每次恢复20%最大生命", "passiveEffects": [], "burstEffects": [{"kind": "heal_over_time", "target_mode": "self_and_random_ally", "ratio": 0.2, "turns": 3, "label": "安睡回春"}]},
	"LS_MONSTER_086": {"name": "安睡回春", "desc": "全体己方持续3次敌方行动，每次恢复20%最大生命", "passiveEffects": [], "burstEffects": [{"kind": "heal_over_time", "target_mode": "all_allies", "ratio": 0.2, "turns": 3, "label": "安睡回春"}]},
	"LS_MONSTER_087": {"name": "地脉反击", "desc": "自身免伤叠加10%（最高80%），并对最低生命敌人造成ATK 300%土伤害", "burstEffects": [{"kind": "self_damage_reduction", "reduction": 0.1, "label": "地脉护体"}, {"kind": "damage", "multiplier": 3.0, "label": "地脉反击"}]},
	"LS_MONSTER_088": {"name": "地脉反击", "desc": "自身免伤叠加15%（最高80%），并对最低生命敌人造成ATK 330%土伤害", "burstEffects": [{"kind": "self_damage_reduction", "reduction": 0.15, "label": "地脉护体"}, {"kind": "damage", "multiplier": 3.3, "label": "地脉反击"}]},
	"LS_MONSTER_089": {"name": "地脉反击", "desc": "自身免伤叠加20%（最高80%），并对最低生命敌人造成ATK 360%土伤害", "burstEffects": [{"kind": "self_damage_reduction", "reduction": 0.2, "label": "地脉护体"}, {"kind": "damage", "multiplier": 3.6, "label": "地脉反击"}]},
	"LS_MONSTER_090": {"name": "草露滋养", "desc": "治疗1名最低生命队友：自身最大HP 10%×草宝石数", "burstEffects": [{"kind": "heal_by_gem_count", "ratio": 0.1, "target_count": 1, "source_element": "grass", "label": "草露滋养"}]},
	"LS_MONSTER_091": {"name": "草露滋养", "desc": "治疗2名最低生命队友：自身最大HP 10%×草宝石数", "burstEffects": [{"kind": "heal_by_gem_count", "ratio": 0.1, "target_count": 2, "source_element": "grass", "label": "草露滋养"}]},
	"LS_MONSTER_092": {"name": "草露滋养", "desc": "治疗3名最低生命队友：自身最大HP 10%×草宝石数", "burstEffects": [{"kind": "heal_by_gem_count", "ratio": 0.1, "target_count": 3, "source_element": "grass", "label": "草露滋养"}]},
	"LS_MONSTER_097": {"name": "怒意蓄势", "desc": "本局内自身攻击力提高8%", "passiveEffects": [], "burstEffects": [{"kind": "self_atk_boost", "multiplier": 1.08, "label": "怒意蓄势"}]},
	"LS_MONSTER_098": {"name": "怒意蓄势", "desc": "本局内自身攻击力提高10%", "passiveEffects": [], "burstEffects": [{"kind": "self_atk_boost", "multiplier": 1.10, "label": "怒意蓄势"}]},
	"LS_MONSTER_099": {"name": "熔锅连击", "desc": "随机向存活敌人攻击8次，每次造成自身攻击力20%的火伤害", "passiveEffects": [], "burstEffects": [{"kind": "random_multi_hit", "count": 8, "ratio": 0.2, "label": "熔锅连击"}]},
	"LS_MONSTER_100": {"name": "熔锅连击", "desc": "随机向存活敌人攻击10次，每次造成自身攻击力20%的火伤害", "passiveEffects": [], "burstEffects": [{"kind": "random_multi_hit", "count": 10, "ratio": 0.2, "label": "熔锅连击"}]},
	"LS_MONSTER_101": {"name": "沸水蒸腾", "desc": "将场上75%的水宝石转为火属性", "burstEffects": [{"kind": "convert_element_gems_by_ratio", "ratio": 0.75, "source_element": "water", "target_element": "fire", "label": "沸水蒸腾"}]},
	"LS_MONSTER_102": {"name": "沸水蒸腾", "desc": "将场上一半水宝石转为火属性", "burstEffects": [{"kind": "convert_element_gems_by_ratio", "ratio": 0.5, "source_element": "water", "target_element": "fire", "label": "沸水蒸腾"}]},
	"LS_MONSTER_103": {"name": "沸水蒸腾", "desc": "将场上全部水宝石转为火属性", "burstEffects": [{"kind": "convert_element_gems_by_ratio", "ratio": 1.0, "source_element": "water", "target_element": "fire", "label": "沸水蒸腾"}]},
	"LS_BOSS_008": {"name": "熔火吞噬", "desc": "消除全部火宝石，对生命最高敌人造成ATK 20%×火宝石数的火伤害", "burstEffects": [{"kind": "clear_element_gems_damage_highest_hp", "ratio": 0.2, "target_element": "fire", "label": "熔火吞噬"}]},
}


static func apply(skill_id: String, base: Dictionary) -> Dictionary:
	if not OVERRIDES.has(skill_id):
		return base
	var merged := base.duplicate(true)
	merged.merge((OVERRIDES[skill_id] as Dictionary).duplicate(true), true)
	return merged

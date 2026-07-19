# ============================================
# data/leader_skill_db.gd - 队长技能配置数据
# 翻译自 data/leader-skills.js
# ============================================
class_name LeaderSkillDb
extends RefCounted

const LeaderSkillV132DbScript = preload("res://src/data/leader_skill_v132_db.gd")

# 队长技能数据库（17个技能）
# ★3(稀有)及以上的精灵才拥有队长技能
# 队长 = 队伍第1个槽位（index 0），被动效果持续整场战斗
const LEADER_SKILLS: Dictionary = {
	# ===== 属性攻击加成：同属性宝石伤害+30% =====
	"ATK_BOOST_FIRE": {
		"id": "ATK_BOOST_FIRE",
		"name": "烈焰之心",
		"desc": "火属性宝石伤害+30%",
		"icon": "🔥",
		"type": "atk_boost",
		"element": "fire",
		"multiplier": 1.3
	},
	"ATK_BOOST_WATER": {
		"id": "ATK_BOOST_WATER",
		"name": "潮汐之力",
		"desc": "水属性宝石伤害+30%",
		"icon": "💧",
		"type": "atk_boost",
		"element": "water",
		"multiplier": 1.3
	},
	"ATK_BOOST_GRASS": {
		"id": "ATK_BOOST_GRASS",
		"name": "自然之怒",
		"desc": "草属性宝石伤害+30%",
		"icon": "🌿",
		"type": "atk_boost",
		"element": "grass",
		"multiplier": 1.3
	},
	"ATK_BOOST_THUNDER": {
		"id": "ATK_BOOST_THUNDER",
		"name": "雷霆之怒",
		"desc": "雷属性宝石伤害+30%",
		"icon": "⚡",
		"type": "atk_boost",
		"element": "thunder",
		"multiplier": 1.3
	},
	"ATK_BOOST_LIGHT": {
		"id": "ATK_BOOST_LIGHT",
		"name": "圣光之耀",
		"desc": "光属性宝石伤害+30%",
		"icon": "✨",
		"type": "atk_boost",
		"element": "light",
		"multiplier": 1.3
	},
	"ATK_BOOST_EARTH": {
		"id": "ATK_BOOST_EARTH",
		"name": "大地之力",
		"desc": "土属性宝石伤害+30%",
		"icon": "⛰️",
		"type": "atk_boost",
		"element": "earth",
		"multiplier": 1.3
	},
	"ATK_BOOST_WIND": {
		"id": "ATK_BOOST_WIND",
		"name": "疾风之刃",
		"desc": "风属性宝石伤害+30%",
		"icon": "🌪️",
		"type": "atk_boost",
		"element": "wind",
		"multiplier": 1.3
	},
	"ATK_BOOST_DARK": {
		"id": "ATK_BOOST_DARK",
		"name": "暗影之力",
		"desc": "暗属性宝石伤害+30%",
		"icon": "🌑",
		"type": "atk_boost",
		"element": "dark",
		"multiplier": 1.3
	},
	"ATK_BOOST_ICE": {
		"id": "ATK_BOOST_ICE",
		"name": "极寒之心",
		"desc": "冰属性宝石伤害+30%",
		"icon": "❄️",
		"type": "atk_boost",
		"element": "ice",
		"multiplier": 1.3
	},
	"ATK_BOOST_VOID": {
		"id": "ATK_BOOST_VOID",
		"name": "虚空之眼",
		"desc": "虚空属性宝石伤害+30%",
		"icon": "🌀",
		"type": "atk_boost",
		"element": "void",
		"multiplier": 1.3
	},
	"ATK_BOOST_TEMPORAL": {
		"id": "ATK_BOOST_TEMPORAL",
		"name": "时间撕裂",
		"desc": "时空属性宝石伤害+30%",
		"icon": "⏳",
		"type": "atk_boost",
		"element": "temporal",
		"multiplier": 1.3
	},
	"ATK_BOOST_STAR": {
		"id": "ATK_BOOST_STAR",
		"name": "星耀之力",
		"desc": "星耀属性宝石伤害+30%",
		"icon": "💫",
		"type": "atk_boost",
		"element": "star",
		"multiplier": 1.3
	},
	"ATK_BOOST_CHAOS": {
		"id": "ATK_BOOST_CHAOS",
		"name": "混沌之怒",
		"desc": "混沌属性宝石伤害+30%",
		"icon": "🌑",
		"type": "atk_boost",
		"element": "chaos",
		"multiplier": 1.3
	},

	# ===== 全队防御加成：全队受到伤害-15% =====
	"DEF_BOOST": {
		"id": "DEF_BOOST",
		"name": "钢铁意志",
		"desc": "全队受到伤害-15%",
		"icon": "🛡️",
		"type": "def_boost",
		"damageReduction": 0.85  # 受伤 × 0.85
	},

	# ===== 全队HP加成：全队HP+20% =====
	"HP_BOOST": {
		"id": "HP_BOOST",
		"name": "生命之泉",
		"desc": "全队HP+20%",
		"icon": "💚",
		"type": "hp_boost",
		"hpMultiplier": 1.2
	},

	# ===== 初始Combo加成：战斗开始自带1层combo =====
	"COMBO_START": {
		"id": "COMBO_START",
		"name": "先手必胜",
		"desc": "战斗开始自带1层combo",
		"icon": "⚡",
		"type": "combo_start",
		"initialCombo": 1
	}
}


# 获取队长技能信息
const FORMAL_LEADER_SKILLS: Dictionary = {
	"LS_MONSTER_001": {
		"id": "LS_MONSTER_001",
		"name": "均衡号令",
		"desc": "全队HP+6%，草属性伤害+8%；队长爆发：对最弱敌人造成ATK 110%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "hp_boost", "hpMultiplier": 1.06},
			{"kind": "atk_boost", "element": "grass", "multiplier": 1.08}
		],
		"burstEffects": [{"kind": "damage", "multiplier": 1.10, "pierce": false, "label": "均衡号令"}]
	},
	"LS_MONSTER_002": {
		"id": "LS_MONSTER_002",
		"name": "生命回响",
		"desc": "队长爆发：治疗最低血量队友20%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [],
		"burstEffects": [{"kind": "heal", "ratio": 0.20, "label": "生命回响"}]
	},
	"LS_MONSTER_003": {
		"id": "LS_MONSTER_003",
		"name": "生命回响",
		"desc": "队长爆发：治疗最低血量队友30%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [],
		"burstEffects": [{"kind": "heal", "ratio": 0.30, "label": "生命回响"}]
	},
	"LS_MONSTER_004": {
		"id": "LS_MONSTER_004",
		"name": "生命回响",
		"desc": "队长爆发：治疗最低血量队友40%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [],
		"burstEffects": [{"kind": "heal", "ratio": 0.40, "label": "生命回响"}]
	},
	"LS_MONSTER_005": {
		"id": "LS_MONSTER_005",
		"name": "疾风先手",
		"desc": "开场Combo+1，风属性伤害+8%；队长爆发：削弱最弱敌人攻击18%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "wind", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 1},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.08}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.18, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_006": {
		"id": "LS_MONSTER_006",
		"name": "疾风先手",
		"desc": "开场Combo+1，风属性伤害+13%；队长爆发：削弱最弱敌人攻击26%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "wind", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 1},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.13}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.26, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_007": {
		"id": "LS_MONSTER_007",
		"name": "生命回响",
		"desc": "全队HP+8%；队长爆发：治疗最低血量队友16%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.08}],
		"burstEffects": [{"kind": "heal", "ratio": 0.16, "label": "生命回响"}]
	},
	"LS_MONSTER_008": {
		"id": "LS_MONSTER_008",
		"name": "疾风先手",
		"desc": "开场Combo+2，风属性伤害+20%；队长爆发：削弱最弱敌人攻击35%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "wind", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 2},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.20}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.35, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_009": {
		"id": "LS_MONSTER_009",
		"name": "生命回响",
		"desc": "全队HP+12%；队长爆发：治疗最低血量队友22%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.12}],
		"burstEffects": [{"kind": "heal", "ratio": 0.22, "label": "生命回响"}]
	},
	"LS_MONSTER_010": {
		"id": "LS_MONSTER_010",
		"name": "生命回响",
		"desc": "全队HP+18%；队长爆发：治疗最低血量队友30%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.18}],
		"burstEffects": [{"kind": "heal", "ratio": 0.30, "label": "生命回响"}]
	},
	"LS_MONSTER_011": {
		"id": "LS_MONSTER_011",
		"name": "潮汐守护",
		"desc": "全队HP+8%；队长爆发：最低血量队友获得25%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.08}],
		"burstEffects": [{"kind": "guard", "reduction": 0.25, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_012": {
		"id": "LS_MONSTER_012",
		"name": "潮汐守护",
		"desc": "全队HP+12%；队长爆发：最低血量队友获得35%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.12}],
		"burstEffects": [{"kind": "guard", "reduction": 0.35, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_013": {
		"id": "LS_MONSTER_013",
		"name": "潮汐守护",
		"desc": "全队HP+18%；队长爆发：最低血量队友获得45%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.18}],
		"burstEffects": [{"kind": "guard", "reduction": 0.45, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_014": {
		"id": "LS_MONSTER_014",
		"name": "岩壁阵线",
		"desc": "全队受伤-6%；队长爆发：最低血量队友获得25%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.94}],
		"burstEffects": [{"kind": "guard", "reduction": 0.25, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_015": {
		"id": "LS_MONSTER_015",
		"name": "岩壁阵线",
		"desc": "全队受伤-9%；队长爆发：最低血量队友获得35%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.91}],
		"burstEffects": [{"kind": "guard", "reduction": 0.35, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_016": {
		"id": "LS_MONSTER_016",
		"name": "岩壁阵线",
		"desc": "全队受伤-13%；队长爆发：最低血量队友获得45%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.87}],
		"burstEffects": [{"kind": "guard", "reduction": 0.45, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_017": {
		"id": "LS_MONSTER_017",
		"name": "暗影追击",
		"desc": "暗属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%暗伤，并回复最低血量队友造成伤害的33%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.20, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.33, "label": "暗影回流"}
		]
	},
	"LS_MONSTER_018": {
		"id": "LS_MONSTER_018",
		"name": "暗影追击",
		"desc": "暗属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%暗伤，并回复最低血量队友造成伤害的41%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.18}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.41, "label": "暗影回流"}
		]
	},
	"LS_MONSTER_019": {
		"id": "LS_MONSTER_019",
		"name": "暗影追击",
		"desc": "暗属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%暗伤，并回复最低血量队友造成伤害的49%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.25}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.49, "label": "暗影回流"}
		]
	},
	"LS_MONSTER_020": {
		"id": "LS_MONSTER_020",
		"name": "均衡号令",
		"desc": "全队HP+6%，草属性伤害+8%；队长爆发：对最弱敌人造成ATK 110%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "hp_boost", "hpMultiplier": 1.06},
			{"kind": "atk_boost", "element": "grass", "multiplier": 1.08}
		],
		"burstEffects": [{"kind": "damage", "multiplier": 1.10, "pierce": false, "label": "均衡号令"}]
	},
	"LS_MONSTER_021": {
		"id": "LS_MONSTER_021",
		"name": "均衡号令",
		"desc": "全队HP+9%，草属性伤害+12%；队长爆发：对最弱敌人造成ATK 125%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "hp_boost", "hpMultiplier": 1.09},
			{"kind": "atk_boost", "element": "grass", "multiplier": 1.12}
		],
		"burstEffects": [{"kind": "damage", "multiplier": 1.25, "pierce": false, "label": "均衡号令"}]
	},
	"LS_MONSTER_022": {
		"id": "LS_MONSTER_022",
		"name": "均衡号令",
		"desc": "全队HP+15%，草属性伤害+19%；队长爆发：对最弱敌人造成ATK 155%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "hp_boost", "hpMultiplier": 1.15},
			{"kind": "atk_boost", "element": "grass", "multiplier": 1.19}
		],
		"burstEffects": [{"kind": "damage", "multiplier": 1.55, "pierce": false, "label": "均衡号令"}]
	},
	"LS_MONSTER_023": {
		"id": "LS_MONSTER_023",
		"name": "潮汐守护",
		"desc": "全队HP+8%；队长爆发：最低血量队友获得25%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.08}],
		"burstEffects": [{"kind": "guard", "reduction": 0.25, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_024": {
		"id": "LS_MONSTER_024",
		"name": "潮汐守护",
		"desc": "全队HP+12%；队长爆发：最低血量队友获得35%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.12}],
		"burstEffects": [{"kind": "guard", "reduction": 0.35, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_025": {
		"id": "LS_MONSTER_025",
		"name": "潮汐守护",
		"desc": "全队HP+18%；队长爆发：最低血量队友获得45%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.18}],
		"burstEffects": [{"kind": "guard", "reduction": 0.45, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_026": {
		"id": "LS_MONSTER_026",
		"name": "雷鸣连锁",
		"desc": "雷属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%雷伤，并眩晕1回合",
		"icon": "leader_thunder",
		"visual": {"element": "thunder", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "thunder", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.20, "pierce": false, "label": "雷鸣连锁"},
			{"kind": "status", "status": "stun", "turns": 1, "label": "雷鸣连锁"}
		]
	},
	"LS_MONSTER_027": {
		"id": "LS_MONSTER_027",
		"name": "雷鸣连锁",
		"desc": "雷属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%雷伤，并眩晕1回合",
		"icon": "leader_thunder",
		"visual": {"element": "thunder", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "thunder", "multiplier": 1.18}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "雷鸣连锁"},
			{"kind": "status", "status": "stun", "turns": 1, "label": "雷鸣连锁"}
		]
	},
	"LS_MONSTER_028": {
		"id": "LS_MONSTER_028",
		"name": "雷鸣连锁",
		"desc": "雷属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%雷伤，并眩晕1回合",
		"icon": "leader_thunder",
		"visual": {"element": "thunder", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "thunder", "multiplier": 1.25}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "雷鸣连锁"},
			{"kind": "status", "status": "stun", "turns": 1, "label": "雷鸣连锁"}
		]
	},
	"LS_MONSTER_029": {
		"id": "LS_MONSTER_029",
		"name": "草能爆发",
		"desc": "草属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "grass", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.20, "pierce": false, "label": "草能爆发"}]
	},
	"LS_MONSTER_030": {
		"id": "LS_MONSTER_030",
		"name": "草能爆发",
		"desc": "草属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "grass", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "草能爆发"}]
	},
	"LS_MONSTER_031": {
		"id": "LS_MONSTER_031",
		"name": "疾风先手",
		"desc": "开场Combo+1，风属性伤害+8%；队长爆发：削弱最弱敌人攻击18%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "wind", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 1},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.08}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.18, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_032": {
		"id": "LS_MONSTER_032",
		"name": "疾风先手",
		"desc": "开场Combo+1，风属性伤害+13%；队长爆发：削弱最弱敌人攻击26%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "wind", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 1},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.13}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.26, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_033": {
		"id": "LS_MONSTER_033",
		"name": "疾风先手",
		"desc": "开场Combo+2，风属性伤害+20%；队长爆发：削弱最弱敌人攻击35%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "wind", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 2},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.20}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.35, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_034": {
		"id": "LS_MONSTER_034",
		"name": "辉光调律",
		"desc": "光属性伤害+12%；队长爆发：随机转化1颗宝石为光，并治疗最低血量队友16%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "convert_gems", "count": 1, "target_element": "light", "label": "辉光调律"},
			{"kind": "heal", "ratio": 0.16, "label": "辉光调律"}
		]
	},
	"LS_MONSTER_035": {
		"id": "LS_MONSTER_035",
		"name": "辉光调律",
		"desc": "光属性伤害+18%；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友22%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.18}],
		"burstEffects": [
			{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "辉光调律"},
			{"kind": "heal", "ratio": 0.22, "label": "辉光调律"}
		]
	},
	"LS_MONSTER_036": {
		"id": "LS_MONSTER_036",
		"name": "辉光调律",
		"desc": "光属性伤害+12%；队长爆发：随机转化1颗宝石为光，并治疗最低血量队友16%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "convert_gems", "count": 1, "target_element": "light", "label": "辉光调律"},
			{"kind": "heal", "ratio": 0.16, "label": "辉光调律"}
		]
	},
	"LS_MONSTER_037": {
		"id": "LS_MONSTER_037",
		"name": "辉光调律",
		"desc": "光属性伤害+18%；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友22%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.18}],
		"burstEffects": [
			{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "辉光调律"},
			{"kind": "heal", "ratio": 0.22, "label": "辉光调律"}
		]
	},
	"LS_MONSTER_038": {
		"id": "LS_MONSTER_038",
		"name": "辉光调律",
		"desc": "光属性伤害+25%；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友30%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.25}],
		"burstEffects": [
			{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "辉光调律"},
			{"kind": "heal", "ratio": 0.30, "label": "辉光调律"}
		]
	},
	"LS_MONSTER_039": {
		"id": "LS_MONSTER_039",
		"name": "暗影追击",
		"desc": "暗属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%暗伤，并回复最低血量队友造成伤害的33%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.20, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.33, "label": "暗影追击"}
		]
	},
	"LS_MONSTER_040": {
		"id": "LS_MONSTER_040",
		"name": "暗影追击",
		"desc": "暗属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%暗伤，并回复最低血量队友造成伤害的33%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.20, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.33, "label": "暗影追击"}
		]
	},
	"LS_MONSTER_041": {
		"id": "LS_MONSTER_041",
		"name": "暗影追击",
		"desc": "暗属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%暗伤，并回复最低血量队友造成伤害的41%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.18}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.41, "label": "暗影追击"}
		]
	},
	"LS_MONSTER_042": {
		"id": "LS_MONSTER_042",
		"name": "岩壁阵线",
		"desc": "全队受伤-6%；队长爆发：最低血量队友获得25%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.94}],
		"burstEffects": [{"kind": "guard", "reduction": 0.25, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_043": {
		"id": "LS_MONSTER_043",
		"name": "岩壁阵线",
		"desc": "全队受伤-9%；队长爆发：最低血量队友获得35%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.91}],
		"burstEffects": [{"kind": "guard", "reduction": 0.35, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_044": {
		"id": "LS_MONSTER_044",
		"name": "岩壁阵线",
		"desc": "全队受伤-13%；队长爆发：最低血量队友获得45%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.87}],
		"burstEffects": [{"kind": "guard", "reduction": 0.45, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_045": {
		"id": "LS_MONSTER_045",
		"name": "暗影追击",
		"desc": "暗属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%暗伤，并回复最低血量队友造成伤害的33%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.20, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.33, "label": "暗影追击"}
		]
	},
	"LS_MONSTER_046": {
		"id": "LS_MONSTER_046",
		"name": "暗影追击",
		"desc": "暗属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%暗伤，并回复最低血量队友造成伤害的41%",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.18}],
		"burstEffects": [
			{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "暗影追击"},
			{"kind": "lifesteal", "ratio": 0.41, "label": "暗影追击"}
		]
	},
	"LS_MONSTER_047": {
		"id": "LS_MONSTER_047",
		"name": "岩壁阵线",
		"desc": "全队受伤-6%；队长爆发：最低血量队友获得25%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.94}],
		"burstEffects": [{"kind": "guard", "reduction": 0.25, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_048": {
		"id": "LS_MONSTER_048",
		"name": "岩壁阵线",
		"desc": "全队受伤-9%；队长爆发：最低血量队友获得35%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.91}],
		"burstEffects": [{"kind": "guard", "reduction": 0.35, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_049": {
		"id": "LS_MONSTER_049",
		"name": "均衡号令",
		"desc": "全队HP+6%，草属性伤害+8%；队长爆发：对最弱敌人造成ATK 110%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "hp_boost", "hpMultiplier": 1.06},
			{"kind": "atk_boost", "element": "grass", "multiplier": 1.08}
		],
		"burstEffects": [{"kind": "damage", "multiplier": 1.10, "pierce": false, "label": "均衡号令"}]
	},
	"LS_MONSTER_050": {
		"id": "LS_MONSTER_050",
		"name": "均衡号令",
		"desc": "全队HP+9%，草属性伤害+12%；队长爆发：对最弱敌人造成ATK 125%草伤害",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "hp_boost", "hpMultiplier": 1.09},
			{"kind": "atk_boost", "element": "grass", "multiplier": 1.12}
		],
		"burstEffects": [{"kind": "damage", "multiplier": 1.25, "pierce": false, "label": "均衡号令"}]
	},
	"LS_MONSTER_051": {
		"id": "LS_MONSTER_051",
		"name": "疾风先手",
		"desc": "开场Combo+1，风属性伤害+8%；队长爆发：削弱最弱敌人攻击18%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "wind", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 1},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.08}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.18, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_052": {
		"id": "LS_MONSTER_052",
		"name": "疾风先手",
		"desc": "开场Combo+1，风属性伤害+13%；队长爆发：削弱最弱敌人攻击26%，持续2回合",
		"icon": "leader_wind",
		"visual": {"element": "dark", "tone": "speed", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "combo_start", "initialCombo": 1},
			{"kind": "atk_boost", "element": "wind", "multiplier": 1.13}
		],
		"burstEffects": [{"kind": "weaken", "reduction": 0.26, "turns": 2, "label": "疾风先手"}]
	},
	"LS_MONSTER_053": {
		"id": "LS_MONSTER_053",
		"name": "潮汐守护",
		"desc": "队长爆发：全队获得相当于队长自身HP 20%的护盾",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [],
		"burstEffects": [{"kind": "team_shield", "ratio": 0.20, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_054": {
		"id": "LS_MONSTER_054",
		"name": "均衡号令",
		"desc": "全队HP+6%，水属性伤害+8%；队长爆发：对最弱敌人造成ATK 110%水伤害",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "balanced", "asset_group": "leader_skills"},
		"passiveEffects": [
			{"kind": "hp_boost", "hpMultiplier": 1.06},
			{"kind": "atk_boost", "element": "water", "multiplier": 1.08}
		],
		"burstEffects": [{"kind": "damage", "multiplier": 1.10, "pierce": false, "label": "均衡号令"}]
	},
	"LS_MONSTER_055": {
		"id": "LS_MONSTER_055",
		"name": "潮汐守护",
		"desc": "队长爆发：全队获得相当于队长自身HP 30%的护盾",
		"icon": "leader_water",
		"visual": {"element": "thunder", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [],
		"burstEffects": [{"kind": "team_shield", "ratio": 0.30, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_056": {
		"id": "LS_MONSTER_056",
		"name": "生命回响",
		"desc": "全队HP+8%；队长爆发：治疗最低血量队友16%HP",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.08}],
		"burstEffects": [{"kind": "heal", "ratio": 0.16, "label": "生命回响"}]
	},
	"LS_MONSTER_057": {
		"id": "LS_MONSTER_057",
		"name": "生命回响",
		"desc": "全队HP+12%；队长爆发：治疗最低血量队友22%HP",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.12}],
		"burstEffects": [{"kind": "heal", "ratio": 0.22, "label": "生命回响"}]
	},
	"LS_MONSTER_058": {
		"id": "LS_MONSTER_058",
		"name": "辉光调律",
		"desc": "光属性伤害+12%；队长爆发：随机转化1颗宝石为光，并治疗最低血量队友16%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.12}],
		"burstEffects": [
			{"kind": "convert_gems", "count": 1, "target_element": "light", "label": "辉光调律"},
			{"kind": "heal", "ratio": 0.16, "label": "辉光调律"}
		]
	},
	"LS_MONSTER_059": {
		"id": "LS_MONSTER_059",
		"name": "辉光调律",
		"desc": "辉光调律：光属性伤害+18%；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友22%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.18}],
		"burstEffects": [{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "辉光调律"}, {"kind": "heal", "ratio": 0.22, "label": "辉光调律"}]
	},
	"LS_MONSTER_060": {
		"id": "LS_MONSTER_060",
		"name": "辉光调律",
		"desc": "辉光调律：光属性伤害+12%；队长爆发：随机转化1颗宝石为光，并治疗最低血量队友16%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.12}],
		"burstEffects": [{"kind": "convert_gems", "count": 1, "target_element": "light", "label": "辉光调律"}, {"kind": "heal", "ratio": 0.16, "label": "辉光调律"}]
	},
	"LS_MONSTER_061": {
		"id": "LS_MONSTER_061",
		"name": "辉光调律",
		"desc": "辉光调律：光属性伤害+18%；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友22%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.18}],
		"burstEffects": [{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "辉光调律"}, {"kind": "heal", "ratio": 0.22, "label": "辉光调律"}]
	},
	"LS_MONSTER_062": {
		"id": "LS_MONSTER_062",
		"name": "潮汐守护",
		"desc": "潮汐守护：全队HP+8%；队长爆发：最低血量队友获得25%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.08}],
		"burstEffects": [{"kind": "guard", "reduction": 0.25, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_063": {
		"id": "LS_MONSTER_063",
		"name": "潮汐守护",
		"desc": "潮汐守护：全队HP+12%；队长爆发：最低血量队友获得35%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "guard", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.12}],
		"burstEffects": [{"kind": "guard", "reduction": 0.35, "turns": 2, "label": "潮汐守护"}]
	},
	"LS_MONSTER_064": {
		"id": "LS_MONSTER_064",
		"name": "生命回响",
		"desc": "生命回响：全队HP+8%；队长爆发：治疗最低血量队友16%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.08}],
		"burstEffects": [{"kind": "heal", "ratio": 0.16, "label": "生命回响"}]
	},
	"LS_MONSTER_065": {
		"id": "LS_MONSTER_065",
		"name": "生命回响",
		"desc": "生命回响：全队HP+12%；队长爆发：治疗最低血量队友22%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.12}],
		"burstEffects": [{"kind": "heal", "ratio": 0.22, "label": "生命回响"}]
	},
	"LS_MONSTER_066": {
		"id": "LS_MONSTER_066",
		"name": "生命回响",
		"desc": "生命回响：全队HP+18%；队长爆发：治疗最低血量队友30%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.18}],
		"burstEffects": [{"kind": "heal", "ratio": 0.3, "label": "生命回响"}]
	},
	"LS_MONSTER_067": {
		"id": "LS_MONSTER_067",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_068": {
		"id": "LS_MONSTER_068",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_069": {
		"id": "LS_MONSTER_069",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.25}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_070": {
		"id": "LS_MONSTER_070",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_071": {
		"id": "LS_MONSTER_071",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_072": {
		"id": "LS_MONSTER_072",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.25}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_073": {
		"id": "LS_MONSTER_073",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_074": {
		"id": "LS_MONSTER_074",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_075": {
		"id": "LS_MONSTER_075",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.25}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_076": {
		"id": "LS_MONSTER_076",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_077": {
		"id": "LS_MONSTER_077",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_078": {
		"id": "LS_MONSTER_078",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：冰属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%冰伤，并冰冻1回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.25}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "霜冻节奏"}, {"kind": "status", "status": "freeze", "turns": 1, "label": "霜冻节奏"}]
	},
	"LS_MONSTER_079": {
		"id": "LS_MONSTER_079",
		"name": "辉光调律",
		"desc": "辉光调律：光属性伤害+12%；队长爆发：随机转化1颗宝石为光，并治疗最低血量队友16%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.12}],
		"burstEffects": [{"kind": "convert_gems", "count": 1, "target_element": "light", "label": "辉光调律"}, {"kind": "heal", "ratio": 0.16, "label": "辉光调律"}]
	},
	"LS_MONSTER_080": {
		"id": "LS_MONSTER_080",
		"name": "辉光调律",
		"desc": "辉光调律：光属性伤害+18%；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友22%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.18}],
		"burstEffects": [{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "辉光调律"}, {"kind": "heal", "ratio": 0.22, "label": "辉光调律"}]
	},
	"LS_MONSTER_081": {
		"id": "LS_MONSTER_081",
		"name": "星辉引导",
		"desc": "星辉引导：开场Combo+1；队长爆发：随机转化1颗宝石为光，并治疗最低血量队友16%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "combo_start", "initialCombo": 1}],
		"burstEffects": [{"kind": "convert_gems", "count": 1, "target_element": "light", "label": "星辉引导"}, {"kind": "heal", "ratio": 0.16, "label": "星辉引导"}]
	},
	"LS_MONSTER_082": {
		"id": "LS_MONSTER_082",
		"name": "星辉引导",
		"desc": "星辉引导：开场Combo+1；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友22%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "combo_start", "initialCombo": 1}],
		"burstEffects": [{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "星辉引导"}, {"kind": "heal", "ratio": 0.22, "label": "星辉引导"}]
	},
	"LS_MONSTER_083": {
		"id": "LS_MONSTER_083",
		"name": "星辉引导",
		"desc": "星辉引导：开场Combo+2；队长爆发：随机转化2颗宝石为光，并治疗最低血量队友30%HP",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "combo_start", "initialCombo": 2}],
		"burstEffects": [{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "星辉引导"}, {"kind": "heal", "ratio": 0.3, "label": "星辉引导"}]
	},
	"LS_MONSTER_084": {
		"id": "LS_MONSTER_084",
		"name": "虚空穿刺",
		"desc": "虚空穿刺：虚空/混沌属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%穿透伤害",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": true, "label": "虚空穿刺"}]
	},
	"LS_MONSTER_085": {
		"id": "LS_MONSTER_085",
		"name": "虚空穿刺",
		"desc": "虚空穿刺：虚空/混沌属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%穿透伤害",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": true, "label": "虚空穿刺"}]
	},
	"LS_MONSTER_086": {
		"id": "LS_MONSTER_086",
		"name": "虚空穿刺",
		"desc": "虚空穿刺：虚空/混沌属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%穿透伤害",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.25}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.75, "pierce": true, "label": "虚空穿刺"}]
	},
	"LS_MONSTER_087": {
		"id": "LS_MONSTER_087",
		"name": "岩壁阵线",
		"desc": "岩壁阵线：全队受伤-6%；队长爆发：最低血量队友获得25%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.94}],
		"burstEffects": [{"kind": "guard", "reduction": 0.25, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_088": {
		"id": "LS_MONSTER_088",
		"name": "岩壁阵线",
		"desc": "岩壁阵线：全队受伤-9%；队长爆发：最低血量队友获得35%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.91}],
		"burstEffects": [{"kind": "guard", "reduction": 0.35, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_089": {
		"id": "LS_MONSTER_089",
		"name": "岩壁阵线",
		"desc": "岩壁阵线：全队受伤-13%；队长爆发：最低血量队友获得45%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.87}],
		"burstEffects": [{"kind": "guard", "reduction": 0.45, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_MONSTER_090": {
		"id": "LS_MONSTER_090",
		"name": "生命回响",
		"desc": "生命回响：全队HP+8%；队长爆发：治疗最低血量队友16%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.08}],
		"burstEffects": [{"kind": "heal", "ratio": 0.16, "label": "生命回响"}]
	},
	"LS_MONSTER_091": {
		"id": "LS_MONSTER_091",
		"name": "生命回响",
		"desc": "生命回响：全队HP+12%；队长爆发：治疗最低血量队友22%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.12}],
		"burstEffects": [{"kind": "heal", "ratio": 0.22, "label": "生命回响"}]
	},
	"LS_MONSTER_092": {
		"id": "LS_MONSTER_092",
		"name": "生命回响",
		"desc": "生命回响：全队HP+18%；队长爆发：治疗最低血量队友30%HP",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.18}],
		"burstEffects": [{"kind": "heal", "ratio": 0.3, "label": "生命回响"}]
	},
	"LS_MONSTER_093": {
		"id": "LS_MONSTER_093",
		"name": "烈焰扑击",
		"desc": "队长爆发：对最弱敌人造成ATK 300%火焰伤害",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [],
		"burstEffects": [{"kind": "damage", "multiplier": 3.00, "pierce": false, "label": "烈焰扑击"}]
	},
	"LS_MONSTER_094": {
		"id": "LS_MONSTER_094",
		"name": "烈焰扑击",
		"desc": "队长爆发：对最弱敌人造成ATK 300%火焰伤害",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [],
		"burstEffects": [{"kind": "damage", "multiplier": 3.00, "pierce": false, "label": "烈焰扑击"}]
	},
	"LS_MONSTER_095": {
		"id": "LS_MONSTER_095",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_096": {
		"id": "LS_MONSTER_096",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_097": {
		"id": "LS_MONSTER_097",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_098": {
		"id": "LS_MONSTER_098",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_099": {
		"id": "LS_MONSTER_099",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_100": {
		"id": "LS_MONSTER_100",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_101": {
		"id": "LS_MONSTER_101",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+18%；队长爆发：对最弱敌人造成ATK 145%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.18}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.45, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_102": {
		"id": "LS_MONSTER_102",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+12%；队长爆发：对最弱敌人造成ATK 120%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.12}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.2, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_MONSTER_103": {
		"id": "LS_MONSTER_103",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+25%；队长爆发：对最弱敌人造成ATK 175%火伤，并附加灼烧",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.25}],
		"burstEffects": [{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "烈焰攻势"}, {"kind": "status", "status": "burn", "turns": 3, "label": "烈焰攻势"}]
	},
	"LS_BOSS_001": {
		"id": "LS_BOSS_001",
		"name": "生命回响",
		"desc": "生命回响：全队HP+25%；队长爆发：随机转化3颗宝石为草",
		"icon": "leader_grass",
		"visual": {"element": "grass", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "hp_boost", "hpMultiplier": 1.25}],
		"burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "grass", "label": "生命回响"}]
	},
	"LS_BOSS_002": {
		"id": "LS_BOSS_002",
		"name": "岩壁阵线",
		"desc": "岩壁阵线：全队受伤-18%；队长爆发：最低血量队友获得55%减伤，持续2回合",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.82}],
		"burstEffects": [{"kind": "guard", "reduction": 0.55, "turns": 2, "label": "岩壁阵线"}]
	},
	"LS_BOSS_003": {
		"id": "LS_BOSS_003",
		"name": "辉光调律",
		"desc": "辉光调律：光属性伤害+35%；队长爆发：随机转化3颗宝石为光",
		"icon": "leader_light",
		"visual": {"element": "light", "tone": "heal", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "light", "multiplier": 1.35}],
		"burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "light", "label": "辉光调律"}]
	},
	"LS_BOSS_004": {
		"id": "LS_BOSS_004",
		"name": "岩壁阵线",
		"desc": "岩壁阵线：全队受伤-18%；队长爆发：随机转化3颗宝石为土",
		"icon": "leader_earth",
		"visual": {"element": "earth", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.82}],
		"burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "earth", "label": "岩壁阵线"}]
	},
	"LS_BOSS_005": {
		"id": "LS_BOSS_005",
		"name": "坚守阵线",
		"desc": "坚守阵线：全队受伤-18%；队长爆发：最低血量队友获得55%减伤，持续2回合",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "bulwark", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "def_boost", "damageReduction": 0.82}],
		"burstEffects": [{"kind": "guard", "reduction": 0.55, "turns": 2, "label": "坚守阵线"}]
	},
	"LS_BOSS_006": {
		"id": "LS_BOSS_006",
		"name": "霜冻节奏",
		"desc": "霜冻节奏：水属性伤害+35%；队长爆发：随机转化3颗宝石为水",
		"icon": "leader_water",
		"visual": {"element": "water", "tone": "chain", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "water", "multiplier": 1.35}],
		"burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "water", "label": "霜冻节奏"}]
	},
	"LS_BOSS_007": {
		"id": "LS_BOSS_007",
		"name": "虚空穿刺",
		"desc": "虚空穿刺：暗属性伤害+35%；队长爆发：随机转化3颗宝石为暗",
		"icon": "leader_dark",
		"visual": {"element": "dark", "tone": "siphon", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "dark", "multiplier": 1.35}],
		"burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "dark", "label": "虚空穿刺"}]
	},
	"LS_BOSS_008": {
		"id": "LS_BOSS_008",
		"name": "烈焰攻势",
		"desc": "烈焰攻势：火属性伤害+35%；队长爆发：随机转化3颗宝石为火",
		"icon": "leader_fire",
		"visual": {"element": "fire", "tone": "fire", "asset_group": "leader_skills"},
		"passiveEffects": [{"kind": "atk_boost", "element": "fire", "multiplier": 1.35}],
		"burstEffects": [{"kind": "convert_gems", "count": 3, "target_element": "fire", "label": "烈焰攻势"}]
	}
}

const VALID_ELEMENTS: Array[String] = ["fire", "water", "grass", "earth", "wind", "thunder", "light", "dark"]

const DEFAULT_BURST_EFFECTS: Dictionary = {
	"grass": [
		{"kind": "heal", "ratio": 0.42, "minimumAtkMultiplier": 1.4, "label": "Verdant Mend"}
	],
	"water": [
		{"kind": "guard", "reduction": 0.50, "turns": 2, "label": "Tide Shell"}
	],
	"earth": [
		{"kind": "guard", "reduction": 0.62, "turns": 2, "label": "Stone Bulwark"}
	],
	"light": [
		{"kind": "convert_gems", "count": 2, "target_element": "light", "label": "Star Calling"}
	],
	"dark": [
		{"kind": "damage", "multiplier": 1.65, "pierce": false, "label": "Night Siphon"},
		{"kind": "lifesteal", "ratio": 0.55, "label": "Siphon Heal"}
	],
	"thunder": [
		{"kind": "damage", "multiplier": 1.75, "pierce": false, "label": "Thunder Pin"},
		{"kind": "status", "status": "stun", "label": "Thunder Pin"}
	],
	"wind": [
		{"kind": "weaken", "reduction": 0.40, "turns": 2, "label": "Gale Break"}
	],
	"fire": [
		{"kind": "damage", "multiplier": 1.55, "pierce": false, "label": "Leader Strike"}
	]
}


static func get_leader_skill(skill_id: String) -> Dictionary:
	var normalized_id := normalize_skill_id(skill_id)
	if FORMAL_LEADER_SKILLS.has(normalized_id):
		return LeaderSkillV132DbScript.apply(normalized_id, FORMAL_LEADER_SKILLS[normalized_id].duplicate(true))
	if LEADER_SKILLS.has(normalized_id):
		var skill: Dictionary = LEADER_SKILLS[normalized_id].duplicate(true)
		if str(skill.get("type", "")) == "atk_boost":
			skill["element"] = normalize_element(str(skill.get("element", "")))
		return skill
	return {}


static func normalize_skill_id(skill_id: String) -> String:
	match skill_id:
		"ATK_BOOST_ICE":
			return "ATK_BOOST_WATER"
		"ATK_BOOST_STAR":
			return "ATK_BOOST_LIGHT"
		"ATK_BOOST_VOID", "ATK_BOOST_CHAOS", "ATK_BOOST_TEMPORAL":
			return "ATK_BOOST_DARK"
		_:
			return skill_id


static func get_burst_effects(leader_skill: Dictionary, element: String) -> Array:
	var custom_effects = leader_skill.get("burstEffects", [])
	if custom_effects is Array and not custom_effects.is_empty():
		return custom_effects.duplicate(true)
	return DEFAULT_BURST_EFFECTS.get(normalize_element(element), DEFAULT_BURST_EFFECTS["fire"]).duplicate(true)


static func normalize_element(element: String) -> String:
	match element:
		"ice":
			return "water"
		"star":
			return "light"
		"void", "chaos", "temporal":
			return "dark"
		_:
			return element if VALID_ELEMENTS.has(element) else "fire"


# 计算队长技能对属性伤害的加成倍率
# @param leader_skill 队长技能数据
# @param element 攻击属性
# @return 倍率 (1.0 = 无加成)
static func get_leader_atk_boost(leader_skill: Dictionary, element: String) -> float:
	if leader_skill.is_empty():
		return 1.0
	var passive_mult := 1.0
	for effect in _passive_effects(leader_skill):
		if not (effect is Dictionary):
			continue
		if str(effect.get("kind", "")) == "atk_boost" and normalize_element(str(effect.get("element", ""))) == normalize_element(element):
			passive_mult *= float(effect.get("multiplier", 1.0))
	if passive_mult != 1.0:
		return passive_mult
	if leader_skill.get("type") == "atk_boost" and normalize_element(str(leader_skill.get("element", ""))) == normalize_element(element):
		return leader_skill.get("multiplier", 1.0)
	return 1.0


# 计算队长技能对受伤的减免
# @param leader_skill 队长技能数据
# @return 倍率 (1.0 = 无减免, 0.85 = -15%)
static func get_leader_def_boost(leader_skill: Dictionary) -> float:
	if leader_skill.is_empty():
		return 1.0
	var passive_mult := 1.0
	for effect in _passive_effects(leader_skill):
		if not (effect is Dictionary):
			continue
		if str(effect.get("kind", "")) == "def_boost":
			passive_mult *= float(effect.get("damageReduction", 1.0))
	if passive_mult != 1.0:
		return passive_mult
	if leader_skill.get("type") == "def_boost":
		return leader_skill.get("damageReduction", 1.0)
	return 1.0


# 计算队长技能对HP的加成
# @param leader_skill 队长技能数据
# @return 倍率 (1.0 = 无加成, 1.2 = +20%)
static func get_leader_hp_boost(leader_skill: Dictionary) -> float:
	if leader_skill.is_empty():
		return 1.0
	var passive_mult := 1.0
	for effect in _passive_effects(leader_skill):
		if not (effect is Dictionary):
			continue
		if str(effect.get("kind", "")) == "hp_boost":
			passive_mult *= float(effect.get("hpMultiplier", 1.0))
	if passive_mult != 1.0:
		return passive_mult
	if leader_skill.get("type") == "hp_boost":
		return leader_skill.get("hpMultiplier", 1.0)
	return 1.0


# 获取队长技能的初始combo加成
# @param leader_skill 队长技能数据
# @return 额外combo数
static func get_leader_combo_start(leader_skill: Dictionary) -> int:
	if leader_skill.is_empty():
		return 0
	var total := 0
	for effect in _passive_effects(leader_skill):
		if not (effect is Dictionary):
			continue
		if str(effect.get("kind", "")) == "combo_start":
			total += int(effect.get("initialCombo", 0))
	if total > 0:
		return total
	if leader_skill.get("type") == "combo_start":
		return leader_skill.get("initialCombo", 0)
	return 0


static func _passive_effects(leader_skill: Dictionary) -> Array:
	var effects = leader_skill.get("passiveEffects", [])
	return effects if effects is Array else []

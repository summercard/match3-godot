class_name MonsterDb
extends RefCounted
## 精灵数据库 - 从 js/battle/monsterData.js 翻译
##
## ⚠️ 数据修改指引 / DATA EDITOR GUIDE
## 本文件是代码形式的数据库，与 docs/怪物数据总表.csv 保持同步。
## 如需新增/修改精灵数据，请：
##   1. 在 docs/怪物数据总表.csv 中编辑（推荐，结构化）
##   2. 将 CSV 导出为 JSON 后手动转为 GDScript 常量
##   3. 或直接在本文件中编辑（需同步更新 CSV）
##
## ⚠️ DATA MODIFICATION GUIDE
## To add/modify monster data:
##   1. Edit docs/怪物数据总表.csv (preferred — structured format)
##   2. Export CSV to JSON, then convert to GDScript constants
##   3. Or edit this file directly (must sync with CSV)

# ========== 精灵数据库 ==========
const MONSTER_DB: Dictionary = {
	"monster_001": {
		"id": "monster_001", "name": "小火龙", "element": "fire",
		"rarity": 2, "emoji": "🦎",
		"baseHP": 180, "baseATK": 45, "baseDEF": 30, "baseSPD": 15,
		"skill": {
			"name": "火焰冲击", "cost": 8, "type": "strike", "multiplier": 2.5,
			"effects": [
				{ "kind": "damage", "target": "weakest_enemy", "multiplier": 2.5 }
			]
		},
		"evolution": { "level": 16, "target": "monster_006" }
	},
	"monster_002": {
		"id": "monster_002", "name": "水龟仔", "element": "water",
		"rarity": 2, "emoji": "🐢",
		"baseHP": 200, "baseATK": 35, "baseDEF": 40, "baseSPD": 12,
		"skill": {
			"name": "水之护盾", "cost": 7, "type": "ward", "multiplier": 1.0,
			"effects": [
				{ "kind": "heal", "target": "lowest_ally", "ratio": 0.28, "min": 24 },
				{ "kind": "guard", "target": "lowest_ally", "reduction": 0.25, "turns": 1 }
			]
		},
		"evolution": { "level": 16, "target": "monster_007" }
	},
	"monster_003": {
		"id": "monster_003", "name": "草苗儿", "element": "grass",
		"rarity": 2, "emoji": "🌱",
		"baseHP": 170, "baseATK": 38, "baseDEF": 35, "baseSPD": 18,
		"skill": {
			"name": "藤蔓束缚", "cost": 6, "type": "tempo", "multiplier": 1.35,
			"effects": [
				{ "kind": "damage", "target": "weakest_enemy", "multiplier": 1.35 },
				{ "kind": "weaken", "target": "damaged_enemy", "reduction": 0.35, "turns": 1 }
			]
		},
		"evolution": { "level": 16, "target": "monster_008" }
	},
	"monster_004": {
		"id": "monster_004", "name": "雷小鼠", "element": "thunder",
		"rarity": 2, "emoji": "🐭",
		"baseHP": 100, "baseATK": 40, "baseDEF": 15, "baseSPD": 25,
		"skill": { "name": "雷电箭", "cost": 9, "multiplier": 3.0 },
		"evolution": { "level": 18, "target": "monster_009" }
	},
	"monster_005": {
		"id": "monster_005", "name": "光精灵", "element": "light",
		"rarity": 2, "emoji": "🧚",
		"baseHP": 90, "baseATK": 38, "baseDEF": 18, "baseSPD": 22,
		"skill": { "name": "星光爆裂", "cost": 10, "multiplier": 3.5 },
		"evolution": { "level": 20, "target": "monster_010" }
	},
	"monster_006": {
		"id": "monster_006", "name": "火恐龙", "element": "fire",
		"rarity": 3, "emoji": "🔥",
		"baseHP": 160, "baseATK": 55, "baseDEF": 30, "baseSPD": 22,
		"skill": {
			"name": "烈焰冲击", "cost": 10, "type": "strike", "multiplier": 3.0,
			"effects": [
				{ "kind": "damage", "target": "weakest_enemy", "multiplier": 3.0 }
			]
		},
		"leaderSkill": "ATK_BOOST_FIRE"
	},
	"monster_007": {
		"id": "monster_007", "name": "水箭龟", "element": "water",
		"rarity": 3, "emoji": "🐢",
		"baseHP": 180, "baseATK": 42, "baseDEF": 45, "baseSPD": 18,
		"skill": {
			"name": "水流护盾", "cost": 9, "type": "ward", "multiplier": 1.0,
			"effects": [
				{ "kind": "heal", "target": "lowest_ally", "ratio": 0.34, "min": 36 },
				{ "kind": "guard", "target": "lowest_ally", "reduction": 0.35, "turns": 1 }
			]
		},
		"leaderSkill": "ATK_BOOST_WATER"
	},
	"monster_008": {
		"id": "monster_008", "name": "妙蛙草", "element": "grass",
		"rarity": 3, "emoji": "🌿",
		"baseHP": 150, "baseATK": 48, "baseDEF": 38, "baseSPD": 25,
		"skill": {
			"name": "藤蔓束缚", "cost": 8, "type": "tempo", "multiplier": 1.65,
			"effects": [
				{ "kind": "damage", "target": "weakest_enemy", "multiplier": 1.65 },
				{ "kind": "weaken", "target": "damaged_enemy", "reduction": 0.45, "turns": 1 }
			]
		},
		"leaderSkill": "ATK_BOOST_GRASS"
	},
	"monster_009": {
		"id": "monster_009", "name": "雷丘", "element": "thunder",
		"rarity": 3, "emoji": "⚡",
		"baseHP": 135, "baseATK": 60, "baseDEF": 22, "baseSPD": 35,
		"skill": { "name": "雷霆万钧", "cost": 12, "multiplier": 3.8 },
		"leaderSkill": "COMBO_START"
	},
	"monster_010": {
		"id": "monster_010", "name": "光耀兽", "element": "light",
		"rarity": 3, "emoji": "✨",
		"baseHP": 125, "baseATK": 58, "baseDEF": 28, "baseSPD": 32,
		"skill": { "name": "圣光爆破", "cost": 13, "multiplier": 4.2 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_boss_001": {
		"id": "monster_boss_001", "name": "花叶兽", "element": "grass",
		"rarity": 3, "emoji": "🌺",
		"baseHP": 350, "baseATK": 45, "baseDEF": 35, "baseSPD": 10,
		"skill": { "name": "花瓣风暴", "cost": 10, "multiplier": 3.0 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 3, "damageMultiplier": 2.5 }
		],
		"leaderSkill": "ATK_BOOST_GRASS"
	},
	"monster_boss_002": {
		"id": "monster_boss_002", "name": "烈焰龙", "element": "fire",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 400, "baseATK": 55, "baseDEF": 30, "baseSPD": 12,
		"skill": { "name": "龙息烈焰", "cost": 12, "multiplier": 3.5 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 3, "damageMultiplier": 2.5 },
			{ "type": "shield", "hp": 50, "cooldown": 5 }
		],
		"leaderSkill": "ATK_BOOST_FIRE"
	},
	"enemy_001": {
		"id": "enemy_001", "name": "野火虫", "element": "fire",
		"rarity": 1, "emoji": "🐛",
		"baseHP": 34, "baseATK": 10, "baseDEF": 7, "baseSPD": 10,
		"skill": { "name": "火星", "cost": 5, "multiplier": 1.5 }
	},
	"enemy_002": {
		"id": "enemy_002", "name": "水泡泡", "element": "water",
		"rarity": 1, "emoji": "🫧",
		"baseHP": 38, "baseATK": 10, "baseDEF": 7, "baseSPD": 8,
		"skill": { "name": "水泡", "cost": 5, "multiplier": 1.5 }
	},
	"enemy_003": {
		"id": "enemy_003", "name": "草精灵", "element": "grass",
		"rarity": 1, "emoji": "🍃", "isElite": true,
		"baseHP": 32, "baseATK": 10, "baseDEF": 7, "baseSPD": 12,
		"skill": { "name": "叶刃", "cost": 5, "multiplier": 1.5 }
	},
	"monster_011": {
		"id": "monster_011", "name": "冰鳞兽", "element": "water",
		"rarity": 2, "emoji": "🐧",
		"baseHP": 145, "baseATK": 30, "baseDEF": 35, "baseSPD": 10,
		"skill": { "name": "寒冰冲击", "cost": 8, "multiplier": 2.3 },
		"evolution": { "level": 18, "target": "monster_012" }
	},
	"monster_012": {
		"id": "monster_012", "name": "冰甲龙", "element": "water",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 200, "baseATK": 45, "baseDEF": 55, "baseSPD": 14,
		"skill": { "name": "极寒吐息", "cost": 10, "multiplier": 2.8 },
		"leaderSkill": "DEF_BOOST"
	},
	"monster_013": {
		"id": "monster_013", "name": "岩甲龙", "element": "earth",
		"rarity": 3, "emoji": "🦕",
		"baseHP": 170, "baseATK": 42, "baseDEF": 50, "baseSPD": 8,
		"skill": { "name": "岩石崩落", "cost": 9, "multiplier": 2.5 },
		"leaderSkill": "ATK_BOOST_EARTH"
	},
	"monster_014": {
		"id": "monster_014", "name": "山岭龙", "element": "earth",
		"rarity": 4, "emoji": "⛰️",
		"baseHP": 230, "baseATK": 58, "baseDEF": 70, "baseSPD": 10,
		"skill": { "name": "大地之力", "cost": 11, "multiplier": 3.0 },
		"leaderSkill": "DEF_BOOST"
	},
	"monster_015": {
		"id": "monster_015", "name": "风羽鹰", "element": "wind",
		"rarity": 2, "emoji": "🦅",
		"baseHP": 95, "baseATK": 36, "baseDEF": 18, "baseSPD": 28,
		"skill": { "name": "风刃切割", "cost": 7, "multiplier": 2.4 },
		"evolution": { "level": 18, "target": "monster_016" }
	},
	"monster_016": {
		"id": "monster_016", "name": "苍穹鹰", "element": "wind",
		"rarity": 3, "emoji": "🌪️",
		"baseHP": 130, "baseATK": 52, "baseDEF": 25, "baseSPD": 38,
		"skill": { "name": "风暴降临", "cost": 10, "multiplier": 3.2 },
		"leaderSkill": "ATK_BOOST_WIND"
	},
	"monster_017": {
		"id": "monster_017", "name": "暗影猫", "element": "dark",
		"rarity": 3, "emoji": "🐱",
		"baseHP": 85, "baseATK": 50, "baseDEF": 12, "baseSPD": 30,
		"skill": { "name": "暗影利爪", "cost": 9, "multiplier": 3.0 },
		"leaderSkill": "ATK_BOOST_DARK"
	},
	"monster_018": {
		"id": "monster_018", "name": "幽冥虎", "element": "dark",
		"rarity": 4, "emoji": "🐯",
		"baseHP": 120, "baseATK": 70, "baseDEF": 18, "baseSPD": 40,
		"skill": { "name": "暗夜终结", "cost": 13, "multiplier": 4.0 },
		"leaderSkill": "COMBO_START"
	},
	"monster_019": {
		"id": "monster_019", "name": "圣光雀", "element": "light",
		"rarity": 3, "emoji": "🐦",
		"baseHP": 115, "baseATK": 52, "baseDEF": 22, "baseSPD": 20,
		"skill": { "name": "圣光射线", "cost": 10, "multiplier": 3.2 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_020": {
		"id": "monster_020", "name": "天使兽", "element": "light",
		"rarity": 4, "emoji": "👼",
		"baseHP": 155, "baseATK": 68, "baseDEF": 32, "baseSPD": 28,
		"skill": { "name": "天堂之光", "cost": 14, "multiplier": 4.5 },
		"leaderSkill": "HP_BOOST"
	},
	"enemy_004": {
		"id": "enemy_004", "name": "深海鱼", "element": "water",
		"rarity": 1, "emoji": "🐟",
		"baseHP": 39, "baseATK": 10, "baseDEF": 10, "baseSPD": 14,
		"skill": { "name": "水弹", "cost": 5, "multiplier": 1.6 }
	},
	"enemy_005": {
		"id": "enemy_005", "name": "岩蜥", "element": "earth",
		"rarity": 1, "emoji": "🦎",
		"baseHP": 35, "baseATK": 10, "baseDEF": 10, "baseSPD": 8,
		"skill": { "name": "石击", "cost": 5, "multiplier": 1.5 }
	},
	"enemy_006": {
		"id": "enemy_006", "name": "风蛾", "element": "wind",
		"rarity": 1, "emoji": "🦋",
		"baseHP": 37, "baseATK": 10, "baseDEF": 10, "baseSPD": 18,
		"skill": { "name": "风切", "cost": 5, "multiplier": 1.7 }
	},
	"enemy_007": {
		"id": "enemy_007", "name": "暗蛛", "element": "dark",
		"rarity": 1, "emoji": "🕷️", "isElite": true,
		"baseHP": 41, "baseATK": 10, "baseDEF": 10, "baseSPD": 20,
		"skill": { "name": "暗袭", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_008": {
		"id": "enemy_008", "name": "光蝇", "element": "light",
		"rarity": 1, "emoji": "✨",
		"baseHP": 33, "baseATK": 10, "baseDEF": 10, "baseSPD": 22,
		"skill": { "name": "光刺", "cost": 5, "multiplier": 1.9 }
	},
	"monster_boss_003": {
		"id": "monster_boss_003", "name": "深海海马王", "element": "water",
		"rarity": 4, "emoji": "🦑",
		"baseHP": 450, "baseATK": 50, "baseDEF": 40, "baseSPD": 14,
		"skill": { "name": "深渊漩涡", "cost": 12, "multiplier": 3.2 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 3, "damageMultiplier": 2.5 },
			{ "type": "heal", "percent": 0.15, "interval": 4 }
		],
		"leaderSkill": "DEF_BOOST"
	},
	"monster_boss_004": {
		"id": "monster_boss_004", "name": "暗影巨龙", "element": "dark",
		"rarity": 4, "emoji": "🐲",
		"baseHP": 530, "baseATK": 55, "baseDEF": 45, "baseSPD": 16,
		"skill": { "name": "暗影龙息", "cost": 13, "multiplier": 3.5 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 3, "damageMultiplier": 2.5 },
			{ "type": "shield", "hp": 60, "cooldown": 5 },
			{ "type": "heal", "percent": 0.12, "interval": 5 }
		],
		"leaderSkill": "ATK_BOOST_DARK"
	},
	"monster_boss_005": {
		"id": "monster_boss_005", "name": "雷霆巨兽", "element": "thunder",
		"rarity": 4, "emoji": "⚡",
		"baseHP": 600, "baseATK": 58, "baseDEF": 48, "baseSPD": 18,
		"skill": { "name": "雷霆裁决", "cost": 14, "multiplier": 3.8 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 2, "damageMultiplier": 3.0 },
			{ "type": "shield", "hp": 70, "cooldown": 4 }
		],
		"leaderSkill": "ATK_BOOST_THUNDER"
	},
	"monster_021": {
		"id": "monster_021", "name": "暗夜蝠", "element": "dark",
		"rarity": 2, "emoji": "🦇",
		"baseHP": 80, "baseATK": 38, "baseDEF": 12, "baseSPD": 28,
		"skill": { "name": "暗影突袭", "cost": 7, "multiplier": 2.4 },
		"evolution": { "level": 18, "target": "monster_022" }
	},
	"monster_022": {
		"id": "monster_022", "name": "暗翼魔", "element": "dark",
		"rarity": 3, "emoji": "🧛",
		"baseHP": 110, "baseATK": 55, "baseDEF": 18, "baseSPD": 38,
		"skill": { "name": "暗翼斩", "cost": 10, "multiplier": 3.2 },
		"leaderSkill": "COMBO_START"
	},
	"monster_023": {
		"id": "monster_023", "name": "毒蛛王", "element": "dark",
		"rarity": 3, "emoji": "🕷️",
		"baseHP": 130, "baseATK": 55, "baseDEF": 20, "baseSPD": 12,
		"skill": { "name": "毒液射击", "cost": 8, "multiplier": 2.8 },
		"leaderSkill": "ATK_BOOST_DARK"
	},
	"monster_024": {
		"id": "monster_024", "name": "剧毒蛛后", "element": "dark",
		"rarity": 4, "emoji": "🕸️",
		"baseHP": 180, "baseATK": 75, "baseDEF": 28, "baseSPD": 16,
		"skill": { "name": "剧毒蛛网", "cost": 12, "multiplier": 3.8 },
		"leaderSkill": "ATK_BOOST_DARK"
	},
	"enemy_009": {
		"id": "enemy_009", "name": "暗夜蝙蝠", "element": "dark",
		"rarity": 1, "emoji": "🦇",
		"baseHP": 35, "baseATK": 10, "baseDEF": 13, "baseSPD": 22,
		"skill": { "name": "暗袭", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_010": {
		"id": "enemy_010", "name": "暗毒蛛", "element": "dark",
		"rarity": 1, "emoji": "🕷️",
		"baseHP": 41, "baseATK": 10, "baseDEF": 13, "baseSPD": 10,
		"skill": { "name": "毒咬", "cost": 5, "multiplier": 1.9 }
	},
	"enemy_011": {
		"id": "enemy_011", "name": "暗幽灵", "element": "dark",
		"rarity": 1, "emoji": "👻", "isElite": true,
		"baseHP": 36, "baseATK": 10, "baseDEF": 13, "baseSPD": 25,
		"skill": { "name": "穿体", "cost": 5, "multiplier": 2.0 }
	},
	"monster_025": {
		"id": "monster_025", "name": "雷翼龙", "element": "thunder",
		"rarity": 2, "emoji": "🐉",
		"baseHP": 105, "baseATK": 42, "baseDEF": 16, "baseSPD": 26,
		"skill": { "name": "雷电冲击", "cost": 8, "multiplier": 2.6 },
		"evolution": { "level": 18, "target": "monster_026" }
	},
	"monster_026": {
		"id": "monster_026", "name": "雷鸣龙", "element": "thunder",
		"rarity": 3, "emoji": "⚡",
		"baseHP": 145, "baseATK": 62, "baseDEF": 24, "baseSPD": 36,
		"skill": { "name": "雷霆万钧", "cost": 12, "multiplier": 3.5 },
		"leaderSkill": "ATK_BOOST_THUNDER"
	},
	"monster_027": {
		"id": "monster_027", "name": "光辉兽", "element": "light",
		"rarity": 2, "emoji": "🦄",
		"baseHP": 115, "baseATK": 45, "baseDEF": 20, "baseSPD": 20,
		"skill": { "name": "光辉射击", "cost": 9, "multiplier": 2.8 },
		"evolution": { "level": 18, "target": "monster_028" }
	},
	"monster_028": {
		"id": "monster_028", "name": "圣光龙", "element": "light",
		"rarity": 3, "emoji": "🌟",
		"baseHP": 155, "baseATK": 65, "baseDEF": 30, "baseSPD": 28,
		"skill": { "name": "圣光裁决", "cost": 12, "multiplier": 3.6 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_029": {
		"id": "monster_029", "name": "雷光兽", "element": "thunder",
		"rarity": 3, "emoji": "🦁",
		"baseHP": 140, "baseATK": 60, "baseDEF": 22, "baseSPD": 24,
		"skill": { "name": "雷光斩", "cost": 10, "multiplier": 3.2 },
		"leaderSkill": "COMBO_START"
	},
	"monster_030": {
		"id": "monster_030", "name": "雷霆圣龙", "element": "thunder",
		"rarity": 4, "emoji": "👑",
		"baseHP": 195, "baseATK": 80, "baseDEF": 32, "baseSPD": 30,
		"skill": { "name": "圣雷灭世", "cost": 14, "multiplier": 4.2 },
		"leaderSkill": "ATK_BOOST_THUNDER"
	},
	"monster_031": {
		"id": "monster_031", "name": "光明天使", "element": "light",
		"rarity": 3, "emoji": "🕊️",
		"baseHP": 130, "baseATK": 58, "baseDEF": 26, "baseSPD": 32,
		"skill": { "name": "天使之光", "cost": 11, "multiplier": 3.4 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_032": {
		"id": "monster_032", "name": "神圣巨龙", "element": "light",
		"rarity": 4, "emoji": "🏛️",
		"baseHP": 175, "baseATK": 75, "baseDEF": 35, "baseSPD": 38,
		"skill": { "name": "神光净化", "cost": 15, "multiplier": 4.5 },
		"leaderSkill": "HP_BOOST"
	},
	"enemy_012": {
		"id": "enemy_012", "name": "雷球", "element": "thunder",
		"rarity": 1, "emoji": "⚡",
		"baseHP": 42, "baseATK": 10, "baseDEF": 17, "baseSPD": 18,
		"skill": { "name": "电击", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_013": {
		"id": "enemy_013", "name": "光球", "element": "light",
		"rarity": 1, "emoji": "✨",
		"baseHP": 36, "baseATK": 10, "baseDEF": 17, "baseSPD": 20,
		"skill": { "name": "光刺", "cost": 5, "multiplier": 1.9 }
	},
	"enemy_014": {
		"id": "enemy_014", "name": "雷鹰", "element": "thunder",
		"rarity": 1, "emoji": "🦅", "isElite": true,
		"baseHP": 41, "baseATK": 10, "baseDEF": 17, "baseSPD": 26,
		"skill": { "name": "雷翼斩", "cost": 5, "multiplier": 2.0 }
	},
	"enemy_015": {
		"id": "enemy_015", "name": "光蝶", "element": "light",
		"rarity": 1, "emoji": "🦋",
		"baseHP": 37, "baseATK": 10, "baseDEF": 17, "baseSPD": 24,
		"skill": { "name": "光翼", "cost": 5, "multiplier": 2.1 }
	},
	"enemy_016": {
		"id": "enemy_016", "name": "雷光元素", "element": "thunder",
		"rarity": 1, "emoji": "💡", "isElite": true,
		"baseHP": 39, "baseATK": 10, "baseDEF": 17, "baseSPD": 22,
		"skill": { "name": "元素雷电", "cost": 5, "multiplier": 2.2 }
	},
	"monster_033": {
		"id": "monster_033", "name": "冰晶兽", "element": "ice",
		"rarity": 2, "emoji": "💎",
		"baseHP": 120, "baseATK": 32, "baseDEF": 28, "baseSPD": 16,
		"skill": { "name": "冰晶冲击", "cost": 7, "multiplier": 2.3 },
		"evolution": { "level": 18, "target": "monster_034" }
	},
	"monster_034": {
		"id": "monster_034", "name": "冰晶龙", "element": "ice",
		"rarity": 3, "emoji": "🔷",
		"baseHP": 165, "baseATK": 48, "baseDEF": 40, "baseSPD": 22,
		"skill": { "name": "冰晶风暴", "cost": 10, "multiplier": 2.9 },
		"leaderSkill": "ATK_BOOST_ICE"
	},
	"monster_035": {
		"id": "monster_035", "name": "霜狼", "element": "ice",
		"rarity": 2, "emoji": "🐺",
		"baseHP": 95, "baseATK": 42, "baseDEF": 18, "baseSPD": 22,
		"skill": { "name": "霜咬", "cost": 8, "multiplier": 2.5 },
		"evolution": { "level": 18, "target": "monster_036" }
	},
	"monster_036": {
		"id": "monster_036", "name": "寒霜狼王", "element": "ice",
		"rarity": 3, "emoji": "❄️",
		"baseHP": 130, "baseATK": 62, "baseDEF": 26, "baseSPD": 30,
		"skill": { "name": "寒霜撕裂", "cost": 11, "multiplier": 3.3 },
		"leaderSkill": "ATK_BOOST_ICE"
	},
	"monster_037": {
		"id": "monster_037", "name": "雪狐", "element": "ice",
		"rarity": 2, "emoji": "🦊",
		"baseHP": 85, "baseATK": 38, "baseDEF": 14, "baseSPD": 30,
		"skill": { "name": "雪遁", "cost": 6, "multiplier": 2.2 },
		"evolution": { "level": 18, "target": "monster_038" }
	},
	"monster_038": {
		"id": "monster_038", "name": "冰霜妖狐", "element": "ice",
		"rarity": 3, "emoji": "🧊",
		"baseHP": 115, "baseATK": 55, "baseDEF": 20, "baseSPD": 42,
		"skill": { "name": "冰霜幻舞", "cost": 9, "multiplier": 3.1 },
		"leaderSkill": "COMBO_START"
	},
	"monster_039": {
		"id": "monster_039", "name": "寒龟", "element": "ice",
		"rarity": 2, "emoji": "🐧",
		"baseHP": 150, "baseATK": 25, "baseDEF": 35, "baseSPD": 10,
		"skill": { "name": "冰甲护体", "cost": 7, "multiplier": 2.0 },
		"evolution": { "level": 20, "target": "monster_040" }
	},
	"monster_040": {
		"id": "monster_040", "name": "极地冰龟", "element": "ice",
		"rarity": 3, "emoji": "🧊",
		"baseHP": 210, "baseATK": 38, "baseDEF": 52, "baseSPD": 14,
		"skill": { "name": "极寒护盾", "cost": 10, "multiplier": 2.5 },
		"leaderSkill": "DEF_BOOST"
	},
	"monster_041": {
		"id": "monster_041", "name": "冰龙", "element": "ice",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 155, "baseATK": 58, "baseDEF": 30, "baseSPD": 20,
		"skill": { "name": "冰龙吐息", "cost": 10, "multiplier": 3.0 },
		"leaderSkill": "ATK_BOOST_ICE"
	},
	"monster_042": {
		"id": "monster_042", "name": "霜翼龙", "element": "ice",
		"rarity": 4, "emoji": "🌨️",
		"baseHP": 200, "baseATK": 75, "baseDEF": 40, "baseSPD": 26,
		"skill": { "name": "暴风雪降临", "cost": 13, "multiplier": 3.8 },
		"leaderSkill": "ATK_BOOST_ICE"
	},
	"enemy_017": {
		"id": "enemy_017", "name": "冰晶怪", "element": "ice",
		"rarity": 1, "emoji": "💠",
		"baseHP": 39, "baseATK": 10, "baseDEF": 22, "baseSPD": 12,
		"skill": { "name": "冰刺", "cost": 5, "multiplier": 1.7 }
	},
	"enemy_018": {
		"id": "enemy_018", "name": "霜雪狼", "element": "ice",
		"rarity": 1, "emoji": "🐺",
		"baseHP": 45, "baseATK": 10, "baseDEF": 22, "baseSPD": 20,
		"skill": { "name": "霜咬", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_019": {
		"id": "enemy_019", "name": "冰幽灵", "element": "ice",
		"rarity": 1, "emoji": "👻",
		"baseHP": 42, "baseATK": 10, "baseDEF": 22, "baseSPD": 24,
		"skill": { "name": "穿体", "cost": 5, "multiplier": 1.9 }
	},
	"enemy_020": {
		"id": "enemy_020", "name": "极地熊", "element": "ice",
		"rarity": 1, "emoji": "🐻", "isElite": true,
		"baseHP": 39, "baseATK": 10, "baseDEF": 22, "baseSPD": 10,
		"skill": { "name": "冰掌", "cost": 5, "multiplier": 1.6 }
	},
	"enemy_021": {
		"id": "enemy_021", "name": "冰翼龙", "element": "ice",
		"rarity": 1, "emoji": "🐉", "isElite": true,
		"baseHP": 45, "baseATK": 10, "baseDEF": 22, "baseSPD": 22,
		"skill": { "name": "冰息", "cost": 5, "multiplier": 2.0 }
	},
	"monster_boss_006": {
		"id": "monster_boss_006", "name": "冰霜巨龙", "element": "ice",
		"rarity": 4, "emoji": "🐲",
		"baseHP": 700, "baseATK": 60, "baseDEF": 55, "baseSPD": 12,
		"skill": { "name": "绝对零度", "cost": 15, "multiplier": 4.0 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 2, "damageMultiplier": 3.0 },
			{ "type": "shield", "hp": 80, "cooldown": 4 },
			{ "type": "heal", "percent": 0.10, "interval": 4 }
		],
		"leaderSkill": "ATK_BOOST_ICE"
	},
	"monster_043": {
		"id": "monster_043", "name": "虚影兽", "element": "void",
		"rarity": 2, "emoji": "👤",
		"baseHP": 100, "baseATK": 40, "baseDEF": 16, "baseSPD": 24,
		"skill": { "name": "虚影冲击", "cost": 8, "multiplier": 2.5 },
		"evolution": { "level": 18, "target": "monster_044" }
	},
	"monster_044": {
		"id": "monster_044", "name": "虚影魔", "element": "void",
		"rarity": 3, "emoji": "👻",
		"baseHP": 140, "baseATK": 58, "baseDEF": 24, "baseSPD": 32,
		"skill": { "name": "虚空撕裂", "cost": 11, "multiplier": 3.2 },
		"leaderSkill": "ATK_BOOST_VOID"
	},
	"monster_045": {
		"id": "monster_045", "name": "噬魂虫", "element": "void",
		"rarity": 2, "emoji": "🪱",
		"baseHP": 80, "baseATK": 36, "baseDEF": 12, "baseSPD": 32,
		"skill": { "name": "灵魂吸收", "cost": 7, "multiplier": 2.4 },
		"evolution": { "level": 18, "target": "monster_046" }
	},
	"monster_046": {
		"id": "monster_046", "name": "噬魂蛾", "element": "void",
		"rarity": 3, "emoji": "🦋",
		"baseHP": 110, "baseATK": 52, "baseDEF": 18, "baseSPD": 44,
		"skill": { "name": "虚空幻翼", "cost": 10, "multiplier": 3.3 },
		"leaderSkill": "COMBO_START"
	},
	"monster_047": {
		"id": "monster_047", "name": "虚空幼龙", "element": "void",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 150, "baseATK": 55, "baseDEF": 30, "baseSPD": 20,
		"skill": { "name": "虚空吐息", "cost": 10, "multiplier": 3.0 },
		"leaderSkill": "ATK_BOOST_VOID"
	},
	"monster_048": {
		"id": "monster_048", "name": "虚空巨龙", "element": "void",
		"rarity": 4, "emoji": "🌑",
		"baseHP": 200, "baseATK": 72, "baseDEF": 40, "baseSPD": 26,
		"skill": { "name": "虚空灭世", "cost": 14, "multiplier": 4.0 },
		"leaderSkill": "ATK_BOOST_VOID"
	},
	"enemy_022": {
		"id": "enemy_022", "name": "虚影", "element": "void",
		"rarity": 1, "emoji": "👤",
		"baseHP": 47, "baseATK": 10, "baseDEF": 28, "baseSPD": 18,
		"skill": { "name": "虚袭", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_023": {
		"id": "enemy_023", "name": "噬魂蛛", "element": "void",
		"rarity": 1, "emoji": "🕷️",
		"baseHP": 45, "baseATK": 10, "baseDEF": 28, "baseSPD": 12,
		"skill": { "name": "魂咬", "cost": 5, "multiplier": 1.9 }
	},
	"enemy_024": {
		"id": "enemy_024", "name": "虚空幽灵", "element": "void",
		"rarity": 1, "emoji": "👻",
		"baseHP": 50, "baseATK": 10, "baseDEF": 28, "baseSPD": 24,
		"skill": { "name": "穿魂", "cost": 5, "multiplier": 2.0 }
	},
	"enemy_025": {
		"id": "enemy_025", "name": "暗蚀兽", "element": "void",
		"rarity": 1, "emoji": "🐺", "isElite": true,
		"baseHP": 43, "baseATK": 10, "baseDEF": 28, "baseSPD": 14,
		"skill": { "name": "暗蚀", "cost": 5, "multiplier": 1.7 }
	},
	"enemy_026": {
		"id": "enemy_026", "name": "虚空元素", "element": "void",
		"rarity": 1, "emoji": "🌀", "isElite": true,
		"baseHP": 46, "baseATK": 10, "baseDEF": 28, "baseSPD": 20,
		"skill": { "name": "虚空弹", "cost": 5, "multiplier": 2.1 }
	},
	"monster_boss_007": {
		"id": "monster_boss_007", "name": "虚空巨龙", "element": "void",
		"rarity": 5, "emoji": "🌑",
		"baseHP": 750, "baseATK": 65, "baseDEF": 50, "baseSPD": 14,
		"skill": { "name": "虚空湮灭", "cost": 15, "multiplier": 4.2 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 2, "damageMultiplier": 3.0 },
			{ "type": "shield", "hp": 90, "cooldown": 4 },
			{ "type": "heal", "percent": 0.12, "interval": 4 }
		],
		"leaderSkill": "ATK_BOOST_VOID"
	},
	"monster_049": {
		"id": "monster_049", "name": "时空狼", "element": "temporal",
		"rarity": 2, "emoji": "🐺",
		"baseHP": 110, "baseATK": 38, "baseDEF": 22, "baseSPD": 22,
		"skill": { "name": "时空撕裂", "cost": 8, "multiplier": 2.4 },
		"evolution": { "level": 18, "target": "monster_050" }
	},
	"monster_050": {
		"id": "monster_050", "name": "时空狼王", "element": "temporal",
		"rarity": 3, "emoji": "🌟",
		"baseHP": 155, "baseATK": 55, "baseDEF": 32, "baseSPD": 30,
		"skill": { "name": "时空裂斩", "cost": 11, "multiplier": 3.1 },
		"leaderSkill": "ATK_BOOST_TEMPORAL"
	},
	"monster_051": {
		"id": "monster_051", "name": "时空幼龙", "element": "temporal",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 145, "baseATK": 52, "baseDEF": 28, "baseSPD": 18,
		"skill": { "name": "时空吐息", "cost": 10, "multiplier": 2.9 },
		"leaderSkill": "ATK_BOOST_TEMPORAL"
	},
	"monster_052": {
		"id": "monster_052", "name": "时空巨龙", "element": "temporal",
		"rarity": 4, "emoji": "⏳",
		"baseHP": 195, "baseATK": 68, "baseDEF": 38, "baseSPD": 24,
		"skill": { "name": "时空湮灭", "cost": 13, "multiplier": 3.6 },
		"leaderSkill": "ATK_BOOST_TEMPORAL"
	},
	"monster_053": {
		"id": "monster_053", "name": "时空狐", "element": "temporal",
		"rarity": 2, "emoji": "🦊",
		"baseHP": 88, "baseATK": 40, "baseDEF": 14, "baseSPD": 32,
		"skill": { "name": "时空穿梭", "cost": 7, "multiplier": 2.3 },
		"evolution": { "level": 18, "target": "monster_054" }
	},
	"monster_054": {
		"id": "monster_054", "name": "时空妖狐", "element": "temporal",
		"rarity": 3, "emoji": "🔮",
		"baseHP": 120, "baseATK": 58, "baseDEF": 20, "baseSPD": 44,
		"skill": { "name": "时空幻舞", "cost": 10, "multiplier": 3.2 },
		"leaderSkill": "COMBO_START"
	},
	"enemy_027": {
		"id": "enemy_027", "name": "时空狼崽", "element": "temporal",
		"rarity": 1, "emoji": "🐺",
		"baseHP": 51, "baseATK": 11, "baseDEF": 35, "baseSPD": 18,
		"skill": { "name": "时空爪", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_028": {
		"id": "enemy_028", "name": "时空幽灵", "element": "temporal",
		"rarity": 1, "emoji": "👻",
		"baseHP": 55, "baseATK": 11, "baseDEF": 35, "baseSPD": 26,
		"skill": { "name": "穿时", "cost": 5, "multiplier": 2.0 }
	},
	"enemy_029": {
		"id": "enemy_029", "name": "时空调律者", "element": "temporal",
		"rarity": 1, "emoji": "🕰️",
		"baseHP": 49, "baseATK": 11, "baseDEF": 34, "baseSPD": 14,
		"skill": { "name": "时间扭曲", "cost": 5, "multiplier": 1.7 }
	},
	"enemy_030": {
		"id": "enemy_030", "name": "虚空噬时兽", "element": "temporal",
		"rarity": 1, "emoji": "🦎", "isElite": true,
		"baseHP": 57, "baseATK": 11, "baseDEF": 36, "baseSPD": 20,
		"skill": { "name": "时间啃噬", "cost": 5, "multiplier": 1.9 }
	},
	"enemy_031": {
		"id": "enemy_031", "name": "时空元素", "element": "temporal",
		"rarity": 1, "emoji": "🌀", "isElite": true,
		"baseHP": 52, "baseATK": 11, "baseDEF": 35, "baseSPD": 22,
		"skill": { "name": "时空弹", "cost": 5, "multiplier": 2.1 }
	},
	"monster_boss_008": {
		"id": "monster_boss_008", "name": "时空巨龙", "element": "temporal",
		"rarity": 5, "emoji": "⏳",
		"baseHP": 800, "baseATK": 68, "baseDEF": 52, "baseSPD": 16,
		"skill": { "name": "时空崩灭", "cost": 16, "multiplier": 4.5 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 2, "damageMultiplier": 3.0 },
			{ "type": "shield", "hp": 100, "cooldown": 4 },
			{ "type": "heal", "percent": 0.12, "interval": 3 }
		],
		"leaderSkill": "ATK_BOOST_TEMPORAL"
	},
	"monster_055": {
		"id": "monster_055", "name": "星耀狼", "element": "star",
		"rarity": 2, "emoji": "🐺",
		"baseHP": 115, "baseATK": 40, "baseDEF": 24, "baseSPD": 24,
		"skill": { "name": "星光撕裂", "cost": 8, "multiplier": 2.5 },
		"evolution": { "level": 18, "target": "monster_056" }
	},
	"monster_056": {
		"id": "monster_056", "name": "星耀狼王", "element": "star",
		"rarity": 3, "emoji": "🌟",
		"baseHP": 160, "baseATK": 58, "baseDEF": 34, "baseSPD": 32,
		"skill": { "name": "星耀裂斩", "cost": 11, "multiplier": 3.2 },
		"leaderSkill": "ATK_BOOST_STAR"
	},
	"monster_057": {
		"id": "monster_057", "name": "星耀幼龙", "element": "star",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 150, "baseATK": 55, "baseDEF": 30, "baseSPD": 20,
		"skill": { "name": "星耀吐息", "cost": 10, "multiplier": 3.0 },
		"leaderSkill": "ATK_BOOST_STAR"
	},
	"monster_058": {
		"id": "monster_058", "name": "星耀巨龙", "element": "star",
		"rarity": 4, "emoji": "✨",
		"baseHP": 205, "baseATK": 72, "baseDEF": 42, "baseSPD": 26,
		"skill": { "name": "星耀灭世", "cost": 14, "multiplier": 3.8 },
		"leaderSkill": "ATK_BOOST_STAR"
	},
	"monster_059": {
		"id": "monster_059", "name": "星耀狐", "element": "star",
		"rarity": 2, "emoji": "🦊",
		"baseHP": 90, "baseATK": 42, "baseDEF": 16, "baseSPD": 34,
		"skill": { "name": "星耀穿梭", "cost": 7, "multiplier": 2.4 },
		"evolution": { "level": 18, "target": "monster_060" }
	},
	"monster_060": {
		"id": "monster_060", "name": "星耀妖狐", "element": "star",
		"rarity": 3, "emoji": "🔮",
		"baseHP": 125, "baseATK": 60, "baseDEF": 22, "baseSPD": 46,
		"skill": { "name": "星耀幻舞", "cost": 10, "multiplier": 3.3 },
		"leaderSkill": "COMBO_START"
	},
	"enemy_032": {
		"id": "enemy_032", "name": "星耀狼崽", "element": "star",
		"rarity": 1, "emoji": "🐺",
		"baseHP": 66, "baseATK": 11, "baseDEF": 44, "baseSPD": 20,
		"skill": { "name": "星爪", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_033": {
		"id": "enemy_033", "name": "星耀幽灵", "element": "star",
		"rarity": 1, "emoji": "👻",
		"baseHP": 58, "baseATK": 11, "baseDEF": 42, "baseSPD": 28,
		"skill": { "name": "穿星", "cost": 5, "multiplier": 2.0 }
	},
	"enemy_034": {
		"id": "enemy_034", "name": "星耀祭司", "element": "star",
		"rarity": 1, "emoji": "🕯️",
		"baseHP": 63, "baseATK": 11, "baseDEF": 43, "baseSPD": 16,
		"skill": { "name": "星光祈福", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_035": {
		"id": "enemy_035", "name": "星蚀兽", "element": "star",
		"rarity": 1, "emoji": "🦎", "isElite": true,
		"baseHP": 60, "baseATK": 11, "baseDEF": 43, "baseSPD": 22,
		"skill": { "name": "星蚀", "cost": 5, "multiplier": 2.0 }
	},
	"enemy_036": {
		"id": "enemy_036", "name": "星耀元素", "element": "star",
		"rarity": 1, "emoji": "💫", "isElite": true,
		"baseHP": 68, "baseATK": 11, "baseDEF": 44, "baseSPD": 24,
		"skill": { "name": "星弹", "cost": 5, "multiplier": 2.2 }
	},
	"monster_boss_009": {
		"id": "monster_boss_009", "name": "星耀巨龙", "element": "star",
		"rarity": 5, "emoji": "✨",
		"baseHP": 850, "baseATK": 72, "baseDEF": 55, "baseSPD": 18,
		"skill": { "name": "星辰湮灭", "cost": 16, "multiplier": 4.8 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 2, "damageMultiplier": 3.5 },
			{ "type": "shield", "hp": 110, "cooldown": 3 },
			{ "type": "heal", "percent": 0.15, "interval": 4 }
		],
		"leaderSkill": "ATK_BOOST_STAR"
	},
	"monster_061": {
		"id": "monster_061", "name": "混沌狼", "element": "chaos",
		"rarity": 2, "emoji": "🐺",
		"baseHP": 118, "baseATK": 42, "baseDEF": 26, "baseSPD": 25,
		"skill": { "name": "混沌撕裂", "cost": 8, "multiplier": 2.6 },
		"evolution": { "level": 18, "target": "monster_062" }
	},
	"monster_062": {
		"id": "monster_062", "name": "混沌狼王", "element": "chaos",
		"rarity": 3, "emoji": "🌟",
		"baseHP": 165, "baseATK": 60, "baseDEF": 36, "baseSPD": 34,
		"skill": { "name": "混沌裂斩", "cost": 11, "multiplier": 3.3 },
		"leaderSkill": "ATK_BOOST_CHAOS"
	},
	"monster_063": {
		"id": "monster_063", "name": "混沌幼龙", "element": "chaos",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 155, "baseATK": 58, "baseDEF": 32, "baseSPD": 22,
		"skill": { "name": "混沌吐息", "cost": 10, "multiplier": 3.1 },
		"leaderSkill": "ATK_BOOST_CHAOS"
	},
	"monster_064": {
		"id": "monster_064", "name": "混沌巨龙", "element": "chaos",
		"rarity": 4, "emoji": "🌑",
		"baseHP": 210, "baseATK": 75, "baseDEF": 44, "baseSPD": 28,
		"skill": { "name": "混沌灭世", "cost": 14, "multiplier": 3.9 },
		"leaderSkill": "ATK_BOOST_CHAOS"
	},
	"monster_065": {
		"id": "monster_065", "name": "混沌狐", "element": "chaos",
		"rarity": 2, "emoji": "🦊",
		"baseHP": 92, "baseATK": 44, "baseDEF": 16, "baseSPD": 36,
		"skill": { "name": "混沌穿梭", "cost": 7, "multiplier": 2.5 },
		"evolution": { "level": 18, "target": "monster_066" }
	},
	"monster_066": {
		"id": "monster_066", "name": "混沌妖狐", "element": "chaos",
		"rarity": 3, "emoji": "🔮",
		"baseHP": 128, "baseATK": 62, "baseDEF": 24, "baseSPD": 48,
		"skill": { "name": "混沌幻舞", "cost": 10, "multiplier": 3.4 },
		"leaderSkill": "COMBO_START"
	},
	"enemy_037": {
		"id": "enemy_037", "name": "混沌狼崽", "element": "chaos",
		"rarity": 1, "emoji": "🐺",
		"baseHP": 72, "baseATK": 12, "baseDEF": 52, "baseSPD": 20,
		"skill": { "name": "混沌爪", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_038": {
		"id": "enemy_038", "name": "混沌幽灵", "element": "chaos",
		"rarity": 1, "emoji": "👻",
		"baseHP": 74, "baseATK": 12, "baseDEF": 52, "baseSPD": 30,
		"skill": { "name": "穿混沌", "cost": 5, "multiplier": 2.0 }
	},
	"enemy_039": {
		"id": "enemy_039", "name": "混沌祭司", "element": "chaos",
		"rarity": 1, "emoji": "🕯️", "isElite": true,
		"baseHP": 69, "baseATK": 12, "baseDEF": 51, "baseSPD": 16,
		"skill": { "name": "混沌祈福", "cost": 5, "multiplier": 1.8 }
	},
	"enemy_040": {
		"id": "enemy_040", "name": "混沌噬星兽", "element": "chaos",
		"rarity": 1, "emoji": "🦎", "isElite": true,
		"baseHP": 79, "baseATK": 12, "baseDEF": 53, "baseSPD": 24,
		"skill": { "name": "星蚀混沌", "cost": 5, "multiplier": 2.2 }
	},
	"enemy_041": {
		"id": "enemy_041", "name": "混沌元素", "element": "chaos",
		"rarity": 1, "emoji": "🌀", "isElite": true,
		"baseHP": 76, "baseATK": 12, "baseDEF": 52, "baseSPD": 26,
		"skill": { "name": "混沌弹", "cost": 5, "multiplier": 2.1 }
	},
	"monster_boss_010": {
		"id": "monster_boss_010", "name": "混沌兽神", "element": "chaos",
		"rarity": 5, "emoji": "🐲",
		"baseHP": 900, "baseATK": 75, "baseDEF": 58, "baseSPD": 20,
		"skill": { "name": "混沌湮灭", "cost": 16, "multiplier": 5.0 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 2, "damageMultiplier": 3.5 },
			{ "type": "shield", "hp": 120, "cooldown": 3 },
			{ "type": "heal", "percent": 0.15, "interval": 3 }
		],
		"leaderSkill": "ATK_BOOST_CHAOS"
	},
	"monster_067": {
		"id": "monster_067", "name": "光耀狼", "element": "light",
		"rarity": 2, "emoji": "🐺",
		"baseHP": 120, "baseATK": 42, "baseDEF": 28, "baseSPD": 26,
		"skill": { "name": "光耀撕裂", "cost": 8, "multiplier": 2.6 },
		"evolution": { "level": 18, "target": "monster_068" }
	},
	"monster_068": {
		"id": "monster_068", "name": "光耀狼王", "element": "light",
		"rarity": 3, "emoji": "🌟",
		"baseHP": 170, "baseATK": 62, "baseDEF": 38, "baseSPD": 35,
		"skill": { "name": "光耀裂斩", "cost": 11, "multiplier": 3.3 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_069": {
		"id": "monster_069", "name": "光耀幼龙", "element": "light",
		"rarity": 3, "emoji": "🐉",
		"baseHP": 160, "baseATK": 60, "baseDEF": 34, "baseSPD": 24,
		"skill": { "name": "光耀吐息", "cost": 10, "multiplier": 3.2 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_070": {
		"id": "monster_070", "name": "光耀巨龙", "element": "light",
		"rarity": 4, "emoji": "✨",
		"baseHP": 215, "baseATK": 78, "baseDEF": 46, "baseSPD": 30,
		"skill": { "name": "光耀灭世", "cost": 14, "multiplier": 4.0 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_071": {
		"id": "monster_071", "name": "光耀狐", "element": "light",
		"rarity": 2, "emoji": "🦊",
		"baseHP": 95, "baseATK": 46, "baseDEF": 18, "baseSPD": 38,
		"skill": { "name": "光耀穿梭", "cost": 7, "multiplier": 2.6 },
		"evolution": { "level": 18, "target": "monster_072" }
	},
	"monster_072": {
		"id": "monster_072", "name": "光耀妖狐", "element": "light",
		"rarity": 3, "emoji": "🔮",
		"baseHP": 132, "baseATK": 65, "baseDEF": 26, "baseSPD": 50,
		"skill": { "name": "光耀幻舞", "cost": 10, "multiplier": 3.5 },
		"leaderSkill": "COMBO_START"
	},
	"monster_073": {
		"id": "monster_073", "name": "光耀战鹰", "element": "light",
		"rarity": 3, "emoji": "🦅",
		"baseHP": 130, "baseATK": 62, "baseDEF": 22, "baseSPD": 28,
		"skill": { "name": "光耀翼斩", "cost": 9, "multiplier": 3.2 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_074": {
		"id": "monster_074", "name": "光耀圣鹰", "element": "light",
		"rarity": 4, "emoji": "🕊️",
		"baseHP": 180, "baseATK": 80, "baseDEF": 32, "baseSPD": 36,
		"skill": { "name": "圣光裁决", "cost": 13, "multiplier": 4.2 },
		"leaderSkill": "ATK_BOOST_LIGHT"
	},
	"monster_075": {
		"id": "monster_075", "name": "光耀守护者", "element": "light",
		"rarity": 3, "emoji": "🛡️",
		"baseHP": 200, "baseATK": 38, "baseDEF": 48, "baseSPD": 12,
		"skill": { "name": "圣光护盾", "cost": 8, "multiplier": 2.2 },
		"leaderSkill": "DEF_BOOST"
	},
	"monster_076": {
		"id": "monster_076", "name": "光耀巨灵", "element": "light",
		"rarity": 4, "emoji": "👼",
		"baseHP": 270, "baseATK": 50, "baseDEF": 65, "baseSPD": 16,
		"skill": { "name": "神圣庇护", "cost": 11, "multiplier": 2.8 },
		"leaderSkill": "DEF_BOOST"
	},
	"enemy_042": {
		"id": "enemy_042", "name": "光耀狼崽", "element": "light",
		"rarity": 1, "emoji": "🐺",
		"baseHP": 90, "baseATK": 13, "baseDEF": 62, "baseSPD": 22,
		"skill": { "name": "光爪", "cost": 5, "multiplier": 1.9 }
	},
	"enemy_043": {
		"id": "enemy_043", "name": "光耀幽灵", "element": "light",
		"rarity": 1, "emoji": "👻",
		"baseHP": 84, "baseATK": 13, "baseDEF": 62, "baseSPD": 30,
		"skill": { "name": "穿光", "cost": 5, "multiplier": 2.1 }
	},
	"enemy_044": {
		"id": "enemy_044", "name": "光耀祭司", "element": "light",
		"rarity": 1, "emoji": "🕯️", "isElite": true,
		"baseHP": 94, "baseATK": 13, "baseDEF": 63, "baseSPD": 18,
		"skill": { "name": "光祈", "cost": 5, "multiplier": 1.9 }
	},
	"enemy_045": {
		"id": "enemy_045", "name": "光蚀兽", "element": "light",
		"rarity": 1, "emoji": "🦎", "isElite": true,
		"baseHP": 78, "baseATK": 13, "baseDEF": 61, "baseSPD": 26,
		"skill": { "name": "光蚀", "cost": 5, "multiplier": 2.0 }
	},
	"enemy_046": {
		"id": "enemy_046", "name": "光耀元素", "element": "light",
		"rarity": 1, "emoji": "💫", "isElite": true,
		"baseHP": 89, "baseATK": 13, "baseDEF": 62, "baseSPD": 28,
		"skill": { "name": "光弹", "cost": 5, "multiplier": 2.2 }
	},
	"enemy_047": {
		"id": "enemy_047", "name": "熔火幼蜥", "element": "fire",
		"rarity": 1, "emoji": "🦎",
		"baseHP": 36, "baseATK": 10, "baseDEF": 8, "baseSPD": 10,
		"skill": { "name": "火苗扑击", "cost": 5, "multiplier": 1.6 }
	},
	"enemy_048": {
		"id": "enemy_048", "name": "岩浆泡泡", "element": "fire",
		"rarity": 1, "emoji": "🔥",
		"baseHP": 40, "baseATK": 10, "baseDEF": 9, "baseSPD": 8,
		"skill": { "name": "熔泡", "cost": 5, "multiplier": 1.5 }
	},
	"enemy_049": {
		"id": "enemy_049", "name": "火绒精", "element": "fire",
		"rarity": 1, "emoji": "✨", "isElite": true,
		"baseHP": 34, "baseATK": 11, "baseDEF": 8, "baseSPD": 12,
		"skill": { "name": "火绒爆", "cost": 5, "multiplier": 1.7 }
	},
	"monster_boss_011": {
		"id": "monster_boss_011", "name": "光耀天使长", "element": "light",
		"rarity": 5, "emoji": "👼",
		"baseHP": 950, "baseATK": 80, "baseDEF": 62, "baseSPD": 22,
		"skill": { "name": "神圣制裁", "cost": 16, "multiplier": 5.2 },
		"isBoss": true,
		"enemySkills": [
			{ "type": "charge", "interval": 2, "damageMultiplier": 4.0 },
			{ "type": "shield", "hp": 130, "cooldown": 3 },
			{ "type": "heal", "percent": 0.18, "interval": 3 }
		],
		"leaderSkill": "HP_BOOST"
	}
}

# ========== 属性克制表 ==========
const ELEMENT_CHART: Dictionary = {
	"fire":    { "strong": "grass",  "weak": "water"   },
	"water":   { "strong": "fire",   "weak": "grass"   },
	"grass":   { "strong": "water",  "weak": "fire"    },
	"thunder": { "strong": "light",  "weak": "light"   },
	"light":   { "strong": "dark",   "weak": "void"    },
	"earth":   { "strong": "wind",   "weak": "fire"    },
	"wind":    { "strong": "earth",  "weak": "water"   },
	"dark":    { "strong": "light",  "weak": "light"   },
	"ice":     { "strong": "grass",  "weak": "fire"    },
	"void":    { "strong": "dark",   "weak": "light"   },
	"temporal":{ "strong": "dark",   "weak": "void"   },
	"star":    { "strong": "temporal", "weak": "void"   },
	"chaos":   { "strong": "star",   "weak": "light"   }
}

# ========== 棋盘能量亲和 ==========
## element 是世界观/克制属性，boardAffinity 是消除宝石时响应的五色棋盘能量。
const BOARD_AFFINITY_FALLBACK: Dictionary = {
	"fire": "fire",
	"water": "water",
	"grass": "grass",
	"thunder": "thunder",
	"light": "light",
	"earth": "grass",
	"wind": "thunder",
	"dark": "light",
	"ice": "water",
	"void": "light",
	"temporal": "thunder",
	"star": "light",
	"chaos": "fire"
}

const BOARD_AFFINITY_NAMES: Dictionary = {
	"fire": "炽能",
	"water": "潮能",
	"grass": "生能",
	"thunder": "震能",
	"light": "辉能"
}

const SKILL_TYPE_LABELS: Dictionary = {
	"strike": "输出",
	"ward": "守护",
	"tempo": "控场",
	"hunt": "猎手",
	"shape": "塑盘"
}

# ========== 稀有度成长率 ==========
const RARITY_GROWTH_RATE: Dictionary = {
	1: 0.08,  # ★1 普通
	2: 0.10,  # ★2 常见
	3: 0.12,  # ★3 稀有
	4: 0.14,  # ★4 史诗
	5: 0.16   # ★5 传说
}

# ========== 静态工具函数 ==========

## 获取属性克制倍率
## JS: getElementMultiplier(atkElement, defElement)
static func get_element_multiplier(atk_element: String, def_element: String) -> float:
	var chart: Dictionary = ELEMENT_CHART.get(atk_element, {})
	if chart.is_empty():
		return 1.0
	if chart.get("strong") == def_element:
		return 1.5
	if chart.get("weak") == def_element:
		return 0.75
	return 1.0

## 根据幻想属性推导棋盘能量亲和，兼容旧精灵数据。
static func get_board_affinity_from_element(element: String) -> String:
	return str(BOARD_AFFINITY_FALLBACK.get(element, "fire"))

## 获取精灵的棋盘能量亲和。新数据可显式写 boardAffinity，旧数据自动从 element 推导。
static func get_board_affinity(monster: Dictionary) -> String:
	var explicit := str(monster.get("boardAffinity", ""))
	if not explicit.is_empty():
		return explicit
	return get_board_affinity_from_element(str(monster.get("element", "fire")))

static func with_board_affinity(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	var result := data.duplicate(true)
	result["boardAffinity"] = get_board_affinity(result)
	if result.has("skill"):
		result["skill"] = normalize_skill(result.get("skill", {}))
	return result

## 将旧倍率技能归一为效果结构。新技能可直接配置 type/effects。
static func normalize_skill(skill: Dictionary) -> Dictionary:
	if skill.is_empty():
		return {}
	var result := skill.duplicate(true)
	if not result.has("type"):
		result["type"] = "strike"
	var effects_value: Variant = result.get("effects", [])
	if not result.has("effects") or not (effects_value is Array) or (effects_value as Array).is_empty():
		result["effects"] = [
			{
				"kind": "damage",
				"target": "weakest_enemy",
				"multiplier": float(result.get("multiplier", 1.0))
			}
		]
	if not result.has("multiplier"):
		var multiplier := 1.0
		for effect: Dictionary in result.get("effects", []):
			if effect.get("kind", "") == "damage":
				multiplier = float(effect.get("multiplier", multiplier))
				break
		result["multiplier"] = multiplier
	return result

## 获取精灵数据（支持等级/性格修正）
## JS: getMonsterStats(monsterId, level, natureId)
static func get_monster_stats(monster_id: String, level: int = 1, nature_id: String = "") -> Dictionary:
	var data: Dictionary = MONSTER_DB.get(monster_id, {})
	if data.is_empty():
		return {}
	var growth_rate: float = RARITY_GROWTH_RATE.get(data.get("rarity", 2), 0.10)
	var mult: float = 1.0 + (level - 1) * growth_rate

	# 计算基础属性
	var hp: int = int(data.get("baseHP", 0) * mult)
	var atk: int = int(data.get("baseATK", 0) * mult)
	var def: int = int(data.get("baseDEF", 0) * mult)
	var spd: int = int(data.get("baseSPD", 0) * mult)

	# 性格修正
	if nature_id != "":
		hp = int(hp * NatureDB.get_nature_stat_mult(nature_id, "hp"))
		atk = int(atk * NatureDB.get_nature_stat_mult(nature_id, "atk"))
		def = int(def * NatureDB.get_nature_stat_mult(nature_id, "def"))
		spd = int(spd * NatureDB.get_nature_stat_mult(nature_id, "spd"))

	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"element": data.get("element", ""),
		"boardAffinity": get_board_affinity(data),
		"rarity": data.get("rarity", 1),
		"emoji": data.get("emoji", ""),
		"hp": hp,
		"maxHP": hp,
		"atk": atk,
		"def": def,
		"spd": spd,
		"skill": normalize_skill(data.get("skill", {})),
		"skillCharge": 0,
		"isBoss": data.get("isBoss", false),
		"enemySkills": null if not data.has("enemySkills") else data.get("enemySkills", []).duplicate(true),
		"leaderSkill": data.get("leaderSkill", "")
	}

## 快捷方法：根据ID获取精灵数据
static func get_monster(monster_id: String) -> Dictionary:
	return with_board_affinity(MONSTER_DB.get(monster_id, {}))

static func get_all() -> Array:
	var result: Array = []
	for monster: Dictionary in MONSTER_DB.values():
		result.append(with_board_affinity(monster))
	return result

static func has_monster(monster_id: String) -> bool:
	return MONSTER_DB.has(monster_id)

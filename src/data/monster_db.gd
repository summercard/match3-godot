class_name MonsterDb
extends RefCounted

const ElementRulesScript = preload("res://src/battle/element_rules.gd")
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
		"id": "monster_001", "name": "大眼蜗", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 160, "baseATK": 20, "baseDEF": 11, "baseSPD": 12,
		"skill": {"name": "大眼蜗冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_001"
	},
	"monster_002": {
		"id": "monster_002", "name": "草兔兔", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 162, "baseATK": 16, "baseDEF": 22, "baseSPD": 15,
		"skill": {"name": "草兔兔冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_002",
		"evolution": {"level": 16, "target": "monster_003"}
	},
	"monster_003": {
		"id": "monster_003", "name": "兔八子", "element": "grass",
		"rarity": 2, "emoji": "",
		"baseHP": 206, "baseATK": 33, "baseDEF": 19, "baseSPD": 23,
		"skill": {"name": "兔八子冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_003",
		"evolution": {"level": 30, "target": "monster_004"}
	},
	"monster_004": {
		"id": "monster_004", "name": "草兔王", "element": "grass",
		"rarity": 3, "emoji": "",
		"baseHP": 293, "baseATK": 39, "baseDEF": 51, "baseSPD": 20,
		"skill": {"name": "草兔王冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_004"
	},
	"monster_005": {
		"id": "monster_005", "name": "风铃猫头鹰", "element": "wind",
		"rarity": 1, "emoji": "",
		"baseHP": 104, "baseATK": 29, "baseDEF": 6, "baseSPD": 39,
		"skill": {"name": "风铃猫头鹰冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_005",
		"evolution": {"level": 16, "target": "monster_006"}
	},
	"monster_006": {
		"id": "monster_006", "name": "飓风猫头鹰", "element": "wind",
		"rarity": 2, "emoji": "",
		"baseHP": 150, "baseATK": 44, "baseDEF": 8, "baseSPD": 49,
		"skill": {"name": "飓风猫头鹰冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_006",
		"evolution": {"level": 30, "target": "monster_008"}
	},
	"monster_007": {
		"id": "monster_007", "name": "草洋洋", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 164, "baseATK": 18, "baseDEF": 20, "baseSPD": 18,
		"skill": {"name": "草洋洋冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_007",
		"evolution": {"level": 16, "target": "monster_009"}
	},
	"monster_008": {
		"id": "monster_008", "name": "猫头鹰王", "element": "wind",
		"rarity": 3, "emoji": "",
		"baseHP": 270, "baseATK": 46, "baseDEF": 48, "baseSPD": 32,
		"skill": {"name": "猫头鹰王冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_008"
	},
	"monster_009": {
		"id": "monster_009", "name": "花洋洋", "element": "grass",
		"rarity": 2, "emoji": "",
		"baseHP": 210, "baseATK": 31, "baseDEF": 31, "baseSPD": 23,
		"skill": {"name": "花洋洋冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_009",
		"evolution": {"level": 30, "target": "monster_010"}
	},
	"monster_010": {
		"id": "monster_010", "name": "绵洋洋", "element": "grass",
		"rarity": 3, "emoji": "",
		"baseHP": 260, "baseATK": 45, "baseDEF": 33, "baseSPD": 26,
		"skill": {"name": "绵洋洋冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_010"
	},
	"monster_011": {
		"id": "monster_011", "name": "水珠花", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 167, "baseATK": 15, "baseDEF": 23, "baseSPD": 16,
		"skill": {"name": "水珠花冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_011",
		"evolution": {"level": 16, "target": "monster_012"}
	},
	"monster_012": {
		"id": "monster_012", "name": "小喷嘴", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 210, "baseATK": 33, "baseDEF": 24, "baseSPD": 22,
		"skill": {"name": "小喷嘴冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_012",
		"evolution": {"level": 30, "target": "monster_013"}
	},
	"monster_013": {
		"id": "monster_013", "name": "大喷嘴", "element": "water",
		"rarity": 3, "emoji": "",
		"baseHP": 262, "baseATK": 44, "baseDEF": 35, "baseSPD": 24,
		"skill": {"name": "大喷嘴冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_013"
	},
	"monster_014": {
		"id": "monster_014", "name": "矿鼠鼠", "element": "earth",
		"rarity": 1, "emoji": "",
		"baseHP": 193, "baseATK": 14, "baseDEF": 34, "baseSPD": 6,
		"skill": {"name": "矿鼠鼠冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_014",
		"evolution": {"level": 16, "target": "monster_015"}
	},
	"monster_015": {
		"id": "monster_015", "name": "矿伯鼠", "element": "earth",
		"rarity": 2, "emoji": "",
		"baseHP": 241, "baseATK": 27, "baseDEF": 46, "baseSPD": 10,
		"skill": {"name": "矿伯鼠冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_015",
		"evolution": {"level": 30, "target": "monster_016"}
	},
	"monster_016": {
		"id": "monster_016", "name": "矿山老板", "element": "earth",
		"rarity": 3, "emoji": "",
		"baseHP": 298, "baseATK": 39, "baseDEF": 56, "baseSPD": 14,
		"skill": {"name": "矿山老板冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_016"
	},
	"monster_017": {
		"id": "monster_017", "name": "不高兴", "element": "dark",
		"rarity": 1, "emoji": "",
		"baseHP": 111, "baseATK": 52, "baseDEF": 6, "baseSPD": 20,
		"skill": {"name": "不高兴冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_017",
		"evolution": {"level": 16, "target": "monster_018"}
	},
	"monster_018": {
		"id": "monster_018", "name": "很不高兴", "element": "dark",
		"rarity": 2, "emoji": "",
		"baseHP": 155, "baseATK": 62, "baseDEF": 8, "baseSPD": 23,
		"skill": {"name": "很不高兴冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_018",
		"evolution": {"level": 30, "target": "monster_019"}
	},
	"monster_019": {
		"id": "monster_019", "name": "特别不高兴", "element": "dark",
		"rarity": 3, "emoji": "",
		"baseHP": 205, "baseATK": 82, "baseDEF": 22, "baseSPD": 30,
		"skill": {"name": "特别不高兴冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_019"
	},
	"monster_020": {
		"id": "monster_020", "name": "迷路绵阳", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 159, "baseATK": 18, "baseDEF": 11, "baseSPD": 12,
		"skill": {"name": "迷路绵阳冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_020",
		"evolution": {"level": 16, "target": "monster_021"}
	},
	"monster_021": {
		"id": "monster_021", "name": "还在迷路咩", "element": "grass",
		"rarity": 2, "emoji": "",
		"baseHP": 198, "baseATK": 31, "baseDEF": 23, "baseSPD": 18,
		"skill": {"name": "还在迷路咩冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_021",
		"evolution": {"level": 30, "target": "monster_022"}
	},
	"monster_022": {
		"id": "monster_022", "name": "超级路痴羊", "element": "grass",
		"rarity": 3, "emoji": "",
		"baseHP": 258, "baseATK": 46, "baseDEF": 31, "baseSPD": 29,
		"skill": {"name": "超级路痴羊冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_022"
	},
	"monster_023": {
		"id": "monster_023", "name": "小雨滴", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 167, "baseATK": 18, "baseDEF": 22, "baseSPD": 17,
		"skill": {"name": "小雨滴冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_023",
		"evolution": {"level": 16, "target": "monster_024"}
	},
	"monster_024": {
		"id": "monster_024", "name": "大雨滴", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 216, "baseATK": 28, "baseDEF": 30, "baseSPD": 19,
		"skill": {"name": "大雨滴冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_024",
		"evolution": {"level": 30, "target": "monster_025"}
	},
	"monster_025": {
		"id": "monster_025", "name": "暴雨来咯", "element": "water",
		"rarity": 3, "emoji": "",
		"baseHP": 264, "baseATK": 40, "baseDEF": 44, "baseSPD": 28,
		"skill": {"name": "暴雨来咯冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_025"
	},
	"monster_026": {
		"id": "monster_026", "name": "哔哩", "element": "thunder",
		"rarity": 1, "emoji": "",
		"baseHP": 106, "baseATK": 35, "baseDEF": 6, "baseSPD": 41,
		"skill": {"name": "哔哩冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_026",
		"evolution": {"level": 16, "target": "monster_027"}
	},
	"monster_027": {
		"id": "monster_027", "name": "哔哩哔哩", "element": "thunder",
		"rarity": 2, "emoji": "",
		"baseHP": 148, "baseATK": 46, "baseDEF": 7, "baseSPD": 44,
		"skill": {"name": "哔哩哔哩冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_027",
		"evolution": {"level": 30, "target": "monster_028"}
	},
	"monster_028": {
		"id": "monster_028", "name": "普拉哔哩", "element": "thunder",
		"rarity": 3, "emoji": "",
		"baseHP": 193, "baseATK": 58, "baseDEF": 20, "baseSPD": 55,
		"skill": {"name": "普拉哔哩冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_028"
	},
	"monster_029": {
		"id": "monster_029", "name": "小拳拳菇", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 132, "baseATK": 39, "baseDEF": 10, "baseSPD": 16,
		"skill": {"name": "小拳拳菇冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_029",
		"evolution": {"level": 16, "target": "monster_030"}
	},
	"monster_030": {
		"id": "monster_030", "name": "拳菇王", "element": "grass",
		"rarity": 2, "emoji": "",
		"baseHP": 235, "baseATK": 25, "baseDEF": 39, "baseSPD": 15,
		"skill": {"name": "拳菇王冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_030"
	},
	"monster_031": {
		"id": "monster_031", "name": "摇滚蝠", "element": "wind",
		"rarity": 1, "emoji": "",
		"baseHP": 105, "baseATK": 29, "baseDEF": 6, "baseSPD": 40,
		"skill": {"name": "摇滚蝠冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_031",
		"evolution": {"level": 16, "target": "monster_032"}
	},
	"monster_032": {
		"id": "monster_032", "name": "叛逆蝠", "element": "wind",
		"rarity": 2, "emoji": "",
		"baseHP": 150, "baseATK": 41, "baseDEF": 12, "baseSPD": 45,
		"skill": {"name": "叛逆蝠冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_032",
		"evolution": {"level": 30, "target": "monster_033"}
	},
	"monster_033": {
		"id": "monster_033", "name": "迪杰蝠", "element": "wind",
		"rarity": 3, "emoji": "",
		"baseHP": 200, "baseATK": 58, "baseDEF": 21, "baseSPD": 57,
		"skill": {"name": "迪杰蝠冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_033"
	},
	"monster_034": {
		"id": "monster_034", "name": "路灯草", "element": "light",
		"rarity": 1, "emoji": "",
		"baseHP": 156, "baseATK": 23, "baseDEF": 19, "baseSPD": 18,
		"skill": {"name": "路灯草冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_034",
		"evolution": {"level": 16, "target": "monster_035"}
	},
	"monster_035": {
		"id": "monster_035", "name": "路灯亮亮", "element": "light",
		"rarity": 2, "emoji": "",
		"baseHP": 192, "baseATK": 39, "baseDEF": 19, "baseSPD": 21,
		"skill": {"name": "路灯亮亮冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_035"
	},
	"monster_036": {
		"id": "monster_036", "name": "托尼", "element": "light",
		"rarity": 1, "emoji": "",
		"baseHP": 154, "baseATK": 26, "baseDEF": 9, "baseSPD": 14,
		"skill": {"name": "托尼冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_036",
		"evolution": {"level": 16, "target": "monster_037"}
	},
	"monster_037": {
		"id": "monster_037", "name": "时尚托尼", "element": "light",
		"rarity": 2, "emoji": "",
		"baseHP": 191, "baseATK": 36, "baseDEF": 18, "baseSPD": 20,
		"skill": {"name": "时尚托尼冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_037",
		"evolution": {"level": 30, "target": "monster_038"}
	},
	"monster_038": {
		"id": "monster_038", "name": "托尼大师", "element": "light",
		"rarity": 3, "emoji": "",
		"baseHP": 255, "baseATK": 52, "baseDEF": 32, "baseSPD": 32,
		"skill": {"name": "托尼大师冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_038"
	},
	"monster_039": {
		"id": "monster_039", "name": "幽幽鱼", "element": "dark",
		"rarity": 1, "emoji": "",
		"baseHP": 118, "baseATK": 51, "baseDEF": 6, "baseSPD": 23,
		"skill": {"name": "幽幽鱼冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_039"
	},
	"monster_040": {
		"id": "monster_040", "name": "小木木", "element": "dark",
		"rarity": 1, "emoji": "",
		"baseHP": 115, "baseATK": 47, "baseDEF": 6, "baseSPD": 19,
		"skill": {"name": "小木木冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_040",
		"evolution": {"level": 16, "target": "monster_041"}
	},
	"monster_041": {
		"id": "monster_041", "name": "阿木阿木", "element": "dark",
		"rarity": 2, "emoji": "",
		"baseHP": 154, "baseATK": 63, "baseDEF": 12, "baseSPD": 25,
		"skill": {"name": "阿木阿木冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_041"
	},
	"monster_042": {
		"id": "monster_042", "name": "甲球", "element": "earth",
		"rarity": 1, "emoji": "",
		"baseHP": 195, "baseATK": 14, "baseDEF": 37, "baseSPD": 6,
		"skill": {"name": "甲球冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_042",
		"evolution": {"level": 16, "target": "monster_043"}
	},
	"monster_043": {
		"id": "monster_043", "name": "刺球怪", "element": "earth",
		"rarity": 2, "emoji": "",
		"baseHP": 239, "baseATK": 26, "baseDEF": 45, "baseSPD": 7,
		"skill": {"name": "刺球怪冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_043",
		"evolution": {"level": 30, "target": "monster_044"}
	},
	"monster_044": {
		"id": "monster_044", "name": "刺刺哥哥", "element": "earth",
		"rarity": 3, "emoji": "",
		"baseHP": 225, "baseATK": 68, "baseDEF": 36, "baseSPD": 23,
		"skill": {"name": "刺刺哥哥冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_044"
	},
	"monster_045": {
		"id": "monster_045", "name": "酒蝎", "element": "dark",
		"rarity": 1, "emoji": "",
		"baseHP": 113, "baseATK": 51, "baseDEF": 6, "baseSPD": 19,
		"skill": {"name": "酒蝎冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_045",
		"evolution": {"level": 16, "target": "monster_046"}
	},
	"monster_046": {
		"id": "monster_046", "name": "豪华酒蝎", "element": "dark",
		"rarity": 2, "emoji": "",
		"baseHP": 150, "baseATK": 62, "baseDEF": 12, "baseSPD": 23,
		"skill": {"name": "豪华酒蝎冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_046"
	},
	"monster_047": {
		"id": "monster_047", "name": "小岩球", "element": "earth",
		"rarity": 1, "emoji": "",
		"baseHP": 198, "baseATK": 14, "baseDEF": 36, "baseSPD": 6,
		"skill": {"name": "小岩球冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_047",
		"evolution": {"level": 16, "target": "monster_048"}
	},
	"monster_048": {
		"id": "monster_048", "name": "大岩球", "element": "earth",
		"rarity": 2, "emoji": "",
		"baseHP": 248, "baseATK": 26, "baseDEF": 44, "baseSPD": 9,
		"skill": {"name": "大岩球冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_048"
	},
	"monster_049": {
		"id": "monster_049", "name": "绿洲蜥", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 152, "baseATK": 20, "baseDEF": 11, "baseSPD": 17,
		"skill": {"name": "绿洲蜥冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_049",
		"evolution": {"level": 16, "target": "monster_050"}
	},
	"monster_050": {
		"id": "monster_050", "name": "绿洲巨蜥", "element": "grass",
		"rarity": 2, "emoji": "",
		"baseHP": 200, "baseATK": 30, "baseDEF": 23, "baseSPD": 18,
		"skill": {"name": "绿洲巨蜥冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_050"
	},
	"monster_051": {
		"id": "monster_051", "name": "沙漠粉狐", "element": "wind",
		"rarity": 1, "emoji": "",
		"baseHP": 109, "baseATK": 32, "baseDEF": 6, "baseSPD": 43,
		"skill": {"name": "沙漠粉狐冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_051",
		"evolution": {"level": 16, "target": "monster_052"}
	},
	"monster_052": {
		"id": "monster_052", "name": "沙漠魅影", "element": "dark",
		"rarity": 2, "emoji": "",
		"baseHP": 151, "baseATK": 66, "baseDEF": 12, "baseSPD": 26,
		"skill": {"name": "沙漠魅影冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_052"
	},
	"monster_053": {
		"id": "monster_053", "name": "信使龟", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 195, "baseATK": 14, "baseDEF": 31, "baseSPD": 11,
		"skill": {"name": "信使龟冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_053",
		"evolution": {"level": 16, "target": "monster_055"}
	},
	"monster_054": {
		"id": "monster_054", "name": "破浪鬼", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 156, "baseATK": 19, "baseDEF": 13, "baseSPD": 16,
		"skill": {"name": "破浪鬼冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_054"
	},
	"monster_055": {
		"id": "monster_055", "name": "超速闪电龟", "element": "thunder",
		"rarity": 2, "emoji": "",
		"baseHP": 215, "baseATK": 32, "baseDEF": 32, "baseSPD": 26,
		"skill": {"name": "超速闪电龟冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_055"
	},
	"monster_056": {
		"id": "monster_056", "name": "水泡泡", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 165, "baseATK": 16, "baseDEF": 21, "baseSPD": 12,
		"skill": {"name": "水泡泡冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_056",
		"evolution": {"level": 16, "target": "monster_057"}
	},
	"monster_057": {
		"id": "monster_057", "name": "啪噗", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 210, "baseATK": 29, "baseDEF": 21, "baseSPD": 18,
		"skill": {"name": "啪噗冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_057"
	},
	"monster_058": {
		"id": "monster_058", "name": "光宝", "element": "light",
		"rarity": 1, "emoji": "",
		"baseHP": 158, "baseATK": 23, "baseDEF": 18, "baseSPD": 16,
		"skill": {"name": "光宝冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_058",
		"evolution": {"level": 16, "target": "monster_059"}
	},
	"monster_059": {
		"id": "monster_059", "name": "宝霸", "element": "light",
		"rarity": 2, "emoji": "",
		"baseHP": 199, "baseATK": 36, "baseDEF": 17, "baseSPD": 24,
		"skill": {"name": "宝霸冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_059"
	},
	"monster_060": {
		"id": "monster_060", "name": "水晶豹", "element": "light",
		"rarity": 1, "emoji": "",
		"baseHP": 118, "baseATK": 33, "baseDEF": 6, "baseSPD": 37,
		"skill": {"name": "水晶豹冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_060",
		"evolution": {"level": 16, "target": "monster_061"}
	},
	"monster_061": {
		"id": "monster_061", "name": "成年水晶豹", "element": "light",
		"rarity": 2, "emoji": "",
		"baseHP": 159, "baseATK": 43, "baseDEF": 14, "baseSPD": 45,
		"skill": {"name": "成年水晶豹冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_061"
	},
	"monster_062": {
		"id": "monster_062", "name": "海噜噜", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 170, "baseATK": 14, "baseDEF": 20, "baseSPD": 15,
		"skill": {"name": "海噜噜冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_062",
		"evolution": {"level": 16, "target": "monster_063"}
	},
	"monster_063": {
		"id": "monster_063", "name": "深海噜噜", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 218, "baseATK": 28, "baseDEF": 30, "baseSPD": 17,
		"skill": {"name": "深海噜噜冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_063"
	},
	"monster_064": {
		"id": "monster_064", "name": "椰果果", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 165, "baseATK": 15, "baseDEF": 18, "baseSPD": 12,
		"skill": {"name": "椰果果冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_064",
		"evolution": {"level": 16, "target": "monster_065"}
	},
	"monster_065": {
		"id": "monster_065", "name": "大椰果果", "element": "grass",
		"rarity": 2, "emoji": "",
		"baseHP": 209, "baseATK": 30, "baseDEF": 28, "baseSPD": 21,
		"skill": {"name": "大椰果果冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_065",
		"evolution": {"level": 30, "target": "monster_066"}
	},
	"monster_066": {
		"id": "monster_066", "name": "肥椰果", "element": "grass",
		"rarity": 3, "emoji": "",
		"baseHP": 267, "baseATK": 45, "baseDEF": 40, "baseSPD": 25,
		"skill": {"name": "肥椰果冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_066"
	},
	"monster_067": {
		"id": "monster_067", "name": "哧溜豹", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 124, "baseATK": 23, "baseDEF": 12, "baseSPD": 26,
		"skill": {"name": "哧溜豹冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_067",
		"evolution": {"level": 16, "target": "monster_068"}
	},
	"monster_068": {
		"id": "monster_068", "name": "哧溜溜豹", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 167, "baseATK": 40, "baseDEF": 20, "baseSPD": 32,
		"skill": {"name": "哧溜溜豹冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_068",
		"evolution": {"level": 30, "target": "monster_069"}
	},
	"monster_069": {
		"id": "monster_069", "name": "哧溜溜溜溜豹", "element": "water",
		"rarity": 3, "emoji": "",
		"baseHP": 213, "baseATK": 52, "baseDEF": 33, "baseSPD": 43,
		"skill": {"name": "哧溜溜溜溜豹冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_069"
	},
	"monster_070": {
		"id": "monster_070", "name": "冰帝小企鹅", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 164, "baseATK": 15, "baseDEF": 25, "baseSPD": 14,
		"skill": {"name": "冰帝小企鹅冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_070",
		"evolution": {"level": 16, "target": "monster_071"}
	},
	"monster_071": {
		"id": "monster_071", "name": "冰帝企鹅", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 213, "baseATK": 27, "baseDEF": 33, "baseSPD": 20,
		"skill": {"name": "冰帝企鹅冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_071",
		"evolution": {"level": 30, "target": "monster_072"}
	},
	"monster_072": {
		"id": "monster_072", "name": "冰帝企鹅王", "element": "water",
		"rarity": 3, "emoji": "",
		"baseHP": 293, "baseATK": 38, "baseDEF": 57, "baseSPD": 21,
		"skill": {"name": "冰帝企鹅王冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_072"
	},
	"monster_073": {
		"id": "monster_073", "name": "噗尼", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 169, "baseATK": 15, "baseDEF": 23, "baseSPD": 9,
		"skill": {"name": "噗尼冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_073",
		"evolution": {"level": 16, "target": "monster_074"}
	},
	"monster_074": {
		"id": "monster_074", "name": "噗尼蚌蚌", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 232, "baseATK": 27, "baseDEF": 44, "baseSPD": 14,
		"skill": {"name": "噗尼蚌蚌冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_074",
		"evolution": {"level": 30, "target": "monster_075"}
	},
	"monster_075": {
		"id": "monster_075", "name": "噗尼尼蚌蚌蚌", "element": "water",
		"rarity": 3, "emoji": "",
		"baseHP": 298, "baseATK": 38, "baseDEF": 56, "baseSPD": 20,
		"skill": {"name": "噗尼尼蚌蚌蚌冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_075"
	},
	"monster_076": {
		"id": "monster_076", "name": "小白", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 191, "baseATK": 14, "baseDEF": 37, "baseSPD": 6,
		"skill": {"name": "小白冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_076",
		"evolution": {"level": 16, "target": "monster_077"}
	},
	"monster_077": {
		"id": "monster_077", "name": "九尾小白", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 236, "baseATK": 24, "baseDEF": 46, "baseSPD": 13,
		"skill": {"name": "九尾小白冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_077",
		"evolution": {"level": 30, "target": "monster_078"}
	},
	"monster_078": {
		"id": "monster_078", "name": "水晶小白", "element": "water",
		"rarity": 3, "emoji": "",
		"baseHP": 271, "baseATK": 44, "baseDEF": 48, "baseSPD": 26,
		"skill": {"name": "水晶小白冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_078"
	},
	"monster_079": {
		"id": "monster_079", "name": "极光小熊", "element": "water",
		"rarity": 1, "emoji": "",
		"baseHP": 165, "baseATK": 18, "baseDEF": 24, "baseSPD": 11,
		"skill": {"name": "极光小熊冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_079",
		"evolution": {"level": 16, "target": "monster_080"}
	},
	"monster_080": {
		"id": "monster_080", "name": "五彩小可爱", "element": "water",
		"rarity": 2, "emoji": "",
		"baseHP": 233, "baseATK": 24, "baseDEF": 41, "baseSPD": 13,
		"skill": {"name": "五彩小可爱冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_080"
	},
	"monster_081": {
		"id": "monster_081", "name": "指路星", "element": "light",
		"rarity": 1, "emoji": "",
		"baseHP": 116, "baseATK": 33, "baseDEF": 6, "baseSPD": 34,
		"skill": {"name": "指路星冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_081",
		"evolution": {"level": 16, "target": "monster_082"}
	},
	"monster_082": {
		"id": "monster_082", "name": "启明星", "element": "light",
		"rarity": 2, "emoji": "",
		"baseHP": 152, "baseATK": 46, "baseDEF": 12, "baseSPD": 41,
		"skill": {"name": "启明星冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_082",
		"evolution": {"level": 30, "target": "monster_083"}
	},
	"monster_083": {
		"id": "monster_083", "name": "萤火彗星", "element": "light",
		"rarity": 3, "emoji": "",
		"baseHP": 201, "baseATK": 59, "baseDEF": 24, "baseSPD": 48,
		"skill": {"name": "萤火彗星冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_083"
	},
	"monster_084": {
		"id": "monster_084", "name": "瞌睡熊", "element": "dark",
		"rarity": 1, "emoji": "",
		"baseHP": 144, "baseATK": 30, "baseDEF": 7, "baseSPD": 18,
		"skill": {"name": "瞌睡熊冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_084",
		"evolution": {"level": 16, "target": "monster_085"}
	},
	"monster_085": {
		"id": "monster_085", "name": "还在瞌睡熊", "element": "dark",
		"rarity": 2, "emoji": "",
		"baseHP": 198, "baseATK": 39, "baseDEF": 18, "baseSPD": 24,
		"skill": {"name": "还在瞌睡熊冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_085",
		"evolution": {"level": 30, "target": "monster_086"}
	},
	"monster_086": {
		"id": "monster_086", "name": "赖床熊", "element": "dark",
		"rarity": 3, "emoji": "",
		"baseHP": 252, "baseATK": 53, "baseDEF": 29, "baseSPD": 28,
		"skill": {"name": "赖床熊冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_086"
	},
	"monster_087": {
		"id": "monster_087", "name": "小地龙", "element": "earth",
		"rarity": 1, "emoji": "",
		"baseHP": 132, "baseATK": 34, "baseDEF": 14, "baseSPD": 13,
		"skill": {"name": "小地龙冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_087",
		"evolution": {"level": 16, "target": "monster_088"}
	},
	"monster_088": {
		"id": "monster_088", "name": "成年地龙", "element": "earth",
		"rarity": 2, "emoji": "",
		"baseHP": 177, "baseATK": 51, "baseDEF": 21, "baseSPD": 19,
		"skill": {"name": "成年地龙冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_088",
		"evolution": {"level": 30, "target": "monster_089"}
	},
	"monster_089": {
		"id": "monster_089", "name": "地龙领主", "element": "earth",
		"rarity": 3, "emoji": "",
		"baseHP": 225, "baseATK": 66, "baseDEF": 36, "baseSPD": 19,
		"skill": {"name": "地龙领主冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_089"
	},
	"monster_090": {
		"id": "monster_090", "name": "夜来香", "element": "grass",
		"rarity": 1, "emoji": "",
		"baseHP": 168, "baseATK": 15, "baseDEF": 21, "baseSPD": 12,
		"skill": {"name": "夜来香冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_090",
		"evolution": {"level": 16, "target": "monster_091"}
	},
	"monster_091": {
		"id": "monster_091", "name": "花满楼", "element": "grass",
		"rarity": 2, "emoji": "",
		"baseHP": 205, "baseATK": 29, "baseDEF": 30, "baseSPD": 19,
		"skill": {"name": "花满楼冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_091",
		"evolution": {"level": 30, "target": "monster_092"}
	},
	"monster_092": {
		"id": "monster_092", "name": "小凤仙", "element": "grass",
		"rarity": 3, "emoji": "",
		"baseHP": 260, "baseATK": 45, "baseDEF": 41, "baseSPD": 30,
		"skill": {"name": "小凤仙冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_092"
	},
	"monster_093": {
		"id": "monster_093", "name": "火焰犬", "element": "fire",
		"rarity": 1, "emoji": "",
		"baseHP": 110, "baseATK": 37, "baseDEF": 6, "baseSPD": 34,
		"skill": {"name": "火焰犬冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_093",
		"evolution": {"level": 16, "target": "monster_094"}
	},
	"monster_094": {
		"id": "monster_094", "name": "熔岩犬", "element": "fire",
		"rarity": 2, "emoji": "",
		"baseHP": 223, "baseATK": 35, "baseDEF": 33, "baseSPD": 15,
		"skill": {"name": "熔岩犬冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_094"
	},
	"monster_095": {
		"id": "monster_095", "name": "熔岩蟹宝宝", "element": "fire",
		"rarity": 1, "emoji": "",
		"baseHP": 175, "baseATK": 21, "baseDEF": 24, "baseSPD": 9,
		"skill": {"name": "熔岩蟹宝宝冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_095",
		"evolution": {"level": 16, "target": "monster_096"}
	},
	"monster_096": {
		"id": "monster_096", "name": "熔岩蟹", "element": "fire",
		"rarity": 2, "emoji": "",
		"baseHP": 217, "baseATK": 33, "baseDEF": 31, "baseSPD": 17,
		"skill": {"name": "熔岩蟹冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_096"
	},
	"monster_097": {
		"id": "monster_097", "name": "生气野猪", "element": "fire",
		"rarity": 1, "emoji": "",
		"baseHP": 112, "baseATK": 46, "baseDEF": 6, "baseSPD": 15,
		"skill": {"name": "生气野猪冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_097",
		"evolution": {"level": 16, "target": "monster_098"}
	},
	"monster_098": {
		"id": "monster_098", "name": "愤怒野猪", "element": "fire",
		"rarity": 2, "emoji": "",
		"baseHP": 154, "baseATK": 60, "baseDEF": 11, "baseSPD": 26,
		"skill": {"name": "愤怒野猪冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_098"
	},
	"monster_099": {
		"id": "monster_099", "name": "热辣锅", "element": "fire",
		"rarity": 1, "emoji": "",
		"baseHP": 112, "baseATK": 51, "baseDEF": 6, "baseSPD": 16,
		"skill": {"name": "热辣锅冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_099",
		"evolution": {"level": 16, "target": "monster_100"}
	},
	"monster_100": {
		"id": "monster_100", "name": "火山烧", "element": "fire",
		"rarity": 2, "emoji": "",
		"baseHP": 153, "baseATK": 60, "baseDEF": 12, "baseSPD": 22,
		"skill": {"name": "火山烧冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_100"
	},
	"monster_101": {
		"id": "monster_101", "name": "炎鱼", "element": "fire",
		"rarity": 2, "emoji": "",
		"baseHP": 155, "baseATK": 63, "baseDEF": 10, "baseSPD": 22,
		"skill": {"name": "炎鱼冲击", "cost": 8, "type": "strike", "multiplier": 1.5, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.5}]},
		"leaderSkill": "LS_MONSTER_101",
		"evolution": {"level": 30, "target": "monster_103"}
	},
	"monster_102": {
		"id": "monster_102", "name": "炎鱼宝宝", "element": "fire",
		"rarity": 1, "emoji": "",
		"baseHP": 113, "baseATK": 49, "baseDEF": 6, "baseSPD": 18,
		"skill": {"name": "炎鱼宝宝冲击", "cost": 7, "type": "strike", "multiplier": 1.25, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.25}]},
		"leaderSkill": "LS_MONSTER_102",
		"evolution": {"level": 16, "target": "monster_101"}
	},
	"monster_103": {
		"id": "monster_103", "name": "斗炎鱼", "element": "fire",
		"rarity": 3, "emoji": "",
		"baseHP": 203, "baseATK": 78, "baseDEF": 23, "baseSPD": 27,
		"skill": {"name": "斗炎鱼冲击", "cost": 9, "type": "strike", "multiplier": 1.75, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 1.75}]},
		"leaderSkill": "LS_MONSTER_103"
	},
	"monster_boss_001": {
		"id": "monster_boss_001", "name": "花草兽", "element": "grass",
		"rarity": 4, "emoji": "",
		"baseHP": 339, "baseATK": 51, "baseDEF": 59, "baseSPD": 27,
		"skill": {"name": "花草兽冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_001",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	},
	"monster_boss_002": {
		"id": "monster_boss_002", "name": "我的刀盾", "element": "earth",
		"rarity": 4, "emoji": "",
		"baseHP": 406, "baseATK": 51, "baseDEF": 87, "baseSPD": 11,
		"skill": {"name": "我的刀盾冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_002",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	},
	"monster_boss_003": {
		"id": "monster_boss_003", "name": "瑞幸", "element": "light",
		"rarity": 4, "emoji": "",
		"baseHP": 338, "baseATK": 62, "baseDEF": 47, "baseSPD": 30,
		"skill": {"name": "瑞幸冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_003",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	},
	"monster_boss_004": {
		"id": "monster_boss_004", "name": "巨石王", "element": "earth",
		"rarity": 4, "emoji": "",
		"baseHP": 407, "baseATK": 47, "baseDEF": 87, "baseSPD": 10,
		"skill": {"name": "巨石王冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_004",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	},
	"monster_boss_005": {
		"id": "monster_boss_005", "name": "深海霸主", "element": "water",
		"rarity": 4, "emoji": "",
		"baseHP": 402, "baseATK": 51, "baseDEF": 83, "baseSPD": 16,
		"skill": {"name": "深海霸主冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_005",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	},
	"monster_boss_006": {
		"id": "monster_boss_006", "name": "雪狐王", "element": "water",
		"rarity": 4, "emoji": "",
		"baseHP": 407, "baseATK": 50, "baseDEF": 90, "baseSPD": 16,
		"skill": {"name": "雪狐王冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_006",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	},
	"monster_boss_007": {
		"id": "monster_boss_007", "name": "混沌虚空", "element": "dark",
		"rarity": 4, "emoji": "",
		"baseHP": 297, "baseATK": 100, "baseDEF": 50, "baseSPD": 27,
		"skill": {"name": "混沌虚空冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_007",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	},
	"monster_boss_008": {
		"id": "monster_boss_008", "name": "山火巨灵", "element": "fire",
		"rarity": 4, "emoji": "",
		"baseHP": 383, "baseATK": 69, "baseDEF": 79, "baseSPD": 18,
		"skill": {"name": "山火巨灵冲击", "cost": 12, "type": "strike", "multiplier": 2.2, "effects": [{"kind": "damage", "target": "weakest_enemy", "multiplier": 2.2}]},
		"leaderSkill": "LS_BOSS_008",
		"isBoss": true,
		"enemyBossMultiplier": {"hp": 2.5, "atk": 0.6, "def": 1, "spd": 0.5},
		"enemySkills": [{"type": "charge", "interval": 3, "damageMultiplier": 2.5}]
	}
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
	1: 0.065,  # ★1 普通：每级 +6.5%
	2: 0.091,  # ★2 常见：每级 +9.1%
	3: 0.104,  # ★3 稀有：每级 +10.4%
	4: 0.156,  # ★4 史诗：每级 +15.6%
	5: 0.195   # ★5 传说：每级 +19.5%
}

# DEF 不参与百分比复利，只按等级增加固定数值。
const RARITY_DEF_GROWTH_PER_LEVEL: Dictionary = {
	1: 0.13,
	2: 0.195,
	3: 0.26,
	4: 0.325,
	5: 0.39
}

# ========== 静态工具函数 ==========

## 获取属性克制倍率
## JS: getElementMultiplier(atkElement, defElement)
static func get_element_multiplier(atk_element: String, def_element: String) -> float:
	return ElementRulesScript.get_multiplier(atk_element, def_element)

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
	var safe_level := clampi(level, 1, 100)
	var rarity := int(data.get("rarity", 2))
	var growth_rate: float = RARITY_GROWTH_RATE.get(data.get("rarity", 2), 0.08)
	var mult: float = pow(1.0 + growth_rate, float(safe_level - 1))
	var def_per_level: float = RARITY_DEF_GROWTH_PER_LEVEL.get(rarity, 0.15)

	# 计算基础属性
	var hp: int = int(data.get("baseHP", 0) * mult)
	var atk: int = int(data.get("baseATK", 0) * mult)
	var def: int = int(float(data.get("baseDEF", 0)) + float(safe_level - 1) * def_per_level)
	var spd: int = int(data.get("baseSPD", 0) * mult)

	# 性格修正
	if nature_id != "":
		hp = int(hp * NatureDB.get_nature_stat_mult(nature_id, "hp"))
		atk = int(atk * NatureDB.get_nature_stat_mult(nature_id, "atk"))
		def = int(def * NatureDB.get_nature_stat_mult(nature_id, "def"))
		spd = int(spd * NatureDB.get_nature_stat_mult(nature_id, "spd"))
	var is_elite := bool(data.get("isElite", false))
	if is_elite:
		var elite_mult := 1.10
		hp = int(float(hp) * elite_mult)
		atk = int(float(atk) * elite_mult)
		def = int(float(def) * elite_mult)
		spd = int(float(spd) * elite_mult)

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
		"isElite": is_elite,
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

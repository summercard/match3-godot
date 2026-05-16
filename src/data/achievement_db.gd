# ============================================
# data/achievement_db.gd - 成就配置数据
# 翻译自 data/achievements.js
# ============================================
class_name AchievementDb
extends RefCounted

# 成就数据库（17个成就）
# unlocked 字段为初始值，实际运行状态由 SaveManager 管理
const ACHIEVEMENTS: Array = [
	# ========== 战斗类 ==========
	{
		"id": "ach_first_battle",
		"name": "初出茅庐",
		"desc": "完成第1场战斗",
		"icon": "⚔️",
		"category": "battle",
		"target": 1,
		"progressKey": "battleCount",
		"reward": {"gold": 50},
		"unlocked": false
	},
	{
		"id": "ach_battle_10",
		"name": "身经百战",
		"desc": "累计完成10场战斗",
		"icon": "🗡️",
		"category": "battle",
		"target": 10,
		"progressKey": "battleCount",
		"reward": {"gold": 100},
		"unlocked": false
	},
	{
		"id": "ach_battle_50",
		"name": "百战老兵",
		"desc": "累计完成50场战斗",
		"icon": "🏆",
		"category": "battle",
		"target": 50,
		"progressKey": "battleCount",
		"reward": {"gold": 300},
		"unlocked": false
	},
	{
		"id": "ach_first_win",
		"name": "首战告捷",
		"desc": "首次击败敌人",
		"icon": "🎖️",
		"category": "battle",
		"target": 1,
		"progressKey": "winCount",
		"reward": {"gold": 80},
		"unlocked": false
	},
	{
		"id": "ach_first_clear",
		"name": "初次通关",
		"desc": "通过第1关",
		"icon": "🚪",
		"category": "battle",
		"target": 1,
		"progressKey": "stageClearedCount",
		"reward": {"gold": 60},
		"unlocked": false
	},
	{
		"id": "ach_clear_10",
		"name": "关卡猎人",
		"desc": "通关10个关卡",
		"icon": "🗺️",
		"category": "battle",
		"target": 10,
		"progressKey": "stageClearedCount",
		"reward": {"gold": 200},
		"unlocked": false
	},

	# ========== 收集类 ==========
	{
		"id": "ach_first_capture",
		"name": "初次收服",
		"desc": "收服第1只怪物",
		"icon": "🔮",
		"category": "collect",
		"target": 1,
		"progressKey": "captureCount",
		"reward": {"gold": 50},
		"unlocked": false
	},
	{
		"id": "ach_capture_5",
		"name": "怪兽收藏家",
		"desc": "收服5只不同怪物",
		"icon": "📚",
		"category": "collect",
		"target": 5,
		"progressKey": "captureCount",
		"reward": {"gold": 150},
		"unlocked": false
	},
	{
		"id": "ach_capture_10",
		"name": "怪物大师",
		"desc": "收服全部怪物",
		"icon": "👑",
		"category": "collect",
		"target": 5,
		"progressKey": "captureCount",
		"reward": {"gold": 500},
		"unlocked": false
	},
	{
		"id": "ach_first_evolve",
		"name": "初次进化",
		"desc": "首次进化怪物",
		"icon": "✨",
		"category": "collect",
		"target": 1,
		"progressKey": "evolveCount",
		"reward": {"gold": 100},
		"unlocked": false
	},
	{
		"id": "ach_evolve_5",
		"name": "进化狂热",
		"desc": "累计进化5只怪物",
		"icon": "🌟",
		"category": "collect",
		"target": 5,
		"progressKey": "evolveCount",
		"reward": {"gold": 300},
		"unlocked": false
	},

	# ========== 数值类 ==========
	{
		"id": "ach_gold_10000",
		"name": "小有资产",
		"desc": "累计获得10000金币",
		"icon": "💰",
		"category": "numeric",
		"target": 10000,
		"progressKey": "totalGoldEarned",
		"reward": {"gold": 200},
		"unlocked": false
	},
	{
		"id": "ach_gold_100000",
		"name": "百万富翁",
		"desc": "累计获得100000金币",
		"icon": "💎",
		"category": "numeric",
		"target": 100000,
		"progressKey": "totalGoldEarned",
		"reward": {"gold": 1000},
		"unlocked": false
	},
	{
		"id": "ach_damage_1000",
		"name": "初露锋芒",
		"desc": "累计造成1000点伤害",
		"icon": "🔥",
		"category": "numeric",
		"target": 1000,
		"progressKey": "totalDamageDealt",
		"reward": {"gold": 80},
		"unlocked": false
	},
	{
		"id": "ach_damage_10000",
		"name": "毁灭之力",
		"desc": "累计造成10000点伤害",
		"icon": "⚡",
		"category": "numeric",
		"target": 10000,
		"progressKey": "totalDamageDealt",
		"reward": {"gold": 500},
		"unlocked": false
	},

	# ========== 连续类 ==========
	{
		"id": "ach_signin_7",
		"name": "一周坚持",
		"desc": "连续签到7天",
		"icon": "📆",
		"category": "continuous",
		"target": 7,
		"progressKey": "maxConsecutiveSignIn",
		"reward": {"gold": 150},
		"unlocked": false
	},
	{
		"id": "ach_signin_30",
		"name": "签到达人",
		"desc": "累计签到30天",
		"icon": "🏅",
		"category": "continuous",
		"target": 30,
		"progressKey": "totalSignInDays",
		"reward": {"gold": 500},
		"unlocked": false
	}
]


# 按 category 筛选成就
static func get_by_category(category: String) -> Array:
	var result: Array = []
	for ach: Dictionary in ACHIEVEMENTS:
		if ach.get("category") == category:
			result.append(ach)
	return result


# 按 ID 获取成就
static func get_by_id(ach_id: String) -> Dictionary:
	for ach: Dictionary in ACHIEVEMENTS:
		if ach.get("id") == ach_id:
			return ach
	return {}
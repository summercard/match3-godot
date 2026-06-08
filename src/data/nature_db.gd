class_name NatureDB
extends RefCounted
## 性格系统数据库 - 从 js/data/natures.js 翻译
## 每只精灵收服时随机获得性格，影响属性成长方向
## 性格在收服时决定，无法更改 → 每只精灵都是独一无二的

# ========== 8种性格定义 ==========
# boost: 加成属性 key (hp/atk/def/spd/skillDmg/critRate/dmgResist/all)
# boostRate: 加成比例
# nerf: 减弱属性 key（null 表示无减弱）
# nerfRate: 减弱比例
const NATURES: Dictionary = {
	"brave": {
		"id": "brave",
		"name": "勇敢",
		"emoji": "⚔️",
		"desc": "勇往直前，攻击更强但略显莽撞",
		"boost": "atk",
		"boostRate": 0.10,
		"nerf": "spd",
		"nerfRate": 0.05
	},
	"cautious": {
		"id": "cautious",
		"name": "谨慎",
		"emoji": "🛡️",
		"desc": "防御至上，坚若磐石",
		"boost": "def",
		"boostRate": 0.10,
		"nerf": "atk",
		"nerfRate": 0.05
	},
	"agile": {
		"id": "agile",
		"name": "敏捷",
		"emoji": "💨",
		"desc": "速度就是一切",
		"boost": "spd",
		"boostRate": 0.10,
		"nerf": "def",
		"nerfRate": 0.05
	},
	"wise": {
		"id": "wise",
		"name": "智慧",
		"emoji": "📖",
		"desc": "技能大师",
		"boost": "skillDmg",
		"boostRate": 0.15,
		"nerf": "atk",
		"nerfRate": 0.05
	},
	"gentle": {
		"id": "gentle",
		"name": "温和",
		"emoji": "💚",
		"desc": "生命力顽强",
		"boost": "hp",
		"boostRate": 0.10,
		"nerf": "atk",
		"nerfRate": 0.05
	},
	"fierce": {
		"id": "fierce",
		"name": "暴躁",
		"emoji": "🔥",
		"desc": "暴躁的打击更致命",
		"boost": "critRate",
		"boostRate": 0.08,
		"nerf": "def",
		"nerfRate": 0.05
	},
	"calm": {
		"id": "calm",
		"name": "冷静",
		"emoji": "❄️",
		"desc": "泰山崩于前而色不变",
		"boost": "dmgResist",
		"boostRate": 0.08,
		"nerf": "critRate",
		"nerfRate": 0.03
	},
	"chaos": {
		"id": "chaos",
		"name": "混沌",
		"emoji": "🌀",
		"desc": "均衡但平庸",
		"boost": "all",
		"boostRate": 0.03,
		"nerf": "",        ## JS 原为 null，GDScript 用空字符串标记"无减弱"
		"nerfRate": 0.0
	}
}


# ========== 辅助函数 ==========

## 随机获取一个性格ID（JS: randomNature）
## 注意：调用方需确保在此之前执行过 randomize() 或场景已自动随机种子
static func random_nature() -> String:
	var ids: Array = NATURES.keys()
	return ids[randi() % ids.size()]

## 获取性格数据，未找到返回空字典（JS: getNature → null，GDScript 用空字典）
static func get_nature(nature_id: String) -> Dictionary:
	return NATURES.get(nature_id, {})

static func has_nature(nature_id: String) -> bool:
	return NATURES.has(nature_id)

## 计算性格对属性的修正倍率（JS: getNatureStatMultiplier）
## 返回值如 1.10 表示+10%，0.95 表示-5%
## statKey: "hp" / "atk" / "def" / "spd" 等
static func get_nature_stat_mult(nature_id: String, stat_key: String) -> float:
	var nature: Dictionary = NATURES.get(nature_id, {})
	if nature.is_empty():
		return 1.0

	var mult: float = 1.0

	# 加成判断
	var boost: String = nature.get("boost", "")
	if boost == "all" or boost == stat_key:
		mult += nature.get("boostRate", 0.0)

	# 减弱判断（空字符串表示无减弱，对应 JS 的 null）
	var nerf: String = nature.get("nerf", "")
	if nerf != "" and nerf == stat_key:
		mult -= nature.get("nerfRate", 0.0)

	return mult

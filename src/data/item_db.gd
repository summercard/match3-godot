# ============================================
# data/item_db.gd - 道具配置数据
# 翻译自 js/data/items.js
# ============================================
class_name ItemDB
extends RefCounted

# 道具数据库（16个道具）
const ITEMS_DB: Dictionary = {
	# ========== 捕获相关 ==========
	"capture_ball": {
		"id": "capture_ball",
		"name": "捕获球",
		"desc": "增加收服怪物的概率",
		"type": "capture",
		"emoji": "🔴",
		"rarity": 1,
		"effect": {
			"captureBonus": 0.15  # 收服概率增加15%
		}
	},
	"capture_ball_plus": {
		"id": "capture_ball_plus",
		"name": "超级捕获球",
		"desc": "大幅增加收服概率",
		"type": "capture",
		"emoji": "🟠",
		"rarity": 2,
		"effect": {
			"captureBonus": 0.30
		}
	},

	# ========== 经验/升级相关 ==========
	"exp_potion": {
		"id": "exp_potion",
		"name": "经验药水",
		"desc": "使用后获得100经验值",
		"type": "exp",
		"emoji": "💧",
		"rarity": 1,
		"effect": {
			"expGain": 100
		}
	},
	"exp_crystal": {
		"id": "exp_crystal",
		"name": "经验水晶",
		"desc": "使用后获得300经验值",
		"type": "exp",
		"emoji": "💎",
		"rarity": 2,
		"effect": {
			"expGain": 300
		}
	},

	# ========== 金币相关 ==========
	"gold_bag": {
		"id": "gold_bag",
		"name": "金币袋",
		"desc": "使用后获得50金币",
		"type": "gold",
		"emoji": "💰",
		"rarity": 1,
		"effect": {
			"goldGain": 50
		}
	},
	"gold_chest": {
		"id": "gold_chest",
		"name": "金币箱",
		"desc": "使用后获得200金币",
		"type": "gold",
		"emoji": "📦",
		"rarity": 2,
		"effect": {
			"goldGain": 200
		}
	},

	# ========== 战斗相关 ==========
	"hp_potion": {
		"id": "hp_potion",
		"name": "HP药水",
		"desc": "战斗中使用，恢复队伍50%最大生命值",
		"type": "battle",
		"emoji": "🧪",
		"rarity": 1,
		"effect": {
			"healRatio": 0.5
		}
	},

	# ========== 进化相关 ==========
	"evolution_stone_fire": {
		"id": "evolution_stone_fire",
		"name": "火之进化石",
		"desc": "小火龙进化所需",
		"type": "evolution",
		"emoji": "🔥",
		"rarity": 2,
		"forMonster": "monster_001"
	},
	"evolution_stone_water": {
		"id": "evolution_stone_water",
		"name": "水之进化石",
		"desc": "水龟仔进化所需",
		"type": "evolution",
		"emoji": "💧",
		"rarity": 2,
		"forMonster": "monster_002"
	},
	"evolution_stone_grass": {
		"id": "evolution_stone_grass",
		"name": "草之进化石",
		"desc": "草苗儿进化所需",
		"type": "evolution",
		"emoji": "🌿",
		"rarity": 2,
		"forMonster": "monster_003"
	},
	"evolution_stone_thunder": {
		"id": "evolution_stone_thunder",
		"name": "雷之进化石",
		"desc": "雷小鼠进化所需",
		"type": "evolution",
		"emoji": "⚡",
		"rarity": 2,
		"forMonster": "monster_004"
	},
	"evolution_stone_light": {
		"id": "evolution_stone_light",
		"name": "光之进化石",
		"desc": "光精灵进化所需",
		"type": "evolution",
		"emoji": "🌟",
		"rarity": 2,
		"forMonster": "monster_005"
	},
	"evolution_stone_earth": {
		"id": "evolution_stone_earth",
		"name": "土之进化石",
		"desc": "土属性怪物进化所需",
		"type": "evolution",
		"emoji": "🪨",
		"rarity": 2,
		"forElement": "earth"
	},
	"evolution_stone_wind": {
		"id": "evolution_stone_wind",
		"name": "风之进化石",
		"desc": "风属性怪物进化所需",
		"type": "evolution",
		"emoji": "🌪️",
		"rarity": 2,
		"forElement": "wind"
	},
	"evolution_stone_dark": {
		"id": "evolution_stone_dark",
		"name": "暗之进化石",
		"desc": "暗属性怪物进化所需",
		"type": "evolution",
		"emoji": "🌑",
		"rarity": 2,
		"forElement": "dark"
	}
}

# 随机掉落表（战斗胜利后可能获得的道具）
const DROP_TABLE: Array = [
	{"id": "capture_ball", "weight": 30},
	{"id": "exp_potion", "weight": 25},
	{"id": "gold_bag", "weight": 35},
	{"id": "capture_ball_plus", "weight": 5},
	{"id": "exp_crystal", "weight": 3},
	{"id": "gold_chest", "weight": 2},
	{"id": "evolution_stone_fire", "weight": 2},
	{"id": "evolution_stone_water", "weight": 2},
	{"id": "evolution_stone_grass", "weight": 2},
	{"id": "evolution_stone_thunder", "weight": 1},
	{"id": "evolution_stone_light", "weight": 1},
	{"id": "evolution_stone_earth", "weight": 1},
	{"id": "evolution_stone_wind", "weight": 1},
	{"id": "evolution_stone_dark", "weight": 1}
]

# 商店商品列表
const SHOP_ITEMS: Array = [
	{"id": "capture_ball", "price": 100, "currency": "gold", "label": "金币"},
	{"id": "capture_ball_plus", "price": 250, "currency": "gold", "label": "金币"},
	{"id": "exp_potion", "price": 80, "currency": "gold", "label": "金币"},
	{"id": "exp_crystal", "price": 200, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_fire", "price": 300, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_water", "price": 300, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_grass", "price": 300, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_thunder", "price": 350, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_light", "price": 400, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_earth", "price": 350, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_wind", "price": 350, "currency": "gold", "label": "金币"},
	{"id": "evolution_stone_dark", "price": 400, "currency": "gold", "label": "金币"}
]


# 根据权重随机抽取道具
static func roll_drop() -> String:
	# 累加总权重（替代 JS 的 reduce）
	var total_weight: float = 0.0
	for entry: Dictionary in DROP_TABLE:
		total_weight += entry["weight"]
	
	# 生成 0 ~ totalWeight 之间的随机数
	var rand_val: float = randf() * total_weight
	
	# 逐项减权重，rand_val <= 0 时命中
	for entry: Dictionary in DROP_TABLE:
		rand_val -= entry["weight"]
		if rand_val <= 0.0:
			return entry["id"]
	
	# 保底返回第一个道具
	return DROP_TABLE[0]["id"]

static func has_item(item_id: String) -> bool:
	return ITEMS_DB.has(item_id)

static func get_item(item_id: String) -> Dictionary:
	return ITEMS_DB.get(item_id, {})

static func get_shop_items() -> Array:
	return SHOP_ITEMS

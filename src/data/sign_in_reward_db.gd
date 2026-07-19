class_name SignInRewardDB
extends RefCounted

## 1.3.2 签到奖励的唯一规则源。界面和发奖服务都只读取此表。
const REWARD_SCHEDULE := [
	{"day": 1, "gold": 500, "exp": 0, "items": [], "monsters": [], "icon": "gold", "amount": "x500", "summary": "金币 x500"},
	{"day": 2, "gold": 0, "exp": 0, "items": [{"id": "exp_potion", "count": 200}], "monsters": [], "icon": "exp", "amount": "x200", "summary": "经验药水 x200"},
	{"day": 3, "gold": 0, "exp": 0, "items": [{"id": "evolution_stone_water", "count": 50}], "monsters": [], "icon": "water", "amount": "x50", "summary": "水之进化石 x50"},
	{"day": 4, "gold": 0, "exp": 0, "items": [{"id": "evolution_stone_fire", "count": 2}], "monsters": [], "icon": "fire", "amount": "x2", "summary": "火之进化石 x2"},
	{"day": 5, "gold": 0, "exp": 0, "items": [{"id": "hp_potion", "count": 1}], "monsters": [], "icon": "potion", "amount": "x1", "summary": "HP药水 x1"},
	{"day": 6, "gold": 0, "exp": 0, "items": [{"id": "evolution_stone_water", "count": 100}], "monsters": [], "icon": "water", "amount": "x100", "summary": "水之进化石 x100"},
	{"day": 7, "gold": 0, "exp": 0, "items": [], "monsters": [{"monsterId": "monster_049", "count": 1, "level": 1}], "icon": "monster_049", "amount": "肖肖蜥 x1", "summary": "Lv.1 肖肖蜥 x1"},
]


static func get_reward(day: int) -> Dictionary:
	var cycle_day := posmod(maxi(1, day) - 1, REWARD_SCHEDULE.size()) + 1
	return (REWARD_SCHEDULE[cycle_day - 1] as Dictionary).duplicate(true)


static func get_schedule() -> Array:
	return REWARD_SCHEDULE.duplicate(true)

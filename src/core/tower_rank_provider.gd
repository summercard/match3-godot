class_name TowerRankProvider
extends RefCounted

const TRAVELERS := [
	{"id": "traveler_iris", "name": "伊蕾", "offset": 7, "burst": 480},
	{"id": "traveler_moss", "name": "苔安", "offset": 3, "burst": 620},
	{"id": "traveler_nova", "name": "诺瓦", "offset": 13, "burst": 810},
	{"id": "traveler_rin", "name": "凛风", "offset": 19, "burst": 970},
	{"id": "traveler_lumen", "name": "流明", "offset": 26, "burst": 1160},
	{"id": "traveler_ash", "name": "烬羽", "offset": 35, "burst": 1380},
]


static func get_climb_entries(player_name: String, state: Dictionary) -> Array:
	var entries: Array = []
	var player_floor := int(state.get("highest_floor", 0))
	var player_turns := int(state.get("total_player_turns", 0))
	entries.append({"id": "player", "name": player_name, "is_player": true, "floor": player_floor, "turns": player_turns})
	for index in TRAVELERS.size():
		var traveler: Dictionary = TRAVELERS[index]
		var floor := clampi(player_floor + int(traveler.get("offset", 0)) - 18 + index * 3, 1, 99)
		entries.append({
			"id": traveler.get("id", ""), "name": traveler.get("name", "旅行者"), "is_player": false,
			"floor": floor, "turns": maxi(1, floor * 10 - index * 7)
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("floor", 0)) != int(b.get("floor", 0)):
			return int(a.get("floor", 0)) > int(b.get("floor", 0))
		return int(a.get("turns", 0)) < int(b.get("turns", 0))
	)
	for index in entries.size():
		entries[index]["rank"] = index + 1
	return entries


static func get_burst_entries(player_name: String, state: Dictionary) -> Array:
	var entries: Array = []
	var player_damage := int(state.get("highest_turn_damage", 0))
	entries.append({"id": "player", "name": player_name, "is_player": true, "damage": player_damage})
	for index in TRAVELERS.size():
		var traveler: Dictionary = TRAVELERS[index]
		entries.append({
			"id": traveler.get("id", ""), "name": traveler.get("name", "旅行者"), "is_player": false,
			"damage": maxi(10, int(traveler.get("burst", 0)) + player_damage / 4 - index * 37)
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("damage", 0)) > int(b.get("damage", 0))
	)
	for index in entries.size():
		entries[index]["rank"] = index + 1
	return entries

class_name BattlePowerRules
extends RefCounted


static func calc_battle_power(stats: Dictionary) -> int:
	return int(stats.get("hp", 0)) + int(stats.get("atk", 0)) + int(stats.get("def", 0))

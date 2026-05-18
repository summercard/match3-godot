class_name MonsterArtDB
extends RefCounted

const BATTLE_PORTRAITS := {
	"monster_001": "res://assets/images/battle/monsters/monster_001_fire_lizard.png",
	"monster_002": "res://assets/images/battle/monsters/monster_002_water_cub.png",
	"monster_003": "res://assets/images/battle/monsters/monster_003_grass_leaf.png",
	"monster_004": "res://assets/images/battle/monsters/monster_004_thunder_rodent.png",
	"monster_005": "res://assets/images/battle/monsters/monster_005_light_sprite.png",
	"monster_006": "res://assets/images/battle/monsters/monster_006_fire_dragon.png",
	"monster_007": "res://assets/images/battle/monsters/monster_007_water_dragon.png",
	"monster_017": "res://assets/images/battle/monsters/monster_017_dark_cat.png",
	"enemy_001": "res://assets/images/battle/monsters/monster_001_fire_lizard.png",
	"enemy_002": "res://assets/images/battle/monsters/monster_002_water_cub.png",
	"enemy_003": "res://assets/images/battle/monsters/monster_003_grass_leaf.png",
	"monster_boss_001": "res://assets/images/battle/monsters/monster_boss_001_grass_flower_512.png"
}

static func get_battle_portrait_path(monster_id: String) -> String:
	return BATTLE_PORTRAITS.get(monster_id, "")

static func has_battle_portrait(monster_id: String) -> bool:
	var path := get_battle_portrait_path(monster_id)
	return not path.is_empty() and ResourceLoader.exists(path)

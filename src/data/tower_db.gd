class_name TowerDB
extends RefCounted

## 共鸣塔配置只负责生成塔内关卡与卡牌，不接入主线 StageDB。

const MAX_FLOOR := 99
const STAGE_SIZE := 5
const UNLOCK_STAGE_ID := "stage_5_12"
const UNLOCK_HINT := "未解锁：击败第 5 章最终 Boss 后开放"
const START_ENEMY_LEVEL := 50

const NORMAL_ENEMY_SETS := [
	["monster_001", "monster_002", "monster_003"],
	["monster_004", "monster_005", "monster_006"],
	["monster_007", "monster_008", "monster_009"],
	["monster_010", "monster_011", "monster_012"],
	["monster_003", "monster_006", "monster_013"],
]

const STAGE_THEMES := [
	"风铃原野", "静水回廊", "羽叶密林", "热砂遗迹", "雷鸣孤岛",
	"霜镜高原", "虚空地窟", "时隙熔脉", "星辉神殿", "混沌阶庭",
	"辉光终章",
]

const CARD_LIBRARY := [
	{
		"id": "healing_bloom", "kind": "supply", "name": "生机花苞",
		"desc": "全队立刻回复 32% 最大生命。", "heal_ratio": 0.32,
		"rarity": "common"
	},
	{
		"id": "focus_spark", "kind": "supply", "name": "聚焦星尘",
		"desc": "所有精灵获得 2 点技能充能。", "charge_gain": 2,
		"rarity": "common"
	},
	{
		"id": "strike_resonance", "kind": "resonance", "name": "强攻共鸣",
		"desc": "本次远征中，我方造成的伤害提高 18%。", "damage_bonus": 0.18,
		"rarity": "uncommon", "max_stacks": 3
	},
	{
		"id": "ward_prayer", "kind": "resonance", "name": "守护祷言",
		"desc": "本次远征中，敌方造成的伤害降低 14%。", "enemy_damage_reduction": 0.14,
		"rarity": "uncommon", "max_stacks": 3
	},
	{
		"id": "resonant_charge", "kind": "resonance", "name": "澎湃回响",
		"desc": "本次远征中，每次消除额外获得 1 点技能充能。", "bonus_charge_per_match": 1,
		"rarity": "rare", "unique": true
	},
	{
		"id": "hazard_pact", "kind": "pact", "name": "锋芒契约",
		"desc": "伤害提高 34%，但立刻失去 12% 当前生命。", "damage_bonus": 0.34,
		"current_hp_loss": 0.12, "rarity": "rare", "unique": true
	},
]


static func is_valid_floor(floor: int) -> bool:
	return floor >= 1 and floor <= MAX_FLOOR


static func unlock_hint() -> String:
	return UNLOCK_HINT


static func is_boss_floor(floor: int) -> bool:
	return is_valid_floor(floor) and (floor % STAGE_SIZE == 0 or floor == MAX_FLOOR)


static func stage_index_for_floor(floor: int) -> int:
	if floor <= 0:
		return 1
	return int(ceili(float(mini(floor, MAX_FLOOR)) / float(STAGE_SIZE)))


static func wave_in_stage(floor: int) -> int:
	if floor == MAX_FLOOR:
		return 4
	var wave := floor % STAGE_SIZE
	return STAGE_SIZE if wave == 0 else wave


static func stage_wave_count(stage_index: int) -> int:
	return 4 if stage_index_for_floor(MAX_FLOOR) == stage_index else STAGE_SIZE


static func get_floor(floor: int) -> Dictionary:
	if not is_valid_floor(floor):
		return {}
	var stage_index := stage_index_for_floor(floor)
	var boss := is_boss_floor(floor)
	var enemy_level := START_ENEMY_LEVEL + int(floor - 1) + int(floor / 10) * 2
	var enemy_ids := _boss_enemy_set(stage_index) if boss else _normal_enemy_set(floor)
	var theme: String = str(STAGE_THEMES[(stage_index - 1) % STAGE_THEMES.size()])
	return {
		"id": "tower_floor_%03d" % floor,
		"name": "共鸣塔 %d 层" % floor,
		"type": "tower_boss" if boss else "tower_normal",
		"mode": "tower",
		"towerFloor": floor,
		"towerStage": stage_index,
		"towerWave": wave_in_stage(floor),
		"towerWaveCount": stage_wave_count(stage_index),
		"towerTheme": theme,
		"isBoss": boss,
		"enemies": enemy_ids,
		"enemyLevel": enemy_level,
		"maxTurns": 34 + int(floor / 10) * 2 + (10 if boss else 0),
		"disableCapture": true,
		"disableRandomElite": true,
		"rewards": {},
		"battleHint": "%s · 第 %d/%d 波" % [theme, wave_in_stage(floor), stage_wave_count(stage_index)],
	}


static func get_stage_reward(floor: int) -> Dictionary:
	if not is_boss_floor(floor):
		return {}
	var stage_index := stage_index_for_floor(floor)
	return {
		"gold": 180 + stage_index * 35,
		"shared_exp": 90 + stage_index * 28,
		"item_id": "hp_potion" if stage_index % 3 != 0 else "capture_ball",
		"item_count": 1,
	}


static func get_card(card_id: String) -> Dictionary:
	for raw_card: Dictionary in CARD_LIBRARY:
		if str(raw_card.get("id", "")) == card_id:
			return raw_card.duplicate(true)
	return {}


static func get_card_candidates(floor: int, seed: int) -> Array:
	var candidates: Array = []
	if not is_boss_floor(floor):
		return candidates
	var offset := posmod(seed + floor * 11 + stage_index_for_floor(floor) * 7, CARD_LIBRARY.size())
	for index in range(CARD_LIBRARY.size()):
		var card: Dictionary = CARD_LIBRARY[(offset + index) % CARD_LIBRARY.size()]
		if not _can_offer_card(card, candidates):
			continue
		candidates.append(card.duplicate(true))
		if candidates.size() >= 3:
			break
	return candidates


static func _normal_enemy_set(floor: int) -> Array:
	return NORMAL_ENEMY_SETS[(floor - 1) % NORMAL_ENEMY_SETS.size()].duplicate()


static func _boss_enemy_set(stage_index: int) -> Array:
	var boss_id := "monster_boss_%03d" % (1 + posmod(stage_index - 1, 8))
	var adds: Array = NORMAL_ENEMY_SETS[(stage_index - 1) % NORMAL_ENEMY_SETS.size()]
	return [boss_id, str(adds[0]), str(adds[1])]


static func _can_offer_card(card: Dictionary, selected: Array) -> bool:
	var card_id := str(card.get("id", ""))
	for selected_card: Dictionary in selected:
		if str(selected_card.get("id", "")) == card_id:
			return false
	return true

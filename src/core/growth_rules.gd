class_name GrowthRules
extends RefCounted

const CATCHUP_TRIGGER_GAP: int = 2
const CATCHUP_STEP_BONUS: float = 0.25
const CATCHUP_MAX_MULTIPLIER: float = 2.0
const EXP_LATE_GROWTH_START_LEVEL: int = 30


## Lv30 前维持原有线性节奏；Lv31 起追加二次项，抑制后期挂机经验的放大效应。
## level 表示当前等级，返回从 level 升到 level + 1 所需的经验。
static func get_exp_for_level(level: int) -> int:
	var safe_level := maxi(1, level)
	var late_level := maxi(0, safe_level - EXP_LATE_GROWTH_START_LEVEL)
	return 80 + safe_level * 10 + late_level * late_level


static func get_total_exp_for_level(level: int) -> int:
	var total := 0
	for current_level in range(1, maxi(1, level)):
		total += get_exp_for_level(current_level)
	return total


static func calc_catchup_multiplier(monster_level: int, reference_level: int) -> float:
	var gap := maxi(0, reference_level - monster_level)
	if gap < CATCHUP_TRIGGER_GAP:
		return 1.0
	return minf(CATCHUP_MAX_MULTIPLIER, 1.0 + float(gap - 1) * CATCHUP_STEP_BONUS)


static func calc_catchup_exp(base_exp: int, monster_level: int, reference_level: int) -> int:
	var multiplier := calc_catchup_multiplier(monster_level, reference_level)
	return maxi(0, int(round(float(base_exp) * multiplier)))


static func get_catchup_state(monster_level: int, reference_level: int) -> Dictionary:
	var multiplier := calc_catchup_multiplier(monster_level, reference_level)
	var gap := maxi(0, reference_level - monster_level)
	return {
		"enabled": multiplier > 1.0,
		"gap": gap,
		"multiplier": multiplier,
		"label": "追赶 x%.1f" % multiplier if multiplier > 1.0 else ""
	}

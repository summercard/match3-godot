class_name GrowthRules
extends RefCounted

const CATCHUP_TRIGGER_GAP: int = 2
const CATCHUP_STEP_BONUS: float = 0.25
const CATCHUP_MAX_MULTIPLIER: float = 2.0


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

class_name RanchCareRules
extends RefCounted

const BASE_IDLE_EXP: float = 5.0
const COMPANION_BONUS_PER_PARTNER: float = 0.15
const COMPANION_BONUS_MAX: float = 0.45
const NATURE_IDLE_MULTIPLIERS := {
	"brave": 1.06,
	"cautious": 1.08,
	"agile": 1.10,
	"wise": 1.15,
	"gentle": 1.12,
	"fierce": 1.05,
	"calm": 1.09,
	"chaos": 1.13,
}


static func calc_base_rate(level: int) -> float:
	return BASE_IDLE_EXP + float(maxi(1, level))


static func calc_nature_multiplier(nature_id: String) -> float:
	return float(NATURE_IDLE_MULTIPLIERS.get(nature_id, 1.0))


static func calc_companion_multiplier(occupied_count: int) -> float:
	var partners := maxi(0, occupied_count - 1)
	var bonus := minf(COMPANION_BONUS_MAX, float(partners) * COMPANION_BONUS_PER_PARTNER)
	return 1.0 + bonus


static func calc_state(monster_level: int, reference_level: int, occupied_count: int, is_focus: bool, nature_id: String = "") -> Dictionary:
	var base_rate := calc_base_rate(monster_level)
	var nature_mult := calc_nature_multiplier(nature_id)
	var companion_mult := calc_companion_multiplier(occupied_count)
	var catchup_state := GrowthRules.get_catchup_state(monster_level, reference_level)
	var catchup_mult := float(catchup_state.get("multiplier", 1.0)) if is_focus else 1.0
	var total_mult := nature_mult * companion_mult * catchup_mult
	var rate := base_rate * total_mult
	return {
		"baseRate": base_rate,
		"rate": rate,
		"occupiedCount": occupied_count,
		"isFocus": is_focus,
		"nature": nature_id,
		"natureMultiplier": nature_mult,
		"companionMultiplier": companion_mult,
		"companionLabel": companion_label(occupied_count),
		"catchup": catchup_state if is_focus else GrowthRules.get_catchup_state(monster_level, monster_level),
		"catchupMultiplier": catchup_mult,
		"totalMultiplier": total_mult,
		"label": build_label(is_focus, companion_mult, catchup_mult)
	}


static func companion_label(occupied_count: int) -> String:
	var mult := calc_companion_multiplier(occupied_count)
	if mult <= 1.0:
		return ""
	return "陪伴 +%d%%" % int(round((mult - 1.0) * 100.0))


static func build_label(is_focus: bool, companion_mult: float, catchup_mult: float) -> String:
	var parts: Array = []
	if is_focus:
		parts.append("专注")
	if catchup_mult > 1.0:
		parts.append("追赶 x%.1f" % catchup_mult)
	if companion_mult > 1.0:
		parts.append("陪伴 +%d%%" % int(round((companion_mult - 1.0) * 100.0)))
	return " ".join(parts)

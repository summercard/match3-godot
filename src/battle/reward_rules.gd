class_name RewardRules
extends RefCounted

const STAR_MULTIPLIERS := {
	1: 0.6,
	2: 0.8,
	3: 1.0
}
const LOSS_REWARD_MULTIPLIER: float = 0.3
const SWEEP_REWARD_MULTIPLIER: float = 0.8
const DEFAULT_STAGE_REWARDS := {
	"gold": 100,
	"exp": 100
}


static func calc_hp_ratio(player_team: Array) -> float:
	var alive_hp: float = 0.0
	var max_hp: float = 0.0
	for monster: Dictionary in player_team:
		if monster:
			alive_hp += float(monster.get("hp", 0))
			max_hp += float(monster.get("maxHP", monster.get("max_hp", 0)))
	return clampf(alive_hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0


static func calc_battle_stars(turn_count: int, max_turns: int, player_hp_ratio: float) -> int:
	var turn_score := 1.0 - (float(maxi(turn_count, 0)) / float(maxi(max_turns, 1)))
	var total := clampf(player_hp_ratio, 0.0, 1.0) * 0.6 + clampf(turn_score, 0.0, 1.0) * 0.4
	if total >= 0.8:
		return 3
	if total >= 0.5:
		return 2
	return 1


static func get_star_multiplier(stars: int) -> float:
	return float(STAR_MULTIPLIERS.get(clampi(stars, 1, 3), 1.0))


static func normalize_stage_rewards(stage_rewards: Dictionary) -> Dictionary:
	var rewards := stage_rewards.duplicate(true)
	if int(rewards.get("gold", 0)) <= 0 and int(rewards.get("exp", 0)) <= 0:
		rewards["gold"] = DEFAULT_STAGE_REWARDS["gold"]
		rewards["exp"] = DEFAULT_STAGE_REWARDS["exp"]
	return rewards


static func calc_battle_rewards(stage_rewards: Dictionary, stars: int, is_win: bool) -> Dictionary:
	var rewards := normalize_stage_rewards(stage_rewards)
	var base_gold := int(rewards.get("gold", DEFAULT_STAGE_REWARDS["gold"]))
	var base_exp := int(rewards.get("exp", DEFAULT_STAGE_REWARDS["exp"]))
	var multiplier := get_star_multiplier(stars) if is_win else LOSS_REWARD_MULTIPLIER
	return {
		"gold": maxi(0, int(round(base_gold * multiplier))),
		"exp": maxi(0, int(round(base_exp * multiplier)))
	}


static func calc_monster_exp(stage_rewards: Dictionary, stars: int, is_win: bool) -> int:
	if not is_win:
		return 0
	return int(calc_battle_rewards(stage_rewards, stars, true).get("exp", 0))


static func calc_sweep_rewards(stage_rewards: Dictionary, stars: int) -> Dictionary:
	var battle_rewards := calc_battle_rewards(stage_rewards, stars, true)
	return {
		"gold": maxi(1, int(round(int(battle_rewards.get("gold", 0)) * SWEEP_REWARD_MULTIPLIER))),
		"exp": maxi(1, int(round(int(battle_rewards.get("exp", 0)) * SWEEP_REWARD_MULTIPLIER)))
	}


static func get_guaranteed_items(stage_rewards: Dictionary) -> Array:
	return stage_rewards.get("guaranteedItems", [])


static func get_first_guaranteed_item(stage_rewards: Dictionary) -> Dictionary:
	var guaranteed_items: Array = get_guaranteed_items(stage_rewards)
	if guaranteed_items.is_empty():
		return {}
	return guaranteed_items[0]

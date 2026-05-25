class_name BattleFlowController
extends RefCounted

static func should_end_battle(battle) -> bool:
	return battle != null and battle.check_battle_end()

static func enemy_turn_end_state(battle) -> Dictionary:
	if battle != null and battle.battle_over:
		return {"state": "battle_end", "message": "战斗结束"}
	return {"state": "idle", "message": "你的回合"}

static func build_result_payload(battle, capture_state: Dictionary) -> Dictionary:
	var result: Dictionary = battle.get_battle_result() if battle != null else {"result": "win"}
	result["capture_played_inline"] = true
	result["captured"] = capture_state.get("success", false)
	result["capture_target"] = capture_state.get("target", {})
	result["capture_result_text"] = capture_state.get("result_text", {})
	result["capture_item_used"] = capture_state.get("item_used", {})
	result["capture_window"] = capture_state.get("window", {})
	return result

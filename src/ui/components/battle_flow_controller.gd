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
	result["capture_target"] = _build_capture_target(capture_state.get("target", {}), result)
	result["capture_result_text"] = capture_state.get("result_text", {})
	result["capture_item_used"] = capture_state.get("item_used", {})
	result["capture_window"] = capture_state.get("window", {})
	return result

static func _build_capture_target(value: Variant, battle_result: Dictionary) -> Dictionary:
	var target: Dictionary = value.duplicate(true) if value is Dictionary else {}
	if target.is_empty():
		return target
	var target_id := str(target.get("monsterId", target.get("id", "")))
	for value_enemy: Variant in battle_result.get("enemies", []):
		if not value_enemy is Dictionary:
			continue
		var enemy: Dictionary = value_enemy
		var enemy_id := str(enemy.get("monsterId", enemy.get("id", "")))
		if enemy_id != target_id:
			continue
		for key in ["level", "nature", "isElite"]:
			if not target.has(key) or (key == "nature" and str(target.get(key, "")).is_empty()):
				target[key] = enemy.get(key)
		break
	if not target.has("level"):
		target["level"] = int(battle_result.get("enemyLevel", battle_result.get("enemy_level", 1)))
	return target

## 主动技能执行器。
## BattleManager 保留战斗状态和公开入口；本类只处理主动技能的效果分派与结算。
class_name ActiveSkillExecutor
extends RefCounted

const SkillTypeTableScript := preload("res://src/data/skill_type_table.gd")

var battle_manager = null


func _init(manager = null) -> void:
	battle_manager = manager


func execute(monster_id: String) -> Dictionary:
	if battle_manager == null:
		return {"success": false, "reason": "missing_battle_manager"}
	if battle_manager.battle_over:
		return {"success": false, "reason": "battle_over"}

	var monster: Dictionary = battle_manager.call("_get_player_monster", monster_id)
	if monster.is_empty():
		return {"success": false, "reason": "monster_unavailable"}
	if int(monster.get("hp", 0)) <= 0:
		return {"success": false, "reason": "dead"}

	var skill: Dictionary = MonsterDb.normalize_skill(monster.get("skill", {}))
	if skill.is_empty():
		return {"success": false, "reason": "no_skill"}
	var cost := int(skill.get("cost", 999))
	var charge := int(battle_manager.skill_charges.get(monster_id, 0))
	if charge < cost:
		return {"success": false, "reason": "not_ready", "charge": charge, "cost": cost}

	var state := {
		"monster": monster,
		"skill": skill,
		"element": str(battle_manager.call("_fantasy_element", monster)),
		"board_affinity": str(battle_manager.call("_board_affinity", monster)),
		"target": battle_manager.call("_get_weakest_enemy"),
		"total_damage": 0,
		"remaining_damage": 0,
		"shield_absorbed": 0,
		"element_mult": 1.0,
		"effect_logs": [],
		"acted": false,
		"last_ally": {},
	}
	state["target_idx"] = battle_manager.enemies.find(state["target"]) if state["target"] != null else -1
	for raw_effect in skill.get("effects", []):
		if raw_effect is Dictionary:
			_apply_effect(state, raw_effect)
	if not bool(state["acted"]):
		return {"success": false, "reason": "no_valid_effect"}

	battle_manager.skill_charges[monster_id] = maxi(0, charge - cost)
	if int(state["remaining_damage"]) > 0:
		battle_manager.total_damage_dealt[monster_id] = int(battle_manager.total_damage_dealt.get(monster_id, 0)) + int(state["remaining_damage"])
		battle_manager.call("_record_player_turn_damage", int(state["remaining_damage"]))
	var target: Variant = state["target"]
	var result := {
		"success": true, "type": "active_skill", "skill_type": str(skill.get("type", "strike")), "skillType": str(skill.get("type", "strike")),
		"attacker": monster.get("name", ""), "attacker_id": monster_id, "attackerId": monster_id, "attacker_emoji": monster.get("emoji", ""),
		"skill": skill.duplicate(true), "skill_name": skill.get("name", "技能"), "skillName": skill.get("name", "技能"),
		"target": target.get("name", "") if target != null else "", "target_emoji": target.get("emoji", "") if target != null else "",
		"target_index": int(state["target_idx"]), "targetIndex": int(state["target_idx"]),
		"damage": int(state["total_damage"]), "remaining_damage": int(state["remaining_damage"]), "remainingDamage": int(state["remaining_damage"]),
		"shield_absorbed": int(state["shield_absorbed"]), "shieldAbsorbed": int(state["shield_absorbed"]),
		"element": str(state["element"]), "boardAffinity": str(state["board_affinity"]),
		"is_effective": float(state["element_mult"]) > 1.0, "isEffective": float(state["element_mult"]) > 1.0,
		"is_weak": float(state["element_mult"]) < 1.0, "isWeak": float(state["element_mult"]) < 1.0,
		"target_died": target != null and int(target.get("hp", 0)) <= 0, "targetDied": target != null and int(target.get("hp", 0)) <= 0,
		"effect_logs": state["effect_logs"], "effectLogs": state["effect_logs"], "battle_ended": false, "battleEnded": false,
	}
	battle_manager.damage_dealt.emit(result)
	if bool(battle_manager.call("check_battle_end")):
		result["battle_ended"] = true
		result["battleEnded"] = true
	return result


func _apply_effect(state: Dictionary, effect: Dictionary) -> void:
	var profile := SkillTypeTableScript.get_active_effect(str(effect.get("kind", "damage")))
	var handler := str(profile.get("handler", ""))
	if handler.is_empty() or not has_method(handler):
		push_warning("Unsupported active skill effect: %s" % str(effect.get("kind", "")))
		return
	call(handler, state, effect)


func _apply_damage(state: Dictionary, effect: Dictionary) -> void:
	var target: Variant = state["target"]
	var target_idx: int = int(state["target_idx"])
	if target == null or target_idx < 0:
		return
	var element: String = str(state["element"])
	var monster: Dictionary = state["monster"]
	var element_mult: float = MonsterDb.get_element_multiplier(element, target.get("element", ""))
	var boost: float = LeaderSkillDb.get_leader_atk_boost(battle_manager.leader_skill_data, element)
	var synergy: float = float(battle_manager.call("get_synergy_atk_mult", state["board_affinity"]))
	var damage: int = int(battle_manager._damage_calc.calc_player_damage(monster.get("atk", 10), element, target.get("def", 0), 3, 1, element_mult, boost, synergy))
	damage = maxi(1, int(round(float(damage) * float(effect.get("multiplier", state["skill"].get("multiplier", 1.0))))))
	damage = int(battle_manager.call("_apply_tower_player_damage", damage))
	damage = int(battle_manager.call("_apply_enemy_vulnerability_damage", damage, target_idx))
	var remaining: int = damage
	var absorbed: int = 0
	if battle_manager._enemy_skill_system != null:
		var shield_result: Dictionary = battle_manager._enemy_skill_system.execute_shield_before_damage(target_idx, damage)
		absorbed = int(shield_result.get("absorbed", 0))
		remaining = int(shield_result.get("remaining", 0))
		battle_manager._enemy_skill_system.get_skill_state(target_idx, "shield")
	target["hp"] = int(target.get("hp", 0)) - remaining
	battle_manager.call("_update_capture_window", target_idx)
	state["total_damage"] = int(state["total_damage"]) + damage
	state["remaining_damage"] = int(state["remaining_damage"]) + remaining
	state["shield_absorbed"] = int(state["shield_absorbed"]) + absorbed
	state["element_mult"] = element_mult
	state["acted"] = true
	(state["effect_logs"] as Array).append({"kind": "damage", "target": target.get("name", ""), "target_index": target_idx, "amount": damage, "remaining": remaining, "shield_absorbed": absorbed})


func _apply_heal(state: Dictionary, effect: Dictionary) -> void:
	var ally: Dictionary = battle_manager.call("_get_lowest_hp_ally")
	if ally.is_empty():
		return
	var amount := maxi(int(effect.get("min", 0)), int(round(float(ally.get("maxHP", 0)) * float(effect.get("ratio", 0.25)))))
	var previous := int(ally.get("hp", 0))
	ally["hp"] = mini(int(ally.get("maxHP", previous)), previous + amount)
	state["last_ally"] = ally
	state["acted"] = true
	(state["effect_logs"] as Array).append({"kind": "heal", "target": ally.get("name", ""), "target_id": ally.get("id", ""), "amount": int(ally.get("hp", 0)) - previous})


func _apply_guard(state: Dictionary, effect: Dictionary) -> void:
	var ally: Dictionary = state["last_ally"] if state["last_ally"] is Dictionary and not (state["last_ally"] as Dictionary).is_empty() else battle_manager.call("_get_lowest_hp_ally")
	if ally.is_empty():
		return
	var reduction := clampf(float(effect.get("reduction", 0.25)), 0.0, 0.8)
	var turns := maxi(1, int(effect.get("turns", 1)))
	battle_manager.call("_apply_player_guard", ally, reduction, turns)
	state["acted"] = true
	(state["effect_logs"] as Array).append({"kind": "guard", "target": ally.get("name", ""), "target_id": ally.get("id", ""), "reduction": reduction, "turns": turns})


func _apply_weaken(state: Dictionary, effect: Dictionary) -> void:
	var target: Variant = state["target"]
	var target_idx := int(state["target_idx"])
	if target == null or target_idx < 0:
		return
	var reduction := clampf(float(effect.get("reduction", 0.35)), 0.0, 0.8)
	var turns := maxi(1, int(effect.get("turns", 1)))
	battle_manager.call("_apply_enemy_tempo_mod", target_idx, reduction, turns)
	state["acted"] = true
	(state["effect_logs"] as Array).append({"kind": "weaken", "target": target.get("name", ""), "target_index": target_idx, "reduction": reduction, "turns": turns})

class_name LeaderSkillExecutor
extends RefCounted

var battle_manager = null


func _init(manager = null) -> void:
	battle_manager = manager


func execute_burst(leader: Dictionary, skill_data: Dictionary = {}) -> Dictionary:
	if battle_manager == null or leader.is_empty() or int(leader.get("hp", 0)) <= 0:
		return {}
	var element := str(battle_manager.call("_fantasy_element", leader))
	var log := {
		"type": "leader_burst",
		"element": element,
		"leader": str(leader.get("name", "")),
		"leader_id": str(leader.get("id", "")),
		"skill_id": str(skill_data.get("id", "")),
		"skill_name": str(skill_data.get("name", "")),
		"visual": skill_data.get("visual", {}).duplicate(true) if skill_data.get("visual", {}) is Dictionary else {},
		"effects": [],
		"battle_ended": false
	}
	var effects := LeaderSkillDb.get_burst_effects(skill_data, element)
	for effect in effects:
		if effect is Dictionary:
			_apply_effect(log, leader, effect)
	if bool(battle_manager.call("check_battle_end")):
		log["battle_ended"] = true
	return log


func _apply_effect(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	match str(effect.get("kind", "")):
		"damage":
			_damage_weakest(log, leader, effect)
		"heal":
			_heal_lowest(log, leader, effect)
		"lifesteal":
			_lifesteal_lowest(log, effect)
		"convert_gems":
			_convert_gems(log, effect)
		"guard":
			_guard_lowest(log, effect)
		"team_shield":
			_team_shield(log, leader, effect)
		"status":
			_status_weakest(log, leader, effect)
		"weaken":
			_weaken_weakest(log, effect)


func _damage_weakest(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var target = battle_manager.call("_get_weakest_enemy")
	if target == null:
		return
	var target_idx: int = battle_manager.enemies.find(target)
	var element := str(log.get("element", battle_manager.call("_fantasy_element", leader)))
	var element_mult := MonsterDb.get_element_multiplier(element, target.get("element", ""))
	var pierce := bool(effect.get("pierce", false))
	var target_def := 0 if pierce else int(target.get("def", 0))
	var damage: int = int(battle_manager._damage_calc.calc_player_damage(
		float(leader.get("atk", 10)),
		element,
		float(target_def),
		3,
		1,
		element_mult,
		1.0,
		float(battle_manager.call("get_synergy_atk_mult", battle_manager.call("_board_affinity", leader)))
	))
	damage = maxi(1, int(round(float(damage) * float(effect.get("multiplier", 1.0)))))
	var remaining: int = damage
	var absorbed := 0
	if battle_manager._enemy_skill_system != null and target_idx >= 0 and not pierce:
		var shield_result: Dictionary = battle_manager._enemy_skill_system.execute_shield_before_damage(target_idx, damage)
		absorbed = int(shield_result.get("absorbed", 0))
		remaining = int(shield_result.get("remaining", damage))
	target["hp"] = int(target.get("hp", 0)) - remaining
	battle_manager.call("_update_capture_window", target_idx)
	log["damage"] = int(log.get("damage", 0)) + damage
	log["remaining_damage"] = int(log.get("remaining_damage", 0)) + remaining
	log["target"] = str(target.get("name", ""))
	log["target_index"] = target_idx
	log["is_effective"] = element_mult > 1.0
	log["is_weak"] = element_mult < 1.0
	log["target_died"] = int(target.get("hp", 0)) <= 0
	log["effects"].append({
		"kind": "damage",
		"label": str(effect.get("label", "Leader Strike")),
		"target": str(target.get("name", "")),
		"target_index": target_idx,
		"amount": damage,
		"remaining": remaining,
		"shield_absorbed": absorbed,
		"pierce": pierce
	})


func _heal_lowest(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var ally: Dictionary = battle_manager.call("_get_lowest_hp_ally")
	if ally.is_empty():
		return
	var max_hp := maxi(1, int(ally.get("maxHP", 1)))
	var prev_hp := int(ally.get("hp", 0))
	var minimum := int(effect.get("minimum", round(float(leader.get("atk", 10)) * float(effect.get("minimumAtkMultiplier", 0.0)))))
	var amount := maxi(minimum, int(round(float(max_hp) * float(effect.get("ratio", 0.0)))))
	ally["hp"] = mini(max_hp, prev_hp + amount)
	var actual := int(ally.get("hp", 0)) - prev_hp
	log["effects"].append({
		"kind": "heal",
		"label": str(effect.get("label", "Leader Heal")),
		"target": str(ally.get("name", "")),
		"target_id": str(ally.get("id", "")),
		"target_index": int(battle_manager.call("_player_index_by_id", str(ally.get("id", "")))),
		"amount": actual
	})


func _lifesteal_lowest(log: Dictionary, effect: Dictionary) -> void:
	var ally: Dictionary = battle_manager.call("_get_lowest_hp_ally")
	if ally.is_empty():
		return
	var damage_done := int(log.get("remaining_damage", log.get("damage", 0)))
	if damage_done <= 0:
		return
	var max_hp := maxi(1, int(ally.get("maxHP", 1)))
	var prev_hp := int(ally.get("hp", 0))
	var amount := maxi(1, int(round(float(damage_done) * clampf(float(effect.get("ratio", 0.0)), 0.0, 2.0))))
	ally["hp"] = mini(max_hp, prev_hp + amount)
	var actual := int(ally.get("hp", 0)) - prev_hp
	log["effects"].append({
		"kind": "lifesteal",
		"label": str(effect.get("label", "Leader Lifesteal")),
		"target": str(ally.get("name", "")),
		"target_id": str(ally.get("id", "")),
		"target_index": int(battle_manager.call("_player_index_by_id", str(ally.get("id", "")))),
		"amount": actual,
		"source_damage": damage_done
	})


func _convert_gems(log: Dictionary, effect: Dictionary) -> void:
	log["effects"].append({
		"kind": "convert_gems",
		"label": str(effect.get("label", "Leader Convert")),
		"count": maxi(1, int(effect.get("count", 1))),
		"target_element": str(effect.get("target_element", log.get("element", "light")))
	})


func _guard_lowest(log: Dictionary, effect: Dictionary) -> void:
	var ally: Dictionary = battle_manager.call("_get_lowest_hp_ally")
	if ally.is_empty():
		return
	var reduction := clampf(float(effect.get("reduction", 0.25)), 0.0, 0.8)
	var turns := maxi(1, int(effect.get("turns", 1)))
	battle_manager.call("_apply_player_guard", ally, reduction, turns)
	log["effects"].append({
		"kind": "guard",
		"label": str(effect.get("label", "Leader Guard")),
		"target": str(ally.get("name", "")),
		"target_id": str(ally.get("id", "")),
		"target_index": int(battle_manager.call("_player_index_by_id", str(ally.get("id", "")))),
		"reduction": reduction,
		"turns": turns
	})


func _team_shield(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var ratio := clampf(float(effect.get("ratio", 0.20)), 0.0, 2.0)
	var turns := maxi(1, int(effect.get("turns", 2)))
	var leader_max_hp := maxi(1, int(leader.get("maxHP", leader.get("hp", 1))))
	var amount := maxi(1, int(round(float(leader_max_hp) * ratio)))
	var applied: Array = []
	for ally in battle_manager.player_team:
		if ally == null or int(ally.get("hp", 0)) <= 0:
			continue
		var ally_id := str(ally.get("id", ""))
		if ally_id.is_empty():
			continue
		var current: Dictionary = battle_manager.player_absorb_shields.get(ally_id, {})
		var current_hp := int(current.get("current_hp", current.get("hp", 0)))
		var shield_hp := maxi(current_hp, amount)
		battle_manager.player_absorb_shields[ally_id] = {
			"current_hp": shield_hp,
			"max_hp": shield_hp,
			"turns": turns,
			"source": str(leader.get("id", ""))
		}
		applied.append({
			"target": str(ally.get("name", "")),
			"target_id": ally_id,
			"target_index": int(battle_manager.call("_player_index_by_id", ally_id)),
			"amount": shield_hp
		})
	if applied.is_empty():
		return
	log["effects"].append({
		"kind": "team_shield",
		"label": str(effect.get("label", "Leader Shield")),
		"ratio": ratio,
		"amount": amount,
		"turns": turns,
		"targets": applied
	})


func _status_weakest(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var target = battle_manager.call("_get_weakest_enemy")
	if target == null:
		return
	var target_idx: int = battle_manager.enemies.find(target)
	var status_type := str(effect.get("status", "stun"))
	var status_log: Dictionary = battle_manager._status_effect.apply_status(target_idx, status_type, int(leader.get("atk", 10)), str(target.get("name", "")))
	if status_log.is_empty():
		return
	battle_manager.call("_refresh_capture_windows")
	log["effects"].append({
		"kind": "status",
		"status": status_type,
		"target": str(target.get("name", "")),
		"target_index": target_idx,
		"turns": maxi(1, int(effect.get("turns", 1))),
		"label": str(effect.get("label", "Leader Status"))
	})


func _weaken_weakest(log: Dictionary, effect: Dictionary) -> void:
	var target = battle_manager.call("_get_weakest_enemy")
	if target == null:
		return
	var target_idx: int = battle_manager.enemies.find(target)
	var reduction := clampf(float(effect.get("reduction", 0.35)), 0.0, 0.8)
	var turns := maxi(1, int(effect.get("turns", 1)))
	battle_manager.call("_apply_enemy_tempo_mod", target_idx, reduction, turns)
	battle_manager.call("_refresh_capture_windows")
	log["effects"].append({
		"kind": "weaken",
		"label": str(effect.get("label", "Leader Weaken")),
		"target": str(target.get("name", "")),
		"target_index": target_idx,
		"reduction": reduction,
		"turns": turns
	})

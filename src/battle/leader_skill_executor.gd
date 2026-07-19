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
		"heal_over_time":
			_heal_over_time(log, leader, effect)
		"heal_by_gem_count":
			_heal_by_gem_count(log, leader, effect)
		"lifesteal":
			_lifesteal_lowest(log, effect)
		"convert_gems":
			_convert_gems(log, effect)
		"convert_element_gems_by_ratio":
			_convert_element_gems_by_ratio(log, effect)
		"convert_adjacent_gems_from_random_source":
			_convert_adjacent_gems(log, effect)
		"shuffle_board":
			_shuffle_board(log, effect)
		"remove_random_element_gems":
			_remove_random_element_gems(log, effect)
		"clear_random_element_gems_damage_all":
			_clear_element_gems_damage_all(log, leader, effect)
		"clear_element_gems_damage_highest_hp":
			_clear_element_gems_damage_highest(log, leader, effect)
		"random_multi_hit":
			_random_multi_hit(log, leader, effect)
		"damage_per_living_element_unit":
			_damage_per_living_element_unit(log, leader, effect)
		"self_atk_boost":
			_self_atk_boost(log, leader, effect)
		"self_damage_reduction":
			_self_damage_reduction(log, leader, effect)
		"randomize_enemy_element":
			_randomize_enemy_element(log, effect)
		"grant_ally_charge":
			_grant_ally_charge(log, leader, effect)
		"reflect_damage":
			_reflect_damage(log, leader, effect)
		"enemy_damage_vulnerability":
			_enemy_damage_vulnerability(log, effect)
		"confuse_enemy_attack":
			_confuse_enemy_attack(log, effect)
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
	var damage_result: Dictionary = battle_manager.call("apply_direct_enemy_damage", target_idx, damage, pierce, str(leader.get("id", "")))
	var final_damage := int(damage_result.get("damage", damage))
	var remaining := int(damage_result.get("remaining", 0))
	var absorbed := int(damage_result.get("shield_absorbed", 0))
	log["damage"] = int(log.get("damage", 0)) + final_damage
	log["remaining_damage"] = int(log.get("remaining_damage", 0)) + remaining
	log["target"] = str(target.get("name", ""))
	log["target_index"] = target_idx
	log["is_effective"] = element_mult > 1.0
	log["is_weak"] = element_mult < 1.0
	log["target_died"] = bool(damage_result.get("target_died", int(target.get("hp", 0)) <= 0))
	log["effects"].append({
		"kind": "damage",
		"label": str(effect.get("label", "队长一击")),
		"target": str(target.get("name", "")),
		"target_index": target_idx,
		"amount": final_damage,
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
		"label": str(effect.get("label", "队长治愈")),
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
		"label": str(effect.get("label", "队长汲取")),
		"target": str(ally.get("name", "")),
		"target_id": str(ally.get("id", "")),
		"target_index": int(battle_manager.call("_player_index_by_id", str(ally.get("id", "")))),
		"amount": actual,
		"source_damage": damage_done
	})


func _convert_gems(log: Dictionary, effect: Dictionary) -> void:
	var target_element := _board_gem_type(str(effect.get("target_element", log.get("element", "light"))))
	var cells := _convert_random_cells(target_element, maxi(1, int(effect.get("count", 1))), maxi(0, int(effect.get("edge_layers", 0))))
	log["effects"].append({
		"kind": "convert_gems",
		"label": str(effect.get("label", "队长转化")),
		"count": cells.size(),
		"requested_count": maxi(1, int(effect.get("count", 1))),
		"target_element": target_element,
		"edge_layers": maxi(0, int(effect.get("edge_layers", 0))),
		"cells": cells,
	})


func _heal_over_time(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var leader_index: int = battle_manager.player_team.find(leader)
	if leader_index < 0:
		return
	var target_indices: Array = [leader_index]
	var mode := str(effect.get("target_mode", "self"))
	if mode == "all_allies":
		target_indices = _living_ally_indices()
	elif mode == "self_and_random_ally":
		var others := _living_ally_indices().filter(func(index): return int(index) != leader_index)
		others.shuffle()
		if not others.is_empty():
			target_indices.append(int(others[0]))
	var ratio := maxf(0.0, float(effect.get("ratio", 0.0)))
	var turns := maxi(1, int(effect.get("turns", 1)))
	var targets: Array = []
	for raw_index in target_indices:
		var index := int(raw_index)
		var ally: Dictionary = battle_manager.player_team[index]
		if int(ally.get("hp", 0)) <= 0:
			continue
		battle_manager.call("apply_leader_regeneration", str(ally.get("id", "")), ratio, turns)
		targets.append(_ally_target_log(ally, index))
	log["effects"].append({"kind": "heal_over_time", "label": str(effect.get("label", "持续治疗")), "ratio": ratio, "turns": turns, "target_mode": mode, "targets": targets})


func _heal_by_gem_count(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var source_element := _board_gem_type(str(effect.get("source_element", log.get("element", "grass"))))
	var source_count := _gem_count(source_element)
	var amount := maxi(0, int(floor(float(leader.get("maxHP", 1)) * maxf(0.0, float(effect.get("ratio", 0.0))) * float(source_count))))
	var target_count := maxi(1, int(effect.get("target_count", 1)))
	for index in _lowest_hp_ally_indices(target_count):
		var ally: Dictionary = battle_manager.player_team[index]
		var before := int(ally.get("hp", 0))
		ally["hp"] = mini(int(ally.get("maxHP", before)), before + amount)
		log["effects"].append({
			"kind": "heal", "trigger_kind": "heal_by_gem_count", "label": str(effect.get("label", "元素滋养")),
			"target": str(ally.get("name", "")), "target_id": str(ally.get("id", "")), "target_index": index,
			"amount": int(ally.get("hp", 0)) - before, "raw_amount": amount,
			"source_element": source_element, "source_count": source_count,
		})


func _convert_element_gems_by_ratio(log: Dictionary, effect: Dictionary) -> void:
	var source := _board_gem_type(str(effect.get("source_element", "water")))
	var target := _board_gem_type(str(effect.get("target_element", log.get("element", "fire"))))
	var candidates := _board_cells_for_type(source)
	candidates.shuffle()
	var count := int(floor(float(candidates.size()) * clampf(float(effect.get("ratio", 0.0)), 0.0, 1.0)))
	var cells := _set_cells_to_type(candidates.slice(0, count), target)
	log["effects"].append({"kind": "convert_element_gems_by_ratio", "label": str(effect.get("label", "元素转化")), "source_element": source, "target_element": target, "ratio": float(effect.get("ratio", 0.0)), "source_count": candidates.size(), "count": cells.size(), "cells": cells})


func _convert_adjacent_gems(log: Dictionary, effect: Dictionary) -> void:
	var source := _board_gem_type(str(effect.get("source_element", "water")))
	var target := _board_gem_type(str(effect.get("target_element", source)))
	var anchors := _board_cells_for_type(source)
	anchors.shuffle()
	anchors = anchors.slice(0, mini(anchors.size(), maxi(1, int(effect.get("count", 1)))))
	var seen: Dictionary = {}
	var adjacent: Array = []
	for anchor: Dictionary in anchors:
		for direction in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
			var row := int(anchor["row"]) + int(direction[0])
			var col := int(anchor["col"]) + int(direction[1])
			if not _is_operable_cell(row, col) or str(battle_manager.board.grid[row][col]) == target:
				continue
			var key := "%d:%d" % [row, col]
			if not seen.has(key):
				seen[key] = true
				adjacent.append({"row": row, "col": col, "from": str(battle_manager.board.grid[row][col])})
	var cells := _set_cells_to_type(adjacent, target)
	log["effects"].append({"kind": "convert_adjacent_gems_from_random_source", "label": str(effect.get("label", "邻接转化")), "source_element": source, "target_element": target, "anchors": anchors, "count": anchors.size(), "cells": cells})


func _shuffle_board(log: Dictionary, effect: Dictionary) -> void:
	var result: Dictionary = {}
	if battle_manager.board != null and battle_manager.board.has_method("shuffle"):
		result = battle_manager.board.shuffle()
	log["effects"].append({"kind": "shuffle_board", "label": str(effect.get("label", "全盘洗牌")), "success": bool(result.get("success", false)), "attempts": int(result.get("attempts", 0)), "regenerated": bool(result.get("regenerated", false))})


func _remove_random_element_gems(log: Dictionary, effect: Dictionary) -> void:
	var target := _board_gem_type(str(effect.get("target_element", log.get("element", "wind"))))
	var candidates := _board_cells_for_type(target)
	candidates.shuffle()
	var requested := 0
	if bool(effect.get("clear_all", false)):
		requested = candidates.size()
	elif effect.has("count"):
		requested = mini(candidates.size(), maxi(0, int(effect.get("count", 0))))
	elif not candidates.is_empty():
		requested = randi_range(1, candidates.size())
	var cells := _clear_cells(candidates.slice(0, requested))
	log["effects"].append({"kind": "remove_random_element_gems", "label": str(effect.get("label", "元素剥离")), "target_element": target, "available": candidates.size(), "requested_count": requested, "count": cells.size(), "clear_all": bool(effect.get("clear_all", false)), "cells": cells})


func _clear_element_gems_damage_all(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var target_element := _board_gem_type(str(effect.get("target_element", log.get("element", "light"))))
	var candidates := _board_cells_for_type(target_element)
	candidates.shuffle()
	var requested := candidates.size() if bool(effect.get("clear_all", false)) else mini(candidates.size(), maxi(0, int(effect.get("count", 0))))
	var cells := _clear_cells(candidates.slice(0, requested))
	var hits: Array = []
	for index in range(battle_manager.enemies.size()):
		var enemy = battle_manager.enemies[index]
		if enemy == null or int(enemy.get("hp", 0)) <= 0:
			continue
		var result: Dictionary = battle_manager.call("apply_direct_enemy_damage", index, maxi(1, int(floor(float(leader.get("atk", 1)) * maxf(0.0, float(effect.get("ratio", 0.0)))))), false, str(leader.get("id", "")))
		if not result.is_empty():
			hits.append({"target": str(enemy.get("name", "")), "target_index": index, "amount": int(result.get("remaining", 0)), "target_died": bool(result.get("target_died", false))})
	_append_multi_damage_log(log, "clear_random_element_gems_damage_all", str(effect.get("label", "光耀裁决")), hits, {"target_element": target_element, "count": cells.size(), "cells": cells, "ratio": float(effect.get("ratio", 0.0))})


func _clear_element_gems_damage_highest(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var target_element := _board_gem_type(str(effect.get("target_element", log.get("element", "fire"))))
	var cells := _clear_cells(_board_cells_for_type(target_element))
	var target_index := _highest_hp_enemy_index()
	var amount := int(floor(float(leader.get("atk", 1)) * maxf(0.0, float(effect.get("ratio", 0.0))) * float(cells.size())))
	var hits: Array = []
	if target_index >= 0 and amount > 0:
		var enemy: Dictionary = battle_manager.enemies[target_index]
		var result: Dictionary = battle_manager.call("apply_direct_enemy_damage", target_index, amount, false, str(leader.get("id", "")))
		hits.append({"target": str(enemy.get("name", "")), "target_index": target_index, "amount": int(result.get("remaining", 0)), "target_died": bool(result.get("target_died", false))})
	_append_multi_damage_log(log, "clear_element_gems_damage_highest_hp", str(effect.get("label", "元素吞噬")), hits, {"target_element": target_element, "count": cells.size(), "cells": cells, "ratio": float(effect.get("ratio", 0.0))})


func _random_multi_hit(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var count := maxi(1, int(effect.get("count", 1)))
	var raw_damage := maxi(1, int(floor(float(leader.get("atk", 1)) * maxf(0.0, float(effect.get("ratio", 0.0))))))
	var hits: Array = []
	for hit_index in range(count):
		var living := _living_enemy_indices()
		if living.is_empty():
			break
		var target_index := int(living.pick_random())
		var enemy: Dictionary = battle_manager.enemies[target_index]
		var result: Dictionary = battle_manager.call("apply_direct_enemy_damage", target_index, raw_damage, false, str(leader.get("id", "")))
		hits.append({"target": str(enemy.get("name", "")), "target_index": target_index, "hit_index": hit_index, "amount": int(result.get("remaining", 0)), "target_died": bool(result.get("target_died", false))})
	_append_multi_damage_log(log, "random_multi_hit", str(effect.get("label", "随机连击")), hits, {"count": count, "executed_count": hits.size(), "ratio": float(effect.get("ratio", 0.0)), "raw_damage": raw_damage})


func _damage_per_living_element_unit(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var source := LeaderSkillDb.normalize_element(str(effect.get("source_element", log.get("element", "water"))))
	var count := 0
	for ally in battle_manager.player_team:
		if ally != null and int(ally.get("hp", 0)) > 0 and LeaderSkillDb.normalize_element(str(ally.get("element", ""))) == source:
			count += 1
	for enemy in battle_manager.enemies:
		if enemy != null and int(enemy.get("hp", 0)) > 0 and LeaderSkillDb.normalize_element(str(enemy.get("element", ""))) == source:
			count += 1
	var multi_effect := effect.duplicate(true)
	multi_effect["count"] = count
	_random_multi_hit(log, leader, multi_effect)
	if not log["effects"].is_empty():
		var last: Dictionary = log["effects"][log["effects"].size() - 1]
		last["trigger_kind"] = "damage_per_living_element_unit"
		last["source_element"] = source
		last["source_unit_count"] = count


func _self_atk_boost(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var before := maxi(1, int(leader.get("atk", 1)))
	leader["atk"] = maxi(1, int(round(float(before) * maxf(0.0, float(effect.get("multiplier", 1.0))))))
	log["effects"].append({"kind": "self_atk_boost", "label": str(effect.get("label", "蓄势强化")), "target": str(leader.get("name", "")), "target_id": str(leader.get("id", "")), "target_index": battle_manager.player_team.find(leader), "before": before, "after": int(leader.get("atk", before)), "amount": int(leader.get("atk", before)) - before})


func _self_damage_reduction(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var total := float(battle_manager.call("add_leader_damage_reduction", str(leader.get("id", "")), float(effect.get("reduction", 0.0))))
	log["effects"].append({"kind": "self_damage_reduction", "label": str(effect.get("label", "地脉护体")), "target": str(leader.get("name", "")), "target_id": str(leader.get("id", "")), "target_index": battle_manager.player_team.find(leader), "reduction": float(effect.get("reduction", 0.0)), "total_reduction": total})


func _randomize_enemy_element(log: Dictionary, effect: Dictionary) -> void:
	var living := _living_enemy_indices()
	living.shuffle()
	var count := living.size() if bool(effect.get("all_targets", false)) else mini(living.size(), maxi(1, int(effect.get("target_count", 1))))
	var targets: Array = []
	for raw_index in living.slice(0, count):
		var index := int(raw_index)
		var enemy: Dictionary = battle_manager.enemies[index]
		var previous := str(enemy.get("element", "fire"))
		var next := str(effect.get("target_element", ""))
		if next.is_empty():
			var candidates := ["fire", "water", "grass", "thunder", "light", "earth", "wind", "dark"].filter(func(element): return str(element) != previous)
			next = str(candidates.pick_random())
		enemy["element"] = next
		enemy["elementShifted"] = true
		targets.append({"target": str(enemy.get("name", "")), "target_index": index, "previous_element": previous, "new_element": next})
	log["effects"].append({"kind": "randomize_enemy_element", "label": str(effect.get("label", "属性轮转")), "count": targets.size(), "all_targets": bool(effect.get("all_targets", false)), "targets": targets})


func _grant_ally_charge(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var leader_index: int = battle_manager.player_team.find(leader)
	var candidates := _living_ally_indices().filter(func(index): return int(index) != leader_index)
	candidates.shuffle()
	var target_count := mini(candidates.size(), maxi(1, int(effect.get("target_count", 1))))
	var amount := maxi(1, int(effect.get("charge_amount", 1)))
	var targets: Array = []
	for raw_index in candidates.slice(0, target_count):
		var index := int(raw_index)
		var ally: Dictionary = battle_manager.player_team[index]
		var id := str(ally.get("id", ""))
		var before := int(battle_manager.leader_charge_points.get(id, 0))
		var after := mini(BattleManager.LEADER_CHARGE_MAX, before + amount)
		battle_manager.leader_charge_points[id] = after
		if after >= BattleManager.LEADER_CHARGE_MAX:
			battle_manager.call("_enqueue_leader_burst", id)
		var entry := _ally_target_log(ally, index)
		entry.merge({"before": before, "after": after, "amount": after - before}, true)
		targets.append(entry)
	log["effects"].append({"kind": "grant_ally_charge", "label": str(effect.get("label", "星辉引导")), "charge_amount": amount, "target_count": targets.size(), "targets": targets})


func _reflect_damage(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var indices := _living_ally_indices() if bool(effect.get("all_targets", false)) else [battle_manager.player_team.find(leader)]
	var ratio := maxf(0.0, float(effect.get("ratio", 0.3)))
	var turns := maxi(1, int(effect.get("turns", 2)))
	var targets: Array = []
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0:
			continue
		var ally: Dictionary = battle_manager.player_team[index]
		battle_manager.call("apply_leader_reflect", str(ally.get("id", "")), ratio, turns)
		targets.append(_ally_target_log(ally, index))
	log["effects"].append({"kind": "reflect_damage", "label": str(effect.get("label", "荆棘反射")), "ratio": ratio, "turns": turns, "all_targets": bool(effect.get("all_targets", false)), "targets": targets})


func _enemy_damage_vulnerability(log: Dictionary, effect: Dictionary) -> void:
	var multiplier := maxf(1.0, float(effect.get("multiplier", 1.0)))
	var turns := maxi(1, int(effect.get("turns", 1)))
	var targets: Array = []
	for index in _living_enemy_indices():
		battle_manager.call("apply_enemy_vulnerability", int(index), multiplier, turns)
		targets.append({"target": str(battle_manager.enemies[int(index)].get("name", "")), "target_index": int(index)})
	log["effects"].append({"kind": "enemy_damage_vulnerability", "label": str(effect.get("label", "易伤")), "multiplier": multiplier, "turns": turns, "targets": targets})


func _confuse_enemy_attack(log: Dictionary, effect: Dictionary) -> void:
	var living := _living_enemy_indices()
	if living.is_empty():
		return
	var index := int(living.pick_random())
	var chance := clampf(float(effect.get("ratio", 0.0)), 0.0, 1.0)
	var turns := maxi(1, int(effect.get("turns", 1)))
	battle_manager.call("apply_enemy_confusion", index, chance, turns)
	log["effects"].append({"kind": "confuse_enemy_attack", "label": str(effect.get("label", "迷乱")), "ratio": chance, "turns": turns, "targets": [{"target": str(battle_manager.enemies[index].get("name", "")), "target_index": index}]})


func _guard_lowest(log: Dictionary, effect: Dictionary) -> void:
	var ally: Dictionary = battle_manager.call("_get_lowest_hp_ally")
	if ally.is_empty():
		return
	var reduction := clampf(float(effect.get("reduction", 0.25)), 0.0, 0.8)
	var turns := maxi(1, int(effect.get("turns", 1)))
	battle_manager.call("_apply_player_guard", ally, reduction, turns)
	log["effects"].append({
		"kind": "guard",
		"label": str(effect.get("label", "队长守护")),
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
		"label": str(effect.get("label", "队长护盾")),
		"ratio": ratio,
		"amount": amount,
		"turns": turns,
		"targets": applied
	})


func _status_weakest(log: Dictionary, leader: Dictionary, effect: Dictionary) -> void:
	var status_type := str(effect.get("status", "stun"))
	var target_indices := _living_enemy_indices()
	if not bool(effect.get("all_targets", false)):
		if bool(effect.get("random_target", false)):
			target_indices = [] if target_indices.is_empty() else [int(target_indices.pick_random())]
		else:
			var target = battle_manager.call("_get_weakest_enemy")
			target_indices = [] if target == null else [battle_manager.enemies.find(target)]
	var targets: Array = []
	for raw_index in target_indices:
		var target_idx := int(raw_index)
		if target_idx < 0:
			continue
		var target: Dictionary = battle_manager.enemies[target_idx]
		var status_log: Dictionary = battle_manager._status_effect.apply_status(target_idx, status_type, int(leader.get("atk", 10)), str(target.get("name", "")), {
			"duration": int(effect.get("turns", 1)),
			"dot_mult": float(effect.get("ratio", 0.0)),
			"increment_per_turn": float(effect.get("increment_ratio", 0.0)),
		})
		if not status_log.is_empty():
			targets.append({"target": str(target.get("name", "")), "target_index": target_idx})
	if targets.is_empty():
		return
	battle_manager.call("_refresh_capture_windows")
	log["effects"].append({
		"kind": "status",
		"status": status_type,
		"target": str(targets[0].get("target", "")),
		"target_index": int(targets[0].get("target_index", -1)),
		"targets": targets,
		"all_targets": bool(effect.get("all_targets", false)),
		"random_target": bool(effect.get("random_target", false)),
		"turns": int(effect.get("turns", 1)),
		"ratio": float(effect.get("ratio", 0.0)),
		"increment_ratio": float(effect.get("increment_ratio", 0.0)),
		"label": str(effect.get("label", "队长状态"))
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
		"label": str(effect.get("label", "队长削弱")),
		"target": str(target.get("name", "")),
		"target_index": target_idx,
		"reduction": reduction,
		"turns": turns
	})


func _living_ally_indices() -> Array:
	var result: Array = []
	for index in range(battle_manager.player_team.size()):
		var ally = battle_manager.player_team[index]
		if ally != null and int(ally.get("hp", 0)) > 0:
			result.append(index)
	return result


func _living_enemy_indices() -> Array:
	var result: Array = []
	for index in range(battle_manager.enemies.size()):
		var enemy = battle_manager.enemies[index]
		if enemy != null and int(enemy.get("hp", 0)) > 0:
			result.append(index)
	return result


func _lowest_hp_ally_indices(count: int) -> Array:
	var indices := _living_ally_indices()
	indices.sort_custom(func(left, right):
		var a: Dictionary = battle_manager.player_team[int(left)]
		var b: Dictionary = battle_manager.player_team[int(right)]
		var a_ratio := float(a.get("hp", 0)) / float(maxi(1, int(a.get("maxHP", 1))))
		var b_ratio := float(b.get("hp", 0)) / float(maxi(1, int(b.get("maxHP", 1))))
		return a_ratio < b_ratio if not is_equal_approx(a_ratio, b_ratio) else int(left) < int(right)
	)
	return indices.slice(0, mini(indices.size(), maxi(0, count)))


func _highest_hp_enemy_index() -> int:
	var best := -1
	var best_hp := -1
	for index in _living_enemy_indices():
		var hp := int(battle_manager.enemies[int(index)].get("hp", 0))
		if hp > best_hp:
			best_hp = hp
			best = int(index)
	return best


func _ally_target_log(ally: Dictionary, index: int) -> Dictionary:
	return {"target": str(ally.get("name", "")), "target_id": str(ally.get("id", "")), "target_index": index}


func _append_multi_damage_log(log: Dictionary, kind: String, label: String, hits: Array, extra: Dictionary = {}) -> void:
	var total := 0
	for hit: Dictionary in hits:
		total += int(hit.get("amount", 0))
	log["damage"] = int(log.get("damage", 0)) + total
	log["remaining_damage"] = int(log.get("remaining_damage", 0)) + total
	if not hits.is_empty():
		var last: Dictionary = hits[hits.size() - 1]
		log["target"] = str(last.get("target", ""))
		log["target_index"] = int(last.get("target_index", -1))
		log["target_died"] = bool(last.get("target_died", false))
	var entry := {"kind": kind, "label": label, "amount": total, "hits": hits}
	entry.merge(extra, true)
	log["effects"].append(entry)


func _board_gem_type(element: String) -> String:
	match element:
		"fire", "chaos":
			return "fire"
		"water", "ice":
			return "water"
		"grass", "earth":
			return "grass"
		"thunder", "wind", "temporal":
			return "thunder"
		_:
			return "light"


func _is_operable_cell(row: int, col: int) -> bool:
	var current_board = battle_manager.board
	if current_board == null or row < 0 or row >= int(current_board.rows) or col < 0 or col >= int(current_board.cols):
		return false
	if current_board.is_blocked_cell(row, col) or not current_board.is_gem_playable(row, col):
		return false
	var gem := str(current_board.grid[row][col])
	return not gem.is_empty()


func _board_cells_for_type(gem_type: String) -> Array:
	var result: Array = []
	var current_board = battle_manager.board
	if current_board == null:
		return result
	for row in range(int(current_board.rows)):
		for col in range(int(current_board.cols)):
			if _is_operable_cell(row, col) and str(current_board.grid[row][col]) == gem_type:
				result.append({"row": row, "col": col, "from": gem_type})
	return result


func _gem_count(gem_type: String) -> int:
	return _board_cells_for_type(gem_type).size()


func _convert_random_cells(target: String, count: int, edge_layers: int = 0) -> Array:
	var candidates: Array = []
	var current_board = battle_manager.board
	if current_board == null:
		return candidates
	for row in range(int(current_board.rows)):
		for col in range(int(current_board.cols)):
			if not _is_operable_cell(row, col) or str(current_board.grid[row][col]) == target:
				continue
			if edge_layers > 0 and row >= edge_layers and row < int(current_board.rows) - edge_layers and col >= edge_layers and col < int(current_board.cols) - edge_layers:
				continue
			candidates.append({"row": row, "col": col, "from": str(current_board.grid[row][col])})
	candidates.shuffle()
	return _set_cells_to_type(candidates.slice(0, mini(candidates.size(), maxi(0, count))), target)


func _set_cells_to_type(cells: Array, target: String) -> Array:
	var changed: Array = []
	if battle_manager.board == null:
		return changed
	for raw_cell in cells:
		if not raw_cell is Dictionary:
			continue
		var cell: Dictionary = (raw_cell as Dictionary).duplicate(true)
		var row := int(cell.get("row", -1))
		var col := int(cell.get("col", -1))
		if not _is_operable_cell(row, col):
			continue
		cell["from"] = str(battle_manager.board.grid[row][col])
		battle_manager.board.grid[row][col] = target
		cell["to"] = target
		changed.append(cell)
	return changed


func _clear_cells(cells: Array) -> Array:
	var cleared: Array = []
	if battle_manager.board == null:
		return cleared
	for raw_cell in cells:
		if not raw_cell is Dictionary:
			continue
		var cell: Dictionary = (raw_cell as Dictionary).duplicate(true)
		var row := int(cell.get("row", -1))
		var col := int(cell.get("col", -1))
		if not _is_operable_cell(row, col):
			continue
		cell["from"] = str(battle_manager.board.grid[row][col])
		battle_manager.board.grid[row][col] = ""
		cleared.append(cell)
	if not cleared.is_empty() and battle_manager.board.has_method("apply_gravity"):
		battle_manager.board.apply_gravity()
	return cleared

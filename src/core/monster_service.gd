class_name MonsterService
extends RefCounted

const EcologyBondRulesScript = preload("res://src/core/ecology_bond_rules.gd")

static func get_template(monster_id: String) -> Dictionary:
	return MonsterDb.get_monster(monster_id).duplicate(true)

static func get_template_stats(monster_id: String, level: int = 1, nature_id: String = "") -> Dictionary:
	return StatCalculator.calc(monster_id, level, nature_id)

## 我方普通精灵使用基础成长数值；只有明确标记为精英的实例才叠加精英倍率。
static func get_owned_stats(monster_id: String, level: int = 1, nature_id: String = "", is_elite: bool = false) -> Dictionary:
	if is_elite:
		return StatCalculator.calc_with_tier(monster_id, level, nature_id, StatCalculator.EnemyTier.ELITE)
	return StatCalculator.calc(monster_id, level, nature_id)

static func get_instance_view(instance_id: String, storage: Node = null) -> Dictionary:
	var sm := _storage(storage)
	if sm == null or not sm.has_method("get_monster_instance"):
		return {}
	var instance: Dictionary = sm.get_monster_instance(instance_id)
	return build_instance_view(instance)

static func get_instance_views(instance_ids: Array, storage: Node = null) -> Array:
	var result: Array = []
	for value in instance_ids:
		var view := get_instance_view(str(value), storage)
		if not view.is_empty():
			result.append(view)
	return result

static func get_owned_instance_views(filters: Dictionary = {}, storage: Node = null) -> Array:
	var sm := _storage(storage)
	if sm == null or not sm.has_method("get_owned_monsters"):
		return []
	var result: Array = []
	for instance: Dictionary in sm.get_owned_monsters(filters):
		var view := build_instance_view(instance)
		if not view.is_empty():
			result.append(view)
	return result

static func get_species_album_view(monster_id: String, storage: Node = null) -> Dictionary:
	var template := get_template(monster_id)
	if template.is_empty():
		return {}
	var instances: Array = []
	var sm := _storage(storage)
	if sm != null and sm.has_method("get_instances_by_monster_id"):
		instances = sm.get_instances_by_monster_id(monster_id)
	var representative := _pick_representative(instances)
	var level := int(representative.get("level", 1)) if not representative.is_empty() else 1
	var nature := str(representative.get("nature", "")) if not representative.is_empty() else ""
	# ★ 主人定 2026-06-11：图鉴显示也尊重 instance.isElite
	var is_elite: bool = bool(representative.get("isElite", template.get("isElite", false))) if not representative.is_empty() else bool(template.get("isElite", false))
	var stats: Dictionary = get_owned_stats(monster_id, level, nature, is_elite)
	return {
		"monsterId": monster_id,
		"template": template,
		"owned": not instances.is_empty(),
		"ownedCount": instances.size(),
		"representative": representative,
		"isElite": is_elite,
		"stats": stats,
		"art": MonsterArtDB.get_art_bundle(monster_id),
	}

static func get_battle_unit_from_instance(instance_id: String, storage: Node = null) -> Dictionary:
	var view := get_instance_view(instance_id, storage)
	if view.is_empty():
		return {}
	var stats: Dictionary = view.get("stats", {}).duplicate(true)
	stats["id"] = view.get("instanceId", "")
	stats["instanceId"] = view.get("instanceId", "")
	stats["monsterId"] = view.get("monsterId", "")
	stats["name"] = view.get("name", stats.get("name", ""))
	stats["rarity"] = view.get("rarity", stats.get("rarity", 1))
	stats["boardAffinity"] = view.get("boardAffinity", MonsterDb.get_board_affinity(stats))
	stats["skill"] = MonsterDb.normalize_skill(view.get("skill", {}))
	stats["leaderSkill"] = view.get("leaderSkill", "")
	stats["level"] = view.get("level", 1)
	stats["nature"] = view.get("nature", "")
	stats["art"] = view.get("art", {})
	# ★ 主人定 2026-06-11：把 isElite 也透传到战斗单元（用于战前/战中标记）
	stats["isElite"] = view.get("isElite", false)
	return stats

static func build_instance_view(instance: Dictionary) -> Dictionary:
	if instance.is_empty():
		return {}
	var monster_id := str(instance.get("monsterId", ""))
	var template := MonsterDb.get_monster(monster_id)
	if template.is_empty():
		return {}
	var nature_id := str(instance.get("nature", ""))
	var nature := NatureDB.get_nature(nature_id)
	var level := int(instance.get("level", 1))
	var identity: Dictionary = EcologyBondRulesScript.get_monster_identity(template)
	# ★ 主人定 2026-06-11：精英宠物走 ELITE tier（HP×5, ATK+20%）
	var is_elite: bool = bool(instance.get("isElite", template.get("isElite", false)))
	var stats: Dictionary = get_owned_stats(monster_id, level, nature_id, is_elite)
	return {
		"instanceId": str(instance.get("instanceId", "")),
		"monsterId": monster_id,
		"name": str(instance.get("name", template.get("name", monster_id))),
		"templateName": str(template.get("name", monster_id)),
		"element": str(template.get("element", "")),
		"boardAffinity": MonsterDb.get_board_affinity(template),
		"rarity": int(template.get("rarity", 1)),
		"level": level,
		"exp": int(instance.get("exp", 0)),
		"nature": nature_id,
		"natureName": str(nature.get("name", "")),
		"gender": str(instance.get("gender", "")),
		"socialProfile": instance.get("socialProfile", {}).duplicate(true),
		"bondTraits": instance.get("bondTraits", []).duplicate(true),
		"bondMemory": instance.get("bondMemory", {}).duplicate(true),
		"identity": identity,
		"bondRole": str(identity.get("role", "")),
		"roleLabel": str(identity.get("roleLabel", "")),
		"ecology": identity.get("ecology", {}).duplicate(true),
		"capturedAt": int(instance.get("capturedAt", 0)),
		"source": str(instance.get("source", "")),
		"favorite": bool(instance.get("favorite", false)),
		"isElite": is_elite,
		"stats": stats,
		"skill": template.get("skill", {}).duplicate(true),
		"leaderSkill": str(template.get("leaderSkill", "")),
		"evolution": template.get("evolution", {}).duplicate(true),
		"art": MonsterArtDB.get_art_bundle(monster_id),
		"template": template.duplicate(true),
	}

static func get_monster_art(monster_id: String, usage: String = "battle") -> String:
	return MonsterArtDB.get_art_path(monster_id, usage)

static func validate_monster_catalog(storage: Node = null) -> Dictionary:
	var missing_fields: Array = []
	var invalid_evolutions: Array = []
	var invalid_art: Array = []
	var required := ["id", "name", "element", "rarity", "baseHP", "baseATK", "baseDEF", "baseSPD", "skill"]
	for monster: Dictionary in MonsterDb.get_all():
		var monster_id := str(monster.get("id", ""))
		for field in required:
			if not monster.has(field):
				missing_fields.append("%s.%s" % [monster_id, field])
		var evolution: Dictionary = monster.get("evolution", {})
		var target := str(evolution.get("target", ""))
		if not target.is_empty() and not MonsterDb.has_monster(target):
			invalid_evolutions.append("%s -> %s" % [monster_id, target])
		if not MonsterArtDB.has_art(monster_id, "battle"):
			invalid_art.append(monster_id)
	var broken_refs: Array = []
	var sm := _storage(storage)
	if sm != null and sm.has_method("get_monster_instance"):
		if sm.has_method("load_team"):
			var team: Dictionary = sm.load_team()
			for slot in ["leader", "member1", "member2"]:
				var value: Variant = team.get(slot, null)
				if value == null:
					continue
				var instance_id := str(value)
				if not instance_id.is_empty() and sm.get_monster_instance(instance_id).is_empty():
					broken_refs.append("team.%s=%s" % [slot, instance_id])
		if sm.has_method("get_ranch_state"):
			var ranch: Dictionary = sm.get_ranch_state()
			var slots: Array = ranch.get("slots", [])
			for i in range(slots.size()):
				var slot: Dictionary = slots[i]
				var value: Variant = slot.get("instance_id", null)
				if value == null:
					continue
				var instance_id := str(value)
				if not instance_id.is_empty() and sm.get_monster_instance(instance_id).is_empty():
					broken_refs.append("ranch.%d=%s" % [i, instance_id])
	return {
		"missingFields": missing_fields,
		"invalidEvolutions": invalid_evolutions,
		"missingBattleArt": invalid_art,
		"brokenInstanceRefs": broken_refs,
		"ok": missing_fields.is_empty() and invalid_evolutions.is_empty() and invalid_art.is_empty() and broken_refs.is_empty(),
	}

static func _storage(storage: Node = null) -> Node:
	if storage != null:
		return storage
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SaveManager")

static func _pick_representative(instances: Array) -> Dictionary:
	var best: Dictionary = {}
	for instance: Dictionary in instances:
		if best.is_empty() or int(instance.get("level", 1)) > int(best.get("level", 1)):
			best = instance
	return best.duplicate(true)

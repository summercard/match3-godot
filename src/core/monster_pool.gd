class_name MonsterPool
extends RefCounted

const GrowthRulesScript = preload("res://src/core/growth_rules.gd")
const DEFAULT_STARTERS: Array[String] = ["monster_001", "monster_002", "monster_003"]

static func generate_instance_id() -> String:
	return "m_%d_%04x%04x" % [Time.get_ticks_msec(), randi() & 0xffff, randi() & 0xffff]

static func create_instance(monster_id: String, options: Dictionary = {}) -> Dictionary:
	var template: Dictionary = MonsterDb.get_monster(monster_id)
	var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
	# 主人定 2026-06-11：捕获时把 MONSTER_DB.isElite 一起带进 instance
	# 没传 isElite 时默认读 MONSTER_DB（兼容老存档）
	var default_elite: bool = bool(template.get("isElite", false))
	return normalize_instance({
		"instanceId": str(options.get("instanceId", generate_instance_id())),
		"monsterId": monster_id,
		"name": str(options.get("name", template.get("name", monster_id))),
		"level": int(options.get("level", 1)),
		"exp": int(options.get("exp", 0)),
		"nature": str(options.get("nature", NatureDB.random_nature())),
		"gender": str(options.get("gender", "")),
		"socialProfile": options.get("socialProfile", {}),
		"bondTraits": options.get("bondTraits", []),
		"bondMemory": options.get("bondMemory", {}),
		"lineage": options.get("lineage", {}),
		"mutationTraits": options.get("mutationTraits", []),
		"conditionEffects": options.get("conditionEffects", []),
		"evolutionInsight": options.get("evolutionInsight", {}),
		"evolutionHistory": options.get("evolutionHistory", []),
		"evolutionCount": int(options.get("evolutionCount", 0)),
		"capturedAt": int(options.get("capturedAt", now_ms)),
		"source": str(options.get("source", "capture")),
		"favorite": bool(options.get("favorite", false)),
		"isElite": bool(options.get("isElite", default_elite)),
	})

static func normalize_instance(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var data: Dictionary = value
	var monster_id := str(data.get("monsterId", data.get("monster_id", data.get("id", ""))))
	if monster_id.is_empty() or not MonsterDb.has_monster(monster_id):
		return {}
	var template := MonsterDb.get_monster(monster_id)
	var instance_id := str(data.get("instanceId", data.get("instance_id", "")))
	if instance_id.is_empty():
		instance_id = generate_instance_id()
	var captured_at: Variant = data.get("capturedAt", data.get("captured_at", Time.get_unix_time_from_system() * 1000.0))
	var gender := str(data.get("gender", ""))
	if not ["male", "female", "neutral"].has(gender):
		gender = _derive_gender(instance_id, monster_id)
	var nature_id := str(data.get("nature", NatureDB.random_nature()))
	var social_profile := _normalize_social_profile(data.get("socialProfile", data.get("social_profile", {})), monster_id, nature_id, gender)
	var bond_traits := _normalize_bond_traits(data.get("bondTraits", data.get("bond_traits", [])), monster_id, nature_id, gender)
	var bond_memory := _normalize_bond_memory(data.get("bondMemory", data.get("bond_memory", {})))
	var raw_lineage: Variant = data.get("lineage", {})
	var lineage: Dictionary = raw_lineage if raw_lineage is Dictionary else {}
	var condition_effects := _normalize_dictionary_array(data.get("conditionEffects", data.get("condition_effects", [])))
	var raw_insight: Variant = data.get("evolutionInsight", data.get("evolution_insight", {}))
	var insight: Dictionary = raw_insight if raw_insight is Dictionary else {}
	var raw_history: Variant = data.get("evolutionHistory", data.get("evolution_history", []))
	var history: Array = raw_history if raw_history is Array else []
	return {
		"instanceId": instance_id,
		"monsterId": monster_id,
		"name": str(data.get("name", template.get("name", monster_id))),
		"level": maxi(1, int(data.get("level", 1))),
		"exp": maxi(0, int(data.get("exp", 0))),
		"nature": nature_id,
		"gender": gender,
		"socialProfile": social_profile,
		"bondTraits": bond_traits,
		"bondMemory": bond_memory,
		"lineage": lineage.duplicate(true),
		"mutationTraits": _normalize_string_array(data.get("mutationTraits", data.get("mutation_traits", []))),
		"conditionEffects": condition_effects,
		"evolutionInsight": insight.duplicate(true),
		"evolutionHistory": history.duplicate(true),
		"evolutionCount": maxi(0, int(data.get("evolutionCount", data.get("evolution_count", 0)))),
		"capturedAt": _normalize_timestamp_ms(captured_at),
		"source": str(data.get("source", "migration")),
		"favorite": bool(data.get("favorite", false)),
		# 老存档没存 isElite 时，回退读 MONSTER_DB（默认 false）
		"isElite": bool(data.get("isElite", template.get("isElite", false))),
	}

static func _derive_gender(instance_id: String, monster_id: String) -> String:
	var seed := "%s:%s" % [monster_id, instance_id]
	var score := 0
	for i in range(seed.length()):
		score += seed.unicode_at(i) * (i + 3)
	var roll := score % 10
	if roll <= 3:
		return "male"
	if roll <= 7:
		return "female"
	return "neutral"

static func _normalize_social_profile(value: Variant, monster_id: String, nature_id: String, gender: String) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var style := str(source.get("style", ""))
	if style.is_empty():
		style = _derive_social_style(nature_id, gender)
	return {
		"style": style,
		"socialExp": maxi(0, int(source.get("socialExp", source.get("social_exp", 0)))),
		"bondExp": maxi(0, int(source.get("bondExp", source.get("bond_exp", 0)))),
		"lastPartnerId": str(source.get("lastPartnerId", source.get("last_partner_id", ""))),
		"lastSocialTags": _normalize_string_array(source.get("lastSocialTags", source.get("last_social_tags", []))),
		"preferredPlace": str(source.get("preferredPlace", source.get("preferred_place", _derive_preferred_place(monster_id))))
	}

static func _normalize_bond_traits(value: Variant, monster_id: String, nature_id: String, gender: String) -> Array:
	var traits := _normalize_string_array(value)
	if traits.is_empty():
		traits = _derive_bond_traits(monster_id, nature_id, gender)
	return traits

static func _normalize_bond_memory(value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var partners: Dictionary = source.get("partners", {}) if source.get("partners", {}) is Dictionary else {}
	return {
		"partners": partners.duplicate(true),
		"branches": _normalize_string_array(source.get("branches", []))
	}

static func _normalize_string_array(value: Variant) -> Array:
	var result: Array = []
	if value is Array:
		for entry in value:
			var text := str(entry)
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result

static func _normalize_dictionary_array(value: Variant) -> Array:
	var result: Array = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				result.append((entry as Dictionary).duplicate(true))
	return result

static func _derive_social_style(nature_id: String, gender: String) -> String:
	if nature_id in ["brave", "fierce"]:
		return "bold"
	if nature_id in ["cautious", "calm"]:
		return "steady"
	if nature_id in ["gentle", "wise"]:
		return "caring"
	if nature_id == "agile":
		return "lively"
	if gender == "neutral":
		return "quiet"
	return "curious"

static func _derive_preferred_place(monster_id: String) -> String:
	var monster := MonsterDb.get_monster(monster_id)
	var element := str(monster.get("element", "fire"))
	var map := {
		"fire": "sunny_yard",
		"water": "pond",
		"grass": "meadow",
		"thunder": "windmill",
		"light": "garden",
		"earth": "rock_field",
		"wind": "sky_perch",
		"dark": "shade",
		"ice": "cool_cave",
		"void": "quiet_room",
		"temporal": "clock_room",
		"star": "observatory",
		"chaos": "wild_corner"
	}
	return str(map.get(element, "meadow"))

static func _derive_bond_traits(monster_id: String, nature_id: String, gender: String) -> Array:
	var monster := MonsterDb.get_monster(monster_id)
	var skill: Dictionary = MonsterDb.normalize_skill(monster.get("skill", {}))
	var role := str(skill.get("type", "strike"))
	var element := str(monster.get("element", "fire"))
	return [
		"role_%s" % role,
		"eco_%s" % _ecology_id_from_element(element),
		"nature_%s" % nature_id,
		"social_%s" % _derive_social_style(nature_id, gender)
	]

static func _ecology_id_from_element(element: String) -> String:
	var map := {
		"fire": "volcanic",
		"water": "shore",
		"grass": "meadow",
		"thunder": "storm",
		"light": "radiant",
		"earth": "mountain",
		"wind": "sky",
		"dark": "shadow",
		"ice": "shore",
		"void": "void",
		"temporal": "time",
		"star": "star",
		"chaos": "chaos"
	}
	return str(map.get(element, "volcanic"))

static func normalize_pool(pool: Array) -> Array:
	var normalized: Array = []
	var seen := {}
	for entry in pool:
		var instance := normalize_instance(entry)
		if instance.is_empty():
			continue
		var instance_id := str(instance.get("instanceId", ""))
		if seen.has(instance_id):
			instance["instanceId"] = generate_instance_id()
			instance_id = str(instance["instanceId"])
		seen[instance_id] = true
		normalized.append(instance)
	return normalized

static func find_index(pool: Array, instance_id: String) -> int:
	for i in range(pool.size()):
		var instance: Dictionary = pool[i]
		if str(instance.get("instanceId", "")) == instance_id:
			return i
	return -1

static func get_instance(pool: Array, instance_id: String) -> Dictionary:
	var idx := find_index(pool, instance_id)
	if idx < 0:
		return {}
	return (pool[idx] as Dictionary).duplicate(true)

static func get_first_instance_by_monster_id(pool: Array, monster_id: String) -> Dictionary:
	for entry in pool:
		var instance: Dictionary = entry
		if str(instance.get("monsterId", "")) == monster_id:
			return instance.duplicate(true)
	return {}

static func get_instances_by_monster_id(pool: Array, monster_id: String) -> Array:
	var result: Array = []
	for entry in pool:
		var instance: Dictionary = entry
		if str(instance.get("monsterId", "")) == monster_id:
			result.append(instance.duplicate(true))
	return result

static func get_owned_species_ids(pool: Array) -> Array:
	var result: Array = []
	var seen := {}
	for entry in pool:
		var instance: Dictionary = entry
		var monster_id := str(instance.get("monsterId", ""))
		if monster_id.is_empty() or seen.has(monster_id):
			continue
		seen[monster_id] = true
		result.append(monster_id)
	return result

static func update_instance(pool: Array, instance_id: String, patch: Dictionary) -> bool:
	var idx := find_index(pool, instance_id)
	if idx < 0:
		return false
	var instance: Dictionary = (pool[idx] as Dictionary).duplicate(true)
	for key in patch.keys():
		instance[key] = patch[key]
	var normalized := normalize_instance(instance)
	if normalized.is_empty():
		return false
	pool[idx] = normalized
	return true

static func remove_instance(pool: Array, instance_id: String) -> bool:
	var idx := find_index(pool, instance_id)
	if idx < 0:
		return false
	pool.remove_at(idx)
	return true

static func get_instance_stats(instance: Dictionary) -> Dictionary:
	if instance.is_empty():
		return {}
	# 统一公式：玩家宠物也走 StatCalculator（与敌人共用同一张表）
	return StatCalculator.calc(
		str(instance.get("monsterId", "")),
		int(instance.get("level", 1)),
		str(instance.get("nature", ""))
	)

static func add_instance_exp(instance: Dictionary, exp_gained: int) -> Dictionary:
	var old_level := int(instance.get("level", 1))
	var old_exp := int(instance.get("exp", 0))
	instance["exp"] = old_exp + maxi(0, exp_gained)
	while true:
		var level := int(instance.get("level", 1))
		var needed := GrowthRulesScript.get_exp_for_level(level)
		if int(instance["exp"]) < needed:
			break
		instance["exp"] = int(instance["exp"]) - needed
		instance["level"] = int(instance.get("level", 1)) + 1
	return {
		"leveledUp": int(instance.get("level", 1)) > old_level,
		"newLevel": int(instance.get("level", 1)),
		"oldLevel": old_level,
		"expGained": exp_gained,
		"currentExp": int(instance.get("exp", 0))
	}

static func evolve_instance(instance: Dictionary) -> Dictionary:
	var monster_id := str(instance.get("monsterId", ""))
	var template := MonsterDb.get_monster(monster_id)
	var evolution: Dictionary = template.get("evolution", {})
	var target_id := str(evolution.get("target", ""))
	var required_level := int(evolution.get("level", 1))
	if target_id.is_empty() or not MonsterDb.has_monster(target_id):
		return {"ok": false, "reason": "no_target", "instance": instance.duplicate(true)}
	if int(instance.get("level", 1)) < required_level:
		return {"ok": false, "reason": "level", "instance": instance.duplicate(true)}
	instance["monsterId"] = target_id
	var target_template := MonsterDb.get_monster(target_id)
	instance["name"] = target_template.get("name", target_id)
	return {"ok": true, "oldMonsterId": monster_id, "newMonsterId": target_id, "instance": instance.duplicate(true)}

static func _normalize_timestamp_ms(value: Variant) -> int:
	var timestamp := float(value)
	if timestamp <= 0.0:
		return int(Time.get_unix_time_from_system() * 1000.0)
	if timestamp < 100000000000.0:
		return int(timestamp * 1000.0)
	return int(timestamp)

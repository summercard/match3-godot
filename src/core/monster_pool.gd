class_name MonsterPool
extends RefCounted

const DEFAULT_STARTERS: Array[String] = ["monster_001", "monster_002", "monster_003"]

static func generate_instance_id() -> String:
	return "m_%d_%04x%04x" % [Time.get_ticks_msec(), randi() & 0xffff, randi() & 0xffff]

static func create_instance(monster_id: String, options: Dictionary = {}) -> Dictionary:
	var template: Dictionary = MonsterDb.get_monster(monster_id)
	var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
	return normalize_instance({
		"instanceId": str(options.get("instanceId", generate_instance_id())),
		"monsterId": monster_id,
		"name": str(options.get("name", template.get("name", monster_id))),
		"level": int(options.get("level", 1)),
		"exp": int(options.get("exp", 0)),
		"nature": str(options.get("nature", NatureDB.random_nature())),
		"capturedAt": int(options.get("capturedAt", now_ms)),
		"source": str(options.get("source", "capture")),
		"favorite": bool(options.get("favorite", false)),
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
	return {
		"instanceId": instance_id,
		"monsterId": monster_id,
		"name": str(data.get("name", template.get("name", monster_id))),
		"level": maxi(1, int(data.get("level", 1))),
		"exp": maxi(0, int(data.get("exp", 0))),
		"nature": str(data.get("nature", NatureDB.random_nature())),
		"capturedAt": _normalize_timestamp_ms(captured_at),
		"source": str(data.get("source", "migration")),
		"favorite": bool(data.get("favorite", false)),
	}

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
	return MonsterDb.get_monster_stats(
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
		var needed := 80 + level * 10
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

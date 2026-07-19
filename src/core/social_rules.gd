class_name SocialRules
extends RefCounted

## 1.3.2 社交只负责性格学习。旧存档中的关系字段会被 MonsterPool 保留，
## 但不会再参与开始条件、概率或结算。
const DURATION_MS := 60.0 * 60.0 * 1000.0
const PERSONALITY_CAPACITY := 3
const PLACE_ORDER := ["meadow_yard", "sunny_yard", "quiet_pond"]
const GENDER_LABELS := {"male": "雄性", "female": "雌性", "neutral": "无性别"}

const PLACE_CONFIGS := {
	"meadow_yard": {
		"id": "meadow_yard", "name": "草坪庭院", "short": "草坪",
		"summary": "草、光、土属性和温和、智慧性格更容易互相学习。",
		"durationHours": 1.0, "preferredElements": ["grass", "light", "earth"],
		"preferredStyles": ["gentle", "wise"], "baseTraitChance": 0.42,
		"elementBonus": 0.12, "personalityBonus": 0.08, "chanceCap": 0.82,
	},
	"sunny_yard": {
		"id": "sunny_yard", "name": "暖阳广场", "short": "暖阳",
		"summary": "火、雷、风属性和勇敢、暴躁、敏捷性格更容易互相学习。",
		"durationHours": 1.0, "preferredElements": ["fire", "thunder", "wind"],
		"preferredStyles": ["brave", "fierce", "agile"], "baseTraitChance": 0.32,
		"elementBonus": 0.18, "personalityBonus": 0.14, "chanceCap": 0.88,
	},
	"quiet_pond": {
		"id": "quiet_pond", "name": "静水池", "short": "静水",
		"summary": "水、冰、虚空属性和冷静、谨慎、温和性格更容易互相学习。",
		"durationHours": 1.0, "preferredElements": ["water", "ice", "void"],
		"preferredStyles": ["calm", "cautious", "gentle"], "baseTraitChance": 0.38,
		"elementBonus": 0.15, "personalityBonus": 0.11, "chanceCap": 0.86,
	},
}


static func normalize_place(place: Variant) -> Dictionary:
	if not place is Dictionary:
		return _empty_place()
	var data := place as Dictionary
	var place_id := str(data.get("place_id", data.get("placeId", "meadow_yard")))
	if not PLACE_CONFIGS.has(place_id):
		place_id = "meadow_yard"
	return {
		"place_id": place_id,
		"slot_a": _nullable_id(data.get("slot_a", data.get("slotA", null))),
		"slot_b": _nullable_id(data.get("slot_b", data.get("slotB", null))),
		"started_at": _normalize_timestamp_ms(data.get("started_at", data.get("startedAt", null))),
		"interaction_count": maxi(0, int(data.get("interaction_count", data.get("interactionCount", 0)))),
		"last_result": (data.get("last_result", data.get("lastResult", {})) as Dictionary).duplicate(true) if data.get("last_result", data.get("lastResult", {})) is Dictionary else {},
	}


static func normalize_places(places: Array, count: int = 1) -> Array:
	var result: Array = []
	for place in places:
		result.append(normalize_place(place))
	while result.size() < count:
		result.append(_empty_place())
	return result.slice(0, count)


static func can_start(place: Dictionary) -> bool:
	return not str(place.get("slot_a", "")).is_empty() and not str(place.get("slot_b", "")).is_empty() and place.get("started_at", null) == null


static func is_ready(place: Dictionary, now_ms: float = -1.0) -> bool:
	var started_at = place.get("started_at", null)
	if started_at == null:
		return false
	var now := Time.get_unix_time_from_system() * 1000.0 if now_ms < 0.0 else now_ms
	return now - float(started_at) >= DURATION_MS


static func progress(place: Dictionary, now_ms: float = -1.0) -> float:
	var started_at = place.get("started_at", null)
	if started_at == null:
		return 0.0
	var now := Time.get_unix_time_from_system() * 1000.0 if now_ms < 0.0 else now_ms
	return clampf((now - float(started_at)) / DURATION_MS, 0.0, 1.0)


static func duration_ms_for_place(_place: Dictionary) -> float:
	return DURATION_MS


static func duration_label_for_place(_place: Dictionary) -> String:
	return "1小时"


static func preview(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary = {}) -> Dictionary:
	return _build_result(instance_a, instance_b, place, false)


static func resolve(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary = {}) -> Dictionary:
	return _build_result(instance_a, instance_b, place, true)


static func get_place_config(place_id: String) -> Dictionary:
	return (PLACE_CONFIGS.get(place_id, PLACE_CONFIGS["meadow_yard"]) as Dictionary).duplicate(true)


static func place_config_for(place: Dictionary) -> Dictionary:
	return get_place_config(str(place.get("place_id", "meadow_yard")))


static func next_place_id(current_id: String) -> String:
	var index := PLACE_ORDER.find(current_id)
	return PLACE_ORDER[0] if index < 0 else PLACE_ORDER[(index + 1) % PLACE_ORDER.size()]


static func get_event_catalog(place_id: String = "") -> Array:
	var configs: Array = []
	for id in PLACE_ORDER:
		if place_id.is_empty() or id == place_id:
			var config := get_place_config(id)
			configs.append({"id": id, "name": config.get("name", "社交场所"), "summary": config.get("summary", ""), "duration": "1小时"})
	return configs


static func build_relationship_detail(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary = {}) -> Dictionary:
	if instance_a.is_empty() or instance_b.is_empty():
		return {}
	var result := preview(instance_a, instance_b, place)
	return {
		"successPercent": int(result.get("success_percent", 0)),
		"ruleText": str(result.get("rule_text", "")),
		"changes": result.get("changes", []).duplicate(true),
	}


static func gender_for_instance(instance: Dictionary) -> String:
	return str(instance.get("gender", "neutral"))


static func derive_gender(instance_id: String, monster_id: String) -> String:
	var roll := posmod(("%s:%s" % [monster_id, instance_id]).hash(), 10)
	return "male" if roll <= 3 else ("female" if roll <= 7 else "neutral")


static func personality_traits(instance: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var primary := str(instance.get("nature", ""))
	if not primary.is_empty():
		result.append(primary)
	for raw_trait in instance.get("learnedNatures", instance.get("learned_natures", [])):
		var nature_id := str(raw_trait)
		if NatureDB.has_nature(nature_id) and not result.has(nature_id):
			result.append(nature_id)
	return result.slice(0, PERSONALITY_CAPACITY)


static func _build_result(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary, final_result: bool) -> Dictionary:
	var config := place_config_for(place)
	var traits_a := personality_traits(instance_a)
	var traits_b := personality_traits(instance_b)
	var chance := _trait_chance(config, instance_a, instance_b, traits_a, traits_b)
	var candidates_a := traits_b.filter(func(candidate_nature): return not traits_a.has(str(candidate_nature)))
	var candidates_b := traits_a.filter(func(candidate_nature): return not traits_b.has(str(candidate_nature)))
	var can_a := traits_a.size() < PERSONALITY_CAPACITY and not candidates_a.is_empty()
	var can_b := traits_b.size() < PERSONALITY_CAPACITY and not candidates_b.is_empty()
	var pair_key := _pair_key(instance_a, instance_b)
	var interaction := int(place.get("interaction_count", 0))
	# Godot's String.hash() keeps neighbouring decimal suffixes too correlated for
	# a repeated one-hour activity. Mix the interaction counter explicitly so a
	# stable pair does not get trapped in a long run of identical outcomes.
	var place_seed := _stable_seed("%s:%s" % [pair_key, str(config.get("id", "meadow_yard"))])
	var seed := posmod(place_seed + interaction * 1103515245 + 12345, 2147483647)
	var receiver_a := can_a and (not can_b or posmod(seed / 3, 2) == 0)
	# A golden-ratio rotation gives each pair/venue a reproducible low-discrepancy
	# sequence. It avoids the correlated decimal suffixes produced by repeatedly
	# hashing neighbouring interaction numbers while still preventing rerolls.
	var roll_phase := float(_stable_seed("%s:%s:trait" % [pair_key, str(config.get("id", "meadow_yard"))])) / 2147483647.0
	var roll := fposmod(roll_phase + float(interaction) * 0.6180339887498949, 1.0)
	var next_a := traits_a.duplicate()
	var next_b := traits_b.duplicate()
	var changes: Array[String] = []
	var learned: Array = []
	var success := (can_a or can_b) and roll < chance if final_result else false
	if success:
		var candidates: Array = candidates_a if receiver_a else candidates_b
		var learned_nature := str(candidates[posmod(seed, candidates.size())])
		var receiver_name := _instance_name(instance_a if receiver_a else instance_b)
		var receiver_id := str((instance_a if receiver_a else instance_b).get("instanceId", ""))
		if receiver_a:
			next_a.append(learned_nature)
		else:
			next_b.append(learned_nature)
		changes.append(TranslationServer.translate("%s 学会了%s") % [TranslationServer.translate(receiver_name), TranslationServer.translate(_nature_name(learned_nature))])
		learned.append({"instance_id": receiver_id, "nature": learned_nature})
	elif final_result:
		changes.append("本次交流没有产生性格变化" if can_a or can_b else "双方没有可学习的新性格")
	else:
		changes.append("完成交流后，将按此概率学习对方未拥有的性格")
	var percent := int(round(chance * 100.0))
	var label := "性格学习成功" if success else ("学习结果待定" if not final_result else "性格保持不变")
	return {
		"version": "1.3.2", "direction": "trait_change" if success else "no_change",
		"direction_label": label, "label": label, "success_chance": chance,
		"success_percent": percent, "success_roll": roll, "rule_text": str(config.get("summary", "")),
		"interactions": interaction + (1 if final_result else 0), "changes": changes,
		"learned_natures": learned,
		"updated_a": {"instanceId": instance_a.get("instanceId", ""), "personalityTraits": next_a, "nature": next_a[0] if not next_a.is_empty() else ""},
		"updated_b": {"instanceId": instance_b.get("instanceId", ""), "personalityTraits": next_b, "nature": next_b[0] if not next_b.is_empty() else ""},
		"place_id": config.get("id", "meadow_yard"), "place_name": config.get("name", "社交场所"),
		"place_summary": config.get("summary", ""), "duration_ms": DURATION_MS, "duration_label": "1小时",
		"summary": TranslationServer.translate("%s：成功率 %d%%；%s。") % [TranslationServer.translate(str(config.get("name", "社交场所"))), percent, "。".join(changes.map(func(value): return TranslationServer.translate(str(value))))],
		"preview": not final_result, "final": final_result,
	}


static func _trait_chance(config: Dictionary, instance_a: Dictionary, instance_b: Dictionary, traits_a: Array[String], traits_b: Array[String]) -> float:
	var preferred_elements: Array = config.get("preferredElements", [])
	var preferred_styles: Array = config.get("preferredStyles", [])
	var element_matches := 0
	for instance in [instance_a, instance_b]:
		var monster := MonsterDb.get_monster(str(instance.get("monsterId", "")))
		if preferred_elements.has(str(monster.get("element", ""))):
			element_matches += 1
	var style_matches := 0
	for traits in [traits_a, traits_b]:
		for known_nature in traits:
			if preferred_styles.has(str(known_nature)):
				style_matches += 1
				break
	return clampf(float(config.get("baseTraitChance", 0.35)) + element_matches * float(config.get("elementBonus", 0.12)) + style_matches * float(config.get("personalityBonus", 0.10)), 0.05, float(config.get("chanceCap", 0.85)))


static func _empty_place() -> Dictionary:
	return {"place_id": "meadow_yard", "slot_a": null, "slot_b": null, "started_at": null, "interaction_count": 0, "last_result": {}}


static func _nullable_id(value: Variant) -> Variant:
	if value == null or str(value).is_empty():
		return null
	return str(value)


static func _normalize_timestamp_ms(value: Variant) -> Variant:
	if value == null or float(value) <= 0.0:
		return null
	return float(value) * 1000.0 if float(value) < 100000000000.0 else float(value)


static func _stable_seed(value: String) -> int:
	return posmod(value.hash(), 2147483647)


static func _pair_key(a: Dictionary, b: Dictionary) -> String:
	var ids := [str(a.get("instanceId", "a")), str(b.get("instanceId", "b"))]
	ids.sort()
	return "%s::%s" % ids


static func _instance_name(instance: Dictionary) -> String:
	return str(instance.get("name", MonsterDb.get_monster(str(instance.get("monsterId", ""))).get("name", "精灵")))


static func _nature_name(nature_id: String) -> String:
	return str(NatureDB.get_nature(nature_id).get("name", nature_id))

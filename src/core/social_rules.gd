class_name SocialRules
extends RefCounted

const DURATION_MS: float = 1.0 * 60.0 * 60.0 * 1000.0

const GENDER_LABELS := {
	"male": "雄性",
	"female": "雌性",
	"neutral": "无性别"
}

const PLACE_ORDER := ["meadow_yard", "sunny_yard", "quiet_pond"]

const PLACE_CONFIGS := {
	"meadow_yard": {
		"id": "meadow_yard",
		"name": "草坪庭院",
		"short": "草坪",
			"summary": "均衡社交，适合第一次熟悉彼此。",
			"durationHours": 1.0,
			"preferredElements": ["grass", "light", "earth"],
		"preferredStyles": ["caring", "curious"],
		"eventTheme": "陪伴"
	},
	"sunny_yard": {
		"id": "sunny_yard",
		"name": "暖阳广场",
		"short": "暖阳",
			"summary": "更容易激发活跃、勇敢或爆发型怪物。",
			"durationHours": 2.0,
			"preferredElements": ["fire", "thunder", "wind"],
		"preferredStyles": ["bold", "lively"],
		"eventTheme": "活力"
	},
	"quiet_pond": {
		"id": "quiet_pond",
		"name": "静水池",
		"short": "静水",
			"summary": "更适合稳重、安静或治愈型怪物沉淀关系。",
			"durationHours": 6.0,
			"preferredElements": ["water", "ice", "void"],
		"preferredStyles": ["steady", "quiet", "caring"],
		"eventTheme": "安定"
	}
}

const RELATION_LEVELS := [
	{"level": 1, "name": "初识", "minCount": 1, "minBest": 0},
	{"level": 2, "name": "熟悉", "minCount": 2, "minBest": 60},
	{"level": 3, "name": "亲近", "minCount": 4, "minBest": 74},
	{"level": 4, "name": "羁绊", "minCount": 7, "minBest": 86},
]

const EVENT_CATALOG := [
	{
		"id": "meadow_first_sniff",
		"placeIds": ["meadow_yard"],
		"minRelation": 1,
		"minScore": 0,
		"requiredTags": [],
		"name": "草叶试探",
		"theme": "陪伴",
		"flavor": "两只怪物绕着草坪慢慢走了一圈，最后在同一块树荫下停住。",
		"outcome": "双方留下初次气味记忆，下次同场所社交更容易读出偏好。",
		"hook": "relation_memory"
	},
	{
		"id": "meadow_same_element_hum",
		"placeIds": ["meadow_yard"],
		"minRelation": 1,
		"minScore": 64,
		"requiredTags": ["同属性共鸣"],
		"name": "同频低鸣",
		"theme": "生态",
		"flavor": "它们在草坪中央发出相近频率的低鸣，周围能量像浅浅的环纹一样扩散。",
		"outcome": "同属性搭档记录增强，后续适合接生态分支和进化启发。",
		"hook": "ecology_bond"
	},
	{
		"id": "meadow_caring_share",
		"placeIds": ["meadow_yard"],
		"minRelation": 2,
		"minScore": 68,
		"requiredTags": ["场所契合"],
		"name": "树荫分享",
		"theme": "陪伴",
		"flavor": "一只怪物把更舒服的位置让出来，另一只没有退开，而是贴近了一点。",
		"outcome": "关系进入稳定陪伴方向，适合作为长期社交搭档。",
		"hook": "companion_growth"
	},
	{
		"id": "sunny_bold_chase",
		"placeIds": ["sunny_yard"],
		"minRelation": 1,
		"minScore": 60,
		"requiredTags": ["场所契合"],
		"name": "追光竞跑",
		"theme": "活力",
		"flavor": "它们追着阳光边界来回奔跑，谁也没有真正认输。",
		"outcome": "活跃搭档记录增强，后续适合接破招节奏或行动型羁绊。",
		"hook": "tempo_hint"
	},
	{
		"id": "sunny_fire_spark",
		"placeIds": ["sunny_yard"],
		"minRelation": 1,
		"minScore": 72,
		"requiredTags": ["同属性共鸣"],
		"name": "火花练习",
		"theme": "活力",
		"flavor": "短促的火花在它们之间跳动，像一次没有危险的技能排练。",
		"outcome": "同属性社交事件被记录，后续可用于进化启发文本。",
		"hook": "evolution_insight"
	},
	{
		"id": "sunny_complement_guard",
		"placeIds": ["sunny_yard"],
		"minRelation": 2,
		"minScore": 70,
		"requiredTags": ["性格互补"],
		"name": "冲刺与等候",
		"theme": "默契",
		"flavor": "一只先冲出去，另一只在终点安静等待；第二轮时，它们自然交换了位置。",
		"outcome": "性格互补关系升温，适合接队伍里的分工羁绊。",
		"hook": "role_bond"
	},
	{
		"id": "pond_quiet_reflection",
		"placeIds": ["quiet_pond"],
		"minRelation": 1,
		"minScore": 0,
		"requiredTags": [],
		"name": "水面倒影",
		"theme": "安定",
		"flavor": "两只怪物看着水面上的倒影，很久都没有打扰彼此。",
		"outcome": "安静陪伴被记录，适合稳重或恢复型怪物继续培养关系。",
		"hook": "calm_memory"
	},
	{
		"id": "pond_steady_care",
		"placeIds": ["quiet_pond"],
		"minRelation": 2,
		"minScore": 66,
		"requiredTags": ["场所契合"],
		"name": "池边守候",
		"theme": "安定",
		"flavor": "其中一只怪物伏在池边休息，另一只守在旁边，偶尔拨开靠近的浮叶。",
		"outcome": "守候型关系增强，后续适合接守护、回复或陪伴成长。",
		"hook": "ward_bond"
	},
	{
		"id": "pond_complement_ripple",
		"placeIds": ["quiet_pond"],
		"minRelation": 2,
		"minScore": 70,
		"requiredTags": ["属性互补"],
		"name": "交错涟漪",
		"theme": "生态",
		"flavor": "两种不同能量落进水面，涟漪没有互相抵消，反而编成了新的纹路。",
		"outcome": "属性互补事件被记录，适合后续扩展跨生态社交路线。",
		"hook": "cross_ecology"
	},
	{
		"id": "any_relation_close",
		"placeIds": [],
		"minRelation": 3,
		"minScore": 74,
		"requiredTags": ["关系升温"],
		"name": "不用招呼",
		"theme": "亲近",
		"flavor": "它们没有特别的动作，却已经知道对方下一步会去哪里。",
		"outcome": "亲近关系确认，后续同伴分支和关系详情会优先展示这段记录。",
		"hook": "relationship_detail"
	},
	{
		"id": "any_bond_echo",
		"placeIds": [],
		"minRelation": 4,
		"minScore": 86,
		"requiredTags": [],
		"name": "羁绊回声",
		"theme": "羁绊",
		"flavor": "短暂的沉默后，两只怪物同时回头，像是听见了只有彼此能懂的声音。",
		"outcome": "羁绊级关系被记录，后续可以接入稀有事件、分支进化或捕捉稳定度。",
		"hook": "bond_branch"
	}
]

static func normalize_place(place: Variant) -> Dictionary:
	if not place is Dictionary:
		return _empty_place()
	var data: Dictionary = place
	var place_id := str(data.get("place_id", data.get("placeId", "meadow_yard")))
	if not PLACE_CONFIGS.has(place_id):
		place_id = "meadow_yard"
	return {
		"place_id": place_id,
			"slot_a": _nullable_id(data.get("slot_a", data.get("slotA", null))),
			"slot_b": _nullable_id(data.get("slot_b", data.get("slotB", null))),
			"started_at": _normalize_timestamp_ms(data.get("started_at", data.get("startedAt", null))),
		"last_result": data.get("last_result", data.get("lastResult", {})) if data.get("last_result", data.get("lastResult", {})) is Dictionary else {}
	}

static func normalize_places(places: Array, count: int = 1) -> Array:
	var result: Array = []
	for raw_place in places:
		result.append(normalize_place(raw_place))
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
	return now - float(started_at) >= duration_ms_for_place(place)

static func progress(place: Dictionary, now_ms: float = -1.0) -> float:
	var started_at = place.get("started_at", null)
	if started_at == null:
		return 0.0
	var now := Time.get_unix_time_from_system() * 1000.0 if now_ms < 0.0 else now_ms
	return clampf((now - float(started_at)) / duration_ms_for_place(place), 0.0, 1.0)

static func duration_ms_for_place(place: Dictionary) -> float:
	var place_config := place_config_for(place)
	return float(place_config.get("durationHours", 1.0)) * 60.0 * 60.0 * 1000.0

static func duration_label_for_place(place: Dictionary) -> String:
	var hours := float(place_config_for(place).get("durationHours", 1.0))
	if is_equal_approx(hours, round(hours)):
		return "%d小时" % int(round(hours))
	return "%.1f小时" % hours

static func preview(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary = {}) -> Dictionary:
	return _build_result(instance_a, instance_b, place, false)

static func resolve(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary = {}) -> Dictionary:
	return _build_result(instance_a, instance_b, place, true)

static func get_place_config(place_id: String) -> Dictionary:
	return PLACE_CONFIGS.get(place_id, PLACE_CONFIGS["meadow_yard"]).duplicate(true)

static func place_config_for(place: Dictionary) -> Dictionary:
	return get_place_config(str(place.get("place_id", "meadow_yard")))

static func next_place_id(current_id: String) -> String:
	var idx := PLACE_ORDER.find(current_id)
	if idx < 0:
		return PLACE_ORDER[0]
	return PLACE_ORDER[(idx + 1) % PLACE_ORDER.size()]

static func get_event_catalog(place_id: String = "") -> Array:
	var result: Array = []
	for event: Dictionary in EVENT_CATALOG:
		var place_ids: Array = event.get("placeIds", [])
		if place_id.is_empty() or place_ids.is_empty() or place_ids.has(place_id):
			result.append(event.duplicate(true))
	return result

static func build_relationship_detail(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary = {}) -> Dictionary:
	if instance_a.is_empty() or instance_b.is_empty():
		return {}
	var preview_result := preview(instance_a, instance_b, place)
	var partner_id := str(instance_b.get("instanceId", ""))
	var memory: Dictionary = instance_a.get("bondMemory", {})
	var partners: Dictionary = memory.get("partners", {})
	var partner_memory: Dictionary = partners.get(partner_id, {})
	var has_history := not partner_memory.is_empty()
	var current_label := str(partner_memory.get("relationLabel", "未相识"))
	var current_level := int(partner_memory.get("relationLevel", 0))
	var count := int(partner_memory.get("count", 0))
	var best_score := int(partner_memory.get("bestScore", 0))
	var next_event: Dictionary = preview_result.get("event", {})
	return {
		"hasHistory": has_history,
		"currentLevel": current_level,
		"currentLabel": current_label,
		"count": count,
		"bestScore": best_score,
		"lastLabel": str(partner_memory.get("lastLabel", "")),
		"lastTags": partner_memory.get("lastTags", []).duplicate(true) if partner_memory.get("lastTags", []) is Array else [],
		"lastPlaceName": str(partner_memory.get("placeName", "")),
		"lastEventName": str(partner_memory.get("lastEventName", "")),
		"lastEventFlavor": str(partner_memory.get("lastEventFlavor", "")),
		"lastEventOutcome": str(partner_memory.get("lastEventOutcome", "")),
		"lastEventHook": str(partner_memory.get("lastEventHook", "")),
		"nextScore": int(preview_result.get("score", 0)),
		"nextLabel": str(preview_result.get("relation_label", "初识")),
		"nextEventName": str(next_event.get("name", "")),
		"nextEventFlavor": str(next_event.get("flavor", "")),
		"nextEventHook": str(next_event.get("hook", "")),
	}

static func gender_for_instance(instance: Dictionary) -> String:
	var gender := str(instance.get("gender", ""))
	if GENDER_LABELS.has(gender):
		return gender
	return derive_gender(str(instance.get("instanceId", "")), str(instance.get("monsterId", "")))

static func derive_gender(instance_id: String, monster_id: String) -> String:
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

static func _build_result(instance_a: Dictionary, instance_b: Dictionary, place: Dictionary, final_result: bool) -> Dictionary:
	var monster_a := MonsterDb.get_monster(str(instance_a.get("monsterId", "")))
	var monster_b := MonsterDb.get_monster(str(instance_b.get("monsterId", "")))
	var element_a := str(monster_a.get("element", ""))
	var element_b := str(monster_b.get("element", ""))
	var nature_a := str(instance_a.get("nature", ""))
	var nature_b := str(instance_b.get("nature", ""))
	var gender_a := gender_for_instance(instance_a)
	var gender_b := gender_for_instance(instance_b)
	var place_config := place_config_for(place)
	var place_id := str(place_config.get("id", "meadow_yard"))
	var style_a := _social_style(instance_a)
	var style_b := _social_style(instance_b)

	var score := 40
	var tags: Array = []
	if gender_a != "neutral" and gender_b != "neutral" and gender_a != gender_b:
		score += 16
		tags.append("异性互补")
	elif gender_a == gender_b:
		score += 8
		tags.append("同伴默契")
	else:
		score += 10
		tags.append("安静陪伴")

	if element_a == element_b and not element_a.is_empty():
		score += 18
		tags.append("同属性共鸣")
	elif _is_element_complement(element_a, element_b):
		score += 14
		tags.append("属性互补")
	else:
		score += 6
		tags.append("生态交流")

	if nature_a == nature_b and not nature_a.is_empty():
		score += 12
		tags.append("性格合拍")
	elif _is_nature_complement(nature_a, nature_b):
		score += 10
		tags.append("性格互补")
	else:
		score += 4
		tags.append("互相熟悉")

	var place_bonus := _place_match_bonus(place_config, element_a, element_b, style_a, style_b)
	if place_bonus >= 14:
		tags.append("场所契合")
	elif place_bonus >= 7:
		tags.append("场所适应")
	score += place_bonus

	var relation := _relation_state(instance_a, instance_b, score)
	var relation_level := int(relation.get("level", 1))
	if relation_level >= 3:
		score += 4
		tags.append("关系升温")

	score = clampi(score, 0, 100)
	var exp_each := 25 + int(score * 0.9)
	var gold := 12 + int(score * 0.45)
	var item_id := _select_item(element_a, element_b, nature_a, nature_b, score)
	var item_count := 1 if score >= 66 else 0
	var label := "深度交流" if score >= 82 else ("良好社交" if score >= 66 else "轻松相处")
	var items: Array = []
	if item_count > 0:
		items.append({"id": item_id, "count": item_count})
	var event := _select_event(place_config, relation, score, tags)
	var major_outcome := _select_major_outcome(instance_a, instance_b, place_config, relation, score, tags)
	return {
		"score": score,
		"label": label,
		"tags": tags,
		"majorOutcome": major_outcome,
		"place_id": place_id,
			"place_name": str(place_config.get("name", "草坪庭院")),
			"place_summary": str(place_config.get("summary", "")),
			"duration_ms": duration_ms_for_place(place),
			"duration_label": duration_label_for_place(place),
		"relation_level": relation_level,
		"relation_label": str(relation.get("name", "初识")),
		"relation_count": int(relation.get("count", 1)),
		"event": event,
		"gender_pair": "%s / %s" % [GENDER_LABELS.get(gender_a, gender_a), GENDER_LABELS.get(gender_b, gender_b)],
		"element_pair": "%s / %s" % [element_a, element_b],
		"nature_pair": "%s / %s" % [_nature_name(nature_a), _nature_name(nature_b)],
		"exp_each": exp_each,
		"gold": gold,
		"items": items,
		"summary": "%s·%s：%s，%s。" % [str(place_config.get("short", "场所")), label, "、".join(tags), str(event.get("summary", "关系产生了变化"))],
		"final": final_result
	}

static func _empty_place() -> Dictionary:
	return {"place_id": "meadow_yard", "slot_a": null, "slot_b": null, "started_at": null, "last_result": {}}

static func _nullable_id(value: Variant) -> Variant:
	if value == null:
		return null
	var text := str(value)
	return null if text.is_empty() else text

static func _normalize_timestamp_ms(value: Variant) -> Variant:
	if value == null:
		return null
	var timestamp := float(value)
	if timestamp <= 0.0:
		return null
	if timestamp < 100000000000.0:
		return timestamp * 1000.0
	return timestamp

static func _is_element_complement(a: String, b: String) -> bool:
	var pair := [a, b]
	return (
		(pair.has("fire") and pair.has("water"))
		or (pair.has("grass") and pair.has("earth"))
		or (pair.has("thunder") and pair.has("wind"))
		or (pair.has("light") and pair.has("dark"))
		or (pair.has("void") and pair.has("star"))
	)

static func _is_nature_complement(a: String, b: String) -> bool:
	var pair := [a, b]
	return (
		(pair.has("brave") and pair.has("cautious"))
		or (pair.has("agile") and pair.has("calm"))
		or (pair.has("wise") and pair.has("gentle"))
		or (pair.has("fierce") and pair.has("calm"))
	)

static func _select_item(element_a: String, element_b: String, nature_a: String, nature_b: String, score: int) -> String:
	if score >= 82 and element_a == element_b:
		var stone_map := {
			"fire": "evolution_stone_fire",
			"water": "evolution_stone_water",
			"grass": "evolution_stone_grass",
			"thunder": "evolution_stone_thunder",
			"light": "evolution_stone_light",
			"earth": "evolution_stone_earth",
			"wind": "evolution_stone_wind",
			"dark": "evolution_stone_dark"
		}
		return str(stone_map.get(element_a, "exp_potion"))
	if nature_a == "wise" or nature_b == "wise":
		return "exp_crystal" if score >= 82 else "exp_potion"
	return "capture_ball_plus" if score >= 82 else "capture_ball"

static func _nature_name(nature_id: String) -> String:
	var nature := NatureDB.get_nature(nature_id)
	return str(nature.get("name", nature_id)) if not nature.is_empty() else nature_id

static func _social_style(instance: Dictionary) -> String:
	var profile: Dictionary = instance.get("socialProfile", {})
	return str(profile.get("style", "curious"))

static func _place_match_bonus(place_config: Dictionary, element_a: String, element_b: String, style_a: String, style_b: String) -> int:
	var bonus := 0
	var preferred_elements: Array = place_config.get("preferredElements", [])
	var preferred_styles: Array = place_config.get("preferredStyles", [])
	if preferred_elements.has(element_a):
		bonus += 7
	if preferred_elements.has(element_b):
		bonus += 7
	if preferred_styles.has(style_a):
		bonus += 5
	if preferred_styles.has(style_b):
		bonus += 5
	return mini(20, bonus)

static func _relation_state(instance_a: Dictionary, instance_b: Dictionary, score: int) -> Dictionary:
	var partner_id := str(instance_b.get("instanceId", ""))
	var memory: Dictionary = instance_a.get("bondMemory", {})
	var partners: Dictionary = memory.get("partners", {})
	var partner_memory: Dictionary = partners.get(partner_id, {})
	var next_count := int(partner_memory.get("count", 0)) + 1
	var best_score := maxi(int(partner_memory.get("bestScore", 0)), score)
	var result: Dictionary = RELATION_LEVELS[0].duplicate(true)
	for raw_level: Dictionary in RELATION_LEVELS:
		if next_count >= int(raw_level.get("minCount", 1)) and best_score >= int(raw_level.get("minBest", 0)):
			result = raw_level.duplicate(true)
	result["count"] = next_count
	result["bestScore"] = best_score
	return result

static func _select_event(place_config: Dictionary, relation: Dictionary, score: int, tags: Array) -> Dictionary:
	var place_id := str(place_config.get("id", "meadow_yard"))
	var level := int(relation.get("level", 1))
	var theme := str(place_config.get("eventTheme", "陪伴"))
	var focus := "、".join(tags.slice(0, mini(2, tags.size())))
	if focus.is_empty():
		focus = theme
	var selected: Dictionary = {}
	var selected_score := -1
	for event: Dictionary in EVENT_CATALOG:
		var place_ids: Array = event.get("placeIds", [])
		if not place_ids.is_empty() and not place_ids.has(place_id):
			continue
		if level < int(event.get("minRelation", 1)):
			continue
		if score < int(event.get("minScore", 0)):
			continue
		var required_tags: Array = event.get("requiredTags", [])
		if not _has_all_tags(tags, required_tags):
			continue
		var rank := int(event.get("minRelation", 1)) * 100 + int(event.get("minScore", 0)) + required_tags.size() * 12
		if place_ids.has(place_id):
			rank += 8
		if rank > selected_score:
			selected_score = rank
			selected = event
	if selected.is_empty():
		selected = EVENT_CATALOG[0]
	var result := selected.duplicate(true)
	result["summary"] = "%s事件触发：%s，关系进入%s。" % [str(result.get("theme", theme)), focus, str(relation.get("name", "初识"))]
	result["impact"] = str(result.get("outcome", "关系记忆被记录，后续系统会读取这段经历。"))
	return result

static func _select_major_outcome(instance_a: Dictionary, instance_b: Dictionary, place_config: Dictionary, relation: Dictionary, score: int, tags: Array) -> Dictionary:
	var gender_a := gender_for_instance(instance_a)
	var gender_b := gender_for_instance(instance_b)
	var element_a := str(MonsterDb.get_monster(str(instance_a.get("monsterId", ""))).get("element", ""))
	var element_b := str(MonsterDb.get_monster(str(instance_b.get("monsterId", ""))).get("element", ""))
	var relation_level := int(relation.get("level", 1))
	if _can_birth(gender_a, gender_b, relation_level, score):
		var child_count := 2 if score >= 96 or (relation_level >= 4 and tags.has("同属性共鸣")) else 1
		return {
			"type": "birth",
			"name": "复合新生",
			"rarity": "rare",
			"summary": "双方关系稳定并产生复合幼体。",
			"childCount": child_count,
			"childPlans": _build_birth_child_plans(instance_a, instance_b, element_a, element_b, relation, score, child_count),
			"risk": "none"
		}
	var erosion := _erosion_candidate(instance_a, instance_b, element_a, element_b, score)
	if not erosion.is_empty():
		return erosion
	return {
		"type": "none",
		"name": "常规社交",
		"summary": "本次只产生普通关系、事件和资源结果。"
	}

static func _can_birth(gender_a: String, gender_b: String, relation_level: int, score: int) -> bool:
	if gender_a == "neutral" or gender_b == "neutral" or gender_a == gender_b:
		return false
	return relation_level >= 3 and score >= 86

static func _build_birth_child_plans(instance_a: Dictionary, instance_b: Dictionary, element_a: String, element_b: String, relation: Dictionary, score: int, child_count: int) -> Array:
	var result: Array = []
	for i in range(child_count):
		var monster_id := _pick_birth_species(instance_a, instance_b, element_a, element_b, i)
		var template := MonsterDb.get_monster(monster_id)
		var nature := _pick_birth_nature(instance_a, instance_b, i)
		result.append({
			"monsterId": monster_id,
			"name": "%s·复合幼体" % str(template.get("name", monster_id)),
			"level": 1,
			"nature": nature,
			"gender": derive_gender("birth_%s_%s_%d" % [str(instance_a.get("instanceId", "")), str(instance_b.get("instanceId", "")), i], monster_id),
			"source": "social_birth",
			"lineage": {
				"type": "hybrid_birth",
				"parents": [str(instance_a.get("instanceId", "")), str(instance_b.get("instanceId", ""))],
				"parentSpecies": [str(instance_a.get("monsterId", "")), str(instance_b.get("monsterId", ""))],
				"elements": [element_a, element_b],
				"score": score,
				"relationLabel": str(relation.get("name", "初识"))
			},
			"mutationTraits": _birth_mutation_traits(element_a, element_b)
		})
	return result

static func _pick_birth_species(instance_a: Dictionary, instance_b: Dictionary, element_a: String, element_b: String, index: int) -> String:
	var parent_species := [str(instance_a.get("monsterId", "")), str(instance_b.get("monsterId", ""))]
	var candidates: Array = []
	for monster: Dictionary in MonsterDb.get_all():
		var monster_id := str(monster.get("id", ""))
		if not monster_id.begins_with("monster_") or bool(monster.get("isBoss", false)):
			continue
		var element := str(monster.get("element", ""))
		if element == element_a or element == element_b:
			candidates.append(monster_id)
	if candidates.is_empty():
		candidates = parent_species
	var seed := "%s:%s:%d" % [parent_species[0], parent_species[1], index]
	return str(candidates[_stable_index(seed, candidates.size())])

static func _pick_birth_nature(instance_a: Dictionary, instance_b: Dictionary, index: int) -> String:
	var natures := [str(instance_a.get("nature", "brave")), str(instance_b.get("nature", "cautious")), "chaos"]
	return str(natures[_stable_index("%s:%s:nature:%d" % [str(instance_a.get("instanceId", "")), str(instance_b.get("instanceId", "")), index], natures.size())])

static func _birth_mutation_traits(element_a: String, element_b: String) -> Array:
	var traits := ["hybrid_birth", "inherit_%s" % element_a]
	if element_b != element_a:
		traits.append("inherit_%s" % element_b)
	else:
		traits.append("pureline_%s" % element_a)
	return traits

static func _erosion_candidate(instance_a: Dictionary, instance_b: Dictionary, element_a: String, element_b: String, score: int) -> Dictionary:
	var danger_a := _erosion_power(instance_a, element_a)
	var danger_b := _erosion_power(instance_b, element_b)
	if maxi(danger_a, danger_b) <= 0 or score > 64:
		return {}
	var aggressor := instance_a
	var victim := instance_b
	var aggressor_element := element_a
	if danger_b > danger_a:
		aggressor = instance_b
		victim = instance_a
		aggressor_element = element_b
	return {
		"type": "erosion",
		"name": "侵蚀吞噬",
		"rarity": "danger",
		"summary": "危险属性或性格压过社交边界，一只怪物吞噬了另一只。",
		"aggressorInstanceId": str(aggressor.get("instanceId", "")),
		"victimInstanceId": str(victim.get("instanceId", "")),
		"aggressorName": str(MonsterDb.get_monster(str(aggressor.get("monsterId", ""))).get("name", "侵蚀者")),
		"victimName": str(MonsterDb.get_monster(str(victim.get("monsterId", ""))).get("name", "被吞噬者")),
		"expGain": 180 + score * 2,
		"negativeEffect": {
			"id": "erosion_hunger",
			"name": "侵蚀饥渴",
			"summary": "吞噬带来快速成长，但留下不稳定的侵蚀负担。",
			"severity": 1,
			"element": aggressor_element
		},
		"risk": "lose_partner"
	}

static func _erosion_power(instance: Dictionary, element: String) -> int:
	var power := 0
	if element in ["dark", "void", "chaos"]:
		power += 2
	var nature := str(instance.get("nature", ""))
	if nature in ["fierce", "chaos"]:
		power += 1
	return power

static func _stable_index(seed: String, size: int) -> int:
	if size <= 0:
		return 0
	var score := 0
	for i in range(seed.length()):
		score += seed.unicode_at(i) * (i + 7)
	return score % size

static func _has_all_tags(tags: Array, required_tags: Array) -> bool:
	for tag in required_tags:
		if not tags.has(str(tag)):
			return false
	return true

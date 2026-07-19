class_name EcologyBondRules
extends RefCounted

const MonsterDBScript = preload("res://src/data/monster_db.gd")
const MonsterEcologyDBScript = preload("res://src/data/monster_ecology_db.gd")

const ROLE_LABELS := {
	"strike": "输出手",
	"ward": "守护手",
	"tempo": "控场手",
	"hunt": "猎手",
	"shape": "塑盘手"
}

const ECOLOGY_BY_ELEMENT := {
	"fire": {"id": "volcanic", "name": "熔火生态", "theme": "爆发与破障", "chapter": "热情沙漠"},
	"water": {"id": "shore", "name": "潮岸生态", "theme": "续航与缓冲", "chapter": "瀑布国"},
	"grass": {"id": "meadow", "name": "林地生态", "theme": "控场与捕捉窗口", "chapter": "微风平原"},
	"thunder": {"id": "storm", "name": "雷暴生态", "theme": "连锁与节奏", "chapter": "南国海"},
	"light": {"id": "radiant", "name": "辉光生态", "theme": "保护与捕捉辅助", "chapter": "光耀圣殿"},
	"earth": {"id": "mountain", "name": "岩山生态", "theme": "防守与破障", "chapter": "热情沙漠"},
	"wind": {"id": "sky", "name": "苍空生态", "theme": "速度与先手", "chapter": "幻羽森林"},
	"dark": {"id": "shadow", "name": "暗影生态", "theme": "集火与压制", "chapter": "幻羽森林"},
	"ice": {"id": "shore", "name": "潮岸生态", "theme": "续航与缓冲", "chapter": "冰之国"},
	"void": {"id": "void", "name": "虚空生态", "theme": "分割与重连", "chapter": "精灵虚空"},
	"temporal": {"id": "time", "name": "时序生态", "theme": "延迟与爆发窗口", "chapter": "烧烤岩"},
	"star": {"id": "star", "name": "星轨生态", "theme": "阵型与跨区连锁", "chapter": "星耀圣殿"},
	"chaos": {"id": "chaos", "name": "混沌生态", "theme": "复合压力", "chapter": "混沌领域"}
}

static func get_monster_identity(monster: Dictionary) -> Dictionary:
	var skill: Dictionary = MonsterDBScript.normalize_skill(monster.get("skill", {}))
	var role := str(skill.get("type", "strike"))
	var element := str(monster.get("element", "fire"))
	var ecology: Dictionary = ECOLOGY_BY_ELEMENT.get(element, ECOLOGY_BY_ELEMENT["fire"]).duplicate(true)
	var species_ecology := MonsterEcologyDBScript.get_ecology(monster)
	if not species_ecology.is_empty():
		for key in species_ecology:
			ecology[key] = species_ecology[key]
	var role_label := str(ROLE_LABELS.get(role, role))
	return {
		"role": role,
		"roleLabel": role_label,
		"ecology": ecology,
		"tags": _build_tags(monster, role_label, ecology),
		"capturePreference": _capture_preference(role, ecology),
		"bondHint": _bond_hint(role, ecology)
	}

static func calc_team_bonds(monsters: Array) -> Array:
	var roles: Dictionary = {}
	var ecology_counts: Dictionary = {}
	var ecology_names: Dictionary = {}
	for monster: Dictionary in monsters:
		if monster.is_empty():
			continue
		var identity: Dictionary = get_monster_identity(monster)
		var role := str(identity.get("role", "strike"))
		roles[role] = roles.get(role, 0) + 1
		var ecology: Dictionary = identity.get("ecology", {})
		var ecology_id := str(ecology.get("id", ""))
		ecology_counts[ecology_id] = ecology_counts.get(ecology_id, 0) + 1
		ecology_names[ecology_id] = ecology.get("name", ecology_id)

	var bonds: Array = []
	if roles.get("strike", 0) >= 1 and roles.get("ward", 0) >= 1 and roles.get("tempo", 0) >= 1:
		bonds.append({
			"id": "pioneer_triad",
			"name": "开拓羁绊",
			"level": 1,
			"summary": "输出/守护/控场齐备，适合处理Boss读招。",
			"status": "active"
		})
	if roles.get("strike", 0) >= 2:
		bonds.append({
			"id": "double_strike",
			"name": "压制火力",
			"level": 1,
			"summary": "双输出队伍，适合快速破盾和压低捕捉目标。",
			"status": "active"
		})
	for ecology_id in ecology_counts.keys():
		var count := int(ecology_counts[ecology_id])
		if count >= 2:
			bonds.append({
				"id": "ecology_%s" % ecology_id,
				"name": TranslationServer.translate("%s羁绊") % ecology_names.get(ecology_id, ecology_id),
				"level": 1 if count == 2 else 2,
				"summary": TranslationServer.translate("同生态成员×%d，适合对应章节机制。") % count,
				"status": "active"
			})
	if bonds.is_empty() and monsters.size() > 0:
		bonds.append({
			"id": "none",
			"name": "未成型",
			"level": 0,
			"summary": "尝试补入守护、控场或同生态成员来触发羁绊。",
			"status": "hint"
		})
	return bonds

static func calc_team_bond_branches(units: Array) -> Array:
	var roles: Dictionary = {}
	var ecology_counts: Dictionary = {}
	var ecology_names: Dictionary = {}
	var valid_count := 0
	for unit: Dictionary in units:
		if unit.is_empty():
			continue
		var template: Dictionary = _template_from_unit(unit)
		if template.is_empty():
			continue
		valid_count += 1
		var identity: Dictionary = get_monster_identity(template)
		var role := str(identity.get("role", "strike"))
		roles[role] = roles.get(role, 0) + 1
		var ecology: Dictionary = identity.get("ecology", {})
		var ecology_id := str(ecology.get("id", ""))
		ecology_counts[ecology_id] = ecology_counts.get(ecology_id, 0) + 1
		ecology_names[ecology_id] = ecology.get("name", ecology_id)

	var branches: Array = []
	if roles.get("strike", 0) >= 1 and roles.get("ward", 0) >= 1 and roles.get("tempo", 0) >= 1:
		branches.append({
			"id": "branch_pioneer",
			"name": "开拓分支",
			"level": 1,
			"status": "active",
			"summary": "输出/守护/控场齐备，适合处理读招、破绽和捕捉窗口。",
			"playStyle": "均衡应对",
			"effectPreview": "后续可接 Boss 破招、捕捉稳定度或回合节奏效果。",
			"tags": ["角色齐备", "Boss应对"]
		})
	if roles.get("strike", 0) >= 2:
		branches.append({
			"id": "branch_pressure",
			"name": "压制分支",
			"level": 1,
			"status": "active",
			"summary": "双输出成员形成压制路线，适合快速破盾和压低目标血线。",
			"playStyle": "快速压血",
			"effectPreview": "后续可接破盾效率或低血捕捉窗口提示。",
			"tags": ["双输出", "破盾"]
		})
	for ecology_id in ecology_counts.keys():
		var count := int(ecology_counts[ecology_id])
		if count >= 2:
			branches.append({
				"id": "branch_ecology_%s" % ecology_id,
				"name": TranslationServer.translate("%s分支") % ecology_names.get(ecology_id, ecology_id),
				"level": 2 if count >= 3 else 1,
				"status": "active",
				"summary": TranslationServer.translate("同生态成员×%d，队伍主题更集中，适合对应章节机制。") % count,
				"playStyle": "生态专精",
				"effectPreview": "后续可接章节机制抗性、生态目标或场地互动。",
				"tags": ["同生态", "章节方向"]
			})
	if branches.is_empty() and valid_count > 0:
		branches.append({
			"id": "branch_hint",
			"name": "未成型",
			"level": 0,
			"status": "hint",
			"summary": "补入守护、控场或同生态成员来形成分支。",
			"playStyle": "待定",
			"effectPreview": "当前只提示方向，不触发分支。",
			"tags": ["提示"]
		})
	return branches

static func get_ecology_progress(monsters: Array, captured_ids: Array) -> Array:
	var groups: Dictionary = {}
	for monster: Dictionary in monsters:
		var identity: Dictionary = get_monster_identity(monster)
		var ecology: Dictionary = identity.get("ecology", {})
		var ecology_id := str(ecology.get("id", "unknown"))
		if not groups.has(ecology_id):
			groups[ecology_id] = {
				"id": ecology_id,
				"name": ecology.get("name", ecology_id),
				"theme": ecology.get("theme", ""),
				"chapter": ecology.get("chapter", ""),
				"total": 0,
				"owned": 0
			}
		groups[ecology_id]["total"] += 1
		if captured_ids.has(str(monster.get("id", ""))):
			groups[ecology_id]["owned"] += 1
	var result: Array = groups.values()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ar := float(a.get("owned", 0)) / maxf(1.0, float(a.get("total", 1)))
		var br := float(b.get("owned", 0)) / maxf(1.0, float(b.get("total", 1)))
		if is_equal_approx(ar, br):
			return str(a.get("id", "")) < str(b.get("id", ""))
		return ar > br
	)
	return result

static func get_ecology_targets(monsters: Array, captured_ids: Array) -> Array:
	var groups: Dictionary = {}
	for monster: Dictionary in monsters:
		var identity: Dictionary = get_monster_identity(monster)
		var ecology: Dictionary = identity.get("ecology", {})
		var ecology_id := str(ecology.get("id", "unknown"))
		if not groups.has(ecology_id):
			groups[ecology_id] = {
				"id": ecology_id,
				"name": ecology.get("name", ecology_id),
				"theme": ecology.get("theme", ""),
				"chapter": ecology.get("chapter", ""),
				"total": 0,
				"owned": 0,
				"missing": []
			}
		groups[ecology_id]["total"] += 1
		var monster_id := str(monster.get("id", ""))
		if captured_ids.has(monster_id):
			groups[ecology_id]["owned"] += 1
		else:
			groups[ecology_id]["missing"].append({
				"id": monster_id,
				"name": str(monster.get("name", monster_id)),
				"roleLabel": identity.get("roleLabel", ""),
				"rarity": int(monster.get("rarity", 1))
			})
	var result: Array = []
	for group: Dictionary in groups.values():
		var total := maxi(1, int(group.get("total", 1)))
		var owned := int(group.get("owned", 0))
		var missing: Array = group.get("missing", [])
		missing.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ra := int(a.get("rarity", 1))
			var rb := int(b.get("rarity", 1))
			if ra == rb:
				return str(a.get("id", "")) < str(b.get("id", ""))
			return ra < rb
		)
		group["missing"] = missing
		group["ratio"] = float(owned) / float(total)
		group["statusLabel"] = "已完成" if owned >= total else TranslationServer.translate("还差 %d") % (total - owned)
		group["nextMissing"] = missing[0] if not missing.is_empty() else {}
		group["suggestion"] = _ecology_target_suggestion(group)
		result.append(group)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_complete := int(a.get("owned", 0)) >= int(a.get("total", 1))
		var b_complete := int(b.get("owned", 0)) >= int(b.get("total", 1))
		if a_complete != b_complete:
			return not a_complete
		var ar := float(a.get("ratio", 0.0))
		var br := float(b.get("ratio", 0.0))
		if is_equal_approx(ar, br):
			return str(a.get("id", "")) < str(b.get("id", ""))
		return ar > br
	)
	return result

static func get_role_collection_target(monsters: Array, captured_ids: Array) -> Dictionary:
	var role_totals: Dictionary = {}
	var role_owned: Dictionary = {}
	for monster: Dictionary in monsters:
		var identity: Dictionary = get_monster_identity(monster)
		var role := str(identity.get("role", "strike"))
		var label := str(identity.get("roleLabel", role))
		if not role_totals.has(role):
			role_totals[role] = {"role": role, "label": label, "total": 0}
			role_owned[role] = 0
		role_totals[role]["total"] += 1
		if captured_ids.has(str(monster.get("id", ""))):
			role_owned[role] += 1
	var required := ["strike", "ward", "tempo"]
	var missing: Array = []
	var owned_required := 0
	for role in required:
		if int(role_owned.get(role, 0)) > 0:
			owned_required += 1
		else:
			missing.append(str(ROLE_LABELS.get(role, role)))
	return {
		"id": "pioneer_roles",
		"name": "开拓角色组",
		"owned": owned_required,
		"total": required.size(),
		"missing": missing,
		"complete": missing.is_empty(),
		"suggestion": "输出/守护/控场各拥有 1 只，组队目标会更清楚。" if not missing.is_empty() else "核心角色齐备，可以尝试组建开拓羁绊。"
	}

static func _build_tags(monster: Dictionary, role_label: String, ecology: Dictionary) -> Array:
	var tags: Array = [role_label, ecology.get("name", "生态")]
	var rarity := int(monster.get("rarity", 1))
	if rarity >= 4:
		tags.append("稀有核心")
	elif rarity <= 1:
		tags.append("易培养")
	if monster.has("evolution"):
		tags.append("可进化")
	return tags

static func _template_from_unit(unit: Dictionary) -> Dictionary:
	var raw_template: Variant = unit.get("template", null)
	if raw_template is Dictionary and not (raw_template as Dictionary).is_empty():
		return raw_template as Dictionary
	var monster_id := str(unit.get("monsterId", unit.get("id", "")))
	if not monster_id.is_empty() and MonsterDBScript.has_monster(monster_id):
		return MonsterDBScript.get_monster(monster_id)
	return unit

static func _capture_preference(role: String, ecology: Dictionary) -> String:
	if role == "tempo" or role == "hunt":
		return "偏好被压制或低血窗口，适合控场捕捉。"
	if role == "ward":
		return "偏好稳定战局，适合带守护降低翻车风险。"
	if str(ecology.get("id", "")) in ["mountain", "volcanic"]:
		return "偏好破障后的开阔棋盘，避免过量伤害。"
	return "偏好低血稳定窗口，注意不要直接击倒。"

static func _bond_hint(role: String, ecology: Dictionary) -> String:
	if role == "strike":
		return "与守护手、控场手组队可组成开拓羁绊。"
	if role == "ward":
		return "与输出手、控场手组队可稳住Boss破招回合。"
	if role == "tempo":
		return "与输出手、守护手组队可放大读招收益。"
	return "与同生态成员组队可形成章节应对方向。"

static func _ecology_target_suggestion(group: Dictionary) -> String:
	var missing: Array = group.get("missing", [])
	if missing.is_empty():
		return "该生态已补齐，适合作为队伍主题尝试。"
	var next: Dictionary = missing[0]
	return TranslationServer.translate("下一只: %s（%s），对应%s。") % [
		str(next.get("name", "未知")),
		str(next.get("roleLabel", "角色")),
		str(group.get("chapter", "后续章节"))
	]

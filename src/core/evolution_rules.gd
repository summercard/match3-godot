class_name EvolutionRules
extends RefCounted

const ROLE_LABELS := {
	"strike": "爆发",
	"ward": "守护",
	"tempo": "控场"
}


static func build_preview(instance: Dictionary) -> Dictionary:
	if instance.is_empty():
		return {}
	var monster_id := str(instance.get("monsterId", ""))
	var monster := MonsterDb.get_monster(monster_id)
	if monster.is_empty():
		return {}
	var evolution: Dictionary = monster.get("evolution", {})
	var target_id := str(evolution.get("target", ""))
	if target_id.is_empty() or not MonsterDb.has_monster(target_id):
		return {
			"has_evolution": false,
			"summary": "当前形态已到达稳定期"
		}
	var level := int(instance.get("level", 1))
	var nature := str(instance.get("nature", ""))
	var target := MonsterDb.get_monster(target_id)
	# 统一公式：进化预览也走 StatCalculator
	var old_stats := StatCalculator.calc(monster_id, level, nature)
	var new_stats := StatCalculator.calc(target_id, level, nature)
	var insight: Dictionary = instance.get("evolutionInsight", {})
	var report := _build_report_core(monster, target, old_stats, new_stats, insight)
	report["has_evolution"] = true
	report["target_id"] = target_id
	report["target_name"] = str(target.get("name", target_id))
	report["required_level"] = int(evolution.get("level", 1))
	report["required_item"] = str(evolution.get("item", ""))
	return report


static func build_report(before_instance: Dictionary, after_instance: Dictionary) -> Dictionary:
	var old_id := str(before_instance.get("monsterId", ""))
	var new_id := str(after_instance.get("monsterId", ""))
	var level := int(after_instance.get("level", before_instance.get("level", 1)))
	var nature := str(after_instance.get("nature", before_instance.get("nature", "")))
	var old_monster := MonsterDb.get_monster(old_id)
	var new_monster := MonsterDb.get_monster(new_id)
	# 统一公式：进化前后对比也走 StatCalculator
	var old_stats := StatCalculator.calc(old_id, level, nature)
	var new_stats := StatCalculator.calc(new_id, level, nature)
	var insight: Dictionary = before_instance.get("evolutionInsight", {})
	var report := _build_report_core(old_monster, new_monster, old_stats, new_stats, insight)
	report["oldMonsterId"] = old_id
	report["newMonsterId"] = new_id
	report["oldName"] = str(old_monster.get("name", old_id))
	report["newName"] = str(new_monster.get("name", new_id))
	report["createdAt"] = int(Time.get_unix_time_from_system() * 1000.0)
	return report


static func make_history_entry(report: Dictionary) -> Dictionary:
	return {
		"oldMonsterId": str(report.get("oldMonsterId", "")),
		"newMonsterId": str(report.get("newMonsterId", "")),
		"oldName": str(report.get("oldName", "")),
		"newName": str(report.get("newName", "")),
		"summary": str(report.get("summary", "")),
		"playUpgrade": str(report.get("play_upgrade", "")),
		"socialInsight": report.get("social_insight", {}).duplicate(true),
		"createdAt": int(report.get("createdAt", Time.get_unix_time_from_system() * 1000.0))
	}


static func make_social_insight(instance: Dictionary, social_result: Dictionary) -> Dictionary:
	if instance.is_empty() or social_result.is_empty():
		return {}
	return {
		"label": str(social_result.get("label", "社交启发")),
		"score": int(social_result.get("score", 0)),
		"tags": social_result.get("tags", []).duplicate(true),
		"source": "social",
		"createdAt": int(Time.get_unix_time_from_system() * 1000.0)
	}


static func insight_label(insight: Dictionary) -> String:
	if insight.is_empty():
		return "社交启发: 无"
	var tags: Array = insight.get("tags", [])
	var tag_text := "、".join(tags.slice(0, mini(2, tags.size()))) if not tags.is_empty() else str(insight.get("label", "社交启发"))
	return "社交启发: %s %d分" % [tag_text, int(insight.get("score", 0))]


static func _build_report_core(old_monster: Dictionary, new_monster: Dictionary, old_stats: Dictionary, new_stats: Dictionary, insight: Dictionary) -> Dictionary:
	if old_monster.is_empty() or new_monster.is_empty():
		return {}
	var old_skill := MonsterDb.normalize_skill(old_monster.get("skill", {}))
	var new_skill := MonsterDb.normalize_skill(new_monster.get("skill", {}))
	var stat_lines := _stat_lines(old_stats, new_stats)
	var play_upgrade := _play_upgrade_text(old_skill, new_skill, new_monster)
	var social_text := insight_label(insight)
	var summary := "%s -> %s，%s" % [
		str(old_monster.get("name", "")),
		str(new_monster.get("name", "")),
		play_upgrade
	]
	return {
		"summary": summary,
		"stat_lines": stat_lines,
		"stat_summary": " / ".join(stat_lines),
		"old_skill": _skill_label(old_skill),
		"new_skill": _skill_label(new_skill),
		"role_before": _role_label(old_skill),
		"role_after": _role_label(new_skill),
		"play_upgrade": play_upgrade,
		"social_text": social_text,
		"social_insight": insight.duplicate(true)
	}


static func _stat_lines(old_stats: Dictionary, new_stats: Dictionary) -> Array:
	var result: Array = []
	for key in ["hp", "atk", "def", "spd"]:
		var old_value := int(old_stats.get(key, 0))
		var new_value := int(new_stats.get(key, 0))
		var delta := new_value - old_value
		result.append("%s %+d" % [key.to_upper(), delta])
	return result


static func _skill_label(skill: Dictionary) -> String:
	if skill.is_empty():
		return "无技能"
	return "%s(%s/%d)" % [
		str(skill.get("name", "技能")),
		_role_label(skill),
		int(skill.get("cost", 0))
	]


static func _role_label(skill: Dictionary) -> String:
	var role := str(skill.get("type", "strike"))
	return str(ROLE_LABELS.get(role, role))


static func _play_upgrade_text(old_skill: Dictionary, new_skill: Dictionary, new_monster: Dictionary) -> String:
	var new_role := str(new_skill.get("type", "strike"))
	var fragments: Array = []
	if new_monster.has("leaderSkill"):
		fragments.append("解锁队长技")
	if new_role == "ward":
		fragments.append("守护能力升级")
	elif new_role == "tempo":
		fragments.append("控场压制升级")
	else:
		fragments.append("爆发输出升级")
	var old_cost := int(old_skill.get("cost", 0))
	var new_cost := int(new_skill.get("cost", 0))
	if old_cost > 0 and new_cost > 0 and new_cost <= old_cost:
		fragments.append("更快启动")
	elif new_cost > old_cost:
		fragments.append("更强但蓄力更久")
	return "，".join(fragments)

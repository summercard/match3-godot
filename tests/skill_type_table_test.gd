extends SceneTree

const SkillTypeTableScript := preload("res://src/data/skill_type_table.gd")
const LeaderSkillDbScript := preload("res://src/data/leader_skill_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(not SkillTypeTableScript.get_active_effect("damage").is_empty(), "active damage type should be managed by the type table")
	_expect(str(SkillTypeTableScript.get_active_effect("guard").get("handler", "")) == "_apply_guard", "active guard should resolve its executor handler")
	_expect(str(SkillTypeTableScript.get_leader_burst_effect("team_shield").get("handler", "")) == "_team_shield", "team shield should resolve its executor handler")
	_expect(SkillTypeTableScript.leader_burst_requires_leader("team_shield"), "type table should manage which leader effects require their caster")
	_expect(not SkillTypeTableScript.leader_burst_requires_leader("shuffle_board"), "type table should keep board-only effects independent from the caster")
	_expect(SkillTypeTableScript.get_leader_burst_effect("unknown").is_empty(), "unknown effect types should not silently resolve")
	var rows := SkillTypeTableScript.get_management_rows()
	_expect(rows.size() >= 30, "skill type table should expose every active, passive, and burst type as management rows")
	for row in rows:
		_expect(not str(row.get("kind", "")).is_empty() and not str(row.get("name", "")).is_empty(), "every management row should have an id and display name")
	for skill_id in LeaderSkillDbScript.FORMAL_LEADER_SKILLS:
		var skill := LeaderSkillDbScript.get_leader_skill(str(skill_id))
		for effect in LeaderSkillDbScript.get_burst_effects(skill, str(skill.get("visual", {}).get("element", "fire"))):
			_expect(not SkillTypeTableScript.get_leader_burst_effect(str(effect.get("kind", ""))).is_empty(), "%s should only use a registered leader burst effect" % skill_id)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SkillTypeTable] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SkillTypeTable] " + failure)
	quit(1)

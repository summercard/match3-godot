extends SceneTree

const EcologyBondRulesScript = preload("res://src/core/ecology_bond_rules.gd")
const MonsterDBScript = preload("res://src/data/monster_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_monster_identity()
	_test_starter_bond()
	_test_bond_branches()
	_test_ecology_progress()
	_test_ecology_targets_without_rewards()
	_finish()


func _test_monster_identity() -> void:
	var fire_starter: Dictionary = MonsterDBScript.get_monster("monster_001")
	var identity: Dictionary = EcologyBondRulesScript.get_monster_identity(fire_starter)
	_expect(identity.get("role", "") == "strike", "fire starter should be a strike role")
	_expect(identity.get("roleLabel", "") == "输出手", "fire starter should expose readable role label")
	_expect(identity.get("ecology", {}).get("name", "") == "熔火生态", "fire starter should expose ecology")
	_expect(str(identity.get("bondHint", "")).contains("守护手"), "identity should explain bond direction")


func _test_starter_bond() -> void:
	var team := [
		MonsterDBScript.get_monster("monster_001"),
		MonsterDBScript.get_monster("monster_002"),
		MonsterDBScript.get_monster("monster_003")
	]
	var bonds: Array = EcologyBondRulesScript.calc_team_bonds(team)
	_expect(not bonds.is_empty(), "starter team should produce a bond result")
	_expect(str(bonds[0].get("id", "")) == "pioneer_triad", "starter roles should activate pioneer bond")
	_expect(str(bonds[0].get("summary", "")).contains("Boss"), "pioneer bond should explain use case")


func _test_bond_branches() -> void:
	var team := [
		_make_unit("monster_001", {"socialExp": 70}, ["social_bold"]),
		_make_unit("monster_002", {"socialExp": 55}, ["social_steady"]),
		_make_unit("monster_003", {"socialExp": 20}, ["social_bold"])
	]
	var branches: Array = EcologyBondRulesScript.calc_team_bond_branches(team)
	_expect(not branches.is_empty(), "team should produce bond branches")
	_expect(str(branches[0].get("id", "")) == "branch_pioneer", "starter roles should activate pioneer branch first")
	var has_companion := false
	var has_trait := false
	for branch: Dictionary in branches:
		if str(branch.get("id", "")) == "branch_companion":
			has_companion = true
		if str(branch.get("id", "")).begins_with("branch_trait_"):
			has_trait = true
		_expect(not branch.has("statBonus"), "first bond branch version should not expose stat bonus")
	_expect(has_companion, "social exp should activate companion branch")
	_expect(has_trait, "shared social style should activate trait branch")


func _test_ecology_progress() -> void:
	var monsters: Array = [
		MonsterDBScript.get_monster("monster_001"),
		MonsterDBScript.get_monster("monster_002"),
		MonsterDBScript.get_monster("monster_003")
	]
	var progress: Array = EcologyBondRulesScript.get_ecology_progress(monsters, ["monster_001", "monster_003"])
	_expect(progress.size() == 3, "three starter ecosystems should be counted")
	var total_owned := 0
	for group: Dictionary in progress:
		total_owned += int(group.get("owned", 0))
		_expect(int(group.get("total", 0)) >= 1, "each ecology group should count total monsters")
	_expect(total_owned == 2, "ecology progress should count captured species")


func _test_ecology_targets_without_rewards() -> void:
	var monsters: Array = [
		MonsterDBScript.get_monster("monster_001"),
		MonsterDBScript.get_monster("monster_006"),
		MonsterDBScript.get_monster("monster_002"),
		MonsterDBScript.get_monster("monster_003")
	]
	var targets: Array = EcologyBondRulesScript.get_ecology_targets(monsters, ["monster_001", "monster_003"])
	_expect(not targets.is_empty(), "ecology targets should be generated")
	var fire_target: Dictionary = {}
	for target: Dictionary in targets:
		if str(target.get("id", "")) == "volcanic":
			fire_target = target
			break
	_expect(not fire_target.is_empty(), "fire ecology target should exist")
	_expect(int(fire_target.get("owned", 0)) == 1, "fire target should count owned species")
	_expect(int(fire_target.get("total", 0)) == 2, "fire target should count total species")
	_expect(str(fire_target.get("statusLabel", "")).contains("还差"), "incomplete target should explain gap")
	_expect(str(fire_target.get("suggestion", "")).contains("下一只"), "target should suggest next missing species")
	_expect(not fire_target.has("reward"), "first ecology target version should not expose reward")

	var role_target: Dictionary = EcologyBondRulesScript.get_role_collection_target(monsters, ["monster_001", "monster_003"])
	_expect(str(role_target.get("id", "")) == "pioneer_roles", "role target should expose stable id")
	_expect(int(role_target.get("owned", 0)) >= 2, "role target should count owned required roles")
	_expect(not role_target.has("reward"), "role target should not expose reward")


func _make_unit(monster_id: String, social_profile: Dictionary, bond_traits: Array) -> Dictionary:
	var unit: Dictionary = MonsterDBScript.get_monster(monster_id).duplicate(true)
	unit["monsterId"] = monster_id
	unit["socialProfile"] = social_profile
	unit["bondTraits"] = bond_traits
	return unit


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EcologyBond] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[EcologyBond] " + failure)
		quit(1)

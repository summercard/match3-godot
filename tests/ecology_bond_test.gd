extends SceneTree

const EcologyBondRulesScript = preload("res://src/core/ecology_bond_rules.gd")
const MonsterDBScript = preload("res://src/data/monster_db.gd")
const MonsterPoolScript = preload("res://src/core/monster_pool.gd")

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
	var starter_id := str(MonsterPoolScript.DEFAULT_STARTERS[0])
	var identity: Dictionary = EcologyBondRulesScript.get_monster_identity(MonsterDBScript.get_monster(starter_id))
	_expect(not str(identity.get("role", "")).is_empty(), "current starter should expose a role")
	_expect(not str(identity.get("roleLabel", "")).is_empty(), "current starter should expose a readable role label")
	_expect(not str((identity.get("ecology", {}) as Dictionary).get("id", "")).is_empty(), "current starter should expose ecology")
	_expect(not str(identity.get("bondHint", "")).is_empty(), "identity should explain a bond direction")


func _test_starter_bond() -> void:
	var team: Array = []
	for starter_id in MonsterPoolScript.DEFAULT_STARTERS:
		team.append(MonsterDBScript.get_monster(str(starter_id)))
	var bonds: Array = EcologyBondRulesScript.calc_team_bonds(team)
	_expect(not bonds.is_empty(), "starter team should produce a bond result")
	_expect(not str((bonds[0] as Dictionary).get("summary", "")).is_empty(), "starter bond should explain its current result")


func _test_bond_branches() -> void:
	var starter_ids: Array = MonsterPoolScript.DEFAULT_STARTERS
	var team := [
		_make_unit(str(starter_ids[0]), {"socialExp": 70}, ["social_bold"]),
		_make_unit(str(starter_ids[1]), {"socialExp": 55}, ["social_bold"]),
		_make_unit(str(starter_ids[2]), {"socialExp": 20}, ["social_steady"])
	]
	var branches: Array = EcologyBondRulesScript.calc_team_bond_branches(team)
	_expect(not branches.is_empty(), "team should produce bond branches")
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
	var monsters: Array = []
	for starter_id in MonsterPoolScript.DEFAULT_STARTERS:
		monsters.append(MonsterDBScript.get_monster(str(starter_id)))
	var progress: Array = EcologyBondRulesScript.get_ecology_progress(monsters, [str(MonsterPoolScript.DEFAULT_STARTERS[0]), str(MonsterPoolScript.DEFAULT_STARTERS[2])])
	_expect(not progress.is_empty(), "current starter ecosystems should be counted")
	var total_owned := 0
	for group: Dictionary in progress:
		total_owned += int(group.get("owned", 0))
		_expect(int(group.get("total", 0)) >= 1, "each ecology group should count total monsters")
	_expect(total_owned == 2, "ecology progress should count captured species")


func _test_ecology_targets_without_rewards() -> void:
	var monsters: Array = []
	for starter_id in MonsterPoolScript.DEFAULT_STARTERS:
		monsters.append(MonsterDBScript.get_monster(str(starter_id)))
	var captured_ids := [str(MonsterPoolScript.DEFAULT_STARTERS[0]), str(MonsterPoolScript.DEFAULT_STARTERS[2])]
	var targets: Array = EcologyBondRulesScript.get_ecology_targets(monsters, captured_ids)
	_expect(not targets.is_empty(), "ecology targets should be generated")
	var target: Dictionary = targets[0]
	_expect(int(target.get("total", 0)) >= 1, "ecology target should count current species")
	_expect(not str(target.get("statusLabel", "")).is_empty(), "target should expose a current completion state")
	_expect(not str(target.get("suggestion", "")).is_empty(), "target should suggest a current next step")
	_expect(not target.has("reward"), "first ecology target version should not expose reward")

	var role_target: Dictionary = EcologyBondRulesScript.get_role_collection_target(monsters, captured_ids)
	_expect(str(role_target.get("id", "")) == "pioneer_roles", "role target should expose stable id")
	_expect(int(role_target.get("owned", 0)) >= 0 and int(role_target.get("total", 0)) == 3, "role target should count current required roles")
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

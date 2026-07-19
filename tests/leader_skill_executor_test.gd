extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_first_batch_formal_skills()
	_test_second_batch_formal_skills()
	_test_third_batch_formal_skills()
	_test_fourth_batch_formal_skills()
	_test_remaining_formal_skills()
	_test_boss_leader_skill_conversions()
	_test_starter_line_custom_leader_skills()
	_test_fire_damage()
	_test_water_freeze()
	_test_dark_pierce()
	_test_grass_heal()
	_test_light_convert()
	_test_wind_weaken()
	_test_dark_lifesteal()
	_test_earth_guard()
	_test_team_shield()
	_test_thunder_stun()
	_test_legacy_element_normalization()
	_finish()


func _test_first_batch_formal_skills() -> void:
	var expected := {
		"monster_001": "LS_MONSTER_001",
		"monster_002": "LS_MONSTER_002",
		"monster_003": "LS_MONSTER_003",
		"monster_004": "LS_MONSTER_004",
		"monster_005": "LS_MONSTER_005",
		"monster_006": "LS_MONSTER_006",
		"monster_007": "LS_MONSTER_007",
		"monster_008": "LS_MONSTER_008",
		"monster_009": "LS_MONSTER_009",
		"monster_010": "LS_MONSTER_010",
		"monster_011": "LS_MONSTER_011",
		"monster_012": "LS_MONSTER_012",
		"monster_013": "LS_MONSTER_013"
	}
	for monster_id in expected:
		var monster: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
		var skill_id := str(monster.get("leaderSkill", ""))
		_expect(skill_id == str(expected[monster_id]), "%s should point at its formal leader skill" % monster_id)
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		_expect(not skill.is_empty(), "%s leader skill should resolve" % monster_id)
		_expect(skill.has("visual"), "%s leader skill should have visual metadata" % monster_id)
	_expect(is_equal_approx(LeaderSkillDb.get_leader_hp_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_001")), 1.06), "monster_001 should grant HP+6%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_001"), "grass"), 1.08), "monster_001 should grant grass damage +8%")
	_expect(LeaderSkillDb.get_leader_combo_start(LeaderSkillDb.get_leader_skill("LS_MONSTER_008")) == 2, "monster_008 should grant opening combo +2")


func _test_second_batch_formal_skills() -> void:
	var expected := {
		"monster_014": "LS_MONSTER_014",
		"monster_015": "LS_MONSTER_015",
		"monster_016": "LS_MONSTER_016",
		"monster_017": "LS_MONSTER_017",
		"monster_018": "LS_MONSTER_018",
		"monster_019": "LS_MONSTER_019",
		"monster_020": "LS_MONSTER_020",
		"monster_021": "LS_MONSTER_021",
		"monster_022": "LS_MONSTER_022",
		"monster_023": "LS_MONSTER_023",
		"monster_024": "LS_MONSTER_024",
		"monster_025": "LS_MONSTER_025",
		"monster_026": "LS_MONSTER_026",
		"monster_027": "LS_MONSTER_027",
		"monster_028": "LS_MONSTER_028"
	}
	for monster_id in expected:
		var monster: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
		var skill_id := str(monster.get("leaderSkill", ""))
		_expect(skill_id == str(expected[monster_id]), "%s should point at its formal leader skill" % monster_id)
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		_expect(not skill.is_empty(), "%s leader skill should resolve" % monster_id)
		_expect(skill.has("visual"), "%s leader skill should have visual metadata" % monster_id)
	_expect(is_equal_approx(LeaderSkillDb.get_leader_def_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_014")), 0.94), "monster_014 should reduce damage by 6%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_019"), "dark"), 1.25), "monster_019 should grant dark damage +25%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_hp_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_022")), 1.15), "monster_022 should grant HP+15%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_022"), "grass"), 1.19), "monster_022 should grant grass damage +19%")


func _test_third_batch_formal_skills() -> void:
	var expected := {
		"monster_029": "LS_MONSTER_029",
		"monster_030": "LS_MONSTER_030",
		"monster_031": "LS_MONSTER_031",
		"monster_032": "LS_MONSTER_032",
		"monster_033": "LS_MONSTER_033",
		"monster_034": "LS_MONSTER_034",
		"monster_035": "LS_MONSTER_035",
		"monster_036": "LS_MONSTER_036",
		"monster_037": "LS_MONSTER_037",
		"monster_038": "LS_MONSTER_038",
		"monster_039": "LS_MONSTER_039",
		"monster_040": "LS_MONSTER_040",
		"monster_041": "LS_MONSTER_041",
		"monster_042": "LS_MONSTER_042",
		"monster_043": "LS_MONSTER_043"
	}
	for monster_id in expected:
		var monster: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
		var skill_id := str(monster.get("leaderSkill", ""))
		_expect(skill_id == str(expected[monster_id]), "%s should point at its third batch leader skill" % monster_id)
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		_expect(not skill.is_empty(), "%s third batch leader skill should resolve" % monster_id)
		_expect(skill.has("visual"), "%s third batch leader skill should have visual metadata" % monster_id)
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_030"), "grass"), 1.18), "monster_030 should grant grass damage +18%")
	_expect(LeaderSkillDb.get_leader_combo_start(LeaderSkillDb.get_leader_skill("LS_MONSTER_033")) == 2, "monster_033 should grant opening combo +2")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_038"), "light"), 1.25), "monster_038 should grant light damage +25%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_041"), "dark"), 1.18), "monster_041 should grant dark damage +18%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_def_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_043")), 0.91), "monster_043 should reduce damage by 9%")


func _test_fourth_batch_formal_skills() -> void:
	var expected := {
		"monster_044": "LS_MONSTER_044",
		"monster_045": "LS_MONSTER_045",
		"monster_046": "LS_MONSTER_046",
		"monster_047": "LS_MONSTER_047",
		"monster_048": "LS_MONSTER_048",
		"monster_049": "LS_MONSTER_049",
		"monster_050": "LS_MONSTER_050",
		"monster_051": "LS_MONSTER_051",
		"monster_052": "LS_MONSTER_052",
		"monster_053": "LS_MONSTER_053",
		"monster_054": "LS_MONSTER_054",
		"monster_055": "LS_MONSTER_055",
		"monster_056": "LS_MONSTER_056",
		"monster_057": "LS_MONSTER_057",
		"monster_058": "LS_MONSTER_058"
	}
	for monster_id in expected:
		var monster: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
		var skill_id := str(monster.get("leaderSkill", ""))
		_expect(skill_id == str(expected[monster_id]), "%s should point at its fourth batch leader skill" % monster_id)
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		_expect(not skill.is_empty(), "%s fourth batch leader skill should resolve" % monster_id)
		_expect(skill.has("visual"), "%s fourth batch leader skill should have visual metadata" % monster_id)
	_expect(is_equal_approx(LeaderSkillDb.get_leader_def_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_044")), 0.87), "monster_044 should reduce damage by 13%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_046"), "dark"), 1.18), "monster_046 should grant dark damage +18%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_hp_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_050")), 1.09), "monster_050 should grant HP+9%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_050"), "grass"), 1.12), "monster_050 should grant grass damage +12%")
	_expect(LeaderSkillDb.get_leader_combo_start(LeaderSkillDb.get_leader_skill("LS_MONSTER_052")) == 1, "monster_052 should grant opening combo +1")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_hp_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_057")), 1.12), "monster_057 should grant HP+12%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_058"), "light"), 1.12), "monster_058 should grant light damage +12%")


func _test_remaining_formal_skills() -> void:
	for i in range(59, 104):
		var monster_id := "monster_%03d" % i
		var skill_id := "LS_MONSTER_%03d" % i
		var monster: Dictionary = MonsterDb.MONSTER_DB.get(monster_id, {})
		_expect(str(monster.get("leaderSkill", "")) == skill_id, "%s should point at its remaining-batch leader skill" % monster_id)
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		_expect(not skill.is_empty(), "%s remaining-batch leader skill should resolve" % monster_id)
		_expect(skill.has("visual"), "%s remaining-batch leader skill should have visual metadata" % monster_id)
	for i in range(1, 9):
		var boss_id := "monster_boss_%03d" % i
		var skill_id := "LS_BOSS_%03d" % i
		var boss: Dictionary = MonsterDb.MONSTER_DB.get(boss_id, {})
		_expect(str(boss.get("leaderSkill", "")) == skill_id, "%s should point at its boss leader skill" % boss_id)
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		_expect(not skill.is_empty(), "%s boss leader skill should resolve" % boss_id)
		_expect(skill.has("visual"), "%s boss leader skill should have visual metadata" % boss_id)
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_069"), "water"), 1.25), "monster_069 should normalize frost damage to water +25%")
	_expect(LeaderSkillDb.get_leader_combo_start(LeaderSkillDb.get_leader_skill("LS_MONSTER_083")) == 2, "monster_083 should grant opening combo +2")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_086"), "dark"), 1.0), "monster_086 should remove its old void-damage passive")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_MONSTER_103"), "fire"), 1.25), "monster_103 should grant fire damage +25%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_hp_boost(LeaderSkillDb.get_leader_skill("LS_BOSS_001")), 1.25), "boss 001 should grant HP+25%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_def_boost(LeaderSkillDb.get_leader_skill("LS_BOSS_002")), 0.82), "boss 002 should reduce damage by 18%")
	_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(LeaderSkillDb.get_leader_skill("LS_BOSS_008"), "fire"), 1.35), "boss 008 should grant fire damage +35%")


func _test_boss_leader_skill_conversions() -> void:
	var expected_conversions := {
		"LS_BOSS_001": "grass",
		"LS_BOSS_003": "light",
		"LS_BOSS_004": "earth",
		"LS_BOSS_006": "water",
		"LS_BOSS_007": "dark"
	}
	for skill_id in expected_conversions:
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		var effects: Array = skill.get("burstEffects", [])
		_expect(effects.size() == 1, "%s should only run the gem conversion burst" % skill_id)
		var effect: Dictionary = effects[0] if not effects.is_empty() else {}
		_expect(str(effect.get("kind", "")) == "convert_gems", "%s should convert gems" % skill_id)
		_expect(int(effect.get("count", 0)) == 3, "%s should convert exactly 3 gems" % skill_id)
		_expect(str(effect.get("target_element", "")) == str(expected_conversions[skill_id]), "%s should convert to its own element" % skill_id)
	for guarded_skill_id in ["LS_BOSS_002", "LS_BOSS_005"]:
		var skill := LeaderSkillDb.get_leader_skill(guarded_skill_id)
		var effects: Array = skill.get("burstEffects", [])
		var effect: Dictionary = effects[0] if not effects.is_empty() else {}
		_expect(str(effect.get("kind", "")) == "guard", "%s should stay as the shared guard boss skill" % guarded_skill_id)
	var boss_008_effects: Array = LeaderSkillDb.get_leader_skill("LS_BOSS_008").get("burstEffects", [])
	var boss_008: Dictionary = boss_008_effects[0] if not boss_008_effects.is_empty() else {}
	_expect(str(boss_008.get("kind", "")) == "clear_element_gems_damage_highest_hp", "LS_BOSS_008 should clear fire gems and hit the highest-HP enemy")
	_expect(str(boss_008.get("target_element", "")) == "fire" and is_equal_approx(float(boss_008.get("ratio", 0.0)), 0.2), "LS_BOSS_008 should deal ATK x20% per cleared fire gem")


func _test_starter_line_custom_leader_skills() -> void:
	for skill_id in ["LS_MONSTER_093", "LS_MONSTER_094"]:
		var skill := LeaderSkillDb.get_leader_skill(skill_id)
		_expect(LeaderSkillDb.get_leader_combo_start(skill) == 0, "%s should no longer grant opening combo" % skill_id)
		_expect(is_equal_approx(LeaderSkillDb.get_leader_atk_boost(skill, "wind"), 1.0), "%s should no longer boost wind damage" % skill_id)
		var effect: Dictionary = (skill.get("burstEffects", []) as Array)[0]
		_expect(str(effect.get("kind", "")) == "damage", "%s should be a fire damage burst" % skill_id)
		_expect(is_equal_approx(float(effect.get("multiplier", 0.0)), 3.0), "%s should deal ATK 300%% damage" % skill_id)
	for data in [
		{"skill": "LS_MONSTER_002", "ratio": 0.20},
		{"skill": "LS_MONSTER_003", "ratio": 0.30},
		{"skill": "LS_MONSTER_004", "ratio": 0.40}
	]:
		var skill := LeaderSkillDb.get_leader_skill(str(data["skill"]))
		_expect(is_equal_approx(LeaderSkillDb.get_leader_hp_boost(skill), 1.0), "%s should not grant passive HP boost" % str(data["skill"]))
		var effect: Dictionary = (skill.get("burstEffects", []) as Array)[0]
		_expect(str(effect.get("kind", "")) == "heal", "%s should remain a single-target heal" % str(data["skill"]))
		_expect(is_equal_approx(float(effect.get("ratio", 0.0)), float(data["ratio"])), "%s should use the requested heal ratio" % str(data["skill"]))
	for data in [
		{"skill": "LS_MONSTER_053", "ratio": 0.20},
		{"skill": "LS_MONSTER_055", "ratio": 0.30}
	]:
		var skill := LeaderSkillDb.get_leader_skill(str(data["skill"]))
		_expect(is_equal_approx(LeaderSkillDb.get_leader_hp_boost(skill), 1.0), "%s should not grant passive HP boost" % str(data["skill"]))
		var effect: Dictionary = (skill.get("burstEffects", []) as Array)[0]
		_expect(str(effect.get("kind", "")) == "team_shield", "%s should shield the whole team" % str(data["skill"]))
		_expect(is_equal_approx(float(effect.get("ratio", 0.0)), float(data["ratio"])), "%s should use the requested shield ratio" % str(data["skill"]))


func _test_fire_damage() -> void:
	var battle := _ready_battle("monster_095")
	var before_hp := int(battle.enemies[0].get("hp", 0))
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	_expect(str(burst.get("element", "")) == "fire", "fire leader should produce a fire burst")
	_expect(int(burst.get("remaining_damage", 0)) > 0, "fire burst should deal damage")
	_expect(int(battle.enemies[0].get("hp", 0)) < before_hp, "fire burst should reduce enemy HP")
	_free_battle(battle)


func _test_water_freeze() -> void:
	var battle := _ready_battle("monster_067")
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var freezes := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "status" and str(effect.get("status", "")) == "freeze":
			freezes = true
	_expect(freezes, "frost burst should request freeze status")
	_expect(is_equal_approx(battle._status_effect.get_freeze_atk_multiplier(0), 0.7), "frost burst should store freeze status")
	_free_battle(battle)


func _test_dark_pierce() -> void:
	var battle := _ready_battle("monster_084")
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var regenerates := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "heal_over_time" and int(effect.get("turns", 0)) == 3 and is_equal_approx(float(effect.get("ratio", 0.0)), 0.2):
			regenerates = true
	_expect(regenerates, "monster_084 should grant three enemy actions of 20% self regeneration")
	_expect(int(burst.get("damage", 0)) == 0, "monster_084 should no longer deal piercing dark damage")
	_free_battle(battle)


func _test_grass_heal() -> void:
	var battle := _ready_battle("monster_002")
	battle.player_team[1]["hp"] = maxi(1, int(battle.player_team[1].get("maxHP", 1)) / 3)
	var before_hp := int(battle.player_team[1].get("hp", 0))
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var healed := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "heal" and int(effect.get("amount", 0)) > 0:
			healed = true
	_expect(healed, "grass burst should include healing")
	_expect(int(battle.player_team[1].get("hp", 0)) > before_hp, "grass burst should heal the lowest ally")
	_free_battle(battle)


func _test_light_convert() -> void:
	var effects: Array = LeaderSkillDb.get_leader_skill("LS_MONSTER_035").get("burstEffects", [])
	var effect: Dictionary = effects[0] if not effects.is_empty() else {}
	_expect(str(effect.get("kind", "")) == "convert_gems", "monster_035 should convert edge gems")
	_expect(int(effect.get("count", 0)) == 8 and int(effect.get("edge_layers", 0)) == 2 and str(effect.get("target_element", "")) == "light", "monster_035 should convert eight non-light gems from the outer two rings")


func _test_wind_weaken() -> void:
	var battle := _ready_battle("monster_005")
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var weakens := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "weaken" and int(effect.get("turns", 0)) == 2:
			weakens = true
	_expect(weakens, "wind burst should weaken for two turns")
	_expect(int(battle.enemy_tempo_mods.get(0, {}).get("turns", 0)) == 2, "wind burst should store the weaken state")
	_free_battle(battle)


func _test_dark_lifesteal() -> void:
	var battle := _ready_battle("monster_017")
	battle.player_team[1]["hp"] = maxi(1, int(battle.player_team[1].get("maxHP", 1)) / 3)
	var before_hp := int(battle.player_team[1].get("hp", 0))
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var lifesteals := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "lifesteal" and int(effect.get("amount", 0)) > 0:
			lifesteals = true
	_expect(lifesteals, "dark burst should lifesteal")
	_expect(int(battle.player_team[1].get("hp", 0)) > before_hp, "dark lifesteal should heal the lowest ally")
	_free_battle(battle)


func _test_earth_guard() -> void:
	var battle := _ready_battle("monster_014")
	battle.player_team[1]["hp"] = maxi(1, int(battle.player_team[1].get("maxHP", 1)) / 3)
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var guards := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "guard" and is_equal_approx(float(effect.get("reduction", 0.0)), 0.25):
			guards = true
	_expect(guards, "earth burst should guard the lowest ally")
	_free_battle(battle)


func _test_team_shield() -> void:
	var battle := _ready_battle("monster_053")
	var leader_max_hp := int(battle.player_team[0].get("maxHP", 0))
	var expected_shield := maxi(1, int(round(float(leader_max_hp) * 0.20)))
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var shields := 0
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "team_shield":
			_expect(int(effect.get("amount", 0)) == expected_shield, "team shield should be based on leader max HP")
			for target: Dictionary in effect.get("targets", []):
				shields += 1
				_expect(int(target.get("amount", 0)) == expected_shield, "each living ally should receive the same shield value")
	_expect(shields == battle.player_team.size(), "team shield should apply to every living ally")
	for monster: Dictionary in battle.player_team:
		var shield: Dictionary = battle.player_absorb_shields.get(str(monster.get("id", "")), {})
		_expect(int(shield.get("current_hp", 0)) == expected_shield, "stored shield should match expected value")
	_free_battle(battle)


func _test_thunder_stun() -> void:
	var battle := _ready_battle("monster_026")
	var burst: Dictionary = battle.consume_ready_leader_burst().get("leader_skill_log", {})
	var stuns := false
	for effect: Dictionary in burst.get("effects", []):
		if str(effect.get("kind", "")) == "status" and str(effect.get("status", "")) == "stun" and int(effect.get("turns", 0)) == 1:
			stuns = true
	_expect(stuns, "thunder burst should stun for one turn")
	_expect(battle._status_effect.is_enemy_stunned(0), "thunder burst should store stun status")
	_free_battle(battle)


func _test_legacy_element_normalization() -> void:
	var ice_effects := LeaderSkillDb.get_burst_effects({}, "ice")
	var star_effects := LeaderSkillDb.get_burst_effects({}, "star")
	var void_effects := LeaderSkillDb.get_burst_effects({}, "void")
	_expect(str((ice_effects[0] as Dictionary).get("kind", "")) == "guard", "legacy ice should normalize to water burst")
	_expect(str((star_effects[0] as Dictionary).get("kind", "")) == "convert_gems", "legacy star should normalize to light burst")
	_expect(str((void_effects[0] as Dictionary).get("kind", "")) == "damage", "legacy void should normalize to dark burst")
	_expect(str(LeaderSkillDb.get_leader_skill("ATK_BOOST_ICE").get("element", "")) == "water", "legacy ice skill id should normalize to water")
	_expect(str(LeaderSkillDb.get_leader_skill("ATK_BOOST_STAR").get("element", "")) == "light", "legacy star skill id should normalize to light")
	_expect(str(LeaderSkillDb.get_leader_skill("ATK_BOOST_VOID").get("element", "")) == "dark", "legacy void skill id should normalize to dark")


func _ready_battle(leader_id: String) -> BattleManager:
	var battle := BattleManagerScript.new()
	root.add_child(battle)
	battle.init([leader_id, "monster_002", "monster_011"], ["monster_014"], 12, 4, {
		"id": "leader_executor_test",
		"enemies": ["monster_014"],
		"enemyLevel": 4,
		"disableRandomElite": true
	}, "leader_executor_test")
	battle.enemies[0]["maxHP"] = 10000
	battle.enemies[0]["hp"] = 10000
	for monster: Dictionary in battle.player_team:
		battle.leader_charge_points[str(monster.get("id", ""))] = BattleManager.LEADER_CHARGE_MAX
	return battle


func _free_battle(battle: BattleManager) -> void:
	battle.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LeaderSkillExecutor] OK")
		quit(0)
	for failure: String in _failures:
		push_error("[LeaderSkillExecutor] " + failure)
	quit(1)

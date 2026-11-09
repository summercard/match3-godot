extends SceneTree

## 眩晕结算顺序回归：
## 1. 眩晕必须在 process_status_effects 消耗之前参与行动判定；
## 2. 挂眩晕的普攻怪当回合 0 伤害、无目标、不产生破招；
## 3. 同一场战斗里，眩晕让普攻怪晚 1 回合才第一次造成伤害，战斗因此多 1 回合才结束；
## 4. 眩晕命中后必定跳过整次行动，不再在结算时二次掷 50% 概率。

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StatusEffectScript = preload("res://src/battle/status_effect.gd")

const TEAM := ["monster_001", "monster_002", "monster_003"]
const SEED := 424242
const SURVIVAL_TURNS := 10

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_single_enemy_action()
	_test_thunder_gem_skips_action()
	_test_battle_lasts_one_turn_longer()
	_test_stun_is_deterministic()
	_finish()


func _test_single_enemy_action() -> void:
	var control := _run_single_enemy_action(false)
	var stunned := _run_single_enemy_action(true)
	print("[StunOrder] control damage=%d actions=%s" % [
		int(control["damage"]), JSON.stringify(control["actions"])])
	print("[StunOrder] stunned damage=%d actions=%s breakCount=%d" % [
		int(stunned["damage"]), JSON.stringify(stunned["actions"]), int(stunned["break_count"])])

	_expect(int(control["damage"]) > 0, "unstunned ordinary enemy should still deal damage, got %d" % int(control["damage"]))
	_expect((control["actions"] as Array).size() == 1, "unstunned ordinary enemy should take one action, got %d" % (control["actions"] as Array).size())
	_expect(int(stunned["damage"]) == 0, "stunned ordinary enemy must deal 0 damage this turn, got %d" % int(stunned["damage"]))
	_expect((stunned["actions"] as Array).size() == 1, "stunned ordinary enemy should still emit one skipped action, got %d" % (stunned["actions"] as Array).size())
	if (stunned["actions"] as Array).size() == 1:
		var action: Dictionary = (stunned["actions"] as Array)[0]
		_expect(bool(action.get("is_stunned", false)), "stunned action should be marked is_stunned, got %s" % str(action))
		_expect(action.get("target", "missing") == null, "stunned action must not pick a target, got %s" % str(action.get("target", "missing")))
		_expect(int(action.get("damage", -1)) == 0, "stunned action must report zero damage, got %s" % str(action.get("damage", "missing")))
		_expect(not bool(action.get("is_broken", false)), "ordinary enemy stun must not be reported as a break")
		_expect(str(action.get("attack_mode", "")) != "break", "ordinary enemy stun must not use break attack mode")
	_expect(int(stunned["break_count"]) == 0, "stunned ordinary enemy must not increment break_count, got %d" % int(stunned["break_count"]))
	_expect(not bool(stunned["has_status"]), "stun should be consumed after the skipped turn")
	_expect(not bool(control["has_status"]), "unstunned enemy should not carry a stun status")


## 从真实 5 颗雷宝石的施加路径进入，确认宝石命中的眩晕同样能跳过当回合行动。
func _test_thunder_gem_skips_action() -> void:
	seed(SEED)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_001"], 1, 1, stage, "stage_1_1")
	for monster: Dictionary in battle.player_team:
		monster["maxHP"] = 99999
		monster["hp"] = 99999
	var status = battle.get("_status_effect")
	battle.process_match_result({ "thunder": 5 }, 1)
	var applied: bool = status.has_status(0, "stun")
	var result: Dictionary = battle.enemy_action()
	var damage := 0
	var stunned := false
	for action: Dictionary in result.get("actions", []):
		damage += int(action.get("damage", 0))
		stunned = stunned or bool(action.get("is_stunned", false))
	print("[StunOrder] thunder5 applied=%s nextActionDamage=%d isStunned=%s" % [
		str(applied), damage, str(stunned)])
	_expect(applied, "a 5-thunder match should apply stun to the weakest ordinary enemy")
	_expect(damage == 0, "the stunned enemy should deal 0 damage on the same turn after a 5-thunder match, got %d" % damage)
	_expect(stunned, "the enemy action should be marked is_stunned after a 5-thunder match")
	battle.free()


func _test_battle_lasts_one_turn_longer() -> void:
	var control := _run_survival_battle(false)
	var stunned := _run_survival_battle(true)
	print("[StunOrder] survival control turns=%d result=%s" % [int(control["turns"]), str(control["result"])])
	print("[StunOrder] survival stunned turns=%d result=%s" % [int(stunned["turns"]), str(stunned["result"])])

	_expect(int(control["turns"]) == SURVIVAL_TURNS, "control battle should end after %d enemy turns, got %d" % [SURVIVAL_TURNS, int(control["turns"])])
	_expect(str(control["result"]) == "lose", "control battle should end in a loss, got %s" % str(control["result"]))
	_expect(str(stunned["result"]) == "lose", "stunned battle should still end in a loss, got %s" % str(stunned["result"]))
	_expect(int(stunned["turns"]) == int(control["turns"]) + 1,
		"stunned battle should last exactly one turn longer (%d -> %d)" % [int(control["turns"]), int(stunned["turns"])])


func _test_stun_is_deterministic() -> void:
	var status = StatusEffectScript.new()
	status.init_effects(1)
	status.apply_status_effect(0, "stun")
	var always_skips := true
	for _i in range(50):
		if not status.is_enemy_stunned(0):
			always_skips = false
			break
	_expect(always_skips, "an applied stun should always skip the action, not roll a second 50% chance")
	status.process_status_effects([{ "name": "enemy_001", "hp": 100, "maxHP": 100 }])
	_expect(not status.is_enemy_stunned(0), "a one-turn stun should be consumed by the enemy turn")


## 单回合对照：同一队、同一关卡、同一随机种子，只差敌方是否带眩晕。
func _run_single_enemy_action(with_stun: bool) -> Dictionary:
	seed(SEED)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_001"], 1, 1, stage, "stage_1_1")
	for monster: Dictionary in battle.player_team:
		monster["maxHP"] = 99999
		monster["hp"] = 99999
	var status = battle.get("_status_effect")
	if with_stun:
		status.apply_status_effect(0, "stun")
	var result: Dictionary = battle.enemy_action()
	var actions: Array = result.get("actions", [])
	var damage := 0
	for action: Dictionary in actions:
		damage += int(action.get("damage", 0))
	var payload := {
		"actions": actions,
		"damage": damage,
		"break_count": int(battle.break_count),
		"has_status": status.has_status(0, "stun")
	}
	battle.free()
	return payload


## 生存对照：把伙伴防御拉满后每次受击固定 1 点，血量 10 点。
## 这样两局的唯一差异就是第一次眩晕是否跳过一次行动，回合数必然相差 1。
func _run_survival_battle(with_stun: bool) -> Dictionary:
	seed(SEED)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(["monster_001"], ["enemy_001"], 1, 1, stage, "stage_1_1")
	battle.player_team[0]["def"] = 100000
	battle.player_team[0]["maxHP"] = SURVIVAL_TURNS
	battle.player_team[0]["hp"] = SURVIVAL_TURNS
	if with_stun:
		battle.get("_status_effect").apply_status_effect(0, "stun")
	var turns := 0
	while not battle.battle_over and turns < 50:
		turns += 1
		battle.enemy_action()
	var payload := {
		"turns": turns,
		"result": str(battle.battle_result),
		"hp": int(battle.player_team[0].get("hp", 0))
	}
	battle.free()
	return payload


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[StunOrder] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[StunOrder] " + failure)
	quit(1)

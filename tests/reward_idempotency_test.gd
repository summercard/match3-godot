extends SceneTree

const SceneResultScript = preload("res://src/ui/controllers/result_logic.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_battle_receipts_are_unique()
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager must be available")
	if storage == null:
		_finish()
		return

	var run_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var receipt_id := "battle_reward:idempotency-test-%s" % run_id
	var stage_id := "idempotency_test_stage_%s" % run_id
	var payload := {
		"result": "win",
		"battleId": "idempotency-test-%s" % run_id,
		"rewardReceiptId": receipt_id,
		"stageId": stage_id,
		"turnCount": 3,
		"maxTurns": 20,
		"playerLevel": 5,
		"enemyLevel": 1,
		"playerTeam": [{"id": "monster_001", "hp": 100, "maxHP": 100}],
		"enemies": [{"id": "enemy_001", "hp": 0, "maxHP": 50}],
		"stageRewards": {"gold": 40, "exp": 0},
		"capture_played_inline": true,
		"captured": false,
		"capture_target": {},
		"totalDamageDealt": {"fire": 50}
	}

	var before_player: Dictionary = storage.get_player().duplicate(true)
	var before_rewards: Dictionary = storage.load_rewards().duplicate(true)
	var first_result = SceneResultScript.new()
	root.add_child(first_result)
	first_result.initialize(null, payload)
	var after_first_player: Dictionary = storage.get_player().duplicate(true)
	var after_first_rewards: Dictionary = storage.load_rewards().duplicate(true)

	_expect(
		int(after_first_player.get("gold", 0)) == int(before_player.get("gold", 0)) + 40,
		"first settlement should grant battle gold once"
	)
	_expect(
		int(after_first_rewards.get("battleCount", 0)) == int(before_rewards.get("battleCount", 0)) + 1,
		"first settlement should increase battle count once"
	)
	_expect(storage.is_reward_receipt_claimed(receipt_id), "first settlement should persist its receipt")

	for repeat_index in range(9):
		first_result.initialize(null, payload)
	var after_repeat_player: Dictionary = storage.get_player().duplicate(true)
	var after_repeat_rewards: Dictionary = storage.load_rewards().duplicate(true)
	_expect(after_repeat_player == after_first_player, "reinitializing the same result node must not grant player rewards twice")
	_expect(after_repeat_rewards == after_first_rewards, "reinitializing the same result node must not update reward counters twice")
	_expect(bool(first_result.get("_reward_already_claimed")), "duplicate settlement should expose an already-claimed state")

	var second_result = SceneResultScript.new()
	root.add_child(second_result)
	second_result.initialize(null, payload)
	_expect(storage.get_player() == after_first_player, "a newly created result node must honor the persisted receipt")
	_expect(storage.load_rewards() == after_first_rewards, "a persisted receipt must block duplicate counters after scene recreation")

	var pending_id := "battle_reward:pending-test-%s" % run_id
	_expect(storage.begin_reward_receipt_claim(pending_id), "a new receipt should enter the in-progress set")
	_expect(not storage.begin_reward_receipt_claim(pending_id), "an in-progress receipt should block reentrant settlement")
	storage.cancel_reward_receipt_claim(pending_id)
	_expect(storage.begin_reward_receipt_claim(pending_id), "cancelling an unfinished receipt should allow a retry")
	storage.cancel_reward_receipt_claim(pending_id)

	first_result.queue_free()
	second_result.queue_free()
	await process_frame
	_finish()


func _test_battle_receipts_are_unique() -> void:
	var first_battle = BattleManagerScript.new()
	var second_battle = BattleManagerScript.new()
	root.add_child(first_battle)
	root.add_child(second_battle)
	var stage := {"id": "receipt_test", "enemies": ["enemy_001"], "rewards": {"gold": 1, "exp": 1}}
	first_battle.init(["monster_001"], ["enemy_001"], 5, 1, stage, "receipt_test")
	second_battle.init(["monster_001"], ["enemy_001"], 5, 1, stage, "receipt_test")
	var first_payload: Dictionary = first_battle.get_battle_result()
	var second_payload: Dictionary = second_battle.get_battle_result()
	_expect(not str(first_payload.get("battleId", "")).is_empty(), "battle result should expose a generated battle id")
	_expect(str(first_payload.get("battleId", "")) != str(second_payload.get("battleId", "")), "separate battles should generate different battle ids")
	_expect(str(first_payload.get("rewardReceiptId", "")) == "battle_reward:%s" % first_payload.get("battleId", ""), "battle receipt should derive from the battle id")
	first_battle.queue_free()
	second_battle.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RewardIdempotency] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RewardIdempotency] " + failure)
	quit(1)

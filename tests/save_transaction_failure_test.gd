extends SceneTree

const SceneShopScript = preload("res://src/ui/controllers/shop_logic.gd")
const SceneResultScript = preload("res://src/ui/controllers/result_logic.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager must be available")
	if storage == null:
		_finish()
		return

	storage.clear_all_data()
	var player: Dictionary = storage.load_player()
	player["gold"] = 1000
	player["gems"] = 100
	player["stamina"] = 5
	player["exp"] = 0
	storage.save_player(player)
	storage.save_stage_stars("stage_1_1", 3)

	var before_sweep_player: Dictionary = storage.load_player().duplicate(true)
	var before_sweep_rewards: Dictionary = storage.load_rewards().duplicate(true)
	storage.set_force_save_failure(true)
	var failed_sweep: Dictionary = storage.do_sweep("stage_1_1")
	storage.set_force_save_failure(false)
	_expect(failed_sweep.is_empty(), "sweep should report failure when the transaction cannot be saved")
	_expect(storage.load_player() == before_sweep_player, "failed sweep should roll back player data")
	_expect(storage.load_rewards() == before_sweep_rewards, "failed sweep should roll back reward counters")

	var successful_sweep: Dictionary = storage.do_sweep("stage_1_1")
	_expect(not successful_sweep.is_empty(), "sweep should still work after a failed transaction")
	_expect(int(storage.load_player().get("stamina", 0)) == int(before_sweep_player.get("stamina", 0)) - 1, "successful sweep should spend stamina once")

	storage.clear_all_data()
	player = storage.load_player()
	player["gold"] = 1000
	player["exp"] = 0
	storage.save_player(player)
	var before_sign_player: Dictionary = storage.load_player().duplicate(true)
	var before_sign_data: Dictionary = storage.load_sign_in_data().duplicate(true)
	storage.set_force_save_failure(true)
	var failed_sign: Dictionary = storage.do_sign_in()
	storage.set_force_save_failure(false)
	_expect(failed_sign.is_empty(), "sign-in should report failure when the transaction cannot be saved")
	_expect(storage.load_player() == before_sign_player, "failed sign-in should roll back player rewards")
	_expect(storage.load_sign_in_data() == before_sign_data, "failed sign-in should roll back sign-in date")

	storage.clear_all_data()
	player = storage.load_player()
	player["gold"] = 1000
	player["gems"] = 100
	storage.save_player(player)
	var shop := SceneShopScript.new()
	root.add_child(shop)
	shop.init()
	var before_shop_player: Dictionary = storage.load_player().duplicate(true)
	var before_inventory: Dictionary = storage.load_inventory().duplicate(true)
	var before_daily: int = storage.get_shop_daily_purchase_count("capture_ball")
	storage.set_force_save_failure(true)
	shop.call("_confirm_purchase", "capture_ball", 1)
	storage.set_force_save_failure(false)
	_expect(storage.load_player() == before_shop_player, "failed shop purchase should roll back currency")
	_expect(storage.load_inventory() == before_inventory, "failed shop purchase should roll back inventory")
	_expect(storage.get_shop_daily_purchase_count("capture_ball") == before_daily, "failed shop purchase should roll back daily limit")
	shop.queue_free()

	storage.clear_all_data()
	player = storage.load_player()
	player["gold"] = 1000
	player["gems"] = 100
	player["exp"] = 0
	storage.save_player(player)
	var before_result_player: Dictionary = storage.load_player().duplicate(true)
	var before_result_rewards: Dictionary = storage.load_rewards().duplicate(true)
	var before_result_inventory: Dictionary = storage.load_inventory().duplicate(true)
	var before_stage_progress: Dictionary = storage.load_stage_progress().duplicate(true)
	var result := SceneResultScript.new()
	root.add_child(result)
	storage.set_force_save_failure(true)
	result.initialize(null, {
		"result": "win",
		"stageId": "stage_1_1",
		"battleId": "tx_failure_battle",
		"playerTeam": [{"hp": 10, "maxHp": 10}],
		"enemies": [],
		"stageRewards": {"gold": 120, "exp": 30},
		"turnCount": 5,
		"maxTurns": 20,
	})
	storage.set_force_save_failure(false)
	_expect(storage.load_player() == before_result_player, "failed result settlement should roll back player rewards")
	_expect(storage.load_rewards() == before_result_rewards, "failed result settlement should roll back reward counters")
	_expect(storage.load_inventory() == before_result_inventory, "failed result settlement should roll back inventory rewards")
	_expect(storage.load_stage_progress() == before_stage_progress, "failed result settlement should roll back stage progress")
	_expect(not storage.is_reward_receipt_claimed("battle_reward:tx_failure_battle"), "failed result settlement should not mark receipt claimed")
	result.queue_free()

	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SaveTransactionFailure] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[SaveTransactionFailure] " + failure)
	quit(1)

extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var lobby: Control = load("res://src/ui/scenes/main_lobby.tscn").instantiate()
	root.add_child(lobby)
	await process_frame
	lobby.set("_player", {"name": "test", "level": 4, "gold": 37, "gems": 12, "stamina": 3, "achievement_score": 250, "exp": 50, "exp_to_level": 100})
	lobby.call("_update_player_display")
	_expect((lobby.get_node("%GoldValue") as Label).text == "37", "gold should sync")
	_expect((lobby.get_node("%DiamondValue") as Label).text == "12", "diamonds should sync")
	_expect((lobby.get_node("%StaminaValue") as Label).text == "3/5", "stamina should sync")
	_expect(not (lobby.get_node("Header/RankPanel") as Control).visible, "achievement score panel should be hidden")
	_expect((lobby.get_node("%RankScore") as Label).text.is_empty(), "hidden achievement score should not sync a runtime value")
	_expect((lobby.get_node("Header/GoldCapsule") as Control).position.y == (lobby.get_node("Header/DiamondCapsule") as Control).position.y and (lobby.get_node("Header/DiamondCapsule") as Control).position.y == (lobby.get_node("Header/StaminaCapsule") as Control).position.y, "gold, diamond and stamina should be first row")
	_expect((lobby.get_node("Header/PlayerStatus") as Control).position.y > (lobby.get_node("Header/GoldCapsule") as Control).position.y, "owner level should be second row")
	_expect(not (lobby.get_node("Header/GoldPlus") as Control).visible, "gold add button should be hidden")
	_expect(not (lobby.get_node("Header/DiamondPlus") as Control).visible, "diamond add button should be hidden")
	_expect(not (lobby.get_node("Header/StaminaPlus") as Control).visible, "stamina add button should be hidden")
	lobby.queue_free()
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[MainLobbyHeader] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[MainLobbyHeader] " + failure)
	quit(1)

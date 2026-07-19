extends SceneTree

const BattleManagerScript := preload("res://src/battle/battle_manager.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle: Control = load("res://src/ui/scene/scene_battle.gd").new() as Control
	var effective: Dictionary = battle.call("_damage_floating_entry", 321, 100.0, 80.0, true, false, 18.0, 0.9, true, "water")
	var normal: Dictionary = battle.call("_damage_floating_entry", 200, 100.0, 80.0, false, false)
	var weak: Dictionary = battle.call("_damage_floating_entry", 100, 100.0, 80.0, false, true)

	_expect(str(effective.get("text", "")) == "克制！-321", "effective damage popup should state the elemental advantage explicitly")
	_expect(float(effective.get("duration", 0.0)) > float(normal.get("duration", 0.0)), "effective popup should remain longer than normal damage")
	_expect(float(effective.get("size", 0.0)) > float(normal.get("size", 0.0)), "effective popup should be larger than normal damage")
	_expect(bool(effective.get("single_layer", false)), "effective popup should use one opaque text layer without translucent shadows")
	_expect(bool(effective.get("bold", false)), "effective popup should use bold text")
	_expect((effective.get("color", Color.WHITE) as Color).is_equal_approx(Color(0.1, 0.4, 1.0, 1.0)), "effective popup should use the attacking element color")
	_expect(not bool(normal.get("single_layer", false)), "normal damage should keep the existing text treatment")
	_expect(float(weak.get("size", 0.0)) < float(normal.get("size", 0.0)), "weak damage should remain visually subdued")
	battle.call("_show_message", "属性克制！伤害提升", 2.2)
	_expect(float(battle.get("_message_timer")) >= 2.19, "effective message should remain visible for about 2.2 seconds")
	_expect(bool(battle.call("_is_major_battle_message", "属性克制！伤害提升")), "effective message should use the prominent major-message treatment")

	var enemy_effective_action := {"damage": 180, "element": "fire", "is_effective": true, "is_weak": false}
	var enemy_weak_action := {"damage": 90, "element": "fire", "is_effective": false, "is_weak": true}
	var enemy_effective_popup: Dictionary = battle.call("_enemy_damage_popup_entry", enemy_effective_action, 70.0, 210.0, 16.0, Color.RED, 0.0)
	var enemy_weak_popup: Dictionary = battle.call("_enemy_damage_popup_entry", enemy_weak_action, 70.0, 210.0, 16.0, Color.RED, 0.0)
	_expect(str(enemy_effective_popup.get("text", "")) == "克制！-180", "effective enemy attack should reuse the prominent elemental damage treatment")
	_expect(float(enemy_weak_popup.get("size", 0.0)) < 16.0, "resisted enemy attack should use the subdued damage treatment")
	battle.call("_show_enemy_element_feedback", enemy_effective_action, 70.0, 210.0)
	_expect(str(battle.get("_message_style_source")) == "效果拔群", "effective enemy attack should announce 效果拔群")
	battle.call("_show_enemy_element_feedback", enemy_weak_action, 70.0, 210.0)
	_expect(str(battle.get("_message_style_source")) == "效果不佳", "resisted enemy attack should announce 效果不佳")
	var feedback_floats: Array = battle.get("_floating_texts")
	_expect(feedback_floats.any(func(entry): return str(entry.get("text", "")) == TranslationServer.translate("效果拔群")), "effective enemy feedback should float beside the struck ally")
	_expect(feedback_floats.any(func(entry): return str(entry.get("text", "")) == TranslationServer.translate("效果不佳")), "resisted enemy feedback should float beside the struck ally")

	_test_enemy_action_effectiveness_flags()

	battle.free()
	_finish()

func _test_enemy_action_effectiveness_flags() -> void:
	var manager := BattleManagerScript.new()
	root.add_child(manager)
	manager.init(["monster_001"], ["monster_014"], 10, 10, {"id": "enemy_element_feedback", "type": "normal", "maxTurns": 20, "disableRandomElite": true}, "enemy_element_feedback")
	manager.player_team[0]["hp"] = 999999
	manager.player_team[0]["maxHP"] = 999999
	manager.enemies[0]["element"] = "fire"
	manager.player_team[0]["element"] = "grass"
	var effective_action := _first_damage_action(manager.enemy_action())
	_expect(bool(effective_action.get("is_effective", false)) and is_equal_approx(float(effective_action.get("element_multiplier", 0.0)), 1.5), "fire enemy attacking grass ally should report effective elemental damage")
	manager.player_team[0]["element"] = "water"
	var weak_action := _first_damage_action(manager.enemy_action())
	_expect(bool(weak_action.get("is_weak", false)) and is_equal_approx(float(weak_action.get("element_multiplier", 0.0)), 0.75), "fire enemy attacking water ally should report resisted elemental damage")
	manager.free()

func _first_damage_action(result: Dictionary) -> Dictionary:
	for action: Dictionary in result.get("actions", []):
		if int(action.get("damage", 0)) > 0 and not bool(action.get("is_friendly_fire", false)):
			return action
	return {}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleEffectiveFeedback] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleEffectiveFeedback] " + failure)
	quit(1)

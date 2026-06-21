extends SceneTree

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

	battle.free()
	_finish()

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

class_name EnemyIntentRules
extends RefCounted


static func build_enemy_intents(enemies: Array, skill_states: Dictionary, status_effects: Array = []) -> Dictionary:
	var result := {}
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy == null or not enemy is Dictionary:
			continue
		var enemy_data: Dictionary = enemy
		if int(enemy_data.get("hp", 0)) <= 0:
			continue
		var state: Dictionary = skill_states.get(i, {})
		var status: Dictionary = status_effects[i] if i < status_effects.size() and status_effects[i] is Dictionary else {}
		result[i] = build_enemy_intent(enemy_data, state, status)
	return result


static func build_enemy_intent(enemy: Dictionary, skill_state: Dictionary, status: Dictionary = {}) -> Dictionary:
	if str(status.get("type", "")) == "stun":
		return {
			"type": "stunned",
			"label": "眩晕",
			"desc": "本回合无法行动",
			"severity": "safe",
			"hint": "趁机输出或调整棋盘"
		}

	var charge: Dictionary = skill_state.get("charge", {})
	if bool(charge.get("is_charging", false)):
		var multiplier := float(charge.get("damage_multiplier", 2.0))
		return {
			"type": "charge_release",
			"label": "蓄力释放",
			"desc": TranslationServer.translate("即将造成 %.1fx 伤害") % multiplier,
			"severity": "danger",
			"hint": "破招: 束缚或守护"
		}

	var shield: Dictionary = skill_state.get("shield", {})
	if not shield.is_empty() and int(shield.get("current_hp", 0)) <= 0 and int(shield.get("cooldown_left", 0)) <= 0:
		return {
			"type": "shield",
			"label": "架盾",
			"desc": "先生成护盾再行动",
			"severity": "shield",
			"hint": "优先用爆发破盾"
		}

	var heal: Dictionary = skill_state.get("heal", {})
	if not heal.is_empty() and int(heal.get("turns_since_last", 0)) + 1 >= int(heal.get("interval", 4)):
		return {
			"type": "heal",
			"label": "回血",
			"desc": "即将回复生命",
			"severity": "heal",
			"hint": "先集火压低血量"
		}

	if not charge.is_empty() and int(charge.get("turns_since_last", 0)) + 1 >= int(charge.get("interval", 3)):
		return {
			"type": "attack_then_charge",
			"label": "攻击后蓄力",
			"desc": "攻击后进入蓄力",
			"severity": "warning",
			"hint": "准备束缚或守护"
		}

	return {
		"type": "attack",
		"label": "普攻",
		"desc": "攻击随机队友",
		"severity": "normal",
		"hint": ""
	}

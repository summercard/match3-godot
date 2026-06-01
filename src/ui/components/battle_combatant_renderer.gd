class_name BattleCombatantRenderer
extends RefCounted

static func draw_enemies(scene, battle, state: Dictionary) -> void:
	var design_w: float = state.get("design_w", 375.0)
	var colors: Dictionary = state.get("colors", {})
	if battle == null:
		return
	if battle.enemies.size() == 1:
		var enemy: Dictionary = battle.enemies[0]
		draw_enemy_stage(scene, battle, state, enemy.get("name", "敌人"), maxi(enemy.get("hp", 0), 0), maxi(enemy.get("maxHP", 1), 1), enemy)
		return
	var enemy_count: int = mini(battle.enemies.size(), 3)
	var stage_slots := _multi_enemy_slots(enemy_count)
	for i in range(enemy_count):
		var enemy: Dictionary = battle.enemies[i]
		if enemy == null:
			continue
		draw_enemy_card(scene, battle, state, stage_slots[i].x, stage_slots[i].y, i, enemy.get("name", "敌人"), maxi(enemy.get("hp", 0), 0), maxi(enemy.get("maxHP", 1), 1), enemy)

static func draw_enemy_stage(scene, battle, state: Dictionary, name: String, hp: int, max_hp: int, enemy: Dictionary) -> void:
	var design_w: float = state.get("design_w", 375.0)
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var is_boss: bool = enemy.get("isBoss", false)
	scene._draw_text_with_shadow(name, design_w / 2.0, 83.0, colors.get("text_primary", Color.WHITE), 13.0, true)
	scene._draw_hp_bar(196.0, 91.0, 150.0, 14.0, float(hp), float(max_hp), colors.get("danger", Color.RED), str(enemy.get("element", "fire")), true)
	scene._draw_text_with_shadow("%d/%d" % [hp, max_hp], 271.0, 102.0, colors.get("white", Color.WHITE), 8.0, true)
	var monster_tex: Texture2D = scene._get_monster_texture(enemy)
	if monster_tex:
		var boss_scale: float = 170.0 if is_boss else 128.0
		var monster_y: float = 104.0 if is_boss else 111.0
		scene._draw_texture_contain(monster_tex, Rect2(design_w / 2.0 - boss_scale / 2.0, monster_y + sin(idle_time * TAU / 1.8) * 3.0, boss_scale, boss_scale), 1.0 if hp > 0 else 0.35)
	else:
		scene._draw_text_with_shadow(enemy.get("emoji", "👾"), design_w / 2.0, 168.0, colors.get("white", Color.WHITE), 50.0)
	_draw_boss_visuals(scene, state, design_w / 2.0 - 55.0, 120.0, 0, hp)
	_draw_enemy_status(scene, battle, state, design_w / 2.0 - 55.0, 120.0, 0, hp, 110.0)

static func draw_enemy_card(scene, battle, state: Dictionary, x: float, y: float, index: int, name: String, hp: int, max_hp: int, enemy: Dictionary) -> void:
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var slot_w: float = 96.0
	var sprite_size: float = 70.0 if enemy.get("isBoss", false) else 62.0
	var flash: Array = state.get("hit_flashes", []).filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == index)
	var has_flash: bool = flash.size() > 0
	var cx: float = x + slot_w / 2.0
	if has_flash:
		var flash_alpha: float = flash[0]["timer"] / flash[0]["maxTimer"] * 0.6
		_draw_hit_spark(scene, Vector2(cx, y + 42.0), 82.0, flash_alpha)

	var monster_tex: Texture2D = scene._get_monster_texture(enemy)
	if monster_tex:
		scene._draw_texture_contain(monster_tex, Rect2(cx - sprite_size / 2.0, y + 11.0 + sin(idle_time * TAU / 1.5 + index * 0.4) * 2.4, sprite_size, sprite_size), 1.0 if hp > 0 else 0.35)
	else:
		scene._draw_text_with_shadow(enemy.get("emoji", "👾"), cx, y + 43.0, colors.get("white", Color.WHITE), 34.0)
	scene._draw_text_with_shadow(name, cx, y + 14.0, colors.get("text_primary", Color.WHITE), 10.4, true)
	scene._draw_hp_bar(x + 7.0, y + 80.0, slot_w - 14.0, 10.0, float(hp), float(max_hp), colors.get("danger", Color.RED))
	scene._draw_text_with_shadow("%d/%d" % [hp, max_hp], cx, y + 89.0, colors.get("white", Color.WHITE), 7.4, true)

	var defeated_enemies: Array = state.get("defeated_enemies", [])
	if hp <= 0 and not defeated_enemies.has(index):
		defeated_enemies.append(index)
		scene._spawn_defeat_particles(cx, y + 48.0, colors.get("danger", Color.RED))

	_draw_boss_visuals(scene, state, x, y, index, hp)
	_draw_enemy_status(scene, battle, state, x, y, index, hp, slot_w)

static func _draw_enemy_intent(scene, state: Dictionary, x: float, y: float, index: int, hp: int, card_w: float) -> void:
	if hp <= 0:
		return
	var intents: Dictionary = state.get("enemy_intents", {})
	if not intents.has(index):
		return
	var intent: Dictionary = intents[index]
	var colors: Dictionary = state.get("colors", {})
	var severity: String = str(intent.get("severity", "normal"))
	var chip_color: Color = Color(0.18, 0.22, 0.32, 0.88)
	var text_color: Color = colors.get("text_secondary", Color.GRAY)
	if severity == "danger":
		chip_color = Color(0.58, 0.12, 0.10, 0.90)
		text_color = colors.get("charged_attack", Color.RED)
	elif severity == "warning":
		chip_color = Color(0.45, 0.30, 0.06, 0.90)
		text_color = colors.get("gold", Color.YELLOW)
	elif severity == "shield":
		chip_color = Color(0.08, 0.25, 0.42, 0.90)
		text_color = colors.get("shield", Color.SKY_BLUE)
	elif severity == "heal":
		chip_color = Color(0.08, 0.34, 0.20, 0.90)
		text_color = colors.get("heal_green", Color.GREEN)
	elif severity == "safe":
		chip_color = Color(0.08, 0.36, 0.28, 0.90)
		text_color = colors.get("success", Color.GREEN)
	var label: String = str(intent.get("label", "普攻"))
	var hint: String = str(intent.get("hint", ""))
	var display: String = label
	if severity == "danger" and not hint.is_empty():
		display = "%s %s" % [label, hint]
	var intent_tex: Texture2D = scene._get_texture(_intent_asset_path(severity))
	if intent_tex:
		scene._draw_texture_fit(intent_tex, Rect2(x + 22.0, y + 100.0, card_w - 44.0, 15.0), 0.90)
	else:
		chip_color.a *= 0.76
		scene._draw_rounded_rect(x + 22.0, y + 100.0, card_w - 44.0, 15.0, 5.0, chip_color)
	scene._draw_text_with_shadow(display, x + card_w / 2.0, y + 111.0, text_color, 7.4, true)

static func _multi_enemy_slots(enemy_count: int) -> Array[Vector2]:
	if enemy_count == 2:
		return [Vector2(82.0, 74.0), Vector2(197.0, 74.0)]
	return [Vector2(24.0, 72.0), Vector2(139.5, 63.0), Vector2(255.0, 72.0)]

static func _draw_stage_enemy_intent(scene, state: Dictionary, hp: int) -> void:
	if hp <= 0:
		return
	var intents: Dictionary = state.get("enemy_intents", {})
	if not intents.has(0):
		return
	var intent: Dictionary = intents[0]
	var colors: Dictionary = state.get("colors", {})
	var severity: String = str(intent.get("severity", "normal"))
	var chip_color: Color = Color(0.08, 0.14, 0.24, 0.86)
	var text_color: Color = colors.get("text_secondary", Color.GRAY)
	if severity == "danger":
		chip_color = Color(0.58, 0.12, 0.10, 0.90)
		text_color = colors.get("charged_attack", Color.RED)
	elif severity == "warning":
		chip_color = Color(0.45, 0.30, 0.06, 0.90)
		text_color = colors.get("gold", Color.YELLOW)
	elif severity == "shield":
		chip_color = Color(0.08, 0.25, 0.42, 0.90)
		text_color = colors.get("shield", Color.SKY_BLUE)
	elif severity == "heal":
		chip_color = Color(0.08, 0.34, 0.20, 0.90)
		text_color = colors.get("heal_green", Color.GREEN)
	elif severity == "safe":
		chip_color = Color(0.08, 0.36, 0.28, 0.90)
		text_color = colors.get("success", Color.GREEN)
	var display := str(intent.get("label", "普攻"))
	var hint := str(intent.get("hint", ""))
	if severity == "danger" and not hint.is_empty():
		display = "%s %s" % [display, hint]
	var intent_tex: Texture2D = scene._get_texture(_intent_asset_path(severity))
	if intent_tex:
		scene._draw_texture_fit(intent_tex, Rect2(238.0, 124.0, 98.0, 22.0), 0.94)
	else:
		scene._draw_rounded_rect(238.0, 124.0, 98.0, 22.0, 6.0, chip_color)
	scene._draw_text_with_shadow(display, 287.0, 139.5, text_color, 9.2, true)

static func _intent_asset_path(severity: String) -> String:
	match severity:
		"danger":
			return "res://assets/images/battle/ui/ui_intent_danger.png"
		"warning":
			return "res://assets/images/battle/ui/ui_intent_warning.png"
		"shield":
			return "res://assets/images/battle/ui/ui_intent_shield.png"
		"heal", "safe":
			return "res://assets/images/battle/ui/ui_intent_heal.png"
		_:
			return "res://assets/images/battle/ui/ui_intent_normal.png"

static func _draw_boss_visuals(scene, state: Dictionary, x: float, y: float, index: int, hp: int) -> void:
	if hp <= 0:
		return
	var boss_skill_visuals: Dictionary = state.get("boss_skill_visuals", {})
	if not boss_skill_visuals.has(index):
		return
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var vis: Dictionary = boss_skill_visuals[index]
	if vis.get("shield_hp", 0.0) > 0.0:
		var shield_hp: float = vis["shield_hp"]
		var shield_max: float = vis["shield_max_hp"]
		var shield_ratio: float = shield_hp / shield_max if shield_max > 0.0 else 0.0
		var shield_tex: Texture2D = scene._get_texture("res://assets/images/battle/fx/fx_shield_ring.png")
		if shield_tex:
			var pulse_alpha := 0.42 + shield_ratio * 0.40 + 0.12 * sin(idle_time * TAU)
			scene._draw_texture_fit(shield_tex, Rect2(x + 5.0, y - 23.0, 100.0, 100.0), pulse_alpha)
		else:
			var shield_color: Color = Color(0.314, 0.706, 1.0, 0.3 + shield_ratio * 0.4)
			scene.draw_arc(Vector2(x + 55.0, y + 28.0), 36.0, 0.0, TAU, 32, shield_color, 2.0, true)
		scene._draw_hp_bar(x + 12.0, y + 75.0, 96.0, 4.0, shield_hp, shield_max, colors.get("shield", Color.SKY_BLUE))
		scene._draw_text_with_shadow("护盾 %d" % int(shield_hp), x + 55.0, y + 83.0, colors.get("shield", Color.SKY_BLUE), 7.4, true)
	if vis.get("charge_timer", 0.0) > 0.0:
		var blink_alpha: float = 0.5 + 0.5 * sin(idle_time * PI * 4.0)
		var charge_tex: Texture2D = scene._get_texture("res://assets/images/battle/fx/fx_charge_aura.png")
		if charge_tex:
			scene._draw_texture_fit(charge_tex, Rect2(x + 2.0, y - 27.0, 106.0, 106.0), 0.55 + 0.28 * blink_alpha)
		scene._draw_text_with_shadow("蓄力中", x + 55.0, y - 1.0, Color(1.0, 0.784, 0.196, blink_alpha), 9.0, true)

static func _draw_enemy_status(scene, battle, state: Dictionary, x: float, y: float, index: int, hp: int, card_w: float) -> void:
	if battle == null or hp <= 0:
		return
	var effects: Array = battle._status_effect.get_effects_snapshot()
	if index >= effects.size() or effects[index] == null:
		return
	var effect: Dictionary = effects[index]
	var status_type: String = effect.get("type", "")
	var emoji: String = state.get("status_emoji", {}).get(status_type, "?")
	var turns: int = effect.get("turns_left", 1)
	var blink_alpha: float = 0.7 + 0.3 * sin(state.get("idle_time", 0.0) * PI * 3.0)
	var status_color: Color = state.get("status_colors", {}).get(status_type, state.get("colors", {}).get("text_muted", Color.GRAY))
	status_color.a = blink_alpha
	scene._draw_text_with_shadow("%s%d" % [emoji, turns], x + card_w - 10.0, y - 2.0, status_color, 11.0)

static func draw_team(scene, battle, state: Dictionary) -> void:
	if battle == null:
		return
	for i in range(mini(battle.player_team.size(), 3)):
		var monster: Dictionary = battle.player_team[i]
		if monster == null:
			continue
		draw_player_card(scene, battle, state, 18.0 + i * 116.0, 218.0, i, monster.get("name", "伙伴"), maxi(monster.get("hp", 0), 0), maxi(monster.get("maxHP", 1), 1), monster)

static func draw_fx(scene, battle, state: Dictionary) -> void:
	if battle == null:
		return
	var colors: Dictionary = state.get("colors", {})
	if battle.enemies.size() == 1:
		var enemy: Dictionary = battle.enemies[0]
		var hp: int = maxi(enemy.get("hp", 0), 0)
		_draw_boss_visuals(scene, state, state.get("design_w", 375.0) / 2.0 - 55.0, 120.0, 0, hp)
		_draw_enemy_status(scene, battle, state, state.get("design_w", 375.0) / 2.0 - 55.0, 120.0, 0, hp, 110.0)
	else:
		var enemy_count: int = mini(battle.enemies.size(), 3)
		var stage_slots := _multi_enemy_slots(enemy_count)
		for i in range(enemy_count):
			var enemy: Dictionary = battle.enemies[i]
			if enemy == null:
				continue
			var hp: int = maxi(enemy.get("hp", 0), 0)
			var x: float = stage_slots[i].x
			var y: float = stage_slots[i].y
			var cx: float = x + 48.0
			var flash: Array = state.get("hit_flashes", []).filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == i)
			if not flash.is_empty():
				var flash_alpha: float = flash[0]["timer"] / flash[0]["maxTimer"] * 0.6
				_draw_hit_spark(scene, Vector2(cx, y + 42.0), 82.0, flash_alpha)
			var defeated_enemies: Array = state.get("defeated_enemies", [])
			if hp <= 0 and not defeated_enemies.has(i):
				defeated_enemies.append(i)
				scene._spawn_defeat_particles(cx, y + 48.0, colors.get("danger", Color.RED))
			_draw_boss_visuals(scene, state, x, y, i, hp)
			_draw_enemy_status(scene, battle, state, x, y, i, hp, 96.0)
	for i in range(mini(battle.player_team.size(), 3)):
		var monster: Dictionary = battle.player_team[i]
		if monster == null:
			continue
		var flash: Array = state.get("hit_flashes", []).filter(func(f): return not f.get("isEnemy", false) and f.get("monsterIndex", -1) == i)
		if not flash.is_empty():
			_draw_hit_spark(scene, Vector2(18.0 + i * 116.0 + 53.0, 253.0), 78.0, 0.62)

static func draw_player_card(scene, battle, state: Dictionary, x: float, y: float, index: int, name: String, hp: int, max_hp: int, monster: Dictionary) -> void:
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var card_w: float = 106.0
	var flash: Array = state.get("hit_flashes", []).filter(func(f): return not f.get("isEnemy", false) and f.get("monsterIndex", -1) == index)
	if not flash.is_empty():
		_draw_hit_spark(scene, Vector2(x + card_w / 2.0, y + 35.0), 78.0, 0.62)

	var monster_tex: Texture2D = scene._get_monster_texture(monster)
	if monster_tex:
		scene._draw_texture_contain(monster_tex, Rect2(x + 8.0, y + 3.0 + sin(idle_time * TAU / 1.5) * 1.2, 90.0, 58.0), 1.0 if hp > 0 else 0.35)
	else:
		scene._draw_text_with_shadow(monster.get("emoji", "👾"), x + 53.0, y + 36.0, colors.get("white", Color.WHITE), 31.0)
	scene._draw_text_with_shadow(name, x + card_w / 2.0, y + 8.0, colors.get("text_primary", Color.WHITE), 10.0)
	scene._draw_hp_bar(x + 4.0, y + 52.0, card_w - 8.0, 11.0, float(hp), float(max_hp), colors.get("success", Color.GREEN))
	scene._draw_text_with_shadow("%d/%d" % [hp, max_hp], x + card_w / 2.0, y + 61.0, colors.get("white", Color.WHITE), 7.4, true)

static func _draw_skill_charge(scene, battle, state: Dictionary, x: float, y: float, monster: Dictionary) -> void:
	if not monster.has("skill"):
		return
	var colors: Dictionary = state.get("colors", {})
	var skill_cost: int = monster.get("skill", {}).get("cost", 10)
	var charge: int = 0
	if battle != null and battle.skill_charges.has(monster.get("id", "")):
		charge = battle.skill_charges[monster.get("id", "")]
	var charge_ratio: float = clamp(float(charge) / float(skill_cost) if skill_cost > 0 else 0.0, 0.0, 1.0)
	if charge_ratio >= 1.0:
		scene._draw_hp_bar(x + 13.0, y + 68.0, 80.0, 5.0, charge_ratio * skill_cost, skill_cost, colors.get("gold", Color.YELLOW))
		var pulse_alpha: float = 0.65 + 0.35 * sin(state.get("idle_time", 0.0) * PI * 4.0)
		var charge_tex: Texture2D = scene._get_texture("res://assets/images/battle/fx/fx_charge_aura.png")
		if charge_tex:
			scene._draw_texture_fit(charge_tex, Rect2(x + 18.0, y + 12.0, 70.0, 58.0), 0.18 * pulse_alpha)
		scene._draw_text_with_shadow("可用", x + 53.0, y + 78.0, Color(1.0, 0.86, 0.25, pulse_alpha), 7.0)
	else:
		scene._draw_hp_bar(x + 13.0, y + 68.0, 80.0, 5.0, charge_ratio * skill_cost, skill_cost, Color(0.20, 0.44, 0.92, 1.0))

static func _draw_stage_ring(scene, element: String, rect: Rect2, opacity: float) -> void:
	var ring_tex: Texture2D = scene._get_texture(_stage_ring_asset_path(element))
	if ring_tex:
		scene._draw_texture_fit(ring_tex, rect, opacity)
		return
	var color := _element_color(element)
	scene.draw_arc(rect.get_center(), rect.size.x * 0.34, PI, TAU, 32, Color(color.r, color.g, color.b, 0.40 * opacity), 1.6, true)

static func _draw_hit_spark(scene, center: Vector2, size: float, opacity: float) -> void:
	var spark_tex: Texture2D = scene._get_texture("res://assets/images/battle/fx/fx_hit_spark.png")
	if spark_tex:
		scene._draw_texture_fit(spark_tex, Rect2(center.x - size / 2.0, center.y - size / 2.0, size, size), opacity)
	else:
		scene._draw_rounded_rect(center.x - size * 0.25, center.y - size * 0.25, size * 0.5, size * 0.5, 12.0, Color(1.0, 0.35, 0.12, 0.5 * opacity))

static func _stage_ring_asset_path(element: String) -> String:
	match element:
		"grass":
			return "res://assets/images/battle/fx/fx_stage_ring_green.png"
		"fire":
			return "res://assets/images/battle/fx/fx_stage_ring_fire.png"
		"dark", "void", "temporal":
			return "res://assets/images/battle/fx/fx_stage_ring_void.png"
		_:
			return "res://assets/images/battle/fx/fx_stage_ring_cyan.png"

static func _element_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.38, 0.16)
		"water", "ice":
			return Color(0.24, 0.74, 1.0)
		"grass":
			return Color(0.38, 0.88, 0.34)
		"thunder":
			return Color(1.0, 0.78, 0.18)
		"light", "star":
			return Color(0.82, 0.92, 1.0)
		"temporal":
			return Color(0.50, 0.62, 1.0)
		"void", "dark":
			return Color(0.62, 0.48, 1.0)
		_:
			return Color(0.18, 0.78, 1.0)

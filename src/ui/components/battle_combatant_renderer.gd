class_name BattleCombatantRenderer
extends RefCounted

static func draw_enemies(scene, battle, state: Dictionary) -> void:
	var design_w: float = state.get("design_w", 375.0)
	var colors: Dictionary = state.get("colors", {})
	scene._draw_text_with_shadow("— 敌方 —", design_w / 2.0, 65.0, colors.get("danger", Color.RED), 12.0)
	if battle == null:
		return
	for i in range(mini(battle.enemies.size(), 3)):
		var enemy: Dictionary = battle.enemies[i]
		if enemy == null:
			continue
		draw_enemy_card(scene, battle, state, 15.0 + i * 120.0, 80.0, i, enemy.get("name", "敌人"), maxi(enemy.get("hp", 0), 0), maxi(enemy.get("maxHP", 1), 1), enemy)

static func draw_enemy_card(scene, battle, state: Dictionary, x: float, y: float, index: int, name: String, hp: int, max_hp: int, enemy: Dictionary) -> void:
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var card_w: float = 110.0
	var card_h: float = 92.0
	var flash: Array = state.get("hit_flashes", []).filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == index)
	var has_flash: bool = flash.size() > 0
	var card_color: Color = colors.get("bg_card", Color(0.1, 0.15, 0.25))
	if has_flash:
		var flash_alpha: float = flash[0]["timer"] / flash[0]["maxTimer"] * 0.6
		card_color = Color(1.0, 0.2, 0.2, flash_alpha)
	scene._draw_panel(x + 5.0, y - 5.0, card_w, card_h, card_color, 0.82)
	if has_flash:
		scene._draw_rounded_rect(x + 5.0, y - 5.0, card_w, card_h, 8.0, card_color)

	var monster_tex: Texture2D = scene._get_monster_texture(enemy)
	if monster_tex:
		var sprite_size: float = 70.0 if enemy.get("isBoss", false) else 54.0
		scene._draw_texture_fit(monster_tex, Rect2(x + 55.0 - sprite_size / 2.0, y - 2.0 + sin(idle_time * TAU / 1.5) * 3.0, sprite_size, sprite_size), 1.0 if hp > 0 else 0.35)
	else:
		scene._draw_text_with_shadow(enemy.get("emoji", "👾"), x + card_w / 2.0, y + 25.0, colors.get("white", Color.WHITE), 32.0)
	scene._draw_text_with_shadow(name, x + card_w / 2.0, y + 55.0, colors.get("text_primary", Color.WHITE), 12.0)
	scene._draw_hp_bar(x + 12.0, y + 66.0, 96.0, 8.0, float(hp), float(max_hp), colors.get("danger", Color.RED))
	scene._draw_text_with_shadow("%d/%d" % [hp, max_hp], x + card_w / 2.0, y + 82.0, colors.get("text_muted", Color.GRAY), 9.0)

	var defeated_enemies: Array = state.get("defeated_enemies", [])
	if hp <= 0 and not defeated_enemies.has(index):
		defeated_enemies.append(index)
		scene._spawn_defeat_particles(x + card_w / 2.0, y + card_h / 2.0, colors.get("danger", Color.RED))

	_draw_boss_visuals(scene, state, x, y, index, hp)
	_draw_enemy_status(scene, battle, state, x, y, index, hp, card_w)

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
		var shield_color: Color = Color(0.314, 0.706, 1.0, 0.3 + shield_ratio * 0.4)
		scene.draw_arc(Vector2(x + 55.0, y + 28.0), 36.0, 0.0, TAU, 32, shield_color, 2.0, true)
		scene._draw_hp_bar(x + 12.0, y + 75.0, 96.0, 4.0, shield_hp, shield_max, colors.get("shield", Color.SKY_BLUE))
		scene._draw_text_with_shadow("🛡️%d" % int(shield_hp), x + 55.0, y + 81.0, colors.get("shield", Color.SKY_BLUE), 8.0)
	if vis.get("charge_timer", 0.0) > 0.0:
		var blink_alpha: float = 0.5 + 0.5 * sin(idle_time * PI * 4.0)
		scene._draw_text_with_shadow("⚡蓄力中...", x + 55.0, y - 2.0, Color(1.0, 0.784, 0.196, blink_alpha), 10.0)

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
	var design_w: float = state.get("design_w", 375.0)
	var colors: Dictionary = state.get("colors", {})
	scene._draw_text_with_shadow("— 我方 —", design_w / 2.0, 180.0, colors.get("success", Color.GREEN), 12.0)
	if battle == null:
		return
	for i in range(mini(battle.player_team.size(), 3)):
		var monster: Dictionary = battle.player_team[i]
		if monster == null:
			continue
		draw_player_card(scene, battle, state, 15.0 + i * 120.0, 195.0, i, monster.get("name", "伙伴"), maxi(monster.get("hp", 0), 0), maxi(monster.get("maxHP", 1), 1), monster)

static func draw_player_card(scene, battle, state: Dictionary, x: float, y: float, index: int, name: String, hp: int, max_hp: int, monster: Dictionary) -> void:
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var card_w: float = 110.0
	var flash: Array = state.get("hit_flashes", []).filter(func(f): return not f.get("isEnemy", false) and f.get("monsterIndex", -1) == index)
	var card_color: Color = colors.get("bg_card", Color(0.1, 0.15, 0.25))
	if not flash.is_empty():
		var flash_alpha: float = flash[0]["timer"] / flash[0]["maxTimer"] * 0.55
		card_color = Color(1.0, 0.84, 0.2, flash_alpha)
	scene._draw_panel(x + 5.0, y - 8.0, 110.0, 58.0, card_color, 0.78)
	if not flash.is_empty():
		scene._draw_rounded_rect(x + 5.0, y - 8.0, 110.0, 58.0, 8.0, card_color)

	var monster_tex: Texture2D = scene._get_monster_texture(monster)
	if monster_tex:
		scene._draw_texture_fit(monster_tex, Rect2(x + 8.0, y - 5.0 + sin(idle_time * TAU / 1.5) * 1.2, 42.0, 42.0), 1.0 if hp > 0 else 0.35)
	else:
		scene._draw_text_with_shadow(monster.get("emoji", "👾"), x + 30.0, y + 16.0, colors.get("white", Color.WHITE), 28.0)
	scene._draw_text_with_shadow(name, x + card_w - 55.0, y + 6.0, colors.get("text_primary", Color.WHITE), 12.0)
	scene._draw_hp_bar(x + 52.0, y + 16.0, 58.0, 7.0, float(hp), float(max_hp), colors.get("success", Color.GREEN))
	scene._draw_text_with_shadow("%d/%d" % [hp, max_hp], x + card_w - 28.0, y + 31.0, colors.get("text_muted", Color.GRAY), 8.0)
	_draw_skill_charge(scene, battle, state, x, y, monster)

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
		scene._draw_hp_bar(x + 52.0, y + 38.0, 58.0, 5.0, charge_ratio * skill_cost, skill_cost, colors.get("gold", Color.YELLOW))
		var pulse_alpha: float = 0.65 + 0.35 * sin(state.get("idle_time", 0.0) * PI * 4.0)
		scene._draw_rounded_rect(x + 52.0, y + 43.0, 58.0, 10.0, 3.0, Color(1.0, 0.8, 0.0, 0.18 * pulse_alpha))
		scene._draw_text_with_shadow("点击释放", x + 81.0, y + 51.0, Color(1.0, 0.86, 0.25, pulse_alpha), 8.0)
	else:
		scene._draw_hp_bar(x + 52.0, y + 38.0, 58.0, 5.0, charge_ratio * skill_cost, skill_cost, colors.get("bg_card", Color(0.1, 0.15, 0.25)))
		scene._draw_text_with_shadow("%d/%d" % [charge, skill_cost], x + 81.0, y + 51.0, colors.get("text_muted", Color.GRAY), 8.0)

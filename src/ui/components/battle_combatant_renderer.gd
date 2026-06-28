class_name BattleCombatantRenderer
extends RefCounted

const DEFEATED_GHOST_ASSET := "res://assets/images/effects/battle_fx_defeated_ghost.png"
const SINGLE_ENEMY_SPRITE_SIZE := 128.0
const SINGLE_BOSS_SPRITE_SIZE := 192.0
const MULTI_ENEMY_SPRITE_SIZE := 62.0
const MULTI_BOSS_SPRITE_SIZE := 124.0
const SINGLE_BOSS_STATUS_OFFSET_Y := -56.0

static func draw_enemies(scene, battle, state: Dictionary) -> void:
	var design_w: float = state.get("design_w", 375.0)
	var colors: Dictionary = state.get("colors", {})
	if battle == null:
		return
	if battle.enemies.size() == 1 and uses_featured_single_layout(battle.enemies[0]):
		var enemy: Dictionary = battle.enemies[0]
		if enemy == null:
			return
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
	var flash: Array = state.get("hit_flashes", []).filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == 0)
	if hp <= 0:
		var defeat_y: float = 176.0 if is_boss else 170.0
		_ensure_enemy_defeat_fx(scene, state, 0, Vector2(design_w / 2.0, defeat_y), colors.get("danger", Color.RED))
		var ghost_size := Vector2(128.0, 128.0) if is_boss else Vector2(96.0, 96.0)
		# ★ 主人定 2026-06-11：倒下时按阶段画幽灵（冲下→渐显）
		var phase := _defeat_phase(scene, state, true, 0, idle_time)
		if bool(phase.get("ghost_visible", true)):
			var alpha: float = float(phase.get("ghost_alpha", 1.0))
			scene._draw_texture_contain(_get_ghost_texture(scene), Rect2(design_w / 2.0 - ghost_size.x * 0.5, defeat_y - ghost_size.y * 0.5 + float(phase.get("ghost_offset_y", 0.0)) + sin(idle_time * TAU / 1.8) * 2.0, ghost_size.x, ghost_size.y), alpha)
		return
	# ★ 主人定 2026-06-11：攻击者弹性放大
	var elastic := _attacker_elastic_factor(state, true, 0)
	var status_offset_y := SINGLE_BOSS_STATUS_OFFSET_Y if is_boss else 0.0
	scene._draw_text_with_shadow(name, design_w / 2.0, 83.0 + status_offset_y, colors.get("text_primary", Color.WHITE), 13.0, true)
	var boss_hp_rect := Rect2(196.0, 91.0 + status_offset_y, 150.0, 14.0)
	scene._draw_hp_bar(boss_hp_rect.position.x, boss_hp_rect.position.y, boss_hp_rect.size.x, boss_hp_rect.size.y, float(hp), float(max_hp), colors.get("danger", Color.RED), str(enemy.get("element", "fire")), true)
	scene._draw_hp_text_in_bar("%d/%d" % [hp, max_hp], boss_hp_rect, colors.get("white", Color.WHITE))
	# ★ 主人定 2026-06-11：精英怪在血条前加 ★ 精英 标识
	if bool(enemy.get("isElite", false)):
		scene._draw_text_with_shadow("★精英", 178.0, 102.0 + status_offset_y, colors.get("gold", Color(1.0, 0.82, 0.18, 1.0)), 9.5, true)
	var monster_tex: Texture2D = scene._get_monster_texture(enemy)
	if monster_tex:
		var boss_scale: float = SINGLE_BOSS_SPRITE_SIZE if is_boss else SINGLE_ENEMY_SPRITE_SIZE
		# ★ 主人定 2026-06-10：phase 2 体型 ×1.5（在原 boss_scale 基础上）
		var visual_scale: float = float(enemy.get("_visualScale", 1.0))
		var final_size: float = boss_scale * visual_scale * elastic
		var monster_y: float = 104.0 if is_boss else 111.0
		# 体型变大后以中心点为锚，避免乱跳
		var monster_rect := Rect2(design_w / 2.0 - final_size / 2.0, monster_y - (final_size - boss_scale * elastic) * 0.3 + sin(idle_time * TAU / 1.8) * 3.0, final_size, final_size)
		scene._draw_texture_contain(monster_tex, monster_rect, 1.0)
		if not flash.is_empty():
			_draw_hit_ring(scene, _enemy_sprite_center(enemy, 0, battle, state), 96.0 if is_boss else 82.0, flash[0])
			_draw_soft_hit_flash(scene, monster_tex, monster_rect, flash[0])
	else:
		scene._draw_text_with_shadow(enemy.get("emoji", "👾"), design_w / 2.0, 168.0, colors.get("white", Color.WHITE), 50.0)
	_draw_boss_visuals(scene, state, design_w / 2.0 - 55.0, 120.0, 0, hp)
	_draw_enemy_status(scene, battle, state, design_w / 2.0 - 55.0, 120.0, 0, hp, 110.0)

static func draw_enemy_card(scene, battle, state: Dictionary, x: float, y: float, index: int, name: String, hp: int, max_hp: int, enemy: Dictionary) -> void:
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var slot_w: float = 96.0
	var sprite_size: float = MULTI_BOSS_SPRITE_SIZE if enemy.get("isBoss", false) else MULTI_ENEMY_SPRITE_SIZE
	var flash: Array = state.get("hit_flashes", []).filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == index)
	var has_flash: bool = flash.size() > 0
	var cx: float = x + slot_w / 2.0
	# ★ 主人定 2026-06-11：倒下阶段
	if hp <= 0:
		_ensure_enemy_defeat_fx(scene, state, index, Vector2(cx, y + 48.0), colors.get("danger", Color.RED))
		var ghost_size := Vector2(66.0, 66.0) if enemy.get("isBoss", false) else Vector2(58.0, 58.0)
		var phase := _defeat_phase(scene, state, true, index, idle_time)
		if bool(phase.get("ghost_visible", true)):
			var alpha: float = float(phase.get("ghost_alpha", 1.0))
			scene._draw_texture_contain(_get_ghost_texture(scene), Rect2(cx - ghost_size.x * 0.5, y + 43.0 - ghost_size.y * 0.5 + float(phase.get("ghost_offset_y", 0.0)) + sin(idle_time * TAU / 1.6 + index * 0.4) * 1.6, ghost_size.x, ghost_size.y), alpha)
		# 渐隐期：仍画活体图，按 alpha 衰减
		if bool(phase.get("alive_visible", false)):
			var fade_alpha: float = float(phase.get("alive_alpha", 0.0))
			var monster_tex: Texture2D = scene._get_monster_texture(enemy)
			if monster_tex:
				var visual_scale: float = float(enemy.get("_visualScale", 1.0))
				var final_sprite_size: float = sprite_size * visual_scale
				scene._draw_texture_contain(monster_tex, Rect2(cx - final_sprite_size / 2.0, y + 11.0 - (final_sprite_size - sprite_size) * 0.3 + sin(idle_time * TAU / 1.5 + index * 0.4) * 2.4, final_sprite_size, final_sprite_size), fade_alpha)
		return
	if has_flash:
		_draw_hit_ring(scene, _enemy_sprite_center(enemy, index, battle, state), 82.0, flash[0])
	# ★ 主人定 2026-06-11：攻击者弹性放大
	var elastic := _attacker_elastic_factor(state, true, index)
	var monster_tex: Texture2D = scene._get_monster_texture(enemy)
	if monster_tex:
		# ★ 主人定 2026-06-10：phase 2 体型 ×1.5
		var visual_scale: float = float(enemy.get("_visualScale", 1.0))
		var final_sprite_size: float = sprite_size * visual_scale * elastic
		var sprite_rect := Rect2(cx - final_sprite_size / 2.0, y + 11.0 - (final_sprite_size - sprite_size * elastic) * 0.3 + sin(idle_time * TAU / 1.5 + index * 0.4) * 2.4, final_sprite_size, final_sprite_size)
		scene._draw_texture_contain(monster_tex, sprite_rect, 1.0)
		if has_flash:
			_draw_soft_hit_flash(scene, monster_tex, sprite_rect, flash[0])
	else:
		scene._draw_text_with_shadow(enemy.get("emoji", "👾"), cx, y + 43.0, colors.get("white", Color.WHITE), 34.0)
	scene._draw_text_with_shadow(name, cx, y + 14.0, colors.get("text_primary", Color.WHITE), 10.4, true)
	var enemy_hp_rect := Rect2(x + 7.0, y + 80.0, slot_w - 14.0, 10.0)
	scene._draw_hp_bar(enemy_hp_rect.position.x, enemy_hp_rect.position.y, enemy_hp_rect.size.x, enemy_hp_rect.size.y, float(hp), float(max_hp), colors.get("danger", Color.RED))
	scene._draw_hp_text_in_bar("%d/%d" % [hp, max_hp], enemy_hp_rect, colors.get("white", Color.WHITE))
	# ★ 主人定 2026-06-11：精英怪在血条左前加 ★ 标识
	if bool(enemy.get("isElite", false)):
		scene._draw_text_with_shadow("★", x + 3.0, y + 86.0, colors.get("gold", Color(1.0, 0.82, 0.18, 1.0)), 9.0, true)

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
	if enemy_count <= 1:
		return [Vector2(139.5, 63.0)]
	if enemy_count == 2:
		return [Vector2(82.0, 74.0), Vector2(197.0, 74.0)]
	return [Vector2(24.0, 72.0), Vector2(139.5, 63.0), Vector2(255.0, 72.0)]

static func uses_featured_single_layout(enemy: Dictionary) -> bool:
	return enemy != null and (bool(enemy.get("isBoss", false)) or bool(enemy.get("isElite", false)))

# ★ 主人定 2026-06-11：算出敌人 sprite 的真实视觉中心
# 优先用 .tscn 里 Portrait 节点的实际位置（gui_enemy_centers），让攻击特效跟着场景布局走
# 没有场景节点时回落到老的硬编码 Rect2 计算（与 draw_enemy_stage / draw_enemy_card 保持一致）
static func _enemy_sprite_center(enemy: Dictionary, index: int, battle, state: Dictionary) -> Vector2:
	# 优先：场景节点中心（.tscn 里 Portrait 的真实位置）
	var gui_centers: Array = state.get("gui_enemy_centers", [])
	if index >= 0 and index < gui_centers.size():
		var c: Vector2 = gui_centers[index]
		if c != Vector2.ZERO:
			return c
	# 回落：老的硬编码 Rect2 计算
	var design_w: float = state.get("design_w", 375.0)
	var idle_time: float = state.get("idle_time", 0.0)
	var is_boss: bool = bool(enemy.get("isBoss", false))
	var visual_scale: float = float(enemy.get("_visualScale", 1.0))
	var enemy_count: int = battle.enemies.size() if battle != null else 1
	if enemy_count <= 1 and uses_featured_single_layout(enemy):
		# 只有单 Boss / 单精英使用放大的 stage 布局。
		var boss_scale: float = SINGLE_BOSS_SPRITE_SIZE if is_boss else SINGLE_ENEMY_SPRITE_SIZE
		var final_size: float = boss_scale * visual_scale
		var base_y: float = 104.0 if is_boss else 111.0
		var top_y: float = base_y - (final_size - boss_scale) * 0.3 + sin(idle_time * TAU / 1.8) * 3.0
		return Vector2(design_w / 2.0, top_y + final_size / 2.0)
	# 多怪 card 布局
	var slots := _multi_enemy_slots(mini(enemy_count, 3))
	if index < 0 or index >= slots.size():
		return Vector2(design_w / 2.0, 170.0)
	var slot_x: float = slots[index].x
	var slot_y: float = slots[index].y
	var sprite_size: float = MULTI_BOSS_SPRITE_SIZE if is_boss else MULTI_ENEMY_SPRITE_SIZE
	var final_sprite_size: float = sprite_size * visual_scale
	var top_y: float = slot_y + 11.0 - (final_sprite_size - sprite_size) * 0.3 + sin(idle_time * TAU / 1.5 + index * 0.4) * 2.4
	return Vector2(slot_x + 48.0, top_y + final_sprite_size / 2.0)

# ★ 主人定 2026-06-11：算出玩家 sprite 的真实视觉中心
# 优先用 .tscn 里 Portrait 节点的实际位置（gui_player_centers）；GUI 模式下不叠加旧 lunge，
# 避免只让攻击光圈/弹道移动而角色本身不动。
# 没有场景节点时回落到老的 (18 + idx*116 + 53, 250) 硬编码
static func _player_sprite_center(index: int, state: Dictionary) -> Vector2:
	var lunge_offset_y: float = 0.0
	var lunge_anims: Array = state.get("player_lunge_anims", [])
	for anim in lunge_anims:
		if int(anim.get("playerIndex", -1)) == index:
			var max_duration: float = maxf(0.01, float(anim.get("maxDuration", anim.get("duration", 0.3))))
			var t: float = clampf(1.0 - float(anim.get("timer", max_duration)) / max_duration, 0.0, 1.0)
			if t < 0.4:
				lunge_offset_y = -16.0 * (t / 0.4)
			else:
				lunge_offset_y = -16.0 * (1.0 - (t - 0.4) / 0.6)
			break
	# 优先：场景节点中心（.tscn 里 Portrait 的真实位置）
	var gui_centers: Array = state.get("gui_player_centers", [])
	if index >= 0 and index < gui_centers.size():
		var c: Vector2 = gui_centers[index]
		if c != Vector2.ZERO:
			return c
	# 回落：老的硬编码
	var idle_time: float = state.get("idle_time", 0.0)
	var x: float = 18.0 + float(index) * 116.0
	var y: float = 218.0
	var offset_y: float = sin(idle_time * TAU / 1.5) * 1.2 + lunge_offset_y
	# sprite 顶 = y + 3 + offset_y, sprite 高 = 58, 中心 y = y + 32 + offset_y
	return Vector2(x + 53.0, y + 32.0 + offset_y)

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
			return "res://assets/images/ui/icons/battle_ui_intent_danger.png"
		"warning":
			return "res://assets/images/ui/icons/battle_ui_intent_warning.png"
		"shield":
			return "res://assets/images/ui/icons/battle_ui_intent_shield.png"
		"heal", "safe":
			return "res://assets/images/ui/icons/battle_ui_intent_heal.png"
		_:
			return "res://assets/images/ui/icons/battle_ui_intent_normal.png"

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
		var shield_tex: Texture2D = scene._get_texture("res://assets/images/effects/battle_fx_shield_ring.png")
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
		var charge_tex: Texture2D = scene._get_texture("res://assets/images/effects/battle_fx_charge_aura.png")
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
	var label := "%s%d" % [emoji, turns]
	var hp_rects: Array = state.get("gui_enemy_hp_rects", [])
	if index >= 0 and index < hp_rects.size() and hp_rects[index] is Rect2:
		var hp_rect: Rect2 = hp_rects[index]
		var text_x := hp_rect.end.x - 8.0
		var text_y := hp_rect.end.y + 9.0
		scene._draw_text_with_shadow(label, text_x, text_y, status_color, 9.5, true)
		return
	scene._draw_text_with_shadow(label, x + card_w - 8.0, y + 104.0, status_color, 9.5, true)

static func _ensure_enemy_defeat_fx(scene, state: Dictionary, index: int, center: Vector2, color: Color) -> void:
	var defeated_enemies: Array = state.get("defeated_enemies", [])
	if defeated_enemies.has(index):
		return
	defeated_enemies.append(index)
	scene._spawn_defeat_particles(center.x, center.y, color)

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
	if battle.enemies.size() == 1 and uses_featured_single_layout(battle.enemies[0]):
		var enemy: Dictionary = battle.enemies[0]
		if enemy == null:
			return
		var hp: int = maxi(enemy.get("hp", 0), 0)
		if hp <= 0:
			_ensure_enemy_defeat_fx(scene, state, 0, Vector2(state.get("design_w", 375.0) / 2.0, 170.0), colors.get("danger", Color.RED))
		else:
			var flash: Array = state.get("hit_flashes", []).filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == 0)
			if not flash.is_empty():
				_draw_hit_ring(scene, _enemy_sprite_center(enemy, 0, battle, state), 96.0 if bool(enemy.get("isBoss", false)) else 82.0, flash[0])
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
			if hp <= 0:
				_ensure_enemy_defeat_fx(scene, state, i, Vector2(cx, y + 48.0), colors.get("danger", Color.RED))
				continue
			var flash: Array = state.get("hit_flashes", []).filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == i)
			if not flash.is_empty():
				_draw_hit_ring(scene, _enemy_sprite_center(enemy, i, battle, state), 82.0, flash[0])
			_draw_boss_visuals(scene, state, x, y, i, hp)
			_draw_enemy_status(scene, battle, state, x, y, i, hp, 96.0)
	for i in range(mini(battle.player_team.size(), 3)):
		var monster: Dictionary = battle.player_team[i]
		if monster == null:
			continue
		var flash: Array = state.get("hit_flashes", []).filter(func(f): return not f.get("isEnemy", false) and f.get("monsterIndex", -1) == i)
		if not flash.is_empty():
			_draw_hit_ring(scene, _player_sprite_center(i, state), 78.0, flash[0])
	# ★ 主人定 2026-06-10：弹道动画（同属性颜色，从玩家弹向目标）
	_draw_bullet_anims(scene, state)
	_draw_attack_cues(scene, battle, state)

static func _draw_bullet_anims(scene, state: Dictionary) -> void:
	var bullets: Array = state.get("bullet_anims", [])
	if bullets.is_empty():
		return
	var canvas: CanvasItem = scene
	var battle = scene._battle if scene != null else null
	for anim in bullets:
		var player_idx: int = int(anim.get("playerIndex", -1))
		var target_idx: int = int(anim.get("targetIndex", -1))
		if player_idx < 0 or target_idx < 0:
			continue
		var max_duration: float = maxf(0.01, float(anim.get("maxDuration", anim.get("duration", 0.4))))
		var t: float = clampf(1.0 - float(anim.get("timer", max_duration)) / max_duration, 0.0, 1.0)
		# ★ 主人定 2026-06-11：起终点跟随真实 sprite 中心（含 visualScale + bob + lunge）
		var start_pos: Vector2 = _player_sprite_center(player_idx, state)
		var end_pos: Vector2 = Vector2(state.get("design_w", 375.0) / 2.0, 175.0)
		if battle != null and target_idx >= 0 and target_idx < battle.enemies.size():
			var target_enemy: Dictionary = battle.enemies[target_idx]
			if target_enemy != null and not target_enemy.is_empty():
				end_pos = _enemy_sprite_center(target_enemy, target_idx, battle, state)
		var start_x: float = start_pos.x
		var start_y: float = start_pos.y
		var end_x: float = end_pos.x
		var end_y: float = end_pos.y
		# 插值位置（带越走越快的函数）
		var eased_t: float = 1.0 - pow(1.0 - t, 2.0)
		var cur_x: float = lerpf(start_x, end_x, eased_t)
		var cur_y: float = lerpf(start_y, end_y, eased_t)
		# 弹道颜色（同属性）
		var element: String = str(anim.get("element", "fire"))
		var bullet_color: Color = _element_color(element)
		# 弹道尺寸：后期略小（模拟飞行衰减）
		var bullet_size: float = lerpf(16.0, 8.0, t)
		# 透明度：后期衰减
		var alpha: float = 1.0 - t * 0.3
		# 画发光圈
		canvas.draw_circle(Vector2(cur_x, cur_y), bullet_size * 1.6, Color(bullet_color.r, bullet_color.g, bullet_color.b, 0.35 * alpha))
		# 画核心
		canvas.draw_circle(Vector2(cur_x, cur_y), bullet_size, Color(bullet_color.r, bullet_color.g, bullet_color.b, 0.85 * alpha))
		# 画亮点
		canvas.draw_circle(Vector2(cur_x, cur_y), bullet_size * 0.45, Color(1, 1, 1, 0.85 * alpha))
		# 画轨迹尾巴（4 个递减的圆点）
		for i in range(4):
			var trail_t: float = eased_t - (i + 1) * 0.05
			if trail_t < 0.0:
				continue
			var trail_x: float = lerpf(start_x, end_x, trail_t)
			var trail_y: float = lerpf(start_y, end_y, trail_t)
			var trail_alpha: float = (1.0 - i * 0.22) * 0.4 * (1.0 - t)
			var trail_size: float = bullet_size * (1.0 - i * 0.18)
			canvas.draw_circle(Vector2(trail_x, trail_y), trail_size, Color(bullet_color.r, bullet_color.g, bullet_color.b, trail_alpha))

static func _draw_attack_cues(scene, battle, state: Dictionary) -> void:
	var cues: Array = state.get("attack_cues", [])
	if cues.is_empty():
		return
	var canvas: CanvasItem = scene
	for cue: Dictionary in cues:
		var duration: float = maxf(0.01, float(cue.get("duration", 0.58)))
		var remaining: float = clampf(float(cue.get("timer", duration)), 0.0, duration)
		var progress: float = clampf(1.0 - remaining / duration, 0.0, 1.0)
		var alpha: float = minf(1.0, progress / 0.12)
		if progress > 0.78:
			alpha = minf(alpha, (1.0 - progress) / 0.22)
		alpha = clampf(alpha, 0.0, 1.0)
		if alpha <= 0.0:
			continue
		var attacker_pos := _combatant_center(bool(cue.get("attacker_is_enemy", false)), int(cue.get("attacker_index", -1)), battle, state)
		var target_pos := _combatant_center(bool(cue.get("target_is_enemy", false)), int(cue.get("target_index", -1)), battle, state)
		var element := str(cue.get("element", "fire"))
		var color := _element_color(element)
		if bool(cue.get("charged", false)):
			color = Color(1.0, 0.34, 0.16).lerp(color, 0.28)
		var pulse := 0.5 + 0.5 * sin(progress * TAU * 2.0)
		var attacker_radius := 26.0 + pulse * 5.0
		var target_radius := 30.0 - pulse * 3.0
		canvas.draw_circle(attacker_pos, attacker_radius + 7.0, Color(color.r, color.g, color.b, 0.13 * alpha))
		canvas.draw_arc(attacker_pos, attacker_radius, -PI * 0.15, PI * 1.85, 48, Color(color.r, color.g, color.b, 0.86 * alpha), 3.0, true)
		canvas.draw_arc(target_pos, target_radius, -PI * 0.35, PI * 1.65, 48, Color(1.0, 0.36, 0.22, 0.82 * alpha), 3.0, true)
		canvas.draw_circle(target_pos, 4.0 + pulse * 2.0, Color(1.0, 0.95, 0.66, 0.72 * alpha))
		var flight: float = clampf((progress - 0.08) / 0.72, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - flight, 2.0)
		var projectile_pos := attacker_pos.lerp(target_pos, eased)
		canvas.draw_line(attacker_pos, target_pos, Color(color.r, color.g, color.b, 0.25 * alpha), 2.0, true)
		for i in range(4):
			var trail_t := maxf(0.0, eased - float(i + 1) * 0.055)
			var trail_pos := attacker_pos.lerp(target_pos, trail_t)
			canvas.draw_circle(trail_pos, maxf(2.0, 8.0 - float(i) * 1.4), Color(color.r, color.g, color.b, (0.34 - float(i) * 0.06) * alpha))
		canvas.draw_circle(projectile_pos, 15.0 if bool(cue.get("charged", false)) else 11.0, Color(color.r, color.g, color.b, 0.38 * alpha))
		canvas.draw_circle(projectile_pos, 6.0 if bool(cue.get("charged", false)) else 4.5, Color(1.0, 1.0, 1.0, 0.92 * alpha))
		var label := str(cue.get("label", ""))
		if not label.is_empty():
			var label_pos := attacker_pos.lerp(target_pos, 0.5) + Vector2(0.0, -34.0)
			scene._draw_fx_text(canvas, label, label_pos.x, label_pos.y, Color(1.0, 0.96, 0.74, alpha), 10.5, 190.0, "normal")

static func _combatant_center(is_enemy: bool, index: int, battle, state: Dictionary) -> Vector2:
	# ★ 主人定 2026-06-11：攻击特效中心点要严格跟随 sprite 实际位置
	# 否则精英 ×1.2 / phase 2 ×1.5 / idle bob / lunge 时特效会偏出怪物
	var design_w: float = state.get("design_w", 375.0)
	if is_enemy:
		if battle == null:
			return Vector2(design_w / 2.0, 170.0)
		if index < 0 or index >= battle.enemies.size():
			return Vector2(design_w / 2.0, 170.0)
		var enemy: Dictionary = battle.enemies[index]
		if enemy == null or enemy.is_empty():
			return Vector2(design_w / 2.0, 170.0)
		return _enemy_sprite_center(enemy, index, battle, state)
	if index >= 0:
		return _player_sprite_center(index, state)
	return Vector2(design_w / 2.0, 251.0)

static func draw_player_card(scene, battle, state: Dictionary, x: float, y: float, index: int, name: String, hp: int, max_hp: int, monster: Dictionary) -> void:
	var colors: Dictionary = state.get("colors", {})
	var idle_time: float = state.get("idle_time", 0.0)
	var card_w: float = 106.0
	var flash: Array = state.get("hit_flashes", []).filter(func(f): return not f.get("isEnemy", false) and f.get("monsterIndex", -1) == index)
	if not flash.is_empty():
		_draw_hit_ring(scene, _player_sprite_center(index, state), 78.0, flash[0])
	# ★ 主人定 2026-06-10：玩家宠物弹动偏移（往前走一下回位）
	var lunge_offset_y: float = 0.0
	var lunge_anims: Array = state.get("player_lunge_anims", [])
	for anim in lunge_anims:
		if int(anim.get("playerIndex", -1)) == index:
			var max_duration: float = maxf(0.01, float(anim.get("maxDuration", anim.get("duration", 0.3))))
			var t: float = clampf(1.0 - float(anim.get("timer", max_duration)) / max_duration, 0.0, 1.0)
			# 0 → 0.4 期间从 0 到 -16（往上往目标弹），0.4 → 1.0 期间回位
			if t < 0.4:
				lunge_offset_y = -16.0 * (t / 0.4)
			else:
				lunge_offset_y = -16.0 * (1.0 - (t - 0.4) / 0.6)
			break

	# ★ 主人定 2026-06-11：攻击者弹性放大
	var elastic := _attacker_elastic_factor(state, false, index)
	var visual_scale := _combatant_visual_scale(monster)
	var monster_tex: Texture2D = scene._get_monster_texture(monster)
	if hp <= 0:
		# ★ 主人定 2026-06-11：倒下阶段：先活体图渐隐，再幽灵从下冲上渐显
		var phase := _defeat_phase(scene, state, false, index, idle_time)
		if bool(phase.get("ghost_visible", true)):
			var alpha: float = float(phase.get("ghost_alpha", 1.0))
			scene._draw_texture_contain(_get_ghost_texture(scene), Rect2(x + 53.0 - 29.0, y + 33.0 - 29.0 + float(phase.get("ghost_offset_y", 0.0)) + sin(idle_time * TAU / 1.7 + index * 0.3) * 1.2, 58.0, 58.0), alpha)
		if bool(phase.get("alive_visible", false)):
			var fade_alpha: float = float(phase.get("alive_alpha", 0.0))
			if monster_tex:
				scene._draw_texture_contain(monster_tex, _player_sprite_rect(x, y, lunge_offset_y, idle_time, index, visual_scale, 1.0), fade_alpha)
			else:
				scene._draw_text_with_shadow(monster.get("emoji", "👾"), x + 53.0, y + 36.0 + lunge_offset_y, colors.get("white", Color.WHITE).darkened(0.0), fade_alpha)
	elif monster_tex:
		var sprite_rect := _player_sprite_rect(x, y, lunge_offset_y, idle_time, index, visual_scale, elastic)
		scene._draw_texture_contain(monster_tex, sprite_rect, 1.0)
		if not flash.is_empty():
			_draw_soft_hit_flash(scene, monster_tex, sprite_rect, flash[0])
	else:
		scene._draw_text_with_shadow(monster.get("emoji", "👾"), x + 53.0, y + 36.0 + lunge_offset_y, colors.get("white", Color.WHITE), 31.0)
	scene._draw_text_with_shadow(name, x + card_w / 2.0, y + 8.0, colors.get("text_primary", Color.WHITE), 10.0)
	var player_hp_rect := Rect2(x + 4.0, y + 52.0, card_w - 8.0, 11.0)
	scene._draw_hp_bar(player_hp_rect.position.x, player_hp_rect.position.y, player_hp_rect.size.x, player_hp_rect.size.y, float(hp), float(max_hp), colors.get("success", Color.GREEN))
	scene._draw_hp_text_in_bar("%d/%d" % [hp, max_hp], player_hp_rect, colors.get("white", Color.WHITE))

static func _combatant_visual_scale(unit: Dictionary) -> float:
	return float(unit.get("_visualScale", StatCalculator.visual_scale_for_stats(unit)))

static func _player_sprite_rect(x: float, y: float, lunge_offset_y: float, idle_time: float, _index: int, visual_scale: float, elastic: float) -> Rect2:
	var base_pos := Vector2(x + 8.0, y + 3.0 + lunge_offset_y + sin(idle_time * TAU / 1.5) * 1.2)
	var base_size := Vector2(90.0, 58.0)
	var scale := maxf(0.1, visual_scale * elastic)
	var size := base_size * scale
	return Rect2(base_pos + (base_size - size) * 0.5, size)

static func _draw_defeated_ghost(scene, center: Vector2, size: Vector2) -> void:
	# legacy 入口（仅在 GUI 模式下保留向后兼容）
	var ghost_tex: Texture2D = _get_ghost_texture(scene)
	if ghost_tex:
		scene._draw_texture_contain(ghost_tex, Rect2(center - size * 0.5, size), 1.0)
	else:
		scene._draw_text_with_shadow("T_T", center.x, center.y + 5.0, Color(0.86, 0.92, 1.0, 1.0), 18.0, true)

static func _draw_soft_hit_flash(scene, tex: Texture2D, rect: Rect2, flash: Dictionary) -> void:
	if tex == null:
		return
	var max_t: float = maxf(0.01, float(flash.get("maxTimer", 0.4)))
	var flash_t: float = clampf(float(flash.get("timer", 0.0)) / max_t, 0.0, 1.0)
	var alpha: float = pow(flash_t, 0.72) * 0.32
	if alpha <= 0.0:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var target := Rect2(rect.position + (rect.size - draw_size) / 2.0, draw_size)
	scene.draw_texture_rect(tex, target, false, Color(1.18, 1.13, 0.94, alpha))

static func _draw_hit_ring(scene, center: Vector2, size: float, flash: Dictionary) -> void:
	var max_t: float = maxf(0.01, float(flash.get("maxTimer", 0.4)))
	var remaining: float = clampf(float(flash.get("timer", 0.0)) / max_t, 0.0, 1.0)
	var progress: float = 1.0 - remaining
	var alpha: float = pow(remaining, 0.82) * 0.58
	if alpha <= 0.0:
		return
	var radius: float = size * (0.22 + progress * 0.32)
	var width: float = maxf(1.4, 3.4 * (1.0 - progress * 0.35))
	scene.draw_arc(center, radius, 0.0, TAU, 54, Color(1.0, 0.86, 0.48, alpha), width, true)
	scene.draw_arc(center, radius * 0.72, 0.0, TAU, 44, Color(1.0, 0.96, 0.74, alpha * 0.46), maxf(1.0, width * 0.55), true)

# ★ 主人定 2026-06-11：取幽灵贴图（统一从 _get_texture 取，失败回落到 T_T 文字）
static func _get_ghost_texture(scene) -> Texture2D:
	return scene._get_texture(DEFEATED_GHOST_ASSET)

# ★ 主人定 2026-06-11：计算倒下阶段
# 0.00~0.20 活体图 alpha 1→0（alive_visible=true）
# 0.20~0.30 空隙（什么都不画）
# 0.30~1.00 幽灵从下冲上（offset_y 30→0）+ alpha 0→1
# 没有 transition 记录时走 legacy：直接显示 ghost
static func _defeat_phase(scene, state: Dictionary, is_enemy: bool, index: int, idle_time: float) -> Dictionary:
	var transitions: Array = state.get("defeat_transitions", [])
	for entry in transitions:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			var max_t: float = maxf(0.01, float(entry.get("maxDuration", entry.get("duration", 0.7))))
			var t: float = clampf(1.0 - float(entry.get("timer", max_t)) / max_t, 0.0, 1.0)
			var result := {
				"alive_visible": false,
				"alive_alpha": 0.0,
				"ghost_visible": false,
				"ghost_offset_y": 30.0,
				"ghost_alpha": 0.0,
			}
			if t < 0.20:
				# 活体图渐隐
				result["alive_visible"] = true
				result["alive_alpha"] = 1.0 - (t / 0.20)
			elif t < 0.30:
				# 空隙
				pass
			elif t < 1.0:
				var rise: float = (t - 0.30) / 0.70
				result["ghost_visible"] = true
				result["ghost_offset_y"] = 30.0 * (1.0 - rise)
				result["ghost_alpha"] = rise
			else:
				result["ghost_visible"] = true
				result["ghost_offset_y"] = 0.0
				result["ghost_alpha"] = 1.0
			return result
	# 没 transition 记录：legacy 行为（直接显示 ghost）
	return {
		"alive_visible": false,
		"alive_alpha": 0.0,
		"ghost_visible": true,
		"ghost_offset_y": 0.0,
		"ghost_alpha": 1.0,
	}

# ★ 主人定 2026-06-11：攻击者小幅度弹性放大
# progress 0→0.10 1.0→1.08（蓄力）
# progress 0.10→0.25 1.08→0.97（过冲回弹）
# progress 0.25→0.40 0.97→1.02（小回弹）
# progress 0.40→1.0 1.02→1.0（稳定）
# 没有 anim 时回 1.0
static func _attacker_elastic_factor(state: Dictionary, is_enemy: bool, index: int) -> float:
	var anims: Array = state.get("attacker_elastic_anims", [])
	for entry in anims:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			var max_t: float = maxf(0.01, float(entry.get("maxDuration", entry.get("duration", 0.32))))
			var t: float = clampf(1.0 - float(entry.get("timer", max_t)) / max_t, 0.0, 1.0)
			if t < 0.10:
				return 1.0 + 0.08 * (t / 0.10)
			elif t < 0.25:
				var p: float = (t - 0.10) / 0.15
				return 1.08 - 0.11 * p
			elif t < 0.40:
				var p2: float = (t - 0.25) / 0.15
				return 0.97 + 0.05 * p2
			elif t < 1.0:
				var p3: float = (t - 0.40) / 0.60
				return 1.02 - 0.02 * p3
			return 1.0
	return 1.0

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
		var charge_tex: Texture2D = scene._get_texture("res://assets/images/effects/battle_fx_charge_aura.png")
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

static func _stage_ring_asset_path(element: String) -> String:
	match element:
		"grass":
			return "res://assets/images/effects/battle_fx_stage_ring_green.png"
		"fire":
			return "res://assets/images/effects/battle_fx_stage_ring_fire.png"
		"dark", "void", "temporal":
			return "res://assets/images/effects/battle_fx_stage_ring_void.png"
		_:
			return "res://assets/images/effects/battle_fx_stage_ring_cyan.png"

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

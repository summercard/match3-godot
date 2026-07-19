extends Control

signal back_pressed

const MonsterDbScript := preload("res://src/data/monster_db.gd")
const MonsterArtDBScript := preload("res://src/data/monster_art_db.gd")
const LeaderSkillVisualDbScript := preload("res://src/data/leader_skill_visual_db.gd")
const MOTE_PATH := "res://assets/images/ui/leader_skills/particles/leader_fx_mote.png"
const FIRE_PARTICLE_PATH := "res://assets/images/ui/leader_skills/particles/leader_fx_element_fire.png"
const ELEMENT_PARTICLE_PATHS := {
	"fire": "res://assets/images/ui/leader_skills/particles/leader_fx_element_fire.png",
	"water": "res://assets/images/ui/leader_skills/particles/leader_fx_element_water.png",
	"grass": "res://assets/images/ui/leader_skills/particles/leader_fx_element_grass.png",
	"wind": "res://assets/images/ui/leader_skills/particles/leader_fx_element_wind.png",
	"earth": "res://assets/images/ui/leader_skills/particles/leader_fx_element_earth.png",
	"light": "res://assets/images/ui/leader_skills/particles/leader_fx_element_light.png",
	"dark": "res://assets/images/ui/leader_skills/particles/leader_fx_element_dark.png",
	"thunder": "res://assets/images/ui/leader_skills/particles/leader_fx_element_thunder.png",
	"ice": "res://assets/images/ui/leader_skills/particles/leader_fx_element_ice.png"
}
const TONE_ELEMENT_PARTICLES := {
	"fire": "fire",
	"balanced": "grass",
	"heal": "grass",
	"speed": "wind",
	"guard": "water",
	"bulwark": "earth",
	"siphon": "dark",
	"chain": "thunder"
}
const FIRE_TRAIL_OUTER_WIDTH := 8.0
const FIRE_TRAIL_MID_WIDTH := 4.8
const FIRE_TRAIL_CORE_WIDTH := 1.8
const FIRE_TRAIL_PARTICLE_SIZE := 42.0
const FIRE_TRAIL_PARTICLE_VARIANCE := 22.0
const FIRE_BURST_PARTICLE_SIZE := 40.0
const FIRE_BURST_PARTICLE_VARIANCE := 24.0
const FIRE_IMPACT_SPRITE_SIZE := 58.0
const FIRE_IMPACT_SPRITE_VARIANCE := 30.0

const DESIGN_SIZE := Vector2(375.0, 667.0)
const TEAM_IDS := ["monster_002", "monster_093", "monster_053"]
const ENEMY_IDS := ["monster_015", "monster_026", "monster_083"]
const TONE_ORDER := ["fire", "balanced", "heal", "speed", "guard", "bulwark", "siphon", "chain"]
const TONE_LABELS := {
	"fire": "火焰",
	"balanced": "均衡",
	"heal": "治疗",
	"speed": "疾风",
	"guard": "潮汐",
	"bulwark": "岩壁",
	"siphon": "暗影",
	"chain": "雷链"
}

var _texture_cache: Dictionary = {}
var _fx: Array[Dictionary] = []
var _float_texts: Array[Dictionary] = []
var _team: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _last_tone := "balanced"
var _last_dispatch := "crest_beam"
var _status_label: Label = null


func _ready() -> void:
	size = DESIGN_SIZE
	custom_minimum_size = DESIGN_SIZE
	_setup_units()
	_build_ui()
	set_process(true)
	queue_redraw()


func init(_data: Dictionary = {}) -> void:
	pass


func get_test_profile() -> Dictionary:
	var active_kinds: Array[String] = []
	for fx in _fx:
		active_kinds.append(str(fx.get("kind", "")))
	return {
		"tones": TONE_ORDER.duplicate(),
		"team_count": _team.size(),
		"enemy_count": _enemies.size(),
		"active_fx": _fx.size(),
		"active_kinds": active_kinds,
		"last_tone": _last_tone,
		"last_dispatch": _last_dispatch,
		"fire_trail_width": FIRE_TRAIL_OUTER_WIDTH,
		"fire_particle_min_size": FIRE_BURST_PARTICLE_SIZE,
		"fire_trail_particle_size": FIRE_TRAIL_PARTICLE_SIZE,
		"fire_impact_size": FIRE_IMPACT_SPRITE_SIZE
	}


func _setup_units() -> void:
	_team.clear()
	for id in TEAM_IDS:
		var unit := MonsterDbScript.get_monster_stats(id, 18)
		if unit.is_empty():
			unit = {"id": id, "name": id, "element": "grass", "hp": 100, "maxHP": 100}
		unit["hp"] = int(float(unit.get("maxHP", 100)) * (0.62 + 0.12 * float(_team.size())))
		_team.append(unit)
	_enemies.clear()
	for id in ENEMY_IDS:
		var enemy := MonsterDbScript.get_monster_stats(id, 16)
		if enemy.is_empty():
			enemy = {"id": id, "name": id, "element": "earth", "hp": 100, "maxHP": 100}
		enemy["hp"] = int(float(enemy.get("maxHP", 100)) * (0.56 + 0.08 * float(_enemies.size())))
		_enemies.append(enemy)


func _build_ui() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "返回"
	back.position = Vector2(12.0, 12.0)
	back.size = Vector2(58.0, 32.0)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)

	var title := Label.new()
	title.name = "Title"
	title.text = "队长技能表现测试"
	title.position = Vector2(82.0, 11.0)
	title.size = Vector2(210.0, 32.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.28, 0.14, 0.05))
	add_child(title)

	for i in range(TONE_ORDER.size()):
		var tone := str(TONE_ORDER[i])
		var button := Button.new()
		button.name = "SkillButton_%s" % tone
		button.text = str(TONE_LABELS.get(tone, tone))
		button.position = Vector2(13.0 + float(i % 4) * 87.0, 56.0 + float(i / 4) * 38.0)
		button.size = Vector2(80.0, 32.0)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = "%s / %s" % [LeaderSkillVisualDbScript.get_profile(tone).get("name", tone), LeaderSkillVisualDbScript.get_dispatch(tone)]
		button.pressed.connect(_trigger_tone.bind(tone))
		add_child(button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "选择上方按钮释放技能表现"
	_status_label.position = Vector2(12.0, 130.0)
	_status_label.size = Vector2(351.0, 26.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.42, 0.22, 0.08))
	add_child(_status_label)


func _process(delta: float) -> void:
	var changed := false
	for i in range(_fx.size() - 1, -1, -1):
		_fx[i]["timer"] = float(_fx[i].get("timer", 0.0)) - delta
		if float(_fx[i].get("timer", 0.0)) <= 0.0:
			_fx.remove_at(i)
		changed = true
	for i in range(_float_texts.size() - 1, -1, -1):
		_float_texts[i]["timer"] = float(_float_texts[i].get("timer", 0.0)) + delta
		if float(_float_texts[i].get("timer", 0.0)) >= float(_float_texts[i].get("duration", 0.8)):
			_float_texts.remove_at(i)
		changed = true
	if changed:
		queue_redraw()


func _trigger_tone(tone: String) -> void:
	_last_tone = tone
	_last_dispatch = LeaderSkillVisualDbScript.get_dispatch(tone)
	if tone == "fire":
		_last_dispatch = "fire_burst"
	_status_label.text = "%s / %s" % [str(TONE_LABELS.get(tone, tone)), _last_dispatch]
	_fx.clear()
	_float_texts.clear()
	var leader_pos := _team_pos(0)
	var target_pos := _enemy_pos(1)
	_add_fx({"kind": "crest", "tone": tone, "center": leader_pos, "duration": 0.72})
	match _last_dispatch:
		"ally_bloom":
			for i in range(_team.size()):
				_add_fx({"kind": "ally", "tone": tone, "center": _team_pos(i), "delay": 0.08 * float(i), "duration": 0.82})
				_add_float_text("+恢复", _team_pos(i) + Vector2(0.0, -26.0), Color(0.20, 0.88, 0.35), 17.0, 0.10 + 0.08 * float(i))
		"enemy_mark":
			for i in range(_enemies.size()):
				_add_fx({"kind": "mark", "tone": tone, "center": _enemy_pos(i), "delay": 0.07 * float(i), "duration": 0.78})
				_add_float_text("攻击下降", _enemy_pos(i) + Vector2(0.0, -24.0), _tone_color(tone), 15.0, 0.15 + 0.07 * float(i))
		"ally_shell":
			for i in range(_team.size()):
				_add_fx({"kind": "shell", "tone": tone, "center": _team_pos(i), "delay": 0.06 * float(i), "duration": 0.88})
				_add_float_text("减伤", _team_pos(i) + Vector2(0.0, -25.0), _tone_color(tone), 16.0, 0.12 + 0.06 * float(i))
		"beam_lifesteal":
			_add_fx({"kind": "beam", "tone": tone, "from": leader_pos, "to": target_pos, "duration": 0.76})
			_add_fx({"kind": "ally", "tone": tone, "center": _team_pos(2), "delay": 0.30, "duration": 0.76})
			_add_float_text("-暗伤", target_pos + Vector2(0.0, -26.0), _tone_color(tone), 18.0, 0.28)
			_add_float_text("+吸血", _team_pos(2) + Vector2(0.0, -26.0), Color(0.95, 0.28, 0.86), 16.0, 0.42)
		"beam_status":
			for i in range(_enemies.size()):
				_add_fx({"kind": "beam", "tone": tone, "from": leader_pos, "to": _enemy_pos(i), "delay": 0.08 * float(i), "duration": 0.74})
				_add_fx({"kind": "mark", "tone": tone, "center": _enemy_pos(i), "delay": 0.25 + 0.08 * float(i), "duration": 0.74})
				_add_float_text("-雷伤", _enemy_pos(i) + Vector2(0.0, -28.0), _tone_color(tone), 17.0, 0.22 + 0.08 * float(i))
				_add_float_text("眩晕", _enemy_pos(i) + Vector2(0.0, -8.0), Color(1.0, 0.78, 0.18), 14.0, 0.42 + 0.08 * float(i))
		"fire_burst":
			_add_fx({"kind": "fire_beam", "tone": tone, "from": leader_pos, "to": target_pos, "duration": 0.82})
			_add_fx({"kind": "fire_impact", "tone": tone, "center": target_pos, "delay": 0.30, "duration": 0.72})
			_add_float_text("-FIRE", target_pos + Vector2(0.0, -28.0), _tone_color(tone), 19.0, 0.24)
			_add_float_text("灼烧", target_pos + Vector2(0.0, -8.0), Color(1.0, 0.64, 0.12), 14.0, 0.44)
		_:
			_add_fx({"kind": "beam", "tone": tone, "from": leader_pos, "to": target_pos, "duration": 0.78})
			var label := "-火伤" if tone == "fire" else "-伤害"
			_add_float_text(label, target_pos + Vector2(0.0, -28.0), _tone_color(tone), 19.0, 0.24)
			if tone == "fire":
				_add_float_text("灼烧", target_pos + Vector2(0.0, -8.0), Color(1.0, 0.64, 0.12), 14.0, 0.44)
	queue_redraw()


func _add_fx(data: Dictionary) -> void:
	var duration := float(data.get("duration", 0.72))
	var delay := float(data.get("delay", 0.0))
	data["timer"] = duration + delay
	data["maxTimer"] = duration
	data["delay"] = delay
	_fx.append(data)


func _add_float_text(text: String, pos: Vector2, color: Color, size_px: float, delay: float = 0.0) -> void:
	_float_texts.append({
		"text": text,
		"x": pos.x,
		"y": pos.y,
		"color": color,
		"size": size_px,
		"timer": -delay,
		"duration": 0.92
	})


func _draw() -> void:
	_draw_background()
	_draw_board()
	for i in range(_team.size()):
		_draw_unit(_team[i], _team_pos(i), false)
	for i in range(_enemies.size()):
		_draw_unit(_enemies[i], _enemy_pos(i), true)
	_draw_fx()
	_draw_float_texts()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.73, 0.88, 0.96))
	draw_rect(Rect2(12.0, 158.0, 351.0, 470.0), Color(1.0, 0.96, 0.78, 0.70))
	draw_rect(Rect2(20.0, 166.0, 335.0, 454.0), Color(0.55, 0.78, 0.92, 0.18))
	draw_line(Vector2(187.0, 176.0), Vector2(187.0, 610.0), Color(1.0, 1.0, 1.0, 0.32), 2.0)
	draw_arc(Vector2(187.0, 392.0), 126.0, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, 0.18), 2.0, true)


func _draw_board() -> void:
	var colors := [
		Color(0.96, 0.40, 0.28),
		Color(0.24, 0.66, 0.95),
		Color(0.42, 0.80, 0.30),
		Color(0.95, 0.78, 0.20),
		Color(0.66, 0.44, 0.86)
	]
	var start := Vector2(132.0, 315.0)
	for y in range(5):
		for x in range(5):
			var p := start + Vector2(float(x) * 22.0, float(y) * 22.0)
			draw_rect(Rect2(p.x, p.y, 18.0, 18.0), Color(1.0, 1.0, 1.0, 0.45))
			draw_circle(p + Vector2(9.0, 9.0), 6.0, colors[(x + y * 2) % colors.size()])


func _draw_unit(unit: Dictionary, center: Vector2, enemy: bool) -> void:
	var ring := Color(0.42, 0.22, 0.08, 0.22) if not enemy else Color(0.62, 0.14, 0.10, 0.22)
	draw_circle(center + Vector2(0.0, 24.0), 34.0, ring)
	var path := MonsterArtDBScript.get_art_path(str(unit.get("id", "")), "battle")
	var tex := _get_texture(path)
	if tex != null:
		var size_px := 74.0 if not enemy else 68.0
		draw_texture_rect(tex, Rect2(center.x - size_px * 0.5, center.y - size_px * 0.62, size_px, size_px), false)
	else:
		draw_circle(center, 24.0, Color(0.9, 0.8, 0.55))
	var hp_ratio := clampf(float(unit.get("hp", 1)) / maxf(1.0, float(unit.get("maxHP", 1))), 0.0, 1.0)
	draw_rect(Rect2(center.x - 32.0, center.y + 35.0, 64.0, 6.0), Color(0.36, 0.16, 0.08, 0.45))
	draw_rect(Rect2(center.x - 32.0, center.y + 35.0, 64.0 * hp_ratio, 6.0), Color(0.25, 0.85, 0.30))
	var font := ThemeDB.fallback_font
	if font != null:
		var unit_name := TranslationServer.translate(str(unit.get("name", "")))
		draw_string(font, center + Vector2(-38.0, 55.0), unit_name, HORIZONTAL_ALIGNMENT_CENTER, 76.0, 12, Color(0.23, 0.12, 0.06))


func _draw_fx() -> void:
	for fx in _fx:
		var max_timer := maxf(0.01, float(fx.get("maxTimer", 0.72)))
		var remaining := float(fx.get("timer", 0.0))
		var delay := float(fx.get("delay", 0.0))
		if remaining > max_timer:
			continue
		var progress := clampf(1.0 - remaining / max_timer, 0.0, 1.0)
		var alpha := clampf(1.0 - maxf(0.0, progress - 0.72) / 0.28, 0.0, 1.0)
		var tone := str(fx.get("tone", _last_tone))
		var color := _tone_color(tone)
		match str(fx.get("kind", "")):
			"crest":
				if tone == "fire":
					_draw_fire_emitter(fx.get("center", Vector2.ZERO), progress, alpha)
				else:
					_draw_vfx_texture(fx.get("center", Vector2.ZERO), tone, 96.0, alpha * 0.98, progress, "crest")
					_draw_particles(fx.get("center", Vector2.ZERO), color, tone, progress, alpha, 5, 34.0)
			"beam":
				_draw_beam(fx.get("from", Vector2.ZERO), fx.get("to", Vector2.ZERO), tone, color, progress, alpha)
			"fire_beam":
				_draw_fire_beam(fx.get("from", Vector2.ZERO), fx.get("to", Vector2.ZERO), progress, alpha)
			"fire_impact":
				_draw_fire_impact(fx.get("center", Vector2.ZERO), progress, alpha)
			"ally":
				_draw_vfx_texture(fx.get("center", Vector2.ZERO), tone, 82.0, alpha * 0.92, progress, "ally")
				_draw_particles(fx.get("center", Vector2.ZERO), color, tone, progress, alpha, 4, 26.0)
			"shell":
				_draw_shell(fx.get("center", Vector2.ZERO), tone, color, progress, alpha)
			"mark":
				_draw_vfx_texture(fx.get("center", Vector2.ZERO), tone, 78.0, alpha * 0.96, progress, "mark")
				draw_arc(fx.get("center", Vector2.ZERO), 24.0 + progress * 18.0, -PI * 0.4, PI * 1.4, 46, Color(color.r, color.g, color.b, alpha * 0.75), 2.6, true)


func _draw_beam(start: Vector2, finish: Vector2, tone: String, color: Color, progress: float, alpha: float) -> void:
	var reach := clampf(progress / 0.45, 0.0, 1.0)
	var tip := start.lerp(finish, 1.0 - pow(1.0 - reach, 3.0))
	draw_line(start, tip, Color(color.r, color.g, color.b, 0.78 * alpha), 6.0)
	draw_line(start, tip, Color(1.0, 1.0, 0.90, 0.68 * alpha), 2.2)
	if tone == "chain":
		_draw_zap(start, tip, color, progress, alpha)
	_draw_element_trail_particles(start, tip, tone, progress, alpha)
	if reach >= 0.95:
		_draw_vfx_texture(finish, tone, 90.0, alpha, progress, "impact")
		_draw_particles(finish, color, tone, progress, alpha, 5, 24.0)


func _draw_element_trail_particles(start: Vector2, finish: Vector2, tone: String, progress: float, alpha: float) -> void:
	var dir := finish - start
	if dir.length() <= 0.1:
		return
	var tex := _get_texture(str(ELEMENT_PARTICLE_PATHS.get(str(TONE_ELEMENT_PARTICLES.get(tone, "grass")), "")))
	if tex == null:
		return
	var normal := dir.normalized().orthogonal()
	var reach := clampf(progress / 0.45, 0.0, 1.0)
	var count := 2 if tone == "chain" else 1
	for i in range(count):
		var t := clampf((float(i) + 0.45) / float(count + 1), 0.0, reach)
		if t > reach:
			continue
		var wave := sin(progress * TAU * 2.4 + float(i) * 1.71)
		var pos := start.lerp(finish, t) + normal * wave * 6.0
		match tone:
			"siphon":
				var back_t := clampf(1.0 - t * 0.72 - progress * 0.12, 0.0, 1.0)
				pos = start.lerp(finish, back_t) - normal * wave * 5.0
			"speed":
				pos += normal * (10.0 + 5.0 * sin(progress * PI)) + dir.normalized() * progress * 9.0
			"guard":
				pos = start.lerp(finish, t) + normal * sin(progress * TAU + float(i)) * 8.0
			"bulwark":
				pos = start.lerp(finish, t) + Vector2(0.0, 8.0 - progress * 14.0) + normal * wave * 3.0
			"heal":
				pos = start.lerp(finish, t) + Vector2(0.0, -8.0 - progress * 8.0) + normal * wave * 4.0
			"chain":
				pos = start.lerp(finish, t) + normal * sin(progress * TAU * 3.0 + float(i) * 2.2) * 10.0
		var size: float = (30.0 + 12.0 * absf(sin(float(i) * 1.83 + progress * PI))) * (1.12 if tone == "chain" else 1.0)
		var disappear_scale: float = 1.0 - smoothstep(0.70, 1.0, progress)
		var draw_size: float = size * clampf(disappear_scale, 0.05, 1.0)
		draw_texture_rect(tex, Rect2(pos.x - draw_size * 0.5, pos.y - draw_size * 0.5, draw_size, draw_size), false, Color.WHITE)


func _draw_shell(center: Vector2, tone: String, color: Color, progress: float, alpha: float) -> void:
	var pulse := sin(clampf(progress / 0.58, 0.0, 1.0) * PI)
	_draw_vfx_texture(center, tone, 84.0, alpha * 0.90, progress, "shell")
	draw_circle(center, 28.0 + pulse * 10.0, Color(color.r, color.g, color.b, 0.15 * alpha))
	draw_arc(center, 30.0 + pulse * 10.0, -PI * 0.85, PI * 0.18, 36, Color(color.r, color.g, color.b, 0.82 * alpha), 3.0, true)
	draw_arc(center, 30.0 + pulse * 10.0, PI * 0.25, PI * 1.25, 36, Color(1.0, 0.96, 0.72, 0.42 * alpha), 1.6, true)


func _draw_zap(start: Vector2, finish: Vector2, color: Color, progress: float, alpha: float) -> void:
	var dir := finish - start
	if dir.length() <= 0.1:
		return
	var normal := dir.normalized().orthogonal()
	var prev := start
	for i in range(1, 5):
		var t := float(i) / 5.0
		var point := start.lerp(finish, t) + normal * sin(progress * TAU * 2.0 + float(i) * 2.1) * 6.0
		draw_line(prev, point, Color(1.0, 0.94, 0.32, 0.80 * alpha), 2.2)
		draw_line(prev, point, Color(color.r, color.g, color.b, 0.60 * alpha), 4.2)
		prev = point
	draw_line(prev, finish, Color(1.0, 0.96, 0.42, 0.86 * alpha), 2.0)


func _draw_vfx_texture(center: Vector2, tone: String, size_px: float, alpha: float, progress: float = 0.0, phase: String = "burst") -> void:
	var tex := _get_texture(LeaderSkillVisualDbScript.get_asset_path(tone))
	if tex == null:
		return
	var s := maxf(8.0, size_px * LeaderSkillVisualDbScript.get_motion_scale(tone, progress, phase))
	var draw_alpha := LeaderSkillVisualDbScript.get_motion_alpha(tone, progress, alpha)
	var disappear_scale := smoothstep(0.08, 0.38, clampf(draw_alpha, 0.0, 1.0))
	var draw_size := s * clampf(disappear_scale, 0.08, 1.0)
	draw_texture_rect(tex, Rect2(center.x - draw_size * 0.5, center.y - draw_size * 0.5, draw_size, draw_size), false, Color.WHITE)


func _draw_particles(center: Vector2, color: Color, tone: String, progress: float, alpha: float, count: int, radius: float) -> void:
	if color.r > 0.95 and color.g < 0.45:
		_draw_fire_particles(center, progress, alpha, count, radius)
		return
	var tex := _get_texture(MOTE_PATH)
	var element_tex := _get_texture(str(ELEMENT_PARTICLE_PATHS.get(str(TONE_ELEMENT_PARTICLES.get(tone, "grass")), "")))
	var limit := mini(maxi(count, 0), 2)
	for i in range(limit):
		var angle := progress * TAU + float(i) * TAU / float(limit)
		var pos := center + Vector2(cos(angle), sin(angle * 1.18)) * radius * (0.40 + progress * 0.60)
		match tone:
			"heal":
				var bloom_angle := -PI * 0.5 + (float(i) - 0.5) * 0.72 + sin(progress * PI) * 0.18
				pos = center + Vector2(cos(bloom_angle) * radius * (0.32 + progress * 0.30), -radius * (0.16 + progress * 0.58) + sin(float(i) + progress * TAU) * 5.0)
			"speed":
				var swirl := progress * TAU * 1.35 + float(i) * PI
				pos = center + Vector2(cos(swirl) * radius * (0.34 + progress * 0.46), sin(swirl) * radius * (0.18 + progress * 0.38)) + Vector2(progress * 12.0, -progress * 8.0)
			"guard":
				var shell_angle := -PI * 0.82 + progress * PI * 1.25 + float(i) * PI * 0.52
				pos = center + Vector2(cos(shell_angle), sin(shell_angle)) * radius * (0.74 + 0.12 * sin(progress * PI))
			"bulwark":
				var side := -1.0 if i == 0 else 1.0
				pos = center + Vector2(side * radius * (0.22 + progress * 0.18), radius * (0.40 - progress * 0.74) + sin(float(i) + progress * PI) * 3.0)
			"siphon":
				var spiral := -progress * TAU * 1.15 + float(i) * PI
				var pull := radius * (0.86 - progress * 0.54)
				pos = center + Vector2(cos(spiral), sin(spiral * 1.08)) * pull
			"chain":
				var snap_angle := -PI * 0.16 + float(i) * PI * 1.12 + sin(progress * TAU * 2.0) * 0.12
				pos = center + Vector2(cos(snap_angle), sin(snap_angle)) * radius * (0.42 + progress * 0.42)
			_:
				var leaf_angle := -PI * 0.25 + float(i) * PI * 0.88 + progress * TAU * 0.24
				pos = center + Vector2(cos(leaf_angle), sin(leaf_angle * 1.12)) * radius * (0.34 + progress * 0.48)
		var s := 9.0 + sin(progress * PI + float(i)) * 2.0
		var element_size := (30.0 + 11.0 * absf(sin(float(i) * 1.67 + progress * PI))) * (0.88 if tone == "bulwark" else 1.0)
		if tone == "bulwark":
			element_size *= 1.18
		elif tone == "chain":
			element_size *= 0.96
		elif tone == "speed":
			element_size *= 0.90
		var modulate := Color(color.r, color.g, color.b, alpha * 0.58)
		if element_tex != null:
			var disappear_scale: float = 1.0 - smoothstep(0.72, 1.0, progress)
			var draw_size: float = element_size * clampf(disappear_scale, 0.05, 1.0)
			draw_texture_rect(element_tex, Rect2(pos.x - draw_size * 0.5, pos.y - draw_size * 0.5, draw_size, draw_size), false, Color.WHITE)
		if tex != null:
			draw_texture_rect(tex, Rect2(pos.x - s * 0.5, pos.y - s * 0.5, s, s), false, modulate)
		else:
			draw_circle(pos, s * 0.25, modulate)


func _draw_fire_emitter(center: Vector2, progress: float, alpha: float) -> void:
	var pulse := sin(clampf(progress / 0.48, 0.0, 1.0) * PI)
	draw_circle(center, 24.0 + pulse * 13.0, Color(1.0, 0.24, 0.03, 0.14 * alpha))
	draw_arc(center, 22.0 + pulse * 9.0, -PI * 0.14, PI * 1.22, 48, Color(1.0, 0.42, 0.08, 0.78 * alpha), 3.2, true)
	_draw_fire_particles(center, progress, alpha, 3, 38.0)


func _draw_fire_beam(start: Vector2, finish: Vector2, progress: float, alpha: float) -> void:
	var reach := clampf(progress / 0.48, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - reach, 3.0)
	var tip := start.lerp(finish, eased)
	var dir := tip - start
	if dir.length() <= 0.1:
		return
	var normal := dir.normalized().orthogonal()
	var points: Array[Vector2] = []
	var segments := 9
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var heat := sin(progress * TAU * 3.2 + t * TAU * 1.7)
		var curl := sin(progress * TAU * 1.7 + float(i) * 1.13)
		var offset := normal * (heat * 11.0 + curl * 5.0) * sin(t * PI)
		points.append(start.lerp(tip, t) + offset)
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		draw_line(a, b, Color(1.0, 0.16, 0.02, 0.90 * alpha), FIRE_TRAIL_OUTER_WIDTH)
		draw_line(a, b, Color(1.0, 0.50, 0.03, 0.96 * alpha), FIRE_TRAIL_MID_WIDTH)
		draw_line(a, b, Color(1.0, 0.92, 0.40, 0.90 * alpha), FIRE_TRAIL_CORE_WIDTH)
	for i in range(4):
		var t := clampf((float(i) + 0.30) / 4.0, 0.0, reach)
		var base := start.lerp(tip, t)
		var flicker := normal * sin(progress * TAU * 4.4 + float(i) * 1.9) * (9.0 + 5.0 * sin(t * PI))
		var size_jitter: float = 0.78 + 0.44 * absf(sin(float(i) * 1.73 + 0.35))
		var size: float = (FIRE_TRAIL_PARTICLE_SIZE + FIRE_TRAIL_PARTICLE_VARIANCE * (0.5 + 0.5 * sin(progress * PI + float(i)))) * size_jitter
		_draw_fire_sprite(base + flicker, i, size, alpha * (0.72 - t * 0.12), progress * 0.8 + t)
	if reach >= 0.96:
		_draw_fire_impact(finish, progress, alpha)


func _draw_fire_impact(center: Vector2, progress: float, alpha: float) -> void:
	var hit := sin(clampf(progress / 0.46, 0.0, 1.0) * PI)
	draw_circle(center, 20.0 + progress * 34.0, Color(1.0, 0.20, 0.02, 0.18 * alpha))
	draw_arc(center, 27.0 + hit * 18.0, -PI * 0.24, PI * 1.42, 62, Color(1.0, 0.39, 0.03, 0.82 * alpha), 4.0, true)
	draw_arc(center, 14.0 + hit * 11.0, PI * 0.04, PI * 1.28, 46, Color(1.0, 0.92, 0.36, 0.72 * alpha), 2.2, true)
	for i in range(2):
		var angle := -PI * 0.78 + float(i) * PI * 0.26 + progress * 0.35
		var pos := center + Vector2(cos(angle), sin(angle)) * (8.0 + hit * (10.0 + float(i % 3) * 3.0))
		var size_jitter: float = 0.82 + 0.54 * absf(sin(float(i) * 1.37 + 0.6))
		var size: float = (FIRE_IMPACT_SPRITE_SIZE + FIRE_IMPACT_SPRITE_VARIANCE * (0.35 + 0.65 * sin(progress * PI + float(i) * 0.6))) * size_jitter
		_draw_fire_sprite(pos, i + 2, size, alpha * 0.76, angle)
	_draw_fire_particles(center, progress, alpha * 0.9, 3, 52.0)


func _draw_fire_particles(center: Vector2, progress: float, alpha: float, count: int, radius: float) -> void:
	var limit := mini(maxi(count, 0), 3)
	for i in range(limit):
		var angle := progress * TAU * 1.3 + float(i) * TAU / float(limit)
		var drift := radius * (0.26 + progress * 0.78)
		var pos := center + Vector2(cos(angle), sin(angle * 1.18)) * drift
		var size_jitter: float = 0.72 + 0.62 * absf(sin(float(i) * 1.91 + 0.2))
		var size: float = (FIRE_BURST_PARTICLE_SIZE + FIRE_BURST_PARTICLE_VARIANCE * (0.5 + 0.5 * sin(progress * PI + float(i) * 0.7))) * size_jitter
		_draw_fire_sprite(pos, i, size, alpha * 0.86, angle)


func _draw_fire_sprite(center: Vector2, index: int, size_px: float, alpha: float, spin: float) -> void:
	var tex := _get_texture(FIRE_PARTICLE_PATH)
	if tex == null:
		var a := clampf(alpha, 0.0, 1.0)
		draw_circle(center + Vector2(0.0, size_px * 0.14), size_px * 0.32, Color(1.0, 0.26, 0.02, a))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0.0, -size_px * 0.55),
			center + Vector2(size_px * 0.34, size_px * 0.18),
			center + Vector2(0.0, size_px * 0.45),
			center + Vector2(-size_px * 0.34, size_px * 0.18)
		]), Color(1.0, 0.52, 0.04, a))
		draw_circle(center + Vector2(0.0, size_px * 0.08), size_px * 0.16, Color(1.0, 0.90, 0.22, a))
		return
	var disappear_scale := smoothstep(0.04, 0.32, clampf(alpha, 0.0, 1.0))
	var draw_size := size_px * clampf(disappear_scale, 0.05, 1.0)
	var w := draw_size
	var h := draw_size
	var wobble := Vector2(cos(spin) * 1.5, sin(spin * 1.7) * 1.5)
	draw_texture_rect(tex, Rect2(center.x - w * 0.5 + wobble.x, center.y - h * 0.5 + wobble.y, w, h), false, Color.WHITE)


func _draw_float_texts() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	for entry in _float_texts:
		var timer := float(entry.get("timer", 0.0))
		if timer < 0.0:
			continue
		var duration := maxf(0.01, float(entry.get("duration", 0.9)))
		var p := clampf(timer / duration, 0.0, 1.0)
		var alpha := 1.0 - smoothstep(0.68, 1.0, p)
		var pop := 1.0 + sin(clampf(p / 0.36, 0.0, 1.0) * PI) * 0.22
		var color: Color = entry.get("color", Color.WHITE)
		color.a *= alpha
		var size_px := int(round(float(entry.get("size", 16.0)) * pop))
		var y := float(entry.get("y", 0.0)) - p * 24.0
		var center := Vector2(float(entry.get("x", 0.0)), y)
		var text := TranslationServer.translate(str(entry.get("text", "")))
		draw_string(font, center + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_CENTER, 96.0, size_px, Color(0.18, 0.08, 0.05, 0.75 * alpha))
		draw_string(font, center, text, HORIZONTAL_ALIGNMENT_CENTER, 96.0, size_px, color)


func _team_pos(index: int) -> Vector2:
	return [Vector2(78.0, 265.0), Vector2(78.0, 392.0), Vector2(78.0, 520.0)][clampi(index, 0, 2)]


func _enemy_pos(index: int) -> Vector2:
	return [Vector2(300.0, 250.0), Vector2(300.0, 385.0), Vector2(300.0, 520.0)][clampi(index, 0, 2)]


func _tone_color(tone: String) -> Color:
	match tone:
		"heal":
			return Color(0.42, 0.95, 0.55)
		"speed":
			return Color(0.25, 0.86, 0.92)
		"guard":
			return Color(0.28, 0.70, 1.0)
		"bulwark":
			return Color(0.76, 0.52, 0.26)
		"siphon":
			return Color(0.70, 0.24, 0.90)
		"chain":
			return Color(0.35, 0.65, 1.0)
		"fire":
			return Color(1.0, 0.34, 0.12)
		_:
			return Color(0.62, 0.88, 0.28)


func _get_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_texture_cache[path] = tex
	return tex

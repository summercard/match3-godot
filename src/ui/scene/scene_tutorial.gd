# scene_tutorial.gd - 新手引导场景
class_name SceneTutorial
extends Control

signal tutorial_completed()

const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const MonsterIdleAnimatorScript = preload("res://src/ui/components/monster_idle_animator.gd")
const ROUND_FONT: Font = preload("res://assets/fonts/noto-cjk/NotoSansCJK-Regular.ttc")

const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0
const BOARD_COLS := 8
const BOARD_ROWS := 6
const BOARD_RECT := Rect2(21.0, 318.0, 333.0, 235.0)
const CELL_SIZE := 41.0
const HEADER_RECT := Rect2(57.0, 14.0, 260.0, 72.0)
const PROMPT_RECT := Rect2(20.0, 498.0, 335.0, 124.0)
const SKIP_RECT := Rect2(18.0, 620.0, 108.0, 40.0)
const NEXT_RECT := Rect2(206.0, 601.0, 160.0, 62.0)
const TARGET_RECT := Rect2(252.0, 374.0, 104.0, 140.0)

const TUTORIAL_ASSETS := {
	"bg": "res://assets/images/maps/backgrounds/battle_bg_forest_ruins.png",
	"header": "res://assets/images/ui/bars/battle_prepare_new_ui_prepare_header.png",
	"prompt": "res://assets/images/ui/panels/result_refresh_ui_panel_large.png",
	"prompt_dark": "res://assets/images/ui/panels/battle_prepare_new_ui_mechanic_panel.png",
	"next_button": "res://assets/images/ui/buttons/battle_flow_new_ui_btn_gold.png",
	"skip_button": "res://assets/images/ui/buttons/battle_flow_new_ui_btn_blue.png",
	"highlight": "res://assets/images/effects/battle_fx_selected_cell.png",
	"arrow": "res://assets/images/ui/buttons/stage_icon_next_arrow.png",
	"target_card": "res://assets/images/ui/cards/result_refresh_ui_reward_card.png",
	"board_frame": "res://assets/images/ui/misc/battle_ui_board_frame.png",
	"board_cell": "res://assets/images/ui/misc/battle_ui_board_cell.png",
	"team_card_fire": "res://assets/images/ui/cards/battle_prepare_new_ui_team_card_fire.png",
	"team_card_grass": "res://assets/images/ui/cards/battle_prepare_new_ui_team_card_grass.png",
	"team_card_water": "res://assets/images/ui/cards/battle_prepare_new_ui_team_card_water.png",
	"enemy_card": "res://assets/images/ui/cards/battle_prepare_new_ui_enemy_card.png",
	"sparkles": "res://assets/images/effects/battle_flow_new_fx_sparkles.png",
	"leaf_cluster": "res://assets/images/effects/battle_prepare_new_fx_leaf_cluster_a.png",
	"leaf_single": "res://assets/images/effects/battle_prepare_new_fx_leaf_single_b.png",
	"hp_green": "res://assets/images/ui/bars/battle_ui_hp_bar_green.png",
	"gem_fire": "res://assets/images/ui/gems/battle_gem_fire.png",
	"gem_water": "res://assets/images/ui/gems/battle_gem_water.png",
	"gem_grass": "res://assets/images/ui/gems/battle_gem_grass.png",
	"gem_thunder": "res://assets/images/ui/gems/battle_gem_thunder.png",
	"gem_light": "res://assets/images/ui/gems/battle_gem_light.png",
	"capture_ball": "res://assets/images/ui/icons/stage_icon_capture_ball.png",
}

const C := {
	"white": Color(1.0, 1.0, 1.0),
	"muted": Color(0.66, 0.72, 0.83),
	"gold": Color(1.0, 0.78, 0.18),
	"blue": Color(0.34, 0.72, 1.0),
	"green": Color(0.58, 1.0, 0.35),
	"red": Color(1.0, 0.26, 0.18),
	"ink": Color(0.10, 0.08, 0.05),
	"shadow": Color(0.0, 0.0, 0.0, 0.62),
}

const STEPS := [
	{
		"title": "欢迎来到萌灵消消",
		"body": ["拖动宝石、击败精灵，", "把可爱的萌灵收为伙伴。"],
		"focus": "overview",
		"hint": "先熟悉战斗画面",
	},
	{
		"title": "拖动宝石",
		"body": ["拖动宝石，使 3 个相同宝石连成一线吧！"],
		"focus": "match",
		"hint": "示例：横向拖动水宝石",
	},
	{
		"title": "击败野生精灵",
		"body": ["消除对应能量会给伙伴充能，", "技能会带来输出、守护或控场。"],
		"focus": "enemy",
		"hint": "观察伙伴技能条",
	},
	{
		"title": "创造捕捉窗口",
		"body": ["把目标压到低血或先压制它，", "会提高捕捉窗口稳定度。"],
		"focus": "capture",
		"hint": "留意战斗底部的捕捉窗口",
	},
	{
		"title": "组建你的队伍",
		"body": ["在精灵编队中放入至少 1 只精灵，", "再去挑战更强关卡。"],
		"focus": "team",
		"hint": "准备好后开始冒险",
	},
]

var _current_step := 0
var _opacity := 0.0
var _anim_time := 0.0
var _step_time := 0.0
var _tutorial_ready := false
var _texture_cache: Dictionary = {}
var _idle_start_frames: Dictionary = {}

static var instance: SceneTutorial


func _ready() -> void:
	instance = self
	mouse_filter = Control.MOUSE_FILTER_STOP
	_connect_authored_hit_areas()


func init(data: Dictionary = {}) -> void:
	_opacity = 0.0
	_step_time = 0.0
	_tutorial_ready = false
	var replay: bool = data.get("replay", false)
	var progress := _load_tutorial_progress()
	if progress.get("completed", false) and not replay:
		_current_step = 0
	else:
		# 保护：确保 _current_step 在有效范围内 [0, STEPS.size()-1]
		var max_valid_step: int = maxi(0, STEPS.size() - 1)
		_current_step = clampi(int(progress.get("currentStep", 0)), 0, max_valid_step)
	queue_redraw()


func _load_tutorial_progress() -> Dictionary:
	var save_manager := _get_autoload("SaveManager")
	if save_manager != null and save_manager.has_method("load_tutorial_progress"):
		return save_manager.load_tutorial_progress()
	return {"completed": false, "currentStep": 0}


func _save_tutorial_progress(step: int) -> void:
	var save_manager := _get_autoload("SaveManager")
	if save_manager != null and save_manager.has_method("save_tutorial_progress"):
		save_manager.save_tutorial_progress(step)


func _get_autoload(node_name: String) -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _gui_input(event: InputEvent) -> void:
	if not _tutorial_ready:
		return
	if event is InputEventScreenTouch and event.pressed:
		_on_tap(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(event.position)
		accept_event()


func _on_tap(point: Vector2) -> void:
	if SKIP_RECT.has_point(point):
		_complete_tutorial()
	elif NEXT_RECT.has_point(point):
		_next_step()


func _connect_authored_hit_areas() -> void:
	for path in ["HitAreas/SkipButton", "HitAreas/NextButton"]:
		var control := get_node_or_null(path) as Control
		if control == null or bool(control.get_meta("_authored_hit_area_bound", false)):
			continue
		control.gui_input.connect(_on_authored_hit_area_input.bind(control))
		control.set_meta("_authored_hit_area_bound", true)


func _on_authored_hit_area_input(event: InputEvent, control: Control) -> void:
	if not _tutorial_ready:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(_hit_area_event_to_scene_position(event.position, control))
		control.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_tap(_hit_area_event_to_scene_position(event.position, control))
		control.accept_event()


func _hit_area_event_to_scene_position(event_position: Vector2, control: Control) -> Vector2:
	var global_pos := control.get_global_transform_with_canvas() * event_position
	return get_global_transform_with_canvas().affine_inverse() * global_pos


func _next_step() -> void:
	_current_step += 1
	if _current_step >= STEPS.size():
		_complete_tutorial()
		return
	_opacity = 0.0
	_step_time = 0.0
	_tutorial_ready = false
	_save_tutorial_progress(_current_step)
	queue_redraw()


func _complete_tutorial() -> void:
	_save_tutorial_progress(STEPS.size())
	_opacity = 0.0
	_step_time = 0.0
	_tutorial_ready = false
	tutorial_completed.emit()


func _skip_tutorial() -> void:
	_complete_tutorial()


func _process(delta: float) -> void:
	_anim_time += delta
	_step_time += delta
	if _opacity < 1.0:
		_opacity = minf(1.0, _opacity + delta * 2.3)
		if _opacity >= 1.0:
			_tutorial_ready = true
	queue_redraw()


func _idle_texture(monster_id: String) -> Texture2D:
	if not _idle_start_frames.has(monster_id):
		_idle_start_frames[monster_id] = MonsterIdleAnimatorScript.random_start_frame(monster_id)
	return MonsterIdleAnimatorScript.texture_at_time(
		monster_id,
		_anim_time,
		"idle",
		int(_idle_start_frames[monster_id])
	)


func _draw() -> void:
	var a := _opacity
	if a <= 0.0:
		return
	_draw_battle_mock(a)
	draw_rect(Rect2(0.0, 0.0, DESIGN_WIDTH, DESIGN_HEIGHT), Color(0.0, 0.0, 0.0, 0.46 * a), true)
	_draw_ambient_fx(a)
	_draw_header(a)
	# 安全检查：确保 _current_step 在有效范围内
	var safe_step: int = clampi(_current_step, 0, maxi(0, STEPS.size() - 1))
	_draw_focus_overlay(str(STEPS[safe_step].get("focus", "")), a)
	_draw_prompt(a)
	_draw_controls(a)


func _draw_battle_mock(a: float) -> void:
	_draw_texture_cover(_tex("bg"), Rect2(0.0, 0.0, DESIGN_WIDTH, DESIGN_HEIGHT), a)
	draw_rect(Rect2(0.0, 0.0, DESIGN_WIDTH, DESIGN_HEIGHT), Color(0.0, 0.02, 0.06, 0.12 * a), true)
	_draw_enemy_row(a)
	_draw_team_row(a)
	_draw_board(a)


func _draw_enemy_row(a: float) -> void:
	var enemies := [
		{"id": "monster_boss_001", "hp": "1200", "element": "gem_grass", "rect": Rect2(44.0, 98.0, 78.0, 78.0)},
		{"id": "monster_004", "hp": "1500", "element": "gem_thunder", "rect": Rect2(148.0, 96.0, 82.0, 82.0)},
		{"id": "monster_006", "hp": "1100", "element": "gem_fire", "rect": Rect2(254.0, 99.0, 78.0, 78.0)},
	]
	for enemy: Dictionary in enemies:
		var rect: Rect2 = enemy["rect"]
		var bob := sin(_anim_time * 2.1 + rect.position.x * 0.03) * 2.4
		_draw_texture_fit(_tex("enemy_card"), Rect2(rect.position.x - 13.0, rect.position.y - 7.0, 104.0, 118.0), 0.54 * a)
		_draw_texture_contain(_tex(str(enemy["element"])), Rect2(rect.position.x - 14.0, 96.0 + bob, 26.0, 26.0), 0.84 * a)
		_draw_texture_contain(_idle_texture(str(enemy["id"])), _offset_rect(rect, Vector2(0.0, bob)), a)
		_draw_text(str(enemy["hp"]), rect.get_center().x, 188.0, C["white"], 15.0, true, 70.0, a)
		_draw_hp_bar(Rect2(rect.position.x - 7.0, 195.0, 92.0, 9.0), Color(0.92, 0.14, 0.12, a), 0.72)


func _draw_team_row(a: float) -> void:
	var team := [
		{"id": "monster_003", "hp": "1200/1200", "element": "gem_grass", "card": "team_card_grass", "rect": Rect2(39.0, 221.0, 92.0, 92.0)},
		{"id": "monster_002", "hp": "1300/1300", "element": "gem_water", "card": "team_card_water", "rect": Rect2(141.0, 221.0, 92.0, 92.0)},
		{"id": "monster_001", "hp": "1100/1100", "element": "gem_fire", "card": "team_card_fire", "rect": Rect2(244.0, 221.0, 92.0, 92.0)},
	]
	for member: Dictionary in team:
		var card: Rect2 = member["rect"]
		var bob := sin(_anim_time * 2.0 + card.position.x * 0.04) * 1.8
		var draw_card := _offset_rect(card, Vector2(0.0, bob))
		_draw_texture_fit(_tex(str(member["card"])), draw_card, 0.96 * a)
		_draw_texture_contain(_tex(str(member["element"])), Rect2(card.position.x + 8.0, card.position.y + 9.0 + bob, 24.0, 24.0), a)
		_draw_texture_contain(_idle_texture(str(member["id"])), Rect2(card.position.x + 13.0, card.position.y + 17.0 + bob, 66.0, 58.0), a)
		_draw_hp_bar(Rect2(card.position.x + 15.0, card.position.y + 76.0, 62.0, 8.0), Color(0.26, 0.82, 0.28, a), 1.0)
		_draw_text(str(member["hp"]), card.get_center().x, card.position.y + 84.0, C["white"], 9.0, true, 72.0, a)


func _draw_board(a: float) -> void:
	_draw_texture_fit(_tex("board_frame"), Rect2(12.0, 306.0, 351.0, 258.0), 0.78 * a)
	var gems: Array[String] = ["gem_water", "gem_grass", "gem_fire", "gem_water", "gem_light", "gem_grass", "gem_water", "gem_thunder"]
	for row in range(BOARD_ROWS):
		for col in range(BOARD_COLS):
			var cell := Rect2(BOARD_RECT.position.x + col * CELL_SIZE, BOARD_RECT.position.y + row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			_draw_texture_fit(_tex("board_cell"), cell.grow(-1.0), 0.88 * a)
			var key: String = gems[(row * 3 + col) % gems.size()]
			if row == 1 and col in [2, 3, 4]:
				key = "gem_water"
			_draw_texture_contain(_tex(key), cell.grow(-5.0), 0.82 * a)


func _draw_focus_overlay(focus: String, a: float) -> void:
	var pulse := 1.0 + sin(_anim_time * 5.0) * 0.045
	var hint_alpha := a * (0.78 + sin(_anim_time * 4.8) * 0.16)
	match focus:
		"overview":
			_draw_texture_contain(_idle_texture("monster_002"), Rect2(18.0, 390.0 + sin(_anim_time * 2.7) * 4.0, 110.0, 115.0), a)
			_draw_texture_fit(_tex("prompt_dark"), _intro_rect(Rect2(139.0, 332.0, 166.0, 50.0), Vector2(0.0, 18.0)), a)
			_draw_text("先看战斗布局", 222.0, 363.0, C["gold"], 18.0, true, 132.0, a)
		"match":
			var match_rect := Rect2(101.0, 354.0, 154.0, 52.0)
			_draw_texture_fit(_tex("highlight"), _scale_rect(match_rect.grow(8.0), pulse), hint_alpha)
			_draw_texture_contain(_tex("arrow"), Rect2(248.0 + sin(_anim_time * 3.7) * 8.0, 356.0, 54.0, 54.0), a)
			_draw_texture_contain(_tex("arrow"), Rect2(151.0 + sin(_anim_time * 3.7) * 8.0, 408.0, 42.0, 42.0), 0.74 * a)
			_draw_target_card(a, "目标", "消除 3 个", "gem_water")
		"enemy":
			_draw_texture_fit(_tex("highlight"), _scale_rect(Rect2(30.0, 91.0, 312.0, 121.0), pulse), hint_alpha)
			_draw_texture_fit(_tex("arrow"), Rect2(150.0, 245.0 + sin(_anim_time * 3.2) * 5.0, 86.0, 40.0), a)
			_draw_texture_fit(_tex("prompt_dark"), _intro_rect(Rect2(107.0, 210.0, 160.0, 48.0), Vector2(0.0, 16.0)), a)
			_draw_text("攻击敌方血条", 187.0, 240.0, C["gold"], 17.0, true, 130.0, a)
		"capture":
			_draw_texture_fit(_tex("highlight"), _scale_rect(Rect2(244.0, 375.0, 117.0, 135.0), pulse), hint_alpha)
			_draw_texture_contain(_tex("capture_ball"), Rect2(281.0, 401.0 + sin(_anim_time * 4.2) * 3.0, 58.0, 58.0), a)
			_draw_target_card(a, "收服", "捕获球 +1", "capture_ball")
		"team":
			_draw_texture_fit(_tex("highlight"), _scale_rect(Rect2(29.0, 214.0, 318.0, 111.0), pulse), hint_alpha)
			_draw_texture_fit(_tex("prompt_dark"), _intro_rect(Rect2(112.0, 337.0, 150.0, 48.0), Vector2(0.0, 16.0)), a)
			_draw_text("这里是我方队伍", 187.0, 367.0, C["gold"], 16.0, true, 126.0, a)


func _draw_target_card(a: float, title: String, body: String, icon_key: String) -> void:
	var rect := _intro_rect(TARGET_RECT, Vector2(22.0, 0.0))
	_draw_texture_fit(_tex("target_card"), rect, a)
	_draw_text(title, rect.get_center().x, rect.position.y + 31.0, C["gold"], 14.0, true, 60.0, a)
	_draw_texture_contain(_tex(icon_key), Rect2(rect.position.x + 22.0, rect.position.y + 45.0 + sin(_anim_time * 4.0) * 2.0, 40.0, 40.0), a)
	_draw_text(body, rect.get_center().x, rect.position.y + 101.0, C["white"], 12.0, true, 70.0, a)


func _draw_header(a: float) -> void:
	var rect := _intro_rect(_offset_rect(HEADER_RECT, Vector2(0.0, sin(_anim_time * 2.2) * 1.6)), Vector2(0.0, -16.0))
	_draw_texture_fit(_tex("header"), rect, a)
	_draw_texture_fit(_tex("sparkles"), Rect2(rect.position.x + 28.0, rect.position.y - 4.0, 176.0, 19.0), 0.45 * a * (0.65 + sin(_anim_time * 3.0) * 0.25))
	_draw_text("教程", HEADER_RECT.get_center().x + 26.0, HEADER_RECT.position.y + 40.0, C["white"], 25.0, true, 150.0, a)


func _draw_prompt(a: float) -> void:
	var safe_step: int = clampi(_current_step, 0, maxi(0, STEPS.size() - 1))
	var step: Dictionary = STEPS[safe_step]
	var rect := _intro_rect(PROMPT_RECT, Vector2(0.0, 26.0))
	_draw_texture_fit(_tex("prompt"), rect, a)
	_draw_texture_contain(_tex("leaf_cluster"), Rect2(rect.position.x + 13.0, rect.position.y - 9.0, 43.0, 33.0), 0.86 * a)
	_draw_texture_contain(_tex("leaf_single"), Rect2(rect.position.x + rect.size.x - 42.0, rect.position.y + 10.0 + sin(_anim_time * 2.5) * 2.0, 24.0, 24.0), 0.72 * a)
	_draw_text(str(step.get("title", "")), rect.get_center().x, rect.position.y + 37.0, C["ink"], 18.0, true, 260.0, a)
	var lines: Array = step.get("body", [])
	var y := rect.position.y + 63.0
	for line in lines:
		_draw_text(str(line), rect.get_center().x, y, C["ink"], 14.0, false, 286.0, a)
		y += 20.0
	_draw_text(str(step.get("hint", "")), rect.get_center().x, rect.position.y + 96.0, Color(0.10, 0.36, 0.62, a), 12.0, true, 240.0, a)
	_draw_step_dots(a)


func _draw_step_dots(a: float) -> void:
	var total := STEPS.size()
	var start_x := PROMPT_RECT.get_center().x - (total - 1) * 14.0
	for i in range(total):
		var center := Vector2(start_x + i * 28.0, PROMPT_RECT.position.y + 116.0)
		var active := i == _current_step
		draw_circle(center, 5.4 if active else 4.2, Color(1.0, 0.79, 0.23, a) if active else Color(0.42, 0.49, 0.57, 0.72 * a))
		if active:
			draw_arc(center, 7.4, 0.0, TAU, 20, Color(1.0, 0.98, 0.72, 0.82 * a), 1.2)


func _draw_controls(a: float) -> void:
	var skip_rect := _intro_rect(SKIP_RECT, Vector2(-18.0, 0.0))
	var next_rect := _scale_rect(_intro_rect(NEXT_RECT, Vector2(24.0, 0.0)), 1.0 + sin(_anim_time * 4.0) * 0.018)
	_draw_texture_fit(_tex("skip_button"), skip_rect, a)
	_draw_text("跳过", SKIP_RECT.get_center().x, SKIP_RECT.position.y + 25.0, C["white"], 15.0, true, 68.0, a)
	_draw_texture_fit(_tex("next_button"), next_rect, a)
	var is_last := _current_step == STEPS.size() - 1
	_draw_text("开始冒险" if is_last else "下一步", NEXT_RECT.get_center().x, NEXT_RECT.position.y + 37.0, C["white"], 18.0, true, 114.0, a)


func _draw_ambient_fx(a: float) -> void:
	_draw_texture_fit(_tex("sparkles"), Rect2(20.0, 82.0, 180.0, 20.0), 0.16 * a * (0.7 + sin(_anim_time * 1.8) * 0.25))
	_draw_texture_contain(_tex("leaf_single"), Rect2(302.0 + sin(_anim_time * 1.7) * 6.0, 68.0 + sin(_anim_time * 2.1) * 4.0, 26.0, 26.0), 0.55 * a)
	_draw_texture_contain(_tex("leaf_cluster"), Rect2(34.0, 208.0 + sin(_anim_time * 1.5) * 3.0, 40.0, 31.0), 0.42 * a)


func _draw_hp_bar(rect: Rect2, color: Color, percent: float) -> void:
	draw_rect(rect, Color(0.04, 0.02, 0.02, color.a), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(percent, 0.0, 1.0), rect.size.y)), color, true)
	draw_rect(rect, Color(0.05, 0.04, 0.04, color.a), false, 1.0)


func _tex(key: String) -> Texture2D:
	return _get_texture(str(TUTORIAL_ASSETS.get(key, "")))


func _get_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path] as Texture2D


func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, opacity))


func _draw_texture_contain(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_pos := rect.position + (rect.size - draw_size) * 0.5
	draw_texture_rect(tex, Rect2(draw_pos, draw_size), false, Color(1.0, 1.0, 1.0, opacity))


func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		draw_rect(rect, Color(0.04, 0.07, 0.15), true)
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var source_size := rect.size / scale
	var source_pos := (tex_size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size), Color(1.0, 1.0, 1.0, opacity))


func _scale_rect(rect: Rect2, scale: float) -> Rect2:
	var center := rect.get_center()
	var size := rect.size * scale
	return Rect2(center - size * 0.5, size)


func _intro_rect(rect: Rect2, from_offset: Vector2) -> Rect2:
	var t := clampf(_step_time * 4.0, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	return _offset_rect(rect, from_offset * (1.0 - eased))


func _offset_rect(rect: Rect2, offset: Vector2) -> Rect2:
	return Rect2(rect.position + offset, rect.size)


func _draw_text(text: String, x: float, y: float, color: Color, font_size: float, _bold: bool = false, width: float = 160.0, opacity: float = 1.0) -> void:
	text = TranslationServer.translate(text)
	var col := Color(color.r, color.g, color.b, color.a * opacity)
	var outline := Color(C["shadow"].r, C["shadow"].g, C["shadow"].b, 0.58 * opacity)
	var font := ROUND_FONT
	var pos := Vector2(x - width / 2.0, y)
	var size := int(font_size)
	var needs_outline := _bold and not _is_dark_text(color)
	if needs_outline:
		draw_string(font, pos + Vector2(0.0, 1.4), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


func _is_dark_text(color: Color) -> bool:
	return color.r < 0.25 and color.g < 0.25 and color.b < 0.25


func destroy() -> void:
	_tutorial_ready = false

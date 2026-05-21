# scene_tutorial.gd - 新手引导场景
class_name SceneTutorial
extends Control

signal tutorial_completed()

const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")

const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0
const BOARD_COLS := 8
const BOARD_ROWS := 6
const BOARD_RECT := Rect2(21.0, 318.0, 333.0, 235.0)
const CELL_SIZE := 41.0
const HEADER_RECT := Rect2(72.0, 18.0, 232.0, 62.0)
const PROMPT_RECT := Rect2(20.0, 510.0, 335.0, 108.0)
const SKIP_RECT := Rect2(18.0, 616.0, 92.0, 44.0)
const NEXT_RECT := Rect2(214.0, 607.0, 148.0, 54.0)
const TARGET_RECT := Rect2(274.0, 389.0, 82.0, 112.0)

const TUTORIAL_ASSETS := {
	"bg": "res://assets/images/battle/battle_bg_forest_ruins.png",
	"header": "res://assets/images/tutorial/ui_tutorial_header.png",
	"prompt": "res://assets/images/tutorial/ui_tutorial_prompt_panel.png",
	"prompt_dark": "res://assets/images/tutorial/ui_tutorial_prompt_dark.png",
	"next_button": "res://assets/images/tutorial/ui_next_button.png",
	"skip_button": "res://assets/images/tutorial/ui_skip_button.png",
	"highlight": "res://assets/images/tutorial/fx_highlight_frame.png",
	"arrow": "res://assets/images/tutorial/fx_swipe_arrow.png",
	"dotted_path": "res://assets/images/tutorial/fx_dotted_path.png",
	"hand": "res://assets/images/tutorial/icon_hand_pointer.png",
	"target_card": "res://assets/images/tutorial/ui_target_card.png",
	"dot_active": "res://assets/images/tutorial/ui_step_dot_active.png",
	"dot_inactive": "res://assets/images/tutorial/ui_step_dot_inactive.png",
	"panel_dark": "res://assets/images/battle/ui/ui_panel_dark_large.png",
	"team_card": "res://assets/images/battle_prepare/ui_team_card.png",
	"enemy_card": "res://assets/images/battle_prepare/ui_enemy_card.png",
	"hp_green": "res://assets/images/battle/ui/ui_hp_bar_green.png",
	"gem_fire": "res://assets/images/battle/gems/gem_fire.png",
	"gem_water": "res://assets/images/battle/gems/gem_water.png",
	"gem_grass": "res://assets/images/battle/gems/gem_grass.png",
	"gem_thunder": "res://assets/images/battle/gems/gem_thunder.png",
	"gem_light": "res://assets/images/battle/gems/gem_light.png",
	"capture_ball": "res://assets/images/stage/icon_capture_ball.png",
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
		"body": ["拖动宝石、击败怪物，", "把可爱的萌灵收为伙伴。"],
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
		"title": "击败野生怪物",
		"body": ["每次消除都会造成伤害，", "把敌方血量打空即可获胜。"],
		"focus": "enemy",
		"hint": "观察敌方血条",
	},
	{
		"title": "收服你的伙伴",
		"body": ["胜利后可尝试收服怪物，", "捕获球能提高成功率。"],
		"focus": "capture",
		"hint": "胜利奖励会进入背包",
	},
	{
		"title": "组建你的队伍",
		"body": ["在精灵编队中放入至少 1 只怪物，", "再去挑战更强关卡。"],
		"focus": "team",
		"hint": "准备好后开始冒险",
	},
]

var _current_step := 0
var _opacity := 0.0
var _tutorial_ready := false
var _texture_cache: Dictionary = {}

static var instance: SceneTutorial


func _ready() -> void:
	instance = self
	mouse_filter = Control.MOUSE_FILTER_STOP


func init(data: Dictionary = {}) -> void:
	_opacity = 0.0
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


func _next_step() -> void:
	_current_step += 1
	if _current_step >= STEPS.size():
		_complete_tutorial()
		return
	_opacity = 0.0
	_tutorial_ready = false
	_save_tutorial_progress(_current_step)
	queue_redraw()


func _complete_tutorial() -> void:
	_save_tutorial_progress(STEPS.size())
	_opacity = 0.0
	_tutorial_ready = false
	tutorial_completed.emit()


func _process(delta: float) -> void:
	if _opacity < 1.0:
		_opacity = minf(1.0, _opacity + delta * 2.3)
		if _opacity >= 1.0:
			_tutorial_ready = true
	queue_redraw()


func _draw() -> void:
	var a := _opacity
	if a <= 0.0:
		return
	_draw_battle_mock(a)
	draw_rect(Rect2(0.0, 0.0, DESIGN_WIDTH, DESIGN_HEIGHT), Color(0.0, 0.0, 0.0, 0.46 * a), true)
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
		_draw_texture_contain(_tex(str(enemy["element"])), Rect2(enemy["rect"].position.x - 14.0, 96.0, 26.0, 26.0), 0.84 * a)
		_draw_texture_contain(_get_texture(MonsterArtDBScript.get_battle_portrait_path(str(enemy["id"]))), enemy["rect"], a)
		_draw_text(str(enemy["hp"]), enemy["rect"].get_center().x, 188.0, C["white"], 15.0, true, 70.0, a)
		_draw_hp_bar(Rect2(enemy["rect"].position.x - 7.0, 195.0, 92.0, 9.0), Color(0.92, 0.14, 0.12, a), 0.72)


func _draw_team_row(a: float) -> void:
	var team := [
		{"id": "monster_003", "hp": "1200/1200", "element": "gem_grass", "rect": Rect2(39.0, 221.0, 92.0, 92.0)},
		{"id": "monster_002", "hp": "1300/1300", "element": "gem_water", "rect": Rect2(141.0, 221.0, 92.0, 92.0)},
		{"id": "monster_001", "hp": "1100/1100", "element": "gem_fire", "rect": Rect2(244.0, 221.0, 92.0, 92.0)},
	]
	for member: Dictionary in team:
		var card: Rect2 = member["rect"]
		_draw_texture_fit(_tex("team_card"), card, 0.9 * a)
		_draw_texture_contain(_tex(str(member["element"])), Rect2(card.position.x + 8.0, card.position.y + 9.0, 24.0, 24.0), a)
		_draw_texture_contain(_get_texture(MonsterArtDBScript.get_battle_portrait_path(str(member["id"]))), Rect2(card.position.x + 13.0, card.position.y + 18.0, 66.0, 58.0), a)
		_draw_hp_bar(Rect2(card.position.x + 15.0, card.position.y + 76.0, 62.0, 8.0), Color(0.26, 0.82, 0.28, a), 1.0)
		_draw_text(str(member["hp"]), card.get_center().x, card.position.y + 84.0, C["white"], 9.0, true, 72.0, a)


func _draw_board(a: float) -> void:
	_draw_texture_fit(_tex("panel_dark"), Rect2(13.0, 306.0, 349.0, 257.0), 0.92 * a)
	var gems: Array[String] = ["gem_water", "gem_grass", "gem_fire", "gem_water", "gem_light", "gem_grass", "gem_water", "gem_thunder"]
	for row in range(BOARD_ROWS):
		for col in range(BOARD_COLS):
			var cell := Rect2(BOARD_RECT.position.x + col * CELL_SIZE, BOARD_RECT.position.y + row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(cell.grow(-1.0), Color(0.02, 0.06, 0.11, 0.62 * a), true)
			draw_rect(cell.grow(-1.0), Color(0.12, 0.19, 0.30, 0.40 * a), false, 1.0)
			var key: String = gems[(row * 3 + col) % gems.size()]
			if row == 1 and col in [2, 3, 4]:
				key = "gem_water"
			_draw_texture_contain(_tex(key), cell.grow(-5.0), 0.82 * a)


func _draw_focus_overlay(focus: String, a: float) -> void:
	match focus:
		"overview":
			_draw_texture_contain(_get_texture(MonsterArtDBScript.get_battle_portrait_path("monster_002")), Rect2(18.0, 392.0, 110.0, 115.0), a)
			_draw_texture_fit(_tex("prompt_dark"), Rect2(139.0, 332.0, 166.0, 50.0), a)
			_draw_text("先看战斗布局", 222.0, 363.0, C["gold"], 18.0, true, 132.0, a)
		"match":
			var match_rect := Rect2(101.0, 354.0, 154.0, 52.0)
			_draw_texture_fit(_tex("highlight"), match_rect.grow(9.0), a)
			_draw_texture_fit(_tex("arrow"), Rect2(250.0, 354.0, 100.0, 46.0), a)
			_draw_texture_fit(_tex("dotted_path"), Rect2(118.0, 416.0, 106.0, 70.0), a)
			_draw_texture_contain(_tex("hand"), Rect2(220.0, 383.0, 82.0, 96.0), a)
			_draw_target_card(a, "目标", "消除 3 个", "gem_water")
		"enemy":
			_draw_texture_fit(_tex("highlight"), Rect2(30.0, 91.0, 312.0, 121.0), a)
			_draw_texture_fit(_tex("arrow"), Rect2(150.0, 245.0, 86.0, 40.0), a)
			_draw_texture_fit(_tex("prompt_dark"), Rect2(107.0, 210.0, 160.0, 48.0), a)
			_draw_text("攻击敌方血条", 187.0, 240.0, C["gold"], 17.0, true, 130.0, a)
		"capture":
			_draw_texture_fit(_tex("highlight"), Rect2(244.0, 375.0, 117.0, 135.0), a)
			_draw_texture_contain(_tex("capture_ball"), Rect2(281.0, 401.0, 58.0, 58.0), a)
			_draw_target_card(a, "收服", "捕获球 +1", "capture_ball")
		"team":
			_draw_texture_fit(_tex("highlight"), Rect2(29.0, 214.0, 318.0, 111.0), a)
			_draw_texture_fit(_tex("prompt_dark"), Rect2(112.0, 337.0, 150.0, 48.0), a)
			_draw_text("这里是我方队伍", 187.0, 367.0, C["gold"], 16.0, true, 126.0, a)


func _draw_target_card(a: float, title: String, body: String, icon_key: String) -> void:
	_draw_texture_fit(_tex("target_card"), TARGET_RECT, a)
	_draw_text(title, TARGET_RECT.get_center().x, TARGET_RECT.position.y + 31.0, C["gold"], 14.0, true, 60.0, a)
	_draw_texture_contain(_tex(icon_key), Rect2(TARGET_RECT.position.x + 22.0, TARGET_RECT.position.y + 45.0, 40.0, 40.0), a)
	_draw_text(body, TARGET_RECT.get_center().x, TARGET_RECT.position.y + 101.0, C["white"], 12.0, true, 70.0, a)


func _draw_header(a: float) -> void:
	_draw_texture_fit(_tex("header"), HEADER_RECT, a)
	_draw_text("教程", HEADER_RECT.get_center().x, HEADER_RECT.position.y + 40.0, C["white"], 27.0, true, 150.0, a)


func _draw_prompt(a: float) -> void:
	var safe_step: int = clampi(_current_step, 0, maxi(0, STEPS.size() - 1))
	var step: Dictionary = STEPS[safe_step]
	_draw_texture_fit(_tex("prompt"), PROMPT_RECT, a)
	_draw_text(str(step.get("title", "")), PROMPT_RECT.get_center().x, PROMPT_RECT.position.y + 37.0, C["ink"], 17.0, true, 260.0, a)
	var lines: Array = step.get("body", [])
	var y := PROMPT_RECT.position.y + 62.0
	for line in lines:
		_draw_text(str(line), PROMPT_RECT.get_center().x, y, C["ink"], 13.0, false, 282.0, a)
		y += 20.0
	_draw_text(str(step.get("hint", "")), PROMPT_RECT.get_center().x, PROMPT_RECT.position.y + 94.0, Color(0.10, 0.36, 0.62, a), 11.0, true, 240.0, a)
	_draw_step_dots(a)


func _draw_step_dots(a: float) -> void:
	var total := STEPS.size()
	var start_x := PROMPT_RECT.get_center().x - (total - 1) * 14.0
	for i in range(total):
		var rect := Rect2(start_x + i * 28.0 - 9.0, PROMPT_RECT.position.y + 86.0, 18.0, 18.0)
		_draw_texture_contain(_tex("dot_active" if i == _current_step else "dot_inactive"), rect, a)


func _draw_controls(a: float) -> void:
	_draw_texture_fit(_tex("skip_button"), SKIP_RECT, a)
	_draw_text("跳过", SKIP_RECT.get_center().x, SKIP_RECT.position.y + 27.0, C["white"], 17.0, true, 62.0, a)
	_draw_texture_fit(_tex("next_button"), NEXT_RECT, a)
	var is_last := _current_step == STEPS.size() - 1
	_draw_text("开始冒险" if is_last else "下一步", NEXT_RECT.get_center().x - (5.0 if is_last else 12.0), NEXT_RECT.position.y + 34.0, C["white"], 18.0, true, 94.0, a)


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


func _draw_text(text: String, x: float, y: float, color: Color, font_size: float, _bold: bool = false, width: float = 160.0, opacity: float = 1.0) -> void:
	var col := Color(color.r, color.g, color.b, color.a * opacity)
	var shadow := Color(C["shadow"].r, C["shadow"].g, C["shadow"].b, C["shadow"].a * opacity)
	draw_string(ThemeDB.fallback_font, Vector2(x - width / 2.0 + 1.0, y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, int(font_size), shadow)
	draw_string(ThemeDB.fallback_font, Vector2(x - width / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, int(font_size), col)


func destroy() -> void:
	_tutorial_ready = false

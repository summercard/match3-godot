@tool
class_name SceneTeamGui
extends "res://src/ui/scene/scene_team.gd"

const GUI_ASSETS := {
	"bg": "res://assets/images/team_new/bg_team_hall.png",
	"currency": "res://assets/images/main/lobby_refresh/ui_currency_capsule_v3.png",
	"gold": "res://assets/images/main/lobby_refresh/icon_gold_coin_v3.png",
	"diamond": "res://assets/images/main/lobby_refresh/icon_diamond_gem_v3.png",
	"heart": "res://assets/images/ranch/fx_social_heart.png",
	"plus": "res://assets/images/main/lobby_refresh/icon_plus_v3.png",
	"empty_plus": "res://assets/images/team_new/ui_empty_pedestal_plus.png",
	"leader_badge": "res://assets/images/team_new/ui_leader_badge.png",
	"pedestal_label": "res://assets/images/team_new/ui_pedestal_label.png",
	"power_panel": "res://assets/images/ranch/ui_care_roster_panel.png",
	"roster_panel": "res://assets/images/ranch/ui_care_roster_panel.png",
	"roster_card": "res://assets/images/ranch/ui_roster_card_ranch.png",
	"roster_card_selected": "res://assets/images/ranch/ui_roster_card_ranch_selected.png",
	"check": "res://assets/images/ranch/icon_check_badge.png",
	"level_badge": "res://assets/images/ranch/ui_level_badge.png",
	"nav_panel": "res://assets/images/ranch/ui_pet_farm_nav_panel.png",
	"nav_selected": "res://assets/images/ranch/ui_pet_farm_nav_selected.png",
	"nav_home": "res://assets/images/team_new/icon_nav_home.png",
	"nav_pets": "res://assets/images/team_new/icon_nav_pets.png",
	"nav_battle": "res://assets/images/team_new/icon_nav_battle.png",
	"nav_shop": "res://assets/images/team_new/icon_nav_shop.png",
	"nav_menu": "res://assets/images/ranch/icon_menu_tab.png",
	"page_prev": "res://assets/images/ranch/ui_btn_previous_round.png",
	"page_next": "res://assets/images/ranch/ui_btn_next_round.png",
	"hp": "res://assets/images/ranch/fx_social_heart.png",
	"atk": "res://assets/images/team_new/icon_nav_battle.png",
	"def": "res://assets/images/main/lobby_refresh/icon_level_shield_v3.png",
	"spd": "res://assets/images/ranch/icon_exp_badge.png",
}

const GUI_ROSTER_PAGE_SIZE := 6
const TEAM_SLOT_RECTS := {
	"member1": Rect2(43.0, 188.0, 78.0, 160.0),
	"leader": Rect2(128.0, 145.0, 119.0, 210.0),
	"member2": Rect2(254.0, 188.0, 78.0, 160.0),
}
const TEAM_SLOT_CENTERS := {
	"member1": Vector2(82.0, 305.0),
	"leader": Vector2(187.5, 294.0),
	"member2": Vector2(293.0, 305.0),
}
const ROSTER_RECTS := [
	Rect2(31.0, 505.0, 53.0, 80.0),
	Rect2(88.0, 505.0, 53.0, 80.0),
	Rect2(145.0, 505.0, 53.0, 80.0),
	Rect2(202.0, 505.0, 53.0, 80.0),
	Rect2(259.0, 505.0, 53.0, 80.0),
	Rect2(316.0, 505.0, 53.0, 80.0),
]
const NAV_ITEMS := [
	{"id": "home", "label": "主页", "icon": "nav_home", "scene": "main"},
	{"id": "pets", "label": "农场", "icon": "nav_pets", "scene": "ranch"},
	{"id": "battle", "label": "战场", "icon": "nav_battle", "scene": "stage_select"},
	{"id": "shop", "label": "商店", "icon": "nav_shop", "scene": "shop"},
	{"id": "menu", "label": "菜单", "icon": "nav_menu", "scene": "settings"},
]

var _nav_rects: Array[Rect2] = []
var _pressed_fx_rect := Rect2()
var _pressed_fx_timer := 0.0
var _pressed_fx_duration := 0.20


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_update_slots_layout()


func _process(delta: float) -> void:
	super._process(delta)
	if _pressed_fx_timer > 0.0:
		_pressed_fx_timer = maxf(0.0, _pressed_fx_timer - delta)
		queue_redraw()


func _update_slots_layout() -> void:
	_slots = [
		{"key": "member1", "rect": TEAM_SLOT_RECTS["member1"], "label": "左位"},
		{"key": "leader", "rect": TEAM_SLOT_RECTS["leader"], "label": "队长"},
		{"key": "member2", "rect": TEAM_SLOT_RECTS["member2"], "label": "右位"},
	]
	_roster_prev_btn = Rect2(70.0, 585.0, 38.0, 38.0)
	_roster_next_btn = Rect2(267.0, 585.0, 38.0, 38.0)
	_nav_rects.clear()
	for i in NAV_ITEMS.size():
		_nav_rects.append(Rect2(19.0 + i * 68.0, 612.0, 65.0, 46.0))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_gui_tap(event.position)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_gui_tap(event.position)
		accept_event()


func _on_gui_tap(pos: Vector2) -> void:
	for i in _nav_rects.size():
		if _nav_rects[i].has_point(pos):
			_flash_button(_nav_rects[i])
			_save_team()
			_change_scene_after_feedback(str(NAV_ITEMS[i]["scene"]))
			return
	if _roster_prev_btn.has_point(pos):
		_flash_button(_roster_prev_btn)
		_turn_roster_page(-1)
		return
	if _roster_next_btn.has_point(pos):
		_flash_button(_roster_next_btn)
		_turn_roster_page(1)
		return
	for slot: Dictionary in _slots:
		var rect: Rect2 = slot["rect"]
		if rect.has_point(pos):
			_flash_button(rect)
			_handle_slot_tap(str(slot["key"]))
			_save_team()
			return
	var idx := _get_monster_index_at_pos(pos)
	var visible := _get_display_monsters()
	if idx >= 0 and idx < visible.size():
		_flash_button(ROSTER_RECTS[idx - _roster_page * GUI_ROSTER_PAGE_SIZE])
		_assign_to_slot(_get_instance_id(visible[idx]))
		_save_team()


func _flash_button(rect: Rect2) -> void:
	_pressed_fx_rect = rect
	_pressed_fx_timer = _pressed_fx_duration
	queue_redraw()


func _change_scene_after_feedback(scene_name: String) -> void:
	await get_tree().create_timer(0.12).timeout
	_change_to_scene(scene_name)


func _get_roster_page_count() -> int:
	return maxi(1, ceili(float(_get_display_monsters().size()) / float(GUI_ROSTER_PAGE_SIZE)))


func _clamp_roster_page() -> void:
	_roster_page = clampi(_roster_page, 0, _get_roster_page_count() - 1)


func _get_monster_index_at_pos(pos: Vector2) -> int:
	for i in ROSTER_RECTS.size():
		if ROSTER_RECTS[i].has_point(pos):
			return _roster_page * GUI_ROSTER_PAGE_SIZE + i
	return -1


func _draw() -> void:
	var font := ThemeDB.fallback_font
	_clamp_roster_page()
	_draw_texture_cover(_gui_tex("bg"), Rect2(0.0, 0.0, DESIGN_W, DESIGN_H))
	_draw_texture_gradient_vignette()
	_draw_currency_bar(font)
	_draw_team_slots(font)
	_draw_power_panel(font)
	_draw_pet_roster(font)
	_draw_bottom_nav(font)
	_draw_press_feedback()


func _draw_texture_gradient_vignette() -> void:
	draw_rect(Rect2(0.0, 0.0, DESIGN_W, 120.0), Color(0.18, 0.07, 0.02, 0.18), true)
	draw_rect(Rect2(0.0, 592.0, DESIGN_W, 75.0), Color(0.12, 0.05, 0.01, 0.22), true)


func _draw_currency_bar(font: Font) -> void:
	var player := _load_player_data()
	var chips := [
		{"icon": "gold", "value": _format_number(int(player.get("gold", 0))), "rect": Rect2(15.0, 13.0, 112.0, 38.0)},
		{"icon": "diamond", "value": _format_number(int(player.get("diamond", player.get("gems", 0)))), "rect": Rect2(132.0, 13.0, 112.0, 38.0)},
		{"icon": "heart", "value": "%s Full" % str(player.get("stamina", player.get("energy", 5))), "rect": Rect2(249.0, 13.0, 112.0, 38.0)},
	]
	for chip in chips:
		var rect: Rect2 = chip["rect"]
		_draw_texture_fit(_gui_tex("currency"), rect)
		_draw_texture_contain(_gui_tex(str(chip["icon"])), Rect2(rect.position.x + 8.0, rect.position.y + 5.0, 28.0, 28.0))
		_draw_text(font, str(chip["value"]), rect.position.x + 70.0, rect.position.y + 26.0, Color(0.32, 0.18, 0.06), 14.0)
		_draw_texture_contain(_gui_tex("plus"), Rect2(rect.end.x - 26.0, rect.position.y + 6.0, 24.0, 24.0))


func _draw_team_slots(font: Font) -> void:
	for slot: Dictionary in _slots:
		var key := str(slot["key"])
		var center: Vector2 = TEAM_SLOT_CENTERS[key]
		var value: Variant = _team.get(key, null)
		var instance_id := "" if value == null else str(value)
		if instance_id.is_empty():
			var pulse := 0.90 + sin(_time_acc * 3.1 + center.x) * 0.06
			var size := 78.0 * pulse
			_draw_texture_contain(_gui_tex("empty_plus"), Rect2(center.x - size * 0.5, 238.0 - size * 0.5, size, size), 0.92)
		else:
			var portrait_size := 118.0 if key == "leader" else 92.0
			var y := 236.0 if key == "leader" else 250.0
			_draw_monster_portrait(instance_id, Rect2(center.x - portrait_size * 0.5, y - portrait_size * 0.5, portrait_size, portrait_size))
			if key == "leader":
				_draw_texture_contain(_gui_tex("leader_badge"), Rect2(center.x - 53.0, 151.0, 106.0, 49.0))
				_draw_text(font, "Leader", center.x, 185.0, Color.WHITE, 16.0)
		var label_rect := Rect2(center.x - 38.0, 341.0 if key == "leader" else 349.0, 76.0, 28.0)
		var label_draw_rect := _feedback_rect(label_rect)
		_draw_texture_fit(_gui_tex("pedestal_label"), label_draw_rect)
		_draw_text(font, str(slot["label"]), label_draw_rect.get_center().x, label_draw_rect.position.y + 20.0, Color(1.0, 0.88, 0.66), 13.0)
		if _selected_slot == key:
			_draw_rounded_rect_outline(slot["rect"].position.x, slot["rect"].position.y, slot["rect"].size.x, slot["rect"].size.y, 16.0, Color(1.0, 0.82, 0.26, 0.95), 3.0)


func _draw_power_panel(font: Font) -> void:
	var rect := Rect2(14.0, 391.0, 347.0, 66.0)
	_draw_texture_fit(_gui_tex("power_panel"), rect)
	_draw_text(font, "Team Power", 82.0, 414.0, Color(0.38, 0.21, 0.07), 14.0)
	_draw_texture_contain(_gui_tex("nav_battle"), Rect2(32.0, 419.0, 29.0, 29.0))
	_draw_text(font, _format_number(_calc_team_power()), 97.0, 443.0, Color(0.92, 0.32, 0.08), 25.0)
	var totals := _calc_team_totals()
	var stats := [
		{"icon": "hp", "value": totals["hp"], "x": 181.0},
		{"icon": "atk", "value": totals["atk"], "x": 237.0},
		{"icon": "def", "value": totals["def"], "x": 291.0},
		{"icon": "spd", "value": totals["spd"], "x": 340.0},
	]
	for stat in stats:
		_draw_texture_contain(_gui_tex(str(stat["icon"])), Rect2(float(stat["x"]) - 37.0, 421.0, 23.0, 23.0))
		_draw_text(font, _format_number(int(stat["value"])), float(stat["x"]), 441.0, Color(0.33, 0.19, 0.07), 12.0)


func _draw_pet_roster(font: Font) -> void:
	var panel := Rect2(14.0, 469.0, 347.0, 128.0)
	_draw_texture_fit(_gui_tex("roster_panel"), panel)
	_draw_text(font, "Choose Pets", DESIGN_W / 2.0, 497.0, Color(0.38, 0.21, 0.07), 20.0)
	_draw_text(font, "选择精灵加入队伍", DESIGN_W / 2.0, 516.0, Color(0.48, 0.27, 0.09), 10.0)
	var visible := _get_display_monsters()
	var start := _roster_page * GUI_ROSTER_PAGE_SIZE
	for i in ROSTER_RECTS.size():
		var index := start + i
		var rect: Rect2 = ROSTER_RECTS[i]
		var draw_rect := _feedback_rect(rect)
		if index >= visible.size():
			_draw_texture_fit(_gui_tex("roster_card"), draw_rect, 0.42)
			continue
		var instance: Dictionary = visible[index]
		var instance_id := _get_instance_id(instance)
		var monster_id := _get_monster_id(instance)
		var in_team := _team.values().has(instance_id)
		_draw_texture_fit(_gui_tex("roster_card_selected" if in_team else "roster_card"), draw_rect)
		_draw_monster_portrait(monster_id, Rect2(draw_rect.position.x + 6.0, draw_rect.position.y + 7.0, draw_rect.size.x - 12.0, 43.0))
		if in_team:
			_draw_texture_contain(_gui_tex("check"), Rect2(draw_rect.end.x - 19.0, draw_rect.end.y - 25.0, 20.0, 20.0))
		var lvl := _get_real_level(instance_id)
		_draw_text(font, "Lv.%d" % lvl, draw_rect.get_center().x, draw_rect.position.y + 71.0, Color(0.43, 0.24, 0.07), 10.0)
	if visible.is_empty():
		_draw_text(font, "暂无可编队精灵", DESIGN_W / 2.0, 556.0, Color(0.50, 0.31, 0.14), 14.0)
	_draw_roster_page_controls_gui(font)


func _draw_roster_page_controls_gui(font: Font) -> void:
	var page_count := _get_roster_page_count()
	if page_count <= 1:
		return
	_draw_texture_contain(_gui_tex("page_prev"), _roster_prev_btn, 1.0 if _roster_page > 0 else 0.42)
	_draw_texture_contain(_gui_tex("page_next"), _roster_next_btn, 1.0 if _roster_page < page_count - 1 else 0.42)
	_draw_text(font, "%d / %d" % [_roster_page + 1, page_count], DESIGN_W / 2.0, 610.0, Color(0.46, 0.26, 0.08), 12.0)


func _draw_bottom_nav(font: Font) -> void:
	_draw_texture_fit(_gui_tex("nav_panel"), Rect2(7.0, 602.0, 361.0, 61.0))
	for i in NAV_ITEMS.size():
		var rect: Rect2 = _nav_rects[i]
		var draw_rect := _feedback_rect(rect)
		var item: Dictionary = NAV_ITEMS[i]
		var selected := str(item["id"]) == "battle"
		if selected:
			_draw_texture_fit(_gui_tex("nav_selected"), Rect2(draw_rect.position.x + 4.0, draw_rect.position.y - 7.0, draw_rect.size.x - 8.0, draw_rect.size.y + 9.0))
		_draw_texture_contain(_gui_tex(str(item["icon"])), Rect2(draw_rect.position.x + 17.0, draw_rect.position.y - 2.0, 31.0, 31.0))
		_draw_text(font, str(item["label"]), draw_rect.get_center().x, draw_rect.position.y + 42.0, Color(0.32, 0.18, 0.06), 12.0)


func _draw_press_feedback() -> void:
	if _pressed_fx_timer <= 0.0:
		return
	var t := 1.0 - _pressed_fx_timer / _pressed_fx_duration
	var alpha := (1.0 - t) * 0.40
	var center := _pressed_fx_rect.get_center()
	var radius := maxf(_pressed_fx_rect.size.x, _pressed_fx_rect.size.y) * (0.52 + t * 0.30)
	draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.78, 0.24, alpha), 2.0)
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + t * 0.35
		var dir := Vector2.from_angle(angle)
		draw_line(center + dir * (radius + 3.0), center + dir * (radius + 9.0 + t * 8.0), Color(1.0, 0.82, 0.28, alpha), 1.2)


func _feedback_rect(rect: Rect2) -> Rect2:
	if _pressed_fx_timer <= 0.0 or rect != _pressed_fx_rect:
		return rect
	var t := 1.0 - _pressed_fx_timer / _pressed_fx_duration
	var scale := 0.92 + sin(t * PI) * 0.11
	var size := rect.size * scale
	return Rect2(rect.get_center() - size * 0.5, size)


func _calc_team_totals() -> Dictionary:
	var totals := {"hp": 0, "atk": 0, "def": 0, "spd": 0}
	for key in ["leader", "member1", "member2"]:
		var value: Variant = _team.get(key, null)
		var ref_id := "" if value == null else str(value)
		if ref_id.is_empty():
			continue
		var stats := _calc_stats(ref_id, _get_real_level(ref_id))
		for stat_key in totals.keys():
			totals[stat_key] += int(stats.get(stat_key, 0))
	return totals


func _load_player_data() -> Dictionary:
	if _storage != null and _storage.has_method("load_player"):
		return _storage.load_player()
	return {"gold": 0, "diamond": 0, "stamina": 5}


func _format_number(value: int) -> String:
	var text := str(value)
	var out := ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out


func _gui_tex(key: String) -> Texture2D:
	return _get_texture(str(GUI_ASSETS.get(key, "")))

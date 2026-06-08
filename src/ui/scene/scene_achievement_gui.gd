@tool
class_name SceneAchievementGui
extends "res://src/ui/scene/scene_achievement.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")

const GUI_ASSETS := {
	"bg": "res://assets/images/main/lobby_refresh/main_lobby_bg_day_v3.png",
	"currency": "res://assets/images/main/lobby_refresh/ui_currency_capsule_v3.png",
	"gold": "res://assets/images/main/lobby_refresh/icon_gold_coin_v3.png",
	"diamond": "res://assets/images/main/lobby_refresh/icon_diamond_gem_v3.png",
	"heart": "res://assets/images/ranch/fx_social_heart.png",
	"plus": "res://assets/images/main/lobby_refresh/icon_plus_v3.png",
	"back": "res://assets/images/ranch/ui_btn_previous_round.png",
	"title": "res://assets/images/shop/concept/image2/ui_shop_title_plaque_image2.png",
	"panel": "res://assets/images/inventory_new/ui_inventory_panel.png",
	"card": "res://assets/images/inventory_new/ui_inventory_detail_panel.png",
	"tab_active": "res://assets/images/inventory_new/ui_inventory_tab_active.png",
	"tab_normal": "res://assets/images/inventory_new/ui_inventory_tab_normal.png",
	"claim": "res://assets/images/inventory_new/ui_inventory_use_button.png",
	"disabled": "res://assets/images/inventory_new/ui_inventory_tab_normal.png",
	"reward_slot": "res://assets/images/inventory_new/ui_inventory_slot.png",
	"trophy": "res://assets/images/common_nav/icon_nav_achievement.png",
	"battle": "res://assets/images/common_nav/icon_nav_battle.png",
	"collect": "res://assets/images/common_nav/icon_nav_album.png",
	"numeric": "res://assets/images/items_new/icon_gold_chest.png",
	"continuous": "res://assets/images/common_nav/icon_nav_signin.png",
	"star": "res://assets/images/album/icon_star_lit.png",
	"check": "res://assets/images/ranch/icon_check_badge.png",
	"nav_panel": "res://assets/images/ranch/ui_pet_farm_nav_panel.png",
	"nav_selected": "res://assets/images/ranch/ui_pet_farm_nav_selected.png",
	"nav_home": "res://assets/images/common_nav/icon_nav_home.png",
	"nav_album": "res://assets/images/common_nav/icon_nav_album.png",
	"nav_achievement": "res://assets/images/common_nav/icon_nav_achievement.png",
	"nav_settings": "res://assets/images/common_nav/icon_nav_settings.png",
	"nav_signin": "res://assets/images/common_nav/icon_nav_signin.png",
}

const CATEGORY_LABELS := [
	{"id": "all", "label": "全部", "icon": "star"},
	{"id": "battle", "label": "战斗", "icon": "battle"},
	{"id": "collect", "label": "收集", "icon": "collect"},
	{"id": "numeric", "label": "财富", "icon": "numeric"},
	{"id": "continuous", "label": "连续", "icon": "continuous"},
]
const NAV_ITEMS := [
	{"id": "home", "label": "主页", "icon": "nav_home", "scene": "main"},
	{"id": "album", "label": "图鉴", "icon": "nav_album", "scene": "album"},
	{"id": "achievement", "label": "成就", "icon": "nav_achievement", "scene": "achievement"},
	{"id": "settings", "label": "设置", "icon": "nav_settings", "scene": "settings"},
	{"id": "signin", "label": "签到", "icon": "nav_signin", "scene": "sign_in"},
]
const ACH_TEXT := {
	"ach_first_battle": {"name": "初战启程", "desc": "完成第一场战斗"},
	"ach_battle_10": {"name": "身经百战", "desc": "累计完成 10 场战斗"},
	"ach_battle_50": {"name": "百战老兵", "desc": "累计完成 50 场战斗"},
	"ach_first_win": {"name": "胜利号角", "desc": "首次击败敌人"},
	"ach_first_clear": {"name": "初次通关", "desc": "通过第一关"},
	"ach_clear_10": {"name": "关卡猎手", "desc": "通关 10 个关卡"},
	"ach_first_capture": {"name": "初次收服", "desc": "收服第一只精灵"},
	"ach_capture_5": {"name": "精灵收藏家", "desc": "收服 5 只不同精灵"},
	"ach_capture_10": {"name": "精灵大师", "desc": "扩充你的精灵图鉴"},
	"ach_first_evolve": {"name": "进化之光", "desc": "首次进化精灵"},
	"ach_evolve_5": {"name": "进化狂热", "desc": "累计进化 5 只精灵"},
	"ach_gold_10000": {"name": "小有资产", "desc": "累计获得 10000 金币"},
	"ach_gold_100000": {"name": "百万富翁", "desc": "累计获得 100000 金币"},
	"ach_damage_1000": {"name": "锋芒初露", "desc": "累计造成 1000 点伤害"},
	"ach_damage_10000": {"name": "毁灭之力", "desc": "累计造成 10000 点伤害"},
	"ach_signin_7": {"name": "一周坚持", "desc": "连续签到 7 天"},
	"ach_signin_30": {"name": "签到达人", "desc": "累计签到 30 天"},
}

const TOP_CHIPS := [
	{"icon": "gold", "key": "gold", "rect": Rect2(14.0, 8.0, 105.0, 36.0)},
	{"icon": "diamond", "key": "gems", "rect": Rect2(129.0, 8.0, 105.0, 36.0)},
	{"icon": "heart", "key": "stamina", "rect": Rect2(244.0, 8.0, 116.0, 36.0)},
]
const TITLE_RECT := Rect2(83.0, 52.0, 210.0, 58.0)
const BACK_BUTTON_RECT := Rect2(15.0, 59.0, 45.0, 45.0)
const SUMMARY_PANEL := Rect2(15.0, 111.0, 345.0, 93.0)
const TAB_RECTS := [
	Rect2(16.0, 211.0, 64.0, 39.0),
	Rect2(84.0, 211.0, 64.0, 39.0),
	Rect2(152.0, 211.0, 64.0, 39.0),
	Rect2(220.0, 211.0, 64.0, 39.0),
	Rect2(288.0, 211.0, 64.0, 39.0),
]
const ACH_LIST_TOP := 259.0
const ACH_LIST_BOTTOM := 596.0
const ACH_CARD_RECT := Rect2(18.0, 0.0, 339.0, 86.0)
const ACH_CARD_GAP := 9.0

var _button_rects: Array[Dictionary] = []
var _press_rect := Rect2()
var _press_timer := 0.0
var _press_duration := 0.20
var _enter_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll_offset = 0.0
	_init_data()
	set_process(true)
	_rebuild_button_rects()


func init(data: Dictionary = {}) -> void:
	_current_category = data.get("category", _current_category)
	_scroll_offset = 0.0
	_init_data()
	_rebuild_button_rects()
	set_process(true)


func _process(delta: float) -> void:
	_enter_t += delta
	if _press_timer > 0.0:
		_press_timer = maxf(0.0, _press_timer - delta)
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_text = ""
	queue_redraw()


func _rebuild_button_rects() -> void:
	_button_rects.clear()
	_button_rects.append({"id": "back", "rect": BACK_BUTTON_RECT, "profile": "icon"})
	for i in TAB_RECTS.size():
		_button_rects.append({"id": "tab_%s" % str(CATEGORY_LABELS[i]["id"]), "rect": TAB_RECTS[i], "profile": "nav"})
	for i in NAV_ITEMS.size():
		_button_rects.append({"id": "nav_%s" % str(NAV_ITEMS[i]["id"]), "rect": Rect2(19.0 + i * 68.0, 612.0, 65.0, 46.0), "profile": "nav"})


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
			_last_drag_y = event.position.y
		else:
			if abs(event.position.y - _drag_start_y) < 8.0:
				_on_gui_tap(event.position)
			_dragging = false
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
			_last_drag_y = event.position.y
		else:
			if abs(event.position.y - _drag_start_y) < 8.0:
				_on_gui_tap(event.position)
			_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_scroll_by_delta(event.position.y - _last_drag_y)
		_last_drag_y = event.position.y
		accept_event()
	elif event is InputEventScreenDrag:
		_scroll_by_delta(event.relative.y)
		accept_event()


func _on_gui_tap(point: Vector2) -> void:
	if BACK_BUTTON_RECT.has_point(point):
		_play_feedback(BACK_BUTTON_RECT)
		_go_scene_after_feedback("main")
		return
	for i in CATEGORY_LABELS.size():
		if TAB_RECTS[i].has_point(point):
			_play_feedback(TAB_RECTS[i])
			_filter_by_category(str(CATEGORY_LABELS[i]["id"]))
			return
	for i in NAV_ITEMS.size():
		var rect := Rect2(19.0 + i * 68.0, 612.0, 65.0, 46.0)
		if rect.has_point(point):
			_play_feedback(rect)
			_go_scene_after_feedback(str(NAV_ITEMS[i]["scene"]))
			return
	if point.y < ACH_LIST_TOP or point.y > ACH_LIST_BOTTOM:
		return
	var index := int((point.y - ACH_LIST_TOP + _scroll_offset) / (ACH_CARD_RECT.size.y + ACH_CARD_GAP))
	if index < 0 or index >= _filtered_achievements.size():
		return
	var ach: Dictionary = _filtered_achievements[index]
	var card_rect := _get_gui_card_rect(index)
	if not card_rect.has_point(point):
		return
	if bool(ach.get("unlocked", false)) and not bool(ach.get("claimed", false)) and _get_gui_claim_rect(card_rect).has_point(point):
		_play_feedback(_get_gui_claim_rect(card_rect))
		_claim_achievement(ach)
	elif bool(ach.get("unlocked", false)):
		_play_feedback(card_rect)
		_show_toast("%s 已完成" % _ach_name(ach))
	else:
		_play_feedback(card_rect)
		_show_toast("目标进度 %d/%d" % [int(ach.get("progress", 0)), int(ach.get("target", 1))])


func _go_scene_after_feedback(scene_name: String) -> void:
	await get_tree().create_timer(0.12).timeout
	_switch_scene(scene_name)


func _switch_scene(scene_name: String) -> void:
	var manager := get_node_or_null("/root/SceneManager")
	if manager and manager.has_method("switch_scene"):
		manager.switch_scene(scene_name, {}, "slide")
	else:
		var game := get_node_or_null("/root/GameManager")
		if game and game.has_method("switch_scene"):
			game.switch_scene(scene_name, {}, "slide")


func _play_feedback(rect: Rect2) -> void:
	_press_rect = rect
	_press_timer = _press_duration
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_texture_cover(_gui_tex("bg"), Rect2(0.0, 0.0, DESIGN_W, DESIGN_H))
	draw_rect(Rect2(0.0, 0.0, DESIGN_W, DESIGN_H), Color(1.0, 0.86, 0.48, 0.09), true)
	_draw_top_currency(font)
	_draw_gui_header(font)
	_draw_summary_panel(font)
	_draw_tabs_gui(font)
	_draw_achievement_list(font)
	_draw_bottom_nav(font)
	_draw_toast_gui(font)
	_draw_press_feedback()


func _draw_top_currency(font: Font) -> void:
	var player := _load_player_data()
	for chip in TOP_CHIPS:
		var rect: Rect2 = chip["rect"]
		_draw_texture_fit(_gui_tex("currency"), rect)
		_draw_texture_contain(_gui_tex(str(chip["icon"])), Rect2(rect.position.x + 7.0, rect.position.y + 5.0, 26.0, 26.0))
		var value := str(player.get(str(chip["key"]), 0))
		if str(chip["key"]) == "stamina":
			value = "%s Full" % str(player.get("stamina", player.get("energy", 5)))
		else:
			value = _format_number(int(value))
		_draw_center_text(font, value, Vector2(rect.position.x + rect.size.x * 0.56, rect.position.y + 24.0), Color(0.32, 0.18, 0.06), 13.0, rect.size.x * 0.58)
		_draw_texture_contain(_gui_tex("plus"), Rect2(rect.end.x - 24.0, rect.position.y + 6.0, 22.0, 22.0))


func _draw_gui_header(font: Font) -> void:
	_draw_texture_fit(_gui_tex("back"), BACK_BUTTON_RECT)
	_draw_texture_fit(_gui_tex("title"), TITLE_RECT)
	_draw_center_text(font, "成就殿堂", TITLE_RECT.get_center() + Vector2(0.0, 14.0), Color.WHITE, 25.0, 150.0)


func _draw_summary_panel(font: Font) -> void:
	_draw_texture_fit(_gui_tex("panel"), SUMMARY_PANEL)
	_draw_texture_contain(_gui_tex("trophy"), Rect2(29.0, 124.0, 76.0, 68.0))
	var unlocked := _all_achievements.filter(func(a): return a.get("unlocked", false)).size()
	var total := maxi(1, _all_achievements.size())
	var claimed := _claimed_ids.size()
	var ratio := float(unlocked) / float(total)
	_draw_text_left_gui(font, "冒险成就", Vector2(116.0, 137.0), Color(0.40, 0.22, 0.07), 18.0, 120.0)
	_draw_text_left_gui(font, "已完成 %d/%d  已领取 %d" % [unlocked, total, claimed], Vector2(116.0, 159.0), Color(0.56, 0.32, 0.11), 12.0, 180.0)
	_draw_progress_bar_gui(Rect2(116.0, 176.0, 200.0, 16.0), ratio, "%d%%" % int(round(ratio * 100.0)))
	_draw_texture_contain(_gui_tex("star"), Rect2(315.0, 133.0, 30.0, 30.0))


func _draw_tabs_gui(font: Font) -> void:
	for i in CATEGORY_LABELS.size():
		var item: Dictionary = CATEGORY_LABELS[i]
		var selected := str(item["id"]) == _current_category
		var rect: Rect2 = TAB_RECTS[i]
		var draw_rect := _feedback_rect(rect)
		_draw_texture_fit(_gui_tex("tab_active" if selected else "tab_normal"), draw_rect)
		_draw_texture_contain(_gui_tex(str(item["icon"])), Rect2(draw_rect.position.x + 6.0, draw_rect.position.y + 7.0, 22.0, 22.0))
		_draw_center_text(font, str(item["label"]), Vector2(draw_rect.position.x + 43.0, draw_rect.position.y + 25.0), Color.WHITE if selected else Color(0.43, 0.24, 0.07), 11.0, 40.0)


func _draw_achievement_list(font: Font) -> void:
	if _filtered_achievements.is_empty():
		_draw_center_text(font, "暂无成就", Vector2(DESIGN_W / 2.0, 427.0), Color(0.50, 0.31, 0.14), 16.0, 160.0)
		return
	for i in _filtered_achievements.size():
		var rect: Rect2 = _get_gui_card_rect(i)
		if rect.position.y < ACH_LIST_TOP or rect.end.y > ACH_LIST_BOTTOM:
			continue
		_draw_achievement_card_gui(font, _filtered_achievements[i], rect)
	_draw_scrollbar_gui()


func _draw_achievement_card_gui(font: Font, ach: Dictionary, rect: Rect2) -> void:
	var draw_rect := _feedback_rect(rect)
	var unlocked := bool(ach.get("unlocked", false))
	var claimed := bool(ach.get("claimed", false))
	_draw_texture_fit(_gui_tex("card"), draw_rect, 1.0 if unlocked else 0.82)
	var icon_key := _category_icon(str(ach.get("category", "")))
	_draw_texture_contain(_gui_tex(icon_key), Rect2(draw_rect.position.x + 12.0, draw_rect.position.y + 14.0, 52.0, 52.0), 1.0 if unlocked else 0.42)
	if not unlocked:
		draw_rect(draw_rect.grow(-6.0), Color(0.22, 0.18, 0.12, 0.20), true)
	_draw_text_left_gui(font, _ach_name(ach), Vector2(draw_rect.position.x + 74.0, draw_rect.position.y + 24.0), Color(0.40, 0.22, 0.07), 16.0, 150.0)
	_draw_text_left_gui(font, _ach_desc(ach), Vector2(draw_rect.position.x + 74.0, draw_rect.position.y + 43.0), Color(0.58, 0.34, 0.12), 10.5, 172.0)
	var target := maxf(1.0, float(ach.get("target", 1)))
	var progress := clampf(float(ach.get("progress", 0)) / target, 0.0, 1.0)
	_draw_progress_bar_gui(Rect2(draw_rect.position.x + 74.0, draw_rect.position.y + 61.0, 154.0, 13.0), progress, "%d/%d" % [int(ach.get("progress", 0)), int(ach.get("target", 1))])
	_draw_reward_gui(font, ach, Rect2(draw_rect.position.x + 232.0, draw_rect.position.y + 16.0, 37.0, 37.0), unlocked)
	if claimed:
		_draw_texture_contain(_gui_tex("check"), Rect2(draw_rect.end.x - 56.0, draw_rect.position.y + 45.0, 28.0, 28.0))
		_draw_center_text(font, "已领取", Vector2(draw_rect.end.x - 42.0, draw_rect.position.y + 72.0), Color(0.38, 0.64, 0.12), 10.0, 54.0)
	elif unlocked:
		var claim_rect := _feedback_rect(_get_gui_claim_rect(rect))
		_draw_texture_fit(_gui_tex("claim"), claim_rect)
		_draw_center_text(font, "领取", claim_rect.get_center() + Vector2(0.0, 7.0), Color.WHITE, 15.0, claim_rect.size.x)
	else:
		var disabled_rect := _get_gui_claim_rect(rect)
		_draw_texture_fit(_gui_tex("disabled"), disabled_rect, 0.86)
		_draw_center_text(font, "未达成", disabled_rect.get_center() + Vector2(0.0, 6.0), Color(0.56, 0.34, 0.13), 11.0, disabled_rect.size.x)


func _draw_reward_gui(font: Font, ach: Dictionary, rect: Rect2, active: bool) -> void:
	_draw_texture_fit(_gui_tex("reward_slot"), rect, 1.0 if active else 0.62)
	var reward: Dictionary = ach.get("reward", {})
	var amount := int(reward.get("gold", 0))
	_draw_texture_contain(_gui_tex("gold"), Rect2(rect.position.x + 7.0, rect.position.y + 4.0, 24.0, 24.0), 1.0 if active else 0.58)
	_draw_center_text(font, "x%d" % amount, Vector2(rect.get_center().x, rect.end.y + 8.0), Color(0.42, 0.24, 0.08), 9.0, 42.0)


func _draw_progress_bar_gui(rect: Rect2, ratio: float, label: String) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	_draw_round_rect(rect, 6.0, Color(0.79, 0.61, 0.34, 0.35))
	_draw_round_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), 6.0, Color(0.38, 0.82, 0.18, 0.95))
	_draw_center_text(ThemeDB.fallback_font, label, rect.get_center() + Vector2(0.0, 4.0), Color.WHITE, 9.0, rect.size.x)


func _draw_bottom_nav(font: Font) -> void:
	_draw_texture_fit(_gui_tex("nav_panel"), Rect2(7.0, 602.0, 361.0, 61.0))
	for i in NAV_ITEMS.size():
		var item: Dictionary = NAV_ITEMS[i]
		var rect := Rect2(19.0 + i * 68.0, 612.0, 65.0, 46.0)
		var draw_rect := _feedback_rect(rect)
		if str(item["id"]) == "achievement":
			_draw_texture_fit(_gui_tex("nav_selected"), Rect2(draw_rect.position.x + 4.0, draw_rect.position.y - 7.0, draw_rect.size.x - 8.0, draw_rect.size.y + 9.0))
		_draw_texture_contain(_gui_tex(str(item["icon"])), Rect2(draw_rect.position.x + 17.0, draw_rect.position.y - 2.0, 31.0, 31.0))
		_draw_center_text(font, str(item["label"]), Vector2(draw_rect.get_center().x, draw_rect.position.y + 42.0), Color(0.32, 0.18, 0.06), 12.0, 54.0)


func _draw_scrollbar_gui() -> void:
	var max_offset := _get_gui_max_scroll_offset()
	if max_offset <= 0.0:
		return
	var track := Rect2(360.0, ACH_LIST_TOP + 4.0, 4.0, ACH_LIST_BOTTOM - ACH_LIST_TOP - 8.0)
	draw_rect(track, Color(0.64, 0.42, 0.18, 0.18), true)
	var thumb_h := maxf(42.0, track.size.y * (track.size.y / (track.size.y + max_offset)))
	var thumb_y := track.position.y + (track.size.y - thumb_h) * (_scroll_offset / max_offset)
	draw_rect(Rect2(track.position.x, thumb_y, track.size.x, thumb_h), Color(0.86, 0.56, 0.18, 0.78), true)


func _draw_toast_gui(font: Font) -> void:
	if _toast_text.is_empty() or _toast_timer <= 0.0:
		return
	var alpha := minf(_toast_timer / 0.35, 1.0)
	var rect := Rect2(58.0, 565.0, 260.0, 34.0)
	_draw_texture_fit(_gui_tex("tab_active"), rect, alpha)
	_draw_center_text(font, _toast_text, rect.get_center() + Vector2(0.0, 6.0), Color(1.0, 1.0, 1.0, alpha), 13.0, 224.0)


func _draw_press_feedback() -> void:
	if _press_timer <= 0.0 or _press_rect.size == Vector2.ZERO:
		return
	var t := 1.0 - _press_timer / _press_duration
	var center := _press_rect.get_center()
	var radius := maxf(_press_rect.size.x, _press_rect.size.y) * (0.50 + t * 0.28)
	var alpha := (1.0 - t) * 0.35
	draw_arc(center, radius, 0.0, TAU, 36, Color(1.0, 0.78, 0.24, alpha), 2.0)
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + t * 0.4
		var dir := Vector2.from_angle(angle)
		draw_line(center + dir * (radius + 3.0), center + dir * (radius + 8.0 + t * 7.0), Color(1.0, 0.82, 0.30, alpha), 1.2)


func _feedback_rect(rect: Rect2) -> Rect2:
	if _press_timer <= 0.0 or rect != _press_rect:
		return rect
	var t := 1.0 - _press_timer / _press_duration
	var scale := 0.92 + sin(t * PI) * 0.11
	var size := rect.size * scale
	return Rect2(rect.get_center() - size * 0.5, size)


func _show_toast(text: String) -> void:
	_toast_text = text
	_toast_timer = 1.55
	set_process(true)
	queue_redraw()


func _get_gui_card_rect(index: int) -> Rect2:
	return Rect2(ACH_CARD_RECT.position.x, ACH_LIST_TOP + index * (ACH_CARD_RECT.size.y + ACH_CARD_GAP) - _scroll_offset, ACH_CARD_RECT.size.x, ACH_CARD_RECT.size.y)


func _get_gui_claim_rect(card_rect: Rect2) -> Rect2:
	return Rect2(card_rect.position.x + 270.0, card_rect.position.y + 52.0, 60.0, 27.0)


func _get_gui_max_scroll_offset() -> float:
	var content_h := _filtered_achievements.size() * (ACH_CARD_RECT.size.y + ACH_CARD_GAP) - ACH_CARD_GAP
	return maxf(0.0, content_h - (ACH_LIST_BOTTOM - ACH_LIST_TOP))


func _get_max_scroll_offset() -> float:
	return _get_gui_max_scroll_offset()


func _filter_by_category(category: String) -> void:
	_current_category = category
	if category == "all":
		_filtered_achievements = _all_achievements.duplicate()
	else:
		_filtered_achievements = _all_achievements.filter(func(ach): return ach.get("category", "") == category)
	_scroll_offset = 0.0
	queue_redraw()


func _category_icon(category: String) -> String:
	match category:
		"battle":
			return "battle"
		"collect":
			return "collect"
		"numeric":
			return "numeric"
		"continuous":
			return "continuous"
		_:
			return "star"


func _ach_name(ach: Dictionary) -> String:
	return str(ACH_TEXT.get(str(ach.get("id", "")), {}).get("name", ach.get("name", "成就")))


func _ach_desc(ach: Dictionary) -> String:
	return str(ACH_TEXT.get(str(ach.get("id", "")), {}).get("desc", ach.get("desc", "")))


func _load_player_data() -> Dictionary:
	if _storage != null and _storage.has_method("load_player"):
		return _storage.load_player()
	return {"gold": 0, "gems": 0, "stamina": 5}


func _gui_tex(key: String) -> Texture2D:
	return _get_texture(str(GUI_ASSETS.get(key, "")))


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
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var draw_size := size * scale
	var pos := rect.position + (rect.size - draw_size) * 0.5
	draw_texture_rect(tex, Rect2(pos, draw_size), false, Color(1.0, 1.0, 1.0, opacity))


func _draw_texture_cover(tex: Texture2D, rect: Rect2) -> void:
	if tex == null:
		draw_rect(rect, Color(0.05, 0.08, 0.15), true)
		return
	var size := tex.get_size()
	var scale := maxf(rect.size.x / size.x, rect.size.y / size.y)
	var source_size := rect.size / scale
	var source_pos := (size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size))


func _draw_center_text(font: Font, text: String, center: Vector2, color: Color, size: float, width: float) -> void:
	var left := center.x - width * 0.5
	draw_string(font, Vector2(left + 1.0, center.y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, int(size), Color(0.22, 0.10, 0.02, 0.38))
	draw_string(font, Vector2(left, center.y), text, HORIZONTAL_ALIGNMENT_CENTER, width, int(size), color)


func _draw_text_left_gui(font: Font, text: String, pos: Vector2, color: Color, size: float, width: float) -> void:
	draw_string(font, Vector2(pos.x + 1.0, pos.y + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, width, int(size), Color(0.22, 0.10, 0.02, 0.28))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, int(size), color)


func _draw_round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2.0, rect.size.y), color, true)
	draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - r * 2.0), color, true)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(Vector2(rect.end.x - r, rect.position.y + r), r, color)
	draw_circle(Vector2(rect.position.x + r, rect.end.y - r), r, color)
	draw_circle(rect.end - Vector2(r, r), r, color)

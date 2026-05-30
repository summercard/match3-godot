# scene_achievement.gd - 成就系统场景
# 源文件: js/ui/sceneAchievement.js
class_name SceneAchievement
extends Control

const AchievementDB = preload("res://src/data/achievement_db.gd")

const DESIGN_W := 375.0
const DESIGN_H := 667.0
const BACK_RECT := Rect2(13.0, 14.0, 58.0, 58.0)
const HEADER_RECT := Rect2(96.0, 20.0, 205.0, 50.0)
const SUMMARY_RECT := Rect2(9.0, 84.0, 357.0, 104.0)
const TAB_Y := 198.0
const TAB_W := 67.0
const TAB_H := 42.0
const TAB_GAP := 5.0
const TAB_START_X := 8.0
const LIST_TOP := 248.0
const LIST_BOTTOM := 650.0
const CARD_X := 9.0
const CARD_W := 357.0
const CARD_H := 92.0
const CARD_GAP := 8.0

const ACHIEVEMENT_ASSETS := {
	"bg": "res://assets/images/achievement/bg_achievement.png",
	"back": "res://assets/images/achievement/ui_back_button.png",
	"header": "res://assets/images/achievement/ui_header_bar.png",
	"summary": "res://assets/images/achievement/ui_summary_panel.png",
	"trophy": "res://assets/images/achievement/icon_trophy.png",
	"tab_all": "res://assets/images/achievement/ui_tab_all.png",
	"tab_battle": "res://assets/images/achievement/ui_tab_battle.png",
	"tab_collect": "res://assets/images/achievement/ui_tab_collect.png",
	"tab_numeric": "res://assets/images/achievement/ui_tab_all.png",
	"tab_continuous": "res://assets/images/achievement/ui_tab_growth.png",
	"card": "res://assets/images/achievement/ui_card_frame.png",
	"ribbon": "res://assets/images/achievement/ui_title_ribbon.png",
	"progress_empty": "res://assets/images/achievement/ui_progress_empty.png",
	"progress_fill": "res://assets/images/achievement/ui_progress_fill.png",
	"claim": "res://assets/images/achievement/ui_btn_claim.png",
	"disabled": "res://assets/images/achievement/ui_btn_disabled.png",
	"stamp": "res://assets/images/achievement/ui_stamp_completed.png",
	"lock": "res://assets/images/achievement/icon_lock.png",
	"badge_star": "res://assets/images/achievement/badge_star.png",
	"badge_battle": "res://assets/images/achievement/badge_battle.png",
	"badge_collect": "res://assets/images/achievement/badge_collect.png",
	"badge_growth": "res://assets/images/achievement/badge_growth.png",
	"badge_locked": "res://assets/images/achievement/badge_locked.png",
	"reward_slot": "res://assets/images/inventory/ui_slot.png",
	"gold": "res://assets/images/main/icon_gold.png",
	"diamond": "res://assets/images/main/icon_diamond.png",
	"exp": "res://assets/images/stage/icon_exp_badge.png",
}

const C := {
	"white": Color(1.0, 1.0, 1.0),
	"muted": Color(0.66, 0.72, 0.83),
	"dim": Color(0.42, 0.48, 0.58),
	"gold": Color(1.0, 0.78, 0.18),
	"green": Color(0.62, 1.0, 0.36),
	"blue": Color(0.42, 0.78, 1.0),
	"shadow": Color(0.0, 0.0, 0.0, 0.58),
	"locked": Color(0.45, 0.48, 0.53, 0.72),
}

var _game: Node = null
var _storage: Node = null
var _all_achievements: Array = []
var _filtered_achievements: Array = []
var _current_category := "all"
var _claimed_ids: Array = []
var _toast_text := ""
var _toast_timer := 0.0
var _scroll_offset := 0.0
var _dragging := false
var _drag_start_y := 0.0
var _last_drag_y := 0.0
var _texture_cache: Dictionary = {}

const CATEGORIES := [
	{"id": "all", "label": "全部"},
	{"id": "battle", "label": "战斗"},
	{"id": "collect", "label": "收集"},
	{"id": "numeric", "label": "数值"},
	{"id": "continuous", "label": "连续"},
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_init_data()
	set_process(false)


func init(data: Dictionary = {}) -> void:
	_current_category = data.get("category", _current_category)
	_init_data()
	set_process(false)


func _init_data() -> void:
	_game = get_node_or_null("/root/GameManager")
	_storage = get_node_or_null("/root/SaveManager")
	if _storage == null and _game and _game.get("storage"):
		_storage = _game.storage
	var save_data: Dictionary = _storage.load_achievements() if _storage and _storage.has_method("load_achievements") else {}
	_claimed_ids = save_data.get("claimedIds", [])
	_all_achievements = _build_achievement_view_models(save_data)
	_filter_by_category(_current_category)
	queue_redraw()


func _build_achievement_view_models(save_data: Dictionary) -> Array:
	var unlocked_ids: Array = save_data.get("unlockedIds", [])
	var stats: Dictionary = save_data.get("stats", {}).duplicate(true)
	_apply_derived_stats(stats)

	var achievements: Array = []
	for ach: Dictionary in AchievementDB.ACHIEVEMENTS:
		var item: Dictionary = ach.duplicate(true)
		var progress_key := str(item.get("progressKey", ""))
		var progress := int(stats.get(progress_key, 0))
		var target := maxi(1, int(item.get("target", 1)))
		var unlocked := unlocked_ids.has(item.get("id", "")) or progress >= target
		item["progress"] = progress
		item["target"] = target
		item["unlocked"] = unlocked
		item["claimed"] = _claimed_ids.has(item.get("id", ""))
		achievements.append(item)
	return achievements


func _apply_derived_stats(stats: Dictionary) -> void:
	if not _storage:
		return
	if _storage.has_method("load_rewards"):
		var rewards: Dictionary = _storage.load_rewards()
		for key: String in ["battleCount", "captureCount", "totalGoldEarned", "totalItemsGained"]:
			stats[key] = maxi(int(stats.get(key, 0)), int(rewards.get(key, 0)))
	if _storage.has_method("load_player"):
		var player: Dictionary = _storage.load_player()
		stats["captureCount"] = maxi(int(stats.get("captureCount", 0)), player.get("captured", []).size())
	if _storage.has_method("load_stage_progress"):
		var cleared_count := 0
		var progress_data: Dictionary = _storage.load_stage_progress()
		for stage_id: String in progress_data.keys():
			var stage_state: Dictionary = progress_data.get(stage_id, {})
			if stage_state.get("cleared", false):
				cleared_count += 1
		stats["stageClearedCount"] = maxi(int(stats.get("stageClearedCount", 0)), cleared_count)
	if _storage.has_method("load_sign_in_data"):
		var sign_in_data: Dictionary = _storage.load_sign_in_data()
		stats["maxConsecutiveSignIn"] = maxi(int(stats.get("maxConsecutiveSignIn", 0)), int(sign_in_data.get("consecutiveDays", 0)))
		stats["totalSignInDays"] = maxi(int(stats.get("totalSignInDays", 0)), int(sign_in_data.get("totalDays", 0)))


func _filter_by_category(category: String) -> void:
	_current_category = category
	if category == "all":
		_filtered_achievements = _all_achievements.duplicate()
	else:
		_filtered_achievements = _all_achievements.filter(func(ach): return ach.get("category", "") == category)
	_scroll_offset = minf(_scroll_offset, _get_max_scroll_offset())
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
			_last_drag_y = event.position.y
		else:
			if abs(event.position.y - _drag_start_y) < 8.0:
				_on_tap(event.position)
			_dragging = false
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
			_last_drag_y = event.position.y
		else:
			if abs(event.position.y - _drag_start_y) < 8.0:
				_on_tap(event.position)
			_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_scroll_by_delta(event.position.y - _last_drag_y)
		_last_drag_y = event.position.y
		accept_event()
	elif event is InputEventScreenDrag:
		_scroll_by_delta(event.relative.y)
		accept_event()


func _on_tap(point: Vector2) -> void:
	if BACK_RECT.has_point(point):
		_on_back_pressed()
		return
	for i in range(CATEGORIES.size()):
		var tab_rect := _get_tab_rect(i)
		if tab_rect.has_point(point):
			_filter_by_category(str(CATEGORIES[i]["id"]))
			return
	if point.y < LIST_TOP or point.y > LIST_BOTTOM:
		return
	var index := int((point.y - LIST_TOP + _scroll_offset) / (CARD_H + CARD_GAP))
	if index < 0 or index >= _filtered_achievements.size():
		return
	var ach: Dictionary = _filtered_achievements[index]
	var card_rect := _get_card_rect(index)
	if not _is_card_fully_visible(card_rect):
		return
	if not card_rect.has_point(point):
		return
	if ach.get("unlocked", false) and not ach.get("claimed", false) and _get_claim_rect(card_rect).has_point(point):
		_claim_achievement(ach)
	elif ach.get("unlocked", false):
		_show_toast("%s 已完成" % ach.get("name", "成就"))
	else:
		_show_toast("目标进度 %d/%d" % [int(ach.get("progress", 0)), int(ach.get("target", 1))])


func _scroll_by_delta(delta_y: float) -> void:
	if _drag_start_y < LIST_TOP or _drag_start_y > LIST_BOTTOM:
		return
	_scroll_offset = clampf(_scroll_offset - delta_y, 0.0, _get_max_scroll_offset())
	queue_redraw()


func _claim_achievement(ach: Dictionary) -> void:
	var ach_id := str(ach.get("id", ""))
	if ach_id.is_empty() or _claimed_ids.has(ach_id):
		return
	var reward: Dictionary = ach.get("reward", {})
	if _storage and reward.has("gold") and _storage.has_method("add_gold"):
		_storage.add_gold(int(reward.get("gold", 0)))
	_claimed_ids.append(ach_id)
	if _storage and _storage.has_method("load_achievements") and _storage.has_method("save_achievements"):
		var save_data: Dictionary = _storage.load_achievements()
		save_data["claimedIds"] = _claimed_ids
		_storage.save_achievements(save_data)
	_all_achievements = _build_achievement_view_models(_storage.load_achievements() if _storage and _storage.has_method("load_achievements") else {})
	_filter_by_category(_current_category)
	_show_toast("领取成功 +%d 金币" % int(reward.get("gold", 0)))


func _get_max_scroll_offset() -> float:
	var content_h := _filtered_achievements.size() * (CARD_H + CARD_GAP) - CARD_GAP
	return maxf(0.0, content_h - (LIST_BOTTOM - LIST_TOP))


func _on_back_pressed() -> void:
	var manager := get_node_or_null("/root/SceneManager")
	if manager and manager.has_method("switch_scene"):
		manager.switch_scene("main", {}, "slide")
	else:
		var game := get_node_or_null("/root/GameManager")
		if game and game.has_method("switch_scene"):
			game.switch_scene("main", {}, "slide")


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_text = ""
		queue_redraw()
		if _toast_timer <= 0.0:
			set_process(false)


func _draw() -> void:
	_draw_texture_cover(_tex("bg"), Rect2(0, 0, DESIGN_W, DESIGN_H))
	_draw_list()
	# 列表是 Canvas 绘制，没有真实裁剪容器；重绘顶部背景和固定 UI，避免滚动卡片盖住头部。
	_draw_background_region(Rect2(0.0, 0.0, DESIGN_W, LIST_TOP))
	_draw_header()
	_draw_summary()
	_draw_tabs()
	_draw_toast()


func _draw_header() -> void:
	_draw_texture_fit(_tex("back"), BACK_RECT)
	_draw_texture_fit(_tex("header"), HEADER_RECT)
	_draw_centered_text("成就", Vector2(DESIGN_W / 2.0, 55.0), C["white"], 29.0, 116.0)


func _draw_summary() -> void:
	_draw_texture_fit(_tex("summary"), SUMMARY_RECT)
	_draw_texture_contain(_tex("trophy"), Rect2(30.0, 98.0, 94.0, 74.0))
	var unlocked_count := _all_achievements.filter(func(a): return a.get("unlocked", false)).size()
	var total_count: int = maxi(1, _all_achievements.size())
	var percent := int(round(float(unlocked_count) / float(total_count) * 100.0))
	var points := unlocked_count * 100 + _claimed_ids.size() * 50
	_draw_text_left("成就点数", Vector2(145.0, 118.0), C["muted"], 15.0, 86.0)
	_draw_text_left(_format_number(points), Vector2(145.0, 153.0), C["gold"], 28.0, 110.0)
	_draw_text_left("完成进度", Vector2(258.0, 118.0), C["muted"], 15.0, 84.0)
	_draw_text_left("%d%%" % percent, Vector2(266.0, 153.0), C["green"], 28.0, 76.0)
	_draw_progress_bar(Rect2(142.0, 165.0, 190.0, 15.0), float(unlocked_count) / float(total_count), "%d/%d" % [unlocked_count, total_count])


func _draw_tabs() -> void:
	for i in range(CATEGORIES.size()):
		var tab: Dictionary = CATEGORIES[i]
		var rect := _get_tab_rect(i)
		var id := str(tab["id"])
		_draw_texture_fit(_tex("tab_%s" % id), rect)
		if id == _current_category:
			draw_rect(rect.grow(-2.0), Color(0.45, 0.80, 1.0, 0.85), false, 2.0)
		_draw_centered_text(str(tab["label"]), rect.get_center() + Vector2(9.0, 8.0), C["white"] if id == _current_category else C["muted"], 14.0, 38.0)


func _draw_list() -> void:
	if _filtered_achievements.is_empty():
		_draw_centered_text("暂无成就", Vector2(DESIGN_W / 2.0, 420.0), C["muted"], 16.0, 160.0)
		return
	for i in range(_filtered_achievements.size()):
		var rect := _get_card_rect(i)
		if not _is_card_fully_visible(rect):
			continue
		_draw_achievement_card(_filtered_achievements[i], rect)
	_draw_scrollbar()


func _draw_achievement_card(ach: Dictionary, rect: Rect2) -> void:
	var unlocked := bool(ach.get("unlocked", false))
	var claimed := bool(ach.get("claimed", false))
	_draw_texture_fit(_tex("card"), rect)
	if not unlocked:
		draw_rect(rect.grow(-5.0), Color(0, 0, 0, 0.30), true)
	var badge_key := _get_badge_key(ach)
	_draw_texture_contain(_tex(badge_key), Rect2(rect.position.x + 12.0, rect.position.y + 10.0, 72.0, 74.0), 1.0 if unlocked else 0.65)
	if not unlocked:
		_draw_texture_contain(_tex("lock"), Rect2(rect.position.x + 52.0, rect.position.y + 56.0, 28.0, 30.0))
	_draw_texture_fit(_tex("ribbon"), Rect2(rect.position.x + 96.0, rect.position.y + 13.0, 126.0, 28.0))
	_draw_centered_text(_ellipsize(str(ach.get("name", "")), 7), Vector2(rect.position.x + 159.0, rect.position.y + 35.0), C["white"] if unlocked else C["muted"], 16.0, 112.0)
	_draw_text_left(_ellipsize(str(ach.get("desc", "")), 13), Vector2(rect.position.x + 98.0, rect.position.y + 58.0), C["muted"] if unlocked else C["dim"], 12.0, 146.0)
	var target: float = maxf(1.0, float(ach.get("target", 1)))
	var progress: float = clampf(float(ach.get("progress", 0)) / target, 0.0, 1.0)
	_draw_progress_bar(Rect2(rect.position.x + 98.0, rect.position.y + 72.0, 148.0, 14.0), progress, "%d/%d" % [int(ach.get("progress", 0)), int(ach.get("target", 1))])
	_draw_reward(ach, Rect2(rect.position.x + 250.0, rect.position.y + 14.0, 38.0, 38.0), unlocked)
	if claimed:
		_draw_texture_fit(_tex("stamp"), Rect2(rect.position.x + 256.0, rect.position.y + 56.0, 88.0, 31.0))
	elif unlocked:
		var claim_rect := _get_claim_rect(rect)
		_draw_texture_fit(_tex("claim"), claim_rect)
		_draw_centered_text("领取", claim_rect.get_center() + Vector2(0, 7.0), C["white"], 18.0, claim_rect.size.x)
	else:
		var disabled_rect := _get_claim_rect(rect)
		_draw_texture_fit(_tex("disabled"), disabled_rect)
		_draw_centered_text("未达成", disabled_rect.get_center() + Vector2(0, 6.0), C["muted"], 14.0, disabled_rect.size.x)


func _draw_reward(ach: Dictionary, rect: Rect2, active: bool) -> void:
	_draw_texture_fit(_tex("reward_slot"), rect)
	var reward: Dictionary = ach.get("reward", {})
	var icon_key := "gold"
	var amount := 0
	if reward.has("gold"):
		icon_key = "gold"
		amount = int(reward.get("gold", 0))
	_draw_texture_contain(_tex(icon_key), Rect2(rect.position.x + 6.0, rect.position.y + 4.0, 26.0, 24.0), 1.0 if active else 0.55)
	_draw_centered_text("x%d" % amount, Vector2(rect.get_center().x, rect.position.y + 36.0), C["white"] if active else C["muted"], 9.0, rect.size.x)


func _draw_progress_bar(rect: Rect2, ratio: float, label: String) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	_draw_texture_fit(_tex("progress_empty"), rect)
	if ratio > 0.0:
		_draw_texture_fit(_tex("progress_fill"), Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)))
	_draw_centered_text(label, rect.get_center() + Vector2(0, 5.0), C["white"], 11.0, rect.size.x)


func _draw_scrollbar() -> void:
	var max_offset := _get_max_scroll_offset()
	if max_offset <= 0.0:
		return
	var track := Rect2(363.0, LIST_TOP + 6.0, 5.0, LIST_BOTTOM - LIST_TOP - 12.0)
	draw_rect(track, Color(0.05, 0.09, 0.16, 0.75), true)
	var thumb_h := maxf(44.0, track.size.y * (track.size.y / (track.size.y + max_offset)))
	var thumb_y := track.position.y + (track.size.y - thumb_h) * (_scroll_offset / max_offset)
	draw_rect(Rect2(track.position.x, thumb_y, track.size.x, thumb_h), Color(0.50, 0.72, 0.95, 0.8), true)


func _draw_toast() -> void:
	if _toast_text.is_empty() or _toast_timer <= 0.0:
		return
	var alpha := minf(_toast_timer / 0.4, 1.0)
	var rect := Rect2(56.0, 603.0, 263.0, 38.0)
	draw_rect(rect, Color(0.03, 0.09, 0.16, 0.88 * alpha), true)
	draw_rect(rect, Color(0.45, 0.80, 1.0, 0.65 * alpha), false, 2.0)
	_draw_centered_text(_toast_text, rect.get_center() + Vector2(0, 6.0), Color(1, 1, 1, alpha), 14.0, rect.size.x - 18.0)


func _show_toast(text: String) -> void:
	_toast_text = text
	_toast_timer = 1.6
	set_process(true)
	queue_redraw()


func _get_tab_rect(index: int) -> Rect2:
	return Rect2(TAB_START_X + index * (TAB_W + TAB_GAP), TAB_Y, TAB_W, TAB_H)


func _get_card_rect(index: int) -> Rect2:
	var y := LIST_TOP + index * (CARD_H + CARD_GAP) - _scroll_offset
	return Rect2(CARD_X, y, CARD_W, CARD_H)


func _get_claim_rect(card_rect: Rect2) -> Rect2:
	return Rect2(card_rect.position.x + 260.0, card_rect.position.y + 54.0, 86.0, 34.0)

func _is_card_fully_visible(rect: Rect2) -> bool:
	return rect.position.y >= LIST_TOP and rect.end.y <= LIST_BOTTOM


func _get_badge_key(ach: Dictionary) -> String:
	if not ach.get("unlocked", false):
		return "badge_locked"
	match str(ach.get("category", "")):
		"battle":
			return "badge_battle"
		"collect":
			return "badge_collect"
		"continuous":
			return "badge_growth"
		_:
			return "badge_star"


func _format_number(value: int) -> String:
	var text := str(value)
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = text[i] + out
		count += 1
	return out


func _ellipsize(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "..."


func _tex(key: String) -> Texture2D:
	var path := str(ACHIEVEMENT_ASSETS.get(key, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path] as Texture2D


func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1, 1, 1, opacity))


func _draw_texture_contain(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var draw_size := size * scale
	var pos := rect.position + (rect.size - draw_size) * 0.5
	draw_texture_rect(tex, Rect2(pos, draw_size), false, Color(1, 1, 1, opacity))


func _draw_texture_cover(tex: Texture2D, rect: Rect2) -> void:
	if tex == null:
		draw_rect(rect, Color(0.04, 0.07, 0.15), true)
		return
	var size := tex.get_size()
	var scale := maxf(rect.size.x / size.x, rect.size.y / size.y)
	var source_size := rect.size / scale
	var source_pos := (size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size))

func _draw_background_region(rect: Rect2) -> void:
	var tex := _tex("bg")
	if tex == null:
		draw_rect(rect, Color(0.04, 0.07, 0.15), true)
		return
	var screen_rect := Rect2(0.0, 0.0, DESIGN_W, DESIGN_H)
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		draw_rect(rect, Color(0.04, 0.07, 0.15), true)
		return
	var scale := maxf(screen_rect.size.x / size.x, screen_rect.size.y / size.y)
	var full_source_size := screen_rect.size / scale
	var full_source_pos := (size - full_source_size) * 0.5
	var source_pos := full_source_pos + (rect.position - screen_rect.position) / scale
	var source_size := rect.size / scale
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size))


func _draw_centered_text(text: String, center: Vector2, color: Color, font_size: float, width: float) -> void:
	var size_i := int(font_size)
	var left := center.x - width / 2.0
	draw_string(ThemeDB.fallback_font, Vector2(left + 1.0, center.y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, C["shadow"])
	draw_string(ThemeDB.fallback_font, Vector2(left, center.y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, color)


func _draw_text_left(text: String, pos: Vector2, color: Color, font_size: float, width: float) -> void:
	var size_i := int(font_size)
	draw_string(ThemeDB.fallback_font, Vector2(pos.x + 1.0, pos.y + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, C["shadow"])
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, color)

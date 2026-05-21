# scene_team.gd - 队伍编成场景
# 源文件: js/ui/sceneTeamSetup.js
# 移植: _draw() 绘制 + _gui_input 交互
class_name SceneTeam
extends Control

const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const MonsterServiceScript = preload("res://src/core/monster_service.gd")

# === 常量 ===
const DESIGN_W := 375.0
const DESIGN_H := 667.0
const MARGIN := 15.0
const LIST_START_Y := 322.0
const LIST_ITEM_W := 85.0
const LIST_ITEM_H := 95.0
const LIST_GAP := 10.0
const LIST_COLS := 4

const TEAM_ASSETS := {
	"bg": "res://assets/images/main/main_lobby_bg.png",
	"back_button": "res://assets/images/team/ui_back_button.png",
	"header": "res://assets/images/team/ui_header_bar.png",
	"help_button": "res://assets/images/team/ui_help_button.png",
	"leader_card": "res://assets/images/team/ui_leader_card.png",
	"member_card": "res://assets/images/team/ui_member_card.png",
	"member_card_alt": "res://assets/images/team/ui_member_card_alt.png",
	"power_banner": "res://assets/images/team/ui_power_banner.png",
	"leader_skill_banner": "res://assets/images/team/ui_leader_skill_banner.png",
	"filter_tab_selected": "res://assets/images/team/ui_filter_tab_selected.png",
	"filter_tab_normal": "res://assets/images/team/ui_filter_tab_normal.png",
	"sort_dropdown": "res://assets/images/team/ui_sort_dropdown.png",
	"roster_card": "res://assets/images/team/ui_roster_card.png",
	"roster_card_selected": "res://assets/images/team/ui_roster_card_selected.png",
	"empty_slot": "res://assets/images/team/ui_empty_slot.png",
	"btn_cancel": "res://assets/images/team/ui_btn_cancel.png",
	"btn_save": "res://assets/images/team/ui_btn_save.png",
	"btn_disassemble": "res://assets/images/team/ui_btn_disassemble.png",
	"icon_power": "res://assets/images/team/icon_power_swords.png",
	"icon_leader": "res://assets/images/team/icon_leader_crown.png",
	"icon_hp": "res://assets/images/team/icon_stat_hp.png",
	"icon_atk": "res://assets/images/team/icon_stat_atk.png",
	"icon_def": "res://assets/images/team/icon_stat_def.png",
	"icon_spd": "res://assets/images/team/icon_stat_spd.png",
	"icon_check": "res://assets/images/team/icon_check.png",
}

const ELEMENT_ICON_ASSETS := {
	"fire": "res://assets/images/stage/icon_gem_fire.png",
	"water": "res://assets/images/stage/icon_gem_water.png",
	"grass": "res://assets/images/stage/icon_gem_grass.png",
	"thunder": "res://assets/images/stage/icon_gem_thunder.png",
	"light": "res://assets/images/stage/icon_gem_light.png",
}

# 颜色
const C := {
	"bg_medium": Color(0.04, 0.07, 0.15),
	"bg_card": Color(0.10, 0.15, 0.25),
	"in_team_bg": Color(0.15, 0.20, 0.35),
	"slot_border": Color(0.40, 0.40, 0.60),
	"gold": Color(1.0, 0.84, 0.0),
	"text_primary": Color(1.0, 1.0, 1.0),
	"text_secondary": Color(0.7, 0.75, 0.85),
	"text_muted": Color(0.5, 0.55, 0.65),
	"success": Color(0.2, 0.8, 0.3),
	"danger": Color(1.0, 0.2, 0.2),
	"white": Color(1.0, 1.0, 1.0),
	"disabled_bg": Color(0.20, 0.22, 0.30)
}

# === 信号 ===
signal team_changed(team: Dictionary)
signal scene_exit()

# === 状态 ===
var _game: Node = null
var _storage: Node = null

var _team: Dictionary = {"leader": null, "member1": null, "member2": null}
var _selected_slot: String = ""
var _hovered_slot: String = ""
var _hovered_monster_index: int = -1
var _list_scroll_y: float = 0.0
var _captured_monsters: Array = []

# 动画状态
var _anim_state: Dictionary = {
	"show_guide": false,
	"guide_timer": 0.0,
	"assign_pop_scale": 1.0,
	"assign_pop_target": "",
	"slot_glow_phase": 0.0
}

var _show_confirm: bool = false

# 按钮区域
var _back_btn: Rect2 = Rect2(15, 10, 60, 35)
var _save_btn: Rect2 = Rect2()
var _cancel_btn: Rect2 = Rect2()
var _disassemble_btn: Rect2 = Rect2()

# 槽位区域（动态计算）
var _slots: Array = []  # [{key, x, y, w, h, label}]

# 时间累计
var _time_acc: float = 0.0
var _texture_cache: Dictionary = {}

# ==================== 生命周期 ====================

var _bg_texture: ColorRect

func _add_dark_background() -> void:
	_bg_texture = ColorRect.new()
	_bg_texture.color = C["bg_medium"]
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

func _ready() -> void:
	_add_dark_background()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_slots_layout()

func _process(delta: float) -> void:
	_time_acc += delta
	var a := _anim_state
	a["guide_timer"] += delta
	a["slot_glow_phase"] += delta * 4.0
	
	# 分配弹跳动画
	if a["assign_pop_scale"] != 1.0 and a["assign_pop_target"] != "":
		var target_slot_key: String = a["assign_pop_target"]
		var elapsed: float = _get_assign_pop_elapsed()
		var duration: float = 0.3
		if elapsed < duration:
			var t: float = elapsed / duration
			if t < 0.5:
				a["assign_pop_scale"] = 1.3 - 0.3 * (t * 2.0)
			else:
				var t2: float = (t - 0.5) * 2.0
				a["assign_pop_scale"] = 1.0 + 0.05 * sin(t2 * PI)
		else:
			a["assign_pop_scale"] = 1.0
	
	queue_redraw()

# ==================== 初始化 ====================

func init(data: Dictionary = {}) -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_game = get_node_or_null("/root/GameManager")
	
	# 加载队伍
	if _storage:
			var saved: Dictionary = _storage.load_team()
			_team = {
				"leader": saved.get("leader", null),
				"member1": saved.get("member1", null),
				"member2": saved.get("member2", null)
			}
	else:
		_team = {"leader": null, "member1": null, "member2": null}
	
	_list_scroll_y = 0.0
	_selected_slot = ""
	_hovered_slot = ""
	_hovered_monster_index = -1
	
	_captured_monsters = _get_captured_monsters()
	_anim_state["show_guide"] = _captured_monsters.is_empty()
	_show_confirm = false
	_update_slots_layout()

# ==================== 辅助 ====================

func _get_captured_monsters() -> Array:
	if not _storage:
		return []
	if _storage.has_method("get_owned_monsters"):
		return _storage.get_owned_monsters()
	var player: Dictionary = _storage.load_player()
	var result: Array = []
	for monster_id in player.get("captured", []):
		result.append({"instanceId": str(monster_id), "monsterId": str(monster_id), "level": 1, "nature": ""})
	return result

func _get_instance_id(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("instanceId", ""))
	return str(value)

func _get_monster_id(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("monsterId", (value as Dictionary).get("id", "")))
	var ref_id := str(value)
	if _storage and _storage.has_method("get_monster_instance"):
		var instance: Dictionary = _storage.get_monster_instance(ref_id)
		if not instance.is_empty():
			return str(instance.get("monsterId", ""))
	return ref_id

func _get_monster_data(monster_id: String) -> Dictionary:
	if monster_id.is_empty():
		return {}
	var MonsterDB = load("res://src/data/monster_db.gd")
	if MonsterDB:
		return MonsterDB.get_monster(_get_monster_id(monster_id))
	return {}

func _get_real_level(ref_id: String) -> int:
	if not _storage:
		return 1
	if _storage.has_method("get_instance_level") and not _storage.get_monster_instance(ref_id).is_empty():
		return _storage.get_instance_level(ref_id)
	if _storage.has_method("get_monster_level"):
		return _storage.get_monster_level(ref_id)
	return 1

func _get_nature(ref_id: String) -> String:
	if not _storage:
		return ""
	if _storage.has_method("get_instance_nature") and not _storage.get_monster_instance(ref_id).is_empty():
		return _storage.get_instance_nature(ref_id)
	if _storage.has_method("get_monster_nature"):
		return _storage.get_monster_nature(ref_id)
	return ""

func _get_element_name(elem: String) -> String:
	var m := {"fire": "火", "water": "水", "grass": "草", "thunder": "雷", "light": "光", "dark": "暗", "earth": "土", "wind": "风", "ice": "冰"}
	return m.get(elem, elem)

func _get_element_color(elem: String) -> Color:
	var m := {
		"fire": Color(1.0, 0.3, 0.1),
		"water": Color(0.1, 0.4, 1.0),
		"grass": Color(0.1, 0.8, 0.2),
		"thunder": Color(0.9, 0.8, 0.1),
		"light": Color(1.0, 0.9, 0.2),
		"dark": Color(0.55, 0.25, 0.85),
		"earth": Color(0.65, 0.45, 0.25),
		"wind": Color(0.45, 0.95, 0.72),
		"ice": Color(0.55, 0.88, 1.0)
	}
	return m.get(elem, C["text_muted"])

func _calc_team_power() -> int:
	var total := 0
	for key in ["leader", "member1", "member2"]:
		var value: Variant = _team.get(key, null)
		var mid := "" if value == null else str(value)
		if mid.is_empty():
			continue
		var md: Dictionary = _get_monster_data(mid)
		if md.is_empty():
			continue
		var lvl: int = _get_real_level(mid)
		var stats: Dictionary = _calc_stats(mid, lvl)
		total += stats.get("hp", 0) + stats.get("atk", 0) + stats.get("def", 0) + stats.get("spd", 0)
	return total

func _calc_stats(monster_id: String, level: int) -> Dictionary:
	if _storage and _storage.has_method("get_instance_stats") and not _storage.get_monster_instance(monster_id).is_empty():
		return _storage.get_instance_stats(monster_id)
	var MonsterDB = load("res://src/data/monster_db.gd")
	if MonsterDB and MonsterDB.has_method("get_monster_stats"):
		return MonsterDB.get_monster_stats(_get_monster_id(monster_id), level, _get_nature(monster_id))
	return {"hp": 50, "atk": 10, "def": 10, "spd": 10}

func _get_max_list_scroll() -> float:
	if _captured_monsters.is_empty():
		return 0.0
	var rows := ceili(float(_captured_monsters.size()) / LIST_COLS)
	var content_h := rows * (LIST_ITEM_H + LIST_GAP) - LIST_GAP
	var view_h := DESIGN_H - 95.0 - LIST_START_Y
	return maxf(0.0, content_h - view_h)

func _get_assign_pop_elapsed() -> float:
	var start_time: float = _anim_state.get("assign_pop_start_time", 0.0)
	if start_time == 0.0:
		return 0.0
	return (Time.get_ticks_msec() - start_time) / 1000.0

func _trigger_assign_pop(slot_key: String) -> void:
	_anim_state["assign_pop_target"] = slot_key
	_anim_state["assign_pop_scale"] = 0.5
	_anim_state["assign_pop_start_time"] = Time.get_ticks_msec()

func _update_slots_layout() -> void:
	var center_x := DESIGN_W / 2.0
	var start_y := 78.0
	
	# 队长槽
	var leader_rect := Rect2(center_x - 50.0, start_y, 100.0, 132.0)
	# 成员1槽
	var member1_rect := Rect2(center_x - 50.0 - 92.0, start_y + 12.0, 82.0, 112.0)
	# 成员2槽
	var member2_rect := Rect2(center_x + 50.0 + 10.0, start_y + 12.0, 82.0, 112.0)
	
	_slots = [
		{"key": "leader", "rect": leader_rect, "label": "队长"},
		{"key": "member1", "rect": member1_rect, "label": "成员1"},
		{"key": "member2", "rect": member2_rect, "label": "成员2"}
	]
	
	# 按钮区域
	_disassemble_btn = Rect2(MARGIN, DESIGN_H - 64.0, 46.0, 46.0)
	_cancel_btn = Rect2(72.0, DESIGN_H - 64.0, 118.0, 46.0)
	_save_btn = Rect2(205.0, DESIGN_H - 64.0, 146.0, 46.0)

func _point_in_rect(pos: Vector2, rect: Rect2) -> bool:
	return rect.has_point(pos)

# ==================== 输入 ====================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenDrag:
		var dy: float = event.relative.y
		if dy < -5.0:
			_scroll_list(1)
		elif dy > 5.0:
			_scroll_list(-1)
		accept_event()

func _on_tap(x: float, y: float) -> void:
	var pos := Vector2(x, y)
	
	if _show_confirm:
		_handle_confirm_tap(pos)
		return
	
	# 返回按钮
	if _point_in_rect(pos, _back_btn):
		_change_to_scene("main")
		return
	
	# 保存按钮
	if _point_in_rect(pos, _save_btn):
		_save_team()
		_change_to_scene("main")
		return
	
	# 取消按钮
	if _point_in_rect(pos, _cancel_btn):
		_show_confirm = true
		return
	
	# 槽位点击
	for s: Dictionary in _slots:
		if _point_in_rect(pos, s["rect"]):
			_handle_slot_tap(s["key"])
			return
	
	# 怪物列表点击
	var monster_idx := _get_monster_index_at_pos(pos)
	if monster_idx >= 0 and monster_idx < _captured_monsters.size():
		_assign_to_slot(_get_instance_id(_captured_monsters[monster_idx]))
		return

func _handle_confirm_tap(pos: Vector2) -> void:
	var cx := DESIGN_W / 2.0
	var cy := DESIGN_H / 2.0
	var confirm_btn := Rect2(cx - 110.0, cy + 30.0, 100.0, 40.0)
	var continue_btn := Rect2(cx + 10.0, cy + 30.0, 100.0, 40.0)
	var dialog_rect := Rect2(cx - 125.0, cy - 75.0, 250.0, 150.0)
	
	if _point_in_rect(pos, confirm_btn):
		_show_confirm = false
		_change_to_scene("main")
	elif _point_in_rect(pos, continue_btn):
		_show_confirm = false
	elif not _point_in_rect(pos, dialog_rect):
		_show_confirm = false

func _handle_slot_tap(slot_key: String) -> void:
	if _team.get(slot_key) != null:
		# 有怪物 → 清空
		_team[slot_key] = null
		if _selected_slot == slot_key:
			_selected_slot = ""
	else:
		# 空槽位 → 切换选中
		_selected_slot = "" if _selected_slot == slot_key else slot_key

func _scroll_list(direction: int) -> void:
	var step := LIST_ITEM_H + LIST_GAP
	var max_scroll := _get_max_list_scroll()
	_list_scroll_y = clampf(_list_scroll_y + direction * step, 0.0, max_scroll)

func _assign_to_slot(monster_id: String) -> void:
	if _selected_slot.is_empty():
		# 自动填入第一个空槽位
		for key in ["leader", "member1", "member2"]:
			if _team[key] == null:
				_team[key] = monster_id
				_trigger_assign_pop(key)
				return
		# 队伍满了，替换队长
		_team["leader"] = monster_id
		_trigger_assign_pop("leader")
	else:
		# 替换目标槽位
		var existing: Variant = _team[_selected_slot]
		_team[_selected_slot] = monster_id
		# 防止重复：如果其他槽已有这个怪物，交换
		for key in ["leader", "member1", "member2"]:
			if key != _selected_slot and _team[key] == monster_id:
				_team[key] = existing
				break
		_selected_slot = ""

func _get_monster_index_at_pos(pos: Vector2) -> int:
	var list_x := (DESIGN_W - (LIST_COLS * LIST_ITEM_W + (LIST_COLS - 1) * LIST_GAP)) / 2.0
	var list_y := LIST_START_Y
	var list_bottom_y := DESIGN_H - 95.0
	
	if pos.y < list_y or pos.y > list_bottom_y:
		return -1
	
	var rel_x := pos.x - list_x
	var rel_y := pos.y - list_y + _list_scroll_y
	
	if rel_x < 0.0:
		return -1
	
	var col := int(floor(rel_x / (LIST_ITEM_W + LIST_GAP)))
	var row := int(floor(rel_y / (LIST_ITEM_H + LIST_GAP)))
	var index := row * LIST_COLS + col
	
	if col < 0 or col >= LIST_COLS:
		return -1
	
	return index

# ==================== 绘制 ====================

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var t := _time_acc
	
	# 背景
	_draw_texture_cover(_tex("bg"), Rect2(0, 0, DESIGN_W, DESIGN_H))
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.05, 0.12, 0.45))
	
	# 标题
	_draw_texture_fit(_tex("header"), Rect2(82.0, 18.0, 210.0, 38.0))
	_draw_text(font, "队伍编成", DESIGN_W / 2.0, 44.0, C["text_primary"], 22.0)
	
	# 返回按钮
	_draw_texture_fit(_tex("back_button"), _back_btn)
	_draw_text(font, "←", _back_btn.position.x + _back_btn.size.x / 2.0, _back_btn.position.y + 25.0, C["text_secondary"], 24.0)
	_draw_texture_fit(_tex("help_button"), Rect2(DESIGN_W - 58.0, 10.0, 43.0, 43.0))
	
	# 空引导提示
	if _anim_state["show_guide"]:
		var alpha := 0.6 + sin(t * 3.0) * 0.4
		_draw_text(font, "点击开始冒险，赢取你的第一只怪物", DESIGN_W / 2.0, 63.0, Color(C["gold"].r, C["gold"].g, C["gold"].b, alpha), 10.0)
	
	# 渲染槽位
	for s: Dictionary in _slots:
		_draw_slot(font, s, t)

	_draw_team_summary(font)
	_draw_roster_toolbar(font)
	
	# 渲染怪物列表
	_draw_monster_list(font, t)
	
	# 底部按钮
	_draw_icon_button(_disassemble_btn, "btn_disassemble")
	_draw_button(_cancel_btn, "取消", "btn_cancel")
	_draw_button(_save_btn, "保存队伍", "btn_save")
	
	# 确认弹窗
	if _show_confirm:
		_draw_confirm_dialog(font)

func _draw_text(font: Font, text: String, x: float, y: float, color: Color, size: float) -> void:
	draw_string(font, Vector2(x - 100.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, size, color)

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	var rr := minf(r, minf(w, h) / 2.0)
	if rr > 0.0:
		draw_rect(Rect2(x + rr, y, w - rr * 2.0, h), color)
		draw_rect(Rect2(x, y + rr, w, h - rr * 2.0), color)
		draw_circle(Vector2(x + rr, y + rr), rr, color)
		draw_circle(Vector2(x + w - rr, y + rr), rr, color)
		draw_circle(Vector2(x + rr, y + h - rr), rr, color)
		draw_circle(Vector2(x + w - rr, y + h - rr), rr, color)
	else:
		draw_rect(Rect2(x, y, w, h), color)

func _draw_button(rect: Rect2, text: String, asset_key: String) -> void:
	_draw_texture_fit(_tex(asset_key), rect)
	_draw_text(ThemeDB.fallback_font, text, rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y / 2.0 + 6.0, C["white"], 16.0)

func _draw_icon_button(rect: Rect2, asset_key: String) -> void:
	_draw_texture_fit(_tex(asset_key), rect)

func _draw_team_summary(font: Font) -> void:
	var power := _calc_team_power()
	_draw_texture_fit(_tex("power_banner"), Rect2(18.0, 224.0, 155.0, 42.0))
	_draw_texture_fit(_tex("icon_power"), Rect2(33.0, 230.0, 28.0, 28.0))
	_draw_text(font, "队伍战力", 101.0, 240.0, C["text_secondary"], 10.0)
	_draw_text(font, "%d" % power, 106.0, 259.0, C["gold"] if power > 0 else C["text_muted"], 17.0)

	_draw_texture_fit(_tex("leader_skill_banner"), Rect2(175.0, 224.0, 184.0, 42.0))
	_draw_texture_fit(_tex("icon_leader"), Rect2(184.0, 230.0, 29.0, 26.0))
	var leader_value: Variant = _team.get("leader", null)
	var leader_id := "" if leader_value == null else str(leader_value)
	var skill_text := "未设置队长技能"
	var skill_color := C["text_muted"]
	if not leader_id.is_empty():
		var md := _get_monster_data(leader_id)
		var skill_id: String = md.get("leaderSkill", md.get("leader_skill", ""))
		if not skill_id.is_empty():
			var LeaderSkillDB = load("res://src/data/leader_skill_db.gd")
			if LeaderSkillDB:
				var skill = LeaderSkillDB.get_leader_skill(skill_id)
				if skill:
					skill_text = "%s：%s" % [skill.get("name", "队长技"), skill.get("desc", "")]
					skill_color = C["gold"]
	_draw_text(font, skill_text, 279.0, 250.0, skill_color, 10.0)

func _draw_roster_toolbar(font: Font) -> void:
	var y := LIST_START_Y - 44.0
	_draw_texture_fit(_tex("filter_tab_selected"), Rect2(16.0, y, 58.0, 28.0))
	_draw_text(font, "全部", 45.0, y + 19.0, C["white"], 11.0)
	var tabs := [
		{"label": "火", "elem": "fire", "x": 82.0},
		{"label": "水", "elem": "water", "x": 125.0},
		{"label": "草", "elem": "grass", "x": 168.0},
	]
	for tab in tabs:
		_draw_texture_fit(_tex("filter_tab_normal"), Rect2(tab["x"], y + 2.0, 36.0, 25.0))
		_draw_element_icon(tab["elem"], Rect2(tab["x"] + 8.0, y + 5.0, 20.0, 20.0))
	_draw_texture_fit(_tex("sort_dropdown"), Rect2(254.0, y, 96.0, 30.0))
	_draw_text(font, "等级", 299.0, y + 20.0, C["text_secondary"], 11.0)

func _draw_slot(font: Font, slot: Dictionary, t: float) -> void:
	var rect: Rect2 = slot["rect"]
	var key: String = slot["key"]
	var label: String = slot["label"]
	var monster_value: Variant = _team.get(key, null)
	var monster_id := "" if monster_value == null else str(monster_value)
	var is_selected := _selected_slot == key
	var is_hovered := _hovered_slot == key
	
	# 弹跳缩放
	var scale := 1.0
	if _anim_state["assign_pop_target"] == key and _anim_state["assign_pop_scale"] != 1.0:
		scale = _anim_state["assign_pop_scale"]
	
	var cx := rect.position.x + rect.size.x / 2.0
	var cy := rect.position.y + rect.size.y / 2.0
	var new_w := rect.size.x * scale
	var new_h := rect.size.y * scale
	var new_x := cx - new_w / 2.0
	var new_y := cy - new_h / 2.0
	var scaled_rect := Rect2(new_x, new_y, new_w, new_h)
	
	# 悬停外发光
	if is_hovered or is_selected:
		var glow_alpha := 0.3 + sin(t * 4.0) * 0.15
		_draw_rounded_rect(new_x - 4.0, new_y - 4.0, new_w + 8.0, new_h + 8.0, 8.0, Color(C["gold"].r, C["gold"].g, C["gold"].b, glow_alpha))
	
	var frame_key := "leader_card" if key == "leader" else ("member_card" if key == "member1" else "member_card_alt")
	_draw_texture_fit(_tex(frame_key), scaled_rect)
	
	# 选中闪烁
	if is_selected:
		var flash := sin(t * 6.67) * 0.3 + 0.7
		_draw_rounded_rect_outline(new_x - 2.0, new_y - 2.0, new_w + 4.0, new_h + 4.0, 10.0, Color(C["gold"].r, C["gold"].g, C["gold"].b, flash), 2.0)
	
	if not monster_id.is_empty():
		var md: Dictionary = _get_monster_data(monster_id)
		if not md.is_empty():
			var face_size := 60.0 if key == "leader" else 48.0
			_draw_monster_portrait(monster_id, Rect2(cx - face_size / 2.0, new_y + 22.0, face_size, face_size))
			_draw_text(font, md.get("name", "未知"), cx, new_y + (88.0 if key == "leader" else 78.0), C["text_primary"], 11.0)
			
			var lvl: int = _get_real_level(monster_id)
			_draw_text(font, "Lv.%d" % lvl, cx, new_y + new_h - 33.0, C["white"], 10.0)
			
			var elem: String = md.get("element", "fire")
			_draw_element_icon(elem, Rect2(new_x + 8.0, new_y + 9.0, 22.0, 22.0))
			
			var stats: Dictionary = _calc_stats(monster_id, lvl)
			_draw_stat_pair(font, "hp", int(stats.get("hp", 0)), new_x + 10.0, new_y + new_h - 25.0)
			_draw_stat_pair(font, "atk", int(stats.get("atk", 0)), new_x + new_w * 0.52, new_y + new_h - 25.0)
		else:
			_draw_text(font, label, cx, new_y + new_h / 2.0, C["text_muted"], 9.0)
	else:
		# 空槽位
		var slot_label_text := "选择怪物" if is_selected else label
		var text_color := C["gold"] if is_selected else C["text_muted"]
		_draw_texture_fit(_tex("empty_slot"), Rect2(cx - 25.0, new_y + 25.0, 50.0, 58.0), 0.55)
		_draw_text(font, slot_label_text, cx, new_y + 92.0, text_color, 11.0)
	_draw_text(font, label, cx, new_y + new_h - 9.0, C["text_muted"], 8.5)

func _draw_rounded_rect_outline(x: float, y: float, w: float, h: float, r: float, color: Color, line_w: float) -> void:
	# 用粗线模拟 strokeRect
	draw_rect(Rect2(x, y, w, line_w), color)
	draw_rect(Rect2(x, y + h - line_w, w, line_w), color)
	draw_rect(Rect2(x, y, line_w, h), color)
	draw_rect(Rect2(x + w - line_w, y, line_w, h), color)

func _draw_monster_list(font: Font, t: float) -> void:
	var list_x := (DESIGN_W - (LIST_COLS * LIST_ITEM_W + (LIST_COLS - 1) * LIST_GAP)) / 2.0
	var list_y := LIST_START_Y
	var list_bottom_y := DESIGN_H - 95.0
	
	# 裁剪区域（列表内只显示可见范围）
	# 不做裁剪，直接绘制所有卡片
	
	for i in range(_captured_monsters.size()):
		var row := int(i / LIST_COLS)
		var col := i % LIST_COLS
		var card_x := list_x + col * (LIST_ITEM_W + LIST_GAP)
		var card_y := list_y + row * (LIST_ITEM_H + LIST_GAP) - _list_scroll_y
		
		# 跳过不可见卡片
		if card_y > list_bottom_y or card_y + LIST_ITEM_H < list_y:
			continue
		
		var instance: Dictionary = _captured_monsters[i]
		var instance_id := _get_instance_id(instance)
		var monster_id := _get_monster_id(instance)
		var md: Dictionary = _get_monster_data(monster_id)
		if md.is_empty():
			continue

		var is_hovered := (_hovered_monster_index == i)
		var in_team := _team.values().has(instance_id)
		var card_key := "roster_card_selected" if in_team or is_hovered else "roster_card"
		_draw_texture_fit(_tex(card_key), Rect2(card_x, card_y, LIST_ITEM_W, LIST_ITEM_H))
		if in_team:
			_draw_texture_fit(_tex("icon_check"), Rect2(card_x + LIST_ITEM_W - 21.0, card_y - 4.0, 22.0, 20.0))
		
		# 怪物头像
		_draw_monster_portrait(monster_id, Rect2(card_x + 17.0, card_y + 10.0, 51.0, 48.0))
		
		# 名字
		var name: String = md.get("name", "?")
		if name.length() > 5:
			name = name.substr(0, 5)
		_draw_text(font, name, card_x + LIST_ITEM_W / 2.0, card_y + 62.0, C["text_primary"], 9.5)
		
		# 等级
		var lvl: int = _get_real_level(instance_id)
		_draw_text(font, "Lv.%d" % lvl, card_x + LIST_ITEM_W / 2.0, card_y + 75.0, C["white"], 8.5)
		
		# 属性角标
		var elem: String = md.get("element", "fire")
		_draw_element_icon(elem, Rect2(card_x + 5.0, card_y + 5.0, 18.0, 18.0))
		var rarity := int(md.get("rarity", 1))
		var stars := ""
		for s in range(mini(rarity, 5)):
			stars += "★"
		_draw_text(font, stars, card_x + LIST_ITEM_W / 2.0, card_y + 90.0, C["gold"], 8.0)

func _draw_confirm_dialog(font: Font) -> void:
	var cx := DESIGN_W / 2.0
	var cy := DESIGN_H / 2.0
	
	# 半透明遮罩
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.0, 0.0, 0.0, 0.7))
	
	var dw := 250.0
	var dh := 150.0
	var dx := cx - dw / 2.0
	var dy := cy - dh / 2.0
	
	# 弹窗背景
	_draw_rounded_rect(dx, dy, dw, dh, 8.0, Color(0.12, 0.12, 0.20, 0.95))
	_draw_rounded_rect_outline(dx, dy, dw, dh, 8.0, Color(0.30, 0.30, 0.50, 1.0), 2.0)
	
	_draw_text(font, "确认取消编辑？", cx, dy + 30.0, C["text_primary"], 16.0)
	_draw_text(font, "未保存的更改将丢失", cx, dy + 52.0, C["text_muted"], 11.0)
	
	# 确认取消按钮
	var confirm_btn := Rect2(dx + 15.0, dy + 100.0, 100.0, 40.0)
	var continue_btn := Rect2(dx + 135.0, dy + 100.0, 100.0, 40.0)
	
	_draw_rounded_rect(confirm_btn.position.x, confirm_btn.position.y, confirm_btn.size.x, confirm_btn.size.y, 8.0, C["danger"])
	_draw_text(font, "确认取消", confirm_btn.position.x + 50.0, confirm_btn.position.y + 24.0, C["white"], 14.0)
	
	_draw_rounded_rect(continue_btn.position.x, continue_btn.position.y, continue_btn.size.x, continue_btn.size.y, 8.0, C["bg_card"])
	_draw_text(font, "继续编辑", continue_btn.position.x + 50.0, continue_btn.position.y + 24.0, C["text_primary"], 14.0)

func _draw_stat_pair(font: Font, stat_key: String, value: int, x: float, y: float) -> void:
	var icon_key := "icon_%s" % stat_key
	_draw_texture_fit(_tex(icon_key), Rect2(x, y - 10.0, 13.0, 13.0))
	draw_string(font, Vector2(x + 15.0, y), "%d" % value, HORIZONTAL_ALIGNMENT_LEFT, 44.0, 8.5, C["text_secondary"])

func _draw_element_icon(element: String, rect: Rect2) -> void:
	var path: String = ELEMENT_ICON_ASSETS.get(element, "")
	if path.is_empty():
		_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, rect.size.x / 2.0, _get_element_color(element))
		return
	_draw_texture_fit(_get_texture(path), rect)

func _draw_monster_portrait(monster_id: String, rect: Rect2) -> void:
	var path: String = MonsterArtDBScript.get_art_path(_get_monster_id(monster_id), "team")
	var tex := _get_texture(path)
	if tex:
		_draw_texture_fit(tex, rect)
		return
	var md := _get_monster_data(monster_id)
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 8.0, Color(0.04, 0.07, 0.15, 0.82))
	_draw_text(ThemeDB.fallback_font, md.get("emoji", "?"), rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y * 0.60, C["white"], minf(rect.size.x * 0.45, 22.0))

func _tex(key: String) -> Texture2D:
	var path: String = TEAM_ASSETS.get(key, "")
	if path.is_empty():
		return null
	return _get_texture(path)

func _get_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex := load(path) as Texture2D
	_texture_cache[path] = tex
	return tex

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, opacity))

func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		draw_rect(rect, C["bg_medium"])
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var src_aspect := tex_size.x / tex_size.y
	var dst_aspect := rect.size.x / rect.size.y
	var src_rect := Rect2(Vector2.ZERO, tex_size)
	if src_aspect > dst_aspect:
		var crop_w := tex_size.y * dst_aspect
		src_rect.position.x = (tex_size.x - crop_w) / 2.0
		src_rect.size.x = crop_w
	else:
		var crop_h := tex_size.x / dst_aspect
		src_rect.position.y = (tex_size.y - crop_h) / 2.0
		src_rect.size.y = crop_h
	draw_texture_rect_region(tex, rect, src_rect, Color(1.0, 1.0, 1.0, opacity))

# ==================== 操作 ====================

func _save_team() -> void:
	if _storage:
		_storage.save_team(_team)
		emit_signal("team_changed", _team)

func _change_to_scene(scene_name: String) -> void:
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").switch_scene(scene_name)
	elif has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm and gm.has_node("scene_manager"):
			gm.scene_manager.switch_scene(scene_name)

func destroy() -> void:
	pass

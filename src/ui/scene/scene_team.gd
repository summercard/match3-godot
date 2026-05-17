# scene_team.gd - 队伍编成场景
# 源文件: js/ui/sceneTeamSetup.js
# 移植: _draw() 绘制 + _gui_input 交互
class_name SceneTeam
extends Control

# === 常量 ===
const DESIGN_W := 375.0
const DESIGN_H := 667.0
const MARGIN := 15.0
const LIST_START_Y := 200.0
const LIST_ITEM_W := 85.0
const LIST_ITEM_H := 95.0
const LIST_GAP := 10.0
const LIST_COLS := 4

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

# 槽位区域（动态计算）
var _slots: Array = []  # [{key, x, y, w, h, label}]

# 时间累计
var _time_acc: float = 0.0

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
			""member1"": saved.get("member1", null),
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
	var player: Dictionary = _storage.load_player()
	return player.get("captured", [])

func _get_monster_data(monster_id: String) -> Dictionary:
	if monster_id.is_empty():
		return {}
	var MonsterDB = load("res://src/data/monster_db.gd")
	if MonsterDB:
		return MonsterDB.get_monster(monster_id)
	return {}

func _get_real_level(monster_id: String) -> int:
	if not _storage:
		return 1
	if _storage.has_method("get_monster_level"):
		return _storage.get_monster_level(monster_id)
	return 1

func _get_nature(monster_id: String) -> String:
	if not _storage:
		return ""
	if _storage.has_method("get_monster_nature"):
		return _storage.get_monster_nature(monster_id)
	return ""

func _get_element_name(elem: String) -> String:
	var m := {"fire": "火", "water": "水", "grass": "草", "thunder": "雷", "light": "光"}
	return m.get(elem, elem)

func _get_element_color(elem: String) -> Color:
	var m := {
		"fire": Color(1.0, 0.3, 0.1),
		"water": Color(0.1, 0.4, 1.0),
		"grass": Color(0.1, 0.8, 0.2),
		"thunder": Color(0.9, 0.8, 0.1),
		"light": Color(1.0, 0.9, 0.2)
	}
	return m.get(elem, C["text_muted"])

func _calc_team_power() -> int:
	var total := 0
	for key in ["leader", "member1", "member2"]:
		var mid: String = _team.get(key, "")
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
	var MonsterDB = load("res://src/data/monster_db.gd")
	if MonsterDB and MonsterDB.has_method("get_monster_stats"):
		return MonsterDB.get_monster_stats(monster_id, level)
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
	var start_y := 70.0
	
	# 队长槽
	var leader_rect := Rect2(center_x - 50.0, start_y, 100.0, 120.0)
	# 成员1槽
	var member1_rect := Rect2(center_x - 50.0 - 90.0, start_y + 10.0, 80.0, 100.0)
	# 成员2槽
	var member2_rect := Rect2(center_x + 50.0 + 10.0, start_y + 10.0, 80.0, 100.0)
	
	_slots = [
		{"key": "leader", "rect": leader_rect, "label": "队长"},
		{"key": "member1", "rect": member1_rect, "label": "成员1"},
		{"key": "member2", "rect": member2_rect, "label": "成员2"}
	]
	
	# 按钮区域
	_cancel_btn = Rect2(MARGIN, DESIGN_H - 75.0, 100.0, 45.0)
	_save_btn = Rect2(DESIGN_W - MARGIN - 140.0, DESIGN_H - 75.0, 140.0, 45.0)

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
		_assign_to_slot(_captured_monsters[monster_idx])
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
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), C["bg_medium"])
	
	# 标题
	_draw_text(font, "⚙️ 队伍编成", DESIGN_W / 2.0, 40.0, C["text_primary"], 22.0)
	
	# 返回按钮
	_draw_rounded_rect(_back_btn.position.x, _back_btn.position.y, _back_btn.size.x, _back_btn.size.y, 6.0, C["bg_card"])
	_draw_text(font, "← 返回", _back_btn.position.x + 8.0, _back_btn.position.y + 22.0, C["text_secondary"], 14.0)
	
	# 空引导提示
	if _anim_state["show_guide"]:
		var alpha := 0.6 + sin(t * 3.0) * 0.4
		_draw_text(font, "💡 点击开始冒险，赢取你的第一只怪物！", DESIGN_W / 2.0, 55.0, Color(C["gold"].r, C["gold"].g, C["gold"].b, alpha), 10.0)
	
	# 战力显示
	var power := _calc_team_power()
	var power_color := C["text_secondary"]
	if power > 0:
		power_color = C["success"]
	_draw_text(font, "队伍总战力: %d" % power, DESIGN_W / 2.0, 155.0, power_color, 14.0)
	
	# 分隔线
	draw_rect(Rect2(MARGIN, 170.0, DESIGN_W - MARGIN * 2.0, 1.0), C["disabled_bg"])
	
	# 怪物列表标题
	_draw_text(font, "📋 已收服怪物", DESIGN_W / 2.0, 195.0, C["text_secondary"], 12.0)
	
	# 渲染槽位
	for s: Dictionary in _slots:
		_draw_slot(font, s, t)
	
	# 渲染怪物列表
	_draw_monster_list(font, t)
	
	# 底部按钮
	_draw_button(_cancel_btn, "取消", C["danger"])
	_draw_button(_save_btn, "💾 保存", C["slot_border"])
	
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

func _draw_button(rect: Rect2, text: String, color: Color) -> void:
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 8.0, color)
	var text_color := C["text_primary"] if color != C["danger"] else C["white"]
	_draw_text(ThemeDB.fallback_font, text, rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y / 2.0 + 5.0, text_color, 14.0)

func _draw_slot(font: Font, slot: Dictionary, t: float) -> void:
	var rect: Rect2 = slot["rect"]
	var key: String = slot["key"]
	var label: String = slot["label"]
	var monster_id: String = _team.get(key, "")
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
	if is_hovered:
		var glow_alpha := 0.3 + sin(t * 4.0) * 0.15
		_draw_rounded_rect(new_x - 4.0, new_y - 4.0, new_w + 8.0, new_h + 8.0, 8.0, Color(C["gold"].r, C["gold"].g, C["gold"].b, glow_alpha))
	
	var bg_color := C["bg_card"]
	var border_color := C["slot_border"]
	var border_w := 2.0
	
	if is_selected:
		border_color = C["gold"]
		border_w = 3.0
	if not monster_id.is_empty():
		bg_color = C["in_team_bg"]
		var md: Dictionary = _get_monster_data(monster_id)
		if not md.is_empty():
			border_color = _get_element_color(md.get("element", ""))
	
	_draw_rounded_rect(new_x, new_y, new_w, new_h, 8.0, bg_color)
	_draw_rounded_rect_outline(new_x, new_y, new_w, new_h, 8.0, border_color, border_w)
	
	# 选中闪烁
	if is_selected:
		var flash := sin(t * 6.67) * 0.3 + 0.7
		_draw_rounded_rect_outline(new_x - 2.0, new_y - 2.0, new_w + 4.0, new_h + 4.0, 10.0, Color(C["gold"].r, C["gold"].g, C["gold"].b, flash), 2.0)
	
	if not monster_id.is_empty():
		var md: Dictionary = _get_monster_data(monster_id)
		if not md.is_empty():
			_draw_text(font, md.get("emoji", "❓"), cx, new_y + 35.0, C["text_primary"], 28.0)
			_draw_text(font, md.get("name", "未知"), cx, new_y + 55.0, C["text_primary"], 11.0)
			
			var lvl: int = _get_real_level(monster_id)
			_draw_text(font, "Lv.%d" % lvl, cx, new_y + 68.0, C["text_muted"], 9.0)
			
			var nature: String = _get_nature(monster_id)
			if not nature.is_empty():
				_draw_text(font, nature, cx, new_y + 80.0, C["gold"], 9.0)
			
			var elem: String = md.get("element", "fire")
			var elem_color: Color = _get_element_color(elem)
			_draw_rounded_rect(new_x + 5.0, new_y + 5.0, 28.0, 14.0, 4.0, elem_color)
			_draw_text(font, _get_element_name(elem), new_x + 19.0, new_y + 14.0, C["white"], 9.0)
			
			_draw_text(font, label, cx, new_y + new_h - 12.0, C["text_muted"], 9.0)
			
			# 队长技能（仅队长槽）
			if key == "leader" and md.has("leader_skill"):
				var LeaderSkillDB = load("res://src/data/leader_skill_db.gd")
				if LeaderSkillDB:
					var skill = LeaderSkillDB.get_skill(md["leader_skill"])
					if skill:
						_draw_text(font, "%s %s" % [skill.get("icon", "⭐"), skill.get("name", "队长技")], cx, new_y + new_h + 10.0, C["gold"], 9.0)
						_draw_text(font, skill.get("desc", ""), cx, new_y + new_h + 22.0, C["text_secondary"], 9.0)
					else:
						_draw_text(font, "(无队长技能)", cx, new_y + new_h + 10.0, C["text_muted"], 9.0)
		else:
			_draw_text(font, label, cx, new_y + new_h / 2.0, C["text_muted"], 9.0)
	else:
		# 空槽位
		var emoji := "👑" if key == "leader" else "⚔️"
		var slot_label_text := "选择怪物" if is_selected else label
		var text_color := C["gold"] if is_selected else C["text_muted"]
		_draw_text(font, emoji, cx, new_y + 30.0, text_color, 28.0)
		_draw_text(font, slot_label_text, cx, new_y + 50.0, text_color, 11.0)
		if key == "leader":
			_draw_text(font, "点击后将填入此处", cx, new_y + 65.0, C["text_muted"], 9.0)
		_draw_text(font, label, cx, new_y + new_h - 12.0, C["text_muted"], 9.0)

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
		var row := i / LIST_COLS
		var col := i % LIST_COLS
		var card_x := list_x + col * (LIST_ITEM_W + LIST_GAP)
		var card_y := list_y + row * (LIST_ITEM_H + LIST_GAP) - _list_scroll_y
		
		# 跳过不可见卡片
		if card_y > list_bottom_y or card_y + LIST_ITEM_H < list_y:
			continue
		
		var monster_id: String = _captured_monsters[i]
		var md: Dictionary = _get_monster_data(monster_id)
		if md.is_empty():
			continue
		
		var is_hovered := (_hovered_monster_index == i)
		
		# 背景
		var elem_color: Color = _get_element_color(md.get("element", ""))
		var bg_color := C["bg_card"]
		var border_color := elem_color
		if is_hovered:
			bg_color = C["in_team_bg"]
			border_color = C["gold"]
		
		_draw_rounded_rect(card_x, card_y, LIST_ITEM_W, LIST_ITEM_H, 6.0, bg_color)
		_draw_rounded_rect_outline(card_x, card_y, LIST_ITEM_W, LIST_ITEM_H, 6.0, border_color, 2.0)
		
		# 怪物图标
		_draw_text(font, md.get("emoji", "?"), card_x + LIST_ITEM_W / 2.0, card_y + 30.0, C["text_primary"], 24.0)
		
		# 名字
		var name: String = md.get("name", "?")
		if name.length() > 5:
			name = name.substr(0, 5)
		_draw_text(font, name, card_x + LIST_ITEM_W / 2.0, card_y + 50.0, C["text_primary"], 10.0)
		
		# 等级
		var lvl: int = _get_real_level(monster_id)
		_draw_text(font, "Lv.%d" % lvl, card_x + LIST_ITEM_W / 2.0, card_y + 63.0, C["text_muted"], 9.0)
		
		# 属性标签
		var elem: String = md.get("element", "fire")
		var elem_color_bg: Color = _get_element_color(elem)
		_draw_rounded_rect(card_x + 5.0, card_y + 73.0, 24.0, 12.0, 3.0, elem_color_bg)
		_draw_text(font, _get_element_name(elem), card_x + 17.0, card_y + 80.0, C["white"], 8.0)

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
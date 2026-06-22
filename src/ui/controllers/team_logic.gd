# team_logic.gd - 队伍编成界面的旧脚本逻辑父类
# 源文件: js/ui/sceneTeamSetup.js
# 移植: _draw() 绘制 + _gui_input 交互
class_name SceneTeam
extends Control

const PROJECT_ROUND_FONT: Font = preload("res://assets/fonts/jf-openhuninn-2.1.ttf")
const EcologyBondRulesScript = preload("res://src/core/ecology_bond_rules.gd")
const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const MonsterServiceScript = preload("res://src/core/monster_service.gd")
const MonsterDBScript = preload("res://src/data/monster_db.gd")
const LeaderSkillDBScript = preload("res://src/data/leader_skill_db.gd")

# === 常量 ===
const DESIGN_W := 375.0
const DESIGN_H := 667.0
const MARGIN := 15.0
const LIST_PANEL_RECT := Rect2(10.0, 325.0, 355.0, 276.0)
const LIST_START_Y := 377.0
const LIST_ITEM_W := 74.0
const LIST_ITEM_H := 84.0
const LIST_GAP := 11.0
const LIST_COLS := 4
const LIST_ROWS := 2
const LIST_PAGE_SIZE := LIST_COLS * LIST_ROWS
const FILTER_ORDER := ["all", "fire", "water", "grass", "thunder", "light"]
const SORT_OPTIONS := [
	{"id": "level", "label": "等级"},
	{"id": "power", "label": "战力"},
	{"id": "rarity", "label": "稀有度"}
]

const TEAM_ASSETS := {
	"bg": "res://assets/images/ui/backgrounds/team_new_bg_team_hall.png",
	"back_button": "res://assets/images/ui/buttons/team_ui_back_button.png",
	"header": "res://assets/images/ui/bars/team_ui_header_bar.png",
	"help_button": "res://assets/images/ui/buttons/team_ui_help_button.png",
	"leader_card": "res://assets/images/ui/cards/team_ui_leader_card.png",
	"member_card": "res://assets/images/ui/cards/team_ui_member_card.png",
	"member_card_alt": "res://assets/images/ui/cards/team_ui_member_card_alt.png",
	"power_banner": "res://assets/images/ui/panels/team_ui_power_banner.png",
	"leader_skill_banner": "res://assets/images/ui/panels/team_ui_leader_skill_banner.png",
	"filter_tab_selected": "res://assets/images/ui/buttons/team_ui_filter_tab_selected.png",
	"filter_tab_normal": "res://assets/images/ui/buttons/team_ui_filter_tab_normal.png",
	"sort_dropdown": "res://assets/images/ui/buttons/team_ui_sort_dropdown.png",
	"roster_card": "res://assets/images/ui/cards/team_ui_roster_card.png",
	"roster_card_selected": "res://assets/images/ui/cards/team_ui_roster_card_selected.png",
	"empty_slot": "res://assets/images/ui/slots/team_ui_empty_slot.png",
	"btn_cancel": "res://assets/images/ui/buttons/team_ui_btn_cancel.png",
	"btn_save": "res://assets/images/ui/buttons/team_ui_btn_save.png",
	"page_button": "res://assets/images/ui/buttons/stage_ui_arrow_button.png",
	"page_prev": "res://assets/images/ui/buttons/stage_icon_prev_arrow.png",
	"page_next": "res://assets/images/ui/buttons/stage_icon_next_arrow.png",
}

const ELEMENT_ICON_ASSETS := {
	"fire": "res://assets/images/ui/elements/element_fire.png",
	"water": "res://assets/images/ui/elements/element_water.png",
	"grass": "res://assets/images/ui/elements/element_grass.png",
	"thunder": "res://assets/images/ui/elements/element_thunder.png",
	"light": "res://assets/images/ui/elements/element_light.png",
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
var _roster_page: int = 0
var _captured_monsters: Array = []
var _active_filter: String = "all"
var _sort_option: int = 0

# 动画状态
var _anim_state: Dictionary = {
	"show_guide": false,
	"guide_timer": 0.0,
	"assign_pop_scale": 1.0,
	"assign_pop_target": "",
	"slot_glow_phase": 0.0
}

var _show_confirm: bool = false
var _show_help: bool = false

# 按钮区域
var _back_btn: Rect2 = Rect2(12.0, 10.0, 52.0, 48.0)
var _help_btn: Rect2 = Rect2(DESIGN_W - 64.0, 10.0, 52.0, 48.0)
var _save_btn: Rect2 = Rect2()
var _cancel_btn: Rect2 = Rect2()
var _filter_all_btn: Rect2 = Rect2()
var _filter_cycle_btn: Rect2 = Rect2()
var _sort_btn: Rect2 = Rect2()
var _roster_prev_btn: Rect2 = Rect2()
var _roster_next_btn: Rect2 = Rect2()

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
	_prime_texture_cache()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_slots_layout()

func _process(delta: float) -> void:
	_time_acc += delta
	var a := _anim_state
	var needs_redraw := false
	if bool(a["show_guide"]):
		a["guide_timer"] += delta
		needs_redraw = true
	if not _selected_slot.is_empty():
		a["slot_glow_phase"] += delta * 4.0
		needs_redraw = true
	
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
		needs_redraw = true

	if needs_redraw:
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
	
	_roster_page = 0
	_selected_slot = ""
	_hovered_slot = ""
	_hovered_monster_index = -1
	_active_filter = "all"
	_sort_option = 0
	
	_captured_monsters = _get_captured_monsters()
	_anim_state["show_guide"] = _captured_monsters.is_empty()
	_show_confirm = false
	_show_help = false
	_update_slots_layout()
	queue_redraw()

static func warm_assets() -> void:
	for path in TEAM_ASSETS.values():
		ResourceLoader.load(str(path), "", ResourceLoader.CACHE_MODE_REUSE)
	for path in ELEMENT_ICON_ASSETS.values():
		ResourceLoader.load(str(path), "", ResourceLoader.CACHE_MODE_REUSE)
	for monster_id in ["monster_001", "monster_002", "monster_003"]:
		var path := MonsterArtDBScript.get_art_path(monster_id, "team")
		if not path.is_empty():
			ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)

func _prime_texture_cache() -> void:
	for path in TEAM_ASSETS.values():
		_get_texture(str(path))
	for path in ELEMENT_ICON_ASSETS.values():
		_get_texture(str(path))

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
	return MonsterDBScript.get_monster(_get_monster_id(monster_id))

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
		total += _calc_battle_power(stats)
	return total

func _calc_stats(monster_id: String, level: int) -> Dictionary:
	if _storage and _storage.has_method("get_instance_stats") and not _storage.get_monster_instance(monster_id).is_empty():
		return _storage.get_instance_stats(monster_id)
	return MonsterDBScript.get_monster_stats(_get_monster_id(monster_id), level, _get_nature(monster_id))


func _calc_battle_power(stats: Dictionary) -> int:
	return int(stats.get("hp", 0)) + int(stats.get("atk", 0)) + int(stats.get("def", 0))

func _get_catchup_state(instance_id: String) -> Dictionary:
	if _storage and _storage.has_method("get_instance_catchup_state") and not _storage.get_monster_instance(instance_id).is_empty():
		return _storage.get_instance_catchup_state(instance_id)
	return {"enabled": false, "label": ""}

func _get_roster_page_count() -> int:
	return maxi(1, ceili(float(_get_display_monsters().size()) / float(LIST_PAGE_SIZE)))

func _clamp_roster_page() -> void:
	_roster_page = clampi(_roster_page, 0, _get_roster_page_count() - 1)

func _get_display_monsters() -> Array:
	var result: Array = []
	for instance in _captured_monsters:
		if not (instance is Dictionary):
			continue
		var monster_id := _get_monster_id(instance)
		var md := _get_monster_data(monster_id)
		if md.is_empty():
			continue
		var element := str(md.get("boardAffinity", md.get("element", "")))
		if _active_filter != "all" and element != _active_filter:
			continue
		result.append(instance)
	var sort_id := str(SORT_OPTIONS[_sort_option]["id"])
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := _get_sort_score(a, sort_id)
		var score_b := _get_sort_score(b, sort_id)
		if score_a == score_b:
			return _get_instance_id(a) < _get_instance_id(b)
		return score_a > score_b
	)
	return result

func _get_sort_score(instance: Dictionary, sort_id: String) -> int:
	var instance_id := _get_instance_id(instance)
	var md := _get_monster_data(_get_monster_id(instance))
	if sort_id == "rarity":
		return int(md.get("rarity", 1))
	if sort_id == "power":
		var stats := _calc_stats(instance_id, _get_real_level(instance_id))
		return _calc_battle_power(stats)
	return _get_real_level(instance_id)

func _select_filter(filter_id: String) -> void:
	_active_filter = filter_id
	_roster_page = 0
	queue_redraw()

func _cycle_element_filter() -> void:
	var index := FILTER_ORDER.find(_active_filter)
	if index < 0:
		index = 0
	index = 1 if index == 0 else index + 1
	if index >= FILTER_ORDER.size():
		index = 1
	_select_filter(str(FILTER_ORDER[index]))

func _cycle_sort_option() -> void:
	_sort_option = (_sort_option + 1) % SORT_OPTIONS.size()
	_roster_page = 0
	queue_redraw()

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
	var start_y := 67.0
	
	# 队长槽
	var leader_rect := Rect2(12.0, start_y, 125.0, 181.0)
	# 成员1槽
	var member1_rect := Rect2(141.0, start_y + 3.0, 108.0, 178.0)
	# 成员2槽
	var member2_rect := Rect2(253.0, start_y + 3.0, 108.0, 178.0)
	
	_slots = [
		{"key": "leader", "rect": leader_rect, "label": "队长"},
		{"key": "member1", "rect": member1_rect, "label": "成员1"},
		{"key": "member2", "rect": member2_rect, "label": "成员2"}
	]
	
	# 按钮区域
	_filter_all_btn = Rect2(18.0, 331.0, 62.0, 44.0)
	_filter_cycle_btn = Rect2(86.0, 331.0, 124.0, 44.0)
	_sort_btn = Rect2(244.0, 331.0, 108.0, 44.0)
	_roster_prev_btn = Rect2(112.0, 555.0, 46.0, 44.0)
	_roster_next_btn = Rect2(217.0, 555.0, 46.0, 44.0)
	_cancel_btn = Rect2(18.0, 610.0, 165.0, 48.0)
	_save_btn = Rect2(192.0, 610.0, 165.0, 48.0)

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

func _on_tap(x: float, y: float) -> void:
	var pos := Vector2(x, y)
	
	if _show_confirm:
		_handle_confirm_tap(pos)
		return

	if _show_help:
		_show_help = false
		queue_redraw()
		return
	
	# 返回按钮
	if _point_in_rect(pos, _back_btn):
		_change_to_scene("main")
		return

	if _point_in_rect(pos, _help_btn):
		_show_help = true
		queue_redraw()
		return
	
	# 保存按钮
	if _point_in_rect(pos, _save_btn):
		_save_team()
		_change_to_scene("main")
		return
	
	# 取消按钮
	if _point_in_rect(pos, _cancel_btn):
		_show_confirm = true
		queue_redraw()
		return

	if _point_in_rect(pos, _filter_all_btn):
		_select_filter("all")
		return

	if _point_in_rect(pos, _filter_cycle_btn):
		_cycle_element_filter()
		return

	if _point_in_rect(pos, _sort_btn):
		_cycle_sort_option()
		return

	if _point_in_rect(pos, _roster_prev_btn):
		_turn_roster_page(-1)
		return

	if _point_in_rect(pos, _roster_next_btn):
		_turn_roster_page(1)
		return
	
	# 槽位点击
	for s: Dictionary in _slots:
		if _point_in_rect(pos, s["rect"]):
			_handle_slot_tap(s["key"])
			return
	
	# 精灵列表点击
	var monster_idx := _get_monster_index_at_pos(pos)
	var visible_monsters := _get_display_monsters()
	if monster_idx >= 0 and monster_idx < visible_monsters.size():
		_assign_to_slot(_get_instance_id(visible_monsters[monster_idx]))
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
		queue_redraw()
	elif not _point_in_rect(pos, dialog_rect):
		_show_confirm = false
		queue_redraw()

func _handle_slot_tap(slot_key: String) -> void:
	if _team.get(slot_key) != null:
		# 有精灵 → 清空
		_team[slot_key] = null
		if _selected_slot == slot_key:
			_selected_slot = ""
	else:
		# 空槽位 → 切换选中
		_selected_slot = "" if _selected_slot == slot_key else slot_key
	queue_redraw()

func _turn_roster_page(direction: int) -> void:
	if direction == 0:
		return
	var page_count := _get_roster_page_count()
	if page_count <= 1:
		_roster_page = 0
		return
	_roster_page = clampi(_roster_page + direction, 0, page_count - 1)
	queue_redraw()

func _assign_to_slot(monster_id: String) -> void:
	if _selected_slot.is_empty():
		# 自动填入第一个空槽位
		for key in ["leader", "member1", "member2"]:
			if _team[key] == null:
					_team[key] = monster_id
					_trigger_assign_pop(key)
					queue_redraw()
					return
		# 队伍满了，替换队长
		_team["leader"] = monster_id
		_trigger_assign_pop("leader")
	else:
		# 替换目标槽位
		var existing: Variant = _team[_selected_slot]
		_team[_selected_slot] = monster_id
		# 防止重复：如果其他槽已有这个精灵，交换
		for key in ["leader", "member1", "member2"]:
			if key != _selected_slot and _team[key] == monster_id:
				_team[key] = existing
				break
		_selected_slot = ""
	queue_redraw()

func _get_monster_index_at_pos(pos: Vector2) -> int:
	var list_x := (DESIGN_W - (LIST_COLS * LIST_ITEM_W + (LIST_COLS - 1) * LIST_GAP)) / 2.0
	var list_y := LIST_START_Y
	var list_h := LIST_ROWS * LIST_ITEM_H + (LIST_ROWS - 1) * LIST_GAP
	if pos.y < list_y or pos.y > list_y + list_h:
		return -1
	
	var rel_x := pos.x - list_x
	var rel_y := pos.y - list_y
	
	if rel_x < 0.0:
		return -1
	
	var stride_x := LIST_ITEM_W + LIST_GAP
	var stride_y := LIST_ITEM_H + LIST_GAP
	var col := int(floor(rel_x / stride_x))
	var row := int(floor(rel_y / stride_y))
	if fmod(rel_x, stride_x) > LIST_ITEM_W or fmod(rel_y, stride_y) > LIST_ITEM_H:
		return -1
	
	if col < 0 or col >= LIST_COLS or row < 0 or row >= LIST_ROWS:
		return -1
	
	return _roster_page * LIST_PAGE_SIZE + row * LIST_COLS + col

# ==================== 绘制 ====================

func _draw() -> void:
	var font := PROJECT_ROUND_FONT
	var t := _time_acc
	
	_clamp_roster_page()

	# 背景
	_draw_texture_cover(_tex("bg"), Rect2(0, 0, DESIGN_W, DESIGN_H))
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.05, 0.12, 0.45))
	
	# 标题
	_draw_texture_fit(_tex("header"), Rect2(78.0, 13.0, 220.0, 42.0))
	_draw_text(font, "队伍编成", DESIGN_W / 2.0, 44.0, C["text_primary"], 24.0)
	
	# 返回按钮
	_draw_texture_fit(_tex("back_button"), _back_btn)
	_draw_texture_fit(_tex("help_button"), _help_btn)
	
	# 空引导提示
	if _anim_state["show_guide"]:
		var alpha := 0.6 + sin(t * 3.0) * 0.4
		_draw_text(font, "点击开始冒险，赢取你的第一只精灵", DESIGN_W / 2.0, 63.0, Color(C["gold"].r, C["gold"].g, C["gold"].b, alpha), 12.0)
	
	# 渲染槽位
	for s: Dictionary in _slots:
		_draw_slot(font, s, t)

	_draw_team_summary(font)
	_draw_bond_summary(font)
	_draw_roster_toolbar(font)
	
	# 渲染精灵列表
	_draw_monster_list(font, t)
	
	# 底部主操作：不展示尚未实现的分解入口。
	_draw_button(_cancel_btn, "取消", "btn_cancel")
	_draw_button(_save_btn, "保存队伍", "btn_save")
	
	# 确认弹窗
	if _show_confirm:
		_draw_confirm_dialog(font)
	elif _show_help:
		_draw_help_dialog(font)

func _draw_text(font: Font, text: String, x: float, y: float, color: Color, size: float) -> void:
	draw_string(font, Vector2(x - 100.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, size, color)

func _draw_text_in_rect(font: Font, text: String, rect: Rect2, color: Color, max_size: float, min_size: float = 8.0) -> void:
	var font_size := max_size
	while font_size > min_size:
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(font_size))
		if text_size.x <= rect.size.x:
			break
		font_size -= 1.0
	var baseline_y := rect.position.y + rect.size.y * 0.5 + font_size * 0.35
	draw_string(font, Vector2(rect.position.x, baseline_y), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, color)

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
	_draw_text(PROJECT_ROUND_FONT, text, rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y / 2.0 + 7.0, C["white"], 18.0)

func _draw_team_summary(font: Font) -> void:
	var power := _calc_team_power()
	_draw_texture_three_slice(_tex("power_banner"), Rect2(12.0, 252.0, 135.0, 45.0), 126.0, 32.0)
	_draw_text(font, "%d" % power, 96.0, 282.0, C["gold"] if power > 0 else C["text_muted"], 22.0)

	_draw_texture_three_slice(_tex("leader_skill_banner"), Rect2(150.0, 252.0, 213.0, 45.0), 126.0, 32.0)
	var leader_value: Variant = _team.get("leader", null)
	var leader_id := "" if leader_value == null else str(leader_value)
	var skill_text := "未设置队长技能"
	var skill_color := C["text_muted"]
	if not leader_id.is_empty():
		var md := _get_monster_data(leader_id)
		var skill_id: String = md.get("leaderSkill", md.get("leader_skill", ""))
		if not skill_id.is_empty():
			if LeaderSkillDBScript:
				var skill = LeaderSkillDBScript.get_leader_skill(skill_id)
				if skill:
					skill_text = "%s：%s" % [skill.get("name", "队长技"), skill.get("desc", "")]
					skill_color = C["gold"]
	_draw_text_in_rect(font, skill_text, Rect2(196.0, 263.0, 158.0, 24.0), skill_color, 12.0, 10.0)

func _draw_bond_summary(font: Font) -> void:
	var branches: Array = EcologyBondRulesScript.calc_team_bond_branches(_get_team_units())
	var bond: Dictionary = branches[0] if not branches.is_empty() else {}
	var rect := Rect2(12.0, 301.0, 351.0, 21.0)
	var active := str(bond.get("status", "hint")) == "active"
	var color := Color(0.08, 0.24, 0.16, 0.88) if active else Color(0.08, 0.11, 0.20, 0.88)
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 7.0, color)
	_draw_rounded_rect_outline(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 7.0, C["gold"] if active else Color(0.22, 0.36, 0.62, 0.82), 1.0)
	var title := str(bond.get("name", "羁绊"))
	var summary := str(bond.get("summary", "选择精灵查看羁绊方向。"))
	_draw_text_in_rect(font, "分支：%s" % title, Rect2(rect.position.x + 8.0, rect.position.y + 1.0, 104.0, 19.0), C["gold"] if active else C["text_secondary"], 11.0, 10.0)
	_draw_text_in_rect(font, summary, Rect2(rect.position.x + 112.0, rect.position.y + 1.0, 231.0, 19.0), C["text_primary"] if active else C["text_muted"], 10.0, 9.0)

func _get_team_monster_defs() -> Array:
	var result: Array = []
	for key in ["leader", "member1", "member2"]:
		var value: Variant = _team.get(key, null)
		var ref_id := "" if value == null else str(value)
		if ref_id.is_empty():
			continue
		var md := _get_monster_data(ref_id)
		if not md.is_empty():
			result.append(md)
	return result

func _get_team_units() -> Array:
	var result: Array = []
	for key in ["leader", "member1", "member2"]:
		var value: Variant = _team.get(key, null)
		var ref_id := "" if value == null else str(value)
		if ref_id.is_empty():
			continue
		if _storage and _storage.has_method("get_monster_instance") and not _storage.get_monster_instance(ref_id).is_empty():
			var view: Dictionary = MonsterServiceScript.get_instance_view(ref_id, _storage)
			if not view.is_empty():
				result.append(view)
				continue
		var md := _get_monster_data(ref_id)
		if not md.is_empty():
			result.append(md)
	return result

func _draw_roster_toolbar(font: Font) -> void:
	_draw_rounded_rect(LIST_PANEL_RECT.position.x, LIST_PANEL_RECT.position.y, LIST_PANEL_RECT.size.x, LIST_PANEL_RECT.size.y, 10.0, Color(0.03, 0.08, 0.16, 0.90))
	_draw_rounded_rect_outline(LIST_PANEL_RECT.position.x, LIST_PANEL_RECT.position.y, LIST_PANEL_RECT.size.x, LIST_PANEL_RECT.size.y, 10.0, Color(0.22, 0.36, 0.62, 0.92), 2.0)
	_draw_texture_fit(_tex("filter_tab_selected" if _active_filter == "all" else "filter_tab_normal"), _filter_all_btn)
	_draw_text(font, "全部", _filter_all_btn.get_center().x, _filter_all_btn.position.y + 28.0, C["white"], 13.0)
	_draw_texture_fit(_tex("filter_tab_selected" if _active_filter != "all" else "filter_tab_normal"), _filter_cycle_btn)
	var filter_label := "属性筛选"
	if _active_filter != "all":
		_draw_element_icon(_active_filter, Rect2(_filter_cycle_btn.position.x + 11.0, _filter_cycle_btn.position.y + 9.0, 26.0, 26.0))
		filter_label = "%s系" % _get_element_name(_active_filter)
	_draw_text(font, filter_label, _filter_cycle_btn.position.x + 76.0, _filter_cycle_btn.position.y + 28.0, C["white"], 13.0)
	_draw_texture_fit(_tex("sort_dropdown"), _sort_btn)
	_draw_text(font, str(SORT_OPTIONS[_sort_option]["label"]), _sort_btn.position.x + 48.0, _sort_btn.position.y + 28.0, C["text_secondary"], 13.0)

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
			var face_size := 78.0 if key == "leader" else 66.0
			_draw_monster_portrait(monster_id, Rect2(cx - face_size / 2.0, new_y + 22.0, face_size, face_size))

			var lvl: int = _get_real_level(monster_id)
			var unit_line := "%s  Lv.%d" % [md.get("name", "未知"), lvl]
			_draw_text(font, unit_line, cx, new_y + (99.0 if key == "leader" else 100.0), C["text_primary"], 11.0)
			var catchup_state := _get_catchup_state(monster_id)
			if bool(catchup_state.get("enabled", false)):
				_draw_rounded_rect(cx - 35.0, new_y + 75.0, 70.0, 15.0, 6.0, Color(0.10, 0.45, 0.35, 0.86))
				_draw_text(font, str(catchup_state.get("label", "")), cx, new_y + 86.0, Color(0.75, 1.0, 0.72), 9.0)

			# 清理卡框未投入功能的底部空槽装饰，为角色标识保留干净底栏。
			draw_rect(Rect2(new_x + 4.0, new_y + new_h - 30.0, new_w - 8.0, 25.0), Color(0.02, 0.06, 0.14, 1.0))
			var stats: Dictionary = _calc_stats(monster_id, lvl)
			_draw_stat_pair(font, "hp", int(stats.get("hp", 0)), new_x + 8.0, new_y + 126.0)
			_draw_stat_pair(font, "atk", int(stats.get("atk", 0)), new_x + new_w * 0.51, new_y + 126.0)
			_draw_stat_pair(font, "def", int(stats.get("def", 0)), new_x + 8.0, new_y + 147.0)
			_draw_stat_pair(font, "spd", int(stats.get("spd", 0)), new_x + new_w * 0.51, new_y + 147.0)
		else:
			_draw_text(font, label, cx, new_y + new_h / 2.0, C["text_muted"], 9.0)
	else:
		# 空槽位
		var slot_label_text := "选择精灵" if is_selected else label
		var text_color := C["gold"] if is_selected else C["text_muted"]
		_draw_texture_contain(_tex("empty_slot"), Rect2(cx - 29.0, new_y + 30.0, 58.0, 68.0), 0.55)
		_draw_text(font, slot_label_text, cx, new_y + 116.0, text_color, 12.0)
	_draw_text(font, label, cx, new_y + new_h - 8.0, C["text_muted"], 10.0)

func _draw_rounded_rect_outline(x: float, y: float, w: float, h: float, r: float, color: Color, line_w: float) -> void:
	# 用粗线模拟 strokeRect
	draw_rect(Rect2(x, y, w, line_w), color)
	draw_rect(Rect2(x, y + h - line_w, w, line_w), color)
	draw_rect(Rect2(x, y, line_w, h), color)
	draw_rect(Rect2(x + w - line_w, y, line_w, h), color)

func _draw_monster_list(font: Font, t: float) -> void:
	var list_x := (DESIGN_W - (LIST_COLS * LIST_ITEM_W + (LIST_COLS - 1) * LIST_GAP)) / 2.0
	var list_y := LIST_START_Y
	var visible_monsters := _get_display_monsters()
	var page_start := _roster_page * LIST_PAGE_SIZE
	var page_end := mini(visible_monsters.size(), page_start + LIST_PAGE_SIZE)
	for i in range(page_start, page_end):
		var local_index := i - page_start
		var row := int(local_index / LIST_COLS)
		var col := local_index % LIST_COLS
		var card_x := list_x + col * (LIST_ITEM_W + LIST_GAP)
		var card_y := list_y + row * (LIST_ITEM_H + LIST_GAP)
		
		var instance: Dictionary = visible_monsters[i]
		var instance_id := _get_instance_id(instance)
		var monster_id := _get_monster_id(instance)
		var md: Dictionary = _get_monster_data(monster_id)
		if md.is_empty():
			continue

		var is_hovered := (_hovered_monster_index == i)
		var in_team := _team.values().has(instance_id)
		var card_key := "roster_card_selected" if in_team or is_hovered else "roster_card"
		var card_tex := _tex(card_key)
		_draw_texture_fit(card_tex, Rect2(card_x, card_y, LIST_ITEM_W, LIST_ITEM_H))

		# 精灵头像
		_draw_monster_portrait(monster_id, Rect2(card_x + 16.0, card_y + 6.0, 42.0, 42.0))

		# 用卡片自身的干净底纹替换装饰暗星，不添加会切断边框的实色底。
		_draw_roster_footer_patch(card_tex, Rect2(card_x, card_y, LIST_ITEM_W, LIST_ITEM_H))

		# 名字
		var name: String = md.get("name", "?")
		if name.length() > 5:
			name = name.substr(0, 5)
		_draw_text(font, name, card_x + LIST_ITEM_W / 2.0, card_y + 58.0, C["text_primary"], 11.0)

		# 等级
		var lvl: int = _get_real_level(instance_id)
		var catchup_state := _get_catchup_state(instance_id)
		if bool(catchup_state.get("enabled", false)):
			_draw_rounded_rect(card_x + 6.0, card_y + 64.0, LIST_ITEM_W - 12.0, 16.0, 5.0, Color(0.10, 0.45, 0.35, 0.92))
			_draw_text(font, str(catchup_state.get("label", "")), card_x + LIST_ITEM_W / 2.0, card_y + 76.0, Color(0.75, 1.0, 0.72), 9.0)
		else:
			var rarity := int(md.get("rarity", 1))
			_draw_text(font, "Lv.%d  %d★" % [lvl, rarity], card_x + LIST_ITEM_W / 2.0, card_y + 74.0, C["gold"], 10.0)

		# 属性角标
		var elem: String = md.get("boardAffinity", md.get("element", "fire"))
		_draw_element_icon(elem, Rect2(card_x + 5.0, card_y + 5.0, 18.0, 18.0))
	if visible_monsters.is_empty():
		var empty_text := "暂无可编队精灵" if _active_filter == "all" else "当前属性没有精灵"
		_draw_text(font, empty_text, DESIGN_W / 2.0, LIST_START_Y + 80.0, C["text_muted"], 14.0)
	_draw_roster_page_controls(font)

func _draw_roster_page_controls(font: Font) -> void:
	var page_count := _get_roster_page_count()
	var prev_opacity := 1.0 if _roster_page > 0 else 0.42
	var next_opacity := 1.0 if _roster_page < page_count - 1 else 0.42
	_draw_texture_contain(_tex("page_button"), _roster_prev_btn, prev_opacity)
	_draw_texture_contain(_tex("page_prev"), _roster_prev_btn.grow(-10.0), prev_opacity)
	_draw_texture_contain(_tex("page_button"), _roster_next_btn, next_opacity)
	_draw_texture_contain(_tex("page_next"), _roster_next_btn.grow(-10.0), next_opacity)
	_draw_text(font, "%d/%d" % [_roster_page + 1, page_count], DESIGN_W / 2.0, 581.0, C["text_secondary"], 13.0)
	var dot_gap := 10.0
	var start_x := DESIGN_W / 2.0 - float(page_count - 1) * dot_gap * 0.5
	for i in range(page_count):
		var color := C["gold"] if i == _roster_page else Color(0.36, 0.48, 0.74, 0.85)
		draw_circle(Vector2(start_x + float(i) * dot_gap, 565.0), 2.8 if i == _roster_page else 2.0, color)

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

func _draw_help_dialog(font: Font) -> void:
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.0, 0.0, 0.0, 0.66))
	var rect := Rect2(28.0, 206.0, 319.0, 242.0)
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 12.0, Color(0.04, 0.09, 0.19, 0.98))
	_draw_rounded_rect_outline(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 12.0, Color(0.42, 0.64, 1.0, 0.92), 2.0)
	_draw_text(font, "编队说明", DESIGN_W / 2.0, rect.position.y + 38.0, C["white"], 20.0)
	_draw_text_in_rect(font, "点击下方精灵，自动填入空位。", Rect2(48.0, 258.0, 279.0, 26.0), C["text_primary"], 14.0, 12.0)
	_draw_text_in_rect(font, "先点上方槽位，可指定替换位置。", Rect2(48.0, 284.0, 279.0, 26.0), C["text_primary"], 14.0, 12.0)
	_draw_text_in_rect(font, "属性筛选可切换元素。", Rect2(48.0, 325.0, 279.0, 24.0), C["text_secondary"], 13.0, 12.0)
	_draw_text_in_rect(font, "排序可切换等级、战力、稀有度。", Rect2(48.0, 349.0, 279.0, 24.0), C["text_secondary"], 13.0, 12.0)
	var close_btn := Rect2(96.0, 385.0, 183.0, 46.0)
	_draw_texture_fit(_tex("btn_save"), close_btn)
	_draw_text(font, "知道了", DESIGN_W / 2.0, 415.0, C["white"], 16.0)

func _draw_stat_pair(font: Font, _stat_key: String, value: int, x: float, y: float) -> void:
	# 槽位卡框已内置属性图标，避免重复叠绘造成重影。
	draw_string(font, Vector2(x + 16.0, y), "%d" % value, HORIZONTAL_ALIGNMENT_LEFT, 44.0, 10.0, C["text_secondary"])

func _draw_element_icon(element: String, rect: Rect2) -> void:
	var path: String = ELEMENT_ICON_ASSETS.get(element, "")
	if path.is_empty():
		_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, rect.size.x / 2.0, _get_element_color(element))
		return
	_draw_texture_contain(_get_texture(path), rect)

func _draw_monster_portrait(monster_id: String, rect: Rect2) -> void:
	var path: String = MonsterArtDBScript.get_art_path(_get_monster_id(monster_id), "team")
	var tex := _get_texture(path)
	if tex:
		_draw_texture_contain(tex, rect)
		return
	var md := _get_monster_data(monster_id)
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 8.0, Color(0.04, 0.07, 0.15, 0.82))
	_draw_text(PROJECT_ROUND_FONT, md.get("emoji", "?"), rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y * 0.60, C["white"], minf(rect.size.x * 0.45, 22.0))

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

func _draw_texture_three_slice(tex: Texture2D, rect: Rect2, left_src_w: float, right_src_w: float, opacity: float = 1.0) -> void:
	if tex == null or rect.size.y <= 0.0:
		return
	var tex_size := tex.get_size()
	var scale := rect.size.y / tex_size.y
	var left_w := left_src_w * scale
	var right_w := right_src_w * scale
	var center_w := maxf(0.0, rect.size.x - left_w - right_w)
	var center_src_w := tex_size.x - left_src_w - right_src_w
	var modulate := Color(1.0, 1.0, 1.0, opacity)
	draw_texture_rect_region(tex, Rect2(rect.position, Vector2(left_w, rect.size.y)), Rect2(0.0, 0.0, left_src_w, tex_size.y), modulate)
	draw_texture_rect_region(tex, Rect2(rect.position.x + left_w, rect.position.y, center_w, rect.size.y), Rect2(left_src_w, 0.0, center_src_w, tex_size.y), modulate)
	draw_texture_rect_region(tex, Rect2(rect.end.x - right_w, rect.position.y, right_w, rect.size.y), Rect2(tex_size.x - right_src_w, 0.0, right_src_w, tex_size.y), modulate)

func _draw_roster_footer_patch(tex: Texture2D, card_rect: Rect2) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	var target := Rect2(card_rect.position.x + 7.0, card_rect.position.y + 61.0, card_rect.size.x - 14.0, 18.0)
	var source := Rect2(tex_size.x * 0.18, tex_size.y * 0.35, tex_size.x * 0.64, tex_size.y * 0.22)
	draw_texture_rect_region(tex, target, source)

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
		get_node("/root/SceneManager").switch_scene(scene_name, {}, "quick")
	elif has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm and gm.has_node("scene_manager"):
			gm.scene_manager.switch_scene(scene_name, {}, "quick")

func destroy() -> void:
	pass

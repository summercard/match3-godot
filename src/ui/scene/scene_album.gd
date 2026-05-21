# scene_album.gd - 怪物图鉴场景
# 美术包装：image-2 拆分资产 + Canvas 绘制
class_name SceneAlbum
extends Control

const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")

const DESIGN_W: float = 375.0
const DESIGN_H: float = 667.0
const COLS: int = 3
const CARD_W: float = 104.0
const CARD_H: float = 112.0
const CARD_GAP: float = 11.0
const GRID_X: float = 20.0
const GRID_Y: float = 118.0
const DETAIL_Y: float = 352.0
const DETAIL_H: float = 242.0
const BOTTOM_TAB_Y: float = 609.0
const DEBUG_UNLOCK_ALL_ALBUM_FOR_QA: bool = true

const ALBUM_ASSETS := {
	"bg": "res://assets/images/main/main_lobby_bg.png",
	"header": "res://assets/images/album/ui_header_plaque.png",
	"back_button": "res://assets/images/album/ui_back_button.png",
	"filter_selected": "res://assets/images/album/ui_filter_tab_selected.png",
	"filter_normal": "res://assets/images/album/ui_filter_tab_normal.png",
	"filter_disabled": "res://assets/images/album/ui_filter_tab_disabled.png",
	"card_green": "res://assets/images/album/ui_roster_card_green.png",
	"card_blue": "res://assets/images/album/ui_roster_card_blue.png",
	"card_locked": "res://assets/images/album/ui_roster_card_locked.png",
	"detail_panel": "res://assets/images/album/ui_detail_panel.png",
	"portrait_stage": "res://assets/images/album/ui_portrait_stage.png",
	"stat_row": "res://assets/images/album/ui_stat_row.png",
	"skill_panel": "res://assets/images/album/ui_skill_panel.png",
	"evolution_strip": "res://assets/images/album/ui_evolution_strip.png",
	"btn_primary": "res://assets/images/album/ui_btn_primary_gold.png",
	"btn_secondary": "res://assets/images/album/ui_btn_secondary_blue.png",
	"bottom_tab_selected": "res://assets/images/album/ui_bottom_tab_selected.png",
	"bottom_tab_normal": "res://assets/images/album/ui_bottom_tab_normal.png",
	"icon_star_lit": "res://assets/images/album/icon_star_lit.png",
	"icon_star_dim": "res://assets/images/album/icon_star_dim.png",
	"icon_lock": "res://assets/images/album/icon_lock.png",
	"icon_album": "res://assets/images/album/icon_album_book.png",
	"icon_paw": "res://assets/images/album/icon_paw.png",
	"icon_favorite": "res://assets/images/album/icon_favorite.png",
	"icon_source": "res://assets/images/album/icon_source_scroll.png",
	"icon_evolution_arrows": "res://assets/images/album/icon_evolution_arrows.png",
	"fx_sparkle": "res://assets/images/album/fx_sparkle_cluster.png",
}

const ELEMENT_ICON_ASSETS := {
	"fire": "res://assets/images/album/icon_element_fire.png",
	"water": "res://assets/images/album/icon_element_water.png",
	"grass": "res://assets/images/album/icon_element_grass.png",
	"thunder": "res://assets/images/album/icon_element_thunder.png",
	"light": "res://assets/images/album/icon_element_light.png",
	"earth": "res://assets/images/album/icon_element_earth.png",
	"wind": "res://assets/images/album/icon_element_wind.png",
	"dark": "res://assets/images/album/icon_element_dark.png",
}

const C := {
	"bg": Color(0.04, 0.07, 0.15),
	"text": Color(1.0, 1.0, 1.0),
	"text_muted": Color(0.55, 0.60, 0.72),
	"gold": Color(1.0, 0.83, 0.12),
	"green": Color(0.42, 0.92, 0.34),
	"blue": Color(0.34, 0.70, 1.0),
	"danger": Color(1.0, 0.34, 0.24)
}

const ELEMENT_NAMES := {
	"all": "全部",
	"fire": "火",
	"water": "水",
	"grass": "草",
	"thunder": "雷",
	"light": "光",
	"earth": "土",
	"wind": "风",
	"dark": "暗",
	"ice": "冰",
	"void": "虚",
	"temporal": "时",
	"star": "星",
	"chaos": "混"
}

const ELEMENT_ORDER := ["all", "fire", "water", "grass", "thunder", "light", "earth", "wind", "dark"]
const ELEMENT_SORT_ORDER := ["fire", "water", "grass", "thunder", "light", "earth", "wind", "dark", "ice", "void", "temporal", "star", "chaos"]

var _storage: Node = null
var _all_monsters: Array = []
var _filtered_monsters: Array = []
var _captured_ids: Array = []
var _selected_element: String = "all"
var _selected_monster_id: String = ""
var _scroll_y: float = 0.0
var _max_scroll_y: float = 0.0
var _dragging: bool = false
var _last_y: float = 0.0
var _drag_start_y: float = 0.0
var _texture_cache: Dictionary = {}
var _time: float = 0.0

var _back_rect := Rect2(12.0, 12.0, 52.0, 52.0)
var _detail_close_rect := Rect2(286.0, DETAIL_Y + 194.0, 72.0, 36.0)
var _detail_evolve_rect := Rect2(126.0, DETAIL_Y + 194.0, 124.0, 36.0)
var _pokedex_cache: Dictionary = {}  # 缓存pokedex数据

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

func init(_data: Dictionary = {}) -> void:
	_storage = _root_node("SaveManager")
	_selected_element = "all"
	_selected_monster_id = ""
	_scroll_y = 0.0
	_load_data()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_last_y = event.position.y
			_drag_start_y = event.position.y
			_handle_tap(event.position)
		else:
			_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_last_y = event.position.y
			_drag_start_y = event.position.y
			_handle_tap(event.position)
		else:
			_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		_handle_drag(event.position.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_handle_drag(event.position.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_scroll_y = clampf(_scroll_y - 36.0, 0.0, _max_scroll_y)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_scroll_y = clampf(_scroll_y + 36.0, 0.0, _max_scroll_y)

func _handle_drag(y: float) -> void:
	if abs(y - _drag_start_y) < 8.0 and not _dragging:
		return
	var delta := _last_y - y
	if abs(delta) > 0.5:
		_scroll_y = clampf(_scroll_y + delta, 0.0, _max_scroll_y)
		_last_y = y

func _handle_tap(pos: Vector2) -> void:
	if _back_rect.has_point(pos):
		_go_back()
		return
	for i in range(ELEMENT_ORDER.size()):
		var rect := _filter_rect(i)
		if rect.has_point(pos):
			_selected_element = ELEMENT_ORDER[i]
			_selected_monster_id = ""
			_scroll_y = 0.0
			_apply_filter()
			return
	if not _selected_monster_id.is_empty():
		if _detail_close_rect.has_point(pos):
			_selected_monster_id = ""
			_apply_filter()
			return
	var idx := _monster_index_at(pos)
	if idx >= 0 and idx < _filtered_monsters.size():
		var monster: Dictionary = _filtered_monsters[idx]
		if _is_captured(monster.get("id", "")):
			_selected_monster_id = monster.get("id", "")
			_apply_filter()

func _load_data() -> void:
	var MonsterDB = load("res://src/data/monster_db.gd")
	_all_monsters = MonsterDB.get_all() if MonsterDB and MonsterDB.has_method("get_all") else []
	_all_monsters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	var player: Dictionary = _storage.load_player() if _storage and _storage.has_method("load_player") else {}
	if _storage and _storage.has_method("get_owned_species_ids"):
		_captured_ids = _storage.get_owned_species_ids()
	else:
		_captured_ids = player.get("captured", [])
	if DEBUG_UNLOCK_ALL_ALBUM_FOR_QA:
		_captured_ids = _all_monsters.map(func(monster: Dictionary) -> String: return str(monster.get("id", "")))
	_apply_filter()

func _apply_filter() -> void:
	_filtered_monsters = []
	if _selected_element == "all":
		_filtered_monsters = _all_monsters.duplicate(true)
		_filtered_monsters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ea := str(a.get("element", ""))
			var eb := str(b.get("element", ""))
			var ia := ELEMENT_SORT_ORDER.find(ea)
			var ib := ELEMENT_SORT_ORDER.find(eb)
			if ia < 0:
				ia = ELEMENT_SORT_ORDER.size()
			if ib < 0:
				ib = ELEMENT_SORT_ORDER.size()
			if ia == ib:
				return str(a.get("id", "")) < str(b.get("id", ""))
			return ia < ib
		)
	else:
		for monster: Dictionary in _all_monsters:
			if monster.get("element", "") == _selected_element:
				_filtered_monsters.append(monster)
	var rows := ceili(float(_filtered_monsters.size()) / float(COLS))
	var content_h := float(rows) * (CARD_H + CARD_GAP)
	var view_bottom := DETAIL_Y - 12.0 if not _selected_monster_id.is_empty() else BOTTOM_TAB_Y - 8.0
	_max_scroll_y = maxf(0.0, content_h - (view_bottom - GRID_Y))

func _draw() -> void:
	_draw_background()
	_draw_header()
	_draw_filters()
	_draw_grid()
	if not _selected_monster_id.is_empty():
		_draw_detail_panel()
	_draw_bottom_tabs()

func _draw_background() -> void:
	var bg := _tex(ALBUM_ASSETS["bg"])
	if bg:
		_draw_texture_cover(bg, Rect2(0.0, 0.0, DESIGN_W, DESIGN_H))
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.04, 0.10, 0.40))

func _draw_header() -> void:
	_draw_texture_fit(_tex(ALBUM_ASSETS["back_button"]), _back_rect)
	_draw_text("←", _back_rect.position.x + 26.0, _back_rect.position.y + 34.0, Color(0.95, 0.93, 0.78), 22.0)
	_draw_texture_fit(_tex(ALBUM_ASSETS["header"]), Rect2(90.0, 14.0, 196.0, 40.0))
	_draw_text("精灵图鉴", DESIGN_W / 2.0, 43.0, C["text"], 22.0, 220.0)
	_draw_stat_chip()

func _draw_stat_chip() -> void:
	var total := _all_monsters.size()
	var captured := _captured_ids.size()
	_draw_rounded_rect(276.0, 18.0, 85.0, 32.0, 6.0, Color(0.06, 0.10, 0.20, 0.84))
	_draw_stroke_rect(276.0, 18.0, 85.0, 32.0, 1.0, Color(0.26, 0.38, 0.62, 0.85))
	_draw_text("%d/%d" % [captured, total], 318.5, 39.0, C["gold"], 13.0, 80.0)

func _draw_filters() -> void:
	for i in range(ELEMENT_ORDER.size()):
		var el: String = ELEMENT_ORDER[i]
		var rect := _filter_rect(i)
		var selected := el == _selected_element
		_draw_texture_fit(_tex(ALBUM_ASSETS["filter_selected"] if selected else ALBUM_ASSETS["filter_normal"]), rect)
		if el != "all":
			_draw_texture_fit(_tex(ELEMENT_ICON_ASSETS.get(el, "")), Rect2(rect.position.x + 5.0, rect.position.y + 5.0, 22.0, 22.0))
		_draw_text(ELEMENT_NAMES.get(el, el), rect.position.x + rect.size.x / 2.0 + (7.0 if el != "all" else 0.0), rect.position.y + 23.0, C["text"] if selected else C["text_muted"], 12.0, rect.size.x)

func _draw_grid() -> void:
	var clip_bottom := DETAIL_Y - 22.0 if not _selected_monster_id.is_empty() else BOTTOM_TAB_Y - 8.0
	for i in range(_filtered_monsters.size()):
		var rect := _card_rect(i)
		if rect.position.y + rect.size.y < GRID_Y - 12.0 or rect.position.y > clip_bottom:
			continue
		_draw_monster_card(_filtered_monsters[i], rect, i)

func _draw_monster_card(monster: Dictionary, rect: Rect2, index: int) -> void:
	var id := str(monster.get("id", ""))
	var element := str(monster.get("element", "grass"))
	var unlocked := _is_captured(id)
	var selected := id == _selected_monster_id
	var frame_key := "card_locked" if not unlocked else ("card_blue" if element in ["water", "light", "wind"] else "card_green")
	_draw_texture_fit(_tex(ALBUM_ASSETS[frame_key]), rect, 1.0 if not selected else 1.0)
	if selected:
		_draw_stroke_rect(rect.position.x + 3.0, rect.position.y + 3.0, rect.size.x - 6.0, rect.size.y - 6.0, 2.0, C["gold"])
	_draw_texture_fit(_tex(ELEMENT_ICON_ASSETS.get(element, "")), Rect2(rect.position.x + 7.0, rect.position.y + 7.0, 22.0, 22.0), 0.95)
	_draw_text("%03d" % [index + 1], rect.position.x + 50.0, rect.position.y + 24.0, C["text"] if unlocked else C["text_muted"], 11.0, 54.0)
	if unlocked:
		_draw_monster_portrait(id, Rect2(rect.position.x + 19.0, rect.position.y + 26.0, 66.0, 56.0))
		_draw_text(monster.get("name", "???"), rect.position.x + rect.size.x / 2.0, rect.position.y + 89.0, C["text"], 10.0, 90.0)
	else:
		_draw_texture_fit(_tex(ALBUM_ASSETS["icon_lock"]), Rect2(rect.position.x + 39.0, rect.position.y + 43.0, 28.0, 34.0), 0.88)
		_draw_text("???", rect.position.x + rect.size.x / 2.0, rect.position.y + 89.0, C["text_muted"], 10.0, 88.0)
	_draw_stars(int(monster.get("rarity", 1)), rect.position.x + 24.0, rect.position.y + 96.0, 12.0, unlocked)

func _draw_detail_panel() -> void:
	var monster := _selected_monster()
	if monster.is_empty():
		return
	var panel_rect := Rect2(12.0, DETAIL_Y, DESIGN_W - 24.0, DETAIL_H)
	_draw_texture_fit(_tex(ALBUM_ASSETS["detail_panel"]), panel_rect)
	var id := str(monster.get("id", ""))
	var element := str(monster.get("element", "grass"))
	var instances := _get_instances_for_species(id)
	var owned_count := instances.size()
	var representative := _pick_representative_instance(instances)
	_draw_texture_fit(_tex(ELEMENT_ICON_ASSETS.get(element, "")), Rect2(25.0, DETAIL_Y + 16.0, 26.0, 26.0))
	_draw_text("%s  %s" % [id.replace("monster_", ""), monster.get("name", "???")], 108.0, DETAIL_Y + 36.0, C["text"], 17.0, 140.0)
	_draw_stars(int(monster.get("rarity", 1)), 28.0, DETAIL_Y + 48.0, 16.0, true)
	var own_text := "未拥有" if owned_count <= 0 else "已拥有 %d 只  代表 Lv.%d" % [owned_count, int(representative.get("level", 1))]
	_draw_text(own_text, 259.0, DETAIL_Y + 37.0, C["gold"] if owned_count > 0 else C["text_muted"], 10.0, 128.0)
	_draw_texture_fit(_tex(ALBUM_ASSETS["portrait_stage"]), Rect2(24.0, DETAIL_Y + 70.0, 122.0, 118.0))
	_draw_monster_portrait(id, Rect2(50.0, DETAIL_Y + 80.0, 74.0, 72.0))
	_draw_texture_fit(_tex(ALBUM_ASSETS["fx_sparkle"]), Rect2(106.0, DETAIL_Y + 68.0, 34.0, 44.0), 0.45)
	_draw_detail_nature(id)  # 绘制性格
	_draw_detail_stats(monster)
	_draw_detail_skill(monster)
	_draw_detail_evolution(monster)
	_draw_detail_buttons(monster)

func _draw_detail_nature(monster_id: String) -> void:
	# 从SaveManager获取性格数据
	var nature_id: String = ""
	var instances := _get_instances_for_species(monster_id)
	if not instances.is_empty():
		nature_id = str(_pick_representative_instance(instances).get("nature", ""))
	elif _storage and _storage.has_method("get_monster_pokedex"):
		var pokedex: Dictionary = _storage.get_monster_pokedex(monster_id)
		nature_id = pokedex.get("nature", "")
	
	# 如果没有性格（未收服），显示"未收服"
	if nature_id.is_empty():
		_draw_text("未收服", 108.0, DETAIL_Y + 52.0, C["text_muted"], 11.0, 120.0)
		return
	
	# 获取性格信息
	var NatureDB = load("res://src/data/nature_db.gd")
	var nature: Dictionary = {}
	if NatureDB and NatureDB.has_method("get_nature"):
		nature = NatureDB.get_nature(nature_id)
	
	if not nature.is_empty():
		# 显示性格emoji和名称
		var emoji: String = nature.get("emoji", "🌀")
		var name: String = nature.get("name", "混沌")
		_draw_text("%s %s" % [emoji, name], 108.0, DETAIL_Y + 52.0, C["text"], 11.0, 120.0)
	else:
		_draw_text("??", 108.0, DETAIL_Y + 52.0, C["text_muted"], 11.0, 120.0)

func _draw_detail_stats(monster: Dictionary) -> void:
	var x := 154.0
	var y := DETAIL_Y + 58.0
	var id := str(monster.get("id", ""))
	
	# 获取性格修正后的实际数值（如果已收服）
	var is_captured := _is_captured(id)
	var level: int = 1
	var nature_id: String = ""
	if is_captured and _storage:
		var instances := _get_instances_for_species(id)
		if not instances.is_empty():
			var representative: Dictionary = _pick_representative_instance(instances)
			level = int(representative.get("level", 1))
			nature_id = str(representative.get("nature", ""))
		else:
			if _storage.has_method("get_monster_level"):
				level = _storage.get_monster_level(id)
			if _storage.has_method("get_monster_nature"):
				nature_id = _storage.get_monster_nature(id)
	
	# 计算带有性格修正的数值
	var MonsterDB = load("res://src/data/monster_db.gd")
	var stats_data: Dictionary = {}
	if MonsterDB and MonsterDB.has_method("get_monster_stats"):
		stats_data = MonsterDB.get_monster_stats(id, level, nature_id)
	
	var base_hp: int = int(monster.get("baseHP", 0))
	var base_atk: int = int(monster.get("baseATK", 0))
	var base_def: int = int(monster.get("baseDEF", 0))
	var base_spd: int = int(monster.get("baseSPD", 0))
	
	# 如果有性格修正，使用修正后的数值
	var final_hp: int = stats_data.get("hp", base_hp) if not stats_data.is_empty() else base_hp
	var final_atk: int = stats_data.get("atk", base_atk) if not stats_data.is_empty() else base_atk
	var final_def: int = stats_data.get("def", base_def) if not stats_data.is_empty() else base_def
	var final_spd: int = stats_data.get("spd", base_spd) if not stats_data.is_empty() else base_spd
	
	var stats := [
		["生命", final_hp, Color(0.45, 0.95, 0.30)],
		["攻击", final_atk, Color(1.0, 0.42, 0.25)],
		["防御", final_def, Color(0.32, 0.68, 1.0)],
		["速度", final_spd, Color(0.38, 0.92, 0.94)],
	]
	for i in range(stats.size()):
		var row_y := y + float(i) * 24.0
		_draw_texture_fit(_tex(ALBUM_ASSETS["stat_row"]), Rect2(x, row_y, 188.0, 20.0), 0.82)
		_draw_text(stats[i][0], x + 29.0, row_y + 15.0, C["text_muted"], 10.0, 48.0)
		var ratio: float = clampf(float(stats[i][1]) / 230.0, 0.08, 1.0)
		draw_rect(Rect2(x + 58.0, row_y + 7.0, 92.0, 6.0), Color(0.02, 0.05, 0.10, 0.82))
		draw_rect(Rect2(x + 58.0, row_y + 7.0, 92.0 * ratio, 6.0), stats[i][2])
		_draw_text(str(stats[i][1]), x + 170.0, row_y + 15.0, C["text"], 10.0, 40.0)

func _draw_detail_skill(monster: Dictionary) -> void:
	var skill: Dictionary = monster.get("skill", {})
	_draw_texture_fit(_tex(ALBUM_ASSETS["skill_panel"]), Rect2(24.0, DETAIL_Y + 166.0, 124.0, 58.0))
	_draw_texture_fit(_tex(ELEMENT_ICON_ASSETS.get(monster.get("element", ""), "")), Rect2(32.0, DETAIL_Y + 176.0, 32.0, 32.0))
	_draw_text(skill.get("name", "未知技能"), 94.0, DETAIL_Y + 187.0, C["text"], 11.0, 76.0)
	_draw_text("能量 %d  倍率 %.1fx" % [skill.get("cost", 0), skill.get("multiplier", 1.0)], 96.0, DETAIL_Y + 205.0, C["text_muted"], 8.5, 76.0)

func _draw_detail_evolution(monster: Dictionary) -> void:
	_draw_texture_fit(_tex(ALBUM_ASSETS["evolution_strip"]), Rect2(154.0, DETAIL_Y + 164.0, 188.0, 60.0))
	_draw_text("进化预览", 202.0, DETAIL_Y + 180.0, C["text_muted"], 9.5, 86.0)
	var id := str(monster.get("id", ""))
	_draw_monster_portrait(id, Rect2(162.0, DETAIL_Y + 184.0, 34.0, 34.0))
	if _selected_has_evolution():
		var target_id := str(monster.get("evolution", {}).get("target", ""))
		_draw_texture_fit(_tex(ALBUM_ASSETS["icon_evolution_arrows"]), Rect2(205.0, DETAIL_Y + 193.0, 28.0, 16.0))
		_draw_monster_portrait(target_id, Rect2(238.0, DETAIL_Y + 184.0, 34.0, 34.0))
	else:
		_draw_text("无", 256.0, DETAIL_Y + 207.0, C["text_muted"], 12.0, 50.0)

func _draw_detail_buttons(monster: Dictionary) -> void:
	_draw_texture_fit(_tex(ALBUM_ASSETS["btn_secondary"]), _detail_close_rect)
	_draw_text("关闭", _detail_close_rect.position.x + _detail_close_rect.size.x / 2.0, _detail_close_rect.position.y + 25.0, C["text"], 13.0, 70.0)

func _draw_bottom_tabs() -> void:
	var y := BOTTOM_TAB_Y
	var tab_w := 112.0
	var tabs := [
		["图鉴", "icon_album", true],
		["羁绊", "icon_paw", false],
		["收藏", "icon_favorite", false],
	]
	for i in range(tabs.size()):
		var x := 18.0 + float(i) * (tab_w + 4.0)
		_draw_texture_fit(_tex(ALBUM_ASSETS["bottom_tab_selected"] if tabs[i][2] else ALBUM_ASSETS["bottom_tab_normal"]), Rect2(x, y, tab_w, 42.0), 1.0 if tabs[i][2] else 0.78)
		_draw_texture_fit(_tex(ALBUM_ASSETS[tabs[i][1]]), Rect2(x + 14.0, y + 6.0, 28.0, 28.0), 1.0 if tabs[i][2] else 0.6)
		_draw_text(tabs[i][0], x + 72.0, y + 27.0, C["text"] if tabs[i][2] else C["text_muted"], 13.0, 60.0)

func _filter_rect(index: int) -> Rect2:
	var w := 38.0 if index > 0 else 58.0
	var x := 10.0
	for i in range(index):
		x += 58.0 if i == 0 else 38.0
		x += 3.0
	return Rect2(x, 70.0, w, 34.0)

func _card_rect(index: int) -> Rect2:
	var col := index % COLS
	var row := index / COLS
	return Rect2(GRID_X + float(col) * (CARD_W + CARD_GAP), GRID_Y + float(row) * (CARD_H + CARD_GAP) - _scroll_y, CARD_W, CARD_H)

func _monster_index_at(pos: Vector2) -> int:
	var bottom := DETAIL_Y if not _selected_monster_id.is_empty() else BOTTOM_TAB_Y
	if pos.y < GRID_Y or pos.y > bottom:
		return -1
	var rel_x := pos.x - GRID_X
	var rel_y := pos.y + _scroll_y - GRID_Y
	if rel_x < 0.0 or rel_y < 0.0:
		return -1
	var col := int(rel_x / (CARD_W + CARD_GAP))
	var row := int(rel_y / (CARD_H + CARD_GAP))
	if col < 0 or col >= COLS:
		return -1
	var rect := Rect2(float(col) * (CARD_W + CARD_GAP), float(row) * (CARD_H + CARD_GAP), CARD_W, CARD_H)
	if not rect.has_point(Vector2(rel_x, rel_y)):
		return -1
	return row * COLS + col

func _selected_monster() -> Dictionary:
	for monster: Dictionary in _all_monsters:
		if monster.get("id", "") == _selected_monster_id:
			return monster
	return {}

func _selected_has_evolution() -> bool:
	var monster := _selected_monster()
	return monster.has("evolution") and monster.get("evolution", {}).has("target")

func _is_captured(id: String) -> bool:
	return _captured_ids.has(id)

func _draw_monster_portrait(id: String, rect: Rect2) -> void:
	var path := MonsterArtDBScript.get_art_path(id, "album")
	var tex := _tex(path)
	if tex:
		_draw_texture_fit(tex, rect)
	else:
		_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 8.0, Color(0.04, 0.07, 0.15, 0.86))
		var md := _get_monster_data(id)
		_draw_text(md.get("emoji", "?"), rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y * 0.62, C["text"], minf(rect.size.x * 0.45, 24.0), rect.size.x)

func _get_monster_data(id: String) -> Dictionary:
	var MonsterDB = load("res://src/data/monster_db.gd")
	return MonsterDB.get_monster(id) if MonsterDB and MonsterDB.has_method("get_monster") else {}

func _draw_stars(rarity: int, x: float, y: float, size: float, lit: bool) -> void:
	for i in range(5):
		var tex := _tex(ALBUM_ASSETS["icon_star_lit"] if i < rarity and lit else ALBUM_ASSETS["icon_star_dim"])
		_draw_texture_fit(tex, Rect2(x + float(i) * (size + 1.0), y, size, size))

func _draw_text(text: String, x: float, y: float, color: Color, size: float, max_w: float = 200.0) -> void:
	var font := ThemeDB.fallback_font
	var left := x - max_w / 2.0
	draw_string(font, Vector2(left + 1.0, y + 1.5), text, HORIZONTAL_ALIGNMENT_CENTER, max_w, size, Color(0, 0, 0, 0.58))
	draw_string(font, Vector2(left, y), text, HORIZONTAL_ALIGNMENT_CENTER, max_w, size, color)

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	draw_rect(Rect2(x + r, y, w - r * 2.0, h), color)
	draw_rect(Rect2(x, y + r, w, h - r * 2.0), color)
	draw_rect(Rect2(x, y, r, r), color)
	draw_rect(Rect2(x + w - r, y, r, r), color)
	draw_rect(Rect2(x, y + h - r, r, r), color)
	draw_rect(Rect2(x + w - r, y + h - r, r, r), color)

func _draw_stroke_rect(x: float, y: float, w: float, h: float, line_width: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, line_width), color)
	draw_rect(Rect2(x, y + h - line_width, w, line_width), color)
	draw_rect(Rect2(x, y, line_width, h), color)
	draw_rect(Rect2(x + w - line_width, y, line_width, h), color)

func _tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex:
		draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, opacity))

func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var source_size := rect.size / scale
	var source_pos := (tex_size - source_size) / 2.0
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size), Color(1.0, 1.0, 1.0, opacity))

func _go_back() -> void:
	var manager := _root_node("SceneManager")
	if manager and manager.has_method("switch_scene"):
		manager.switch_scene("main")

func _go_evolve() -> void:
	var manager := _root_node("SceneManager")
	if manager and manager.has_method("switch_scene"):
		manager.switch_scene("evolve", {"monsterId": _selected_monster_id})

func _pick_representative_instance(instances: Array) -> Dictionary:
	var best: Dictionary = {}
	for instance: Dictionary in instances:
		if best.is_empty() or int(instance.get("level", 1)) > int(best.get("level", 1)):
			best = instance
	return best

func _get_instances_for_species(monster_id: String) -> Array:
	if _storage and _storage.has_method("get_instances_by_monster_id"):
		var instances: Array = _storage.get_instances_by_monster_id(monster_id)
		if not instances.is_empty():
			return instances
	if DEBUG_UNLOCK_ALL_ALBUM_FOR_QA and _is_captured(monster_id):
		var monster := _get_monster_data(monster_id)
		return [{
			"instanceId": "qa_%s" % monster_id,
			"monsterId": monster_id,
			"name": str(monster.get("name", monster_id)),
			"level": 1,
			"exp": 0,
			"nature": "",
			"source": "album_qa"
		}]
	return []

func _root_node(node_name: String) -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)

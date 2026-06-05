# scene_album_gui.gd - 可在 Godot 编辑器中调整的怪物图鉴界面
# 列表交互改为分页，不再使用拖拽/滚轮滚动。
class_name SceneAlbumGui
extends "res://src/ui/scene/scene_album.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const LockedSilhouetteShader := preload("res://src/ui/shaders/album_locked_silhouette.gdshader")
const PAGE_SIZE := 15
const CARD_PATHS := [
	"AlbumPage/Grid/Card1",
	"AlbumPage/Grid/Card2",
	"AlbumPage/Grid/Card3",
	"AlbumPage/Grid/Card4",
	"AlbumPage/Grid/Card5",
	"AlbumPage/Grid/Card6",
	"AlbumPage/Grid/Card7",
	"AlbumPage/Grid/Card8",
	"AlbumPage/Grid/Card9",
	"AlbumPage/Grid/Card10",
	"AlbumPage/Grid/Card11",
	"AlbumPage/Grid/Card12",
	"AlbumPage/Grid/Card13",
	"AlbumPage/Grid/Card14",
	"AlbumPage/Grid/Card15",
]
const FILTER_PATHS := [
	"AlbumPage/Filters/All",
	"AlbumPage/Filters/Fire",
	"AlbumPage/Filters/Water",
	"AlbumPage/Filters/Grass",
	"AlbumPage/Filters/Thunder",
	"AlbumPage/Filters/Light",
	"AlbumPage/Filters/Earth",
	"AlbumPage/Filters/Wind",
	"AlbumPage/Filters/Dark",
]
const TAB_IDS := ["album", "bond", "collection"]
const TAB_PATHS := ["BottomTabs/AlbumTab", "BottomTabs/BondTab", "BottomTabs/CollectionTab"]
const STAT_LABELS := ["生命", "攻击", "防御", "速度"]

var _album_page := 0
var _locked_silhouette_material: ShaderMaterial = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_connect_gui_actions()
	_attach_gui_feedback()
	_sync_gui()

func init(data: Dictionary = {}) -> void:
	super.init(data)
	_album_page = int(data.get("page", 0))
	var target_id := str(data.get("selectedMonsterId", data.get("monsterId", "")))
	if not target_id.is_empty():
		_selected_tab = "album"
		_selected_element = "all"
		if _is_captured(target_id):
			_selected_monster_id = target_id
		_apply_filter()
		_album_page = _page_for_monster(target_id)
	_clamp_album_page()
	_sync_gui()

func _process(delta: float) -> void:
	_time += delta

func _draw() -> void:
	pass

func _gui_input(_event: InputEvent) -> void:
	pass

func _apply_filter() -> void:
	super._apply_filter()
	_scroll_y = 0.0
	_clamp_album_page()
	_sync_gui()

func _connect_gui_actions() -> void:
	_connect_button("Header/BackButton", _go_back)
	for i in FILTER_PATHS.size():
		_connect_button(FILTER_PATHS[i], _on_filter_pressed.bind(ELEMENT_ORDER[i]))
	for i in CARD_PATHS.size():
		_connect_button(CARD_PATHS[i], _on_card_pressed.bind(i))
	_connect_button("AlbumPage/PageControls/PreviousButton", _on_previous_page_pressed)
	_connect_button("AlbumPage/PageControls/NextButton", _on_next_page_pressed)
	_connect_button("DetailPanel/CloseButton", _on_detail_close_pressed)
	_connect_button("DetailPanel/EvolveButton", _go_evolve)
	for i in TAB_PATHS.size():
		_connect_button(TAB_PATHS[i], _on_tab_pressed.bind(TAB_IDS[i]))
	_connect_button("LobbyBottomNav/HomeButton", _go_to_scene.bind("main"))
	_connect_button("LobbyBottomNav/PetsButton", _on_tab_pressed.bind("album"))
	_connect_button("LobbyBottomNav/BattleButton", _on_tab_pressed.bind("bond"))
	_connect_button("LobbyBottomNav/ShopButton", _on_tab_pressed.bind("collection"))
	_connect_button("LobbyBottomNav/MenuButton", _go_to_scene.bind("settings"))

func _attach_gui_feedback() -> void:
	var primary_paths := ["DetailPanel/EvolveButton"]
	for path in FILTER_PATHS + CARD_PATHS + TAB_PATHS + [
		"Header/BackButton",
		"AlbumPage/PageControls/PreviousButton",
		"AlbumPage/PageControls/NextButton",
		"DetailPanel/CloseButton",
		"LobbyBottomNav/HomeButton",
		"LobbyBottomNav/PetsButton",
		"LobbyBottomNav/BattleButton",
		"LobbyBottomNav/ShopButton",
		"LobbyBottomNav/MenuButton",
	]:
		var button := get_node_or_null(path) as BaseButton
		if button == null or button.has_node("CartoonFeedback"):
			continue
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		feedback.setup(button, CartoonButtonFeedback.Profile.PRIMARY if path in primary_paths else CartoonButtonFeedback.Profile.NAV)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _on_filter_pressed(element: String) -> void:
	if _selected_element == element:
		return
	_selected_element = element
	_selected_monster_id = ""
	_album_page = 0
	_apply_filter()

func _on_card_pressed(visible_index: int) -> void:
	var index := _album_page * PAGE_SIZE + visible_index
	if index < 0 or index >= _filtered_monsters.size():
		return
	var monster: Dictionary = _filtered_monsters[index]
	var id := str(monster.get("id", ""))
	if not _is_captured(id):
		_selected_monster_id = ""
		_sync_gui()
		return
	_selected_monster_id = id
	_sync_gui()

func _on_previous_page_pressed() -> void:
	_album_page = maxi(0, _album_page - 1)
	_selected_monster_id = ""
	_sync_gui()

func _on_next_page_pressed() -> void:
	_album_page = mini(_max_album_page(), _album_page + 1)
	_selected_monster_id = ""
	_sync_gui()

func _page_for_monster(monster_id: String) -> int:
	for i in range(_filtered_monsters.size()):
		if str((_filtered_monsters[i] as Dictionary).get("id", "")) == monster_id:
			return int(floor(float(i) / float(PAGE_SIZE)))
	return 0

func _on_detail_close_pressed() -> void:
	_selected_monster_id = ""
	_sync_gui()

func _on_tab_pressed(tab_id: String) -> void:
	_selected_tab = tab_id
	_selected_monster_id = ""
	_album_page = 0
	_sync_gui()

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Header"):
		return
	_sync_static_labels()
	_sync_resource_bar()
	_sync_header()
	_sync_pages()
	_sync_tabs()

func _sync_static_labels() -> void:
	_node("Header/BackButton").visible = false
	_node("BottomTabs").visible = false
	var tab_labels := {
		"BottomTabs/AlbumTab/Text": "图鉴",
		"BottomTabs/BondTab/Text": "羁绊",
		"BottomTabs/CollectionTab/Text": "目标",
	}
	for path in tab_labels.keys():
		_label(path).text = str(tab_labels[path])
	var nav_labels := {
		"LobbyBottomNav/HomeButton/Text": "主页",
		"LobbyBottomNav/PetsButton/Text": "图鉴",
		"LobbyBottomNav/BattleButton/Text": "羁绊",
		"LobbyBottomNav/ShopButton/Text": "目标",
		"LobbyBottomNav/MenuButton/Text": "菜单",
	}
	for path in nav_labels.keys():
		_label(path).text = str(nav_labels[path])
	_label("LobbyBottomNav/HomeButton/Glyph").text = "⌂"

func _sync_resource_bar() -> void:
	var player: Dictionary = _storage.get_player() if _storage != null and _storage.has_method("get_player") else {}
	_label("AlbumResourceBar/GoldCapsule/Value").text = "金币  %s" % _format_resource_number(int(player.get("gold", 0)))
	_label("AlbumResourceBar/GemCapsule/Value").text = "钻石  %s" % _format_resource_number(int(player.get("gems", 0)))
	_label("AlbumResourceBar/EnergyCapsule/Value").text = "体力  Full"

func _sync_header() -> void:
	_label("Header/Title").text = "精灵图鉴"
	_label("Header/Progress").text = "%d/%d" % [_captured_ids.size(), _all_monsters.size()]

func _sync_pages() -> void:
	_node("AlbumPage").visible = _selected_tab == "album"
	_node("BondPage").visible = _selected_tab == "bond"
	_node("CollectionPage").visible = _selected_tab == "collection"
	if _selected_tab == "album":
		_sync_filters()
		_sync_grid()
		_sync_page_controls()
		_sync_detail()
	elif _selected_tab == "bond":
		_sync_bond_page()
	else:
		_sync_collection_page()

func _sync_filters() -> void:
	for i in FILTER_PATHS.size():
		var button := get_node(FILTER_PATHS[i]) as TextureButton
		var frame := button.get_node("Frame") as TextureRect
		var element: String = ELEMENT_ORDER[i]
		var selected: bool = element == _selected_element
		var compact := element in ["all", "thunder", "earth", "wind"]
		var texture_key := "filter_selected" if selected else "filter_normal"
		if compact:
			texture_key = "filter_compact_selected" if selected else "filter_compact_normal"
		frame.texture = _album_texture(texture_key)
		var icon := button.get_node("Icon") as TextureRect
		icon.visible = element != "all"
		icon.texture = _element_texture(element)
		var text := button.get_node("Text") as Label
		text.text = str(ELEMENT_NAMES.get(element, element))
		text.add_theme_color_override("font_color", Color(0.12, 0.43, 0.72) if selected else Color(0.43, 0.24, 0.07))
		text.add_theme_color_override("font_shadow_color", Color(1.0, 0.96, 0.82, 0.72))

func _sync_grid() -> void:
	var start := _album_page * PAGE_SIZE
	for i in CARD_PATHS.size():
		var card := get_node(CARD_PATHS[i]) as TextureButton
		var index := start + i
		card.visible = index < _filtered_monsters.size()
		if not card.visible:
			continue
		var monster: Dictionary = _filtered_monsters[index]
		_sync_card(card, monster, index)

func _sync_card(card: TextureButton, monster: Dictionary, index: int) -> void:
	var id := str(monster.get("id", ""))
	var element := str(monster.get("element", "grass"))
	var unlocked := _is_captured(id)
	var frame := card.get_node("Frame") as TextureRect
	frame.visible = false
	(card.get_node("SelectedFrame") as ColorRect).visible = false
	var element_icon := card.get_node("ElementIcon") as TextureRect
	element_icon.visible = false
	element_icon.texture = _element_texture(element)
	var number := card.get_node("Number") as Label
	number.visible = false
	number.text = "%03d" % [index + 1]
	var name_label := card.get_node("Name") as Label
	name_label.visible = false
	name_label.text = str(monster.get("name", "???")) if unlocked else "???"
	var portrait := card.get_node("Portrait") as TextureRect
	portrait.visible = true
	portrait.texture = _monster_texture(id, "album")
	portrait.material = null if unlocked else _locked_portrait_material()
	(card.get_node("LockIcon") as TextureRect).visible = false
	(card.get_node("Stars") as Control).visible = false
	for i in 5:
		var star := card.get_node("Stars/Star%d" % (i + 1)) as TextureRect
		star.texture = _album_texture("icon_star_lit" if i < int(monster.get("rarity", 1)) and unlocked else "icon_star_dim")

func _sync_page_controls() -> void:
	_clamp_album_page()
	var max_page := _max_album_page()
	_label("AlbumPage/PageControls/PageLabel").text = "%d / %d" % [_album_page + 1, max_page + 1]
	var prev := get_node("AlbumPage/PageControls/PreviousButton") as TextureButton
	var next := get_node("AlbumPage/PageControls/NextButton") as TextureButton
	prev.disabled = _album_page <= 0
	next.disabled = _album_page >= max_page
	prev.modulate.a = 0.45 if prev.disabled else 1.0
	next.modulate.a = 0.45 if next.disabled else 1.0

func _sync_detail() -> void:
	var panel := _node("DetailPanel")
	panel.visible = not _selected_monster_id.is_empty()
	if not panel.visible:
		return
	var monster := _selected_monster()
	if monster.is_empty():
		panel.visible = false
		return
	var id := str(monster.get("id", ""))
	var element := str(monster.get("element", "grass"))
	var instances := _get_instances_for_species(id)
	var owned_count := instances.size()
	var representative := _pick_representative_instance(instances)
	(get_node("DetailPanel/ElementIcon") as TextureRect).texture = _element_texture(element)
	_label("DetailPanel/Name").text = "%s  %s" % [id.replace("monster_", ""), str(monster.get("name", "???"))]
	_label("DetailPanel/Nature").text = _detail_nature_text(id)
	_label("DetailPanel/Owned").text = "未拥有" if owned_count <= 0 else "已拥有 %d 只  代表 Lv.%d" % [owned_count, int(representative.get("level", 1))]
	(get_node("DetailPanel/PortraitStage/Portrait") as TextureRect).texture = _monster_texture(id, "album")
	_sync_detail_stars(monster)
	_sync_detail_stats(monster)
	_sync_detail_skill(monster)
	_sync_detail_evolution(monster)
	_sync_detail_ecology(monster)

func _detail_nature_text(monster_id: String) -> String:
	var nature_id := ""
	var instances := _get_instances_for_species(monster_id)
	if not instances.is_empty():
		nature_id = str(_pick_representative_instance(instances).get("nature", ""))
	elif _storage and _storage.has_method("get_monster_pokedex"):
		nature_id = str((_storage.get_monster_pokedex(monster_id) as Dictionary).get("nature", ""))
	if nature_id.is_empty():
		return "未收服"
	var NatureDB = load("res://src/data/nature_db.gd")
	var nature: Dictionary = NatureDB.get_nature(nature_id) if NatureDB and NatureDB.has_method("get_nature") else {}
	return str(nature.get("name", "??"))

func _sync_detail_stars(monster: Dictionary) -> void:
	for i in 5:
		var star := get_node("DetailPanel/Stars/Star%d" % (i + 1)) as TextureRect
		star.texture = _album_texture("icon_star_lit" if i < int(monster.get("rarity", 1)) else "icon_star_dim")

func _sync_detail_stats(monster: Dictionary) -> void:
	var id := str(monster.get("id", ""))
	var level := 1
	var nature_id := ""
	var instances := _get_instances_for_species(id)
	if not instances.is_empty():
		var representative := _pick_representative_instance(instances)
		level = int(representative.get("level", 1))
		nature_id = str(representative.get("nature", ""))
	var MonsterDB = load("res://src/data/monster_db.gd")
	var stats_data: Dictionary = MonsterDB.get_monster_stats(id, level, nature_id) if MonsterDB and MonsterDB.has_method("get_monster_stats") else {}
	var stats := [
		int(stats_data.get("hp", monster.get("baseHP", 0))),
		int(stats_data.get("atk", monster.get("baseATK", 0))),
		int(stats_data.get("def", monster.get("baseDEF", 0))),
		int(stats_data.get("spd", monster.get("baseSPD", 0))),
	]
	for i in STAT_LABELS.size():
		var row := get_node("DetailPanel/Stats/Stat%d" % (i + 1)) as Control
		(row.get_node("Name") as Label).text = STAT_LABELS[i]
		(row.get_node("Value") as Label).text = str(stats[i])
		(row.get_node("Fill") as ColorRect).size.x = 92.0 * clampf(float(stats[i]) / 230.0, 0.08, 1.0)

func _sync_detail_skill(monster: Dictionary) -> void:
	var skill: Dictionary = MonsterDb.normalize_skill(monster.get("skill", {}))
	(get_node("DetailPanel/SkillPanel/Icon") as TextureRect).texture = _element_texture(str(monster.get("element", "")))
	_label("DetailPanel/SkillPanel/Name").text = str(skill.get("name", "未知技能"))
	var skill_type := str(skill.get("type", "strike"))
	var type_label := str(MonsterDb.SKILL_TYPE_LABELS.get(skill_type, skill_type))
	_label("DetailPanel/SkillPanel/Desc").text = "能量 %d  %s %.1fx" % [int(skill.get("cost", 0)), type_label, float(skill.get("multiplier", 1.0))]

func _sync_detail_evolution(monster: Dictionary) -> void:
	var id := str(monster.get("id", ""))
	(get_node("DetailPanel/EvolutionStrip/From") as TextureRect).texture = _monster_texture(id, "album")
	var has_evolution := _selected_has_evolution()
	(get_node("DetailPanel/EvolutionStrip/Arrow") as TextureRect).visible = has_evolution
	(get_node("DetailPanel/EvolutionStrip/To") as TextureRect).visible = has_evolution
	_label("DetailPanel/EvolutionStrip/Empty").visible = not has_evolution
	if has_evolution:
		var target_id := str(monster.get("evolution", {}).get("target", ""))
		(get_node("DetailPanel/EvolutionStrip/To") as TextureRect).texture = _monster_texture(target_id, "album")

func _sync_detail_ecology(monster: Dictionary) -> void:
	var identity: Dictionary = EcologyBondRulesScript.get_monster_identity(monster)
	var ecology: Dictionary = identity.get("ecology", {})
	_label("DetailPanel/Ecology").text = "%s · %s" % [str(identity.get("roleLabel", "角色")), str(ecology.get("name", "生态"))]

func _sync_bond_page() -> void:
	var progress: Array = EcologyBondRulesScript.get_ecology_progress(_all_monsters, _captured_ids)
	for i in 6:
		var row := get_node("BondPage/Rows/Row%d" % (i + 1)) as Control
		row.visible = i < progress.size()
		if not row.visible:
			continue
		var group: Dictionary = progress[i]
		var owned := int(group.get("owned", 0))
		var total := maxi(1, int(group.get("total", 1)))
		(row.get_node("Name") as Label).text = str(group.get("name", ""))
		(row.get_node("Theme") as Label).text = str(group.get("theme", ""))
		(row.get_node("Progress") as Label).text = "%d/%d" % [owned, total]
		var bar_bg := row.get_node("BarBg") as ColorRect
		(row.get_node("Fill") as ColorRect).size.x = bar_bg.size.x * clampf(float(owned) / float(total), 0.0, 1.0)

func _sync_collection_page() -> void:
	var role_target: Dictionary = EcologyBondRulesScript.get_role_collection_target(_all_monsters, _captured_ids)
	_label("CollectionPage/RoleTarget/Name").text = str(role_target.get("name", "角色目标"))
	_label("CollectionPage/RoleTarget/Progress").text = "%d/%d" % [int(role_target.get("owned", 0)), int(role_target.get("total", 1))]
	_label("CollectionPage/RoleTarget/Suggestion").text = str(role_target.get("suggestion", ""))
	var targets: Array = EcologyBondRulesScript.get_ecology_targets(_all_monsters, _captured_ids)
	for i in 5:
		var row := get_node("CollectionPage/Rows/Row%d" % (i + 1)) as Control
		row.visible = i < targets.size()
		if not row.visible:
			continue
		var target: Dictionary = targets[i]
		(row.get_node("Name") as Label).text = str(target.get("name", ""))
		(row.get_node("Status") as Label).text = str(target.get("statusLabel", ""))
		(row.get_node("Theme") as Label).text = str(target.get("theme", ""))
		(row.get_node("Suggestion") as Label).text = str(target.get("suggestion", ""))
		var bar_bg := row.get_node("BarBg") as ColorRect
		(row.get_node("Fill") as ColorRect).size.x = bar_bg.size.x * clampf(float(target.get("ratio", 0.0)), 0.0, 1.0)

func _sync_tabs() -> void:
	for i in TAB_PATHS.size():
		var tab := get_node(TAB_PATHS[i]) as TextureButton
		var selected: bool = TAB_IDS[i] == _selected_tab
		(tab.get_node("Frame") as TextureRect).texture = _album_texture("bottom_tab_selected" if selected else "bottom_tab_normal")
		var text := tab.get_node("Text") as Label
		text.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.40, 0.23, 0.07))
		text.add_theme_color_override("font_shadow_color", Color(0.13, 0.24, 0.43, 0.75) if selected else Color(1.0, 0.95, 0.78, 0.65))
		tab.modulate.a = 1.0 if selected else 0.78
	var bottom_tab_buttons := {
		"album": "LobbyBottomNav/PetsButton",
		"bond": "LobbyBottomNav/BattleButton",
		"collection": "LobbyBottomNav/ShopButton",
	}
	for tab_id in bottom_tab_buttons.keys():
		var path := str(bottom_tab_buttons[tab_id])
		var selected := str(tab_id) == _selected_tab
		var selected_frame := get_node_or_null("%s/Selected" % path) as TextureRect
		if selected_frame != null:
			selected_frame.visible = selected
		var button := get_node(path) as Control
		button.modulate.a = 1.0 if selected else 0.92
		var label := get_node("%s/Text" % path) as Label
		label.add_theme_color_override("font_color", Color(0.36, 0.18, 0.05) if selected else Color(0.42, 0.28, 0.13))

func _max_album_page() -> int:
	return maxi(0, ceili(float(_filtered_monsters.size()) / float(PAGE_SIZE)) - 1)

func _clamp_album_page() -> void:
	_album_page = clampi(_album_page, 0, _max_album_page())

func _album_texture(key: String) -> Texture2D:
	return _tex(str(ALBUM_ASSETS.get(key, "")))

func _element_texture(element: String) -> Texture2D:
	return _tex(str(ELEMENT_ICON_ASSETS.get(element, "")))

func _monster_texture(id: String, variant: String) -> Texture2D:
	if variant == "album":
		var album_path := "res://assets/images/album/portraits/%s_album_thumb.png" % id
		if ResourceLoader.exists(album_path):
			return _tex(album_path)
	return _tex(MonsterArtDBScript.get_art_path(id, variant))

func _node(path: String) -> Control:
	return get_node(path) as Control

func _go_to_scene(scene_name: String) -> void:
	var manager := _root_node("SceneManager")
	if manager and manager.has_method("switch_scene"):
		manager.switch_scene(scene_name)

func _format_resource_number(value: int) -> String:
	var digits := str(absi(value))
	var formatted := ""
	while digits.length() > 3:
		formatted = "," + digits.substr(digits.length() - 3) + formatted
		digits = digits.substr(0, digits.length() - 3)
	formatted = digits + formatted
	return "-" + formatted if value < 0 else formatted

func _locked_portrait_material() -> ShaderMaterial:
	if _locked_silhouette_material == null:
		_locked_silhouette_material = ShaderMaterial.new()
		_locked_silhouette_material.shader = LockedSilhouetteShader
	return _locked_silhouette_material

func _label(path: NodePath) -> Label:
	return get_node(path) as Label

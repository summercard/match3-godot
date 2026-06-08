class_name SceneTeamGui
extends "res://src/ui/scene/scene_team.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")

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
	"nav_panel": "res://assets/images/ranch/ui_pet_farm_nav_panel.png",
	"nav_selected": "res://assets/images/ranch/ui_pet_farm_nav_selected.png",
	"nav_home": "res://assets/images/common_nav/icon_nav_home.png",
	"nav_pets": "res://assets/images/common_nav/icon_nav_pets.png",
	"nav_battle": "res://assets/images/common_nav/icon_nav_battle.png",
	"nav_shop": "res://assets/images/common_nav/icon_nav_shop.png",
	"nav_menu": "res://assets/images/common_nav/icon_nav_menu.png",
	"page_prev": "res://assets/images/ranch/ui_btn_previous_round.png",
	"page_next": "res://assets/images/ranch/ui_btn_next_round.png",
	"hp": "res://assets/images/ranch/fx_social_heart.png",
	"atk": "res://assets/images/common_nav/icon_nav_battle.png",
	"def": "res://assets/images/main/lobby_refresh/icon_level_shield_v3.png",
	"spd": "res://assets/images/ranch/icon_exp_badge.png",
}

const GUI_ROSTER_PAGE_SIZE := 6
const SLOT_PATHS := {
	"member1": "TeamSlots/Member1Slot",
	"leader": "TeamSlots/LeaderSlot",
	"member2": "TeamSlots/Member2Slot",
}
const ROSTER_PATHS := [
	"RosterPanel/Cards/Card1",
	"RosterPanel/Cards/Card2",
	"RosterPanel/Cards/Card3",
	"RosterPanel/Cards/Card4",
	"RosterPanel/Cards/Card5",
	"RosterPanel/Cards/Card6",
]
const NAV_PATHS := [
	"BottomNav/HomeButton",
	"BottomNav/PetsButton",
	"BottomNav/BattleButton",
	"BottomNav/ShopButton",
	"BottomNav/MenuButton",
]
const NAV_ITEMS := [
	{"id": "home", "label": "主页", "icon": "nav_home", "scene": "main"},
	{"id": "pets", "label": "农场", "icon": "nav_pets", "scene": "ranch"},
	{"id": "battle", "label": "战场", "icon": "nav_battle", "scene": "stage_select"},
	{"id": "shop", "label": "商店", "icon": "nav_shop", "scene": "shop"},
	{"id": "menu", "label": "菜单", "icon": "nav_menu", "scene": "settings"},
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_update_slots_layout()
	_connect_gui_actions()
	_attach_gui_feedback()
	_sync_gui()


func init(data: Dictionary = {}) -> void:
	super.init(data)
	_sync_gui()


func _process(delta: float) -> void:
	_time_acc += delta
	_sync_empty_slot_pulses()
	if not _has_empty_slot():
		set_process(false)


func _draw() -> void:
	pass


func _gui_input(_event: InputEvent) -> void:
	pass


func _update_slots_layout() -> void:
	_slots = [
		{"key": "member1", "rect": Rect2(43.0, 188.0, 78.0, 160.0), "label": "左位"},
		{"key": "leader", "rect": Rect2(128.0, 145.0, 119.0, 210.0), "label": "队长"},
		{"key": "member2", "rect": Rect2(254.0, 188.0, 78.0, 160.0), "label": "右位"},
	]
	_roster_prev_btn = Rect2(70.0, 585.0, 38.0, 38.0)
	_roster_next_btn = Rect2(267.0, 585.0, 38.0, 38.0)


func _get_roster_page_count() -> int:
	return maxi(1, ceili(float(_get_display_monsters().size()) / float(GUI_ROSTER_PAGE_SIZE)))


func _connect_gui_actions() -> void:
	if not has_node("TeamSlots"):
		return
	for key in SLOT_PATHS.keys():
		_connect_button(str(SLOT_PATHS[key]), _on_slot_pressed.bind(str(key)))
	for i in ROSTER_PATHS.size():
		_connect_button(ROSTER_PATHS[i], _on_roster_card_pressed.bind(i))
	_connect_button("RosterPanel/PageControls/PreviousButton", _on_previous_page_pressed)
	_connect_button("RosterPanel/PageControls/NextButton", _on_next_page_pressed)
	for i in NAV_PATHS.size():
		_connect_button(NAV_PATHS[i], _on_nav_pressed.bind(str(NAV_ITEMS[i].get("scene", "main"))))


func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)


func _attach_gui_feedback() -> void:
	for path in SLOT_PATHS.values():
		_add_feedback(str(path), CartoonButtonFeedback.Profile.ENTRY)
	for path in ROSTER_PATHS:
		_add_feedback(path, CartoonButtonFeedback.Profile.ENTRY)
	for path in NAV_PATHS:
		_add_feedback(path, CartoonButtonFeedback.Profile.NAV)
	_add_feedback("RosterPanel/PageControls/PreviousButton", CartoonButtonFeedback.Profile.ICON)
	_add_feedback("RosterPanel/PageControls/NextButton", CartoonButtonFeedback.Profile.ICON)


func _add_feedback(path: String, profile: int) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button == null or button.has_node("CartoonFeedback"):
		return
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)


func _on_slot_pressed(slot_key: String) -> void:
	_handle_slot_tap(slot_key)
	_save_team()
	_sync_gui()


func _on_roster_card_pressed(visible_index: int) -> void:
	var visible := _get_display_monsters()
	var index := _roster_page * GUI_ROSTER_PAGE_SIZE + visible_index
	if index < 0 or index >= visible.size():
		return
	_assign_to_slot(_get_instance_id(visible[index]))
	_save_team()
	_sync_gui()


func _on_previous_page_pressed() -> void:
	_turn_roster_page(-1)
	_sync_gui()


func _on_next_page_pressed() -> void:
	_turn_roster_page(1)
	_sync_gui()


func _on_nav_pressed(scene_name: String) -> void:
	_save_team()
	_change_scene_after_feedback(scene_name)


func _change_scene_after_feedback(scene_name: String) -> void:
	await get_tree().create_timer(0.12).timeout
	_change_to_scene(scene_name)


func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("TeamSlots"):
		return
	_clamp_roster_page()
	_sync_currency_bar()
	_sync_team_slots()
	_sync_power_panel()
	_sync_pet_roster()
	_sync_bottom_nav()
	_sync_empty_slot_pulses()
	set_process(_has_empty_slot())


func _sync_currency_bar() -> void:
	var player := _load_player_data()
	var values := {
		"GoldChip": _format_number(int(player.get("gold", 0))),
		"DiamondChip": _format_number(int(player.get("diamond", player.get("gems", 0)))),
		"HeartChip": "%s Full" % str(player.get("stamina", player.get("energy", 5))),
	}
	for chip_name in values.keys():
		_label("CurrencyBar/%s/Amount" % chip_name).text = str(values[chip_name])


func _sync_team_slots() -> void:
	for slot: Dictionary in _slots:
		var key := str(slot["key"])
		var slot_node := get_node(str(SLOT_PATHS[key])) as TextureButton
		var value: Variant = _team.get(key, null)
		var instance_id := "" if value == null else str(value)
		var occupied := not instance_id.is_empty()
		(slot_node.get_node("EmptyPlus") as TextureRect).visible = not occupied
		(slot_node.get_node("Portrait") as TextureRect).visible = occupied
		(slot_node.get_node("Fallback") as Label).visible = false
		(slot_node.get_node("Selection") as Panel).visible = _selected_slot == key
		(slot_node.get_node("LeaderBadge") as TextureRect).visible = key == "leader" and occupied
		(slot_node.get_node("LeaderText") as Label).visible = key == "leader" and occupied
		(slot_node.get_node("Label/Text") as Label).text = str(slot["label"])
		if not occupied:
			continue
		var portrait := slot_node.get_node("Portrait") as TextureRect
		var monster_id := _get_monster_id(instance_id)
		portrait.texture = _get_monster_texture(monster_id)
		if portrait.texture == null:
			var md := _get_monster_data(monster_id)
			(slot_node.get_node("Fallback") as Label).text = str(md.get("emoji", "?"))
			(slot_node.get_node("Fallback") as Label).visible = true


func _sync_empty_slot_pulses() -> void:
	if not is_inside_tree() or not has_node("TeamSlots"):
		return
	for key in SLOT_PATHS.keys():
		var value: Variant = _team.get(str(key), null)
		if value != null and not str(value).is_empty():
			continue
		var slot_node := get_node(str(SLOT_PATHS[key])) as TextureButton
		var empty := slot_node.get_node("EmptyPlus") as TextureRect
		empty.pivot_offset = empty.size * 0.5
		var pulse := 0.90 + sin(_time_acc * 3.1 + slot_node.position.x) * 0.06
		empty.scale = Vector2.ONE * pulse


func _has_empty_slot() -> bool:
	for key in SLOT_PATHS.keys():
		var value: Variant = _team.get(str(key), null)
		if value == null or str(value).is_empty():
			return true
	return false


func _sync_power_panel() -> void:
	_label("PowerPanel/Title").text = "Team Power"
	_label("PowerPanel/Power").text = _format_number(_calc_team_power())
	var totals := _calc_team_totals()
	for stat_key in ["hp", "atk", "def", "spd"]:
		_label("PowerPanel/Stats/%s/Value" % stat_key.capitalize()).text = _format_number(int(totals.get(stat_key, 0)))


func _sync_pet_roster() -> void:
	_label("RosterPanel/Title").text = "Choose Pets"
	_label("RosterPanel/Subtitle").text = "选择精灵加入队伍"
	var visible := _get_display_monsters()
	var start := _roster_page * GUI_ROSTER_PAGE_SIZE
	for i in ROSTER_PATHS.size():
		var card := get_node(ROSTER_PATHS[i]) as TextureButton
		var index := start + i
		if index >= visible.size():
			_sync_empty_roster_card(card)
		else:
			_sync_roster_card(card, visible[index])
	_label("RosterPanel/EmptyLabel").visible = visible.is_empty()
	_sync_roster_page_controls()


func _sync_roster_card(card: TextureButton, instance: Dictionary) -> void:
	var instance_id := _get_instance_id(instance)
	var monster_id := _get_monster_id(instance)
	var in_team := _team.values().has(instance_id)
	card.disabled = false
	card.modulate.a = 1.0
	(card.get_node("Frame") as TextureRect).texture = _gui_tex("roster_card_selected" if in_team else "roster_card")
	(card.get_node("Portrait") as TextureRect).texture = _get_monster_texture(monster_id)
	(card.get_node("Check") as TextureRect).visible = in_team
	(card.get_node("Level") as Label).text = "Lv.%d" % _get_real_level(instance_id)


func _sync_empty_roster_card(card: TextureButton) -> void:
	card.disabled = true
	card.modulate.a = 0.42
	(card.get_node("Frame") as TextureRect).texture = _gui_tex("roster_card")
	(card.get_node("Portrait") as TextureRect).texture = null
	(card.get_node("Check") as TextureRect).visible = false
	(card.get_node("Level") as Label).text = ""


func _sync_roster_page_controls() -> void:
	var page_count := _get_roster_page_count()
	var show_controls := page_count > 1
	_node("RosterPanel/PageControls").visible = show_controls
	if not show_controls:
		return
	_label("RosterPanel/PageControls/PageLabel").text = "%d / %d" % [_roster_page + 1, page_count]
	var prev := get_node("RosterPanel/PageControls/PreviousButton") as TextureButton
	var next := get_node("RosterPanel/PageControls/NextButton") as TextureButton
	prev.disabled = _roster_page <= 0
	next.disabled = _roster_page >= page_count - 1
	prev.modulate.a = 0.42 if prev.disabled else 1.0
	next.modulate.a = 0.42 if next.disabled else 1.0


func _sync_bottom_nav() -> void:
	for i in NAV_PATHS.size():
		var item: Dictionary = NAV_ITEMS[i]
		var button := get_node(NAV_PATHS[i]) as TextureButton
		(button.get_node("Selected") as TextureRect).visible = str(item.get("id", "")) == "battle"
		(button.get_node("Text") as Label).text = str(item.get("label", ""))


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


func _get_monster_texture(monster_id: String) -> Texture2D:
	return _get_texture(MonsterArtDBScript.get_art_path(_get_monster_id(monster_id), "team"))


func _gui_tex(key: String) -> Texture2D:
	return _get_texture(str(GUI_ASSETS.get(key, "")))


func _node(path: NodePath) -> Control:
	return get_node(path) as Control


func _label(path: NodePath) -> Label:
	return get_node(path) as Label

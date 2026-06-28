class_name SceneTeamGui
extends Control

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const MonsterArtDBScript := preload("res://src/data/monster_art_db.gd")
const MonsterDBScript := preload("res://src/data/monster_db.gd")
const BattlePowerRulesScript := preload("res://src/core/battle_power_rules.gd")

signal team_changed(team: Dictionary)
signal scene_exit()

const GUI_ASSETS := {
	"bg": "res://assets/images/ui/backgrounds/team_new_bg_team_hall.png",
	"currency": "res://assets/images/ui/panels/main_ui_currency_capsule_v3.png",
	"gold": "res://assets/images/ui/icons/main_icon_gold_coin_v3.png",
	"diamond": "res://assets/images/ui/gems/main_icon_diamond_gem_v3.png",
	"heart": "res://assets/images/effects/ranch_fx_social_heart.png",
	"plus": "res://assets/images/ui/icons/main_icon_currency_plus_green.png",
	"empty_plus": "res://assets/images/ui/panels/team_new_ui_empty_pedestal_plus.png",
	"leader_badge": "res://assets/images/ui/icons/team_new_ui_leader_badge.png",
	"pedestal_label": "res://assets/images/ui/panels/team_new_ui_pedestal_label.png",
	"power_panel": "res://assets/images/ui/panels/ranch_ui_care_roster_panel.png",
	"roster_panel": "res://assets/images/ui/panels/ranch_ui_care_roster_panel.png",
	"roster_card": "res://assets/images/ui/cards/ranch_ui_roster_card_ranch.png",
	"roster_card_selected": "res://assets/images/ui/cards/ranch_ui_roster_card_ranch_selected.png",
	"check": "res://assets/images/ui/icons/ranch_icon_check_badge_glossy.png",
	"nav_panel": "res://assets/images/ui/icons/ranch_ui_pet_farm_nav_panel.png",
	"nav_selected": "res://assets/images/ui/icons/ranch_ui_pet_farm_nav_selected.png",
	"nav_home": "res://assets/images/ui/icons/common_nav_icon_nav_home.png",
	"nav_pets": "res://assets/images/ui/icons/common_nav_icon_nav_pets.png",
	"nav_battle": "res://assets/images/ui/icons/common_nav_icon_nav_battle.png",
	"nav_shop": "res://assets/images/ui/icons/common_nav_icon_nav_shop.png",
	"nav_menu": "res://assets/images/ui/icons/common_nav_icon_nav_menu.png",
	"page_prev": "res://assets/images/ui/buttons/ranch_ui_btn_previous_round.png",
	"page_next": "res://assets/images/ui/buttons/ranch_ui_btn_next_round.png",
	"hp": "res://assets/images/effects/ranch_fx_social_heart.png",
	"atk": "res://assets/images/ui/icons/common_nav_icon_nav_battle.png",
	"def": "res://assets/images/ui/icons/main_icon_level_shield_v3.png",
	"spd": "res://assets/images/ui/icons/ranch_icon_exp_badge.png",
}

const GUI_ROSTER_PAGE_SIZE := 6
const SORT_OPTIONS := [
	{"id": "level", "label": "等级"},
	{"id": "power", "label": "战力"},
	{"id": "rarity", "label": "稀有度"},
]
const SLOT_PATHS := {
	"member1": "TeamSlots/Member1Slot",
	"leader": "TeamSlots/LeaderSlot",
	"member2": "TeamSlots/Member2Slot",
}
const SLOT_KEYS := ["member1", "leader", "member2"]
const SLOT_LABELS := {
	"member1": "左位",
	"leader": "队长",
	"member2": "右位",
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

var _storage: Node = null
var _team: Dictionary = {"leader": null, "member1": null, "member2": null}
var _selected_slot: String = ""
var _roster_page: int = 0
var _captured_monsters: Array = []
var _active_filter: String = "all"
var _sort_option: int = 0
var _time_acc: float = 0.0
var _texture_cache: Dictionary = {}
var _team_portrait_cache: Dictionary = {}
var _roster_texture_cache: Dictionary = {}
var _loaded_roster_page: int = -1
var _roster_load_generation: int = 0
var _pending_portrait_loads: Dictionary = {}
var _player_snapshot: Dictionary = {}
var _instance_by_id: Dictionary = {}
var _monster_id_by_instance_id: Dictionary = {}
var _stats_cache: Dictionary = {}
var _display_monsters_cache: Array = []
var _initialized: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_connect_gui_actions()
	_attach_gui_feedback()


func init(_data: Dictionary = {}) -> void:
	if not _initialized:
		_refresh_services()
		_initialized = true
	_roster_page = 0
	_selected_slot = ""
	_active_filter = "all"
	_sort_option = 0
	_rebuild_display_monsters_cache()
	_sync_gui()
	_play_entry_animation()


func _process(delta: float) -> void:
	_time_acc += delta
	_sync_empty_slot_pulses()
	_poll_portrait_loads()
	if not _has_empty_slot() and _pending_portrait_loads.is_empty():
		set_process(false)


func _play_entry_animation() -> void:
	var anim := get_node_or_null("EntryAnim") as AnimationPlayer
	if anim == null:
		return
	_set_entry_animation_start_state()
	anim.stop()
	anim.play("default/entry")


func _set_entry_animation_start_state() -> void:
	var currency_bar := get_node_or_null("CurrencyBar") as Control
	if currency_bar != null:
		currency_bar.position.y = -30.0
		currency_bar.modulate.a = 0.0
	var team_slots := get_node_or_null("TeamSlots") as Control
	if team_slots != null:
		team_slots.scale = Vector2(0.85, 0.85)
		team_slots.modulate.a = 0.0
	var power_panel := get_node_or_null("PowerPanel") as Control
	if power_panel != null:
		power_panel.scale = Vector2(0.96, 0.96)
		power_panel.modulate.a = 0.0
	var roster_panel := get_node_or_null("RosterPanel") as Control
	if roster_panel != null:
		roster_panel.scale = Vector2(0.96, 0.96)
		roster_panel.modulate.a = 0.0
	var bottom_nav := get_node_or_null("BottomNav") as Control
	if bottom_nav != null:
		bottom_nav.position.y = 632.0
		bottom_nav.modulate.a = 0.0


static func warm_assets() -> void:
	for path in GUI_ASSETS.values():
		ResourceLoader.load(str(path), "", ResourceLoader.CACHE_MODE_REUSE)


func _refresh_services() -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_load_team_state()
	_player_snapshot = _storage.load_player() if _storage != null and _storage.has_method("load_player") else {}
	_captured_monsters = _get_captured_monsters()
	_rebuild_instance_index()
	_stats_cache.clear()
	_team_portrait_cache.clear()
	_roster_texture_cache.clear()
	_pending_portrait_loads.clear()
	_loaded_roster_page = -1


func _rebuild_instance_index() -> void:
	_instance_by_id.clear()
	_monster_id_by_instance_id.clear()
	for value: Variant in _captured_monsters:
		if not value is Dictionary:
			continue
		var instance: Dictionary = value
		var instance_id := _get_instance_id(instance)
		if instance_id.is_empty():
			continue
		_instance_by_id[instance_id] = instance
		_monster_id_by_instance_id[instance_id] = str(instance.get("monsterId", instance.get("id", "")))


func _load_team_state() -> void:
	if _storage != null and _storage.has_method("load_team"):
		var saved: Dictionary = _storage.load_team()
		_team = {
			"leader": saved.get("leader", null),
			"member1": saved.get("member1", null),
			"member2": saved.get("member2", null),
		}
	else:
		_team = {"leader": null, "member1": null, "member2": null}
	_sanitize_team_unique_refs()


func _get_team_slots_for_instance(instance_id: String) -> Array:
	var slots: Array = []
	if instance_id.is_empty():
		return slots
	for key in ["leader", "member1", "member2"]:
		var value: Variant = _team.get(key, null)
		if value != null and str(value) == instance_id:
			slots.append(key)
	return slots


func _remove_from_team(instance_id: String) -> bool:
	var removed := false
	for key: String in _get_team_slots_for_instance(instance_id):
		_team[key] = null
		if _selected_slot == key:
			_selected_slot = ""
		removed = true
	return removed


func _sanitize_team_unique_refs() -> void:
	var seen := {}
	for key in ["leader", "member1", "member2"]:
		var value: Variant = _team.get(key, null)
		if value == null:
			continue
		var instance_id := str(value)
		if instance_id.is_empty() or seen.has(instance_id):
			_team[key] = null
			if _selected_slot == key:
				_selected_slot = ""
			continue
		seen[instance_id] = true


func _get_captured_monsters() -> Array:
	if _storage == null:
		return []
	if _storage.has_method("get_owned_monsters"):
		return _storage.get_owned_monsters()
	if _storage.has_method("load_player"):
		var player: Dictionary = _storage.load_player()
		var result: Array = []
		for monster_id in player.get("captured", []):
			result.append({"instanceId": str(monster_id), "monsterId": str(monster_id), "level": 1, "nature": ""})
		return result
	return []


func _get_instance_id(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("instanceId", ""))
	return str(value)


func _get_monster_id(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("monsterId", (value as Dictionary).get("id", "")))
	var ref_id := str(value)
	if _monster_id_by_instance_id.has(ref_id):
		return str(_monster_id_by_instance_id[ref_id])
	if MonsterDBScript.has_monster(ref_id):
		return ref_id
	var instance := _get_monster_instance(ref_id)
	if not instance.is_empty():
		return str(instance.get("monsterId", ""))
	return ref_id


func _get_monster_instance(ref_id: String) -> Dictionary:
	if _instance_by_id.has(ref_id):
		return _instance_by_id[ref_id]
	if _storage != null and _storage.has_method("get_monster_instance"):
		var instance: Variant = _storage.get_monster_instance(ref_id)
		if instance is Dictionary:
			return instance
	return {}


func _get_monster_data(monster_id: String) -> Dictionary:
	if monster_id.is_empty():
		return {}
	return MonsterDBScript.get_monster(_get_monster_id(monster_id))


func _get_real_level(ref_id: String) -> int:
	var instance := _get_monster_instance(ref_id)
	if not instance.is_empty():
		return int(instance.get("level", 1))
	return 1


func _get_nature(ref_id: String) -> String:
	var instance := _get_monster_instance(ref_id)
	if not instance.is_empty():
		return str(instance.get("nature", ""))
	return ""


func _calc_team_power() -> int:
	var total := 0
	for key in ["leader", "member1", "member2"]:
		var value: Variant = _team.get(key, null)
		var ref_id := "" if value == null else str(value)
		if ref_id.is_empty():
			continue
		var stats := _calc_stats(ref_id, _get_real_level(ref_id))
		total += _calc_battle_power(stats)
	return total


func _calc_stats(monster_id: String, level: int) -> Dictionary:
	var cache_key := "%s:%d" % [monster_id, level]
	if _stats_cache.has(cache_key):
		return _stats_cache[cache_key]
	var stats := MonsterDBScript.get_monster_stats(_get_monster_id(monster_id), level, _get_nature(monster_id))
	_stats_cache[cache_key] = stats
	return stats


func _calc_battle_power(stats: Dictionary) -> int:
	return BattlePowerRulesScript.calc_battle_power(stats)


func _get_catchup_state(instance_id: String) -> Dictionary:
	if _storage != null and _storage.has_method("get_instance_catchup_state") and not _get_monster_instance(instance_id).is_empty():
		return _storage.get_instance_catchup_state(instance_id)
	return {"enabled": false, "multiplier": 1.0, "label": ""}


func _clamp_roster_page() -> void:
	_roster_page = clampi(_roster_page, 0, _get_roster_page_count() - 1)


func _get_display_monsters() -> Array:
	return _display_monsters_cache


func _rebuild_display_monsters_cache() -> void:
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
	_display_monsters_cache = result


func _get_sort_score(instance: Dictionary, sort_id: String) -> int:
	var instance_id := _get_instance_id(instance)
	var md := _get_monster_data(_get_monster_id(instance))
	if sort_id == "rarity":
		return int(md.get("rarity", 1))
	if sort_id == "power":
		var stats := _calc_stats(instance_id, _get_real_level(instance_id))
		return _calc_battle_power(stats)
	return _get_real_level(instance_id)


func _handle_slot_tap(slot_key: String) -> void:
	if _team.get(slot_key) != null:
		_team[slot_key] = null
		if _selected_slot == slot_key:
			_selected_slot = ""
	else:
		_selected_slot = "" if _selected_slot == slot_key else slot_key


func _turn_roster_page(direction: int) -> void:
	if direction == 0:
		return
	var page_count := _get_roster_page_count()
	if page_count <= 1:
		_roster_page = 0
		return
	_roster_page = clampi(_roster_page + direction, 0, page_count - 1)


func _assign_to_slot(monster_id: String) -> void:
	if monster_id.is_empty():
		return
	if _selected_slot.is_empty() and not _get_team_slots_for_instance(monster_id).is_empty():
		_remove_from_team(monster_id)
		return
	if _selected_slot.is_empty():
		for key in ["leader", "member1", "member2"]:
			if _team.get(key) == null:
				_team[key] = monster_id
				return
		_team["leader"] = monster_id
		_sanitize_team_unique_refs()
		return
	var existing: Variant = _team[_selected_slot]
	_team[_selected_slot] = monster_id
	var swapped := false
	for key in ["leader", "member1", "member2"]:
		if key != _selected_slot and _team.get(key) == monster_id:
			_team[key] = existing if not swapped else null
			swapped = true
	_selected_slot = ""
	_sanitize_team_unique_refs()


func _save_team() -> void:
	if _storage != null and _storage.has_method("save_team"):
		_sanitize_team_unique_refs()
		_storage.save_team(_team)
		emit_signal("team_changed", _team)


func _change_to_scene(scene_name: String) -> void:
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").switch_scene(scene_name, {}, "quick")
	elif has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm != null and gm.has_node("scene_manager"):
			gm.scene_manager.switch_scene(scene_name, {}, "quick")


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


# 精灵旅馆入场动画由 team.tscn 中的 EntryAnim (AnimationPlayer) 负责，autoplay="entry" 自动播放


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
	_sync_pet_roster()


func _on_next_page_pressed() -> void:
	_turn_roster_page(1)
	_sync_pet_roster()


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
	set_process(_has_empty_slot() or not _pending_portrait_loads.is_empty())


func _sync_currency_bar() -> void:
	var player := _load_player_data()
	var values := {
		"GoldChip": _format_number(int(player.get("gold", 0))),
		"DiamondChip": _format_number(int(player.get("diamond", player.get("gems", 0)))),
		"HeartChip": "%d/5" % int(player.get("stamina", player.get("energy", 5))),
	}
	for chip_name in values.keys():
		_label("CurrencyBar/%s/Amount" % chip_name).text = str(values[chip_name])


func _sync_team_slots() -> void:
	for key: String in SLOT_KEYS:
		var slot_node := get_node(str(SLOT_PATHS[key])) as TextureButton
		var value: Variant = _team.get(key, null)
		var instance_id := "" if value == null else str(value)
		var occupied := not instance_id.is_empty()
		(slot_node.get_node("EmptyPlus") as TextureRect).visible = not occupied
		var portrait := slot_node.find_child("Portrait", true, false) as TextureRect
		if portrait != null:
			portrait.visible = occupied
		(slot_node.get_node("Fallback") as Label).visible = false
		(slot_node.get_node("Selection") as Panel).visible = _selected_slot == key
		var leader_badge := slot_node.find_child("LeaderBadge", true, false) as CanvasItem
		if leader_badge != null:
			leader_badge.visible = key == "leader" and occupied
		var leader_text := slot_node.find_child("LeaderText", true, false) as CanvasItem
		if leader_text != null:
			leader_text.visible = key == "leader" and occupied
		(slot_node.get_node("Label/Text") as Label).text = str(SLOT_LABELS[key])
		if not occupied or portrait == null:
			continue
		var monster_id := _get_monster_id(instance_id)
		_request_portrait_texture(monster_id, portrait, "team")
		if MonsterArtDBScript.get_art_path(monster_id, "team").is_empty():
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
	_prepare_roster_texture_page(_roster_page)
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
	card.visible = true
	card.disabled = false
	card.modulate.a = 1.0
	(card.get_node("Frame") as TextureRect).texture = _gui_tex("roster_card")
	_request_portrait_texture(monster_id, card.get_node("Portrait") as TextureRect, "roster")
	(card.get_node("Check") as TextureRect).visible = in_team
	(card.get_node("Level") as Label).text = "Lv.%d" % _get_real_level(instance_id)


func _sync_empty_roster_card(card: TextureButton) -> void:
	card.visible = false
	card.disabled = true
	card.modulate.a = 0.42
	(card.get_node("Frame") as TextureRect).texture = _gui_tex("roster_card")
	(card.get_node("Portrait") as TextureRect).texture = null
	(card.get_node("Check") as TextureRect).visible = false
	(card.get_node("Level") as Label).text = ""


func _sync_roster_page_controls() -> void:
	var page_count := _get_roster_page_count()
	_node("RosterPanel/PageControls").visible = true
	_label("RosterPanel/PageControls/PageLabel").text = "%d / %d" % [_roster_page + 1, page_count]
	var prev := get_node("RosterPanel/PageControls/PreviousButton") as TextureButton
	var next := get_node("RosterPanel/PageControls/NextButton") as TextureButton
	prev.visible = page_count > 1
	next.visible = page_count > 1
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
	return _player_snapshot


func _format_number(value: int) -> String:
	var text := str(value)
	var out := ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out


func _get_monster_texture(monster_id: String) -> Texture2D:
	return _get_texture(MonsterArtDBScript.get_art_path(_get_monster_id(monster_id), "team"))


func _prepare_roster_texture_page(page: int) -> void:
	if page == _loaded_roster_page:
		return
	_roster_load_generation += 1
	for path: String in ROSTER_PATHS:
		var portrait := get_node_or_null(path + "/Portrait") as TextureRect
		if portrait != null:
			portrait.texture = null
	_roster_texture_cache.clear()
	_loaded_roster_page = page


func _request_portrait_texture(monster_id: String, target: TextureRect, scope: String) -> void:
	var path := MonsterArtDBScript.get_art_path(_get_monster_id(monster_id), "team")
	if path.is_empty():
		target.texture = null
		return
	var cache := _team_portrait_cache if scope == "team" else _roster_texture_cache
	if cache.has(path):
		target.texture = cache[path]
		return
	target.texture = null
	var targets: Array = _pending_portrait_loads.get(path, [])
	targets.append({
		"node": target,
		"scope": scope,
		"generation": _roster_load_generation if scope == "roster" else -1,
	})
	_pending_portrait_loads[path] = targets
	if targets.size() == 1:
		ResourceLoader.load_threaded_request(path, "Texture2D", true, ResourceLoader.CACHE_MODE_REUSE)
	set_process(true)


func _poll_portrait_loads() -> void:
	if _pending_portrait_loads.is_empty():
		return
	for path: String in _pending_portrait_loads.keys():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		var targets: Array = _pending_portrait_loads[path]
		_pending_portrait_loads.erase(path)
		if status != ResourceLoader.THREAD_LOAD_LOADED:
			continue
		var texture := ResourceLoader.load_threaded_get(path) as Texture2D
		if texture == null:
			continue
		for target_data: Dictionary in targets:
			var scope := str(target_data.get("scope", ""))
			if scope == "roster" and int(target_data.get("generation", -1)) != _roster_load_generation:
				continue
			var node := target_data.get("node") as TextureRect
			if node == null or not is_instance_valid(node):
				continue
			if scope == "team":
				_team_portrait_cache[path] = texture
			else:
				_roster_texture_cache[path] = texture
			node.texture = texture


func _gui_tex(key: String) -> Texture2D:
	return _get_texture(str(GUI_ASSETS.get(key, "")))


func _get_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex := load(path) as Texture2D
	_texture_cache[path] = tex
	return tex


func _node(path: NodePath) -> Control:
	return get_node(path) as Control


func _label(path: NodePath) -> Label:
	return get_node(path) as Label

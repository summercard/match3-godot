extends SceneTree

const MonsterDb := preload("res://src/data/monster_db.gd")
const StageDb := preload("res://src/data/stage_db.gd")

const AUDIT_LOCALES := ["zh_TW", "en", "ja", "ko", "fr", "de", "es_419"]
const AUDIT_SCENES := [
	"start",
	"main",
	"stage_select",
	"battle_prepare",
	"result",
	"team",
	"album",
	"ranch",
	"inventory",
	"shop",
	"achievement",
	"settings",
	"sign_in",
	"tower",
	"mailbox",
]

var _failures: Array[String] = []
var _failure_keys: Dictionary = {}
var _monster_names: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var localization := root.get_node_or_null("Localization")
	_expect(localization != null, "Localization autoload must be available")
	if localization == null:
		_finish()
		return
	for monster: Dictionary in MonsterDb.get_all():
		var monster_name := str(monster.get("name", ""))
		if not monster_name.is_empty() and monster_name not in _monster_names:
			_monster_names.append(monster_name)

	var main := load("res://main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame

	for locale in AUDIT_LOCALES:
		localization.call("set_language_preference", locale, false)
		for scene_name in AUDIT_SCENES:
			_expect(main.switch_scene(scene_name, _scene_data(scene_name)), "%s/%s should load" % [locale, scene_name])
			await process_frame
			await process_frame
			await process_frame
			var scene := main.get_current_scene() as Control
			if scene_name == "ranch" and scene != null:
				scene.set("_active_page", "classroom")
				if scene.has_method("_sync_gui"):
					scene.call("_sync_gui")
				await process_frame
			_audit_tree(scene, locale, scene_name)

	localization.call("set_language_preference", "auto", false)
	main.queue_free()
	await process_frame
	await process_frame
	_finish()


func _scene_data(scene_name: String) -> Dictionary:
	if scene_name == "battle_prepare":
		var stage_db := StageDb.new()
		return {"stageId": "stage_1_1", "stageData": stage_db.get_stage("stage_1_1")}
	if scene_name == "result":
		return {
			"result": "win",
			"stageId": "stage_1_1",
			"turnCount": 5,
			"maxTurns": 20,
			"playerLevel": 5,
			"enemyLevel": 3,
			"stageRewards": {"gold": 80, "exp": 30, "guaranteedItems": []},
			"playerTeam": [{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "hp": 20, "maxHP": 20}],
			"enemies": [{"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "hp": 0, "maxHP": 16}],
			"capture_played_inline": true,
			"captured": true,
			"capture_target": {"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "rarity": 1},
			"capture_result_text": {"title": "收服成功", "reason": "窗口稳定"},
			"capture_item_used": {"name": "捕捉球"},
			"capture_window": {"label": "稳定", "stability": 0.82},
		}
	return {}


func _audit_tree(node: Node, locale: String, scene_name: String) -> void:
	if node == null:
		_add_failure("%s/%s has no scene root" % [locale, scene_name])
		return
	if node is Label:
		var label := node as Label
		if label.is_visible_in_tree():
			_audit_monster_text(label.text, locale, scene_name, str(label.get_path()))
			if _button_ancestor(label) != null and not label.text.contains("\n"):
				_audit_label_width(label, locale, scene_name)
	elif node is RichTextLabel:
		var rich := node as RichTextLabel
		if rich.is_visible_in_tree():
			_audit_monster_text(rich.text, locale, scene_name, str(rich.get_path()))
	elif node is Button:
		var button := node as Button
		if button.is_visible_in_tree():
			_audit_monster_text(button.text, locale, scene_name, str(button.get_path()))
			_audit_monster_text(button.tooltip_text, locale, scene_name, "%s tooltip" % button.get_path())
			_audit_button_width(button, locale, scene_name)
	for child in node.get_children():
		_audit_tree(child, locale, scene_name)


func _audit_monster_text(raw_text: String, locale: String, scene_name: String, path: String) -> void:
	if raw_text.is_empty():
		return
	for source_name in _monster_names:
		if not raw_text.contains(source_name):
			continue
		var translated_name := TranslationServer.translate(source_name)
		if translated_name == source_name:
			continue
		# Exact source labels are translated automatically by Godot. Composite
		# strings must translate the embedded name before formatting.
		if TranslationServer.translate(raw_text) == raw_text:
			_add_failure("%s/%s untranslated monster name '%s' at %s: %s" % [locale, scene_name, source_name, path, raw_text])


func _audit_label_width(label: Label, locale: String, scene_name: String) -> void:
	var display_text := TranslationServer.translate(label.text).replace("\n", " ")
	if display_text.strip_edges().is_empty():
		return
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var available := maxf(1.0, label.size.x - 4.0)
	var width := font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	if width > available + 0.5:
		_add_failure("%s/%s button label overflows at %s (%.1f > %.1f): %s" % [locale, scene_name, label.get_path(), width, available, display_text])


func _audit_button_width(button: Button, locale: String, scene_name: String) -> void:
	var display_text := TranslationServer.translate(button.text)
	if display_text.strip_edges().is_empty():
		return
	var font := button.get_theme_font("font")
	var font_size := button.get_theme_font_size("font_size")
	var available := maxf(1.0, button.size.x - 16.0)
	if button.autowrap_mode != TextServer.AUTOWRAP_OFF or display_text.contains("\n"):
		var wrapped := font.get_multiline_string_size(display_text, HORIZONTAL_ALIGNMENT_CENTER, available, font_size)
		if wrapped.y > maxf(1.0, button.size.y - 8.0) + 0.5:
			_add_failure("%s/%s wrapped button text overflows vertically at %s (%.1f > %.1f): %s" % [locale, scene_name, button.get_path(), wrapped.y, button.size.y - 8.0, display_text.replace("\n", " / ")])
		return
	var width := font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	if width > available + 0.5:
		_add_failure("%s/%s button text overflows at %s (%.1f > %.1f): %s" % [locale, scene_name, button.get_path(), width, available, display_text])


func _button_ancestor(node: Node) -> BaseButton:
	var ancestor := node.get_parent()
	for _depth in 4:
		if ancestor == null:
			return null
		if ancestor is BaseButton:
			return ancestor as BaseButton
		ancestor = ancestor.get_parent()
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_add_failure(message)


func _add_failure(message: String) -> void:
	if _failure_keys.has(message):
		return
	_failure_keys[message] = true
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LocalizedNameLayout] OK (%d locales, %d scenes)" % [AUDIT_LOCALES.size(), AUDIT_SCENES.size()])
		quit(0)
		return
	for failure in _failures:
		push_error("[LocalizedNameLayout] " + failure)
	quit(1)

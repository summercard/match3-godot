class_name CartoonTypography
extends RefCounted

const ROUND_FONT := preload("res://assets/fonts/noto-cjk/NotoSansCJK-Regular.ttc")


static func apply(root: Node, profile: String = "") -> void:
	if root == null:
		return
	var use_lobby_font := profile == "lobby" and str(root.scene_file_path).ends_with("main_lobby.tscn")
	var font := _build_lobby_font() if use_lobby_font else _build_round_font()
	_apply_node(root, font, profile)


static func _build_round_font() -> Font:
	var font := FontVariation.new()
	font.base_font = ROUND_FONT
	font.set("variation_embolden", 0.45)
	return font


static func _build_lobby_font() -> Font:
	var font := FontVariation.new()
	font.base_font = ROUND_FONT
	font.set("variation_embolden", 0.42)
	return font


static func _apply_node(node: Node, font: Font, profile: String) -> void:
	if node is Label:
		_style_label(node as Label, font, profile)
	elif node is Button:
		_style_button(node as Button, font)
	for child in node.get_children():
		_apply_node(child, font, profile)


static func fit_label(label: Label, preferred_size: int = 0, minimum_size: int = 6, horizontal_padding: float = 4.0) -> void:
	if label == null:
		return
	var font := label.get_theme_font("font")
	var fitted := preferred_size if preferred_size > 0 else maxi(label.get_theme_font_size("font_size"), 1)
	var available_width := maxf(1.0, label.size.x - horizontal_padding)
	var display_text := TranslationServer.translate(label.text).replace("\n", " ")
	while fitted > minimum_size and font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x > available_width:
		fitted -= 1
	label.add_theme_font_size_override("font_size", fitted)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true


static func _style_label(label: Label, font: Font, profile: String) -> void:
	label.add_theme_font_override("font", font)
	var target_size := _target_font_size(label, profile)
	target_size = _fit_font_size(label, font, target_size)
	label.add_theme_font_size_override("font_size", target_size)
	var outline := _target_outline_size(label, profile)
	label.add_theme_constant_override("outline_size", outline)
	if not label.has_theme_color_override("font_outline_color"):
		label.add_theme_color_override("font_outline_color", Color(0.30, 0.13, 0.04, 0.82))
	if profile == "lobby" and _is_bottom_nav_label(label):
		label.add_theme_color_override("font_outline_color", Color(1.0, 0.93, 0.68, 0.70))
	var localized_text := TranslationServer.translate(label.text)
	if not _requires_single_line(label) and label.size.y >= float(target_size) * 1.8 and (localized_text.contains("\n") or font.get_string_size(localized_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, target_size).x > label.size.x):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
	elif _requires_single_line(label):
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true


static func _style_button(button: Button, font: Font) -> void:
	button.add_theme_font_override("font", font)
	var fitted := maxi(button.get_theme_font_size("font_size"), 1)
	var display_text := TranslationServer.translate(button.text).replace("\n", " ")
	var available_width := maxf(1.0, button.size.x - 16.0)
	while fitted > 6 and font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x > available_width:
		fitted -= 1
	button.add_theme_font_size_override("font_size", fitted)
	button.clip_text = true


static func _fit_font_size(label: Label, font: Font, preferred_size: int) -> int:
	var available_width := maxf(1.0, label.size.x - 4.0)
	var raw_text := TranslationServer.translate(label.text)
	var localized_text := raw_text.replace("\n", " ")
	if localized_text.is_empty() or available_width <= 4.0:
		return preferred_size
	var fitted := preferred_size
	var minimum_size := 6 if _requires_single_line(label) else 8
	var can_wrap := not _requires_single_line(label) and label.size.y >= float(preferred_size) * 1.8
	while fitted > minimum_size:
		var fits := false
		if can_wrap:
			var wrapped_size := font.get_multiline_string_size(raw_text, HORIZONTAL_ALIGNMENT_LEFT, available_width, fitted)
			fits = wrapped_size.x <= available_width and wrapped_size.y <= maxf(1.0, label.size.y - 2.0)
		else:
			fits = font.get_string_size(localized_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x <= available_width
		if fits:
			break
		fitted -= 1
	return fitted


static func _requires_single_line(label: Label) -> bool:
	var path := str(label.get_path())
	if label.text.contains("\n"):
		return false
	if _is_button_label(label):
		return true
	if path.find("PrimaryButtons/") != -1 and label.name == "Text":
		return true
	return (path.find("TeamPanel/Cards/TeamCard") != -1 or path.find("EnemyPanel/Cards/EnemyCard") != -1) and label.name == "Name"


static func _is_button_label(label: Label) -> bool:
	var ancestor: Node = label.get_parent()
	for _depth in 4:
		if ancestor == null:
			break
		if ancestor is BaseButton:
			return true
		ancestor = ancestor.get_parent()
	return false


static func _target_font_size(label: Label, profile: String) -> int:
	var current_size := maxi(label.get_theme_font_size("font_size"), 1)
	var path := str(label.get_path())
	var node_name := String(label.name)
	if profile == "lobby":
		if path.find("PrimaryButtons/StartButton/Text") != -1:
			return 34
		if path.find("PrimaryButtons/") != -1 and node_name == "Text":
			return 18
		if path.find("BottomNav/") != -1 and node_name == "Text":
			return 15
	if _is_button_label(label):
		return current_size
	if profile != "lobby":
		return max(current_size, 10)

	match node_name:
		"OwnerLevelTitle":
			return 14
		"LevelValue":
			return 22
		"ExpValue":
			return 9
		"GoldValue", "DiamondValue":
			return 14
		"RankTitle":
			return 9
		"RankScore":
			return 12
		_:
			return max(current_size, 14)


static func _target_outline_size(label: Label, profile: String) -> int:
	var current_outline := label.get_theme_constant("outline_size")
	if profile != "lobby":
		return max(current_outline, 1)
	var path := str(label.get_path())
	if path.find("PrimaryButtons/StartButton/Text") != -1:
		return max(current_outline, 4)
	if path.find("PrimaryButtons/") != -1:
		return max(current_outline, 3)
	if label.name in ["LevelValue", "ExpValue"]:
		return max(current_outline, 2)
	return max(current_outline, 1)


static func _is_bottom_nav_label(label: Label) -> bool:
	return str(label.get_path()).find("BottomNav/") != -1 and label.name == "Text"

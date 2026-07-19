extends SceneTree

const FONT_PATH := "res://assets/fonts/noto-cjk/NotoSansCJK-Regular.ttc"
const SYMBOL_FONT_PATH := "res://assets/fonts/noto-symbols/NotoSansSymbols2-Regular.ttf"
const EMOJI_FONT_PATH := "res://assets/fonts/noto-symbols/NotoColorEmoji_WindowsCompatible.ttf"
const LOCALES := ["zh_CN", "zh_TW", "en", "ja", "ko", "fr", "de", "es_419"]
const FACE_BY_LOCALE := {"ja": 0, "ko": 1, "zh_CN": 2, "zh_TW": 3}


func _init() -> void:
	var base_font := load(FONT_PATH) as FontFile
	var symbol_font := load(SYMBOL_FONT_PATH) as FontFile
	var emoji_font := load(EMOJI_FONT_PATH) as FontFile
	if base_font == null or symbol_font == null or emoji_font == null:
		push_error("[CatalogFontAudit] Failed to load bundled fonts")
		quit(1)
		return
	var failures: Array[String] = []
	for locale in LOCALES:
		var catalog: Dictionary = {}
		if locale == "zh_CN":
			var source_payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://localization/source_strings.json"))
			for source: Variant in (source_payload.get("messages", {}) as Dictionary).keys():
				catalog[source] = source
		else:
			catalog = JSON.parse_string(FileAccess.get_file_as_string("res://localization/locales/%s.json" % locale))
		var font := base_font.duplicate(true) as FontFile
		font.set_face_index(0, int(FACE_BY_LOCALE.get(locale, 0)))
		var missing: Dictionary = {}
		for value: Variant in catalog.values():
			var rendered := str(value)
			for index in rendered.length():
				var codepoint := rendered.unicode_at(index)
				if codepoint <= 0x20 or codepoint in [0x200B, 0x200C, 0x200D, 0xFE0E, 0xFE0F]:
					continue
				if not font.has_char(codepoint) and not symbol_font.has_char(codepoint) and not emoji_font.has_char(codepoint):
					missing[char(codepoint)] = codepoint
		if not missing.is_empty():
			failures.append("%s missing %d glyphs: %s" % [locale, missing.size(), ", ".join(missing.keys())])
		else:
			print("[CatalogFontAudit] %s OK (%d messages)" % [locale, catalog.size()])
	if failures.is_empty():
		print("[CatalogFontAudit] OK")
		quit(0)
		return
	for failure in failures:
		push_error("[CatalogFontAudit] " + failure)
	quit(1)

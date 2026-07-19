extends Node
## Selects the region-appropriate face from the bundled Noto Sans CJK
## collection. Every authored font reference points to the same TTC resource,
## so changing its active face updates Controls and custom draw code together.

signal font_changed(locale: String)

const MULTILINGUAL_FONT: FontFile = preload("res://assets/fonts/noto-cjk/NotoSansCJK-Regular.ttc")
const SYMBOL_FONT: FontFile = preload("res://assets/fonts/noto-symbols/NotoSansSymbols2-Regular.ttf")
const EMOJI_FONT: FontFile = preload("res://assets/fonts/noto-symbols/NotoColorEmoji_WindowsCompatible.ttf")
const FACE_BY_LOCALE := {
	"ja": 0,
	"ko": 1,
	"zh_CN": 2,
	"zh_TW": 3,
}

var _active_face := -1


func _ready() -> void:
	var bundled_fallbacks: Array[Font] = [SYMBOL_FONT, EMOJI_FONT]
	MULTILINGUAL_FONT.set("fallbacks", bundled_fallbacks)
	var localization := get_node_or_null("/root/Localization")
	if localization != null:
		if localization.has_signal("locale_changed"):
			localization.locale_changed.connect(_on_locale_changed)
		if localization.has_method("get_active_locale"):
			apply_locale(str(localization.call("get_active_locale")))
			return
	apply_locale(TranslationServer.get_locale())


func get_font() -> Font:
	return MULTILINGUAL_FONT


func apply_locale(locale: String) -> void:
	var face := int(FACE_BY_LOCALE.get(locale, 0))
	if face == _active_face:
		return
	_active_face = face
	if MULTILINGUAL_FONT.get_cache_count() > 0:
		MULTILINGUAL_FONT.set_face_index(0, face)
		MULTILINGUAL_FONT.emit_changed()
	font_changed.emit(locale)


func has_char(character: String) -> bool:
	return not character.is_empty() and MULTILINGUAL_FONT.has_char(character.unicode_at(0))


func _on_locale_changed(locale: String, _preference: String) -> void:
	apply_locale(locale)

extends Node
## Runtime localization service for the mobile build.
##
## Translation files are plain JSON dictionaries under res://localization/locales.
## Their keys are the original Simplified Chinese source strings. Keeping the
## source text as the message id lets authored .tscn controls use Godot's native
## automatic translation while code can use text()/format_text().

signal locale_changed(locale: String, preference: String)

const AUTO_LANGUAGE := "auto"
const DEFAULT_LOCALE := "en"
const SOURCE_LOCALE := "zh_CN"
const GAME_TITLE_SOURCE := "萌灵消消大冒险"
const LOCALES_DIR := "res://localization/locales"
const SUPPORTED_LOCALES: PackedStringArray = [
	"zh_CN",
	"zh_TW",
	"en",
	"ja",
	"ko",
	"fr",
	"de",
	"es_419",
]
const LANGUAGE_OPTIONS: Array[Dictionary] = [
	{"value": AUTO_LANGUAGE, "native_name": "自动", "name_key": "跟随系统语言"},
	{"value": "zh_CN", "native_name": "简体中文", "name_key": "简体中文"},
	{"value": "zh_TW", "native_name": "繁體中文", "name_key": "繁体中文"},
	{"value": "en", "native_name": "English", "name_key": "英语"},
	{"value": "ja", "native_name": "日本語", "name_key": "日语"},
	{"value": "ko", "native_name": "한국어", "name_key": "韩语"},
	{"value": "fr", "native_name": "Français", "name_key": "法语"},
	{"value": "de", "native_name": "Deutsch", "name_key": "德语"},
	{"value": "es_419", "native_name": "Español LATAM", "name_key": "西班牙语"},
]

var _preference: String = AUTO_LANGUAGE
var _active_locale: String = SOURCE_LOCALE
var _translations: Array[Translation] = []
var _catalogs: Dictionary = {}


func _ready() -> void:
	_install_catalogs()
	_preference = _load_preference()
	_apply_preference(_preference, false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and _preference == AUTO_LANGUAGE:
		refresh_system_locale()


func get_supported_locales() -> PackedStringArray:
	return SUPPORTED_LOCALES.duplicate()


func get_language_options() -> Array[Dictionary]:
	return LANGUAGE_OPTIONS.duplicate(true)


func get_language_preference() -> String:
	return _preference


func get_active_locale() -> String:
	return _active_locale


func get_active_language_name() -> String:
	return get_language_native_name(_active_locale)


func get_language_native_name(value: String) -> String:
	for option: Dictionary in LANGUAGE_OPTIONS:
		if str(option.get("value", "")) == value:
			return str(option.get("native_name", value))
	return value


func set_language_preference(value: String, persist: bool = true) -> bool:
	var normalized := _normalize_preference(value)
	if normalized != AUTO_LANGUAGE and normalized not in SUPPORTED_LOCALES:
		return false
	_preference = normalized
	if persist:
		_save_preference(_preference)
	_apply_preference(_preference, true)
	return true


func refresh_system_locale() -> void:
	if _preference == AUTO_LANGUAGE:
		_apply_preference(AUTO_LANGUAGE, true)


func resolve_system_locale(raw_locale: String = "") -> String:
	var raw := raw_locale.strip_edges()
	if raw.is_empty():
		# Automated tests pin their UI language explicitly; production builds do
		# not set this variable and continue to follow the mobile/browser locale.
		var test_locale := OS.get_environment("MATCH3_TEST_LOCALE").strip_edges()
		raw = test_locale if not test_locale.is_empty() else OS.get_locale()
	var normalized := raw.replace("-", "_")
	var lowered := normalized.to_lower()
	if lowered.begins_with("zh"):
		if lowered.contains("hant") or lowered.contains("_tw") or lowered.contains("_hk") or lowered.contains("_mo"):
			return "zh_TW"
		return "zh_CN"
	if lowered.begins_with("ja"):
		return "ja"
	if lowered.begins_with("ko"):
		return "ko"
	if lowered.begins_with("fr"):
		return "fr"
	if lowered.begins_with("de"):
		return "de"
	if lowered.begins_with("es"):
		return "es_419"
	if lowered.begins_with("en"):
		return "en"
	return DEFAULT_LOCALE


func text(source: String) -> String:
	if source.is_empty() or _active_locale == SOURCE_LOCALE:
		return source
	var translated := TranslationServer.translate(source)
	return source if translated.is_empty() else translated


func format_text(source: String, values: Variant) -> String:
	return text(source) % values


func has_message(source: String, locale: String = "") -> bool:
	var target := _active_locale if locale.is_empty() else locale
	if target == SOURCE_LOCALE:
		return true
	var catalog: Dictionary = _catalogs.get(target, {})
	return catalog.has(source) and not str(catalog.get(source, "")).is_empty()


func _install_catalogs() -> void:
	_translations.clear()
	_catalogs.clear()
	# Godot falls back by base language, so zh_CN can otherwise select the
	# zh_TW catalog. Register an exact Simplified Chinese identity catalog first
	# to keep both Chinese variants completely isolated.
	var source_catalog := _load_catalog(DEFAULT_LOCALE)
	var source_translation := Translation.new()
	source_translation.set_locale(SOURCE_LOCALE)
	for source: Variant in source_catalog.keys():
		source_translation.add_message(str(source), str(source))
	TranslationServer.add_translation(source_translation)
	_translations.append(source_translation)
	for locale: String in SUPPORTED_LOCALES:
		if locale == SOURCE_LOCALE:
			continue
		var catalog := _load_catalog(locale)
		_catalogs[locale] = catalog
		var translation := Translation.new()
		translation.set_locale(locale)
		for source: Variant in catalog.keys():
			var message := str(catalog[source])
			if not message.is_empty():
				translation.add_message(str(source), message)
		TranslationServer.add_translation(translation)
		_translations.append(translation)


func _load_catalog(locale: String) -> Dictionary:
	var path := "%s/%s.json" % [LOCALES_DIR, locale]
	if not FileAccess.file_exists(path):
		push_error("[Localization] Missing locale catalog: %s" % path)
		return {}
	var source := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(source)
	if parsed is not Dictionary:
		push_error("[Localization] Invalid locale catalog: %s" % path)
		return {}
	return (parsed as Dictionary).duplicate(true)


func _load_preference() -> String:
	var storage := get_node_or_null("/root/SaveManager")
	if storage != null and storage.has_method("load_settings"):
		var settings: Dictionary = storage.call("load_settings")
		return _normalize_preference(str(settings.get("language", AUTO_LANGUAGE)))
	return AUTO_LANGUAGE


func _save_preference(value: String) -> void:
	var storage := get_node_or_null("/root/SaveManager")
	if storage == null or not storage.has_method("load_settings") or not storage.has_method("save_settings"):
		return
	var settings: Dictionary = storage.call("load_settings")
	settings["language"] = value
	storage.call("save_settings", settings)


func _apply_preference(value: String, notify: bool) -> void:
	var locale := resolve_system_locale() if value == AUTO_LANGUAGE else value
	if locale not in SUPPORTED_LOCALES:
		locale = DEFAULT_LOCALE
	_active_locale = locale
	TranslationServer.set_locale(locale)
	if DisplayServer.get_name().to_lower() != "headless":
		DisplayServer.window_set_title(text(GAME_TITLE_SOURCE))
	if notify:
		locale_changed.emit(_active_locale, _preference)


func _normalize_preference(value: String) -> String:
	var normalized := value.strip_edges().replace("-", "_")
	if normalized.is_empty() or normalized.to_lower() == AUTO_LANGUAGE:
		return AUTO_LANGUAGE
	var lowered := normalized.to_lower()
	if lowered.begins_with("zh"):
		return resolve_system_locale(normalized)
	if lowered.begins_with("es"):
		return "es_419"
	for locale: String in SUPPORTED_LOCALES:
		if lowered == locale.to_lower() or lowered.begins_with(locale.to_lower() + "_"):
			return locale
	return normalized

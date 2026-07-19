extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var localization := root.get_node_or_null("Localization")
	_expect(localization != null, "Localization autoload must be available")
	if localization == null:
		_finish()
		return

	var supported: PackedStringArray = localization.call("get_supported_locales")
	_expect(supported == PackedStringArray(["zh_CN", "zh_TW", "en", "ja", "ko", "fr", "de", "es_419"]), "the release must expose exactly eight locales")
	var options: Array = localization.call("get_language_options")
	_expect(options.size() == 9, "language picker must include Auto plus eight explicit languages")

	var resolution_cases := {
		"zh-Hans-CN": "zh_CN",
		"zh-Hant-TW": "zh_TW",
		"zh_HK": "zh_TW",
		"ja-JP": "ja",
		"ko-KR": "ko",
		"fr-CA": "fr",
		"de-DE": "de",
		"es-MX": "es_419",
		"en-US": "en",
		"pt-BR": "en",
	}
	for raw_locale in resolution_cases:
		_expect(
			str(localization.call("resolve_system_locale", raw_locale)) == str(resolution_cases[raw_locale]),
			"system locale %s should resolve to %s" % [raw_locale, resolution_cases[raw_locale]]
		)

	for locale in supported:
		_expect(bool(localization.call("set_language_preference", locale, false)), "%s should be selectable" % locale)
		_expect(str(localization.call("get_active_locale")) == locale, "%s should become active" % locale)
		var server_locale := TranslationServer.get_locale()
		var server_locale_matches := server_locale == locale or (locale == "es_419" and server_locale.begins_with("es"))
		_expect(server_locale_matches, "%s should be applied to TranslationServer (reported %s)" % [locale, server_locale])
		var language_text := str(localization.call("text", "游戏语言"))
		_expect(not language_text.is_empty(), "%s should translate a settings label" % locale)
		if locale != "zh_CN":
			_expect(language_text != "游戏语言", "%s must not fall back to Simplified Chinese" % locale)
		var formatted := str(localization.call("format_text", "第%d章", 3))
		_expect(formatted.contains("3") and not formatted.contains("%d"), "%s should preserve and fill numeric placeholders" % locale)

	_expect(not bool(localization.call("set_language_preference", "unsupported", false)), "unsupported locale values must be rejected")
	localization.call("set_language_preference", "auto", false)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LocalizationRuntime] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[LocalizationRuntime] " + failure)
	quit(1)

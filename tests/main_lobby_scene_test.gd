extends SceneTree

const TestSceneCleanup := preload("res://tests/helpers/test_scene_cleanup.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	TestSceneCleanup.mute_audio_for_test(self)
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("main")
	await process_frame
	var loaded_lobby: Control = main.get_current_scene()
	_expect(loaded_lobby != null, "main scene should instantiate")
	if loaded_lobby != null:
		_expect(loaded_lobby.scene_file_path == "res://src/ui/scenes/main_lobby.tscn", "main should load editable lobby PackedScene")
		_expect(loaded_lobby.has_node("%PlayerName"), "editable player-name node should exist")
		_expect(loaded_lobby.has_node("%ExperienceFill"), "editable experience fill node should exist")
		_expect(loaded_lobby.has_node("Header/ExperienceTrack"), "owner level card should expose the experience track")
		_expect(not loaded_lobby.has_node("Header/SettingsTopButton"), "concept lobby should not expose a duplicate top settings shortcut")
		_expect(loaded_lobby.has_node("BottomNav/Panel"), "concept lobby should expose the bottom navigation panel")
		var particles := loaded_lobby.get_node("Particles")
		var effect_profile: Dictionary = particles.call("get_effect_profile")
		_expect(int(effect_profile.get("sun_rays", 0)) > 0, "lobby should expose subtle sunlight rays")
		_expect(int(effect_profile.get("motes", 0)) <= 20, "lobby ambient motes should stay restrained")
		_expect(int(effect_profile.get("sparkles", 0)) <= 8, "lobby sparkles should stay restrained")

	var lobby: Control = load("res://src/ui/scenes/main_lobby.tscn").instantiate()
	root.add_child(lobby)
	await process_frame
	var emitted_ids: Array[String] = []
	lobby.button_pressed.connect(func(button_id: String): emitted_ids.append(button_id))
	var expected_buttons := {
		"StartButton": "start",
		"TeamButton": "team",
		"RanchButton": "ranch",
		"ShopButton": "shop",
		"AlbumButton": "album",
		"InventoryButton": "inventory",
		"AchievementButton": "achievement",
		"SettingsButton": "settings",
		"SigninButton": "signin",
		"TowerButton": "tower",
		"MailboxButton": "mailbox",
	}
	_expect((lobby.get_node("PrimaryButtons/RanchButton/Text") as Label).text == "精灵课堂", "lobby ranch entry should be labeled as the spirit classroom")
	var tower_entry := lobby.get_node("PrimaryButtons/TowerButton") as TextureButton
	var shop_entry := lobby.get_node("PrimaryButtons/ShopButton") as TextureButton
	_expect(tower_entry != null and tower_entry.texture_normal == shop_entry.texture_normal, "tower should reuse the shop entry button art")
	var mailbox_entry := lobby.get_node("PrimaryButtons/MailboxButton") as TextureButton
	_expect(mailbox_entry != null and mailbox_entry.texture_normal.resource_path == "res://assets/images/mailbox_new/mailbox_lobby_envelope_icon_v1.png", "mailbox should use the square envelope icon")
	_expect(mailbox_entry.position.x <= 20.0 and mailbox_entry.position.y <= 110.0, "mailbox entry should sit near the upper-left status area")
	var mailbox_badge := lobby.get_node("%MailboxBadge") as TextureRect
	_expect(mailbox_badge != null and mailbox_badge.texture != null, "mailbox should expose a star notification badge")
	_expect(mailbox_badge.size.x <= 20.0 and mailbox_badge.position.x <= 30.0, "mailbox badge should be compact and sit near the envelope corner")
	_expect(lobby.has_node("%MailboxArrivalStar"), "new blessing arrival should animate in the lobby")
	var mailbox_burst := lobby.get_node("%MailboxArrivalBurst") as Control
	_expect(mailbox_burst != null and mailbox_burst.has_method("play"), "mailbox arrival should include a lightweight colored particle burst")
	_expect((lobby.get_node("%BlessingArrivalMessage") as Label).text == "远方的一个陌生人送来了祝福", "lobby should show the blessing-arrival message")
	_expect(not lobby.has_node("Header/TowerButton") and not lobby.has_node("Header/MailboxButton"), "tower and mailbox entries should no longer occupy the header")
	var lobby_font := (lobby.get_node("PrimaryButtons/RanchButton/Text") as Label).get_theme_font("font") as FontVariation
	_expect(lobby_font != null and lobby_font.base_font != null, "lobby labels should use the bundled rounded-font profile")
	if lobby_font != null and lobby_font.base_font != null:
		_expect(lobby_font.base_font.resource_path.ends_with("jf-openhuninn-2.1.ttf"), "lobby rounded font profile should use bundled jf open huninn")
	for button_name in expected_buttons:
		var button := lobby.get_node("%" + button_name) as TextureButton
		_expect(button != null, "%s should be editable TextureButton" % button_name)
		_expect(button.has_node("CartoonFeedback"), "%s should expose cartoon feedback" % button_name)
		var feedback_profile: Dictionary = button.get_node("CartoonFeedback").call("get_feedback_profile")
		_expect(float(feedback_profile.get("press_scale", 1.0)) > 1.0, "%s should enlarge while pressed for touch feedback" % button_name)
		_expect(is_equal_approx(float(feedback_profile.get("hover_scale", 1.0)), 1.0), "%s should not change on hover in the mobile lobby" % button_name)
		_expect(not bool(feedback_profile.get("burst", true)), "%s should not show a desktop-style release burst" % button_name)
		button.pressed.emit()
		await create_timer(0.23 if button_name == "StartButton" else 0.17).timeout
	_expect(emitted_ids == expected_buttons.values(), "all lobby buttons should preserve their navigation ids")
	lobby.set("_player", {"name": "test", "level": 4, "gold": 0, "gems": 0, "stamina": 3, "achievement_score": 250, "exp": 50, "exp_to_level": 100})
	lobby.call("_update_player_display")
	_expect(is_equal_approx(float(lobby.get_node("%ExperienceFill").get("value")), 50.0), "owner level experience bar should use a real percentage value")
	var exp_profile: Dictionary = lobby.get_node("%ExperienceFill").call("get_visual_profile")
	_expect(exp_profile.get("style", "") == "lobby_refresh", "owner level experience bar should use the lobby refresh art style")
	_expect(bool(exp_profile.get("draws_frame", false)), "owner level experience bar should draw its own frame")
	var level_badge := lobby.get_node("Header/LevelBadge") as TextureRect
	var level_value := lobby.get_node("%LevelValue") as Label
	var exp_bar := lobby.get_node("%ExperienceFill") as Control
	_expect(level_badge.visible, "owner level badge should be visible beside the experience bar")
	_expect(level_value.get_theme_font_size("font_size") == 22, "owner level number should keep the requested 22px runtime font size")
	_expect(exp_bar.size.y >= 15.0, "owner level experience bar should be tall enough to read")
	_expect(absf((level_badge.position.y + level_badge.size.y * 0.5) - (exp_bar.position.y + exp_bar.size.y * 0.5)) <= 2.0, "owner level badge and experience bar should align on the same center line")
	_expect((lobby.get_node("%StaminaValue") as Label).text == "3/5", "top resource row should show stamina as current over max")
	_expect(not (lobby.get_node("Header/RankPanel") as Control).visible, "achievement score header panel should be hidden")
	_expect((lobby.get_node("%RankScore") as Label).text.is_empty(), "hidden achievement score should not receive a runtime value")
	_expect((lobby.get_node("Header/GoldCapsule") as Control).position.y == (lobby.get_node("Header/DiamondCapsule") as Control).position.y and (lobby.get_node("Header/DiamondCapsule") as Control).position.y == (lobby.get_node("Header/StaminaCapsule") as Control).position.y, "gold, diamond and stamina should share the first row")
	_expect((lobby.get_node("Header/PlayerStatus") as Control).position.y > (lobby.get_node("Header/GoldCapsule") as Control).position.y, "owner level should sit on the second row")
	_expect(not (lobby.get_node("%TestToolButton") as Control).visible, "test tool should not have a visible lobby entry")
	var start_label := lobby.get_node("PrimaryButtons/StartButton/Text") as Label
	var nav_label := lobby.get_node("BottomNav/AlbumButton/Text") as Label
	_expect(start_label.get_theme_font("font") != null, "start text should use the shared cartoon font")
	_expect(start_label.get_theme_font_size("font_size") >= 32, "start text should be large and readable")
	_expect(nav_label.get_theme_font("font") != null, "bottom navigation text should use the shared cartoon font")
	_expect(nav_label.get_theme_font_size("font_size") >= 15, "bottom navigation text should be larger than the old compact labels")
	_expect(not lobby.has_node("Header/SettingsTopButton"), "top settings shortcut should be removed")
	for plus_path in ["Header/GoldPlus", "Header/DiamondPlus", "Header/StaminaPlus"]:
		var plus_button := lobby.get_node(plus_path) as TextureButton
		_expect(plus_button.has_node("CartoonFeedback"), "%s should expose cartoon feedback" % plus_path)
		plus_button.pressed.emit()
		await create_timer(0.17).timeout
		_expect(emitted_ids.back() == "shop", "%s should open the shop" % plus_path)

	TestSceneCleanup.queue_free_root(self)
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("[MainLobbyScene] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[MainLobbyScene] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

# ============================================
# ui/scene/scene_start.gd - 可编辑 UI 场景欢迎页控制器
# 静态视觉与按钮布局由 src/ui/scenes/start_screen.tscn 管理。
# ============================================

class_name SceneStart
extends Control

signal hold_pressed

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const FADE_SPEED := 1.8
const PULSE_SPEED := 1.7
const MONSTER_BOB_HEIGHT := 3.0
const GEM_BOB_HEIGHT := 3.5
const WELCOME_ART_LOCALES: PackedStringArray = [
	"zh_CN",
	"zh_TW",
	"en",
	"ja",
	"ko",
	"fr",
	"de",
	"es_419",
]
const TITLE_TEXTURE_PATTERN := "res://assets/images/ui/icons/localized/start_title_logo_%s.png"
const BUTTON_NORMAL_TEXTURE_PATTERN := "res://assets/images/ui/buttons/localized/start_ui_btn_start_normal_%s.png"
const BUTTON_PRESSED_TEXTURE_PATTERN := "res://assets/images/ui/buttons/localized/start_ui_btn_start_pressed_%s.png"

const MONSTER_PHASES := {
	"FireMonster": -0.5,
	"WaterMonster": 0.0,
	"GrassMonster": 0.55,
}

const GEM_PHASES := {
	"FireGem": 0.0,
	"WaterGem": 0.65,
	"GrassGem": 1.25,
	"ThunderGem": 1.9,
	"LightGem": 2.5,
}

@onready var _content: Control = %Content
@onready var _logo: TextureRect = $Content/Logo
@onready var _start_glow: TextureRect = %StartGlow
@onready var _start_button: TextureButton = %StartButton
@onready var _hint_group: Control = %HintGroup
@onready var _monster_nodes: Array[TextureRect] = [
	%FireMonster,
	%WaterMonster,
	%GrassMonster,
]
@onready var _gem_nodes: Array[TextureRect] = [
	%FireGem,
	%WaterGem,
	%GrassGem,
	%ThunderGem,
	%LightGem,
]

var _elapsed := 0.0
var _opacity := 0.0
var _entering := false
var _entry_queued := false
var _monster_base_positions: Dictionary = {}
var _gem_base_positions: Dictionary = {}

func _ready() -> void:
	name = "SceneStart"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_content.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_start_button.pressed.connect(_on_start_button_pressed)
	_apply_localized_welcome_art()
	var localization := get_node_or_null("/root/Localization")
	if localization != null and localization.has_signal("locale_changed"):
		localization.locale_changed.connect(_on_locale_changed)
	_start_glow.pivot_offset = _start_glow.size * 0.5
	_attach_button_feedback(_start_button, CartoonButtonFeedback.Profile.PRIMARY)
	for node in _monster_nodes:
		node.pivot_offset = node.size * 0.5
		_monster_base_positions[node.name] = node.position
	for node in _gem_nodes:
		node.pivot_offset = node.size * 0.5
		_gem_base_positions[node.name] = node.position

func init(_data: Dictionary = {}) -> void:
	pass

func _apply_localized_welcome_art() -> void:
	var locale := "zh_CN"
	var localization := get_node_or_null("/root/Localization")
	if localization != null and localization.has_method("get_active_locale"):
		locale = str(localization.call("get_active_locale"))
	if locale not in WELCOME_ART_LOCALES:
		locale = "zh_CN"

	var title_texture := load(TITLE_TEXTURE_PATTERN % locale) as Texture2D
	var normal_texture := load(BUTTON_NORMAL_TEXTURE_PATTERN % locale) as Texture2D
	var pressed_texture := load(BUTTON_PRESSED_TEXTURE_PATTERN % locale) as Texture2D
	if title_texture != null:
		_logo.texture = title_texture
	if normal_texture != null:
		_start_glow.texture = normal_texture
		_start_button.texture_normal = normal_texture
	if pressed_texture != null:
		_start_button.texture_pressed = pressed_texture
	_start_button.tooltip_text = tr("开始冒险")

func _on_locale_changed(_locale: String, _preference: String) -> void:
	_apply_localized_welcome_art()

func _process(delta: float) -> void:
	_elapsed += delta
	if _opacity < 1.0:
		_opacity = minf(1.0, _opacity + delta * FADE_SPEED)
	_content.modulate.a = _opacity
	_animate_monsters()
	_animate_gems()
	_animate_button()

func _animate_monsters() -> void:
	for node in _monster_nodes:
		var phase: float = MONSTER_PHASES.get(node.name, 0.0)
		var base_position: Vector2 = _monster_base_positions[node.name]
		node.position = base_position + Vector2(0.0, sin(_elapsed * PULSE_SPEED + phase) * MONSTER_BOB_HEIGHT)

func _animate_gems() -> void:
	for node in _gem_nodes:
		var phase: float = GEM_PHASES.get(node.name, 0.0)
		var pulse := sin(_elapsed * PULSE_SPEED + phase)
		node.position = _gem_base_positions[node.name] + Vector2(0.0, pulse * GEM_BOB_HEIGHT)
		node.scale = Vector2.ONE * (1.0 + pulse * 0.035)

func _animate_button() -> void:
	var pulse := 0.5 + 0.5 * sin(_elapsed * 2.0)
	_start_glow.modulate.a = 0.10 + pulse * 0.09
	_start_glow.scale = Vector2.ONE * (1.0 + pulse * 0.035)
	_hint_group.modulate.a = 0.56 + pulse * 0.28

func _on_start_button_pressed() -> void:
	if _entering or _entry_queued:
		return
	_start_glow.scale = Vector2(1.06, 1.06)
	_entry_queued = true
	get_tree().create_timer(0.24).timeout.connect(_do_enter)

func _do_enter() -> void:
	if _entering:
		return
	_entering = true
	_start_button.disabled = true
	hold_pressed.emit()
	var entry_scene := _get_entry_scene()
	var parent_node := get_parent()
	if parent_node != null and parent_node.has_method("switch_scene"):
		parent_node.switch_scene(entry_scene)
		return
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager != null and scene_manager.has_method("switch_scene"):
		scene_manager.switch_scene(entry_scene)

func _get_entry_scene() -> String:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_tutorial_progress"):
		if save_manager.has_method("has_tutorial_progress") and not save_manager.has_tutorial_progress():
			if save_manager.has_method("has_player_data") and save_manager.has_player_data():
				return "main"
			return "tutorial"
		var progress: Dictionary = save_manager.load_tutorial_progress()
		if not progress.get("completed", false):
			return "tutorial"
	return "main"

func _attach_button_feedback(button: BaseButton, profile: int) -> void:
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)

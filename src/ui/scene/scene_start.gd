# ============================================
# ui/scene/scene_start.gd - 可编辑 UI 场景欢迎页控制器
# 静态视觉与按钮布局由 src/ui/scenes/start_screen.tscn 管理。
# ============================================

class_name SceneStart
extends Control

signal hold_pressed

const FADE_SPEED := 1.8
const PULSE_SPEED := 1.7
const MONSTER_BOB_HEIGHT := 3.0
const GEM_BOB_HEIGHT := 3.5

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
var _monster_base_positions: Dictionary = {}
var _gem_base_positions: Dictionary = {}

func _ready() -> void:
	name = "SceneStart"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_content.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_start_button.button_down.connect(_on_start_button_down)
	_start_button.button_up.connect(_on_start_button_up)
	_start_button.tooltip_text = "开始冒险"
	_start_glow.pivot_offset = _start_glow.size * 0.5
	_start_button.pivot_offset = _start_button.size * 0.5
	for node in _monster_nodes:
		node.pivot_offset = node.size * 0.5
		_monster_base_positions[node.name] = node.position
	for node in _gem_nodes:
		node.pivot_offset = node.size * 0.5
		_gem_base_positions[node.name] = node.position

func init(_data: Dictionary = {}) -> void:
	pass

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

func _on_start_button_down() -> void:
	if _entering:
		return
	_start_button.scale = Vector2(0.96, 0.96)
	_start_glow.scale = Vector2(1.06, 1.06)
	_do_enter()

func _on_start_button_up() -> void:
	_start_button.scale = Vector2.ONE

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
			return "main"
		var progress: Dictionary = save_manager.load_tutorial_progress()
		if not progress.get("completed", false):
			return "tutorial"
	return "main"

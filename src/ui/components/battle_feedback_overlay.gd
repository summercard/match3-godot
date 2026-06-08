class_name BattleFeedbackOverlay
extends Control

var owner_scene: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	if owner_scene != null and owner_scene.has_method("_draw_top_feedback_layer"):
		owner_scene._draw_top_feedback_layer(self)

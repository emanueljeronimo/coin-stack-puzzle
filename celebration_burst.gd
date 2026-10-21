class_name CelebrationBurst
extends Control

const FireworksScript := preload("res://celebration_fireworks.gd")

var _fireworks: Control = null
var _built := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 320
	_fireworks = FireworksScript.new()
	_fireworks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fireworks)

func play_for_card(card: Control, ui_scale: float) -> void:
	if card == null:
		return
	_ensure_built()
	visible = true
	if _fireworks != null and _fireworks.has_method("play_around_card"):
		_fireworks.play_around_card(card, ui_scale)

func stop() -> void:
	if _fireworks != null and _fireworks.has_method("stop"):
		_fireworks.stop()
	visible = false

class_name DialogBuilderService
extends RefCounted

static func create_modal_overlay(alpha: float, z_index: int) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, alpha)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	overlay.z_as_relative = false
	overlay.z_index = z_index
	return overlay

static func dialog_scale(viewport_size: Vector2, min_scale: float = 0.75, max_scale: float = 1.2) -> float:
	var raw: float = minf(viewport_size.x / 1080.0, viewport_size.y / 1920.0)
	return clampf(raw, min_scale, max_scale)

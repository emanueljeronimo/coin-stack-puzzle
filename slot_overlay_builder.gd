class_name SlotOverlayBuilder
extends RefCounted

static func create_overlay_root(z_index: int = 12) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	root.z_index = z_index
	return root

static func create_full_rect_texture_panel(panel_script: GDScript) -> TextureRect:
	var panel: TextureRect = panel_script.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	return panel

static func create_full_rect_hairline_panel() -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	return panel

static func snap_rect(pos: Vector2, size: Vector2) -> Rect2:
	var snapped_pos := Vector2(roundf(pos.x), roundf(pos.y))
	var snapped_size := Vector2(maxf(1.0, roundf(size.x)), maxf(1.0, roundf(size.y)))
	return Rect2(snapped_pos, snapped_size)

static func inner_corner_radius(outer_px: int, inset_px: int) -> int:
	return maxi(outer_px - inset_px, 0)

static func apply_inset_full_rect(control: Control, inset_px: int) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = inset_px
	control.offset_top = inset_px
	control.offset_right = -inset_px
	control.offset_bottom = -inset_px

static func apply_frame_style(panel: Panel, corner_px: int, color: Color) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.draw_center = true
	style.anti_aliasing = true
	style.set_border_width_all(0)
	style.set_corner_radius_all(maxi(corner_px, 0))
	panel.add_theme_stylebox_override("panel", style)

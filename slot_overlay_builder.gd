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

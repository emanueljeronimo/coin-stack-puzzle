class_name UiStyleUtils
extends RefCounted

static func make_outlined_label(text: String, font_size: int, font: Font, font_color: Color, outline_color: Color, outline_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_color)
	lbl.add_theme_color_override("font_outline_color", outline_color)
	lbl.add_theme_constant_override("outline_size", outline_size)
	if font != null:
		lbl.add_theme_font_override("font", font)
	return lbl

static func flat_style(bg: Color, border: Color, radius: int, border_w: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_w
	style.border_width_top = border_w
	style.border_width_right = border_w
	style.border_width_bottom = border_w
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

static func apply_button_style(btn: Button, bg: Color, border: Color, radius: int, font_color: Color, outline_color: Color, outline_size: int) -> void:
	if btn == null:
		return
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_outline_color", outline_color)
	btn.add_theme_constant_override("outline_size", outline_size)
	var style := flat_style(bg, border, radius)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
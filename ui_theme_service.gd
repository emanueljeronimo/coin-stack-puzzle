class_name UiThemeService
extends RefCounted

static func uses_rainbow_ui(palette: Dictionary) -> bool:
	return bool(palette.get("rainbow_ui", false))

static func settings_card_colors(palette: Dictionary, bg_fallback: Color, border_fallback: Color) -> Dictionary:
	var card_bg: Color = palette.get("settings_card_bg", bg_fallback)
	card_bg = card_bg.lightened(0.18)
	var card_border: Color = palette.get("settings_card_border", border_fallback)
	card_border = card_border.darkened(0.35)
	return {"bg": card_bg, "border": card_border}

## Relleno crema + borde oscuro del mismo tono que los botones candy.
static func candy_dialog_colors(palette: Dictionary) -> Dictionary:
	var fill: Color = palette.get("settings_card_bg", Color(0.62, 0.52, 0.82, 0.98))
	fill = fill.lightened(0.22).lerp(Color(0.99, 0.95, 0.88, 1.0), 0.42)
	fill.a = 1.0
	var accent: Color = palette.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98))
	var border := Color.from_hsv(
		accent.h,
		minf(1.0, accent.s + 0.18),
		clampf(accent.v * 0.32, 0.16, 0.30),
		1.0
	)
	var shadow := Color(border.r, border.g, border.b, 0.40)
	return {"bg": fill, "border": border, "shadow": shadow}

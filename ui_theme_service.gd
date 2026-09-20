class_name UiThemeService
extends RefCounted

static func settings_card_colors(palette: Dictionary, bg_fallback: Color, border_fallback: Color) -> Dictionary:
	var card_bg: Color = palette.get("settings_card_bg", bg_fallback)
	card_bg = card_bg.lightened(0.18)
	var card_border: Color = palette.get("settings_card_border", border_fallback)
	card_border = card_border.darkened(0.35)
	return {"bg": card_bg, "border": card_border}

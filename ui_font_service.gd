class_name UiFontService
extends RefCounted

const DisplayFont = preload("res://Fonts/Lobster-Regular.ttf")
const FallbackFont = preload("res://Fonts/Chewy-Regular.ttf")

static var _cached: Font = null

## Lobster en toda la UI; Chewy solo si falta un glifo (↩, ∞).
static func ui_font() -> Font:
	if _cached != null:
		return _cached
	if DisplayFont == null:
		return FallbackFont
	var variation := FontVariation.new()
	variation.base_font = DisplayFont
	if FallbackFont != null:
		variation.fallbacks = [FallbackFont]
	_cached = variation
	return _cached

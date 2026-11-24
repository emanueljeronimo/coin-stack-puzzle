class_name HudBannerLayoutService
extends RefCounted

const FALLBACK_ASPECT := 3.2
## Capsula interna de cartel-diamantes.png (derecha del diamante, izquierda de las hojas).
const DIAMOND_LABEL_LEFT := 0.30
const DIAMOND_LABEL_RIGHT := 0.84
const DIAMOND_LABEL_TOP := 0.16
const DIAMOND_LABEL_BOTTOM := 0.16
const BANNER_VALUE_FONT_RATIO := 0.44
const BANNER_VALUE_FONT_MAX := 44

static func size_for_height(tex_size: Vector2, height: float) -> Vector2:
	var h: float = maxf(height, 1.0)
	if tex_size.y <= 0.0:
		return Vector2(h * FALLBACK_ASPECT, h)
	return Vector2(h * (tex_size.x / tex_size.y), h)

static func size_for_width(tex_size: Vector2, width: float) -> Vector2:
	var w: float = maxf(width, 1.0)
	if tex_size.x <= 0.0:
		return Vector2(w, w / FALLBACK_ASPECT)
	return Vector2(w, w * (tex_size.y / tex_size.x))

static func diamond_label_rect(size: Vector2) -> Rect2:
	var left: float = size.x * DIAMOND_LABEL_LEFT
	var right: float = size.x * (1.0 - DIAMOND_LABEL_RIGHT)
	var top: float = size.y * DIAMOND_LABEL_TOP
	var text_w: float = maxf(28.0, size.x - left - right)
	var text_h: float = maxf(16.0, size.y - top - size.y * DIAMOND_LABEL_BOTTOM)
	return Rect2(left, top, text_w, text_h)

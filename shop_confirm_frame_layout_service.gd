class_name ShopConfirmFrameLayoutService
extends RefCounted

## Fracciones de cartel-confirmar-compra.png (1312x1199).
const ICON_FRAC := Rect2(0.18, 0.055, 0.64, 0.145)
const TITLE_FRAC := Rect2(0.14, 0.248, 0.72, 0.255)
const ACCEPT_FRAC := Rect2(0.158, 0.538, 0.684, 0.132)
const CANCEL_FRAC := Rect2(0.154, 0.722, 0.691, 0.118)
const FALLBACK_ASPECT := 1.094
const TITLE_FONT_RATIO := 0.36
const ACCEPT_FONT_RATIO := 0.52
const CANCEL_FONT_RATIO := 0.52
const ICON_RATIO := 0.78

static func card_size(viewport: Vector2, tex_size: Vector2) -> Vector2:
	var aspect: float = FALLBACK_ASPECT
	if tex_size.y > 0.0:
		aspect = tex_size.x / tex_size.y
	var max_w: float = viewport.x * 0.90
	var max_h: float = viewport.y * 0.72
	var w: float = max_w
	var h: float = w / aspect
	if h > max_h:
		h = max_h
		w = h * aspect
	return Vector2(w, h)

static func mapped_rect(card: Vector2, frac: Rect2) -> Rect2:
	return Rect2(
		card.x * frac.position.x,
		card.y * frac.position.y,
		card.x * frac.size.x,
		card.y * frac.size.y
	)

static func title_font_size(title_h: float) -> int:
	return int(clampf(title_h * TITLE_FONT_RATIO, 36.0, 72.0))

static func pill_font_size(pill_h: float) -> int:
	return int(clampf(pill_h * ACCEPT_FONT_RATIO, 28.0, 64.0))

static func icon_side(icon_h: float) -> float:
	return clampf(icon_h * ICON_RATIO, 48.0, 120.0)

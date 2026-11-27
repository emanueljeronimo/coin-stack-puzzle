class_name AboutFrameLayoutService
extends RefCounted

## Fracciones de cartel-acerca-de.png (937x1311).
const CLOSE_FRAC := Rect2(0.828, 0.028, 0.155, 0.115)
const INTRO_FRAC := Rect2(0.188, 0.462, 0.624, 0.090)
const WELL_FRAC := Rect2(0.118, 0.592, 0.764, 0.238)
const FALLBACK_ASPECT := 0.715
const INTRO_FONT_RATIO := 0.70
const BODY_FONT_RATIO := 0.145

static func card_size(viewport: Vector2, tex_size: Vector2) -> Vector2:
	var aspect: float = FALLBACK_ASPECT
	if tex_size.y > 0.0:
		aspect = tex_size.x / tex_size.y
	var max_w: float = viewport.x * 0.92
	var max_h: float = viewport.y * 0.90
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

static func intro_font_size(intro_h: float) -> int:
	return int(clampf(intro_h * INTRO_FONT_RATIO, 52.0, 80.0))

static func body_font_size(well_h: float) -> int:
	return int(clampf(well_h * BODY_FONT_RATIO, 36.0, 46.0))

static func body_line_spacing(font_size: int) -> int:
	return maxi(int(round(float(font_size) * 0.06)), 2)

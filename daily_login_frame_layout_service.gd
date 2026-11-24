class_name DailyLoginFrameLayoutService
extends RefCounted

## Fracciones de cartel-login.png (1230x1179).
const TITLE_FRAC := Rect2(0.18, 0.018, 0.64, 0.142)
const CLOSE_FRAC := Rect2(0.855, 0.035, 0.135, 0.155)
const FOOTER_FRAC := Rect2(0.125, 0.828, 0.810, 0.125)
const FOOTER_TEXT_FRAC := Rect2(0.085, 0.829, 0.806, 0.091)
const CELL_FRACS: Array[Rect2] = [
	Rect2(0.095, 0.211, 0.393, 0.278),
	Rect2(0.512, 0.211, 0.393, 0.278),
	Rect2(0.095, 0.517, 0.393, 0.290),
	Rect2(0.512, 0.517, 0.393, 0.290),
]
const FALLBACK_ASPECT := 1.043
const TITLE_FONT_RATIO := 0.72
const CELL_ICON_RATIO := 0.46
const CELL_QTY_RATIO := 0.22
const CELL_BTN_RATIO := 0.32
const CELL_BTN_FONT_RATIO := 0.54
const CELL_BOTTOM_PAD_RATIO := 0.035
const CELL_REWARD_GAP_RATIO := 0.11
const FOOTER_FONT_RATIO := 0.74

static func title_font_size(title_h: float) -> int:
	return int(clampf(title_h * TITLE_FONT_RATIO, 44.0, 92.0))

static func cell_icon_side(cell_h: float) -> float:
	return clampf(cell_h * CELL_ICON_RATIO, 72.0, 180.0)

static func cell_qty_font_size(cell_h: float) -> int:
	return int(clampf(cell_h * CELL_QTY_RATIO, 28.0, 58.0))

static func cell_btn_height(cell_h: float) -> float:
	return clampf(cell_h * CELL_BTN_RATIO, 56.0, 108.0)

static func cell_btn_font_size(btn_h: float) -> int:
	return int(clampf(btn_h * CELL_BTN_FONT_RATIO, 24.0, 50.0))

static func cell_bottom_pad(cell_h: float) -> int:
	return int(clampf(cell_h * CELL_BOTTOM_PAD_RATIO, 6.0, 12.0))

static func cell_reward_gap(cell_h: float) -> int:
	return int(clampf(cell_h * CELL_REWARD_GAP_RATIO, 12.0, 28.0))

static func footer_font_size(footer_h: float) -> int:
	return int(clampf(footer_h * FOOTER_FONT_RATIO, 48.0, 96.0))

static func card_size(viewport: Vector2, tex_size: Vector2) -> Vector2:
	var aspect: float = FALLBACK_ASPECT
	if tex_size.y > 0.0:
		aspect = tex_size.x / tex_size.y
	var max_w: float = viewport.x * 0.96
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

static func cell_rect(card: Vector2, index: int) -> Rect2:
	if index < 0 or index >= CELL_FRACS.size():
		return Rect2()
	return mapped_rect(card, CELL_FRACS[index])

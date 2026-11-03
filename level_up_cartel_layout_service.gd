class_name LevelUpCartelLayoutService
extends RefCounted

const WIDTH_RATIO := 0.76
const MAX_WIDTH := 760.0
const CARD_ASPECT := 0.58
const PAD_LEFT := 0.08
const PAD_RIGHT := 0.08
const PAD_TOP := 0.12
const PAD_BOTTOM := 0.14
const CORNER_RATIO := 0.22
const FILL_ALPHA := 0.82
const FILL_HI := Color(1.00, 0.86, 0.92)
const FILL_MID := Color(0.98, 0.58, 0.76)
const FILL_LO := Color(0.88, 0.38, 0.58)
const FILL_BORDER := Color(0.58, 0.22, 0.38, 1.0)
const TITLE_FONT_SIZE := 84
const TITLE_H := 100.0
const TITLE_LETTER_SPACING := 4
const LEVEL_FONT_SIZE := 76
const LEVEL_H := 92.0
const STAR_H := 90.0
const STAR_ASPECT := 1.78
const BUTTON_BORDER := Color(0.68, 0.54, 0.92, 1.0)
const BUTTON_H := 90.0
const BUTTON_MAX_W := 300.0
const BUTTON_MIN_W := 200.0
const BUTTON_WIDTH_RATIO := 0.42
const AD_WIDTH_RATIO := 0.48
const CLAIM_FONT_SIZE := 36
const AD_FONT_SIZE := 28
const BUTTON_ICON_RATIO := 0.62
const BUTTON_PAD := 12.0
const BUTTON_ICON_SEP := 8.0
const CONTINUE_FONT_SIZE := 40
const V_SEP := 16.0
const BODY_GAP_MIN := 28.0
const BUTTON_SEP := 24.0
const AD_LABEL := "x2 (ver Ad)"

static func fill_colors() -> Dictionary:
	return {
		"hi": FILL_HI,
		"mid": FILL_MID,
		"lo": FILL_LO,
		"border": FILL_BORDER,
	}

static func texture_aspect() -> float:
	return CARD_ASPECT

static func card_size(viewport_size: Vector2, ui_scale: float) -> Vector2:
	var max_w: float = minf(viewport_size.x * WIDTH_RATIO, MAX_WIDTH * ui_scale)
	var card_w: float = maxf(max_w, 280.0)
	return Vector2(card_w, card_w * CARD_ASPECT)

static func corner_radius(card: Vector2) -> int:
	return int(round(minf(card.x, card.y) * CORNER_RATIO))

static func content_margins(card: Vector2) -> Dictionary:
	return {
		"left": int(round(card.x * PAD_LEFT)),
		"right": int(round(card.x * PAD_RIGHT)),
		"top": int(round(card.y * PAD_TOP)),
		"bottom": int(round(card.y * PAD_BOTTOM)),
	}

static func reward_button_width(inner_w: float) -> float:
	return clampf(inner_w * BUTTON_WIDTH_RATIO, BUTTON_MIN_W, BUTTON_MAX_W)

static func ad_button_width(inner_w: float) -> float:
	return clampf(inner_w * AD_WIDTH_RATIO, BUTTON_MIN_W + 24.0, BUTTON_MAX_W)

static func star_icon_size(ui_scale: float) -> Vector2:
	var h: float = STAR_H * ui_scale
	return Vector2(h * STAR_ASPECT, h)

static func button_border_color() -> Color:
	return BUTTON_BORDER

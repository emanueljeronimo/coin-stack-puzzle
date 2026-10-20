class_name LevelUpCartelLayoutService
extends RefCounted

const TEX_WIDTH := 1536.0
const TEX_HEIGHT := 1024.0
const WIDTH_RATIO := 0.96
const MAX_WIDTH := 980.0
const PAD_LEFT := 0.16
const PAD_RIGHT := 0.16
const PAD_TOP := 0.26
const PAD_BOTTOM := 0.58
const TITLE_FONT_SIZE := 72
const TITLE_H := 86.0
const LEVEL_FONT_SIZE := 62
const LEVEL_H := 78.0
const STAR_H := 72.0
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
const BUTTON_SEP := 16.0
const AD_LABEL := "x2 (ver Ad)"

static func texture_aspect() -> float:
	if TEX_WIDTH <= 0.0:
		return 1.0
	return TEX_HEIGHT / TEX_WIDTH

static func card_size(viewport_size: Vector2, ui_scale: float) -> Vector2:
	var max_w: float = minf(viewport_size.x * WIDTH_RATIO, MAX_WIDTH * ui_scale)
	var card_w: float = maxf(max_w, 280.0)
	return Vector2(card_w, card_w * texture_aspect())

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

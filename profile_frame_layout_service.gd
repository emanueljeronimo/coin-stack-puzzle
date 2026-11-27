class_name ProfileFrameLayoutService
extends RefCounted

## Fracciones de menu-perfil.png (1325x1187).
const TITLE_FRAC := Rect2(0.19, 0.062, 0.62, 0.112)
const EDIT_TITLE_FRAC := Rect2(0.19, 0.082, 0.62, 0.104)
const CLOSE_FRAC := Rect2(0.828, 0.086, 0.128, 0.142)
const AVATAR_FRAC := Rect2(0.170, 0.248, 0.164, 0.156)
const NAME_FRAC := Rect2(0.352, 0.278, 0.520, 0.108)
const ACTION_FRAC := Rect2(0.108, 0.447, 0.784, 0.088)
const ACTION_TEXT_FRAC := Rect2(0.108, 0.454, 0.784, 0.074)
const STAT_LABEL_FRACS: Array[Rect2] = [
	Rect2(0.168, 0.578, 0.500, 0.078),
	Rect2(0.168, 0.680, 0.500, 0.078),
]
const STAT_CHIP_FRACS: Array[Rect2] = [
	Rect2(0.728, 0.572, 0.158, 0.090),
	Rect2(0.728, 0.674, 0.158, 0.090),
]
const EDIT_AVATAR_FRAC := Rect2(0.112, 0.250, 0.148, 0.148)
const EDIT_NAME_FRAC := Rect2(0.318, 0.290, 0.580, 0.088)
const EDIT_ACTION_FRAC := Rect2(0.108, 0.772, 0.784, 0.092)
const EDIT_ACTION_TEXT_FRAC := Rect2(0.108, 0.778, 0.784, 0.078)
const EDIT_CELL_FRACS: Array[Rect2] = [
	Rect2(0.105, 0.440, 0.142, 0.142),
	Rect2(0.265, 0.440, 0.142, 0.142),
	Rect2(0.425, 0.440, 0.142, 0.142),
	Rect2(0.585, 0.440, 0.142, 0.142),
	Rect2(0.745, 0.440, 0.142, 0.142),
	Rect2(0.105, 0.598, 0.142, 0.140),
	Rect2(0.265, 0.598, 0.142, 0.140),
	Rect2(0.425, 0.598, 0.142, 0.140),
	Rect2(0.585, 0.598, 0.142, 0.140),
	Rect2(0.745, 0.598, 0.142, 0.140),
]
const FALLBACK_ASPECT := 1.116
const TITLE_FONT_RATIO := 0.78
const NAME_FONT_RATIO := 0.56
const EDIT_NAME_FONT_RATIO := 0.78
const ACTION_FONT_RATIO := 0.62
const STAT_FONT_RATIO := 0.62
const CHIP_FONT_RATIO := 0.58
const CHIP_ICON_RATIO := 0.38
const AVATAR_CLIP_RATIO := 0.18
const PREVIEW_IMAGE_INSET_RATIO := 0.05
const PREVIEW_BORDER_RATIO := 0.045
const EDIT_CELL_IMAGE_INSET_RATIO := 0.02

static func card_size(viewport: Vector2, tex_size: Vector2) -> Vector2:
	var aspect: float = FALLBACK_ASPECT
	if tex_size.y > 0.0:
		aspect = tex_size.x / tex_size.y
	var max_w: float = viewport.x * 0.92
	var max_h: float = viewport.y * 0.82
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

static func square_in_rect(rect: Rect2) -> Rect2:
	var side: float = minf(rect.size.x, rect.size.y)
	var pos := rect.position + (rect.size - Vector2(side, side)) * 0.5
	return Rect2(pos, Vector2(side, side))

static func title_font_size(title_h: float) -> int:
	return int(clampf(title_h * TITLE_FONT_RATIO, 48.0, 96.0))

static func name_font_size(name_h: float) -> int:
	return int(clampf(name_h * NAME_FONT_RATIO, 36.0, 72.0))

static func edit_name_font_size(name_h: float) -> int:
	return int(clampf(name_h * EDIT_NAME_FONT_RATIO, 48.0, 88.0))

static func action_font_size(action_h: float) -> int:
	return int(clampf(action_h * ACTION_FONT_RATIO, 34.0, 72.0))

static func stat_font_size(row_h: float) -> int:
	return int(clampf(row_h * STAT_FONT_RATIO, 32.0, 56.0))

static func avatar_clip_radius(size: Vector2) -> float:
	return minf(size.x, size.y) * AVATAR_CLIP_RATIO

static func preview_border_width(size: Vector2) -> int:
	return int(clampf(minf(size.x, size.y) * PREVIEW_BORDER_RATIO, 4.0, 8.0))

static func preview_image_pad(size: Vector2) -> float:
	var border: float = float(preview_border_width(size))
	return clampf(minf(size.x, size.y) * PREVIEW_IMAGE_INSET_RATIO, border + 1.0, 12.0)

static func chip_font_size(chip_h: float) -> int:
	return int(clampf(chip_h * CHIP_FONT_RATIO, 30.0, 56.0))

static func chip_icon_side(chip_h: float) -> float:
	return clampf(chip_h * CHIP_ICON_RATIO, 20.0, 40.0)

static func edit_cell_rect(card: Vector2, index: int) -> Rect2:
	if index < 0 or index >= EDIT_CELL_FRACS.size():
		return Rect2()
	return mapped_rect(card, EDIT_CELL_FRACS[index])

static func edit_cell_image_pad(cell_side: float) -> float:
	return clampf(cell_side * EDIT_CELL_IMAGE_INSET_RATIO, 1.5, 5.0)

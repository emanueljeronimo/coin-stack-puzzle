class_name SettingsFrameLayoutService
extends RefCounted

## Fracciones de menu-settings.png (1223x1457).
const TITLE_FRAC := Rect2(0.18, 0.042, 0.62, 0.078)
const CLOSE_FRAC := Rect2(0.800, 0.050, 0.155, 0.090)
const TOGGLE_LABEL_FRACS: Array[Rect2] = [
	Rect2(0.110, 0.176, 0.628, 0.040),
	Rect2(0.110, 0.236, 0.628, 0.036),
	Rect2(0.110, 0.294, 0.628, 0.036),
]
const TOGGLE_PILL_FRACS: Array[Rect2] = [
	Rect2(0.766, 0.174, 0.126, 0.044),
	Rect2(0.766, 0.234, 0.126, 0.040),
	Rect2(0.766, 0.292, 0.126, 0.040),
]
const SECTION_FRAC := Rect2(0.085, 0.348, 0.830, 0.042)
const SECTION_TEXT_FRAC := Rect2(0.085, 0.352, 0.830, 0.034)
const THEME_WELL_FRAC := Rect2(0.110, 0.408, 0.780, 0.388)
const THEME_COLUMNS := 4
const THEME_SLOTS := 8
const STATUS_FRAC := Rect2(0.140, 0.768, 0.720, 0.040)
const CONTACT_FRAC := Rect2(0.086, 0.814, 0.398, 0.050)
const CONTACT_TEXT_FRAC := Rect2(0.086, 0.820, 0.398, 0.038)
const RESTORE_FRAC := Rect2(0.514, 0.814, 0.400, 0.050)
const RESTORE_TEXT_FRAC := Rect2(0.514, 0.820, 0.400, 0.038)
const TERMS_FRAC := Rect2(0.086, 0.884, 0.398, 0.048)
const TERMS_TEXT_FRAC := Rect2(0.086, 0.890, 0.398, 0.036)
const PRIVACY_FRAC := Rect2(0.514, 0.884, 0.400, 0.048)
const PRIVACY_TEXT_FRAC := Rect2(0.514, 0.890, 0.400, 0.036)
const FALLBACK_ASPECT := 0.839
const TITLE_FONT_RATIO := 0.72
const TOGGLE_LABEL_RATIO := 0.58
const TOGGLE_PILL_RATIO := 0.52
const ACTION_FONT_RATIO := 0.58
const GRID_ACTION_FONT_RATIO := 0.46
const LEGAL_FONT_RATIO := 0.55

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

static func title_font_size(title_h: float) -> int:
	return int(clampf(title_h * TITLE_FONT_RATIO, 44.0, 88.0))

static func toggle_label_font_size(row_h: float) -> int:
	return int(clampf(row_h * TOGGLE_LABEL_RATIO, 28.0, 52.0))

static func toggle_pill_font_size(pill_h: float) -> int:
	return int(clampf(pill_h * TOGGLE_PILL_RATIO, 20.0, 40.0))

static func action_font_size(action_h: float) -> int:
	return int(clampf(action_h * ACTION_FONT_RATIO, 32.0, 64.0))

static func grid_action_font_size(action_h: float) -> int:
	return int(clampf(action_h * GRID_ACTION_FONT_RATIO, 20.0, 40.0))

static func legal_font_size(legal_h: float) -> int:
	return int(clampf(legal_h * LEGAL_FONT_RATIO, 18.0, 32.0))

static func theme_cell_rect(card: Vector2, index: int) -> Rect2:
	if index < 0 or index >= THEME_SLOTS:
		return Rect2()
	var well: Rect2 = mapped_rect(card, THEME_WELL_FRAC)
	var cols: int = THEME_COLUMNS
	var rows: int = int(ceili(float(THEME_SLOTS) / float(cols)))
	var gap: float = minf(well.size.x, well.size.y) * 0.045
	var cell_w: float = (well.size.x - gap * float(cols - 1)) / float(cols)
	var cell_h: float = (well.size.y - gap * float(rows - 1)) / float(rows)
	var col: int = index % cols
	var row: int = int(index / cols)
	return Rect2(
		well.position.x + (cell_w + gap) * float(col),
		well.position.y + (cell_h + gap) * float(row),
		cell_w,
		cell_h
	)

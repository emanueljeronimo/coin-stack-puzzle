class_name SettingsFrameLayoutService
extends RefCounted

## Fracciones de menu-settings.png (1223x1457).
## Toggles a la izquierda; recuadro de version a la derecha; temas; acciones 2x2.
const TITLE_FRAC := Rect2(0.20, 0.046, 0.60, 0.086)
const CLOSE_FRAC := Rect2(0.800, 0.050, 0.155, 0.090)
const TOGGLE_LABEL_FRACS: Array[Rect2] = [
	Rect2(0.138, 0.166, 0.337, 0.049),
	Rect2(0.138, 0.224, 0.337, 0.047),
	Rect2(0.138, 0.281, 0.337, 0.047),
]
const TOGGLE_PILL_FRACS: Array[Rect2] = [
	Rect2(0.491, 0.166, 0.078, 0.049),
	Rect2(0.491, 0.224, 0.078, 0.047),
	Rect2(0.491, 0.281, 0.078, 0.047),
]
const SECTION_FRAC := Rect2(0.597, 0.168, 0.325, 0.156)
const SECTION_TEXT_FRAC := Rect2(0.610, 0.188, 0.300, 0.116)
const THEME_WELL_FRAC := Rect2(0.110, 0.364, 0.780, 0.379)
const THEME_COLUMNS := 4
const THEME_SLOTS := 8
const THEME_SLOT_FRACS: Array[Rect2] = [
	Rect2(0.112, 0.364, 0.171, 0.176),
	Rect2(0.314, 0.364, 0.170, 0.176),
	Rect2(0.516, 0.364, 0.170, 0.176),
	Rect2(0.718, 0.364, 0.170, 0.176),
	Rect2(0.110, 0.561, 0.170, 0.182),
	Rect2(0.311, 0.561, 0.170, 0.182),
	Rect2(0.517, 0.561, 0.170, 0.182),
	Rect2(0.720, 0.561, 0.170, 0.182),
]
const STATUS_FRAC := Rect2(0.140, 0.748, 0.720, 0.040)
const CONTACT_FRAC := Rect2(0.085, 0.800, 0.404, 0.057)
const CONTACT_TEXT_FRAC := Rect2(0.090, 0.805, 0.394, 0.047)
const RESTORE_FRAC := Rect2(0.512, 0.800, 0.405, 0.057)
const RESTORE_TEXT_FRAC := Rect2(0.517, 0.805, 0.395, 0.047)
const TERMS_FRAC := Rect2(0.084, 0.873, 0.405, 0.055)
const TERMS_TEXT_FRAC := Rect2(0.089, 0.878, 0.395, 0.045)
const PRIVACY_FRAC := Rect2(0.513, 0.873, 0.404, 0.055)
const PRIVACY_TEXT_FRAC := Rect2(0.518, 0.878, 0.394, 0.045)
const FALLBACK_ASPECT := 0.839
const TITLE_FONT_RATIO := 0.80
const TOGGLE_LABEL_RATIO := 0.58
const TOGGLE_PILL_RATIO := 0.52
const ACTION_FONT_RATIO := 0.58
const SECTION_FONT_RATIO := 0.28
const GRID_ACTION_FONT_RATIO := 0.62
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
	return int(clampf(title_h * TITLE_FONT_RATIO, 50.0, 96.0))

static func toggle_label_font_size(row_h: float) -> int:
	return int(clampf(row_h * TOGGLE_LABEL_RATIO, 28.0, 52.0))

static func toggle_pill_font_size(pill_h: float) -> int:
	return int(clampf(pill_h * TOGGLE_PILL_RATIO, 20.0, 40.0))

static func action_font_size(action_h: float) -> int:
	return int(clampf(action_h * ACTION_FONT_RATIO, 32.0, 64.0))

static func section_font_size(section_h: float) -> int:
	return int(clampf(section_h * SECTION_FONT_RATIO, 22.0, 40.0))

static func grid_action_font_size(action_h: float) -> int:
	return int(clampf(action_h * GRID_ACTION_FONT_RATIO, 26.0, 50.0))

static func legal_font_size(legal_h: float) -> int:
	return int(clampf(legal_h * LEGAL_FONT_RATIO, 18.0, 32.0))

static func theme_cell_rect(card: Vector2, index: int) -> Rect2:
	if index < 0 or index >= THEME_SLOT_FRACS.size():
		return Rect2()
	return mapped_rect(card, THEME_SLOT_FRACS[index])

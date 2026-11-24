class_name LoadingBarLayoutService
extends RefCounted

const TRANSIT_WIDTH_RATIO := 0.56
const BOOT_WIDTH_RATIO := 0.52
const BAR_HEIGHT := 76.0
const STATUS_GAP := 40.0
const VIOLET_A := Color(0.86, 0.70, 0.98, 1.0)
const VIOLET_B := Color(0.72, 0.42, 0.94, 1.0)
const VIOLET_C := Color(0.45, 0.20, 0.72, 1.0)
const TRACK_BG := Color(0.28, 0.16, 0.42, 0.92)
const TRACK_BORDER := Color(0.38, 0.22, 0.56, 1.0)

static func bar_height(ui_scale: float) -> float:
	return BAR_HEIGHT * maxf(ui_scale, 0.5)

static func status_gap(ui_scale: float) -> float:
	return STATUS_GAP * maxf(ui_scale, 0.5)

static func transit_width(viewport_x: float) -> float:
	return maxf(viewport_x, 0.0) * TRANSIT_WIDTH_RATIO

static func boot_width(viewport_x: float, _slot_w: float) -> float:
	return maxf(viewport_x, 0.0) * BOOT_WIDTH_RATIO

static func corner_radius(bar_h: float) -> int:
	return int(round(maxf(bar_h, 2.0) * 0.5))

static func is_violet(color: Color) -> bool:
	return color.b > color.r and color.r > color.g

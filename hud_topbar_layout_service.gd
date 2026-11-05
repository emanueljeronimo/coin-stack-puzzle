class_name HudTopbarLayoutService
extends RefCounted

## Same ratios as lobby.gd so board HUD chips match lobby size on the same viewport.
const REF_VIEWPORT_W := 1080.0
const CORNER_WIDTH_RATIO := 0.12
const STAT_WIDTH_RATIO := 0.19
const CHIP_HEIGHT_RATIO := 0.76

static func topbar_base_metrics(scale: float, hud_edge_margin: float, hud_chip_stat_w: float, hud_chip_h: float, hud_chip_gap: float) -> Dictionary:
	return {
		"edge_margin": hud_edge_margin * scale,
		"stat_w": hud_chip_stat_w * scale,
		"chip_h": hud_chip_h * scale,
		"col_gap": hud_chip_gap * scale,
	}

static func lobby_matched_metrics(viewport_w: float, hud_edge_margin: float, hud_chip_gap: float) -> Dictionary:
	var scale: float = viewport_w / REF_VIEWPORT_W if REF_VIEWPORT_W > 0.0 else 1.0
	var corner_w: float = viewport_w * CORNER_WIDTH_RATIO
	return {
		"scale": scale,
		"edge_margin": hud_edge_margin * scale,
		"stat_w": viewport_w * STAT_WIDTH_RATIO,
		"chip_h": corner_w * CHIP_HEIGHT_RATIO,
		"corner_w": corner_w,
		"col_gap": hud_chip_gap * scale,
	}

static func chip_row_y(
	min_y: float,
	board_top: float,
	chip_h: float,
	progress_h: float,
	chip_to_progress_gap: float,
	board_gap: float
) -> float:
	var stacked: float = chip_h + chip_to_progress_gap + progress_h + board_gap
	return maxf(min_y, board_top - stacked)

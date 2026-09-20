class_name HudTopbarLayoutService
extends RefCounted

static func topbar_base_metrics(scale: float, hud_edge_margin: float, hud_chip_stat_w: float, hud_chip_h: float, hud_chip_gap: float) -> Dictionary:
	return {
		"edge_margin": hud_edge_margin * scale,
		"stat_w": hud_chip_stat_w * scale,
		"chip_h": hud_chip_h * scale,
		"col_gap": hud_chip_gap * scale,
	}

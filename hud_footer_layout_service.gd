class_name HudFooterLayoutService
extends RefCounted

static func compute_footer_positions(viewport_size: Vector2, board_rect: Rect2, scale: float, cta_width_ratio: float, cta_height: float, gap: float) -> Dictionary:
	var cta_w: float = board_rect.size.x * cta_width_ratio
	var cta_h: float = cta_height * scale
	var footer_y: float = board_rect.end.y + 14.0 * scale
	var btn_gap: float = gap * scale
	return {
		"cta_w": cta_w,
		"cta_h": cta_h,
		"footer_y": footer_y,
		"btn_gap": btn_gap,
		"cta_x": (viewport_size.x - cta_w) * 0.5,
	}

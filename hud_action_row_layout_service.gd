class_name HudActionRowLayoutService
extends RefCounted

static func compute_action_row(cta_pos: Vector2, cta_h: float, icon_btn_size: float, wildcard_button_gap: float, viewport_width: float, badge_w_ratio: float = 0.72) -> Dictionary:
	var action_y: float = cta_pos.y + cta_h + 20.0
	var action_size: float = icon_btn_size
	var action_gap: float = wildcard_button_gap
	var actions_total_w: float = action_size * 3.0 + action_gap * 2.0
	var actions_start_x: float = (viewport_width - actions_total_w) * 0.5
	return {
		"action_y": action_y,
		"action_size": action_size,
		"action_gap": action_gap,
		"actions_start_x": actions_start_x,
		"badge_w_ratio": badge_w_ratio,
	}

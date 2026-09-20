class_name MainTurnResolutionService
extends RefCounted

static func should_abort_resolution(expected_revision: int, board_revision: int, has_pending_incoming: bool) -> bool:
	if expected_revision >= 0 and expected_revision != board_revision:
		return true
	return has_pending_incoming

static func level_alert_open(level_up_overlay: CanvasItem, pending_level_up_alerts: Array, pending_cycle_reset_milestone: int, cycle_reset_transition_playing: bool) -> bool:
	return (
		(level_up_overlay != null and level_up_overlay.visible)
		or not pending_level_up_alerts.is_empty()
		or pending_cycle_reset_milestone > 0
		or cycle_reset_transition_playing
	)

static func wildcard_alert_open(wildcard_unlock_overlay: CanvasItem) -> bool:
	return wildcard_unlock_overlay != null and wildcard_unlock_overlay.visible

static func should_unlock_board(level_alert_open_flag: bool, wildcard_alert_open_flag: bool) -> bool:
	return not level_alert_open_flag and not wildcard_alert_open_flag

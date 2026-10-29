class_name BoosterFlowService
extends RefCounted

static func has_uses(counts: Dictionary, booster_type: String) -> bool:
	return int(counts.get(booster_type, 0)) > 0

static func booster_action_kind(booster_type: String) -> String:
	match booster_type:
		"mix":
			return "mix"
		"hammer", "glove":
			return "tool"
		_:
			return "unknown"

## Mix se gasta al tocar el HUD. Martillo/guante solo al aplicarlos al tablero.
static func should_spend_on_hud(booster_type: String) -> bool:
	return booster_action_kind(booster_type) == "mix"

## enter: apuntar. cancel: mismo chip otra vez. switch: el otro tool. ignore: no es tool.
static func tool_hud_click(active_tool: String, clicked_type: String) -> String:
	if clicked_type != "hammer" and clicked_type != "glove":
		return "ignore"
	if active_tool == clicked_type:
		return "cancel"
	if active_tool == "hammer" or active_tool == "glove":
		return "switch"
	return "enter"

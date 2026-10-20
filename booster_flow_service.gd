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

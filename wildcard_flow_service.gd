class_name WildcardFlowService
extends RefCounted

static func has_uses(counts: Dictionary, wildcard_type: String) -> bool:
	return int(counts.get(wildcard_type, 0)) > 0

static func wildcard_action_kind(wildcard_type: String) -> String:
	match wildcard_type:
		"mix":
			return "mix"
		"hammer", "glove":
			return "tool"
		_:
			return "unknown"

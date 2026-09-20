class_name MainSessionAdapter
extends RefCounted

static func build_save_payload(builder: Callable, payload: Dictionary) -> Dictionary:
	if not builder.is_valid():
		return payload.duplicate(true)
	var out: Variant = builder.call(payload)
	if out is Dictionary:
		return (out as Dictionary).duplicate(true)
	return payload.duplicate(true)

static func parse_save_payload(parser: Callable, data: Dictionary, defaults: Dictionary) -> Dictionary:
	if not parser.is_valid():
		return defaults.duplicate(true)
	var out: Variant = parser.call(data, defaults)
	if out is Dictionary:
		return (out as Dictionary).duplicate(true)
	return defaults.duplicate(true)

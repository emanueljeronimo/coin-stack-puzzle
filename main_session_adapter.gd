class_name MainSessionAdapter
extends RefCounted

static func build_save_payload(builder: Callable, payload: Dictionary = {}) -> Dictionary:
	if not builder.is_valid():
		return payload.duplicate(true)
	# Main.collect_save_dict() is 0-arg; passing payload crashes _ready and the board never finishes opening.
	var out: Variant
	if builder.get_argument_count() > 0:
		out = builder.call(payload)
	else:
		out = builder.call()
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

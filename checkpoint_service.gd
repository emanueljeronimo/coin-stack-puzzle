class_name CheckpointService
extends RefCounted

static func build_snapshot(payload: Dictionary, snapshot_builder: Callable) -> Dictionary:
	if snapshot_builder.is_valid():
		var out: Variant = snapshot_builder.call(payload)
		if out is Dictionary:
			return (out as Dictionary).duplicate(true)
	return {}

static func read_int(snapshot: Dictionary, key: String, fallback: int) -> int:
	return int(snapshot.get(key, fallback))

static func read_float(snapshot: Dictionary, key: String, fallback: float) -> float:
	return float(snapshot.get(key, fallback))

static func read_array(snapshot: Dictionary, key: String) -> Array:
	var raw: Variant = snapshot.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []

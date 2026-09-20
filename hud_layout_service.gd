class_name HudLayoutService
extends RefCounted

func safe_scale(viewport_size: Vector2, ref_width: float, ref_height: float, min_scale: float, max_scale: float) -> float:
	if ref_width <= 0.0 or ref_height <= 0.0:
		return 1.0
	var raw: float = min(viewport_size.x / ref_width, viewport_size.y / ref_height)
	return clampf(raw, min_scale, max_scale)

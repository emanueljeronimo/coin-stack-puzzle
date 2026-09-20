class_name UiHitTestService
extends RefCounted

static func is_control_clicked(ctrl: Control, point: Vector2) -> bool:
	if ctrl == null or not ctrl.visible:
		return false
	return ctrl.get_global_rect().has_point(point)

class_name MainInputRouter
extends RefCounted

static func is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

static func _overlay_open(node: CanvasItem) -> bool:
	return node != null and node.visible

static func _panel_open(node: Variant) -> bool:
	return node != null and node.has_method("is_open") and bool(node.is_open())

static func should_block_board_input(settings_ui: Variant, shop_ui: Variant, level_up_overlay: CanvasItem, wildcard_unlock_overlay: CanvasItem, no_moves_overlay: CanvasItem, purchase_overlay: CanvasItem) -> bool:
	if _panel_open(settings_ui) or _panel_open(shop_ui):
		return true
	if _overlay_open(level_up_overlay) or _overlay_open(wildcard_unlock_overlay):
		return true
	if _overlay_open(no_moves_overlay) or _overlay_open(purchase_overlay):
		return true
	return false

static func is_control_clicked(ctrl: Control, point: Vector2) -> bool:
	if ctrl == null or not ctrl.visible:
		return false
	return ctrl.get_global_rect().has_point(point)

static func is_click_consumed_by_controls(point: Vector2, controls: Array) -> bool:
	for ctrl in controls:
		if ctrl is Control and is_control_clicked(ctrl, point):
			return true
	return false

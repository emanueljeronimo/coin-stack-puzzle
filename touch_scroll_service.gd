class_name TouchScrollService
extends RefCounted

const DEADZONE := 14.0

static func is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		return mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	return false

static func is_release(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		return mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed
	return false

static func is_drag(event: InputEvent) -> bool:
	if event is InputEventScreenDrag:
		return true
	if event is InputEventMouseMotion:
		return ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	return false

static func event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouse:
		return (event as InputEventMouse).position
	return Vector2.ZERO

static func drag_delta_y(event: InputEvent, last_y: float) -> float:
	return event_position(event).y - last_y

static func should_start_drag(press_y: float, current_y: float, deadzone: float = DEADZONE) -> bool:
	return absf(current_y - press_y) >= deadzone

static func next_scroll_vertical(current: int, delta_y: float) -> int:
	return current - int(round(delta_y))

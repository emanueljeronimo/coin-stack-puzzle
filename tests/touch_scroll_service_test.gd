extends SceneTree

const Service = preload("res://touch_scroll_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== touch_scroll_service test ===")
	_test_deadzone()
	_test_scroll_follows_drag()
	_test_mouse_drag_event()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_deadzone() -> void:
	if Service.should_start_drag(100.0, 108.0):
		_fail("inside_deadzone")
		return
	if not Service.should_start_drag(100.0, 120.0):
		_fail("outside_deadzone")
		return
	_ok("deadzone")

func _test_scroll_follows_drag() -> void:
	var next: int = Service.next_scroll_vertical(80, -20.0)
	if next != 100:
		_fail("drag_up_increases_scroll", str(next))
		return
	var down: int = Service.next_scroll_vertical(80, 30.0)
	if down != 50:
		_fail("drag_down_decreases_scroll", str(down))
		return
	_ok("scroll_follows_drag")

func _test_mouse_drag_event() -> void:
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = Vector2(0, -12)
	motion.position = Vector2(10, 40)
	if not Service.is_drag(motion):
		_fail("mouse_not_drag")
		return
	if absf(Service.drag_delta_y(motion, 52.0) + 12.0) > 0.01:
		_fail("mouse_delta", str(Service.drag_delta_y(motion, 52.0)))
		return
	if absf(Service.drag_delta_y(motion, 40.0)) > 0.01:
		_fail("same_pos_no_delta", str(Service.drag_delta_y(motion, 40.0)))
		return
	_ok("mouse_drag_event")

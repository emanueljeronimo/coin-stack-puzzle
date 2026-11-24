extends SceneTree

const Service = preload("res://loading_bar_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== loading_bar_layout_service test ===")
	_test_shorter_bar()
	_test_thicker_bar()
	_test_rounded_ends()
	_test_status_gap()
	_test_violet_stops()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_shorter_bar() -> void:
	var w: float = Service.transit_width(1080.0)
	if w > 1080.0 * 0.62:
		_fail("transit_too_long", str(w))
		return
	if w < 1080.0 * 0.40:
		_fail("transit_too_short", str(w))
		return
	var boot_w: float = Service.boot_width(1080.0, 800.0)
	if boot_w > 1080.0 * 0.62:
		_fail("boot_too_long", str(boot_w))
		return
	_ok("shorter_bar")

func _test_thicker_bar() -> void:
	if Service.bar_height(1.0) < 68.0:
		_fail("bar_too_thin", str(Service.bar_height(1.0)))
		return
	_ok("thicker_bar")

func _test_rounded_ends() -> void:
	var radius: int = Service.corner_radius(76.0)
	if radius < 36:
		_fail("not_pill", str(radius))
		return
	_ok("rounded_ends")

func _test_status_gap() -> void:
	if Service.status_gap(1.0) < 32.0:
		_fail("status_too_close", str(Service.status_gap(1.0)))
		return
	_ok("status_gap")

func _test_violet_stops() -> void:
	if not Service.is_violet(Service.VIOLET_A):
		_fail("violet_a", str(Service.VIOLET_A))
		return
	if not Service.is_violet(Service.VIOLET_B):
		_fail("violet_b", str(Service.VIOLET_B))
		return
	if not Service.is_violet(Service.VIOLET_C):
		_fail("violet_c", str(Service.VIOLET_C))
		return
	_ok("violet_stops")

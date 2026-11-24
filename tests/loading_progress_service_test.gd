extends SceneTree

const Service := preload("res://loading_progress_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== loading_progress_service test ===")
	_test_tracks_load_ratio()
	_test_finish_when_loaded()
	_test_step_display_catches_up()
	_test_shimmer_wraps()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_tracks_load_ratio() -> void:
	if absf(Service.mapped_load_target(0.0, 0.0)) > 0.001:
		_fail("zero_stays_zero", str(Service.mapped_load_target(0.0, 0.0)))
		return
	if absf(Service.mapped_load_target(0.4, 0.0) - 0.4) > 0.001:
		_fail("maps_ratio", str(Service.mapped_load_target(0.4, 0.0)))
		return
	if absf(Service.mapped_load_target(1.0, 0.4) - 1.0) > 0.001:
		_fail("maps_full", str(Service.mapped_load_target(1.0, 0.4)))
		return
	var held: float = Service.next_target(0.6, 0.2, 0.5, false)
	if absf(held - 0.6) > 0.001:
		_fail("never_shrink", str(held))
		return
	var crawled: float = Service.next_target(0.0, 0.0, 0.5, false)
	if crawled > 0.001:
		_fail("no_fake_crawl", str(crawled))
		return
	_ok("tracks_load_ratio")

func _test_finish_when_loaded() -> void:
	if Service.can_finish(false, 1.0):
		_fail("finish_while_loading")
		return
	if Service.can_finish(true, 0.5):
		_fail("finish_before_full")
		return
	if not Service.can_finish(true, 1.0):
		_fail("finish_when_full")
		return
	if absf(Service.next_target(0.4, 0.2, 0.1, true) - 1.0) > 0.001:
		_fail("loaded_target")
		return
	_ok("finish_when_loaded")

func _test_step_display_catches_up() -> void:
	var a: float = Service.step_display(0.0, 0.4, 0.02)
	if a <= 0.0 or a > 0.4 + 0.001:
		_fail("first_step", str(a))
		return
	var b: float = Service.step_display(a, 0.4, 0.02)
	if b < a:
		_fail("second_step", str(b))
		return
	var done: float = Service.step_display(0.2, 0.2, 0.05)
	if absf(done - 0.2) > 0.001:
		_fail("holds_exact", str(done))
		return
	_ok("step_display_catches_up")

func _test_shimmer_wraps() -> void:
	var band := 40.0
	var start: float = Service.shimmer_x(0.0, 200.0, band, 1.0)
	if absf(start + band) > 0.05:
		_fail("shimmer_start", str(start))
		return
	var mid: float = Service.shimmer_x(0.5, 200.0, band, 1.0)
	if mid <= start:
		_fail("shimmer_moves", str(mid))
		return
	_ok("shimmer_wraps")

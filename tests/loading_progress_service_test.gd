extends SceneTree

const Service := preload("res://loading_progress_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== loading_progress_service test ===")
	_test_mapped_load_never_shrinks()
	_test_crawl_then_finish()
	_test_step_display_eases()
	_test_shimmer_wraps()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_mapped_load_never_shrinks() -> void:
	var first: float = Service.mapped_load_target(0.0, 0.0)
	if first < Service.START_TARGET - 0.001:
		_fail("start_floor", str(first))
		return
	var later: float = Service.mapped_load_target(0.2, first)
	if later < first:
		_fail("shrunk", str(later))
		return
	var capped: float = Service.mapped_load_target(1.0, later)
	if capped > Service.LOADING_CAP + 0.001:
		_fail("over_cap", str(capped))
		return
	_ok("mapped_load_never_shrinks")

func _test_crawl_then_finish() -> void:
	var target: float = Service.next_target(0.0, 0.0, 0.5, false)
	if target <= Service.START_TARGET:
		_fail("crawl_moves", str(target))
		return
	if Service.can_finish(false, 0.5):
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
	var held: float = Service.next_target(0.8, 0.0, 0.2, false)
	if held < 0.8 - 0.001:
		_fail("never_shrink", str(held))
		return
	_ok("crawl_then_finish")

func _test_step_display_eases() -> void:
	var a: float = Service.step_display(0.0, 1.0, 0.08)
	if a <= 0.0 or a >= 1.0:
		_fail("first_step", str(a))
		return
	var b: float = Service.step_display(a, 1.0, 0.08)
	if b <= a:
		_fail("second_step", str(b))
		return
	var done: float = Service.step_display(0.999, 1.0, 1.0)
	if done < 0.995:
		_fail("reaches_end", str(done))
		return
	_ok("step_display_eases")

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

extends SceneTree

const Service = preload("res://hud_banner_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== hud_banner_layout_service test ===")
	_test_banner_size_fallback()
	_test_banner_size_aspect()
	_test_diamond_label_insets()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_banner_size_fallback() -> void:
	var by_h: Vector2 = Service.size_for_height(Vector2.ZERO, 100.0)
	if absf(by_h.y - 100.0) > 0.01 or absf(by_h.x - 320.0) > 0.01:
		_fail("size_for_height", str(by_h))
		return
	var by_w: Vector2 = Service.size_for_width(Vector2.ZERO, 320.0)
	if absf(by_w.x - 320.0) > 0.01 or absf(by_w.y - 100.0) > 0.01:
		_fail("size_for_width", str(by_w))
		return
	_ok("banner_size_fallback")

func _test_banner_size_aspect() -> void:
	var sized: Vector2 = Service.size_for_height(Vector2(895.0, 278.0), 100.0)
	var expected_w: float = 100.0 * (895.0 / 278.0)
	if absf(sized.y - 100.0) > 0.01 or absf(sized.x - expected_w) > 0.05:
		_fail("aspect_height", str(sized))
		return
	_ok("banner_size_aspect")

func _test_diamond_label_insets() -> void:
	if Service.DIAMOND_LABEL_LEFT < 0.25:
		_fail("label_left_covers_gem", str(Service.DIAMOND_LABEL_LEFT))
		return
	if Service.DIAMOND_LABEL_RIGHT > 0.90:
		_fail("label_right_covers_leaves", str(Service.DIAMOND_LABEL_RIGHT))
		return
	var rect: Rect2 = Service.diamond_label_rect(Vector2(320.0, 100.0))
	if rect.position.x < 70.0 or rect.end.x > 280.0 or rect.size.x < 80.0:
		_fail("label_rect", str(rect))
		return
	if Service.BANNER_VALUE_FONT_RATIO < 0.40 or Service.BANNER_VALUE_FONT_RATIO > 0.50:
		_fail("banner_font_mid_size", str(Service.BANNER_VALUE_FONT_RATIO))
		return
	if Service.BANNER_VALUE_FONT_MAX < 40 or Service.BANNER_VALUE_FONT_MAX > 50:
		_fail("banner_font_max_mid_size", str(Service.BANNER_VALUE_FONT_MAX))
		return
	_ok("diamond_label_insets")

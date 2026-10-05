extends SceneTree

const DialogBuilderServiceScript = preload("res://dialog_builder_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== dialog_builder_service test ===")
	_test_modal_overlay()
	_test_dialog_scale()
	_test_should_ignore_open_click()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_modal_overlay() -> void:
	var overlay := DialogBuilderServiceScript.create_modal_overlay(0.4, 123)
	if overlay == null:
		_fail("create_modal_overlay_null")
		return
	if overlay.z_index != 123:
		_fail("create_modal_overlay_z")
		return
	if overlay.visible:
		_fail("create_modal_overlay_visible")
		return
	_ok("create_modal_overlay")

func _test_dialog_scale() -> void:
	var big := DialogBuilderServiceScript.dialog_scale(Vector2(1080, 1920))
	if abs(big - 1.0) > 0.001:
		_fail("dialog_scale_base", "expected 1.0 got %f" % big)
		return
	var tiny := DialogBuilderServiceScript.dialog_scale(Vector2(200, 300))
	if tiny < 0.75 or tiny > 1.2:
		_fail("dialog_scale_clamped", "out of range %f" % tiny)
		return
	_ok("dialog_scale")

func _test_should_ignore_open_click() -> void:
	if not DialogBuilderServiceScript.should_ignore_open_click(1000, 1100, 250):
		_fail("ignore_within_grace")
		return
	if DialogBuilderServiceScript.should_ignore_open_click(1000, 1300, 250):
		_fail("allow_after_grace")
		return
	_ok("should_ignore_open_click")

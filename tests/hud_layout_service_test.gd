extends SceneTree

const HudLayoutServiceScript = preload("res://hud_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== hud_layout_service test ===")
	_test_scale_clamp()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_scale_clamp() -> void:
	var svc := HudLayoutServiceScript.new()
	var low := svc.safe_scale(Vector2(100, 100), 1080.0, 1920.0, 0.75, 1.2)
	if low != 0.75:
		_fail("low_clamp", str(low))
		return
	var high := svc.safe_scale(Vector2(4000, 4000), 1080.0, 1920.0, 0.75, 1.2)
	if high != 1.2:
		_fail("high_clamp", str(high))
		return
	_ok("scale_clamp")

extends SceneTree

const Service := preload("res://ui_font_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== ui_font_service test ===")
	_test_ui_font()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_ui_font() -> void:
	if Service.DisplayFont == null:
		_fail("display_missing")
		return
	var font: Font = Service.ui_font()
	if font == null:
		_fail("ui_font_null")
		return
	if Service.ui_font() != font:
		_fail("ui_font_cached")
		return
	var variation := font as FontVariation
	if variation == null or variation.base_font != Service.DisplayFont:
		_fail("ui_font_base")
		return
	_ok("ui_font")

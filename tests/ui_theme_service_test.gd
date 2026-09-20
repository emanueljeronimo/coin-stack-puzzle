extends SceneTree

const UiThemeServiceScript = preload("res://ui_theme_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== ui_theme_service test ===")
	_test_settings_card_colors()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_settings_card_colors() -> void:
	var palette := {
		"settings_card_bg": Color(0.2, 0.3, 0.4, 1.0),
		"settings_card_border": Color(0.8, 0.7, 0.6, 1.0),
	}
	var out := UiThemeServiceScript.settings_card_colors(palette, Color.BLACK, Color.WHITE)
	if not out.has("bg") or not out.has("border"):
		_fail("keys_present")
		return
	if not (out["bg"] is Color) or not (out["border"] is Color):
		_fail("types")
		return
	_ok("settings_card_colors")

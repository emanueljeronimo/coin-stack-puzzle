extends SceneTree

const UiStyleUtilsScript = preload("res://ui_style_utils.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== ui_style_utils test ===")
	_test_make_outlined_label()
	_test_flat_style()
	_test_apply_button_style()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_make_outlined_label() -> void:
	var lbl := UiStyleUtilsScript.make_outlined_label(
		"Hola",
		24,
		null,
		Color(1, 0, 0, 1),
		Color(0, 0, 0, 1),
		4
	)
	if lbl.text != "Hola":
		_fail("label_text", lbl.text)
		return
	if int(lbl.get_theme_font_size("font_size")) != 24:
		_fail("label_font_size", str(lbl.get_theme_font_size("font_size")))
		return
	if lbl.get_theme_color("font_color").r < 0.99:
		_fail("label_font_color", str(lbl.get_theme_color("font_color")))
		return
	_ok("make_outlined_label")

func _test_flat_style() -> void:
	var style := UiStyleUtilsScript.flat_style(
		Color(0.1, 0.2, 0.3, 1),
		Color(0.4, 0.5, 0.6, 1),
		12,
		5
	)
	if style.corner_radius_top_left != 12:
		_fail("style_radius", str(style.corner_radius_top_left))
		return
	if style.border_width_left != 5:
		_fail("style_border_width", str(style.border_width_left))
		return
	if style.bg_color.g < 0.19 or style.bg_color.g > 0.21:
		_fail("style_bg_color", str(style.bg_color))
		return
	_ok("flat_style")

func _test_apply_button_style() -> void:
	var btn := Button.new()
	UiStyleUtilsScript.apply_button_style(
		btn,
		Color(0.2, 0.3, 0.4, 1),
		Color(0.8, 0.7, 0.6, 1),
		14,
		Color(1, 1, 1, 1),
		Color(0, 0, 0, 1),
		3
	)
	var normal := btn.get_theme_stylebox("normal")
	if normal == null:
		_fail("button_normal_style")
		return
	if int(btn.get_theme_constant("outline_size")) != 3:
		_fail("button_outline_size", str(btn.get_theme_constant("outline_size")))
		return
	_ok("apply_button_style")
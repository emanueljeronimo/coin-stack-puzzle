extends SceneTree

const MarkScript := preload("res://coin_number_mark.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== coin_number_mark test ===")
	_test_face_side()
	_test_font_size()
	_test_outline_px()
	_test_outline_from_tint()
	_test_texture_side_null()
	_test_canvas_middle_draw_pos()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_face_side() -> void:
	var side: float = MarkScript.face_side(26.0, 0.86)
	if absf(side - 44.72) > 0.001:
		_fail("face_side", str(side))
		return
	_ok("face_side")

func _test_font_size() -> void:
	var small: int = MarkScript.font_size_for_side(44.72, 0.55)
	if small != 25:
		_fail("font_size_small", str(small))
		return
	var big: int = MarkScript.font_size_for_side(1024.0, 0.55)
	if big != 563:
		_fail("font_size_texture", str(big))
		return
	_ok("font_size")

func _test_outline_px() -> void:
	if MarkScript.outline_px_for_side(45.0) != 2:
		_fail("outline_min", str(MarkScript.outline_px_for_side(45.0)))
		return
	if MarkScript.outline_px_for_side(1024.0) != 46:
		_fail("outline_texture", str(MarkScript.outline_px_for_side(1024.0)))
		return
	_ok("outline_px")

func _test_outline_from_tint() -> void:
	var tint := Color(0.80, 0.40, 0.40, 1.0)
	var outline: Color = MarkScript.outline_from_tint(tint, 0.50)
	if outline.r >= tint.r or outline.g >= tint.g or outline.b >= tint.b:
		_fail("outline_darker", str(outline))
		return
	if outline.a < 0.99:
		_fail("outline_alpha", str(outline.a))
		return
	_ok("outline_from_tint")

func _test_texture_side_null() -> void:
	if MarkScript.texture_side(null) != 0.0:
		_fail("texture_side_null")
		return
	_ok("texture_side_null")

func _test_canvas_middle_draw_pos() -> void:
	var empty: Vector2 = MarkScript.canvas_middle_draw_pos(null, "2", 24)
	if empty != Vector2.ZERO:
		_fail("canvas_middle_null", str(empty))
		return
	var font: Font = ThemeDB.fallback_font
	var pos: Vector2 = MarkScript.canvas_middle_draw_pos(font, "2", 24)
	if pos.x >= 0.0:
		_fail("canvas_middle_x", str(pos))
		return
	if not is_finite(pos.y):
		_fail("canvas_middle_y", str(pos.y))
		return
	_ok("canvas_middle_draw_pos")

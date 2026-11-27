extends SceneTree

const Service = preload("res://about_frame_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== about_frame_layout_service test ===")
	_test_close_top_right()
	_test_stack_order()
	_test_wells_on_art()
	_test_card_fits_viewport()
	_test_content_scales()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_close_top_right() -> void:
	if Service.CLOSE_FRAC.position.x < 0.80 or Service.CLOSE_FRAC.position.y > 0.12:
		_fail("close_not_top_right", str(Service.CLOSE_FRAC))
		return
	_ok("close_top_right")

func _test_stack_order() -> void:
	if Service.INTRO_FRAC.end.y > Service.WELL_FRAC.position.y:
		_fail("intro_overlaps_well", str(Service.INTRO_FRAC.end.y))
		return
	if Service.WELL_FRAC.end.y > 0.85:
		_fail("well_covers_footer", str(Service.WELL_FRAC.end.y))
		return
	_ok("stack_order")

func _test_wells_on_art() -> void:
	if Service.INTRO_FRAC.position.y < 0.43 or Service.INTRO_FRAC.end.y > 0.56:
		_fail("intro_not_in_lilac_well", str(Service.INTRO_FRAC))
		return
	if Service.WELL_FRAC.position.y < 0.58 or Service.WELL_FRAC.end.y > 0.85:
		_fail("copy_not_in_cream_well", str(Service.WELL_FRAC))
		return
	_ok("wells_on_art")

func _test_card_fits_viewport() -> void:
	var vp := Vector2(1080, 1920)
	var sized: Vector2 = Service.card_size(vp, Vector2(937, 1311))
	if sized.x > vp.x or sized.y > vp.y * 0.92:
		_fail("card_too_big", str(sized))
		return
	if sized.x < 400.0 or sized.y < 500.0:
		_fail("card_too_small", str(sized))
		return
	_ok("card_fits_viewport")

func _test_content_scales() -> void:
	if Service.intro_font_size(120.0) < 70:
		_fail("intro_font_too_small", str(Service.intro_font_size(120.0)))
		return
	if Service.body_font_size(300.0) < 36:
		_fail("body_font_too_small", str(Service.body_font_size(300.0)))
		return
	if Service.body_line_spacing(32) < 0:
		_fail("body_line_spacing_tight", str(Service.body_line_spacing(32)))
		return
	var card: Vector2 = Service.card_size(Vector2(1080, 1920), Vector2(937, 1311))
	var well: Rect2 = Service.mapped_rect(card, Service.WELL_FRAC)
	if well.size.x < 400.0 or well.size.y < 200.0:
		_fail("well_too_small", str(well.size))
		return
	_ok("content_scales")

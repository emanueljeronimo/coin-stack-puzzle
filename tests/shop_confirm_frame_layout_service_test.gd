extends SceneTree

const Service = preload("res://shop_confirm_frame_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== shop_confirm_frame_layout_service test ===")
	_test_stack_order()
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

func _test_stack_order() -> void:
	var icons_bottom: float = Service.ICON_FRAC.position.y + Service.ICON_FRAC.size.y
	if icons_bottom > Service.TITLE_FRAC.position.y:
		_fail("icons_overlap_title", str(icons_bottom))
		return
	var title_bottom: float = Service.TITLE_FRAC.position.y + Service.TITLE_FRAC.size.y
	if title_bottom > Service.ACCEPT_FRAC.position.y:
		_fail("title_overlap_accept", str(title_bottom))
		return
	var accept_bottom: float = Service.ACCEPT_FRAC.position.y + Service.ACCEPT_FRAC.size.y
	if accept_bottom > Service.CANCEL_FRAC.position.y:
		_fail("accept_overlap_cancel", str(accept_bottom))
		return
	_ok("stack_order")

func _test_card_fits_viewport() -> void:
	var vp := Vector2(1080, 1920)
	var sized: Vector2 = Service.card_size(vp, Vector2(1312, 1199))
	if sized.x > vp.x or sized.y > vp.y * 0.78:
		_fail("card_too_big", str(sized))
		return
	if sized.x < 400.0 or sized.y < 360.0:
		_fail("card_too_small", str(sized))
		return
	_ok("card_fits_viewport")

func _test_content_scales() -> void:
	if Service.title_font_size(200.0) < 56:
		_fail("title_font_too_small", str(Service.title_font_size(200.0)))
		return
	if Service.pill_font_size(110.0) < 48:
		_fail("pill_font_too_small", str(Service.pill_font_size(110.0)))
		return
	if Service.icon_side(140.0) < 90.0:
		_fail("icon_too_small", str(Service.icon_side(140.0)))
		return
	_ok("content_scales")

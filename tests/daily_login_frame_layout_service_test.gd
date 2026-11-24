extends SceneTree

const Service = preload("res://daily_login_frame_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== daily_login_frame_layout_service test ===")
	_test_four_cells()
	_test_title_above_cells()
	_test_close_top_right()
	_test_card_fits_viewport()
	_test_content_scales_up()
	_test_footer_on_pill()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_four_cells() -> void:
	if Service.CELL_FRACS.size() != 4:
		_fail("cell_count", str(Service.CELL_FRACS.size()))
		return
	var card := Vector2(1000, 1000)
	var r0: Rect2 = Service.cell_rect(card, 0)
	var r1: Rect2 = Service.cell_rect(card, 1)
	if r1.position.x <= r0.position.x:
		_fail("cells_left_right", str(r0) + " " + str(r1))
		return
	_ok("four_cells")

func _test_title_above_cells() -> void:
	var title_bottom: float = Service.TITLE_FRAC.position.y + Service.TITLE_FRAC.size.y
	if title_bottom > Service.CELL_FRACS[0].position.y:
		_fail("title_overlaps_cells", str(title_bottom))
		return
	_ok("title_above_cells")

func _test_close_top_right() -> void:
	if Service.CLOSE_FRAC.position.x < 0.80 or Service.CLOSE_FRAC.position.y > 0.12:
		_fail("close_not_top_right", str(Service.CLOSE_FRAC))
		return
	_ok("close_top_right")

func _test_card_fits_viewport() -> void:
	var vp := Vector2(1080, 1920)
	var sized: Vector2 = Service.card_size(vp, Vector2(1230, 1179))
	if sized.x > vp.x or sized.y > vp.y * 0.92:
		_fail("card_too_big", str(sized))
		return
	if sized.x < 400.0 or sized.y < 400.0:
		_fail("card_too_small", str(sized))
		return
	_ok("card_fits_viewport")

func _test_content_scales_up() -> void:
	if Service.title_font_size(140.0) < 80:
		_fail("title_font_too_small", str(Service.title_font_size(140.0)))
		return
	if Service.cell_icon_side(280.0) < 118.0:
		_fail("cell_icon_too_small", str(Service.cell_icon_side(280.0)))
		return
	if Service.cell_reward_gap(280.0) < 20:
		_fail("reward_gap_too_small", str(Service.cell_reward_gap(280.0)))
		return
	if Service.cell_qty_font_size(280.0) < 40:
		_fail("qty_font_too_small", str(Service.cell_qty_font_size(280.0)))
		return
	if Service.cell_btn_height(280.0) < 80.0:
		_fail("cell_btn_too_thin", str(Service.cell_btn_height(280.0)))
		return
	if Service.cell_btn_font_size(90.0) < 40:
		_fail("cell_btn_font_too_small", str(Service.cell_btn_font_size(90.0)))
		return
	if Service.cell_bottom_pad(280.0) > 16:
		_fail("cell_bottom_pad_too_big", str(Service.cell_bottom_pad(280.0)))
		return
	_ok("content_scales_up")

func _test_footer_on_pill() -> void:
	var cells_bottom: float = Service.CELL_FRACS[2].position.y + Service.CELL_FRACS[2].size.y
	if Service.FOOTER_FRAC.position.y < cells_bottom:
		_fail("footer_overlaps_cells", str(Service.FOOTER_FRAC))
		return
	var hit: Rect2 = Service.FOOTER_FRAC
	var text: Rect2 = Service.FOOTER_TEXT_FRAC
	if text.position.x < hit.position.x - 0.05 or text.end.x > hit.end.x + 0.05:
		_fail("footer_text_outside_hit_x", str(text) + " " + str(hit))
		return
	if text.position.y < hit.position.y - 0.02 or text.end.y > hit.end.y + 0.02:
		_fail("footer_text_outside_hit_y", str(text) + " " + str(hit))
		return
	var text_c: Vector2 = text.position + text.size * 0.5
	if text_c.x > 0.50:
		_fail("footer_text_not_left", str(text_c.x))
		return
	if text_c.y > 0.885:
		_fail("footer_text_not_up", str(text_c.y))
		return
	if Service.footer_font_size(110.0) < 72:
		_fail("footer_font_too_small", str(Service.footer_font_size(110.0)))
		return
	_ok("footer_on_pill")

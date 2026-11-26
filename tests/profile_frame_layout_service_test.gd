extends SceneTree

const Service = preload("res://profile_frame_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== profile_frame_layout_service test ===")
	_test_stack_order()
	_test_close_top_right()
	_test_title_centered_in_cloud()
	_test_stats_pair()
	_test_edit_layout()
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
	var title_bottom: float = Service.TITLE_FRAC.position.y + Service.TITLE_FRAC.size.y
	if title_bottom > Service.AVATAR_FRAC.position.y:
		_fail("title_overlaps_avatar", str(title_bottom))
		return
	var avatar_bottom: float = Service.AVATAR_FRAC.position.y + Service.AVATAR_FRAC.size.y
	if avatar_bottom > Service.ACTION_FRAC.position.y:
		_fail("avatar_overlaps_action", str(avatar_bottom))
		return
	var action_bottom: float = Service.ACTION_FRAC.position.y + Service.ACTION_FRAC.size.y
	if action_bottom > Service.STAT_LABEL_FRACS[0].position.y:
		_fail("action_overlaps_stats", str(action_bottom))
		return
	var name_right: float = Service.NAME_FRAC.position.x
	var avatar_right: float = Service.AVATAR_FRAC.position.x + Service.AVATAR_FRAC.size.x
	if name_right < avatar_right:
		_fail("name_overlaps_avatar", str(name_right))
		return
	_ok("stack_order")

func _test_close_top_right() -> void:
	if Service.CLOSE_FRAC.position.x < 0.80 or Service.CLOSE_FRAC.position.y > 0.14:
		_fail("close_not_top_right", str(Service.CLOSE_FRAC))
		return
	_ok("close_top_right")

func _test_title_centered_in_cloud() -> void:
	var c: Vector2 = Service.TITLE_FRAC.position + Service.TITLE_FRAC.size * 0.5
	if c.x < 0.48 or c.x > 0.53:
		_fail("title_not_cloud_center_x", str(c.x))
		return
	if c.y < 0.10 or c.y > 0.14:
		_fail("title_not_cloud_center_y", str(c.y))
		return
	_ok("title_centered_in_cloud")

func _test_stats_pair() -> void:
	if Service.STAT_LABEL_FRACS.size() != 2 or Service.STAT_CHIP_FRACS.size() != 2:
		_fail("stats_count")
		return
	if Service.STAT_LABEL_FRACS[0].position.x < 0.15:
		_fail("stats_too_left", str(Service.STAT_LABEL_FRACS[0]))
		return
	if Service.STAT_CHIP_FRACS[0].position.x <= Service.STAT_LABEL_FRACS[0].end.x - 0.02:
		_fail("chip_not_right", str(Service.STAT_CHIP_FRACS[0]))
		return
	if Service.STAT_LABEL_FRACS[1].position.y <= Service.STAT_LABEL_FRACS[0].end.y:
		_fail("stats_not_stacked", str(Service.STAT_LABEL_FRACS[1]))
		return
	if Service.ACTION_TEXT_FRAC.position.y < Service.ACTION_FRAC.position.y:
		_fail("action_text_too_high", str(Service.ACTION_TEXT_FRAC))
		return
	if Service.ACTION_TEXT_FRAC.end.y > Service.ACTION_FRAC.end.y:
		_fail("action_text_too_low", str(Service.ACTION_TEXT_FRAC))
		return
	_ok("stats_pair")

func _test_edit_layout() -> void:
	if Service.EDIT_CELL_FRACS.size() != 10:
		_fail("edit_cell_count", str(Service.EDIT_CELL_FRACS.size()))
		return
	if Service.EDIT_CELL_FRACS[1].position.x <= Service.EDIT_CELL_FRACS[0].position.x:
		_fail("edit_cells_not_row", str(Service.EDIT_CELL_FRACS[1]))
		return
	if Service.EDIT_CELL_FRACS[5].position.y <= Service.EDIT_CELL_FRACS[0].end.y:
		_fail("edit_cells_not_two_rows", str(Service.EDIT_CELL_FRACS[5]))
		return
	if Service.EDIT_AVATAR_FRAC.end.y > Service.EDIT_CELL_FRACS[0].position.y:
		_fail("edit_avatar_overlaps_grid", str(Service.EDIT_AVATAR_FRAC))
		return
	if Service.EDIT_CELL_FRACS[5].end.y > Service.EDIT_ACTION_FRAC.position.y:
		_fail("edit_grid_overlaps_save", str(Service.EDIT_CELL_FRACS[5]))
		return
	if Service.EDIT_ACTION_FRAC.position.y < 0.70:
		_fail("edit_save_not_bottom", str(Service.EDIT_ACTION_FRAC))
		return
	if Service.EDIT_ACTION_TEXT_FRAC.position.y < Service.EDIT_ACTION_FRAC.position.y:
		_fail("edit_save_text_too_high", str(Service.EDIT_ACTION_TEXT_FRAC))
		return
	if Service.EDIT_ACTION_TEXT_FRAC.end.y > Service.EDIT_ACTION_FRAC.end.y:
		_fail("edit_save_text_too_low", str(Service.EDIT_ACTION_TEXT_FRAC))
		return
	var pad: float = Service.edit_cell_image_pad(120.0)
	if pad < 3.0 or pad > 8.0:
		_fail("edit_cell_image_pad", str(pad))
		return
	_ok("edit_layout")

func _test_card_fits_viewport() -> void:
	var vp := Vector2(1080, 1920)
	var sized: Vector2 = Service.card_size(vp, Vector2(1325, 1187))
	if sized.x > vp.x or sized.y > vp.y * 0.86:
		_fail("card_too_big", str(sized))
		return
	if sized.x < 400.0 or sized.y < 360.0:
		_fail("card_too_small", str(sized))
		return
	_ok("card_fits_viewport")

func _test_content_scales() -> void:
	if Service.title_font_size(130.0) < 70:
		_fail("title_font_too_small", str(Service.title_font_size(130.0)))
		return
	if Service.action_font_size(90.0) < 50:
		_fail("action_font_too_small", str(Service.action_font_size(90.0)))
		return
	if Service.name_font_size(90.0) < 46:
		_fail("name_font_too_small", str(Service.name_font_size(90.0)))
		return
	if Service.stat_font_size(78.0) < 44:
		_fail("stat_font_too_small", str(Service.stat_font_size(78.0)))
		return
	if Service.chip_font_size(80.0) < 42:
		_fail("chip_font_too_small", str(Service.chip_font_size(80.0)))
		return
	var preview_pad: float = Service.preview_image_pad(Vector2(150, 150))
	if preview_pad < 6.0 or preview_pad > 12.0:
		_fail("preview_image_pad", str(preview_pad))
		return
	if Service.preview_border_width(Vector2(150, 150)) < 4:
		_fail("preview_border_too_thin", str(Service.preview_border_width(Vector2(150, 150))))
		return
	var square: Rect2 = Service.square_in_rect(Rect2(10, 10, 120, 80))
	if not is_equal_approx(square.size.x, square.size.y) or square.size.x > 80.1:
		_fail("square_in_rect", str(square))
		return
	_ok("content_scales")

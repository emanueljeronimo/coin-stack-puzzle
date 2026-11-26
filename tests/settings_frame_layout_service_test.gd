extends SceneTree

const Service = preload("res://settings_frame_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== settings_frame_layout_service test ===")
	_test_stack_order()
	_test_close_top_right()
	_test_title_centered_in_cloud()
	_test_toggle_pills_right()
	_test_theme_grid()
	_test_card_fits_viewport()
	_test_slots_on_taller_art()
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
	var title_bottom: float = Service.TITLE_FRAC.end.y
	if title_bottom > Service.TOGGLE_LABEL_FRACS[0].position.y:
		_fail("title_overlaps_toggles", str(title_bottom))
		return
	if Service.TOGGLE_LABEL_FRACS[1].position.y <= Service.TOGGLE_LABEL_FRACS[0].end.y:
		_fail("toggles_not_stacked", str(Service.TOGGLE_LABEL_FRACS[1]))
		return
	if Service.TOGGLE_LABEL_FRACS[2].end.y > Service.SECTION_FRAC.position.y:
		_fail("toggles_overlap_section", str(Service.TOGGLE_LABEL_FRACS[2].end.y))
		return
	if Service.SECTION_FRAC.end.y > Service.THEME_WELL_FRAC.position.y:
		_fail("section_overlaps_themes", str(Service.SECTION_FRAC.end.y))
		return
	if Service.THEME_WELL_FRAC.end.y > Service.CONTACT_FRAC.position.y:
		_fail("themes_overlap_actions", str(Service.THEME_WELL_FRAC.end.y))
		return
	if Service.CONTACT_FRAC.end.y > Service.TERMS_FRAC.position.y:
		_fail("top_row_overlaps_bottom", str(Service.CONTACT_FRAC.end.y))
		return
	if Service.RESTORE_FRAC.position.x <= Service.CONTACT_FRAC.end.x:
		_fail("contact_overlaps_restore", str(Service.RESTORE_FRAC))
		return
	if Service.PRIVACY_FRAC.position.x <= Service.TERMS_FRAC.end.x:
		_fail("terms_overlaps_privacy", str(Service.PRIVACY_FRAC))
		return
	if Service.SECTION_TEXT_FRAC.position.y < Service.SECTION_FRAC.position.y:
		_fail("section_text_too_high", str(Service.SECTION_TEXT_FRAC))
		return
	if Service.SECTION_TEXT_FRAC.end.y > Service.SECTION_FRAC.end.y:
		_fail("section_text_too_low", str(Service.SECTION_TEXT_FRAC))
		return
	if Service.CONTACT_TEXT_FRAC.position.y < Service.CONTACT_FRAC.position.y:
		_fail("contact_text_too_high", str(Service.CONTACT_TEXT_FRAC))
		return
	if Service.TERMS_TEXT_FRAC.end.y > Service.TERMS_FRAC.end.y:
		_fail("terms_text_too_low", str(Service.TERMS_TEXT_FRAC))
		return
	if Service.PRIVACY_TEXT_FRAC.end.y > Service.PRIVACY_FRAC.end.y:
		_fail("privacy_text_too_low", str(Service.PRIVACY_TEXT_FRAC))
		return
	_ok("stack_order")

func _test_close_top_right() -> void:
	if Service.CLOSE_FRAC.position.x < 0.78 or Service.CLOSE_FRAC.position.y > 0.12:
		_fail("close_not_top_right", str(Service.CLOSE_FRAC))
		return
	_ok("close_top_right")

func _test_title_centered_in_cloud() -> void:
	var c: Vector2 = Service.TITLE_FRAC.position + Service.TITLE_FRAC.size * 0.5
	if c.x < 0.48 or c.x > 0.53:
		_fail("title_not_cloud_center_x", str(c.x))
		return
	if c.y < 0.07 or c.y > 0.11:
		_fail("title_not_cloud_center_y", str(c.y))
		return
	_ok("title_centered_in_cloud")

func _test_toggle_pills_right() -> void:
	if Service.TOGGLE_LABEL_FRACS.size() != 3 or Service.TOGGLE_PILL_FRACS.size() != 3:
		_fail("toggle_count")
		return
	for i in range(3):
		var label_right: float = Service.TOGGLE_LABEL_FRACS[i].end.x
		var pill_left: float = Service.TOGGLE_PILL_FRACS[i].position.x
		if pill_left < label_right - 0.02:
			_fail("pill_not_right", "%d %s" % [i, str(Service.TOGGLE_PILL_FRACS[i])])
			return
		if Service.TOGGLE_PILL_FRACS[i].position.x < 0.70:
			_fail("pill_not_far_right", str(Service.TOGGLE_PILL_FRACS[i]))
			return
	_ok("toggle_pills_right")

func _test_theme_grid() -> void:
	var card := Vector2(1000, 1050)
	var r0: Rect2 = Service.theme_cell_rect(card, 0)
	var r1: Rect2 = Service.theme_cell_rect(card, 1)
	var r4: Rect2 = Service.theme_cell_rect(card, 4)
	if r0.size.x <= 0.0:
		_fail("theme_cell_empty", str(r0))
		return
	if r1.position.x <= r0.position.x:
		_fail("theme_not_row", str(r1))
		return
	if r4.position.y <= r0.end.y:
		_fail("theme_not_two_rows", str(r4))
		return
	if Service.theme_cell_rect(card, 8).size.x > 0.0:
		_fail("theme_extra_slot")
		return
	var well: Rect2 = Service.mapped_rect(card, Service.THEME_WELL_FRAC)
	if r4.end.y > well.end.y + 0.5:
		_fail("theme_overflows_well", str(r4.end.y))
		return
	_ok("theme_grid")

func _test_card_fits_viewport() -> void:
	var vp := Vector2(1080, 1920)
	var sized: Vector2 = Service.card_size(vp, Vector2(1223, 1457))
	if sized.x > vp.x or sized.y > vp.y * 0.92:
		_fail("card_too_big", str(sized))
		return
	if sized.x < 400.0 or sized.y < 400.0:
		_fail("card_too_small", str(sized))
		return
	_ok("card_fits_viewport")

func _test_slots_on_taller_art() -> void:
	if Service.TOGGLE_LABEL_FRACS[0].position.y > 0.20:
		_fail("toggle_not_upper", str(Service.TOGGLE_LABEL_FRACS[0]))
		return
	if Service.SECTION_FRAC.position.y < 0.32 or Service.SECTION_FRAC.position.y > 0.38:
		_fail("section_not_mid", str(Service.SECTION_FRAC))
		return
	if Service.CONTACT_FRAC.position.y < 0.80:
		_fail("actions_not_bottom", str(Service.CONTACT_FRAC))
		return
	if Service.THEME_WELL_FRAC.size.y < 0.30:
		_fail("theme_well_too_short", str(Service.THEME_WELL_FRAC.size.y))
		return
	_ok("slots_on_taller_art")

func _test_content_scales() -> void:
	if Service.title_font_size(120.0) < 70:
		_fail("title_font_too_small", str(Service.title_font_size(120.0)))
		return
	if Service.action_font_size(80.0) < 44:
		_fail("action_font_too_small", str(Service.action_font_size(80.0)))
		return
	if Service.toggle_label_font_size(70.0) < 36:
		_fail("toggle_label_too_small", str(Service.toggle_label_font_size(70.0)))
		return
	if Service.toggle_pill_font_size(56.0) < 26:
		_fail("toggle_pill_too_small", str(Service.toggle_pill_font_size(56.0)))
		return
	if Service.legal_font_size(48.0) < 24:
		_fail("legal_font_too_small", str(Service.legal_font_size(48.0)))
		return
	if Service.grid_action_font_size(70.0) < 28:
		_fail("grid_action_too_small", str(Service.grid_action_font_size(70.0)))
		return
	_ok("content_scales")

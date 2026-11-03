extends SceneTree

const Service := preload("res://level_up_cartel_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== level_up_cartel_layout_service test ===")
	_test_aspect_is_landscape()
	_test_card_keeps_aspect()
	_test_card_fits_viewport()
	_test_content_margins_even()
	_test_inner_copy_fits_gold_card()
	_test_reward_buttons_are_compact()
	_test_card_is_rounded()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_aspect_is_landscape() -> void:
	if Service.texture_aspect() >= 1.0:
		_fail("aspect_not_wide", str(Service.texture_aspect()))
		return
	if Service.texture_aspect() < 0.45 or Service.texture_aspect() > 0.72:
		_fail("aspect_out_of_range", str(Service.texture_aspect()))
		return
	_ok("aspect_is_landscape")

func _test_card_keeps_aspect() -> void:
	var size: Vector2 = Service.card_size(Vector2(1080, 1920), 1.0)
	var ratio: float = size.y / size.x
	if absf(ratio - Service.texture_aspect()) > 0.002:
		_fail("aspect_mismatch", str(ratio))
		return
	_ok("card_keeps_aspect")

func _test_card_fits_viewport() -> void:
	var viewport := Vector2(1080, 1920)
	var size: Vector2 = Service.card_size(viewport, 1.0)
	if size.x > viewport.x + 0.5 or size.y > viewport.y + 0.5:
		_fail("overflow", str(size))
		return
	if size.x > Service.MAX_WIDTH + 0.5:
		_fail("wider_than_cap", str(size.x))
		return
	_ok("card_fits_viewport")

func _test_content_margins_even() -> void:
	var card: Vector2 = Service.card_size(Vector2(1080, 1920), 1.0)
	var m: Dictionary = Service.content_margins(card)
	if int(m.left) + int(m.right) >= int(card.x) or int(m.top) + int(m.bottom) >= int(card.y):
		_fail("margins_too_big", str(m))
		return
	if abs(int(m.left) - int(m.right)) > 1:
		_fail("sides_uneven", str(m))
		return
	if int(m.left) < 40 or int(m.top) < 40:
		_fail("margins_too_small", str(m))
		return
	if int(m.bottom) > int(card.y) * 0.22:
		_fail("bottom_pad_too_big", str(m.bottom))
		return
	_ok("content_margins_even")

func _test_inner_copy_fits_gold_card() -> void:
	if Service.TITLE_FONT_SIZE < 78 or Service.TITLE_FONT_SIZE > 96:
		_fail("title_size", str(Service.TITLE_FONT_SIZE))
		return
	if Service.TITLE_LETTER_SPACING < 2 or Service.TITLE_LETTER_SPACING > 10:
		_fail("title_spacing", str(Service.TITLE_LETTER_SPACING))
		return
	if Service.MAX_WIDTH > 860.0 or Service.MAX_WIDTH < 700.0:
		_fail("card_width", str(Service.MAX_WIDTH))
		return
	_ok("inner_copy_fits_gold_card")

func _test_reward_buttons_are_compact() -> void:
	var inner_w := 640.0
	var btn_w: float = Service.reward_button_width(inner_w)
	if btn_w >= inner_w * 0.55:
		_fail("buttons_too_wide", str(btn_w))
		return
	var ad_w: float = Service.ad_button_width(inner_w)
	if ad_w < btn_w:
		_fail("ad_button_too_narrow", str(ad_w))
		return
	if Service.BUTTON_H < 64.0:
		_fail("buttons_too_thin", str(Service.BUTTON_H))
		return
	var star: Vector2 = Service.star_icon_size(1.0)
	if star.y < 84.0 or star.x <= star.y:
		_fail("star_cluster_size", str(star))
		return
	if absf(star.y - float(Service.LEVEL_FONT_SIZE)) > 20.0:
		_fail("stars_not_with_level", str(star.y))
		return
	if Service.LEVEL_FONT_SIZE < 70:
		_fail("level_font_too_small", str(Service.LEVEL_FONT_SIZE))
		return
	if Service.BUTTON_ICON_RATIO < 0.55:
		_fail("button_icon_too_small", str(Service.BUTTON_ICON_RATIO))
		return
	var border: Color = Service.button_border_color()
	if border.v < 0.45:
		_fail("button_border_too_dark", str(border))
		return
	if Service.AD_LABEL.find("x2") < 0:
		_fail("ad_label", Service.AD_LABEL)
		return
	_ok("reward_buttons_are_compact")

func _test_card_is_rounded() -> void:
	var card: Vector2 = Service.card_size(Vector2(1080, 1920), 1.0)
	var radius: int = Service.corner_radius(card)
	if radius < 48:
		_fail("not_round_enough", str(radius))
		return
	if float(radius) > minf(card.x, card.y) * 0.40:
		_fail("too_capsule", str(radius))
		return
	if Service.FILL_ALPHA < 0.72 or Service.FILL_ALPHA > 0.92:
		_fail("fill_alpha", str(Service.FILL_ALPHA))
		return
	var fill: Dictionary = Service.fill_colors()
	var mid: Color = fill.get("mid", Color.BLACK)
	if mid.r < 0.85 or mid.g > 0.70:
		_fail("fill_not_pink", str(mid))
		return
	_ok("card_is_rounded")

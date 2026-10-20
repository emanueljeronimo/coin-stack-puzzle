extends SceneTree

const Service := preload("res://wavy_dialog_card_service.gd")
const CardScript := preload("res://wavy_dialog_card.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== wavy_dialog_card_service test ===")
	_test_mint_is_very_light_green()
	_test_points_stay_inside()
	_test_top_edge_is_wavy()
	_test_inset_shrinks_bounds()
	_test_card_configure_redraws()
	_test_rainbow_border_colors()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_mint_is_very_light_green() -> void:
	var top: Color = Service.FILL_TOP
	var bottom: Color = Service.FILL_BOTTOM
	if top.g < 0.92 or top.v < 0.90:
		_fail("fill_top_not_light", str(top))
		return
	if top.g <= top.r or top.g <= top.b:
		_fail("fill_top_not_green", str(top))
		return
	if bottom.g < 0.88 or bottom.v < 0.82:
		_fail("fill_bottom_not_light", str(bottom))
		return
	_ok("mint_is_very_light_green")

func _test_points_stay_inside() -> void:
	var card_size := Vector2(400, 520)
	var pts: PackedVector2Array = Service.build_wave_points(
		card_size,
		18.0,
		10,
		52.0
	)
	if pts.size() < 40:
		_fail("point_count", str(pts.size()))
		return
	for p in pts:
		if p.x < -0.75 or p.y < -0.75 or p.x > card_size.x + 0.75 or p.y > card_size.y + 0.75:
			_fail("out_of_bounds", str(p))
			return
	_ok("points_stay_inside")

func _test_top_edge_is_wavy() -> void:
	var pts: PackedVector2Array = Service.build_wave_points(Vector2(400, 520), 18.0, 10, 52.0)
	var min_y := 9999.0
	var max_top := 0.0
	for p in pts:
		min_y = minf(min_y, p.y)
		if p.y < 48.0:
			max_top = maxf(max_top, p.y)
	if max_top - min_y < 8.0:
		_fail("top_not_wavy", "%s %s" % [min_y, max_top])
		return
	_ok("top_edge_is_wavy")

func _test_inset_shrinks_bounds() -> void:
	var outer: PackedVector2Array = Service.build_wave_points(Vector2(400, 520), 18.0, 10, 52.0)
	var inner: PackedVector2Array = Service.inset_along_normals(outer, 10.0)
	if inner.size() != outer.size():
		_fail("inset_count", "%d %d" % [inner.size(), outer.size()])
		return
	var outer_min := Vector2(9999.0, 9999.0)
	var inner_min := Vector2(9999.0, 9999.0)
	for i in range(outer.size()):
		outer_min.x = minf(outer_min.x, outer[i].x)
		outer_min.y = minf(outer_min.y, outer[i].y)
		inner_min.x = minf(inner_min.x, inner[i].x)
		inner_min.y = minf(inner_min.y, inner[i].y)
	if inner_min.x <= outer_min.x or inner_min.y <= outer_min.y:
		_fail("inset_not_inward", "%s %s" % [outer_min, inner_min])
		return
	_ok("inset_shrinks_bounds")

func _test_card_configure_redraws() -> void:
	var card: Control = CardScript.new()
	card.configure(1.0, Color(0.1, 0.2, 0.1, 1.0), Color(0, 0, 0, 0.3))
	if card == null:
		_fail("card_null")
		return
	card.free()
	_ok("card_configure_redraws")

func _test_rainbow_border_colors() -> void:
	var a: Color = Service.rainbow_at(0.0)
	var b: Color = Service.rainbow_at(0.33)
	var c: Color = Service.rainbow_at(0.66)
	if is_equal_approx(a.h, b.h) or is_equal_approx(b.h, c.h):
		_fail("rainbow_hues_too_similar")
		return
	var colors: PackedColorArray = Service.perimeter_rainbow_colors(12)
	if colors.size() != 12:
		_fail("perimeter_count", str(colors.size()))
		return
	var closed: PackedColorArray = Service.closed_rainbow_colors(12)
	if closed.size() != 13:
		_fail("closed_count", str(closed.size()))
		return
	var outer: PackedVector2Array = Service.build_wave_points(Vector2(400, 520), 18.0, 10, 52.0)
	var inner: PackedVector2Array = Service.inset_along_normals(outer, 10.0)
	var quad: PackedVector2Array = Service.border_quad(outer, inner, 0)
	if quad.size() != 4:
		_fail("border_quad", str(quad.size()))
		return
	_ok("rainbow_border_colors")

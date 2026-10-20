extends SceneTree

const Service := preload("res://celebration_rainbow_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== celebration_rainbow_service test ===")
	_test_bands_are_pastel()
	_test_arc_has_points()
	_test_slots_around_card()
	_test_cycle_draw_rewinds()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_bands_are_pastel() -> void:
	var colors: Array[Color] = Service.band_colors()
	if colors.size() < 5:
		_fail("band_count", str(colors.size()))
		return
	for c in colors:
		var col: Color = c
		if col.s > 0.55 or col.v < 0.82:
			_fail("not_pastel", str(col))
			return
	_ok("bands_are_pastel")

func _test_arc_has_points() -> void:
	var pts: PackedVector2Array = Service.arc_points(Vector2(100, 80), 40.0)
	if pts.size() < 9:
		_fail("arc_count", str(pts.size()))
		return
	_ok("arc_has_points")

func _test_slots_around_card() -> void:
	var viewport := Vector2(1080, 1920)
	var card := Rect2(Vector2(180, 720), Vector2(720, 480))
	var slots: Array[Dictionary] = Service.rainbow_slots(viewport, card, 1.0)
	if slots.size() < 10:
		_fail("slot_count", str(slots.size()))
		return
	var has_top := false
	var has_bottom := false
	var delay_min := 9999.0
	var delay_max := 0.0
	var rot_min := 9999.0
	var rot_max := -9999.0
	var min_x := 9999.0
	var max_x := 0.0
	var min_y := 9999.0
	var max_y := 0.0
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		var center: Vector2 = slot.center
		if float(slot.radius) < 70.0:
			_fail("too_small", str(slot.radius))
			return
		if card.has_point(center):
			_fail("inside_card", str(center))
			return
		delay_min = minf(delay_min, float(slot.delay))
		delay_max = maxf(delay_max, float(slot.delay))
		rot_min = minf(rot_min, float(slot.rot))
		rot_max = maxf(rot_max, float(slot.rot))
		min_x = minf(min_x, center.x)
		max_x = maxf(max_x, center.x)
		min_y = minf(min_y, center.y)
		max_y = maxf(max_y, center.y)
		if center.y < card.position.y:
			has_top = true
		elif center.y > card.position.y + card.size.y:
			has_bottom = true
		for j in range(i + 1, slots.size()):
			var other: Dictionary = slots[j]
			var min_dist: float = (float(slot.radius) + float(other.radius)) * 0.9
			if center.distance_to(other.center) < min_dist:
				_fail("overlap", str(center))
				return
	if not has_top or not has_bottom:
		_fail("missing_top_or_bottom")
		return
	if max_x - min_x < viewport.x * 0.45 or max_y - min_y < viewport.y * 0.45:
		_fail("not_full_screen", "%s %s" % [max_x - min_x, max_y - min_y])
		return
	if rot_max - rot_min < 1.2:
		_fail("rots_aligned", "%s %s" % [rot_min, rot_max])
		return
	if delay_max - delay_min < 1.0:
		_fail("delays_coordinated", "%s %s" % [delay_min, delay_max])
		return
	_ok("slots_around_card")

func _test_cycle_draw_rewinds() -> void:
	if Service.cycle_draw(0.0, 0.5) > 0.01:
		_fail("draw_before_delay")
		return
	var mid: float = Service.cycle_draw(0.30, 0.0)
	if mid < 0.4 or mid > 0.8:
		_fail("draw_in_progress", str(mid))
		return
	if Service.cycle_draw(0.70, 0.0) < 0.99:
		_fail("draw_full")
		return
	var undraw: float = Service.cycle_draw(1.10, 0.0)
	if undraw < 0.05 or undraw > 0.95:
		_fail("undraw_in_progress", str(undraw))
		return
	var half: PackedVector2Array = Service.arc_points(Vector2.ZERO, 40.0, 18, 0.5)
	var full: PackedVector2Array = Service.arc_points(Vector2.ZERO, 40.0, 18, 1.0)
	if half.size() >= full.size():
		_fail("partial_not_shorter", "%d %d" % [half.size(), full.size()])
		return
	_ok("cycle_draw_rewinds")

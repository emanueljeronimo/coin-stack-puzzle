extends SceneTree

const Service := preload("res://boot_cover_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== boot_cover_layout_service test ===")
	_test_cover_draw_rect_covers_viewport()
	_test_slot_centered_on_cover()
	_test_slot_near_bottom()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_cover_draw_rect_covers_viewport() -> void:
	var viewport := Vector2(1080, 1920)
	var rect: Rect2 = Service.cover_draw_rect(viewport, Vector2(1080, 1920))
	if rect.size.x + 0.5 < viewport.x or rect.size.y + 0.5 < viewport.y:
		_fail("cover_covers", str(rect))
		return
	_ok("cover_draw_rect_covers_viewport")

func _test_slot_centered_on_cover() -> void:
	var viewport := Vector2(1080, 1920)
	var cover := Rect2(Vector2.ZERO, viewport)
	var slot_size: Vector2 = Service.default_slot_size(cover.size.x)
	var slot: Rect2 = Service.play_slot_rect(viewport, cover, slot_size)
	var mid: float = cover.position.x + cover.size.x * 0.5
	var slot_mid: float = slot.position.x + slot.size.x * 0.5
	if abs(mid - slot_mid) > 1.0:
		_fail("slot_centered", "%f vs %f" % [mid, slot_mid])
		return
	_ok("slot_centered_on_cover")

func _test_slot_near_bottom() -> void:
	var viewport := Vector2(1080, 1920)
	var cover := Rect2(Vector2.ZERO, viewport)
	var slot_size: Vector2 = Service.default_slot_size(cover.size.x)
	var slot: Rect2 = Service.play_slot_rect(viewport, cover, slot_size)
	if slot.position.y < viewport.y * 0.55:
		_fail("slot_near_bottom", str(slot.position.y))
		return
	if slot.position.y + slot.size.y * Service.PLAY_VISIBLE_HEIGHT > viewport.y + 1.0:
		_fail("slot_visible", str(slot))
		return
	_ok("slot_near_bottom")

extends SceneTree

const SlotOverlayBuilderScript = preload("res://slot_overlay_builder.gd")
const SlotOverlayBgScript = preload("res://slot_overlay_bg.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== slot_overlay_builder test ===")
	_test_create_overlay_root()
	_test_create_full_rect_panel()
	_test_snap_rect()
	_test_inner_corner_radius()
	_test_apply_frame_style()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_create_overlay_root() -> void:
	var root := SlotOverlayBuilderScript.create_overlay_root(9)
	if root == null:
		_fail("create_overlay_root_null")
		return
	if root.z_index != 9 or root.visible:
		_fail("create_overlay_root_values")
		return
	_ok("create_overlay_root")

func _test_create_full_rect_panel() -> void:
	var panel := SlotOverlayBuilderScript.create_full_rect_texture_panel(SlotOverlayBgScript)
	if panel == null:
		_fail("create_full_rect_panel_null")
		return
	if panel.offset_left != 0 or panel.offset_top != 0:
		_fail("create_full_rect_panel_offsets")
		return
	_ok("create_full_rect_panel")

func _test_snap_rect() -> void:
	var snapped: Rect2 = SlotOverlayBuilderScript.snap_rect(Vector2(10.4, 3.6), Vector2(50.2, 19.8))
	if snapped.position != Vector2(10, 4):
		_fail("snap_rect_pos", str(snapped.position))
		return
	if snapped.size != Vector2(50, 20):
		_fail("snap_rect_size", str(snapped.size))
		return
	_ok("snap_rect")

func _test_inner_corner_radius() -> void:
	if SlotOverlayBuilderScript.inner_corner_radius(18, 2) != 16:
		_fail("inner_corner_radius")
		return
	if SlotOverlayBuilderScript.inner_corner_radius(1, 4) != 0:
		_fail("inner_corner_radius_min")
		return
	_ok("inner_corner_radius")

func _test_apply_frame_style() -> void:
	var panel := SlotOverlayBuilderScript.create_full_rect_hairline_panel()
	if panel == null:
		_fail("frame_panel_null")
		return
	SlotOverlayBuilderScript.apply_frame_style(panel, 18, Color(0, 0, 0, 1))
	var style: StyleBox = panel.get_theme_stylebox("panel")
	if style == null or not (style is StyleBoxFlat):
		_fail("frame_style_type")
		return
	var flat := style as StyleBoxFlat
	if not flat.draw_center:
		_fail("frame_draw_center")
		return
	if flat.border_width_left != 0:
		_fail("frame_no_stroke")
		return
	if flat.corner_radius_top_left != 18:
		_fail("frame_radius")
		return
	_ok("apply_frame_style")

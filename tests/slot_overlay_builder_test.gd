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

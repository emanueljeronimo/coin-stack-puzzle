extends SceneTree

const MainBoardRenderServiceScript = preload("res://main_board_render_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== main_board_render_service test ===")
	_test_skip_slot()
	_test_slot_visual_state()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_skip_slot() -> void:
	if not MainBoardRenderServiceScript.should_skip_slot(4, 4, false, -1):
		_fail("skip_temp_slot_when_disabled")
		return
	if not MainBoardRenderServiceScript.should_skip_slot(7, 4, true, 7):
		_fail("skip_adjacent_offer")
		return
	if MainBoardRenderServiceScript.should_skip_slot(6, 4, true, 7):
		_fail("keep_regular_slot")
		return
	_ok("skip_slot")

func _test_slot_visual_state() -> void:
	var state := MainBoardRenderServiceScript.slot_visual_state(
		1, 4, true, 1, true,
		Color.BLACK, Color.BLACK,
		Color.RED, Color.RED,
		Color.GREEN, Color.GREEN,
		Color.BLUE, Color.BLUE
	)
	if str(state.get("style_key", "")) != "selected":
		_fail("selected_style", str(state))
		return
	state = MainBoardRenderServiceScript.slot_visual_state(
		2, 4, true, -1, true,
		Color.BLACK, Color.BLACK,
		Color.RED, Color.RED,
		Color.GREEN, Color.GREEN,
		Color.BLUE, Color.BLUE
	)
	if str(state.get("style_key", "")) != "active":
		_fail("active_style", str(state))
		return
	_ok("slot_visual_state")

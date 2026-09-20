extends SceneTree

const MainTurnResolutionServiceScript = preload("res://main_turn_resolution_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== main_turn_resolution_service test ===")
	_test_abort_rules()
	_test_alert_flags()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_abort_rules() -> void:
	if not MainTurnResolutionServiceScript.should_abort_resolution(2, 3, false):
		_fail("abort_on_revision_mismatch")
		return
	if not MainTurnResolutionServiceScript.should_abort_resolution(-1, 3, true):
		_fail("abort_on_pending")
		return
	if MainTurnResolutionServiceScript.should_abort_resolution(3, 3, false):
		_fail("continue_when_valid")
		return
	_ok("abort_rules")

func _test_alert_flags() -> void:
	var overlay := ColorRect.new()
	overlay.visible = false
	var open := MainTurnResolutionServiceScript.level_alert_open(overlay, [], 0, false)
	if open:
		_fail("level_alert_closed")
		return
	overlay.visible = true
	open = MainTurnResolutionServiceScript.level_alert_open(overlay, [], 0, false)
	if not open:
		_fail("level_alert_visible")
		return
	if not MainTurnResolutionServiceScript.should_unlock_board(false, false):
		_fail("unlock_board_when_clear")
		return
	if MainTurnResolutionServiceScript.should_unlock_board(true, false):
		_fail("keep_locked_with_level_alert")
		return
	_ok("alert_flags")

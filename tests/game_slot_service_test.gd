extends SceneTree

const GameSlotServiceScript = preload("res://game_slot_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_slot_service test ===")
	_test_temp_action_when_inactive()
	_test_temp_action_close_sequence()
	_test_unlock_cursor()
	_test_unlock_decision()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_temp_action_when_inactive() -> void:
	var out := GameSlotServiceScript.consume_temp_action(false, 3)
	if bool(out.get("should_close", true)):
		_fail("inactive_should_not_close", str(out))
		return
	if int(out.get("actions_remaining", -1)) != 3:
		_fail("inactive_should_keep_counter", str(out))
		return
	_ok("temp_action_inactive")

func _test_temp_action_close_sequence() -> void:
	var out1 := GameSlotServiceScript.consume_temp_action(true, 2)
	if bool(out1.get("should_close", true)):
		_fail("sequence_step1", str(out1))
		return
	var out2 := GameSlotServiceScript.consume_temp_action(true, int(out1.get("actions_remaining", 0)))
	if not bool(out2.get("should_close", false)):
		_fail("sequence_step2_close", str(out2))
		return
	_ok("temp_action_close_sequence")

func _test_unlock_cursor() -> void:
	var keep := GameSlotServiceScript.ensure_unlock_cursor(7, 15, 2)
	if keep != 8:
		_fail("unlock_cursor_keep", str(keep))
		return
	var init := GameSlotServiceScript.ensure_unlock_cursor(0, 15, 2)
	if init != 18:
		_fail("unlock_cursor_init", str(init))
		return
	_ok("unlock_cursor")

func _test_unlock_decision() -> void:
	if GameSlotServiceScript.is_stale_unlock(10, 10):
		_fail("equal_is_not_stale")
		return
	if not GameSlotServiceScript.is_stale_unlock(11, 10):
		_fail("past_is_stale")
		return
	# 43→44 con cursor en 43: hay que otorgar la ranura, no saltar a 45.
	if not GameSlotServiceScript.can_grant_free_unlock(43, 44, 43):
		_fail("grant_missed_unlock_on_next_level")
		return
	if not GameSlotServiceScript.can_grant_free_unlock(10, 12, 12):
		_fail("grant_exact_level")
		return
	_ok("unlock_decision")

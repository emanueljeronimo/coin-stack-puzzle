extends SceneTree

const GameRulesScript = preload("res://game_rules.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_rules test ===")
	_test_unlock_levels()
	_test_normalize_temp_state()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_unlock_levels() -> void:
	var first := GameRulesScript.initial_free_slot_unlock_level(15)
	if first != 19:
		_fail("first_unlock", str(first))
		return
	var next := GameRulesScript.next_free_slot_unlock_level(first)
	if next != 21:
		_fail("next_unlock", str(next))
		return
	_ok("unlock_levels")

func _test_normalize_temp_state() -> void:
	var off := GameRulesScript.normalize_temp_state(false, 60.0, 6, 5)
	if bool(off.get("temp_slot_bonus_active", true)):
		_fail("normalize_off", str(off))
		return
	var bad_time := GameRulesScript.normalize_temp_state(true, 0.01, 6, 5)
	if bool(bad_time.get("temp_slot_bonus_active", true)):
		_fail("normalize_bad_time", str(bad_time))
		return
	var bad_stack := GameRulesScript.normalize_temp_state(true, 60.0, 5, 5)
	if bool(bad_stack.get("temp_slot_bonus_active", true)):
		_fail("normalize_bad_stack", str(bad_stack))
		return
	var ok := GameRulesScript.normalize_temp_state(true, 59.0, 6, 5)
	if not bool(ok.get("temp_slot_bonus_active", false)):
		_fail("normalize_ok", str(ok))
		return
	_ok("normalize_temp_state")

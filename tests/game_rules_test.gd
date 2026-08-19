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
	if GameRulesScript.first_future_free_slot_unlock_level(15, 15) != 19:
		_fail("future_at_milestone", str(GameRulesScript.first_future_free_slot_unlock_level(15, 15)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(15, 19) != 21:
		_fail("future_at_first_hito", str(GameRulesScript.first_future_free_slot_unlock_level(15, 19)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(15, 21) != 23:
		_fail("future_at_level_21", str(GameRulesScript.first_future_free_slot_unlock_level(15, 21)))
		return
	if GameRulesScript.advance_free_slot_unlock_past_level(19, 21) != 23:
		_fail("advance_stale_19_at_21", str(GameRulesScript.advance_free_slot_unlock_past_level(19, 21)))
		return
	var false_23 := GameRulesScript.heal_inflated_cycle_free_slots(6, 25, 21, 15, 5)
	if not bool(false_23.get("changed", false)):
		_fail("heal_slots_detects_false_23", str(false_23))
		return
	if int(false_23.get("active_stacks", 0)) != 5:
		_fail("heal_slots_back_to_5", str(false_23))
		return
	if int(false_23.get("next_free_slot_unlock_level", 0)) != 23:
		_fail("heal_slots_cursor_23", str(false_23))
		return
	var real_23 := GameRulesScript.heal_inflated_cycle_free_slots(6, 25, 23, 15, 5)
	if bool(real_23.get("changed", true)):
		_fail("heal_slots_keeps_real_23", str(real_23))
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

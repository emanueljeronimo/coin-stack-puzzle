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
	if first != 18:
		_fail("first_unlock", str(first))
		return
	var next := GameRulesScript.next_free_slot_unlock_level(first)
	if next != 20:
		_fail("next_unlock", str(next))
		return
	if GameRulesScript.initial_free_slot_unlock_level(0) != 2:
		_fail("first_unlock_cycle1", str(GameRulesScript.initial_free_slot_unlock_level(0)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(15, 15) != 18:
		_fail("future_at_milestone", str(GameRulesScript.first_future_free_slot_unlock_level(15, 15)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(15, 19) != 20:
		_fail("future_at_first_hito", str(GameRulesScript.first_future_free_slot_unlock_level(15, 19)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(15, 21) != 22:
		_fail("future_at_level_21", str(GameRulesScript.first_future_free_slot_unlock_level(15, 21)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(25, 41) != 42:
		_fail("future_at_level_41", str(GameRulesScript.first_future_free_slot_unlock_level(25, 41)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(25, 44) != 46:
		_fail("future_at_level_44", str(GameRulesScript.first_future_free_slot_unlock_level(25, 44)))
		return
	var missed_44 := GameRulesScript.missed_cycle_free_slot_grants(5, 44, 25, 41, 5)
	if not bool(missed_44.get("changed", false)) or int(missed_44.get("missing", 0)) != 2:
		_fail("missed_slot_at_44", str(missed_44))
		return
	if int(missed_44.get("next_free_slot_unlock_level", 0)) != 46:
		_fail("missed_slot_cursor_46", str(missed_44))
		return
	var has_slots := GameRulesScript.missed_cycle_free_slot_grants(7, 44, 25, 41, 5)
	if bool(has_slots.get("changed", true)):
		_fail("has_slots_at_44", str(has_slots))
		return
	if GameRulesScript.advance_free_slot_unlock_past_level(19, 21) != 22:
		_fail("advance_stale_19_at_21", str(GameRulesScript.advance_free_slot_unlock_past_level(19, 21)))
		return
	if GameRulesScript.next_free_slot_unlock_level(45) != 46:
		_fail("odd_cursor_snaps_even", str(GameRulesScript.next_free_slot_unlock_level(45)))
		return
	var false_23 := GameRulesScript.heal_inflated_cycle_free_slots(6, 25, 21, 15, 5)
	if not bool(false_23.get("changed", false)):
		_fail("heal_slots_detects_false_23", str(false_23))
		return
	if int(false_23.get("active_stacks", 0)) != 5:
		_fail("heal_slots_back_to_5", str(false_23))
		return
	if int(false_23.get("next_free_slot_unlock_level", 0)) != 22:
		_fail("heal_slots_cursor_22", str(false_23))
		return
	var real_22 := GameRulesScript.heal_inflated_cycle_free_slots(6, 24, 22, 15, 5)
	if bool(real_22.get("changed", true)):
		_fail("heal_slots_keeps_real_22", str(real_22))
		return
	# Wipe de fichas 17→14: 7 ranuras y nivel 25 vuelven al arranque post-prestige.
	var desync := GameRulesScript.heal_prestige_start_desync({
		"max_value": 15,
		"highest_board_coin": 14,
		"checkpoint_level": 25,
		"active_stacks": 7,
		"next_free_slot_unlock_level": 27,
		"prestige_level": 21,
		"milestone_level": 15,
		"cycle_reset_stacks": 5,
		"adjacent_slot_next_price": 600,
		"adjacent_slot_base_price": 600,
	})
	if not bool(desync.get("changed", false)):
		_fail("desync_detects_7_slots", str(desync))
		return
	if int(desync.get("active_stacks", 0)) != 5:
		_fail("desync_back_to_5", str(desync))
		return
	if int(desync.get("next_free_slot_unlock_level", 0)) != 22:
		_fail("desync_next_22", str(desync))
		return
	if int(desync.get("checkpoint_level", 0)) != 21:
		_fail("desync_level_21", str(desync))
		return
	var has_16 := GameRulesScript.heal_prestige_start_desync({
		"max_value": 16,
		"highest_board_coin": 16,
		"checkpoint_level": 23,
		"active_stacks": 6,
		"next_free_slot_unlock_level": 25,
		"prestige_level": 21,
		"milestone_level": 15,
		"cycle_reset_stacks": 5,
		"adjacent_slot_next_price": 600,
		"adjacent_slot_base_price": 600,
	})
	if bool(has_16.get("changed", true)):
		_fail("desync_keeps_real_16", str(has_16))
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

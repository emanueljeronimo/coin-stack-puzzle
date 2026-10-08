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
	_test_wildcard_stack_receive()
	_test_attached_wildcard_resolution()
	_test_deal_wildcard_unlock()
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
	if GameRulesScript.next_free_slot_unlock_level(2) != 3:
		_fail("next_after_2_is_3", str(GameRulesScript.next_free_slot_unlock_level(2)))
		return
	if GameRulesScript.next_free_slot_unlock_level(3) != 4:
		_fail("next_after_3_is_4", str(GameRulesScript.next_free_slot_unlock_level(3)))
		return
	if GameRulesScript.next_free_slot_unlock_level(4) != 7:
		_fail("next_after_4_is_7", str(GameRulesScript.next_free_slot_unlock_level(4)))
		return
	if GameRulesScript.next_free_slot_unlock_level(7) != 10:
		_fail("next_after_7_is_10", str(GameRulesScript.next_free_slot_unlock_level(7)))
		return
	if GameRulesScript.previous_free_slot_unlock_level(3) != 2:
		_fail("previous_3_is_2", str(GameRulesScript.previous_free_slot_unlock_level(3)))
		return
	if GameRulesScript.previous_free_slot_unlock_level(4) != 3:
		_fail("previous_4_is_3", str(GameRulesScript.previous_free_slot_unlock_level(4)))
		return
	if GameRulesScript.previous_free_slot_unlock_level(7) != 4:
		_fail("previous_7_is_4", str(GameRulesScript.previous_free_slot_unlock_level(7)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(0, 2) != 3:
		_fail("future_after_level_2", str(GameRulesScript.first_future_free_slot_unlock_level(0, 2)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(0, 4) != 7:
		_fail("future_after_level_4", str(GameRulesScript.first_future_free_slot_unlock_level(0, 4)))
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
	if GameRulesScript.next_free_slot_unlock_level(48) != 50:
		_fail("next_48_is_50", str(GameRulesScript.next_free_slot_unlock_level(48)))
		return
	if GameRulesScript.next_free_slot_unlock_level(50) != 53:
		_fail("next_50_is_53", str(GameRulesScript.next_free_slot_unlock_level(50)))
		return
	if GameRulesScript.next_free_slot_unlock_level(53) != 56:
		_fail("next_53_is_56", str(GameRulesScript.next_free_slot_unlock_level(53)))
		return
	if GameRulesScript.next_free_slot_unlock_level(98) != 100:
		_fail("next_98_is_100", str(GameRulesScript.next_free_slot_unlock_level(98)))
		return
	if GameRulesScript.next_free_slot_unlock_level(100) != 104:
		_fail("next_100_is_104", str(GameRulesScript.next_free_slot_unlock_level(100)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(0, 50) != 53:
		_fail("future_after_50", str(GameRulesScript.first_future_free_slot_unlock_level(0, 50)))
		return
	if GameRulesScript.first_future_free_slot_unlock_level(0, 100) != 104:
		_fail("future_after_100", str(GameRulesScript.first_future_free_slot_unlock_level(0, 100)))
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

func _test_wildcard_stack_receive() -> void:
	var W: int = GameRulesScript.COIN_WILDCARD_VALUE
	if not GameRulesScript.can_stack_receive_value(5, W, false):
		_fail("number_accepts_wildcard")
		return
	if not GameRulesScript.can_stack_receive_value(W, 5, false):
		_fail("wildcard_accepts_number")
		return
	if not GameRulesScript.can_stack_receive_value(-1, 5, false):
		_fail("empty_accepts_number")
		return
	if GameRulesScript.can_stack_receive_value(5, 7, false):
		_fail("number_rejects_other")
		return
	if GameRulesScript.can_stack_receive_value(W, 5, true):
		_fail("full_rejects_wildcard_dest")
		return
	_ok("wildcard_stack_receive")

func _test_attached_wildcard_resolution() -> void:
	var W: int = GameRulesScript.COIN_WILDCARD_VALUE
	var onto_number: Dictionary = GameRulesScript.attached_wildcard_resolution(5, W)
	if str(onto_number.get("convert", "")) != "incoming" or int(onto_number.get("value", -1)) != 5:
		_fail("wildcard_onto_number", str(onto_number))
		return
	var onto_wildcard: Dictionary = GameRulesScript.attached_wildcard_resolution(W, 5)
	if str(onto_wildcard.get("convert", "")) != "below" or int(onto_wildcard.get("value", -1)) != 5:
		_fail("number_onto_wildcard", str(onto_wildcard))
		return
	if not GameRulesScript.attached_wildcard_resolution(5, 5).is_empty():
		_fail("same_numbers_no_convert")
		return
	if not GameRulesScript.attached_wildcard_resolution(W, W).is_empty():
		_fail("two_wildcards_no_convert")
		return
	_ok("attached_wildcard_resolution")

func _test_deal_wildcard_unlock() -> void:
	if GameRulesScript.deal_wildcard_chance(9) != 0.0:
		_fail("locked_before_10")
		return
	if GameRulesScript.deal_wildcard_chance(10) != GameRulesScript.WILDCARD_ROUND_CHANCE:
		_fail("unlocks_at_10")
		return
	_ok("deal_wildcard_unlock")

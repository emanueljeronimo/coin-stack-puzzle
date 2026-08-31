extends SceneTree

const GameEngineScript = preload("res://game_engine.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_engine test ===")
	_test_cycle_math()
	_test_checkpoint_eval()
	_test_legacy_cycle_heal()
	_test_descriptions()
	_test_cover_showcase()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_cycle_math() -> void:
	var c := GameEngineScript.cycle_index(1, 5, 15)
	if c != 0:
		_fail("cycle_index_0", str(c))
		return
	# Piso 10 sigue siendo el primer ciclo (el prestige arranca en tiradas 11-14).
	if GameEngineScript.cycle_base_level(10, 5, 15) != 0:
		_fail("cycle_base_10_still_first", str(GameEngineScript.cycle_base_level(10, 5, 15)))
		return
	if GameEngineScript.cycle_base_level(11, 5, 15) != 15:
		_fail("cycle_base_15_from_11")
		return
	if GameEngineScript.cycle_reset_roll_value_floor(15, 5) != 11:
		_fail("reset_floor_15")
		return
	if GameEngineScript.cycle_reset_max_value(15) != 15:
		_fail("reset_max_15")
		return
	if GameEngineScript.cycle_checkpoint_origin(15, 15) != 15:
		_fail("origin_on_time")
		return
	if GameEngineScript.cycle_checkpoint_origin(15, 21) != 20:
		_fail("origin_ahead_21")
		return
	if GameEngineScript.cycle_reset_roll_value_floor(25, 5) != 21:
		_fail("reset_floor_25")
		return
	if GameEngineScript.cycle_reset_max_value(25) != 25:
		_fail("reset_max_25")
		return
	if GameEngineScript.next_cycle_coin_milestone(11, 5, 15) != 25:
		_fail("next_milestone_after_15")
		return
	if GameEngineScript.reached_cycle_coin_milestone(25, 11, 5, 15) != 25:
		_fail("milestone_25")
		return
	if GameEngineScript.reached_cycle_coin_milestone(24, 11, 5, 15) != 0:
		_fail("no_milestone_24")
		return
	if GameEngineScript.cycle_reset_roll_value_floor(35, 5) != 31:
		_fail("reset_floor_35")
		return
	if GameEngineScript.cycle_coin_offset(21, 5, 15) != 20:
		_fail("offset_after_25")
		return
	if GameEngineScript.reached_cycle_coin_milestone(14, 1, 5, 15) != 0:
		_fail("no_milestone_14")
		return
	if GameEngineScript.reached_cycle_coin_milestone(15, 1, 5, 15) != 15:
		_fail("milestone_15")
		return
	_ok("cycle_math")

func _eval_piles(counts: Dictionary, roll_floor: int = 1, origin: int = 0, min_level: int = 0) -> int:
	return GameEngineScript.evaluate_checkpoint_from_piles(
		func(v: int) -> int: return int(counts.get(v, 0)),
		roll_floor,
		5,
		5,
		15,
		origin,
		min_level
	)

func _test_checkpoint_eval() -> void:
	# Un 5 suelto no sube. 5 cincos en una pila = nivel 2. Completar 5s (un 6) = 3.
	if _eval_piles({5: 1}) != 1:
		_fail("one_five_stays_level_1", str(_eval_piles({5: 1})))
		return
	if _eval_piles({5: 5}) != 2:
		_fail("half_5_is_level_2", str(_eval_piles({5: 5})))
		return
	if _eval_piles({6: 1}) != 3:
		_fail("complete_5_is_level_3", str(_eval_piles({6: 1})))
		return
	if _eval_piles({4: 10}) != 1:
		_fail("fours_stay_level_1")
		return
	if _eval_piles({6: 5}) != 4:
		_fail("half_6_is_level_4", str(_eval_piles({6: 5})))
		return
	if _eval_piles({6: 1, 7: 1}) != 5:
		_fail("complete_6_is_level_5", str(_eval_piles({6: 1, 7: 1})))
		return
	if _eval_piles({6: 1, 7: 5}) != 6:
		_fail("half_7_is_level_6", str(_eval_piles({6: 1, 7: 5})))
		return
	if _eval_piles({6: 1, 7: 1, 8: 1}) != 7:
		_fail("complete_7_is_level_7", str(_eval_piles({6: 1, 7: 1, 8: 1})))
		return
	if _eval_piles({6: 1, 7: 1, 8: 5}) != 8:
		_fail("half_8_is_level_8", str(_eval_piles({6: 1, 7: 1, 8: 5})))
		return
	if _eval_piles({6: 1, 7: 1, 8: 1, 9: 1}) != 9:
		_fail("complete_8_is_level_9", str(_eval_piles({6: 1, 7: 1, 8: 1, 9: 1})))
		return
	# Un 8 suelto, sin 5/6/7, no salta al 8/9.
	if _eval_piles({8: 5}) != 1:
		_fail("leftover_eights_stay_level_1", str(_eval_piles({8: 5})))
		return
	var origin21 := GameEngineScript.cycle_checkpoint_origin(15, 21)
	if _eval_piles({15: 1}, 11, origin21) != 20:
		_fail("prestige_21_one_15_stays_hold", str(_eval_piles({15: 1}, 11, origin21)))
		return
	if _eval_piles({15: 5}, 11, origin21) != 21:
		_fail("prestige_21_half_15_is_21", str(_eval_piles({15: 5}, 11, origin21)))
		return
	if _eval_piles({16: 1}, 11, origin21) != 22:
		_fail("prestige_21_create_16_is_22", str(_eval_piles({16: 1}, 11, origin21)))
		return
	# Un 25 suelto, sin 15/16, no salta el hold. El piso es el origen (20), no 21.
	if _eval_piles({25: 1}, 11, origin21) != 20:
		_fail("prestige_21_stray_25_stays_origin", str(_eval_piles({25: 1}, 11, origin21)))
		return
	var origin41 := GameEngineScript.cycle_checkpoint_origin(25, 41)
	if origin41 != 40:
		_fail("origin_ahead_41", str(origin41))
		return
	if _eval_piles({25: 1}, 21, origin41) != 40:
		_fail("prestige_41_has_25", str(_eval_piles({25: 1}, 21, origin41)))
		return
	if _eval_piles({26: 1}, 21, origin41) != 42:
		_fail("prestige_41_create_26_is_42", str(_eval_piles({26: 1}, 21, origin41)))
		return
	if _eval_piles({26: 1, 27: 5}, 21, origin41) != 45:
		_fail("half_27_is_level_45", str(_eval_piles({26: 1, 27: 5}, 21, origin41)))
		return
	if _eval_piles({26: 1, 27: 1, 28: 1}, 21, origin41) != 46:
		_fail("complete_27_is_level_46", str(_eval_piles({26: 1, 27: 1, 28: 1}, 21, origin41)))
		return
	# En el 45, completar 27s no pide 25/26 todavía en el tablero (ya se fusionaron).
	if _eval_piles({27: 10}, 21, origin41, 45) != 46:
		_fail("min_level_45_ten_27_is_46", str(_eval_piles({27: 10}, 21, origin41, 45)))
		return
	if _eval_piles({28: 1}, 21, origin41, 45) != 46:
		_fail("min_level_45_has_28_is_46", str(_eval_piles({28: 1}, 21, origin41, 45)))
		return
	if _eval_piles({27: 5}, 21, origin41, 45) != 45:
		_fail("min_level_45_half_27_stays_45", str(_eval_piles({27: 5}, 21, origin41, 45)))
		return
	if _eval_piles({8: 5}, 1, 0, 1) != 1:
		_fail("min_level_1_leftover_eights", str(_eval_piles({8: 5}, 1, 0, 1)))
		return
	var stale := _eval_piles({21: 1}, 11, origin41)
	if stale > 41:
		_fail("stale_origin_no_jump_on_21", str(stale))
		return
	if GameEngineScript.effective_cycle_origin(40, 15) != 15:
		_fail("reject_future_origin", str(GameEngineScript.effective_cycle_origin(40, 15)))
		return
	if GameEngineScript.effective_cycle_origin(40, 25) != 40:
		_fail("keep_origin_in_cycle", str(GameEngineScript.effective_cycle_origin(40, 25)))
		return
	if GameEngineScript.effective_cycle_origin(20, 15) != 20:
		_fail("keep_origin_20", str(GameEngineScript.effective_cycle_origin(20, 15)))
		return
	_ok("checkpoint_eval")

func _test_legacy_cycle_heal() -> void:
	if GameEngineScript.prestige_hold_checkpoint(15, 5) != 21:
		_fail("prestige_hold_21")
		return
	# Save inflado: prestigió en 21, el parche lo mandó a 23 sin crear el 16.
	var jumped := GameEngineScript.heal_legacy_cycle_progress({
		"milestone_level": 15,
		"checkpoint_level": 23,
		"current_level": 2,
		"max_value": 16,
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 22,
		"cycle_rules_revision": 1,
	}, 5)
	if int(jumped.get("checkpoint_level", 0)) != 21:
		_fail("heal_23_to_21", str(jumped))
		return
	if int(jumped.get("cycle_checkpoint_origin", 0)) != 20:
		_fail("heal_origin_20", str(jumped))
		return
	if int(jumped.get("max_value", 0)) != 15:
		_fail("heal_max_15", str(jumped))
		return
	if int(jumped.get("roll_value_floor", 0)) != 11:
		_fail("heal_floor_11", str(jumped))
		return
	if not bool(jumped.get("refill", false)):
		_fail("heal_refill", str(jumped))
		return
	if int(jumped.get("cycle_rules_revision", 0)) != GameEngineScript.CYCLE_RULES_REVISION:
		_fail("heal_revision", str(jumped))
		return
	# Tras curar, crear 16 es nivel 22 (el hold 21 ya contó; no vuelve a sumar).
	var origin := int(jumped.get("cycle_checkpoint_origin", 0))
	var lv16 := GameEngineScript.evaluate_checkpoint_level(16, 1, 11, 5, 5, 15, origin)
	if lv16 != 22:
		_fail("heal_then_create_16_is_22", str(lv16))
		return
	# Ya curado: no volver a bajar un 23 legítimo.
	var stable := GameEngineScript.heal_legacy_cycle_progress({
		"milestone_level": 15,
		"checkpoint_level": 23,
		"current_level": 2,
		"max_value": 16,
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 20,
		"cycle_rules_revision": GameEngineScript.CYCLE_RULES_REVISION,
	}, 5)
	if bool(stable.get("changed", true)):
		_fail("heal_idempotent", str(stable))
		return
	if int(stable.get("checkpoint_level", 0)) != 23:
		_fail("heal_keeps_real_23", str(stable))
		return
	# Progreso real a 17/18: no rellenar el tablero ni bajar el objetivo a 15.
	var late := GameEngineScript.heal_legacy_cycle_progress({
		"milestone_level": 15,
		"checkpoint_level": 25,
		"current_level": 3,
		"max_value": 18,
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 20,
		"cycle_rules_revision": GameEngineScript.CYCLE_RULES_REVISION,
		"highest_board_coin": 17,
	}, 5)
	if bool(late.get("changed", true)) or bool(late.get("refill", true)):
		_fail("heal_keeps_17_18", str(late))
		return
	if int(late.get("max_value", 0)) != 18:
		_fail("heal_keeps_max_18", str(late))
		return
	var late_old_rev := GameEngineScript.heal_legacy_cycle_progress({
		"milestone_level": 15,
		"checkpoint_level": 25,
		"current_level": 3,
		"max_value": 18,
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 20,
		"cycle_rules_revision": 0,
		"highest_board_coin": 17,
	}, 5)
	if bool(late_old_rev.get("refill", true)):
		_fail("heal_no_refill_after_17", str(late_old_rev))
		return
	if int(late_old_rev.get("max_value", 0)) != 18:
		_fail("heal_old_rev_keeps_18", str(late_old_rev))
		return
	if int(late_old_rev.get("checkpoint_level", 0)) != 25:
		_fail("heal_old_rev_keeps_level", str(late_old_rev))
		return
	var display := GameEngineScript.healed_display_checkpoint(23, {
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 20,
		"cycle_rules_revision": 0,
		"max_value": 16,
		"checkpoint_level": 23,
	})
	if display != 21:
		_fail("heal_display_lobby", str(display))
		return
	_ok("legacy_cycle_heal")

func _test_descriptions() -> void:
	var d2 := GameEngineScript.checkpoint_level_description(2, 5, 15)
	if d2.find("mitad") < 0 or d2.find("5") < 0:
		_fail("desc_level_2", d2)
		return
	var d3 := GameEngineScript.checkpoint_level_description(3, 5, 15)
	if d3.find("Completaste") < 0 or d3.find("5") < 0:
		_fail("desc_level_3", d3)
		return
	_ok("descriptions")

func _test_cover_showcase() -> void:
	# Arranque: objetivo 5, tablero 1-4.
	if GameEngineScript.cover_showcase_coin_value(5, 4) != 5:
		_fail("cover_start", str(GameEngineScript.cover_showcase_coin_value(5, 4)))
		return
	# Prestige: tablero 11-14, objetivo real 15; un max_value viejo=16 no debe verse.
	if GameEngineScript.cover_showcase_coin_value(16, 14) != 15:
		_fail("cover_prestige_stale_16", str(GameEngineScript.cover_showcase_coin_value(16, 14)))
		return
	if GameEngineScript.cover_showcase_coin_value(15, 14) != 15:
		_fail("cover_prestige_15", str(GameEngineScript.cover_showcase_coin_value(15, 14)))
		return
	# Ya creaste el 16.
	if GameEngineScript.cover_showcase_coin_value(16, 16) != 16:
		_fail("cover_has_16", str(GameEngineScript.cover_showcase_coin_value(16, 16)))
		return
	_ok("cover_showcase")

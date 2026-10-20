extends SceneTree

const GameTurnEngineScript = preload("res://game_turn_engine.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_turn_engine test ===")
	_test_roll_value_pool()
	_test_roll_count_policy()
	_test_early_roll_ramp()
	_test_deal_multiplier_ramp()
	_test_grouped_early_rolls()
	_test_balanced_pick_policy()
	_test_round_wildcard_once()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_roll_value_pool() -> void:
	var values := GameTurnEngineScript.build_roll_values(10, 12, func() -> int:
		return 2
	)
	if values != [10, 10, 10, 11, 11, 11, 12, 12, 12]:
		_fail("roll_pool_shape", str(values))
		return
	_ok("roll_value_pool")

func _test_roll_count_policy() -> void:
	if GameTurnEngineScript.compute_roll_count(20, 0, true) != 0:
		_fail("roll_count_zero")
		return
	if GameTurnEngineScript.compute_roll_count(3, 5, true) != 3:
		_fail("roll_count_small_pool")
		return
	# Con 2+ huecos y pool >= huecos, deja uno libre.
	if GameTurnEngineScript.compute_roll_count(8, 4, true) != 3:
		_fail("roll_count_keep_one_free")
		return
	if GameTurnEngineScript.compute_roll_count(8, 4, false) != 4:
		_fail("roll_count_fill_all_when_disabled")
		return
	_ok("roll_count_policy")

func _test_early_roll_ramp() -> void:
	if GameTurnEngineScript.early_roll_target(1) <= GameTurnEngineScript.early_roll_target(3):
		_fail("early_starts_higher")
		return
	if GameTurnEngineScript.early_roll_target(5) != 0:
		_fail("early_ends_at_5")
		return
	var lv1: int = GameTurnEngineScript.compute_level_roll_count(1, 3, 20, true)
	var lv5: int = GameTurnEngineScript.compute_level_roll_count(5, 3, 20, true)
	var lv6: int = GameTurnEngineScript.compute_level_roll_count(6, 3, 20, true)
	var lv7: int = GameTurnEngineScript.compute_level_roll_count(7, 3, 20, true)
	var lv8: int = GameTurnEngineScript.compute_level_roll_count(8, 3, 20, true)
	if GameTurnEngineScript.early_roll_target(1) != 10:
		_fail("level1_target_10", str(GameTurnEngineScript.early_roll_target(1)))
		return
	if GameTurnEngineScript.early_roll_target(3) != 6:
		_fail("level3_target_6", str(GameTurnEngineScript.early_roll_target(3)))
		return
	if GameTurnEngineScript.early_roll_target(4) != 5:
		_fail("level4_ramps_down", str(GameTurnEngineScript.early_roll_target(4)))
		return
	if not GameTurnEngineScript.should_double_early_deals(8):
		_fail("double_until_8")
		return
	if GameTurnEngineScript.should_double_early_deals(9):
		_fail("no_double_after_8")
		return
	if lv1 < 19 or lv1 <= lv5:
		_fail("level1_drops_more", "%d vs %d" % [lv1, lv5])
		return
	if lv5 != 6:
		_fail("level5_double_pool", str(lv5))
		return
	if lv6 != 6:
		_fail("level6_double_pool", str(lv6))
		return
	if lv7 != 6:
		_fail("level7_double_pool", str(lv7))
		return
	if lv8 != 6:
		_fail("level8_double_pool", str(lv8))
		return
	if GameTurnEngineScript.early_roll_value_max(1, 0, 1, 4) != 2:
		_fail("first_deal_ones_twos", str(GameTurnEngineScript.early_roll_value_max(1, 0, 1, 4)))
		return
	if GameTurnEngineScript.early_roll_value_max(1, 1, 1, 4) != 3:
		_fail("second_deal_threes", str(GameTurnEngineScript.early_roll_value_max(1, 1, 1, 4)))
		return
	if GameTurnEngineScript.early_roll_value_max(4, 3, 1, 5) != 5:
		_fail("after_six_deals_fives", str(GameTurnEngineScript.early_roll_value_max(4, 3, 1, 5)))
		return
	if GameTurnEngineScript.early_pad_max(5, 1, 8) != 8:
		_fail("late_uses_full_max", str(GameTurnEngineScript.early_pad_max(5, 1, 8)))
		return
	var padded: Array = GameTurnEngineScript.pad_roll_values([1, 2], 5, 1, 2)
	if padded.size() != 5:
		_fail("pad_pool", str(padded))
		return
	_ok("early_roll_ramp")

func _test_deal_multiplier_ramp() -> void:
	if GameTurnEngineScript.deal_multiplier(1) != 2.0:
		_fail("mult_level1", str(GameTurnEngineScript.deal_multiplier(1)))
		return
	if GameTurnEngineScript.deal_multiplier(8) != 2.0:
		_fail("mult_level8", str(GameTurnEngineScript.deal_multiplier(8)))
		return
	if GameTurnEngineScript.deal_multiplier(9) != 1.5:
		_fail("mult_level9", str(GameTurnEngineScript.deal_multiplier(9)))
		return
	if GameTurnEngineScript.deal_multiplier(12) != 1.5:
		_fail("mult_level12", str(GameTurnEngineScript.deal_multiplier(12)))
		return
	if GameTurnEngineScript.deal_multiplier(13) != 1.0:
		_fail("mult_level13", str(GameTurnEngineScript.deal_multiplier(13)))
		return
	if GameTurnEngineScript.deal_multiplier(15) != 1.0:
		_fail("mult_prestige", str(GameTurnEngineScript.deal_multiplier(15)))
		return
	var lv9: int = GameTurnEngineScript.compute_level_roll_count(9, 3, 20, true)
	var lv12: int = GameTurnEngineScript.compute_level_roll_count(12, 3, 20, true)
	var lv13: int = GameTurnEngineScript.compute_level_roll_count(13, 3, 20, true)
	if lv9 != 5:
		_fail("level9_one_half_pool", str(lv9))
		return
	if lv12 != 5:
		_fail("level12_one_half_pool", str(lv12))
		return
	if lv13 != 3:
		_fail("level13_normal_pool", str(lv13))
		return
	_ok("deal_multiplier_ramp")

func _test_grouped_early_rolls() -> void:
	if GameTurnEngineScript.should_group_early_rolls(1):
		_fail("no_auto_group_level_1")
		return
	if GameTurnEngineScript.should_group_early_rolls(3):
		_fail("no_auto_group_level_3")
		return
	_ok("grouped_early_rolls")

func _test_balanced_pick_policy() -> void:
	var assigned := [0, 0, 0]
	for _i in range(6):
		var idx := GameTurnEngineScript.pick_balanced_index(
			assigned.size(),
			func(candidate_index: int) -> int:
				return assigned[candidate_index],
			func(_max_exclusive: int) -> int:
				return 0
		)
		if idx < 0 or idx >= assigned.size():
			_fail("balanced_pick_index", str(idx))
			return
		assigned[idx] += 1
	if assigned != [2, 2, 2]:
		_fail("balanced_pick_distribution", str(assigned))
		return
	_ok("balanced_pick_policy")

func _test_round_wildcard_once() -> void:
	var none := GameTurnEngineScript.apply_round_wildcard(
		[1, 2, 3, 4],
		4,
		0.10,
		func() -> float: return 0.99,
		func(_n: int) -> int: return 0
	)
	if none != [1, 2, 3, 4]:
		_fail("wildcard_round_miss", str(none))
		return
	var hit := GameTurnEngineScript.apply_round_wildcard(
		[1, 2, 3, 4],
		4,
		0.10,
		func() -> float: return 0.0,
		func(_n: int) -> int: return 2
	)
	if hit != [1, 2, 0, 4]:
		_fail("wildcard_round_one", str(hit))
		return
	var only_dealt := GameTurnEngineScript.apply_round_wildcard(
		[1, 2, 3, 4, 5],
		2,
		1.0,
		func() -> float: return 0.0,
		func(_n: int) -> int: return 1
	)
	if only_dealt != [1, 0, 3, 4, 5]:
		_fail("wildcard_only_in_dealt", str(only_dealt))
		return
	_ok("round_wildcard_once")

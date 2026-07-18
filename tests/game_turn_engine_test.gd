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
	_test_balanced_pick_policy()
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

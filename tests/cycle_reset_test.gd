extends SceneTree

## Verifica la lógica de ciclo de tablero (reset al conseguir ficha 15/25/35 + rangos de tirada).
## godot --headless --path . --script res://tests/cycle_reset_test.gd

const GameEngineScript = preload("res://game_engine.gd")

var _failed := 0
var _passed := 0

const BOARD_CYCLE_LEVELS := 15
const CHECKPOINT_BASE_VALUE := 5

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== cycle reset logic test ===")
	_test_milestones()
	_test_roll_ranges()
	_test_evaluate_mapping()
	_test_reset_trigger_is_coin_not_level()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _cycle_index_from_floor(roll_value_floor: int) -> int:
	if roll_value_floor <= 1:
		return 0
	return int((roll_value_floor + CHECKPOINT_BASE_VALUE) / BOARD_CYCLE_LEVELS)

func _cycle_base_from_floor(roll_value_floor: int) -> int:
	return _cycle_index_from_floor(roll_value_floor) * BOARD_CYCLE_LEVELS

func _coin_offset_from_floor(roll_value_floor: int) -> int:
	var idx := _cycle_index_from_floor(roll_value_floor)
	if idx <= 0:
		return 0
	return idx * BOARD_CYCLE_LEVELS - CHECKPOINT_BASE_VALUE

func _floor_for_milestone(milestone: int) -> int:
	return milestone - CHECKPOINT_BASE_VALUE + 1

func _next_milestone(roll_value_floor: int) -> int:
	return GameEngineScript.next_cycle_coin_milestone(
		roll_value_floor, CHECKPOINT_BASE_VALUE, BOARD_CYCLE_LEVELS
	)

func _reached_milestone(hv: int, roll_value_floor: int) -> int:
	return GameEngineScript.reached_cycle_coin_milestone(
		hv, roll_value_floor, CHECKPOINT_BASE_VALUE, BOARD_CYCLE_LEVELS
	)

func _test_milestones() -> void:
	for m in [15, 25, 35, 45]:
		if not GameEngineScript.is_cycle_coin_milestone(m, BOARD_CYCLE_LEVELS):
			_fail("milestone_%d" % m)
			return
		if GameEngineScript.cycle_reset_roll_value_floor(m, CHECKPOINT_BASE_VALUE) != m - 4:
			_fail("floor_%d" % m)
			return
	if GameEngineScript.is_cycle_coin_milestone(30, BOARD_CYCLE_LEVELS):
		_fail("30_is_not_milestone")
		return
	_ok("milestones_15_25_35_45")

func _test_roll_ranges() -> void:
	if GameEngineScript.cycle_reset_roll_value_floor(15, CHECKPOINT_BASE_VALUE) != 11:
		_fail("range_15_floor")
		return
	if GameEngineScript.cycle_reset_roll_value_floor(25, CHECKPOINT_BASE_VALUE) != 21:
		_fail("range_25_floor")
		return
	if GameEngineScript.cycle_reset_roll_value_floor(35, CHECKPOINT_BASE_VALUE) != 31:
		_fail("range_35_floor")
		return
	_ok("roll_ranges_post_reset")

func _test_evaluate_mapping() -> void:
	# Ciclo 1: 5 cincos → nivel 2; un 5 suelto no cuenta.
	if GameEngineScript.evaluate_checkpoint_level(5, 1, 1, CHECKPOINT_BASE_VALUE, 5, BOARD_CYCLE_LEVELS) != 1:
		_fail("c1_one5", str(GameEngineScript.evaluate_checkpoint_level(5, 1, 1, CHECKPOINT_BASE_VALUE, 5, BOARD_CYCLE_LEVELS)))
		return
	if GameEngineScript.evaluate_checkpoint_level(5, 5, 1, CHECKPOINT_BASE_VALUE, 5, BOARD_CYCLE_LEVELS) != 2:
		_fail("c1_half5")
		return
	# Tras reset @15 (floor 11), fichas 11-14 se quedan en el hito.
	var origin15 := GameEngineScript.cycle_checkpoint_origin(15, 15)
	if GameEngineScript.evaluate_checkpoint_level(14, 1, 11, CHECKPOINT_BASE_VALUE, 5, BOARD_CYCLE_LEVELS, origin15) != 15:
		_fail("c2_stay15", str(GameEngineScript.evaluate_checkpoint_level(14, 1, 11, CHECKPOINT_BASE_VALUE, 5, BOARD_CYCLE_LEVELS, origin15)))
		return
	if GameEngineScript.evaluate_checkpoint_level(15, 1, 11, CHECKPOINT_BASE_VALUE, 5, BOARD_CYCLE_LEVELS, origin15) != 15:
		_fail("c2_one15_stays")
		return
	_ok("evaluate_cycle_mapping")

func _test_reset_trigger_is_coin_not_level() -> void:
	# Mitad de 11: checkpoint 15, sin ficha 15 → NO reset
	if _reached_milestone(11, 1) != 0:
		_fail("half11_no_reset", str(_reached_milestone(11, 1)))
		return
	# Crear ficha 12..14: aún no
	for v in [12, 13, 14]:
		if _reached_milestone(v, 1) != 0:
			_fail("coin%d_no_reset" % v, str(_reached_milestone(v, 1)))
			return
	# Crear ficha 15 → SÍ reset
	if _reached_milestone(15, 1) != 15:
		_fail("coin15_reset", str(_reached_milestone(15, 1)))
		return
	# Tras ciclo 1, crear 25 → reset a 25
	if _reached_milestone(25, 11) != 25:
		_fail("coin25_reset", str(_reached_milestone(25, 11)))
		return
	# Tras ciclo 1, ficha 15 no vuelve a resetear
	if _reached_milestone(15, 11) != 0:
		_fail("coin15_after_reset_no_rerun", str(_reached_milestone(15, 11)))
		return
	_ok("reset_trigger_is_coin_value")

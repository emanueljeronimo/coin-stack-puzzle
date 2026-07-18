extends SceneTree

## Verifica la lógica de ciclo de tablero (reset al conseguir ficha 15/30/45 + rangos de tirada).
## godot --headless --path . --script res://tests/cycle_reset_test.gd

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
	return milestone - CHECKPOINT_BASE_VALUE

func _next_milestone(roll_value_floor: int) -> int:
	return (_cycle_index_from_floor(roll_value_floor) + 1) * BOARD_CYCLE_LEVELS

func _reached_milestone(hv: int, roll_value_floor: int) -> int:
	var found := 0
	var next_m := _next_milestone(roll_value_floor)
	while next_m > 0 and next_m <= hv:
		found = next_m
		next_m += BOARD_CYCLE_LEVELS
	return found

func _test_milestones() -> void:
	for m in [15, 30, 45, 60]:
		if m % BOARD_CYCLE_LEVELS != 0:
			_fail("milestone_%d" % m)
			return
		if _floor_for_milestone(m) != m - 5:
			_fail("floor_%d" % m)
			return
	_ok("milestones_15_30_45_60")

func _test_roll_ranges() -> void:
	# Tras reset @15: piso 10, techo 14 (objetivo 15)
	if not (_floor_for_milestone(15) == 10):
		_fail("range_15_floor")
		return
	if not (_floor_for_milestone(30) == 25):
		_fail("range_30_floor")
		return
	if not (_floor_for_milestone(45) == 40):
		_fail("range_45_floor")
		return
	_ok("roll_ranges_post_reset")

func _evaluate(hv: int, roll_value_floor: int, has_half: bool) -> int:
	var offset := _coin_offset_from_floor(roll_value_floor)
	var local_hv := hv - offset
	var cycle_base := _cycle_base_from_floor(roll_value_floor)
	if local_hv < CHECKPOINT_BASE_VALUE:
		return 1 if cycle_base == 0 else cycle_base
	var local_level := 2 * (local_hv - CHECKPOINT_BASE_VALUE) + 2 + (1 if has_half else 0)
	if cycle_base == 0:
		return local_level
	return cycle_base + local_level - 1

func _test_evaluate_mapping() -> void:
	# Ciclo 0: crear 5 → nivel 2
	if _evaluate(5, 1, false) != 2:
		_fail("c1_create5", str(_evaluate(5, 1, false)))
		return
	# Ciclo 0: half de 11 → checkpoint 15, PERO no debe resetear (sin ficha 15)
	if _evaluate(11, 1, true) != 15:
		_fail("c1_half11", str(_evaluate(11, 1, true)))
		return
	# Tras reset @15 (floor 10), fichas 10-14 no deben saltar checkpoint
	if _evaluate(14, 10, false) != 15:
		_fail("c2_stay15", str(_evaluate(14, 10, false)))
		return
	# Crear 15 con floor 10 (local 5) → nivel 16
	if _evaluate(15, 10, false) != 16:
		_fail("c2_create15", str(_evaluate(15, 10, false)))
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
	# Tras ciclo 1, crear 30 → reset a 30
	if _reached_milestone(30, 10) != 30:
		_fail("coin30_reset", str(_reached_milestone(30, 10)))
		return
	# Tras ciclo 1, ficha 15 no vuelve a resetear
	if _reached_milestone(15, 10) != 0:
		_fail("coin15_after_reset_no_rerun", str(_reached_milestone(15, 10)))
		return
	_ok("reset_trigger_is_coin_value")

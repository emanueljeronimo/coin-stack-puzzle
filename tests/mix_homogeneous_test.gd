extends SceneTree

## Regresión: Mezclar desarma, colapsa fusiones de 10 y recoloca homogéneo.
## godot --headless --path . --script res://tests/mix_homogeneous_test.gd

const STACK_CAPACITY := 10

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== mix homogeneous test ===")
	_test_partial_groups_fit()
	_test_large_group_split()
	_test_collapse_tens_before_place()
	_test_overflow_keeps_largest_pure()
	_test_plan_places_every_coin()
	_test_no_mix_when_chunks_fit()
	_test_opening_deal_skips_fusion()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _plan(values: Array, stack_count: int) -> Array:
	return GameRules.build_mix_stack_plan(values, stack_count, STACK_CAPACITY)

func _assert_all_homogeneous(plan: Array, name: String) -> bool:
	for idx in range(plan.size()):
		var segment: Array = plan[idx]
		if segment.is_empty():
			continue
		if segment.size() > STACK_CAPACITY:
			_fail(name, "stack %d over capacity: %d" % [idx, segment.size()])
			return false
		var first := int(segment[0])
		for raw in segment:
			if int(raw) != first:
				_fail(name, "stack %d mixed: %s" % [idx, str(segment)])
				return false
	return true

func _count_mixed(plan: Array) -> int:
	var mixed := 0
	for segment in plan:
		if segment.is_empty():
			continue
		var first := int(segment[0])
		for raw in segment:
			if int(raw) != first:
				mixed += 1
				break
	return mixed

func _total_planned(plan: Array) -> int:
	var n := 0
	for segment in plan:
		n += (segment as Array).size()
	return n

func _count_value(plan: Array, value: int) -> int:
	var n := 0
	for segment in plan:
		for raw in segment:
			if int(raw) == value:
				n += 1
	return n

func _test_partial_groups_fit() -> void:
	var values: Array = []
	for _i in range(3):
		values.append(2)
	for _i in range(8):
		values.append(4)
	for _i in range(7):
		values.append(5)
	for _i in range(6):
		values.append(6)
	var plan := _plan(values, 5)
	if not _assert_all_homogeneous(plan, "partial_groups_homogeneous"):
		return
	_ok("partial_groups_homogeneous")

func _test_large_group_split() -> void:
	# 18 × 3 → colapsa a 2 × 4 + 8 × 3; + 5 × 7 → todo homogéneo en 4 ranuras.
	var values: Array = []
	for _i in range(18):
		values.append(3)
	for _i in range(5):
		values.append(7)
	var plan := _plan(values, 4)
	if not _assert_all_homogeneous(plan, "large_group_split"):
		return
	if _count_value(plan, 3) != 8:
		_fail("large_group_counts", "3s=%d" % _count_value(plan, 3))
		return
	if _count_value(plan, 4) != 2:
		_fail("large_group_fused_4", "4s=%d" % _count_value(plan, 4))
		return
	if _count_value(plan, 7) != 5:
		_fail("large_group_counts_7", "7s=%d" % _count_value(plan, 7))
		return
	_ok("large_group_split")

func _test_collapse_tens_before_place() -> void:
	# 20 × 5 → 4 × 6; debe caber homogéneo en 1 pila.
	var values: Array = []
	for _i in range(20):
		values.append(5)
	var plan := _plan(values, 3)
	if not _assert_all_homogeneous(plan, "collapse_tens"):
		return
	if _count_value(plan, 5) != 0:
		_fail("collapse_no_fives", "5s=%d" % _count_value(plan, 5))
		return
	if _count_value(plan, 6) != 4:
		_fail("collapse_four_sixes", "6s=%d" % _count_value(plan, 6))
		return
	_ok("collapse_tens")

func _test_overflow_keeps_largest_pure() -> void:
	# Más colores que ranuras → inevitablemente alguna pila mixta,
	# pero los grupos grandes quedan puros.
	var values: Array = []
	for _i in range(9):
		values.append(5)
	for _i in range(8):
		values.append(1)
	for _i in range(4):
		values.append(6)
	for _i in range(2):
		values.append(8)
	for _i in range(1):
		values.append(7)
	for _i in range(1):
		values.append(4)
	for _i in range(1):
		values.append(3)
	var plan := _plan(values, 5)
	if _total_planned(plan) != values.size():
		_fail("overflow_count", "%d vs %d" % [_total_planned(plan), values.size()])
		return
	if _count_value(plan, 5) != 9:
		_fail("overflow_keep_fives", "5s=%d" % _count_value(plan, 5))
		return
	# Debe haber al menos una pila pura de nueves 5s.
	var found_pure_five := false
	for segment in plan:
		if segment.is_empty():
			continue
		var only_five := true
		for raw in segment:
			if int(raw) != 5:
				only_five = false
				break
		if only_five and segment.size() == 9:
			found_pure_five = true
	if not found_pure_five:
		_fail("overflow_pure_five_stack", str(plan))
		return
	if _count_mixed(plan) < 1:
		_fail("overflow_expects_mix", "mixed=%d" % _count_mixed(plan))
		return
	_ok("overflow_keeps_largest_pure")

func _test_plan_places_every_coin() -> void:
	var values: Array = []
	for v in range(1, 8):
		for _i in range(7):
			values.append(v)
	var plan := _plan(values, 5)
	# Tras colapso no hay grupos de 10; total de fichas se mantiene (= 49).
	if _total_planned(plan) != values.size():
		_fail("places_every_coin", "%d vs %d" % [_total_planned(plan), values.size()])
		return
	for segment in plan:
		if segment.size() > STACK_CAPACITY:
			_fail("over_capacity", str(segment.size()))
			return
	_ok("places_every_coin")

func _test_no_mix_when_chunks_fit() -> void:
	var values: Array = []
	for _i in range(11):
		values.append(7)
	for _i in range(9):
		values.append(2)
	for _i in range(4):
		values.append(6)
	for _i in range(2):
		values.append(5)
	for _i in range(1):
		values.append(4)
	# 11×7 → 2×8 + 1×7; +9×2 +4×6 +2×5 +1×4 = 6 grupos → caben en 7.
	var plan := _plan(values, 7)
	if not _assert_all_homogeneous(plan, "no_mix_when_chunks_fit"):
		return
	if _count_value(plan, 8) != 2 or _count_value(plan, 7) != 1:
		_fail("no_mix_fused_7", "8s=%d 7s=%d" % [_count_value(plan, 8), _count_value(plan, 7)])
		return
	_ok("no_mix_when_chunks_fit")

func _test_opening_deal_skips_fusion() -> void:
	# Apertura: 10×3 no debe colapsar a 4s; se parten en chunks homogéneos.
	var values: Array = []
	for _i in range(10):
		values.append(3)
	for _i in range(4):
		values.append(5)
	var plan: Array = GameRules.build_mix_stack_plan(values, 3, STACK_CAPACITY, false)
	if _count_value(plan, 3) != 10:
		_fail("opening_keeps_tens", "3s=%d" % _count_value(plan, 3))
		return
	if _count_value(plan, 4) != 0:
		_fail("opening_no_fuse", "4s=%d" % _count_value(plan, 4))
		return
	if not _assert_all_homogeneous(plan, "opening_homogeneous"):
		return
	_ok("opening_deal_skips_fusion")

extends SceneTree

## Regresión: Mezclar desarma, recoloca homogéneo y deja pilas de 10 para fusionar.
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
	_test_collapse_one_generation_only()
	_test_overflow_keeps_largest_pure()
	_test_plan_places_every_coin()
	_test_no_mix_when_chunks_fit()
	_test_opening_deal_skips_fusion()
	_test_overflow_uses_empty_stacks_by_number()
	_test_regroups_fused_remainder()
	_test_ten_without_collapse_ready_to_fuse()
	_test_fifty_fours_without_collapse()
	_test_leftover_does_not_complete_nine()
	_test_same_value_not_split_when_it_fits()
	_test_overflow_keeps_nines_together()
	_test_wildcard_mix_joins_fused()
	_test_wildcard_mix_does_not_chain()
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

func _test_collapse_one_generation_only() -> void:
	# 50 × 4 → 10 × 5. La cascada vieja seguía a 2 × 6 y saltaba al nivel 4/9.
	var values: Array = []
	for _i in range(50):
		values.append(4)
	var plan: Array = GameRules.build_mix_stack_plan(values, 5, STACK_CAPACITY, true)
	if _count_value(plan, 6) != 0:
		_fail("collapse_no_sixes", "6s=%d" % _count_value(plan, 6))
		return
	if _count_value(plan, 5) != 10:
		_fail("collapse_ten_fives", "5s=%d" % _count_value(plan, 5))
		return
	if _count_value(plan, 4) != 0:
		_fail("collapse_no_fours", "4s=%d" % _count_value(plan, 4))
		return
	_ok("collapse_one_generation")

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

func _test_overflow_uses_empty_stacks_by_number() -> void:
	# 6 grupos en 5 ranuras: el resto no debe ir todo a una pila dejando otra vacía.
	var values: Array = []
	for _i in range(9):
		values.append(5)
	for _i in range(8):
		values.append(1)
	for _i in range(7):
		values.append(6)
	for _i in range(6):
		values.append(8)
	for _i in range(6):
		values.append(4)
	for _i in range(5):
		values.append(3)
	var plan := _plan(values, 5)
	if _total_planned(plan) != values.size():
		_fail("overflow_empty_count", "%d vs %d" % [_total_planned(plan), values.size()])
		return
	var used := 0
	for segment in plan:
		if not (segment as Array).is_empty():
			used += 1
	if used < 5:
		_fail("overflow_uses_all_stacks", "used=%d plan=%s" % [used, str(plan)])
		return
	var pure_big := 0
	for segment in plan:
		if segment.is_empty():
			continue
		var first := int(segment[0])
		var homogeneous := true
		for raw in segment:
			if int(raw) != first:
				homogeneous = false
				break
		if homogeneous and segment.size() >= 6:
			pure_big += 1
	if pure_big < 2:
		_fail("overflow_keeps_groups_by_number", "pure_big=%d plan=%s" % [pure_big, str(plan)])
		return
	_ok("overflow_uses_empty_stacks_by_number")

func _test_regroups_fused_remainder() -> void:
	# 12 × 5 + 3 × 6 → colapsa a 2×6 + 2×5 + 3×6 = 2 cincos y 5 seises, homogéneo.
	var values: Array = []
	for _i in range(12):
		values.append(5)
	for _i in range(3):
		values.append(6)
	var plan := _plan(values, 4)
	if not _assert_all_homogeneous(plan, "regroup_fused_homogeneous"):
		return
	if _count_value(plan, 5) != 2:
		_fail("regroup_leftover_fives", "5s=%d" % _count_value(plan, 5))
		return
	if _count_value(plan, 6) != 5:
		_fail("regroup_all_sixes", "6s=%d" % _count_value(plan, 6))
		return
	_ok("regroups_fused_remainder")

func _segment_is_value(segment: Array, value: int) -> bool:
	if segment.is_empty():
		return false
	for raw in segment:
		if int(raw) != value:
			return false
	return true

func _test_ten_without_collapse_ready_to_fuse() -> void:
	# Mezclar recoloca; resolve fusiona la pila de 10. Colapsar acá dejaba el 10 crudo.
	var values: Array = []
	for _i in range(10):
		values.append(5)
	for _i in range(3):
		values.append(7)
	var plan: Array = GameRules.build_mix_stack_plan(values, 4, STACK_CAPACITY, false)
	if _count_value(plan, 5) != 10 or _count_value(plan, 6) != 0:
		_fail("ten_no_collapse", "5s=%d 6s=%d" % [_count_value(plan, 5), _count_value(plan, 6)])
		return
	var found_ten := false
	for segment in plan:
		if (segment as Array).size() == 10 and _segment_is_value(segment, 5):
			found_ten = true
			break
	if not found_ten:
		_fail("ten_ready_to_fuse", str(plan))
		return
	_ok("ten_without_collapse_ready_to_fuse")

func _test_fifty_fours_without_collapse() -> void:
	# 50 cuatros → 5 pilas de 10. Collapse+skip dejaba 10 cincos sin fusionar.
	var values: Array = []
	for _i in range(50):
		values.append(4)
	var plan: Array = GameRules.build_mix_stack_plan(values, 5, STACK_CAPACITY, false)
	if _count_value(plan, 4) != 50:
		_fail("fifty_keeps_fours", "4s=%d" % _count_value(plan, 4))
		return
	if _count_value(plan, 5) != 0:
		_fail("fifty_no_fives_yet", "5s=%d" % _count_value(plan, 5))
		return
	var tens := 0
	for segment in plan:
		if (segment as Array).size() == 10 and _segment_is_value(segment, 4):
			tens += 1
	if tens != 5:
		_fail("fifty_five_tens", "tens=%d plan=%s" % [tens, str(plan)])
		return
	_ok("fifty_fours_without_collapse")

func _test_leftover_does_not_complete_nine() -> void:
	# 9 cincos + 4 seises + 3 ochos en 2 ranuras: no rellenar los 9 con otro número.
	var plan: Array = [[], []]
	var overflow: Array = []
	for _i in range(9):
		overflow.append(5)
	for _i in range(4):
		overflow.append(6)
	for _i in range(3):
		overflow.append(8)
	GameRules._mix_fill_overflow_by_value(plan, overflow, 0, 2, STACK_CAPACITY)
	var found_nine_fives := false
	var mixed_ten_fives := false
	for segment in plan:
		if _segment_is_value(segment, 5) and (segment as Array).size() == 9:
			found_nine_fives = true
		if (segment as Array).size() == 10 and int(segment[0]) == 5 and not _segment_is_value(segment, 5):
			mixed_ten_fives = true
	if not found_nine_fives:
		_fail("leftover_keeps_nine_fives", str(plan))
		return
	if mixed_ten_fives:
		_fail("leftover_fake_ten", str(plan))
		return
	_ok("leftover_does_not_complete_nine")

func _count_pure_stacks_of(plan: Array, value: int) -> int:
	var n := 0
	for segment in plan:
		if _segment_is_value(segment, value):
			n += 1
	return n

func _test_same_value_not_split_when_it_fits() -> void:
	# 10 de un número + el resto caben: no partir los 22 ni mezclarlos.
	var values: Array = []
	for _i in range(10):
		values.append(22)
	for _i in range(10):
		values.append(26)
	for _i in range(8):
		values.append(28)
	for _i in range(6):
		values.append(27)
	for _i in range(6):
		values.append(23)
	for _i in range(6):
		values.append(24)
	for _i in range(4):
		values.append(30)
	for _i in range(3):
		values.append(25)
	var plan: Array = GameRules.build_mix_stack_plan(values, 10, STACK_CAPACITY, false)
	if not _assert_all_homogeneous(plan, "same_value_not_split"):
		return
	if _count_pure_stacks_of(plan, 22) != 1 or _count_value(plan, 22) != 10:
		_fail("twenty_twos_one_stack", str(plan))
		return
	if _count_pure_stacks_of(plan, 26) != 1 or _count_value(plan, 26) != 10:
		_fail("twenty_sixes_one_stack", str(plan))
		return
	_ok("same_value_not_split_when_it_fits")

func _test_overflow_keeps_nines_together() -> void:
	# 11 números, 10 ranuras: los 9 veinti-dós quedan en una sola pila pura.
	var values: Array = []
	for _i in range(9):
		values.append(22)
	for v in range(23, 30):
		for _i in range(5):
			values.append(v)
	for v in range(30, 33):
		for _i in range(2):
			values.append(v)
	var plan: Array = GameRules.build_mix_stack_plan(values, 10, STACK_CAPACITY, false)
	if _total_planned(plan) != values.size():
		_fail("overflow_nines_count", "%d vs %d" % [_total_planned(plan), values.size()])
		return
	if _count_pure_stacks_of(plan, 22) != 1 or _count_value(plan, 22) != 9:
		_fail("overflow_nines_together", str(plan))
		return
	_ok("overflow_keeps_nines_together")

func _test_wildcard_mix_joins_fused() -> void:
	# 10×22 + 3×23 → fusiona a 2×23 y los junta: 5 veintitres en una pila.
	var values: Array = []
	for _i in range(10):
		values.append(22)
	for _i in range(3):
		values.append(23)
	var plan: Array = GameRules.build_wildcard_mix_plan(values, 5, STACK_CAPACITY)
	if _count_value(plan, 22) != 0:
		_fail("wildcard_fused_22", "22s=%d" % _count_value(plan, 22))
		return
	if _count_value(plan, 23) != 5:
		_fail("wildcard_joined_23", "23s=%d" % _count_value(plan, 23))
		return
	if _count_pure_stacks_of(plan, 23) != 1:
		_fail("wildcard_one_23_stack", str(plan))
		return
	if not _assert_all_homogeneous(plan, "wildcard_mix_joins"):
		return
	_ok("wildcard_mix_joins_fused")

func _test_wildcard_mix_does_not_chain() -> void:
	# 50×4 → pila de 10 cincos → se convierte a 2 seises. No sigue a sietes.
	var values: Array = []
	for _i in range(50):
		values.append(4)
	var plan: Array = GameRules.build_wildcard_mix_plan(values, 5, STACK_CAPACITY)
	if _count_value(plan, 4) != 0:
		_fail("wildcard_no_fours", "4s=%d" % _count_value(plan, 4))
		return
	if _count_value(plan, 7) != 0:
		_fail("wildcard_no_chain_sevens", "7s=%d" % _count_value(plan, 7))
		return
	if _count_value(plan, 6) != 2 or _count_value(plan, 5) != 0:
		_fail("wildcard_two_sixes", "6s=%d 5s=%d" % [
			_count_value(plan, 6), _count_value(plan, 5)
		])
		return
	if _count_pure_stacks_of(plan, 6) != 1:
		_fail("wildcard_sixes_together", str(plan))
		return
	_ok("wildcard_mix_converts_completed_stack")

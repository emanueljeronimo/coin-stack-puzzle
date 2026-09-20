extends SceneTree

const BoardMetricsServiceScript = preload("res://board_metrics_service.gd")

class FakeStack:
	extends RefCounted
	var _empty: bool
	var _top: int
	var _free: int
	var _receivable: Dictionary

	func _init(empty: bool, top: int, free: int, receivable: Dictionary) -> void:
		_empty = empty
		_top = top
		_free = free
		_receivable = receivable

	func is_empty() -> bool:
		return _empty

	func top_value() -> int:
		return _top

	func free_slots() -> int:
		return _free

	func can_receive_value(value: int) -> bool:
		return bool(_receivable.get(value, false))

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== board_metrics_service test ===")
	_test_count_total_free_slots()
	_test_count_legal_moves()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_count_total_free_slots() -> void:
	var stacks: Array = [
		FakeStack.new(false, 2, 1, {}),
		FakeStack.new(true, 0, 3, {}),
	]
	var total := BoardMetricsServiceScript.count_total_free_slots(stacks)
	if total != 4:
		_fail("count_total_free_slots", "expected 4 got %d" % total)
		return
	_ok("count_total_free_slots")

func _test_count_legal_moves() -> void:
	var a := FakeStack.new(false, 3, 0, {2: true})
	var b := FakeStack.new(false, 2, 0, {3: true})
	var c := FakeStack.new(true, 0, 0, {2: true, 3: true})
	var moves := BoardMetricsServiceScript.count_legal_moves([a, b, c])
	if moves != 4:
		_fail("count_legal_moves", "expected 4 got %d" % moves)
		return
	_ok("count_legal_moves")

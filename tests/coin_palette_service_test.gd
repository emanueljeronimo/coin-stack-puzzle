extends SceneTree

const Service := preload("res://coin_palette_service.gd")
const CoinScript := preload("res://coin.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== coin_palette_service test ===")
	_test_loop_restarts_at_sixteen()
	_test_palette_has_fifteen()
	_test_palette_colors_are_distinct()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_loop_restarts_at_sixteen() -> void:
	var n: int = 15
	if Service.palette_index(16, n) != Service.palette_index(1, n):
		_fail("sixteen_is_one")
		return
	if Service.palette_index(17, n) != Service.palette_index(2, n):
		_fail("seventeen_is_two")
		return
	if Service.palette_index(18, n) != Service.palette_index(3, n):
		_fail("eighteen_is_three")
		return
	if Service.palette_index(14, n) == Service.palette_index(1, n):
		_fail("fourteen_should_not_be_one")
		return
	if Service.wrap_cycle(16, n) != 1:
		_fail("sixteen_starts_second_cycle")
		return
	_ok("loop_restarts_at_sixteen")

func _test_palette_has_fifteen() -> void:
	if CoinScript.VALUE_COLORS.size() != 15:
		_fail("palette_size", str(CoinScript.VALUE_COLORS.size()))
		return
	_ok("palette_has_fifteen")

func _test_palette_colors_are_distinct() -> void:
	var colors: Array = CoinScript.VALUE_COLORS
	for i in range(colors.size()):
		for j in range(i + 1, colors.size()):
			var delta: float = Service.max_channel_delta(colors[i], colors[j])
			if delta < 0.16:
				_fail("too_close_%d_%d" % [i + 1, j + 1], str(delta))
				return
	_ok("palette_colors_are_distinct")

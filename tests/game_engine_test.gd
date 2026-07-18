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
	_test_descriptions()
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
	if GameEngineScript.cycle_base_level(10, 5, 15) != 15:
		_fail("cycle_base_15")
		return
	if GameEngineScript.reached_cycle_coin_milestone(14, 1, 5, 15) != 0:
		_fail("no_milestone_14")
		return
	if GameEngineScript.reached_cycle_coin_milestone(15, 1, 5, 15) != 15:
		_fail("milestone_15")
		return
	_ok("cycle_math")

func _test_checkpoint_eval() -> void:
	var lv2 := GameEngineScript.evaluate_checkpoint_level(5, 1, 1, 5, 5, 15)
	if lv2 != 2:
		_fail("create_5_is_level_2", str(lv2))
		return
	var lv15 := GameEngineScript.evaluate_checkpoint_level(11, 6, 1, 5, 5, 15)
	if lv15 != 15:
		_fail("half_11_is_level_15", str(lv15))
		return
	_ok("checkpoint_eval")

func _test_descriptions() -> void:
	var d2 := GameEngineScript.checkpoint_level_description(2, 5, 15)
	if d2.find("5") < 0:
		_fail("desc_level_2", d2)
		return
	var d3 := GameEngineScript.checkpoint_level_description(3, 5, 15)
	if d3.find("mitad") < 0:
		_fail("desc_level_3", d3)
		return
	_ok("descriptions")

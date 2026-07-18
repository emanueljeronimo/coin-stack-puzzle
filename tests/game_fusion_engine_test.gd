extends SceneTree

const GameFusionEngineScript = preload("res://game_fusion_engine.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_fusion_engine test ===")
	_test_bonus_flag()
	_test_bonus_amount()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_bonus_flag() -> void:
	if GameFusionEngineScript.bonus_enabled(false, true):
		_fail("bonus_disabled_global")
		return
	if GameFusionEngineScript.bonus_enabled(true, false):
		_fail("bonus_disabled_unlock")
		return
	if not GameFusionEngineScript.bonus_enabled(true, true):
		_fail("bonus_enabled")
		return
	_ok("bonus_flag")

func _test_bonus_amount() -> void:
	var none := GameFusionEngineScript.bonus_amount_for_target(4, 4, 0, 9, 2, 1, false)
	if none != 0:
		_fail("bonus_none", str(none))
		return
	var full := GameFusionEngineScript.bonus_amount_for_target(4, 4, 3, 9, 2, 1, true)
	if full != 2:
		_fail("bonus_full", str(full))
		return
	var reduced := GameFusionEngineScript.bonus_amount_for_target(4, 4, 10, 9, 2, 1, true)
	if reduced != 1:
		_fail("bonus_reduced", str(reduced))
		return
	var wrong_value := GameFusionEngineScript.bonus_amount_for_target(5, 4, 0, 9, 2, 1, true)
	if wrong_value != 0:
		_fail("bonus_wrong_fused_value", str(wrong_value))
		return
	_ok("bonus_amount")

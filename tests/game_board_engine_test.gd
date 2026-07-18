extends SceneTree

const GameBoardEngineScript = preload("res://game_board_engine.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_board_engine test ===")
	_test_level_up_detection()
	_test_checkpoint_decision()
	_test_cycle_reset_state()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_level_up_detection() -> void:
	if not GameBoardEngineScript.has_level_up([1, 2, 6], 5):
		_fail("level_up_detect")
		return
	var lv := GameBoardEngineScript.apply_level_up(7, 11)
	if int(lv.get("current_level", 0)) != 8 or int(lv.get("max_value", 0)) != 12:
		_fail("level_up_apply", str(lv))
		return
	_ok("level_up")

func _test_checkpoint_decision() -> void:
	var no_change := GameBoardEngineScript.decide_checkpoint_update(10, 9, 0)
	if bool(no_change.get("changed", true)):
		_fail("checkpoint_no_change", str(no_change))
		return
	var eval_up := GameBoardEngineScript.decide_checkpoint_update(10, 12, 0)
	if not bool(eval_up.get("changed", false)) or int(eval_up.get("checkpoint_level", 0)) != 12:
		_fail("checkpoint_eval_up", str(eval_up))
		return
	var milestone := GameBoardEngineScript.decide_checkpoint_update(14, 13, 15)
	if not bool(milestone.get("did_cycle_reset", false)) or int(milestone.get("checkpoint_level", 0)) != 15:
		_fail("checkpoint_milestone", str(milestone))
		return
	_ok("checkpoint_decision")

func _test_cycle_reset_state() -> void:
	var st := GameBoardEngineScript.build_cycle_reset_state(30, {
		"board_cycle_levels": 15,
		"checkpoint_base_value": 5,
		"cycle_reset_stacks": 4,
		"adjacent_slot_base_price": 600,
	})
	if not bool(st.get("valid", false)):
		_fail("cycle_reset_valid", str(st))
		return
	if int(st.get("roll_value_floor", 0)) != 25:
		_fail("cycle_reset_floor", str(st))
		return
	_ok("cycle_reset_state")

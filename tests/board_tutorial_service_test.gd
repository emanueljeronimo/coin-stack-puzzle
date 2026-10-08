extends SceneTree

const BoardTutorialServiceScript = preload("res://board_tutorial_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== board_tutorial_service test ===")
	_test_start_rules()
	_test_layout_and_moves()
	_test_step_flow()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_start_rules() -> void:
	if not BoardTutorialServiceScript.should_start(false, 1):
		_fail("start_new_player")
		return
	if BoardTutorialServiceScript.should_start(true, 1):
		_fail("skip_when_done")
		return
	if BoardTutorialServiceScript.should_start(false, 6):
		_fail("skip_when_leveled")
		return
	if not BoardTutorialServiceScript.should_skip_for_progress(6):
		_fail("skip_progress")
		return
	if BoardTutorialServiceScript.should_skip_for_progress(1):
		_fail("keep_level_1")
		return
	_ok("start_rules")

func _test_layout_and_moves() -> void:
	var rows: Array = BoardTutorialServiceScript.initial_stack_rows()
	if rows.size() != 5 or (rows[4] as Array).size() != 0:
		_fail("empty_last_slot", str(rows))
		return
	if not BoardTutorialServiceScript.is_merge_layout(rows):
		_fail("detect_layout")
		return
	var shuffled: Array = rows.duplicate(true)
	(shuffled[0] as Array).append(2)
	if BoardTutorialServiceScript.is_merge_layout(shuffled):
		_fail("reject_changed_layout")
		return
	if not BoardTutorialServiceScript.can_select_stack("merge", 0):
		_fail("select_origin")
		return
	if BoardTutorialServiceScript.can_select_stack("merge", 2):
		_fail("block_other_stack")
		return
	if not BoardTutorialServiceScript.can_move("merge", 0, 1):
		_fail("allow_merge_pair")
		return
	if BoardTutorialServiceScript.can_move("merge", 0, 2):
		_fail("block_wrong_dest")
		return
	if BoardTutorialServiceScript.can_select_stack("roll", 0):
		_fail("no_select_on_roll")
		return
	_ok("layout_and_moves")

func _test_step_flow() -> void:
	if not BoardTutorialServiceScript.blocks_roll("merge"):
		_fail("block_roll_on_merge")
		return
	if not BoardTutorialServiceScript.uses_scripted_roll("roll"):
		_fail("scripted_roll")
		return
	var rolled: Array = BoardTutorialServiceScript.roll_values()
	if rolled.size() < 8 or int(rolled[0]) != 1:
		_fail("easy_roll", str(rolled))
		return
	if BoardTutorialServiceScript.next_after_merge("merge") != "roll":
		_fail("merge_to_roll")
		return
	if BoardTutorialServiceScript.next_after_roll("roll") != "done":
		_fail("roll_to_done")
		return
	if BoardTutorialServiceScript.speech_for_step("merge").is_empty():
		_fail("merge_speech")
		return
	if not BoardTutorialServiceScript.pointer_is_stack("merge"):
		_fail("pointer_stack")
		return
	if BoardTutorialServiceScript.pointer_is_stack("roll"):
		_fail("pointer_cta")
		return
	_ok("step_flow")

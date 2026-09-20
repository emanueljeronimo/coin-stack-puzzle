extends SceneTree

const MainMoveInteractionServiceScript = preload("res://main_move_interaction_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== main_move_interaction_service test ===")
	_test_click_helpers()
	_test_messages()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_click_helpers() -> void:
	if MainMoveInteractionServiceScript.can_process_click(true):
		_fail("can_process_click_blocked")
		return
	if not MainMoveInteractionServiceScript.can_process_click(false):
		_fail("can_process_click_allowed")
		return
	if not MainMoveInteractionServiceScript.clicked_outside_stack(null):
		_fail("clicked_outside_stack_null")
		return
	if MainMoveInteractionServiceScript.clicked_outside_stack(Node.new()):
		_fail("clicked_outside_stack_node")
		return
	_ok("click_helpers")

func _test_messages() -> void:
	if MainMoveInteractionServiceScript.invalid_move_message().is_empty():
		_fail("invalid_move_message")
		return
	if MainMoveInteractionServiceScript.glove_prompt_no_stack().is_empty():
		_fail("glove_prompt_no_stack")
		return
	_ok("messages")

extends SceneTree

const MainInputRouterScript = preload("res://main_input_router.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== main_input_router test ===")
	_test_blocking_rules()
	_test_control_click_consumption()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_blocking_rules() -> void:
	var overlay := ColorRect.new()
	overlay.visible = false
	if MainInputRouterScript.should_block_board_input(null, null, overlay, null, null, null):
		_fail("no_block_when_all_closed")
		return
	overlay.visible = true
	if not MainInputRouterScript.should_block_board_input(null, null, overlay, null, null, null):
		_fail("blocks_on_visible_overlay")
		return
	_ok("blocking_rules")

func _test_control_click_consumption() -> void:
	var root := Control.new()
	get_root().add_child(root)
	var btn := Button.new()
	btn.position = Vector2(10, 10)
	btn.size = Vector2(80, 40)
	root.add_child(btn)
	if not MainInputRouterScript.is_click_consumed_by_controls(Vector2(20, 20), [btn]):
		_fail("consumed_inside")
		return
	if MainInputRouterScript.is_click_consumed_by_controls(Vector2(200, 200), [btn]):
		_fail("not_consumed_outside")
		return
	_ok("control_click_consumption")

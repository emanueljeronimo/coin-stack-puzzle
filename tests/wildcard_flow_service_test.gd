extends SceneTree

const BoosterFlowServiceScript = preload("res://booster_flow_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== wildcard_flow_service test ===")
	_test_has_uses()
	_test_action_kind()
	_test_tool_hud_click()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_has_uses() -> void:
	if BoosterFlowServiceScript.has_uses({"mix": 0}, "mix"):
		_fail("has_uses_zero")
		return
	if not BoosterFlowServiceScript.has_uses({"mix": 2}, "mix"):
		_fail("has_uses_positive")
		return
	_ok("has_uses")

func _test_action_kind() -> void:
	if BoosterFlowServiceScript.booster_action_kind("mix") != "mix":
		_fail("kind_mix")
		return
	if BoosterFlowServiceScript.booster_action_kind("hammer") != "tool":
		_fail("kind_hammer")
		return
	if BoosterFlowServiceScript.booster_action_kind("x") != "unknown":
		_fail("kind_unknown")
		return
	_ok("action_kind")

func _test_tool_hud_click() -> void:
	if BoosterFlowServiceScript.should_spend_on_hud("mix") != true:
		_fail("mix_spends_on_hud")
		return
	if BoosterFlowServiceScript.should_spend_on_hud("hammer"):
		_fail("hammer_does_not_spend_on_hud")
		return
	if BoosterFlowServiceScript.should_spend_on_hud("glove"):
		_fail("glove_does_not_spend_on_hud")
		return
	if BoosterFlowServiceScript.tool_hud_click("", "hammer") != "enter":
		_fail("enter_hammer")
		return
	if BoosterFlowServiceScript.tool_hud_click("hammer", "hammer") != "cancel":
		_fail("cancel_hammer")
		return
	if BoosterFlowServiceScript.tool_hud_click("hammer", "glove") != "switch":
		_fail("switch_to_glove")
		return
	if BoosterFlowServiceScript.tool_hud_click("glove", "hammer") != "switch":
		_fail("switch_to_hammer")
		return
	if BoosterFlowServiceScript.tool_hud_click("", "mix") != "ignore":
		_fail("mix_ignore")
		return
	_ok("tool_hud_click")

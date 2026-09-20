extends SceneTree

const TempSlotPurchaseServiceScript = preload("res://temp_slot_purchase_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== temp_slot_purchase_service test ===")
	_test_builders()
	_test_messages()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_builders() -> void:
	var req := TempSlotPurchaseServiceScript.build_purchase_request(10, false, false)
	var rules := TempSlotPurchaseServiceScript.build_rules(5, 30.0, 2)
	if int(req.get("player_stars", -1)) != 10:
		_fail("request_player_stars")
		return
	if int(rules.get("temp_slot_cost_stars", -1)) != 5:
		_fail("rules_cost")
		return
	_ok("builders")

func _test_messages() -> void:
	if TempSlotPurchaseServiceScript.message_for_rejection("already_active", 0, 0).is_empty():
		_fail("already_active_message")
		return
	if TempSlotPurchaseServiceScript.message_for_rejection("insufficient_stars", 7, 3).is_empty():
		_fail("insufficient_message")
		return
	_ok("messages")

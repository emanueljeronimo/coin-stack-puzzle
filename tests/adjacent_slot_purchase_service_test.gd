extends SceneTree

const AdjacentSlotPurchaseServiceScript = preload("res://adjacent_slot_purchase_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== adjacent_slot_purchase_service test ===")
	_test_build_request()
	_test_reason_helpers()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_build_request() -> void:
	var req := AdjacentSlotPurchaseServiceScript.build_purchase_request(2, 6, 14, 9, 10, 25, 8)
	if int(req.get("active_stacks", -1)) != 6:
		_fail("request_active_stacks")
		return
	if int(req.get("adjacent_slot_next_price", -1)) != 8:
		_fail("request_next_price")
		return
	_ok("build_request")

func _test_reason_helpers() -> void:
	if not AdjacentSlotPurchaseServiceScript.is_insufficient_stars("insufficient_stars"):
		_fail("insufficient_helper")
		return
	if not AdjacentSlotPurchaseServiceScript.is_free_unlock("free_unlock"):
		_fail("free_unlock_helper")
		return
	_ok("reason_helpers")

extends SceneTree

const GameEconomyServiceScript = preload("res://game_economy_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_economy_service test ===")
	_test_temp_slot_purchase()
	_test_temp_slot_purchase_rejects()
	_test_adjacent_purchase_paths()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_temp_slot_purchase() -> void:
	var out := GameEconomyServiceScript.purchase_temp_slot(
		{
			"player_stars": 900,
			"temp_slot_bonus_active": false,
			"has_active_temp_stack": false,
		},
		{
			"temp_slot_cost_stars": 200,
			"temp_slot_duration_sec": 60.0,
			"temp_slot_actions_to_close": 3,
		}
	)
	if not bool(out.get("ok", false)):
		_fail("temp_purchase_ok", str(out))
		return
	if int(out.get("player_stars", 0)) != 700:
		_fail("temp_purchase_stars", str(out))
		return
	if int(out.get("temp_slot_actions_remaining", 0)) != 3:
		_fail("temp_purchase_actions", str(out))
		return
	_ok("temp_slot_purchase")

func _test_temp_slot_purchase_rejects() -> void:
	var active := GameEconomyServiceScript.purchase_temp_slot(
		{
			"player_stars": 900,
			"temp_slot_bonus_active": true,
			"has_active_temp_stack": true,
		},
		{
			"temp_slot_cost_stars": 200,
			"temp_slot_duration_sec": 60.0,
			"temp_slot_actions_to_close": 3,
		}
	)
	if bool(active.get("ok", true)):
		_fail("temp_purchase_reject_active", str(active))
		return
	var poor := GameEconomyServiceScript.purchase_temp_slot(
		{
			"player_stars": 100,
			"temp_slot_bonus_active": false,
			"has_active_temp_stack": false,
		},
		{
			"temp_slot_cost_stars": 200,
			"temp_slot_duration_sec": 60.0,
			"temp_slot_actions_to_close": 3,
		}
	)
	if bool(poor.get("ok", true)):
		_fail("temp_purchase_reject_poor", str(poor))
		return
	_ok("temp_slot_purchase_rejects")

func _test_adjacent_purchase_paths() -> void:
	var free := GameEconomyServiceScript.purchase_adjacent_slot(
		{
			"adjacent_offer_board_index": 9,
			"active_stacks": 6,
			"max_permanent_stacks": 14,
			"checkpoint_level": 8,
			"next_free_slot_unlock_level": 8,
			"player_stars": 100,
			"adjacent_slot_next_price": 600,
		}
	)
	if str(free.get("reason", "")) != "free_unlock":
		_fail("adjacent_free_unlock", str(free))
		return

	var paid := GameEconomyServiceScript.purchase_adjacent_slot(
		{
			"adjacent_offer_board_index": 9,
			"active_stacks": 6,
			"max_permanent_stacks": 14,
			"checkpoint_level": 7,
			"next_free_slot_unlock_level": 8,
			"player_stars": 1000,
			"adjacent_slot_next_price": 600,
		}
	)
	if str(paid.get("reason", "")) != "purchased":
		_fail("adjacent_paid_reason", str(paid))
		return
	if int(paid.get("player_stars", -1)) != 400:
		_fail("adjacent_paid_stars", str(paid))
		return

	var poor := GameEconomyServiceScript.purchase_adjacent_slot(
		{
			"adjacent_offer_board_index": 9,
			"active_stacks": 6,
			"max_permanent_stacks": 14,
			"checkpoint_level": 7,
			"next_free_slot_unlock_level": 8,
			"player_stars": 200,
			"adjacent_slot_next_price": 600,
		}
	)
	if bool(poor.get("ok", true)):
		_fail("adjacent_reject_poor", str(poor))
		return
	_ok("adjacent_purchase_paths")

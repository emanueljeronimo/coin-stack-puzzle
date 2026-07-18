extends SceneTree

const GameTurnEngineScript = preload("res://game_turn_engine.gd")
const GameEconomyServiceScript = preload("res://game_economy_service.gd")
const GameRulesScript = preload("res://game_rules.gd")
const GameSlotServiceScript = preload("res://game_slot_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== integration_turn_economy_flow test ===")
	_test_temp_slot_lifecycle_with_actions()
	_test_roll_generation_policy_in_flow()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_temp_slot_lifecycle_with_actions() -> void:
	var purchase := GameEconomyServiceScript.purchase_temp_slot(
		{
			"player_stars": 500,
			"temp_slot_bonus_active": false,
			"has_active_temp_stack": false,
		},
		{
			"temp_slot_cost_stars": 200,
			"temp_slot_duration_sec": 60.0,
			"temp_slot_actions_to_close": GameRulesScript.TEMP_SLOT_ACTIONS_TO_CLOSE,
		}
	)
	if not bool(purchase.get("ok", false)):
		_fail("temp_purchase", str(purchase))
		return

	var active := bool(purchase.get("temp_slot_bonus_active", false))
	var remaining := int(purchase.get("temp_slot_actions_remaining", 0))
	for _i in range(2):
		var step := GameSlotServiceScript.consume_temp_action(active, remaining)
		remaining = int(step.get("actions_remaining", remaining))
		if bool(step.get("should_close", false)):
			_fail("should_not_close_early", str(step))
			return
	var last := GameSlotServiceScript.consume_temp_action(active, remaining)
	if not bool(last.get("should_close", false)):
		_fail("should_close_on_third_action", str(last))
		return
	_ok("temp_slot_lifecycle_with_actions")

func _test_roll_generation_policy_in_flow() -> void:
	var values := GameTurnEngineScript.build_roll_values(10, 12, func() -> int:
		return 2
	)
	if values.size() != 9:
		_fail("roll_pool_size", str(values.size()))
		return
	values.shuffle()
	var roll_count := GameTurnEngineScript.compute_roll_count(values.size(), 4, true)
	if roll_count != 3:
		_fail("roll_keep_one_free", str(roll_count))
		return
	if values.size() < roll_count:
		_fail("roll_count_not_exceed_pool", str(values.size()))
		return
	_ok("roll_generation_policy_in_flow")

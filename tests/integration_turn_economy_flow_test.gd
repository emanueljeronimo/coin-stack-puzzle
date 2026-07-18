extends SceneTree

const GameTurnEngineScript = preload("res://game_turn_engine.gd")
const GameEconomyServiceScript = preload("res://game_economy_service.gd")
const GameRulesScript = preload("res://game_rules.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== integration_turn_economy_flow test ===")
	_test_temp_slot_lifecycle_timer_only()
	_test_roll_generation_policy_in_flow()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_temp_slot_lifecycle_timer_only() -> void:
	var purchase := GameEconomyServiceScript.purchase_temp_slot(
		{
			"player_stars": 500,
			"temp_slot_bonus_active": false,
			"has_active_temp_stack": false,
		},
		{
			"temp_slot_cost_stars": 200,
			"temp_slot_duration_sec": 60.0,
			"temp_slot_actions_to_close": (
				GameRulesScript.TEMP_SLOT_ACTIONS_TO_CLOSE if GameRulesScript.TEMP_SLOT_CLOSE_BY_ACTIONS else 0
			),
		}
	)
	if not bool(purchase.get("ok", false)):
		_fail("temp_purchase", str(purchase))
		return
	var remaining := int(purchase.get("temp_slot_actions_remaining", -1))
	if GameRulesScript.TEMP_SLOT_CLOSE_BY_ACTIONS:
		if remaining != GameRulesScript.TEMP_SLOT_ACTIONS_TO_CLOSE:
			_fail("temp_action_budget_when_enabled", str(purchase))
			return
	else:
		if remaining != 0:
			_fail("temp_action_budget_disabled", str(purchase))
			return
	_ok("temp_slot_lifecycle_timer_only")

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

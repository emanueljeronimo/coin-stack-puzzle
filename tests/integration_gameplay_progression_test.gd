extends SceneTree

const GameEngineScript = preload("res://game_engine.gd")
const GameBoardEngineScript = preload("res://game_board_engine.gd")
const GameRulesScript = preload("res://game_rules.gd")
const GameSlotServiceScript = preload("res://game_slot_service.gd")

const CHECKPOINT_BASE_VALUE := 5
const CHECKPOINT_HALF_THRESHOLD := 5
const BOARD_CYCLE_LEVELS := 15
const CYCLE_RESET_STACKS := 4
const ADJACENT_BASE_PRICE := 600
const MAX_PERMANENT_STACKS := 14

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== integration_gameplay_progression test ===")
	_test_progression_purchase_and_cycle_reset()
	_test_free_unlock_applies_immediately_on_level_threshold()
	_test_reconcile_missing_free_unlock_state()
	_test_no_early_unlock_before_target_level()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _apply_free_unlocks(state: Dictionary, previous_level: int, new_level: int) -> void:
	while int(state.get("active_stacks", 1)) < MAX_PERMANENT_STACKS:
		var unlock_level := int(state.get("next_free_slot_unlock_level", 1))
		if GameSlotServiceScript.is_stale_unlock(previous_level, unlock_level):
			state["next_free_slot_unlock_level"] = GameRulesScript.next_free_slot_unlock_level(unlock_level)
			continue
		if not GameSlotServiceScript.can_grant_free_unlock(previous_level, new_level, unlock_level):
			break
		state["active_stacks"] = int(state.get("active_stacks", 1)) + 1
		state["next_free_slot_unlock_level"] = GameRulesScript.next_free_slot_unlock_level(unlock_level)

func _advance_checkpoint(state: Dictionary, highest_value: int, highest_value_count: int) -> Dictionary:
	var previous_checkpoint := int(state.get("checkpoint_level", 1))
	var roll_value_floor := int(state.get("roll_value_floor", 1))
	var eval_checkpoint := GameEngineScript.evaluate_checkpoint_level(
		highest_value,
		highest_value_count,
		roll_value_floor,
		CHECKPOINT_BASE_VALUE,
		CHECKPOINT_HALF_THRESHOLD,
		BOARD_CYCLE_LEVELS
	)
	var milestone := GameEngineScript.reached_cycle_coin_milestone(
		highest_value,
		roll_value_floor,
		CHECKPOINT_BASE_VALUE,
		BOARD_CYCLE_LEVELS
	)
	var decision := GameBoardEngineScript.decide_checkpoint_update(
		previous_checkpoint,
		eval_checkpoint,
		milestone
	)
	if not bool(decision.get("changed", false)):
		return state
	state["checkpoint_level"] = int(decision.get("checkpoint_level", previous_checkpoint))
	if bool(decision.get("did_cycle_reset", false)):
		var cycle_state := GameBoardEngineScript.build_cycle_reset_state(
			milestone,
			{
				"board_cycle_levels": BOARD_CYCLE_LEVELS,
				"checkpoint_base_value": CHECKPOINT_BASE_VALUE,
				"cycle_reset_stacks": CYCLE_RESET_STACKS,
				"adjacent_slot_base_price": ADJACENT_BASE_PRICE,
			}
		)
		if bool(cycle_state.get("valid", false)):
			state["active_stacks"] = int(cycle_state.get("active_stacks", CYCLE_RESET_STACKS))
			state["current_level"] = int(cycle_state.get("current_level", 1))
			state["max_value"] = int(cycle_state.get("max_value", milestone))
			state["roll_value_floor"] = int(cycle_state.get("roll_value_floor", milestone - CHECKPOINT_BASE_VALUE))
			state["adjacent_slot_next_price"] = int(cycle_state.get("adjacent_slot_next_price", ADJACENT_BASE_PRICE))
			state["next_free_slot_unlock_level"] = GameRulesScript.initial_free_slot_unlock_level(milestone)
	else:
		_apply_free_unlocks(state, previous_checkpoint, int(state.get("checkpoint_level", previous_checkpoint)))
	return state

func _test_progression_purchase_and_cycle_reset() -> void:
	var state := {
		"checkpoint_level": 1,
		"current_level": 1,
		"max_value": 5,
		"roll_value_floor": 1,
		"active_stacks": 5,
		"adjacent_slot_next_price": ADJACENT_BASE_PRICE,
		"next_free_slot_unlock_level": GameRulesScript.initial_free_slot_unlock_level(0),
	}

	state = _advance_checkpoint(state, 5, 1)
	if int(state.get("checkpoint_level", 0)) != 2:
		_fail("progress_to_level_2", str(state))
		return

	# Compra antes del nivel gratis: consume el próximo hito gratis.
	state["active_stacks"] = int(state.get("active_stacks", 5)) + 1
	state["next_free_slot_unlock_level"] = GameRulesScript.next_free_slot_unlock_level(
		int(state.get("next_free_slot_unlock_level", 4))
	)

	state = _advance_checkpoint(state, 6, 1) # nivel 4
	if int(state.get("checkpoint_level", 0)) != 4:
		_fail("progress_to_level_4", str(state))
		return
	if int(state.get("active_stacks", 0)) != 6:
		_fail("no_double_unlock_after_purchase", str(state))
		return

	state = _advance_checkpoint(state, 7, 1) # nivel 6
	if int(state.get("checkpoint_level", 0)) != 6:
		_fail("progress_to_level_6", str(state))
		return
	if int(state.get("active_stacks", 0)) != 7:
		_fail("unlock_on_consumed_next_tier", str(state))
		return

	state = _advance_checkpoint(state, 15, 1) # reset de ciclo
	if int(state.get("checkpoint_level", 0)) != 15:
		_fail("checkpoint_at_milestone", str(state))
		return
	if int(state.get("active_stacks", 0)) != CYCLE_RESET_STACKS:
		_fail("cycle_reset_stacks", str(state))
		return
	if int(state.get("roll_value_floor", 0)) != 10:
		_fail("cycle_reset_floor", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 19:
		_fail("cycle_reset_unlock_cursor", str(state))
		return

	_ok("progression_purchase_and_cycle_reset")

func _test_free_unlock_applies_immediately_on_level_threshold() -> void:
	var state := {
		"checkpoint_level": 1,
		"current_level": 1,
		"max_value": 5,
		"roll_value_floor": 1,
		"active_stacks": 5,
		"adjacent_slot_next_price": ADJACENT_BASE_PRICE,
		"next_free_slot_unlock_level": GameRulesScript.initial_free_slot_unlock_level(0),
	}

	# Nivel 2 al crear ficha 5 (sin desbloqueo gratis aún).
	state = _advance_checkpoint(state, 5, 1)
	if int(state.get("checkpoint_level", 0)) != 2:
		_fail("immediate_unlock_level_2", str(state))
		return
	if int(state.get("active_stacks", 0)) != 5:
		_fail("immediate_unlock_no_early_slot", str(state))
		return

	# Nivel 4 al crear ficha 6: debe otorgar ranura gratis en el mismo avance.
	state = _advance_checkpoint(state, 6, 1)
	if int(state.get("checkpoint_level", 0)) != 4:
		_fail("immediate_unlock_level_4", str(state))
		return
	if int(state.get("active_stacks", 0)) != 6:
		_fail("immediate_unlock_slot_granted", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 6:
		_fail("immediate_unlock_cursor_advanced", str(state))
		return

	_ok("free_unlock_applies_immediately_on_level_threshold")

func _test_reconcile_missing_free_unlock_state() -> void:
	# Estado inconsistente típico de bug visual/restore:
	# nivel ya alcanzado, pero la ranura gratis aún no fue aplicada.
	var state := {
		"checkpoint_level": 4,
		"current_level": 2,
		"max_value": 6,
		"roll_value_floor": 1,
		"active_stacks": 5,
		"adjacent_slot_next_price": ADJACENT_BASE_PRICE,
		"next_free_slot_unlock_level": 4,
	}

	_apply_free_unlocks(state, 3, 4)
	if int(state.get("active_stacks", 0)) != 6:
		_fail("reconcile_missing_unlock_slot", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 6:
		_fail("reconcile_missing_unlock_cursor", str(state))
		return

	_ok("reconcile_missing_free_unlock_state")

func _test_no_early_unlock_before_target_level() -> void:
	var state := {
		"checkpoint_level": 3,
		"current_level": 2,
		"max_value": 6,
		"roll_value_floor": 1,
		"active_stacks": 5,
		"adjacent_slot_next_price": ADJACENT_BASE_PRICE,
		"next_free_slot_unlock_level": 4,
	}

	_apply_free_unlocks(state, 2, 3)
	if int(state.get("active_stacks", 0)) != 5:
		_fail("no_early_unlock_slot", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 4:
		_fail("no_early_unlock_cursor", str(state))
		return

	_ok("no_early_unlock_before_target_level")

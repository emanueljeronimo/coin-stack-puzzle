extends SceneTree

const GameEngineScript = preload("res://game_engine.gd")
const GameBoardEngineScript = preload("res://game_board_engine.gd")
const GameRulesScript = preload("res://game_rules.gd")
const GameSlotServiceScript = preload("res://game_slot_service.gd")

const CHECKPOINT_BASE_VALUE := 5
const CHECKPOINT_HALF_THRESHOLD := 5
const BOARD_CYCLE_LEVELS := 15
const CYCLE_RESET_STACKS := 5
const ADJACENT_BASE_PRICE := 600
const MAX_PERMANENT_STACKS := 14

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== integration_gameplay_progression test ===")
	_test_progression_purchase_and_cycle_reset()
	_test_first_cycle_levels_from_one_to_nine()
	_test_cycle_reset_skips_stale_unlocks_when_checkpoint_ahead()
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

func _advance_checkpoint(
	state: Dictionary,
	highest_value: int,
	highest_value_count: int,
	fill_path: bool = true
) -> Dictionary:
	var previous_checkpoint := int(state.get("checkpoint_level", 1))
	var roll_value_floor := int(state.get("roll_value_floor", 1))
	var counts := {highest_value: highest_value_count}
	# Simula que llegaste a esa ficha paso a paso (un 8 implica 6 y 7).
	# En un prestige a tiempo no rellenar 6–14: eso evalúa 21 y pisa el hito 15.
	if fill_path:
		for v in range(CHECKPOINT_BASE_VALUE + 1, highest_value):
			if not counts.has(v):
				counts[v] = 1
	var eval_checkpoint := GameEngineScript.evaluate_checkpoint_from_piles(
		func(v: int) -> int: return int(counts.get(v, 0)),
		roll_value_floor,
		CHECKPOINT_BASE_VALUE,
		CHECKPOINT_HALF_THRESHOLD,
		BOARD_CYCLE_LEVELS,
		int(state.get("cycle_checkpoint_origin", 0)),
		previous_checkpoint
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
				"checkpoint_level": int(state.get("checkpoint_level", milestone)),
			}
		)
		if bool(cycle_state.get("valid", false)):
			state["active_stacks"] = int(cycle_state.get("active_stacks", CYCLE_RESET_STACKS))
			state["current_level"] = int(cycle_state.get("current_level", 1))
			state["max_value"] = int(cycle_state.get(
				"max_value",
				GameEngineScript.cycle_reset_max_value(milestone)
			))
			state["roll_value_floor"] = int(cycle_state.get(
				"roll_value_floor",
				GameEngineScript.cycle_reset_roll_value_floor(milestone, CHECKPOINT_BASE_VALUE)
			))
			state["cycle_checkpoint_origin"] = int(cycle_state.get(
				"cycle_checkpoint_origin",
				GameEngineScript.cycle_checkpoint_origin(
					milestone,
					int(state.get("checkpoint_level", milestone))
				)
			))
			state["adjacent_slot_next_price"] = int(cycle_state.get("adjacent_slot_next_price", ADJACENT_BASE_PRICE))
			state["next_free_slot_unlock_level"] = GameRulesScript.first_future_free_slot_unlock_level(
				milestone,
				int(state.get("checkpoint_level", milestone))
			)
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

	# Compra en nivel 1, antes del primer hito gratis (nivel 2).
	state["active_stacks"] = int(state.get("active_stacks", 5)) + 1
	state["next_free_slot_unlock_level"] = GameRulesScript.next_free_slot_unlock_level(
		int(state.get("next_free_slot_unlock_level", 2))
	)

	state = _advance_checkpoint(state, 5, 5)
	if int(state.get("checkpoint_level", 0)) != 2:
		_fail("progress_to_level_2", str(state))
		return
	if int(state.get("active_stacks", 0)) != 6:
		_fail("purchase_consumes_level_2_free", str(state))
		return

	state = _advance_checkpoint(state, 6, 5) # 5 seises = nivel 4
	if int(state.get("checkpoint_level", 0)) != 4:
		_fail("progress_to_level_4", str(state))
		return
	if int(state.get("active_stacks", 0)) != 7:
		_fail("unlock_on_consumed_next_tier", str(state))
		return

	state = _advance_checkpoint(state, 15, 1, false) # reset de ciclo (crear 15, sin 6–14 residuales)
	if int(state.get("checkpoint_level", 0)) != 15:
		_fail("checkpoint_at_milestone", str(state))
		return
	if int(state.get("active_stacks", 0)) != CYCLE_RESET_STACKS:
		_fail("cycle_reset_stacks", str(state))
		return
	if int(state.get("roll_value_floor", 0)) != 11:
		_fail("cycle_reset_floor", str(state))
		return
	if int(state.get("max_value", 0)) != 15:
		_fail("cycle_reset_max", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 18:
		_fail("cycle_reset_unlock_cursor", str(state))
		return

	_ok("progression_purchase_and_cycle_reset")

func _test_first_cycle_levels_from_one_to_nine() -> void:
	# Desde el 1: sube con ≥5 en una pila, y otra vez al completar. Los 4 no cuentan.
	var state := {
		"checkpoint_level": 1,
		"current_level": 1,
		"max_value": 5,
		"roll_value_floor": 1,
		"active_stacks": 5,
		"adjacent_slot_next_price": ADJACENT_BASE_PRICE,
		"next_free_slot_unlock_level": GameRulesScript.initial_free_slot_unlock_level(0),
	}
	state = _advance_checkpoint(state, 4, 10)
	if int(state.get("checkpoint_level", 0)) != 1:
		_fail("fours_stay_level_1", str(state))
		return
	var steps: Array = [
		[5, 5, 2],
		[6, 1, 3],
		[6, 5, 4],
		[7, 1, 5],
		[7, 5, 6],
		[8, 1, 7],
		[8, 5, 8],
		[9, 1, 9],
	]
	for step in steps:
		var coin := int(step[0])
		var count := int(step[1])
		var expected := int(step[2])
		state = _advance_checkpoint(state, coin, count)
		if int(state.get("checkpoint_level", 0)) != expected:
			_fail("first_cycle_level_%d" % expected, str(state))
			return
	_ok("first_cycle_levels_from_one_to_nine")

func _test_cycle_reset_skips_stale_unlocks_when_checkpoint_ahead() -> void:
	# Mitad de 14 deja checkpoint 21 sin ficha 15; al crear la 15 el tablero
	# reinicia, pero el cursor no puede quedar en 18 (ya pasado).
	var state := {
		"checkpoint_level": 21,
		"current_level": 20,
		"max_value": 14,
		"roll_value_floor": 1,
		"active_stacks": 12,
		"adjacent_slot_next_price": ADJACENT_BASE_PRICE,
		"next_free_slot_unlock_level": 22,
	}

	state = _advance_checkpoint(state, 15, 1)
	if int(state.get("checkpoint_level", 0)) != 21:
		_fail("prestige_keeps_checkpoint_21", str(state))
		return
	if int(state.get("active_stacks", 0)) != CYCLE_RESET_STACKS:
		_fail("prestige_resets_stacks", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 22:
		_fail("prestige_unlock_cursor_skips_past", str(state))
		return
	if int(state.get("roll_value_floor", 0)) != 11:
		_fail("prestige_roll_floor_11", str(state))
		return
	if int(state.get("max_value", 0)) != 15:
		_fail("prestige_max_15", str(state))
		return
	if int(state.get("cycle_checkpoint_origin", 0)) != 20:
		_fail("prestige_origin_20", str(state))
		return

	# Crear 16 (completar 15s) = nivel 22. El 21 ya era el hold.
	state = _advance_checkpoint(state, 16, 1)
	if int(state.get("checkpoint_level", 0)) != 22:
		_fail("prestige_create_16_is_level_22", str(state))
		return

	# Crear 25 (como crear 15) reinicia otra vez: tiradas 21-24, objetivo 25.
	state = _advance_checkpoint(state, 25, 1)
	if int(state.get("checkpoint_level", 0)) != 40:
		_fail("prestige_create_25_keeps_level_40", str(state))
		return
	if int(state.get("roll_value_floor", 0)) != 21:
		_fail("prestige_25_roll_floor_21", str(state))
		return
	if int(state.get("max_value", 0)) != 25:
		_fail("prestige_25_max_25", str(state))
		return
	if int(state.get("active_stacks", 0)) != CYCLE_RESET_STACKS:
		_fail("prestige_25_resets_stacks", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 42:
		_fail("prestige_25_unlock_cursor", str(state.get("next_free_slot_unlock_level", 0)))
		return
	if int(state.get("cycle_checkpoint_origin", 0)) != 39:
		_fail("prestige_25_origin_39", str(state))
		return

	_ok("cycle_reset_skips_stale_unlocks_when_checkpoint_ahead")

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

	# Nivel 2: formar la 5 abre ranura.
	state = _advance_checkpoint(state, 5, 5)
	if int(state.get("checkpoint_level", 0)) != 2:
		_fail("immediate_unlock_level_2", str(state))
		return
	if int(state.get("active_stacks", 0)) != 6:
		_fail("immediate_unlock_slot_on_level_2", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 4:
		_fail("immediate_unlock_cursor_after_2", str(state))
		return

	# Nivel 3: mitad de pila (un 6) no abre ranura.
	state = _advance_checkpoint(state, 6, 1)
	if int(state.get("checkpoint_level", 0)) != 3:
		_fail("immediate_unlock_level_3", str(state))
		return
	if int(state.get("active_stacks", 0)) != 6:
		_fail("immediate_unlock_no_slot_on_level_3", str(state))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 4:
		_fail("immediate_unlock_cursor_stays_4", str(state))
		return

	# Nivel 4: pila completa abre ranura.
	state = _advance_checkpoint(state, 6, 5)
	if int(state.get("checkpoint_level", 0)) != 4:
		_fail("immediate_unlock_level_4", str(state))
		return
	if int(state.get("active_stacks", 0)) != 7:
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

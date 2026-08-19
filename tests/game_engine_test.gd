extends SceneTree

const GameEngineScript = preload("res://game_engine.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_engine test ===")
	_test_cycle_math()
	_test_checkpoint_eval()
	_test_legacy_cycle_heal()
	_test_descriptions()
	_test_cover_showcase()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_cycle_math() -> void:
	var c := GameEngineScript.cycle_index(1, 5, 15)
	if c != 0:
		_fail("cycle_index_0", str(c))
		return
	if GameEngineScript.cycle_base_level(10, 5, 15) != 15:
		_fail("cycle_base_15")
		return
	if GameEngineScript.cycle_base_level(11, 5, 15) != 15:
		_fail("cycle_base_15_from_11")
		return
	if GameEngineScript.cycle_reset_roll_value_floor(15, 5) != 11:
		_fail("reset_floor_15")
		return
	if GameEngineScript.cycle_reset_max_value(15) != 15:
		_fail("reset_max_15")
		return
	if GameEngineScript.cycle_checkpoint_origin(15, 15) != 15:
		_fail("origin_on_time")
		return
	if GameEngineScript.cycle_checkpoint_origin(15, 21) != 20:
		_fail("origin_ahead_21")
		return
	if GameEngineScript.cycle_reset_roll_value_floor(30, 5) != 26:
		_fail("reset_floor_30")
		return
	if GameEngineScript.reached_cycle_coin_milestone(14, 1, 5, 15) != 0:
		_fail("no_milestone_14")
		return
	if GameEngineScript.reached_cycle_coin_milestone(15, 1, 5, 15) != 15:
		_fail("milestone_15")
		return
	_ok("cycle_math")

func _test_checkpoint_eval() -> void:
	var lv2 := GameEngineScript.evaluate_checkpoint_level(5, 1, 1, 5, 5, 15)
	if lv2 != 2:
		_fail("create_5_is_level_2", str(lv2))
		return
	var lv3 := GameEngineScript.evaluate_checkpoint_level(5, 5, 1, 5, 5, 15)
	if lv3 != 3:
		_fail("half_stack_5_is_level_3", str(lv3))
		return
	var lv15 := GameEngineScript.evaluate_checkpoint_level(11, 6, 1, 5, 5, 15)
	if lv15 != 15:
		_fail("half_11_is_level_15", str(lv15))
		return
	# Prestige en 21: crear 16 (local 4) = nivel 23, cuando el 15 entra en la tirada.
	var origin21 := GameEngineScript.cycle_checkpoint_origin(15, 21)
	var lv_has15 := GameEngineScript.evaluate_checkpoint_level(15, 1, 11, 5, 5, 15, origin21)
	if lv_has15 != 21:
		_fail("prestige_21_has_15", str(lv_has15))
		return
	var lv_create16 := GameEngineScript.evaluate_checkpoint_level(16, 1, 11, 5, 5, 15, origin21)
	if lv_create16 != 23:
		_fail("prestige_21_create_16_is_23", str(lv_create16))
		return
	_ok("checkpoint_eval")

func _test_legacy_cycle_heal() -> void:
	if GameEngineScript.prestige_hold_checkpoint(15, 5) != 21:
		_fail("prestige_hold_21")
		return
	# Save inflado: prestigió en 21, el parche lo mandó a 23 sin crear el 16.
	var jumped := GameEngineScript.heal_legacy_cycle_progress({
		"milestone_level": 15,
		"checkpoint_level": 23,
		"current_level": 2,
		"max_value": 16,
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 22,
		"cycle_rules_revision": 1,
	}, 5)
	if int(jumped.get("checkpoint_level", 0)) != 21:
		_fail("heal_23_to_21", str(jumped))
		return
	if int(jumped.get("cycle_checkpoint_origin", 0)) != 20:
		_fail("heal_origin_20", str(jumped))
		return
	if int(jumped.get("max_value", 0)) != 15:
		_fail("heal_max_15", str(jumped))
		return
	if int(jumped.get("roll_value_floor", 0)) != 11:
		_fail("heal_floor_11", str(jumped))
		return
	if not bool(jumped.get("refill", false)):
		_fail("heal_refill", str(jumped))
		return
	if int(jumped.get("cycle_rules_revision", 0)) != GameEngineScript.CYCLE_RULES_REVISION:
		_fail("heal_revision", str(jumped))
		return
	# Tras curar, crear 16 sigue siendo nivel 23.
	var origin := int(jumped.get("cycle_checkpoint_origin", 0))
	var lv16 := GameEngineScript.evaluate_checkpoint_level(16, 1, 11, 5, 5, 15, origin)
	if lv16 != 23:
		_fail("heal_then_create_16_is_23", str(lv16))
		return
	# Ya curado: no volver a bajar un 23 legítimo.
	var stable := GameEngineScript.heal_legacy_cycle_progress({
		"milestone_level": 15,
		"checkpoint_level": 23,
		"current_level": 2,
		"max_value": 16,
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 20,
		"cycle_rules_revision": GameEngineScript.CYCLE_RULES_REVISION,
	}, 5)
	if bool(stable.get("changed", true)):
		_fail("heal_idempotent", str(stable))
		return
	if int(stable.get("checkpoint_level", 0)) != 23:
		_fail("heal_keeps_real_23", str(stable))
		return
	var display := GameEngineScript.healed_display_checkpoint(23, {
		"roll_value_floor": 11,
		"cycle_checkpoint_origin": 20,
		"cycle_rules_revision": 0,
		"max_value": 16,
		"checkpoint_level": 23,
	})
	if display != 21:
		_fail("heal_display_lobby", str(display))
		return
	_ok("legacy_cycle_heal")

func _test_descriptions() -> void:
	var d2 := GameEngineScript.checkpoint_level_description(2, 5, 15)
	if d2.find("5") < 0:
		_fail("desc_level_2", d2)
		return
	var d3 := GameEngineScript.checkpoint_level_description(3, 5, 15)
	if d3.find("mitad") < 0:
		_fail("desc_level_3", d3)
		return
	_ok("descriptions")

func _test_cover_showcase() -> void:
	# Arranque: objetivo 5, tablero 1-4.
	if GameEngineScript.cover_showcase_coin_value(5, 4) != 5:
		_fail("cover_start", str(GameEngineScript.cover_showcase_coin_value(5, 4)))
		return
	# Prestige: tablero 11-14, objetivo real 15; un max_value viejo=16 no debe verse.
	if GameEngineScript.cover_showcase_coin_value(16, 14) != 15:
		_fail("cover_prestige_stale_16", str(GameEngineScript.cover_showcase_coin_value(16, 14)))
		return
	if GameEngineScript.cover_showcase_coin_value(15, 14) != 15:
		_fail("cover_prestige_15", str(GameEngineScript.cover_showcase_coin_value(15, 14)))
		return
	# Ya creaste el 16.
	if GameEngineScript.cover_showcase_coin_value(16, 16) != 16:
		_fail("cover_has_16", str(GameEngineScript.cover_showcase_coin_value(16, 16)))
		return
	_ok("cover_showcase")

extends SceneTree

const Bot := preload("res://board_play_bot_service.gd")
const GameEngineScript = preload("res://game_engine.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== board_play_bot_service test ===")
	_test_prestige_35_opening_is_narrow()
	_test_bot_can_play_prestige_35()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_prestige_35_opening_is_narrow() -> void:
	var state: Dictionary = Bot.prestige_state(35, 41)
	if int(state.get("active_stacks", 0)) != 5:
		_fail("stacks_5", str(state))
		return
	if int(state.get("roll_value_floor", 0)) != 31:
		_fail("floor_31", str(state))
		return
	if Bot.play_level(state) != 1:
		_fail("play_level_1", str(Bot.play_level(state)))
		return
	if Bot.deal_max_value(state) != 32:
		_fail("opening_deal_31_32", str(Bot.deal_max_value(state)))
		return
	if int(state.get("next_free_slot_unlock_level", 0)) != 42:
		_fail("next_slot_42", str(state.get("next_free_slot_unlock_level", 0)))
		return
	_ok("prestige_35_opening_is_narrow")

func _test_bot_can_play_prestige_35() -> void:
	var state: Dictionary = Bot.prestige_state(35, 41)
	var report: Dictionary = Bot.run(state, 80, 7)
	if int(report.get("unique", 99)) > 4:
		_fail("too_many_values_on_five_slots", str(report))
		return
	if int(report.get("highest", 0)) < 31:
		_fail("no_coins", str(report))
		return
	_ok("bot_can_play_prestige_35")

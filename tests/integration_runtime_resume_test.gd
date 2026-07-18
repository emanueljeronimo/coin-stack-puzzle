extends SceneTree

const GameSessionServiceScript = preload("res://game_session_service.gd")
const GameRulesScript = preload("res://game_rules.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== integration_runtime_resume test ===")
	_test_runtime_snapshot_roundtrip()
	_test_temp_state_normalization_on_corruption()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_runtime_snapshot_roundtrip() -> void:
	var runtime := GameSessionServiceScript.build_runtime_snapshot({
		"current_level": 7,
		"checkpoint_level": 12,
		"max_value": 11,
		"roll_value_floor": 10,
		"active_stacks": 6,
		"has_active_temp_stack": true,
		"temp_slot_bonus_active": true,
		"temp_slot_time_remaining": 44.0,
		"temp_slot_actions_remaining": 2,
		"all_rows": [[10, 10], [11], [9], [8], [], [10], []],
	})
	var payload := GameSessionServiceScript.build_save_payload({
		"checkpoint_level": 12,
		"checkpoint_snapshot": {"foo": 1},
		"runtime_snapshot": runtime,
		"current_level": 7,
		"max_value": 11,
		"roll_value_floor": 10,
		"active_stacks": 6,
		"next_free_slot_unlock_level": 19,
		"temp_slot_actions_remaining": 2,
		"lives": 4,
		"gems": 80,
		"player_stars": 1200,
	})
	var parsed := GameSessionServiceScript.parse_save_payload(payload, {
		"checkpoint_level": 1,
		"checkpoint_snapshot": {},
		"runtime_snapshot": {},
		"current_level": 1,
		"max_value": 5,
		"roll_value_floor": 1,
		"active_stacks": 5,
		"next_free_slot_unlock_level": 4,
		"temp_slot_actions_remaining": 0,
		"lives": 5,
		"gems": 0,
		"player_stars": 0,
		"checkpoint_base_value": 5,
	})
	var rs: Dictionary = parsed.get("runtime_snapshot", {})
	if int(rs.get("checkpoint_level", 0)) != 12:
		_fail("runtime_roundtrip_checkpoint", str(rs))
		return
	var rows: Array = rs.get("stacks", [])
	if rows.size() != 7:
		_fail("runtime_roundtrip_rows", str(rows.size()))
		return
	if rows[0] != [10, 10] or rows[6] != []:
		_fail("runtime_roundtrip_content", str(rows))
		return
	_ok("runtime_snapshot_roundtrip")

func _test_temp_state_normalization_on_corruption() -> void:
	var ok := GameRulesScript.normalize_temp_state(true, 30.0, 7, 6)
	if not bool(ok.get("temp_slot_bonus_active", false)):
		_fail("normalize_valid_state", str(ok))
		return
	var corrupted := GameRulesScript.normalize_temp_state(true, 30.0, 6, 6)
	if bool(corrupted.get("temp_slot_bonus_active", true)):
		_fail("normalize_corrupted_state", str(corrupted))
		return
	_ok("temp_state_normalization_on_corruption")

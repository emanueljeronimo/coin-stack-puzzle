extends SceneTree

const GameSessionServiceScript = preload("res://game_session_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_session_service test ===")
	_test_runtime_snapshot_shape()
	_test_runtime_snapshot_padding()
	_test_parse_save_payload_fallbacks()
	_test_parse_save_payload_with_data()
	_test_level_up_alert_persistence()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_runtime_snapshot_shape() -> void:
	var snap := GameSessionServiceScript.build_runtime_snapshot({
		"current_level": 4,
		"checkpoint_level": 8,
		"active_stacks": 4,
		"has_active_temp_stack": true,
		"temp_slot_bonus_active": true,
		"temp_slot_time_remaining": 33.0,
		"all_rows": [[1], [2], [3], [4], [9]],
	})
	var rows: Array = snap.get("stacks", [])
	if rows.size() != 5:
		_fail("runtime_shape_rows", str(rows.size()))
		return
	if not bool(snap.get("temp_slot_bonus_active", false)):
		_fail("runtime_shape_temp_flag", str(snap))
		return
	_ok("runtime_snapshot_shape")

func _test_runtime_snapshot_padding() -> void:
	var snap := GameSessionServiceScript.build_runtime_snapshot({
		"active_stacks": 3,
		"has_active_temp_stack": false,
		"all_rows": [[1]],
	})
	var rows: Array = snap.get("stacks", [])
	if rows.size() != 3:
		_fail("runtime_padding_size", str(rows.size()))
		return
	if rows[1] != [] or rows[2] != []:
		_fail("runtime_padding_values", str(rows))
		return
	_ok("runtime_snapshot_padding")

func _test_parse_save_payload_fallbacks() -> void:
	var defaults := {
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
		"gems": 10,
		"player_stars": 999,
		"checkpoint_base_value": 5,
	}
	var parsed := GameSessionServiceScript.parse_save_payload({}, defaults)
	if int(parsed.get("max_value", 0)) != 5:
		_fail("parse_fallback_max_value", str(parsed))
		return
	_ok("parse_payload_fallbacks")

func _test_parse_save_payload_with_data() -> void:
	var defaults := {
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
		"gems": 10,
		"player_stars": 999,
		"checkpoint_base_value": 5,
	}
	var parsed := GameSessionServiceScript.parse_save_payload({
		"checkpoint_level": 9,
		"current_level": 4,
		"max_value": 11,
		"roll_value_floor": 10,
		"cycle_checkpoint_origin": 20,
		"cycle_rules_revision": 2,
		"active_stacks": 7,
		"next_free_slot_unlock_level": 12,
		"temp_slot_actions_remaining": -3,
		"coins": 1234,
		"lives": 2,
		"gems": 88,
		"runtime_snapshot": {"foo": 1},
	}, defaults)
	if int(parsed.get("temp_slot_actions_remaining", 1)) != 0:
		_fail("parse_temp_actions_clamped", str(parsed))
		return
	if int(parsed.get("player_stars", 0)) != 1234:
		_fail("parse_coins_alias", str(parsed))
		return
	if int(parsed.get("cycle_checkpoint_origin", 0)) != 20:
		_fail("parse_cycle_origin", str(parsed))
		return
	if int(parsed.get("cycle_rules_revision", 0)) != 2:
		_fail("parse_cycle_revision", str(parsed))
		return
	var rs: Dictionary = parsed.get("runtime_snapshot", {})
	if int(rs.get("foo", 0)) != 1:
		_fail("parse_runtime_snapshot", str(rs))
		return
	_ok("parse_payload_with_data")

func _test_level_up_alert_persistence() -> void:
	var snap := GameSessionServiceScript.build_runtime_snapshot({
		"checkpoint_level": 47,
		"active_stacks": 8,
		"pending_level_up_alerts": [47],
		"last_acknowledged_checkpoint_level": 46,
		"all_rows": [[1], [2], [3], [4], [5], [6], [7], [8]],
	})
	var pending: Array = snap.get("pending_level_up_alerts", [])
	if pending != [47]:
		_fail("runtime_keeps_pending_alerts", str(pending))
		return
	if int(snap.get("last_acknowledged_checkpoint_level", 0)) != 46:
		_fail("runtime_keeps_last_ack", str(snap.get("last_acknowledged_checkpoint_level", 0)))
		return
	if GameSessionServiceScript.migrated_last_acknowledged_checkpoint(false, 0, 47) != 47:
		_fail("old_save_acks_current", str(GameSessionServiceScript.migrated_last_acknowledged_checkpoint(false, 0, 47)))
		return
	if GameSessionServiceScript.migrated_last_acknowledged_checkpoint(true, 46, 47) != 46:
		_fail("new_save_keeps_ack", str(GameSessionServiceScript.migrated_last_acknowledged_checkpoint(true, 46, 47)))
		return
	var recovered := GameSessionServiceScript.queued_unacked_level_up_alerts([], 46, 47)
	if recovered != [47]:
		_fail("recover_popped_banner", str(recovered))
		return
	var merged := GameSessionServiceScript.queued_unacked_level_up_alerts([47], 45, 47)
	if merged != [46, 47]:
		_fail("fill_skipped_banner_gap", str(merged))
		return
	var none := GameSessionServiceScript.queued_unacked_level_up_alerts([47], 47, 47)
	if not none.is_empty():
		_fail("acked_banner_not_replayed", str(none))
		return
	_ok("level_up_alert_persistence")

extends SceneTree

const GameWildcardServiceScript = preload("res://game_wildcard_service.gd")
const GameSessionServiceScript = preload("res://game_session_service.gd")
const GameEngineScript = preload("res://game_engine.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== integration_undo_wildcard_checkpoint test ===")
	_test_undo_restores_wildcard_and_checkpoint_snapshot()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_undo_restores_wildcard_and_checkpoint_snapshot() -> void:
	var wildcard_counts := {"hammer": 1, "mix": 0, "glove": 0}
	var snapshot_before := GameSessionServiceScript.build_checkpoint_snapshot({
		"checkpoint_level": 6,
		"current_level": 6,
		"max_value": 10,
		"roll_value_floor": 1,
		"cycle_checkpoint_origin": 0,
		"cycle_rules_revision": 0,
		"active_stacks": 5,
		"next_free_slot_unlock_level": 9,
		"adjacent_slot_next_price": 3,
		"wildcard_counts": wildcard_counts,
		"wildcard_unlock_granted": {"hammer": true},
		"stacks": [[1, 1, 1, 1, 1]],
	})

	wildcard_counts = GameWildcardServiceScript.consume(wildcard_counts, "hammer")
	if int(wildcard_counts.get("hammer", -1)) != 0:
		_fail("consume_hammer")
		return

	var restored_wildcards: Dictionary = snapshot_before.get("wildcard_counts", {})
	if int(restored_wildcards.get("hammer", -1)) != 1:
		_fail("undo_wildcard_restore")
		return

	var level_desc := GameEngineScript.checkpoint_level_description(6, 5, 10, 0, 1)
	if level_desc.is_empty():
		_fail("checkpoint_description")
		return
	_ok("undo_wildcard_checkpoint_flow")

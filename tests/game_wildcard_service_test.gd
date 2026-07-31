extends SceneTree

## Regresión: comodines no deben aparecer/desaparecer al salir y volver.
## godot --headless --path . --script res://tests/game_wildcard_service_test.gd

const GameWildcardServiceScript = preload("res://game_wildcard_service.gd")
const GameSessionServiceScript = preload("res://game_session_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_wildcard_service test ===")
	_test_first_unlock_grants_initial_uses()
	_test_restore_does_not_regrant_when_granted()
	_test_restore_keeps_spent_counts()
	_test_locked_wildcards_stay_zero()
	_test_consume_and_add()
	_test_runtime_roundtrip_preserves_wildcards()
	_test_exit_reenter_does_not_refill_or_wipe()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_first_unlock_grants_initial_uses() -> void:
	var synced := GameWildcardServiceScript.sync_unlocks(
		5,
		{"mix": 0, "hammer": 0, "glove": 0},
		{"mix": false, "hammer": false, "glove": false},
		4
	)
	var counts: Dictionary = synced.get("wildcard_counts", {})
	if int(counts.get("mix", 0)) != GameWildcardServiceScript.INITIAL_USES:
		_fail("first_unlock_mix", str(counts))
		return
	if int(counts.get("hammer", -1)) != 0:
		_fail("first_unlock_hammer_locked", str(counts))
		return
	var newly: Array = synced.get("newly_unlocked", [])
	if newly.size() != 1 or str(newly[0]) != "mix":
		_fail("first_unlock_panel", str(newly))
		return
	_ok("first_unlock_grants_initial_uses")

func _test_restore_does_not_regrant_when_granted() -> void:
	# Usó todos los mix; al restaurar NO debe volver a 3.
	var synced := GameWildcardServiceScript.sync_unlocks(
		12,
		{"mix": 0, "hammer": 1, "glove": 0},
		{"mix": true, "hammer": true, "glove": false},
		-1
	)
	var counts: Dictionary = synced.get("wildcard_counts", {})
	if int(counts.get("mix", -1)) != 0:
		_fail("no_regrant_spent_mix", str(counts))
		return
	if int(counts.get("hammer", -1)) != 1:
		_fail("keep_hammer", str(counts))
		return
	# glove aún no granted y nivel >= 15? 12 < 15 → sigue 0
	if int(counts.get("glove", -1)) != 0:
		_fail("glove_still_locked", str(counts))
		return
	var newly: Array = synced.get("newly_unlocked", [])
	if not newly.is_empty():
		_fail("restore_no_panel", str(newly))
		return
	_ok("restore_does_not_regrant_when_granted")

func _test_restore_keeps_spent_counts() -> void:
	var synced := GameWildcardServiceScript.sync_unlocks(
		10,
		{"mix": 2, "hammer": 3, "glove": 0},
		{"mix": true, "hammer": true, "glove": false},
		-1
	)
	var counts: Dictionary = synced.get("wildcard_counts", {})
	if int(counts.get("mix", 0)) != 2 or int(counts.get("hammer", 0)) != 3:
		_fail("keep_spent", str(counts))
		return
	_ok("restore_keeps_spent_counts")

func _test_locked_wildcards_stay_zero() -> void:
	var synced := GameWildcardServiceScript.sync_unlocks(
		4,
		{"mix": 9, "hammer": 9, "glove": 9},
		{"mix": true, "hammer": true, "glove": true},
		-1
	)
	var counts: Dictionary = synced.get("wildcard_counts", {})
	for t in GameWildcardServiceScript.TYPES:
		if int(counts.get(t, -1)) != 0:
			_fail("locked_zero_" + str(t), str(counts))
			return
	_ok("locked_wildcards_stay_zero")

func _test_consume_and_add() -> void:
	var counts := {"mix": 3, "hammer": 1, "glove": 0}
	counts = GameWildcardServiceScript.consume(counts, "mix")
	if int(counts.get("mix", 0)) != 2:
		_fail("consume_mix", str(counts))
		return
	counts = GameWildcardServiceScript.add_uses(counts, "hammer", 1, 12)
	if int(counts.get("hammer", 0)) != 2:
		_fail("add_hammer", str(counts))
		return
	# No sumar si está bloqueado.
	counts = GameWildcardServiceScript.add_uses(counts, "glove", 5, 12)
	if int(counts.get("glove", 0)) != 0:
		_fail("add_locked_glove", str(counts))
		return
	_ok("consume_and_add")

func _test_runtime_roundtrip_preserves_wildcards() -> void:
	var runtime := GameSessionServiceScript.build_runtime_snapshot({
		"current_level": 7,
		"checkpoint_level": 12,
		"max_value": 11,
		"roll_value_floor": 1,
		"active_stacks": 6,
		"wildcard_counts": {"mix": 1, "hammer": 2, "glove": 0},
		"wildcard_unlock_granted": {"mix": true, "hammer": true, "glove": false},
		"all_rows": [[1], [2], [3], [4], [5], []],
	})
	if int((runtime.get("wildcard_counts", {}) as Dictionary).get("mix", 0)) != 1:
		_fail("runtime_has_mix", str(runtime.get("wildcard_counts", {})))
		return
	if not bool((runtime.get("wildcard_unlock_granted", {}) as Dictionary).get("hammer", false)):
		_fail("runtime_has_granted", str(runtime.get("wildcard_unlock_granted", {})))
		return
	var payload := GameSessionServiceScript.build_save_payload({
		"checkpoint_level": 12,
		"checkpoint_snapshot": {
			"wildcard_counts": {"mix": 3, "hammer": 3, "glove": 0},
			"wildcard_unlock_granted": {"mix": true, "hammer": true, "glove": false},
		},
		"runtime_snapshot": runtime,
		"current_level": 7,
		"max_value": 11,
		"roll_value_floor": 1,
		"active_stacks": 6,
		"next_free_slot_unlock_level": 14,
		"temp_slot_actions_remaining": 0,
		"lives": 5,
		"gems": 0,
		"player_stars": 100,
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
	var wc: Dictionary = rs.get("wildcard_counts", {})
	# Debe preferir el runtime (1), no el checkpoint stale (3).
	if int(wc.get("mix", 0)) != 1 or int(wc.get("hammer", 0)) != 2:
		_fail("roundtrip_runtime_counts", str(wc))
		return
	_ok("runtime_roundtrip_preserves_wildcards")

func _test_exit_reenter_does_not_refill_or_wipe() -> void:
	# Simula: tenía 3, usó 1 → quedó 2, granted true. Al “reentrar” se sync con -1.
	var after_use := {"mix": 2, "hammer": 0, "glove": 0}
	var granted := {"mix": true, "hammer": false, "glove": false}
	var reenter := GameWildcardServiceScript.sync_unlocks(8, after_use, granted, -1)
	var counts: Dictionary = reenter.get("wildcard_counts", {})
	if int(counts.get("mix", 0)) != 2:
		_fail("reenter_no_refill", str(counts))
		return
	# Bug viejo: si se perdían counts/granted al reentrar (defaults), sync regalaba 3.
	var wiped := GameWildcardServiceScript.sync_unlocks(
		8,
		{"mix": 0, "hammer": 0, "glove": 0},
		{"mix": false, "hammer": false, "glove": false},
		-1
	)
	# Sin flag granted, un restore “vacío” SÍ migra el primer unlock (esperado para saves viejos).
	# El fix de persistencia evita llegar a este estado si ya estaban granted.
	if int((wiped.get("wildcard_counts", {}) as Dictionary).get("mix", 0)) != GameWildcardServiceScript.INITIAL_USES:
		_fail("legacy_empty_migrates", str(wiped.get("wildcard_counts", {})))
		return
	# Con granted preservado y 0 usos: no rellenar.
	var spent := GameWildcardServiceScript.sync_unlocks(
		8,
		{"mix": 0, "hammer": 0, "glove": 0},
		{"mix": true, "hammer": false, "glove": false},
		-1
	)
	if int((spent.get("wildcard_counts", {}) as Dictionary).get("mix", -1)) != 0:
		_fail("spent_stays_zero", str(spent.get("wildcard_counts", {})))
		return
	_ok("exit_reenter_does_not_refill_or_wipe")

extends SceneTree

## Regresión: Boosters no deben aparecer/desaparecer al salir y volver.
## godot --headless --path . --script res://tests/game_wildcard_service_test.gd

const GameBoosterServiceScript = preload("res://game_booster_service.gd")
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
	_test_reads_legacy_save_keys()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_first_unlock_grants_initial_uses() -> void:
	if GameBoosterServiceScript.earliest_unlock_level() != 4:
		_fail("earliest_unlock", str(GameBoosterServiceScript.earliest_unlock_level()))
		return
	var synced := GameBoosterServiceScript.sync_unlocks(
		4,
		{"mix": 0, "hammer": 0, "glove": 0},
		{"mix": false, "hammer": false, "glove": false},
		3
	)
	var counts: Dictionary = synced.get("booster_counts", {})
	if int(counts.get("hammer", 0)) != GameBoosterServiceScript.INITIAL_USES:
		_fail("first_unlock_hammer", str(counts))
		return
	if int(counts.get("mix", -1)) != 0:
		_fail("first_unlock_mix_locked", str(counts))
		return
	var newly: Array = synced.get("newly_unlocked", [])
	if newly.size() != 1 or str(newly[0]) != "hammer":
		_fail("first_unlock_panel", str(newly))
		return
	_ok("first_unlock_grants_initial_uses")

func _test_restore_does_not_regrant_when_granted() -> void:
	# Usó todos los mix; al restaurar NO debe volver a 3.
	var synced := GameBoosterServiceScript.sync_unlocks(
		12,
		{"mix": 0, "hammer": 1, "glove": 0},
		{"mix": true, "hammer": true, "glove": false},
		-1
	)
	var counts: Dictionary = synced.get("booster_counts", {})
	if int(counts.get("mix", -1)) != 0:
		_fail("no_regrant_spent_mix", str(counts))
		return
	if int(counts.get("hammer", -1)) != 1:
		_fail("keep_hammer", str(counts))
		return
	# glove aun no granted y nivel >= 14? 12 < 14 → sigue 0
	if int(counts.get("glove", -1)) != 0:
		_fail("glove_still_locked", str(counts))
		return
	var newly: Array = synced.get("newly_unlocked", [])
	if not newly.is_empty():
		_fail("restore_no_panel", str(newly))
		return
	_ok("restore_does_not_regrant_when_granted")

func _test_restore_keeps_spent_counts() -> void:
	var synced := GameBoosterServiceScript.sync_unlocks(
		10,
		{"mix": 2, "hammer": 3, "glove": 0},
		{"mix": true, "hammer": true, "glove": false},
		-1
	)
	var counts: Dictionary = synced.get("booster_counts", {})
	if int(counts.get("mix", 0)) != 2 or int(counts.get("hammer", 0)) != 3:
		_fail("keep_spent", str(counts))
		return
	_ok("restore_keeps_spent_counts")

func _test_locked_wildcards_stay_zero() -> void:
	var synced := GameBoosterServiceScript.sync_unlocks(
		3,
		{"mix": 9, "hammer": 9, "glove": 9},
		{"mix": true, "hammer": true, "glove": true},
		-1
	)
	var counts: Dictionary = synced.get("booster_counts", {})
	for t in GameBoosterServiceScript.TYPES:
		if int(counts.get(t, -1)) != 0:
			_fail("locked_zero_" + str(t), str(counts))
			return
	_ok("locked_wildcards_stay_zero")

func _test_consume_and_add() -> void:
	var counts := {"mix": 3, "hammer": 1, "glove": 0}
	counts = GameBoosterServiceScript.consume(counts, "mix")
	if int(counts.get("mix", 0)) != 2:
		_fail("consume_mix", str(counts))
		return
	counts = GameBoosterServiceScript.add_uses(counts, "hammer", 1, 12)
	if int(counts.get("hammer", 0)) != 2:
		_fail("add_hammer", str(counts))
		return
	# No sumar si está bloqueado.
	counts = GameBoosterServiceScript.add_uses(counts, "glove", 5, 12)
	if int(counts.get("glove", 0)) != 0:
		_fail("add_locked_glove", str(counts))
		return
	counts = GameBoosterServiceScript.add_uses(
		counts, "glove", 3, 12, GameBoosterServiceScript.UNLOCK_LEVEL, false
	)
	if int(counts.get("glove", 0)) != 3:
		_fail("add_shop_glove", str(counts))
		return
	_ok("consume_and_add")

func _test_runtime_roundtrip_preserves_wildcards() -> void:
	var runtime := GameSessionServiceScript.build_runtime_snapshot({
		"current_level": 7,
		"checkpoint_level": 12,
		"max_value": 11,
		"roll_value_floor": 1,
		"active_stacks": 6,
		"booster_counts": {"mix": 1, "hammer": 2, "glove": 0},
		"booster_unlock_granted": {"mix": true, "hammer": true, "glove": false},
		"all_rows": [[1], [2], [3], [4], [5], []],
	})
	if int((runtime.get("booster_counts", {}) as Dictionary).get("mix", 0)) != 1:
		_fail("runtime_has_mix", str(runtime.get("booster_counts", {})))
		return
	if not bool((runtime.get("booster_unlock_granted", {}) as Dictionary).get("hammer", false)):
		_fail("runtime_has_granted", str(runtime.get("booster_unlock_granted", {})))
		return
	var payload := GameSessionServiceScript.build_save_payload({
		"checkpoint_level": 12,
		"checkpoint_snapshot": {
			"booster_counts": {"mix": 3, "hammer": 3, "glove": 0},
			"booster_unlock_granted": {"mix": true, "hammer": true, "glove": false},
		},
		"runtime_snapshot": runtime,
		"current_level": 7,
		"max_value": 11,
		"roll_value_floor": 1,
		"active_stacks": 6,
		"next_free_slot_unlock_level": 14,
		"temp_slot_actions_remaining": 0,
		"lives": 5,
		"player_diamonds": 100,
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
		"player_diamonds": 0,
		"checkpoint_base_value": 5,
	})
	var rs: Dictionary = parsed.get("runtime_snapshot", {})
	var wc: Dictionary = rs.get("booster_counts", {})
	# Debe preferir el runtime (1), no el checkpoint stale (3).
	if int(wc.get("mix", 0)) != 1 or int(wc.get("hammer", 0)) != 2:
		_fail("roundtrip_runtime_counts", str(wc))
		return
	_ok("runtime_roundtrip_preserves_wildcards")

func _test_exit_reenter_does_not_refill_or_wipe() -> void:
	# Simula: tenia 3, uso 1 → quedo 2, granted true. Al "reentrar" se sync con -1.
	var after_use := {"mix": 0, "hammer": 2, "glove": 0}
	var granted := {"mix": false, "hammer": true, "glove": false}
	var reenter := GameBoosterServiceScript.sync_unlocks(8, after_use, granted, -1)
	var counts: Dictionary = reenter.get("booster_counts", {})
	if int(counts.get("hammer", 0)) != 2:
		_fail("reenter_no_refill", str(counts))
		return
	# Bug viejo: si se perdian counts/granted al reentrar (defaults), sync regalaba 3.
	var wiped := GameBoosterServiceScript.sync_unlocks(
		8,
		{"mix": 0, "hammer": 0, "glove": 0},
		{"mix": false, "hammer": false, "glove": false},
		-1
	)
	# Sin flag granted, un restore "vacio" SI migra el primer unlock (esperado para saves viejos).
	# El fix de persistencia evita llegar a este estado si ya estaban granted.
	if int((wiped.get("booster_counts", {}) as Dictionary).get("hammer", 0)) != GameBoosterServiceScript.INITIAL_USES:
		_fail("legacy_empty_migrates", str(wiped.get("booster_counts", {})))
		return
	# Con granted preservado y 0 usos: no rellenar.
	var spent := GameBoosterServiceScript.sync_unlocks(
		8,
		{"mix": 0, "hammer": 0, "glove": 0},
		{"mix": false, "hammer": true, "glove": false},
		-1
	)
	if int((spent.get("booster_counts", {}) as Dictionary).get("hammer", -1)) != 0:
		_fail("spent_stays_zero", str(spent.get("booster_counts", {})))
		return
	_ok("exit_reenter_does_not_refill_or_wipe")

func _test_reads_legacy_save_keys() -> void:
	var legacy := {
		"wildcard_counts": {"mix": 1, "hammer": 2, "glove": 0},
		"wildcard_unlock_granted": {"mix": true, "hammer": true, "glove": false},
	}
	var counts: Dictionary = GameBoosterServiceScript.read_counts(legacy)
	var granted: Dictionary = GameBoosterServiceScript.read_granted(legacy)
	if int(counts.get("hammer", 0)) != 2 or not bool(granted.get("mix", false)):
		_fail("legacy_read", str(counts) + str(granted))
		return
	var out := {}
	GameBoosterServiceScript.write_state(out, counts, granted)
	if not out.has("booster_counts") or out.has("wildcard_counts"):
		_fail("legacy_write", str(out))
		return
	_ok("reads_legacy_save_keys")

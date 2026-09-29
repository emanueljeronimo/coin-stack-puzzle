extends SceneTree

const MainSessionAdapterScript = preload("res://main_session_adapter.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== main_session_adapter test ===")
	_test_zero_arg_collector()
	_test_payload_collector()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _zero_arg_save() -> Dictionary:
	return {"checkpoint_level": 7, "player_stars": 42}

func _payload_save(payload: Dictionary) -> Dictionary:
	var out := payload.duplicate(true)
	out["from_payload"] = true
	return out

func _test_zero_arg_collector() -> void:
	var out := MainSessionAdapterScript.build_save_payload(Callable(self, "_zero_arg_save"), {})
	if int(out.get("checkpoint_level", 0)) != 7:
		_fail("zero_arg_collector", str(out))
		return
	_ok("zero_arg_collector")

func _test_payload_collector() -> void:
	var out := MainSessionAdapterScript.build_save_payload(Callable(self, "_payload_save"), {"keep": 1})
	if not bool(out.get("from_payload", false)) or int(out.get("keep", 0)) != 1:
		_fail("payload_collector", str(out))
		return
	_ok("payload_collector")

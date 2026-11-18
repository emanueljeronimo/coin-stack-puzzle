extends SceneTree

const Service := preload("res://play_days_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== play_days_service test ===")
	_test_first_day()
	_test_same_day()
	_test_next_day()
	_test_empty_today()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_first_day() -> void:
	var out: Dictionary = Service.tick("", 0, "2026-11-16")
	if str(out.get("day", "")) != "2026-11-16" or int(out.get("count", 0)) != 1:
		_fail("first_day", str(out))
		return
	_ok("first_day")

func _test_same_day() -> void:
	var out: Dictionary = Service.tick("2026-11-16", 2, "2026-11-16")
	if str(out.get("day", "")) != "2026-11-16" or int(out.get("count", 0)) != 2:
		_fail("same_day", str(out))
		return
	_ok("same_day")

func _test_next_day() -> void:
	var out: Dictionary = Service.tick("2026-11-16", 2, "2026-11-17")
	if str(out.get("day", "")) != "2026-11-17" or int(out.get("count", 0)) != 3:
		_fail("next_day", str(out))
		return
	_ok("next_day")

func _test_empty_today() -> void:
	var out: Dictionary = Service.tick("2026-11-16", 4, "")
	if str(out.get("day", "")) != "2026-11-16" or int(out.get("count", 0)) != 4:
		_fail("empty_today", str(out))
		return
	_ok("empty_today")

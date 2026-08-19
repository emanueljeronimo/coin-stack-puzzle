extends SceneTree

## godot --headless --path . --script res://tests/game_lives_service_test.gd

const GameLivesServiceScript = preload("res://game_lives_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== game_lives_service test ===")
	_test_catch_up_fills_to_max()
	_test_catch_up_keeps_remainder()
	_test_spend_starts_timer()
	_test_spend_keeps_running_timer()
	_test_grant_to_max_clears_timer()
	_test_chip_format()
	_test_migrate_old_save()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_catch_up_fills_to_max() -> void:
	var now := 2_000_000
	var next := now - (2 * 60 * 60)
	var out := GameLivesServiceScript.catch_up(3, next, now)
	if int(out.get("lives", 0)) != 5:
		_fail("catch_up_fills_to_max", str(out))
		return
	if int(out.get("next_unix", -1)) != 0:
		_fail("catch_up_fills_clears_timer", str(out))
		return
	_ok("catch_up_fills_to_max")

func _test_catch_up_keeps_remainder() -> void:
	var now := 10_000
	var next := now - 10
	var out := GameLivesServiceScript.catch_up(3, next, now)
	if int(out.get("lives", 0)) != 4:
		_fail("catch_up_one_life", str(out))
		return
	if int(out.get("next_unix", 0)) != next + GameLivesServiceScript.REGEN_SECONDS:
		_fail("catch_up_remainder", str(out))
		return
	_ok("catch_up_keeps_remainder")

func _test_spend_starts_timer() -> void:
	var now := 50_000
	var out := GameLivesServiceScript.on_spend(5, 0, now)
	if not bool(out.get("ok", false)) or int(out.get("lives", -1)) != 4:
		_fail("spend_from_full", str(out))
		return
	if int(out.get("next_unix", 0)) != now + GameLivesServiceScript.REGEN_SECONDS:
		_fail("spend_starts_timer", str(out))
		return
	_ok("spend_starts_timer")

func _test_spend_keeps_running_timer() -> void:
	var now := 50_000
	var next := now + 600
	var out := GameLivesServiceScript.on_spend(4, next, now)
	if int(out.get("lives", -1)) != 3 or int(out.get("next_unix", 0)) != next:
		_fail("spend_keeps_timer", str(out))
		return
	_ok("spend_keeps_running_timer")

func _test_grant_to_max_clears_timer() -> void:
	var now := 80_000
	var next := now + 100
	var out := GameLivesServiceScript.on_grant(3, 5, next, now)
	if int(out.get("lives", 0)) != 5 or int(out.get("next_unix", -1)) != 0:
		_fail("grant_to_max", str(out))
		return
	var ad := GameLivesServiceScript.on_grant(3, 1, next, now)
	if int(ad.get("lives", 0)) != 4 or int(ad.get("next_unix", 0)) != next:
		_fail("grant_one_keeps_timer", str(ad))
		return
	_ok("grant_to_max_clears_timer")

func _test_chip_format() -> void:
	if GameLivesServiceScript.format_chip_text(5, 0) != "full":
		_fail("chip_full", GameLivesServiceScript.format_chip_text(5, 0))
		return
	if GameLivesServiceScript.format_chip_text(3, 1787) != "29:47":
		_fail("chip_countdown", GameLivesServiceScript.format_chip_text(3, 1787))
		return
	_ok("chip_format")

func _test_migrate_old_save() -> void:
	var now := 1_000_000
	var mtime := now - (2 * 24 * 60 * 60)
	var out := GameLivesServiceScript.migrate_missing_timer(3, now, mtime)
	if int(out.get("lives", 0)) != 5 or int(out.get("next_unix", -1)) != 0:
		_fail("migrate_two_days", str(out))
		return
	_ok("migrate_old_save")

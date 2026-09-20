extends SceneTree

const HudActionRowLayoutServiceScript = preload("res://hud_action_row_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== hud_action_row_layout_service test ===")
	_test_compute_action_row()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_compute_action_row() -> void:
	var out := HudActionRowLayoutServiceScript.compute_action_row(Vector2(100, 200), 60.0, 48.0, 12.0, 360.0)
	if not out.has("action_y") or not out.has("actions_start_x"):
		_fail("keys")
		return
	if float(out.get("action_y", 0.0)) <= 200.0:
		_fail("action_y")
		return
	_ok("compute_action_row")

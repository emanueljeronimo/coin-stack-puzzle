extends SceneTree

const HudTopbarLayoutServiceScript = preload("res://hud_topbar_layout_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== hud_topbar_layout_service test ===")
	_test_lobby_matched_metrics_at_ref_width()
	_test_chip_row_y_clears_progress()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_lobby_matched_metrics_at_ref_width() -> void:
	var out := HudTopbarLayoutServiceScript.lobby_matched_metrics(1080.0, 14.0, 26.0)
	var corner_w := float(out.get("corner_w", 0.0))
	var chip_h := float(out.get("chip_h", 0.0))
	var stat_w := float(out.get("stat_w", 0.0))
	if absf(corner_w - 129.6) > 0.05:
		_fail("corner_w", str(corner_w))
		return
	if absf(chip_h - 98.496) > 0.05:
		_fail("chip_h", str(chip_h))
		return
	if absf(stat_w - 205.2) > 0.05:
		_fail("stat_w", str(stat_w))
		return
	if chip_h <= 50.0 or stat_w <= 136.0:
		_fail("larger_than_old_board_hud", "h=%s w=%s" % [chip_h, stat_w])
		return
	_ok("lobby_matched_metrics_at_ref_width")

func _test_chip_row_y_clears_progress() -> void:
	var chip_h := 98.496
	var progress_h := 54.0
	var gap := 26.0
	var board_gap := 12.0
	var y := HudTopbarLayoutServiceScript.chip_row_y(12.0, 311.0, chip_h, progress_h, gap, board_gap)
	var progress_bottom := y + chip_h + gap + progress_h
	if progress_bottom > 311.0 - board_gap + 0.01:
		_fail("overlap_board", str(progress_bottom))
		return
	if y < 12.0:
		_fail("below_min", str(y))
		return
	_ok("chip_row_y_clears_progress")

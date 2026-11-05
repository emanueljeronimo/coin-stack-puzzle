extends SceneTree

const Service := preload("res://board_music_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== board_music_service test ===")
	_test_paths()
	_test_cycle()
	_test_enabled()
	_test_labels()
	_test_resolve_legacy()
	_test_normalize_unknown()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_paths() -> void:
	if not str(Service.path_for(Service.TRACK_1)).ends_with("musica tablero.mp3"):
		_fail("track1_path", Service.path_for(Service.TRACK_1))
		return
	if not str(Service.path_for(Service.TRACK_2)).ends_with("musica-tablero2.mp3"):
		_fail("track2_path", Service.path_for(Service.TRACK_2))
		return
	if not Service.path_for(Service.TRACK_OFF).is_empty():
		_fail("off_has_no_path", Service.path_for(Service.TRACK_OFF))
		return
	_ok("paths")

func _test_cycle() -> void:
	if Service.next_track(Service.TRACK_1) != Service.TRACK_2:
		_fail("one_to_two", Service.next_track(Service.TRACK_1))
		return
	if Service.next_track(Service.TRACK_2) != Service.TRACK_OFF:
		_fail("two_to_off", Service.next_track(Service.TRACK_2))
		return
	if Service.next_track(Service.TRACK_OFF) != Service.TRACK_1:
		_fail("off_to_one", Service.next_track(Service.TRACK_OFF))
		return
	_ok("cycle")

func _test_enabled() -> void:
	if not Service.is_enabled(Service.TRACK_1):
		_fail("track1_enabled")
		return
	if not Service.is_enabled(Service.TRACK_2):
		_fail("track2_enabled")
		return
	if Service.is_enabled(Service.TRACK_OFF):
		_fail("off_disabled")
		return
	_ok("enabled")

func _test_labels() -> void:
	if Service.button_label(Service.TRACK_1) != "Chill":
		_fail("label1", Service.button_label(Service.TRACK_1))
		return
	if Service.button_label(Service.TRACK_2) != "Forest":
		_fail("label2", Service.button_label(Service.TRACK_2))
		return
	if Service.button_label(Service.TRACK_OFF) != "OFF":
		_fail("label_off", Service.button_label(Service.TRACK_OFF))
		return
	_ok("labels")

func _test_resolve_legacy() -> void:
	if Service.resolve_track("", true) != Service.TRACK_1:
		_fail("legacy_on", Service.resolve_track("", true))
		return
	if Service.resolve_track("", false) != Service.TRACK_OFF:
		_fail("legacy_off", Service.resolve_track("", false))
		return
	if Service.resolve_track(Service.TRACK_2, false) != Service.TRACK_2:
		_fail("saved_track_wins", Service.resolve_track(Service.TRACK_2, false))
		return
	_ok("resolve_legacy")

func _test_normalize_unknown() -> void:
	if Service.normalize("xyz") != Service.TRACK_1:
		_fail("unknown_falls_back", Service.normalize("xyz"))
		return
	_ok("normalize_unknown")

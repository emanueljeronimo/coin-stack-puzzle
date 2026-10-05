extends SceneTree

const UiSfxServiceScript = preload("res://ui_sfx_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== ui_sfx_service test ===")
	_test_button_path()
	_test_should_play_button()
	_test_oneshot_null_is_safe()
	_test_coin_sfx_pitch()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_button_path() -> void:
	if not str(UiSfxServiceScript.BUTTON_SFX_PATH).ends_with("sonido-boton.mp3"):
		_fail("button_path", UiSfxServiceScript.BUTTON_SFX_PATH)
		return
	_ok("button_path")

func _test_should_play_button() -> void:
	if not UiSfxServiceScript.should_play_button(true, true):
		_fail("play_when_enabled")
		return
	if UiSfxServiceScript.should_play_button(false, true):
		_fail("muted_skips")
		return
	if UiSfxServiceScript.should_play_button(true, false):
		_fail("missing_player_skips")
		return
	_ok("should_play_button")

func _test_oneshot_null_is_safe() -> void:
	UiSfxServiceScript.apply_oneshot_stream(null)
	_ok("oneshot_null_is_safe")

func _test_coin_sfx_pitch() -> void:
	if not str(UiSfxServiceScript.COIN_SFX_PATH).ends_with("sonido-ficha-2.mp3"):
		_fail("coin_path", UiSfxServiceScript.COIN_SFX_PATH)
		return
	if not is_equal_approx(UiSfxServiceScript.coin_sfx_pitch(1), 1.0):
		_fail("one_coin_normal", str(UiSfxServiceScript.coin_sfx_pitch(1)))
		return
	if UiSfxServiceScript.coin_sfx_pitch(5) >= UiSfxServiceScript.coin_sfx_pitch(1):
		_fail("more_coins_lower_pitch", str(UiSfxServiceScript.coin_sfx_pitch(5)))
		return
	if UiSfxServiceScript.coin_sfx_pitch(10) > UiSfxServiceScript.coin_sfx_pitch(5):
		_fail("ten_not_higher_than_five", str(UiSfxServiceScript.coin_sfx_pitch(10)))
		return
	if UiSfxServiceScript.coin_sfx_pitch(10) < UiSfxServiceScript.COIN_PITCH_MIN - 0.001:
		_fail("pitch_floor", str(UiSfxServiceScript.coin_sfx_pitch(10)))
		return
	if UiSfxServiceScript.coin_sfx_pitch(0) != 1.0:
		_fail("zero_counts_as_one", str(UiSfxServiceScript.coin_sfx_pitch(0)))
		return
	_ok("coin_sfx_pitch")


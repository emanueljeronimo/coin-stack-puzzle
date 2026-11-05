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
	_test_card_flicks_get_longer()
	_test_solitaire_paths()
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

func _test_card_flicks_get_longer() -> void:
	if UiSfxServiceScript.card_flick_count(1) != 1:
		_fail("one_card", str(UiSfxServiceScript.card_flick_count(1)))
		return
	if UiSfxServiceScript.card_flick_count(5) != 5:
		_fail("five_cards", str(UiSfxServiceScript.card_flick_count(5)))
		return
	if UiSfxServiceScript.card_flick_count(0) != 1:
		_fail("zero_counts_as_one", str(UiSfxServiceScript.card_flick_count(0)))
		return
	if UiSfxServiceScript.card_flick_count(20) != UiSfxServiceScript.CARD_FLICK_MAX:
		_fail("cap", str(UiSfxServiceScript.card_flick_count(20)))
		return
	if UiSfxServiceScript.card_flick_delay(3) <= UiSfxServiceScript.card_flick_delay(1):
		_fail("later_flick_is_later")
		return
	_ok("card_flicks_get_longer")

func _test_solitaire_paths() -> void:
	if not str(UiSfxServiceScript.COIN_SELECT_SFX_PATH).ends_with("sonido-giro.wav"):
		_fail("select_path", UiSfxServiceScript.COIN_SELECT_SFX_PATH)
		return
	if not str(UiSfxServiceScript.COIN_PLACE_SFX_PATH).ends_with("sonido-colocar.wav"):
		_fail("place_path", UiSfxServiceScript.COIN_PLACE_SFX_PATH)
		return
	if UiSfxServiceScript.COIN_SELECT_SFX_PATH == UiSfxServiceScript.COIN_PLACE_SFX_PATH:
		_fail("select_and_place_are_same")
		return
	if not str(UiSfxServiceScript.FUSION_SFX_PATH).ends_with("sonido-clin.wav"):
		_fail("clin_path", UiSfxServiceScript.FUSION_SFX_PATH)
		return
	if not str(UiSfxServiceScript.LEVEL_UP_SFX_PATH).ends_with("subir-nivel.mp3"):
		_fail("level_path", UiSfxServiceScript.LEVEL_UP_SFX_PATH)
		return
	_ok("solitaire_paths")

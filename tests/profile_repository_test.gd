extends SceneTree

const ProfileRepositoryScript = preload("res://profile_repository.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== profile_repository test ===")
	_test_username_sanitize()
	_test_lookup_defaults()
	_test_default_player_data()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" — " + detail) if not detail.is_empty() else "")

func _test_username_sanitize() -> void:
	var sanitized := ProfileRepositoryScript.sanitize_username("  NombreLarguisimoParaCortar  ", 10)
	if sanitized != "NombreLarg":
		_fail("username_trim_cut", sanitized)
		return
	_ok("username_sanitize")

func _test_lookup_defaults() -> void:
	if ProfileRepositoryScript.default_avatar_id().is_empty():
		_fail("default_avatar_id")
		return
	if ProfileRepositoryScript.avatar_path_for_id("inexistente") != "":
		_fail("unknown_avatar_returns_empty")
		return
	if not (ProfileRepositoryScript.border_color_for_id(ProfileRepositoryScript.default_border_color_id()) is Color):
		_fail("default_border_color")
		return
	_ok("lookup_defaults")

func _test_default_player_data() -> void:
	var data := ProfileRepositoryScript.default_player_data(7, "Player", Color(0.1, 0.2, 0.3), 99, 5, 4)
	if int(data.get("save_version", 0)) != 7:
		_fail("save_version", str(data))
		return
	if int(data.get("coins", 0)) != 99:
		_fail("coins", str(data))
		return
	_ok("default_player_data")

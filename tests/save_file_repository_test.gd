extends SceneTree

const SaveFileRepositoryScript = preload("res://save_file_repository.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== save_file_repository test ===")
	_test_read_write_cycle()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_read_write_cycle() -> void:
	var path := "user://save_file_repository_test.json"
	var payload := {"a": 1, "nested": {"b": true}}
	if not SaveFileRepositoryScript.write_json_dict(path, payload):
		_fail("write_json_dict")
		return
	if not SaveFileRepositoryScript.has_file(path):
		_fail("has_file")
		return
	var loaded := SaveFileRepositoryScript.read_json_dict(path)
	if int(loaded.get("a", -1)) != 1:
		_fail("read_json_dict_scalar")
		return
	var nested: Dictionary = loaded.get("nested", {})
	if not bool(nested.get("b", false)):
		_fail("read_json_dict_nested")
		return
	_ok("read_write_cycle")

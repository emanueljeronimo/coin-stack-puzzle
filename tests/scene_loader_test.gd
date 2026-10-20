extends SceneTree

const SceneLoaderScript := preload("res://scene_loader.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== scene_loader test ===")
	_test_boot_defaults_to_lobby()
	_test_pending_scene_is_not_boot()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_boot_defaults_to_lobby() -> void:
	var loader: Node = SceneLoaderScript.new()
	if not loader.consume_is_boot():
		_fail("boot_flag")
		loader.free()
		return
	var path: String = loader.consume_pending_scene()
	if path != "res://Lobby.tscn":
		_fail("boot_path", path)
		loader.free()
		return
	_ok("boot_defaults_to_lobby")
	loader.free()

func _test_pending_scene_is_not_boot() -> void:
	var loader: Node = SceneLoaderScript.new()
	loader.pending_scene_path = "res://Main.tscn"
	loader.pending_message = "Cargando"
	if loader.consume_is_boot():
		_fail("pending_not_boot")
		loader.free()
		return
	var path: String = loader.consume_pending_scene()
	if path != "res://Main.tscn":
		_fail("pending_path", path)
		loader.free()
		return
	_ok("pending_scene_is_not_boot")
	loader.free()

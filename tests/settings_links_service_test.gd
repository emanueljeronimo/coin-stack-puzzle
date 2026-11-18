extends SceneTree

const Service := preload("res://settings_links_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== settings_links_service test ===")
	_test_configured()
	_test_messages()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_configured() -> void:
	if Service.is_configured(""):
		_fail("empty_url", "empty should not be configured")
		return
	if Service.is_configured("   "):
		_fail("blank_url", "blank should not be configured")
		return
	if not Service.is_configured("https://example.com"):
		_fail("https_url", "https should be configured")
		return
	if Service.is_configured(Service.CONTACT_URL):
		_fail("contact_placeholder", Service.CONTACT_URL)
		return
	if Service.is_configured(Service.TERMS_URL):
		_fail("terms_placeholder", Service.TERMS_URL)
		return
	if Service.is_configured(Service.PRIVACY_URL):
		_fail("privacy_placeholder", Service.PRIVACY_URL)
		return
	_ok("configured")

func _test_messages() -> void:
	if Service.restore_purchases_message().strip_edges().is_empty():
		_fail("restore_message")
		return
	if Service.missing_link_message().strip_edges().is_empty():
		_fail("missing_link_message")
		return
	_ok("messages")

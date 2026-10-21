extends SceneTree

const ShopTabServiceScript = preload("res://shop_tab_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== shop_tab_service test ===")
	_test_titles()
	_test_clamp_index()
	_test_page_visible()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_titles() -> void:
	var titles: PackedStringArray = ShopTabServiceScript.titles()
	if titles.size() != ShopTabServiceScript.TAB_COUNT:
		_fail("title_count", str(titles.size()))
		return
	if titles[ShopTabServiceScript.TAB_DIAMONDS] != "Diamantes":
		_fail("title_diamonds", titles[ShopTabServiceScript.TAB_DIAMONDS])
		return
	if titles[ShopTabServiceScript.TAB_RESOURCES] != "Recursos":
		_fail("title_resources", titles[ShopTabServiceScript.TAB_RESOURCES])
		return
	if titles[ShopTabServiceScript.TAB_COMBOS] != "Combos":
		_fail("title_combos", titles[ShopTabServiceScript.TAB_COMBOS])
		return
	_ok("titles")

func _test_clamp_index() -> void:
	if ShopTabServiceScript.clamp_index(-2) != 0:
		_fail("clamp_low", str(ShopTabServiceScript.clamp_index(-2)))
		return
	if ShopTabServiceScript.clamp_index(9) != 2:
		_fail("clamp_high", str(ShopTabServiceScript.clamp_index(9)))
		return
	if ShopTabServiceScript.clamp_index(1) != 1:
		_fail("clamp_mid", str(ShopTabServiceScript.clamp_index(1)))
		return
	_ok("clamp_index")

func _test_page_visible() -> void:
	if not ShopTabServiceScript.is_page_visible(0, 0):
		_fail("diamonds_page")
		return
	if ShopTabServiceScript.is_page_visible(0, 1):
		_fail("diamonds_hides_resources")
		return
	if not ShopTabServiceScript.is_page_visible(2, 2):
		_fail("combos_page")
		return
	_ok("page_visible")

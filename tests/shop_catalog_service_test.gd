extends SceneTree

const ShopCatalogServiceScript = preload("res://shop_catalog_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== shop_catalog_service test ===")
	_test_star_packs()
	_test_formatters()
	_test_confirm_copy()
	_test_combo_pack()
	_test_resource_wildcards()
	_test_grant_stars()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_star_packs() -> void:
	var packs: Array = ShopCatalogServiceScript.star_packs()
	if packs.size() != 5:
		_fail("pack_count", str(packs.size()))
		return
	var fav := ShopCatalogServiceScript.pack_by_id("stars_2500")
	if fav.is_empty() or int(fav.get("amount", 0)) != 2500 or not bool(fav.get("favorite", false)):
		_fail("favorite_pack", str(fav))
		return
	if not ShopCatalogServiceScript.pack_by_id("missing").is_empty():
		_fail("unknown_pack")
		return
	_ok("star_packs")

func _test_formatters() -> void:
	if ShopCatalogServiceScript.format_amount(500) != "500":
		_fail("amount_500", ShopCatalogServiceScript.format_amount(500))
		return
	if ShopCatalogServiceScript.format_amount(1200) != "1.200":
		_fail("amount_1200", ShopCatalogServiceScript.format_amount(1200))
		return
	if ShopCatalogServiceScript.format_amount(15000) != "15.000":
		_fail("amount_15000", ShopCatalogServiceScript.format_amount(15000))
		return
	if ShopCatalogServiceScript.format_price_usd(99) != "$0.99":
		_fail("price_99", ShopCatalogServiceScript.format_price_usd(99))
		return
	if ShopCatalogServiceScript.format_price_usd(1499) != "$14.99":
		_fail("price_1499", ShopCatalogServiceScript.format_price_usd(1499))
		return
	_ok("formatters")

func _test_confirm_copy() -> void:
	var copy_2500: String = ShopCatalogServiceScript.confirm_copy(2500, 399)
	if copy_2500 != "¿Comprar 2.500 por $3.99?":
		_fail("confirm_2500", copy_2500)
		return
	var copy_500: String = ShopCatalogServiceScript.confirm_copy(500, 99)
	if copy_500 != "¿Comprar 500 por $0.99?":
		_fail("confirm_500", copy_500)
		return
	_ok("confirm_copy")

func _test_combo_pack() -> void:
	var packs: Array = ShopCatalogServiceScript.combo_packs()
	if packs.size() != 1:
		_fail("combo_count", str(packs.size()))
		return
	var pack: Dictionary = ShopCatalogServiceScript.pack_by_id("combo_player")
	if pack.is_empty() or not ShopCatalogServiceScript.is_combo_pack(pack):
		_fail("combo_lookup", str(pack))
		return
	if int(pack.get("stars", 0)) != 2500 or int(pack.get("unlimited_lives_sec", 0)) != 3600:
		_fail("combo_contents", str(pack))
		return
	if int(pack.get("wildcards", 0)) != 3 or int(pack.get("temp_slots", 0)) != 1:
		_fail("combo_extras", str(pack))
		return
	if ShopCatalogServiceScript.confirm_copy_for_pack(pack) != "¿Comprar PACK JUGADOR por $3.99?":
		_fail("combo_confirm", ShopCatalogServiceScript.confirm_copy_for_pack(pack))
		return
	var lines: PackedStringArray = ShopCatalogServiceScript.combo_line_texts(pack)
	if lines.size() != 4 or lines[1] != "1 hora de vidas ilimitadas" or lines[3] != "1 ranura temporal":
		_fail("combo_lines", str(lines))
		return
	var icons: PackedStringArray = ShopCatalogServiceScript.confirm_icon_keys(pack)
	if icons.size() != 3 or icons[0] != "stars" or icons[1] != "lives" or icons[2] != "wildcards":
		_fail("combo_confirm_icons", str(icons))
		return
	var star_icons: PackedStringArray = ShopCatalogServiceScript.confirm_icon_keys(
		ShopCatalogServiceScript.pack_by_id("stars_500")
	)
	if star_icons.size() != 1 or star_icons[0] != "stars":
		_fail("star_confirm_icons", str(star_icons))
		return
	var mixed: Dictionary = ShopCatalogServiceScript.apply_mix_uses({"mix": 1, "hammer": 0}, 3)
	if int(mixed.get("mix", 0)) != 4:
		_fail("apply_mix", str(mixed))
		return
	_ok("combo_pack")

func _test_resource_wildcards() -> void:
	var packs: Array = ShopCatalogServiceScript.resource_wildcard_packs()
	if packs.size() != 6:
		_fail("resource_count", str(packs.size()))
		return
	var mix: Dictionary = ShopCatalogServiceScript.pack_by_id("res_mix")
	if not ShopCatalogServiceScript.is_resource_wildcard(mix):
		_fail("resource_kind", str(mix))
		return
	if str(mix.get("wildcard_type", "")) != "mix" or int(mix.get("star_cost", 0)) != 200:
		_fail("resource_mix", str(mix))
		return
	var mix_pack: Dictionary = ShopCatalogServiceScript.pack_by_id("res_mix_pack")
	if int(mix_pack.get("amount", 0)) != 3 or int(mix_pack.get("star_cost", 0)) != 500:
		_fail("resource_mix_pack", str(mix_pack))
		return
	if int(ShopCatalogServiceScript.pack_by_id("res_hammer_pack").get("star_cost", 0)) != 500:
		_fail("resource_hammer_pack_cost")
		return
	if int(ShopCatalogServiceScript.pack_by_id("res_glove").get("star_cost", 0)) != 200:
		_fail("resource_glove_cost")
		return
	if ShopCatalogServiceScript.confirm_copy_for_pack(mix) != "¿Comprar Mezclar por 200?":
		_fail("resource_confirm", ShopCatalogServiceScript.confirm_copy_for_pack(mix))
		return
	if ShopCatalogServiceScript.confirm_copy_for_pack(mix_pack) != "¿Comprar 3 Mezclar por 500?":
		_fail("resource_pack_confirm", ShopCatalogServiceScript.confirm_copy_for_pack(mix_pack))
		return
	var icons: PackedStringArray = ShopCatalogServiceScript.confirm_icon_keys(mix)
	if icons.size() != 2 or icons[0] != "mix" or icons[1] != "stars":
		_fail("resource_icons", str(icons))
		return
	var types: PackedStringArray = ShopCatalogServiceScript.resource_column_types()
	if types.size() != 3 or types[0] != "mix" or types[2] != "glove":
		_fail("resource_columns", str(types))
		return
	var hammer_offers: Array = ShopCatalogServiceScript.resource_packs_for_type("hammer")
	if hammer_offers.size() != 2:
		_fail("hammer_offers", str(hammer_offers.size()))
		return
	if ShopCatalogServiceScript.unlock_level_for_type("mix") != 4:
		_fail("unlock_mix")
		return
	if ShopCatalogServiceScript.can_buy_resource(mix, 3):
		_fail("locked_at_3")
		return
	if not ShopCatalogServiceScript.can_buy_resource(mix, 4):
		_fail("unlocked_at_4")
		return
	if ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_hammer"), 8):
		_fail("hammer_locked_at_8")
		return
	if not ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_hammer"), 9):
		_fail("hammer_unlocked_at_9")
		return
	if ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_glove"), 13):
		_fail("glove_locked_at_13")
		return
	if not ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_glove"), 14):
		_fail("glove_unlocked_at_14")
		return
	var spent: Dictionary = ShopCatalogServiceScript.spend_stars(250, 200)
	if not bool(spent.get("ok", false)) or int(spent.get("player_stars", 0)) != 50:
		_fail("spend_ok", str(spent))
		return
	var poor: Dictionary = ShopCatalogServiceScript.spend_stars(100, 200)
	if bool(poor.get("ok", true)):
		_fail("spend_poor", str(poor))
		return
	var uses: Dictionary = ShopCatalogServiceScript.apply_wildcard_uses({"hammer": 1}, "hammer", 1)
	if int(uses.get("hammer", 0)) != 2:
		_fail("apply_hammer", str(uses))
		return
	_ok("resource_wildcards")

func _test_grant_stars() -> void:
	var bad: Dictionary = ShopCatalogServiceScript.grant_stars(10, 0)
	if bool(bad.get("ok", true)):
		_fail("grant_zero", str(bad))
		return
	var ok: Dictionary = ShopCatalogServiceScript.grant_stars(100, 500)
	if not bool(ok.get("ok", false)) or int(ok.get("player_stars", 0)) != 600:
		_fail("grant_500", str(ok))
		return
	_ok("grant_stars")

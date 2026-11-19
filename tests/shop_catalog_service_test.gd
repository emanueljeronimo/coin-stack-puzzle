extends SceneTree

const ShopCatalogServiceScript = preload("res://shop_catalog_service.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== shop_catalog_service test ===")
	_test_diamond_packs()
	_test_formatters()
	_test_confirm_copy()
	_test_combo_pack()
	_test_resource_boosters()
	_test_grant_diamonds()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_diamond_packs() -> void:
	var packs: Array = ShopCatalogServiceScript.diamond_packs()
	if packs.size() != 6:
		_fail("pack_count", str(packs.size()))
		return
	var first := ShopCatalogServiceScript.pack_by_id("diamonds_1000")
	if first.is_empty() or int(first.get("amount", 0)) != 1000 or int(first.get("price_cents", 0)) != 199:
		_fail("pack_1000", str(first))
		return
	var last := ShopCatalogServiceScript.pack_by_id("diamonds_100000")
	if last.is_empty() or int(last.get("amount", 0)) != 100000 or int(last.get("price_cents", 0)) != 9999:
		_fail("pack_100000", str(last))
		return
	if int(ShopCatalogServiceScript.pack_by_id("diamonds_25000").get("price_cents", 0)) != 3299:
		_fail("pack_25000_price")
		return
	if ShopCatalogServiceScript.diamond_art_path(first) != "res://Imagenes/oferta-1000.png":
		_fail("art_1000", ShopCatalogServiceScript.diamond_art_path(first))
		return
	if ShopCatalogServiceScript.diamond_art_path(ShopCatalogServiceScript.pack_by_id("diamonds_25000")) != "res://Imagenes/oferta-25000.png":
		_fail("art_25000")
		return
	if ShopCatalogServiceScript.diamond_art_path(last) != "res://Imagenes/oferta-100000.png":
		_fail("art_100000")
		return
	var seen_fills: Array[Color] = []
	for pack_n in packs:
		var ident: Dictionary = ShopCatalogServiceScript.offer_identity(pack_n as Dictionary)
		var fill: Color = ident.get("fill", Color.BLACK)
		for prev in seen_fills:
			if prev.is_equal_approx(fill):
				_fail("diamond_identity_unique", str((pack_n as Dictionary).get("id", "")))
				return
		seen_fills.append(fill)
	if not ShopCatalogServiceScript.pack_by_id("missing").is_empty():
		_fail("unknown_pack")
		return
	_ok("diamond_packs")

func _test_formatters() -> void:
	if ShopCatalogServiceScript.format_amount(500) != "500":
		_fail("amount_500", ShopCatalogServiceScript.format_amount(500))
		return
	if ShopCatalogServiceScript.format_amount(1000) != "1.000":
		_fail("amount_1000", ShopCatalogServiceScript.format_amount(1000))
		return
	if ShopCatalogServiceScript.format_amount(100000) != "100.000":
		_fail("amount_100000", ShopCatalogServiceScript.format_amount(100000))
		return
	if ShopCatalogServiceScript.format_price_usd(199) != "USD 1.99":
		_fail("price_199", ShopCatalogServiceScript.format_price_usd(199))
		return
	if ShopCatalogServiceScript.format_price_usd(3199) != "USD 31.99":
		_fail("price_3199", ShopCatalogServiceScript.format_price_usd(3199))
		return
	_ok("formatters")

func _test_confirm_copy() -> void:
	var copy_1000: String = ShopCatalogServiceScript.confirm_copy(1000, 199)
	if copy_1000 != "¿Comprar 1.000 por USD 1.99?":
		_fail("confirm_1000", copy_1000)
		return
	var copy_50000: String = ShopCatalogServiceScript.confirm_copy(50000, 5999)
	if copy_50000 != "¿Comprar 50.000 por USD 59.99?":
		_fail("confirm_50000", copy_50000)
		return
	_ok("confirm_copy")

func _test_combo_pack() -> void:
	var packs: Array = ShopCatalogServiceScript.combo_packs()
	if packs.size() != 4:
		_fail("combo_count", str(packs.size()))
		return
	var beginner: Dictionary = ShopCatalogServiceScript.pack_by_id("combo_beginner")
	if beginner.is_empty() or not ShopCatalogServiceScript.is_combo_pack(beginner):
		_fail("combo_lookup", str(beginner))
		return
	if int(beginner.get("diamonds", 0)) != 1000 or int(beginner.get("booster_each", 0)) != 2:
		_fail("combo_beginner_contents", str(beginner))
		return
	if not bool(beginner.get("requires_all_boosters", false)):
		_fail("combo_beginner_gate")
		return
	if ShopCatalogServiceScript.all_boosters_unlocked(13):
		_fail("boosters_locked_at_13")
		return
	if not ShopCatalogServiceScript.all_boosters_unlocked(14):
		_fail("boosters_unlocked_at_14")
		return
	var visible_low: Array = ShopCatalogServiceScript.visible_combo_packs(13)
	if visible_low.size() != 3:
		_fail("visible_before_glove", str(visible_low.size()))
		return
	var visible_high: Array = ShopCatalogServiceScript.visible_combo_packs(14)
	if visible_high.size() != 4:
		_fail("visible_after_glove", str(visible_high.size()))
		return
	if ShopCatalogServiceScript.can_buy_combo(beginner, 13):
		_fail("beginner_locked")
		return
	if not ShopCatalogServiceScript.can_buy_combo(beginner, 14):
		_fail("beginner_unlocked")
		return
	var advanced: Dictionary = ShopCatalogServiceScript.pack_by_id("combo_advanced")
	if int(advanced.get("price_cents", 0)) != 999 or int(advanced.get("booster_each", 0)) != 1:
		_fail("combo_advanced", str(advanced))
		return
	if not ShopCatalogServiceScript.can_buy_combo(advanced, 1):
		_fail("advanced_always_visible")
		return
	var ultimate: Dictionary = ShopCatalogServiceScript.pack_by_id("combo_ultimate")
	if int(ultimate.get("diamonds", 0)) != 25000 or int(ultimate.get("price_cents", 0)) != 3199:
		_fail("combo_ultimate", str(ultimate))
		return
	if ShopCatalogServiceScript.art_path_for_amount(25000) != "res://Imagenes/oferta-25000.png":
		_fail("combo_art_amount", ShopCatalogServiceScript.art_path_for_amount(25000))
		return
	if ShopCatalogServiceScript.combo_art_path(beginner) != "res://Imagenes/beginner_bundle.png":
		_fail("combo_beginner_art", ShopCatalogServiceScript.combo_art_path(beginner))
		return
	if ShopCatalogServiceScript.combo_art_path(ultimate) != "res://Imagenes/ultimate-bundle.png":
		_fail("combo_ultimate_art", ShopCatalogServiceScript.combo_art_path(ultimate))
		return
	var beginner_fill: Color = ShopCatalogServiceScript.offer_identity(beginner).get("fill", Color.BLACK)
	var ultimate_fill: Color = ShopCatalogServiceScript.offer_identity(ultimate).get("fill", Color.BLACK)
	if beginner_fill.is_equal_approx(ultimate_fill):
		_fail("combo_identity_unique")
		return
	if ShopCatalogServiceScript.confirm_copy_for_pack(beginner) != "¿Comprar Beginner Bundle por USD 1.99?":
		_fail("combo_confirm", ShopCatalogServiceScript.confirm_copy_for_pack(beginner))
		return
	var lines: PackedStringArray = ShopCatalogServiceScript.combo_line_texts(beginner)
	if lines.size() != 2 or lines[0] != "1.000 diamantes" or lines[1] != "x2 de cada comodín":
		_fail("combo_lines", str(lines))
		return
	var icons: PackedStringArray = ShopCatalogServiceScript.confirm_icon_keys(beginner)
	if icons.size() != 4 or icons[0] != "diamonds" or icons[3] != "glove":
		_fail("combo_confirm_icons", str(icons))
		return
	var diamond_icons: PackedStringArray = ShopCatalogServiceScript.confirm_icon_keys(
		ShopCatalogServiceScript.pack_by_id("diamonds_1000")
	)
	if diamond_icons.size() != 1 or diamond_icons[0] != "diamonds":
		_fail("diamond_confirm_icons", str(diamond_icons))
		return
	var mixed: Dictionary = ShopCatalogServiceScript.apply_mix_uses({"mix": 1, "hammer": 0}, 3)
	if int(mixed.get("mix", 0)) != 4:
		_fail("apply_mix", str(mixed))
		return
	_ok("combo_pack")

func _test_resource_boosters() -> void:
	var packs: Array = ShopCatalogServiceScript.resource_booster_packs()
	if packs.size() != 6:
		_fail("resource_count", str(packs.size()))
		return
	var mix: Dictionary = ShopCatalogServiceScript.pack_by_id("res_mix")
	if not ShopCatalogServiceScript.is_resource_booster(mix):
		_fail("resource_kind", str(mix))
		return
	if str(mix.get("booster_type", "")) != "mix" or int(mix.get("diamond_cost", 0)) != 400:
		_fail("resource_mix", str(mix))
		return
	var mix_pack: Dictionary = ShopCatalogServiceScript.pack_by_id("res_mix_pack")
	if int(mix_pack.get("amount", 0)) != 3 or int(mix_pack.get("diamond_cost", 0)) != 1000:
		_fail("resource_mix_pack", str(mix_pack))
		return
	if int(ShopCatalogServiceScript.pack_by_id("res_hammer_pack").get("diamond_cost", 0)) != 1000:
		_fail("resource_hammer_pack_cost")
		return
	if int(ShopCatalogServiceScript.pack_by_id("res_glove").get("diamond_cost", 0)) != 400:
		_fail("resource_glove_cost")
		return
	if ShopCatalogServiceScript.confirm_copy_for_pack(mix) != "¿Comprar Mezclar por 400?":
		_fail("resource_confirm", ShopCatalogServiceScript.confirm_copy_for_pack(mix))
		return
	if ShopCatalogServiceScript.confirm_copy_for_pack(mix_pack) != "¿Comprar 3 Mezclar por 1.000?":
		_fail("resource_pack_confirm", ShopCatalogServiceScript.confirm_copy_for_pack(mix_pack))
		return
	var icons: PackedStringArray = ShopCatalogServiceScript.confirm_icon_keys(mix)
	if icons.size() != 2 or icons[0] != "mix" or icons[1] != "diamonds":
		_fail("resource_icons", str(icons))
		return
	var types: PackedStringArray = ShopCatalogServiceScript.resource_column_types()
	if types.size() != 3 or types[0] != "hammer" or types[1] != "mix" or types[2] != "glove":
		_fail("resource_columns", str(types))
		return
	var hammer_offers: Array = ShopCatalogServiceScript.resource_packs_for_type("hammer")
	if hammer_offers.size() != 2:
		_fail("hammer_offers", str(hammer_offers.size()))
		return
	if ShopCatalogServiceScript.unlock_level_for_type("hammer") != 4:
		_fail("unlock_hammer")
		return
	if ShopCatalogServiceScript.unlock_level_for_type("mix") != 9:
		_fail("unlock_mix")
		return
	if ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_hammer"), 3):
		_fail("hammer_locked_at_3")
		return
	if not ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_hammer"), 4):
		_fail("hammer_unlocked_at_4")
		return
	if ShopCatalogServiceScript.can_buy_resource(mix, 8):
		_fail("mix_locked_at_8")
		return
	if not ShopCatalogServiceScript.can_buy_resource(mix, 9):
		_fail("mix_unlocked_at_9")
		return
	if ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_glove"), 13):
		_fail("glove_locked_at_13")
		return
	if not ShopCatalogServiceScript.can_buy_resource(ShopCatalogServiceScript.pack_by_id("res_glove"), 14):
		_fail("glove_unlocked_at_14")
		return
	var spent: Dictionary = ShopCatalogServiceScript.spend_diamonds(500, 400)
	if not bool(spent.get("ok", false)) or int(spent.get("player_diamonds", 0)) != 100:
		_fail("spend_ok", str(spent))
		return
	var poor: Dictionary = ShopCatalogServiceScript.spend_diamonds(100, 400)
	if bool(poor.get("ok", true)):
		_fail("spend_poor", str(poor))
		return
	var uses: Dictionary = ShopCatalogServiceScript.apply_booster_uses({"hammer": 1}, "hammer", 1)
	if int(uses.get("hammer", 0)) != 2:
		_fail("apply_hammer", str(uses))
		return
	_ok("resource_boosters")

func _test_grant_diamonds() -> void:
	var bad: Dictionary = ShopCatalogServiceScript.grant_diamonds(10, 0)
	if bool(bad.get("ok", true)):
		_fail("grant_zero", str(bad))
		return
	var ok: Dictionary = ShopCatalogServiceScript.grant_diamonds(100, 500)
	if not bool(ok.get("ok", false)) or int(ok.get("player_diamonds", 0)) != 600:
		_fail("grant_500", str(ok))
		return
	_ok("grant_diamonds")

extends RefCounted

const GameBoosterServiceScript = preload("res://game_booster_service.gd")

const DIAMOND_PACKS := [
	{"id": "diamonds_1000", "amount": 1000, "price_cents": 199, "favorite": false, "art": "res://Imagenes/oferta-1000.png", "fill": Color(0.16, 0.74, 0.86, 0.98), "border": Color(0.62, 0.96, 1.00, 1.0)},
	{"id": "diamonds_5000", "amount": 5000, "price_cents": 799, "favorite": false, "art": "res://Imagenes/oferta-5000.png", "fill": Color(0.22, 0.72, 0.34, 0.98), "border": Color(0.62, 0.96, 0.58, 1.0)},
	{"id": "diamonds_10000", "amount": 10000, "price_cents": 1499, "favorite": false, "art": "res://Imagenes/oferta-10000.png", "fill": Color(0.16, 0.40, 0.92, 0.98), "border": Color(0.62, 0.78, 1.00, 1.0)},
	{"id": "diamonds_25000", "amount": 25000, "price_cents": 3299, "favorite": false, "art": "res://Imagenes/oferta-25000.png", "fill": Color(0.54, 0.26, 0.90, 0.98), "border": Color(0.86, 0.70, 1.00, 1.0)},
	{"id": "diamonds_50000", "amount": 50000, "price_cents": 5999, "favorite": false, "art": "res://Imagenes/oferta-50000.png", "fill": Color(0.88, 0.28, 0.62, 0.98), "border": Color(1.00, 0.70, 0.88, 1.0)},
	{"id": "diamonds_100000", "amount": 100000, "price_cents": 9999, "favorite": false, "art": "res://Imagenes/oferta-100000.png", "fill": Color(0.88, 0.20, 0.26, 0.98), "border": Color(1.00, 0.62, 0.58, 1.0)},
]

const COMBO_PACKS := [
	{
		"id": "combo_beginner",
		"kind": "combo",
		"title": "Beginner Bundle",
		"price_cents": 199,
		"diamonds": 1000,
		"booster_each": 2,
		"art": "res://Imagenes/beginner_bundle.png",
		"requires_all_boosters": true,
		"fill": Color(0.10, 0.66, 0.50, 0.98),
		"border": Color(0.48, 0.96, 0.78, 1.0),
	},
	{
		"id": "combo_advanced",
		"kind": "combo",
		"title": "Advanced Bundle",
		"price_cents": 999,
		"diamonds": 5000,
		"booster_each": 1,
		"art": "res://Imagenes/advanced_bundle.png",
		"fill": Color(0.10, 0.52, 0.78, 0.98),
		"border": Color(0.52, 0.86, 1.00, 1.0),
	},
	{
		"id": "combo_expert",
		"kind": "combo",
		"title": "Expert Bundle",
		"price_cents": 1999,
		"diamonds": 10000,
		"booster_each": 3,
		"art": "res://Imagenes/expert_bundle.png",
		"fill": Color(0.50, 0.20, 0.68, 0.98),
		"border": Color(0.90, 0.64, 1.00, 1.0),
	},
	{
		"id": "combo_ultimate",
		"kind": "combo",
		"title": "Ultimate Bundle",
		"price_cents": 3199,
		"diamonds": 25000,
		"booster_each": 4,
		"art": "res://Imagenes/ultimate-bundle.png",
		"fill": Color(1.00, 0.46, 0.78, 0.98),
		"border": Color(1.00, 0.82, 0.92, 1.0),
	},
]

const BOOSTER_UNIT_AMOUNT := 1
const BOOSTER_UNIT_COST := 400
const BOOSTER_PACK_AMOUNT := 3
const BOOSTER_PACK_COST := 1000

const RESOURCE_BOOSTERS := [
	{
		"id": "res_mix",
		"kind": "resource_booster",
		"booster_type": "mix",
		"title": "Mezclar",
		"amount": BOOSTER_UNIT_AMOUNT,
		"diamond_cost": BOOSTER_UNIT_COST,
	},
	{
		"id": "res_mix_pack",
		"kind": "resource_booster",
		"booster_type": "mix",
		"title": "Mezclar",
		"amount": BOOSTER_PACK_AMOUNT,
		"diamond_cost": BOOSTER_PACK_COST,
	},
	{
		"id": "res_hammer",
		"kind": "resource_booster",
		"booster_type": "hammer",
		"title": "Martillo",
		"amount": BOOSTER_UNIT_AMOUNT,
		"diamond_cost": BOOSTER_UNIT_COST,
	},
	{
		"id": "res_hammer_pack",
		"kind": "resource_booster",
		"booster_type": "hammer",
		"title": "Martillo",
		"amount": BOOSTER_PACK_AMOUNT,
		"diamond_cost": BOOSTER_PACK_COST,
	},
	{
		"id": "res_glove",
		"kind": "resource_booster",
		"booster_type": "glove",
		"title": "Guante",
		"amount": BOOSTER_UNIT_AMOUNT,
		"diamond_cost": BOOSTER_UNIT_COST,
	},
	{
		"id": "res_glove_pack",
		"kind": "resource_booster",
		"booster_type": "glove",
		"title": "Guante",
		"amount": BOOSTER_PACK_AMOUNT,
		"diamond_cost": BOOSTER_PACK_COST,
	},
]

static func diamond_packs() -> Array:
	return DIAMOND_PACKS.duplicate(true)

static func diamond_art_path(pack: Dictionary) -> String:
	var path: String = str(pack.get("art", ""))
	if path.is_empty():
		return "res://Imagenes/icono-diamante.png"
	return path

static func combo_art_path(pack: Dictionary) -> String:
	return diamond_art_path(pack)

static func art_path_for_amount(amount: int) -> String:
	for pack in DIAMOND_PACKS:
		if int(pack.get("amount", 0)) == amount:
			return diamond_art_path(pack as Dictionary)
	return "res://Imagenes/icono-diamante.png"

static func offer_identity(pack: Dictionary) -> Dictionary:
	var fill: Color = Color(0.22, 0.48, 0.78, 0.98)
	var border: Color = Color(0.70, 0.84, 1.00, 1.0)
	if pack.get("fill") is Color:
		fill = pack.get("fill") as Color
	if pack.get("border") is Color:
		border = pack.get("border") as Color
	return {
		"fill": fill,
		"border": border,
	}

static func combo_packs() -> Array:
	return COMBO_PACKS.duplicate(true)

static func all_boosters_unlocked(player_level: int) -> bool:
	for booster_type in GameBoosterServiceScript.TYPES:
		if not GameBoosterServiceScript.is_unlocked(str(booster_type), player_level):
			return false
	return true

static func visible_combo_packs(player_level: int) -> Array:
	var out: Array = []
	for pack in COMBO_PACKS:
		if not (pack is Dictionary):
			continue
		var row: Dictionary = (pack as Dictionary).duplicate(true)
		if bool(row.get("requires_all_boosters", false)) and not all_boosters_unlocked(player_level):
			continue
		out.append(row)
	return out

static func can_buy_combo(pack: Dictionary, player_level: int) -> bool:
	if not is_combo_pack(pack):
		return false
	if bool(pack.get("requires_all_boosters", false)):
		return all_boosters_unlocked(player_level)
	return true

static func resource_booster_packs() -> Array:
	return RESOURCE_BOOSTERS.duplicate(true)

static func resource_column_types() -> PackedStringArray:
	return PackedStringArray(["hammer", "mix", "glove"])

static func resource_packs_for_type(booster_type: String) -> Array:
	var out: Array = []
	for pack in RESOURCE_BOOSTERS:
		if str(pack.get("booster_type", "")) == booster_type:
			out.append((pack as Dictionary).duplicate(true))
	return out

static func unlock_level_for_type(booster_type: String) -> int:
	return int(GameBoosterServiceScript.UNLOCK_LEVEL.get(booster_type, 9999))

static func can_buy_resource(pack: Dictionary, player_level: int) -> bool:
	if not is_resource_booster(pack):
		return false
	return GameBoosterServiceScript.is_unlocked(str(pack.get("booster_type", "")), player_level)

static func is_combo_pack(pack: Dictionary) -> bool:
	return str(pack.get("kind", "")) == "combo"

static func is_resource_booster(pack: Dictionary) -> bool:
	return str(pack.get("kind", "")) == "resource_booster"

static func pack_by_id(pack_id: String) -> Dictionary:
	for pack in DIAMOND_PACKS:
		if str(pack.get("id", "")) == pack_id:
			return (pack as Dictionary).duplicate(true)
	for pack in COMBO_PACKS:
		if str(pack.get("id", "")) == pack_id:
			return (pack as Dictionary).duplicate(true)
	for pack in RESOURCE_BOOSTERS:
		if str(pack.get("id", "")) == pack_id:
			return (pack as Dictionary).duplicate(true)
	return {}

static func format_amount(amount: int) -> String:
	var digits: String = str(maxi(0, amount))
	if digits.length() <= 3:
		return digits
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "." + out
		out = digits[i] + out
		count += 1
	return out

static func format_price_usd(price_cents: int) -> String:
	var cents: int = maxi(0, price_cents)
	var dollars: int = int(cents / 100)
	var rest: int = cents % 100
	return "USD %d.%02d" % [dollars, rest]

static func confirm_copy(amount: int, price_cents: int) -> String:
	return "¿Comprar %s por %s?" % [format_amount(amount), format_price_usd(price_cents)]

static func confirm_copy_for_pack(pack: Dictionary) -> String:
	if pack.is_empty():
		return ""
	if is_resource_booster(pack):
		var title: String = str(pack.get("title", ""))
		var amount: int = int(pack.get("amount", 1))
		var cost_txt: String = format_amount(int(pack.get("diamond_cost", 0)))
		if amount > 1:
			return "¿Comprar %d %s por %s?" % [amount, title, cost_txt]
		return "¿Comprar %s por %s?" % [title, cost_txt]
	if is_combo_pack(pack):
		return "¿Comprar %s por %s?" % [
			str(pack.get("title", "")),
			format_price_usd(int(pack.get("price_cents", 0))),
		]
	return confirm_copy(int(pack.get("amount", 0)), int(pack.get("price_cents", 0)))

static func combo_line_texts(pack: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var diamonds: int = int(pack.get("diamonds", 0))
	var booster_each: int = int(pack.get("booster_each", 0))
	var boosters: int = int(pack.get("boosters", pack.get("wildcards", 0)))
	if diamonds > 0:
		lines.append("%s diamantes" % format_amount(diamonds))
	if booster_each > 0:
		lines.append("x%d de cada comodín" % booster_each)
	elif boosters > 0:
		lines.append("%d Boosters" % boosters)
	return lines

static func confirm_icon_keys(pack: Dictionary) -> PackedStringArray:
	var keys := PackedStringArray()
	if is_combo_pack(pack):
		if int(pack.get("diamonds", 0)) > 0:
			keys.append("diamonds")
		if int(pack.get("booster_each", 0)) > 0:
			keys.append("mix")
			keys.append("hammer")
			keys.append("glove")
		elif int(pack.get("boosters", pack.get("wildcards", 0))) > 0:
			keys.append("boosters")
		return keys
	if is_resource_booster(pack):
		keys.append(str(pack.get("booster_type", "mix")))
		keys.append("diamonds")
		return keys
	for _i in range(4):
		keys.append("diamonds")
	return keys

static func apply_booster_uses(counts: Dictionary, booster_type: String, amount: int) -> Dictionary:
	var out: Dictionary = counts.duplicate(true)
	var key: String = booster_type
	if key.is_empty():
		return out
	out[key] = int(out.get(key, 0)) + maxi(0, amount)
	return out

static func apply_mix_uses(counts: Dictionary, amount: int) -> Dictionary:
	return apply_booster_uses(counts, "mix", amount)

static func spend_diamonds(current_diamonds: int, cost: int) -> Dictionary:
	if cost <= 0:
		return {"ok": false, "player_diamonds": current_diamonds, "spent": 0, "reason": "invalid"}
	if current_diamonds < cost:
		return {
			"ok": false,
			"player_diamonds": current_diamonds,
			"spent": 0,
			"required": cost,
			"reason": "insufficient",
		}
	return {
		"ok": true,
		"player_diamonds": current_diamonds - cost,
		"spent": cost,
	}

static func grant_diamonds(current_diamonds: int, amount: int) -> Dictionary:
	if amount <= 0:
		return {"ok": false, "player_diamonds": current_diamonds, "granted": 0}
	return {
		"ok": true,
		"player_diamonds": current_diamonds + amount,
		"granted": amount,
	}


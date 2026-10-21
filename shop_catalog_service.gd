extends RefCounted

const GameBoosterServiceScript = preload("res://game_booster_service.gd")

const DIAMOND_PACKS := [
	{"id": "diamonds_500", "amount": 500, "price_cents": 99, "favorite": false},
	{"id": "diamonds_1200", "amount": 1200, "price_cents": 199, "favorite": false},
	{"id": "diamonds_2500", "amount": 2500, "price_cents": 399, "favorite": true},
	{"id": "diamonds_6000", "amount": 6000, "price_cents": 799, "favorite": false},
	{"id": "diamonds_15000", "amount": 15000, "price_cents": 1499, "favorite": false},
]

const COMBO_PACKS := [
	{
		"id": "combo_player",
		"kind": "combo",
		"title": "PACK JUGADOR",
		"price_cents": 399,
		"diamonds": 2500,
		"unlimited_lives_sec": 3600,
		"boosters": 3,
		"temp_slots": 1,
	},
]

const BOOSTER_UNIT_AMOUNT := 1
const BOOSTER_UNIT_COST := 200
const BOOSTER_PACK_AMOUNT := 3
const BOOSTER_PACK_COST := 500

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

static func combo_packs() -> Array:
	return COMBO_PACKS.duplicate(true)

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
	return "$%d.%02d" % [dollars, rest]

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
	var unlimited_sec: int = int(pack.get("unlimited_lives_sec", 0))
	var boosters: int = int(pack.get("boosters", pack.get("wildcards", 0)))
	var temp_slots: int = int(pack.get("temp_slots", 0))
	if diamonds > 0:
		lines.append("%s diamantes" % format_amount(diamonds))
	if unlimited_sec >= 3600:
		var hours: int = int(unlimited_sec / 3600)
		if hours == 1:
			lines.append("1 hora de vidas ilimitadas")
		else:
			lines.append("%d horas de vidas ilimitadas" % hours)
	elif unlimited_sec > 0:
		lines.append("vidas ilimitadas")
	if boosters > 0:
		lines.append("%d Boosters" % boosters)
	if temp_slots == 1:
		lines.append("1 ranura temporal")
	elif temp_slots > 1:
		lines.append("%d ranuras temporales" % temp_slots)
	return lines

static func confirm_icon_keys(pack: Dictionary) -> PackedStringArray:
	var keys := PackedStringArray()
	if is_combo_pack(pack):
		if int(pack.get("diamonds", 0)) > 0:
			keys.append("diamonds")
		if int(pack.get("unlimited_lives_sec", 0)) > 0 or int(pack.get("lives", 0)) > 0:
			keys.append("lives")
		if int(pack.get("boosters", pack.get("wildcards", 0))) > 0:
			keys.append("boosters")
		return keys
	if is_resource_booster(pack):
		keys.append(str(pack.get("booster_type", "mix")))
		keys.append("diamonds")
		return keys
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


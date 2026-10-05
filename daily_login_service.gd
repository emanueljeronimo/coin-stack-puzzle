extends RefCounted

const GameWildcardServiceScript = preload("res://game_wildcard_service.gd")

const SLOT_COUNT := 4
const FREE_STARS := 70
const AD_STARS := 100
const UNLIMITED_LIVES_SEC := 15 * 60
const WILDCARD_TYPES: PackedStringArray = ["mix", "hammer", "glove"]

static func unlock_level() -> int:
	return int(GameWildcardServiceScript.UNLOCK_LEVEL.get("mix", 5))

static func is_unlocked(player_level: int) -> bool:
	return player_level >= unlock_level()

static func day_key_from_dict(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [
		int(date.get("year", 0)),
		int(date.get("month", 0)),
		int(date.get("day", 0)),
	]

static func local_day_key() -> String:
	return day_key_from_dict(Time.get_date_dict_from_system())

static func synced_progress(saved_day: String, saved_claimed: int, today: String) -> Dictionary:
	if saved_day != today:
		return {"day": today, "claimed": 0}
	return {"day": today, "claimed": clampi(saved_claimed, 0, SLOT_COUNT)}

static func can_claim(index: int, claimed: int) -> bool:
	return index == claimed and claimed >= 0 and claimed < SLOT_COUNT

static func claim(index: int, claimed: int) -> Dictionary:
	if not can_claim(index, claimed):
		return {"ok": false, "claimed": claimed}
	return {"ok": true, "claimed": claimed + 1}

static func slot_status(index: int, claimed: int) -> String:
	if index < claimed:
		return "claimed"
	if index == claimed:
		return "available"
	return "locked"

static func wildcard_for_day(day_key: String) -> String:
	var parts: PackedStringArray = day_key.split("-")
	if parts.size() != 3:
		return "mix"
	var ordinal: int = int(parts[0]) * 372 + int(parts[1]) * 31 + int(parts[2])
	return WILDCARD_TYPES[ordinal % WILDCARD_TYPES.size()]

static func wildcard_title(wildcard_type: String) -> String:
	match wildcard_type:
		"hammer":
			return "Martillo"
		"glove":
			return "Guante"
		_:
			return "Mezclar"

static func slot_defs(day_key: String) -> Array:
	var wildcard_type: String = wildcard_for_day(day_key)
	return [
		{
			"id": "free_stars",
			"kind": "stars",
			"amount": FREE_STARS,
			"button": "Gratis",
			"requires_ad": false,
		},
		{
			"id": "ad_stars",
			"kind": "stars",
			"amount": AD_STARS,
			"button": "Ver anuncio",
			"requires_ad": true,
		},
		{
			"id": "ad_wildcard",
			"kind": "wildcard",
			"wildcard_type": wildcard_type,
			"amount": 1,
			"button": "Ver anuncio",
			"requires_ad": true,
		},
		{
			"id": "ad_lives",
			"kind": "unlimited_lives",
			"seconds": UNLIMITED_LIVES_SEC,
			"button": "Ver anuncio",
			"requires_ad": true,
		},
	]

static func slot_label(slot: Dictionary) -> String:
	var kind: String = str(slot.get("kind", ""))
	if kind == "stars":
		return str(int(slot.get("amount", 0)))
	if kind == "wildcard":
		return wildcard_title(str(slot.get("wildcard_type", "mix")))
	if kind == "unlimited_lives":
		return "15 min"
	return ""

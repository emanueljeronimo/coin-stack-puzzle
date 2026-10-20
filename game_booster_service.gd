extends RefCounted
class_name GameBoosterService

## Inventario y desbloqueo de Boosters (Martillo / Mezclar / Guante).
## La ficha "?" del mazo es comodin, no Booster.

const TYPES := ["mix", "hammer", "glove"]
const INITIAL_USES := 3
const UNLOCK_LEVEL := {
	"mix": 9,
	"hammer": 4,
	"glove": 14,
}
const COUNTS_KEY := "booster_counts"
const GRANTED_KEY := "booster_unlock_granted"
const LEGACY_COUNTS_KEY := "wildcard_counts"
const LEGACY_GRANTED_KEY := "wildcard_unlock_granted"

static func normalize_counts(raw: Variant) -> Dictionary:
	var out := {}
	for t in TYPES:
		out[t] = 0
	if raw is Dictionary:
		for t in TYPES:
			out[t] = maxi(0, int(raw.get(t, 0)))
	return out

static func normalize_granted(raw: Variant) -> Dictionary:
	var out := {}
	for t in TYPES:
		out[t] = false
	if raw is Dictionary:
		for t in TYPES:
			out[t] = bool(raw.get(t, false))
	return out

static func read_counts(data: Dictionary) -> Dictionary:
	if data.has(COUNTS_KEY):
		return normalize_counts(data.get(COUNTS_KEY))
	return normalize_counts(data.get(LEGACY_COUNTS_KEY, {}))

static func read_granted(data: Dictionary) -> Dictionary:
	if data.has(GRANTED_KEY):
		return normalize_granted(data.get(GRANTED_KEY))
	return normalize_granted(data.get(LEGACY_GRANTED_KEY, {}))

static func write_state(data: Dictionary, counts: Dictionary, granted: Dictionary) -> void:
	data[COUNTS_KEY] = normalize_counts(counts)
	data[GRANTED_KEY] = normalize_granted(granted)
	data.erase(LEGACY_COUNTS_KEY)
	data.erase(LEGACY_GRANTED_KEY)

static func is_unlocked(booster_type: String, checkpoint_level: int, unlock_levels: Dictionary = UNLOCK_LEVEL) -> bool:
	return checkpoint_level >= int(unlock_levels.get(booster_type, 9999))

static func earliest_unlock_level(unlock_levels: Dictionary = UNLOCK_LEVEL) -> int:
	var earliest: int = 9999
	for booster_type in TYPES:
		earliest = mini(earliest, int(unlock_levels.get(booster_type, 9999)))
	return earliest

## Aplica desbloqueos. previous_level=-1 = restore/setup (sin carteles).
static func sync_unlocks(
	checkpoint_level: int,
	counts: Dictionary,
	granted: Dictionary,
	previous_level: int = -1,
	initial_uses: int = INITIAL_USES,
	unlock_levels: Dictionary = UNLOCK_LEVEL
) -> Dictionary:
	var new_counts := normalize_counts(counts)
	var new_granted := normalize_granted(granted)
	var newly_unlocked: Array = []
	for booster_type in TYPES:
		var unlock_lvl := int(unlock_levels.get(booster_type, 9999))
		if checkpoint_level >= unlock_lvl:
			if not bool(new_granted.get(booster_type, false)):
				if int(new_counts.get(booster_type, 0)) <= 0:
					new_counts[booster_type] = initial_uses
				new_granted[booster_type] = true
				var crossed := (
					previous_level >= 0
					and previous_level < unlock_lvl
					and checkpoint_level >= unlock_lvl
				)
				if crossed:
					newly_unlocked.append(booster_type)
		else:
			new_counts[booster_type] = 0
	return {
		"booster_counts": new_counts,
		"booster_unlock_granted": new_granted,
		"newly_unlocked": newly_unlocked,
	}

static func consume(counts: Dictionary, booster_type: String) -> Dictionary:
	var out := normalize_counts(counts)
	if not TYPES.has(booster_type):
		return out
	out[booster_type] = maxi(0, int(out.get(booster_type, 0)) - 1)
	return out

static func add_uses(
	counts: Dictionary,
	booster_type: String,
	amount: int,
	checkpoint_level: int,
	unlock_levels: Dictionary = UNLOCK_LEVEL,
	require_unlock: bool = true
) -> Dictionary:
	var out := normalize_counts(counts)
	if not TYPES.has(booster_type):
		return out
	if require_unlock and not is_unlocked(booster_type, checkpoint_level, unlock_levels):
		return out
	out[booster_type] = int(out.get(booster_type, 0)) + maxi(1, amount)
	return out

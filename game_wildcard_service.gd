extends RefCounted
class_name GameWildcardService

## Lógica pura de inventario/desbloqueo de comodines (testeable sin escena).

const TYPES := ["mix", "hammer", "glove"]
const INITIAL_USES := 3
const UNLOCK_LEVEL := {
	"mix": 5,
	"hammer": 10,
	"glove": 15,
}

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

static func is_unlocked(wildcard_type: String, checkpoint_level: int, unlock_levels: Dictionary = UNLOCK_LEVEL) -> bool:
	return checkpoint_level >= int(unlock_levels.get(wildcard_type, 9999))

## Aplica desbloqueos. previous_level=-1 = restore/setup (sin carteles).
## Devuelve counts/granted actualizados y la lista de tipos recién cruzados (para UI).
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
	for wildcard_type in TYPES:
		var unlock_lvl := int(unlock_levels.get(wildcard_type, 9999))
		if checkpoint_level >= unlock_lvl:
			if not bool(new_granted.get(wildcard_type, false)):
				if int(new_counts.get(wildcard_type, 0)) <= 0:
					new_counts[wildcard_type] = initial_uses
				new_granted[wildcard_type] = true
				var crossed := (
					previous_level >= 0
					and previous_level < unlock_lvl
					and checkpoint_level >= unlock_lvl
				)
				if crossed:
					newly_unlocked.append(wildcard_type)
		else:
			new_counts[wildcard_type] = 0
	return {
		"wildcard_counts": new_counts,
		"wildcard_unlock_granted": new_granted,
		"newly_unlocked": newly_unlocked,
	}

static func consume(counts: Dictionary, wildcard_type: String) -> Dictionary:
	var out := normalize_counts(counts)
	if not TYPES.has(wildcard_type):
		return out
	out[wildcard_type] = maxi(0, int(out.get(wildcard_type, 0)) - 1)
	return out

static func add_uses(
	counts: Dictionary,
	wildcard_type: String,
	amount: int,
	checkpoint_level: int,
	unlock_levels: Dictionary = UNLOCK_LEVEL
) -> Dictionary:
	var out := normalize_counts(counts)
	if not TYPES.has(wildcard_type):
		return out
	if not is_unlocked(wildcard_type, checkpoint_level, unlock_levels):
		return out
	out[wildcard_type] = int(out.get(wildcard_type, 0)) + maxi(1, amount)
	return out

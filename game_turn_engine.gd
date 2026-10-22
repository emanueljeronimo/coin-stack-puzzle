extends RefCounted
class_name GameTurnEngine

const GameRulesScript = preload("res://game_rules.gd")

# Motor puro para decisiones del turno de reparto.

static func build_roll_values(roll_min: int, roll_max: int, extra_count_provider: Callable) -> Array:
	var values: Array = []
	for value in range(roll_min, roll_max + 1):
		values.append(value)
		var extra_count := int(extra_count_provider.call())
		extra_count = clampi(extra_count, 0, 2)
		for _i in range(extra_count):
			values.append(value)
	return values

static func compute_roll_count(pool_size: int, total_free_slots: int, keep_one_free_if_possible: bool = true) -> int:
	var roll_count := mini(pool_size, total_free_slots)
	if keep_one_free_if_possible and total_free_slots >= 2 and roll_count >= total_free_slots:
		roll_count = total_free_slots - 1
	return maxi(0, roll_count)

const EARLY_GROUP_LEVELS := 0
const EARLY_GROUP_CHUNK := 4

## 2x al inicio, 1.5x al desbloquear Mezclar, 1x cerca del prestige.
const DEAL_DOUBLE_UNTIL_LEVEL := 8
const DEAL_ONE_HALF_UNTIL_LEVEL := 12

static func deal_multiplier(checkpoint_level: int) -> float:
	if checkpoint_level <= 0:
		return 1.0
	if checkpoint_level <= DEAL_DOUBLE_UNTIL_LEVEL:
		return 2.0
	if checkpoint_level <= DEAL_ONE_HALF_UNTIL_LEVEL:
		return 1.5
	return 1.0

static func should_double_early_deals(checkpoint_level: int) -> bool:
	return deal_multiplier(checkpoint_level) >= 2.0

static func early_roll_target(checkpoint_level: int) -> int:
	match checkpoint_level:
		1:
			return 10
		2:
			return 8
		3:
			return 6
		4:
			return 5
		_:
			return 0

static func should_group_early_rolls(checkpoint_level: int) -> bool:
	return EARLY_GROUP_LEVELS > 0 and checkpoint_level >= 1 and checkpoint_level <= EARLY_GROUP_LEVELS

## Primera tirada piso..piso+1, segunda piso+2. Despues el tope sigue al mazo real.
## El piso post-prestige (31) tiene que capear 31-32, no el absoluto 1-2.
static func early_roll_value_max(
	checkpoint_level: int,
	deal_index: int,
	roll_floor: int,
	max_roll: int
) -> int:
	if early_roll_target(checkpoint_level) <= 0:
		return max_roll
	var cap := max_roll
	if deal_index <= 0:
		cap = roll_floor + 1
	elif deal_index == 1 or checkpoint_level <= 2:
		cap = roll_floor + 2
	return clampi(mini(cap, max_roll), roll_floor, max_roll)

static func early_pad_max(checkpoint_level: int, roll_floor: int, max_roll: int) -> int:
	return early_roll_value_max(checkpoint_level, 2, roll_floor, max_roll)

static func compute_level_roll_count(
	checkpoint_level: int,
	pool_size: int,
	total_free_slots: int,
	keep_one_free_if_possible: bool = true
) -> int:
	var base: int = compute_roll_count(pool_size, total_free_slots, keep_one_free_if_possible)
	var early: int = early_roll_target(checkpoint_level)
	var wanted: int = maxi(base, early)
	wanted = int(round(float(wanted) * deal_multiplier(checkpoint_level)))
	var cap: int = total_free_slots
	if keep_one_free_if_possible and total_free_slots >= 2:
		cap = total_free_slots - 1
	return clampi(wanted, 0, maxi(0, cap))

static func pad_roll_values(values: Array, target_count: int, easy_min: int, easy_max: int) -> Array:
	var out: Array = values.duplicate()
	if target_count <= out.size() or easy_max < easy_min:
		return out
	var span: int = easy_max - easy_min + 1
	var i: int = 0
	while out.size() < target_count:
		out.append(easy_min + (i % span))
		i += 1
	return out

## Junta iguales en bloques (2,2,2,2,1,1) para tirarlas juntas.
static func cluster_roll_values(values: Array) -> Array:
	var counts: Dictionary = {}
	var keys: Array = []
	for raw in values:
		var v := int(raw)
		if not counts.has(v):
			keys.append(v)
		counts[v] = int(counts.get(v, 0)) + 1
	var out: Array = []
	for key in keys:
		var v := int(key)
		for _i in range(int(counts[v])):
			out.append(v)
	return out

static func pick_stack_for_grouped_value(
	value: int,
	stack_tops: Array,
	stack_free: Array,
	avoid_index: int = -1
) -> int:
	var best := pick_stack_for_grouped_value_among(value, stack_tops, stack_free, avoid_index)
	if best >= 0:
		return best
	return pick_stack_for_grouped_value_among(value, stack_tops, stack_free, -1)

static func pick_stack_for_grouped_value_among(
	value: int,
	stack_tops: Array,
	stack_free: Array,
	avoid_index: int
) -> int:
	var best := -1
	var best_score := -1
	for i in range(stack_tops.size()):
		if i == avoid_index:
			continue
		var free := int(stack_free[i]) if i < stack_free.size() else 0
		if free <= 0:
			continue
		var top := int(stack_tops[i])
		var score := free
		if top == value:
			score += 300
		elif top < 0:
			score += 200
		if score > best_score:
			best_score = score
			best = i
	return best

static func assign_grouped_rolls(values: Array, stack_tops: Array, stack_free: Array) -> Array:
	var tops: Array = stack_tops.duplicate()
	var frees: Array = stack_free.duplicate()
	var assigned: Array = []
	var run_stack := -1
	var run_value := -999
	var run_len := 0
	for raw in values:
		var value := int(raw)
		var idx := -1
		if (
			run_stack >= 0
			and run_value == value
			and run_len < EARLY_GROUP_CHUNK
			and run_stack < frees.size()
			and int(frees[run_stack]) > 0
		):
			idx = run_stack
		else:
			var avoid := run_stack if run_value == value and run_len >= EARLY_GROUP_CHUNK else -1
			idx = pick_stack_for_grouped_value(value, tops, frees, avoid)
			run_len = 0
		assigned.append(idx)
		if idx < 0:
			run_stack = -1
			run_value = -999
			run_len = 0
			continue
		tops[idx] = value
		frees[idx] = int(frees[idx]) - 1
		run_stack = idx
		run_value = value
		run_len += 1
	return assigned

static func apply_round_wildcard(
	values: Array,
	dealt_count: int,
	chance: float,
	roll01: Callable,
	pick_index: Callable,
	force: bool = false
) -> Array:
	var n := mini(dealt_count, values.size())
	if n <= 0:
		return values
	if chance <= 0.0:
		return values
	if not force and float(roll01.call()) >= chance:
		return values
	var idx := int(pick_index.call(n))
	idx = clampi(idx, 0, n - 1)
	values[idx] = GameRulesScript.COIN_WILDCARD_VALUE
	return values

static func pick_balanced_index(
	candidate_count: int,
	assigned_count_for_candidate: Callable,
	random_index_provider: Callable
) -> int:
	if candidate_count <= 0:
		return -1
	var min_assigned := 2147483647
	var shortlist: Array = []
	for i in range(candidate_count):
		var assigned := int(assigned_count_for_candidate.call(i))
		if assigned < min_assigned:
			min_assigned = assigned
			shortlist = [i]
		elif assigned == min_assigned:
			shortlist.append(i)
	if shortlist.is_empty():
		return -1
	if shortlist.size() == 1:
		return int(shortlist[0])
	var pick := int(random_index_provider.call(shortlist.size()))
	pick = clampi(pick, 0, shortlist.size() - 1)
	return int(shortlist[pick])

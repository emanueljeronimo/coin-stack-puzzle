extends RefCounted
class_name GameTurnEngine

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

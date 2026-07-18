extends RefCounted
class_name GameEngine

# Motor puro: reglas matemáticas de checkpoints, ciclos y progreso.

static func cycle_index(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	if roll_value_floor <= 1:
		return 0
	return int((roll_value_floor + checkpoint_base_value) / board_cycle_levels)

static func cycle_base_level(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	return cycle_index(roll_value_floor, checkpoint_base_value, board_cycle_levels) * board_cycle_levels

static func cycle_coin_offset(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	var idx := cycle_index(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	if idx <= 0:
		return 0
	return idx * board_cycle_levels - checkpoint_base_value

static func next_cycle_coin_milestone(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	return (cycle_index(roll_value_floor, checkpoint_base_value, board_cycle_levels) + 1) * board_cycle_levels

static func reached_cycle_coin_milestone(
	highest_value: int,
	roll_value_floor: int,
	checkpoint_base_value: int,
	board_cycle_levels: int
) -> int:
	var found := 0
	var next_m := next_cycle_coin_milestone(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	while next_m > 0 and next_m <= highest_value:
		found = next_m
		next_m += board_cycle_levels
	return found

static func evaluate_checkpoint_level(
	highest_value: int,
	highest_value_max_count: int,
	roll_value_floor: int,
	checkpoint_base_value: int,
	checkpoint_half_threshold: int,
	board_cycle_levels: int
) -> int:
	var offset := cycle_coin_offset(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var local_highest := highest_value - offset
	var cycle_base := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	if local_highest < checkpoint_base_value:
		return 1 if cycle_base == 0 else cycle_base
	var has_half := highest_value_max_count > checkpoint_half_threshold
	var local_level := 2 * (local_highest - checkpoint_base_value) + 2 + (1 if has_half else 0)
	if cycle_base == 0:
		return local_level
	return cycle_base + local_level - 1

static func progress_toward_checkpoint_level(
	target_level: int,
	highest_value: int,
	max_count_for_value: Callable,
	stack_capacity: int,
	roll_value_floor: int,
	checkpoint_base_value: int,
	checkpoint_half_threshold: int,
	board_cycle_levels: int
) -> float:
	if target_level <= 1:
		return 0.0
	var cycle_for_target := int(maxi(target_level - 1, 0) / board_cycle_levels)
	var cycle_base := cycle_for_target * board_cycle_levels
	var local_target := target_level if cycle_base == 0 else target_level - cycle_base + 1
	var offset := 0 if cycle_for_target <= 0 else cycle_for_target * board_cycle_levels - checkpoint_base_value
	if local_target <= 1:
		return 0.0
	var steps := local_target - 2
	var local_v := checkpoint_base_value + int(steps / 2)
	var v := local_v + offset
	if steps % 2 == 0:
		if highest_value >= v:
			return 1.0
		var prev_v := maxi(offset + 1, v - 1)
		var hv_part := clampf(float(highest_value - offset) / float(maxi(1, prev_v - offset)), 0.0, 1.0) * 0.35
		var pile_part := clampf(
			float(int(max_count_for_value.call(prev_v))) / float(stack_capacity), 0.0, 1.0
		) * 0.65
		return clampf(hv_part + pile_part, 0.0, 0.99)
	var need := checkpoint_half_threshold + 1
	return clampf(float(int(max_count_for_value.call(v))) / float(need), 0.0, 1.0)

static func checkpoint_level_description(
	level: int,
	checkpoint_base_value: int,
	board_cycle_levels: int
) -> String:
	if level <= 1:
		return ""
	var cycle_for_level := int(maxi(level - 1, 0) / board_cycle_levels)
	var cycle_base := cycle_for_level * board_cycle_levels
	var local_level := level if cycle_base == 0 else level - cycle_base + 1
	var offset := 0 if cycle_for_level <= 0 else cycle_for_level * board_cycle_levels - checkpoint_base_value
	if local_level <= 1:
		return ""
	var steps := local_level - 2
	var local_v := checkpoint_base_value + int(steps / 2)
	var v := local_v + offset
	if steps % 2 == 0:
		if steps == 0:
			return "Creaste la pila %d" % v
		return "Completaste la pila %d" % (v - 1)
	return "Pila %d: más de la mitad" % v

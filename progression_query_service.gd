class_name ProgressionQueryService
extends RefCounted

static func evaluate_checkpoint_level(engine_script: GDScript, max_count_callable: Callable, roll_value_floor: int, checkpoint_base_value: int, checkpoint_half_threshold: int, board_cycle_levels: int, cycle_checkpoint_origin: int, checkpoint_level: int) -> int:
	return engine_script.evaluate_checkpoint_from_piles(
		max_count_callable,
		roll_value_floor,
		checkpoint_base_value,
		checkpoint_half_threshold,
		board_cycle_levels,
		cycle_checkpoint_origin,
		checkpoint_level
	)

static func progress_toward_checkpoint(engine_script: GDScript, target_level: int, highest_coin_value_for_checkpoint: int, max_count_callable: Callable, stack_capacity: int, roll_value_floor: int, checkpoint_base_value: int, checkpoint_half_threshold: int, board_cycle_levels: int, cycle_checkpoint_origin: int) -> float:
	return engine_script.progress_toward_checkpoint_level(
		target_level,
		highest_coin_value_for_checkpoint,
		max_count_callable,
		stack_capacity,
		roll_value_floor,
		checkpoint_base_value,
		checkpoint_half_threshold,
		board_cycle_levels,
		cycle_checkpoint_origin
	)

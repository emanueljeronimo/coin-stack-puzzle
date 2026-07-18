extends RefCounted
class_name GameBoardEngine

# Motor puro para decisiones de tablero (checkpoint/reset/subida de nivel).

static func has_level_up(top_values: Array, max_value: int) -> bool:
	var next_value := max_value + 1
	for v in top_values:
		if int(v) == next_value:
			return true
	return false

static func apply_level_up(current_level: int, max_value: int) -> Dictionary:
	return {
		"current_level": current_level + 1,
		"max_value": max_value + 1,
	}

static func decide_checkpoint_update(
	previous_checkpoint: int,
	evaluated_checkpoint: int,
	cycle_milestone: int
) -> Dictionary:
	if cycle_milestone > 0:
		return {
			"changed": true,
			"checkpoint_level": maxi(previous_checkpoint, cycle_milestone),
			"did_cycle_reset": true,
		}
	if evaluated_checkpoint > previous_checkpoint:
		return {
			"changed": true,
			"checkpoint_level": evaluated_checkpoint,
			"did_cycle_reset": false,
		}
	return {
		"changed": false,
		"checkpoint_level": previous_checkpoint,
		"did_cycle_reset": false,
	}

static func build_cycle_reset_state(milestone_level: int, config: Dictionary) -> Dictionary:
	var board_cycle_levels := int(config.get("board_cycle_levels", 15))
	if milestone_level < board_cycle_levels or milestone_level % board_cycle_levels != 0:
		return {"valid": false}
	var checkpoint_base_value := int(config.get("checkpoint_base_value", 5))
	return {
		"valid": true,
		"active_stacks": int(config.get("cycle_reset_stacks", 4)),
		"current_level": 1,
		"max_value": milestone_level,
		"roll_value_floor": milestone_level - checkpoint_base_value,
		"adjacent_slot_next_price": int(config.get("adjacent_slot_base_price", 600)),
	}

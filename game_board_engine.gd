extends RefCounted
class_name GameBoardEngine

const GameEngineScript := preload("res://game_engine.gd")

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

## El objetivo avanza de a 1 solo si ya existe la ficha siguiente (max+1).
## Ochos residuales con max=5 no cuentan como nivel 8/9 en el mismo turno.
static func catch_up_max_value(current_level: int, max_value: int, has_next_value: bool) -> Dictionary:
	if not has_next_value:
		return {
			"current_level": current_level,
			"max_value": max_value,
			"changed": false,
			"steps": 0,
		}
	return {
		"current_level": current_level + 1,
		"max_value": max_value + 1,
		"changed": true,
		"steps": 1,
	}

static func decide_checkpoint_update(
	previous_checkpoint: int,
	evaluated_checkpoint: int,
	cycle_milestone: int
) -> Dictionary:
	if cycle_milestone > 0:
		return {
			"changed": true,
			"checkpoint_level": maxi(previous_checkpoint, maxi(evaluated_checkpoint, cycle_milestone)),
			"did_cycle_reset": true,
		}
	if evaluated_checkpoint > previous_checkpoint:
		return {
			"changed": true,
			# Como mucho mitad + completar en la misma jugada (1→3). Nunca 1→9.
			"checkpoint_level": mini(evaluated_checkpoint, previous_checkpoint + 2),
			"did_cycle_reset": false,
		}
	return {
		"changed": false,
		"checkpoint_level": previous_checkpoint,
		"did_cycle_reset": false,
	}

static func build_cycle_reset_state(milestone_level: int, config: Dictionary) -> Dictionary:
	var board_cycle_levels := int(config.get("board_cycle_levels", 15))
	if milestone_level < board_cycle_levels or not GameEngineScript.is_cycle_coin_milestone(
		milestone_level,
		board_cycle_levels
	):
		return {"valid": false}
	var checkpoint_base_value := int(config.get("checkpoint_base_value", 5))
	var prestige_checkpoint := int(config.get("checkpoint_level", milestone_level))
	return {
		"valid": true,
		"active_stacks": int(config.get("cycle_reset_stacks", 5)),
		# Igual que el arranque: objetivo = hito, tirada hasta hito-1.
		"current_level": 1,
		"max_value": GameEngineScript.cycle_reset_max_value(milestone_level),
		"roll_value_floor": GameEngineScript.cycle_reset_roll_value_floor(
			milestone_level,
			checkpoint_base_value
		),
		"cycle_checkpoint_origin": GameEngineScript.cycle_checkpoint_origin(
			milestone_level,
			prestige_checkpoint
		),
		"adjacent_slot_next_price": int(config.get("adjacent_slot_base_price", 600)),
	}

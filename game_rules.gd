extends RefCounted
class_name GameRules

# Reglas de motor centralizadas (data-driven) para no mezclar criterio de juego con UI.
const TEMP_SLOT_ACTIONS_TO_CLOSE := 3
const TEMP_SLOT_CLOSE_BY_ACTIONS := false
const ENABLE_FUSION_CREATE_BONUS := false

const ADJACENT_SLOT_FREE_FIRST_LEVEL := 4
const ADJACENT_SLOT_FREE_LEVEL_INTERVAL := 2

static func initial_free_slot_unlock_level(cycle_base_level: int) -> int:
	return cycle_base_level + ADJACENT_SLOT_FREE_FIRST_LEVEL

static func next_free_slot_unlock_level(current_unlock_level: int) -> int:
	return current_unlock_level + ADJACENT_SLOT_FREE_LEVEL_INTERVAL

static func normalize_temp_state(
	temp_active: bool,
	temp_time_remaining: float,
	stack_count: int,
	active_stacks: int
) -> Dictionary:
	var has_extra_stack := stack_count == active_stacks + 1 and active_stacks >= 1
	if not temp_active:
		return {
			"temp_slot_bonus_active": false,
			"temp_slot_time_remaining": 0.0,
		}
	if temp_time_remaining <= 0.05:
		return {
			"temp_slot_bonus_active": false,
			"temp_slot_time_remaining": 0.0,
		}
	if not has_extra_stack:
		return {
			"temp_slot_bonus_active": false,
			"temp_slot_time_remaining": 0.0,
		}
	return {
		"temp_slot_bonus_active": true,
		"temp_slot_time_remaining": temp_time_remaining,
	}

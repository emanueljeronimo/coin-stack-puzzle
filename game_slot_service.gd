extends RefCounted
class_name GameSlotService

static func consume_temp_action(temp_active: bool, actions_remaining: int) -> Dictionary:
	if not temp_active:
		return {
			"actions_remaining": actions_remaining,
			"should_close": false,
		}
	if actions_remaining <= 0:
		return {
			"actions_remaining": 0,
			"should_close": true,
		}
	actions_remaining -= 1
	return {
		"actions_remaining": actions_remaining,
		"should_close": actions_remaining <= 0,
	}

static func ensure_unlock_cursor(current_level: int, cycle_base_level: int, first_level_in_cycle: int) -> int:
	if current_level > 0:
		if current_level % 2 != 0:
			return current_level + 1
		return current_level
	var fallback := cycle_base_level + first_level_in_cycle
	if fallback % 2 != 0:
		fallback += 1
	return fallback

static func is_stale_unlock(previous_level: int, unlock_level: int) -> bool:
	return unlock_level < previous_level

static func can_grant_free_unlock(previous_level: int, new_level: int, unlock_level: int) -> bool:
	if is_stale_unlock(previous_level, unlock_level):
		return false
	return new_level >= unlock_level

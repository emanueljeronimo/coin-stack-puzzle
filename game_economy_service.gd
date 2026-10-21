extends RefCounted
class_name GameEconomyService

# Motor puro para compras y economía in-game (slots).
# player_stars y coins quedan como claves legacy de save.

static func read_diamonds(data: Dictionary, fallback: int = 0) -> int:
	if data.has("player_diamonds"):
		return int(data["player_diamonds"])
	if data.has("player_stars"):
		return int(data["player_stars"])
	if data.has("coins"):
		return int(data["coins"])
	return fallback


static func write_diamonds(data: Dictionary, amount: int) -> Dictionary:
	var next: int = maxi(0, amount)
	data["player_diamonds"] = next
	data["player_stars"] = next
	data["coins"] = next
	return data


static func purchase_temp_slot(state: Dictionary, config: Dictionary) -> Dictionary:
	var diamonds := read_diamonds(state)
	var temp_active := bool(state.get("temp_slot_bonus_active", false))
	var has_temp_stack := bool(state.get("has_active_temp_stack", false))
	var cost := int(config.get("temp_slot_cost_diamonds", 0))
	var duration := float(config.get("temp_slot_duration_sec", 0.0))
	var actions_on_open := int(config.get("temp_slot_actions_to_close", 0))

	if temp_active and has_temp_stack:
		return {"ok": false, "reason": "already_active"}

	# Estado corrupto: flag activa sin pila temporal real.
	if temp_active and not has_temp_stack:
		temp_active = false

	if diamonds < cost:
		return {"ok": false, "reason": "insufficient_diamonds", "required": cost, "current": diamonds}

	return {
		"ok": true,
		"reason": "opened",
		"player_diamonds": diamonds - cost,
		"temp_slot_bonus_active": true,
		"temp_slot_time_remaining": duration,
		"temp_slot_actions_remaining": maxi(0, actions_on_open),
	}

static func purchase_adjacent_slot(state: Dictionary) -> Dictionary:
	var offer_index := int(state.get("adjacent_offer_board_index", -1))
	var active_stacks := int(state.get("active_stacks", 0))
	var max_permanent := int(state.get("max_permanent_stacks", 14))
	if offer_index < 0 or active_stacks >= max_permanent:
		return {"ok": false, "reason": "not_available"}

	var checkpoint_level := int(state.get("checkpoint_level", 1))
	var unlock_level := int(state.get("next_free_slot_unlock_level", 99999))
	if checkpoint_level >= unlock_level:
		return {"ok": true, "reason": "free_unlock"}

	var diamonds := read_diamonds(state)
	var price := int(state.get("adjacent_slot_next_price", 0))
	if diamonds < price:
		return {
			"ok": false,
			"reason": "insufficient_diamonds",
			"required": price,
			"current": diamonds,
		}

	var next_unlock := int(state.get("next_free_slot_unlock_level", unlock_level))
	return {
		"ok": true,
		"reason": "purchased",
		"player_diamonds": diamonds - price,
		"adjacent_slot_next_price": price * 2,
		"next_free_slot_unlock_level": next_unlock,
	}

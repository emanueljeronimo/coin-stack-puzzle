class_name TempSlotPurchaseService
extends RefCounted

static func build_purchase_request(player_diamonds: int, temp_slot_bonus_active: bool, has_active_temp_stack: bool) -> Dictionary:
	return {
		"player_diamonds": player_diamonds,
		"temp_slot_bonus_active": temp_slot_bonus_active,
		"has_active_temp_stack": has_active_temp_stack,
	}

static func build_rules(cost_diamonds: int, duration_sec: float, actions_to_close: int) -> Dictionary:
	return {
		"temp_slot_cost_diamonds": cost_diamonds,
		"temp_slot_duration_sec": duration_sec,
		"temp_slot_actions_to_close": actions_to_close,
	}

static func confirm_copy(price: int) -> String:
	return "¿Comprar ranura temporal por %d?" % maxi(0, price)

static func message_for_rejection(reason: String, required: int, current: int) -> String:
	if reason == "already_active":
		return "Ya tenes una ranura temporal activa."
	if reason == "insufficient_diamonds":
		return "Necesitas %d diamantes para la ranura temporal (tenes %d)." % [required, current]
	return ""

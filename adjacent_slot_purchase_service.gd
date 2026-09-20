class_name AdjacentSlotPurchaseService
extends RefCounted

static func build_purchase_request(adjacent_offer_board_index: int, active_stacks: int, max_permanent_stacks: int, checkpoint_level: int, next_free_slot_unlock_level: int, player_stars: int, adjacent_slot_next_price: int) -> Dictionary:
	return {
		"adjacent_offer_board_index": adjacent_offer_board_index,
		"active_stacks": active_stacks,
		"max_permanent_stacks": max_permanent_stacks,
		"checkpoint_level": checkpoint_level,
		"next_free_slot_unlock_level": next_free_slot_unlock_level,
		"player_stars": player_stars,
		"adjacent_slot_next_price": adjacent_slot_next_price,
	}

static func is_insufficient_stars(reason: String) -> bool:
	return reason == "insufficient_stars"

static func is_free_unlock(reason: String) -> bool:
	return reason == "free_unlock"

class_name MainBoardRenderService
extends RefCounted

static func should_skip_slot(slot_index: int, temp_slot_index: int, temp_slot_bonus_active: bool, adjacent_offer_board_index: int) -> bool:
	if slot_index == temp_slot_index and not temp_slot_bonus_active:
		return true
	if slot_index == adjacent_offer_board_index and adjacent_offer_board_index >= 0:
		return true
	return false

static func slot_visual_state(slot_index: int, temp_slot_index: int, temp_slot_bonus_active: bool, selected_slot_idx: int, slot_is_active: bool, fill_dim: Color, border_dim: Color, fill_temp: Color, border_temp: Color, fill_selected: Color, border_selected: Color, fill_active: Color, border_active: Color) -> Dictionary:
	var is_selected_slot := selected_slot_idx >= 0 and slot_index == selected_slot_idx
	if slot_index == temp_slot_index and not temp_slot_bonus_active:
		return {"style_key": "temp", "fill": fill_temp, "border": border_temp, "selected": false}
	if is_selected_slot:
		return {"style_key": "selected", "fill": fill_selected, "border": border_selected, "selected": true}
	if slot_is_active:
		return {"style_key": "active", "fill": fill_active, "border": border_active, "selected": false}
	return {"style_key": "inactive", "fill": fill_dim, "border": border_dim, "selected": false}

static func slot_border_width(border_base: int, is_selected: bool) -> int:
	return border_base + (1 if is_selected else 0)

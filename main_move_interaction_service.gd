class_name MainMoveInteractionService
extends RefCounted

static func can_process_click(has_pending_coin_animations: bool) -> bool:
	return not has_pending_coin_animations

static func clicked_outside_stack(clicked_stack: Variant) -> bool:
	return clicked_stack == null

static func glove_prompt_no_stack() -> String:
	return "Guante: elegi origen y despues un destino con espacio."

static func glove_prompt_empty_origin() -> String:
	return "Guante: elegi una pila con fichas."

static func glove_prompt_pick_destination() -> String:
	return "Guante: ahora toca el destino (cualquier ranura con hueco)."

static func invalid_move_message() -> String:
	return "Movimiento invalido: destino lleno o tope incompatible."

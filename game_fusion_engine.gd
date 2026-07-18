extends RefCounted
class_name GameFusionEngine

# Motor puro para decisiones de fusiones y bonus por creación.

static func bonus_enabled(global_enabled: bool, target_unlocked_before_chain: bool) -> bool:
	return global_enabled and target_unlocked_before_chain

static func bonus_amount_for_target(
	fused_result_value: int,
	trigger_value: int,
	on_board_target_count: int,
	near_cap_count: int,
	full_amount: int,
	reduced_amount: int,
	is_bonus_enabled: bool
) -> int:
	if not is_bonus_enabled:
		return 0
	if trigger_value < 1:
		return 0
	if fused_result_value != trigger_value:
		return 0
	return reduced_amount if on_board_target_count >= near_cap_count else full_amount

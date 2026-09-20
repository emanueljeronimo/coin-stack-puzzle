class_name BoardMetricsService
extends RefCounted

static func count_total_free_slots(stacks: Array) -> int:
	var total := 0
	for stack in stacks:
		if stack != null and stack.has_method("free_slots"):
			total += int(stack.free_slots())
	return total

static func count_legal_moves(stacks: Array) -> int:
	var legal_moves := 0
	for i in range(stacks.size()):
		for j in range(stacks.size()):
			if i == j:
				continue
			if stacks[i].is_empty():
				continue
			if stacks[j].can_receive_value(stacks[i].top_value()):
				legal_moves += 1
	return legal_moves

extends RefCounted
class_name BoardPlayBotService

## Simulador greedy headless: reparte, mueve bloques iguales y fusiona.
## Sirve para estresar prestige / late game sin abrir el editor.

const GameEngineScript = preload("res://game_engine.gd")
const GameTurnEngineScript = preload("res://game_turn_engine.gd")
const GameRulesScript = preload("res://game_rules.gd")

const STACK_CAP := 10
const FUSION_OUT := 2
const CHECKPOINT_BASE := 5

static func prestige_state(milestone: int, checkpoint_level: int) -> Dictionary:
	var origin: int = GameEngineScript.cycle_checkpoint_origin(milestone, checkpoint_level)
	var floor_v: int = GameEngineScript.cycle_reset_roll_value_floor(milestone, CHECKPOINT_BASE)
	var max_v: int = GameEngineScript.cycle_reset_max_value(milestone)
	var stacks: Array = []
	for _i in range(5):
		stacks.append([])
	return {
		"stacks": stacks,
		"active_stacks": 5,
		"checkpoint_level": checkpoint_level,
		"cycle_checkpoint_origin": origin,
		"roll_value_floor": floor_v,
		"max_value": max_v,
		"board_deal_count": 0,
		"next_free_slot_unlock_level": GameRulesScript.first_future_play_unlock_level(
			origin,
			checkpoint_level
		),
	}

static func play_level(state: Dictionary) -> int:
	return GameEngineScript.cycle_play_level(
		int(state.get("checkpoint_level", 1)),
		int(state.get("cycle_checkpoint_origin", 0))
	)

static func deal_max_value(state: Dictionary) -> int:
	var floor_v: int = int(state.get("roll_value_floor", 1))
	var max_roll: int = maxi(floor_v, int(state.get("max_value", 5)) - 1)
	return GameTurnEngineScript.early_roll_value_max(
		play_level(state),
		int(state.get("board_deal_count", 0)),
		floor_v,
		max_roll
	)

static func unique_values(state: Dictionary) -> int:
	var seen := {}
	for stack in state.get("stacks", []):
		if not stack is Array:
			continue
		for raw in stack:
			var v := int(raw)
			if v > 0:
				seen[v] = true
	return seen.size()

static func highest_coin(state: Dictionary) -> int:
	var hi := 0
	for stack in state.get("stacks", []):
		if not stack is Array:
			continue
		for raw in stack:
			hi = maxi(hi, int(raw))
	return hi

static func free_slots_total(state: Dictionary) -> int:
	var free := 0
	for stack in state.get("stacks", []):
		if stack is Array:
			free += maxi(0, STACK_CAP - stack.size())
	return free

static func _top_value(stack: Array) -> int:
	if stack.is_empty():
		return -1
	return int(stack[stack.size() - 1])

static func _top_block_size(stack: Array) -> int:
	if stack.is_empty():
		return 0
	var top: int = _top_value(stack)
	var n := 0
	var i: int = stack.size() - 1
	while i >= 0 and int(stack[i]) == top:
		n += 1
		i -= 1
	return n

static func _try_fuse(state: Dictionary) -> bool:
	var stacks: Array = state.get("stacks", [])
	for si in range(stacks.size()):
		var stack: Array = stacks[si]
		if stack.size() < STACK_CAP:
			continue
		var v: int = int(stack[0])
		var homo := true
		for raw in stack:
			if int(raw) != v or v <= 0:
				homo = false
				break
		if not homo:
			continue
		stack.clear()
		var nxt: int = v + 1
		for _j in range(FUSION_OUT):
			stack.append(nxt)
		state["max_value"] = maxi(int(state.get("max_value", 1)), nxt)
		return true
	return false

static func _try_move(state: Dictionary) -> bool:
	var stacks: Array = state.get("stacks", [])
	var best_from := -1
	var best_to := -1
	var best_size := 0
	for src in range(stacks.size()):
		var from_stack: Array = stacks[src]
		var block: int = _top_block_size(from_stack)
		if block <= 0:
			continue
		var val: int = _top_value(from_stack)
		for dst in range(stacks.size()):
			if dst == src:
				continue
			var to_stack: Array = stacks[dst]
			if to_stack.size() + block > STACK_CAP:
				continue
			var top: int = _top_value(to_stack)
			var ok: bool = top < 0 or top == val
			if ok and block > best_size:
				best_size = block
				best_from = src
				best_to = dst
	if best_from < 0:
		return false
	var src_stack: Array = stacks[best_from]
	var dst_stack: Array = stacks[best_to]
	var moved: Array = src_stack.slice(src_stack.size() - best_size, src_stack.size())
	src_stack.resize(src_stack.size() - best_size)
	for raw in moved:
		dst_stack.append(raw)
	return true

static func _deal(state: Dictionary, rng: RandomNumberGenerator) -> bool:
	var free: int = free_slots_total(state)
	if free <= 0:
		return false
	var floor_v: int = int(state.get("roll_value_floor", 1))
	var dmax: int = deal_max_value(state)
	var values: Array = GameTurnEngineScript.build_roll_values(
		floor_v,
		dmax,
		func() -> int:
			return rng.randi_range(0, 2)
	)
	values.shuffle()
	var count: int = GameTurnEngineScript.compute_level_roll_count(
		play_level(state),
		values.size(),
		free,
		true
	)
	if count <= 0:
		return false
	var stacks: Array = state.get("stacks", [])
	var placed := 0
	for vi in range(mini(count, values.size())):
		var val: int = int(values[vi])
		var put := false
		for stack in stacks:
			if stack is Array and stack.size() < STACK_CAP and (_top_value(stack) == val or stack.is_empty()):
				stack.append(val)
				put = true
				placed += 1
				break
		if put:
			continue
		for stack in stacks:
			if stack is Array and stack.size() < STACK_CAP:
				stack.append(val)
				placed += 1
				break
	state["board_deal_count"] = int(state.get("board_deal_count", 0)) + 1
	return placed > 0

static func step(state: Dictionary, rng: RandomNumberGenerator) -> String:
	if _try_fuse(state):
		return "fuse"
	if _try_move(state):
		return "move"
	if _deal(state, rng):
		return "deal"
	return "stuck"

static func run(state: Dictionary, max_steps: int, seed_value: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	seed(seed_value)
	var stuck := false
	var steps := 0
	var last := ""
	while steps < max_steps:
		last = step(state, rng)
		steps += 1
		if last == "stuck":
			stuck = true
			break
	return {
		"steps": steps,
		"stuck": stuck,
		"last": last,
		"highest": highest_coin(state),
		"unique": unique_values(state),
		"active_stacks": int(state.get("active_stacks", 0)),
		"deal_max": deal_max_value(state),
		"play_level": play_level(state),
		"floor": int(state.get("roll_value_floor", 0)),
		"max_value": int(state.get("max_value", 0)),
		"next_unlock": int(state.get("next_free_slot_unlock_level", 0)),
	}

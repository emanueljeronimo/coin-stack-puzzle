extends RefCounted
class_name GameRules

# Reglas de motor centralizadas (data-driven) para no mezclar criterio de juego con UI.
const TEMP_SLOT_ACTIONS_TO_CLOSE := 3
const TEMP_SLOT_CLOSE_BY_ACTIONS := false
const ENABLE_FUSION_CREATE_BONUS := false
## Al completar 10 iguales, se crean esta cantidad de fichas del valor siguiente.
const FUSION_OUTPUT_COUNT := 2

const ADJACENT_SLOT_FREE_FIRST_LEVEL := 4
const ADJACENT_SLOT_FREE_LEVEL_INTERVAL := 2

static func initial_free_slot_unlock_level(cycle_base_level: int) -> int:
	return cycle_base_level + ADJACENT_SLOT_FREE_FIRST_LEVEL

static func next_free_slot_unlock_level(current_unlock_level: int) -> int:
	return current_unlock_level + ADJACENT_SLOT_FREE_LEVEL_INTERVAL

## Próximo hito gratis estrictamente posterior a reached_level (sin desbloqueo retroactivo).
static func advance_free_slot_unlock_past_level(current_unlock_level: int, reached_level: int) -> int:
	var unlock := current_unlock_level
	if unlock <= 0:
		unlock = ADJACENT_SLOT_FREE_FIRST_LEVEL
	var guard := 0
	while unlock <= reached_level and guard < 64:
		unlock = next_free_slot_unlock_level(unlock)
		guard += 1
	return unlock

## Primer hito gratis del ciclo que todavía no se alcanzó.
static func first_future_free_slot_unlock_level(cycle_base_level: int, reached_level: int) -> int:
	return advance_free_slot_unlock_past_level(
		initial_free_slot_unlock_level(cycle_base_level),
		reached_level
	)

## Quita ranuras gratis adelantadas por un checkpoint inflado (p.ej. 21→23).
## Si el cursor quedó más adelante de lo que el nivel actual permite, deshace esos grants.
static func heal_inflated_cycle_free_slots(
	active_stacks: int,
	next_free_slot_unlock_level: int,
	checkpoint_level: int,
	cycle_base_level: int,
	cycle_reset_stacks: int
) -> Dictionary:
	var expected_unlock := first_future_free_slot_unlock_level(cycle_base_level, checkpoint_level)
	var stacks := active_stacks
	var unlock := next_free_slot_unlock_level
	var changed := false
	while stacks > cycle_reset_stacks and unlock > expected_unlock:
		stacks -= 1
		unlock -= ADJACENT_SLOT_FREE_LEVEL_INTERVAL
		changed = true
	return {
		"changed": changed,
		"active_stacks": stacks,
		"next_free_slot_unlock_level": unlock,
	}

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

## Mezclar: desarma todo, cuenta fichas/espacios, opcionalmente colapsa fusiones de 10 y
## recoloca 1 color por pila siempre que quepa. Si no alcanzan ranuras, maximiza
## pilas homogéneas y concentra el resto en la menor cantidad de pilas mixtas.
## collapse_fusions=false: tirada/apertura inicial (mantiene los valores tal cual).
static func build_mix_stack_plan(
	all_values: Array,
	stack_count: int,
	capacity: int = 10,
	collapse_fusions: bool = true
) -> Array:
	var plan: Array = []
	for _i in range(maxi(0, stack_count)):
		plan.append([])
	if stack_count <= 0 or all_values.is_empty() or capacity <= 0:
		return plan

	var counts := _mix_count_values(all_values)
	# Omnipotente: 10 iguales → FUSION_OUTPUT_COUNT del siguiente valor.
	if collapse_fusions:
		counts = _mix_collapse_fusions(counts, capacity)

	var total_coins := 0
	for v in counts.keys():
		total_coins += int(counts[v])
	var total_spaces := stack_count * capacity
	if total_coins > total_spaces:
		push_error(
			"Mix: %d fichas no caben en %d espacios (%d pilas x %d)"
			% [total_coins, total_spaces, stack_count, capacity]
		)

	var chunks: Array = _mix_build_chunks(counts, capacity)
	if chunks.is_empty():
		return plan

	# Camino perfecto: un chunk = una pila homogénea.
	if chunks.size() <= stack_count:
		for i in range(chunks.size()):
			plan[i] = chunks[i]
		return plan

	# Ordenar chunks grandes primero.
	chunks.sort_custom(func(a, b):
		var sa := (a as Array).size()
		var sb := (b as Array).size()
		if sa != sb:
			return sa > sb
		return int((a as Array)[0]) < int((b as Array)[0])
	)

	# Guardar chunks puros mientras el resto siga cabiendo en las ranuras restantes.
	var si := 0
	var coins_left := total_coins
	var stacks_left := stack_count
	var overflow: Array = []
	for chunk in chunks:
		var chunk_arr: Array = chunk
		var chunk_size := chunk_arr.size()
		var rest := coins_left - chunk_size
		var stacks_after := stacks_left - 1
		if (
			si < stack_count
			and stacks_after >= 0
			and rest <= stacks_after * capacity
		):
			plan[si] = chunk_arr.duplicate()
			si += 1
			stacks_left -= 1
			coins_left -= chunk_size
		else:
			for raw in chunk_arr:
				overflow.append(int(raw))

	overflow.sort()
	var oi := 0
	while oi < overflow.size() and si < stack_count:
		var room := capacity - (plan[si] as Array).size()
		if room <= 0:
			si += 1
			continue
		var put := mini(room, overflow.size() - oi)
		for _j in range(put):
			(plan[si] as Array).append(int(overflow[oi]))
			oi += 1
		if (plan[si] as Array).size() >= capacity:
			si += 1

	if oi < overflow.size():
		push_error("Mix: sobraron %d fichas sin colocar" % (overflow.size() - oi))

	return plan

static func _mix_count_values(all_values: Array) -> Dictionary:
	var counts: Dictionary = {}
	for raw in all_values:
		var v := int(raw)
		counts[v] = int(counts.get(v, 0)) + 1
	return counts

## 10 del valor V → FUSION_OUTPUT_COUNT del valor V+1, en cascada hasta estabilizar.
static func _mix_collapse_fusions(counts: Dictionary, capacity: int = 10) -> Dictionary:
	var out: Dictionary = counts.duplicate()
	var guard := 0
	var changed := true
	while changed and guard < 1000:
		changed = false
		guard += 1
		var keys: Array = out.keys()
		keys.sort()
		for v in keys:
			var c := int(out.get(v, 0))
			if c < capacity:
				continue
			var fused := int(c / capacity)
			var rem := c % capacity
			if rem > 0:
				out[v] = rem
			else:
				out.erase(v)
			var nxt := int(v) + 1
			out[nxt] = int(out.get(nxt, 0)) + fused * FUSION_OUTPUT_COUNT
			changed = true
	return out

static func _mix_build_chunks(counts: Dictionary, capacity: int) -> Array:
	var values: Array = counts.keys()
	values.sort_custom(func(a, b):
		var ca := int(counts[a])
		var cb := int(counts[b])
		if ca != cb:
			return ca > cb
		return int(a) < int(b)
	)
	var chunks: Array = []
	for v in values:
		var left := int(counts[v])
		while left > 0:
			var put := mini(left, capacity)
			var chunk: Array = []
			for _j in range(put):
				chunk.append(int(v))
			chunks.append(chunk)
			left -= put
	return chunks
 
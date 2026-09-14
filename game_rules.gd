extends RefCounted
class_name GameRules

# Reglas de motor centralizadas (data-driven) para no mezclar criterio de juego con UI.
const TEMP_SLOT_ACTIONS_TO_CLOSE := 3
const TEMP_SLOT_CLOSE_BY_ACTIONS := false
const ENABLE_FUSION_CREATE_BONUS := false
## Al completar 10 iguales, se crean esta cantidad de fichas del valor siguiente.
const FUSION_OUTPUT_COUNT := 2
## Una sola tirada por repartida: 10% de chance de incluir exactamente 1 comodín.
const WILDCARD_ROUND_CHANCE := 0.10
const COIN_WILDCARD_VALUE := 0

const ADJACENT_SLOT_FREE_FIRST_LEVEL := 2
const ADJACENT_SLOT_FREE_LEVEL_INTERVAL := 2
## Desde este nivel (inclusive) el gratis pasa a cada 3; desde 100, cada 4.
const ADJACENT_SLOT_INTERVAL_3_FROM_LEVEL := 50
const ADJACENT_SLOT_INTERVAL_4_FROM_LEVEL := 100
const ADJACENT_SLOT_FREE_INTERVAL_MID := 3
const ADJACENT_SLOT_FREE_INTERVAL_LATE := 4
const _UNLOCK_WALK_GUARD := 128

static func is_coin_wildcard_value(value: int) -> bool:
	return int(value) == COIN_WILDCARD_VALUE

static func coin_value_from_board_row(board_row_index: int) -> int:
	return maxi(1, int(board_row_index) + 1)

static func even_free_slot_unlock_level(level: int) -> int:
	return normalize_free_slot_unlock_level(level)

static func normalize_free_slot_unlock_level(level: int) -> int:
	var v := maxi(level, ADJACENT_SLOT_FREE_FIRST_LEVEL)
	if v < ADJACENT_SLOT_INTERVAL_3_FROM_LEVEL and v % 2 != 0:
		v += 1
	return v

static func free_slot_unlock_interval_after(unlock_level: int) -> int:
	if unlock_level >= ADJACENT_SLOT_INTERVAL_4_FROM_LEVEL:
		return ADJACENT_SLOT_FREE_INTERVAL_LATE
	if unlock_level >= ADJACENT_SLOT_INTERVAL_3_FROM_LEVEL:
		return ADJACENT_SLOT_FREE_INTERVAL_MID
	return ADJACENT_SLOT_FREE_LEVEL_INTERVAL

static func initial_free_slot_unlock_level(cycle_base_level: int) -> int:
	return normalize_free_slot_unlock_level(cycle_base_level + ADJACENT_SLOT_FREE_FIRST_LEVEL)

static func next_free_slot_unlock_level(current_unlock_level: int) -> int:
	var base := normalize_free_slot_unlock_level(current_unlock_level)
	if current_unlock_level < ADJACENT_SLOT_INTERVAL_3_FROM_LEVEL and current_unlock_level % 2 != 0:
		return base
	var nxt := base + free_slot_unlock_interval_after(base)
	if base < ADJACENT_SLOT_INTERVAL_4_FROM_LEVEL and nxt > ADJACENT_SLOT_INTERVAL_4_FROM_LEVEL:
		return ADJACENT_SLOT_INTERVAL_4_FROM_LEVEL
	return nxt

static func previous_free_slot_unlock_level(unlock_level: int) -> int:
	var n := normalize_free_slot_unlock_level(unlock_level)
	if n <= ADJACENT_SLOT_FREE_FIRST_LEVEL:
		return n
	if n > ADJACENT_SLOT_INTERVAL_4_FROM_LEVEL:
		return n - ADJACENT_SLOT_FREE_INTERVAL_LATE
	if n == ADJACENT_SLOT_INTERVAL_4_FROM_LEVEL:
		return n - 2
	if n > ADJACENT_SLOT_INTERVAL_3_FROM_LEVEL:
		return n - ADJACENT_SLOT_FREE_INTERVAL_MID
	return n - ADJACENT_SLOT_FREE_LEVEL_INTERVAL

## Próximo hito gratis estrictamente posterior a reached_level (sin desbloqueo retroactivo).
static func advance_free_slot_unlock_past_level(current_unlock_level: int, reached_level: int) -> int:
	var unlock := normalize_free_slot_unlock_level(current_unlock_level)
	var guard := 0
	while unlock <= reached_level and guard < _UNLOCK_WALK_GUARD:
		unlock = next_free_slot_unlock_level(unlock)
		guard += 1
	return unlock

## Primer hito gratis del ciclo que todavía no se alcanzó.
static func first_future_free_slot_unlock_level(cycle_base_level: int, reached_level: int) -> int:
	return advance_free_slot_unlock_past_level(
		initial_free_slot_unlock_level(cycle_base_level),
		reached_level
	)

## Cuántas ranuras gratis del ciclo actual ya se ganaron (p.ej. 42 y 44 a nivel 44 → 2).
static func earned_cycle_free_slot_count(
	cycle_base_level: int,
	prestige_level: int,
	checkpoint_level: int
) -> int:
	var first := first_future_free_slot_unlock_level(
		cycle_base_level,
		maxi(prestige_level, cycle_base_level)
	)
	var earned := 0
	var unlock := first
	var guard := 0
	while unlock <= checkpoint_level and guard < _UNLOCK_WALK_GUARD:
		earned += 1
		unlock = next_free_slot_unlock_level(unlock)
		guard += 1
	return earned

## Si el cursor saltó un hito (42→46 a nivel 44) sin abrir la ranura, indica cuántas faltan.
static func missed_cycle_free_slot_grants(
	active_stacks: int,
	checkpoint_level: int,
	cycle_base_level: int,
	prestige_level: int,
	cycle_reset_stacks: int
) -> Dictionary:
	var earned := earned_cycle_free_slot_count(
		cycle_base_level, prestige_level, checkpoint_level
	)
	var expected_stacks := cycle_reset_stacks + earned
	var expected_unlock := first_future_free_slot_unlock_level(cycle_base_level, checkpoint_level)
	var missing := maxi(0, expected_stacks - active_stacks)
	return {
		"changed": missing > 0,
		"missing": missing,
		"expected_stacks": expected_stacks,
		"next_free_slot_unlock_level": expected_unlock,
	}

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
		unlock = previous_free_slot_unlock_level(unlock)
		changed = true
	if changed and unlock != expected_unlock:
		unlock = expected_unlock
	return {
		"changed": changed,
		"active_stacks": stacks,
		"next_free_slot_unlock_level": unlock,
	}

## Tablero de prestige otra vez (objetivo 15, sin ficha 16) pero con ranuras/nivel de más adelante.
## Tras un wipe de fichas 17→14, vuelve a 5 ranuras y a la 6ª en el primer hito (22).
static func heal_prestige_start_desync(state: Dictionary) -> Dictionary:
	var max_value := int(state.get("max_value", 0))
	var highest := int(state.get("highest_board_coin", 0))
	var milestone := int(state.get("milestone_level", 0))
	var checkpoint_level := int(state.get("checkpoint_level", 1))
	var active_stacks := int(state.get("active_stacks", 1))
	var next_free := int(state.get("next_free_slot_unlock_level", 1))
	var prestige_level := int(state.get("prestige_level", milestone))
	var cycle_reset_stacks := int(state.get("cycle_reset_stacks", 5))
	var price := int(state.get("adjacent_slot_next_price", 0))
	var base_price := int(state.get("adjacent_slot_base_price", 0))
	var result := {
		"changed": false,
		"checkpoint_level": checkpoint_level,
		"active_stacks": active_stacks,
		"next_free_slot_unlock_level": next_free,
	}
	if milestone <= 0:
		return result
	if max_value > milestone or highest >= milestone + 1:
		return result
	if base_price > 0 and price > base_price:
		return result
	var expected_unlock := first_future_free_slot_unlock_level(milestone, prestige_level)
	var changed := false
	if active_stacks > cycle_reset_stacks:
		active_stacks = cycle_reset_stacks
		changed = true
	if next_free != expected_unlock:
		next_free = expected_unlock
		changed = true
	if checkpoint_level > prestige_level:
		checkpoint_level = prestige_level
		changed = true
	result["changed"] = changed
	result["checkpoint_level"] = checkpoint_level
	result["active_stacks"] = active_stacks
	result["next_free_slot_unlock_level"] = next_free
	return result

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
	# Una generación: 10 iguales → FUSION_OUTPUT_COUNT del siguiente. Encadenar
	# 4→8 en el mismo Mezclar saltaba del nivel 1 al 8/9 (sobre todo en móvil).
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

	var leftover_counts := counts.duplicate()
	var remaining_stacks := stack_count
	var exclusive_coins: Dictionary = {}
	var values_by_count: Array = leftover_counts.keys()
	values_by_count.sort_custom(func(a, b):
		var ca := int(leftover_counts[a])
		var cb := int(leftover_counts[b])
		if ca != cb:
			return ca > cb
		return int(a) < int(b)
	)
	var stacks_needed := 0
	for v in leftover_counts.keys():
		stacks_needed += _mix_ceil_div(int(leftover_counts[v]), capacity)
	# Camino simple: cada número cabe en sus propias pilas. Cero mezclas.
	if stacks_needed <= stack_count:
		var ordered: Array = leftover_counts.keys()
		ordered.sort_custom(func(a, b): return int(a) < int(b))
		var pi := 0
		for v in ordered:
			var left := int(leftover_counts[v])
			while left > 0 and pi < stack_count:
				var put := mini(left, capacity)
				for _j in range(put):
					(plan[pi] as Array).append(int(v))
				left -= put
				pi += 1
		_mix_sort_plan_stacks(plan)
		return plan
	# Un número por pila(s). No rechazar un grupo porque "desperdicia" huecos:
	# 7 iguales en una ranura de 10 es correcto; mezclarlos no.
	for v in values_by_count:
		var n := int(leftover_counts.get(v, 0))
		if n <= 0 or remaining_stacks <= 0:
			continue
		var need := _mix_ceil_div(n, capacity)
		if need <= 0:
			continue
		var take := mini(need, remaining_stacks)
		var placed_n := mini(n, take * capacity)
		exclusive_coins[int(v)] = int(exclusive_coins.get(int(v), 0)) + placed_n
		leftover_counts[v] = n - placed_n
		remaining_stacks -= take

	var si := 0
	var exclusive_values: Array = exclusive_coins.keys()
	exclusive_values.sort()
	for v in exclusive_values:
		var left := int(exclusive_coins[v])
		while left > 0 and si < stack_count:
			var room := capacity - (plan[si] as Array).size()
			if room <= 0:
				si += 1
				continue
			var put := mini(room, left)
			for _j in range(put):
				(plan[si] as Array).append(int(v))
			left -= put
			if (plan[si] as Array).size() >= capacity:
				si += 1

	var overflow: Array = []
	var overflow_keys: Array = leftover_counts.keys()
	overflow_keys.sort_custom(func(a, b):
		var ca := int(leftover_counts[a])
		var cb := int(leftover_counts[b])
		if ca != cb:
			return ca > cb
		return int(a) < int(b)
	)
	for v in overflow_keys:
		for _j in range(int(leftover_counts[v])):
			overflow.append(int(v))
	_mix_fill_overflow_by_value(plan, overflow, si, stack_count, capacity)
	for i in range(plan.size()):
		plan[i] = _mix_clustered_stack(plan[i])
	_mix_sort_plan_stacks(plan)
	return plan

## Mezclar del comodín: agrupa por número y convierte cada pila de 10.
## Después de juntar los fusionados, si vuelve a haber 10 iguales, también se
## convierten. No sigue después de eso (evita 4→8 en un solo uso).
static func build_wildcard_mix_plan(
	all_values: Array,
	stack_count: int,
	capacity: int = 10
) -> Array:
	var plan: Array = build_mix_stack_plan(all_values, stack_count, capacity, false)
	plan = _mix_fuse_full_stacks(plan, capacity)
	plan = build_mix_stack_plan(_mix_flatten_plan(plan), stack_count, capacity, false)
	plan = _mix_fuse_full_stacks(plan, capacity)
	return build_mix_stack_plan(_mix_flatten_plan(plan), stack_count, capacity, false)

static func _mix_flatten_plan(plan: Array) -> Array:
	var all_values: Array = []
	for segment in plan:
		for raw in segment:
			all_values.append(int(raw))
	return all_values

static func _mix_fuse_full_stacks(plan: Array, capacity: int) -> Array:
	var out: Array = []
	for segment in plan:
		var arr: Array = (segment as Array).duplicate()
		if (
			arr.size() >= capacity
			and not _mix_stack_is_mixed(arr)
			and int(arr[0]) > 0
		):
			var nxt := int(arr[0]) + 1
			var fused: Array = []
			for _i in range(FUSION_OUTPUT_COUNT):
				fused.append(nxt)
			out.append(fused)
		else:
			out.append(arr)
	return out

static func _mix_count_values(all_values: Array) -> Dictionary:
	var counts: Dictionary = {}
	for raw in all_values:
		var v := int(raw)
		counts[v] = int(counts.get(v, 0)) + 1
	return counts

static func _mix_ceil_div(n: int, d: int) -> int:
	if d <= 0:
		return 0
	return int((maxi(0, n) + d - 1) / d)

static func _mix_append_value(slot: Array, value: int, amount: int) -> void:
	for _j in range(maxi(0, amount)):
		slot.append(int(value))

static func _mix_stack_is_mixed(slot: Array) -> bool:
	if slot.size() <= 1:
		return false
	var first := int(slot[0])
	for raw in slot:
		if int(raw) != first:
			return true
	return false

static func _mix_stack_is_pure_value(slot: Array, value: int) -> bool:
	if slot.is_empty():
		return false
	for raw in slot:
		if int(raw) != int(value):
			return false
	return true

## Sobrantes por valor: completar pilas de ese número, luego ranuras vacías. Mezclar al final.
static func _mix_fill_overflow_by_value(
	plan: Array,
	overflow: Array,
	start_index: int,
	stack_count: int,
	capacity: int
) -> void:
	if overflow.is_empty():
		return
	if start_index >= stack_count:
		_mix_dump_remainders(plan, overflow, 0, stack_count, capacity)
		return
	var groups := _mix_count_values(overflow)
	var values: Array = groups.keys()
	values.sort_custom(func(a, b):
		var ca := int(groups[a])
		var cb := int(groups[b])
		if ca != cb:
			return ca > cb
		return int(a) < int(b)
	)
	var leftover: Dictionary = {}
	for v in values:
		var left := int(groups[v])
		for di in range(start_index, stack_count):
			if left <= 0:
				break
			var slot: Array = plan[di]
			var room := capacity - slot.size()
			if room <= 0:
				continue
			if not _mix_stack_is_pure_value(slot, int(v)):
				continue
			var put := mini(room, left)
			_mix_append_value(plan[di], int(v), put)
			left -= put
		for di in range(start_index, stack_count):
			if left <= 0:
				break
			var slot: Array = plan[di]
			if not slot.is_empty():
				continue
			var put := mini(capacity, left)
			_mix_append_value(plan[di], int(v), put)
			left -= put
		if left > 0:
			leftover[int(v)] = left
	if leftover.is_empty():
		return
	var rem: Array = []
	var leftover_keys: Array = leftover.keys()
	leftover_keys.sort()
	for v in leftover_keys:
		for _j in range(int(leftover[v])):
			rem.append(int(v))
	_mix_dump_remainders(plan, rem, 0, stack_count, capacity)

static func _mix_dump_remainders(
	plan: Array,
	remainders: Array,
	start_index: int,
	stack_count: int,
	capacity: int
) -> void:
	var oi := 0
	while oi < remainders.size():
		var best_i := -1
		var best_score := 1 << 30
		for di in range(start_index, stack_count):
			var slot: Array = plan[di]
			if slot.size() >= capacity:
				continue
			var score := _mix_remainder_slot_score(slot, int(remainders[oi]))
			if score < best_score:
				best_score = score
				best_i = di
		if best_i < 0:
			push_error("Mix: sobraron %d fichas sin colocar" % (remainders.size() - oi))
			return
		(plan[best_i] as Array).append(int(remainders[oi]))
		oi += 1


## Menor score = mejor destino. No completar una pila pura con otro número si hay alternativa.
static func _mix_remainder_slot_score(slot: Array, value: int) -> int:
	if slot.is_empty():
		return 500
	if _mix_stack_is_pure_value(slot, value):
		return 100 + slot.size()
	if _mix_stack_is_mixed(slot):
		return slot.size()
	return 10000 + slot.size()

## En pilas mixtas, agrupa por número y deja el bloque más grande arriba (se puede mover).
static func _mix_clustered_stack(slot: Array) -> Array:
	if slot.size() <= 1 or not _mix_stack_is_mixed(slot):
		return slot
	var counts := _mix_count_values(slot)
	var keys: Array = counts.keys()
	keys.sort_custom(func(a, b):
		var ca := int(counts[a])
		var cb := int(counts[b])
		if ca != cb:
			return ca < cb
		return int(a) < int(b)
	)
	var out: Array = []
	for v in keys:
		_mix_append_value(out, int(v), int(counts[v]))
	return out

static func _mix_sort_plan_stacks(plan: Array) -> void:
	plan.sort_custom(func(a, b):
		var aa := a as Array
		var bb := b as Array
		var a_empty := aa.is_empty()
		var b_empty := bb.is_empty()
		if a_empty != b_empty:
			return b_empty
		if a_empty:
			return false
		var a_mix := _mix_stack_is_mixed(aa)
		var b_mix := _mix_stack_is_mixed(bb)
		if a_mix != b_mix:
			return b_mix
		var a_key := int(aa[aa.size() - 1])
		var b_key := int(bb[bb.size() - 1])
		if a_key != b_key:
			return a_key < b_key
		return aa.size() > bb.size()
	)

## 10 del valor V → FUSION_OUTPUT_COUNT del valor V+1. Solo los grupos que ya
## existían; el resultado no se vuelve a fusionar en el mismo paso.
static func _mix_collapse_fusions(counts: Dictionary, capacity: int = 10) -> Dictionary:
	var out: Dictionary = counts.duplicate()
	var keys: Array = counts.keys()
	keys.sort()
	for v in keys:
		if is_coin_wildcard_value(int(v)):
			continue
		var c := int(counts.get(v, 0))
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
 
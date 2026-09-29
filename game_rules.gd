extends RefCounted
class_name GameRules

# Reglas de motor centralizadas (data-driven) para no mezclar criterio de juego con UI.
const TEMP_SLOT_ACTIONS_TO_CLOSE := 3
const TEMP_SLOT_CLOSE_BY_ACTIONS := false
const ENABLE_FUSION_CREATE_BONUS := false
## Al completar 10 iguales, se crean esta cantidad de fichas del valor siguiente.
const FUSION_OUTPUT_COUNT := 2
## Una sola tirada por repartida: 10% de chance de incluir exactamente 1 comodin.
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
	var chunks: Array = _mix_build_chunks(leftover_counts, capacity)
	var guard := 0
	while chunks.size() > stack_count and guard < 64:
		guard += 1
		if not _mix_pour_smallest_chunk(chunks, capacity):
			break
	for i in range(mini(chunks.size(), stack_count)):
		plan[i] = chunks[i]
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
	var numbered: Array = []
	var wildcard_n := 0
	for raw in all_values:
		if is_coin_wildcard_value(int(raw)):
			wildcard_n += 1
		else:
			numbered.append(int(raw))
	var plan: Array = build_mix_stack_plan(numbered, stack_count, capacity, false)
	plan = _mix_fuse_full_stacks(plan, capacity)
	plan = build_mix_stack_plan(_mix_flatten_plan(plan), stack_count, capacity, false)
	plan = _mix_fuse_full_stacks(plan, capacity)
	plan = build_mix_stack_plan(_mix_flatten_plan(plan), stack_count, capacity, false)
	_mix_place_wildcards(plan, wildcard_n, capacity)
	return plan

## Los 0 (ficha estrella) no se mezclan con números: van a ranuras vacías.
static func _mix_place_wildcards(plan: Array, amount: int, capacity: int) -> void:
	var left := maxi(0, amount)
	if left <= 0 or plan.is_empty() or capacity <= 0:
		return
	for round_idx in range(2):
		for i in range(plan.size()):
			if left <= 0:
				_mix_sort_plan_stacks(plan)
				return
			var slot: Array = plan[i]
			var room := capacity - slot.size()
			if room <= 0:
				continue
			var can_fill := slot.is_empty()
			if round_idx == 0:
				can_fill = slot.is_empty() or _mix_stack_is_pure_value(slot, COIN_WILDCARD_VALUE)
			if not can_fill:
				continue
			var put := mini(room, left)
			_mix_append_value(slot, COIN_WILDCARD_VALUE, put)
			plan[i] = slot
			left -= put
	if left <= 0:
		_mix_sort_plan_stacks(plan)
		return
	var star_dump: Array = []
	for _j in range(left):
		star_dump.append(COIN_WILDCARD_VALUE)
	_mix_dump_remainders(plan, star_dump, 0, plan.size(), capacity)
	_mix_sort_plan_stacks(plan)

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

static func _mix_absorb_into_matching_pures(
	plan: Array,
	overflow: Array,
	capacity: int
) -> Array:
	if overflow.is_empty() or capacity <= 0:
		return overflow
	var groups := _mix_count_values(overflow)
	var remaining: Array = []
	var keys: Array = groups.keys()
	keys.sort()
	for v in keys:
		var left := int(groups[v])
		for slot in plan:
			if left <= 0:
				break
			var arr: Array = slot
			if not _mix_stack_is_pure_value(arr, int(v)):
				continue
			var room := capacity - arr.size()
			if room <= 0:
				continue
			var put := mini(room, left)
			_mix_append_value(arr, int(v), put)
			left -= put
		for _j in range(left):
			remaining.append(int(v))
	return remaining

static func _mix_pack_into_empty_slots(plan: Array, overflow: Array, capacity: int) -> void:
	if overflow.is_empty() or capacity <= 0:
		return
	var oi := 0
	for i in range(plan.size()):
		if oi >= overflow.size():
			break
		var slot: Array = plan[i]
		if not slot.is_empty():
			continue
		var put := mini(capacity, overflow.size() - oi)
		for _j in range(put):
			slot.append(int(overflow[oi]))
			oi += 1
		plan[i] = _mix_clustered_stack(slot)
	if oi <= 0:
		return
	for _k in range(oi):
		overflow.remove_at(0)

static func _mix_dump_slot_score(slot: Array, room: int) -> int:
	if _mix_stack_is_mixed(slot):
		return 100 - room
	if slot.is_empty():
		return 1000 - room
	return 10000 - room
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
			var room := capacity - slot.size()
			if room <= 0:
				continue
			var score := _mix_dump_slot_score(slot, room)
			if score < best_score:
				best_score = score
				best_i = di
		if best_i < 0:
			push_error("Mix: sobraron %d fichas sin colocar" % (remainders.size() - oi))
			return
		var dest: Array = plan[best_i]
		var room := capacity - dest.size()
		var put := mini(room, remainders.size() - oi)
		for _j in range(put):
			dest.append(int(remainders[oi]))
			oi += 1
		plan[best_i] = dest


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
		var ka := _mix_stack_order_key(a as Array)
		var kb := _mix_stack_order_key(b as Array)
		if ka != kb:
			return ka < kb
		return (a as Array).size() > (b as Array).size()
	)

static func _mix_stack_order_key(slot: Array) -> int:
	if slot.is_empty():
		return 1000000
	if _mix_stack_is_mixed(slot):
		return 200000 + _mix_stack_majority_value(slot)
	var v := int(slot[0])
	if is_coin_wildcard_value(v):
		return 100000
	return v

static func _mix_stack_majority_value(slot: Array) -> int:
	var counts := _mix_count_values(slot)
	var best_v := int(slot[slot.size() - 1])
	var best_n := -1
	for k in counts.keys():
		var n := int(counts[k])
		if n > best_n or (n == best_n and int(k) < best_v):
			best_n = n
			best_v = int(k)
	return best_v

static func mix_fill_order_by_slot(slot_for_index: Array, columns: int) -> Array:
	var order: Array = []
	for i in range(slot_for_index.size()):
		order.append(i)
	var cols := maxi(1, columns)
	order.sort_custom(func(a, b):
		var sa := int(slot_for_index[a])
		var sb := int(slot_for_index[b])
		var ra := int(sa / cols)
		var rb := int(sb / cols)
		if ra != rb:
			return ra < rb
		return (sa % cols) < (sb % cols)
	)
	return order

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

static func _mix_pour_smallest_chunk(chunks: Array, capacity: int) -> bool:
	if chunks.size() < 2 or capacity <= 0:
		return false
	var src_i := -1
	var src_size := 1 << 30
	for i in range(chunks.size()):
		var c: Array = chunks[i]
		if c.is_empty() or c.size() >= capacity:
			continue
		if c.size() < src_size:
			src_size = c.size()
			src_i = i
	if src_i < 0:
		return false
	var src: Array = (chunks[src_i] as Array).duplicate()
	chunks.remove_at(src_i)
	var oi := 0
	while oi < src.size():
		var best_i := -1
		var best_score := 1 << 30
		for i in range(chunks.size()):
			var slot: Array = chunks[i]
			var room := capacity - slot.size()
			if room <= 0:
				continue
			var score := _mix_dump_slot_score(slot, room)
			if score < best_score:
				best_score = score
				best_i = i
		if best_i < 0:
			chunks.append(src.slice(oi))
			return false
		var dest: Array = chunks[best_i]
		var room := capacity - dest.size()
		var put := mini(room, src.size() - oi)
		for _j in range(put):
			dest.append(int(src[oi]))
			oi += 1
		chunks[best_i] = _mix_clustered_stack(dest)
	return true

 
extends RefCounted
class_name GameRules

# Reglas de motor centralizadas (data-driven) para no mezclar criterio de juego con UI.
const TEMP_SLOT_ACTIONS_TO_CLOSE := 3
const TEMP_SLOT_CLOSE_BY_ACTIONS := false
const ENABLE_FUSION_CREATE_BONUS := false
## Al completar 10 iguales, se crean esta cantidad de fichas del valor siguiente.
const FUSION_OUTPUT_COUNT := 2

const ADJACENT_SLOT_FREE_FIRST_LEVEL := 2
const ADJACENT_SLOT_FREE_LEVEL_INTERVAL := 2

static func even_free_slot_unlock_level(level: int) -> int:
	var v := maxi(level, ADJACENT_SLOT_FREE_FIRST_LEVEL)
	if v % 2 != 0:
		v += 1
	return v

static func initial_free_slot_unlock_level(cycle_base_level: int) -> int:
	return even_free_slot_unlock_level(cycle_base_level + ADJACENT_SLOT_FREE_FIRST_LEVEL)

static func next_free_slot_unlock_level(current_unlock_level: int) -> int:
	var even := even_free_slot_unlock_level(current_unlock_level)
	if current_unlock_level % 2 != 0:
		return even
	return even + ADJACENT_SLOT_FREE_LEVEL_INTERVAL

## Próximo hito gratis estrictamente posterior a reached_level (sin desbloqueo retroactivo).
static func advance_free_slot_unlock_past_level(current_unlock_level: int, reached_level: int) -> int:
	var unlock := even_free_slot_unlock_level(current_unlock_level)
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
	while unlock <= checkpoint_level and guard < 64:
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
		unlock -= ADJACENT_SLOT_FREE_LEVEL_INTERVAL
		changed = true
	if changed and unlock % 2 != 0:
		unlock -= 1
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

	var chunks: Array = _mix_build_chunks(counts, capacity)
	if chunks.is_empty():
		return plan

	# Camino perfecto: un chunk = una pila homogénea.
	if chunks.size() <= stack_count:
		for i in range(chunks.size()):
			plan[i] = chunks[i]
		_mix_sort_plan_stacks(plan)
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

	_mix_fill_overflow_by_value(plan, overflow, si, stack_count, capacity)
	_mix_sort_plan_stacks(plan)
	return plan

static func _mix_count_values(all_values: Array) -> Dictionary:
	var counts: Dictionary = {}
	for raw in all_values:
		var v := int(raw)
		counts[v] = int(counts.get(v, 0)) + 1
	return counts

## Sobrantes por valor: una pila por número si hay ranuras vacías. Mezclar solo si no alcanzan.
static func _mix_fill_overflow_by_value(
	plan: Array,
	overflow: Array,
	start_index: int,
	stack_count: int,
	capacity: int
) -> void:
	if overflow.is_empty() or start_index >= stack_count:
		if not overflow.is_empty():
			push_error("Mix: sobraron %d fichas sin colocar" % overflow.size())
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
	var si := start_index
	var leftover: Dictionary = {}
	for v in values:
		var left := int(groups[v])
		while left > 0 and si < stack_count:
			var slot: Array = plan[si]
			var room := capacity - slot.size()
			if room <= 0:
				si += 1
				continue
			if not slot.is_empty() and int(slot[0]) != int(v):
				si += 1
				continue
			var put := mini(room, left)
			for _j in range(put):
				(plan[si] as Array).append(int(v))
			left -= put
			if (plan[si] as Array).size() >= capacity:
				si += 1
		if left > 0:
			leftover[int(v)] = left
	if leftover.is_empty():
		return
	var rem: Array = []
	var rem_keys: Array = leftover.keys()
	rem_keys.sort()
	for v in rem_keys:
		for _j in range(int(leftover[v])):
			rem.append(int(v))
	var oi := 0
	var di := start_index
	while oi < rem.size() and di < stack_count:
		var slot: Array = plan[di]
		var room := capacity - slot.size()
		if room <= 0:
			di += 1
			continue
		var put := mini(room, rem.size() - oi)
		for _j in range(put):
			(plan[di] as Array).append(int(rem[oi]))
			oi += 1
		if (plan[di] as Array).size() >= capacity:
			di += 1
	if oi < rem.size():
		push_error("Mix: sobraron %d fichas sin colocar" % (rem.size() - oi))

static func _mix_sort_plan_stacks(plan: Array) -> void:
	plan.sort_custom(func(a, b):
		var aa := a as Array
		var bb := b as Array
		if aa.is_empty() != bb.is_empty():
			return bb.is_empty()
		if aa.is_empty():
			return false
		return int(aa[0]) < int(bb[0])
	)

## 10 del valor V → FUSION_OUTPUT_COUNT del valor V+1. Solo los grupos que ya
## existían; el resultado no se vuelve a fusionar en el mismo paso.
static func _mix_collapse_fusions(counts: Dictionary, capacity: int = 10) -> Dictionary:
	var out: Dictionary = counts.duplicate()
	var keys: Array = counts.keys()
	keys.sort()
	for v in keys:
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
 
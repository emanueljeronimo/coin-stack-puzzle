extends RefCounted
class_name GameEngine

# Motor puro: reglas matemáticas de checkpoints, ciclos y progreso.
## Primer prestige en ficha 15; después cada 10 (25, 35, 45…).
const CYCLE_REPEAT_COINS := 10

static func is_cycle_coin_milestone(
	value: int,
	first_milestone: int,
	repeat_coins: int = CYCLE_REPEAT_COINS
) -> bool:
	if value < first_milestone:
		return false
	return (value - first_milestone) % repeat_coins == 0

static func last_cycle_milestone_at_or_below(
	value: int,
	first_milestone: int,
	repeat_coins: int = CYCLE_REPEAT_COINS
) -> int:
	if value < first_milestone:
		return 0
	return first_milestone + int((value - first_milestone) / repeat_coins) * repeat_coins

static func cycle_index(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	var base := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	if base <= 0:
		return 0
	return 1 + int((base - board_cycle_levels) / CYCLE_REPEAT_COINS)

static func cycle_base_level(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	if roll_value_floor <= 1:
		return 0
	var inferred := roll_value_floor + checkpoint_base_value - 1
	return last_cycle_milestone_at_or_below(inferred, board_cycle_levels)

static func cycle_coin_offset(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	var base := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	if base <= 0:
		return 0
	return base - checkpoint_base_value

## El ancla guardada solo vale en el ciclo del piso actual.
## Si no, origen 40 + piso 11 hace que un 21 cuente como 16 y suba 2 niveles de golpe.
static func effective_cycle_origin(
	cycle_origin: int,
	cycle_base: int,
	repeat_coins: int = CYCLE_REPEAT_COINS
) -> int:
	if cycle_origin <= cycle_base:
		return cycle_base
	if cycle_origin - cycle_base > repeat_coins + 6:
		return cycle_base
	return cycle_origin

## Tras el hito (15/25/35…), el piso sube: tiradas 11-14 / 21-24 / 31-34 (el hito no sale en la tirada).
static func cycle_reset_roll_value_floor(milestone_level: int, checkpoint_base_value: int) -> int:
	return maxi(1, milestone_level - checkpoint_base_value + 1)

## Objetivo del tablero nuevo = el hito que ya creaste (como el 5 del ciclo 1).
static func cycle_reset_max_value(milestone_level: int) -> int:
	return milestone_level

## Ficha de portada: no mostrar un objetivo que todavía no existe en el tablero.
## Tras prestige, max_value viejo=16 + tablero 11-14 no debe exhibir un 16.
static func cover_showcase_coin_value(max_value: int, highest_board_coin: int) -> int:
	var objective := maxi(1, max_value)
	if highest_board_coin > 0:
		objective = mini(objective, highest_board_coin + 1)
	return maxi(5, maxi(objective, highest_board_coin))

## Ancla de niveles si prestigiaste con el checkpoint ya por delante del hito.
## Prestige en 15 → 15 (crear 15 otra vez = 16). Prestige en 21 → 20 (crear 16 = 23).
static func cycle_checkpoint_origin(milestone_level: int, prestige_checkpoint: int) -> int:
	return maxi(milestone_level, prestige_checkpoint - 1)

## Revisión 2: cura el salto 21→23 por fichas 15/16 residuales del parche.
## Los saves que prestigaron con revisión 1 igual se curan una vez.
const CYCLE_RULES_REVISION := 2

## Máximo checkpoint al prestigiar sin haber creado el (hito+1). Ciclo 15 → 21.
static func prestige_hold_checkpoint(milestone_level: int, checkpoint_base_value: int) -> int:
	return milestone_level + checkpoint_base_value + 1

## Cura saves inflados (nivel 23 sin haber juntado 15s para el 16).
## Nunca rebobina un tablero que ya pasó el objetivo de prestige (ficha/objetivo 17+).
static func heal_legacy_cycle_progress(state: Dictionary, checkpoint_base_value: int) -> Dictionary:
	var milestone := int(state.get("milestone_level", 0))
	var checkpoint_level := int(state.get("checkpoint_level", 1))
	var current_level := int(state.get("current_level", 1))
	var max_value := int(state.get("max_value", checkpoint_base_value))
	var roll_value_floor := int(state.get("roll_value_floor", 1))
	var origin := int(state.get("cycle_checkpoint_origin", 0))
	var revision := int(state.get("cycle_rules_revision", 0))
	var highest := int(state.get("highest_board_coin", 0))
	var result := {
		"changed": false,
		"refill": false,
		"checkpoint_level": checkpoint_level,
		"current_level": current_level,
		"max_value": max_value,
		"roll_value_floor": roll_value_floor,
		"cycle_checkpoint_origin": origin,
		"cycle_rules_revision": revision,
	}
	if milestone <= 0:
		return result
	var new_floor := cycle_reset_roll_value_floor(milestone, checkpoint_base_value)
	var new_max := cycle_reset_max_value(milestone)
	var progressed_past_reset := maxi(max_value, highest) > new_max + 1
	var changed := false
	var refill := false
	if not progressed_past_reset and roll_value_floor == milestone - checkpoint_base_value:
		roll_value_floor = new_floor
		changed = true
		refill = true
	if revision < CYCLE_RULES_REVISION:
		revision = CYCLE_RULES_REVISION
		changed = true
		if not progressed_past_reset:
			var hold := mini(
				checkpoint_level,
				prestige_hold_checkpoint(milestone, checkpoint_base_value)
			)
			origin = cycle_checkpoint_origin(milestone, maxi(milestone, hold))
			var prestige_level := origin + 1
			if checkpoint_level > prestige_level:
				checkpoint_level = prestige_level
			max_value = new_max
			current_level = 1
			roll_value_floor = new_floor
			refill = true
	elif origin <= 0:
		origin = cycle_checkpoint_origin(milestone, checkpoint_level)
		changed = true
	result["changed"] = changed
	result["refill"] = refill
	result["checkpoint_level"] = checkpoint_level
	result["current_level"] = current_level
	result["max_value"] = max_value
	result["roll_value_floor"] = roll_value_floor
	result["cycle_checkpoint_origin"] = origin
	result["cycle_rules_revision"] = revision
	return result

## Nivel para lobby/HUD: aplica la cura 21→23 sin tocar el save (el tablero se rellena al entrar).
static func healed_display_checkpoint(
	checkpoint_level: int,
	data: Dictionary,
	checkpoint_base_value: int = 5,
	board_cycle_levels: int = 15
) -> int:
	var roll_value_floor := int(data.get("roll_value_floor", 1))
	var origin := int(data.get("cycle_checkpoint_origin", 0))
	var revision := int(data.get("cycle_rules_revision", 0))
	var max_value := int(data.get("max_value", checkpoint_base_value))
	var current_level := int(data.get("current_level", 1))
	var level := checkpoint_level
	var rs: Variant = data.get("runtime_snapshot", {})
	if rs is Dictionary and not (rs as Dictionary).is_empty():
		roll_value_floor = int(rs.get("roll_value_floor", roll_value_floor))
		origin = int(rs.get("cycle_checkpoint_origin", origin))
		revision = int(rs.get("cycle_rules_revision", revision))
		max_value = int(rs.get("max_value", max_value))
		current_level = int(rs.get("current_level", current_level))
		level = int(rs.get("checkpoint_level", level))
	var highest := int(data.get("highest_board_coin", 0))
	if rs is Dictionary:
		highest = maxi(highest, _highest_coin_in_stack_rows(rs.get("stacks", [])))
	var snap: Variant = data.get("checkpoint_snapshot", {})
	if highest <= 0 and snap is Dictionary:
		highest = _highest_coin_in_stack_rows(snap.get("stacks", []))
	var milestone := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var healed := heal_legacy_cycle_progress({
		"milestone_level": milestone,
		"checkpoint_level": level,
		"current_level": current_level,
		"max_value": max_value,
		"roll_value_floor": roll_value_floor,
		"cycle_checkpoint_origin": origin,
		"cycle_rules_revision": revision,
		"highest_board_coin": highest,
	}, checkpoint_base_value)
	return maxi(1, int(healed.get("checkpoint_level", level)))

static func _highest_coin_in_stack_rows(rows: Variant) -> int:
	var best := 0
	if not rows is Array:
		return 0
	for row in rows:
		if not row is Array:
			continue
		for raw in row:
			best = maxi(best, int(raw))
	return best

static func next_cycle_coin_milestone(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	if roll_value_floor <= 1:
		return board_cycle_levels
	return cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels) + CYCLE_REPEAT_COINS

static func reached_cycle_coin_milestone(
	highest_value: int,
	roll_value_floor: int,
	checkpoint_base_value: int,
	board_cycle_levels: int
) -> int:
	var found := 0
	var next_m := next_cycle_coin_milestone(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	while next_m > 0 and next_m <= highest_value:
		found = next_m
		next_m += CYCLE_REPEAT_COINS
	return found

## Tras prestige a tiempo, el piso es el hito (15). Si prestigiaste en 21, el piso es 21:
## el hold ya cuenta; la mitad de 15 no vuelve a sumar. Mitad de 27 = 45, no 46.
static func checkpoint_walk_start(cycle_base: int, origin: int) -> int:
	if cycle_base <= 0:
		return 1
	if origin > cycle_base:
		return origin
	return cycle_base

## Nivel según pilas reales: +1 si hay ≥5 de V en una pila, +1 al completar V
## (10 iguales o ya existe V+1). Un 8 suelto no cuenta como haber pasado 5/6/7.
## min_level: no re-exigir 25/26 si el checkpoint ya los contó; si no, al fusionar
## 27s desaparecen y el cartel del 46 espera a Repartir.
static func evaluate_checkpoint_from_piles(
	max_count_for_value: Callable,
	roll_value_floor: int,
	checkpoint_base_value: int,
	checkpoint_half_threshold: int,
	board_cycle_levels: int,
	cycle_origin: int = 0,
	min_level: int = 0
) -> int:
	var offset := cycle_coin_offset(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var cycle_base := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var origin := effective_cycle_origin(cycle_origin, cycle_base)
	var level := checkpoint_walk_start(cycle_base, origin)
	var local_v := checkpoint_base_value
	var guard := 0
	while guard < 128:
		guard += 1
		var coin := local_v + offset
		var pile := int(max_count_for_value.call(coin))
		var next_pile := int(max_count_for_value.call(coin + 1))
		var completed := pile >= 10 or next_pile >= 1
		var has_half := pile >= checkpoint_half_threshold or completed
		var half_level := level + 1
		var complete_level := level + 2
		# El checkpoint ya pagó este valor (p. ej. 45 = mitad de 27). No pedir
		# otra vez 25/26 que se fusionaron.
		if min_level >= complete_level:
			level = complete_level
			local_v += 1
			continue
		if min_level >= half_level:
			if not completed:
				return maxi(half_level, min_level)
			level = complete_level
			local_v += 1
			continue
		if not has_half:
			break
		level += 1
		if not completed:
			break
		level += 1
		local_v += 1
	return maxi(level, min_level) if min_level > 0 else level

## Compat: un solo valor en el tablero (sin inferir 5→8).
static func evaluate_checkpoint_level(
	highest_value: int,
	highest_value_max_count: int,
	roll_value_floor: int,
	checkpoint_base_value: int,
	checkpoint_half_threshold: int,
	board_cycle_levels: int,
	cycle_origin: int = 0,
	min_level: int = 0
) -> int:
	var counts := {}
	if highest_value > 0:
		counts[highest_value] = highest_value_max_count
	return evaluate_checkpoint_from_piles(
		func(v: int) -> int: return int(counts.get(v, 0)),
		roll_value_floor,
		checkpoint_base_value,
		checkpoint_half_threshold,
		board_cycle_levels,
		cycle_origin,
		min_level
	)

static func progress_toward_checkpoint_level(
	target_level: int,
	highest_value: int,
	max_count_for_value: Callable,
	stack_capacity: int,
	roll_value_floor: int,
	checkpoint_base_value: int,
	checkpoint_half_threshold: int,
	board_cycle_levels: int,
	cycle_origin: int = 0
) -> float:
	if target_level <= 1:
		return 0.0
	var offset := cycle_coin_offset(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var cycle_base := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var origin := effective_cycle_origin(cycle_origin, cycle_base)
	var start := checkpoint_walk_start(cycle_base, origin)
	var local_target := target_level - start + 1
	if local_target <= 1:
		return 0.0
	var steps := local_target - 2
	var local_v := checkpoint_base_value + int(steps / 2)
	var v := local_v + offset
	if steps % 2 == 0:
		var need := checkpoint_half_threshold
		return clampf(float(int(max_count_for_value.call(v))) / float(need), 0.0, 1.0)
	var pile := int(max_count_for_value.call(v))
	if int(max_count_for_value.call(v + 1)) >= 1 or pile >= stack_capacity:
		return 1.0
	return clampf(float(pile) / float(stack_capacity), 0.0, 1.0)

static func checkpoint_level_description(
	level: int,
	checkpoint_base_value: int,
	board_cycle_levels: int,
	cycle_origin: int = 0,
	roll_value_floor: int = 1
) -> String:
	if level <= 1:
		return ""
	var offset := cycle_coin_offset(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var cycle_base := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var origin := effective_cycle_origin(cycle_origin, cycle_base)
	var start := checkpoint_walk_start(cycle_base, origin)
	var local_level := level - start + 1
	if local_level <= 1:
		return ""
	var steps := local_level - 2
	var local_v := checkpoint_base_value + int(steps / 2)
	var v := local_v + offset
	if steps % 2 == 0:
		return "Pila %d: mitad o más" % v
	return "Completaste la pila %d" % v

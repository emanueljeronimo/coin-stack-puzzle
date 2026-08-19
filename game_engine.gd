extends RefCounted
class_name GameEngine

# Motor puro: reglas matemáticas de checkpoints, ciclos y progreso.

static func cycle_index(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	if roll_value_floor <= 1:
		return 0
	return int((roll_value_floor + checkpoint_base_value) / board_cycle_levels)

static func cycle_base_level(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	return cycle_index(roll_value_floor, checkpoint_base_value, board_cycle_levels) * board_cycle_levels

static func cycle_coin_offset(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	var idx := cycle_index(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	if idx <= 0:
		return 0
	return idx * board_cycle_levels - checkpoint_base_value

## Tras el hito (15/30/45…), el piso sube: tiradas 11-14 / 26-29 / 41-44 (el hito no sale en la tirada).
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
## Devuelve checkpoint/origen/tirada y si hay que rellenar el tablero.
static func heal_legacy_cycle_progress(state: Dictionary, checkpoint_base_value: int) -> Dictionary:
	var milestone := int(state.get("milestone_level", 0))
	var checkpoint_level := int(state.get("checkpoint_level", 1))
	var current_level := int(state.get("current_level", 1))
	var max_value := int(state.get("max_value", checkpoint_base_value))
	var roll_value_floor := int(state.get("roll_value_floor", 1))
	var origin := int(state.get("cycle_checkpoint_origin", 0))
	var revision := int(state.get("cycle_rules_revision", 0))
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
	var changed := false
	var refill := false
	if roll_value_floor == milestone - checkpoint_base_value:
		roll_value_floor = new_floor
		changed = true
		refill = true
	if max_value > new_max:
		max_value = new_max
		current_level = 1
		changed = true
		refill = true
	if revision < CYCLE_RULES_REVISION:
		revision = CYCLE_RULES_REVISION
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
		changed = true
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
	var milestone := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var healed := heal_legacy_cycle_progress({
		"milestone_level": milestone,
		"checkpoint_level": level,
		"current_level": current_level,
		"max_value": max_value,
		"roll_value_floor": roll_value_floor,
		"cycle_checkpoint_origin": origin,
		"cycle_rules_revision": revision,
	}, checkpoint_base_value)
	return maxi(1, int(healed.get("checkpoint_level", level)))

static func next_cycle_coin_milestone(roll_value_floor: int, checkpoint_base_value: int, board_cycle_levels: int) -> int:
	return (cycle_index(roll_value_floor, checkpoint_base_value, board_cycle_levels) + 1) * board_cycle_levels

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
		next_m += board_cycle_levels
	return found

static func evaluate_checkpoint_level(
	highest_value: int,
	highest_value_max_count: int,
	roll_value_floor: int,
	checkpoint_base_value: int,
	checkpoint_half_threshold: int,
	board_cycle_levels: int,
	cycle_origin: int = 0
) -> int:
	var offset := cycle_coin_offset(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var local_highest := highest_value - offset
	var cycle_base := cycle_base_level(roll_value_floor, checkpoint_base_value, board_cycle_levels)
	var origin := cycle_base
	if cycle_origin > cycle_base:
		origin = cycle_origin
	if local_highest < checkpoint_base_value:
		return 1 if cycle_base == 0 else origin
	var has_half := highest_value_max_count >= checkpoint_half_threshold
	var local_level := 2 * (local_highest - checkpoint_base_value) + 2 + (1 if has_half else 0)
	if cycle_base == 0:
		return local_level
	return origin + local_level - 1

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
	var cycle_for_target := int(maxi(target_level - 1, 0) / board_cycle_levels)
	var mapping_base := cycle_for_target * board_cycle_levels
	if cycle_origin > mapping_base:
		mapping_base = cycle_origin
	var local_target := target_level if mapping_base == 0 else target_level - mapping_base + 1
	var offset := 0 if cycle_for_target <= 0 else cycle_for_target * board_cycle_levels - checkpoint_base_value
	if local_target <= 1:
		return 0.0
	var steps := local_target - 2
	var local_v := checkpoint_base_value + int(steps / 2)
	var v := local_v + offset
	if steps % 2 == 0:
		if highest_value >= v:
			return 1.0
		var prev_v := maxi(offset + 1, v - 1)
		var hv_part := clampf(float(highest_value - offset) / float(maxi(1, prev_v - offset)), 0.0, 1.0) * 0.35
		var pile_part := clampf(
			float(int(max_count_for_value.call(prev_v))) / float(stack_capacity), 0.0, 1.0
		) * 0.65
		return clampf(hv_part + pile_part, 0.0, 0.99)
	var need := checkpoint_half_threshold
	return clampf(float(int(max_count_for_value.call(v))) / float(need), 0.0, 1.0)

static func checkpoint_level_description(
	level: int,
	checkpoint_base_value: int,
	board_cycle_levels: int,
	cycle_origin: int = 0
) -> String:
	if level <= 1:
		return ""
	var cycle_for_level := int(maxi(level - 1, 0) / board_cycle_levels)
	var mapping_base := cycle_for_level * board_cycle_levels
	if cycle_origin > mapping_base:
		mapping_base = cycle_origin
	var local_level := level if mapping_base == 0 else level - mapping_base + 1
	var offset := 0 if cycle_for_level <= 0 else cycle_for_level * board_cycle_levels - checkpoint_base_value
	if local_level <= 1:
		return ""
	var steps := local_level - 2
	var local_v := checkpoint_base_value + int(steps / 2)
	var v := local_v + offset
	if steps % 2 == 0:
		if steps == 0:
			return "Creaste la pila %d" % v
		return "Completaste la pila %d" % (v - 1)
	return "Pila %d: mitad o más" % v

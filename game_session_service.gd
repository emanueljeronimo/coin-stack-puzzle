extends RefCounted
class_name GameSessionService

static func build_runtime_snapshot(state: Dictionary) -> Dictionary:
	var expected := int(state.get("active_stacks", 0))
	if bool(state.get("has_active_temp_stack", false)):
		expected += 1
	var all_rows: Array = state.get("all_rows", [])
	var rows: Array = []
	for i in range(mini(expected, all_rows.size())):
		rows.append(all_rows[i])
	while rows.size() < expected:
		rows.append([])
	return {
		"current_level": int(state.get("current_level", 1)),
		"checkpoint_level": int(state.get("checkpoint_level", 1)),
		"max_value": int(state.get("max_value", 5)),
		"roll_value_floor": int(state.get("roll_value_floor", 1)),
		"cycle_checkpoint_origin": int(state.get("cycle_checkpoint_origin", 0)),
		"cycle_rules_revision": int(state.get("cycle_rules_revision", 0)),
		"fusion_target_bonus_unlocked": bool(state.get("fusion_target_bonus_unlocked", false)),
		"checkpoint_snapshot": (state.get("checkpoint_snapshot", {}) as Dictionary).duplicate(true),
		"active_stacks": int(state.get("active_stacks", 1)),
		"next_free_slot_unlock_level": int(state.get("next_free_slot_unlock_level", 1)),
		"temp_slot_bonus_active": bool(state.get("temp_slot_bonus_active", false)),
		"temp_slot_time_remaining": float(state.get("temp_slot_time_remaining", 0.0)),
		"temp_slot_actions_remaining": int(state.get("temp_slot_actions_remaining", 0)),
		"pending_cycle_reset_milestone": int(state.get("pending_cycle_reset_milestone", 0)),
		"pending_level_up_alerts": normalize_int_list(state.get("pending_level_up_alerts", [])),
		"last_acknowledged_checkpoint_level": int(state.get("last_acknowledged_checkpoint_level", 0)),
		"wildcard_counts": (state.get("wildcard_counts", {}) as Dictionary).duplicate(true),
		"wildcard_unlock_granted": (state.get("wildcard_unlock_granted", {}) as Dictionary).duplicate(true),
		"stacks": rows,
	}

static func build_checkpoint_snapshot(state: Dictionary) -> Dictionary:
	return {
		"checkpoint_level": int(state.get("checkpoint_level", 1)),
		"current_level": int(state.get("current_level", 1)),
		"max_value": int(state.get("max_value", 5)),
		"roll_value_floor": int(state.get("roll_value_floor", 1)),
		"cycle_checkpoint_origin": int(state.get("cycle_checkpoint_origin", 0)),
		"cycle_rules_revision": int(state.get("cycle_rules_revision", 0)),
		"active_stacks": int(state.get("active_stacks", 1)),
		"next_free_slot_unlock_level": int(state.get("next_free_slot_unlock_level", 1)),
		"adjacent_slot_next_price": int(state.get("adjacent_slot_next_price", 0)),
		"wildcard_counts": (state.get("wildcard_counts", {}) as Dictionary).duplicate(),
		"wildcard_unlock_granted": (state.get("wildcard_unlock_granted", {}) as Dictionary).duplicate(),
		"stacks": (state.get("stacks", []) as Array).duplicate(true),
	}

static func build_save_payload(state: Dictionary) -> Dictionary:
	return {
		"checkpoint_level": int(state.get("checkpoint_level", 1)),
		"checkpoint_snapshot": (state.get("checkpoint_snapshot", {}) as Dictionary).duplicate(true),
		"runtime_snapshot": (state.get("runtime_snapshot", {}) as Dictionary).duplicate(true),
		"current_level": int(state.get("current_level", 1)),
		"max_value": int(state.get("max_value", 5)),
		"roll_value_floor": int(state.get("roll_value_floor", 1)),
		"cycle_checkpoint_origin": int(state.get("cycle_checkpoint_origin", 0)),
		"cycle_rules_revision": int(state.get("cycle_rules_revision", 0)),
		"active_stacks": int(state.get("active_stacks", 1)),
		"next_free_slot_unlock_level": int(state.get("next_free_slot_unlock_level", 1)),
		"temp_slot_actions_remaining": int(state.get("temp_slot_actions_remaining", 0)),
		"lives": int(state.get("lives", 0)),
		"gems": int(state.get("gems", 0)),
		"player_stars": int(state.get("player_stars", 0)),
	}

static func parse_save_payload(data: Dictionary, defaults: Dictionary) -> Dictionary:
	var parsed := defaults.duplicate(true)
	if data.is_empty():
		return parsed
	parsed["checkpoint_level"] = maxi(1, int(data.get("checkpoint_level", parsed["checkpoint_level"])))
	parsed["current_level"] = maxi(1, int(data.get("current_level", parsed["current_level"])))
	parsed["max_value"] = maxi(int(defaults.get("checkpoint_base_value", 5)), int(data.get("max_value", parsed["max_value"])))
	parsed["roll_value_floor"] = maxi(1, int(data.get("roll_value_floor", parsed["roll_value_floor"])))
	parsed["cycle_checkpoint_origin"] = maxi(0, int(data.get("cycle_checkpoint_origin", parsed.get("cycle_checkpoint_origin", 0))))
	parsed["cycle_rules_revision"] = maxi(0, int(data.get("cycle_rules_revision", parsed.get("cycle_rules_revision", 0))))
	parsed["active_stacks"] = int(data.get("active_stacks", parsed["active_stacks"]))
	parsed["next_free_slot_unlock_level"] = int(data.get("next_free_slot_unlock_level", parsed["next_free_slot_unlock_level"]))
	parsed["temp_slot_actions_remaining"] = maxi(0, int(data.get("temp_slot_actions_remaining", parsed["temp_slot_actions_remaining"])))
	parsed["lives"] = int(data.get("lives", parsed["lives"]))
	parsed["gems"] = int(data.get("gems", parsed["gems"]))
	parsed["player_stars"] = int(data.get("player_stars", data.get("coins", parsed["player_stars"])))
	var cp: Variant = data.get("checkpoint_snapshot", {})
	if cp is Dictionary and not cp.is_empty():
		parsed["checkpoint_snapshot"] = cp.duplicate(true)
	var rs: Variant = data.get("runtime_snapshot", {})
	if rs is Dictionary and not rs.is_empty():
		parsed["runtime_snapshot"] = rs.duplicate(true)
	else:
		parsed["runtime_snapshot"] = {}
	return parsed

static func normalize_int_list(raw: Variant) -> Array:
	var out: Array = []
	if not raw is Array:
		return out
	for v in raw:
		out.append(int(v))
	return out

## Saves viejos no tienen acuse: no re-mostrar todos los niveles 1..N.
static func migrated_last_acknowledged_checkpoint(has_saved_ack: bool, saved_ack: int, checkpoint_level: int) -> int:
	if not has_saved_ack or saved_ack <= 0:
		return maxi(1, checkpoint_level)
	return saved_ack

## Completa huecos (p.ej. cartel poppeado pero sin Continuar) y evita duplicados.
static func queued_unacked_level_up_alerts(pending: Array, last_acked: int, checkpoint_level: int) -> Array:
	var out: Array = []
	var seen := {}
	if last_acked > 0:
		for lvl in range(last_acked + 1, checkpoint_level + 1):
			seen[lvl] = true
			out.append(lvl)
	for v in pending:
		var lvl := int(v)
		if last_acked > 0 and lvl <= last_acked:
			continue
		if seen.has(lvl):
			continue
		seen[lvl] = true
		out.append(lvl)
	return out

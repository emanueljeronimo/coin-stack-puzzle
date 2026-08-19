extends RefCounted
class_name GameLivesService

## Recarga de vidas gratis (testeable sin escena).

const MAX_LIVES := 5
const REGEN_SECONDS := 30 * 60

static func catch_up(
	lives: int,
	next_unix: int,
	now: int,
	max_lives: int = MAX_LIVES,
	interval: int = REGEN_SECONDS
) -> Dictionary:
	var out_lives := clampi(lives, 0, max_lives)
	var out_next := next_unix
	if out_lives >= max_lives:
		return {"lives": max_lives, "next_unix": 0}
	if out_next <= 0:
		return {"lives": out_lives, "next_unix": now + interval}
	while out_lives < max_lives and out_next > 0 and now >= out_next:
		out_lives += 1
		if out_lives >= max_lives:
			out_next = 0
		else:
			out_next += interval
	return {"lives": out_lives, "next_unix": out_next}

static func on_spend(
	lives: int,
	next_unix: int,
	now: int,
	max_lives: int = MAX_LIVES,
	interval: int = REGEN_SECONDS
) -> Dictionary:
	if lives <= 0:
		return {"ok": false, "lives": lives, "next_unix": next_unix}
	var out_lives := lives - 1
	var out_next := next_unix
	if out_lives < max_lives and out_next <= 0:
		out_next = now + interval
	return {"ok": true, "lives": out_lives, "next_unix": out_next}

static func on_grant(
	lives: int,
	amount: int,
	next_unix: int,
	now: int,
	max_lives: int = MAX_LIVES,
	interval: int = REGEN_SECONDS
) -> Dictionary:
	var out_lives := clampi(lives + maxi(0, amount), 0, max_lives)
	var out_next := next_unix
	if out_lives >= max_lives:
		out_next = 0
	elif out_next <= 0:
		out_next = now + interval
	return {"lives": out_lives, "next_unix": out_next}

static func remaining_seconds(lives: int, next_unix: int, now: int, max_lives: int = MAX_LIVES) -> int:
	if lives >= max_lives or next_unix <= 0:
		return 0
	return maxi(0, next_unix - now)

static func format_countdown(seconds: int) -> String:
	var total := maxi(0, seconds)
	var minutes := int(total / 60)
	var secs := total % 60
	return "%d:%02d" % [minutes, secs]

static func format_chip_text(
	lives: int,
	remaining_sec: int,
	max_lives: int = MAX_LIVES
) -> String:
	if lives >= max_lives:
		return "full"
	return format_countdown(remaining_sec)

## Saves viejos sin timestamp: el ciclo arrancó al guardar.
static func migrate_missing_timer(
	lives: int,
	now: int,
	save_mtime: int,
	max_lives: int = MAX_LIVES,
	interval: int = REGEN_SECONDS
) -> Dictionary:
	var out_lives := clampi(lives, 0, max_lives)
	if out_lives >= max_lives:
		return {"lives": max_lives, "next_unix": 0}
	var anchor := save_mtime if save_mtime > 0 else now
	return catch_up(out_lives, anchor + interval, now, max_lives, interval)

class_name CelebrationRainbowService
extends RefCounted

const CYCLE_SEC := 1.85
const STAGGER_SEC := 0.28

static func band_colors() -> Array[Color]:
	return [
		Color(1.00, 0.72, 0.80, 1.0),
		Color(1.00, 0.86, 0.70, 1.0),
		Color(1.00, 0.96, 0.78, 1.0),
		Color(0.78, 0.94, 0.84, 1.0),
		Color(0.72, 0.86, 1.00, 1.0),
		Color(0.86, 0.78, 1.00, 1.0),
	]

static func band_width(ui_scale: float) -> float:
	return clampf(7.4 * ui_scale, 5.5, 11.0)

static func arc_points(
	center: Vector2,
	radius: float,
	samples: int = 18,
	progress: float = 1.0
) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var drawn: float = clampf(progress, 0.0, 1.0)
	if drawn <= 0.02:
		return pts
	var n: int = maxi(samples, 8)
	var last_i: int = maxi(int(round(float(n) * drawn)), 1)
	var a0: float = PI + 0.18
	var a1: float = TAU - 0.18
	for i in range(last_i + 1):
		var t: float = float(i) / float(n)
		var ang: float = lerpf(a0, a1, t)
		pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
	return pts

static func rainbow_slots(
	viewport: Vector2,
	card: Rect2,
	ui_scale: float,
	seed_value: int = 1
) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else 1
	var base_r: float = 90.0 * ui_scale
	var margin: float = 72.0 * ui_scale
	var keepout: Rect2 = card.grow(28.0 * ui_scale)
	var spacing: float = base_r * 2.35
	var candidates: Array[Vector2] = []
	var row_i: int = 0
	var y: float = margin
	while y <= viewport.y - margin:
		var x: float = margin + (spacing * 0.5 if row_i % 2 == 1 else 0.0)
		while x <= viewport.x - margin:
			var p := Vector2(
				clampf(x + rng.randf_range(-spacing * 0.18, spacing * 0.18), margin, viewport.x - margin),
				clampf(y + rng.randf_range(-spacing * 0.18, spacing * 0.18), margin, viewport.y - margin)
			)
			if not keepout.has_point(p):
				candidates.append(p)
			x += spacing
		y += spacing
		row_i += 1
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2 = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var want: int = mini(16, candidates.size())
	var slots: Array[Dictionary] = []
	for p in candidates:
		if slots.size() >= want:
			break
		var radius: float = base_r * rng.randf_range(0.86, 1.08)
		if _overlaps_slot(slots, p, radius):
			continue
		slots.append({
			"center": p,
			"radius": radius,
			"rot": rng.randf_range(-PI, PI),
			"delay": rng.randf_range(0.0, 2.4),
			"cycle_sec": rng.randf_range(1.35, 2.75),
		})
	return slots

static func _overlaps_slot(slots: Array[Dictionary], p: Vector2, radius: float) -> bool:
	for slot in slots:
		var other_r: float = float(slot.radius)
		var min_dist: float = (radius + other_r) * 0.92
		if p.distance_to(slot.center) < min_dist:
			return true
	return false

static func cycle_draw(elapsed: float, delay: float, cycle_sec: float = CYCLE_SEC) -> float:
	var t: float = elapsed - delay
	if t < 0.0:
		return 0.0
	var dur: float = maxf(cycle_sec, 0.8)
	var cycle: float = fposmod(t, dur)
	var scale: float = dur / CYCLE_SEC
	var draw_t: float = 0.52 * scale
	var hold_t: float = 0.28 * scale
	var undraw_t: float = 0.52 * scale
	if cycle < draw_t:
		return cycle / draw_t
	if cycle < draw_t + hold_t:
		return 1.0
	if cycle < draw_t + hold_t + undraw_t:
		return 1.0 - (cycle - draw_t - hold_t) / undraw_t
	return 0.0

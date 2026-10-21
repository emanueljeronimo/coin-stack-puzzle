class_name CelebrationBurstService
extends RefCounted

const CONFETTI_AMOUNT := 88
const SPARKLE_AMOUNT := 30
const FIREWORK_AMOUNT := 42

static func confetti_colors() -> Array[Color]:
	return [
		Color(1.00, 0.78, 0.88, 1.0),
		Color(0.82, 0.96, 0.90, 1.0),
		Color(0.86, 0.80, 1.00, 1.0),
		Color(0.75, 0.90, 1.00, 1.0),
		Color(1.00, 0.92, 0.76, 1.0),
		Color(0.95, 0.82, 0.96, 1.0),
	]

static func sparkle_colors() -> Array[Color]:
	return [
		Color(1.00, 0.95, 0.55, 1.0),
		Color(0.55, 1.00, 0.88, 1.0),
		Color(1.00, 1.00, 0.92, 1.0),
		Color(1.00, 0.78, 0.42, 1.0),
	]

static func gradient_from_colors(colors: Array[Color]) -> Gradient:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var n: int = maxi(colors.size(), 1)
	var offsets := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in n:
		offsets.append(float(i) / float(n))
		cols.append(colors[i])
	g.offsets = offsets
	g.colors = cols
	return g

static func fade_out_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 0),
	])
	return g

static func make_dot_texture() -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 8:
		for x in 8:
			var d: float = Vector2(float(x) - 3.5, float(y) - 3.5).length()
			if d < 3.2:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)

static func make_confetti_texture() -> ImageTexture:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 4:
		for x in 4:
			var d: float = Vector2(float(x) - 1.5, float(y) - 1.5).length()
			if d < 1.7:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)

static func apply_sparkles(particles: CPUParticles2D, ui_scale: float, card_w: float) -> void:
	particles.one_shot = true
	particles.amount = SPARKLE_AMOUNT
	particles.lifetime = 1.05
	particles.explosiveness = 0.92
	particles.randomness = 0.42
	particles.lifetime_randomness = 0.28
	particles.local_coords = true
	particles.emitting = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(maxf(card_w * 0.18, 40.0), 16.0 * ui_scale)
	particles.direction = Vector2(0, -1)
	particles.spread = 58.0
	particles.gravity = Vector2(0, -36.0 * ui_scale)
	particles.initial_velocity_min = 16.0 * ui_scale
	particles.initial_velocity_max = 64.0 * ui_scale
	particles.angular_velocity_min = -50.0
	particles.angular_velocity_max = 50.0
	particles.scale_amount_min = 2.0 * ui_scale
	particles.scale_amount_max = 5.2 * ui_scale
	particles.color = Color(1.0, 0.95, 0.70, 1.0)
	particles.color_initial_ramp = gradient_from_colors(sparkle_colors())
	particles.color_ramp = fade_out_ramp()
	particles.texture = make_dot_texture()

static func apply_confetti(particles: CPUParticles2D, ui_scale: float) -> void:
	particles.one_shot = true
	particles.amount = CONFETTI_AMOUNT
	particles.lifetime = 1.05
	particles.explosiveness = 1.0
	particles.randomness = 0.22
	particles.lifetime_randomness = 0.18
	particles.local_coords = true
	particles.emitting = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 6.0 * ui_scale
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 90.0 * ui_scale)
	particles.initial_velocity_min = 220.0 * ui_scale
	particles.initial_velocity_max = 420.0 * ui_scale
	particles.damping_min = 12.0
	particles.damping_max = 22.0
	particles.angle_min = -180.0
	particles.angle_max = 180.0
	particles.angular_velocity_min = -140.0
	particles.angular_velocity_max = 140.0
	particles.scale_amount_min = 1.1 * ui_scale
	particles.scale_amount_max = 2.3 * ui_scale
	particles.color = Color(1, 1, 1, 1)
	particles.color_initial_ramp = gradient_from_colors(confetti_colors())
	particles.color_ramp = fade_out_ramp()
	particles.texture = make_confetti_texture()

const KIND_PEONY := "peony"
const KIND_RING := "ring"
const KIND_WILLOW := "willow"

static func firework_colors() -> Array[Color]:
	return [
		Color(1.00, 0.58, 0.66, 1.0),
		Color(1.00, 0.82, 0.42, 1.0),
		Color(0.58, 0.94, 0.74, 1.0),
		Color(0.58, 0.78, 1.00, 1.0),
		Color(0.86, 0.64, 1.00, 1.0),
		Color(1.00, 0.95, 0.72, 1.0),
	]

static func firework_kinds() -> PackedStringArray:
	return PackedStringArray([KIND_PEONY, KIND_RING, KIND_WILLOW])

static func firework_bursts(
	viewport: Vector2,
	card: Rect2,
	ui_scale: float,
	seed_value: int = 1
) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else 1
	var keepout: Rect2 = card.grow(20.0 * ui_scale)
	var margin: float = 48.0 * ui_scale
	var spacing: float = 168.0 * ui_scale
	var top_y: float = maxf(margin, card.position.y - 78.0 * ui_scale)
	var bot_y: float = minf(viewport.y - margin, card.position.y + card.size.y + 78.0 * ui_scale)
	var candidates: Array[Vector2] = [
		Vector2(margin, margin),
		Vector2(margin + 72.0 * ui_scale, margin + 86.0 * ui_scale),
		Vector2(viewport.x * 0.18, top_y),
		Vector2(viewport.x * 0.32, margin + 52.0 * ui_scale),
		Vector2(viewport.x - margin, margin),
		Vector2(viewport.x - margin - 72.0 * ui_scale, margin + 86.0 * ui_scale),
		Vector2(viewport.x * 0.82, top_y),
		Vector2(viewport.x * 0.68, margin + 52.0 * ui_scale),
		Vector2(margin, viewport.y - margin),
		Vector2(margin + 72.0 * ui_scale, viewport.y - margin - 86.0 * ui_scale),
		Vector2(viewport.x * 0.18, bot_y),
		Vector2(viewport.x * 0.32, viewport.y - margin - 52.0 * ui_scale),
		Vector2(viewport.x - margin, viewport.y - margin),
		Vector2(viewport.x - margin - 72.0 * ui_scale, viewport.y - margin - 86.0 * ui_scale),
		Vector2(viewport.x * 0.82, bot_y),
		Vector2(viewport.x * 0.68, viewport.y - margin - 52.0 * ui_scale),
	]
	var y: float = margin
	var row_i: int = 0
	while y <= viewport.y - margin:
		var x: float = margin + (spacing * 0.5 if row_i % 2 == 1 else 0.0)
		while x <= viewport.x - margin:
			candidates.append(Vector2(
				clampf(x + rng.randf_range(-36.0, 36.0) * ui_scale, margin, viewport.x - margin),
				clampf(y + rng.randf_range(-36.0, 36.0) * ui_scale, margin, viewport.y - margin)
			))
			x += spacing
		y += spacing
		row_i += 1
	var buckets: Array = [[], [], [], []]
	var mid_x: float = viewport.x * 0.5
	for p in candidates:
		if keepout.has_point(p):
			continue
		var top: bool = p.y <= card.get_center().y
		var right: bool = p.x >= mid_x
		var idx: int = (0 if top else 2) + (1 if right else 0)
		buckets[idx].append(p)
	for b in range(buckets.size()):
		var pts: Array[Vector2] = []
		pts.assign(buckets[b])
		_shuffle_points(rng, pts)
		buckets[b] = pts
	var kinds: PackedStringArray = firework_kinds()
	var want: int = 16
	var bursts: Array[Dictionary] = []
	var cursor: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
	while bursts.size() < want:
		var added := false
		for i in range(buckets.size()):
			if bursts.size() >= want:
				break
			var pts: Array = buckets[i]
			while cursor[i] < pts.size():
				var p: Vector2 = pts[cursor[i]]
				cursor[i] += 1
				if _firework_too_close(bursts, p, 102.0 * ui_scale):
					continue
				_append_firework(bursts, rng, p, kinds[bursts.size() % kinds.size()], ui_scale)
				added = true
				break
		if not added:
			break
	return bursts

static func _shuffle_points(rng: RandomNumberGenerator, pts: Array[Vector2]) -> void:
	for i in range(pts.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2 = pts[i]
		pts[i] = pts[j]
		pts[j] = tmp

static func _firework_too_close(bursts: Array[Dictionary], p: Vector2, min_dist: float) -> bool:
	for other in bursts:
		if p.distance_to(other.origin) < min_dist:
			return true
	return false

static func _append_firework(
	bursts: Array[Dictionary],
	rng: RandomNumberGenerator,
	p: Vector2,
	kind: String,
	ui_scale: float
) -> void:
	var colors: Array[Color] = firework_colors()
	var spark_n: int = rng.randi_range(16, 22)
	var max_r: float = rng.randf_range(78.0, 118.0) * ui_scale
	var duration: float = rng.randf_range(0.95, 1.35)
	if kind == KIND_RING:
		spark_n = rng.randi_range(18, 24)
		max_r = rng.randf_range(70.0, 98.0) * ui_scale
		duration = rng.randf_range(1.05, 1.40)
	elif kind == KIND_WILLOW:
		spark_n = rng.randi_range(10, 14)
		max_r = rng.randf_range(88.0, 128.0) * ui_scale
		duration = rng.randf_range(1.25, 1.70)
	bursts.append({
		"origin": p,
		"kind": kind,
		"color": colors[rng.randi_range(0, colors.size() - 1)],
		"spark_count": spark_n,
		"max_r": max_r,
		"delay": rng.randf_range(0.0, 1.8),
		"duration": duration,
		"cycle_sec": rng.randf_range(2.4, 3.8),
		"spin": rng.randf_range(0.0, TAU),
	})

static func firework_progress(elapsed: float, delay: float, duration: float, cycle_sec: float) -> float:
	var t: float = elapsed - delay
	if t < 0.0:
		return 0.0
	var dur: float = maxf(duration, 0.4)
	var cycle: float = fposmod(t, maxf(cycle_sec, dur + 0.4))
	if cycle >= dur:
		return 0.0
	return cycle / dur

static func spark_offset(
	angle: float,
	max_r: float,
	u: float,
	ui_scale: float,
	kind: String = KIND_PEONY
) -> Vector2:
	var drawn: float = clampf(u, 0.0, 1.0)
	var dist: float = max_r * (1.0 - pow(1.0 - drawn, 2.1))
	var fall: float = 55.0 * ui_scale * drawn * drawn
	if kind == KIND_RING:
		var rush: float = clampf(drawn * 1.7, 0.0, 1.0)
		dist = max_r * (1.0 - pow(1.0 - rush, 3.0))
		fall = 14.0 * ui_scale * drawn * drawn
	elif kind == KIND_WILLOW:
		dist = max_r * (1.0 - pow(1.0 - drawn, 1.55))
		fall = 120.0 * ui_scale * drawn * drawn
	return Vector2(cos(angle), sin(angle)) * dist + Vector2(0.0, fall)

static func spark_alpha(u: float) -> float:
	var drawn: float = clampf(u, 0.0, 1.0)
	if drawn < 0.32:
		return 1.0
	return clampf(1.0 - (drawn - 0.32) / 0.68, 0.0, 1.0)

static func apply_fireworks(particles: CPUParticles2D, ui_scale: float) -> void:
	particles.one_shot = true
	particles.amount = FIREWORK_AMOUNT
	particles.lifetime = 1.35
	particles.explosiveness = 0.90
	particles.randomness = 0.28
	particles.lifetime_randomness = 0.30
	particles.local_coords = true
	particles.emitting = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0 * ui_scale
	particles.direction = Vector2(0, -1)
	particles.spread = 42.0
	particles.gravity = Vector2(0, 620.0 * ui_scale)
	particles.initial_velocity_min = 280.0 * ui_scale
	particles.initial_velocity_max = 520.0 * ui_scale
	particles.angular_velocity_min = -80.0
	particles.angular_velocity_max = 80.0
	particles.scale_amount_min = 2.4 * ui_scale
	particles.scale_amount_max = 6.0 * ui_scale
	particles.color = Color(1.0, 0.92, 0.55, 1.0)
	particles.color_initial_ramp = gradient_from_colors(sparkle_colors())
	particles.color_ramp = fade_out_ramp()
	particles.texture = make_dot_texture()

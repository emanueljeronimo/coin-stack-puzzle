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

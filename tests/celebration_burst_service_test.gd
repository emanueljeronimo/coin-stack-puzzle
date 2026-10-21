extends SceneTree

const Service := preload("res://celebration_burst_service.gd")
const BurstScript := preload("res://celebration_burst.gd")

var _failed := 0
var _passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== celebration_burst_service test ===")
	_test_palette_sizes()
	_test_gradient_from_colors()
	_test_textures()
	_test_apply_modes()
	_test_burst_play_stop()
	_test_confetti_is_pastel_firework()
	_test_firework_bursts()
	_test_firework_progress_vanishes()
	print("=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _ok(name: String) -> void:
	_passed += 1
	print("PASS: ", name)

func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL: ", name, (" - " + detail) if not detail.is_empty() else "")

func _test_palette_sizes() -> void:
	if Service.confetti_colors().size() < 5:
		_fail("confetti_colors")
		return
	if Service.sparkle_colors().size() < 3:
		_fail("sparkle_colors")
		return
	_ok("palette_sizes")

func _test_gradient_from_colors() -> void:
	var colors: Array[Color] = Service.confetti_colors()
	var g: Gradient = Service.gradient_from_colors(colors)
	if g.colors.size() != colors.size():
		_fail("gradient_count", str(g.colors.size()))
		return
	if g.interpolation_mode != Gradient.GRADIENT_INTERPOLATE_CONSTANT:
		_fail("gradient_mode")
		return
	_ok("gradient_from_colors")

func _test_textures() -> void:
	var dot: ImageTexture = Service.make_dot_texture()
	if dot.get_width() != 8 or dot.get_height() != 8:
		_fail("dot_texture_size")
		return
	var rect: ImageTexture = Service.make_confetti_texture()
	if rect.get_width() != 4 or rect.get_height() != 4:
		_fail("confetti_texture_size")
		return
	_ok("textures")

func _test_apply_modes() -> void:
	var sparkles := CPUParticles2D.new()
	Service.apply_sparkles(sparkles, 1.0, 720.0)
	if not sparkles.one_shot or sparkles.amount != Service.SPARKLE_AMOUNT:
		_fail("apply_sparkles")
		sparkles.free()
		return
	var confetti := CPUParticles2D.new()
	Service.apply_confetti(confetti, 1.0)
	if not confetti.one_shot or confetti.amount != Service.CONFETTI_AMOUNT:
		_fail("apply_confetti")
		sparkles.free()
		confetti.free()
		return
	var fireworks := CPUParticles2D.new()
	Service.apply_fireworks(fireworks, 1.0)
	if not fireworks.one_shot or fireworks.amount != Service.FIREWORK_AMOUNT:
		_fail("apply_fireworks")
		sparkles.free()
		confetti.free()
		fireworks.free()
		return
	sparkles.free()
	confetti.free()
	fireworks.free()
	_ok("apply_modes")

func _test_burst_play_stop() -> void:
	var burst: Control = BurstScript.new()
	root.add_child(burst)
	var card := ColorRect.new()
	card.position = Vector2(100, 200)
	card.size = Vector2(400, 300)
	root.add_child(card)
	burst.play_for_card(card, 1.0)
	if burst.get_child_count() < 1:
		_fail("burst_children", str(burst.get_child_count()))
		burst.queue_free()
		card.queue_free()
		return
	if burst.z_index < 312:
		_fail("burst_in_front", str(burst.z_index))
		burst.queue_free()
		card.queue_free()
		return
	burst.stop()
	if burst.visible:
		_fail("burst_still_visible")
		burst.queue_free()
		card.queue_free()
		return
	burst.queue_free()
	card.queue_free()
	_ok("burst_play_stop")

func _test_confetti_is_pastel_firework() -> void:
	for c in Service.confetti_colors():
		var col: Color = c
		if col.s > 0.55 or col.v < 0.82:
			_fail("confetti_not_pastel", str(col))
			return
	var confetti := CPUParticles2D.new()
	Service.apply_confetti(confetti, 1.0)
	if confetti.scale_amount_max > 3.0:
		_fail("confetti_too_big", str(confetti.scale_amount_max))
		confetti.free()
		return
	if confetti.explosiveness < 0.99 or confetti.spread < 179.0:
		_fail("confetti_not_firework", "%s %s" % [confetti.explosiveness, confetti.spread])
		confetti.free()
		return
	confetti.free()
	_ok("confetti_is_pastel_firework")

func _test_firework_bursts() -> void:
	var viewport := Vector2(1080, 1920)
	var card := Rect2(Vector2(180, 720), Vector2(720, 480))
	var bursts: Array[Dictionary] = Service.firework_bursts(viewport, card, 1.0, 11)
	if bursts.size() < 12:
		_fail("firework_count", str(bursts.size()))
		return
	var kinds := {}
	var quad := PackedInt32Array([0, 0, 0, 0])
	var mid_x: float = viewport.x * 0.5
	var mid_y: float = card.get_center().y
	for burst in bursts:
		var origin: Vector2 = burst.origin
		if card.has_point(origin):
			_fail("firework_inside_card", str(origin))
			return
		var idx: int = (0 if origin.y <= mid_y else 2) + (1 if origin.x >= mid_x else 0)
		quad[idx] += 1
		kinds[str(burst.get("kind", ""))] = true
	var qmin: int = mini(mini(quad[0], quad[1]), mini(quad[2], quad[3]))
	var qmax: int = maxi(maxi(quad[0], quad[1]), maxi(quad[2], quad[3]))
	if qmin < 2 or qmax - qmin > 2:
		_fail("uneven_quads", str(quad))
		return
	if Service.firework_kinds().size() < 3:
		_fail("kind_count", str(Service.firework_kinds().size()))
		return
	if kinds.size() < 3:
		_fail("missing_kinds", str(kinds.keys()))
		return
	_ok("firework_bursts")

func _test_firework_progress_vanishes() -> void:
	if Service.firework_progress(0.0, 0.5, 1.2, 3.0) > 0.01:
		_fail("firework_before_delay")
		return
	var mid: float = Service.firework_progress(0.60, 0.0, 1.2, 3.0)
	if mid < 0.3 or mid > 0.7:
		_fail("firework_in_progress", str(mid))
		return
	if Service.firework_progress(1.5, 0.0, 1.2, 3.0) > 0.01:
		_fail("firework_still_visible")
		return
	var start: Vector2 = Service.spark_offset(0.0, 100.0, 0.0, 1.0)
	var end: Vector2 = Service.spark_offset(0.0, 100.0, 1.0, 1.0)
	if end.length() <= start.length():
		_fail("spark_does_not_expand")
		return
	_ok("firework_progress_vanishes")

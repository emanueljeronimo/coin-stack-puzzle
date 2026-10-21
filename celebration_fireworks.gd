class_name CelebrationFireworks
extends Control

const Service := preload("res://celebration_burst_service.gd")

var _bursts: Array[Dictionary] = []
var _card := Rect2()
var _playing := false
var _elapsed := 0.0
var _ui_scale := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

func play_around_card(card: Control, ui_scale: float) -> void:
	if card == null:
		return
	_ui_scale = maxf(ui_scale, 0.5)
	var viewport: Vector2 = size
	if viewport.x < 8.0 or viewport.y < 8.0:
		viewport = get_viewport_rect().size
	_card = Rect2(card.position, card.size).grow(8.0)
	_bursts = Service.firework_bursts(viewport, Rect2(card.position, card.size), _ui_scale, Time.get_ticks_msec())
	_elapsed = 0.0
	_playing = true
	visible = true
	queue_redraw()
	set_process(true)

func stop() -> void:
	_playing = false
	set_process(false)
	visible = false
	queue_redraw()

func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	if not _playing or _bursts.is_empty():
		return
	for burst in _bursts:
		var u: float = Service.firework_progress(
			_elapsed,
			float(burst.get("delay", 0.0)),
			float(burst.get("duration", 1.1)),
			float(burst.get("cycle_sec", 3.0))
		)
		if u <= 0.02:
			continue
		_draw_burst(burst, u)

func _draw_burst(burst: Dictionary, u: float) -> void:
	var kind: String = str(burst.get("kind", Service.KIND_PEONY))
	if u < 0.18:
		var flash: float = 1.0 - u / 0.18
		draw_circle(burst.origin, (10.0 + 18.0 * flash) * _ui_scale, Color(1.0, 0.98, 0.88, 0.85 * flash))
	if kind == Service.KIND_WILLOW:
		_draw_willow(burst, u)
	elif kind == Service.KIND_RING:
		_draw_ring(burst, u)
	else:
		_draw_peony(burst, u)

func _draw_peony(burst: Dictionary, u: float) -> void:
	var origin: Vector2 = burst.origin
	var color: Color = burst.color
	var max_r: float = float(burst.max_r)
	var spark_n: int = int(burst.spark_count)
	var spin: float = float(burst.get("spin", 0.0))
	var alpha: float = Service.spark_alpha(u)
	for i in range(spark_n):
		var ang: float = spin + TAU * float(i) / float(spark_n)
		for trail in range(3):
			var tu: float = clampf(u - float(trail) * 0.045, 0.0, 1.0)
			if tu <= 0.0:
				continue
			var pos: Vector2 = origin + Service.spark_offset(ang, max_r, tu, _ui_scale, Service.KIND_PEONY)
			if _card.has_point(pos):
				continue
			var c: Color = color
			c.a = alpha * (1.0 - float(trail) * 0.28)
			draw_circle(pos, (3.6 - float(trail) * 0.9) * _ui_scale, c)

func _draw_ring(burst: Dictionary, u: float) -> void:
	var origin: Vector2 = burst.origin
	var color: Color = burst.color
	var max_r: float = float(burst.max_r)
	var spark_n: int = int(burst.spark_count)
	var spin: float = float(burst.get("spin", 0.0))
	var alpha: float = Service.spark_alpha(u)
	for shell in range(2):
		var shell_r: float = max_r * (1.0 if shell == 0 else 0.58)
		var n: int = spark_n if shell == 0 else maxi(spark_n - 6, 10)
		var shell_c: Color = color.lerp(Color(1, 1, 1, 1), 0.22 * float(shell))
		for i in range(n):
			var ang: float = spin + TAU * float(i) / float(n) + float(shell) * 0.12
			var pos: Vector2 = origin + Service.spark_offset(ang, shell_r, u, _ui_scale, Service.KIND_RING)
			if _card.has_point(pos):
				continue
			shell_c.a = alpha
			draw_circle(pos, (3.1 - float(shell) * 0.5) * _ui_scale, shell_c)

func _draw_willow(burst: Dictionary, u: float) -> void:
	var origin: Vector2 = burst.origin
	var color: Color = burst.color
	var max_r: float = float(burst.max_r)
	var spark_n: int = int(burst.spark_count)
	var spin: float = float(burst.get("spin", 0.0))
	var alpha: float = Service.spark_alpha(u)
	for i in range(spark_n):
		var ang: float = spin + TAU * float(i) / float(spark_n)
		var pts := PackedVector2Array()
		for k in range(7):
			var tu: float = clampf(u - float(k) * 0.055, 0.0, 1.0)
			if tu <= 0.0:
				continue
			var pos: Vector2 = origin + Service.spark_offset(ang, max_r, tu, _ui_scale, Service.KIND_WILLOW)
			if not _card.has_point(pos):
				pts.append(pos)
		if pts.size() >= 2:
			var line_c: Color = color
			line_c.a = alpha * 0.82
			draw_polyline(pts, line_c, 2.4 * _ui_scale, true)
		if not pts.is_empty() and not _card.has_point(pts[0]):
			var tip: Color = color.lerp(Color(1, 1, 1, 1), 0.25)
			tip.a = alpha
			draw_circle(pts[0], 3.2 * _ui_scale, tip)

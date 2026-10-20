class_name CelebrationRainbows
extends Control

const Service := preload("res://celebration_rainbow_service.gd")

var _slots: Array[Dictionary] = []
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
	_slots = Service.rainbow_slots(
		viewport,
		Rect2(card.position, card.size),
		_ui_scale,
		Time.get_ticks_msec()
	)
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
	if not _playing or _slots.is_empty():
		return
	var colors: Array[Color] = Service.band_colors()
	var width: float = Service.band_width(_ui_scale)
	for i in range(_slots.size()):
		var slot: Dictionary = _slots[i]
		var drawn: float = Service.cycle_draw(
			_elapsed,
			float(slot.get("delay", float(i) * Service.STAGGER_SEC)),
			float(slot.get("cycle_sec", Service.CYCLE_SEC))
		)
		if drawn <= 0.02:
			continue
		var center: Vector2 = slot.center
		var radius: float = float(slot.radius)
		var rot: float = float(slot.rot)
		draw_set_transform(center, rot, Vector2.ONE)
		for b in range(colors.size()):
			var band: Color = colors[b]
			var r: float = radius - float(b) * width
			if r < 8.0:
				continue
			var pts: PackedVector2Array = Service.arc_points(Vector2.ZERO, r, 24, drawn)
			if pts.size() < 2:
				continue
			draw_polyline(pts, band, width * 1.15, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

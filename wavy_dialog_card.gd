class_name WavyDialogCard
extends Control

const Service := preload("res://wavy_dialog_card_service.gd")

var _ui_scale: float = 1.0
var _border: Color = Color(0.18, 0.32, 0.22, 1.0)
var _shadow: Color = Color(0.12, 0.22, 0.16, 0.38)
var _border_w: float = 10.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func configure(ui_scale: float, border: Color, shadow: Color) -> void:
	_ui_scale = maxf(ui_scale, 0.5)
	_border = border
	_shadow = shadow
	_border_w = clampf(10.0 * _ui_scale, 8.0, 14.0)
	queue_redraw()

func _draw() -> void:
	var amp: float = Service.amplitude_for_scale(_ui_scale)
	var outer: PackedVector2Array = Service.build_wave_points(
		size,
		amp,
		Service.WAVE_COUNT,
		Service.corner_for_scale(_ui_scale)
	)
	if outer.size() < 8:
		return
	var fill_pts: PackedVector2Array = Service.inset_along_normals(outer, _border_w)
	var shadow_pts: PackedVector2Array = Service.translated(
		outer,
		Vector2(0.0, round(6.0 * _ui_scale))
	)
	draw_colored_polygon(shadow_pts, _shadow)
	if fill_pts.size() >= 8:
		draw_polygon(fill_pts, Service.fill_colors_for(fill_pts, size))
		_draw_rainbow_border(outer, fill_pts)
	draw_polyline_colors(
		Service.closed_polyline(outer),
		Service.closed_rainbow_colors(outer.size()),
		3.2 * _ui_scale,
		true
	)

func _draw_rainbow_border(outer: PackedVector2Array, inner: PackedVector2Array) -> void:
	var n: int = mini(outer.size(), inner.size())
	if n < 8:
		return
	var colors: PackedColorArray = Service.perimeter_rainbow_colors(n)
	for i in range(n):
		var c0: Color = colors[i]
		var c1: Color = colors[(i + 1) % n]
		draw_polygon(
			Service.border_quad(outer, inner, i),
			PackedColorArray([c0, c1, c1, c0])
		)

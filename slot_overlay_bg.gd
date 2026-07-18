extends TextureRect

var _corner_radius_px: float = 16.0
var _color_celeste := Color(0.62, 0.82, 0.97, 0.94)
var _color_rosa := Color(0.98, 0.68, 0.84, 0.94)
var _color_verde := Color(0.66, 0.88, 0.68, 0.94)
var _last_size := Vector2.ZERO

func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(
	corner_px: int,
	celeste: Color,
	rosa: Color,
	verde: Color,
	pixel_size: Vector2 = Vector2.ZERO
) -> void:
	var corner_changed := not is_equal_approx(_corner_radius_px, float(corner_px))
	var colors_changed := (
		_color_celeste != celeste or _color_rosa != rosa or _color_verde != verde
	)
	_corner_radius_px = float(corner_px)
	_color_celeste = celeste
	_color_rosa = rosa
	_color_verde = verde
	if corner_changed or colors_changed:
		_last_size = Vector2.ZERO
	if pixel_size.x > 1.0 and pixel_size.y > 1.0:
		_refresh_gradient_for_size(pixel_size)
	else:
		_refresh_gradient()

func _refresh_gradient() -> void:
	_refresh_gradient_for_size(size)

func _refresh_gradient_for_size(target_size: Vector2) -> void:
	if target_size == _last_size and texture != null:
		return
	_last_size = target_size
	var w := int(maxi(target_size.x, 4.0))
	var h := int(maxi(target_size.y, 4.0))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var half := Vector2(w, h) * 0.5
	var radius := minf(_corner_radius_px, minf(half.x, half.y))
	for y in h:
		var uv_y := float(y) / float(maxi(h - 1, 1))
		for x in w:
			var uv := Vector2(float(x) / float(maxi(w - 1, 1)), uv_y)
			var col := _gradient_color_at(uv)
			var alpha := _rounded_alpha(Vector2(x, y) - half, half, radius)
			col.a *= alpha
			img.set_pixel(x, y, col)
	texture = ImageTexture.create_from_image(img)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_refresh_gradient")

func _gradient_color_at(uv: Vector2) -> Color:
	var t := clampf(uv.x * 0.40 + uv.y * 0.60, 0.0, 1.0)
	var col := _color_celeste.lerp(_color_rosa, smoothstep(0.0, 0.55, t))
	return col.lerp(_color_verde, smoothstep(0.42, 1.0, t))

func _rounded_alpha(p: Vector2, half: Vector2, radius: float) -> float:
	var q := Vector2(absf(p.x), absf(p.y)) - half + Vector2(radius, radius)
	var d := minf(maxf(q.x, q.y), 0.0) + Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() - radius
	return 1.0 - smoothstep(-1.0, 1.5, d)

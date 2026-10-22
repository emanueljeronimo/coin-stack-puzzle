extends Node2D

## Dibuja el numero como el HTML: centro de la ficha + middle + nudge.

var text: String = ""
var font: Font = null
var font_size: int = 16
var outline_px: int = 2
var outline_color: Color = Color(0, 0, 0, 1)
var fill_color: Color = Color(1, 1, 1, 1)
var shown: bool = false

func configure(
	p_text: String,
	p_font: Font,
	p_font_size: int,
	p_outline_px: int,
	p_outline_color: Color,
	p_fill_color: Color,
	p_width_scale: float,
	p_nudge: Vector2,
	p_shown: bool
) -> void:
	text = p_text
	font = p_font
	font_size = p_font_size
	outline_px = p_outline_px
	outline_color = p_outline_color
	fill_color = p_fill_color
	shown = p_shown
	position = p_nudge
	scale = Vector2(p_width_scale, 1.0)
	queue_redraw()

func _draw() -> void:
	if not shown or font == null or text.is_empty() or font_size < 1:
		return
	var pos: Vector2 = canvas_middle_draw_pos(font, text, font_size)
	if outline_px > 0:
		draw_string_outline(
			font,
			pos,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			outline_px,
			outline_color
		)
	draw_string(
		font,
		pos,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		fill_color
	)

static func face_side(radius: float, face_scale: float) -> float:
	return radius * 2.0 * face_scale

static func texture_side(texture: Texture2D) -> float:
	if texture == null:
		return 0.0
	var tex_size: Vector2 = texture.get_size()
	return maxf(tex_size.x, tex_size.y)

static func font_size_for_side(side: float, to_diameter: float) -> int:
	return maxi(8, int(round(side * to_diameter)))

static func outline_px_for_side(side: float) -> int:
	return maxi(2, int(round(side * 2.0 / 45.0)))

static func canvas_middle_draw_pos(font: Font, p_text: String, p_font_size: int) -> Vector2:
	if font == null or p_text.is_empty() or p_font_size < 1:
		return Vector2.ZERO
	var width: float = font.get_string_size(p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, p_font_size).x
	var baseline_y: float = (font.get_ascent(p_font_size) - font.get_descent(p_font_size)) * 0.5
	return Vector2(-width * 0.5, baseline_y)

static func outline_from_tint(face_tint: Color, darken_amount: float) -> Color:
	var outline: Color = face_tint.darkened(darken_amount)
	outline.a = 1.0
	return outline

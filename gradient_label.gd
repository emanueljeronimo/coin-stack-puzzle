extends Control

var display_text: String = ""
var font_size: int = 42
var color_start: Color = Color.WHITE
var color_end: Color = Color.WHITE
var outline_color: Color = Color.WHITE
var outline_size: int = 6

var _font: Font = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(
	font: Font,
	text: String,
	size: int,
	start: Color,
	end_color: Color,
	outline: Color,
	outline_sz: int
) -> void:
	_font = font
	display_text = text
	font_size = size
	color_start = start
	color_end = end_color
	outline_color = outline
	outline_size = outline_sz
	queue_redraw()

func apply_font_size(size: int) -> void:
	font_size = size
	queue_redraw()

func _draw() -> void:
	if _font == null or display_text.is_empty():
		return
	var full_size := _font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var glyph_pos := Vector2(
		(size.x - full_size.x) * 0.5,
		(size.y + _font.get_ascent(font_size) - _font.get_descent(font_size)) * 0.5
	)
	var char_count := display_text.length()
	for i in char_count:
		var ch: String = display_text[i]
		var code: int = ch.unicode_at(0)
		var t := float(i) / float(maxi(1, char_count - 1))
		var fill := color_start.lerp(color_end, t)
		if outline_size > 0:
			for ox in range(-outline_size, outline_size + 1):
				for oy in range(-outline_size, outline_size + 1):
					if ox == 0 and oy == 0:
						continue
					if ox * ox + oy * oy > outline_size * outline_size:
						continue
					_font.draw_char(get_canvas_item(), glyph_pos + Vector2(ox, oy), code, font_size, outline_color)
		glyph_pos.x += _font.draw_char(get_canvas_item(), glyph_pos, code, font_size, fill)

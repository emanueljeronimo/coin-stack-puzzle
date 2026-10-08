class_name BoardTutorialOverlay
extends Control

const SpeechFont = preload("res://Fonts/FredokaOne-Regular.ttf")
const ArrowTexture = preload("res://Imagenes/flecha-abajo.png")
const REF_WIDTH := 1080.0
const BUBBLE_FILL := Color(0.52, 0.78, 0.42, 0.98)
const BUBBLE_BORDER := Color(0.14, 0.40, 0.20)
const BUBBLE_SHADOW := Color(0.05, 0.20, 0.09, 0.28)
const TEXT_FILL := Color(0.99, 0.96, 0.88)
const TEXT_OUTLINE := Color(0.14, 0.40, 0.20)

var _bubble: TutorialSpeechBubble = null
var _speech: Label = null
var _pointer: TextureRect = null
var _bounce: Tween = null
var _pointer_base := Vector2.ZERO

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()

func open_step(text: String) -> void:
	if _speech != null:
		_speech.text = text
	visible = true

func close() -> void:
	visible = false
	if _bounce != null and _bounce.is_valid():
		_bounce.kill()
	_bounce = null

func layout_targets(viewport_size: Vector2, bubble_center: Vector2, pointer_pos: Vector2) -> void:
	var scale: float = clampf(minf(viewport_size.x / REF_WIDTH, viewport_size.y / 1920.0), 0.75, 1.25)
	var arrow_size := Vector2(176.0 * scale, 176.0 * scale)
	if _pointer != null:
		_pointer.size = arrow_size
		_pointer_base = Vector2(pointer_pos.x - arrow_size.x * 0.5, pointer_pos.y - arrow_size.y * 0.82)
		_pointer.position = _pointer_base
		_start_pointer_bounce(16.0 * scale)
	if _bubble != null:
		var bubble_w: float = minf(viewport_size.x * 0.78, 640.0 * scale)
		var body_h: float = 118.0 * scale
		var tail_h: float = 26.0 * scale
		_bubble.tail_height = tail_h
		_bubble.size = Vector2(bubble_w, body_h + tail_h)
		var bx: float = clampf(
			bubble_center.x - bubble_w * 0.5,
			12.0,
			viewport_size.x - bubble_w - 12.0
		)
		var by: float = _pointer_base.y - 10.0 * scale - body_h - tail_h
		by = clampf(by, 12.0, viewport_size.y - body_h - tail_h - 12.0)
		_bubble.position = Vector2(bx, by)
		_bubble.queue_redraw()
	if _speech != null:
		_speech.add_theme_font_size_override("font_size", int(32.0 * scale))
		_speech.add_theme_constant_override("outline_size", int(8.0 * scale))
		var pad: float = 18.0 * scale
		_speech.offset_left = pad
		_speech.offset_top = pad
		_speech.offset_right = -pad
		_speech.offset_bottom = -(_bubble.tail_height + pad * 0.35) if _bubble != null else -pad

func _build_ui() -> void:
	_bubble = TutorialSpeechBubble.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubble)

	_speech = Label.new()
	_speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speech.add_theme_color_override("font_color", TEXT_FILL)
	_speech.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	if SpeechFont != null:
		_speech.add_theme_font_override("font", SpeechFont)
	_bubble.add_child(_speech)

	_pointer = TextureRect.new()
	_pointer.texture = ArrowTexture
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pointer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_pointer)

func _start_pointer_bounce(distance: float) -> void:
	if _pointer == null:
		return
	if _bounce != null and _bounce.is_valid():
		_bounce.kill()
	_bounce = create_tween()
	_bounce.set_loops()
	_bounce.set_trans(Tween.TRANS_SINE)
	_bounce.set_ease(Tween.EASE_IN_OUT)
	_bounce.tween_property(_pointer, "position:y", _pointer_base.y + distance, 0.46)
	_bounce.tween_property(_pointer, "position:y", _pointer_base.y, 0.46)


class TutorialSpeechBubble extends Control:
	var tail_height := 26.0

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w < 8.0 or h < 8.0:
			return
		var tail_h: float = minf(tail_height, h * 0.28)
		var body := Rect2(0.0, 0.0, w, h - tail_h)
		var radius := minf(34.0, body.size.y * 0.42)
		_draw_round_rect(body.position + Vector2(5, 7), body.size, radius, BoardTutorialOverlay.BUBBLE_SHADOW)
		var tip := Vector2(w * 0.50, h - 1.0)
		var tail_l := Vector2(w * 0.42, body.size.y - 2.0)
		var tail_r := Vector2(w * 0.58, body.size.y - 2.0)
		draw_colored_polygon(
			PackedVector2Array([tip + Vector2(5, 7), tail_l + Vector2(5, 7), tail_r + Vector2(5, 7)]),
			BoardTutorialOverlay.BUBBLE_SHADOW
		)
		_draw_round_rect(body.position, body.size, radius, BoardTutorialOverlay.BUBBLE_BORDER)
		var inset := 5.0
		_draw_round_rect(
			body.position + Vector2(inset, inset),
			body.size - Vector2(inset * 2.0, inset * 2.0),
			maxf(8.0, radius - inset),
			BoardTutorialOverlay.BUBBLE_FILL
		)
		draw_colored_polygon(PackedVector2Array([tip, tail_l, tail_r]), BoardTutorialOverlay.BUBBLE_BORDER)
		var inner_tip := Vector2(w * 0.50, h - 7.0)
		var inner_l := Vector2(w * 0.445, body.size.y - inset)
		var inner_r := Vector2(w * 0.555, body.size.y - inset)
		draw_colored_polygon(PackedVector2Array([inner_tip, inner_l, inner_r]), BoardTutorialOverlay.BUBBLE_FILL)

	func _draw_round_rect(pos: Vector2, sz: Vector2, radius: float, color: Color) -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(int(round(radius)))
		draw_style_box(style, Rect2(pos, sz))

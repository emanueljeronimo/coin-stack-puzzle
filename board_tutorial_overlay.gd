class_name BoardTutorialOverlay
extends Control

const SpeechFont = preload("res://Fonts/FredokaOne-Regular.ttf")
const ArrowTexture = preload("res://Imagenes/flecha-abajo.png")
const BubbleTexture = preload("res://Imagenes/globo-dialogo.png")
const REF_WIDTH := 1080.0
const TEXT_FILL := Color(0.99, 0.96, 0.88)
const TEXT_OUTLINE := Color(0.42, 0.22, 0.58)
## Insets sobre el png. El globo visible esta un poco bajo en el recuadro; el texto va al centro.
const TEXT_PAD_LEFT := 0.12
const TEXT_PAD_RIGHT := 0.118
const TEXT_PAD_TOP := 0.22
const TEXT_PAD_BOTTOM := 0.25

var _bubble: TextureRect = null
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
		var aspect := 0.5
		if BubbleTexture != null and BubbleTexture.get_width() > 0:
			aspect = float(BubbleTexture.get_height()) / float(BubbleTexture.get_width())
		var bubble_w: float = minf(viewport_size.x * 0.78, 680.0 * scale)
		var bubble_h: float = bubble_w * aspect
		_bubble.size = Vector2(bubble_w, bubble_h)
		var bx: float = clampf(
			bubble_center.x - bubble_w * 0.5 + viewport_size.x * 0.28,
			8.0,
			viewport_size.x - bubble_w - 8.0
		)
		var by: float = _pointer_base.y - 8.0 * scale - bubble_h * 0.64
		by = clampf(by, 8.0, viewport_size.y - bubble_h - 8.0)
		_bubble.position = Vector2(bx, by)
	if _speech != null:
		_speech.add_theme_font_size_override("font_size", int(37.0 * scale))
		_speech.add_theme_constant_override("outline_size", int(11.0 * scale))
		if _bubble != null:
			_speech.offset_left = _bubble.size.x * TEXT_PAD_LEFT
			_speech.offset_top = _bubble.size.y * TEXT_PAD_TOP
			_speech.offset_right = -_bubble.size.x * TEXT_PAD_RIGHT
			_speech.offset_bottom = -_bubble.size.y * TEXT_PAD_BOTTOM

func _build_ui() -> void:
	_bubble = TextureRect.new()
	_bubble.texture = BubbleTexture
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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

class_name AboutOverlay
extends Control

const AboutFrameLayoutServiceScript = preload("res://about_frame_layout_service.gd")
const DialogBuilderServiceScript = preload("res://dialog_builder_service.gd")
const FRAME_PATH := "res://Imagenes/cartel-acerca-de.png"
const LogoFont = preload("res://Fonts/Lobster-Regular.ttf")
const INK := Color(0.42, 0.20, 0.60, 1.0)
const VERSION_OUTLINE := Color(1.00, 0.96, 0.92, 0.90)
const VERSION_TEXT := "Version 1.1"
const BODY_TEXT := "Creado con mucho cafe y pocas horas de sueño.\nGracias por jugar ♥\n\nProgramación - Arte - Musica: Carolina Birolo\nTesters (mis salvadores):\n♥ Belen Abechian - Jeronimo Alderete ♥"

var overlay: ColorRect = null
var card: Panel = null
var frame_art: TextureRect = null
var close_btn: Button = null
var version_label: Label = null
var body_label: Label = null
var _layout_busy := false
var _opened_at_msec := 0

func _ready() -> void:
	visible = false
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func open() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_opened_at_msec = Time.get_ticks_msec()
	if body_label != null:
		body_label.visible = true
		move_child(body_label, get_child_count() - 1)

func close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_open() -> bool:
	return visible

func layout_for_viewport(viewport_size: Vector2) -> void:
	if card == null or _layout_busy:
		return
	_layout_busy = true
	var tex_size := Vector2(937, 1311)
	if frame_art != null and frame_art.texture != null:
		tex_size = frame_art.texture.get_size()
	var card_size: Vector2 = AboutFrameLayoutServiceScript.card_size(viewport_size, tex_size)
	card.size = card_size
	card.position = Vector2(
		(viewport_size.x - card_size.x) * 0.5,
		(viewport_size.y - card_size.y) * 0.5
	)
	if frame_art != null:
		frame_art.position = Vector2.ZERO
		frame_art.size = card_size
	_place_mapped(close_btn, card_size, AboutFrameLayoutServiceScript.CLOSE_FRAC)
	_place_mapped(version_label, card_size, AboutFrameLayoutServiceScript.INTRO_FRAC)
	if version_label != null:
		_style_about_label(
			version_label,
			AboutFrameLayoutServiceScript.intro_font_size(
				AboutFrameLayoutServiceScript.mapped_rect(
					card_size,
					AboutFrameLayoutServiceScript.INTRO_FRAC
				).size.y
			)
		)
	_place_body(card_size)
	_layout_busy = false

func _place_body(card_size: Vector2) -> void:
	if body_label == null:
		return
	var well: Rect2 = AboutFrameLayoutServiceScript.mapped_rect(
		card_size,
		AboutFrameLayoutServiceScript.WELL_FRAC
	)
	body_label.position = card.position + well.position
	body_label.size = well.size
	body_label.custom_minimum_size = well.size
	body_label.visible = true
	body_label.z_index = 50
	body_label.clip_contents = false
	body_label.clip_text = false
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.text = BODY_TEXT
	var body_font: int = AboutFrameLayoutServiceScript.body_font_size(well.size.y)
	if LogoFont != null:
		var longest: String = "Programación - Arte - Musica: Carolina Birolo"
		while body_font > 34:
			var measured: Vector2 = LogoFont.get_string_size(
				longest,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				body_font
			)
			if measured.x <= well.size.x * 1.02:
				break
			body_font -= 1
	_style_about_label(body_label, body_font)
	body_label.add_theme_constant_override(
		"line_spacing",
		AboutFrameLayoutServiceScript.body_line_spacing(body_font)
	)

func _style_about_label(lbl: Label, font_size: int) -> void:
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", INK)
	lbl.add_theme_color_override("font_outline_color", VERSION_OUTLINE)
	lbl.add_theme_constant_override("outline_size", maxi(int(round(float(font_size) * 0.10)), 4))
	if LogoFont != null:
		lbl.add_theme_font_override("font", LogoFont)

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.05, 0.04, 0.10, 0.78)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_dimmer_input)
	add_child(overlay)

	card = Panel.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.clip_contents = false
	card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(card)

	frame_art = TextureRect.new()
	if ResourceLoader.exists(FRAME_PATH):
		frame_art.texture = load(FRAME_PATH) as Texture2D
	frame_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_art.stretch_mode = TextureRect.STRETCH_SCALE
	frame_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_art.z_index = 0
	card.add_child(frame_art)

	close_btn = _make_empty_button()
	close_btn.pressed.connect(close)
	card.add_child(close_btn)

	version_label = _make_about_label(VERSION_TEXT)
	version_label.z_index = 6
	card.add_child(version_label)

	body_label = _make_about_label(BODY_TEXT)
	body_label.z_index = 50
	add_child(body_label)

func _make_about_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = false
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", INK)
	lbl.add_theme_color_override("font_outline_color", VERSION_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 4)
	if LogoFont != null:
		lbl.add_theme_font_override("font", LogoFont)
	return lbl

func _place_mapped(node: Control, card_size: Vector2, frac: Rect2) -> void:
	if node == null:
		return
	var rect: Rect2 = AboutFrameLayoutServiceScript.mapped_rect(card_size, frac)
	node.position = rect.position
	node.size = rect.size

func _make_empty_button() -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	GameState.hook_button_sound(btn)
	return btn

func _on_dimmer_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if DialogBuilderServiceScript.should_ignore_open_click(_opened_at_msec, Time.get_ticks_msec()):
		return
	var mouse_event := event as InputEventMouseButton
	if card != null and card.get_global_rect().has_point(mouse_event.global_position):
		return
	close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible and not _layout_busy:
		layout_for_viewport(get_viewport_rect().size)

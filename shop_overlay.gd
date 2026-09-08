class_name ShopOverlay
extends Control

const REF_WIDTH := 1080.0
const LogoFont = preload("res://Fonts/Chewy-Regular.ttf")
const CLOSE_RED := Color(0.90, 0.22, 0.24, 1.0)
const CLOSE_RED_BORDER := Color(0.55, 0.10, 0.12, 1.0)

var overlay: ColorRect = null
var card: Panel = null
var card_margin: MarginContainer = null
var main_vbox: VBoxContainer = null
var header: Control = null
var title_label: Label = null
var close_btn: Button = null
var content_well: Panel = null
var content_margin: MarginContainer = null
var placeholder_label: Label = null
var _close_menu_btn: Button = null
var _opened_at_msec: int = 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()
	if not GameState.background_theme_changed.is_connected(_on_background_theme_changed):
		GameState.background_theme_changed.connect(_on_background_theme_changed)
	_apply_theme_colors()

func open() -> void:
	_apply_theme_colors()
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_opened_at_msec = Time.get_ticks_msec()

func close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_open() -> bool:
	return visible

func _on_background_theme_changed(_theme_id: String) -> void:
	_apply_theme_colors()

func layout_for_viewport(viewport_size: Vector2) -> void:
	if card == null:
		return
	var scale := viewport_size.x / REF_WIDTH
	var card_w := viewport_size.x * 0.94
	var outer_pad := int(16.0 * scale)
	var top_pad := int(16.0 * scale)
	var bottom_pad := int(16.0 * scale)
	var sep := int(14.0 * scale)

	if card_margin != null:
		card_margin.add_theme_constant_override("margin_left", outer_pad)
		card_margin.add_theme_constant_override("margin_top", top_pad)
		card_margin.add_theme_constant_override("margin_right", outer_pad)
		card_margin.add_theme_constant_override("margin_bottom", bottom_pad)
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", sep)

	var header_h := 64.0 * scale
	if header != null:
		header.custom_minimum_size = Vector2(0, header_h)
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(52 * scale))
		title_label.add_theme_constant_override("outline_size", int(8 * scale))
	if close_btn != null:
		var close_side := 64.0 * scale
		close_btn.custom_minimum_size = Vector2(close_side, close_side)
		close_btn.add_theme_font_size_override("font_size", int(36 * scale))
		close_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		close_btn.offset_left = -close_side
		close_btn.offset_top = -close_side * 0.5
		close_btn.offset_right = 0
		close_btn.offset_bottom = close_side * 0.5

	var well_pad := int(14.0 * scale)
	if content_margin != null:
		content_margin.add_theme_constant_override("margin_left", well_pad)
		content_margin.add_theme_constant_override("margin_top", well_pad)
		content_margin.add_theme_constant_override("margin_right", well_pad)
		content_margin.add_theme_constant_override("margin_bottom", well_pad)
	if placeholder_label != null:
		placeholder_label.add_theme_font_size_override("font_size", int(36 * scale))
		placeholder_label.add_theme_constant_override("outline_size", int(6 * scale))

	var content_h := 280.0 * scale
	if content_well != null:
		content_well.custom_minimum_size = Vector2(0, content_h)

	var footer_h := 80.0 * scale
	if _close_menu_btn != null:
		_close_menu_btn.custom_minimum_size = Vector2(0, footer_h)
		_close_menu_btn.add_theme_font_size_override("font_size", int(40 * scale))

	var card_h := (
		header_h
		+ content_h
		+ footer_h
		+ float(sep) * 2.0
		+ float(top_pad + bottom_pad)
	)
	card_h = mini(card_h, viewport_size.y * 0.96)
	card.size = Vector2(card_w, card_h)
	card.position = Vector2((viewport_size.x - card_w) * 0.5, (viewport_size.y - card_h) * 0.5)

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.05, 0.04, 0.10, 0.78)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_dimmer_input)
	add_child(overlay)

	card = Panel.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card)

	card_margin = MarginContainer.new()
	card_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_margin.add_theme_constant_override("margin_left", 14)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_right", 14)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(card_margin)

	main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_theme_constant_override("separation", 12)
	card_margin.add_child(main_vbox)

	header = Control.new()
	header.custom_minimum_size = Vector2(0, 58)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)

	title_label = _make_outlined_label("Tienda", 46)
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)

	close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.custom_minimum_size = Vector2(56, 56)
	close_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	close_btn.offset_left = -56
	close_btn.offset_top = -28
	close_btn.offset_right = 0
	close_btn.offset_bottom = 28
	if LogoFont != null:
		close_btn.add_theme_font_override("font", LogoFont)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	content_well = Panel.new()
	content_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_well)

	content_margin = MarginContainer.new()
	content_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", 10)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_right", 10)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	content_well.add_child(content_margin)

	placeholder_label = _make_outlined_label("Próximamente", 36)
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(placeholder_label)

	_close_menu_btn = _make_action_button("Cerrar")
	_close_menu_btn.pressed.connect(close)
	main_vbox.add_child(_close_menu_btn)

	_apply_theme_colors()

func _make_outlined_label(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.86, 0.83))
	lbl.add_theme_color_override("font_outline_color", Color(0.22, 0.20, 0.24, 0.78))
	lbl.add_theme_constant_override("outline_size", 5)
	if LogoFont != null:
		lbl.add_theme_font_override("font", LogoFont)
	return lbl

func _make_action_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, 64)
	if LogoFont != null:
		btn.add_theme_font_override("font", LogoFont)
	btn.add_theme_font_size_override("font_size", 34)
	return btn

func _flat_style(bg: Color, border: Color, radius: int, border_w: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_w
	style.border_width_top = border_w
	style.border_width_right = border_w
	style.border_width_bottom = border_w
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _apply_button_style(btn: Button, bg: Color, border: Color, radius: int, font_color: Color) -> void:
	if btn == null:
		return
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.14, 0.9))
	btn.add_theme_constant_override("outline_size", 5)
	var style := _flat_style(bg, border, radius)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)

func _apply_theme_colors() -> void:
	var p: Dictionary = GameState.get_ui_palette()
	var card_bg: Color = p.get("settings_card_bg", Color(0.62, 0.52, 0.82, 0.98))
	card_bg = card_bg.lightened(0.18)
	var card_border: Color = p.get("settings_card_border", Color(0.42, 0.28, 0.58, 0.95))
	card_border = card_border.darkened(0.35)
	var inset: Color = p.get("settings_btn_off", Color(0.34, 0.26, 0.48, 0.95))
	inset.a = 0.98
	var well: Color = inset.darkened(0.12)
	well.a = 0.98
	var text_marble := Color(0.88, 0.86, 0.83)
	var btn_on: Color = p.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98))
	var btn_border: Color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))

	if card != null:
		card.add_theme_stylebox_override("panel", _flat_style(card_bg, card_border, 30, 4))
	if content_well != null:
		content_well.add_theme_stylebox_override("panel", _flat_style(well, card_border.darkened(0.15), 20, 2))
	_apply_button_style(close_btn, CLOSE_RED, CLOSE_RED_BORDER, 14, Color(0.90, 0.88, 0.85))
	if title_label != null:
		title_label.add_theme_color_override("font_color", p.get("settings_title", text_marble))
	if placeholder_label != null:
		placeholder_label.add_theme_color_override("font_color", p.get("settings_section", text_marble))
	_apply_button_style(_close_menu_btn, btn_on, btn_border, 22, text_marble)

func _on_dimmer_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	# El toque que abre el menú no debe cerrarlo en el mismo frame.
	if Time.get_ticks_msec() - _opened_at_msec < 250:
		return
	var mouse_event := event as InputEventMouseButton
	var point: Vector2 = mouse_event.global_position
	if card != null and not card.get_global_rect().has_point(point):
		close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		layout_for_viewport(get_viewport_rect().size)

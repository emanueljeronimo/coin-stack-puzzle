class_name SettingsOverlay
extends Control

signal restart_level_confirmed

const REF_WIDTH := 1080.0
const LogoFont = preload("res://Fonts/Chewy-Regular.ttf")
const CLOSE_RED := Color(0.90, 0.22, 0.24, 1.0)
const CLOSE_RED_BORDER := Color(0.55, 0.10, 0.12, 1.0)
const SELECT_GREEN := Color(0.32, 0.86, 0.28, 1.0)

var overlay: ColorRect = null
var card: Panel = null
var card_margin: MarginContainer = null
var main_vbox: VBoxContainer = null
var header: Control = null
var title_label: Label = null
var close_btn: Button = null
var toggles_well: Panel = null
var toggles_margin: MarginContainer = null
var toggles_box: VBoxContainer = null
var bg_section_label: Label = null
var themes_well: Panel = null
var themes_margin: MarginContainer = null
var theme_grid: GridContainer = null
var theme_option_roots: Array[Panel] = []
var _toggle_rows: Array[HBoxContainer] = []
var _toggle_labels: Array[Label] = []
var _toggle_btns: Array[Button] = []
var _toggle_setters: Array[Callable] = []
var _footer_row: HBoxContainer = null
var _restart_btn: Button = null
var _close_menu_btn: Button = null
var _restart_available := false
var _confirm_root: Control = null
var _confirm_card: Panel = null
var _confirm_title: Label = null
var _confirm_salir_btn: Button = null
var _confirm_atras_btn: Button = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()
	if not GameState.background_theme_changed.is_connected(_on_background_theme_changed):
		GameState.background_theme_changed.connect(_on_background_theme_changed)
	_apply_theme_colors()

func open() -> void:
	_hide_restart_confirm()
	_apply_theme_colors()
	_refresh_theme_selection()
	_refresh_toggle_states()
	_sync_restart_button_visibility()
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func close() -> void:
	_hide_restart_confirm()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_open() -> bool:
	return visible

## Solo en partida: muestra el botón Reiniciar.
func set_restart_available(available: bool) -> void:
	_restart_available = available
	_sync_restart_button_visibility()

func _on_background_theme_changed(_theme_id: String) -> void:
	_apply_theme_colors()
	if visible:
		_refresh_theme_selection()

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
	if toggles_margin != null:
		toggles_margin.add_theme_constant_override("margin_left", well_pad)
		toggles_margin.add_theme_constant_override("margin_top", well_pad)
		toggles_margin.add_theme_constant_override("margin_right", well_pad)
		toggles_margin.add_theme_constant_override("margin_bottom", well_pad)
	if themes_margin != null:
		themes_margin.add_theme_constant_override("margin_left", well_pad)
		themes_margin.add_theme_constant_override("margin_top", well_pad)
		themes_margin.add_theme_constant_override("margin_right", well_pad)
		themes_margin.add_theme_constant_override("margin_bottom", well_pad)

	var toggle_h := 64.0 * scale
	var toggle_font := int(36 * scale)
	var toggle_btn := Vector2(132.0 * scale, 56.0 * scale)
	for i in range(_toggle_labels.size()):
		_toggle_labels[i].add_theme_font_size_override("font_size", toggle_font)
		_toggle_labels[i].add_theme_constant_override("outline_size", int(6 * scale))
	for i in range(_toggle_btns.size()):
		_toggle_btns[i].custom_minimum_size = toggle_btn
		_toggle_btns[i].add_theme_font_size_override("font_size", int(26 * scale))
	for row in _toggle_rows:
		row.custom_minimum_size = Vector2(0, toggle_h)
	var toggles_block_h := toggle_h * 3.0 + float(sep) * 2.0 + float(well_pad) * 2.0
	if toggles_well != null:
		toggles_well.custom_minimum_size = Vector2(0, toggles_block_h)

	var section_h := 50.0 * scale
	if bg_section_label != null:
		bg_section_label.add_theme_font_size_override("font_size", int(40 * scale))
		bg_section_label.add_theme_constant_override("outline_size", int(7 * scale))
		bg_section_label.custom_minimum_size = Vector2(0, section_h)

	var gap := 14.0 * scale
	if theme_grid != null:
		theme_grid.add_theme_constant_override("h_separation", int(gap))
		theme_grid.add_theme_constant_override("v_separation", int(gap))
	var grid_w := card_w - float(outer_pad) * 2.0 - float(well_pad) * 2.0
	var cell_w := (grid_w - gap * 2.0) / 3.0
	# Miniaturas casi a todo el ancho de cada celda (sin tope chico).
	var preview_side := cell_w * 0.92
	var option_h := preview_side + 12.0 * scale
	for option in theme_option_roots:
		if option == null:
			continue
		option.custom_minimum_size = Vector2(cell_w, option_h)
		for child in option.get_children():
			if child is TextureButton:
				(child as TextureButton).custom_minimum_size = Vector2(preview_side, preview_side)
	var theme_rows := ceili(float(maxi(theme_option_roots.size(), 1)) / 3.0)
	var grid_h := option_h * float(theme_rows) + gap * float(maxi(theme_rows - 1, 0))
	var themes_h := grid_h + float(well_pad) * 2.0
	if themes_well != null:
		themes_well.custom_minimum_size = Vector2(0, themes_h)

	var footer_h := 80.0 * scale
	var action_font := int(40 * scale)
	if _restart_btn != null:
		_restart_btn.custom_minimum_size = Vector2(0, footer_h)
		_restart_btn.add_theme_font_size_override("font_size", action_font)
	if _close_menu_btn != null:
		_close_menu_btn.custom_minimum_size = Vector2(0, footer_h)
		_close_menu_btn.add_theme_font_size_override("font_size", action_font)

	var content_h := (
		header_h
		+ toggles_block_h
		+ section_h
		+ themes_h
		+ footer_h
		+ float(sep) * 4.0
		+ float(top_pad + bottom_pad)
	)
	var card_h := mini(content_h, viewport_size.y * 0.96)
	card.size = Vector2(card_w, card_h)
	card.position = Vector2((viewport_size.x - card_w) * 0.5, (viewport_size.y - card_h) * 0.5)

	if _confirm_title != null:
		_confirm_title.add_theme_font_size_override("font_size", int(38 * scale))
		_confirm_title.add_theme_constant_override("outline_size", int(7 * scale))
	if _confirm_salir_btn != null:
		_confirm_salir_btn.custom_minimum_size = Vector2(0, 72.0 * scale)
		_confirm_salir_btn.add_theme_font_size_override("font_size", int(36 * scale))
	if _confirm_atras_btn != null:
		_confirm_atras_btn.custom_minimum_size = Vector2(0, 72.0 * scale)
		_confirm_atras_btn.add_theme_font_size_override("font_size", int(36 * scale))
	_layout_confirm_card(scale)

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

	# Header: título centrado + X rojo (mismo formato que perfil).
	header = Control.new()
	header.custom_minimum_size = Vector2(0, 58)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)

	title_label = _make_outlined_label("Configuración", 46)
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

	toggles_well = Panel.new()
	toggles_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggles_well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_child(toggles_well)

	toggles_margin = MarginContainer.new()
	toggles_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	toggles_margin.add_theme_constant_override("margin_left", 10)
	toggles_margin.add_theme_constant_override("margin_top", 10)
	toggles_margin.add_theme_constant_override("margin_right", 10)
	toggles_margin.add_theme_constant_override("margin_bottom", 10)
	toggles_well.add_child(toggles_margin)

	toggles_box = VBoxContainer.new()
	toggles_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggles_box.add_theme_constant_override("separation", 10)
	toggles_margin.add_child(toggles_box)

	_add_toggle_row(toggles_box, "Música", _get_music_enabled, _set_music_enabled)
	_add_toggle_row(toggles_box, "Sonidos", _get_sounds_enabled, _set_sounds_enabled)
	_add_toggle_row(toggles_box, "Vibración", _get_vibration_enabled, _set_vibration_enabled)

	bg_section_label = _make_outlined_label("Elegir fondo:", 36)
	bg_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg_section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bg_section_label)

	themes_well = Panel.new()
	themes_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	themes_well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_child(themes_well)

	themes_margin = MarginContainer.new()
	themes_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	themes_margin.add_theme_constant_override("margin_left", 10)
	themes_margin.add_theme_constant_override("margin_top", 10)
	themes_margin.add_theme_constant_override("margin_right", 10)
	themes_margin.add_theme_constant_override("margin_bottom", 10)
	themes_well.add_child(themes_margin)

	theme_grid = GridContainer.new()
	theme_grid.columns = 3
	theme_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theme_grid.add_theme_constant_override("h_separation", 10)
	theme_grid.add_theme_constant_override("v_separation", 10)
	themes_margin.add_child(theme_grid)

	for theme in GameState.get_background_themes():
		var option := _build_theme_option(theme)
		theme_grid.add_child(option)
		theme_option_roots.append(option)

	_footer_row = HBoxContainer.new()
	_footer_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(_footer_row)

	_restart_btn = _make_action_button("Reiniciar nivel")
	_restart_btn.pressed.connect(_on_restart_pressed)
	_restart_btn.visible = false
	_footer_row.add_child(_restart_btn)

	_close_menu_btn = _make_action_button("Cerrar")
	_close_menu_btn.pressed.connect(close)
	_footer_row.add_child(_close_menu_btn)

	_build_restart_confirm()
	_apply_theme_colors()

func _build_restart_confirm() -> void:
	_confirm_root = Control.new()
	_confirm_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_root.visible = false
	_confirm_root.z_index = 50
	add_child(_confirm_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.04, 0.10, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_root.add_child(dim)

	_confirm_card = Panel.new()
	_confirm_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_root.add_child(_confirm_card)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_confirm_card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	_confirm_title = _make_outlined_label("¿Desea reiniciar nivel?\nPerderá una vida", 34)
	_confirm_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_confirm_title)

	_confirm_salir_btn = _make_action_button("Salir")
	_confirm_salir_btn.pressed.connect(_on_confirm_salir_pressed)
	vbox.add_child(_confirm_salir_btn)

	_confirm_atras_btn = _make_action_button("Atrás")
	_confirm_atras_btn.pressed.connect(_on_confirm_atras_pressed)
	vbox.add_child(_confirm_atras_btn)

func _sync_restart_button_visibility() -> void:
	if _restart_btn != null:
		_restart_btn.visible = _restart_available
	if _close_menu_btn != null:
		_close_menu_btn.size_flags_stretch_ratio = 1.0 if _restart_available else 2.0

func _show_restart_confirm() -> void:
	if _confirm_root == null:
		return
	_confirm_root.visible = true
	_layout_confirm_card(get_viewport_rect().size.x / REF_WIDTH)

func _hide_restart_confirm() -> void:
	if _confirm_root != null:
		_confirm_root.visible = false

func _layout_confirm_card(scale: float) -> void:
	if _confirm_card == null:
		return
	var vp := get_viewport_rect().size
	var card_w := vp.x * 0.82
	var card_h := maxf(360.0 * scale, vp.y * 0.32)
	_confirm_card.size = Vector2(card_w, card_h)
	_confirm_card.position = Vector2((vp.x - card_w) * 0.5, (vp.y - card_h) * 0.5)

func _on_restart_pressed() -> void:
	_show_restart_confirm()

func _on_confirm_atras_pressed() -> void:
	_hide_restart_confirm()

func _on_confirm_salir_pressed() -> void:
	_hide_restart_confirm()
	restart_level_confirmed.emit()

func _make_outlined_label(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.99, 0.99, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.14, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)
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

	if card != null:
		card.add_theme_stylebox_override("panel", _flat_style(card_bg, card_border, 30, 4))
	if toggles_well != null:
		toggles_well.add_theme_stylebox_override("panel", _flat_style(well, card_border.darkened(0.15), 20, 2))
	if themes_well != null:
		themes_well.add_theme_stylebox_override("panel", _flat_style(well, card_border.darkened(0.15), 20, 2))
	if _confirm_card != null:
		_confirm_card.add_theme_stylebox_override("panel", _flat_style(card_bg, card_border, 30, 4))

	_apply_button_style(close_btn, CLOSE_RED, CLOSE_RED_BORDER, 14, Color(1, 1, 1))
	var btn_on: Color = p.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98))
	var btn_border: Color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))
	_apply_button_style(_close_menu_btn, btn_on, btn_border, 22, Color(1, 1, 1))
	_apply_button_style(_restart_btn, p.get("settings_btn_off", Color(0.40, 0.50, 0.40, 0.95)), card_border, 22, Color(1, 1, 1))
	_apply_button_style(_confirm_salir_btn, btn_on, btn_border, 22, Color(1, 1, 1))
	_apply_button_style(_confirm_atras_btn, p.get("settings_btn_off", Color(0.40, 0.50, 0.40, 0.95)), card_border, 22, Color(1, 1, 1))

	for i in range(_toggle_btns.size()):
		_apply_toggle_style(_toggle_btns[i], _toggle_btns[i].button_pressed)
	_refresh_theme_selection()

func _add_toggle_row(
	parent: VBoxContainer,
	label_text: String,
	getter: Callable,
	setter: Callable
) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	_toggle_rows.append(row)

	var lbl := _make_outlined_label(label_text, 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	_toggle_labels.append(lbl)

	var toggle_idx := _toggle_btns.size()
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.toggle_mode = true
	btn.pressed.connect(_on_toggle_pressed.bind(toggle_idx))
	if LogoFont != null:
		btn.add_theme_font_override("font", LogoFont)
	row.add_child(btn)
	_toggle_btns.append(btn)
	_toggle_setters.append(setter)
	btn.button_pressed = bool(getter.call())
	_apply_toggle_style(btn, btn.button_pressed)

func _get_music_enabled() -> bool:
	return GameState.music_enabled

func _get_sounds_enabled() -> bool:
	return GameState.sounds_enabled

func _get_vibration_enabled() -> bool:
	return GameState.vibration_enabled

func _set_music_enabled(enabled: bool) -> void:
	GameState.set_music_enabled(enabled)

func _set_sounds_enabled(enabled: bool) -> void:
	GameState.set_sounds_enabled(enabled)

func _set_vibration_enabled(enabled: bool) -> void:
	GameState.set_vibration_enabled(enabled)

func _on_toggle_pressed(index: int) -> void:
	if index < 0 or index >= _toggle_btns.size():
		return
	var btn: Button = _toggle_btns[index]
	var enabled: bool = btn.button_pressed
	_apply_toggle_style(btn, enabled)
	if index < _toggle_setters.size():
		_toggle_setters[index].call(enabled)

func _refresh_toggle_states() -> void:
	if _toggle_btns.size() < 3:
		return
	_sync_toggle_btn(0, GameState.music_enabled)
	_sync_toggle_btn(1, GameState.sounds_enabled)
	_sync_toggle_btn(2, GameState.vibration_enabled)

func _sync_toggle_btn(index: int, on: bool) -> void:
	_toggle_btns[index].button_pressed = on
	_apply_toggle_style(_toggle_btns[index], on)

func _apply_toggle_style(btn: Button, is_on: bool) -> void:
	btn.text = "ON" if is_on else "OFF"
	var p: Dictionary = GameState.get_ui_palette()
	if is_on:
		_apply_button_style(
			btn,
			p.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98)),
			p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0)),
			14,
			Color(1, 1, 1)
		)
	else:
		_apply_button_style(
			btn,
			p.get("settings_btn_off", Color(0.40, 0.50, 0.40, 0.95)),
			p.get("settings_card_border", Color(0.52, 0.60, 0.48, 0.9)).darkened(0.2),
			14,
			Color(0.98, 0.98, 1.0)
		)

func _build_theme_option(theme: Dictionary) -> Panel:
	var theme_id := str(theme.get("id", ""))
	var wrap := Panel.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.set_meta("theme_id", theme_id)

	var preview := TextureButton.new()
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.offset_left = 6
	preview.offset_top = 6
	preview.offset_right = -6
	preview.offset_bottom = -6
	preview.texture_normal = load(str(theme.get("path", ""))) as Texture2D
	preview.ignore_texture_size = true
	preview.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	preview.clip_contents = true
	preview.focus_mode = Control.FOCUS_NONE
	preview.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	preview.pressed.connect(_on_theme_option_pressed.bind(theme_id))
	wrap.add_child(preview)
	return wrap

func _apply_theme_option_style(option: Panel, selected: bool) -> void:
	var border := SELECT_GREEN if selected else Color(0, 0, 0, 0)
	var bg := Color(1, 1, 1, 0.10) if selected else Color(1, 1, 1, 0.04)
	option.add_theme_stylebox_override("panel", _flat_style(bg, border, 14, 4 if selected else 0))

func _refresh_theme_selection() -> void:
	var current := GameState.background_theme_id
	for option in theme_option_roots:
		if option == null:
			continue
		_apply_theme_option_style(option, str(option.get_meta("theme_id", "")) == current)

func _on_theme_option_pressed(theme_id: String) -> void:
	GameState.set_background_theme(theme_id)
	_refresh_theme_selection()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _confirm_root != null and _confirm_root.visible:
			_hide_restart_confirm()
			return
		if card != null and not card.get_global_rect().has_point((event as InputEventMouseButton).position):
			close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		layout_for_viewport(get_viewport_rect().size)

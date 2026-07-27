class_name SettingsOverlay
extends Control

signal restart_level_confirmed

const REF_WIDTH := 1080.0
const CARD_BG := Color(0.58, 0.68, 0.54, 0.98)
const CARD_BORDER := Color(0.48, 0.58, 0.44, 0.95)
const TITLE_COLOR := Color(0.96, 0.98, 0.94)
const LABEL_COLOR := Color(0.92, 0.96, 0.90)
const SECTION_COLOR := Color(0.90, 0.95, 0.88)

var overlay: ColorRect = null
var card: Panel = null
var close_x_btn: Button = null
var content_scroll: ScrollContainer = null
var theme_grid: GridContainer = null
var theme_option_roots: Array[Panel] = []
var _main_title: Label = null
var _bg_section_label: Label = null
var _toggle_rows: Array[HBoxContainer] = []
var _toggle_labels: Array[Label] = []
var _toggle_btns: Array[Button] = []
var _toggle_setters: Array[Callable] = []
var _restart_btn: Button = null
var _close_menu_btn: Button = null
var _footer_row: HBoxContainer = null
var _restart_available := false
var _confirm_root: Control = null
var _confirm_card: Panel = null
var _confirm_title: Label = null
var _confirm_salir_btn: Button = null
var _confirm_atras_btn: Button = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
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
	call_deferred("_ensure_close_on_top")

func _on_background_theme_changed(_theme_id: String) -> void:
	_apply_theme_colors()
	if visible:
		_refresh_theme_selection()

## Recolorea cartel, toggles y botones según la paleta del fondo actual.
func _apply_theme_colors() -> void:
	var p: Dictionary = GameState.get_ui_palette()
	var card_bg: Color = p.get("settings_card_bg", CARD_BG)
	var card_border: Color = p.get("settings_card_border", CARD_BORDER)
	var title_c: Color = p.get("settings_title", TITLE_COLOR)
	var label_c: Color = p.get("settings_label", LABEL_COLOR)
	var section_c: Color = p.get("settings_section", SECTION_COLOR)
	var btn_on: Color = p.get("settings_btn_on", Color(0.64, 0.83, 0.43, 0.98))
	var btn_off: Color = p.get("settings_btn_off", Color(0.42, 0.50, 0.40, 0.95))
	var btn_border: Color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))

	_set_panel_style(card, card_bg, card_border)
	_set_panel_style(_confirm_card, card_bg, card_border)

	if _main_title != null:
		_main_title.add_theme_color_override("font_color", title_c)
	if _bg_section_label != null:
		_bg_section_label.add_theme_color_override("font_color", section_c)
	if _confirm_title != null:
		_confirm_title.add_theme_color_override("font_color", title_c)
	for lbl in _toggle_labels:
		if lbl != null:
			lbl.add_theme_color_override("font_color", label_c)

	_style_flat_button(close_x_btn, btn_off, btn_border)
	_style_flat_button(_restart_btn, btn_on, btn_border)
	_style_flat_button(_close_menu_btn, btn_off, btn_border)
	_style_flat_button(_confirm_salir_btn, btn_on, btn_border)
	_style_flat_button(_confirm_atras_btn, btn_off, btn_border)

	for i in range(_toggle_btns.size()):
		_apply_toggle_style(_toggle_btns[i], _toggle_btns[i].button_pressed)

	_refresh_theme_selection()

func _set_panel_style(panel: Panel, bg: Color, border: Color) -> void:
	if panel == null:
		return
	var style: StyleBox = panel.get_theme_stylebox("panel")
	var flat: StyleBoxFlat
	if style is StyleBoxFlat:
		flat = (style as StyleBoxFlat).duplicate() as StyleBoxFlat
	else:
		flat = StyleBoxFlat.new()
		flat.border_width_left = 2
		flat.border_width_top = 2
		flat.border_width_right = 2
		flat.border_width_bottom = 2
		flat.corner_radius_top_left = 28
		flat.corner_radius_top_right = 28
		flat.corner_radius_bottom_left = 28
		flat.corner_radius_bottom_right = 28
	flat.bg_color = bg
	flat.border_color = border
	panel.add_theme_stylebox_override("panel", flat)

func _style_flat_button(btn: Button, bg: Color, border: Color) -> void:
	if btn == null:
		return
	btn.add_theme_color_override("font_color", Color(0.98, 0.99, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.98))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)

func close() -> void:
	_hide_restart_confirm()
	visible = false

func is_open() -> bool:
	return visible

## Solo en partida: muestra el botón Reiniciar debajo de los fondos.
func set_restart_available(available: bool) -> void:
	_restart_available = available
	_sync_restart_button_visibility()

func layout_for_viewport(viewport_size: Vector2) -> void:
	if card == null:
		return
	var scale := viewport_size.x / REF_WIDTH
	var card_w := viewport_size.x * 0.70
	# Primero escalar contenido; después ajustar altura al contenido (con un poco de aire).
	_apply_scaled_content(scale, card_w)
	var card_h := clampf(
		_measure_content_height(scale, card_w),
		viewport_size.y * 0.36,
		viewport_size.y * 0.82
	)
	card.size = Vector2(card_w, card_h)
	card.position = Vector2((viewport_size.x - card_w) * 0.5, (viewport_size.y - card_h) * 0.5)
	_position_close_button()

func _measure_content_height(scale: float, card_w: float) -> float:
	var panel_scale := clampf(card_w / (REF_WIDTH * 0.47), 0.55, 1.0)
	var title_h := 38.0 * scale * panel_scale * 1.35
	var toggle_h := maxf(48.0 * scale * panel_scale, 34.0 * scale * panel_scale * 1.35)
	var toggles_block := toggle_h * 3.0 + 14.0 * 2.0
	var section_h := 40.0 * scale * panel_scale * 1.35
	var cell_w := (card_w - 56.0 * scale) / 3.0 - 12.0 * scale
	var preview_side := mini(cell_w * 0.62, 108.0 * scale * panel_scale)
	var option_h := preview_side + 36.0 * scale
	var theme_rows := 2
	var grid_h := option_h * float(theme_rows) + 12.0 * float(theme_rows - 1)
	var restart_h := 0.0
	# Fila inferior siempre presente (Cerrar; Reiniciar solo en partida).
	restart_h = 56.0 * scale * panel_scale * 0.85 + 8.0 * scale
	var child_count := 5
	var separation := 24.0 * float(child_count - 1)
	var margins := 52.0 + 24.0
	# Holgura para que entre todo sin scrollbar, sin volver al vacío grande.
	var pad := 40.0 * scale
	return margins + title_h + toggles_block + section_h + grid_h + restart_h + separation + pad

func _apply_scaled_content(scale: float, card_w: float) -> void:
	var panel_scale := clampf(card_w / (REF_WIDTH * 0.47), 0.55, 1.0)
	var title_size := int(38.0 * scale * panel_scale)
	var row_label_size := int(34.0 * scale * panel_scale)
	var section_size := int(40.0 * scale * panel_scale)
	var toggle_btn_size := Vector2(96.0 * scale * panel_scale, 48.0 * scale * panel_scale)
	var action_btn_h := 48.0 * scale * panel_scale
	var action_font := int(24.0 * scale * panel_scale)

	if _main_title != null:
		_main_title.add_theme_font_size_override("font_size", title_size)
	if _bg_section_label != null:
		_bg_section_label.add_theme_font_size_override("font_size", section_size)

	for i in range(_toggle_labels.size()):
		_toggle_labels[i].add_theme_font_size_override("font_size", row_label_size)
	for i in range(_toggle_btns.size()):
		_toggle_btns[i].custom_minimum_size = toggle_btn_size
		_toggle_btns[i].add_theme_font_size_override("font_size", int(22.0 * scale * panel_scale))

	if _restart_btn != null:
		_restart_btn.custom_minimum_size = Vector2(0.0, action_btn_h)
		_restart_btn.add_theme_font_size_override("font_size", action_font)
	if _close_menu_btn != null:
		_close_menu_btn.custom_minimum_size = Vector2(0.0, action_btn_h)
		_close_menu_btn.add_theme_font_size_override("font_size", action_font)

	if _confirm_title != null:
		_confirm_title.add_theme_font_size_override("font_size", int(32.0 * scale * panel_scale))
	if _confirm_salir_btn != null:
		_confirm_salir_btn.custom_minimum_size = Vector2(0.0, action_btn_h)
		_confirm_salir_btn.add_theme_font_size_override("font_size", action_font)
	if _confirm_atras_btn != null:
		_confirm_atras_btn.custom_minimum_size = Vector2(0.0, action_btn_h)
		_confirm_atras_btn.add_theme_font_size_override("font_size", action_font)
	_layout_confirm_card(scale)

	var cell_w := (card_w - 56.0 * scale) / 3.0 - 12.0 * scale
	# Miniaturas cuadradas y más chicas; la imagen se recorta (cover).
	var preview_side := mini(cell_w * 0.62, 108.0 * scale * panel_scale)
	for option in theme_option_roots:
		if option == null:
			continue
		option.custom_minimum_size = Vector2(cell_w, preview_side + 30.0 * scale)
		for child in option.get_children():
			if child is VBoxContainer:
				for sub in child.get_children():
					if sub is TextureButton:
						sub.custom_minimum_size = Vector2(preview_side, preview_side)
						sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					elif sub is Label:
						sub.add_theme_font_size_override("font_size", int(18.0 * scale * panel_scale))

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.04, 0.08, 0.06, 0.82)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_dimmer_input)
	add_child(overlay)

	card = _create_panel(CARD_BG, CARD_BORDER, 36)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 52)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(content_scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 24)
	content_scroll.add_child(vbox)

	_main_title = _create_label("Configuración", 38, TITLE_COLOR)
	vbox.add_child(_main_title)

	var toggles_box := VBoxContainer.new()
	toggles_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggles_box.add_theme_constant_override("separation", 14)
	vbox.add_child(toggles_box)

	_add_toggle_row(toggles_box, "Música", _get_music_enabled, _set_music_enabled)
	_add_toggle_row(toggles_box, "Sonidos", _get_sounds_enabled, _set_sounds_enabled)
	_add_toggle_row(toggles_box, "Vibración", _get_vibration_enabled, _set_vibration_enabled)

	_bg_section_label = _create_label("Elegir fondo", 24, SECTION_COLOR)
	_bg_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(_bg_section_label)

	theme_grid = GridContainer.new()
	theme_grid.columns = 3
	theme_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theme_grid.add_theme_constant_override("h_separation", 12)
	theme_grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(theme_grid)

	for theme in GameState.get_background_themes():
		var option := _build_theme_option(theme)
		theme_grid.add_child(option)
		theme_option_roots.append(option)

	_footer_row = HBoxContainer.new()
	_footer_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_row.add_theme_constant_override("separation", 12)
	vbox.add_child(_footer_row)

	_restart_btn = _create_action_button("Reiniciar", Color(0.52, 0.62, 0.40, 0.98))
	_restart_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_restart_btn.size_flags_stretch_ratio = 1.0
	_restart_btn.pressed.connect(_on_restart_pressed)
	_restart_btn.visible = false
	_footer_row.add_child(_restart_btn)

	_close_menu_btn = _create_action_button("Cerrar", Color(0.42, 0.50, 0.40, 0.95))
	_close_menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_menu_btn.size_flags_stretch_ratio = 1.0
	_close_menu_btn.pressed.connect(_on_close_pressed)
	_footer_row.add_child(_close_menu_btn)

	close_x_btn = _create_close_button()
	card.add_child(close_x_btn)

	_build_restart_confirm()

func _build_restart_confirm() -> void:
	_confirm_root = Control.new()
	_confirm_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_root.visible = false
	_confirm_root.z_index = 50
	add_child(_confirm_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.08, 0.06, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_root.add_child(dim)

	_confirm_card = _create_panel(CARD_BG, CARD_BORDER, 28)
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
	vbox.add_theme_constant_override("separation", 22)
	margin.add_child(vbox)

	_confirm_title = _create_label(
		"¿Desea reiniciar nivel?\nPerderá una vida",
		32,
		TITLE_COLOR
	)
	vbox.add_child(_confirm_title)

	_confirm_salir_btn = _create_action_button("Salir", Color(0.64, 0.83, 0.43, 0.98))
	_confirm_salir_btn.pressed.connect(_on_confirm_salir_pressed)
	vbox.add_child(_confirm_salir_btn)

	_confirm_atras_btn = _create_action_button("Atrás", Color(0.42, 0.50, 0.40, 0.95))
	_confirm_atras_btn.pressed.connect(_on_confirm_atras_pressed)
	vbox.add_child(_confirm_atras_btn)

func _sync_restart_button_visibility() -> void:
	if _restart_btn != null:
		_restart_btn.visible = _restart_available
	# Sin Reiniciar, Cerrar ocupa todo el ancho de la fila.
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
	var card_w := vp.x * 0.52
	var card_h := maxf(280.0 * scale, vp.y * 0.24)
	_confirm_card.size = Vector2(card_w, card_h)
	_confirm_card.position = Vector2((vp.x - card_w) * 0.5, (vp.y - card_h) * 0.5)

func _on_restart_pressed() -> void:
	_show_restart_confirm()

func _on_confirm_atras_pressed() -> void:
	_hide_restart_confirm()

func _on_confirm_salir_pressed() -> void:
	_hide_restart_confirm()
	restart_level_confirmed.emit()

func _create_action_button(text: String, bg: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if HudTextureButtons.LogoFont != null:
		btn.add_theme_font_override("font", HudTextureButtons.LogoFont)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color(0.98, 0.99, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.98))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.75, 0.88, 0.58, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	return btn

func _create_close_button() -> Button:
	var btn := Button.new()
	btn.text = "✕"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.z_index = 100
	btn.pressed.connect(_on_close_pressed)
	if HudTextureButtons.LogoFont != null:
		btn.add_theme_font_override("font", HudTextureButtons.LogoFont)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color(0.96, 0.98, 0.94))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.98))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.44, 0.54, 0.40, 0.98)
	style.border_color = Color(0.72, 0.82, 0.66, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	return btn

func _on_close_pressed() -> void:
	close()

func _ensure_close_on_top() -> void:
	if close_x_btn != null and card != null:
		card.move_child(close_x_btn, card.get_child_count() - 1)
		_position_close_button()

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

	var lbl := _create_label(label_text, 26, LABEL_COLOR)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	_toggle_labels.append(lbl)

	var toggle_idx := _toggle_btns.size()
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.toggle_mode = true
	btn.pressed.connect(_on_toggle_pressed.bind(toggle_idx))
	if HudTextureButtons.LogoFont != null:
		btn.add_theme_font_override("font", HudTextureButtons.LogoFont)
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
	var style := StyleBoxFlat.new()
	if is_on:
		style.bg_color = p.get("settings_btn_on", Color(0.64, 0.83, 0.43, 0.98))
		style.border_color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))
		btn.add_theme_color_override("font_color", Color(0.98, 0.99, 0.95))
	else:
		style.bg_color = p.get("settings_btn_off", Color(0.42, 0.50, 0.40, 0.95))
		style.border_color = p.get("settings_card_border", Color(0.52, 0.60, 0.48, 0.9))
		btn.add_theme_color_override("font_color", p.get("settings_label", Color(0.82, 0.88, 0.78)))
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _build_theme_option(theme: Dictionary) -> Panel:
	var theme_id := str(theme.get("id", ""))
	var wrap := Panel.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.set_meta("theme_id", theme_id)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_top = 8
	column.offset_right = -8
	column.offset_bottom = -8
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	wrap.add_child(column)

	var preview := TextureButton.new()
	preview.texture_normal = load(str(theme.get("path", ""))) as Texture2D
	preview.ignore_texture_size = true
	preview.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	preview.clip_contents = true
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.focus_mode = Control.FOCUS_NONE
	preview.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	preview.pressed.connect(_on_theme_option_pressed.bind(theme_id))
	column.add_child(preview)

	var lbl := _create_label(str(theme.get("label", theme_id)), 18, LABEL_COLOR)
	column.add_child(lbl)

	return wrap

func _apply_theme_option_style(option: Panel, selected: bool) -> void:
	var p: Dictionary = GameState.get_ui_palette()
	var style := StyleBoxFlat.new()
	var selected_bg: Color = p.get("settings_option_selected", Color(0.72, 0.82, 0.66, 0.85))
	var idle_bg: Color = p.get("settings_option_idle", Color(0.72, 0.82, 0.66, 0.35))
	style.bg_color = selected_bg if selected else idle_bg
	if not selected:
		style.bg_color.a = minf(style.bg_color.a, 0.40)
	style.border_color = (
		p.get("settings_btn_border", Color(0.90, 0.96, 0.84, 1.0))
		if selected
		else p.get("settings_card_border", Color(0.58, 0.66, 0.54, 0.9))
	)
	style.border_width_left = 4 if selected else 2
	style.border_width_top = 4 if selected else 2
	style.border_width_right = 4 if selected else 2
	style.border_width_bottom = 4 if selected else 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	option.add_theme_stylebox_override("panel", style)

	# Etiqueta de la miniatura.
	for child in option.get_children():
		if child is VBoxContainer:
			for sub in child.get_children():
				if sub is Label:
					(sub as Label).add_theme_color_override(
						"font_color", p.get("settings_label", LABEL_COLOR)
					)

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
		close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		layout_for_viewport(get_viewport_rect().size)

func _position_close_button() -> void:
	if close_x_btn == null or card == null:
		return
	var btn_size := 52.0
	close_x_btn.position = Vector2(card.size.x - btn_size - 14.0, 12.0)
	close_x_btn.size = Vector2(btn_size, btn_size)
	close_x_btn.custom_minimum_size = Vector2(btn_size, btn_size)

func _create_panel(bg: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _create_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	if HudTextureButtons.LogoFont != null:
		lbl.add_theme_font_override("font", HudTextureButtons.LogoFont)
	return lbl

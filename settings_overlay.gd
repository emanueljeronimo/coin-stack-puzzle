class_name SettingsOverlay
extends Control

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

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()

func open() -> void:
	_refresh_theme_selection()
	_refresh_toggle_states()
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	call_deferred("_ensure_close_on_top")

func close() -> void:
	visible = false

func is_open() -> bool:
	return visible

func layout_for_viewport(viewport_size: Vector2) -> void:
	if card == null:
		return
	var scale := viewport_size.x / REF_WIDTH
	var card_w := viewport_size.x * 0.70
	var card_h := viewport_size.y * 0.60
	card.position = Vector2((viewport_size.x - card_w) * 0.5, (viewport_size.y - card_h) * 0.5)
	card.size = Vector2(card_w, card_h)
	_position_close_button()
	_apply_scaled_content(scale, card_w)

func _apply_scaled_content(scale: float, card_w: float) -> void:
	var panel_scale := clampf(card_w / (REF_WIDTH * 0.47), 0.55, 1.0)
	var title_size := int(38.0 * scale * panel_scale)
	var row_label_size := int(34.0 * scale * panel_scale)
	var section_size := int(40.0 * scale * panel_scale)
	var toggle_btn_size := Vector2(96.0 * scale * panel_scale, 48.0 * scale * panel_scale)

	if _main_title != null:
		_main_title.add_theme_font_size_override("font_size", title_size)
	if _bg_section_label != null:
		_bg_section_label.add_theme_font_size_override("font_size", section_size)

	for i in range(_toggle_labels.size()):
		_toggle_labels[i].add_theme_font_size_override("font_size", row_label_size)
	for i in range(_toggle_btns.size()):
		_toggle_btns[i].custom_minimum_size = toggle_btn_size
		_toggle_btns[i].add_theme_font_size_override("font_size", int(22.0 * scale * panel_scale))

	var preview_w := (card_w - 56.0 * scale) / 3.0 - 12.0 * scale
	var preview_h := preview_w * 1.15
	for option in theme_option_roots:
		if option == null:
			continue
		option.custom_minimum_size = Vector2(preview_w, preview_h + 32.0 * scale)
		for child in option.get_children():
			if child is VBoxContainer:
				for sub in child.get_children():
					if sub is TextureButton:
						sub.custom_minimum_size = Vector2(preview_w - 12.0, preview_h)
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
	margin.add_theme_constant_override("margin_top", 60)
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
	vbox.add_theme_constant_override("separation", 40)
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

	close_x_btn = _create_close_button()
	card.add_child(close_x_btn)

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
	var style := StyleBoxFlat.new()
	if is_on:
		style.bg_color = Color(0.64, 0.83, 0.43, 0.98)
		style.border_color = Color(0.75, 0.88, 0.58, 1.0)
		btn.add_theme_color_override("font_color", Color(0.98, 0.99, 0.95))
	else:
		style.bg_color = Color(0.42, 0.50, 0.40, 0.95)
		style.border_color = Color(0.52, 0.60, 0.48, 0.9)
		btn.add_theme_color_override("font_color", Color(0.82, 0.88, 0.78))
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
	preview.focus_mode = Control.FOCUS_NONE
	preview.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	preview.pressed.connect(_on_theme_option_pressed.bind(theme_id))
	column.add_child(preview)

	var lbl := _create_label(str(theme.get("label", theme_id)), 18, LABEL_COLOR)
	column.add_child(lbl)

	return wrap

func _apply_theme_option_style(option: Panel, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.82, 0.66, 0.85 if selected else 0.35)
	style.border_color = Color(0.90, 0.96, 0.84, 1.0) if selected else Color(0.58, 0.66, 0.54, 0.9)
	style.border_width_left = 4 if selected else 2
	style.border_width_top = 4 if selected else 2
	style.border_width_right = 4 if selected else 2
	style.border_width_bottom = 4 if selected else 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	option.add_theme_stylebox_override("panel", style)

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

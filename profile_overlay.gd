class_name ProfileOverlay
extends Control

## Menú Editar perfil (referencia casual): nombre + grilla de avatares.

signal profile_saved

const REF_WIDTH := 1080.0
const LogoFont = preload("res://Fonts/Chewy-Regular.ttf")
const SAVE_GREEN := Color(0.34, 0.82, 0.32, 1.0)
const SAVE_GREEN_BORDER := Color(0.18, 0.52, 0.18, 1.0)
const SELECT_GREEN := Color(0.32, 0.86, 0.28, 1.0)
const CLOSE_RED := Color(0.90, 0.22, 0.24, 1.0)
const CLOSE_RED_BORDER := Color(0.55, 0.10, 0.12, 1.0)

var overlay: ColorRect = null
var card: Panel = null
var card_margin: MarginContainer = null
var main_vbox: VBoxContainer = null
var header: Control = null
var title_label: Label = null
var close_btn: Button = null
var name_bar: Panel = null
var name_margin: MarginContainer = null
var preview_frame: Panel = null
var preview_avatar: TextureRect = null
var name_label: Label = null
var name_edit: LineEdit = null
var edit_name_btn: Button = null
var choose_label: Label = null
var avatar_well: Panel = null
var well_margin: MarginContainer = null
var avatar_grid: GridContainer = null
var avatar_cells: Array = []
var save_btn: Button = null
var _pending_avatar_id: String = "mariposa"
var _editing_name: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()
	if not GameState.background_theme_changed.is_connected(_on_theme_changed):
		GameState.background_theme_changed.connect(_on_theme_changed)

func _on_theme_changed(_theme_id: String) -> void:
	_apply_theme_colors()
	if visible:
		_refresh_avatar_selection()

func open() -> void:
	_pending_avatar_id = SaveManager.get_avatar_id()
	_editing_name = false
	_sync_name_widgets()
	_apply_theme_colors()
	_refresh_preview_avatar()
	_refresh_avatar_selection()
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_editing_name = false

func is_open() -> bool:
	return visible

func layout_for_viewport(viewport_size: Vector2) -> void:
	if card == null:
		return
	var scale := viewport_size.x / REF_WIDTH
	var card_w := viewport_size.x * 0.88

	var outer_pad := int(12.0 * scale)
	var top_pad := int(12.0 * scale)
	var bottom_pad := int(12.0 * scale)
	var sep := int(10.0 * scale)
	if card_margin != null:
		card_margin.add_theme_constant_override("margin_left", outer_pad)
		card_margin.add_theme_constant_override("margin_top", top_pad)
		card_margin.add_theme_constant_override("margin_right", outer_pad)
		card_margin.add_theme_constant_override("margin_bottom", bottom_pad)
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", sep)
		main_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var header_h := 54.0 * scale
	if header != null:
		header.custom_minimum_size = Vector2(0, header_h)

	# Preview más grande, pero siempre dentro de la barra de nombre.
	var name_pad := int(10.0 * scale)
	var preview_side := 128.0 * scale
	var name_h := preview_side + float(name_pad) * 2.0
	if name_margin != null:
		name_margin.add_theme_constant_override("margin_left", name_pad)
		name_margin.add_theme_constant_override("margin_top", name_pad)
		name_margin.add_theme_constant_override("margin_right", name_pad)
		name_margin.add_theme_constant_override("margin_bottom", name_pad)
	if name_bar != null:
		name_bar.custom_minimum_size = Vector2(0, name_h)
	if preview_frame != null:
		preview_frame.custom_minimum_size = Vector2(preview_side, preview_side)
		preview_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		preview_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if edit_name_btn != null:
		edit_name_btn.custom_minimum_size = Vector2(60.0 * scale, 60.0 * scale)
		edit_name_btn.add_theme_font_size_override("font_size", int(32 * scale))
	if close_btn != null:
		var close_side := 56.0 * scale
		close_btn.custom_minimum_size = Vector2(close_side, close_side)
		close_btn.add_theme_font_size_override("font_size", int(32 * scale))
		close_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		close_btn.offset_left = -close_side
		close_btn.offset_top = -close_side * 0.5
		close_btn.offset_right = 0
		close_btn.offset_bottom = close_side * 0.5
	var save_h := 72.0 * scale
	if save_btn != null:
		save_btn.custom_minimum_size = Vector2(0, save_h)
		save_btn.add_theme_font_size_override("font_size", int(40 * scale))
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(46 * scale))
		title_label.add_theme_constant_override("outline_size", int(7 * scale))
	if name_label != null:
		name_label.add_theme_font_size_override("font_size", int(42 * scale))
		name_label.add_theme_constant_override("outline_size", int(7 * scale))
	if name_edit != null:
		name_edit.add_theme_font_size_override("font_size", int(38 * scale))
		name_edit.custom_minimum_size = Vector2(0, 64.0 * scale)
	var choose_h := 42.0 * scale
	if choose_label != null:
		choose_label.add_theme_font_size_override("font_size", int(36 * scale))
		choose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choose_label.custom_minimum_size = Vector2(0, choose_h)

	var well_pad := int(6.0 * scale)
	if well_margin != null:
		well_margin.add_theme_constant_override("margin_left", well_pad)
		well_margin.add_theme_constant_override("margin_top", well_pad)
		well_margin.add_theme_constant_override("margin_right", well_pad)
		well_margin.add_theme_constant_override("margin_bottom", well_pad)

	# Grilla casi a todo el ancho; el well se achica al contenido.
	var gap := 10.0 * scale
	if avatar_grid != null:
		avatar_grid.add_theme_constant_override("h_separation", int(gap))
		avatar_grid.add_theme_constant_override("v_separation", int(gap))
	var grid_w := card_w - float(outer_pad) * 2.0 - float(well_pad) * 2.0
	var side := (grid_w - gap * 2.0) / 3.0
	side = maxf(side, 96.0 * scale)
	for cell_node in avatar_cells:
		if cell_node is Control:
			(cell_node as Control).custom_minimum_size = Vector2(side, side)
			_layout_avatar_check(cell_node as Control, scale)
	var rows := ceili(float(avatar_cells.size()) / 3.0)
	var grid_h := side * float(rows) + gap * float(maxi(rows - 1, 0))
	var well_h := grid_h + float(well_pad) * 2.0
	if avatar_well != null:
		avatar_well.custom_minimum_size = Vector2(0, well_h)
		avatar_well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	# Altura del menú = contenido hasta Guardar (sin espacio vacío abajo).
	var content_h := (
		header_h
		+ name_h
		+ choose_h
		+ well_h
		+ save_h
		+ float(sep) * 4.0
		+ float(top_pad + bottom_pad)
	)
	var card_h := mini(content_h, viewport_size.y * 0.94)
	card.size = Vector2(card_w, card_h)
	card.position = Vector2((viewport_size.x - card_w) * 0.5, (viewport_size.y - card_h) * 0.5)


func _layout_avatar_check(cell: Control, scale: float) -> void:
	var check: Variant = cell.get_meta("check", null)
	if not (check is Panel):
		return
	var badge := check as Panel
	var badge_side := 36.0 * scale
	var inset := 8.0 * scale
	badge.offset_left = -badge_side - inset
	badge.offset_top = -badge_side - inset
	badge.offset_right = -inset
	badge.offset_bottom = -inset
	var mark: Variant = cell.get_meta("check_mark", null)
	if mark is Label:
		(mark as Label).add_theme_font_size_override("font_size", int(18 * scale))

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

	# Header: título centrado + X arriba a la derecha.
	header = Control.new()
	header.custom_minimum_size = Vector2(0, 58)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)

	title_label = _make_outlined_label("Editar perfil", 46)
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

	# Barra nombre actual
	name_bar = Panel.new()
	name_bar.custom_minimum_size = Vector2(0, 120)
	name_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(name_bar)

	name_margin = MarginContainer.new()
	name_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_margin.add_theme_constant_override("margin_left", 14)
	name_margin.add_theme_constant_override("margin_top", 14)
	name_margin.add_theme_constant_override("margin_right", 14)
	name_margin.add_theme_constant_override("margin_bottom", 14)
	name_bar.add_child(name_margin)

	var name_row := HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_row.add_theme_constant_override("separation", 16)
	name_margin.add_child(name_row)

	preview_frame = Panel.new()
	preview_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.clip_contents = true
	preview_frame.custom_minimum_size = Vector2(128, 128)
	preview_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	preview_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(1, 1, 1, 0.12)
	preview_style.corner_radius_top_left = 18
	preview_style.corner_radius_top_right = 18
	preview_style.corner_radius_bottom_left = 18
	preview_style.corner_radius_bottom_right = 18
	preview_frame.add_theme_stylebox_override("panel", preview_style)
	name_row.add_child(preview_frame)

	preview_avatar = TextureRect.new()
	preview_avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.add_child(preview_avatar)

	name_label = _make_outlined_label("", 42)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.clip_text = true
	name_row.add_child(name_label)

	name_edit = LineEdit.new()
	name_edit.max_length = 20
	name_edit.placeholder_text = "Tu nombre"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_edit.custom_minimum_size = Vector2(0, 64)
	name_edit.visible = false
	if LogoFont != null:
		name_edit.add_theme_font_override("font", LogoFont)
	name_edit.add_theme_font_size_override("font_size", 38)
	name_edit.text_changed.connect(_on_name_edit_changed)
	name_edit.text_submitted.connect(func(_t: String) -> void: _set_editing_name(false))
	name_row.add_child(name_edit)

	edit_name_btn = Button.new()
	edit_name_btn.text = "✎"
	edit_name_btn.focus_mode = Control.FOCUS_NONE
	edit_name_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	edit_name_btn.custom_minimum_size = Vector2(60, 60)
	edit_name_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if LogoFont != null:
		edit_name_btn.add_theme_font_override("font", LogoFont)
	edit_name_btn.pressed.connect(_on_edit_name_pressed)
	name_row.add_child(edit_name_btn)

	choose_label = _make_outlined_label("Elegí tu avatar:", 36)
	choose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choose_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(choose_label)

	avatar_well = Panel.new()
	avatar_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_child(avatar_well)

	well_margin = MarginContainer.new()
	well_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	well_margin.add_theme_constant_override("margin_left", 8)
	well_margin.add_theme_constant_override("margin_top", 8)
	well_margin.add_theme_constant_override("margin_right", 8)
	well_margin.add_theme_constant_override("margin_bottom", 8)
	avatar_well.add_child(well_margin)

	avatar_grid = GridContainer.new()
	avatar_grid.columns = 3
	avatar_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	avatar_grid.add_theme_constant_override("h_separation", 12)
	avatar_grid.add_theme_constant_override("v_separation", 12)
	well_margin.add_child(avatar_grid)

	avatar_cells.clear()
	for opt in SaveManager.get_avatar_options():
		var cell := _make_avatar_cell(str(opt.get("id", "")), str(opt.get("path", "")))
		avatar_grid.add_child(cell)
		avatar_cells.append(cell)

	save_btn = Button.new()
	save_btn.text = "Guardar"
	save_btn.focus_mode = Control.FOCUS_NONE
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	save_btn.custom_minimum_size = Vector2(0, 72)
	if LogoFont != null:
		save_btn.add_theme_font_override("font", LogoFont)
	save_btn.add_theme_font_size_override("font_size", 40)
	save_btn.pressed.connect(_on_save_pressed)
	main_vbox.add_child(save_btn)

	_apply_theme_colors()

func _make_avatar_cell(avatar_id: String, path: String) -> Control:
	var cell := Panel.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.clip_contents = true
	cell.custom_minimum_size = Vector2(140, 140)
	cell.set_meta("avatar_id", avatar_id)

	var btn := TextureButton.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.offset_left = 5
	btn.offset_top = 5
	btn.offset_right = -5
	btn.offset_bottom = -5
	btn.texture_normal = load(path) as Texture2D
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_avatar_pressed.bind(avatar_id))
	cell.add_child(btn)
	cell.set_meta("btn", btn)

	var check := Panel.new()
	check.visible = false
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	check.offset_left = -44
	check.offset_top = -44
	check.offset_right = -8
	check.offset_bottom = -8
	var check_style := StyleBoxFlat.new()
	check_style.bg_color = SELECT_GREEN
	check_style.border_color = Color(1, 1, 1, 0.95)
	check_style.border_width_left = 2
	check_style.border_width_top = 2
	check_style.border_width_right = 2
	check_style.border_width_bottom = 2
	check_style.corner_radius_top_left = 22
	check_style.corner_radius_top_right = 22
	check_style.corner_radius_bottom_left = 22
	check_style.corner_radius_bottom_right = 22
	check.add_theme_stylebox_override("panel", check_style)
	cell.add_child(check)
	cell.set_meta("check", check)

	var mark := Label.new()
	mark.text = "✓"
	mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	mark.add_theme_font_size_override("font_size", 18)
	if LogoFont != null:
		mark.add_theme_font_override("font", LogoFont)
	check.add_child(mark)
	cell.set_meta("check_mark", mark)

	return cell

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
	if name_bar != null:
		name_bar.add_theme_stylebox_override("panel", _flat_style(inset, card_border.darkened(0.1), 18, 2))
	if avatar_well != null:
		avatar_well.add_theme_stylebox_override("panel", _flat_style(well, card_border.darkened(0.15), 20, 2))
	if title_label != null:
		title_label.add_theme_color_override("font_color", Color(0.99, 0.99, 1.0))
	if choose_label != null:
		choose_label.add_theme_color_override("font_color", Color(0.99, 0.99, 1.0))
	if name_label != null:
		name_label.add_theme_color_override("font_color", Color(0.99, 0.99, 1.0))

	_apply_button_style(close_btn, CLOSE_RED, CLOSE_RED_BORDER, 14, Color(1, 1, 1))
	_apply_button_style(edit_name_btn, Color(0.96, 0.96, 0.98), Color(0.55, 0.55, 0.62), 12, Color(0.2, 0.2, 0.28))
	_apply_button_style(save_btn, SAVE_GREEN, SAVE_GREEN_BORDER, 22, Color(1, 1, 1))

	if name_edit != null:
		var edit_style := _flat_style(Color(0.12, 0.10, 0.18, 0.55), Color(0.85, 0.85, 0.92, 0.4), 10, 1)
		name_edit.add_theme_stylebox_override("normal", edit_style)
		name_edit.add_theme_stylebox_override("focus", edit_style)
		name_edit.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
		name_edit.add_theme_color_override("font_placeholder_color", Color(0.85, 0.85, 0.92, 0.55))

func _sync_name_widgets() -> void:
	var uname := SaveManager.get_username()
	if name_label != null:
		name_label.text = uname
		name_label.visible = not _editing_name
	if name_edit != null:
		name_edit.text = uname
		name_edit.visible = _editing_name
		if _editing_name:
			name_edit.grab_focus()
			name_edit.caret_column = name_edit.text.length()

func _set_editing_name(enabled: bool) -> void:
	_editing_name = enabled
	if enabled and name_edit != null and name_label != null:
		name_edit.text = name_label.text
	elif not enabled and name_edit != null and name_label != null:
		var t := name_edit.text.strip_edges()
		if not t.is_empty():
			name_label.text = t
	_sync_name_widgets()

func _on_edit_name_pressed() -> void:
	_set_editing_name(not _editing_name)

func _on_name_edit_changed(new_text: String) -> void:
	if name_label != null:
		name_label.text = new_text

func _refresh_preview_avatar() -> void:
	if preview_avatar == null:
		return
	var path := ""
	for opt in SaveManager.get_avatar_options():
		if str(opt.get("id", "")) == _pending_avatar_id:
			path = str(opt.get("path", ""))
			break
	if path.is_empty():
		preview_avatar.texture = SaveManager.get_avatar_texture()
	else:
		preview_avatar.texture = load(path) as Texture2D

func _refresh_avatar_selection() -> void:
	for cell in avatar_cells:
		if not (cell is Panel):
			continue
		var p := cell as Panel
		var selected := str(p.get_meta("avatar_id", "")) == _pending_avatar_id
		var border := SELECT_GREEN if selected else Color(0, 0, 0, 0)
		var bg := Color(1, 1, 1, 0.06)
		p.add_theme_stylebox_override("panel", _flat_style(bg, border, 14, 4 if selected else 0))
		var check: Variant = p.get_meta("check", null)
		if check is CanvasItem:
			(check as CanvasItem).visible = selected

func _on_avatar_pressed(avatar_id: String) -> void:
	_pending_avatar_id = avatar_id
	_refresh_preview_avatar()
	_refresh_avatar_selection()

func _on_save_pressed() -> void:
	var uname := ""
	if _editing_name and name_edit != null:
		uname = name_edit.text.strip_edges()
	elif name_label != null:
		uname = name_label.text.strip_edges()
	if uname.is_empty():
		uname = SaveManager.get_username()
	SaveManager.set_username(uname)
	SaveManager.set_avatar_id(_pending_avatar_id)
	profile_saved.emit()
	close()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if card != null and not card.get_global_rect().has_point((event as InputEventMouseButton).position):
			close()

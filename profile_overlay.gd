class_name ProfileOverlay
extends Control

signal profile_saved

const REF_WIDTH := 1080.0
const LogoFont = preload("res://Fonts/Lobster-Regular.ttf")
const StarIcon = preload("res://Imagenes/ficha-comodin.png")
const CalendarIcon = preload("res://Imagenes/icono-login-diario.png")
const CLOSE_RED := Color(0.90, 0.22, 0.24, 1.0)
const CLOSE_RED_BORDER := Color(0.55, 0.10, 0.12, 1.0)
const SELECT_GREEN := Color(0.32, 0.86, 0.28, 1.0)
const TEXT_OUTLINE := Color(0.0, 0.0, 0.0, 1.0)
const TITLE_OUTLINE := 12
const LABEL_OUTLINE := 8
const BUTTON_OUTLINE := 8
const PAGE_VIEW := 0
const PAGE_EDIT := 1

var overlay: ColorRect = null
var card: Panel = null
var card_margin: MarginContainer = null
var main_vbox: VBoxContainer = null
var header: Control = null
var title_label: Label = null
var close_btn: Button = null
var view_box: VBoxContainer = null
var edit_box: VBoxContainer = null
var view_name_bar: Panel = null
var view_name_margin: MarginContainer = null
var view_preview_frame: Panel = null
var view_preview_avatar: TextureRect = null
var view_name_label: Label = null
var edit_profile_btn: Button = null
var stats_well: Panel = null
var stats_margin: MarginContainer = null
var _level_value_label: Label = null
var _days_value_label: Label = null
var _stat_labels: Array[Label] = []
var _stat_chips: Array[Panel] = []
var edit_name_bar: Panel = null
var edit_name_margin: MarginContainer = null
var edit_preview_frame: Panel = null
var edit_preview_avatar: TextureRect = null
var name_label: Label = null
var name_edit: LineEdit = null
var edit_name_btn: Button = null
var avatar_well: Panel = null
var well_margin: MarginContainer = null
var avatar_grid: GridContainer = null
var avatar_cells: Array = []
var save_btn: Button = null
var _pending_avatar_id: String = "mariposa"
var _pending_username: String = ""
var _editing_name: bool = false
var _page: int = PAGE_VIEW

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
	_pending_username = SaveManager.get_username()
	_editing_name = false
	SaveManager.get_play_days()
	_sync_name_widgets()
	_refresh_preview_avatars()
	_refresh_avatar_selection()
	_refresh_stats()
	_apply_theme_colors()
	_set_page(PAGE_VIEW)
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_editing_name = false
	if name_edit != null:
		name_edit.release_focus()
	_set_page(PAGE_VIEW)

func is_open() -> bool:
	return visible

func layout_for_viewport(viewport_size: Vector2) -> void:
	if card == null:
		return
	var scale := viewport_size.x / REF_WIDTH
	var card_w := viewport_size.x * 0.76
	var outer_pad := int(20.0 * scale)
	var top_pad := int(24.0 * scale)
	var bottom_pad := int(24.0 * scale)
	var sep := int(18.0 * scale)
	if card_margin != null:
		card_margin.add_theme_constant_override("margin_left", outer_pad)
		card_margin.add_theme_constant_override("margin_top", top_pad)
		card_margin.add_theme_constant_override("margin_right", outer_pad)
		card_margin.add_theme_constant_override("margin_bottom", bottom_pad)
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", sep)
	if view_box != null:
		view_box.add_theme_constant_override("separation", sep)
	if edit_box != null:
		edit_box.add_theme_constant_override("separation", sep)

	var header_h := 72.0 * scale
	if header != null:
		header.custom_minimum_size = Vector2(0, header_h)
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(58 * scale))
		title_label.add_theme_constant_override("outline_size", int(TITLE_OUTLINE * scale))
	if close_btn != null:
		var close_side := 64.0 * scale
		close_btn.custom_minimum_size = Vector2(close_side, close_side)
		close_btn.add_theme_font_size_override("font_size", int(36 * scale))
		close_btn.add_theme_constant_override("outline_size", int(BUTTON_OUTLINE * scale))
		close_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		close_btn.offset_left = -close_side
		close_btn.offset_top = -close_side * 0.5
		close_btn.offset_right = 0
		close_btn.offset_bottom = close_side * 0.5

	var name_pad := int(12.0 * scale)
	var preview_side := 128.0 * scale
	var name_h := preview_side + float(name_pad) * 2.0
	for margin in [view_name_margin, edit_name_margin]:
		if margin == null:
			continue
		margin.add_theme_constant_override("margin_left", name_pad)
		margin.add_theme_constant_override("margin_top", name_pad)
		margin.add_theme_constant_override("margin_right", name_pad)
		margin.add_theme_constant_override("margin_bottom", name_pad)
	for bar in [view_name_bar, edit_name_bar]:
		if bar != null:
			bar.custom_minimum_size = Vector2(0, name_h)
	_layout_preview_frame(view_preview_frame, view_preview_avatar, preview_side)
	_layout_preview_frame(edit_preview_frame, edit_preview_avatar, preview_side)
	if view_name_label != null:
		view_name_label.add_theme_font_size_override("font_size", int(42 * scale))
		view_name_label.add_theme_constant_override("outline_size", int(LABEL_OUTLINE * scale))
	if name_label != null:
		name_label.add_theme_font_size_override("font_size", int(42 * scale))
		name_label.add_theme_constant_override("outline_size", int(LABEL_OUTLINE * scale))
	if name_edit != null:
		name_edit.add_theme_font_size_override("font_size", int(38 * scale))
		name_edit.custom_minimum_size = Vector2(280.0 * scale, 64.0 * scale)
	if edit_name_btn != null:
		edit_name_btn.custom_minimum_size = Vector2(60.0 * scale, 60.0 * scale)
		edit_name_btn.add_theme_font_size_override("font_size", int(32 * scale))
		edit_name_btn.add_theme_constant_override("outline_size", int(BUTTON_OUTLINE * scale))

	var action_h := 74.0 * scale
	var action_font := int(38 * scale)
	for btn in [edit_profile_btn, save_btn]:
		if btn == null:
			continue
		btn.custom_minimum_size = Vector2(0, action_h)
		btn.add_theme_font_size_override("font_size", action_font)
		btn.add_theme_constant_override("outline_size", int(BUTTON_OUTLINE * scale))

	var stat_h := 88.0 * scale
	var stats_pad := int(14.0 * scale)
	if stats_margin != null:
		stats_margin.add_theme_constant_override("margin_left", stats_pad)
		stats_margin.add_theme_constant_override("margin_top", stats_pad)
		stats_margin.add_theme_constant_override("margin_right", stats_pad)
		stats_margin.add_theme_constant_override("margin_bottom", stats_pad)
	for lbl in _stat_labels:
		lbl.add_theme_font_size_override("font_size", int(36 * scale))
		lbl.add_theme_constant_override("outline_size", int(LABEL_OUTLINE * scale))
	var chip_side := 88.0 * scale
	var icon_side := 40.0 * scale
	for chip in _stat_chips:
		chip.custom_minimum_size = Vector2(chip_side * 1.35, chip_side)
		var icon_node: Variant = chip.get_meta("icon", null)
		if icon_node is TextureRect:
			(icon_node as TextureRect).custom_minimum_size = Vector2(icon_side, icon_side)
	for value_lbl in [_level_value_label, _days_value_label]:
		if value_lbl == null:
			continue
		value_lbl.add_theme_font_size_override("font_size", int(36 * scale))
		value_lbl.add_theme_constant_override("outline_size", int(LABEL_OUTLINE * scale))
	var stats_h := stat_h * 2.0 + float(sep) + float(stats_pad) * 2.0
	if stats_well != null:
		stats_well.custom_minimum_size = Vector2(0, stats_h)

	var well_pad := int(14.0 * scale)
	if well_margin != null:
		well_margin.add_theme_constant_override("margin_left", well_pad)
		well_margin.add_theme_constant_override("margin_top", well_pad)
		well_margin.add_theme_constant_override("margin_right", well_pad)
		well_margin.add_theme_constant_override("margin_bottom", well_pad)
	var gap := 14.0 * scale
	if avatar_grid != null:
		avatar_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		avatar_grid.add_theme_constant_override("h_separation", int(gap))
		avatar_grid.add_theme_constant_override("v_separation", int(gap))
	var grid_w := card_w - float(outer_pad) * 2.0 - float(well_pad) * 2.0
	var side := (grid_w - gap * 2.0) / 3.0
	var extra_h := 96.0 * scale
	var max_card := viewport_size.y * 0.92
	var chrome := (
		header_h
		+ name_h
		+ action_h
		+ float(sep) * 3.0
		+ float(top_pad + bottom_pad)
		+ float(well_pad) * 2.0
		+ extra_h
	)
	var max_grid_h := maxf(max_card - chrome, 240.0 * scale)
	side = minf(side, (max_grid_h - gap * 2.0) / 3.0)
	for cell_node in avatar_cells:
		if cell_node is Control:
			(cell_node as Control).custom_minimum_size = Vector2(side, side)
			(cell_node as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_layout_avatar_check(cell_node as Control, scale)
	var rows := ceili(float(maxi(avatar_cells.size(), 1)) / 3.0)
	var grid_h := side * float(rows) + gap * float(maxi(rows - 1, 0))
	var well_h := grid_h + float(well_pad) * 2.0 + extra_h
	if avatar_well != null:
		avatar_well.custom_minimum_size = Vector2(0, well_h)
	if stats_well != null:
		stats_well.custom_minimum_size = Vector2(0, stats_h + extra_h)

	var view_h := name_h + action_h + stats_h + extra_h + float(sep) * 2.0
	var edit_h := name_h + well_h + action_h + float(sep) * 2.0
	var page_h := edit_h if _page == PAGE_EDIT else view_h
	var content_h := header_h + page_h + float(sep) + float(top_pad + bottom_pad)
	var card_h := mini(content_h, max_card)
	card.size = Vector2(card_w, card_h)
	card.position = Vector2((viewport_size.x - card_w) * 0.5, (viewport_size.y - card_h) * 0.5)

func _layout_preview_frame(frame: Panel, avatar: TextureRect, side: float) -> void:
	if frame == null:
		return
	frame.custom_minimum_size = Vector2(side, side)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_preview_frame_style(frame, avatar, side)

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
	var btn: Variant = cell.get_meta("btn", null)
	if btn is TextureButton:
		var side := maxf(cell.custom_minimum_size.x, 1.0)
		var pad := 5.0
		var inner := maxf(side - pad * 2.0, 1.0)
		HudTextureButtons.apply_rounded_clip(btn as TextureButton, Vector2(inner, inner), inner * 0.30)

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
	card.add_child(card_margin)

	main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_margin.add_child(main_vbox)

	header = Control.new()
	header.custom_minimum_size = Vector2(0, 58)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)

	title_label = _make_outlined_label("Perfil", 52)
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)

	close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if LogoFont != null:
		close_btn.add_theme_font_override("font", LogoFont)
	close_btn.pressed.connect(_on_close_pressed)
	GameState.hook_button_sound(close_btn)
	header.add_child(close_btn)

	view_box = VBoxContainer.new()
	view_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(view_box)

	var view_identity := _make_identity_bar(false)
	view_name_bar = view_identity["bar"]
	view_name_margin = view_identity["margin"]
	view_preview_frame = view_identity["frame"]
	view_preview_avatar = view_identity["avatar"]
	view_name_label = view_identity["label"]
	view_box.add_child(view_name_bar)

	edit_profile_btn = _make_action_button("Editar perfil")
	edit_profile_btn.pressed.connect(_on_edit_profile_pressed)
	view_box.add_child(edit_profile_btn)

	stats_well = Panel.new()
	stats_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_box.add_child(stats_well)

	stats_margin = MarginContainer.new()
	stats_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_well.add_child(stats_margin)

	var stats_box := VBoxContainer.new()
	stats_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_box.add_theme_constant_override("separation", 14)
	stats_margin.add_child(stats_box)
	_add_stat_row(stats_box, "Nivel actual", StarIcon, true)
	_add_stat_row(stats_box, "Días jugados", CalendarIcon, false)

	edit_box = VBoxContainer.new()
	edit_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_box.visible = false
	main_vbox.add_child(edit_box)

	var edit_identity := _make_identity_bar(true)
	edit_name_bar = edit_identity["bar"]
	edit_name_margin = edit_identity["margin"]
	edit_preview_frame = edit_identity["frame"]
	edit_preview_avatar = edit_identity["avatar"]
	name_label = edit_identity["label"]
	name_edit = edit_identity["edit"]
	edit_name_btn = edit_identity["pencil"]
	edit_box.add_child(edit_name_bar)

	avatar_well = Panel.new()
	avatar_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	edit_box.add_child(avatar_well)

	well_margin = MarginContainer.new()
	well_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_well.add_child(well_margin)

	var grid_center := CenterContainer.new()
	grid_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	well_margin.add_child(grid_center)

	avatar_grid = GridContainer.new()
	avatar_grid.columns = 3
	avatar_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid_center.add_child(avatar_grid)

	avatar_cells.clear()
	for opt in SaveManager.get_avatar_options():
		var cell := _make_avatar_cell(str(opt.get("id", "")), str(opt.get("path", "")))
		avatar_grid.add_child(cell)
		avatar_cells.append(cell)

	save_btn = _make_action_button("Guardar")
	save_btn.pressed.connect(_on_save_pressed)
	edit_box.add_child(save_btn)

	_apply_theme_colors()
	_set_page(PAGE_VIEW)

func _make_identity_bar(editable: bool) -> Dictionary:
	var bar := Panel.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(margin)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	frame.custom_minimum_size = Vector2(128, 128)
	row.add_child(frame)

	var avatar := TextureRect.new()
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(avatar)

	var label := _make_outlined_label("", 42)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(label)

	var edit: LineEdit = null
	var pencil: Button = null
	if editable:
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_default_cursor_shape = Control.CURSOR_IBEAM
		label.gui_input.connect(_on_name_label_gui_input)
		edit = LineEdit.new()
		edit.max_length = 20
		edit.placeholder_text = "Tu nombre"
		edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		edit.custom_minimum_size = Vector2(280, 64)
		edit.visible = false
		edit.clear_button_enabled = true
		edit.caret_blink = true
		if LogoFont != null:
			edit.add_theme_font_override("font", LogoFont)
		edit.text_changed.connect(_on_name_edit_changed)
		edit.text_submitted.connect(func(_t: String) -> void: _set_editing_name(false))
		row.add_child(edit)
		pencil = Button.new()
		pencil.text = "✎"
		pencil.focus_mode = Control.FOCUS_NONE
		pencil.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pencil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if LogoFont != null:
			pencil.add_theme_font_override("font", LogoFont)
		pencil.pressed.connect(_on_edit_name_pressed)
		GameState.hook_button_sound(pencil)
		row.add_child(pencil)

	return {
		"bar": bar,
		"margin": margin,
		"frame": frame,
		"avatar": avatar,
		"label": label,
		"edit": edit,
		"pencil": pencil,
	}

func _add_stat_row(parent: VBoxContainer, caption: String, icon: Texture2D, is_level: bool) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var lbl := _make_outlined_label(caption, 36)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	_stat_labels.append(lbl)

	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(88, 88)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chip)
	_stat_chips.append(chip)

	var chip_margin := MarginContainer.new()
	chip_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip_margin.add_theme_constant_override("margin_left", 6)
	chip_margin.add_theme_constant_override("margin_right", 8)
	chip.add_child(chip_margin)

	var chip_row := HBoxContainer.new()
	chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip_row.add_theme_constant_override("separation", 4)
	chip_margin.add_child(chip_row)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(40, 40)
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_child(icon_rect)
	chip.set_meta("icon", icon_rect)

	var value := _make_outlined_label("1", 36)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_row.add_child(value)
	if is_level:
		_level_value_label = value
	else:
		_days_value_label = value

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
	GameState.hook_button_sound(btn)
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
	check_style.set_border_width_all(2)
	check_style.set_corner_radius_all(22)
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
	if LogoFont != null:
		mark.add_theme_font_override("font", LogoFont)
	check.add_child(mark)
	cell.set_meta("check_mark", mark)
	return cell

func _make_outlined_label(text: String, font_size: int) -> Label:
	return UiStyleUtils.make_outlined_label(
		text,
		font_size,
		LogoFont,
		Color(0.88, 0.86, 0.83),
		TEXT_OUTLINE,
		LABEL_OUTLINE
	)

func _make_action_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if LogoFont != null:
		btn.add_theme_font_override("font", LogoFont)
	btn.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	btn.add_theme_constant_override("outline_size", BUTTON_OUTLINE)
	GameState.hook_button_sound(btn)
	return btn

func _flat_style(bg: Color, border: Color, radius: int, border_w: int = 3) -> StyleBoxFlat:
	var style := UiStyleUtils.flat_style(bg, border, radius, border_w)
	style.anti_aliasing = true
	style.corner_detail = 12
	return style

func _apply_button_style(btn: Button, bg: Color, border: Color, radius: int, font_color: Color) -> void:
	UiStyleUtils.apply_button_style(
		btn,
		bg,
		border,
		radius,
		font_color,
		TEXT_OUTLINE,
		BUTTON_OUTLINE
	)

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
	var title_col: Color = p.get("settings_title", text_marble)
	var label_col: Color = p.get("settings_label", text_marble)
	if card != null:
		card.add_theme_stylebox_override("panel", _flat_style(card_bg, card_border, 30, 4))
	for bar in [view_name_bar, edit_name_bar]:
		if bar != null:
			bar.add_theme_stylebox_override("panel", _flat_style(inset, card_border.darkened(0.1), 18, 2))
	if avatar_well != null:
		avatar_well.add_theme_stylebox_override("panel", _flat_style(well, card_border.darkened(0.15), 24, 2))
	if stats_well != null:
		stats_well.add_theme_stylebox_override("panel", _flat_style(well, card_border.darkened(0.15), 24, 2))
	if title_label != null:
		title_label.add_theme_color_override("font_color", title_col)
		title_label.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	for lbl in [view_name_label, name_label]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", title_col)
			lbl.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	for lbl in _stat_labels:
		lbl.add_theme_color_override("font_color", label_col)
		lbl.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	for value_lbl in [_level_value_label, _days_value_label]:
		if value_lbl != null:
			value_lbl.add_theme_color_override("font_color", title_col)
			value_lbl.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	for chip in _stat_chips:
		chip.add_theme_stylebox_override("panel", _flat_style(inset.lightened(0.08), card_border, 16, 2))
	_apply_button_style(close_btn, CLOSE_RED, CLOSE_RED_BORDER, 14, text_marble)
	if edit_name_btn != null:
		_apply_button_style(edit_name_btn, Color(0.96, 0.96, 0.98), Color(0.55, 0.55, 0.62), 12, Color(0.2, 0.2, 0.28))
	var btn_on: Color = p.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98))
	var btn_border: Color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))
	_apply_button_style(edit_profile_btn, btn_on, btn_border, 26, text_marble)
	_apply_button_style(save_btn, btn_on, btn_border, 26, text_marble)
	if name_edit != null:
		var edit_style := _flat_style(Color(0.12, 0.10, 0.18, 0.55), Color(0.85, 0.85, 0.92, 0.4), 10, 1)
		name_edit.add_theme_stylebox_override("normal", edit_style)
		name_edit.add_theme_stylebox_override("focus", edit_style)
		name_edit.add_theme_color_override("font_color", text_marble)
		name_edit.add_theme_color_override("font_placeholder_color", Color(0.78, 0.76, 0.74, 0.55))
	_refresh_preview_avatars()
	_apply_rainbow_ui_fills()

func _apply_rainbow_ui_fills() -> void:
	if card != null:
		HudTextureButtons.apply_optional_rainbow_fill(card, 30, card.size, 4)
	if edit_profile_btn != null:
		HudTextureButtons.apply_optional_rainbow_fill(edit_profile_btn, 26, edit_profile_btn.size, 3)
	if save_btn != null:
		HudTextureButtons.apply_optional_rainbow_fill(save_btn, 26, save_btn.size, 3)

func _set_page(page: int) -> void:
	_page = page
	if view_box != null:
		view_box.visible = page == PAGE_VIEW
	if edit_box != null:
		edit_box.visible = page == PAGE_EDIT
	if title_label != null:
		title_label.text = "Editar perfil" if page == PAGE_EDIT else "Perfil"
	if page != PAGE_EDIT:
		_set_editing_name(false)
	if visible:
		layout_for_viewport(get_viewport_rect().size)

func _on_close_pressed() -> void:
	if _page == PAGE_EDIT:
		_pending_avatar_id = SaveManager.get_avatar_id()
		_pending_username = SaveManager.get_username()
		_sync_name_widgets()
		_refresh_preview_avatars()
		_refresh_avatar_selection()
		_set_page(PAGE_VIEW)
		return
	close()

func _on_edit_profile_pressed() -> void:
	_pending_avatar_id = SaveManager.get_avatar_id()
	_pending_username = SaveManager.get_username()
	_editing_name = false
	_sync_name_widgets()
	_refresh_preview_avatars()
	_refresh_avatar_selection()
	_set_page(PAGE_EDIT)

func _refresh_stats() -> void:
	if _level_value_label != null:
		_level_value_label.text = str(maxi(1, GameState.player_level))
	if _days_value_label != null:
		_days_value_label.text = str(SaveManager.get_play_days())

func _sync_name_widgets() -> void:
	if view_name_label != null:
		view_name_label.text = _pending_username
	if name_label != null:
		name_label.text = _pending_username
		name_label.visible = not _editing_name
	if name_edit != null:
		if name_edit.text != _pending_username:
			name_edit.text = _pending_username
		name_edit.visible = _editing_name
		if _editing_name:
			name_edit.call_deferred("grab_focus")
			name_edit.caret_column = name_edit.text.length()

func _commit_name_edit_draft() -> void:
	if name_edit == null:
		return
	var t := name_edit.text.strip_edges()
	if not t.is_empty():
		_pending_username = t
	elif not _pending_username.strip_edges().is_empty():
		name_edit.text = _pending_username

func _set_editing_name(enabled: bool) -> void:
	if enabled == _editing_name:
		return
	if enabled:
		_editing_name = true
		if name_edit != null:
			name_edit.text = _pending_username
	else:
		_commit_name_edit_draft()
		_editing_name = false
		if name_edit != null:
			name_edit.release_focus()
	_sync_name_widgets()

func _on_edit_name_pressed() -> void:
	_set_editing_name(not _editing_name)

func _on_name_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameState.play_button_sound()
		_set_editing_name(true)
		accept_event()

func _on_name_edit_changed(new_text: String) -> void:
	_pending_username = new_text

func _apply_preview_frame_style(frame: Panel, avatar: TextureRect, side: float) -> void:
	if frame == null:
		return
	var border_w := int(clampf(side * 0.06, 4.0, 8.0))
	var radius := int(side * 0.38)
	var border_col := SaveManager.get_avatar_border_color()
	frame.add_theme_stylebox_override("panel", _flat_style(border_col, border_col, radius, border_w))
	if avatar == null:
		return
	avatar.offset_left = float(border_w)
	avatar.offset_top = float(border_w)
	avatar.offset_right = float(-border_w)
	avatar.offset_bottom = float(-border_w)
	var inner := maxf(side - float(border_w) * 2.0, 1.0)
	var inner_radius := maxf(float(radius) - float(border_w), inner * 0.34)
	HudTextureButtons.apply_rounded_clip(avatar, Vector2(inner, inner), inner_radius)

func _refresh_preview_avatars() -> void:
	var path := ""
	for opt in SaveManager.get_avatar_options():
		if str(opt.get("id", "")) == _pending_avatar_id:
			path = str(opt.get("path", ""))
			break
	var tex: Texture2D = SaveManager.get_avatar_texture()
	if not path.is_empty():
		tex = load(path) as Texture2D
	for avatar in [view_preview_avatar, edit_preview_avatar]:
		if avatar != null:
			avatar.texture = tex
	var side := 128.0
	if view_preview_frame != null:
		side = maxf(view_preview_frame.custom_minimum_size.x, side)
	_apply_preview_frame_style(view_preview_frame, view_preview_avatar, side)
	_apply_preview_frame_style(edit_preview_frame, edit_preview_avatar, side)

func _refresh_avatar_selection() -> void:
	for cell in avatar_cells:
		if not (cell is Panel):
			continue
		var p := cell as Panel
		var selected := str(p.get_meta("avatar_id", "")) == _pending_avatar_id
		var border := SELECT_GREEN if selected else Color(0, 0, 0, 0)
		var bg := Color(1, 1, 1, 0.06)
		var cell_side := maxf(p.custom_minimum_size.x, 140.0)
		p.add_theme_stylebox_override("panel", _flat_style(bg, border, int(cell_side * 0.28), 4 if selected else 0))
		var check: Variant = p.get_meta("check", null)
		if check is CanvasItem:
			(check as CanvasItem).visible = selected

func _on_avatar_pressed(avatar_id: String) -> void:
	_pending_avatar_id = avatar_id
	_refresh_preview_avatars()
	_refresh_avatar_selection()

func _on_save_pressed() -> void:
	if _editing_name:
		_commit_name_edit_draft()
		_editing_name = false
	var uname := _pending_username.strip_edges()
	if uname.is_empty():
		uname = SaveManager.get_username()
	_pending_username = uname
	SaveManager.set_username(uname)
	SaveManager.set_avatar_id(_pending_avatar_id)
	_sync_name_widgets()
	_refresh_preview_avatars()
	_refresh_stats()
	profile_saved.emit()
	_set_page(PAGE_VIEW)

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if card != null and not card.get_global_rect().has_point((event as InputEventMouseButton).position):
			_on_close_pressed()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		layout_for_viewport(get_viewport_rect().size)

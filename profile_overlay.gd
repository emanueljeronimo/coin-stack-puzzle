class_name ProfileOverlay
extends Control

signal profile_saved

const ProfileFrameLayoutServiceScript = preload("res://profile_frame_layout_service.gd")
const FrameTexture = preload("res://Imagenes/menu-perfil.png")
const EditFrameTexture = preload("res://Imagenes/menu-perfil-2.png")
const LogoFont = preload("res://Fonts/Lobster-Regular.ttf")
const StarIcon = preload("res://Imagenes/ficha-comodin.png")
const CalendarIcon = preload("res://Imagenes/icono-login-diario.png")
const SELECT_GREEN := Color(0.32, 0.86, 0.28, 1.0)
const TEXT_OUTLINE := Color(0.22, 0.10, 0.38, 0.88)
const TITLE_FILL := Color(0.42, 0.20, 0.60, 1.0)
const TITLE_OUTLINE := Color(1.00, 0.96, 0.92, 0.85)
const PILL_TEXT := Color(1.00, 0.98, 0.96, 1.0)
const PILL_OUTLINE := Color(0.62, 0.18, 0.48, 0.90)
const NAME_FILL := Color(1.00, 0.98, 0.96, 1.0)
const STAT_INK := Color(0.42, 0.20, 0.60, 1.0)
const PAGE_VIEW := 0
const PAGE_EDIT := 1

var overlay: ColorRect = null
var card: Panel = null
var frame_art: TextureRect = null
var title_label: Label = null
var close_btn: Button = null
var preview_frame: Panel = null
var preview_avatar: TextureRect = null
var view_name_label: Label = null
var name_label: Label = null
var name_edit: LineEdit = null
var edit_name_btn: Button = null
var edit_profile_btn: Button = null
var edit_profile_label: Label = null
var save_btn: Button = null
var save_label: Label = null
var avatar_well: Panel = null
var avatar_cells: Array = []
var _stat_labels: Array[Label] = []
var _stat_chips: Array[Panel] = []
var _level_value_label: Label = null
var _days_value_label: Label = null
var _pending_avatar_id: String = "conejo"
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
	var editing := _page == PAGE_EDIT
	var frame_tex: Texture2D = EditFrameTexture if editing else FrameTexture
	var tex_size := Vector2(1325, 1187)
	if frame_tex != null:
		tex_size = frame_tex.get_size()
	var card_size: Vector2 = ProfileFrameLayoutServiceScript.card_size(viewport_size, tex_size)
	card.size = card_size
	card.position = Vector2(
		(viewport_size.x - card_size.x) * 0.5,
		(viewport_size.y - card_size.y) * 0.5
	)
	if frame_art != null:
		frame_art.texture = frame_tex
		frame_art.position = Vector2.ZERO
		frame_art.size = card_size
	_place_mapped(title_label, card_size, ProfileFrameLayoutServiceScript.TITLE_FRAC)
	if title_label != null:
		var title_h: float = ProfileFrameLayoutServiceScript.mapped_rect(
			card_size,
			ProfileFrameLayoutServiceScript.TITLE_FRAC
		).size.y
		var title_font: int = ProfileFrameLayoutServiceScript.title_font_size(title_h)
		title_label.add_theme_font_size_override("font_size", title_font)
		title_label.add_theme_constant_override("outline_size", maxi(int(round(float(title_font) * 0.10)), 4))
	_place_mapped(close_btn, card_size, ProfileFrameLayoutServiceScript.CLOSE_FRAC)
	if editing:
		_layout_identity(
			card_size,
			ProfileFrameLayoutServiceScript.EDIT_AVATAR_FRAC,
			ProfileFrameLayoutServiceScript.EDIT_NAME_FRAC
		)
		_layout_action_pill(
			save_btn,
			save_label,
			ProfileFrameLayoutServiceScript.mapped_rect(card_size, ProfileFrameLayoutServiceScript.EDIT_ACTION_FRAC),
			ProfileFrameLayoutServiceScript.mapped_rect(card_size, ProfileFrameLayoutServiceScript.EDIT_ACTION_TEXT_FRAC)
		)
		_layout_edit_cells(card_size)
	else:
		_layout_identity(
			card_size,
			ProfileFrameLayoutServiceScript.AVATAR_FRAC,
			ProfileFrameLayoutServiceScript.NAME_FRAC
		)
		_layout_action_pill(
			edit_profile_btn,
			edit_profile_label,
			ProfileFrameLayoutServiceScript.mapped_rect(card_size, ProfileFrameLayoutServiceScript.ACTION_FRAC),
			ProfileFrameLayoutServiceScript.mapped_rect(card_size, ProfileFrameLayoutServiceScript.ACTION_TEXT_FRAC)
		)
		_layout_stats(card_size)

func _layout_identity(card_size: Vector2, avatar_frac: Rect2, name_frac: Rect2) -> void:
	var avatar_rect: Rect2 = ProfileFrameLayoutServiceScript.mapped_rect(card_size, avatar_frac)
	_place_rect(preview_frame, avatar_rect)
	_layout_preview_frame(preview_frame, preview_avatar, avatar_rect.size)
	var name_rect: Rect2 = ProfileFrameLayoutServiceScript.mapped_rect(card_size, name_frac)
	_place_rect(view_name_label, name_rect)
	var name_font: int = ProfileFrameLayoutServiceScript.name_font_size(name_rect.size.y)
	if view_name_label != null:
		view_name_label.add_theme_font_size_override("font_size", name_font)
		view_name_label.add_theme_constant_override("outline_size", maxi(int(round(float(name_font) * 0.12)), 4))
	var pencil_side: float = minf(name_rect.size.y * 0.82, 56.0)
	var pencil_rect := Rect2(
		name_rect.position.x + name_rect.size.x - pencil_side,
		name_rect.position.y + (name_rect.size.y - pencil_side) * 0.5,
		pencil_side,
		pencil_side
	)
	var edit_name_rect := Rect2(
		name_rect.position,
		Vector2(maxf(name_rect.size.x - pencil_side - 8.0, 40.0), name_rect.size.y)
	)
	_place_rect(name_label, edit_name_rect)
	_place_rect(name_edit, edit_name_rect)
	_place_rect(edit_name_btn, pencil_rect)
	if name_label != null:
		name_label.add_theme_font_size_override("font_size", name_font)
		name_label.add_theme_constant_override("outline_size", maxi(int(round(float(name_font) * 0.12)), 4))
	if name_edit != null:
		name_edit.add_theme_font_size_override("font_size", maxi(name_font - 4, 22))
		name_edit.custom_minimum_size = Vector2.ZERO
	if edit_name_btn != null:
		edit_name_btn.custom_minimum_size = Vector2.ZERO
		edit_name_btn.add_theme_font_size_override("font_size", int(clampf(pencil_side * 0.55, 22.0, 36.0)))

func _layout_stats(card_size: Vector2) -> void:
	for i in range(_stat_labels.size()):
		var label_frac: Rect2 = ProfileFrameLayoutServiceScript.STAT_LABEL_FRACS[mini(i, 1)]
		var chip_frac: Rect2 = ProfileFrameLayoutServiceScript.STAT_CHIP_FRACS[mini(i, 1)]
		var label_rect: Rect2 = ProfileFrameLayoutServiceScript.mapped_rect(card_size, label_frac)
		var chip_rect: Rect2 = ProfileFrameLayoutServiceScript.mapped_rect(card_size, chip_frac)
		_place_rect(_stat_labels[i], label_rect)
		var stat_font: int = ProfileFrameLayoutServiceScript.stat_font_size(label_rect.size.y)
		_stat_labels[i].add_theme_font_size_override("font_size", stat_font)
		_stat_labels[i].add_theme_constant_override("outline_size", maxi(int(round(float(stat_font) * 0.10)), 3))
		if i < _stat_chips.size():
			_place_rect(_stat_chips[i], chip_rect)
			var icon_node: Variant = _stat_chips[i].get_meta("icon", null)
			var icon_side: float = ProfileFrameLayoutServiceScript.chip_icon_side(chip_rect.size.y)
			if icon_node is TextureRect:
				(icon_node as TextureRect).custom_minimum_size = Vector2(icon_side, icon_side)
			var value_lbl: Label = _level_value_label if i == 0 else _days_value_label
			if value_lbl != null:
				var chip_font: int = ProfileFrameLayoutServiceScript.chip_font_size(chip_rect.size.y)
				value_lbl.add_theme_font_size_override("font_size", chip_font)
				value_lbl.add_theme_constant_override("outline_size", maxi(int(round(float(chip_font) * 0.12)), 3))

func _layout_edit_cells(card_size: Vector2) -> void:
	if avatar_well != null:
		avatar_well.position = Vector2.ZERO
		avatar_well.size = card_size
	for i in range(avatar_cells.size()):
		var cell_node: Variant = avatar_cells[i]
		if not (cell_node is Control):
			continue
		var cell := cell_node as Control
		var cell_rect: Rect2 = ProfileFrameLayoutServiceScript.edit_cell_rect(card_size, i)
		if cell_rect.size.x <= 0.0:
			cell.visible = false
			continue
		cell.visible = true
		cell.custom_minimum_size = Vector2.ZERO
		_place_rect(cell, cell_rect)
		_layout_avatar_check(cell, cell_rect.size.y / 140.0)

func _place_mapped(node: Control, card_size: Vector2, frac: Rect2) -> void:
	_place_rect(node, ProfileFrameLayoutServiceScript.mapped_rect(card_size, frac))

func _place_rect(node: Control, rect: Rect2) -> void:
	if node == null:
		return
	node.position = rect.position
	node.size = rect.size

func _layout_action_pill(btn: Button, lbl: Label, hit_rect: Rect2, text_rect: Rect2) -> void:
	if btn != null:
		btn.custom_minimum_size = Vector2.ZERO
		btn.position = hit_rect.position
		btn.size = hit_rect.size
	if lbl != null:
		lbl.position = text_rect.position
		lbl.size = text_rect.size
		var font_size: int = ProfileFrameLayoutServiceScript.action_font_size(hit_rect.size.y)
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.add_theme_constant_override("outline_size", maxi(int(round(float(font_size) * 0.12)), 4))

func _layout_preview_frame(frame: Panel, avatar: TextureRect, size: Vector2) -> void:
	if frame == null:
		return
	frame.custom_minimum_size = Vector2.ZERO
	_apply_preview_frame_style(frame, avatar, size)

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
		(mark as Label).add_theme_font_size_override("font_size", int(18.0 * scale))
	var btn: Variant = cell.get_meta("btn", null)
	if btn is TextureButton:
		var tex_btn := btn as TextureButton
		var side := maxf(minf(cell.size.x, cell.size.y), 1.0)
		var pad: float = ProfileFrameLayoutServiceScript.edit_cell_image_pad(side)
		tex_btn.offset_left = pad
		tex_btn.offset_top = pad
		tex_btn.offset_right = -pad
		tex_btn.offset_bottom = -pad
		var inner := maxf(side - pad * 2.0, 1.0)
		HudTextureButtons.apply_rounded_clip(tex_btn, Vector2(inner, inner), inner * 0.18)

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	frame_art.texture = FrameTexture
	frame_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_art.stretch_mode = TextureRect.STRETCH_SCALE
	frame_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame_art)

	title_label = _make_outlined_label("Perfil", 52)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false
	card.add_child(title_label)

	close_btn = _make_empty_button()
	close_btn.pressed.connect(_on_close_pressed)
	card.add_child(close_btn)

	preview_frame = Panel.new()
	preview_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.clip_contents = true
	preview_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	card.add_child(preview_frame)

	preview_avatar = TextureRect.new()
	preview_avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.add_child(preview_avatar)

	view_name_label = _make_outlined_label("", 42)
	view_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	view_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(view_name_label)

	name_label = _make_outlined_label("", 42)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	name_label.mouse_default_cursor_shape = Control.CURSOR_IBEAM
	name_label.gui_input.connect(_on_name_label_gui_input)
	card.add_child(name_label)

	name_edit = LineEdit.new()
	name_edit.max_length = 20
	name_edit.placeholder_text = "Tu nombre"
	name_edit.visible = false
	name_edit.clear_button_enabled = true
	name_edit.caret_blink = true
	if LogoFont != null:
		name_edit.add_theme_font_override("font", LogoFont)
	name_edit.text_changed.connect(_on_name_edit_changed)
	name_edit.text_submitted.connect(func(_t: String) -> void: _set_editing_name(false))
	card.add_child(name_edit)

	edit_name_btn = _make_empty_button()
	edit_name_btn.text = "✎"
	if LogoFont != null:
		edit_name_btn.add_theme_font_override("font", LogoFont)
	edit_name_btn.add_theme_color_override("font_color", PILL_TEXT)
	edit_name_btn.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	edit_name_btn.add_theme_constant_override("outline_size", 6)
	edit_name_btn.pressed.connect(_on_edit_name_pressed)
	card.add_child(edit_name_btn)

	edit_profile_btn = _make_empty_button()
	edit_profile_btn.pressed.connect(_on_edit_profile_pressed)
	card.add_child(edit_profile_btn)
	edit_profile_label = _make_outlined_label("Editar perfil", 40)
	edit_profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit_profile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(edit_profile_label)

	save_btn = _make_empty_button()
	save_btn.pressed.connect(_on_save_pressed)
	card.add_child(save_btn)
	save_label = _make_outlined_label("Guardar", 40)
	save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(save_label)

	_add_stat_row("Nivel actual", StarIcon, true)
	_add_stat_row("Días jugados", CalendarIcon, false)

	avatar_well = Panel.new()
	avatar_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_well.clip_contents = false
	avatar_well.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	avatar_well.visible = false
	card.add_child(avatar_well)

	avatar_cells.clear()
	for opt in SaveManager.get_avatar_options():
		var cell := _make_avatar_cell(str(opt.get("id", "")), str(opt.get("path", "")))
		avatar_well.add_child(cell)
		avatar_cells.append(cell)

	_apply_theme_colors()
	_set_page(PAGE_VIEW)

func _add_stat_row(caption: String, icon: Texture2D, is_level: bool) -> void:
	var lbl := _make_outlined_label(caption, 36)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(lbl)
	_stat_labels.append(lbl)

	var chip := Panel.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	card.add_child(chip)
	_stat_chips.append(chip)

	var chip_row := HBoxContainer.new()
	chip_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip_row.add_theme_constant_override("separation", 4)
	chip.add_child(chip_row)

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
	cell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cell.set_meta("avatar_id", avatar_id)

	var btn := TextureButton.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.offset_left = 3
	btn.offset_top = 3
	btn.offset_right = -3
	btn.offset_bottom = -3
	btn.texture_normal = load(path) as Texture2D
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
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
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", PILL_TEXT)
	lbl.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 5)
	if LogoFont != null:
		lbl.add_theme_font_override("font", LogoFont)
	return lbl

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

func _flat_style(bg: Color, border: Color, radius: int, border_w: int = 3) -> StyleBoxFlat:
	var style := UiStyleUtils.flat_style(bg, border, radius, border_w)
	style.anti_aliasing = true
	style.corner_detail = 12
	return style

func _apply_theme_colors() -> void:
	if card != null:
		card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if title_label != null:
		title_label.add_theme_color_override("font_color", TITLE_FILL)
		title_label.add_theme_color_override("font_outline_color", TITLE_OUTLINE)
	for lbl in [view_name_label, name_label]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", NAME_FILL)
			lbl.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	for lbl in [edit_profile_label, save_label]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", PILL_TEXT)
			lbl.add_theme_color_override("font_outline_color", PILL_OUTLINE)
	for lbl in _stat_labels:
		lbl.add_theme_color_override("font_color", STAT_INK)
		lbl.add_theme_color_override("font_outline_color", TITLE_OUTLINE)
	for value_lbl in [_level_value_label, _days_value_label]:
		if value_lbl != null:
			value_lbl.add_theme_color_override("font_color", STAT_INK)
			value_lbl.add_theme_color_override("font_outline_color", TITLE_OUTLINE)
	for chip in _stat_chips:
		chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if avatar_well != null:
		avatar_well.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if name_edit != null:
		var edit_style := _flat_style(Color(0.42, 0.24, 0.62, 0.18), Color(0.85, 0.78, 0.95, 0.0), 12, 0)
		name_edit.add_theme_stylebox_override("normal", edit_style)
		name_edit.add_theme_stylebox_override("focus", edit_style)
		name_edit.add_theme_color_override("font_color", NAME_FILL)
		name_edit.add_theme_color_override("font_placeholder_color", Color(0.92, 0.88, 0.96, 0.55))
	if edit_name_btn != null:
		edit_name_btn.add_theme_color_override("font_color", PILL_TEXT)
		edit_name_btn.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	_refresh_preview_avatars()

func _set_page(page: int) -> void:
	_page = page
	var editing := page == PAGE_EDIT
	if view_name_label != null:
		view_name_label.visible = not editing
	if name_label != null:
		name_label.visible = editing and not _editing_name
	if name_edit != null:
		name_edit.visible = editing and _editing_name
	if edit_name_btn != null:
		edit_name_btn.visible = editing
	if edit_profile_btn != null:
		edit_profile_btn.visible = not editing
	if edit_profile_label != null:
		edit_profile_label.visible = not editing
	if save_btn != null:
		save_btn.visible = editing
	if save_label != null:
		save_label.visible = editing
	for lbl in _stat_labels:
		lbl.visible = not editing
	for chip in _stat_chips:
		chip.visible = not editing
	if avatar_well != null:
		avatar_well.visible = editing
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
		name_label.visible = _page == PAGE_EDIT and not _editing_name
	if name_edit != null:
		if name_edit.text != _pending_username:
			name_edit.text = _pending_username
		name_edit.visible = _page == PAGE_EDIT and _editing_name
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

func _apply_preview_frame_style(frame: Panel, avatar: TextureRect, size: Vector2) -> void:
	if frame == null:
		return
	var border_w: int = ProfileFrameLayoutServiceScript.preview_border_width(size)
	var radius: int = int(ProfileFrameLayoutServiceScript.avatar_clip_radius(size))
	var border_col := SaveManager.get_avatar_border_color()
	frame.add_theme_stylebox_override(
		"panel",
		_flat_style(Color(0, 0, 0, 0), border_col, radius, border_w)
	)
	if avatar == null:
		return
	var pad: float = ProfileFrameLayoutServiceScript.preview_image_pad(size)
	avatar.offset_left = pad
	avatar.offset_top = pad
	avatar.offset_right = -pad
	avatar.offset_bottom = -pad
	var inner := Vector2(maxf(size.x - pad * 2.0, 1.0), maxf(size.y - pad * 2.0, 1.0))
	HudTextureButtons.apply_rounded_clip(
		avatar,
		inner,
		ProfileFrameLayoutServiceScript.avatar_clip_radius(inner)
	)

func _refresh_preview_avatars() -> void:
	var path := ""
	for opt in SaveManager.get_avatar_options():
		if str(opt.get("id", "")) == _pending_avatar_id:
			path = str(opt.get("path", ""))
			break
	var tex: Texture2D = SaveManager.get_avatar_texture()
	if not path.is_empty():
		tex = load(path) as Texture2D
	if preview_avatar != null:
		preview_avatar.texture = tex
	var fill := Vector2(128, 128)
	if preview_frame != null:
		fill = preview_frame.size
		if fill.x < 1.0 or fill.y < 1.0:
			fill = Vector2(128, 128)
	_apply_preview_frame_style(preview_frame, preview_avatar, fill)

func _refresh_avatar_selection() -> void:
	for cell in avatar_cells:
		if not (cell is Panel):
			continue
		var p := cell as Panel
		var selected := str(p.get_meta("avatar_id", "")) == _pending_avatar_id
		var cell_side := maxf(p.size.x, 1.0)
		if selected:
			p.add_theme_stylebox_override(
				"panel",
				_flat_style(Color(1, 1, 1, 0.0), SELECT_GREEN, int(cell_side * 0.28), 4)
			)
		else:
			p.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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

class_name SettingsOverlay
extends Control

signal restart_level_confirmed

const SettingsFrameLayoutServiceScript = preload("res://settings_frame_layout_service.gd")
const BoardMusicServiceScript = preload("res://board_music_service.gd")
const SettingsLinksServiceScript = preload("res://settings_links_service.gd")
const FRAME_PATH := "res://Imagenes/menu-settings.png"
const LogoFont = preload("res://Fonts/Lobster-Regular.ttf")
const REF_WIDTH := 1080.0
const SELECT_GREEN := Color(0.32, 0.86, 0.28, 1.0)
const TEXT_OUTLINE := Color(0.22, 0.10, 0.38, 0.88)
const TITLE_FILL := Color(0.42, 0.20, 0.60, 1.0)
const TITLE_OUTLINE := Color(1.00, 0.96, 0.92, 0.85)
const PILL_TEXT := Color(0.42, 0.20, 0.60, 1.0)
const PILL_OUTLINE := Color(1.00, 0.96, 0.92, 0.85)
const ROW_INK := Color(0.42, 0.20, 0.60, 1.0)
const THEME_SLOT_LILAC := Color(0.863, 0.745, 0.992, 1.0)
const THEME_SLOT_BORDER := Color(0.58, 0.38, 0.88, 1.0)
const THEME_SLOT_BORDER_W := 6
const LABEL_OUTLINE := 8
const BUTTON_OUTLINE := 8

var overlay: ColorRect = null
var card: Panel = null
var frame_art: TextureRect = null
var title_label: Label = null
var close_btn: Button = null
var bg_section_label: Label = null
var _about_btn: Button = null
var _about_ui: AboutOverlay = null
var themes_well: Panel = null
var theme_option_roots: Array[Panel] = []
var _toggle_labels: Array[Label] = []
var _toggle_btns: Array[Button] = []
var _toggle_pill_labels: Array[Label] = []
var _toggle_setters: Array[Callable] = []
var _music_btn: Button = null
var _music_pill_label: Label = null
var _restart_btn: Button = null
var _restart_label: Label = null
var _contact_btn: Button = null
var _contact_label: Label = null
var _restore_btn: Button = null
var _restore_label: Label = null
var _terms_btn: Button = null
var _terms_label: Label = null
var _privacy_btn: Button = null
var _privacy_label: Label = null
var _status_label: Label = null
var _restart_available := false
var _confirm_root: Control = null
var _confirm_card: Panel = null
var _confirm_title: Label = null
var _confirm_salir_btn: Button = null
var _confirm_atras_btn: Button = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()
	if not GameState.background_theme_changed.is_connected(_on_background_theme_changed):
		GameState.background_theme_changed.connect(_on_background_theme_changed)
	_apply_theme_colors()

func open() -> void:
	_hide_restart_confirm()
	_set_status("")
	_apply_theme_colors()
	_refresh_theme_selection()
	_refresh_toggle_states()
	_sync_restart_button_visibility()
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func close() -> void:
	_hide_restart_confirm()
	if _about_ui != null:
		_about_ui.close()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_open() -> bool:
	return visible

## Solo en partida: muestra el boton Reiniciar en la pastilla rosa central.
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
	var tex_size := Vector2(1223, 1457)
	if frame_art != null and frame_art.texture != null:
		tex_size = frame_art.texture.get_size()
	var card_size: Vector2 = SettingsFrameLayoutServiceScript.card_size(viewport_size, tex_size)
	card.size = card_size
	card.position = Vector2(
		(viewport_size.x - card_size.x) * 0.5,
		(viewport_size.y - card_size.y) * 0.5
	)
	if frame_art != null:
		frame_art.position = Vector2.ZERO
		frame_art.size = card_size
	_place_mapped(title_label, card_size, SettingsFrameLayoutServiceScript.TITLE_FRAC)
	if title_label != null:
		var title_h: float = SettingsFrameLayoutServiceScript.mapped_rect(
			card_size,
			SettingsFrameLayoutServiceScript.TITLE_FRAC
		).size.y
		var title_font: int = SettingsFrameLayoutServiceScript.title_font_size(title_h)
		title_label.add_theme_font_size_override("font_size", title_font)
		title_label.add_theme_constant_override("outline_size", maxi(int(round(float(title_font) * 0.10)), 4))
	_place_mapped(close_btn, card_size, SettingsFrameLayoutServiceScript.CLOSE_FRAC)
	_layout_toggle_row(0, card_size, _toggle_labels[0] if _toggle_labels.size() > 0 else null, _music_btn, _music_pill_label)
	_layout_toggle_row(1, card_size, _toggle_labels[1] if _toggle_labels.size() > 1 else null, _toggle_btns[0] if _toggle_btns.size() > 0 else null, _toggle_pill_labels[0] if _toggle_pill_labels.size() > 0 else null)
	_layout_toggle_row(2, card_size, _toggle_labels[2] if _toggle_labels.size() > 2 else null, _toggle_btns[1] if _toggle_btns.size() > 1 else null, _toggle_pill_labels[1] if _toggle_pill_labels.size() > 1 else null)
	_layout_action_pill(
		_restart_btn,
		_restart_label,
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.SECTION_FRAC),
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.SECTION_TEXT_FRAC),
		true
	)
	_place_mapped(_about_btn, card_size, SettingsFrameLayoutServiceScript.SECTION_FRAC)
	_place_mapped(bg_section_label, card_size, SettingsFrameLayoutServiceScript.SECTION_TEXT_FRAC)
	if bg_section_label != null:
		var section_h: float = SettingsFrameLayoutServiceScript.mapped_rect(
			card_size,
			SettingsFrameLayoutServiceScript.SECTION_TEXT_FRAC
		).size.y
		var section_font: int = SettingsFrameLayoutServiceScript.section_font_size(section_h)
		bg_section_label.add_theme_font_size_override("font_size", section_font)
		bg_section_label.add_theme_constant_override("outline_size", maxi(int(round(float(section_font) * 0.12)), 4))
	if _about_ui != null and _about_ui.visible:
		_about_ui.layout_for_viewport(viewport_size)
	if themes_well != null:
		themes_well.position = Vector2.ZERO
		themes_well.size = card_size
	for i in range(theme_option_roots.size()):
		var option: Panel = theme_option_roots[i]
		if option == null:
			continue
		var cell_rect: Rect2 = SettingsFrameLayoutServiceScript.theme_cell_rect(card_size, i)
		if cell_rect.size.x <= 0.0:
			option.visible = false
			continue
		option.visible = true
		option.custom_minimum_size = Vector2.ZERO
		_place_rect(option, cell_rect)
		_layout_theme_preview(option, cell_rect.size)
		_apply_theme_option_style(
			option,
			str(option.get_meta("theme_id", "")) == GameState.background_theme_id
		)
	_layout_action_pill(
		_contact_btn,
		_contact_label,
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.CONTACT_FRAC),
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.CONTACT_TEXT_FRAC),
		true
	)
	_layout_action_pill(
		_restore_btn,
		_restore_label,
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.RESTORE_FRAC),
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.RESTORE_TEXT_FRAC),
		true
	)
	_layout_action_pill(
		_terms_btn,
		_terms_label,
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.TERMS_FRAC),
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.TERMS_TEXT_FRAC),
		true
	)
	_layout_action_pill(
		_privacy_btn,
		_privacy_label,
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.PRIVACY_FRAC),
		SettingsFrameLayoutServiceScript.mapped_rect(card_size, SettingsFrameLayoutServiceScript.PRIVACY_TEXT_FRAC),
		true
	)
	_place_mapped(_status_label, card_size, SettingsFrameLayoutServiceScript.STATUS_FRAC)
	var status_h: float = SettingsFrameLayoutServiceScript.mapped_rect(
		card_size,
		SettingsFrameLayoutServiceScript.STATUS_FRAC
	).size.y
	var status_font: int = SettingsFrameLayoutServiceScript.legal_font_size(status_h)
	if _status_label != null:
		_status_label.add_theme_font_size_override("font_size", status_font)
		_status_label.add_theme_constant_override("outline_size", maxi(int(round(float(status_font) * 0.10)), 3))
	_layout_confirm_card(viewport_size.x / REF_WIDTH)

func _layout_toggle_row(index: int, card_size: Vector2, label: Label, btn: Button, pill_label: Label) -> void:
	if index < 0 or index >= SettingsFrameLayoutServiceScript.TOGGLE_LABEL_FRACS.size():
		return
	var label_rect: Rect2 = SettingsFrameLayoutServiceScript.mapped_rect(
		card_size,
		SettingsFrameLayoutServiceScript.TOGGLE_LABEL_FRACS[index]
	)
	var pill_rect: Rect2 = SettingsFrameLayoutServiceScript.mapped_rect(
		card_size,
		SettingsFrameLayoutServiceScript.TOGGLE_PILL_FRACS[index]
	)
	_place_rect(label, label_rect)
	if label != null:
		var label_font: int = SettingsFrameLayoutServiceScript.toggle_label_font_size(label_rect.size.y)
		label.add_theme_font_size_override("font_size", label_font)
		label.add_theme_constant_override("outline_size", maxi(int(round(float(label_font) * 0.12)), 3))
	_place_rect(btn, pill_rect)
	_place_rect(pill_label, pill_rect)
	if btn != null:
		btn.custom_minimum_size = Vector2.ZERO
	if pill_label != null:
		var pill_font: int = SettingsFrameLayoutServiceScript.toggle_pill_font_size(pill_rect.size.y)
		pill_label.add_theme_font_size_override("font_size", pill_font)
		pill_label.add_theme_constant_override("outline_size", maxi(int(round(float(pill_font) * 0.12)), 3))

func _layout_action_pill(btn: Button, lbl: Label, hit_rect: Rect2, text_rect: Rect2, grid: bool = false) -> void:
	if btn != null:
		btn.custom_minimum_size = Vector2.ZERO
		btn.position = hit_rect.position
		btn.size = hit_rect.size
	if lbl != null:
		lbl.position = text_rect.position
		lbl.size = text_rect.size
		var font_size: int = (
			SettingsFrameLayoutServiceScript.grid_action_font_size(hit_rect.size.y)
			if grid
			else SettingsFrameLayoutServiceScript.action_font_size(hit_rect.size.y)
		)
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.add_theme_constant_override("outline_size", maxi(int(round(float(font_size) * 0.12)), 4))

func _layout_theme_preview(option: Panel, size: Vector2) -> void:
	var preview: Variant = option.get_meta("preview", null)
	if not (preview is TextureRect):
		return
	var photo := preview as TextureRect
	var pad: float = float(THEME_SLOT_BORDER_W)
	photo.offset_left = pad
	photo.offset_top = pad
	photo.offset_right = -pad
	photo.offset_bottom = -pad
	var inner := Vector2(maxf(size.x - pad * 2.0, 1.0), maxf(size.y - pad * 2.0, 1.0))
	var outer_radius: float = maxf(minf(size.x, size.y) * 0.22, 16.0)
	var image_radius: float = maxf(outer_radius - pad, 10.0)
	HudTextureButtons.apply_rounded_clip(photo, inner, image_radius)

func _place_mapped(node: Control, card_size: Vector2, frac: Rect2) -> void:
	_place_rect(node, SettingsFrameLayoutServiceScript.mapped_rect(card_size, frac))

func _place_rect(node: Control, rect: Rect2) -> void:
	if node == null:
		return
	node.position = rect.position
	node.size = rect.size

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
	if ResourceLoader.exists(FRAME_PATH):
		frame_art.texture = load(FRAME_PATH) as Texture2D
	frame_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_art.stretch_mode = TextureRect.STRETCH_SCALE
	frame_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame_art)

	title_label = _make_outlined_label("Ajustes", 52)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false
	card.add_child(title_label)

	close_btn = _make_empty_button()
	close_btn.pressed.connect(close)
	card.add_child(close_btn)

	_add_row_label("Música")
	_music_btn = _make_empty_button()
	_music_btn.pressed.connect(_on_music_pressed)
	card.add_child(_music_btn)
	_music_pill_label = _make_outlined_label("Chill", 26)
	_music_pill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_music_pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(_music_pill_label)

	_add_toggle_row("Sonidos", _get_sounds_enabled, _set_sounds_enabled)
	_add_toggle_row("Vibración", _get_vibration_enabled, _set_vibration_enabled)

	_about_btn = _make_empty_button()
	_about_btn.pressed.connect(_on_about_pressed)
	card.add_child(_about_btn)
	bg_section_label = _make_outlined_label("Coin Stack Puzzle\nversion 1.1", 36)
	bg_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg_section_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bg_section_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bg_section_label.clip_text = false
	card.add_child(bg_section_label)

	_restart_btn = _make_empty_button()
	_restart_btn.pressed.connect(_on_restart_pressed)
	_restart_btn.visible = false
	card.add_child(_restart_btn)
	_restart_label = _make_outlined_label("Reiniciar nivel", 40)
	_restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_restart_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_restart_label.visible = false
	card.add_child(_restart_label)

	themes_well = Panel.new()
	themes_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	themes_well.clip_contents = false
	themes_well.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	card.add_child(themes_well)

	for theme in GameState.get_background_themes():
		var option := _build_theme_option(theme)
		themes_well.add_child(option)
		theme_option_roots.append(option)

	_contact_btn = _make_empty_button()
	_contact_btn.pressed.connect(_on_contact_pressed)
	card.add_child(_contact_btn)
	_contact_label = _make_outlined_label("Enviar comentarios", 40)
	_contact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(_contact_label)

	_restore_btn = _make_empty_button()
	_restore_btn.pressed.connect(_on_restore_pressed)
	card.add_child(_restore_btn)
	_restore_label = _make_outlined_label("Restaurar compras", 40)
	_restore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_restore_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(_restore_label)

	_terms_btn = _make_empty_button()
	_terms_btn.pressed.connect(_on_terms_pressed)
	card.add_child(_terms_btn)
	_terms_label = _make_outlined_label("Términos y condiciones", 32)
	_terms_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_terms_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(_terms_label)

	_privacy_btn = _make_empty_button()
	_privacy_btn.pressed.connect(_on_privacy_pressed)
	card.add_child(_privacy_btn)
	_privacy_label = _make_outlined_label("Política de privacidad", 32)
	_privacy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_privacy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(_privacy_label)

	_status_label = _make_outlined_label("", 24)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.visible = false
	card.add_child(_status_label)

	_build_restart_confirm()
	_apply_theme_colors()

func _add_row_label(text: String) -> void:
	var lbl := _make_outlined_label(text, 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(lbl)
	_toggle_labels.append(lbl)

func _add_toggle_row(label_text: String, getter: Callable, setter: Callable) -> void:
	_add_row_label(label_text)
	var btn := _make_empty_button()
	var toggle_idx := _toggle_btns.size()
	btn.toggle_mode = true
	btn.pressed.connect(_on_toggle_pressed.bind(toggle_idx))
	card.add_child(btn)
	_toggle_btns.append(btn)
	_toggle_setters.append(setter)
	var pill := _make_outlined_label("ON", 26)
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(pill)
	_toggle_pill_labels.append(pill)
	btn.button_pressed = bool(getter.call())
	_apply_toggle_style(btn, btn.button_pressed)

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
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_confirm_title = _make_outlined_label("¿Desea reiniciar nivel?", 42)
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
	if _restart_label != null:
		_restart_label.visible = _restart_available
	if bg_section_label != null:
		bg_section_label.visible = not _restart_available
	if _about_btn != null:
		_about_btn.visible = not _restart_available
	if visible:
		layout_for_viewport(get_viewport_rect().size)

func _show_restart_confirm() -> void:
	if _confirm_root == null:
		return
	_confirm_root.visible = true
	_layout_confirm_card(get_viewport_rect().size.x / REF_WIDTH)

func _hide_restart_confirm() -> void:
	if _confirm_root != null:
		_confirm_root.visible = false

func _layout_confirm_card(_scale: float) -> void:
	if _confirm_card == null:
		return
	var vp := get_viewport_rect().size
	var s: float = clampf(minf(vp.x / REF_WIDTH, vp.y / 1920.0), 0.75, 1.25)
	var pad: float = 32.0 * s
	var sep: float = 18.0 * s
	var title_h: float = 120.0 * s
	var btn_h: float = 76.0 * s
	if _confirm_salir_btn != null:
		btn_h = maxf(btn_h, _confirm_salir_btn.custom_minimum_size.y)
	var card_w: float = minf(vp.x * 0.86, 720.0 * s)
	var card_h: float = pad * 2.0 + title_h + btn_h * 2.0 + sep * 2.0
	_confirm_card.size = Vector2(card_w, card_h)
	_confirm_card.position = Vector2((vp.x - card_w) * 0.5, (vp.y - card_h) * 0.5)
	if _confirm_title != null:
		_confirm_title.add_theme_font_size_override("font_size", int(42.0 * s))
		_confirm_title.add_theme_constant_override("outline_size", int(LABEL_OUTLINE * s))
	if _confirm_salir_btn != null:
		_confirm_salir_btn.custom_minimum_size = Vector2(0, btn_h)
		_confirm_salir_btn.add_theme_font_size_override("font_size", int(38.0 * s))
		_confirm_salir_btn.add_theme_constant_override("outline_size", int(BUTTON_OUTLINE * s))
	if _confirm_atras_btn != null:
		_confirm_atras_btn.custom_minimum_size = Vector2(0, btn_h)
		_confirm_atras_btn.add_theme_font_size_override("font_size", int(38.0 * s))
		_confirm_atras_btn.add_theme_constant_override("outline_size", int(BUTTON_OUTLINE * s))
	var margin: MarginContainer = null
	for child in _confirm_card.get_children():
		if child is MarginContainer:
			margin = child as MarginContainer
			break
	if margin != null:
		var m: int = int(round(pad))
		margin.add_theme_constant_override("margin_left", m)
		margin.add_theme_constant_override("margin_top", m)
		margin.add_theme_constant_override("margin_right", m)
		margin.add_theme_constant_override("margin_bottom", m)
		if margin.get_child_count() > 0 and margin.get_child(0) is VBoxContainer:
			(margin.get_child(0) as VBoxContainer).add_theme_constant_override("separation", int(round(sep)))

func _on_restart_pressed() -> void:
	_show_restart_confirm()

func _on_contact_pressed() -> void:
	_open_external_url(SettingsLinksServiceScript.CONTACT_URL)

func _on_restore_pressed() -> void:
	_set_status(SettingsLinksServiceScript.restore_purchases_message())

func _on_terms_pressed() -> void:
	_open_external_url(SettingsLinksServiceScript.TERMS_URL)

func _on_privacy_pressed() -> void:
	_open_external_url(SettingsLinksServiceScript.PRIVACY_URL)

func _open_external_url(url: String) -> void:
	if SettingsLinksServiceScript.is_configured(url):
		OS.shell_open(url.strip_edges())
		_set_status("")
		return
	_set_status(SettingsLinksServiceScript.missing_link_message())

func _set_status(text: String) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_label.visible = not text.strip_edges().is_empty()
	if visible:
		layout_for_viewport(get_viewport_rect().size)

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
	lbl.add_theme_color_override("font_color", PILL_TEXT)
	lbl.add_theme_color_override("font_outline_color", PILL_OUTLINE)
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
	btn.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	btn.add_theme_constant_override("outline_size", BUTTON_OUTLINE)
	GameState.hook_button_sound(btn)
	return btn

func _flat_style(bg: Color, border: Color, radius: int, border_w: int = 3) -> StyleBoxFlat:
	return UiStyleUtils.flat_style(bg, border, radius, border_w)

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
	if card != null:
		card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if themes_well != null:
		themes_well.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if title_label != null:
		title_label.add_theme_color_override("font_color", TITLE_FILL)
		title_label.add_theme_color_override("font_outline_color", TITLE_OUTLINE)
	for lbl in _toggle_labels:
		if lbl != null:
			lbl.add_theme_color_override("font_color", ROW_INK)
			lbl.add_theme_color_override("font_outline_color", TITLE_OUTLINE)
	for lbl in [_music_pill_label]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", PILL_TEXT)
			lbl.add_theme_color_override("font_outline_color", PILL_OUTLINE)
	for lbl in _toggle_pill_labels:
		if lbl != null:
			lbl.add_theme_color_override("font_color", PILL_TEXT)
			lbl.add_theme_color_override("font_outline_color", PILL_OUTLINE)
	for lbl in [bg_section_label, _restart_label, _contact_label, _restore_label, _terms_label, _privacy_label]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", PILL_TEXT)
			lbl.add_theme_color_override("font_outline_color", PILL_OUTLINE)
	if _status_label != null:
		_status_label.add_theme_color_override("font_color", ROW_INK)
		_status_label.add_theme_color_override("font_outline_color", TITLE_OUTLINE)

	var p: Dictionary = GameState.get_ui_palette()
	var card_bg: Color = p.get("settings_card_bg", Color(0.62, 0.52, 0.82, 0.98))
	card_bg = card_bg.lightened(0.18)
	var btn_on: Color = p.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98))
	var btn_border: Color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))
	var card_border: Color = p.get("settings_card_border", Color(0.42, 0.28, 0.58, 0.95))
	if _confirm_card != null:
		_confirm_card.add_theme_stylebox_override("panel", _flat_style(card_bg, btn_on, 30, 5))
	if _confirm_title != null:
		_confirm_title.add_theme_color_override("font_color", TITLE_FILL)
		_confirm_title.add_theme_color_override("font_outline_color", TITLE_OUTLINE)
	_apply_button_style(_confirm_salir_btn, btn_on, btn_border, 26, TITLE_FILL)
	_apply_button_style(_confirm_atras_btn, p.get("settings_btn_off", Color(0.40, 0.50, 0.40, 0.95)), card_border, 26, TITLE_FILL)

	_apply_music_style()
	for i in range(_toggle_btns.size()):
		_apply_toggle_style(_toggle_btns[i], _toggle_btns[i].button_pressed)
	_refresh_theme_selection()
	_apply_rainbow_ui_fills()

func _apply_rainbow_ui_fills() -> void:
	if _confirm_card != null:
		HudTextureButtons.apply_optional_rainbow_fill(_confirm_card, 30, _confirm_card.size, 5)
	if _confirm_salir_btn != null:
		HudTextureButtons.apply_optional_rainbow_fill(_confirm_salir_btn, 22, _confirm_salir_btn.size, 3)
	if _confirm_atras_btn != null:
		HudTextureButtons.apply_optional_rainbow_fill(_confirm_atras_btn, 22, _confirm_atras_btn.size, 3)

func _get_sounds_enabled() -> bool:
	return GameState.sounds_enabled

func _get_vibration_enabled() -> bool:
	return GameState.vibration_enabled

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

func _on_music_pressed() -> void:
	GameState.cycle_music_track()
	_apply_music_style()

func _apply_music_style() -> void:
	if _music_pill_label == null:
		return
	_music_pill_label.text = BoardMusicServiceScript.button_label(GameState.music_track_id)

func _refresh_toggle_states() -> void:
	if _toggle_btns.size() < 2:
		return
	_apply_music_style()
	_sync_toggle_btn(0, GameState.sounds_enabled)
	_sync_toggle_btn(1, GameState.vibration_enabled)

func _sync_toggle_btn(index: int, on: bool) -> void:
	_toggle_btns[index].button_pressed = on
	_apply_toggle_style(_toggle_btns[index], on)

func _apply_toggle_style(btn: Button, is_on: bool) -> void:
	var idx := _toggle_btns.find(btn)
	if idx >= 0 and idx < _toggle_pill_labels.size() and _toggle_pill_labels[idx] != null:
		_toggle_pill_labels[idx].text = "ON" if is_on else "OFF"

func _build_theme_option(theme: Dictionary) -> Panel:
	var theme_id := str(theme.get("id", ""))
	var wrap := Panel.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.clip_contents = false
	wrap.set_meta("theme_id", theme_id)
	wrap.add_theme_stylebox_override(
		"panel",
		_flat_style(THEME_SLOT_LILAC, THEME_SLOT_BORDER, 22, THEME_SLOT_BORDER_W)
	)

	var photo := TextureRect.new()
	photo.set_anchors_preset(Control.PRESET_FULL_RECT)
	photo.offset_left = float(THEME_SLOT_BORDER_W)
	photo.offset_top = float(THEME_SLOT_BORDER_W)
	photo.offset_right = -float(THEME_SLOT_BORDER_W)
	photo.offset_bottom = -float(THEME_SLOT_BORDER_W)
	photo.texture = load(str(theme.get("path", ""))) as Texture2D
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(photo)

	var hit := Button.new()
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.text = ""
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	hit.add_theme_stylebox_override("normal", empty)
	hit.add_theme_stylebox_override("hover", empty)
	hit.add_theme_stylebox_override("pressed", empty)
	hit.add_theme_stylebox_override("focus", empty)
	hit.add_theme_stylebox_override("disabled", empty)
	hit.pressed.connect(_on_theme_option_pressed.bind(theme_id))
	GameState.hook_button_sound(hit)
	wrap.add_child(hit)

	wrap.set_meta("preview", photo)
	return wrap

func _apply_theme_option_style(option: Panel, selected: bool) -> void:
	var slot_min: float = minf(option.size.x, option.size.y)
	var radius: int = 22
	if slot_min > 1.0:
		radius = maxi(int(round(slot_min * 0.22)), 16)
	var border: Color = SELECT_GREEN if selected else THEME_SLOT_BORDER
	option.add_theme_stylebox_override(
		"panel",
		_flat_style(THEME_SLOT_LILAC, border, radius, THEME_SLOT_BORDER_W)
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

func _ensure_about_overlay() -> void:
	if _about_ui != null:
		return
	_about_ui = AboutOverlay.new()
	_about_ui.visible = false
	_about_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_about_ui.z_index = 40
	add_child(_about_ui)

func _on_about_pressed() -> void:
	_ensure_about_overlay()
	if _about_ui != null:
		_about_ui.open()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _about_ui != null and _about_ui.is_open():
			return
		if _confirm_root != null and _confirm_root.visible:
			_hide_restart_confirm()
			return
		if card != null and not card.get_global_rect().has_point((event as InputEventMouseButton).position):
			close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		layout_for_viewport(get_viewport_rect().size)

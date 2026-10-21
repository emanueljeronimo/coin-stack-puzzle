class_name DailyLoginOverlay
extends Control

signal rewards_changed

const DialogBuilderServiceScript = preload("res://dialog_builder_service.gd")
const DailyLoginServiceScript = preload("res://daily_login_service.gd")
const ShopCatalogServiceScript = preload("res://shop_catalog_service.gd")
const GameBoosterServiceScript = preload("res://game_booster_service.gd")
const DiamondIconTexture = preload("res://Imagenes/icono-diamante.png")
const LifeIconTexture = preload("res://Imagenes/icono-vidas.png")
const MixIconTexture = preload("res://Imagenes/icono-mezclar.png")
const HammerIconTexture = preload("res://Imagenes/icono-martillo.png")
const GloveIconTexture = preload("res://Imagenes/icono-mano.png")
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
var _grid: GridContainer = null
var _slots: Array[Dictionary] = []
var _close_menu_btn: Button = null
var _opened_at_msec: int = 0
var _applying_pending: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()
	if not GameState.background_theme_changed.is_connected(_on_background_theme_changed):
		GameState.background_theme_changed.connect(_on_background_theme_changed)
	_apply_theme_colors()

func open() -> void:
	if GameState != null and not DailyLoginServiceScript.is_unlocked(GameState.player_level):
		return
	apply_pending_grants()
	_apply_theme_colors()
	_refresh_slots()
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
	var scale: float = clampf(minf(viewport_size.x / REF_WIDTH, viewport_size.y / 1920.0), 0.75, 1.25)
	var card_w: float = minf(viewport_size.x * 0.90, 780.0 * scale)
	var pad: float = 16.0 * scale
	var sep: int = int(12.0 * scale)
	var header_h: float = 58.0 * scale
	var well_h: float = 520.0 * scale
	var footer_h: float = 80.0 * scale
	if header != null:
		header.custom_minimum_size = Vector2(0, header_h)
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(46.0 * scale))
		title_label.add_theme_constant_override("outline_size", int(7.0 * scale))
	if close_btn != null:
		var close_side: float = 56.0 * scale
		close_btn.custom_minimum_size = Vector2(close_side, close_side)
		close_btn.offset_left = -close_side
		close_btn.offset_top = -close_side * 0.5
		close_btn.offset_right = 0
		close_btn.offset_bottom = close_side * 0.5
		close_btn.add_theme_font_size_override("font_size", int(36.0 * scale))
	if content_well != null:
		content_well.custom_minimum_size = Vector2(0, well_h)
	if _grid != null:
		_grid.add_theme_constant_override("h_separation", int(12.0 * scale))
		_grid.add_theme_constant_override("v_separation", int(12.0 * scale))
	for slot_ui in _slots:
		var icon: TextureRect = slot_ui.get("icon") as TextureRect
		var qty: Label = slot_ui.get("qty") as Label
		var lock: Label = slot_ui.get("lock") as Label
		var btn: Button = slot_ui.get("button") as Button
		if icon != null:
			icon.custom_minimum_size = Vector2(72.0 * scale, 72.0 * scale)
		if qty != null:
			qty.add_theme_font_size_override("font_size", int(32.0 * scale))
			qty.add_theme_constant_override("outline_size", int(5.0 * scale))
		if lock != null:
			lock.add_theme_font_size_override("font_size", int(28.0 * scale))
		if btn != null:
			btn.custom_minimum_size = Vector2(0, 58.0 * scale)
			btn.add_theme_font_size_override("font_size", int(26.0 * scale))
	if _close_menu_btn != null:
		_close_menu_btn.custom_minimum_size = Vector2(0, footer_h)
		_close_menu_btn.add_theme_font_size_override("font_size", int(40.0 * scale))
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", sep)
	if card_margin != null:
		var m: int = int(round(pad))
		card_margin.add_theme_constant_override("margin_left", m)
		card_margin.add_theme_constant_override("margin_top", m)
		card_margin.add_theme_constant_override("margin_right", m)
		card_margin.add_theme_constant_override("margin_bottom", m)
	var card_h: float = pad * 2.0 + header_h + well_h + footer_h + float(sep) * 2.0
	card_h = minf(card_h, viewport_size.y * 0.92)
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
	card.add_child(card_margin)

	main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_margin.add_child(main_vbox)

	header = Control.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)

	title_label = _make_outlined_label("Login diario", 46)
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)

	close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	if LogoFont != null:
		close_btn.add_theme_font_override("font", LogoFont)
	close_btn.pressed.connect(close)
	GameState.hook_button_sound(close_btn)
	header.add_child(close_btn)

	content_well = Panel.new()
	content_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_well)

	var well_margin := MarginContainer.new()
	well_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	well_margin.add_theme_constant_override("margin_left", 10)
	well_margin.add_theme_constant_override("margin_top", 10)
	well_margin.add_theme_constant_override("margin_right", 10)
	well_margin.add_theme_constant_override("margin_bottom", 10)
	content_well.add_child(well_margin)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	well_margin.add_child(_grid)

	_slots.clear()
	for i in range(DailyLoginServiceScript.SLOT_COUNT):
		var cell: Dictionary = _make_slot_cell(i)
		_grid.add_child(cell.get("root") as Control)
		_slots.append(cell)

	_close_menu_btn = _make_action_button("Cerrar")
	_close_menu_btn.pressed.connect(close)
	main_vbox.add_child(_close_menu_btn)

func _make_slot_cell(index: int) -> Dictionary:
	var root := Panel.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var icon := TextureRect.new()
	icon.texture = DiamondIconTexture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(72, 72)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var qty := _make_outlined_label("", 32)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(qty)

	var lock := _make_outlined_label("🔒", 28)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.visible = false
	vbox.add_child(lock)

	var btn := _make_action_button("Gratis")
	btn.pressed.connect(_on_slot_pressed.bind(index))
	vbox.add_child(btn)

	return {
		"root": root,
		"icon": icon,
		"qty": qty,
		"lock": lock,
		"button": btn,
	}

func _player_level() -> int:
	if GameState != null:
		return GameState.player_level
	return 1

func _slot_defs(day_key: String) -> Array:
	return DailyLoginServiceScript.slot_defs(day_key, _player_level())

func _load_progress() -> Dictionary:
	var today: String = DailyLoginServiceScript.local_day_key()
	var saved_day := ""
	var saved_claimed := 0
	var saved_applied := 0
	if SaveManager != null:
		saved_day = str(SaveManager.player_data.get("daily_login_day", ""))
		saved_claimed = int(SaveManager.player_data.get("daily_login_claimed", 0))
		saved_applied = int(SaveManager.player_data.get("daily_login_applied", 0))
	return DailyLoginServiceScript.synced_progress(saved_day, saved_claimed, today, saved_applied)

func _save_progress(day_key: String, claimed: int, applied: int = -1) -> void:
	if SaveManager == null:
		return
	var applied_count: int = claimed if applied < 0 else applied
	SaveManager.player_data["daily_login_day"] = day_key
	SaveManager.player_data["daily_login_claimed"] = claimed
	SaveManager.player_data["daily_login_applied"] = applied_count
	SaveManager.save_game()

func apply_pending_grants() -> bool:
	if _applying_pending:
		return false
	if GameState != null and not DailyLoginServiceScript.is_unlocked(GameState.player_level):
		return false
	var progress: Dictionary = _load_progress()
	var claimed: int = int(progress.get("claimed", 0))
	var applied: int = int(progress.get("applied", 0))
	var pending: Array = DailyLoginServiceScript.pending_grant_indexes(claimed, applied)
	if pending.is_empty():
		return false
	_applying_pending = true
	var defs: Array = _slot_defs(str(progress.get("day", "")))
	var granted_any := false
	for raw_index in pending:
		var index: int = int(raw_index)
		if index < 0 or index >= defs.size():
			continue
		var slot: Dictionary = defs[index] as Dictionary
		if str(slot.get("kind", "")) == "unlimited_lives" and GameState != null and GameState.is_unlimited_lives():
			continue
		_apply_grant(slot)
		granted_any = true
	_save_progress(str(progress.get("day", "")), claimed, claimed)
	_applying_pending = false
	if granted_any:
		rewards_changed.emit()
	return granted_any

func _refresh_slots() -> void:
	var progress: Dictionary = _load_progress()
	var claimed: int = int(progress.get("claimed", 0))
	var defs: Array = _slot_defs(str(progress.get("day", "")))
	for i in range(_slots.size()):
		if i >= defs.size():
			continue
		var slot: Dictionary = defs[i] as Dictionary
		var ui: Dictionary = _slots[i]
		var icon: TextureRect = ui.get("icon") as TextureRect
		var qty: Label = ui.get("qty") as Label
		var lock: Label = ui.get("lock") as Label
		var btn: Button = ui.get("button") as Button
		var root: Panel = ui.get("root") as Panel
		if icon != null:
			icon.texture = _icon_for_slot(slot)
		if qty != null:
			qty.text = DailyLoginServiceScript.slot_label(slot)
		var status: String = DailyLoginServiceScript.slot_status(i, claimed)
		if lock != null:
			lock.visible = status == "locked"
		if btn != null:
			if status == "claimed":
				btn.text = "Listo"
				btn.disabled = true
			elif status == "locked":
				btn.text = str(slot.get("button", ""))
				btn.disabled = true
			else:
				btn.text = str(slot.get("button", ""))
				btn.disabled = false
		if root != null:
			root.modulate = Color(1, 1, 1, 1) if status == "available" else Color(0.72, 0.72, 0.72, 0.92)
	_apply_theme_colors()

func _icon_for_slot(slot: Dictionary) -> Texture2D:
	var kind: String = str(slot.get("kind", ""))
	if kind == "unlimited_lives":
		return LifeIconTexture
	if kind == "booster":
		match str(slot.get("booster_type", "mix")):
			"hammer":
				return HammerIconTexture
			"glove":
				return GloveIconTexture
			_:
				return MixIconTexture
	return DiamondIconTexture

func _on_slot_pressed(index: int) -> void:
	if GameState != null and not DailyLoginServiceScript.is_unlocked(GameState.player_level):
		return
	var progress: Dictionary = _load_progress()
	var claimed: int = int(progress.get("claimed", 0))
	if not DailyLoginServiceScript.can_claim(index, claimed):
		return
	var defs: Array = _slot_defs(str(progress.get("day", "")))
	if index < 0 or index >= defs.size():
		return
	var result: Dictionary = DailyLoginServiceScript.claim(index, claimed)
	if not bool(result.get("ok", false)):
		return
	_apply_grant(defs[index] as Dictionary)
	var new_claimed: int = int(result.get("claimed", claimed))
	_save_progress(str(progress.get("day", "")), new_claimed, new_claimed)
	_refresh_slots()
	rewards_changed.emit()

func _apply_grant(slot: Dictionary) -> void:
	var kind: String = str(slot.get("kind", ""))
	if kind == "diamonds":
		var amount: int = int(slot.get("amount", 0))
		if amount > 0 and SaveManager != null:
			SaveManager.add_coins(amount)
		elif amount > 0 and GameState != null:
			GameState.player_diamonds += amount
		return
	if kind == "booster":
		_persist_booster_uses(str(slot.get("booster_type", "")), int(slot.get("amount", 1)))
		return
	if kind == "unlimited_lives" and GameState != null:
		GameState.grant_unlimited_lives(int(slot.get("seconds", 0)))

func _persist_booster_uses(booster_type: String, amount: int) -> void:
	if amount <= 0 or booster_type.is_empty():
		return
	var snap: Dictionary = {}
	if SaveManager != null and SaveManager.player_data.get("checkpoint_snapshot") is Dictionary:
		snap = (SaveManager.player_data["checkpoint_snapshot"] as Dictionary).duplicate(true)
	elif GameState != null:
		snap = GameState.checkpoint_snapshot.duplicate(true)
	var counts: Dictionary = GameBoosterServiceScript.read_counts(snap)
	if not snap.has("booster_counts") and not snap.has("wildcard_counts") and GameState != null:
		counts = GameBoosterServiceScript.read_counts(GameState.checkpoint_snapshot)
	counts = ShopCatalogServiceScript.apply_booster_uses(counts, booster_type, amount)
	GameBoosterServiceScript.write_state(snap, counts, GameBoosterServiceScript.read_granted(snap))
	if GameState != null:
		GameState.checkpoint_snapshot = snap
	if SaveManager != null:
		SaveManager.player_data["checkpoint_snapshot"] = snap
		var runtime: Variant = SaveManager.player_data.get("runtime_snapshot", {})
		if runtime is Dictionary:
			var rt: Dictionary = (runtime as Dictionary).duplicate(true)
			rt["booster_counts"] = snap["booster_counts"]
			SaveManager.player_data["runtime_snapshot"] = rt
		SaveManager.save_game()

func _on_dimmer_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if DialogBuilderServiceScript.should_ignore_open_click(_opened_at_msec, Time.get_ticks_msec()):
		return
	var mouse_event := event as InputEventMouseButton
	if card != null and card.get_global_rect().has_point(mouse_event.global_position):
		return
	close()

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
	GameState.hook_button_sound(btn)
	return btn

func _flat_style(bg: Color, border: Color, radius: int, border_w: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
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
	btn.add_theme_stylebox_override("disabled", style)

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
	var btn_off: Color = p.get("settings_btn_off", Color(0.34, 0.26, 0.48, 0.95))
	if card != null:
		card.add_theme_stylebox_override("panel", _flat_style(card_bg, card_border, 30, 4))
	if content_well != null:
		content_well.add_theme_stylebox_override("panel", _flat_style(well, card_border.darkened(0.15), 20, 2))
	_apply_button_style(close_btn, CLOSE_RED, CLOSE_RED_BORDER, 14, Color(0.90, 0.88, 0.85))
	if title_label != null:
		title_label.add_theme_color_override("font_color", p.get("settings_title", text_marble))
	_apply_button_style(_close_menu_btn, btn_on, btn_border, 22, text_marble)
	var progress: Dictionary = _load_progress()
	var claimed: int = int(progress.get("claimed", 0))
	for i in range(_slots.size()):
		var ui: Dictionary = _slots[i]
		var root: Panel = ui.get("root") as Panel
		var qty: Label = ui.get("qty") as Label
		var btn: Button = ui.get("button") as Button
		if root != null:
			root.add_theme_stylebox_override(
				"panel",
				_flat_style(well.lightened(0.06), card_border.darkened(0.1), 18, 2)
			)
		if qty != null:
			qty.add_theme_color_override("font_color", text_marble)
		var status: String = DailyLoginServiceScript.slot_status(i, claimed)
		if status == "available":
			_apply_button_style(btn, btn_on, btn_border, 16, text_marble)
		else:
			_apply_button_style(btn, btn_off, card_border.darkened(0.2), 16, text_marble)
	_apply_rainbow_ui_fills()

func _apply_rainbow_ui_fills() -> void:
	if card != null:
		HudTextureButtons.apply_optional_rainbow_fill(card, 30, card.size, 4)
	if _close_menu_btn != null:
		HudTextureButtons.apply_optional_rainbow_fill(_close_menu_btn, 22, _close_menu_btn.size, 3)
	for ui in _slots:
		var root: Panel = ui.get("root") as Panel
		var btn: Button = ui.get("button") as Button
		if root != null:
			HudTextureButtons.apply_optional_rainbow_fill(root, 18, root.size, 2)
		if btn != null:
			HudTextureButtons.apply_optional_rainbow_fill(btn, 16, btn.size, 3)

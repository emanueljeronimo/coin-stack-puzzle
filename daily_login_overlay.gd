class_name DailyLoginOverlay
extends Control

signal rewards_changed

const DialogBuilderServiceScript = preload("res://dialog_builder_service.gd")
const DailyLoginServiceScript = preload("res://daily_login_service.gd")
const DailyLoginFrameLayoutServiceScript = preload("res://daily_login_frame_layout_service.gd")
const ShopCatalogServiceScript = preload("res://shop_catalog_service.gd")
const GameBoosterServiceScript = preload("res://game_booster_service.gd")
const DiamondIconTexture = preload("res://Imagenes/icono-diamante.png")
const LifeIconTexture = preload("res://Imagenes/icono-vidas.png")
const MixIconTexture = preload("res://Imagenes/icono-mezclar.png")
const HammerIconTexture = preload("res://Imagenes/icono-martillo.png")
const GloveIconTexture = preload("res://Imagenes/icono-mano.png")
const FrameTexture = preload("res://Imagenes/cartel-login.png")
const LogoFont = preload("res://Fonts/Lobster-Regular.ttf")
const TITLE_FILL := Color(0.42, 0.20, 0.60, 1.0)
const TITLE_OUTLINE := Color(1.00, 0.96, 0.92, 0.85)
const CELL_INK := Color(0.36, 0.18, 0.54, 1.0)
const PILL_ON := Color(0.78, 0.52, 0.98, 1.0)
const PILL_ON_BORDER := Color(0.48, 0.22, 0.78, 1.0)
const PILL_OFF := Color(0.74, 0.58, 0.90, 1.0)
const PILL_OFF_BORDER := Color(0.58, 0.40, 0.78, 1.0)
const PILL_TEXT := Color(1.00, 0.98, 0.96, 1.0)
const PILL_OFF_TEXT := Color(0.42, 0.24, 0.58, 1.0)

var overlay: ColorRect = null
var card: Panel = null
var frame_art: TextureRect = null
var title_label: Label = null
var close_btn: Button = null
var footer_btn: Button = null
var footer_label: Label = null
var _slots: Array[Dictionary] = []
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
	var tex_size := Vector2(1230, 1179)
	if FrameTexture != null:
		tex_size = FrameTexture.get_size()
	var card_size: Vector2 = DailyLoginFrameLayoutServiceScript.card_size(viewport_size, tex_size)
	card.size = card_size
	card.position = Vector2(
		(viewport_size.x - card_size.x) * 0.5,
		(viewport_size.y - card_size.y) * 0.5
	)
	if frame_art != null:
		frame_art.position = Vector2.ZERO
		frame_art.size = card_size
	if title_label != null:
		var title_rect: Rect2 = DailyLoginFrameLayoutServiceScript.mapped_rect(
			card_size,
			DailyLoginFrameLayoutServiceScript.TITLE_FRAC
		)
		title_label.position = title_rect.position
		title_label.size = title_rect.size
		var title_font: int = DailyLoginFrameLayoutServiceScript.title_font_size(title_rect.size.y)
		title_label.add_theme_font_size_override("font_size", title_font)
		title_label.add_theme_constant_override("outline_size", maxi(int(round(float(title_font) * 0.08)), 4))
	if close_btn != null:
		var close_rect: Rect2 = DailyLoginFrameLayoutServiceScript.mapped_rect(
			card_size,
			DailyLoginFrameLayoutServiceScript.CLOSE_FRAC
		)
		close_btn.position = close_rect.position
		close_btn.size = close_rect.size
	if footer_btn != null:
		var footer_rect: Rect2 = DailyLoginFrameLayoutServiceScript.mapped_rect(
			card_size,
			DailyLoginFrameLayoutServiceScript.FOOTER_FRAC
		)
		footer_btn.custom_minimum_size = Vector2.ZERO
		footer_btn.position = footer_rect.position
		footer_btn.size = footer_rect.size
	if footer_label != null:
		var text_rect: Rect2 = DailyLoginFrameLayoutServiceScript.mapped_rect(
			card_size,
			DailyLoginFrameLayoutServiceScript.FOOTER_TEXT_FRAC
		)
		footer_label.position = text_rect.position
		footer_label.size = text_rect.size
		var font_h: float = DailyLoginFrameLayoutServiceScript.mapped_rect(
			card_size,
			DailyLoginFrameLayoutServiceScript.FOOTER_FRAC
		).size.y
		var footer_font: int = DailyLoginFrameLayoutServiceScript.footer_font_size(font_h)
		footer_label.add_theme_font_size_override("font_size", footer_font)
		footer_label.add_theme_constant_override("outline_size", maxi(int(round(float(footer_font) * 0.10)), 4))
	for i in range(_slots.size()):
		var slot_ui: Dictionary = _slots[i]
		var root: Control = slot_ui.get("root") as Control
		var cell_rect: Rect2 = DailyLoginFrameLayoutServiceScript.cell_rect(card_size, i)
		if root != null:
			root.position = cell_rect.position
			root.size = cell_rect.size
		var cell_h: float = cell_rect.size.y
		var pad: int = int(clampf(cell_h * 0.06, 6.0, 16.0))
		var bottom_pad: int = DailyLoginFrameLayoutServiceScript.cell_bottom_pad(cell_h)
		var margin: MarginContainer = slot_ui.get("margin") as MarginContainer
		if margin != null:
			margin.add_theme_constant_override("margin_left", pad)
			margin.add_theme_constant_override("margin_top", pad)
			margin.add_theme_constant_override("margin_right", pad)
			margin.add_theme_constant_override("margin_bottom", bottom_pad)
		var vbox: VBoxContainer = slot_ui.get("vbox") as VBoxContainer
		if vbox != null:
			vbox.alignment = BoxContainer.ALIGNMENT_END
			vbox.add_theme_constant_override("separation", DailyLoginFrameLayoutServiceScript.cell_reward_gap(cell_h))
		var reward_row: HBoxContainer = slot_ui.get("reward_row") as HBoxContainer
		if reward_row != null:
			reward_row.add_theme_constant_override("separation", int(clampf(cell_h * 0.06, 8.0, 16.0)))
		var icon: TextureRect = slot_ui.get("icon") as TextureRect
		var qty: Label = slot_ui.get("qty") as Label
		var lock: Label = slot_ui.get("lock") as Label
		var btn: Button = slot_ui.get("button") as Button
		var icon_side: float = DailyLoginFrameLayoutServiceScript.cell_icon_side(cell_h)
		if icon != null:
			icon.custom_minimum_size = Vector2(icon_side, icon_side)
		var qty_font: int = DailyLoginFrameLayoutServiceScript.cell_qty_font_size(cell_h)
		if qty != null:
			qty.add_theme_font_size_override("font_size", qty_font)
			qty.add_theme_constant_override("outline_size", maxi(int(round(float(qty_font) * 0.10)), 3))
		if lock != null:
			lock.add_theme_font_size_override("font_size", maxi(int(round(float(qty_font) * 0.85)), 22))
		if btn != null:
			var btn_h: float = DailyLoginFrameLayoutServiceScript.cell_btn_height(cell_h)
			btn.custom_minimum_size = Vector2(0, btn_h)
			btn.add_theme_font_size_override("font_size", DailyLoginFrameLayoutServiceScript.cell_btn_font_size(btn_h))
	_apply_theme_colors()

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

	title_label = _make_outlined_label("Login diario", 46)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(title_label)

	close_btn = Button.new()
	close_btn.text = ""
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.flat = true
	var empty := StyleBoxEmpty.new()
	close_btn.add_theme_stylebox_override("normal", empty)
	close_btn.add_theme_stylebox_override("hover", empty)
	close_btn.add_theme_stylebox_override("pressed", empty)
	close_btn.add_theme_stylebox_override("focus", empty)
	close_btn.pressed.connect(close)
	GameState.hook_button_sound(close_btn)
	card.add_child(close_btn)

	footer_btn = _make_action_button("")
	footer_btn.flat = true
	var footer_empty := StyleBoxEmpty.new()
	footer_btn.add_theme_stylebox_override("normal", footer_empty)
	footer_btn.add_theme_stylebox_override("hover", footer_empty)
	footer_btn.add_theme_stylebox_override("pressed", footer_empty)
	footer_btn.add_theme_stylebox_override("focus", footer_empty)
	footer_btn.pressed.connect(close)
	card.add_child(footer_btn)

	footer_label = _make_outlined_label("Cerrar", 64)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer_label.clip_text = false
	footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_label.add_theme_color_override("font_color", PILL_TEXT)
	footer_label.add_theme_color_override("font_outline_color", Color(0.32, 0.12, 0.52, 0.85))
	card.add_child(footer_label)

	_slots.clear()
	for i in range(DailyLoginServiceScript.SLOT_COUNT):
		var cell: Dictionary = _make_slot_cell(i)
		card.add_child(cell.get("root") as Control)
		_slots.append(cell)

func _make_slot_cell(index: int) -> Dictionary:
	var root := Panel.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var reward_row := HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reward_row.add_theme_constant_override("separation", 10)
	vbox.add_child(reward_row)

	var icon := TextureRect.new()
	icon.texture = DiamondIconTexture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(72, 72)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reward_row.add_child(icon)

	var qty := _make_outlined_label("", 32)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qty.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	qty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reward_row.add_child(qty)

	var lock := _make_outlined_label("🔒", 28)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lock.visible = false
	reward_row.add_child(lock)

	var btn := _make_action_button("Gratis")
	btn.pressed.connect(_on_slot_pressed.bind(index))
	vbox.add_child(btn)

	return {
		"root": root,
		"margin": margin,
		"vbox": vbox,
		"reward_row": reward_row,
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
	if kind == "unlimited_lives" and GameState != null and GameState.lives_enabled():
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
	btn.add_theme_color_override("font_hover_color", font_color)
	btn.add_theme_color_override("font_pressed_color", font_color)
	btn.add_theme_color_override("font_disabled_color", font_color)
	btn.add_theme_color_override("font_outline_color", Color(0.28, 0.10, 0.48, 0.85))
	btn.add_theme_constant_override("outline_size", 4)
	var style := _flat_style(bg, border, radius, 3)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_stylebox_override("disabled", style)

func _apply_theme_colors() -> void:
	if card != null:
		card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if title_label != null:
		title_label.add_theme_color_override("font_color", TITLE_FILL)
		title_label.add_theme_color_override("font_outline_color", TITLE_OUTLINE)
	if footer_label != null:
		footer_label.add_theme_color_override("font_color", PILL_TEXT)
		footer_label.add_theme_color_override("font_outline_color", Color(0.32, 0.12, 0.52, 0.85))
	var progress: Dictionary = _load_progress()
	var claimed: int = int(progress.get("claimed", 0))
	for i in range(_slots.size()):
		var ui: Dictionary = _slots[i]
		var root: Panel = ui.get("root") as Panel
		var qty: Label = ui.get("qty") as Label
		var btn: Button = ui.get("button") as Button
		if root != null:
			root.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		if qty != null:
			qty.add_theme_color_override("font_color", CELL_INK)
			qty.add_theme_color_override("font_outline_color", Color(1.0, 0.97, 0.94, 0.75))
		var status: String = DailyLoginServiceScript.slot_status(i, claimed)
		var radius := 22
		if btn != null:
			radius = int(clampf(btn.size.y * 0.50, 18.0, 36.0))
		if status == "available":
			_apply_button_style(btn, PILL_ON, PILL_ON_BORDER, radius, PILL_TEXT)
		else:
			_apply_button_style(btn, PILL_OFF, PILL_OFF_BORDER, radius, PILL_OFF_TEXT)

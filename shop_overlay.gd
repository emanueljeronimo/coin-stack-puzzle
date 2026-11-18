class_name ShopOverlay
extends Control

signal diamonds_purchased(amount: int)
signal combo_purchased(pack: Dictionary)
signal booster_purchased(booster_type: String, amount: int)

const ShopTabServiceScript = preload("res://shop_tab_service.gd")
const ShopCatalogServiceScript = preload("res://shop_catalog_service.gd")
const GameBoosterServiceScript = preload("res://game_booster_service.gd")
const DiamondIconTexture = preload("res://Imagenes/icono-diamante.png")
const LifeIconTexture = preload("res://Imagenes/icono-vidas.png")
const MixIconTexture = preload("res://Imagenes/icono-mezclar.png")
const HammerIconTexture = preload("res://Imagenes/icono-martillo.png")
const GloveIconTexture = preload("res://Imagenes/icono-mano.png")
const CartIconTexture = preload("res://Imagenes/icono-cart.png")
const REF_WIDTH := 1080.0
const LogoFont = preload("res://Fonts/Lobster-Regular.ttf")
const RainbowLabelShader = preload("res://rainbow_label.gdshader")
const CLOSE_RED := Color(0.90, 0.22, 0.24, 1.0)
const CLOSE_RED_BORDER := Color(0.55, 0.10, 0.12, 1.0)
const FAVORITE_GOLD := Color(0.98, 0.82, 0.28, 1.0)
const SHOP_BRONZE := Color(0.80, 0.52, 0.26, 1.0)
const SHOP_CARD_BG := Color(1.00, 1.00, 1.00, 0.24)
const SHOP_INK := Color(0.28, 0.26, 0.27, 1.0)
const SHOP_CARD_BORDER := SHOP_INK
const SHOP_WELL := Color(0.00, 0.00, 0.00, 0.00)
const SHOP_CONFIRM_BG := Color(1.00, 1.00, 1.00, 0.74)
const SHOP_TITLE := Color(1.00, 1.00, 1.00, 1.0)
const SHOP_TEXT := Color(1.00, 1.00, 1.00, 1.0)
const SHOP_OUTLINE := Color(0.12, 0.10, 0.16, 0.78)
const SHOP_PRICE_BG := Color("#1F574A")
const SHOP_PRICE_BORDER := Color("#163E35")
const SHOP_CANCEL_BG := Color(0.68, 0.42, 0.20, 0.96)

var overlay: ColorRect = null
var card: Panel = null
var card_margin: MarginContainer = null
var main_vbox: VBoxContainer = null
var header: Control = null
var title_label: Label = null
var close_btn: Button = null
var tabs_row: HBoxContainer = null
var content_well: Panel = null
var content_margin: MarginContainer = null
var _tab_btns: Array[Button] = []
var _pages: Array[Control] = []
var _placeholder_labels: Array[Label] = []
var _diamond_list: GridContainer = null
var _diamond_offer_rows: Array[Dictionary] = []
var _resource_list: HBoxContainer = null
var _resource_rows: Array[Dictionary] = []
var _combo_list: VBoxContainer = null
var _combo_cards: Array[Dictionary] = []
var _active_tab: int = 0
var _close_menu_btn: Button = null
var _opened_at_msec: int = 0
var _confirm_root: Control = null
var _confirm_card: Panel = null
var _confirm_icons_row: HBoxContainer = null
var _confirm_icon_nodes: Array[TextureRect] = []
var _confirm_title: Label = null
var _confirm_accept_btn: Button = null
var _confirm_cancel_btn: Button = null
var _pending_pack_id: String = ""

func _ready() -> void:
	_cover_viewport()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()
	if not GameState.background_theme_changed.is_connected(_on_background_theme_changed):
		GameState.background_theme_changed.connect(_on_background_theme_changed)
	_apply_shop_identity()

func open() -> void:
	_apply_shop_identity()
	_sync_combo_visibility()
	_set_active_tab(_active_tab)
	layout_for_viewport(get_viewport_rect().size)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_opened_at_msec = Time.get_ticks_msec()

func close() -> void:
	_hide_buy_confirm()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_open() -> bool:
	return visible

func _on_background_theme_changed(_theme_id: String) -> void:
	_apply_shop_identity()

func _cover_viewport(viewport_size: Vector2 = Vector2.ZERO) -> void:
	var vp: Vector2 = viewport_size
	if vp == Vector2.ZERO:
		var tree := get_viewport()
		if tree != null:
			vp = tree.get_visible_rect().size
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	if vp != Vector2.ZERO:
		size = vp
		position = Vector2.ZERO
	if overlay != null:
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if vp != Vector2.ZERO:
			overlay.size = vp

func layout_for_viewport(viewport_size: Vector2) -> void:
	_cover_viewport(viewport_size)
	if card == null:
		return
	var scale := viewport_size.x / REF_WIDTH
	var card_w := viewport_size.x * 0.90
	var outer_pad := int(16.0 * scale)
	var top_pad := int(24.0 * scale)
	var bottom_pad := int(16.0 * scale)
	var sep := int(12.0 * scale)

	if card_margin != null:
		card_margin.add_theme_constant_override("margin_left", outer_pad)
		card_margin.add_theme_constant_override("margin_top", top_pad)
		card_margin.add_theme_constant_override("margin_right", outer_pad)
		card_margin.add_theme_constant_override("margin_bottom", bottom_pad)
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", sep)

	var header_h := 88.0 * scale
	if header != null:
		header.custom_minimum_size = Vector2(0, header_h)
	if title_label != null:
		title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		title_label.offset_left = 0
		title_label.offset_top = 0
		title_label.offset_right = 0
		title_label.offset_bottom = 0
		title_label.add_theme_font_size_override("font_size", int(72 * scale))
		title_label.add_theme_constant_override("outline_size", int(8 * scale))
		_clear_rainbow_label(title_label)
	if close_btn != null:
		var close_side := 46.0 * scale
		var close_pad := 14.0 * scale
		close_btn.custom_minimum_size = Vector2(close_side, close_side)
		close_btn.add_theme_font_size_override("font_size", int(30 * scale))
		close_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		close_btn.offset_left = -close_side - close_pad
		close_btn.offset_top = -close_side * 0.5
		close_btn.offset_right = -close_pad
		close_btn.offset_bottom = close_side * 0.5

	var tabs_h := 0.0
	if tabs_row != null:
		tabs_row.visible = false
		tabs_row.custom_minimum_size = Vector2(0, 0)

	var well_pad := int(10.0 * scale)
	if content_margin != null:
		content_margin.add_theme_constant_override("margin_left", 0)
		content_margin.add_theme_constant_override("margin_top", well_pad)
		content_margin.add_theme_constant_override("margin_right", 0)
		content_margin.add_theme_constant_override("margin_bottom", well_pad)
	for lbl in _placeholder_labels:
		if lbl == null:
			continue
		lbl.add_theme_font_size_override("font_size", int(44 * scale))
		lbl.add_theme_constant_override("outline_size", int(6 * scale))

	var footer_h := 80.0 * scale
	if _close_menu_btn != null:
		_close_menu_btn.custom_minimum_size = Vector2(0, footer_h)
		_close_menu_btn.add_theme_font_size_override("font_size", int(50 * scale))

	var card_h := viewport_size.y * 0.75
	var content_h := (
		card_h
		- header_h
		- tabs_h
		- footer_h
		- float(sep) * 3.0
		- float(top_pad + bottom_pad)
	)
	content_h = maxf(content_h, 240.0 * scale)
	if content_well != null:
		content_well.custom_minimum_size = Vector2(0, content_h)
	card.size = Vector2(card_w, card_h)
	card.position = Vector2((viewport_size.x - card_w) * 0.5, (viewport_size.y - card_h) * 0.5)
	_layout_diamond_offers(scale)
	_layout_resource_offers(scale)
	_layout_combo_offers(scale)
	if _confirm_root != null and _confirm_root.visible:
		_layout_buy_confirm()

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

	header = Panel.new()
	header.clip_contents = true
	header.custom_minimum_size = Vector2(0, 58)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)

	title_label = _make_outlined_label("Tienda", 58)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	close_btn.clip_text = true
	close_btn.clip_contents = true
	var close_font := FontVariation.new()
	close_font.variation_embolden = 0.7
	close_btn.add_theme_font_override("font", close_font)
	close_btn.pressed.connect(close)
	GameState.hook_button_sound(close_btn)
	header.add_child(close_btn)

	tabs_row = HBoxContainer.new()
	tabs_row.visible = false
	tabs_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(tabs_row)
	_tab_btns.clear()

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

	_pages.clear()
	_placeholder_labels.clear()
	_diamond_offer_rows.clear()
	_resource_rows.clear()
	_combo_cards.clear()
	_pages.append(_build_store_page())
	for page in _pages:
		content_margin.add_child(page)

	_close_menu_btn = _make_action_button("Cerrar")
	_close_menu_btn.pressed.connect(close)
	main_vbox.add_child(_close_menu_btn)

	_build_buy_confirm()
	_cover_viewport()
	_apply_shop_identity()
	_set_active_tab(ShopTabServiceScript.TAB_STORE)

func _build_placeholder_page(copy: String) -> Control:
	var page := _make_outlined_label(copy, 44)
	page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_placeholder_labels.append(page)
	return page

func _build_store_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	var combos := VBoxContainer.new()
	combos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combos.add_theme_constant_override("separation", 12)
	list.add_child(combos)
	_combo_list = combos
	for pack in ShopCatalogServiceScript.combo_packs():
		if not (pack is Dictionary):
			continue
		var card_row: Dictionary = _make_combo_card(pack as Dictionary)
		combos.add_child(card_row.get("root") as Control)
		_combo_cards.append(card_row)

	var diamonds := GridContainer.new()
	diamonds.columns = 3
	diamonds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diamonds.add_theme_constant_override("h_separation", 10)
	diamonds.add_theme_constant_override("v_separation", 10)
	list.add_child(diamonds)
	_diamond_list = diamonds
	for pack in ShopCatalogServiceScript.diamond_packs():
		if not (pack is Dictionary):
			continue
		var row: Dictionary = _make_diamond_offer_row(pack as Dictionary)
		diamonds.add_child(row.get("root") as Control)
		_diamond_offer_rows.append(row)
	return scroll

func _build_resources_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP

	var list := HBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_resource_list = list

	var types: PackedStringArray = ShopCatalogServiceScript.resource_column_types()
	for booster_type in types:
		var packs: Array = ShopCatalogServiceScript.resource_packs_for_type(booster_type)
		if packs.is_empty():
			continue
		var column: Dictionary = _make_resource_column(booster_type, packs)
		list.add_child(column.get("root") as Control)
		_resource_rows.append(column)
	return scroll

func _make_resource_column(booster_type: String, packs: Array) -> Dictionary:
	var title_text: String = str((packs[0] as Dictionary).get("title", ""))
	var root := Panel.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_meta("booster_type", booster_type)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var icon := TextureRect.new()
	icon.texture = _texture_for_confirm_key(booster_type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(96, 96)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var title := _make_outlined_label(title_text, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title)

	var lock := _make_outlined_label("Nivel %d" % ShopCatalogServiceScript.unlock_level_for_type(booster_type), 26)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock.visible = false
	vbox.add_child(lock)

	var offers_box := VBoxContainer.new()
	offers_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offers_box.add_theme_constant_override("separation", 18)
	vbox.add_child(offers_box)

	var offers: Array = []
	for pack_n in packs:
		if not (pack_n is Dictionary):
			continue
		var offer: Dictionary = _make_resource_offer_button(pack_n as Dictionary)
		offers_box.add_child(offer.get("buy") as Control)
		offers.append(offer)

	return {
		"root": root,
		"icon": icon,
		"title": title,
		"lock": lock,
		"vbox": vbox,
		"offers_box": offers_box,
		"booster_type": booster_type,
		"offers": offers,
	}

func _make_resource_offer_button(pack: Dictionary) -> Dictionary:
	var pack_id: String = str(pack.get("id", ""))
	var amount: int = int(pack.get("amount", 1))
	var diamond_cost: int = int(pack.get("diamond_cost", 0))

	var buy := Button.new()
	buy.focus_mode = Control.FOCUS_NONE
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy.custom_minimum_size = Vector2(0, 64)
	buy.set_meta("pack_id", pack_id)
	buy.pressed.connect(_on_buy_diamond_pack.bind(pack_id))
	GameState.hook_button_sound(buy)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy.add_child(center)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(row)

	var qty := _make_outlined_label(str(amount), 38)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(qty)

	var cost_icon := TextureRect.new()
	cost_icon.texture = DiamondIconTexture
	cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_icon.custom_minimum_size = Vector2(32, 32)
	row.add_child(cost_icon)

	var cost := _make_outlined_label(ShopCatalogServiceScript.format_amount(diamond_cost), 38)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(cost)

	return {
		"buy": buy,
		"qty": qty,
		"cost_icon": cost_icon,
		"cost": cost,
		"pack_id": pack_id,
	}

func _make_combo_card(pack: Dictionary) -> Dictionary:
	var pack_id: String = str(pack.get("id", ""))
	var booster_each: int = int(pack.get("booster_each", 0))
	var root := Panel.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_meta("pack_id", pack_id)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(margin)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)

	var left := Control.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.custom_minimum_size = Vector2(220, 140)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	body.add_child(left)

	var hero := TextureRect.new()
	hero.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(hero)

	var title := _make_outlined_label(str(pack.get("title", "")), 34)
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.offset_left = 8
	title.offset_right = -8
	title.offset_bottom = -4
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(title)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 2)
	body.add_child(center)

	var icon := TextureRect.new()
	icon.texture = _texture_for_art_path(ShopCatalogServiceScript.art_path_for_amount(int(pack.get("diamonds", 0))))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(100, 100)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(icon)

	var amount_lbl := _make_outlined_label(
		ShopCatalogServiceScript.format_amount(int(pack.get("diamonds", 0))),
		36
	)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(amount_lbl)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 10)
	chips.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.add_child(chips)

	var booster_chips: Array[Dictionary] = []
	var chip_keys := PackedStringArray(["mix", "hammer", "glove"])
	for key in chip_keys:
		var chip: Dictionary = _make_booster_chip(key, booster_each)
		chips.add_child(chip.get("root") as Control)
		booster_chips.append(chip)

	var buy := _make_action_button(ShopCatalogServiceScript.format_price_usd(int(pack.get("price_cents", 0))))
	buy.custom_minimum_size = Vector2(168, 48)
	buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy.pressed.connect(_on_buy_diamond_pack.bind(pack_id))
	right.add_child(buy)

	return {
		"root": root,
		"title": title,
		"buy": buy,
		"amount": amount_lbl,
		"icon": icon,
		"hero": hero,
		"left": left,
		"chips": booster_chips,
		"line_icons": [],
		"line_labels": [],
	}

func _make_booster_chip(booster_type: String, amount: int) -> Dictionary:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = Vector2(96, 128)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	root.add_child(vbox)

	var icon := TextureRect.new()
	icon.texture = _texture_for_confirm_key(booster_type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(88, 88)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var qty := _make_outlined_label("x%d" % amount, 30)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(qty)

	return {
		"root": root,
		"icon": icon,
		"qty": qty,
	}

func _make_diamond_offer_row(pack: Dictionary) -> Dictionary:
	var pack_id: String = str(pack.get("id", ""))
	var amount: int = int(pack.get("amount", 0))
	var price_text: String = ShopCatalogServiceScript.format_price_usd(int(pack.get("price_cents", 0)))

	var root := Panel.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_meta("pack_id", pack_id)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var amount_lbl := _make_outlined_label(ShopCatalogServiceScript.format_amount(amount), 34)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(amount_lbl)

	var icon := TextureRect.new()
	icon.texture = _texture_for_diamond_pack(pack)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(72, 72)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)

	var buy := _make_action_button(price_text)
	buy.custom_minimum_size = Vector2(0, 48)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.pressed.connect(_on_buy_diamond_pack.bind(pack_id))
	col.add_child(buy)

	return {
		"root": root,
		"icon": icon,
		"amount": amount_lbl,
		"badge": null,
		"buy": buy,
		"favorite": false,
	}

func _layout_diamond_offers(ui_scale: float) -> void:
	var s: float = maxf(ui_scale, 0.5)
	if _diamond_list != null and content_well != null:
		var inner_w: float = maxf(content_well.size.x, 200.0 * s)
		_diamond_list.custom_minimum_size.x = inner_w
		_diamond_list.columns = 3
		_diamond_list.add_theme_constant_override("h_separation", int(10.0 * s))
		_diamond_list.add_theme_constant_override("v_separation", int(10.0 * s))
	for row in _diamond_offer_rows:
		var root: Panel = row.get("root") as Panel
		var icon: TextureRect = row.get("icon") as TextureRect
		var amount_lbl: Label = row.get("amount") as Label
		var buy: Button = row.get("buy") as Button
		if root != null:
			root.custom_minimum_size = Vector2(0, 340.0 * s)
		if icon != null:
			icon.custom_minimum_size = Vector2(136.0 * s, 136.0 * s)
		if amount_lbl != null:
			amount_lbl.add_theme_font_size_override("font_size", int(38.0 * s))
			amount_lbl.add_theme_constant_override("outline_size", int(5.0 * s))
		if buy != null:
			buy.custom_minimum_size = Vector2(0, 76.0 * s)
			buy.add_theme_font_size_override("font_size", int(42.0 * s))
			buy.add_theme_constant_override("outline_size", 6)

func _layout_resource_offers(ui_scale: float) -> void:
	var s: float = maxf(ui_scale, 0.5)
	if _resource_list != null and content_well != null:
		var inner_w: float = maxf(content_well.size.x - 28.0 * s, 200.0 * s)
		var inner_h: float = maxf(content_well.size.y - 28.0 * s, 360.0 * s)
		_resource_list.custom_minimum_size = Vector2(inner_w, inner_h)
		_resource_list.add_theme_constant_override("separation", int(10.0 * s))
	for column in _resource_rows:
		var root: Panel = column.get("root") as Panel
		var icon: TextureRect = column.get("icon") as TextureRect
		var title: Label = column.get("title") as Label
		var lock: Label = column.get("lock") as Label
		var vbox: VBoxContainer = column.get("vbox") as VBoxContainer
		var offers_box: VBoxContainer = column.get("offers_box") as VBoxContainer
		if root != null:
			root.custom_minimum_size = Vector2(0, 420.0 * s)
		if vbox != null:
			vbox.add_theme_constant_override("separation", int(14.0 * s))
		if offers_box != null:
			offers_box.add_theme_constant_override("separation", int(22.0 * s))
		if icon != null:
			icon.custom_minimum_size = Vector2(96.0 * s, 96.0 * s)
		if title != null:
			title.add_theme_font_size_override("font_size", int(50.0 * s))
			title.add_theme_constant_override("outline_size", int(7.0 * s))
		if lock != null:
			lock.add_theme_font_size_override("font_size", int(26.0 * s))
			lock.add_theme_constant_override("outline_size", int(5.0 * s))
		var offers: Array = column.get("offers", []) as Array
		for offer_n in offers:
			if not (offer_n is Dictionary):
				continue
			var offer: Dictionary = offer_n as Dictionary
			var buy: Button = offer.get("buy") as Button
			var qty: Label = offer.get("qty") as Label
			var cost: Label = offer.get("cost") as Label
			var cost_icon: TextureRect = offer.get("cost_icon") as TextureRect
			if buy != null:
				buy.custom_minimum_size = Vector2(0, 80.0 * s)
			if qty != null:
				qty.add_theme_font_size_override("font_size", int(38.0 * s))
				qty.add_theme_constant_override("outline_size", int(6.0 * s))
			if cost != null:
				cost.add_theme_font_size_override("font_size", int(38.0 * s))
				cost.add_theme_constant_override("outline_size", int(6.0 * s))
			if cost_icon != null:
				cost_icon.custom_minimum_size = Vector2(30.0 * s, 30.0 * s)

func _layout_combo_offers(ui_scale: float) -> void:
	var s: float = maxf(ui_scale, 0.5)
	if _combo_list != null and content_well != null:
		var inner_w: float = maxf(content_well.size.x, 200.0 * s)
		_combo_list.custom_minimum_size.x = inner_w
		_combo_list.add_theme_constant_override("separation", int(12.0 * s))
	for card_row in _combo_cards:
		var root: Panel = card_row.get("root") as Panel
		var title: Label = card_row.get("title") as Label
		var buy: Button = card_row.get("buy") as Button
		var amount_lbl: Label = card_row.get("amount") as Label
		var icon: TextureRect = card_row.get("icon") as TextureRect
		var left: Control = card_row.get("left") as Control
		if root != null:
			root.custom_minimum_size = Vector2(0, 292.0 * s)
		if left != null:
			left.custom_minimum_size = Vector2(286.0 * s, 196.0 * s)
		if title != null:
			title.add_theme_font_size_override("font_size", int(42.0 * s))
			title.add_theme_constant_override("outline_size", int(5.0 * s))
		if amount_lbl != null:
			amount_lbl.add_theme_font_size_override("font_size", int(40.0 * s))
			amount_lbl.add_theme_constant_override("outline_size", int(5.0 * s))
		if icon != null:
			icon.custom_minimum_size = Vector2(128.0 * s, 128.0 * s)
		var chips: Array = card_row.get("chips", []) as Array
		for chip_n in chips:
			if not (chip_n is Dictionary):
				continue
			var chip: Dictionary = chip_n as Dictionary
			var chip_root: Control = chip.get("root") as Control
			var chip_icon: TextureRect = chip.get("icon") as TextureRect
			var chip_qty: Label = chip.get("qty") as Label
			if chip_root != null:
				chip_root.custom_minimum_size = Vector2(94.0 * s, 130.0 * s)
			if chip_icon != null:
				chip_icon.custom_minimum_size = Vector2(88.0 * s, 88.0 * s)
			if chip_qty != null:
				chip_qty.add_theme_font_size_override("font_size", int(28.0 * s))
				chip_qty.add_theme_constant_override("outline_size", int(4.0 * s))
		if buy != null:
			buy.custom_minimum_size = Vector2(236.0 * s, 78.0 * s)
			buy.add_theme_font_size_override("font_size", int(36.0 * s))
			buy.add_theme_constant_override("outline_size", 5)

func _style_diamond_offer_rows() -> void:
	for row in _diamond_offer_rows:
		var root: Panel = row.get("root") as Panel
		var amount_lbl: Label = row.get("amount") as Label
		var buy: Button = row.get("buy") as Button
		var pack: Dictionary = {}
		if root != null:
			pack = ShopCatalogServiceScript.pack_by_id(str(root.get_meta("pack_id", "")))
		var ident: Dictionary = ShopCatalogServiceScript.offer_identity(pack)
		if root != null:
			root.add_theme_stylebox_override(
				"panel",
				_flat_style(ident.get("fill", SHOP_WELL), SHOP_CARD_BORDER, 24, 2)
			)
		if amount_lbl != null:
			amount_lbl.add_theme_color_override("font_color", SHOP_TEXT)
		_apply_button_style(buy, SHOP_PRICE_BG, SHOP_PRICE_BORDER, 20, SHOP_TEXT)

func _style_resource_rows(
	btn_on: Color,
	btn_border: Color,
	well: Color,
	card_border: Color,
	text_marble: Color
) -> void:
	for column in _resource_rows:
		var root: Panel = column.get("root") as Panel
		var title: Label = column.get("title") as Label
		var lock: Label = column.get("lock") as Label
		if root != null:
			root.add_theme_stylebox_override(
				"panel",
				_flat_style(well.lightened(0.04), card_border.darkened(0.1), 18, 2)
			)
		if title != null:
			title.add_theme_color_override("font_color", text_marble)
		if lock != null:
			lock.add_theme_color_override("font_color", text_marble)
		var offers: Array = column.get("offers", []) as Array
		for offer_n in offers:
			if not (offer_n is Dictionary):
				continue
			var offer: Dictionary = offer_n as Dictionary
			var buy: Button = offer.get("buy") as Button
			var qty: Label = offer.get("qty") as Label
			var cost: Label = offer.get("cost") as Label
			_apply_button_style(buy, btn_on, btn_border, 16, text_marble)
			if qty != null:
				qty.add_theme_color_override("font_color", text_marble)
			if cost != null:
				cost.add_theme_color_override("font_color", text_marble)
	_sync_resource_locks()

func _style_combo_cards() -> void:
	for card_row in _combo_cards:
		var root: Panel = card_row.get("root") as Panel
		var title: Label = card_row.get("title") as Label
		var buy: Button = card_row.get("buy") as Button
		var amount_lbl: Label = card_row.get("amount") as Label
		var pack: Dictionary = {}
		if root != null:
			pack = ShopCatalogServiceScript.pack_by_id(str(root.get_meta("pack_id", "")))
		var ident: Dictionary = ShopCatalogServiceScript.offer_identity(pack)
		if root != null:
			root.add_theme_stylebox_override(
				"panel",
				_flat_style(ident.get("fill", SHOP_WELL), SHOP_CARD_BORDER, 26, 2)
			)
		if title != null:
			title.add_theme_color_override("font_color", SHOP_TEXT)
		if amount_lbl != null:
			amount_lbl.add_theme_color_override("font_color", SHOP_TEXT)
		var chips: Array = card_row.get("chips", []) as Array
		for chip_n in chips:
			if not (chip_n is Dictionary):
				continue
			var chip_qty: Label = (chip_n as Dictionary).get("qty") as Label
			if chip_qty != null:
				chip_qty.add_theme_color_override("font_color", SHOP_TEXT)
		_apply_button_style(buy, SHOP_PRICE_BG, SHOP_PRICE_BORDER, 20, SHOP_TEXT)

func _on_buy_diamond_pack(pack_id: String) -> void:
	var pack: Dictionary = ShopCatalogServiceScript.pack_by_id(pack_id)
	if ShopCatalogServiceScript.is_resource_booster(pack):
		if not ShopCatalogServiceScript.can_buy_resource(pack, _player_shop_level()):
			return
	if ShopCatalogServiceScript.is_combo_pack(pack):
		if not ShopCatalogServiceScript.can_buy_combo(pack, _player_shop_level()):
			return
	_show_buy_confirm(pack_id)

func _player_shop_level() -> int:
	if GameState == null:
		return 1
	return maxi(1, GameState.player_level)

func _sync_combo_visibility() -> void:
	var level: int = _player_shop_level()
	for card_row in _combo_cards:
		var root: Panel = card_row.get("root") as Panel
		if root == null:
			continue
		var pack: Dictionary = ShopCatalogServiceScript.pack_by_id(str(root.get_meta("pack_id", "")))
		root.visible = ShopCatalogServiceScript.can_buy_combo(pack, level)

func _sync_resource_locks() -> void:
	var level: int = _player_shop_level()
	var p: Dictionary = GameState.get_ui_palette() if GameState != null else {}
	var off_bg: Color = p.get("settings_btn_off", Color(0.34, 0.26, 0.48, 0.95))
	var off_border: Color = p.get("settings_card_border", Color(0.42, 0.28, 0.58, 0.95))
	var on_bg: Color = p.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98))
	var on_border: Color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))
	var text_marble := Color(0.88, 0.86, 0.83)
	for column in _resource_rows:
		var booster_type: String = str(column.get("booster_type", ""))
		var unlocked: bool = ShopCatalogServiceScript.can_buy_resource(
			{"kind": "resource_booster", "booster_type": booster_type},
			level
		)
		var root: Panel = column.get("root") as Panel
		var lock: Label = column.get("lock") as Label
		if root != null:
			root.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.72, 0.72, 0.72, 0.88)
		if lock != null:
			lock.visible = not unlocked
			lock.text = "Nivel %d" % ShopCatalogServiceScript.unlock_level_for_type(booster_type)
		var offers: Array = column.get("offers", []) as Array
		for offer_n in offers:
			if not (offer_n is Dictionary):
				continue
			var buy: Button = (offer_n as Dictionary).get("buy") as Button
			if buy == null:
				continue
			buy.disabled = not unlocked
			if unlocked:
				_apply_button_style(buy, on_bg, on_border, 16, text_marble)
			else:
				_apply_button_style(buy, off_bg, off_border.darkened(0.2), 16, text_marble)

func _grant_diamond_pack(pack_id: String) -> void:
	var pack: Dictionary = ShopCatalogServiceScript.pack_by_id(pack_id)
	if pack.is_empty():
		return
	if ShopCatalogServiceScript.is_combo_pack(pack):
		_grant_combo_pack(pack)
		return
	if ShopCatalogServiceScript.is_resource_booster(pack):
		_grant_resource_pack(pack)
		return
	var amount: int = int(pack.get("amount", 0))
	var result: Dictionary = ShopCatalogServiceScript.grant_diamonds(GameState.player_diamonds, amount)
	if not bool(result.get("ok", false)):
		return
	_apply_diamond_grant(amount, result)

func _grant_combo_pack(pack: Dictionary) -> void:
	if not ShopCatalogServiceScript.can_buy_combo(pack, _player_shop_level()):
		return
	var diamonds: int = int(pack.get("diamonds", 0))
	if diamonds > 0:
		var result: Dictionary = ShopCatalogServiceScript.grant_diamonds(GameState.player_diamonds, diamonds)
		if bool(result.get("ok", false)):
			_apply_diamond_grant(diamonds, result)
	var booster_each: int = int(pack.get("booster_each", 0))
	if booster_each > 0:
		for booster_type in GameBoosterServiceScript.TYPES:
			_persist_booster_uses(str(booster_type), booster_each)
	else:
		var boosters: int = int(pack.get("boosters", pack.get("wildcards", 0)))
		if boosters > 0:
			_persist_booster_uses("mix", boosters)
	if SaveManager != null:
		SaveManager.save_game()
	combo_purchased.emit(pack)

func _grant_resource_pack(pack: Dictionary) -> bool:
	if not ShopCatalogServiceScript.can_buy_resource(pack, _player_shop_level()):
		return false
	var cost: int = int(pack.get("diamond_cost", 0))
	var amount: int = int(pack.get("amount", 1))
	var booster_type: String = str(pack.get("booster_type", ""))
	var current: int = 0
	if GameState != null:
		current = GameState.player_diamonds
	var preview: Dictionary = ShopCatalogServiceScript.spend_diamonds(current, cost)
	if not bool(preview.get("ok", false)):
		return false
	if SaveManager != null:
		if not SaveManager.spend_coins(cost):
			return false
	elif GameState != null:
		GameState.player_diamonds = int(preview.get("player_diamonds", current))
	diamonds_purchased.emit(0)
	if amount > 0 and not booster_type.is_empty():
		_persist_booster_uses(booster_type, amount)
		booster_purchased.emit(booster_type, amount)
	return true

func _apply_diamond_grant(amount: int, result: Dictionary) -> void:
	if SaveManager != null:
		SaveManager.add_coins(amount)
	elif GameState != null:
		GameState.player_diamonds = int(result.get("player_diamonds", GameState.player_diamonds))
	diamonds_purchased.emit(amount)

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

func _queue_pending_temp_slots(amount: int) -> void:
	if amount <= 0 or SaveManager == null:
		return
	var pending: int = int(SaveManager.player_data.get("pending_temp_slots", 0))
	SaveManager.player_data["pending_temp_slots"] = pending + amount

func _build_buy_confirm() -> void:
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
	dim.gui_input.connect(_on_confirm_dimmer_input)
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

	_confirm_icons_row = HBoxContainer.new()
	_confirm_icons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_icons_row.add_theme_constant_override("separation", 14)
	_confirm_icons_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_confirm_icons_row)
	_confirm_icon_nodes.clear()
	for _i in range(4):
		var icon := TextureRect.new()
		icon.texture = DiamondIconTexture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(72, 72)
		icon.visible = false
		_confirm_icons_row.add_child(icon)
		_confirm_icon_nodes.append(icon)

	_confirm_title = _make_outlined_label("¿Comprar?", 52)
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_confirm_title)

	_confirm_accept_btn = _make_action_button("Aceptar")
	_confirm_accept_btn.pressed.connect(_on_confirm_accept_pressed)
	vbox.add_child(_confirm_accept_btn)

	_confirm_cancel_btn = _make_action_button("Cancelar")
	_confirm_cancel_btn.pressed.connect(_on_confirm_cancel_pressed)
	vbox.add_child(_confirm_cancel_btn)

func _show_buy_confirm(pack_id: String) -> void:
	var pack: Dictionary = ShopCatalogServiceScript.pack_by_id(pack_id)
	if pack.is_empty() or _confirm_root == null:
		return
	if ShopCatalogServiceScript.is_resource_booster(pack):
		if not ShopCatalogServiceScript.can_buy_resource(pack, _player_shop_level()):
			return
	if ShopCatalogServiceScript.is_combo_pack(pack):
		if not ShopCatalogServiceScript.can_buy_combo(pack, _player_shop_level()):
			return
	_pending_pack_id = pack_id
	if _confirm_title != null:
		_confirm_title.text = ShopCatalogServiceScript.confirm_copy_for_pack(pack)
	_sync_confirm_icons(pack)
	_confirm_root.visible = true
	_layout_buy_confirm()

func _sync_confirm_icons(pack: Dictionary) -> void:
	var keys: PackedStringArray = ShopCatalogServiceScript.confirm_icon_keys(pack)
	for i in range(_confirm_icon_nodes.size()):
		var icon: TextureRect = _confirm_icon_nodes[i]
		if icon == null:
			continue
		if i < keys.size():
			icon.texture = _texture_for_confirm_key(keys[i])
			icon.visible = true
		else:
			icon.visible = false

func _texture_for_diamond_pack(pack: Dictionary) -> Texture2D:
	return _texture_for_art_path(ShopCatalogServiceScript.diamond_art_path(pack))

func _texture_for_art_path(path: String) -> Texture2D:
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		return tex
	return DiamondIconTexture

func _texture_for_confirm_key(key: String) -> Texture2D:
	match key:
		"lives":
			return LifeIconTexture
		"boosters":
			return MixIconTexture
		"mix":
			return MixIconTexture
		"hammer":
			return HammerIconTexture
		"glove":
			return GloveIconTexture
		_:
			return DiamondIconTexture

func _hide_buy_confirm() -> void:
	_pending_pack_id = ""
	if _confirm_root != null:
		_confirm_root.visible = false

func _layout_buy_confirm() -> void:
	if _confirm_card == null:
		return
	var vp := get_viewport_rect().size
	var s: float = clampf(minf(vp.x / REF_WIDTH, vp.y / 1920.0), 0.75, 1.25)
	var pad: float = 32.0 * s
	var sep: float = 18.0 * s
	var icon_h: float = 80.0 * s
	var title_h: float = 128.0 * s
	var btn_h: float = 86.0 * s
	if _confirm_accept_btn != null:
		btn_h = maxf(btn_h, _confirm_accept_btn.custom_minimum_size.y)
	var card_w: float = minf(vp.x * 0.86, 720.0 * s)
	var card_h: float = pad * 2.0 + icon_h + title_h + btn_h * 2.0 + sep * 3.0
	_confirm_card.size = Vector2(card_w, card_h)
	_confirm_card.position = Vector2((vp.x - card_w) * 0.5, (vp.y - card_h) * 0.5)
	if _confirm_icons_row != null:
		_confirm_icons_row.add_theme_constant_override("separation", int(14.0 * s))
	for icon in _confirm_icon_nodes:
		if icon != null:
			icon.custom_minimum_size = Vector2(icon_h, icon_h)
	if _confirm_title != null:
		_confirm_title.add_theme_font_size_override("font_size", int(52.0 * s))
		_confirm_title.add_theme_constant_override("outline_size", int(8.0 * s))
	if _confirm_accept_btn != null:
		_confirm_accept_btn.custom_minimum_size = Vector2(0, btn_h)
		_confirm_accept_btn.add_theme_font_size_override("font_size", int(46.0 * s))
	if _confirm_cancel_btn != null:
		_confirm_cancel_btn.custom_minimum_size = Vector2(0, btn_h)
		_confirm_cancel_btn.add_theme_font_size_override("font_size", int(46.0 * s))
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

func _on_confirm_accept_pressed() -> void:
	var pack_id: String = _pending_pack_id
	if pack_id.is_empty():
		_hide_buy_confirm()
		return
	var pack: Dictionary = ShopCatalogServiceScript.pack_by_id(pack_id)
	if ShopCatalogServiceScript.is_resource_booster(pack):
		if not _grant_resource_pack(pack):
			return
		_hide_buy_confirm()
		return
	_hide_buy_confirm()
	_grant_diamond_pack(pack_id)

func _on_confirm_cancel_pressed() -> void:
	_hide_buy_confirm()

func _on_confirm_dimmer_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var mouse_event := event as InputEventMouseButton
	if _confirm_card != null and _confirm_card.get_global_rect().has_point(mouse_event.global_position):
		return
	_hide_buy_confirm()

func _make_tab_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, 56)
	if LogoFont != null:
		btn.add_theme_font_override("font", LogoFont)
	btn.add_theme_font_size_override("font_size", 36)
	GameState.hook_button_sound(btn)
	return btn

func _on_tab_pressed(tab_index: int) -> void:
	_set_active_tab(tab_index)

func _set_active_tab(tab_index: int) -> void:
	_active_tab = ShopTabServiceScript.clamp_index(tab_index)
	for i in range(_pages.size()):
		_pages[i].visible = ShopTabServiceScript.is_page_visible(_active_tab, i)
	_refresh_tab_styles()

func _refresh_tab_styles() -> void:
	var p: Dictionary = GameState.get_ui_palette()
	var on_bg: Color = p.get("settings_btn_on", Color(0.58, 0.80, 0.48, 0.98))
	var on_border: Color = p.get("settings_btn_border", Color(0.75, 0.88, 0.58, 1.0))
	var off_bg: Color = p.get("settings_btn_off", Color(0.34, 0.26, 0.48, 0.95))
	var off_border: Color = p.get("settings_card_border", Color(0.42, 0.28, 0.58, 0.95))
	var text_marble := Color(0.88, 0.86, 0.83)
	for i in range(_tab_btns.size()):
		if i == _active_tab:
			_apply_button_style(_tab_btns[i], on_bg, on_border, 14, text_marble)
		else:
			_apply_button_style(_tab_btns[i], off_bg, off_border.darkened(0.2), 14, text_marble)

func _make_outlined_label(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", SHOP_TEXT)
	lbl.add_theme_color_override("font_outline_color", SHOP_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 3)
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
	btn.add_theme_font_size_override("font_size", 42)
	GameState.hook_button_sound(btn)
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
	btn.add_theme_color_override("font_outline_color", SHOP_OUTLINE)
	btn.add_theme_constant_override("outline_size", 3)
	var style := _flat_style(bg, border, radius)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_stylebox_override("disabled", style)

func _apply_rainbow_label(lbl: Label, span_px: float) -> void:
	if lbl == null:
		return
	var mat: ShaderMaterial = lbl.material as ShaderMaterial
	if mat == null or mat.shader != RainbowLabelShader:
		mat = ShaderMaterial.new()
		mat.shader = RainbowLabelShader
		lbl.material = mat
	mat.set_shader_parameter("span_px", maxf(span_px, 1.0))
	mat.set_shader_parameter("rainbow_sat", 0.82)
	mat.set_shader_parameter("rainbow_val", 0.98)
	mat.set_shader_parameter("pastel_mix", 0.0)

func _clear_rainbow_label(lbl: Label) -> void:
	if lbl != null:
		lbl.material = null

func _hide_rainbow_fill(host: Control) -> void:
	if host == null or not host.has_meta(HudTextureButtons.RAINBOW_BG_META):
		return
	var bg: TextureRect = host.get_meta(HudTextureButtons.RAINBOW_BG_META)
	if bg != null:
		bg.visible = false

func _hide_gold_fill(host: Control) -> void:
	if host == null or not host.has_meta(HudTextureButtons.GOLD_BG_META):
		return
	var bg: TextureRect = host.get_meta(HudTextureButtons.GOLD_BG_META)
	if bg != null:
		bg.visible = false

func _apply_shop_identity() -> void:
	if card != null:
		_hide_gold_fill(card)
		_hide_rainbow_fill(card)
		card.add_theme_stylebox_override("panel", _flat_style(SHOP_CARD_BG, SHOP_CARD_BORDER, 34, 0))
	if content_well != null:
		content_well.add_theme_stylebox_override("panel", _flat_style(SHOP_WELL, SHOP_CARD_BORDER, 24, 0))
	if header != null:
		header.add_theme_stylebox_override(
			"panel",
			_flat_style(SHOP_PRICE_BG, SHOP_PRICE_BORDER, 18, 2)
		)
	if close_btn != null:
		var close_style := _flat_style(Color(1.00, 1.00, 1.00, 1.0), SHOP_PRICE_BG, 12, 3)
		close_btn.add_theme_color_override("font_color", SHOP_PRICE_BG)
		close_btn.add_theme_color_override("font_outline_color", SHOP_PRICE_BG)
		close_btn.add_theme_constant_override("outline_size", 3)
		close_btn.add_theme_stylebox_override("normal", close_style)
		close_btn.add_theme_stylebox_override("hover", close_style)
		close_btn.add_theme_stylebox_override("pressed", close_style)
		close_btn.add_theme_stylebox_override("focus", close_style)
		close_btn.add_theme_stylebox_override("disabled", close_style)
	if title_label != null:
		_clear_rainbow_label(title_label)
		title_label.add_theme_color_override("font_color", SHOP_TITLE)
		title_label.add_theme_color_override("font_outline_color", SHOP_OUTLINE)
	for lbl in _placeholder_labels:
		if lbl != null:
			lbl.add_theme_color_override("font_color", SHOP_TEXT)
	_apply_button_style(_close_menu_btn, SHOP_PRICE_BG, SHOP_PRICE_BORDER, 22, SHOP_TEXT)
	_style_diamond_offer_rows()
	_style_resource_rows(SHOP_PRICE_BG, SHOP_PRICE_BORDER, SHOP_WELL, SHOP_CARD_BORDER, SHOP_TEXT)
	_style_combo_cards()
	if _confirm_card != null:
		_hide_gold_fill(_confirm_card)
		_hide_rainbow_fill(_confirm_card)
		_confirm_card.add_theme_stylebox_override("panel", _flat_style(SHOP_CONFIRM_BG, SHOP_CARD_BORDER, 34, 2))
	if _confirm_title != null:
		_confirm_title.add_theme_color_override("font_color", SHOP_TITLE)
		_confirm_title.add_theme_color_override("font_outline_color", SHOP_OUTLINE)
	_apply_button_style(_confirm_accept_btn, SHOP_PRICE_BG, SHOP_PRICE_BORDER, 22, SHOP_TEXT)
	_apply_button_style(_confirm_cancel_btn, SHOP_CANCEL_BG, SHOP_CARD_BORDER, 22, SHOP_TEXT)
	_hide_rainbow_fill(_close_menu_btn)
	_hide_rainbow_fill(_confirm_accept_btn)
	_hide_rainbow_fill(_confirm_cancel_btn)

func _on_dimmer_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	# El toque que abre el menú no debe cerrarlo en el mismo frame.
	if Time.get_ticks_msec() - _opened_at_msec < 250:
		return
	if _confirm_root != null and _confirm_root.visible:
		_hide_buy_confirm()
		return
	var mouse_event := event as InputEventMouseButton
	var point: Vector2 = mouse_event.global_position
	if card != null and not card.get_global_rect().has_point(point):
		close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		layout_for_viewport(get_viewport_rect().size)

extends Control

const CoverTexture = preload("res://Imagenes/home-2.png")
const LifeIconTexture = preload("res://Imagenes/icono-vidas.png")
const StarIconTexture = preload("res://Imagenes/icono-estrella.png")
const CartIconTexture = preload("res://Imagenes/icono-cart.png")
const SettingsIconTexture = preload("res://Imagenes/icono-settings.png")
const CoinScene = preload("res://coin.tscn")
const LogoFont = preload("res://Fonts/Chewy-Regular.ttf")
const GameScenePath := "res://Main.tscn"

const REF_WIDTH := 1080.0
const EDGE_MARGIN := 14.0
const CHIP_TOP_RATIO := 0.075
const LEVEL_Y_RATIO := 0.36
## Centro de la moneda sobre el pedestal/cojín del fondo home-2.
const PEDESTAL_COIN_X_RATIO := 0.50
const PEDESTAL_COIN_Y_RATIO := 0.505
const PEDESTAL_COIN_SCALE := 3.6
const BTN_GAP := 16.0
const CORNER_BTN_WIDTH_RATIO := 0.12
const STAT_BTN_WIDTH_RATIO := 0.24
const LOBBY_STAT_FONT_SIZE := 44
const HUD_PILL_TEXT := Color(0.95, 0.98, 0.92)
const HUD_PILL_RADIUS := 34
const LOBBY_CHIP_HEIGHT_RATIO := 0.76
const LOBBY_CORNER_ICON_RATIO := 0.68
const LOBBY_STAT_ICON_RATIO := 0.56

const PLAY_WIDTH_RATIO := 0.46
const PLAY_BOTTOM_MARGIN := 0.0
const PLAY_Y_DROP := 58.0
const PLAY_VISIBLE_HEIGHT := 0.86

var background_rect: TextureRect = null
var hud_layer: CanvasLayer = null
var hud_root: Control = null
var profile_button_shadow: Panel = null
var profile_button: Control = null
var profile_avatar: TextureRect = null
var shop_button_shadow: Panel = null
var shop_button: Control = null
var shop_button_icon: TextureRect = null
var life_button_shadow: Panel = null
var life_button: Control = null
var life_button_icon: TextureRect = null
var life_button_label: Label = null
var stars_button_shadow: Panel = null
var stars_button: Control = null
var stars_button_icon: TextureRect = null
var stars_button_label: Label = null
var settings_button_shadow: Panel = null
var settings_button: Control = null
var settings_button_icon: TextureRect = null
var level_label: Label = null
var showcase_coin: Node2D = null
var play_button: TextureButton = null
var settings_layer: CanvasLayer = null
var settings_ui: SettingsOverlay = null
var profile_layer: CanvasLayer = null
var profile_ui: ProfileOverlay = null

func _ready() -> void:
	_apply_portrait_orientation()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_ui()
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	if not GameState.background_theme_changed.is_connected(_on_background_theme_changed):
		GameState.background_theme_changed.connect(_on_background_theme_changed)
	if not SaveManager.player_data_changed.is_connected(_on_player_data_changed):
		SaveManager.player_data_changed.connect(_on_player_data_changed)
	update_displays()
	layout_ui()

func _on_background_theme_changed(_theme_id: String) -> void:
	layout_ui()

func _on_player_data_changed() -> void:
	update_displays()

func _apply_portrait_orientation() -> void:
	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		return
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

func build_ui() -> void:
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.texture = CoverTexture
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)

	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_layer.add_child(hud_root)

	var profile_parts := _build_profile_chip()
	profile_button_shadow = profile_parts.shadow
	profile_button = profile_parts.panel
	profile_avatar = profile_parts.avatar
	_bind_chip_click(profile_button, _open_profile)

	var shop_parts := _build_hud_icon_chip(CartIconTexture)
	shop_button_shadow = shop_parts.shadow
	shop_button = shop_parts.panel
	shop_button_icon = shop_parts.icon
	_bind_chip_click(shop_button, _on_shop_pressed)

	var life_parts := _build_hud_stat_chip(LifeIconTexture, "0 Vidas")
	life_button_shadow = life_parts.shadow
	life_button = life_parts.panel
	life_button_icon = life_parts.icon
	life_button_label = life_parts.label
	var stars_parts := _build_hud_stat_chip(StarIconTexture, "0")
	stars_button_shadow = stars_parts.shadow
	stars_button = stars_parts.panel
	stars_button_icon = stars_parts.icon
	stars_button_label = stars_parts.label
	var settings_parts := _build_hud_icon_chip(SettingsIconTexture)
	settings_button_shadow = settings_parts.shadow
	settings_button = settings_parts.panel
	settings_button_icon = settings_parts.icon
	_bind_chip_click(settings_button, _open_settings)

	hud_root.add_child(profile_button_shadow)
	hud_root.add_child(profile_button)
	hud_root.add_child(life_button_shadow)
	hud_root.add_child(life_button)
	hud_root.add_child(stars_button_shadow)
	hud_root.add_child(stars_button)
	hud_root.add_child(settings_button_shadow)
	hud_root.add_child(settings_button)
	hud_root.add_child(shop_button_shadow)
	hud_root.add_child(shop_button)

	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if LogoFont != null:
		level_label.add_theme_font_override("font", LogoFont)
	level_label.add_theme_font_size_override("font_size", 72)
	level_label.add_theme_color_override("font_color", Color(0.22, 0.42, 0.24))
	level_label.add_theme_color_override("font_outline_color", Color(0.98, 0.99, 0.94, 0.9))
	level_label.add_theme_constant_override("outline_size", 6)
	hud_root.add_child(level_label)

	showcase_coin = CoinScene.instantiate()
	showcase_coin.z_index = 5
	hud_root.add_child(showcase_coin)
	if showcase_coin.has_method("set_value"):
		showcase_coin.set_value(SaveManager.get_max_unlocked_coin_value())

	build_settings_dialog()
	build_profile_editor()

	play_button = HudTextureButtons.create_play()
	play_button.pressed.connect(_on_play_pressed)
	play_button.z_index = 20
	hud_root.add_child(play_button)

func _build_profile_chip() -> Dictionary:
	return HudTextureButtons.create_avatar_chip(SaveManager.get_avatar_texture())

func build_settings_dialog() -> void:
	settings_layer = CanvasLayer.new()
	settings_layer.layer = 100
	add_child(settings_layer)
	settings_ui = SettingsOverlay.new()
	settings_layer.add_child(settings_ui)

func build_profile_editor() -> void:
	profile_layer = CanvasLayer.new()
	profile_layer.layer = 110
	add_child(profile_layer)
	profile_ui = ProfileOverlay.new()
	profile_layer.add_child(profile_ui)
	profile_ui.profile_saved.connect(_on_profile_saved)

func _on_profile_saved() -> void:
	update_displays()

func update_displays() -> void:
	if life_button_label != null:
		life_button_label.text = HudTextureButtons.format_lives_text(GameState.lives)
	if stars_button_label != null:
		stars_button_label.text = HudTextureButtons.format_stat_number(GameState.player_stars)
	if level_label != null:
		level_label.text = "Nivel %d" % GameState.player_level
	if showcase_coin != null and showcase_coin.has_method("set_value"):
		showcase_coin.set_value(SaveManager.get_max_unlocked_coin_value())
	if profile_avatar != null:
		profile_avatar.texture = SaveManager.get_avatar_texture()

func _hud_pill_radius(scale: float) -> int:
	return int(HUD_PILL_RADIUS * scale)

func _apply_hud_chip_styles(shadow: Panel, pill: Control, radius: int, pill_size: Vector2) -> void:
	HudTextureButtons.apply_shadow_corner_radius(shadow, radius)
	HudTextureButtons.apply_gradient_pill_style(pill, radius, pill_size)

func create_shadow_panel(radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.19, 0.28, 0.18, 0.18)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", style)
	return panel

func create_hud_text_label(text: String, font_size: int) -> Label:
	var lbl := create_label(text, font_size, HUD_PILL_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if LogoFont != null:
		lbl.add_theme_font_override("font", LogoFont)
	return lbl

func layout_hud_pill_pair(shadow: Panel, panel: Control, pos: Vector2, size: Vector2, scale: float) -> void:
	if panel != null:
		panel.position = pos
		panel.size = size
	if shadow != null:
		shadow.position = pos + Vector2(0, 6.0 * scale)
		shadow.size = size

func _build_hud_icon_chip(icon_texture: Texture2D) -> Dictionary:
	var radius := HUD_PILL_RADIUS
	var shadow := create_shadow_panel(radius)
	var panel := HudTextureButtons.create_gradient_pill()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)
	return {"shadow": shadow, "panel": panel, "icon": icon}

func _build_hud_stat_chip(icon_texture: Texture2D, text: String) -> Dictionary:
	var radius := HUD_PILL_RADIUS
	var shadow := create_shadow_panel(radius)
	var panel := HudTextureButtons.create_gradient_pill()
	panel.clip_contents = true
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(row)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var lbl := create_hud_text_label(text, LOBBY_STAT_FONT_SIZE)
	row.add_child(lbl)
	return {"shadow": shadow, "panel": panel, "icon": icon, "label": lbl}

func _bind_chip_click(panel: Control, callback: Callable) -> void:
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			callback.call()
	)

func _get_cover_draw_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	var tex_size := CoverTexture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)
	var cover_scale := maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	var drawn_size := tex_size * cover_scale
	var offset := (viewport_size - drawn_size) * 0.5
	return Rect2(offset, drawn_size)

func _get_play_button_size(cover_width: float) -> Vector2:
	return HudTextureButtons.get_button_size(
		HudTextureButtons.PlayButtonTexture,
		cover_width * PLAY_WIDTH_RATIO
	)

func layout_ui() -> void:
	var viewport_size := get_viewport_rect().size
	var scale := viewport_size.x / REF_WIDTH
	var cover := _get_cover_draw_rect()
	var row_y := cover.position.y + cover.size.y * CHIP_TOP_RATIO
	var edge_margin := EDGE_MARGIN * scale
	var gap := BTN_GAP * scale
	var layout_w := viewport_size.x
	var corner_w := layout_w * CORNER_BTN_WIDTH_RATIO
	var chip_h := corner_w * LOBBY_CHIP_HEIGHT_RATIO
	var stat_w := layout_w * STAT_BTN_WIDTH_RATIO
	var required := edge_margin * 2.0 + corner_w * 2.0 + stat_w * 2.0 + gap
	if required > layout_w and required > 0.0:
		var shrink := layout_w / required
		corner_w *= shrink
		stat_w *= shrink
		chip_h *= shrink
		gap *= shrink
	var corner_size := Vector2(corner_w, chip_h)
	var stat_size := Vector2(stat_w, chip_h)
	var pill_radius := _hud_pill_radius(scale)
	var total_center_w := stat_size.x + gap + stat_size.x
	var center_x := (viewport_size.x - total_center_w) * 0.5
	var avatar_side := chip_h * 1.35
	var min_center_x := edge_margin + avatar_side + 4.0
	var max_center_x := viewport_size.x - edge_margin - corner_w - total_center_w - 4.0
	center_x = clampf(center_x, min_center_x, maxf(min_center_x, max_center_x))
	var icon_corner := chip_h * LOBBY_CORNER_ICON_RATIO
	var icon_stat := chip_h * LOBBY_STAT_ICON_RATIO
	var stat_font := int(clampf(LOBBY_STAT_FONT_SIZE * scale, 22.0, chip_h * 0.44))

	# Perfil arriba a la izquierda (un poco más grande que el resto de chips).
	var avatar_size := Vector2(avatar_side, avatar_side)
	var avatar_y := row_y - (avatar_side - chip_h) * 0.5
	layout_hud_pill_pair(profile_button_shadow, profile_button, Vector2(edge_margin, avatar_y), avatar_size, scale)
	HudTextureButtons.apply_avatar_chip_style(profile_button_shadow, avatar_size)

	layout_hud_pill_pair(life_button_shadow, life_button, Vector2(center_x, row_y), stat_size, scale)
	_apply_hud_chip_styles(life_button_shadow, life_button, pill_radius, stat_size)
	life_button_icon.custom_minimum_size = Vector2(icon_stat, icon_stat)
	if life_button_label != null:
		life_button_label.add_theme_font_size_override("font_size", stat_font)

	layout_hud_pill_pair(
		stars_button_shadow,
		stars_button,
		Vector2(center_x + stat_size.x + gap, row_y),
		stat_size,
		scale
	)
	_apply_hud_chip_styles(stars_button_shadow, stars_button, pill_radius, stat_size)
	stars_button_icon.custom_minimum_size = Vector2(icon_stat, icon_stat)
	if stars_button_label != null:
		stars_button_label.add_theme_font_size_override("font_size", stat_font)

	layout_hud_pill_pair(
		settings_button_shadow,
		settings_button,
		Vector2(viewport_size.x - edge_margin - corner_size.x, row_y),
		corner_size,
		scale
	)
	_apply_hud_chip_styles(settings_button_shadow, settings_button, pill_radius, corner_size)
	settings_button_icon.custom_minimum_size = Vector2(icon_corner, icon_corner)

	if level_label != null:
		var level_w := cover.size.x * 0.72
		var level_h := 120.0 * scale
		var level_x := cover.position.x + (cover.size.x - level_w) * 0.5
		var level_y := cover.position.y + cover.size.y * LEVEL_Y_RATIO
		level_label.position = Vector2(level_x, level_y)
		level_label.size = Vector2(level_w, level_h)
		level_label.add_theme_font_size_override("font_size", int(72.0 * scale))

	if showcase_coin != null:
		var coin_x := cover.position.x + cover.size.x * PEDESTAL_COIN_X_RATIO
		var coin_y := cover.position.y + cover.size.y * PEDESTAL_COIN_Y_RATIO
		showcase_coin.position = Vector2(coin_x, coin_y)
		showcase_coin.scale = Vector2.ONE * (PEDESTAL_COIN_SCALE * scale)

	var play_pos := Vector2.ZERO
	var play_size := Vector2.ZERO
	if play_button != null:
		play_size = _get_play_button_size(cover.size.x)
		play_pos.x = cover.position.x + (cover.size.x - play_size.x) * 0.5
		var cover_bottom := minf(cover.position.y + cover.size.y, viewport_size.y)
		play_pos.y = cover_bottom - play_size.y - (PLAY_BOTTOM_MARGIN * scale) + (PLAY_Y_DROP * scale)
		var max_y := viewport_size.y - play_size.y * PLAY_VISIBLE_HEIGHT
		play_pos.y = minf(play_pos.y, max_y)
		HudTextureButtons.layout_button(play_button, play_pos, play_size)

	# Tienda abajo a la izquierda, alineada con Jugar.
	var shop_size := corner_size
	var shop_x := edge_margin
	var shop_y := play_pos.y + (play_size.y - shop_size.y) * 0.5
	if play_button == null:
		shop_y = viewport_size.y - shop_size.y - edge_margin * 2.0
	layout_hud_pill_pair(shop_button_shadow, shop_button, Vector2(shop_x, shop_y), shop_size, scale)
	_apply_hud_chip_styles(shop_button_shadow, shop_button, pill_radius, shop_size)
	shop_button_icon.custom_minimum_size = Vector2(icon_corner, icon_corner)

	if settings_ui != null:
		settings_ui.layout_for_viewport(viewport_size)
	if profile_ui != null:
		profile_ui.layout_for_viewport(viewport_size)

func _open_profile() -> void:
	if profile_ui != null:
		profile_ui.open()
		profile_ui.layout_for_viewport(get_viewport_rect().size)

func _on_viewport_resized() -> void:
	layout_ui()

func _on_play_pressed() -> void:
	SceneLoader.go_to(GameScenePath)

func _on_shop_pressed() -> void:
	print("Tienda — próximamente")

func _open_settings() -> void:
	if settings_ui != null:
		settings_ui.open()
		settings_ui.layout_for_viewport(get_viewport_rect().size)

func create_panel(bg: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", style)
	return panel

func create_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

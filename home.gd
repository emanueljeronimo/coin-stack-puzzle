extends Control

const CoverTexture = preload("res://Imagenes/prototipo 1 portada.png")
const LifeIconTexture = preload("res://Imagenes/icono-vidas.png")
const PlayButtonTexture = preload("res://Imagenes/boton-jugar_ahora.png")
const GameScenePath := "res://Main.tscn"

const REF_WIDTH := 1080.0
## Chips superiores — burbuja pastel semitransparente.
const CHIP_HEIGHT := 90.0
const CHIP_LIFE_W := 228.0
const CHIP_STARS_W := 238.0
const CHIP_GAP := 20.0
const TOP_MARGIN := 26.0
const CHIP_RADIUS := 38
const CHIP_FONT_LIFE := 36
const CHIP_FONT_STARS := 34
const CHIP_BG := Color(1.0, 0.99, 1.0, 0.52)
const CHIP_BORDER := Color(0.60, 0.84, 0.72, 0.72)
const CHIP_TEXT := Color(0.94, 0.58, 0.74, 1.0)
const CHIP_TEXT_OUTLINE := Color(0.99, 0.96, 0.86, 0.95)

## Botón Jugar — imagen sobre la portada.
const PLAY_WIDTH_RATIO := 0.54
const PLAY_BOTTOM_MARGIN := 0.0
const PLAY_Y_DROP := 44.0
const PLAY_VISIBLE_HEIGHT := 0.88

var background_rect: TextureRect = null
var play_button: TextureButton = null
var hud_layer: CanvasLayer = null
var life_chip: Panel = null
var life_chip_icon: TextureRect = null
var life_chip_label: Label = null
var stars_chip: Panel = null
var stars_chip_label: Label = null
var _cute_font: Font = null

func _ready() -> void:
	_apply_portrait_orientation()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_ui()
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	layout_ui()
	update_resource_displays()

func _apply_portrait_orientation() -> void:
	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		return
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

func build_ui() -> void:
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.offset_left = 0
	background_rect.offset_top = 0
	background_rect.offset_right = 0
	background_rect.offset_bottom = 0
	background_rect.texture = CoverTexture
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)

	play_button = TextureButton.new()
	play_button.texture_normal = PlayButtonTexture
	play_button.ignore_texture_size = true
	play_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_button.pressed.connect(_on_play_pressed)
	play_button.button_down.connect(_on_play_button_down)
	play_button.button_up.connect(_on_play_button_up)
	play_button.mouse_exited.connect(_on_play_button_up)
	add_child(play_button)

	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	life_chip = _create_chip_with_icon_panel(
		LifeIconTexture, "%d  Vidas" % GameState.lives, CHIP_BG, CHIP_BORDER, CHIP_FONT_LIFE
	)
	life_chip_icon = life_chip.get_meta("chip_icon")
	life_chip_label = life_chip.get_meta("chip_label")
	stars_chip = _create_chip_panel(
		"%d ⭐" % GameState.player_stars, CHIP_BG, CHIP_BORDER, CHIP_FONT_STARS
	)
	stars_chip_label = stars_chip.get_meta("chip_label")
	hud_layer.add_child(life_chip)
	hud_layer.add_child(stars_chip)

func _get_cute_font() -> Font:
	if _cute_font == null:
		var system_font := SystemFont.new()
		system_font.font_weight = 800
		system_font.font_names = PackedStringArray([
			"Fredoka",
			"Nunito",
			"Baloo 2",
			"Segoe UI",
			"Arial Rounded MT Bold",
			"sans-serif",
		])
		_cute_font = system_font
	return _cute_font

func _get_play_button_size(cover_width: float) -> Vector2:
	var tex_size := PlayButtonTexture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Vector2(cover_width * PLAY_WIDTH_RATIO, cover_width * PLAY_WIDTH_RATIO * 0.28)
	var btn_w := cover_width * PLAY_WIDTH_RATIO
	var btn_h := btn_w * (tex_size.y / tex_size.x)
	return Vector2(btn_w, btn_h)

func _get_cover_draw_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	var tex_size := CoverTexture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)
	var cover_scale := maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	var drawn_size := tex_size * cover_scale
	var offset := (viewport_size - drawn_size) * 0.5
	return Rect2(offset, drawn_size)

func layout_ui() -> void:
	if play_button == null:
		return
	var viewport_size := get_viewport_rect().size
	var scale := viewport_size.x / REF_WIDTH
	var cover := _get_cover_draw_rect()
	var btn_size := _get_play_button_size(cover.size.x)
	var btn_x := cover.position.x + (cover.size.x - btn_size.x) * 0.5
	var cover_bottom := minf(cover.position.y + cover.size.y, viewport_size.y)
	var btn_y := cover_bottom - btn_size.y - (PLAY_BOTTOM_MARGIN * scale) + (PLAY_Y_DROP * scale)
	var max_y := viewport_size.y - btn_size.y * PLAY_VISIBLE_HEIGHT
	btn_y = minf(btn_y, max_y)
	play_button.position = Vector2(btn_x, btn_y)
	play_button.size = btn_size
	play_button.pivot_offset = btn_size * 0.5

	if life_chip == null or stars_chip == null:
		return
	var chip_h := CHIP_HEIGHT * scale
	var gap := CHIP_GAP * scale
	var life_w := CHIP_LIFE_W * scale
	var stars_w := CHIP_STARS_W * scale
	var total_w := life_w + stars_w + gap
	var start_x := (viewport_size.x - total_w) * 0.5
	var chip_y := TOP_MARGIN * scale

	life_chip.position = Vector2(start_x, chip_y)
	life_chip.size = Vector2(life_w, chip_h)
	stars_chip.position = Vector2(start_x + life_w + gap, chip_y)
	stars_chip.size = Vector2(stars_w, chip_h)
	_apply_cute_chip_label(life_chip, int(CHIP_FONT_LIFE * scale))
	_apply_cute_chip_label(stars_chip, int(CHIP_FONT_STARS * scale))
	if life_chip_icon != null:
		var life_icon_size := chip_h * 0.78
		life_chip_icon.custom_minimum_size = Vector2(life_icon_size, life_icon_size)

func update_resource_displays() -> void:
	if life_chip_label != null:
		life_chip_label.text = "%d  Vidas" % GameState.lives
	if stars_chip_label != null:
		stars_chip_label.text = "%d ⭐" % GameState.player_stars

func _on_viewport_resized() -> void:
	layout_ui()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GameScenePath)

func _on_play_button_down() -> void:
	if play_button != null:
		play_button.scale = Vector2(0.96, 0.96)

func _on_play_button_up() -> void:
	if play_button != null:
		play_button.scale = Vector2.ONE

func _create_panel(bg: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.72, 0.56, 0.68, 0.10)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _create_cute_label(
	text: String,
	font_size: int,
	fill: Color,
	outline: Color,
	outline_size: int
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_cute_label_style(lbl, font_size, fill, outline, outline_size)
	return lbl

func _apply_cute_label_style(
	lbl: Label,
	font_size: int,
	fill: Color,
	outline: Color,
	outline_size: int
) -> void:
	lbl.add_theme_font_override("font", _get_cute_font())
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", fill)
	lbl.add_theme_constant_override("outline_size", outline_size)
	lbl.add_theme_color_override("font_outline_color", outline)

func _apply_cute_chip_label(chip: Panel, font_size: int) -> void:
	if chip == null:
		return
	var lbl: Label = chip.get_meta("chip_label")
	if lbl != null:
		_apply_cute_label_style(lbl, font_size, CHIP_TEXT, CHIP_TEXT_OUTLINE, 4)

func _create_chip_panel(text: String, bg: Color, border: Color, font_size: int) -> Panel:
	var panel := _create_panel(bg, border, CHIP_RADIUS)
	panel.clip_contents = true
	var lbl := _create_cute_label(text, font_size, CHIP_TEXT, CHIP_TEXT_OUTLINE, 4)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 0
	lbl.offset_top = 0
	lbl.offset_right = 0
	lbl.offset_bottom = 0
	panel.add_child(lbl)
	panel.set_meta("chip_label", lbl)
	return panel

func _create_chip_with_icon_panel(
	texture: Texture2D, text: String, bg: Color, border: Color, font_size: int
) -> Panel:
	var panel := _create_panel(bg, border, CHIP_RADIUS)
	panel.clip_contents = true
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16
	content.offset_top = 0
	content.offset_right = -16
	content.offset_bottom = 0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var lbl := _create_cute_label(text, font_size, CHIP_TEXT, CHIP_TEXT_OUTLINE, 4)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(lbl)
	panel.set_meta("chip_label", lbl)
	panel.set_meta("chip_icon", icon)
	return panel

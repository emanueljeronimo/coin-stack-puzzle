class_name HudTextureButtons
extends RefCounted

const LongButtonTexture := preload("res://Imagenes/boton-largo.png")
const RoundButtonTexture := preload("res://Imagenes/boton-redondo.png")
const PlayPastelButtonTexture := preload("res://Imagenes/boton-jugar-ahora-pastel.png")
const PlayButtonTexture := preload("res://Imagenes/boton-jugar_ahora.png")
const LogoFont := preload("res://Fonts/Chewy-Regular.ttf")
const GameLivesServiceScript := preload("res://game_lives_service.gd")
const SlotOverlayBgScript := preload("res://slot_overlay_bg.gd")

const PILL_GRAD_CELESTE := Color(0.62, 0.82, 0.97, 0.94)
const PILL_GRAD_ROSA := Color(0.98, 0.68, 0.84, 0.94)
const PILL_GRAD_VERDE := Color(0.66, 0.88, 0.68, 0.94)
const PILL_BG_META := "pill_bg"
const RoundedClipShader = preload("res://rounded_clip.gdshader")

const BTN_TEXT_COLOR := Color(0.88, 0.86, 0.83)
const BTN_TEXT_OUTLINE := Color(0.22, 0.20, 0.24, 0.78)
## Texto sobre chips crema (vidas, estrellas): verde oscuro legible sobre fondo claro.
const CHIP_STAT_COLOR := Color(0.34, 0.48, 0.36)
const CHIP_STAT_OUTLINE := Color(0.99, 0.98, 0.94, 0.75)
const CHIP_STAT_OUTLINE_SIZE := 2
const CHIP_STAT_FONT_SIZE := 33
const ROUND_ICON_SIZE_RATIO := 0.58
const LONG_CHIP_ICON_SIZE_RATIO := 0.52
const LIFE_HEART_ICON_SIZE_RATIO := 1.12
const LIFE_COUNT_COLOR := Color(0.98, 0.97, 0.94)
const LIFE_COUNT_OUTLINE := Color(0.28, 0.10, 0.14, 0.92)
## El PNG deja el cuerpo del corazón ~43% desde arriba (hay vacío abajo del pico).
const LIFE_COUNT_TOP_RATIO := 0.02
const LIFE_COUNT_BOTTOM_RATIO := 0.18
const RESOURCE_PILL_BG := Color(0.97, 0.94, 0.88, 0.98)
const RESOURCE_PILL_SHADOW := Color(0.18, 0.12, 0.10, 0.22)
const RESOURCE_TEXT := Color(0.16, 0.20, 0.34)
const RESOURCE_PLUS_BG := Color(0.40, 0.78, 0.30, 1.0)
const RESOURCE_PLUS_BORDER := Color(0.28, 0.58, 0.20, 1.0)
## El pill es más bajo que la fila HUD; el ícono queda claramente más grande.
const RESOURCE_PILL_HEIGHT_RATIO := 0.66
const RESOURCE_ICON_HEIGHT_RATIO := 2.15
const RESOURCE_ICON_HANG := 0.40

static func get_button_size(texture: Texture2D, width: float) -> Vector2:
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Vector2(width, width * 0.35)
	return Vector2(width, width * (tex_size.y / tex_size.x))

static func wire_press_scale(btn: TextureButton) -> void:
	btn.button_down.connect(func() -> void:
		btn.scale = Vector2(0.96, 0.96)
	)
	var reset := func() -> void:
		btn.scale = Vector2.ONE
	btn.button_up.connect(reset)
	btn.mouse_exited.connect(reset)

static func layout_button(btn: TextureButton, position: Vector2, size: Vector2) -> void:
	if btn == null:
		return
	btn.position = position
	btn.size = size
	btn.pivot_offset = size * 0.5

static func create_base(texture: Texture2D) -> TextureButton:
	var btn := TextureButton.new()
	btn.texture_normal = texture
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	wire_press_scale(btn)
	return btn

static func format_stat_number(value: int) -> String:
	var digits := str(value)
	if digits.length() <= 3:
		return digits
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "." + out
		out = digits[i] + out
		count += 1
	return out

static func format_lives_text(value: int, remaining_sec: int = 0) -> String:
	return GameLivesServiceScript.format_chip_text(value, remaining_sec)

## Ajusta chips del HUD superior para que no se superpongan en pantallas angostas.
static func fit_top_hud_chip_row(
	viewport_w: float,
	edge_margin: float,
	gap: float,
	corner_w: float,
	stat_w: float,
	chip_h: float
) -> Dictionary:
	var margin := edge_margin
	var row_gap := gap
	var corner := corner_w
	var stat := stat_w
	var height := chip_h
	var avail := viewport_w - margin * 2.0
	var required := corner * 2.0 + stat * 2.0 + row_gap
	if required > avail and required > 0.0:
		var shrink := avail / required
		corner *= shrink
		stat *= shrink
		height *= shrink
		row_gap *= shrink
	var total_center := stat * 2.0 + row_gap
	var center_x := (viewport_w - total_center) * 0.5
	var min_center := margin + corner + 4.0
	var max_center := viewport_w - margin - corner - total_center - 4.0
	center_x = clampf(center_x, min_center, maxf(min_center, max_center))
	return {
		"edge_margin": margin,
		"gap": row_gap,
		"corner_w": corner,
		"stat_w": stat,
		"chip_h": height,
		"center_x": center_x,
	}

static func create_gradient_pill() -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.clip_contents = true
	var bg := SlotOverlayBgScript.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	root.set_meta(PILL_BG_META, bg)
	return root


static func apply_rounded_clip(item: CanvasItem, size: Vector2, radius: float) -> void:
	if item == null:
		return
	var size_px := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	var r := minf(radius, minf(size_px.x, size_px.y) * 0.5)
	var mat: ShaderMaterial = null
	if item.material is ShaderMaterial:
		var existing := item.material as ShaderMaterial
		if existing.shader == RoundedClipShader:
			mat = existing
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = RoundedClipShader
		item.material = mat
	mat.set_shader_parameter("size_px", size_px)
	mat.set_shader_parameter("corner_radius", r)


## Primer color opaco en diagonal desde (0,0), oscurecido para el borde.
## Sale siempre de la imagen (path PNG o textura); no hay color fijo por avatar.
static func sample_texture_corner_color(texture: Texture2D, path: String = "") -> Color:
	var img: Image = null
	if not path.is_empty():
		img = _image_from_path(path)
	if img == null and texture != null:
		img = _texture_to_image(texture)
		if img == null and not str(texture.resource_path).is_empty():
			img = _image_from_path(texture.resource_path)
	var sampled := _first_opaque_diagonal(img)
	if sampled.a <= 0.0:
		return Color(0, 0, 0, 1)
	sampled.a = 1.0
	return sampled.darkened(0.28)


static func _first_opaque_diagonal(img: Image) -> Color:
	if img == null or img.get_width() < 1 or img.get_height() < 1:
		return Color(0, 0, 0, 0)
	var limit := mini(img.get_width(), img.get_height())
	for i in range(limit):
		var c := img.get_pixel(i, i)
		if c.a > 0.15:
			return c
	return Color(0, 0, 0, 0)


static func _image_from_path(path: String) -> Image:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var img := Image.new()
	if img.load_png_from_buffer(bytes) != OK:
		return null
	return img


static func _texture_to_image(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var img := texture.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img = img.duplicate()
		if img.decompress() != OK:
			return null
	return img


## Botón de perfil: avatar con borde fino redondeado.
static func create_avatar_chip(texture: Texture2D, path: String = "") -> Dictionary:
	var shadow := Panel.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.visible = false
	shadow.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.clip_contents = true
	if path.is_empty() and texture != null:
		path = texture.resource_path
	panel.set_meta("avatar_path", path)
	var border_col := SaveManager.get_avatar_border_color()
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = border_col
	border_style.border_color = border_col
	border_style.set_border_width_all(5)
	border_style.set_corner_radius_all(22)
	panel.add_theme_stylebox_override("panel", border_style)

	var avatar := TextureRect.new()
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.offset_left = 5
	avatar.offset_top = 5
	avatar.offset_right = -5
	avatar.offset_bottom = -5
	avatar.texture = texture
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(avatar)
	return {"shadow": shadow, "panel": panel, "avatar": avatar}


static func apply_avatar_chip_style(shadow: Panel, panel: Control, avatar: TextureRect, size: Vector2) -> void:
	if shadow == null:
		return
	var side := mini(size.x, size.y)
	var radius := int(side * 0.36)
	var border_w := int(clampf(side * 0.06, 4.0, 8.0))
	apply_shadow_corner_radius(shadow, radius)
	if panel == null:
		return
	var style := panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.set_corner_radius_all(radius)
		flat.set_border_width_all(border_w)
		if avatar != null and avatar.texture != null:
			var border_col := SaveManager.get_avatar_border_color()
			flat.border_color = border_col
			flat.bg_color = border_col
		panel.add_theme_stylebox_override("panel", flat)
	if avatar != null:
		avatar.offset_left = float(border_w)
		avatar.offset_top = float(border_w)
		avatar.offset_right = float(-border_w)
		avatar.offset_bottom = float(-border_w)
		var inner := maxf(side - float(border_w) * 2.0, 1.0)
		var inner_radius := maxf(float(radius) - float(border_w), inner * 0.34)
		apply_rounded_clip(avatar, Vector2(inner, inner), inner_radius)


static func set_avatar_chip_texture(panel: Control, avatar: TextureRect, texture: Texture2D, path: String = "") -> void:
	if avatar != null:
		avatar.texture = texture
	if panel == null or texture == null:
		return
	if path.is_empty():
		path = texture.resource_path
	panel.set_meta("avatar_path", path)
	var style := panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		var border_col := SaveManager.get_avatar_border_color()
		flat.border_color = border_col
		flat.bg_color = border_col
		panel.add_theme_stylebox_override("panel", flat)


static func apply_gradient_pill_style(pill: Control, radius: int, pill_size: Vector2) -> void:
	if pill == null or not pill.has_meta(PILL_BG_META):
		return
	var bg: TextureRect = pill.get_meta(PILL_BG_META)
	if bg != null and bg.has_method("configure"):
		var palette: Dictionary = GameState.get_ui_palette()
		bg.configure(
			radius,
			palette.get("grad_a", PILL_GRAD_CELESTE),
			palette.get("grad_b", PILL_GRAD_ROSA),
			palette.get("grad_c", PILL_GRAD_VERDE),
			pill_size
		)

static func apply_shadow_corner_radius(shadow: Panel, radius: int) -> void:
	if shadow == null:
		return
	var style := shadow.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		flat.corner_radius_top_left = radius
		flat.corner_radius_top_right = radius
		flat.corner_radius_bottom_left = radius
		flat.corner_radius_bottom_right = radius

static func create_chip_stat_label(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if LogoFont != null:
		lbl.add_theme_font_override("font", LogoFont)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", CHIP_STAT_COLOR)
	lbl.add_theme_color_override("font_outline_color", CHIP_STAT_OUTLINE)
	lbl.add_theme_constant_override("outline_size", CHIP_STAT_OUTLINE_SIZE)
	return lbl

static func create_life_heart_badge(icon_texture: Texture2D) -> Dictionary:
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 0
	icon.offset_top = 0
	icon.offset_right = 0
	icon.offset_bottom = 0
	stack.add_child(icon)
	var count := Label.new()
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if LogoFont != null:
		count.add_theme_font_override("font", LogoFont)
	count.add_theme_color_override("font_color", LIFE_COUNT_COLOR)
	count.add_theme_color_override("font_outline_color", LIFE_COUNT_OUTLINE)
	count.add_theme_constant_override("outline_size", 5)
	count.set_anchors_preset(Control.PRESET_FULL_RECT)
	count.offset_left = 0
	count.offset_top = 0
	count.offset_right = 0
	count.offset_bottom = 0
	stack.add_child(count)
	return {"stack": stack, "icon": icon, "count": count}

static func layout_life_heart_badge(
	stack: Control,
	count: Label,
	size: float,
	font_ratio: float = 0.36,
	font_max: int = 38
) -> void:
	if stack != null:
		stack.custom_minimum_size = Vector2(size, size)
		stack.size = Vector2(size, size)
	if count != null:
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.offset_left = 0.0
		count.offset_right = 0.0
		count.offset_top = size * LIFE_COUNT_TOP_RATIO
		count.offset_bottom = -size * LIFE_COUNT_BOTTOM_RATIO
		count.clip_text = false
		count.add_theme_constant_override("outline_size", 4)
		count.add_theme_font_size_override("font_size", int(clampf(size * font_ratio, 16.0, float(font_max))))

static func create_resource_chip(icon_texture: Texture2D, with_icon_count: bool) -> Dictionary:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.clip_contents = false

	var shadow := Panel.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = RESOURCE_PILL_SHADOW
	shadow_style.set_corner_radius_all(28)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	root.add_child(shadow)

	var pill := create_gradient_pill()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.clip_contents = true
	root.add_child(pill)

	var icon_wrap := Control.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.z_index = 2
	root.add_child(icon_wrap)

	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 0
	icon.offset_top = 0
	icon.offset_right = 0
	icon.offset_bottom = 0
	icon_wrap.add_child(icon)

	var count: Label = null
	if with_icon_count:
		count = Label.new()
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if LogoFont != null:
			count.add_theme_font_override("font", LogoFont)
		count.add_theme_color_override("font_color", LIFE_COUNT_COLOR)
		count.add_theme_color_override("font_outline_color", LIFE_COUNT_OUTLINE)
		count.add_theme_constant_override("outline_size", 6)
		count.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_wrap.add_child(count)

	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if LogoFont != null:
		value.add_theme_font_override("font", LogoFont)
	value.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	value.add_theme_color_override("font_outline_color", BTN_TEXT_OUTLINE)
	value.add_theme_constant_override("outline_size", 4)
	value.z_index = 1
	root.add_child(value)

	var plus := Button.new()
	plus.text = "+"
	plus.focus_mode = Control.FOCUS_NONE
	plus.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plus.z_index = 3
	plus.add_theme_color_override("font_color", Color.WHITE)
	plus.add_theme_color_override("font_hover_color", Color.WHITE)
	plus.add_theme_color_override("font_pressed_color", Color.WHITE)
	root.add_child(plus)

	return {
		"root": root,
		"shadow": shadow,
		"pill": pill,
		"icon": icon,
		"heart": icon_wrap,
		"count": count,
		"label": value,
		"plus": plus,
		"panel": root,
	}

static func resource_chip_hang(
	row_h: float,
	pill_height_ratio: float = RESOURCE_PILL_HEIGHT_RATIO,
	icon_height_ratio: float = RESOURCE_ICON_HEIGHT_RATIO
) -> float:
	return (row_h * pill_height_ratio * icon_height_ratio) * RESOURCE_ICON_HANG

static func resource_chip_visual_width(
	row_h: float,
	pill_w: float,
	pill_height_ratio: float = RESOURCE_PILL_HEIGHT_RATIO,
	icon_height_ratio: float = RESOURCE_ICON_HEIGHT_RATIO
) -> float:
	return resource_chip_hang(row_h, pill_height_ratio, icon_height_ratio) + pill_w

static func resource_chip_pair_gap(row_h: float, min_gap: float) -> float:
	return maxf(min_gap, resource_chip_hang(row_h) + row_h * 0.22)

static func layout_resource_chip(
	chip: Dictionary,
	pill_pos: Vector2,
	pill_size: Vector2,
	count_font_ratio: float = 0.36,
	count_font_max: int = 38,
	pill_height_ratio: float = RESOURCE_PILL_HEIGHT_RATIO,
	icon_height_ratio: float = RESOURCE_ICON_HEIGHT_RATIO
) -> void:
	var root: Control = chip.get("root", chip.get("panel", null))
	if root == null:
		return
	var pill_h: float = pill_size.y * pill_height_ratio
	var pill_w: float = pill_size.x
	var icon_h: float = pill_h * icon_height_ratio
	var hang: float = icon_h * RESOURCE_ICON_HANG
	var root_h: float = icon_h
	var pill_draw := Vector2(pill_w, pill_h)
	root.position = Vector2(pill_pos.x - hang, pill_pos.y + (pill_size.y - pill_h) * 0.5 - (root_h - pill_h) * 0.5)
	root.size = Vector2(pill_w + hang, root_h)

	var pill: Control = chip.get("pill", null)
	var shadow: Panel = chip.get("shadow", null)
	var icon_wrap: Control = chip.get("heart", null)
	var plus: Button = chip.get("plus", null)
	var value: Label = chip.get("label", null)
	var count: Label = chip.get("count", null)

	var pill_local := Vector2(hang, (root_h - pill_h) * 0.5)
	var radius := int(pill_h * 0.5)
	if shadow != null:
		var shadow_off := Vector2(0.0, maxf(3.0, pill_h * 0.08))
		shadow.position = pill_local + shadow_off
		shadow.size = pill_draw
		apply_shadow_corner_radius(shadow, radius)
	if pill != null:
		pill.position = pill_local
		pill.size = pill_draw
		apply_gradient_pill_style(pill, radius, pill_draw)

	if icon_wrap != null:
		icon_wrap.clip_contents = true
		icon_wrap.position = Vector2(0.0, 0.0)
		icon_wrap.size = Vector2(icon_h, icon_h)
		layout_life_heart_badge(icon_wrap, count, icon_h, count_font_ratio, count_font_max)

	if plus != null:
		var plus_s: float = clampf(icon_h * 0.30, 18.0, 34.0)
		plus.size = Vector2(plus_s, plus_s)
		plus.position = Vector2(icon_h * 0.62, icon_h * 0.64)
		var plus_r := int(clampf(plus_s * 0.22, 4.0, 8.0))
		var plus_style := StyleBoxFlat.new()
		plus_style.bg_color = RESOURCE_PLUS_BG
		plus_style.border_color = RESOURCE_PLUS_BORDER
		plus_style.set_border_width_all(1)
		plus_style.set_corner_radius_all(plus_r)
		plus.add_theme_stylebox_override("normal", plus_style)
		var plus_hover := plus_style.duplicate() as StyleBoxFlat
		plus_hover.bg_color = RESOURCE_PLUS_BG.lightened(0.08)
		plus.add_theme_stylebox_override("hover", plus_hover)
		var plus_pressed := plus_style.duplicate() as StyleBoxFlat
		plus_pressed.bg_color = RESOURCE_PLUS_BG.darkened(0.08)
		plus.add_theme_stylebox_override("pressed", plus_pressed)
		plus.add_theme_font_size_override("font_size", int(plus_s * 0.72))

	if value != null:
		var text_left: float = icon_h * 0.86
		var right_pad: float = maxf(pill_h * 0.38, 12.0)
		var text_w: float = maxf(36.0, (hang + pill_w) - text_left - right_pad)
		value.position = Vector2(text_left, pill_local.y)
		value.size = Vector2(text_w, pill_h)
		value.clip_text = true
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var desired_font := int(clampf(pill_h * 0.60, 18.0, 42.0))
		value.set_meta("fit_max_w", text_w)
		value.set_meta("fit_desired", desired_font)
		fit_resource_value_label(value)


static func fit_resource_value_label(label: Label) -> void:
	if label == null:
		return
	label.clip_text = true
	var max_w: float = float(label.get_meta("fit_max_w", label.size.x))
	if max_w <= 1.0:
		max_w = label.size.x
	var desired: int = int(label.get_meta("fit_desired", 32))
	var font: Font = label.get_theme_font("font")
	if font == null:
		label.add_theme_font_size_override("font_size", desired)
		return
	var sample := label.text
	if sample.is_empty():
		sample = "000.000"
	var outline := float(label.get_theme_constant("outline_size"))
	var font_size := desired
	var min_size := 14
	while font_size > min_size:
		var measured := font.get_string_size(sample, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if measured.x + outline * 2.0 + 2.0 <= max_w:
			break
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)


static func set_resource_chip_value(chip: Dictionary, text: String) -> void:
	var value: Label = chip.get("label", null)
	if value == null:
		return
	value.text = text
	fit_resource_value_label(value)

static func create_button_label(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if LogoFont != null:
		lbl.add_theme_font_override("font", LogoFont)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	lbl.add_theme_color_override("font_outline_color", BTN_TEXT_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 4)
	return lbl

static func create_round_icon(icon_texture: Texture2D) -> TextureButton:
	var btn := create_base(RoundButtonTexture)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(center)

	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)

	btn.set_meta("chip_icon", icon)
	return btn

static func create_round_symbol(symbol: String, font_size: int) -> TextureButton:
	var btn := create_base(RoundButtonTexture)
	var lbl := create_button_label(symbol, font_size)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(lbl)
	btn.set_meta("chip_label", lbl)
	return btn

static func create_long_icon_text(icon_texture: Texture2D, text: String, font_size: int = CHIP_STAT_FONT_SIZE) -> TextureButton:
	var btn := create_base(LongButtonTexture)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(center)

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

	var lbl := create_chip_stat_label(text, font_size)
	row.add_child(lbl)

	btn.set_meta("chip_label", lbl)
	btn.set_meta("chip_icon", icon)
	return btn

static func create_play_pastel() -> TextureButton:
	return create_base(PlayPastelButtonTexture)

static func create_play() -> TextureButton:
	return create_base(PlayButtonTexture)

static func create_long_text(text: String, font_size: int) -> TextureButton:
	var btn := create_base(LongButtonTexture)
	var lbl := create_button_label(text, font_size)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(lbl)
	btn.set_meta("chip_label", lbl)
	return btn

static func apply_content_layout(btn: TextureButton, size: Vector2, icon_size_ratio: float = -1.0) -> void:
	if not btn.has_meta("chip_icon"):
		return
	var icon: TextureRect = btn.get_meta("chip_icon")
	if icon == null:
		return
	var ratio := icon_size_ratio
	if ratio < 0.0:
		ratio = LONG_CHIP_ICON_SIZE_RATIO if btn.has_meta("chip_label") else ROUND_ICON_SIZE_RATIO
	var icon_size := size.y * ratio
	icon.custom_minimum_size = Vector2(icon_size, icon_size)

static func apply_label_font(btn: TextureButton, font_size: int) -> void:
	if btn == null or not btn.has_meta("chip_label"):
		return
	var lbl: Label = btn.get_meta("chip_label")
	if lbl != null:
		lbl.add_theme_font_size_override("font_size", font_size)

static func apply_chip_stat_style(
	btn: TextureButton,
	font_size: int,
	color: Color = CHIP_STAT_COLOR,
	outline: Color = CHIP_STAT_OUTLINE,
	outline_size: int = CHIP_STAT_OUTLINE_SIZE
) -> void:
	if btn == null or not btn.has_meta("chip_label"):
		return
	var lbl: Label = btn.get_meta("chip_label")
	if lbl == null:
		return
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", outline)
	lbl.add_theme_constant_override("outline_size", outline_size)

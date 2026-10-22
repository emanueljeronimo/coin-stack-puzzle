extends Area2D

const GameRulesScript = preload("res://game_rules.gd")
const CoinWildcardShader = preload("res://coin_wildcard.gdshader")
const CoinNumberFont = preload("res://Fonts/Chewy-Regular.ttf")
const CoinFaceTexture = preload("res://Imagenes/ficha.png")
const WildcardFaceTexture = preload("res://Imagenes/ficha-comodin.png")
const CoinNumberMarkScript = preload("res://coin_number_mark.gd")

var value: int = 1
var number_visible: bool = true

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight_sprite: Sprite2D = $HighlightSprite
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

## Paleta pastel con matices redistribuidos para mejor distinción.
const VALUE_COLORS := [
	Color(0.95, 0.45, 0.55), # 1  blush
	Color(0.25, 0.75, 0.40), # 2  verde
	Color(0.55, 0.35, 0.85), # 3  violeta
	Color(0.90, 0.65, 0.50), # 4  durazno (bajado)
	Color(0.25, 0.85, 0.80), # 5  aqua
	Color(0.75, 0.30, 0.75), # 6  rosa violeta
	Color(0.65, 0.85, 0.25), # 7  lima
	Color(0.30, 0.55, 0.90), # 8  azul
	Color(0.95, 0.85, 0.35), # 9  amarillo trigo
	Color(0.55, 0.70, 0.55), # 10 salvia
	Color(0.90, 0.50, 0.15), # 11 naranja
	Color(0.75, 0.70, 0.95), # 12 lavanda
	Color(0.22, 0.62, 0.70), # 13 teal
	Color(0.95, 0.75, 0.85), # 14 rosa claro
	Color(0.92, 0.92, 0.95), # 15 gris claro 
]

const PASTEL_SOFTEN := 0.14
## Aclarado mínimo al aplicar color (la textura gris ya oscurece un poco).
const COIN_TINT_LIGHTEN := 0.04
const SHADOW_ALPHA := 0.09
const HIGHLIGHT_ALPHA := 0.14
const COIN_RADIUS := 26.0
const NUMBER_TO_DIAMETER := 0.55
const NUMBER_OUTLINE_DARKEN := 0.50
const NUMBER_WIDTH_SCALE := 0.76
const NUMBER_NUDGE_X := 0.0
## El HTML usa 0.05 por metricas de canvas; en Godot ese valor baja de mas el digito.
const NUMBER_NUDGE_Y := 0.0
const NUMBER_FILL_COLOR := Color(1.0, 0.99, 1.0, 0.98)
const FACE_SCALE := 0.86
var coin_color: Color = VALUE_COLORS[0]
var is_wildcard := false
var wildcard_original_row := -1
var _transform_tween: Tween = null
var _number_font: FontVariation = null
var _number_root = null

func _ready() -> void:
	input_pickable = false
	monitoring = false
	monitorable = false
	configure_sprite_scale()
	if label:
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.queue_free()
		label = null
	_ensure_number_font()
	_ensure_number_root()
	configure_collision()
	update_display()

func _ensure_number_root() -> void:
	if _number_root != null and is_instance_valid(_number_root):
		_attach_number_root()
		return
	if sprite == null:
		return
	_number_root = CoinNumberMarkScript.new()
	_number_root.name = "NumberRoot"
	_number_root.z_index = 5
	sprite.add_child(_number_root)

func _attach_number_root() -> void:
	if _number_root == null or sprite == null:
		return
	if _number_root.get_parent() == sprite:
		return
	if _number_root.get_parent() != null:
		_number_root.reparent(sprite, false)
	else:
		sprite.add_child(_number_root)

func _ensure_number_font() -> void:
	if _number_font != null:
		return
	var base: Font = CoinNumberFont
	if base == null:
		base = ThemeDB.fallback_font
	_number_font = FontVariation.new()
	_number_font.base_font = base

func _number_tex_side() -> float:
	var side: float = CoinNumberMarkScript.texture_side(sprite.texture if sprite else null)
	if side > 0.0:
		return side
	return CoinNumberMarkScript.face_side(COIN_RADIUS, FACE_SCALE)

func _refresh_number_mark() -> void:
	_ensure_number_font()
	_ensure_number_root()
	if _number_root == null:
		return
	if is_wildcard or not number_visible:
		_number_root.configure(
			"",
			_number_font,
			8,
			2,
			Color.BLACK,
			NUMBER_FILL_COLOR,
			NUMBER_WIDTH_SCALE,
			Vector2.ZERO,
			false
		)
		return
	var side: float = _number_tex_side()
	var font_size: int = CoinNumberMarkScript.font_size_for_side(side, NUMBER_TO_DIAMETER)
	_number_root.configure(
		str(value),
		_number_font,
		font_size,
		CoinNumberMarkScript.outline_px_for_side(side),
		get_number_outline_color(coin_color),
		NUMBER_FILL_COLOR,
		NUMBER_WIDTH_SCALE,
		Vector2(side * NUMBER_NUDGE_X, side * NUMBER_NUDGE_Y),
		true
	)

func update_display() -> void:
	apply_color_by_value()
	_sync_center_mark()

func set_value(new_value: int) -> void:
	value = new_value
	update_display()

func is_wildcard_coin() -> bool:
	return is_wildcard

func make_wildcard(origin_row: int) -> void:
	is_wildcard = true
	wildcard_original_row = origin_row
	value = GameRulesScript.COIN_WILDCARD_VALUE
	update_display()

func transform_wildcard(new_value: int) -> void:
	if not is_wildcard:
		return
	is_wildcard = false
	wildcard_original_row = -1
	set_value(new_value)
	_play_transform_punch()

func _play_transform_punch() -> void:
	if not is_inside_tree():
		return
	if _transform_tween != null and _transform_tween.is_valid():
		_transform_tween.kill()
	var base_sc := scale
	_transform_tween = create_tween()
	_transform_tween.set_trans(Tween.TRANS_SINE)
	_transform_tween.set_ease(Tween.EASE_OUT)
	_transform_tween.tween_property(self, "scale", base_sc * 1.10, 0.08)
	_transform_tween.tween_property(self, "scale", base_sc * 0.96, 0.07)
	_transform_tween.tween_property(self, "scale", base_sc, 0.08)

func get_color_for_value(v: int) -> Color:
	if v <= 0:
		return Color.WHITE
	var idx := (v - 1) % VALUE_COLORS.size()
	return VALUE_COLORS[idx].lerp(Color.WHITE, PASTEL_SOFTEN)

func get_sprite_tint(base: Color) -> Color:
	return base.lightened(COIN_TINT_LIGHTEN)

func get_shadow_tint(base: Color) -> Color:
	var tinted := base.darkened(0.22).lerp(Color(0.72, 0.55, 0.64), 0.25)
	tinted.a = SHADOW_ALPHA
	return tinted

func get_number_outline_color(base: Color) -> Color:
	return CoinNumberMarkScript.outline_from_tint(get_sprite_tint(base), NUMBER_OUTLINE_DARKEN)

func apply_color_by_value() -> void:
	if is_wildcard:
		_set_face_texture(WildcardFaceTexture)
		_ensure_wildcard_material()
		coin_color = Color.WHITE
		if sprite:
			sprite.self_modulate = Color.WHITE
		if shadow_sprite:
			shadow_sprite.self_modulate = get_shadow_tint(Color(0.86, 0.68, 0.28))
		if highlight_sprite:
			highlight_sprite.visible = false
		return
	_set_face_texture(CoinFaceTexture)
	_clear_wildcard_material()
	coin_color = get_color_for_value(value)
	if sprite:
		sprite.self_modulate = get_sprite_tint(coin_color)
	if shadow_sprite:
		shadow_sprite.self_modulate = get_shadow_tint(coin_color)
	if highlight_sprite:
		highlight_sprite.visible = true
		highlight_sprite.self_modulate = Color(1.0, 1.0, 1.0, HIGHLIGHT_ALPHA)

func set_number_visible(visible: bool) -> void:
	number_visible = visible
	_sync_center_mark()

func configure_collision() -> void:
	if collision_shape == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = COIN_RADIUS
	collision_shape.shape = circle

func configure_sprite_scale() -> void:
	if sprite == null or sprite.texture == null:
		return
	var tex_size: Vector2 = sprite.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var target_diameter := COIN_RADIUS * 2.0 * FACE_SCALE
	var scale_factor := target_diameter / maxf(tex_size.x, tex_size.y)
	var final_scale := Vector2.ONE * scale_factor
	sprite.scale = final_scale
	if shadow_sprite:
		shadow_sprite.scale = final_scale * 0.98
	if highlight_sprite:
		highlight_sprite.scale = final_scale

func _sync_center_mark() -> void:
	if label != null:
		label.visible = false
	_refresh_number_mark()


func _set_face_texture(face: Texture2D) -> void:
	if face == null:
		return
	if sprite and sprite.texture != face:
		sprite.texture = face
	if shadow_sprite and shadow_sprite.texture != face:
		shadow_sprite.texture = face
	if highlight_sprite and highlight_sprite.texture != face:
		highlight_sprite.texture = face
	configure_sprite_scale()


func _ensure_wildcard_material() -> void:
	if sprite == null:
		return
	var mat := sprite.material as ShaderMaterial
	if mat != null and mat.shader == CoinWildcardShader:
		return
	mat = ShaderMaterial.new()
	mat.shader = CoinWildcardShader
	sprite.material = mat

func _clear_wildcard_material() -> void:
	if sprite == null:
		return
	var mat := sprite.material as ShaderMaterial
	if mat != null and mat.shader == CoinWildcardShader:
		sprite.material = null

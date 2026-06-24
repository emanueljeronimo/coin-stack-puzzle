extends Area2D

var value: int = 1
var number_visible: bool = true

@onready var shadow_sprite = $ShadowSprite
@onready var sprite = $Sprite2D
@onready var highlight_sprite = $HighlightSprite
@onready var label = $Label
@onready var collision_shape = $CollisionShape2D

## Paleta pastel con color visible (suavizada ~15% hacia blanco).
const VALUE_COLORS := [
	Color(0.96, 0.70, 0.72), # 1  blush
	Color(0.62, 0.76, 0.96), # 7  azul
	Color(0.99, 0.94, 0.70), # 3  amarillo pastel (mantequilla)
	Color(0.78, 0.66, 0.94), # 8  violeta
	Color(0.62, 0.88, 0.70), # 5  verde
	Color(0.96, 0.74, 0.58), # 9  naranja
	Color(0.58, 0.88, 0.84), # 6  aqua
	Color(0.92, 0.66, 0.90), # 10 rosa violeta
	Color(0.78, 0.90, 0.62), # 4  lima
	Color(0.94, 0.66, 0.78), # 11 rosa
	Color(0.92, 0.78, 0.66), # 13 trigo
	Color(0.72, 0.68, 0.94), # 14 lavanda
	Color(0.96, 0.74, 0.66), # 2  durazno
	Color(0.68, 0.86, 0.68), # 12 salvia
	Color(0.88, 0.86, 0.88), # 15 gris lavanda
]
const PASTEL_SOFTEN := 0.14
## Aclarado mínimo al aplicar color (la textura gris ya oscurece un poco).
const COIN_TINT_LIGHTEN := 0.04
const SHADOW_ALPHA := 0.09
const HIGHLIGHT_ALPHA := 0.14
const COIN_RADIUS := 26.0
var coin_color: Color = VALUE_COLORS[0]

func _ready() -> void:
	input_pickable = false
	configure_sprite_scale()
	if label:
		label.z_index = 5
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-26, -26)
		label.size = Vector2(52, 52)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1.0, 0.99, 1.0, 0.98))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", Color(0.52, 0.38, 0.46, 0.55))
	else:
		print("ERROR: No se encontró el Label en coin.tscn")
	configure_collision()
	update_display()

func update_display() -> void:
	apply_color_by_value()
	if label:
		label.text = str(value)
		label.visible = number_visible

func set_value(new_value: int) -> void:
	value = new_value
	update_display()

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

func apply_color_by_value() -> void:
	coin_color = get_color_for_value(value)
	if sprite:
		sprite.self_modulate = get_sprite_tint(coin_color)
	if shadow_sprite:
		shadow_sprite.self_modulate = get_shadow_tint(coin_color)
	if highlight_sprite:
		highlight_sprite.self_modulate = Color(1.0, 1.0, 1.0, HIGHLIGHT_ALPHA)
	if label:
		var outline := coin_color.darkened(0.50)
		outline.a = 0.50
		label.add_theme_color_override("font_outline_color", outline)

func set_number_visible(visible: bool) -> void:
	number_visible = visible
	if label:
		label.visible = number_visible

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
	var target_diameter := COIN_RADIUS * 2.0
	var scale_factor := target_diameter / maxf(tex_size.x, tex_size.y)
	var final_scale := Vector2.ONE * scale_factor
	sprite.scale = final_scale
	if shadow_sprite:
		shadow_sprite.scale = final_scale * 0.98
	if highlight_sprite:
		highlight_sprite.scale = final_scale

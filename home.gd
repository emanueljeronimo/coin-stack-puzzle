extends Control

const CoverTexture = preload("res://Imagenes/prototipo 1 portada.png")
const PlayButtonTexture = preload("res://Imagenes/boton-jugar_ahora.png")
const LobbyScenePath := "res://Lobby.tscn"

const REF_WIDTH := 1080.0

## Botón Jugar — imagen sobre la portada.
const PLAY_WIDTH_RATIO := 0.46
const PLAY_BOTTOM_MARGIN := 0.0
const PLAY_Y_DROP := 58.0
const PLAY_VISIBLE_HEIGHT := 0.86

var background_rect: TextureRect = null
var play_button: TextureButton = null

func _ready() -> void:
	_apply_portrait_orientation()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_ui()
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	layout_ui()

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

func _on_viewport_resized() -> void:
	layout_ui()

func _on_play_pressed() -> void:
	SceneLoader.go_to(LobbyScenePath)

func _on_play_button_down() -> void:
	if play_button != null:
		play_button.scale = Vector2(0.96, 0.96)

func _on_play_button_up() -> void:
	if play_button != null:
		play_button.scale = Vector2.ONE

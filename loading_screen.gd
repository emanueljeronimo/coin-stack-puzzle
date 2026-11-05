extends Control

const BootCoverTexture := preload("res://Imagenes/portada-nueva2.png")
const TransitCoverTexture := preload("res://Imagenes/home-nueva.png")
const UiFont := preload("res://Fonts/Lobster-Regular.ttf")
const BootCoverLayoutServiceScript := preload("res://boot_cover_layout_service.gd")
const LoadingProgressServiceScript := preload("res://loading_progress_service.gd")
const LoadingBarRainbowShader := preload("res://loading_bar_rainbow.gdshader")

const REF_WIDTH := 1080.0
const PROGRESS_TRACK_BG := Color(0.36, 0.30, 0.46, 0.94)
const PROGRESS_TRACK_BORDER := Color(0.0, 0.0, 0.0, 1.0)
const PROGRESS_TRACK_BORDER_W := 2
const PROGRESS_TEXT := Color(0.44, 0.36, 0.58)
const PROGRESS_LABEL_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const PROGRESS_LABEL_OUTLINE := Color(0.0, 0.0, 0.0, 1.0)
const PROGRESS_LABEL_SHADOW := Color(0.0, 0.0, 0.0, 0.72)
## Transito lobby/tablero: barra cerca de donde esta Jugar ahora.
const TRANSIT_BAR_BOTTOM_MARGIN := 88.0

const BOOT_WARMUP_PRELOADS: Array[String] = [
	"res://Imagenes/home-nueva.png",
	"res://Imagenes/boton-nuevo.png",
	"res://Fonts/Lobster-Regular.ttf",
	"res://stack.tscn",
]

var _target_scene_path: String = ""
var _loading_message: String = "Cargando"
var _is_boot := false
var _display_progress: float = 0.0
var _target_progress: float = 0.0
var _load_started := false
var _scene_ready := false
var _scene_loaded := false
var _load_wait_sec: float = 0.0
const LOAD_TIMEOUT_SEC := 12.0

var background_rect: TextureRect = null
var status_label: Label = null
var progress_container: Panel = null
var fill_clip: Control = null
var progress_fill: ColorRect = null
var shimmer_band: ColorRect = null
var progress_bar_max_width: float = 0.0
var progress_bar_height: float = 0.0


func _ready() -> void:
	_apply_portrait_orientation()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_boot = SceneLoader.consume_is_boot()
	_target_scene_path = SceneLoader.consume_pending_scene()
	_loading_message = SceneLoader.consume_pending_message()
	build_ui()
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	layout_ui()
	_start_loading()


func _apply_portrait_orientation() -> void:
	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		return
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)


func build_ui() -> void:
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.texture = BootCoverTexture if _is_boot else TransitCoverTexture
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)

	status_label = Label.new()
	status_label.text = _loading_message
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UiFont != null:
		status_label.add_theme_font_override("font", UiFont)
	_apply_status_label_style(1.0)
	add_child(status_label)

	progress_container = _create_panel(
		PROGRESS_TRACK_BG,
		PROGRESS_TRACK_BORDER,
		24,
		PROGRESS_TRACK_BORDER_W
	)
	progress_container.clip_contents = true
	add_child(progress_container)

	fill_clip = Control.new()
	fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_clip.clip_contents = true
	progress_container.add_child(fill_clip)

	progress_fill = ColorRect.new()
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_mat := ShaderMaterial.new()
	fill_mat.shader = LoadingBarRainbowShader
	progress_fill.material = fill_mat
	fill_clip.add_child(progress_fill)

	shimmer_band = ColorRect.new()
	shimmer_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shimmer_band.color = Color(1.0, 1.0, 1.0, 0.28)
	fill_clip.add_child(shimmer_band)


func _apply_status_label_style(ui_scale: float) -> void:
	if status_label == null:
		return
	var s: float = maxf(ui_scale, 0.5)
	status_label.add_theme_color_override("font_color", PROGRESS_LABEL_COLOR)
	status_label.add_theme_color_override("font_outline_color", PROGRESS_LABEL_OUTLINE)
	status_label.add_theme_constant_override("outline_size", int(round(8.0 * s)))
	status_label.add_theme_color_override("font_shadow_color", PROGRESS_LABEL_SHADOW)
	status_label.add_theme_constant_override("shadow_offset_x", int(round(2.0 * s)))
	status_label.add_theme_constant_override("shadow_offset_y", int(round(4.0 * s)))
	status_label.add_theme_constant_override("shadow_outline_size", int(round(4.0 * s)))


func _create_panel(bg: Color, border: Color, radius: int, border_w: int = 2) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(float(border_w))
	panel.add_theme_stylebox_override("panel", style)
	return panel


func layout_ui() -> void:
	var viewport_size := get_viewport_rect().size
	var scale := viewport_size.x / REF_WIDTH
	var progress_w: float = minf(viewport_size.x * 0.82, 860.0 * scale)
	var progress_h: float = 36.0 * scale
	var progress_x: float = (viewport_size.x - progress_w) * 0.5
	var progress_y: float = viewport_size.y - progress_h - TRANSIT_BAR_BOTTOM_MARGIN * scale
	if _is_boot:
		var tex_size := Vector2(1080, 1920)
		if background_rect != null and background_rect.texture != null:
			tex_size = background_rect.texture.get_size()
		var cover: Rect2 = BootCoverLayoutServiceScript.cover_draw_rect(viewport_size, tex_size)
		var slot: Rect2 = BootCoverLayoutServiceScript.play_slot_rect(
			viewport_size,
			cover,
			BootCoverLayoutServiceScript.default_slot_size(cover.size.x)
		)
		progress_w = slot.size.x
		progress_h = 32.0 * scale
		progress_x = slot.position.x
		progress_y = slot.position.y + slot.size.y - progress_h
		if status_label != null:
			var label_h: float = maxf(slot.size.y - progress_h - 8.0 * scale, 56.0 * scale)
			status_label.position = Vector2(slot.position.x, slot.position.y)
			status_label.size = Vector2(slot.size.x, label_h)
			status_label.add_theme_font_size_override("font_size", int(64.0 * scale))
			_apply_status_label_style(scale)
	else:
		if status_label != null:
			var label_h := 80.0 * scale
			status_label.position = Vector2(progress_x, progress_y - label_h - 12.0 * scale)
			status_label.size = Vector2(progress_w, label_h)
			status_label.add_theme_font_size_override("font_size", int(56.0 * scale))
			_apply_status_label_style(scale)

	var border_w: float = float(PROGRESS_TRACK_BORDER_W)
	var inner_w: float = maxf(progress_w - border_w * 2.0, 4.0)
	var inner_h: float = maxf(progress_h - border_w * 2.0, 4.0)
	progress_bar_max_width = inner_w
	progress_bar_height = inner_h
	progress_container.position = Vector2(progress_x, progress_y)
	progress_container.size = Vector2(progress_w, progress_h)
	if fill_clip != null:
		fill_clip.position = Vector2(border_w, border_w)
	if progress_fill != null:
		progress_fill.position = Vector2.ZERO
		progress_fill.size = Vector2(inner_w, inner_h)
	_update_progress_visual()


func _on_viewport_resized() -> void:
	layout_ui()


func _start_loading() -> void:
	_warmup_boot_resources()
	var err := ResourceLoader.load_threaded_request(_target_scene_path)
	if err != OK:
		push_error("LoadingScreen: no se pudo iniciar carga de %s (err %d)" % [_target_scene_path, err])
		get_tree().change_scene_to_file(_target_scene_path)
		return
	_load_started = true


func _warmup_boot_resources() -> void:
	for path in BOOT_WARMUP_PRELOADS:
		if ResourceLoader.exists(path):
			ResourceLoader.load(path)
	_target_progress = maxf(
		_target_progress,
		LoadingProgressServiceScript.START_TARGET
	)
	_update_progress_visual()


func _process(delta: float) -> void:
	if not _load_started or _scene_ready:
		return

	_load_wait_sec += delta
	if _load_wait_sec >= LOAD_TIMEOUT_SEC:
		push_warning("LoadingScreen: timeout, forzando cambio a %s" % _target_scene_path)
		_force_go_to_target_scene()
		return

	var progress_array: Array = []
	var status := ResourceLoader.load_threaded_get_status(_target_scene_path, progress_array)
	var load_ratio: float = 0.0
	if progress_array.size() > 0:
		load_ratio = float(progress_array[0])

	match status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			push_error("LoadingScreen: falló la carga de %s" % _target_scene_path)
			_force_go_to_target_scene()
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			_scene_loaded = true
		_:
			pass

	_target_progress = LoadingProgressServiceScript.next_target(
		_target_progress,
		load_ratio,
		delta,
		_scene_loaded
	)
	_display_progress = LoadingProgressServiceScript.step_display(
		_display_progress,
		_target_progress,
		delta
	)
	_update_progress_visual()
	if LoadingProgressServiceScript.can_finish(_scene_loaded, _display_progress):
		_finish_loading()


func _finish_loading() -> void:
	if _scene_ready:
		return
	_scene_ready = true
	var packed: Variant = ResourceLoader.load_threaded_get(_target_scene_path)
	if packed is PackedScene:
		get_tree().call_deferred("change_scene_to_packed", packed)
		return
	_force_go_to_target_scene()


func _force_go_to_target_scene() -> void:
	if _scene_ready:
		return
	_scene_ready = true
	get_tree().call_deferred("change_scene_to_file", _target_scene_path)


func _update_progress_visual() -> void:
	if fill_clip == null or progress_bar_max_width <= 0.0:
		return
	var pct := clampf(_display_progress, 0.0, 1.0)
	var fill_w := progress_bar_max_width * pct
	fill_clip.size = Vector2(fill_w, progress_bar_height)
	if shimmer_band == null:
		return
	var band_w: float = maxf(progress_bar_height * 1.6, 36.0)
	shimmer_band.size = Vector2(band_w, progress_bar_height)
	shimmer_band.position = Vector2(
		LoadingProgressServiceScript.shimmer_x(_load_wait_sec, fill_w, band_w),
		0.0
	)

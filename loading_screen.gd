extends Control

const CoverTexture := preload("res://Imagenes/home-2.png")
const UiFont := preload("res://Fonts/Chewy-Regular.ttf")
const SlotOverlayBgScript := preload("res://slot_overlay_bg.gd")

const REF_WIDTH := 1080.0
const PROGRESS_TRACK_BG := Color(0.84, 0.80, 0.96, 0.92)
const PROGRESS_TRACK_BORDER := Color(0.72, 0.66, 0.88, 0.88)
const PROGRESS_TEXT := Color(0.44, 0.36, 0.58)
const PROGRESS_LABEL_COLOR := Color(0.98, 0.99, 0.95)
const PROGRESS_LABEL_OUTLINE := Color(0.16, 0.38, 0.20)

const BOOT_WARMUP_PRELOADS: Array[String] = [
	"res://Imagenes/home-2.png",
	"res://Imagenes/boton-jugar_ahora.png",
	"res://Fonts/Chewy-Regular.ttf",
	"res://stack.tscn",
]

var _target_scene_path: String = ""
var _loading_message: String = "Cargando"
var _display_progress: float = 0.0
var _target_progress: float = 0.0
var _load_started := false
var _scene_ready := false
var _load_wait_sec: float = 0.0
const LOAD_TIMEOUT_SEC := 12.0

var background_rect: TextureRect = null
var status_label: Label = null
var progress_container: Panel = null
var progress_fill: TextureRect = null
var progress_bar_max_width: float = 0.0
var progress_bar_height: float = 0.0


func _ready() -> void:
	_apply_portrait_orientation()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	background_rect.texture = CoverTexture
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
	status_label.add_theme_font_size_override("font_size", 56)
	status_label.add_theme_color_override("font_color", PROGRESS_LABEL_COLOR)
	status_label.add_theme_color_override("font_outline_color", PROGRESS_LABEL_OUTLINE)
	status_label.add_theme_constant_override("outline_size", 5)
	add_child(status_label)

	progress_container = _create_panel(PROGRESS_TRACK_BG, PROGRESS_TRACK_BORDER, 24)
	progress_container.clip_contents = true
	add_child(progress_container)

	progress_fill = SlotOverlayBgScript.new()
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_container.add_child(progress_fill)


func _create_panel(bg: Color, border: Color, radius: int) -> Panel:
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


func layout_ui() -> void:
	var viewport_size := get_viewport_rect().size
	var scale := viewport_size.x / REF_WIDTH
	var progress_w := minf(viewport_size.x * 0.82, 860.0 * scale)
	var progress_h := 36.0 * scale
	progress_bar_max_width = progress_w
	progress_bar_height = progress_h
	var progress_x := (viewport_size.x - progress_w) * 0.5
	var progress_y := viewport_size.y * 0.72

	progress_container.position = Vector2(progress_x, progress_y)
	progress_container.size = Vector2(progress_w, progress_h)

	if status_label != null:
		var label_h := 80.0 * scale
		status_label.position = Vector2(progress_x, progress_y - label_h - 12.0 * scale)
		status_label.size = Vector2(progress_w, label_h)
		status_label.add_theme_font_size_override("font_size", int(56.0 * scale))

	_update_progress_visual(false)


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
	_target_progress = maxf(_target_progress, 0.12)
	_display_progress = _target_progress
	_update_progress_visual(false)


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
		ResourceLoader.THREAD_LOAD_LOADED:
			_display_progress = 1.0
			_update_progress_visual(false)
			_finish_loading()
		_:
			_target_progress = clampf(0.15 + load_ratio * 0.85, _target_progress, 0.95)
			_display_progress = move_toward(_display_progress, _target_progress, delta * 1.8)
			_update_progress_visual(true)


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


func _update_progress_visual(_animated: bool) -> void:
	if progress_fill == null or progress_bar_max_width <= 0.0:
		return
	var pct := clampf(_display_progress, 0.0, 1.0)
	var fill_w := progress_bar_max_width * pct
	progress_fill.size = Vector2(fill_w, progress_bar_height)
	if progress_fill.has_method("configure"):
		var radius := int(maxi(progress_bar_height * 0.45, 6.0))
		progress_fill.configure(
			radius,
			HudTextureButtons.PILL_GRAD_CELESTE,
			HudTextureButtons.PILL_GRAD_ROSA,
			HudTextureButtons.PILL_GRAD_VERDE,
			Vector2(fill_w, progress_bar_height)
		)

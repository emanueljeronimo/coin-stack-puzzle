extends Node

signal background_theme_changed(theme_id: String)
signal music_enabled_changed(enabled: bool)
signal lives_changed

const GameLivesServiceScript = preload("res://game_lives_service.gd")

## Recursos del jugador compartidos entre Lobby y partida.
const INITIAL_LIVES := 5
const INITIAL_STARS := 100000
const INITIAL_GEMS := 756

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_BACKGROUND_THEME_ID := "fondo2-verde"
const BOARD_MUSIC_PATH := "res://musica/musica tablero.mp3"

const BACKGROUND_THEMES: Array = [
	{"id": "fonde2-rosa", "path": "res://Imagenes/fonde2-rosa.png"},
	{"id": "fondo-azul", "path": "res://Imagenes/fondo-azul.png"},
	{"id": "fondo-rosa", "path": "res://Imagenes/fondo-rosa.png"},
	{"id": "fondo-verde", "path": "res://Imagenes/fondo-verde.png"},
	{"id": "fondo2-verde", "path": "res://Imagenes/fondo2-verde.png"},
	{"id": "fondo2-azul", "path": "res://Imagenes/fondo2-azul.png"},
]

## Paletas UI (slots + barra) por familia de fondo.
const UI_PALETTE_ROSA := {
	"slot_fill": Color(0.98, 0.76, 0.86, 0.38),
	"slot_border": Color(0.90, 0.52, 0.70, 0.82),
	"slot_fill_dim": Color(0.98, 0.82, 0.92, 0.20),
	"slot_border_dim": Color(0.84, 0.70, 0.82, 0.50),
	"slot_fill_temp": Color(0.96, 0.78, 0.88, 0.26),
	"slot_border_temp": Color(0.88, 0.58, 0.74, 0.62),
	"progress_track_bg": Color(0.96, 0.82, 0.90, 0.92),
	"progress_track_border": Color(0.88, 0.62, 0.76, 0.88),
	"progress_knob_bg": Color(0.98, 0.88, 0.93, 0.97),
	"progress_knob_border": Color(0.88, 0.64, 0.78, 0.9),
	"progress_text": Color(0.58, 0.32, 0.46),
	"grad_a": Color(0.98, 0.78, 0.88, 0.96),
	"grad_b": Color(0.94, 0.62, 0.78, 0.96),
	"grad_c": Color(0.88, 0.48, 0.68, 0.96),
	"settings_card_bg": Color(0.78, 0.52, 0.64, 0.98),
	"settings_card_border": Color(0.92, 0.72, 0.82, 0.95),
	"settings_title": Color(0.90, 0.84, 0.86),
	"settings_label": Color(0.88, 0.82, 0.84),
	"settings_section": Color(0.86, 0.80, 0.82),
	"settings_btn_on": Color(0.92, 0.58, 0.74, 0.98),
	"settings_btn_off": Color(0.62, 0.42, 0.52, 0.95),
	"settings_btn_border": Color(0.96, 0.78, 0.88, 1.0),
	"settings_option_selected": Color(0.94, 0.70, 0.82, 0.88),
	"settings_option_idle": Color(0.86, 0.62, 0.74, 0.40),
}
const UI_PALETTE_AZUL := {
	"slot_fill": Color(0.72, 0.86, 0.98, 0.38),
	"slot_border": Color(0.42, 0.68, 0.92, 0.82),
	"slot_fill_dim": Color(0.80, 0.90, 0.98, 0.20),
	"slot_border_dim": Color(0.62, 0.78, 0.92, 0.50),
	"slot_fill_temp": Color(0.74, 0.86, 0.96, 0.26),
	"slot_border_temp": Color(0.48, 0.70, 0.90, 0.62),
	"progress_track_bg": Color(0.78, 0.88, 0.98, 0.92),
	"progress_track_border": Color(0.58, 0.74, 0.92, 0.88),
	"progress_knob_bg": Color(0.86, 0.92, 0.99, 0.97),
	"progress_knob_border": Color(0.58, 0.74, 0.90, 0.9),
	"progress_text": Color(0.28, 0.42, 0.62),
	"grad_a": Color(0.72, 0.88, 0.98, 0.96),
	"grad_b": Color(0.52, 0.74, 0.96, 0.96),
	"grad_c": Color(0.38, 0.62, 0.90, 0.96),
	"settings_card_bg": Color(0.42, 0.58, 0.78, 0.98),
	"settings_card_border": Color(0.68, 0.82, 0.96, 0.95),
	"settings_title": Color(0.86, 0.88, 0.92),
	"settings_label": Color(0.82, 0.86, 0.90),
	"settings_section": Color(0.80, 0.84, 0.88),
	"settings_btn_on": Color(0.48, 0.72, 0.94, 0.98),
	"settings_btn_off": Color(0.34, 0.46, 0.62, 0.95),
	"settings_btn_border": Color(0.72, 0.86, 0.98, 1.0),
	"settings_option_selected": Color(0.58, 0.78, 0.96, 0.88),
	"settings_option_idle": Color(0.48, 0.64, 0.82, 0.40),
}
const UI_PALETTE_VERDE := {
	"slot_fill": Color(0.76, 0.92, 0.78, 0.38),
	"slot_border": Color(0.48, 0.78, 0.52, 0.82),
	"slot_fill_dim": Color(0.84, 0.94, 0.86, 0.20),
	"slot_border_dim": Color(0.64, 0.82, 0.68, 0.50),
	"slot_fill_temp": Color(0.78, 0.90, 0.80, 0.26),
	"slot_border_temp": Color(0.52, 0.76, 0.56, 0.62),
	"progress_track_bg": Color(0.80, 0.92, 0.82, 0.92),
	"progress_track_border": Color(0.58, 0.78, 0.62, 0.88),
	"progress_knob_bg": Color(0.88, 0.96, 0.90, 0.97),
	"progress_knob_border": Color(0.58, 0.78, 0.62, 0.9),
	"progress_text": Color(0.28, 0.48, 0.32),
	"grad_a": Color(0.74, 0.92, 0.76, 0.96),
	"grad_b": Color(0.56, 0.84, 0.60, 0.96),
	"grad_c": Color(0.42, 0.72, 0.48, 0.96),
	"settings_card_bg": Color(0.48, 0.62, 0.48, 0.98),
	"settings_card_border": Color(0.68, 0.82, 0.66, 0.95),
	"settings_title": Color(0.88, 0.90, 0.84),
	"settings_label": Color(0.84, 0.88, 0.80),
	"settings_section": Color(0.82, 0.86, 0.78),
	"settings_btn_on": Color(0.58, 0.80, 0.48, 0.98),
	"settings_btn_off": Color(0.40, 0.50, 0.40, 0.95),
	"settings_btn_border": Color(0.75, 0.88, 0.58, 1.0),
	"settings_option_selected": Color(0.68, 0.84, 0.62, 0.88),
	"settings_option_idle": Color(0.54, 0.66, 0.52, 0.40),
}

const UI_PALETTES_BY_THEME := {
	"fonde2-rosa": UI_PALETTE_ROSA,
	"fondo-rosa": UI_PALETTE_ROSA,
	"fondo-azul": UI_PALETTE_AZUL,
	"fondo2-azul": UI_PALETTE_AZUL,
	"fondo-verde": UI_PALETTE_VERDE,
	"fondo2-verde": UI_PALETTE_VERDE,
}

var lives: int = INITIAL_LIVES
var next_free_life_unix: int = 0
var player_stars: int = INITIAL_STARS
var gems: int = INITIAL_GEMS
var player_level: int = 1
var username: String = ""
var checkpoint_snapshot: Dictionary = {}
var background_theme_id: String = DEFAULT_BACKGROUND_THEME_ID
var music_enabled: bool = true
var sounds_enabled: bool = true
var vibration_enabled: bool = true

var _background_textures: Dictionary = {}
var _board_music_player: AudioStreamPlayer = null
var _board_music_active: bool = false
var _life_hud_tick: float = 0.0

func _ready() -> void:
	load_settings()
	_ensure_board_music_player()

func _process(delta: float) -> void:
	if lives >= GameLivesServiceScript.MAX_LIVES:
		_life_hud_tick = 0.0
		return
	_life_hud_tick += delta
	if next_free_life_unix > 0 and _now_unix() >= next_free_life_unix:
		refresh_lives(true)
		_life_hud_tick = 0.0
		return
	if _life_hud_tick >= 1.0:
		_life_hud_tick = 0.0
		lives_changed.emit()

func _now_unix() -> int:
	return int(Time.get_unix_time_from_system())

func get_life_regen_remaining() -> int:
	return GameLivesServiceScript.remaining_seconds(lives, next_free_life_unix, _now_unix())

func get_life_chip_text() -> String:
	return GameLivesServiceScript.format_chip_text(lives, get_life_regen_remaining())

func refresh_lives(persist: bool = false) -> bool:
	var before_lives := lives
	var before_next := next_free_life_unix
	var out := GameLivesServiceScript.catch_up(lives, next_free_life_unix, _now_unix())
	lives = int(out.get("lives", lives))
	next_free_life_unix = int(out.get("next_unix", next_free_life_unix))
	var changed := lives != before_lives or next_free_life_unix != before_next
	if changed:
		lives_changed.emit()
		if persist:
			_persist_lives()
	return changed

func migrate_life_timer(save_mtime: int) -> void:
	var out := GameLivesServiceScript.migrate_missing_timer(lives, _now_unix(), save_mtime)
	lives = int(out.get("lives", lives))
	next_free_life_unix = int(out.get("next_unix", 0))
	lives_changed.emit()

func spend_life() -> bool:
	var out := GameLivesServiceScript.on_spend(lives, next_free_life_unix, _now_unix())
	if not bool(out.get("ok", false)):
		return false
	lives = int(out.get("lives", lives))
	next_free_life_unix = int(out.get("next_unix", next_free_life_unix))
	lives_changed.emit()
	_persist_lives()
	return true

func add_lives(amount: int) -> void:
	var out := GameLivesServiceScript.on_grant(lives, amount, next_free_life_unix, _now_unix())
	lives = int(out.get("lives", lives))
	next_free_life_unix = int(out.get("next_unix", next_free_life_unix))
	lives_changed.emit()
	_persist_lives()

func _persist_lives() -> void:
	if SaveManager == null:
		return
	SaveManager.player_data["lives"] = lives
	SaveManager.player_data["next_free_life_unix"] = next_free_life_unix
	SaveManager.save_game()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	background_theme_id = str(
		cfg.get_value("display", "background_theme_id", DEFAULT_BACKGROUND_THEME_ID)
	)
	if background_theme_id == "forndo2-azul":
		background_theme_id = "fondo2-azul"
	if get_background_theme_path(background_theme_id).is_empty():
		background_theme_id = DEFAULT_BACKGROUND_THEME_ID
	music_enabled = bool(cfg.get_value("audio", "music_enabled", true))
	sounds_enabled = bool(cfg.get_value("audio", "sounds_enabled", true))
	vibration_enabled = bool(cfg.get_value("audio", "vibration_enabled", true))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("display", "background_theme_id", background_theme_id)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "sounds_enabled", sounds_enabled)
	cfg.set_value("audio", "vibration_enabled", vibration_enabled)
	cfg.save(SETTINGS_PATH)

func get_background_themes() -> Array:
	return BACKGROUND_THEMES.duplicate()

func get_background_theme_path(theme_id: String) -> String:
	for theme in BACKGROUND_THEMES:
		if str(theme.get("id", "")) == theme_id:
			return str(theme.get("path", ""))
	return ""

## Colores de slots y barra de progreso según el fondo actual (o el id indicado).
func get_ui_palette(theme_id: String = "") -> Dictionary:
	var id := theme_id if not theme_id.is_empty() else background_theme_id
	if UI_PALETTES_BY_THEME.has(id):
		return (UI_PALETTES_BY_THEME[id] as Dictionary).duplicate()
	if UI_PALETTES_BY_THEME.has(DEFAULT_BACKGROUND_THEME_ID):
		return (UI_PALETTES_BY_THEME[DEFAULT_BACKGROUND_THEME_ID] as Dictionary).duplicate()
	return UI_PALETTE_VERDE.duplicate()

func get_background_theme_texture(theme_id: String = "") -> Texture2D:
	var id := theme_id if not theme_id.is_empty() else background_theme_id
	if _background_textures.has(id):
		return _background_textures[id]
	var path := get_background_theme_path(id)
	if path.is_empty():
		path = get_background_theme_path(DEFAULT_BACKGROUND_THEME_ID)
	var tex := load(path) as Texture2D
	_background_textures[id] = tex
	return tex

func set_background_theme(theme_id: String) -> void:
	if get_background_theme_path(theme_id).is_empty():
		return
	if background_theme_id == theme_id:
		return
	background_theme_id = theme_id
	save_settings()
	background_theme_changed.emit(theme_id)

func set_music_enabled(enabled: bool) -> void:
	if music_enabled == enabled:
		return
	music_enabled = enabled
	save_settings()
	music_enabled_changed.emit(enabled)
	_apply_board_music_playback()

func set_sounds_enabled(enabled: bool) -> void:
	sounds_enabled = enabled
	save_settings()

func set_vibration_enabled(enabled: bool) -> void:
	vibration_enabled = enabled
	save_settings()

## Reproduce la música del tablero en loop mientras hay partida activa.
func start_board_music() -> void:
	_board_music_active = true
	_ensure_board_music_player()
	_apply_board_music_playback()

## Detiene la música del tablero al salir de la partida.
func stop_board_music() -> void:
	_board_music_active = false
	if _board_music_player == null:
		return
	_board_music_player.stream_paused = false
	if _board_music_player.playing:
		_board_music_player.stop()

func _ensure_board_music_player() -> void:
	if _board_music_player != null:
		return
	var stream := load(BOARD_MUSIC_PATH) as AudioStream
	if stream == null:
		push_warning("No se pudo cargar la música del tablero: %s" % BOARD_MUSIC_PATH)
		return
	stream = stream.duplicate()
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_board_music_player = AudioStreamPlayer.new()
	_board_music_player.name = "BoardMusicPlayer"
	_board_music_player.stream = stream
	add_child(_board_music_player)

func _apply_board_music_playback() -> void:
	if _board_music_player == null:
		return
	if _board_music_active and music_enabled:
		if _board_music_player.stream_paused:
			_board_music_player.stream_paused = false
		elif not _board_music_player.playing:
			_board_music_player.play()
	elif _board_music_player.playing:
		if _board_music_active:
			_board_music_player.stream_paused = true
		else:
			_board_music_player.stream_paused = false
			_board_music_player.stop()

extends Node

signal background_theme_changed(theme_id: String)

## Recursos del jugador compartidos entre Lobby y partida.
const INITIAL_LIVES := 5
const INITIAL_STARS := 100000
const INITIAL_GEMS := 756

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_BACKGROUND_THEME_ID := "fondo2-verde"

const BACKGROUND_THEMES: Array = [
	{"id": "fonde2-rosa", "path": "res://Imagenes/fonde2-rosa.png", "label": "Rosa 2"},
	{"id": "fondo-azul", "path": "res://Imagenes/fondo-azul.png", "label": "Azul"},
	{"id": "fondo-rosa", "path": "res://Imagenes/fondo-rosa.png", "label": "Rosa"},
	{"id": "fondo-verde", "path": "res://Imagenes/fondo-verde.png", "label": "Verde"},
	{"id": "fondo2-verde", "path": "res://Imagenes/fondo2-verde.png", "label": "Verde 2"},
	{"id": "fondo2-azul", "path": "res://Imagenes/fondo2-azul.png", "label": "Azul 2"},
]

var lives: int = INITIAL_LIVES
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

func _ready() -> void:
	load_settings()

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

func get_background_theme_label(theme_id: String) -> String:
	for theme in BACKGROUND_THEMES:
		if str(theme.get("id", "")) == theme_id:
			return str(theme.get("label", theme_id))
	return theme_id

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
	music_enabled = enabled
	save_settings()

func set_sounds_enabled(enabled: bool) -> void:
	sounds_enabled = enabled
	save_settings()

func set_vibration_enabled(enabled: bool) -> void:
	vibration_enabled = enabled
	save_settings()

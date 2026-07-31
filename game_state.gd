extends Node

signal background_theme_changed(theme_id: String)

## Recursos del jugador compartidos entre Lobby y partida.
const INITIAL_LIVES := 5
const INITIAL_STARS := 100000
const INITIAL_GEMS := 756

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_BACKGROUND_THEME_ID := "fondo2-verde"

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
	music_enabled = enabled
	save_settings()

func set_sounds_enabled(enabled: bool) -> void:
	sounds_enabled = enabled
	save_settings()

func set_vibration_enabled(enabled: bool) -> void:
	vibration_enabled = enabled
	save_settings()

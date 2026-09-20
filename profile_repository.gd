class_name ProfileRepository
extends RefCounted

const AVATAR_OPTIONS: Array = [
	{"id": "mariposa", "path": "res://Imagenes/avatars/avatar-mariposa.png", "label": "Mariposa"},
	{"id": "conejo", "path": "res://Imagenes/avatars/avatar-conejo.png", "label": "Conejo"},
	{"id": "buho", "path": "res://Imagenes/avatars/avatar-buho.png", "label": "Búho"},
	{"id": "rana", "path": "res://Imagenes/avatars/avatar-rana.png", "label": "Rana"},
	{"id": "hombre", "path": "res://Imagenes/avatars/avatar-hombre.png", "label": "Hombre"},
	{"id": "gato", "path": "res://Imagenes/avatars/avatar-gato.png", "label": "Gato"},
	{"id": "mujer", "path": "res://Imagenes/avatars/avatar-mujer.png", "label": "Mujer"},
	{"id": "zorro", "path": "res://Imagenes/avatars/avatar-zorro.png", "label": "Zorro"},
	{"id": "panda", "path": "res://Imagenes/avatars/avatar-panda.png", "label": "Panda"},
]

const BORDER_COLOR_OPTIONS: Array = [
	{"id": "verde", "color": Color(0.25, 0.75, 0.40), "label": "Verde"},
	{"id": "violeta", "color": Color(0.55, 0.35, 0.85), "label": "Violeta"},
	{"id": "amarillo", "color": Color(0.95, 0.85, 0.25), "label": "Amarillo"},
	{"id": "azul", "color": Color(0.30, 0.55, 0.90), "label": "Azul"},
	{"id": "naranja", "color": Color(0.90, 0.50, 0.15), "label": "Naranja"},
	{"id": "lima", "color": Color(0.65, 0.85, 0.25), "label": "Lima"},
	{"id": "rosa_claro", "color": Color(0.95, 0.75, 0.85), "label": "Rosa claro"},
	{"id": "rosa_violeta", "color": Color(0.75, 0.30, 0.75), "label": "Rosa violeta"},
]

static func sanitize_username(value: String, max_len: int = 20) -> String:
	var cleaned := value.strip_edges()
	if max_len > 0 and cleaned.length() > max_len:
		cleaned = cleaned.substr(0, max_len)
	return cleaned

static func avatar_options() -> Array:
	return AVATAR_OPTIONS.duplicate(true)

static func border_options() -> Array:
	return BORDER_COLOR_OPTIONS.duplicate(true)

static func default_avatar_id() -> String:
	return str(AVATAR_OPTIONS[0].get("id", "mariposa"))

static func default_border_color_id() -> String:
	return str(BORDER_COLOR_OPTIONS[0].get("id", "verde"))

static func avatar_path_for_id(avatar_id: String) -> String:
	for opt in AVATAR_OPTIONS:
		if str(opt.get("id", "")) == avatar_id:
			return str(opt.get("path", ""))
	return ""

static func border_color_for_id(border_id: String) -> Variant:
	for opt in BORDER_COLOR_OPTIONS:
		if str(opt.get("id", "")) == border_id:
			return opt.get("color", null)
	return null

static func default_player_data(save_version: int, username: String, default_custom_border_color: Color, initial_stars: int, initial_lives: int, initial_gems: int) -> Dictionary:
	return {
		"save_version": save_version,
		"username": username,
		"avatar_id": default_avatar_id(),
		"avatar_border_id": default_border_color_id(),
		"avatar_border_custom": {
			"r": default_custom_border_color.r,
			"g": default_custom_border_color.g,
			"b": default_custom_border_color.b,
		},
		"level": 1,
		"coins": initial_stars,
		"position": {"x": 0.0, "y": 0.0},
		"lives": initial_lives,
		"gems": initial_gems,
		"checkpoint_level": 1,
		"checkpoint_snapshot": {},
		"current_level": 1,
		"max_value": 5,
		"active_stacks": 5,
		"player_stars": initial_stars,
	}

extends Node

## Autoload: gestión de usuario y guardado automático en user://player_save.json
##
## Ejemplo desde cualquier script:
##   $UsernameLabel.text = SaveManager.get_username()
##   SaveManager.add_coins(100)
##   SaveManager.player_data["level"] = 5
##   SaveManager.save_game()

signal player_data_changed

const SAVE_PATH := "user://player_save.json"
const AUTOSAVE_INTERVAL_SEC := 30.0
const SAVE_VERSION := 1

const ADJECTIVES: Array[String] = [
	"Valiente", "Astuto", "Veloz", "Brillante", "Audaz", "Noble", "Feroz", "Sabio",
	"Agil", "Lucky", "Epico", "Magico", "Dorado", "Feliz", "Turbo", "Cosmico",
]
const NOUNS: Array[String] = [
	"Panda", "Lobo", "Zorro", "Tigre", "Halcon", "Delfin", "Koala", "Leon",
	"Buho", "Gato", "Dragon", "Fenix", "Cometa", "Ninja", "Pirata", "Héroe",
]

var player_data: Dictionary = {}

var _autosave_timer: Timer = null
var _session_collector: Callable = Callable()


func _ready() -> void:
	_setup_autosave_timer()
	load_game()


func _setup_autosave_timer() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL_SEC
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _on_autosave_timeout() -> void:
	save_game()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save_game()


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func get_username() -> String:
	return str(player_data.get("username", ""))


func set_username(new_name: String) -> void:
	var cleaned := new_name.strip_edges()
	if cleaned.is_empty():
		return
	if cleaned.length() > 20:
		cleaned = cleaned.substr(0, 20)
	player_data["username"] = cleaned
	if GameState != null:
		GameState.username = cleaned
	player_data_changed.emit()
	save_game()


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


func get_avatar_options() -> Array:
	return AVATAR_OPTIONS.duplicate(true)


func get_default_avatar_id() -> String:
	return str(AVATAR_OPTIONS[0].get("id", "mariposa"))


func get_avatar_id() -> String:
	var id := str(player_data.get("avatar_id", get_default_avatar_id()))
	if _avatar_path_for_id(id).is_empty():
		return get_default_avatar_id()
	return id


func set_avatar_id(avatar_id: String) -> void:
	if _avatar_path_for_id(avatar_id).is_empty():
		return
	player_data["avatar_id"] = avatar_id
	player_data_changed.emit()
	save_game()


func get_avatar_texture() -> Texture2D:
	var path := _avatar_path_for_id(get_avatar_id())
	if path.is_empty():
		path = str(AVATAR_OPTIONS[0].get("path", ""))
	return load(path) as Texture2D


## Mayor valor de ficha del progreso guardado (objetivo actual del nivel).
func get_max_unlocked_coin_value() -> int:
	var best := 0
	var snap: Variant = player_data.get("checkpoint_snapshot", {})
	if snap is Dictionary:
		best = maxi(best, int(snap.get("max_value", 0)))
	best = maxi(best, int(player_data.get("max_value", 0)))
	if best <= 0 and GameState != null:
		var gs: Variant = GameState.checkpoint_snapshot
		if gs is Dictionary:
			best = maxi(best, int(gs.get("max_value", 0)))
	return maxi(5, best)


func _avatar_path_for_id(avatar_id: String) -> String:
	for opt in AVATAR_OPTIONS:
		if str(opt.get("id", "")) == avatar_id:
			return str(opt.get("path", ""))
	return ""


func get_position() -> Vector2:
	var pos: Variant = player_data.get("position", {"x": 0.0, "y": 0.0})
	if pos is Dictionary:
		return Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	if pos is Vector2:
		return pos
	return Vector2.ZERO


func set_position(pos: Vector2) -> void:
	player_data["position"] = {"x": pos.x, "y": pos.y}


func add_coins(amount: int) -> void:
	var current: int = int(player_data.get("coins", 0))
	player_data["coins"] = current + amount
	if GameState != null:
		GameState.player_stars = int(player_data["coins"])
	player_data_changed.emit()
	save_game()


func register_session_collector(collector: Callable) -> void:
	_session_collector = collector


func merge_session_data(session: Dictionary) -> void:
	for key in session.keys():
		player_data[key] = session[key]
	_sync_core_fields_to_player_data()


func load_game() -> bool:
	if not has_save_file():
		player_data = _create_default_player_data()
		_apply_to_game_state()
		save_game()
		player_data_changed.emit()
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: no se pudo abrir %s" % SAVE_PATH)
		player_data = _create_default_player_data()
		_apply_to_game_state()
		return false

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("SaveManager: JSON inválido en %s" % SAVE_PATH)
		player_data = _create_default_player_data()
		_apply_to_game_state()
		return false

	player_data = _merge_with_defaults(parsed as Dictionary)
	_apply_to_game_state()
	player_data_changed.emit()
	return true


func save_game() -> void:
	if _session_collector.is_valid():
		var session: Variant = _session_collector.call()
		if session is Dictionary:
			merge_session_data(session)
	else:
		_sync_core_fields_to_player_data()

	player_data["save_version"] = SAVE_VERSION

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: no se pudo escribir %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(player_data, "\t"))
	file.close()


func _create_default_player_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"username": _generate_random_username(),
		"avatar_id": "mariposa",
		"level": 1,
		"coins": GameState.INITIAL_STARS,
		"position": {"x": 0.0, "y": 0.0},
		"lives": GameState.INITIAL_LIVES,
		"gems": GameState.INITIAL_GEMS,
		"checkpoint_level": 1,
		"checkpoint_snapshot": {},
		"current_level": 1,
		"max_value": 5,
		"active_stacks": 5,
		"player_stars": GameState.INITIAL_STARS,
	}


func _merge_with_defaults(loaded: Dictionary) -> Dictionary:
	var merged := _create_default_player_data()
	for key in loaded.keys():
		merged[key] = loaded[key]
	if str(merged.get("username", "")).is_empty():
		merged["username"] = _generate_random_username()
	var pos: Variant = merged.get("position")
	if not pos is Dictionary:
		merged["position"] = {"x": 0.0, "y": 0.0}
	var avatar_id := str(merged.get("avatar_id", ""))
	if _avatar_path_for_id(avatar_id).is_empty():
		merged["avatar_id"] = get_default_avatar_id()
	return merged


func _generate_random_username() -> String:
	var adj: String = ADJECTIVES[randi() % ADJECTIVES.size()]
	var noun: String = NOUNS[randi() % NOUNS.size()]
	var num: int = randi_range(10, 999)
	return "%s%s%d" % [adj, noun, num]


func _sync_core_fields_to_player_data() -> void:
	if GameState == null:
		return
	var level: int = int(player_data.get("checkpoint_level", player_data.get("level", GameState.player_level)))
	player_data["level"] = level
	player_data["checkpoint_level"] = level
	player_data["coins"] = int(player_data.get("player_stars", GameState.player_stars))
	player_data["lives"] = GameState.lives
	player_data["gems"] = GameState.gems
	if not player_data.has("username") or str(player_data["username"]).is_empty():
		player_data["username"] = _generate_random_username()


func _apply_to_game_state() -> void:
	if GameState == null:
		return
	GameState.username = get_username()
	GameState.player_level = maxi(1, int(player_data.get("level", player_data.get("checkpoint_level", 1))))
	GameState.player_stars = int(player_data.get("coins", player_data.get("player_stars", GameState.INITIAL_STARS)))
	GameState.lives = int(player_data.get("lives", GameState.INITIAL_LIVES))
	GameState.gems = int(player_data.get("gems", GameState.INITIAL_GEMS))
	var snap: Variant = player_data.get("checkpoint_snapshot", {})
	if snap is Dictionary:
		GameState.checkpoint_snapshot = snap.duplicate(true)

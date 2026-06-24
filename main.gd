extends Node2D

const StackScene = preload("res://stack.tscn")
const StackScript = preload("res://stack.gd")
const BackgroundTexture = preload("res://Imagenes/fondo2-verde.png")
const MixIconTexture = preload("res://Imagenes/icono-mezclar.png")
const HammerIconTexture = preload("res://Imagenes/icono-martillo.png")
const GloveIconTexture = preload("res://Imagenes/icono-mano.png")
const DiamondIconTexture = preload("res://Imagenes/icono-estrella.png")
const LifeIconTexture = preload("res://Imagenes/icono-vidas.png")
const HomeScenePath := "res://Home.tscn"

const TOTAL_SLOTS = 15
const SLOT_COLUMNS = 5
const SLOT_ROWS = 3
const STACK_CAPACITY = 10
const INITIAL_COINS_PER_STACK = 3
## Bonus solo para el arranque del tablero (no aplica al botón Repartir).
const INITIAL_EXTRA_COINS = 7
const ROLL_COINS_PER_ACTION = 2
## --- Layout del tablero y slots (ajustar acá) ---
## Altura extra de cada celda respecto a la pila (más = slots más altos).
const SLOT_HEIGHT_EXTRA_RATIO = 0.10
## Ancho de cada celda vs pila (menos de 1.0 = tablero un poco más angosto).
const SLOT_WIDTH_RATIO = 0.97
## Separación vertical entre filas de slots (fracción de la altura de una pila).
const SLOT_ROW_GAP_RATIO = 0.06
## Separación horizontal entre columnas de slots (fracción del ancho de una pila).
const SLOT_COLUMN_GAP_RATIO = 0.05
## Cuánto de la pantalla puede ocupar la grilla (ancho / alto útil).
const GRID_FILL_WIDTH_RATIO = 0.98
const GRID_FILL_HEIGHT_RATIO = 0.80
const LAYOUT_SCALE_MIN = 0.50
const LAYOUT_SCALE_MAX = 2.50
const BOARD_GRID_WIDTH_PADDING = 1.0
const BOARD_GRID_HEIGHT_PADDING = 1.02
## Borde verde alrededor de la grilla (en unidades de slot; más = panel más grande).
const BOARD_PAD_X_SLOTS = 0.04
const BOARD_PAD_Y_SLOTS = 0.04
const PANEL_CONTENT_PADDING_RATIO = 0.004
## Posición vertical del panel (área útil sobre el banner).
const BOARD_PANEL_TOP_RATIO = 0.17
## Colores del tablero — verde menta transparente (estilo portada).
const BOARD_BG_COLOR := Color(0.54, 0.82, 0.64, 0.36)
const BOARD_GLOSS_COLOR := Color(0.88, 0.98, 0.90, 0.12)
const BOARD_SHADOW_BASE := Color(0.18, 0.32, 0.22)
const BOARD_ROW_COLOR := Color(0.50, 0.78, 0.60, 0.28)
const BOARD_SLOT_ACTIVE_COLOR := Color(0.46, 0.72, 0.54, 0.40)
const BOARD_SLOT_INACTIVE_COLOR := Color(0.56, 0.84, 0.66, 0.16)
const BOARD_SLOT_TEMP_COLOR := Color(0.48, 0.74, 0.56, 0.24)
## Chips superiores (home, vidas, estrellas, settings).
const HUD_SIZE_MULTIPLIER = 1.0
const HUD_CHIP_HEIGHT = 58.0
const HUD_CORNER_SIZE = 56.0
const HUD_CHIP_LIFE_W = 148.0
const HUD_CHIP_STARS_W = 130.0
const HUD_CHIP_GAP = 26.0
const HUD_CHIP_TO_PROGRESS_GAP = 26.0
const HUD_EDGE_MARGIN = 14.0
## Botón Repartir y comodines.
const CTA_WIDTH_RATIO = 0.40
const CTA_HEIGHT = 62.0
const CTA_FONT_SIZE = 38.0
const WILDCARD_BUTTON_SIZE = 68.0
const WILDCARD_BUTTON_GAP = 24.0
const AD_FOOTER_HEIGHT_RATIO = 0.16
const AD_FOOTER_MIN_HEIGHT = 120.0
const AD_FOOTER_MAX_HEIGHT = 200.0
const WILDCARD_TYPES := ["mix", "hammer", "glove"]
const WILDCARD_INITIAL_USES := 3
const WILDCARD_COST_DIAMONDS := 200
## Nivel de checkpoint para desbloquear cada comodín (ver barra de progreso).
const WILDCARD_UNLOCK_LEVEL := {
	"mix": 5,
	"hammer": 10,
	"glove": 15,
}
const WILDCARD_LOCKED_MODULATE := Color(0.70, 0.70, 0.70, 0.82)
const TEMP_SLOT_COST_DIAMONDS := 200
const TEMP_SLOT_DURATION_SEC := 60.0
const TEMP_LOCKED_PANEL_GREEN := Color(0.14, 0.38, 0.22, 1.0)
const TEMP_LOCKED_PANEL_CREAM := Color(0.98, 0.94, 0.86, 1.0)
## Ranura temporal: celda arriba a la derecha (fila 0, col 4 → índice 4). Bloqueada hasta pagar.
const TEMP_SLOT_BOARD_INDEX := 4
## Compra opcional al lado de la última pila habilitada (estrellas mock); precio se duplica en cada compra.
const ADJACENT_EXTRA_SLOT_BASE_PRICE := 600
## Mock: al alcanzar este nivel de jugador la ranura extra sería gratis (solo texto UI).
const ADJACENT_EXTRA_SLOT_FREE_AT_LEVEL := 8
## Máximo de pilas en las otras 14 celdas; la 15ª pila solo aparece con ranura temporal activa.
const MAX_PERMANENT_STACKS := 14
const INITIAL_LIVES := 5
## Cartel "No hay movimientos": costo de comprar la recarga completa de vidas y cuántas otorga.
const BUY_LIVES_COST := 600
const BUY_LIVES_AMOUNT := INITIAL_LIVES
## Vidas que otorga ver un anuncio (mock).
const AD_LIVES_AMOUNT := 1
## Sistema de niveles (checkpoints). Patrón por valor V (>=5): crear pila V, pila V >50%, completar pila V (=crear V+1).
## N1=inicio (solo valores 1..4). N2=crear pila 5. N3=pila 5 >50%. N4=completar pila 5 → crear pila 6. Y así sucesivamente.
const CHECKPOINT_BASE_VALUE := 5
## "Más del 50 %": la pila tiene más de la mitad de su capacidad en fichas de ese valor.
const CHECKPOINT_HALF_THRESHOLD := STACK_CAPACITY / 2
## Orden de las 14 celdas permanentes: primero la fila de abajo (10→14) izq→der, luego la del medio, luego la de arriba sin la celda 4 (temporal).
const PERMANENT_SLOT_ORDER := [10, 11, 12, 13, 14, 5, 6, 7, 8, 9, 0, 1, 2, 3]
# --- Persistencia desactivada: siempre partida nueva al abrir el juego. ---
# Antes: user://coin_stack_save.json (ruta virtual de Godot).
# Windows (proyecto CoinStackPuzzle): %APPDATA%\Godot\app_userdata\CoinStackPuzzle\coin_stack_save.json
# Para reactivar: restaurar SAVE_PATH/SAVE_VERSION, collect_save_dict/apply_save_dict, try_load en _ready,
# save_game en _exit_tree, y cuerpos reales de save_game/try_load_saved_game.
# const SAVE_PATH := "user://coin_stack_save.json"
# const SAVE_VERSION := 2

var active_stacks: int = 5
var current_level: int = 1
## Nivel de checkpoint actual (el más alto alcanzado). Monótono: no baja aunque el tablero retroceda.
## Es el valor que se expone para save/load (ver get_current_level / collect_save_dict).
var checkpoint_level: int = 1
## Tablero + progresión guardados al alcanzar cada checkpoint (GDD: inicio del último nivel alcanzado).
var checkpoint_snapshot: Dictionary = {}
var max_value: int = 5
var stacks: Array = []
var selected_stack: Node = null
var board_locked: bool = false
var hammer_mode_active: bool = false
var background_sprite: Sprite2D = null
var hud_layer: CanvasLayer = null
var hud_root: Control = null
var home_chip: Panel = null
var life_chip: Panel = null
var life_chip_icon: TextureRect = null
var life_chip_label: Label = null
var settings_chip: Panel = null
var progress_container: Panel = null
var progress_fill: ColorRect = null
var progress_knob: Panel = null
var progress_left_label: Label = null
var progress_right_label: Label = null
var progress_bar_max_width: float = 0.0
var progress_bar_height: float = 0.0
var progress_fill_tween: Tween = null
var cta_shadow: Panel = null
var cta_button: Panel = null
var cta_label: Label = null
var action_shadows: Array = []
var action_pills: Array = []
var action_icons: Array = []
var action_labels: Array = []
var action_count_badges: Array = []
var action_count_labels: Array = []
var wildcard_counts := {
	"mix": 0,
	"hammer": 0,
	"glove": 0,
}
var wildcard_unlock_granted := {
	"mix": false,
	"hammer": false,
	"glove": false,
}
## Balance de gemas (diamantes); no hay chip en el HUD, solo lógica de compras.
var gems: int = 756
## Mock para compras de ranura extra adyacente (no es la ranura temporal).
var player_stars: int = 100000
var adjacent_slot_next_price: int = ADJACENT_EXTRA_SLOT_BASE_PRICE
## Celda del tablero (0..14) donde se muestra la oferta; -1 si no aplica.
var adjacent_offer_board_index: int = -1
var temp_slot_time_remaining: float = 0.0
## Solo true tras comprar la ranura temporal (hay una pila extra); no confundir con "última pila" del tablero normal.
var temp_slot_bonus_active: bool = false
## UI ranura bloqueada (crema, reloj de arena, 60 seg, precio); no recibe clics (IGNORE).
var temp_slot_locked_root: Control = null
var temp_slot_locked_panel: Panel = null
var temp_slot_locked_hourglass: Label = null
var temp_slot_locked_lbl_60: Label = null
var temp_slot_locked_lbl_seg: Label = null
var temp_slot_locked_lbl_cost: Label = null
var temp_slot_locked_vbox: VBoxContainer = null
var temp_slot_locked_cost_row: HBoxContainer = null
var temp_slot_locked_cost_icon: TextureRect = null
## Cuenta regresiva solo tras comprar; pequeña, en el borde superior derecho.
var temp_slot_timer_label: Label = null
## Oferta de ranura extra (panel crema como temporal; precio = número + icono-estrella).
var adjacent_slot_offer_root: Control = null
var adjacent_slot_offer_panel: Panel = null
var adjacent_slot_offer_lbl_level: Label = null
var adjacent_slot_offer_lbl_lock: Label = null
var adjacent_slot_offer_price_row: HBoxContainer = null
var adjacent_slot_offer_lbl_cost: Label = null
var adjacent_slot_offer_cost_icon: TextureRect = null
var adjacent_slot_star_error_label: Label = null
var adjacent_slot_star_error_tween: Tween = null
var stars_chip: Panel = null
var stars_chip_label: Label = null
var purchase_overlay: ColorRect = null
var purchase_card: Panel = null
var purchase_title_label: Label = null
var purchase_icon_circle: Panel = null
var purchase_icon_texture_rect: TextureRect = null
var purchase_count_badge: Panel = null
var purchase_count_label: Label = null
var purchase_buy_button: Button = null
var purchase_buy_center: CenterContainer = null
var purchase_buy_content: HBoxContainer = null
var purchase_buy_gem_icon: TextureRect = null
var purchase_buy_cost_label: Label = null
var purchase_close_button: Button = null
var pending_purchase_type: String = ""
var lives: int = INITIAL_LIVES
## Cartel "No hay movimientos" (bloqueo del tablero).
var no_moves_overlay: ColorRect = null
var no_moves_card: Panel = null
var no_moves_margin: MarginContainer = null
var no_moves_vbox: VBoxContainer = null
var no_moves_title_label: Label = null
var no_moves_restart_button: Button = null
var no_moves_buy_button: Button = null
var no_moves_ad_button: Button = null
## Cartel al subir de nivel (checkpoint).
var level_up_overlay: ColorRect = null
var level_up_card: Panel = null
var level_up_margin: MarginContainer = null
var level_up_vbox: VBoxContainer = null
var level_up_title_label: Label = null
var level_up_subtitle_label: Label = null
var level_up_continue_button: Button = null

func _ready() -> void:
	_apply_portrait_orientation()
	_sync_player_resources_from_game_state()
	randomize()
	background_sprite = Sprite2D.new()
	background_sprite.texture = BackgroundTexture
	background_sprite.centered = false
	background_sprite.z_as_relative = false
	background_sprite.z_index = -100
	add_child(background_sprite)
	move_child(background_sprite, 0)
	update_background_scale()
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	build_mock_ui()
	# if not try_load_saved_game():
	# 	setup_board()
	setup_board()
	configure_process_for_temp_slot()
	queue_redraw()
	print_status()

## Fuerza orientación vertical en móvil (Godot 4 usa sobre todo project.godot > Handheld > Orientation).
func _apply_portrait_orientation() -> void:
	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		return
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

func _exit_tree() -> void:
	pass
	# save_game()

func _process(delta: float) -> void:
	if temp_slot_time_remaining <= 0.0:
		return
	temp_slot_time_remaining = maxf(0.0, temp_slot_time_remaining - delta)
	_sync_slot_overlay_controls()
	queue_redraw()
	if temp_slot_time_remaining <= 0.0:
		close_temporary_slot()

func clear_board_stacks() -> void:
	hammer_mode_active = false
	clear_selection()
	for s in stacks:
		s.queue_free()
	stacks.clear()

func create_stack_nodes(count: int) -> void:
	for i in range(count):
		var stack = StackScene.instantiate()
		add_child(stack)
		stack.z_index = 10
		stack.position = get_stack_position_for_index(i)
		stack.scale = Vector2.ONE * get_layout_scale()
		stacks.append(stack)

func fill_board_initial_random() -> void:
	if active_stacks <= 1:
		for _j in range(mini(STACK_CAPACITY, INITIAL_COINS_PER_STACK + INITIAL_EXTRA_COINS)):
			stacks[0].push(get_roll_value())
		return
	## Siempre dejamos exactamente una pila vacía (índice active_stacks - 1) para poder mover al hueco.
	var keep_empty_index := clampi(active_stacks - 1, 0, maxi(0, stacks.size() - 1))
	var initial_target_stacks: Array = []
	for si in range(stacks.size()):
		while not stacks[si].is_empty():
			stacks[si].pop()
	for i in range(active_stacks):
		if i == keep_empty_index:
			continue
		initial_target_stacks.append(stacks[i])
		for _j in range(INITIAL_COINS_PER_STACK):
			stacks[i].push(get_roll_value())
	# Arranque más funcional: sumar monedas extra al inicio sin afectar la tirada normal.
	var extra_to_place := INITIAL_EXTRA_COINS + maxi(0, active_stacks - 2)
	while extra_to_place > 0:
		var candidates: Array = []
		for st in initial_target_stacks:
			if st.free_slots() > 0:
				candidates.append(st)
		if candidates.is_empty():
			break
		var random_stack = candidates[randi() % candidates.size()]
		random_stack.push(get_roll_value())
		extra_to_place -= 1

func setup_board() -> void:
	board_locked = false
	temp_slot_bonus_active = false
	temp_slot_time_remaining = 0.0
	configure_process_for_temp_slot()
	adjacent_slot_next_price = ADJACENT_EXTRA_SLOT_BASE_PRICE
	checkpoint_level = 1
	current_level = 1
	max_value = CHECKPOINT_BASE_VALUE
	active_stacks = 5
	reset_wildcard_state()
	clear_board_stacks()
	create_stack_nodes(active_stacks)
	fill_board_initial_random()
	capture_checkpoint_snapshot()
	_sync_slot_overlay_controls()
	update_progress_bar(false)

func save_game() -> void:
	pass

func try_load_saved_game() -> bool:
	return false

## Estado persistible (save/load sigue desactivado; estos helpers quedan listos para reactivarlo).
## Incluye el nivel actual (checkpoint) como pide el sistema de checkpoints.
func collect_save_dict() -> Dictionary:
	return {
		"checkpoint_level": checkpoint_level,
		"checkpoint_snapshot": checkpoint_snapshot.duplicate(true),
		"current_level": current_level,
		"max_value": max_value,
		"active_stacks": active_stacks,
		"lives": lives,
		"gems": gems,
		"player_stars": player_stars,
	}

func apply_save_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	checkpoint_level = maxi(1, int(data.get("checkpoint_level", checkpoint_level)))
	var snap = data.get("checkpoint_snapshot", {})
	if snap is Dictionary and not snap.is_empty():
		checkpoint_snapshot = snap.duplicate(true)
	current_level = maxi(1, int(data.get("current_level", current_level)))
	max_value = maxi(CHECKPOINT_BASE_VALUE, int(data.get("max_value", max_value)))
	active_stacks = int(data.get("active_stacks", active_stacks))
	lives = int(data.get("lives", lives))
	gems = int(data.get("gems", gems))
	player_stars = int(data.get("player_stars", player_stars))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_control_clicked(home_chip, event.position):
			go_to_home()
			return
	# Evitar click-through: si el cartel de subida de nivel está abierto, no procesar input del tablero.
	if level_up_overlay != null and level_up_overlay.visible:
		return
	# Evitar click-through: si el cartel de bloqueo está abierto, no procesar input del tablero.
	if no_moves_overlay != null and no_moves_overlay.visible:
		return
	# Evitar click-through: si el popup de compra está abierto, no procesar input del tablero.
	if purchase_overlay != null and purchase_overlay.visible:
		return
	if board_locked:
		return
	if event.is_action_pressed("ui_accept"):
		perform_roll()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_control_clicked(cta_button, event.position):
			perform_roll()
			return
		if is_click_on_adjacent_extra_slot_offer(event.position):
			try_purchase_adjacent_extra_slot()
			return
		if is_click_on_temp_slot_cell(event.position):
			try_purchase_temp_slot()
			return
		if board_locked:
			return
		if hammer_mode_active:
			var hammer_stack = get_stack_at_point(event.position)
			if hammer_stack != null:
				apply_hammer_on_stack(hammer_stack)
			else:
				print("Martillo: toca una pila para vaciarla.")
			return
		if action_pills.size() > 0 and is_control_clicked(action_pills[0], event.position):
			try_use_wildcard("mix")
			return
		if action_pills.size() > 1 and is_control_clicked(action_pills[1], event.position):
			try_use_wildcard("hammer")
			return
		if action_pills.size() > 2 and is_control_clicked(action_pills[2], event.position):
			try_use_wildcard("glove")
			return
		handle_click(event.position)

func handle_click(mouse_pos: Vector2) -> void:
	var clicked_stack = get_stack_at_point(mouse_pos)
	if clicked_stack == null:
		print("Click fuera de pila.")
		clear_selection()
		return
	if selected_stack == null:
		selected_stack = clicked_stack
		selected_stack.set_selected(true)
		return
	if selected_stack == clicked_stack:
		clear_selection()
		return
	var moved = selected_stack.move_top_block_to(clicked_stack)
	if moved == 0:
		print("Movimiento invalido: destino lleno o tope incompatible.")
	clear_selection()
	# La resolución (fusiones, checkpoint, bloqueo) corre al asentarse la animación en stack.gd.
	# No llamar resolve_board_after_action() aquí: el tablero aún está a medias y puede dar bloqueo falso.

func get_stack_at_point(mouse_pos: Vector2) -> Node:
	for stack in stacks:
		var stack_scale: Vector2 = stack.scale if stack is Node2D else Vector2.ONE
		var foot: Vector2 = get_unscaled_stack_footprint() * stack_scale
		var top_local: float = StackScript.get_top_local_y() * stack_scale.y
		var rect = Rect2(
			stack.global_position + Vector2(-foot.x / 2.0, top_local),
			foot
		)
		if rect.has_point(mouse_pos):
			return stack
	return null

func clear_selection() -> void:
	if selected_stack != null:
		selected_stack.set_selected(false)
	selected_stack = null

func go_to_home() -> void:
	_push_player_resources_to_game_state()
	save_game()
	get_tree().change_scene_to_file(HomeScenePath)

func _sync_player_resources_from_game_state() -> void:
	lives = GameState.lives
	player_stars = GameState.player_stars
	gems = GameState.gems

func _push_player_resources_to_game_state() -> void:
	GameState.lives = lives
	GameState.player_stars = player_stars
	GameState.gems = gems

func can_repartir() -> bool:
	for stack in stacks:
		if stack.has_method("free_slots") and stack.free_slots() > 0:
			return true
	return false

func perform_roll() -> bool:
	var target_stacks: Array = []
	var total_free_slots := 0
	for stack in stacks:
		var free = stack.free_slots() if stack.has_method("free_slots") else 0
		if free > 0:
			target_stacks.append(stack)
			total_free_slots += free
	if target_stacks.is_empty():
		print("Sin espacio para tirada.")
		save_game()
		check_blocked_state()
		return false

	var values_to_roll: Array = []
	# Igual que get_roll_value(): la tirada nunca incluye max_value (solo objetivo de nivel).
	var max_roll_value = max(1, max_value - 1)
	for value in range(1, max_roll_value + 1):
		# Garantiza al menos una ficha de cada numero permitido en tirada (1 .. max-1).
		values_to_roll.append(value)
		# Y agrega variacion: ese numero puede salir 2 o 3 veces.
		var extra_count = randi_range(0, 2)
		for _i in range(extra_count):
			values_to_roll.append(value)

	values_to_roll.shuffle()
	var roll_count = mini(values_to_roll.size(), total_free_slots)
	## Anti-bloqueo: con 2+ huecos, dejar al menos 1 libre para no lockear el tablero en una sola tirada.
	## Con un único hueco, permitir llenarlo: repartir es arriesgado y puede llenar el tablero → fin de vida.
	if total_free_slots >= 2 and roll_count >= total_free_slots:
		roll_count = total_free_slots - 1
	for i in range(roll_count):
		var available_stacks: Array = []
		for stack in target_stacks:
			if not stack.is_full():
				available_stacks.append(stack)
		if available_stacks.is_empty():
			break
		var idx = randi() % available_stacks.size()
		available_stacks[idx].push(values_to_roll[i])

	board_locked = false
	resolve_board_after_action()
	return true

func resolve_board_after_action() -> void:
	resolve_fusions()
	check_level_up()
	update_progress_bar(true)
	var leveled_up := update_checkpoint_level()
	if leveled_up:
		_force_progress_bar_display(1.0)
	if level_up_overlay == null or not level_up_overlay.visible:
		board_locked = false
	print_status()
	save_game()
	if level_up_overlay == null or not level_up_overlay.visible:
		check_blocked_state()

## True si alguna pila tiene monedas en vuelo (animación de movimiento).
func has_pending_coin_animations() -> bool:
	for stack in stacks:
		if stack.pending_incoming_values.size() > 0:
			return true
	return false

## Muestra el cartel "No hay movimientos" solo si no hay jugadas entre pilas ni espacio para repartir.
func check_blocked_state() -> void:
	if level_up_overlay != null and level_up_overlay.visible:
		return
	if no_moves_overlay != null and no_moves_overlay.visible:
		return
	if has_pending_coin_animations():
		return
	if not has_any_valid_moves():
		show_no_moves_panel()

func resolve_fusions() -> void:
	var changed := true
	var guard := 0
	while changed and guard < 200:
		changed = false
		guard += 1
		for stack in stacks:
			if not stack.is_ready_to_fuse():
				continue
			var base_value = stack.top_value()
			stack.play_fusion_animation()
			var new_value = stack.remove_all_and_fuse()
			if new_value < 0:
				continue
			stack.push(new_value)
			print("Fusion: ", base_value, "x10 -> ", new_value)
			changed = true

func check_level_up() -> void:
	var next_value = max_value + 1
	for stack in stacks:
		if stack.top_value() == next_value:
			level_up()
			return

func level_up() -> void:
	current_level += 1
	max_value += 1
	print("Subiste al nivel ", current_level, ". Nuevo objetivo: ", max_value)
	if current_level % 2 == 0 and permanent_stack_count() < MAX_PERMANENT_STACKS:
		active_stacks += 1
		add_new_stack_for_level_unlock()
		print("Ranura desbloqueada. Ranuras activas: ", active_stacks)
	_sync_slot_overlay_controls()

func add_new_stack_for_level_unlock() -> void:
	if has_active_temp_stack() and stacks.size() > 0:
		insert_stack_before_index(stacks.size() - 1)
	else:
		append_new_stack_node()

func append_new_stack_node() -> void:
	var i = stacks.size()
	var stack = StackScene.instantiate()
	add_child(stack)
	stack.z_index = 10
	stack.position = get_stack_position_for_index(i)
	stack.scale = Vector2.ONE * get_layout_scale()
	stacks.append(stack)

func insert_stack_before_index(insert_before: int) -> void:
	if stacks.is_empty():
		return
	insert_before = clampi(insert_before, 0, stacks.size() - 1)
	var stack = StackScene.instantiate()
	var sibling = stacks[insert_before]
	add_child(stack)
	move_child(stack, sibling.get_index())
	stacks.insert(insert_before, stack)
	stack.z_index = 10
	refresh_all_stack_layout()

func refresh_all_stack_layout() -> void:
	var sc = get_layout_scale()
	for i in range(stacks.size()):
		stacks[i].position = get_stack_position_for_index(i)
		stacks[i].scale = Vector2.ONE * sc
		if stacks[i].has_method("normalize_coin_scales"):
			stacks[i].normalize_coin_scales()

func try_purchase_temp_slot() -> void:
	if temp_slot_bonus_active:
		print("Ya tenés una ranura temporal activa.")
		return
	# active_stacks cuenta solo ranuras permanentes (máx. 14). La temporal es aparte.
	if active_stacks >= 14:
		print("No hay más ranuras disponibles en el tablero.")
		return
	if gems < TEMP_SLOT_COST_DIAMONDS:
		print("Necesitás %d diamantes para la ranura temporal." % TEMP_SLOT_COST_DIAMONDS)
		return
	gems -= TEMP_SLOT_COST_DIAMONDS
	temp_slot_bonus_active = true
	append_new_stack_node()
	# Recalcular posiciones ahora que ya existe la pila temporal como última.
	# Sin este refresh, puede quedar momentáneamente en una celda permanente.
	refresh_all_stack_layout()
	board_locked = false
	temp_slot_time_remaining = TEMP_SLOT_DURATION_SEC
	update_gem_display()
	configure_process_for_temp_slot()
	_sync_slot_overlay_controls()
	queue_redraw()
	save_game()
	print("Ranura temporal abierta por %.0f s." % TEMP_SLOT_DURATION_SEC)

func close_temporary_slot() -> void:
	if not temp_slot_bonus_active:
		temp_slot_time_remaining = 0.0
		configure_process_for_temp_slot()
		return
	if not stacks.is_empty():
		var temp_stack: Node = stacks[stacks.size() - 1]
		if temp_stack != null and temp_stack.has_method("is_empty") and not temp_stack.is_empty():
			# No cerrar con fichas adentro: evitar pérdida silenciosa de monedas.
			temp_slot_time_remaining = 1.0
			configure_process_for_temp_slot()
			_sync_slot_overlay_controls()
			print("La ranura temporal está llena. Vaciala antes de que cierre.")
			return
	temp_slot_time_remaining = 0.0
	if stacks.is_empty():
		temp_slot_bonus_active = false
		configure_process_for_temp_slot()
		return
	var removed: Node = stacks.pop_back()
	if selected_stack == removed:
		clear_selection()
	if is_instance_valid(removed):
		removed.queue_free()
	temp_slot_bonus_active = false
	refresh_all_stack_layout()
	configure_process_for_temp_slot()
	_sync_slot_overlay_controls()
	queue_redraw()
	save_game()
	print("Ranura temporal cerrada.")

func configure_process_for_temp_slot() -> void:
	set_process(temp_slot_time_remaining > 0.001)

func get_roll_value() -> int:
	return randi() % max(1, max_value - 1) + 1

func has_any_valid_moves() -> bool:
	return count_legal_moves() > 0 or can_repartir()

func count_legal_moves() -> int:
	var total := 0
	for i in range(stacks.size()):
		if stacks[i].is_empty():
			continue
		var value: int = stacks[i].top_value()
		for j in range(stacks.size()):
			if i == j:
				continue
			if stacks[j].can_receive_value(value):
				total += 1
	return total

func count_total_free_slots() -> int:
	var total := 0
	for stack in stacks:
		if stack.has_method("free_slots"):
			total += int(stack.free_slots())
	return total

## Valor de ficha más alto presente en cualquier pila del tablero (0 si está vacío).
func highest_coin_value_on_board() -> int:
	var hv := 0
	for stack in stacks:
		for c in stack.coins:
			if int(c) > hv:
				hv = int(c)
	return hv

## Mayor cantidad de fichas de un valor dado dentro de una misma pila.
func max_count_of_value(value: int) -> int:
	var best := 0
	for stack in stacks:
		var cnt := 0
		for c in stack.coins:
			if int(c) == value:
				cnt += 1
		if cnt > best:
			best = cnt
	return best

## Calcula el nivel según el estado actual del tablero (sin tener en cuenta el máximo alcanzado).
## N1=inicio (valores 1..4). Para V>=5: crear pila V y "pila V >50%" suman 2 niveles por valor;
## "completar pila V" coincide con "crear pila V+1" (la fusión de 10 V genera un V+1).
func evaluate_checkpoint_level() -> int:
	var hv := highest_coin_value_on_board()
	if hv < CHECKPOINT_BASE_VALUE:
		return 1
	var has_half := max_count_of_value(hv) > CHECKPOINT_HALF_THRESHOLD
	return 2 * (hv - CHECKPOINT_BASE_VALUE) + 2 + (1 if has_half else 0)

## Progreso 0..1 hacia un nivel objetivo (según el estado actual del tablero).
func get_progress_toward_checkpoint_level(target_level: int) -> float:
	if target_level <= 1:
		return 0.0
	var steps := target_level - 2
	var v := CHECKPOINT_BASE_VALUE + steps / 2
	if steps % 2 == 0:
		var hv := highest_coin_value_on_board()
		if hv >= v:
			return 1.0
		var prev_v := maxi(1, v - 1)
		var hv_part := clampf(float(hv) / float(prev_v), 0.0, 1.0) * 0.35
		var pile_part := clampf(
			float(max_count_of_value(prev_v)) / float(STACK_CAPACITY), 0.0, 1.0
		) * 0.65
		return clampf(hv_part + pile_part, 0.0, 0.99)
	var need := CHECKPOINT_HALF_THRESHOLD + 1
	return clampf(float(max_count_of_value(v)) / float(need), 0.0, 1.0)

## Progreso hacia el siguiente checkpoint guardado (0..1).
func get_current_level_progress() -> float:
	var next_lvl := checkpoint_level + 1
	var pct := get_progress_toward_checkpoint_level(next_lvl)
	if evaluate_checkpoint_level() >= next_lvl:
		pct = 1.0
	return clampf(pct, 0.0, 1.0)

func update_progress_bar(animated: bool = false) -> void:
	if progress_fill == null or progress_container == null:
		return
	if progress_bar_max_width <= 0.0:
		return
	var pct := get_current_level_progress()
	if progress_left_label != null:
		progress_left_label.text = str(checkpoint_level)
	if progress_right_label != null:
		progress_right_label.text = "%d%%" % int(round(pct * 100.0))
	var target_w := progress_bar_max_width * pct
	if animated:
		if progress_fill_tween != null and progress_fill_tween.is_valid():
			progress_fill_tween.kill()
		progress_fill_tween = create_tween()
		progress_fill_tween.set_trans(Tween.TRANS_SINE)
		progress_fill_tween.set_ease(Tween.EASE_OUT)
		progress_fill_tween.tween_property(
			progress_fill, "size", Vector2(target_w, progress_bar_height), 0.28
		)
	else:
		progress_fill.size = Vector2(target_w, progress_bar_height)

func _force_progress_bar_display(pct: float) -> void:
	if progress_fill == null or progress_bar_max_width <= 0.0:
		return
	pct = clampf(pct, 0.0, 1.0)
	if progress_right_label != null:
		progress_right_label.text = "%d%%" % int(round(pct * 100.0))
	progress_fill.size = Vector2(progress_bar_max_width * pct, progress_bar_height)

## Actualiza el checkpoint de forma monótona (solo avanza). Devuelve true si subió.
func update_checkpoint_level() -> bool:
	var lvl := evaluate_checkpoint_level()
	if lvl > checkpoint_level:
		checkpoint_level = lvl
		capture_checkpoint_snapshot()
		sync_wildcard_unlocks()
		print("Checkpoint alcanzado: nivel ", checkpoint_level, " (tablero guardado)")
		show_level_up_panel(checkpoint_level)
		return true
	return false

## Texto descriptivo del hito alcanzado (N2..Nx).
func get_checkpoint_level_description(level: int) -> String:
	if level <= 1:
		return ""
	var steps := level - 2
	var v := CHECKPOINT_BASE_VALUE + steps / 2
	if steps % 2 == 0:
		if steps == 0:
			return "Creaste la pila %d" % v
		return "Completaste la pila %d" % (v - 1)
	return "Pila %d: más del 50%%" % v

## Guarda tablero y progresión en el momento del checkpoint (para reinicio / save).
func capture_checkpoint_snapshot() -> void:
	var stack_data: Array = []
	for stack in stacks:
		var row: Array = []
		for c in stack.coins:
			row.append(int(c))
		stack_data.append(row)
	checkpoint_snapshot = {
		"checkpoint_level": checkpoint_level,
		"current_level": current_level,
		"max_value": max_value,
		"active_stacks": active_stacks,
		"adjacent_slot_next_price": adjacent_slot_next_price,
		"wildcard_counts": wildcard_counts.duplicate(),
		"wildcard_unlock_granted": wildcard_unlock_granted.duplicate(),
		"stacks": stack_data,
	}

## Restaura el tablero al último checkpoint guardado (pérdida de vida, compra de vidas, anuncio).
func restore_checkpoint() -> void:
	if checkpoint_snapshot.is_empty():
		setup_board()
		return
	hammer_mode_active = false
	clear_selection()
	board_locked = false
	temp_slot_bonus_active = false
	temp_slot_time_remaining = 0.0
	configure_process_for_temp_slot()
	checkpoint_level = maxi(1, int(checkpoint_snapshot.get("checkpoint_level", checkpoint_level)))
	current_level = maxi(1, int(checkpoint_snapshot.get("current_level", 1)))
	max_value = maxi(CHECKPOINT_BASE_VALUE, int(checkpoint_snapshot.get("max_value", CHECKPOINT_BASE_VALUE)))
	active_stacks = maxi(1, int(checkpoint_snapshot.get("active_stacks", 5)))
	adjacent_slot_next_price = int(checkpoint_snapshot.get(
		"adjacent_slot_next_price", ADJACENT_EXTRA_SLOT_BASE_PRICE
	))
	clear_board_stacks()
	create_stack_nodes(active_stacks)
	var stack_data: Array = checkpoint_snapshot.get("stacks", [])
	for i in range(mini(stacks.size(), stack_data.size())):
		if stack_data[i] is Array:
			for v in stack_data[i]:
				stacks[i].push(int(v))
	_restore_wildcard_state_from_snapshot()
	_sync_slot_overlay_controls()
	update_progress_bar(false)
	queue_redraw()
	print("Checkpoint restaurado: nivel ", checkpoint_level)

## Nivel actual expuesto para save/load.
func get_current_level() -> int:
	return checkpoint_level

func set_current_level(value: int) -> void:
	checkpoint_level = maxi(1, value)

func print_status() -> void:
	var summary: Array = []
	for i in range(stacks.size()):
		summary.append("S%d=%s" % [i, str(stacks[i].coins)])
	var legal_moves := count_legal_moves()
	var free_slots := count_total_free_slots()
	print(
		"Nivel:", current_level,
		" checkpoint:", checkpoint_level,
		" objetivo:", max_value,
		" jugadas:", legal_moves,
		" huecos:", free_slots,
		" | ", " ".join(summary)
	)
	if not has_any_valid_moves():
		print(">>> BLOQUEO: sin jugadas entre pilas ni espacio para repartir.")
	elif legal_moves == 0 and can_repartir():
		print(">>> Sin jugadas entre pilas, pero se puede repartir (", free_slots, " huecos).")

func _draw() -> void:
	var board_rect = get_board_rect()
	var corner = get_panel_corner_radius()
	# Sombra suave multicapa para elevacion leve.
	for i in range(4):
		var grow = float(6 + i * 5)
		var alpha = 0.05 - i * 0.010
		var shadow_rect = board_rect.grow(grow)
		shadow_rect.position.y += 4.0 + i * 1.5
		var soft_shadow := StyleBoxFlat.new()
		soft_shadow.bg_color = Color(
			BOARD_SHADOW_BASE.r, BOARD_SHADOW_BASE.g, BOARD_SHADOW_BASE.b, max(alpha, 0.01)
		)
		soft_shadow.corner_radius_top_left = int(corner + grow)
		soft_shadow.corner_radius_top_right = int(corner + grow)
		soft_shadow.corner_radius_bottom_left = int(corner + grow)
		soft_shadow.corner_radius_bottom_right = int(corner + grow)
		draw_style_box(soft_shadow, shadow_rect)

	var board_style := StyleBoxFlat.new()
	board_style.bg_color = BOARD_BG_COLOR
	board_style.corner_radius_top_left = corner
	board_style.corner_radius_top_right = corner
	board_style.corner_radius_bottom_right = corner
	board_style.corner_radius_bottom_left = corner
	draw_style_box(board_style, board_rect)

	var gloss_rect = Rect2(
		board_rect.position + Vector2(18, 14) * get_layout_scale(),
		Vector2(board_rect.size.x - 36 * get_layout_scale(), 42 * get_layout_scale())
	)
	var gloss_style := StyleBoxFlat.new()
	gloss_style.bg_color = BOARD_GLOSS_COLOR
	gloss_style.corner_radius_top_left = int(18 * get_layout_scale())
	gloss_style.corner_radius_top_right = int(18 * get_layout_scale())
	gloss_style.corner_radius_bottom_left = int(18 * get_layout_scale())
	gloss_style.corner_radius_bottom_right = int(18 * get_layout_scale())
	draw_style_box(gloss_style, gloss_rect)

	for row in range(SLOT_ROWS):
		var row_rect = get_row_rect(row)
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = BOARD_ROW_COLOR
		row_style.corner_radius_top_left = 22
		row_style.corner_radius_top_right = 22
		row_style.corner_radius_bottom_left = 22
		row_style.corner_radius_bottom_right = 22
		draw_style_box(row_style, row_rect)

	for i in range(TOTAL_SLOTS):
		var slot_rect = get_slot_rect(i)
		var slot_style := StyleBoxFlat.new()
		if i == TEMP_SLOT_BOARD_INDEX and not temp_slot_bonus_active:
			# Celda base suave; el cartel crema lo dibuja temp_slot_locked_root encima.
			slot_style.bg_color = BOARD_SLOT_TEMP_COLOR
		elif is_slot_active(i):
			slot_style.bg_color = BOARD_SLOT_ACTIVE_COLOR
		else:
			slot_style.bg_color = BOARD_SLOT_INACTIVE_COLOR
		slot_style.corner_radius_top_left = 18
		slot_style.corner_radius_top_right = 18
		slot_style.corner_radius_bottom_left = 18
		slot_style.corner_radius_bottom_right = 18
		draw_style_box(slot_style, slot_rect)

func _on_viewport_resized() -> void:
	update_background_scale()
	refresh_all_stack_layout()
	layout_mock_ui()
	layout_purchase_dialog_controls()
	layout_no_moves_dialog_controls()
	layout_level_up_dialog_controls()
	_sync_slot_overlay_controls()
	queue_redraw()

func update_background_scale() -> void:
	var viewport_size = get_viewport_rect().size
	if background_sprite == null:
		return
	if BackgroundTexture != null and BackgroundTexture.get_size().x > 0 and BackgroundTexture.get_size().y > 0:
		background_sprite.scale = Vector2(
			viewport_size.x / BackgroundTexture.get_size().x,
			viewport_size.y / BackgroundTexture.get_size().y
		)

func get_unscaled_stack_footprint() -> Vector2:
	return Vector2(float(StackScript.STACK_WIDTH), float(StackScript.get_visual_height()))

func get_unscaled_slot_size() -> Vector2:
	var foot := get_unscaled_stack_footprint()
	return Vector2(
		foot.x * SLOT_WIDTH_RATIO,
		foot.y * (1.0 + SLOT_HEIGHT_EXTRA_RATIO)
	)

func get_unscaled_grid_size() -> Vector2:
	var slot := get_unscaled_slot_size()
	var col_pitch := slot.x * (1.0 + SLOT_COLUMN_GAP_RATIO)
	var row_pitch := slot.y * (1.0 + SLOT_ROW_GAP_RATIO)
	return Vector2(
		float(SLOT_COLUMNS - 1) * col_pitch + slot.x,
		float(SLOT_ROWS - 1) * row_pitch + slot.y
	)

func get_slot_rect_size() -> Vector2:
	var sc: float = get_layout_scale()
	return get_unscaled_slot_size() * sc

func get_slot_row_pitch() -> float:
	return get_slot_rect_size().y * (1.0 + SLOT_ROW_GAP_RATIO)

func get_slot_column_pitch() -> float:
	return get_slot_rect_size().x * (1.0 + SLOT_COLUMN_GAP_RATIO)

func get_board_grid_width() -> float:
	var slot_w := get_slot_rect_size().x
	return float(SLOT_COLUMNS - 1) * get_slot_column_pitch() + slot_w

func get_board_grid_height() -> float:
	return (SLOT_ROWS - 1) * get_slot_row_pitch() + get_slot_rect_size().y

func get_board_origin() -> Vector2:
	var content := get_content_rect()
	var grid_w := get_board_grid_width()
	var grid_h := get_board_grid_height()
	return Vector2(
		content.position.x + (content.size.x - grid_w) * 0.5,
		content.position.y + maxf(0.0, (content.size.y - grid_h) * 0.5)
	)

func get_slot_base_y(row: int) -> float:
	var origin := get_board_origin()
	var slot_h := get_slot_rect_size().y
	var pitch := get_slot_row_pitch()
	return origin.y + float(row) * pitch + slot_h

func permanent_stack_count() -> int:
	return active_stacks

## True solo cuando existe la pila extra comprada (no basta con el temporizador ni con ser la última pila).
func has_active_temp_stack() -> bool:
	return temp_slot_bonus_active and stacks.size() == active_stacks + 1 and active_stacks >= 1

func get_board_slot_for_stack_index(stack_index: int) -> int:
	## Con temporal activa, solo la última pila (índice active_stacks) usa la celda temporal.
	if has_active_temp_stack() and stack_index == active_stacks and stack_index == stacks.size() - 1:
		return TEMP_SLOT_BOARD_INDEX
	if stack_index < 0:
		return PERMANENT_SLOT_ORDER[0]
	if stack_index >= PERMANENT_SLOT_ORDER.size():
		return PERMANENT_SLOT_ORDER[PERMANENT_SLOT_ORDER.size() - 1]
	return PERMANENT_SLOT_ORDER[stack_index]

func get_stack_position_for_index(index: int) -> Vector2:
	var slot_index = get_board_slot_for_stack_index(index)
	var col = slot_index % SLOT_COLUMNS
	var row = int(slot_index / SLOT_COLUMNS)
	var slot_w := get_slot_rect_size().x
	var x = get_board_origin().x + float(col) * get_slot_column_pitch() + slot_w * 0.5
	var sc: float = get_layout_scale()
	var slot_bottom := get_slot_base_y(row)
	# Anclar la pila al borde inferior del slot (coincide con el tope visual de las fichas).
	return Vector2(x, slot_bottom - StackScript.get_bottom_local_y() * sc)

func get_temp_slot_global_rect() -> Rect2:
	var r = get_slot_rect(TEMP_SLOT_BOARD_INDEX)
	var tl = to_global(r.position)
	var br = to_global(r.position + r.size)
	return Rect2(tl, br - tl)


func get_adjacent_extra_slot_offer_global_rect() -> Rect2:
	if adjacent_offer_board_index < 0:
		return Rect2()
	var r := get_slot_rect(adjacent_offer_board_index)
	var tl := to_global(r.position)
	var br := to_global(r.position + r.size)
	return Rect2(tl, br - tl)


func _occupied_board_slot_index_set() -> Dictionary:
	var occ := {}
	for si in range(stacks.size()):
		var bi := get_board_slot_for_stack_index(si)
		occ[bi] = true
	return occ


func find_adjacent_extra_slot_offer_board_index() -> int:
	if stacks.is_empty() or active_stacks < 1:
		return -1
	## Máximo de ranuras permanentes: 14 (la 15ª es solo temporal).
	if active_stacks >= 14:
		return -1
	var occ := _occupied_board_slot_index_set()
	## Siguiente celda en PERMANENT_SLOT_ORDER justo después de la última ranura habilitada (sin huecos).
	for ki in range(active_stacks, PERMANENT_SLOT_ORDER.size()):
		var bi: int = PERMANENT_SLOT_ORDER[ki]
		if bi == TEMP_SLOT_BOARD_INDEX and not temp_slot_bonus_active:
			continue
		if occ.has(bi):
			continue
		return bi
	return -1


func build_adjacent_slot_offer_ui() -> void:
	adjacent_slot_offer_root = Control.new()
	adjacent_slot_offer_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_offer_root.visible = false
	adjacent_slot_offer_root.z_index = 12
	hud_layer.add_child(adjacent_slot_offer_root)

	adjacent_slot_offer_panel = Panel.new()
	adjacent_slot_offer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_offer_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	adjacent_slot_offer_panel.offset_left = 0
	adjacent_slot_offer_panel.offset_top = 0
	adjacent_slot_offer_panel.offset_right = 0
	adjacent_slot_offer_panel.offset_bottom = 0
	adjacent_slot_offer_root.add_child(adjacent_slot_offer_panel)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	adjacent_slot_offer_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	center.add_child(vbox)

	adjacent_slot_offer_lbl_level = Label.new()
	adjacent_slot_offer_lbl_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_offer_lbl_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adjacent_slot_offer_lbl_level.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(adjacent_slot_offer_lbl_level)

	adjacent_slot_offer_lbl_lock = Label.new()
	adjacent_slot_offer_lbl_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_offer_lbl_lock.text = "🔒"
	adjacent_slot_offer_lbl_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(adjacent_slot_offer_lbl_lock)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(spacer)

	adjacent_slot_offer_price_row = HBoxContainer.new()
	adjacent_slot_offer_price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_offer_price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	adjacent_slot_offer_price_row.add_theme_constant_override("separation", 6)
	vbox.add_child(adjacent_slot_offer_price_row)

	adjacent_slot_offer_lbl_cost = Label.new()
	adjacent_slot_offer_lbl_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_offer_lbl_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	adjacent_slot_offer_lbl_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	adjacent_slot_offer_price_row.add_child(adjacent_slot_offer_lbl_cost)

	adjacent_slot_offer_cost_icon = TextureRect.new()
	adjacent_slot_offer_cost_icon.texture = DiamondIconTexture
	adjacent_slot_offer_cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	adjacent_slot_offer_cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	adjacent_slot_offer_cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_offer_price_row.add_child(adjacent_slot_offer_cost_icon)


func layout_adjacent_slot_star_error_label() -> void:
	if adjacent_slot_star_error_label == null or not adjacent_slot_star_error_label.visible:
		return
	var gr := get_adjacent_extra_slot_offer_global_rect()
	if gr.size == Vector2.ZERO:
		return
	var sc := get_layout_scale()
	var fs := int(clampf(12.5 * sc, 11.0, 17.0))
	adjacent_slot_star_error_label.add_theme_font_size_override("font_size", fs)
	adjacent_slot_star_error_label.add_theme_color_override("font_color", Color.WHITE)
	adjacent_slot_star_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adjacent_slot_star_error_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	adjacent_slot_star_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	adjacent_slot_star_error_label.custom_minimum_size = Vector2(gr.size.x - 8.0 * sc, 0)
	adjacent_slot_star_error_label.reset_size()
	var sz := adjacent_slot_star_error_label.get_combined_minimum_size()
	adjacent_slot_star_error_label.size = sz
	var pad := 6.0 * sc
	adjacent_slot_star_error_label.global_position = Vector2(
		gr.position.x + (gr.size.x - sz.x) * 0.5,
		gr.position.y - sz.y - pad
	)


func show_adjacent_slot_insufficient_stars_message() -> void:
	if adjacent_slot_star_error_label == null:
		return
	if adjacent_slot_star_error_tween != null:
		adjacent_slot_star_error_tween.kill()
		adjacent_slot_star_error_tween = null
	adjacent_slot_star_error_label.text = "No tienes suficientes estrellas"
	adjacent_slot_star_error_label.modulate = Color.WHITE
	adjacent_slot_star_error_label.visible = true
	layout_adjacent_slot_star_error_label()
	var tw := create_tween()
	adjacent_slot_star_error_tween = tw
	tw.tween_property(adjacent_slot_star_error_label, "modulate", Color(1, 1, 1, 0), 2.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(adjacent_slot_star_error_label):
			adjacent_slot_star_error_label.visible = false
			adjacent_slot_star_error_label.modulate = Color.WHITE
	)


func is_click_on_adjacent_extra_slot_offer(mouse_pos: Vector2) -> bool:
	if adjacent_slot_offer_root == null or not adjacent_slot_offer_root.visible:
		return false
	if adjacent_offer_board_index < 0:
		return false
	return get_adjacent_extra_slot_offer_global_rect().has_point(mouse_pos)


func try_purchase_adjacent_extra_slot() -> void:
	if adjacent_offer_board_index < 0:
		return
	if active_stacks >= 14:
		return
	if player_stars < adjacent_slot_next_price:
		show_adjacent_slot_insufficient_stars_message()
		return
	player_stars -= adjacent_slot_next_price
	adjacent_slot_next_price *= 2
	active_stacks += 1
	# Mantener la pila temporal como última cuando está activa.
	add_new_stack_for_level_unlock()
	refresh_all_stack_layout()
	board_locked = false
	update_stars_display()
	_sync_slot_overlay_controls()
	queue_redraw()
	save_game()
	print("Ranura extra comprada. Próximo precio (estrellas): ", adjacent_slot_next_price)


func update_adjacent_slot_offer_ui() -> void:
	if adjacent_slot_offer_root == null:
		return
	adjacent_offer_board_index = find_adjacent_extra_slot_offer_board_index()
	if adjacent_offer_board_index < 0:
		adjacent_slot_offer_root.visible = false
		layout_adjacent_slot_star_error_label()
		return
	var gr := get_adjacent_extra_slot_offer_global_rect()
	var sc := get_layout_scale()
	var inset := 4.0 * sc
	adjacent_slot_offer_root.visible = true
	adjacent_slot_offer_root.global_position = gr.position + Vector2(inset, inset)
	adjacent_slot_offer_root.size = gr.size - Vector2(inset * 2.0, inset * 2.0)
	var corner_px := int(clampf(22.0 * sc, 16.0, 30.0))
	adjacent_slot_offer_panel.add_theme_stylebox_override("panel", _make_temp_slot_locked_panel_style(corner_px))

	var g := TEMP_LOCKED_PANEL_GREEN
	if adjacent_slot_offer_lbl_level != null:
		adjacent_slot_offer_lbl_level.text = "Gratis al nivel %d" % ADJACENT_EXTRA_SLOT_FREE_AT_LEVEL
		adjacent_slot_offer_lbl_level.add_theme_font_size_override("font_size", int(clampf(19.0 * sc, 16.0, 26.0)))
		adjacent_slot_offer_lbl_level.add_theme_color_override("font_color", g)
	if adjacent_slot_offer_lbl_lock != null:
		adjacent_slot_offer_lbl_lock.add_theme_font_size_override("font_size", int(clampf(48.0 * sc, 40.0, 60.0)))
		adjacent_slot_offer_lbl_lock.add_theme_color_override("font_color", g)
	if adjacent_slot_offer_lbl_cost != null:
		adjacent_slot_offer_lbl_cost.text = str(adjacent_slot_next_price)
		adjacent_slot_offer_lbl_cost.add_theme_font_size_override("font_size", int(clampf(28.0 * sc, 22.0, 36.0)))
		adjacent_slot_offer_lbl_cost.add_theme_color_override("font_color", g)
	if adjacent_slot_offer_cost_icon != null:
		var icon_px := int(clampf(32.0 * sc, 26.0, 40.0))
		adjacent_slot_offer_cost_icon.custom_minimum_size = Vector2(icon_px, icon_px)
	layout_adjacent_slot_star_error_label()


func _sync_slot_overlay_controls() -> void:
	update_temp_slot_overlay_label()
	update_adjacent_slot_offer_ui()

func _make_temp_slot_locked_panel_style(corner_px: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = TEMP_LOCKED_PANEL_CREAM
	s.border_color = Color(0.22, 0.44, 0.28, 0.5)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = corner_px
	s.corner_radius_top_right = corner_px
	s.corner_radius_bottom_left = corner_px
	s.corner_radius_bottom_right = corner_px
	return s

func build_temp_slot_locked_ui() -> void:
	temp_slot_locked_root = Control.new()
	temp_slot_locked_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_locked_root.visible = false
	hud_layer.add_child(temp_slot_locked_root)

	temp_slot_locked_panel = Panel.new()
	temp_slot_locked_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_locked_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	temp_slot_locked_panel.offset_left = 0
	temp_slot_locked_panel.offset_top = 0
	temp_slot_locked_panel.offset_right = 0
	temp_slot_locked_panel.offset_bottom = 0
	temp_slot_locked_root.add_child(temp_slot_locked_panel)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	temp_slot_locked_root.add_child(center)

	temp_slot_locked_root.clip_contents = true

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	temp_slot_locked_vbox = vbox
	center.add_child(vbox)

	temp_slot_locked_hourglass = Label.new()
	temp_slot_locked_hourglass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_locked_hourglass.text = "⏳"
	temp_slot_locked_hourglass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temp_slot_locked_hourglass.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(temp_slot_locked_hourglass)

	temp_slot_locked_lbl_60 = Label.new()
	temp_slot_locked_lbl_60.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_locked_lbl_60.text = "60 seg"
	temp_slot_locked_lbl_60.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temp_slot_locked_lbl_60.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	temp_slot_locked_lbl_60.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(temp_slot_locked_lbl_60)

	temp_slot_locked_lbl_seg = Label.new()
	temp_slot_locked_lbl_seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_locked_lbl_seg.visible = false
	vbox.add_child(temp_slot_locked_lbl_seg)

	temp_slot_locked_cost_row = HBoxContainer.new()
	temp_slot_locked_cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	temp_slot_locked_cost_row.add_theme_constant_override("separation", 4)
	temp_slot_locked_cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(temp_slot_locked_cost_row)

	temp_slot_locked_lbl_cost = Label.new()
	temp_slot_locked_lbl_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_locked_lbl_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temp_slot_locked_lbl_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	temp_slot_locked_cost_row.add_child(temp_slot_locked_lbl_cost)

	temp_slot_locked_cost_icon = TextureRect.new()
	temp_slot_locked_cost_icon.texture = DiamondIconTexture
	temp_slot_locked_cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	temp_slot_locked_cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	temp_slot_locked_cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_locked_cost_row.add_child(temp_slot_locked_cost_icon)


func is_click_on_temp_slot_cell(mouse_pos: Vector2) -> bool:
	if temp_slot_bonus_active:
		return false
	return get_temp_slot_global_rect().has_point(mouse_pos)

func update_temp_slot_overlay_label() -> void:
	if temp_slot_locked_root == null or temp_slot_timer_label == null:
		return
	var gr = get_temp_slot_global_rect()
	var sc = get_layout_scale()
	var font = ThemeDB.fallback_font

	if not temp_slot_bonus_active:
		temp_slot_locked_root.visible = true
		temp_slot_timer_label.visible = false
		var inset = maxf(2.0, gr.size.x * 0.04)
		temp_slot_locked_root.global_position = gr.position + Vector2(inset, inset)
		temp_slot_locked_root.size = gr.size - Vector2(inset * 2.0, inset * 2.0)
		var fit := minf(temp_slot_locked_root.size.x, temp_slot_locked_root.size.y)
		var corner_px := int(clampf(fit * 0.14, 10.0, 22.0))
		temp_slot_locked_panel.add_theme_stylebox_override("panel", _make_temp_slot_locked_panel_style(corner_px))

		var g = TEMP_LOCKED_PANEL_GREEN
		var hourglass_fs := int(clampf(fit * 0.24, 18.0, 36.0))
		var duration_fs := int(clampf(fit * 0.18, 14.0, 28.0))
		var cost_fs := int(clampf(fit * 0.17, 14.0, 26.0))
		var icon_px := clampf(fit * 0.20, 18.0, 32.0)
		if temp_slot_locked_vbox != null:
			temp_slot_locked_vbox.add_theme_constant_override("separation", int(clampf(fit * 0.04, 2.0, 6.0)))

		temp_slot_locked_hourglass.add_theme_font_size_override("font_size", hourglass_fs)
		temp_slot_locked_hourglass.add_theme_color_override("font_color", g)

		temp_slot_locked_lbl_60.text = "60 seg"
		temp_slot_locked_lbl_60.add_theme_font_size_override("font_size", duration_fs)
		temp_slot_locked_lbl_60.add_theme_color_override("font_color", g)
		temp_slot_locked_lbl_60.add_theme_constant_override("outline_size", 2)
		temp_slot_locked_lbl_60.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))

		temp_slot_locked_lbl_cost.text = str(TEMP_SLOT_COST_DIAMONDS)
		temp_slot_locked_lbl_cost.add_theme_font_size_override("font_size", cost_fs)
		temp_slot_locked_lbl_cost.add_theme_color_override("font_color", g)
		if temp_slot_locked_cost_icon != null:
			temp_slot_locked_cost_icon.custom_minimum_size = Vector2(icon_px, icon_px)
	else:
		temp_slot_locked_root.visible = false
		var show_timer = temp_slot_time_remaining > 0.05
		temp_slot_timer_label.visible = show_timer
		if not show_timer:
			return
		var tfs = int(14 * sc)
		temp_slot_timer_label.text = "%.0f s" % maxf(0.0, temp_slot_time_remaining)
		temp_slot_timer_label.add_theme_font_size_override("font_size", tfs)
		temp_slot_timer_label.add_theme_color_override("font_color", Color(0.1, 0.34, 0.14, 0.96))
		temp_slot_timer_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.75))
		temp_slot_timer_label.add_theme_constant_override("outline_size", 3)
		var tw: float = font.get_string_size(temp_slot_timer_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x
		var th: float = font.get_height(tfs)
		var pad = 5.0 * sc
		var timer_size = Vector2(tw + pad * 2.0, th + pad * 1.25)
		temp_slot_timer_label.size = timer_size
		temp_slot_timer_label.global_position = Vector2(gr.end.x - timer_size.x - pad * 0.35, gr.position.y + pad * 0.35)

func get_slot_rect(index: int) -> Rect2:
	var col = index % SLOT_COLUMNS
	var row = int(index / SLOT_COLUMNS)
	var origin = get_board_origin()
	var slot_size = get_slot_rect_size()
	var center_x = origin.x + float(col) * get_slot_column_pitch() + slot_size.x * 0.5
	var base_y = get_slot_base_y(row)
	var top_left = Vector2(center_x - slot_size.x * 0.5, base_y - slot_size.y)
	return Rect2(top_left, slot_size)

func get_row_rect(row: int) -> Rect2:
	var origin = get_board_origin()
	var scale = get_layout_scale()
	var slot_size = get_slot_rect_size()
	var top_y = get_slot_base_y(row) - slot_size.y
	return Rect2(Vector2(origin.x, top_y), Vector2(get_board_grid_width(), slot_size.y))

func get_board_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var avail_h: float = viewport_size.y - get_ad_footer_height()
	var slot := get_slot_rect_size()
	var grid_w := get_board_grid_width()
	var grid_h := get_board_grid_height()
	var pad_x: float = slot.x * BOARD_PAD_X_SLOTS
	var pad_y: float = slot.y * BOARD_PAD_Y_SLOTS
	var panel_w: float = grid_w + pad_x * 2.0
	var panel_h: float = grid_h + pad_y * 2.0
	var x: float = (viewport_size.x - panel_w) * 0.5
	var y: float = avail_h * BOARD_PANEL_TOP_RATIO
	return Rect2(Vector2(x, y), Vector2(panel_w, panel_h))

func get_ad_footer_height() -> float:
	var viewport_height = get_viewport_rect().size.y
	return clampf(viewport_height * AD_FOOTER_HEIGHT_RATIO, AD_FOOTER_MIN_HEIGHT, AD_FOOTER_MAX_HEIGHT)

func get_layout_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	var avail_h: float = viewport_size.y - get_ad_footer_height()
	var grid_size: Vector2 = get_unscaled_grid_size()
	var width_scale: float = (
		viewport_size.x * GRID_FILL_WIDTH_RATIO / (grid_size.x * BOARD_GRID_WIDTH_PADDING)
	)
	var height_scale: float = (
		avail_h * GRID_FILL_HEIGHT_RATIO / (grid_size.y * BOARD_GRID_HEIGHT_PADDING)
	)
	return clampf(min(width_scale, height_scale), LAYOUT_SCALE_MIN, LAYOUT_SCALE_MAX)

func get_slot_cell_size() -> Vector2:
	return Vector2(get_slot_column_pitch(), get_slot_row_pitch())

func get_content_rect() -> Rect2:
	var board_rect = get_board_rect()
	var pad = min(board_rect.size.x, board_rect.size.y) * PANEL_CONTENT_PADDING_RATIO
	return Rect2(
		board_rect.position + Vector2(pad, pad),
		board_rect.size - Vector2(pad * 2.0, pad * 2.0)
	)

func get_panel_corner_radius() -> int:
	return int(clampf(26.0 * get_layout_scale(), 20.0, 30.0))

func get_hud_layout_scale() -> float:
	return get_layout_scale() * HUD_SIZE_MULTIPLIER

func _apply_chip_font(chip: Panel, font_size: int) -> void:
	if chip == null:
		return
	var lbl: Label = chip.get_meta("chip_label")
	if lbl != null:
		lbl.add_theme_font_size_override("font_size", font_size)

func build_mock_ui() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud_root)

	home_chip = create_chip_panel("⌂", Color(0.97, 0.97, 0.93, 0.92), Color(0.84, 0.87, 0.79, 0.85), 30)
	home_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	life_chip = create_chip_with_icon_panel(LifeIconTexture, "%d  Vidas" % lives, Color(0.97, 0.97, 0.93, 0.92), Color(0.84, 0.87, 0.79, 0.85), 24)
	life_chip_icon = life_chip.get_meta("chip_icon")
	life_chip_label = life_chip.get_meta("chip_label")
	stars_chip = create_chip_panel("%d ⭐" % player_stars, Color(0.97, 0.97, 0.93, 0.92), Color(0.84, 0.87, 0.79, 0.85), 22)
	stars_chip_label = stars_chip.get_meta("chip_label")
	settings_chip = create_chip_panel("⚙", Color(0.97, 0.97, 0.93, 0.92), Color(0.84, 0.87, 0.79, 0.85), 30)
	hud_root.add_child(home_chip)
	hud_root.add_child(life_chip)
	hud_root.add_child(stars_chip)
	hud_root.add_child(settings_chip)

	progress_container = create_panel(Color(0.95, 0.96, 0.90, 0.94), Color(0.84, 0.88, 0.78, 0.9), 24)
	progress_fill = ColorRect.new()
	progress_fill.color = Color(0.56, 0.80, 0.30, 0.92)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_fill.clip_contents = true
	progress_container.add_child(progress_fill)
	progress_knob = create_panel(Color(0.97, 0.98, 0.92, 0.96), Color(0.70, 0.82, 0.53, 0.9), 24)
	progress_left_label = create_label("1", 30, Color(0.31, 0.46, 0.25))
	progress_right_label = create_label("0%", 28, Color(0.31, 0.46, 0.25))
	progress_container.add_child(progress_knob)
	progress_container.add_child(progress_left_label)
	progress_container.add_child(progress_right_label)
	hud_root.add_child(progress_container)

	cta_shadow = create_shadow_panel(36)
	hud_root.add_child(cta_shadow)
	cta_button = create_panel(Color(0.64, 0.83, 0.43, 0.95), Color(0.75, 0.88, 0.58, 1.0), 34)
	cta_label = create_label("Repartir", 52, Color(0.95, 0.98, 0.92))
	cta_button.add_child(cta_label)
	hud_root.add_child(cta_button)

	var action_index := 0
	for action_text in ["Mezclar", "Martillo", "Guante"]:
		var action_shadow = create_shadow_panel(42)
		var action = create_panel(Color(0.96, 0.97, 0.92, 0.94), Color(0.84, 0.88, 0.78, 0.9), 40)
		var wildcard_type: String = WILDCARD_TYPES[action_index]
		var icon = create_wildcard_icon_texture_rect(get_wildcard_icon_texture(wildcard_type))
		var lbl = create_label(action_text, 24, Color(0.29, 0.45, 0.29))
		hud_root.add_child(action_shadow)
		hud_root.add_child(action)
		hud_root.add_child(icon)
		hud_root.add_child(lbl)
		var count_badge = create_panel(Color(0.99, 0.99, 0.95, 0.98), Color(0.80, 0.86, 0.72, 0.92), 14)
		var count_label = create_label("", 18, Color(0.27, 0.43, 0.24))
		count_badge.add_child(count_label)
		hud_root.add_child(count_badge)
		action_shadows.append(action_shadow)
		action_pills.append(action)
		action_icons.append(icon)
		action_labels.append(lbl)
		action_count_badges.append(count_badge)
		action_count_labels.append(count_label)
		action_index += 1

	build_purchase_dialog()

	build_no_moves_dialog()

	build_level_up_dialog()

	build_temp_slot_locked_ui()

	temp_slot_timer_label = Label.new()
	temp_slot_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_slot_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temp_slot_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	temp_slot_timer_label.visible = false
	hud_layer.add_child(temp_slot_timer_label)

	build_adjacent_slot_offer_ui()

	adjacent_slot_star_error_label = Label.new()
	adjacent_slot_star_error_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adjacent_slot_star_error_label.visible = false
	adjacent_slot_star_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adjacent_slot_star_error_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	adjacent_slot_star_error_label.z_index = 32
	hud_layer.add_child(adjacent_slot_star_error_label)

	update_stars_display()
	update_life_display()
	update_wildcard_badges()
	layout_mock_ui()
	_sync_slot_overlay_controls()

func layout_mock_ui() -> void:
	if hud_root == null:
		return
	var viewport_size = get_viewport_rect().size
	var board_rect = get_board_rect()
	var scale = get_layout_scale()
	var chip_y = maxf(12.0 * scale, board_rect.position.y - 132.0 * scale)
	var chip_h = HUD_CHIP_HEIGHT * scale
	var gap = HUD_CHIP_GAP * scale
	var edge_margin = HUD_EDGE_MARGIN * scale
	var corner_size = HUD_CORNER_SIZE * scale
	var life_w = HUD_CHIP_LIFE_W * scale
	var stars_w = HUD_CHIP_STARS_W * scale
	var total_w = life_w + stars_w + gap
	var start_x = (viewport_size.x - total_w) * 0.5
	home_chip.position = Vector2(edge_margin, chip_y)
	home_chip.size = Vector2(corner_size, chip_h)
	life_chip.position = Vector2(start_x, chip_y)
	life_chip.size = Vector2(life_w, chip_h)
	if stars_chip != null:
		stars_chip.position = Vector2(start_x + life_w + gap, chip_y)
		stars_chip.size = Vector2(stars_w, chip_h)
	settings_chip.position = Vector2(viewport_size.x - edge_margin - corner_size, chip_y)
	settings_chip.size = Vector2(corner_size, chip_h)
	_apply_chip_font(home_chip, int(30.0 * scale))
	_apply_chip_font(settings_chip, int(30.0 * scale))
	_apply_chip_font(life_chip, int(24.0 * scale))
	_apply_chip_font(stars_chip, int(22.0 * scale))
	if life_chip_icon != null:
		var life_icon_size = chip_h * 0.72
		life_chip_icon.custom_minimum_size = Vector2(life_icon_size, life_icon_size)

	var progress_w = viewport_size.x * 0.78
	var progress_h = 54 * scale
	var progress_y = min(chip_y + chip_h + HUD_CHIP_TO_PROGRESS_GAP * scale, board_rect.position.y - progress_h - 12 * scale)
	progress_container.position = Vector2((viewport_size.x - progress_w) * 0.5, progress_y)
	progress_container.size = Vector2(progress_w, progress_h)
	var bar_rect = Rect2(Vector2(54 * scale, progress_h * 0.36), Vector2(progress_w - 110 * scale, progress_h * 0.28))
	progress_bar_max_width = bar_rect.size.x
	progress_bar_height = bar_rect.size.y
	progress_fill.position = bar_rect.position
	progress_knob.position = Vector2(8 * scale, 8 * scale)
	progress_knob.size = Vector2(progress_h - 16 * scale, progress_h - 16 * scale)
	progress_left_label.position = progress_knob.position
	progress_left_label.size = progress_knob.size
	progress_right_label.position = Vector2(progress_w - 62 * scale, 0)
	progress_right_label.size = Vector2(54 * scale, progress_h)
	update_progress_bar(false)

	var cta_w = board_rect.size.x * CTA_WIDTH_RATIO
	var cta_h = CTA_HEIGHT * scale
	cta_button.position = Vector2((viewport_size.x - cta_w) * 0.5, board_rect.end.y + 14 * scale)
	cta_button.size = Vector2(cta_w, cta_h)
	cta_shadow.position = cta_button.position + Vector2(0, 6 * scale)
	cta_shadow.size = cta_button.size
	cta_label.position = Vector2(0, 0)
	cta_label.size = cta_button.size
	if cta_label != null:
		cta_label.add_theme_font_size_override("font_size", int(CTA_FONT_SIZE * scale))

	var action_y = cta_button.position.y + cta_h + 20.0 * scale
	var action_size = WILDCARD_BUTTON_SIZE * scale
	var action_gap = WILDCARD_BUTTON_GAP * scale
	var actions_total_w = action_size * 3 + action_gap * 2
	var actions_start_x = (viewport_size.x - actions_total_w) * 0.5
	var badge_w = 22.0 * scale
	var badge_h = 18.0 * scale
	var badge_font = int(15.0 * scale)
	for i in range(action_pills.size()):
		var x = actions_start_x + i * (action_size + action_gap)
		action_shadows[i].position = Vector2(x, action_y + 4.0 * scale)
		action_shadows[i].size = Vector2(action_size, action_size)
		action_pills[i].position = Vector2(x, action_y)
		action_pills[i].size = Vector2(action_size, action_size)
		var icon_size = action_size * 0.88
		action_icons[i].position = Vector2(
			x + (action_size - icon_size) * 0.5,
			action_y + (action_size - icon_size) * 0.5
		)
		action_icons[i].size = Vector2(icon_size, icon_size)
		action_labels[i].visible = false
		action_count_badges[i].position = Vector2(x + action_size - badge_w * 0.85, action_y - 5.0 * scale)
		action_count_badges[i].size = Vector2(badge_w, badge_h)
		action_count_labels[i].position = Vector2.ZERO
		action_count_labels[i].size = action_count_badges[i].size
		action_count_labels[i].add_theme_font_size_override("font_size", badge_font)

	_sync_slot_overlay_controls()

func update_life_display() -> void:
	if life_chip_label != null:
		life_chip_label.text = "%d  Vidas" % lives

func create_panel(bg: Color, border: Color, radius: int) -> Panel:
	var panel = Panel.new()
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

func create_shadow_panel(radius: int) -> Panel:
	var panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.19, 0.28, 0.18, 0.18)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", style)
	return panel

func create_chip_panel(text: String, bg: Color, border: Color, font_size: int) -> Panel:
	var panel = create_panel(bg, border, 28)
	panel.clip_contents = true
	var lbl = create_label(text, font_size, Color(0.24, 0.43, 0.25))
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 0
	lbl.offset_top = 0
	lbl.offset_right = 0
	lbl.offset_bottom = 0
	panel.add_child(lbl)
	panel.set_meta("chip_label", lbl)
	return panel

func create_chip_with_icon_panel(texture: Texture2D, text: String, bg: Color, border: Color, font_size: int) -> Panel:
	var panel = create_panel(bg, border, 28)
	panel.clip_contents = true
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_top = 0
	content.offset_right = -12
	content.offset_bottom = 0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(font_size * 1.65, font_size * 1.65)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var lbl = create_label(text, font_size, Color(0.24, 0.43, 0.25))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(lbl)

	panel.set_meta("chip_label", lbl)
	panel.set_meta("chip_icon", icon)
	return panel

func create_label(text: String, font_size: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func is_slot_active(slot_index: int) -> bool:
	for i in range(stacks.size()):
		if get_board_slot_for_stack_index(i) == slot_index:
			return true
	return false

func is_control_clicked(ctrl: Control, point: Vector2) -> bool:
	if ctrl == null or not ctrl.visible:
		return false
	return ctrl.get_global_rect().has_point(point)

func perform_mix_action() -> void:
	if board_locked:
		return

	var all_values: Array = []
	for stack in stacks:
		while not stack.is_empty():
			all_values.append(stack.pop())

	if all_values.is_empty():
		return

	# Orden estable por número/color.
	all_values.sort()

	# Reparto conservativo:
	# - intenta mantener pilas homogéneas por valor (ordenadas de menor a mayor),
	# - nunca descarta fichas: si no entra en el esquema ideal, hace fallback en cualquier pila con hueco.
	var stack_idx := 0
	var placed_count := 0
	var i := 0
	while i < all_values.size():
		var value := int(all_values[i])
		var remaining_of_value := 0
		while i < all_values.size() and int(all_values[i]) == value:
			remaining_of_value += 1
			i += 1

		while remaining_of_value > 0:
			while stack_idx < stacks.size() and stacks[stack_idx].is_full():
				stack_idx += 1

			if stack_idx >= stacks.size():
				break

			var st: Node = stacks[stack_idx]
			var room: int = 0
			if st.has_method("free_slots"):
				room = int(st.free_slots())
			else:
				room = int(STACK_CAPACITY - st.coins.size())
			var to_place: int = mini(room, remaining_of_value)
			for _k in range(to_place):
				st.push(value)
				placed_count += 1
			remaining_of_value -= to_place

			# Siguiente valor en la siguiente pila para mantener orden visual por bloques.
			stack_idx += 1

		# Fallback extremo para garantizar que no se pierdan fichas nunca.
		while remaining_of_value > 0:
			var fallback_done := false
			for st_fallback in stacks:
				if st_fallback.is_full():
					continue
				st_fallback.push(value)
				placed_count += 1
				remaining_of_value -= 1
				fallback_done = true
				break
			if not fallback_done:
				push_error("Mix: sin espacio para reubicar fichas (esto no debería pasar).")
				break

	if placed_count != all_values.size():
		push_error("Mix inconsistente: esperadas %d, colocadas %d" % [all_values.size(), placed_count])

	# Mostrar primero el ordenado; fusionar en el siguiente frame.
	queue_redraw()
	call_deferred("resolve_board_after_action")

func perform_hammer_action() -> void:
	if board_locked:
		return
	hammer_mode_active = true
	clear_selection()
	print("Martillo activo: selecciona una pila para vaciarla.")

func perform_glove_action() -> void:
	print("Guante: todavia no esta implementado.")

func apply_hammer_on_stack(target_stack: Node) -> void:
	if target_stack == null:
		return
	while not target_stack.is_empty():
		target_stack.pop()
	hammer_mode_active = false
	resolve_board_after_action()

func try_use_wildcard(wildcard_type: String) -> void:
	if board_locked:
		return
	if not is_wildcard_unlocked(wildcard_type):
		print(
			"%s se desbloquea en el nivel %d."
			% [get_wildcard_display_name(wildcard_type), get_wildcard_unlock_level(wildcard_type)]
		)
		return
	if int(wildcard_counts.get(wildcard_type, 0)) <= 0:
		open_purchase_dialog(wildcard_type)
		return

	match wildcard_type:
		"mix":
			consume_wildcard(wildcard_type)
			perform_mix_action()
		"hammer":
			consume_wildcard(wildcard_type)
			perform_hammer_action()
		"glove":
			consume_wildcard(wildcard_type)
			perform_glove_action()
		_:
			return

func consume_wildcard(wildcard_type: String) -> void:
	wildcard_counts[wildcard_type] = max(0, int(wildcard_counts.get(wildcard_type, 0)) - 1)
	update_wildcard_badges()

func add_wildcard_use(wildcard_type: String, amount: int = 1) -> void:
	if not is_wildcard_unlocked(wildcard_type):
		return
	wildcard_counts[wildcard_type] = int(wildcard_counts.get(wildcard_type, 0)) + max(1, amount)
	update_wildcard_badges()

func get_wildcard_unlock_level(wildcard_type: String) -> int:
	return int(WILDCARD_UNLOCK_LEVEL.get(wildcard_type, 9999))

func is_wildcard_unlocked(wildcard_type: String) -> bool:
	return get_current_level() >= get_wildcard_unlock_level(wildcard_type)

func reset_wildcard_state() -> void:
	for wildcard_type in WILDCARD_TYPES:
		wildcard_counts[wildcard_type] = 0
		wildcard_unlock_granted[wildcard_type] = false
	sync_wildcard_unlocks()

func _restore_wildcard_state_from_snapshot() -> void:
	var counts = checkpoint_snapshot.get("wildcard_counts", null)
	if counts is Dictionary:
		for wildcard_type in WILDCARD_TYPES:
			wildcard_counts[wildcard_type] = int(counts.get(wildcard_type, 0))
	var granted = checkpoint_snapshot.get("wildcard_unlock_granted", null)
	if granted is Dictionary:
		for wildcard_type in WILDCARD_TYPES:
			wildcard_unlock_granted[wildcard_type] = bool(granted.get(wildcard_type, false))
	sync_wildcard_unlocks()

## Concede 3 usos gratis la primera vez que el nivel desbloquea cada comodín.
func sync_wildcard_unlocks() -> void:
	for wildcard_type in WILDCARD_TYPES:
		if is_wildcard_unlocked(wildcard_type):
			if not wildcard_unlock_granted.get(wildcard_type, false):
				wildcard_counts[wildcard_type] = WILDCARD_INITIAL_USES
				wildcard_unlock_granted[wildcard_type] = true
				print(
					"Comodín desbloqueado: %s (%d usos gratis)"
					% [get_wildcard_display_name(wildcard_type), WILDCARD_INITIAL_USES]
				)
		else:
			wildcard_counts[wildcard_type] = 0
			wildcard_unlock_granted[wildcard_type] = false
	update_wildcard_badges()

func update_wildcard_badges() -> void:
	for i in range(mini(action_count_labels.size(), WILDCARD_TYPES.size())):
		var wildcard_type: String = WILDCARD_TYPES[i]
		var unlocked := is_wildcard_unlocked(wildcard_type)
		var uses_left := int(wildcard_counts.get(wildcard_type, 0))
		var modulate_color := Color.WHITE if unlocked else WILDCARD_LOCKED_MODULATE
		if i < action_pills.size():
			action_pills[i].modulate = modulate_color
		if i < action_shadows.size():
			action_shadows[i].modulate = modulate_color
		if i < action_icons.size():
			action_icons[i].modulate = modulate_color
		if i < action_count_badges.size():
			action_count_badges[i].visible = true
		if i < action_count_labels.size():
			if not unlocked:
				action_count_labels[i].text = "🔒"
			else:
				action_count_labels[i].text = str(uses_left) if uses_left > 0 else "+"

func update_gem_display() -> void:
	## Reservado si más adelante volvés a mostrar gemas en el HUD.
	pass


func update_stars_display() -> void:
	if stars_chip_label != null:
		stars_chip_label.text = "%d ⭐" % player_stars

func build_purchase_dialog() -> void:
	purchase_overlay = ColorRect.new()
	purchase_overlay.color = Color(0.0, 0.0, 0.0, 0.12)
	purchase_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	purchase_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	purchase_overlay.visible = false
	# Debe quedar por encima de overlays de ranuras/ofertas.
	purchase_overlay.z_as_relative = false
	purchase_overlay.z_index = 300
	hud_layer.add_child(purchase_overlay)

	purchase_card = create_panel(Color(0.95, 0.97, 0.92, 0.985), Color(0.86, 0.91, 0.81, 1.0), 48)
	purchase_card.mouse_filter = Control.MOUSE_FILTER_STOP
	purchase_card.z_as_relative = false
	purchase_card.z_index = 301
	purchase_overlay.add_child(purchase_card)

	purchase_title_label = create_label("Mezclar", 72, Color(0.24, 0.45, 0.26))
	purchase_card.add_child(purchase_title_label)

	purchase_icon_circle = create_panel(Color(0.92, 0.95, 0.88, 0.92), Color(0.79, 0.87, 0.72, 0.95), 200)
	purchase_card.add_child(purchase_icon_circle)

	purchase_icon_texture_rect = create_wildcard_icon_texture_rect(MixIconTexture)
	purchase_icon_circle.add_child(purchase_icon_texture_rect)

	purchase_count_badge = create_panel(Color(0.63, 0.80, 0.44, 0.97), Color(0.76, 0.88, 0.58, 1.0), 30)
	purchase_count_label = create_label("x1", 44, Color(0.95, 0.98, 0.92))
	purchase_count_badge.add_child(purchase_count_label)
	purchase_card.add_child(purchase_count_badge)

	purchase_buy_button = Button.new()
	purchase_buy_button.focus_mode = Control.FOCUS_NONE
	purchase_buy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	purchase_buy_button.add_theme_stylebox_override("normal", make_flat_style(Color(0.61, 0.82, 0.41, 0.98), Color(0.74, 0.88, 0.56, 1.0), 36, 1))
	purchase_buy_button.add_theme_stylebox_override("hover", make_flat_style(Color(0.67, 0.86, 0.47, 1.0), Color(0.79, 0.90, 0.63, 1.0), 36, 1))
	purchase_buy_button.add_theme_stylebox_override("pressed", make_flat_style(Color(0.56, 0.76, 0.37, 1.0), Color(0.69, 0.82, 0.50, 1.0), 36, 1))
	purchase_buy_button.pressed.connect(_on_purchase_confirmed)
	purchase_card.add_child(purchase_buy_button)

	purchase_buy_center = CenterContainer.new()
	purchase_buy_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	purchase_buy_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	purchase_buy_button.add_child(purchase_buy_center)

	purchase_buy_content = HBoxContainer.new()
	purchase_buy_content.alignment = BoxContainer.ALIGNMENT_CENTER
	purchase_buy_content.add_theme_constant_override("separation", 24)
	purchase_buy_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	purchase_buy_center.add_child(purchase_buy_content)

	purchase_buy_gem_icon = TextureRect.new()
	purchase_buy_gem_icon.texture = DiamondIconTexture
	purchase_buy_gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	purchase_buy_gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	purchase_buy_gem_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	purchase_buy_cost_label = create_label(str(WILDCARD_COST_DIAMONDS), 64, Color(0.95, 0.98, 0.92))
	purchase_buy_content.add_child(purchase_buy_gem_icon)
	purchase_buy_content.add_child(purchase_buy_cost_label)

	purchase_close_button = Button.new()
	purchase_close_button.text = "✕"
	purchase_close_button.focus_mode = Control.FOCUS_NONE
	purchase_close_button.custom_minimum_size = Vector2(88, 88)
	purchase_close_button.add_theme_font_size_override("font_size", 54)
	purchase_close_button.add_theme_color_override("font_color", Color(0.95, 0.98, 0.93))
	purchase_close_button.add_theme_color_override("font_hover_color", Color(0.95, 0.98, 0.93))
	purchase_close_button.add_theme_color_override("font_pressed_color", Color(0.95, 0.98, 0.93))
	purchase_close_button.add_theme_stylebox_override("normal", make_flat_style(Color(0.92, 0.52, 0.52, 0.98), Color(0.86, 0.45, 0.45, 1.0), 44, 2))
	purchase_close_button.add_theme_stylebox_override("hover", make_flat_style(Color(0.95, 0.58, 0.58, 1.0), Color(0.90, 0.50, 0.50, 1.0), 44, 2))
	purchase_close_button.add_theme_stylebox_override("pressed", make_flat_style(Color(0.86, 0.46, 0.46, 1.0), Color(0.80, 0.40, 0.40, 1.0), 44, 2))
	purchase_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	purchase_close_button.pressed.connect(_on_purchase_close_pressed)
	purchase_card.add_child(purchase_close_button)
	layout_purchase_dialog_controls()

func open_purchase_dialog(wildcard_type: String) -> void:
	if not is_wildcard_unlocked(wildcard_type):
		return
	if purchase_overlay == null:
		return
	pending_purchase_type = wildcard_type
	update_purchase_dialog_content(wildcard_type)
	purchase_overlay.visible = true
	purchase_overlay.move_to_front()
	layout_purchase_dialog_controls()

func _on_purchase_confirmed() -> void:
	if pending_purchase_type.is_empty():
		return
	if gems < WILDCARD_COST_DIAMONDS:
		print("No alcanza: necesitas %d diamantes." % WILDCARD_COST_DIAMONDS)
		return
	gems -= WILDCARD_COST_DIAMONDS
	add_wildcard_use(pending_purchase_type, 1)
	update_gem_display()
	pending_purchase_type = ""
	if purchase_overlay != null:
		purchase_overlay.visible = false
	save_game()

func layout_purchase_dialog_controls() -> void:
	if purchase_overlay == null or purchase_card == null:
		return
	var viewport_size = get_viewport_rect().size
	var scale = clampf(min(viewport_size.x / 1080.0, viewport_size.y / 1920.0), 0.75, 1.2)
	var card_size = Vector2(760.0, 980.0) * scale
	purchase_card.size = card_size
	purchase_card.position = (viewport_size - card_size) * 0.5

	purchase_title_label.position = Vector2(70, 78) * scale
	purchase_title_label.size = Vector2(card_size.x - 140 * scale, 98 * scale)
	purchase_title_label.add_theme_font_size_override("font_size", int(80 * scale))

	var circle_size = Vector2(460, 460) * scale
	purchase_icon_circle.size = circle_size
	purchase_icon_circle.position = Vector2((card_size.x - circle_size.x) * 0.5, 220 * scale)
	if purchase_icon_texture_rect != null:
		var icon_size = circle_size * 0.64
		purchase_icon_texture_rect.size = icon_size
		purchase_icon_texture_rect.position = (circle_size - icon_size) * 0.5

	purchase_count_badge.size = Vector2(140, 90) * scale
	purchase_count_badge.position = purchase_icon_circle.position + Vector2(circle_size.x - purchase_count_badge.size.x * 0.65, circle_size.y - purchase_count_badge.size.y * 0.95)
	purchase_count_label.position = Vector2.ZERO
	purchase_count_label.size = purchase_count_badge.size
	purchase_count_label.add_theme_font_size_override("font_size", int(58 * scale))

	purchase_buy_button.size = Vector2(card_size.x - 120 * scale, 132 * scale)
	purchase_buy_button.position = Vector2((card_size.x - purchase_buy_button.size.x) * 0.5, card_size.y - purchase_buy_button.size.y - 70 * scale)
	purchase_buy_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	purchase_buy_center.offset_left = 0
	purchase_buy_center.offset_top = 0
	purchase_buy_center.offset_right = 0
	purchase_buy_center.offset_bottom = 0
	if purchase_buy_gem_icon != null:
		var gem_icon_size = 74.0 * scale
		purchase_buy_gem_icon.custom_minimum_size = Vector2(gem_icon_size, gem_icon_size)
		purchase_buy_gem_icon.size = Vector2(gem_icon_size, gem_icon_size)
	purchase_buy_cost_label.add_theme_font_size_override("font_size", int(76 * scale))

	purchase_close_button.size = Vector2(88, 88) * scale
	purchase_close_button.position = Vector2(card_size.x - purchase_close_button.size.x * 0.65, -purchase_close_button.size.y * 0.40)
	purchase_close_button.add_theme_font_size_override("font_size", int(54 * scale))

func _on_purchase_close_pressed() -> void:
	pending_purchase_type = ""
	if purchase_overlay != null:
		purchase_overlay.visible = false

func _on_purchase_close_requested() -> void:
	_on_purchase_close_pressed()

func update_purchase_dialog_content(wildcard_type: String) -> void:
	if purchase_title_label == null:
		return
	purchase_title_label.text = get_wildcard_display_name(wildcard_type)
	if purchase_icon_texture_rect != null:
		purchase_icon_texture_rect.texture = get_wildcard_icon_texture(wildcard_type)
	purchase_count_label.text = "x1"
	purchase_buy_cost_label.text = str(WILDCARD_COST_DIAMONDS)

func get_wildcard_display_name(wildcard_type: String) -> String:
	match wildcard_type:
		"mix":
			return "Mezclar"
		"hammer":
			return "Martillo"
		"glove":
			return "Guante"
		_:
			return "comodin"

func get_wildcard_icon_texture(wildcard_type: String) -> Texture2D:
	match wildcard_type:
		"mix":
			return MixIconTexture
		"hammer":
			return HammerIconTexture
		"glove":
			return GloveIconTexture
		_:
			return MixIconTexture

func create_wildcard_icon_texture_rect(texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func make_flat_style(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func build_no_moves_dialog() -> void:
	no_moves_overlay = ColorRect.new()
	no_moves_overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	no_moves_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	no_moves_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	no_moves_overlay.visible = false
	# Debe quedar por encima de cualquier otro overlay del HUD.
	no_moves_overlay.z_as_relative = false
	no_moves_overlay.z_index = 320
	hud_layer.add_child(no_moves_overlay)

	no_moves_card = create_panel(Color(0.95, 0.97, 0.92, 0.985), Color(0.86, 0.91, 0.81, 1.0), 48)
	no_moves_card.mouse_filter = Control.MOUSE_FILTER_STOP
	no_moves_card.z_as_relative = false
	no_moves_card.z_index = 321
	no_moves_overlay.add_child(no_moves_card)

	no_moves_margin = MarginContainer.new()
	no_moves_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	no_moves_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	no_moves_card.add_child(no_moves_margin)

	no_moves_vbox = VBoxContainer.new()
	no_moves_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	no_moves_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	no_moves_vbox.add_theme_constant_override("separation", 28)
	no_moves_margin.add_child(no_moves_vbox)

	no_moves_title_label = create_label("No hay movimientos", 64, Color(0.24, 0.45, 0.26))
	no_moves_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	no_moves_vbox.add_child(no_moves_title_label)

	no_moves_restart_button = make_no_moves_button(
		"Reiniciar", Color(0.61, 0.82, 0.41, 0.98), Color(0.74, 0.88, 0.56, 1.0)
	)
	no_moves_restart_button.pressed.connect(_on_no_moves_restart_pressed)
	no_moves_vbox.add_child(no_moves_restart_button)

	no_moves_buy_button = make_no_moves_button(
		"Comprar %d vidas por %d" % [BUY_LIVES_AMOUNT, BUY_LIVES_COST],
		Color(0.61, 0.82, 0.41, 0.98), Color(0.74, 0.88, 0.56, 1.0)
	)
	no_moves_buy_button.pressed.connect(_on_no_moves_buy_lives_pressed)
	no_moves_vbox.add_child(no_moves_buy_button)

	no_moves_ad_button = make_no_moves_button(
		"Ver un anuncio para obtener 1 vida", Color(0.40, 0.62, 0.86, 0.98), Color(0.56, 0.74, 0.92, 1.0)
	)
	no_moves_ad_button.pressed.connect(_on_no_moves_watch_ad_pressed)
	no_moves_vbox.add_child(no_moves_ad_button)

	layout_no_moves_dialog_controls()

func make_no_moves_button(text: String, bg: Color, border: Color) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 118)
	btn.add_theme_stylebox_override("normal", make_flat_style(bg, border, 36, 1))
	btn.add_theme_stylebox_override("hover", make_flat_style(bg.lightened(0.06), border, 36, 1))
	btn.add_theme_stylebox_override("pressed", make_flat_style(bg.darkened(0.08), border, 36, 1))
	var lbl := create_label(text, 36, Color(0.97, 0.99, 0.94))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 20
	lbl.offset_right = -20
	lbl.offset_top = 8
	lbl.offset_bottom = -8
	btn.add_child(lbl)
	btn.set_meta("label", lbl)
	return btn

func layout_no_moves_dialog_controls() -> void:
	if no_moves_overlay == null or no_moves_card == null:
		return
	var viewport_size = get_viewport_rect().size
	var scale = clampf(min(viewport_size.x / 1080.0, viewport_size.y / 1920.0), 0.75, 1.2)
	var card_size = Vector2(min(viewport_size.x * 0.88, 840.0 * scale), 660.0 * scale)
	no_moves_card.size = card_size
	no_moves_card.position = (viewport_size - card_size) * 0.5

	if no_moves_margin != null:
		no_moves_margin.add_theme_constant_override("margin_left", int(54 * scale))
		no_moves_margin.add_theme_constant_override("margin_right", int(54 * scale))
		no_moves_margin.add_theme_constant_override("margin_top", int(64 * scale))
		no_moves_margin.add_theme_constant_override("margin_bottom", int(58 * scale))
	if no_moves_vbox != null:
		no_moves_vbox.add_theme_constant_override("separation", int(28 * scale))
	if no_moves_title_label != null:
		no_moves_title_label.add_theme_font_size_override("font_size", int(60 * scale))

	for btn in [no_moves_restart_button, no_moves_buy_button, no_moves_ad_button]:
		if btn == null:
			continue
		btn.custom_minimum_size = Vector2(0, 118 * scale)
		var lbl: Label = btn.get_meta("label")
		if lbl != null:
			lbl.add_theme_font_size_override("font_size", int(36 * scale))

func show_no_moves_panel() -> void:
	if no_moves_overlay == null:
		return
	board_locked = true
	clear_selection()
	hammer_mode_active = false
	update_no_moves_buttons()
	no_moves_overlay.visible = true
	no_moves_overlay.move_to_front()
	layout_no_moves_dialog_controls()

func hide_no_moves_panel() -> void:
	if no_moves_overlay != null:
		no_moves_overlay.visible = false

## Con vidas disponibles: solo "Reiniciar". Tras perder la última vida: comprar vidas o ver anuncio.
func update_no_moves_buttons() -> void:
	var has_lives := lives > 0
	if no_moves_restart_button != null:
		no_moves_restart_button.visible = has_lives
	if no_moves_buy_button != null:
		no_moves_buy_button.visible = not has_lives
		var buy_lbl: Label = no_moves_buy_button.get_meta("label")
		if buy_lbl != null:
			buy_lbl.text = "Comprar %d vidas por %d" % [BUY_LIVES_AMOUNT, BUY_LIVES_COST]
	if no_moves_ad_button != null:
		no_moves_ad_button.visible = not has_lives

func _restart_after_no_moves() -> void:
	hide_no_moves_panel()
	restore_checkpoint()
	board_locked = false
	save_game()
	check_blocked_state()

func _on_no_moves_restart_pressed() -> void:
	if lives <= 0:
		update_no_moves_buttons()
		return
	lives -= 1
	update_life_display()
	if lives <= 0:
		# Se perdió la última vida: no se reinicia. El cartel pasa a ofrecer comprar vidas o ver anuncio.
		update_no_moves_buttons()
		layout_no_moves_dialog_controls()
		return
	_restart_after_no_moves()

func _on_no_moves_buy_lives_pressed() -> void:
	if player_stars < BUY_LIVES_COST:
		print("No alcanza: necesitas %d para comprar vidas." % BUY_LIVES_COST)
		return
	player_stars -= BUY_LIVES_COST
	lives = BUY_LIVES_AMOUNT
	update_life_display()
	update_stars_display()
	_restart_after_no_moves()

func _on_no_moves_watch_ad_pressed() -> void:
	# Mock: ver un anuncio otorga 1 vida.
	lives = mini(INITIAL_LIVES, lives + AD_LIVES_AMOUNT)
	update_life_display()
	_restart_after_no_moves()

func build_level_up_dialog() -> void:
	level_up_overlay = ColorRect.new()
	level_up_overlay.color = Color(0.0, 0.0, 0.0, 0.40)
	level_up_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_up_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	level_up_overlay.visible = false
	level_up_overlay.z_as_relative = false
	level_up_overlay.z_index = 310
	hud_layer.add_child(level_up_overlay)

	level_up_card = create_panel(Color(0.95, 0.97, 0.92, 0.985), Color(0.86, 0.91, 0.81, 1.0), 48)
	level_up_card.mouse_filter = Control.MOUSE_FILTER_STOP
	level_up_card.z_as_relative = false
	level_up_card.z_index = 311
	level_up_overlay.add_child(level_up_card)

	level_up_margin = MarginContainer.new()
	level_up_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_up_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_up_card.add_child(level_up_margin)

	level_up_vbox = VBoxContainer.new()
	level_up_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	level_up_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_up_vbox.add_theme_constant_override("separation", 20)
	level_up_margin.add_child(level_up_vbox)

	level_up_title_label = create_label("¡Subiste de nivel!", 64, Color(0.24, 0.45, 0.26))
	level_up_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_up_vbox.add_child(level_up_title_label)

	level_up_subtitle_label = create_label("Nivel 2", 44, Color(0.35, 0.52, 0.32))
	level_up_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_up_vbox.add_child(level_up_subtitle_label)

	level_up_continue_button = make_no_moves_button(
		"Continuar", Color(0.61, 0.82, 0.41, 0.98), Color(0.74, 0.88, 0.56, 1.0)
	)
	level_up_continue_button.pressed.connect(_on_level_up_continue_pressed)
	level_up_vbox.add_child(level_up_continue_button)

	layout_level_up_dialog_controls()

func layout_level_up_dialog_controls() -> void:
	if level_up_overlay == null or level_up_card == null:
		return
	var viewport_size = get_viewport_rect().size
	var scale = clampf(min(viewport_size.x / 1080.0, viewport_size.y / 1920.0), 0.75, 1.2)
	var card_size = Vector2(min(viewport_size.x * 0.88, 780.0 * scale), 520.0 * scale)
	level_up_card.size = card_size
	level_up_card.position = (viewport_size - card_size) * 0.5

	if level_up_margin != null:
		level_up_margin.add_theme_constant_override("margin_left", int(54 * scale))
		level_up_margin.add_theme_constant_override("margin_right", int(54 * scale))
		level_up_margin.add_theme_constant_override("margin_top", int(64 * scale))
		level_up_margin.add_theme_constant_override("margin_bottom", int(58 * scale))
	if level_up_vbox != null:
		level_up_vbox.add_theme_constant_override("separation", int(24 * scale))
	if level_up_title_label != null:
		level_up_title_label.add_theme_font_size_override("font_size", int(60 * scale))
	if level_up_subtitle_label != null:
		level_up_subtitle_label.add_theme_font_size_override("font_size", int(44 * scale))
	if level_up_continue_button != null:
		level_up_continue_button.custom_minimum_size = Vector2(0, 118 * scale)
		var lbl: Label = level_up_continue_button.get_meta("label")
		if lbl != null:
			lbl.add_theme_font_size_override("font_size", int(36 * scale))

func show_level_up_panel(level: int) -> void:
	if level_up_overlay == null:
		return
	hide_no_moves_panel()
	board_locked = true
	clear_selection()
	hammer_mode_active = false
	if level_up_title_label != null:
		level_up_title_label.text = "¡Subiste de nivel!"
	if level_up_subtitle_label != null:
		var desc := get_checkpoint_level_description(level)
		if desc.is_empty():
			level_up_subtitle_label.text = "Nivel %d" % level
		else:
			level_up_subtitle_label.text = "Nivel %d\n%s" % [level, desc]
	_force_progress_bar_display(1.0)
	level_up_overlay.visible = true
	level_up_overlay.move_to_front()
	layout_level_up_dialog_controls()

func hide_level_up_panel() -> void:
	if level_up_overlay != null:
		level_up_overlay.visible = false
	board_locked = false
	update_progress_bar(false)

func _on_level_up_continue_pressed() -> void:
	hide_level_up_panel()
	check_blocked_state()

extends Node2D

const MAX_CAPACITY = 10
const CoinScene = preload("res://coin.tscn")
const STACK_WIDTH := 122.0
const COIN_BASE_DIAMETER := 52.0
const COIN_TARGET_WIDTH := 115.0
const COIN_SCALE := COIN_TARGET_WIDTH / COIN_BASE_DIAMETER
const COIN_STEP_Y := 16.0
## Altura visual de 10 monedas apiladas: 9 pasos + diámetro de ficha = 259.
const STACK_HEIGHT := float(MAX_CAPACITY - 1) * COIN_STEP_Y + COIN_TARGET_WIDTH
const COIN_TOP_OFFSET := -STACK_HEIGHT + 1.0

## Altura real de una pila; los slots del tablero deben coincidir con esto (10 monedas).
static func get_visual_height(coin_count: int = MAX_CAPACITY) -> float:
	if coin_count <= 0:
		return 0.0
	if coin_count == 1:
		return COIN_TARGET_WIDTH
	return float(coin_count - 1) * COIN_STEP_Y + COIN_TARGET_WIDTH

static func get_top_local_y(coin_count: int = MAX_CAPACITY) -> float:
	return COIN_TOP_OFFSET - COIN_TARGET_WIDTH * 0.5

static func get_bottom_local_y(coin_count: int = MAX_CAPACITY) -> float:
	var last_index := clampi(coin_count, 1, MAX_CAPACITY)
	return COIN_TOP_OFFSET + float(last_index - 1) * COIN_STEP_Y + COIN_TARGET_WIDTH * 0.5
const SELECTED_BLOCK_LIFT_Y := -13.0

var coins: Array = []
var coin_nodes: Array = []
var pending_incoming_values: Array = []
var is_selected := false
var flash_alpha := 0.0
var selection_tween: Tween = null
var fusion_tween: Tween = null
var move_tweens: Array = []

func _ready() -> void:
	queue_redraw()

func is_empty() -> bool:
	return coins.size() == 0

func is_full() -> bool:
	return _total_occupied_slots() >= MAX_CAPACITY

func top_value() -> int:
	if is_empty():
		return -1
	return coins[-1]

func top_block_size() -> int:
	if is_empty():
		return 0
	var top = coins[-1]
	var count = 0
	for i in range(coins.size() - 1, -1, -1):
		if coins[i] == top:
			count += 1
		else:
			break
	return count

func is_homogeneous() -> bool:
	if is_empty():
		return false
	var top = coins[0]
	for c in coins:
		if c != top:
			return false
	return true

func is_ready_to_fuse() -> bool:
	# Solo fusionar con monedas efectivamente adjuntas a la pila.
	return coins.size() >= MAX_CAPACITY and is_homogeneous()

func free_slots() -> int:
	return MAX_CAPACITY - _total_occupied_slots()

func can_receive_value(value: int) -> bool:
	if is_full():
		return false
	return _effective_top_value_for_receive() in [-1, value]

func set_selected(selected: bool, animated: bool = true) -> void:
	is_selected = selected
	if animated:
		animate_selected_block_lift()
	else:
		if selection_tween != null and selection_tween.is_valid():
			selection_tween.kill()
		selection_tween = null
		update_coin_positions(false)
	queue_redraw()

func kill_all_tweens() -> void:
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	selection_tween = null
	if fusion_tween != null and fusion_tween.is_valid():
		fusion_tween.kill()
	fusion_tween = null
	for tw in move_tweens:
		if tw is Tween and tw.is_valid():
			tw.kill()
	move_tweens.clear()
	for coin_node in coin_nodes:
		_clear_coin_flight_tween_meta(coin_node)

func has_active_move_animations() -> bool:
	for tw in move_tweens:
		if tw is Tween and tw.is_valid():
			return true
	return false

func push(value: int, play_spawn: bool = true) -> bool:
	if is_full():
		return false
	
	coins.append(value)
	
	# Crear la moneda visualmente
	var coin_node = CoinScene.instantiate()
	coin_node.set_value(value)
	coin_node.position = get_coin_local_position(coins.size())
	add_child(coin_node)
	coin_nodes.append(coin_node)
	refresh_visible_numbers()
	update_coin_positions(false)
	if play_spawn:
		play_coin_spawn_animation(coin_node)
	else:
		coin_node.scale = get_coin_local_scale()
	queue_redraw()
	
	return true

func move_top_block_to(target: Node) -> int:
	if is_empty() or target == self:
		return 0
	var value = top_value()
	if not target.can_receive_value(value):
		return 0
	var amount = mini(top_block_size(), target.free_slots())
	var moved_amount := 0
	for i in range(amount):
		var moved_coin = take_top_coin_for_move()
		if moved_coin.is_empty():
			break
		if target.has_method("receive_moved_coin"):
			target.receive_moved_coin(moved_coin["value"], moved_coin["node"], i * 0.05)
		else:
			target.push(moved_coin["value"])
			moved_coin["node"].queue_free()
		moved_amount += 1
	return moved_amount

func remove_all_and_fuse() -> int:
	if not is_ready_to_fuse():
		return -1
	var fused_value = top_value() + 1
	_clear_pending_incoming()
	while not is_empty():
		pop()
	return fused_value

func pop() -> int:
	if is_empty():
		return -1
	
	var value = coins.pop_back()
	
	# Eliminar la moneda visualmente
	if coin_nodes.size() > 0:
		var coin_node = coin_nodes.pop_back()
		if is_instance_valid(coin_node):
			_kill_coin_flight_tween(coin_node)
			coin_node.queue_free()
	refresh_visible_numbers()
	update_coin_positions(false)
	
	queue_redraw()
	return value

func _draw() -> void:
	# Sin fondo de pila: solo feedback visual.
	var outer_body = Rect2(
		Vector2(-STACK_WIDTH / 2.0, -STACK_HEIGHT),
		Vector2(STACK_WIDTH, STACK_HEIGHT)
	)

	# Highlight cuando está seleccionada
	if is_selected:
		draw_rect(outer_body.grow(4.0), Color(0.72, 0.90, 1.0, 0.45), false, 4.0)

	# Flash temporal para feedback de fusion.
	if flash_alpha > 0.01:
		draw_rect(outer_body.grow(2.0), Color(1.0, 0.94, 0.72, flash_alpha))

func get_board_layout_scale() -> float:
	var parent_node := get_parent()
	if parent_node and parent_node.has_method("get_layout_scale"):
		return float(parent_node.get_layout_scale())
	return 1.0

func get_coin_local_scale() -> Vector2:
	return Vector2.ONE * COIN_SCALE

func get_coin_flight_scale() -> Vector2:
	return Vector2.ONE * (get_board_layout_scale() * COIN_SCALE)

func normalize_coin_scales() -> void:
	var local_scale := get_coin_local_scale()
	for coin_node in coin_nodes:
		if is_instance_valid(coin_node):
			coin_node.scale = local_scale

func play_fusion_animation() -> void:
	if fusion_tween != null and fusion_tween.is_valid():
		fusion_tween.kill()
	var base_sc := get_board_layout_scale()
	var punch_sc := base_sc * 1.05
	fusion_tween = create_tween()
	fusion_tween.set_trans(Tween.TRANS_SINE)
	fusion_tween.set_ease(Tween.EASE_OUT)
	fusion_tween.tween_method(set_flash_alpha, flash_alpha, 0.65, 0.10)
	fusion_tween.tween_method(set_flash_alpha, 0.65, 0.0, 0.22)
	fusion_tween.parallel().tween_property(self, "scale", Vector2.ONE * punch_sc, 0.10)
	fusion_tween.tween_property(self, "scale", Vector2.ONE * base_sc, 0.12)

func set_flash_alpha(v: float) -> void:
	flash_alpha = v
	queue_redraw()

func play_coin_spawn_animation(coin_node: Node2D) -> void:
	if not is_instance_valid(coin_node) or not is_inside_tree():
		return
	_kill_coin_flight_tween(coin_node)
	coin_node.scale = Vector2(0.25, 0.25)
	var tween = create_tween()
	move_tweens.append(tween)
	tween.finished.connect(func() -> void:
		move_tweens.erase(tween)
	)
	_track_coin_flight_tween(coin_node, tween)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_node, "scale", get_coin_local_scale(), 0.16)

func _kill_coin_flight_tween(coin_node: Node) -> void:
	if coin_node == null or not is_instance_valid(coin_node):
		return
	if coin_node.has_meta("flight_tween"):
		var existing = coin_node.get_meta("flight_tween")
		coin_node.remove_meta("flight_tween")
		if existing is Tween and existing.is_valid():
			existing.kill()
		move_tweens.erase(existing)

func _clear_coin_flight_tween_meta(coin_node: Node) -> void:
	## Quita la meta sin matar el tween (seguro desde el callback del propio tween).
	if coin_node == null or not is_instance_valid(coin_node):
		return
	if coin_node.has_meta("flight_tween"):
		coin_node.remove_meta("flight_tween")

func _track_coin_flight_tween(coin_node: Node, tween: Tween) -> void:
	if coin_node == null or tween == null or not is_instance_valid(coin_node):
		return
	_kill_coin_flight_tween(coin_node)
	coin_node.set_meta("flight_tween", tween)
	tween.finished.connect(func() -> void:
		_clear_coin_flight_tween_meta(coin_node)
	)

func refresh_visible_numbers() -> void:
	for i in range(coin_nodes.size()):
		var coin_node = coin_nodes[i]
		if not is_instance_valid(coin_node):
			continue
		if coin_node.has_method("set_number_visible"):
			# Mostrar numero solo en la ficha del tope para evitar solapados visuales.
			coin_node.set_number_visible(i == coin_nodes.size() - 1)

func get_coin_local_position(stack_count: int) -> Vector2:
	# Apila desde arriba hacia abajo.
	return Vector2(0, COIN_TOP_OFFSET + ((stack_count - 1) * COIN_STEP_Y))

func take_top_coin_for_move() -> Dictionary:
	if is_empty() or coin_nodes.is_empty():
		return {}

	var value = coins.pop_back()
	var coin_node: Node2D = coin_nodes.pop_back()
	if not is_instance_valid(coin_node):
		return {}
	_kill_coin_flight_tween(coin_node)
	var board := get_parent()
	if board == null or not is_instance_valid(board):
		coin_node.queue_free()
		return {}
	coin_node.reparent(board)
	coin_node.scale = get_coin_flight_scale()
	coin_node.z_index = 30
	refresh_visible_numbers()
	update_coin_positions(false)
	queue_redraw()
	return {
		"value": value,
		"node": coin_node,
	}

func receive_moved_coin(value: int, moving_coin: Node2D, delay: float = 0.0) -> void:
	if not is_instance_valid(moving_coin) or not moving_coin.is_inside_tree():
		return
	if not is_inside_tree() or is_full():
		_kill_coin_flight_tween(moving_coin)
		moving_coin.queue_free()
		return

	pending_incoming_values.append(value)
	var target_local = get_coin_local_position(_total_occupied_slots())
	var target_global = to_global(target_local)
	var flight_scale := get_coin_flight_scale()
	if moving_coin.has_method("set_number_visible"):
		moving_coin.set_number_visible(false)

	# Tween del tablero (padre), no de la pila: sobrevive si la pila se limpia,
	# y evitamos kill() del propio tween desde su callback.
	var board := get_parent()
	var tween: Tween
	if board != null and is_instance_valid(board):
		tween = board.create_tween()
	else:
		tween = create_tween()
	move_tweens.append(tween)
	tween.finished.connect(func() -> void:
		move_tweens.erase(tween)
	)
	_track_coin_flight_tween(moving_coin, tween)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(moving_coin, "global_position", target_global, 0.18)
	tween.parallel().tween_property(moving_coin, "scale", flight_scale, 0.18)
	# Adjuntar en el frame siguiente al terminar el vuelo: evita mutar nodos
	# dentro del callback interno del Tween (inestable en móvil).
	tween.tween_callback(func() -> void:
		_clear_coin_flight_tween_meta(moving_coin)
		if is_instance_valid(self):
			call_deferred("_attach_moved_coin", moving_coin, target_local, value)
		elif is_instance_valid(moving_coin):
			moving_coin.queue_free()
	)

func _attach_moved_coin(moving_coin: Node2D, target_local: Vector2, value: int) -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		if is_instance_valid(moving_coin):
			moving_coin.queue_free()
		return
	_clear_coin_flight_tween_meta(moving_coin)
	if not _consume_pending_incoming_value(value):
		if is_instance_valid(moving_coin):
			moving_coin.queue_free()
		return
	if not is_instance_valid(moving_coin):
		return
	coins.append(value)
	moving_coin.reparent(self)
	moving_coin.position = target_local
	moving_coin.scale = get_coin_local_scale()
	moving_coin.z_index = 0
	coin_nodes.append(moving_coin)
	refresh_visible_numbers()
	update_coin_positions(false)
	queue_redraw()
	_try_resolve_after_pending_settled()

func _total_occupied_slots() -> int:
	return coins.size() + pending_incoming_values.size()

func _effective_top_value_for_receive() -> int:
	if not pending_incoming_values.is_empty():
		return int(pending_incoming_values[-1])
	return top_value()

func _consume_pending_incoming_value(value: int) -> bool:
	for i in range(pending_incoming_values.size() - 1, -1, -1):
		if int(pending_incoming_values[i]) == value:
			pending_incoming_values.remove_at(i)
			return true
	return false

func _clear_pending_incoming() -> void:
	pending_incoming_values.clear()

func _try_resolve_after_pending_settled() -> void:
	if not pending_incoming_values.is_empty():
		return
	# Solo mirar pendientes de otras pilas; no bloquear por el tween actual
	# (acabamos de aterrizar y ese tween todavía "está activo").
	var board = get_parent()
	if board == null or not is_instance_valid(board):
		return
	if board.has_method("has_pending_incoming_coins") and board.has_pending_incoming_coins():
		return
	if board.has_method("request_resolve_board_after_action"):
		var rev: int = int(board.get("board_revision")) if board.get("board_revision") != null else -1
		board.call_deferred("request_resolve_board_after_action", rev)

func animate_selected_block_lift() -> void:
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	selection_tween = null
	if coin_nodes.is_empty():
		return
	var has_valid_coin := false
	for coin_node in coin_nodes:
		if is_instance_valid(coin_node):
			has_valid_coin = true
			break
	if not has_valid_coin:
		return
	selection_tween = create_tween()
	selection_tween.set_trans(Tween.TRANS_SINE)
	selection_tween.set_ease(Tween.EASE_OUT)
	update_coin_positions(true)

func update_coin_positions(animated: bool) -> void:
	if coin_nodes.is_empty():
		return
	var movable_block_size := top_block_size() if is_selected else 0
	var movable_start := coin_nodes.size() - movable_block_size
	var tweened_any := false
	for i in range(coin_nodes.size()):
		var coin_node: Node2D = coin_nodes[i]
		if not is_instance_valid(coin_node):
			continue
		var target = get_coin_local_position(i + 1)
		if i >= movable_start:
			target.y += SELECTED_BLOCK_LIFT_Y
		if animated and selection_tween != null and selection_tween.is_valid():
			selection_tween.parallel().tween_property(coin_node, "position", target, 0.12)
			tweened_any = true
		else:
			coin_node.position = target
	if animated and selection_tween != null and selection_tween.is_valid() and not tweened_any:
		selection_tween.kill()
		selection_tween = null

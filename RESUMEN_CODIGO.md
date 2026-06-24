Querés…	Constante
Slots más altos/bajos: SLOT_HEIGHT_EXTRA_RATIO
Tablero más angosto/ancho: SLOT_WIDTH_RATIO (ej. 0.95 = más angosto)
Más espacio entre filas: SLOT_ROW_GAP_RATIO
Más espacio entre columnas: SLOT_COLUMN_GAP_RATIO
Tablero más grande en pantalla: GRID_FILL_WIDTH_RATIO / GRID_FILL_HEIGHT_RATIO
Más/menos borde verde: BOARD_PAD_X_SLOTS / BOARD_PAD_Y_SLOTS
Subir/bajar el tablero: BOARD_PANEL_TOP_RATIO



#Resumen del código — Coin Stack Puzzle

Documento generado para explicar la lógica del juego en los scripts principales del proyecto (Godot 4, GDScript). Los archivos bajo `addons/godot_mcp/` son un plugin externo y no se detallan aquí.

---

## 1. Qué hace el proyecto (visión general)

Es un puzzle de **pilas de monedas** numeradas. El jugador:

- **Hace clic** en una pila y luego en otra para mover el **bloque superior** (todas las monedas consecutivas del mismo valor que el tope).
- Solo puede apilar sobre una pila **vacía** o sobre un tope **del mismo número**.
- Con **10 monedas iguales** en una pila se **fusionan** en una moneda de valor `valor + 1`.
- **Repartir** (tirada) reparte números aleatorios entre las pilas con hueco.
- Hay **niveles** (`max_value` es el número objetivo a alcanzar en el tope para subir de nivel), **comodines** (mezclar, martillo, guante), **ranura temporal** (diamantes) y **ranura extra adyacente** (estrellas mock).

**Escenas:** `Main.tscn` cuelga el nodo raíz del tablero; `stack.tscn` instancia cada pila; `coin.tscn` es cada ficha visual.

---

## 2. Tipos de datos de Godot que aparecen (referencia rápida)

| Tipo / concepto | Uso en este proyecto |
|-----------------|----------------------|
| `int`, `float`, `bool`, `String` | Valores numéricos, tiempo, banderas, textos UI. |
| `Vector2` | Posiciones 2D, escalas (`x`, `y`), tamaños en pantalla. |
| `Rect2` | Rectángulos (posición + tamaño) para celdas del tablero y clics. |
| `Color` | Colores de UI, fondos, bordes, texto. |
| `Array` | Listas ordenadas: pilas, valores de tirada, nodos de UI. |
| `Dictionary` | Pares clave-valor: conteos en mezcla, `wildcard_counts`, resultados `{"value", "node"}`. |
| `Node`, `Node2D` | Jerarquía de escena; pilas y monedas son nodos. |
| `Control`, `Panel`, `Label`, `Button`, `TextureRect`, `CanvasLayer` | Interfaz 2D encima del juego. |
| `Sprite2D`, `Area2D` | Fondo y moneda con colisión. |
| `InputEvent`, `InputEventMouseButton` | Entrada de ratón y teclas. |
| `Tween` | Animaciones suaves (escala, flash, movimiento de monedas). |
| `StyleBoxFlat` | Cajas redondeadas dibujadas en `_draw()` o como tema de `Panel`. |
| `Texture2D` | Imágenes precargadas con `preload()`. |
| `Callable` | Referencia a función (p. ej. callback al terminar un tween). |

**Nota:** En GDScript, `Array` y `Dictionary` son flexibles: pueden contener `int`, `Node`, etc. sin tipado estricto salvo que uses tipado explícito (`Array[int]`, etc.).

---

## 3. `coin.gd` — Ficha individual (`extends Area2D`)

### Constantes y variables

| Nombre | Tipo (conceptual) | Qué hace |
|--------|-------------------|----------|
| `VALUE_COLORS` | `Array` de `Color` | Paleta por valor de moneda (índice cíclico `(v-1) % tamaño`). |
| `COIN_RADIUS` | `float` | Radio lógico de la moneda (26 px) para colisión y escala. |
| `value` | `int` | Número mostrado en la ficha (1, 2, 3…). |
| `number_visible` | `bool` | Si el `Label` con el número se muestra (solo el tope de la pila lo muestra a veces). |
| `shadow_sprite`, `sprite`, `highlight_sprite`, `label`, `collision_shape` | nodos `@onready` | Referencias a hijos de `coin.tscn`. |
| `coin_color` | `Color` | Color actual derivado de `value`. |

### Funciones

| Función | Qué hace |
|---------|----------|
| `_ready()` | Desactiva `input_pickable`, escala sprites, configura `Label` y colisión, llama `update_display()`. |
| `update_display()` | Aplica color y texto del número según `value` y `number_visible`. |
| `set_value(new_value)` | Asigna `value` y refresca la vista. |
| `apply_color_by_value()` | Pone colores en sprite/sombra/brillo según `coin_color`. |
| `get_color_for_value(v)` | Devuelve color para un entero `v` (blanco si `v <= 0`). |
| `set_number_visible(visible)` | Controla visibilidad del número en el `Label`. |
| `configure_collision()` | Asigna un `CircleShape2D` al `CollisionShape2D`. |
| `configure_sprite_scale()` | Escala texturas al diámetro objetivo según textura y `COIN_RADIUS`. |

---

## 4. `stack.gd` — Una pila de monedas (`extends Node2D`)

### Constantes

| Nombre | Valor / uso |
|--------|----------------|
| `MAX_CAPACITY` | 10 — capacidad máxima de la pila (fusiona al llenarse con todas iguales). |
| `CoinScene` | Escena precargada para instanciar cada moneda visual. |
| `STACK_WIDTH`, `STACK_HEIGHT` | Tamaño lógico de la pila para dibujar y hit-testing en `main.gd`. |
| `COIN_BASE_DIAMETER`, `COIN_TARGET_WIDTH`, `COIN_SCALE` | Escala visual de monedas respecto al sprite base. |
| `COIN_TOP_OFFSET`, `COIN_STEP_Y` | Posición vertical base y paso entre monedas apiladas. |
| `SELECTED_BLOCK_LIFT_Y` | Levanta visualmente el bloque seleccionable al seleccionar la pila. |

### Variables

| Nombre | Tipo | Qué hace |
|--------|------|----------|
| `coins` | `Array` (de `int`) | Valores de abajo a arriba; el tope es el último elemento. |
| `coin_nodes` | `Array` (nodos `Coin`) | Nodos visuales en el mismo orden que `coins`. |
| `pending_incoming_values` | `Array` | Valores que aún están animándose hacia la pila (`receive_moved_coin`). |
| `is_selected` | `bool` | Si la pila está seleccionada para mover bloque. |
| `flash_alpha` | `float` | Opacidad del flash al fusionar (dibujo en `_draw`). |
| `selection_tween` | `Tween` | Animación del levantamiento del bloque seleccionado. |

### Funciones principales

| Función | Retorno | Qué hace |
|---------|---------|----------|
| `is_empty()` | `bool` | `coins` sin elementos. |
| `is_full()` | `bool` | Ocupación ≥ `MAX_CAPACITY` (incluye pendientes). |
| `top_value()` | `int` | Valor del tope o `-1` si vacía. |
| `top_block_size()` | `int` | Cuántas monedas iguales consecutivas hay desde el tope hacia abajo. |
| `is_homogeneous()` | `bool` | Si **toda** la pila es el mismo número. |
| `is_ready_to_fuse()` | `bool` | Llena (`MAX_CAPACITY`) y homogénea → puede fusionar. |
| `free_slots()` | `int` | Huecos libres hasta `MAX_CAPACITY`. |
| `can_receive_value(value)` | `bool` | Si acepta ese valor (vacía o tope efectivo igual a `value`). |
| `set_selected(selected)` | void | Marca selección y anima levantamiento. |
| `push(value)` | `bool` | Añade moneda al final: datos + nodo instanciado + animación spawn. |
| `move_top_block_to(target)` | `int` | Mueve hasta N monedas del bloque superior a otra pila; usa `receive_moved_coin` o `push`. |
| `remove_all_and_fuse()` | `int` | Vacía la pila y devuelve `top_value + 1`, o `-1` si no estaba lista. |
| `pop()` | `int` | Saca el tope (datos + nodo). |
| `_draw()` | void | Dibuja contorno/highlight selección y flash de fusión. |
| `play_fusion_animation()` | void | Tween de flash + ligera escala. |
| `set_flash_alpha(v)` | void | Actualiza `flash_alpha` y redibuja. |
| `play_coin_spawn_animation(coin_node)` | void | Escala desde pequeño a `COIN_SCALE`. |
| `refresh_visible_numbers()` | void | Solo la última moneda muestra número en el label. |
| `get_coin_local_position(stack_count)` | `Vector2` | Posición local Y según cantidad apilada. |
| `take_top_coin_for_move()` | `Dictionary` | Saca tope: claves `"value"` y `"node"` (nodo reparentado al padre de la pila). |
| `receive_moved_coin(value, moving_coin, delay)` | void | Anima la moneda entrante y al terminar llama `_attach_moved_coin`. |
| `_attach_moved_coin(...)` | void | Incorpora la moneda a `coins`/`coin_nodes`; puede disparar `resolve_board_after_action` en el padre. |
| `_total_occupied_slots()` | `int` | `coins.size() + pending_incoming_values.size()`. |
| `_effective_top_value_for_receive()` | `int` | Tope considerando monedas en vuelo. |
| `_consume_pending_incoming_value(value)` | `bool` | Quita una entrada pendiente igual a `value`. |
| `_clear_pending_incoming()` | void | Limpia pendientes. |
| `_try_resolve_after_pending_settled()` | void | Si ya fusionable y sin pendientes, pide al tablero resolver fusiones/nivel. |
| `animate_selected_block_lift()` | void | Reinicia tween de posiciones de monedas del bloque superior. |
| `update_coin_positions(animated)` | void | Coloca cada nodo moneda; si seleccionada, sube el bloque superior. |

---

## 5. `main.gd` — Tablero, reglas, UI y economía mock (`extends Node2D`)

### Constantes precargadas (escenas / texturas)

| Nombre | Tipo | Qué es |
|--------|------|--------|
| `StackScene` | `PackedScene` | Plantilla de cada pila. |
| `BackgroundTexture`, `MixIconTexture`, `HammerIconTexture`, `GloveIconTexture`, `DiamondIconTexture`, `LifeIconTexture` | `Texture2D` | Arte de fondo e iconos del HUD/diálogo. |

### Constantes numéricas y de diseño

| Nombre | Qué hace |
|--------|----------|
| `TOTAL_SLOTS` | 15 celdas visuales en la cuadrícula 5×3. |
| `SLOT_COLUMNS`, `SLOT_ROWS` | 5 columnas, 3 filas. |
| `STACK_CAPACITY` | 10 — debe coincidir con la lógica de `stack.gd` (`MAX_CAPACITY`). |
| `INITIAL_COINS_PER_STACK` | Monedas iniciales por pila al rellenar (salvo la pila vacía). |
| `ROLL_COINS_PER_ACTION` | Declarado como `2`; en el código actual **no se usa** (la tirada usa otra lógica). |
| `STACK_SIZE` | `Vector2(122, 286)` — caja para detectar clics sobre cada pila. |
| `PANEL_HEIGHT_RATIO`, `PANEL_MAX_WIDTH_RATIO`, `PANEL_CONTENT_PADDING_RATIO` | Proporciones del panel del tablero respecto al viewport. |
| `SLOT_FILL_RATIO` | `Vector2` — qué fracción de cada celda ocupa el “hueco” visual de la ranura. |
| `AD_FOOTER_HEIGHT_RATIO`, `AD_FOOTER_MIN_HEIGHT`, `AD_FOOTER_MAX_HEIGHT` | Altura reservada abajo (pie tipo anuncio). |
| `WILDCARD_TYPES` | `["mix", "hammer", "glove"]` — identificadores de comodines. |
| `WILDCARD_INITIAL_USES` | Usos iniciales por comodín. |
| `WILDCARD_COST_DIAMONDS` | Precio en gemas al recomprar usos en el diálogo. |
| `TEMP_SLOT_COST_DIAMONDS`, `TEMP_SLOT_DURATION_SEC` | Coste y duración de la ranura temporal. |
| `TEMP_LOCKED_PANEL_GREEN`, `TEMP_LOCKED_PANEL_CREAM` | Colores del cartel de ranura bloqueada / oferta. |
| `TEMP_SLOT_BOARD_INDEX` | Índice de celda 0..14 de la ranura temporal (esquina arriba-derecha = 4). |
| `ADJACENT_EXTRA_SLOT_BASE_PRICE`, `ADJACENT_EXTRA_SLOT_FREE_AT_LEVEL` | Precio base en estrellas y texto mock de “gratis al nivel X”. |
| `MAX_PERMANENT_STACKS` | Máximo 14 pilas “fijas”; la 15ª solo con ranura temporal activa. |
| `PERMANENT_SLOT_ORDER` | `Array` de índices de tablero: orden en que se colocan las pilas 1..14 en la cuadrícula. |

### Variables de estado del juego

| Nombre | Qué hace |
|--------|----------|
| `active_stacks` | Cuántas pilas están en juego (crece con nivel y compras). |
| `current_level` | Nivel actual del jugador. |
| `max_value` | Número objetivo para subir de nivel (aparece `max_value+1` en el tope). |
| `stacks` | `Array` de nodos pila en orden de índice lógico. |
| `selected_stack` | Pila elegida para mover, o `null`. |
| `board_locked` | Si el tablero no acepta movimientos (p. ej. sin espacio en tirada). |
| `hammer_mode_active` | Tras usar martillo, el próximo clic vacía una pila. |
| `background_sprite` | `Sprite2D` del fondo. |
| `hud_layer`, `hud_root` | `CanvasLayer` y `Control` raíz del HUD. |
| `home_chip`, `life_chip`, `life_chip_icon`, `settings_chip` | Chips superiores (decorativos/mock). |
| `progress_container`, `progress_fill`, `progress_knob`, `progress_*_label` | Barra de progreso mock. |
| `cta_shadow`, `cta_button`, `cta_label` | Botón grande “Repartir”. |
| `action_shadows`, `action_pills`, `action_icons`, `action_labels`, `action_count_badges`, `action_count_labels` | Arrays paralelos: UI de los tres comodines y contadores. |
| `wildcard_counts` | `Dictionary` — usos restantes por `"mix"`, `"hammer"`, `"glove"`. |
| `gems` | Diamantes para compras (comodines, ranura temporal). |
| `player_stars` | Estrellas mock para ranura adyacente. |
| `adjacent_slot_next_price` | Precio actual de la siguiente ranura extra (se duplica al comprar). |
| `adjacent_offer_board_index` | Celda del tablero donde se pinta la oferta adyacente, o `-1`. |
| `temp_slot_time_remaining` | Segundos restantes de la ranura temporal. |
| `temp_slot_bonus_active` | Si la pila extra por diamantes está activa. |
| `temp_slot_locked_*` | Nodos UI del cartel “bloqueado” de la ranura temporal. |
| `temp_slot_timer_label` | Cuenta atrás pequeña cuando la ranura temporal está activa. |
| `adjacent_slot_offer_*` | UI de la oferta de ranura extra con estrellas. |
| `adjacent_slot_star_error_label`, `adjacent_slot_star_error_tween` | Mensaje “no tienes estrellas” con fade. |
| `stars_chip`, `stars_chip_label` | Chip que muestra estrellas. |
| `purchase_*` | Diálogo de compra de usos de comodín con diamantes. |
| `pending_purchase_type` | Qué comodín se está comprando mientras el overlay está abierto. |

### Ciclo de vida y entrada

| Función | Qué hace |
|---------|----------|
| `_ready()` | `randomize()`, fondo, resize, `build_mock_ui()`, `setup_board()`, proceso temporal, `print_status()`. |
| `_exit_tree()` | Vacío; guardado comentado. |
| `_process(delta)` | Resta tiempo a ranura temporal; al llegar a 0 llama `close_temporary_slot()`. |
| `_input(event)` | Enter / clic en CTA → tirada; clics en ofertas; martillo; comodines; `handle_click`. |

### Tablero y pilas

| Función | Qué hace |
|---------|----------|
| `clear_board_stacks()` | Quita martillo, selección, libera nodos y vacía `stacks`. |
| `create_stack_nodes(count)` | Instancia `count` pilas y las posiciona. |
| `fill_board_initial_random()` | Deja una pila vacía y reparte `INITIAL_COINS_PER_STACK` en el resto con `get_roll_value()`. |
| `setup_board()` | Reinicia flags temporales, precio adyacente, limpia y vuelve a crear pilas. |
| `save_game()` / `try_load_saved_game()` | Stub: persistencia desactivada (comentarios indican cómo reactivarla). |

### Interacción y tirada

| Función | Qué hace |
|---------|----------|
| `handle_click(mouse_pos)` | Selecciona pila o mueve bloque superior a destino; llama `resolve_board_after_action` si hubo movimiento. |
| `get_stack_at_point(mouse_pos)` | Prueba `Rect2` por cada pila con `STACK_SIZE` escalado. |
| `clear_selection()` | Quita highlight de la pila seleccionada. |
| `perform_roll()` | Construye pool de valores 1..`max_value-1` con repeticiones aleatorias, reparte sin llenar al 100% los huecos, fusiona/nivel. |
| `resolve_board_after_action()` | Fusiones en bucle, subida de nivel, aviso de bloqueo, `print_status`, `save_game`. |
| `resolve_fusions()` | Bucle hasta que ninguna pila esté lista o límite de guardia 200. |
| `check_level_up()` | Si algún tope vale `max_value + 1`, sube nivel. |
| `level_up()` | Incrementa nivel y `max_value`; cada 2 niveles puede añadir pila permanente. |
| `add_new_stack_for_level_unlock()` | Inserta antes del final si hay pila temporal activa; si no, añade al final. |
| `append_new_stack_node()` / `insert_stack_before_index()` / `refresh_all_stack_layout()` | Crear pila y recalcular posiciones/escala. |
| `get_roll_value()` | Entero aleatorio en `1 .. max_value-1`. |
| `has_any_valid_moves()` | Doble bucle: existe movimiento legal entre pilas no vacías. |
| `print_status()` | Imprime nivel, objetivo y `stacks[i].coins` (acceso al array interno de cada `Stack`). |

### Ranura temporal (diamantes)

| Función | Qué hace |
|---------|----------|
| `try_purchase_temp_slot()` | Cobra gemas, aumenta `active_stacks`, marca bonus, añade nodo, inicia temporizador. |
| `close_temporary_slot()` | Elimina la última pila, baja `active_stacks`, reacomoda. |
| `configure_process_for_temp_slot()` | Activa `_process` solo si hay tiempo > 0. |
| `is_click_on_temp_slot_cell(pos)` | Clic en celda temporal si no está ya comprada. |
| `build_temp_slot_locked_ui()` / `update_temp_slot_overlay_label()` | Construye y actualiza textos/tamaños del overlay. |

### Ranura extra adyacente (estrellas)

| Función | Qué hace |
|---------|----------|
| `_occupied_board_slot_index_set()` | `Dictionary` de celdas de tablero ya ocupadas por una pila. |
| `find_adjacent_extra_slot_offer_board_index()` | Siguiente celda libre en `PERMANENT_SLOT_ORDER` según reglas (14 pilas sin temporal, etc.). |
| `build_adjacent_slot_offer_ui()` / `update_adjacent_slot_offer_ui()` | UI de precio y texto en la celda oferta. |
| `try_purchase_adjacent_extra_slot()` | Cobra estrellas, duplica precio, añade pila. |
| `is_click_on_adjacent_extra_slot_offer(pos)` | Hit test del rectángulo global de la oferta. |
| `show_adjacent_slot_insufficient_stars_message()` / `layout_adjacent_slot_star_error_label()` | Feedback de error. |

### Geometría del tablero y dibujo

| Función | Qué hace |
|---------|----------|
| `_draw()` | Sombra, panel, brillo, filas, celdas activas/inactivas/temporal. |
| `_on_viewport_resized()` | Reescala fondo, pilas, HUD, diálogo, overlays. |
| `update_background_scale()` | Escala el sprite de fondo al viewport. |
| `get_board_origin()`, `get_slot_base_y(row)`, `get_board_rect()`, `get_content_rect()`, `get_ad_footer_height()` | Rectángulos y orígenes para layout. |
| `get_layout_scale()` | Factor de escala UI/tablon entre 0.5 y 1.0. |
| `get_slot_cell_size()`, `get_slot_rect_size()`, `get_slot_rect(index)`, `get_row_rect(row)` | Matemática de celdas. |
| `get_panel_corner_radius()` | Radio de esquinas según escala. |
| `permanent_stack_count()` | Pilas contando sin la extra temporal si aplica. |
| `has_active_temp_stack()` | True si la última pila es la extra comprada por diamantes. |
| `get_board_slot_for_stack_index(stack_index)` | Mapea índice de pila → índice de celda 0..14. |
| `get_stack_position_for_index(index)` | `Vector2` centro-base de la pila en pantalla. |
| `get_temp_slot_global_rect()` / `get_adjacent_extra_slot_offer_global_rect()` | `Rect2` en coordenadas globales para clics. |
| `is_slot_active(slot_index)` | Si alguna pila usa esa celda del tablero. |

### HUD y utilidades UI

| Función | Qué hace |
|---------|----------|
| `build_mock_ui()` | Crea toda la jerarquía: chips, barra, CTA, acciones, diálogo, overlays temporales y adyacentes. |
| `layout_mock_ui()` | Posiciones y tamaños según viewport y `get_board_rect()`. |
| `create_panel`, `create_shadow_panel`, `create_chip_panel`, `create_chip_with_icon_panel`, `create_label` | Fábricas de controles con estilos coherentes. |
| `is_control_clicked(ctrl, point)` | ¿El clic cayó dentro del `Control`? |
| `_sync_slot_overlay_controls()` | Actualiza overlays de temporal y adyacente. |
| `_make_temp_slot_locked_panel_style(corner_px)` | `StyleBoxFlat` crema con borde verde. |

### Comodines y diálogo de compra

| Función | Qué hace |
|---------|----------|
| `perform_mix_action()` | Vacía todas las pilas, ordena todos los valores de menor a mayor (`sort`) y los vuelve a colocar por bloques homogéneos (una pila por bloque cuando es posible), sin descartar fichas; al final dibuja el estado ordenado y difiere `resolve_board_after_action` al siguiente frame para que una pila de 10 pueda verse antes de fusionar. |
| `perform_hammer_action()` | Activa modo martillo. |
| `perform_glove_action()` | Stub: solo imprime que no está implementado. |
| `apply_hammer_on_stack(target_stack)` | Vacía la pila elegida y desactiva martillo. |
| `try_use_wildcard(wildcard_type)` | Si no hay usos, abre compra; si hay, consume y ejecuta acción. |
| `consume_wildcard` / `add_wildcard_use` / `update_wildcard_badges` | Contadores en UI. |
| `update_gem_display()` | Reservado (vacío). |
| `update_stars_display()` | Actualiza texto del chip de estrellas. |
| `build_purchase_dialog()`, `open_purchase_dialog()`, `layout_purchase_dialog_controls()`, `update_purchase_dialog_content()` | Overlay de compra con diamantes. |
| `_on_purchase_confirmed()` | Cobra gemas y suma un uso. |
| `_on_purchase_close_pressed()` / `_on_purchase_close_requested()` | Cierra sin comprar. |
| `get_wildcard_display_name()`, `get_wildcard_icon_texture()`, `create_wildcard_icon_texture_rect()` | Texto e icono según tipo. |
| `make_flat_style()` | Crea `StyleBoxFlat` para botones. |

---

## 6. Arrays y vectores importantes (resumen)

- **`PERMANENT_SLOT_ORDER`**: orden de desbloqueo visual de las 14 pilas permanentes en la cuadrícula 5×3 (no es orden fila/columna simple, es un recorrido de diseño).
- **`stacks`**: lista de nodos `Stack` en orden de juego; el último puede ser la pila temporal.
- **`WILDCARD_TYPES`**: alinea índices 0..2 con sombras, pastillas, iconos y badges en `build_mock_ui`.
- **`coins` / `coin_nodes` en `stack.gd`**: paralelos; mismo índice = misma moneda lógica y visual.
- **`values_to_roll` en `perform_roll`**: mezcla aleatoria de enteros antes de repartir en pilas.

---

## 7. Archivos que no están explicados línea a línea

- **`addons/godot_mcp/**`**: integración MCP para el editor; no forma parte del gameplay de Coin Stack Puzzle.
- **`.tscn`**: escenas en formato Godot (árbol de nodos y propiedades); el comportamiento está en los scripts enlazados.

Si más adelante añadís scripts nuevos, conviene actualizar este resumen o generar documentación automática desde comentarios `##` en GDScript.
